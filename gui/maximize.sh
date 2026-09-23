#!/usr/bin/env bash
# Waits for the omarchy-mgldvd window to appear and maximizes it, the same as
# Omarchy's SUPER + ALT + F ("Full width"). Omarchy ignores maximize requests
# made by the apps themselves (suppress_event = "maximize"), so it has to be
# done from outside once the window is mapped and focused.
set -euo pipefail

command -v hyprctl >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

for _ in $(seq 1 50); do
  active="$(hyprctl -j activewindow 2>/dev/null || true)"
  if [ "$(jq -r '.title // empty' <<<"$active" 2>/dev/null)" = "omarchy-mgldvd" ]; then
    # fullscreen == 0 means it is a normal (tiled/floating) window.
    if [ "$(jq -r '.fullscreen // 0' <<<"$active")" = "0" ]; then
      hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized" })' >/dev/null 2>&1 || true
    fi
    exit 0
  fi
  sleep 0.1
done
