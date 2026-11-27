#!/usr/bin/env bash
# Copyright (c) 2026 Paul Butcher. All rights reserved.
# Released under Apache 2.0 license as described in the file LICENSE.

# Runs the guild's script NAME with this checkout's kit executable and settings.env.
#   scripts/lib/guild.sh NAME [ARGS...]
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
name="$1"; shift
export KIT="$root/.lake/build/bin/inkproof-guild" KIT_ENV="$root/settings.env"
[ -x "$KIT" ] || { echo "No kit executable: run \`lake build\` in $root first." >&2; exit 1; }
[ -f "$KIT_ENV" ] || { echo "No settings: copy deploy/settings.env.example to $KIT_ENV and edit it." >&2; exit 1; }
exec "$root/.lake/packages/guild/scripts/$name.sh" "$@"
