#!/usr/bin/env bash
# Copyright (c) 2026 Paul Butcher. All rights reserved.
# Released under Apache 2.0 license as described in the file LICENSE.

# Stage 3's acceptance: the guild's kit, with Inkproof's configuration and settings, comes up
# under the compose project name inkproof-forge against an empty Forgejo with mirrors off and
# no GitHub token; bootstrap creates the organisation, empty repositories and accounts; and
# every agent starts stopped. The deployment is kept for inspection; KEEP=0 removes it.
#
# It runs only in the dev container's own Docker engine: the Mac's holds production's volumes
# under the same project name.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
project=inkproof-forge

[ "$(docker info --format '{{.Name}}')" = "$(hostname)" ] \
  || { echo "This Docker engine isn't this container's own; refusing to deploy $project on it." >&2; exit 1; }

dir="$root/.lake/stage3"
state="$dir/state"
# What we deployed before may go; anything else under the name is not ours to remove.
if docker ps -aq --filter "label=com.docker.compose.project=$project" | grep -q . \
   || docker volume ls -q --filter "label=com.docker.compose.project=$project" | grep -q .; then
  [ -e "$dir/deployed" ] || { echo "A $project kit this script didn't make is in this engine; remove it first." >&2; exit 1; }
fi

lake build inkproof-guild >/dev/null
guild="$root/.lake/packages/guild"
export KIT="$root/.lake/build/bin/inkproof-guild" KIT_ENV="$dir/settings.env" KIT_YES=1

if [ -e "$dir/deployed" ]; then
  KIT_NO_BUILD=1 "$guild/scripts/down.sh" >/dev/null 2>&1 || true
  docker volume ls -q --filter "label=com.docker.compose.project=$project" | xargs -r docker volume rm >/dev/null
fi
rm -rf "$dir"
mkdir -p "$dir"
# The template, with the dev container's user and ports clear of a forwarded 3000.
{
  sed -e '/^HOST_UID=/d' -e '/^HOST_GID=/d' -e '/^FORGE_PORT=/d' -e '/^FORGE_WEB_URL=/d' \
    -e 's/^HUMAN_EMAIL=.*/HUMAN_EMAIL=human@noreply.localhost/' deploy/settings.env.example
  echo "HUMAN_PASSWORD=$(openssl rand -hex 12)"
  echo "FORGE_PORT=3300"
  echo "FORGE_WEB_URL=http://localhost:3300"
  echo "DISPATCHER_PORT=3301"
  echo "UI_PORT=3302"
  echo "MIRRORS=off"
} > "$KIT_ENV"
touch "$dir/deployed"

# Every agent stopped before its container first starts, and a stand-in Claude token so that
# up.sh starts them: a stopped agent never runs, so the token is never used.
( set -a; . "$KIT_ENV"; "$KIT" export "$state/config" >/dev/null )
agents="$(cut -f1 "$state/config/agents.tsv")"
mkdir -p "$state/control" "$state/secrets/claude"
for a in $agents; do touch "$state/control/stopped-$a"; done
echo stand-in > "$state/secrets/claude/oauth-token"

echo "== Up, bootstrap, up again"
"$guild/scripts/up.sh" >"$dir/up.log" 2>&1 || { tail -20 "$dir/up.log"; exit 1; }
"$guild/scripts/bootstrap.sh" >"$dir/bootstrap.log" 2>&1 || { tail -20 "$dir/bootstrap.log"; exit 1; }
"$guild/scripts/up.sh" >>"$dir/up.log" 2>&1 || { tail -20 "$dir/up.log"; exit 1; }

fails=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; fails=$((fails + 1)); }
api() { KIT_NO_BUILD=1 "$guild/scripts/kit.sh" api GET "$1" </dev/null 2>/dev/null; }
. "$state/config/project.env"
. "$KIT_ENV"

running="$(docker ps --filter "label=com.docker.compose.project=$project" --format '{{.Label "com.docker.compose.service"}}')"
has() { printf '%s\n' "$running" | grep -qx "$1"; }
for s in forgejo dispatcher gatekeeper ui ci-runner; do
  has "$s" && pass "$s runs under $project" || fail "$s isn't running under $project"
done

api "/orgs/$FORGE_ORG" | jq -e .id >/dev/null && pass "the organisation $FORGE_ORG exists" || fail "no organisation $FORGE_ORG"
for r in $REPOSITORIES; do
  repo="$(api "/repos/$FORGE_ORG/$r")"
  if [ "$(printf '%s' "$repo" | jq -r .empty)" = true ]; then pass "$r exists, empty"; else fail "$r is missing or not empty"; fi
  # With mirrors off, Forgejo refuses the request outright, which is stronger than an empty list.
  m="$(KIT_NO_BUILD=1 "$guild/scripts/kit.sh" api GET "/repos/$FORGE_ORG/$r/push_mirrors" </dev/null 2>&1 || true)"
  case "$m" in "[]"|*"Mirror feature is disabled"*) ;; *) fail "$r has a push mirror" ;; esac
done
[ ! -s "$state/secrets/github/mirror-token" ] && pass "there is no GitHub token" || fail "a GitHub token is in secrets/"

for a in $HUMAN_USER $agents; do
  api "/users/$a" | jq -e .id >/dev/null || fail "no account for $a"
done
pass "checked the accounts of $HUMAN_USER and every agent"

status="$(curl -fsS "http://127.0.0.1:$DISPATCHER_PORT/status")"
for a in $agents; do
  has "$a" || fail "$a's container isn't running"
  [ "$(printf '%s' "$status" | jq -r --arg a "$a" '.agents[$a].state')" = stopped ] || fail "$a isn't stopped"
done
pass "checked that every agent runs, stopped"

if [ "${KEEP:-1}" = 0 ]; then
  "$guild/scripts/down.sh" >/dev/null
  docker volume ls -q --filter "label=com.docker.compose.project=$project" | xargs -r docker volume rm >/dev/null
  rm -rf "$dir"
else
  echo "INFO: kept; Forgejo at http://localhost:3300/, the UI at http://localhost:3302/ (key in $state/secrets/ui/key)"
fi
echo
[ "$fails" = 0 ] && echo "Stage 3: all checks passed." || { echo "Stage 3: $fails check(s) failed."; exit 1; }
