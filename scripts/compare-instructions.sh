#!/bin/sh
# Copyright (c) 2026 Paul Butcher. All rights reserved.
# Released under Apache 2.0 license as described in the file LICENSE.
#
# Each agent's instructions as the reference renders them and as the guild assembles them,
# written to <out>/reference/ and <out>/guild/, then diffed.
#   scripts/compare-instructions.sh [<out> [<reference checkout>]]
set -eu
here="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$here/.lake/compare}"
ref="${2:-$here/../inkproof-forge}"
org=tentenths human=paulbutcher owner=paulbutcher web=http://localhost:3000

lake -d "$here" build inkproof-guild >/dev/null
rm -rf "$out" && mkdir -p "$out/reference" "$out/guild"

grep -v '^#' "$ref/agents.conf" | while read -r agent _ repo _; do
  [ -n "$agent" ] || continue
  # As the reference's inkproof-render does.
  render() {
    sed -e "s|{{AGENT}}|$agent|g" -e "s|{{REPO}}|$repo|g" -e "s|{{ORG}}|$org|g" \
        -e "s|{{HUMAN}}|$human|g" -e "s|{{GH_OWNER}}|$owner|g" -e "s|{{FORGE_WEB_URL}}|$web|g" "$1"
  }
  { render "$ref/roles/$agent.md"; echo; render "$ref/docker/agent/PROTOCOL.md"; } > "$out/reference/$agent.md"
  FORGE_ORG=$org HUMAN_USER=$human FORGE_WEB_URL=$web WORKSPACE_STATE=.inkproof \
    "$here/.lake/build/bin/inkproof-guild" instructions "$agent" > "$out/guild/$agent.md"
done

diff -ru "$out/reference" "$out/guild" || true
