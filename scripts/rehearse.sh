#!/usr/bin/env bash
# Copyright (c) 2026 Paul Butcher. All rights reserved.
# Released under Apache 2.0 license as described in the file LICENSE.

# Stage 4's rehearsal, on a production backup restored into the dev container's own engine,
# isolated (rehearsal/isolated.yaml), with no Claude token, so no agent starts:
#   1. the reference's kit on one restored copy, and its view: status.sh, its status, its ledger;
#   2. the guild's kit on another, restored with the guild's own restore.sh, and its view;
#   3. the switch on a third: the reference drained, backed up and stopped, the guild started on
#      its data, bootstrapped and resumed; then the way back: the guild drained, switch-back.sh,
#      the guild stopped, the reference started on the same ledger and resumed.
# Each copy is the compose project inkproof-forge, the reference's fixed name, with its own state.
# The views and their differences go to .lake/rehearsal/out; explaining them is the human's and the
# agent's work, so differences there don't fail this script.
#   scripts/rehearse.sh backups/<time>
# The reference runs from a copy of ../inkproof-forge (REFERENCE), never from its checkout.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
backup="${1:?usage: scripts/rehearse.sh backups/<time>}"
backup="$(cd "$backup" && pwd)"
[ -s "$backup/forgejo.tar.gz" ] || { echo "No backup in $backup." >&2; exit 1; }
project=inkproof-forge
label="label=com.docker.compose.project=$project"

[ "$(docker info --format '{{.Name}}')" = "$(hostname)" ] \
  || { echo "This Docker engine isn't this container's own; refusing to restore production's data on it." >&2; exit 1; }
dir="$root/.lake/rehearsal"
if docker ps -aq --filter "$label" | grep -q . || docker volume ls -q --filter "$label" | grep -q .; then
  [ -e "$dir/deployed" ] || { echo "A $project kit this script didn't make is in this engine; remove it first." >&2; exit 1; }
fi

clear_kit() {
  docker ps -aq --filter "$label" | xargs -r docker rm -f >/dev/null
  docker volume ls -q --filter "$label" | xargs -r docker volume rm >/dev/null
  docker network ls -q --filter "$label" | xargs -r docker network rm >/dev/null
}
clear_kit
rm -rf "$dir"
mkdir -p "$dir/out"
touch "$dir/deployed"
out="$dir/out"
ref="$dir/reference"

lake build inkproof-guild >/dev/null
guild_scripts="$root/.lake/packages/guild/scripts"
mkdir -p "$ref"
tar -C "${REFERENCE:-$root/../inkproof-forge}" --exclude=.git -cf - . | tar -C "$ref" -xf -

export COMPOSE_FILE="compose.yaml:$root/rehearsal/isolated.yaml" KIT_YES=1 RESTORE_CONFIRM=restore

# settings STATE: each kit's settings for a copy whose state is in STATE.
settings() {
  local state="$1"
  mkdir -p "$state"
  cat > "$dir/reference.env" <<EOF
GH_OWNER=paulbutcher
GH_FORMER_OWNERS=tentenths
FORGE_ORG=tentenths
REPO_PREFIX=inkproof-
HUMAN_USER=paulbutcher
HUMAN_EMAIL=human@noreply.localhost
HOST_UID=$(id -u)
HOST_GID=$(id -g)
FORGE_PORT=3400
DISPATCHER_PORT=3401
STATE_DIR=$state
MIRROR_BRANCHES=main
EOF
  {
    sed -e '/^HOST_UID=/d' -e '/^HOST_GID=/d' -e '/^FORGE_PORT=/d' -e '/^FORGE_WEB_URL=/d' -e '/^STATE_DIR=/d' \
      -e 's/^HUMAN_EMAIL=.*/HUMAN_EMAIL=human@noreply.localhost/' deploy/settings.env.example
    echo "STATE_DIR=$state"
    echo "FORGE_PORT=3400"
    echo "FORGE_WEB_URL=http://localhost:3400"
    echo "DISPATCHER_PORT=3401"
    echo "UI_PORT=3402"
    echo "MIRRORS=off"
  } > "$dir/guild.env"
  STATE="$state"
}
refkit() { (cd "$ref" && KIT_ENV="$dir/reference.env" "$@"); }
guild() { KIT_ENV="$dir/guild.env" KIT="$root/.lake/build/bin/inkproof-guild" "$@"; }

fails=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; fails=$((fails + 1)); }
step() { echo "== $*"; }
# quiet LOG COMMAND...: the command's output to LOG, and its tail on failure.
quiet() { local log="$1"; shift; "$@" >>"$log" 2>&1 || { tail -30 "$log" >&2; return 1; }; }
until_true() {
  local deadline=$(( $(date +%s) + $1 ))
  shift
  while [ "$(date +%s)" -lt "$deadline" ]; do
    "$@" >/dev/null 2>&1 && return 0
    sleep 5
  done
  return 1
}
status() { curl -fsS -m 30 http://127.0.0.1:3401/status; }
jqs() { status | jq -r "$@"; }
# A sweep now, through the admin endpoint both kits have.
reconcile() {
  curl -fsS -m 600 -X POST -H "Authorization: Bearer $(tr -d '[:space:]' < "$STATE/secrets/dispatcher/admin-key")" \
    http://127.0.0.1:3401/admin/reconcile >/dev/null
}
settle() {
  until_true 300 status || { fail "the dispatcher never answered"; return 1; }
  until_true 900 reconcile || { fail "the dispatcher never swept"; return 1; }
  reconcile || true
}
# What is owed, by whom and whether it is now the human's.
obligations() { jq -r '.obligations[] | [.agent, .unit, .what, (.escalated | tostring)] | @tsv' | sort; }
# The ledger, copied out of the stopped kit's volume.
ledger() {
  mkdir -p "$1"
  docker run --rm --network none -v "${project}_dispatcher-state:/s:ro" alpine:3.24 tar -C /s -cf - . | tar -C "$1" -xf -
}
units() {
  docker run --rm --network none -v "$1:/l:ro" --entrypoint sqlite3 "$project-tools:1" -separator "$(printf '\t')" \
    /l/ledger.db "SELECT unit, kind, state, holders FROM units ORDER BY unit"
}
# Notices made since the backup: what each dispatcher told the human on waking to it.
new_notices() {
  local before
  before="$(docker run --rm --network none -v "$backup:/b:ro" --entrypoint sqlite3 "$project-tools:1" "file:/b/ledger.db?immutable=1" \
    "SELECT COALESCE(MAX(id), 0) FROM notices")"
  docker run --rm --network none -v "$1:/l:ro" --entrypoint sqlite3 "$project-tools:1" -separator "$(printf '\t')" \
    /l/ledger.db "SELECT kind, repo, number FROM notices WHERE id > $before ORDER BY kind, repo, number"
}

# The reference's kit, restored from the backup, with tokens made afresh.
reference_restored() {
  quiet "$1" refkit scripts/up.sh
  quiet "$1" refkit scripts/restore.sh "$backup"
  quiet "$1" refkit scripts/bootstrap.sh
  quiet "$1" refkit scripts/up.sh
}

step "1. The reference's view"
settings "$dir/state-reference"
reference_restored "$out/reference.log"
settle
refkit scripts/status.sh > "$out/reference-status.txt" 2>&1 || fail "the reference's status.sh failed"
status > "$out/reference-status.json"
quiet "$out/reference.log" refkit scripts/down.sh
ledger "$dir/ledger-reference"
clear_kit
pass "the reference ran on its restored copy"

step "2. The guild's view"
settings "$dir/state-guild"
quiet "$out/guild.log" guild "$guild_scripts/up.sh"
quiet "$out/guild.log" guild "$guild_scripts/restore.sh" "$backup"
quiet "$out/guild.log" guild "$guild_scripts/bootstrap.sh"
quiet "$out/guild.log" guild "$guild_scripts/up.sh"
settle
status > "$out/guild-status.json"
quiet "$out/guild.log" guild "$guild_scripts/down.sh"
ledger "$dir/ledger-guild"
clear_kit
pass "the guild ran on its restored copy, restored by its own restore.sh"

step "The comparison"
for k in reference guild; do
  obligations < "$out/$k-status.json" > "$out/$k-obligations.tsv"
  units "$dir/ledger-$k" > "$out/$k-units.tsv"
  new_notices "$dir/ledger-$k" > "$out/$k-notices.tsv"
done
jq -r '.summary | split("\n")[0]' "$out/reference-status.json" > "$out/reference-human.txt"
jq -r '.waiting_on_you' "$out/guild-status.json" > "$out/guild-human.txt"
{
  for f in obligations units notices; do
    echo "## $f (reference, then guild)"
    diff "$out/reference-$f.tsv" "$out/guild-$f.tsv" && echo "the same"
    echo
  done
  echo "## waiting on the human"
  echo "reference: $(cat "$out/reference-human.txt")"
  echo "guild: $(cat "$out/guild-human.txt")"
} > "$out/comparison.txt" || true
echo "INFO: $(grep -c '^[<>]' "$out/comparison.txt" || true) differing line(s) in $out/comparison.txt"

step "3. The switch"
settings "$dir/state-switch"
reference_restored "$out/switch.log"
settle
status | obligations > "$out/switch-before.tsv"
refkit timeout 1800 scripts/drain.sh >>"$out/switch.log" 2>&1 && pass "the reference drains" || fail "the reference never drained"
quiet "$out/switch.log" refkit scripts/backup.sh
ls -d "$STATE"/backups/[0-9]*Z >/dev/null 2>&1 && pass "the reference backs up" || fail "the reference made no backup"
quiet "$out/switch.log" refkit scripts/down.sh
# The guild's state is a copy of the reference's four folders, as the runbook's switch makes it.
mkdir -p "$dir/state-switch-guild"
cp -Rp "$STATE"/{secrets,control,backups,proxy} "$dir/state-switch-guild/"
sed -i "s|^STATE_DIR=.*|STATE_DIR=$dir/state-switch-guild|" "$dir/guild.env"
STATE="$dir/state-switch-guild"
before_volumes="$(docker volume ls -q --filter "$label" | sort)"
quiet "$out/switch.log" guild "$guild_scripts/up.sh"
settle
[ "$(jqs .draining)" = true ] && pass "the guild finds the reference's drain" || fail "the guild isn't draining"
added="$(comm -13 <(printf '%s\n' "$before_volumes") <(docker volume ls -q --filter "$label" | sort) \
  | grep -E 'forgejo|dispatcher-state|run-archive' || true)"
[ -z "$added" ] && pass "the guild uses the reference's volumes" || fail "the guild made volumes of its own: $added"
status | obligations > "$out/switch-guild.tsv"
diff "$out/switch-before.tsv" "$out/switch-guild.tsv" > "$out/switch-obligations.diff" \
  && pass "the guild owes what the reference owed" || echo "INFO: obligations differ after the switch: $out/switch-obligations.diff"
guild "$guild_scripts/bootstrap.sh" > "$out/switch-bootstrap.txt" 2>&1 \
  && pass "the guild's bootstrap runs on the reference's Forgejo" || fail "the guild's bootstrap failed: $out/switch-bootstrap.txt"
grep -E '^  ' "$out/switch-bootstrap.txt" | sed 's/^ */INFO: bootstrap: /' || true
rm -f "$STATE/control/draining"
until_true 60 sh -c "curl -fsS http://127.0.0.1:3401/status | jq -e '.draining == false'" \
  && pass "the guild resumes" || fail "the guild didn't resume"

step "3. The way back"
touch "$STATE/control/draining"
until_true 1800 sh -c "curl -fsS http://127.0.0.1:3401/status | jq -e .drained" && pass "the guild drains" || fail "the guild never drained"
guild "$guild_scripts/switch-back.sh" > "$out/switch-back.txt" 2>&1 \
  && pass "switch-back.sh lists nothing" || echo "INFO: switch-back.sh lists items to edit first: $out/switch-back.txt"
status | obligations > "$out/switch-guild-end.tsv"
quiet "$out/switch.log" guild "$guild_scripts/down.sh"
guild "$guild_scripts/switch-back.sh" --hand-back >>"$out/switch.log" 2>&1 \
  && pass "the guild hands the ledger back" || fail "switch-back.sh --hand-back failed"
# The way back points the reference at the guild's state.
sed -i "s|^STATE_DIR=.*|STATE_DIR=$STATE|" "$dir/reference.env"
quiet "$out/switch.log" refkit scripts/up.sh
settle
[ "$(jqs .draining)" = true ] && pass "the reference finds the guild's drain" || fail "the reference isn't draining"
status | obligations > "$out/switch-back-reference.tsv"
diff "$out/switch-guild-end.tsv" "$out/switch-back-reference.tsv" > "$out/switch-back-obligations.diff" \
  && pass "the reference owes what the guild owed" || echo "INFO: obligations differ after the way back: $out/switch-back-obligations.diff"
quiet "$out/switch.log" refkit scripts/resume.sh
[ "$(jqs .draining)" = false ] && pass "the reference resumes" || fail "the reference didn't resume"

if [ "${KEEP:-}" = 1 ]; then
  echo "INFO: kept the reference running on the switched copy: Forgejo at http://localhost:3400/"
else
  quiet "$out/switch.log" refkit scripts/down.sh
  clear_kit
fi
echo
[ "$fails" = 0 ] && echo "Rehearsal: every step passed; the views' differences are in $out." \
  || { echo "Rehearsal: $fails step(s) failed."; exit 1; }
