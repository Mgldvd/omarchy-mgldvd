#!/usr/bin/env bash
# Lists the available improvements as a JSON array: id, name, description,
# status and sliders. gui/Main.qml uses it to draw the window.
set -euo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

for d in "$DIR"/improvements/*/; do
  script="${d}improvement.sh"
  [ -x "$script" ] || continue
  id="$(basename "$d")"
  name="$("$script" name)"
  desc="$("$script" description)"
  status="$("$script" status)"
  # Only some improvements expose sliders (optional `sliders` subcommand).
  sliders="$("$script" sliders 2>/dev/null || true)"
  [ -n "$sliders" ] || sliders="[]"
  jq -nc --arg id "$id" --arg name "$name" --arg desc "$desc" --arg status "$status" \
    --argjson sliders "$sliders" \
    '{id: $id, name: $name, description: $desc, status: $status, sliders: $sliders}'
done | jq -s .
