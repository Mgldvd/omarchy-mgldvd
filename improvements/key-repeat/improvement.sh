#!/usr/bin/env bash
# Improvement: tunes Hyprland's key repeat (input:repeat_delay and
# input:repeat_rate). With Omarchy's default delay (250 ms), holding a key for
# just a moment (or having the key release arrive late, as happens with
# Sunshine/Moonlight) is enough to make it repeat: for example, a paste that
# fires 2 or 3 times. Raising the delay avoids it.
# Besides configure (terminal menu), it exposes `sliders` and `set` so the
# graphical window (./run-gui) can show one slider per value.
set -euo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=../../lib/common.sh
source "$DIR/../../lib/common.sh"

NAME="key-repeat"
CONF_FILE="$MGLDVD_STATE_DIR/${NAME}.conf"

# Slider limits / validation.
DELAY_MIN=150
DELAY_MAX=1000
RATE_MIN=5
RATE_MAX=60

defaults() {
  # Omarchy ships 250 ms / 40 per second; the raised delay avoids accidental
  # repeats.
  REPEAT_DELAY="500"
  REPEAT_RATE="25"
}

load_conf() {
  defaults
  # shellcheck disable=SC1090
  [ -f "$CONF_FILE" ] && source "$CONF_FILE"
  return 0
}

save_conf() {
  common::ensure_state_dir
  cat >"$CONF_FILE" <<EOF
REPEAT_DELAY="$REPEAT_DELAY"
REPEAT_RATE="$REPEAT_RATE"
EOF
}

# Returns 0 if $1 is an integer between $2 and $3.
in_range() { [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge "$2" ] && [ "$1" -le "$3" ]; }

check_values() {
  if ! in_range "$REPEAT_DELAY" "$DELAY_MIN" "$DELAY_MAX"; then
    echo "Invalid delay: '$REPEAT_DELAY' (allowed ${DELAY_MIN}-${DELAY_MAX} ms)." >&2
    return 1
  fi
  if ! in_range "$REPEAT_RATE" "$RATE_MIN" "$RATE_MAX"; then
    echo "Invalid rate: '$REPEAT_RATE' (allowed ${RATE_MIN}-${RATE_MAX} per second)." >&2
    return 1
  fi
}

render() {
  common::remove_marked_block "$INPUT_FILE" "$NAME"
  common::add_marked_block "$INPUT_FILE" "$NAME" \
    "hl.config({ input = { repeat_delay = ${REPEAT_DELAY}, repeat_rate = ${REPEAT_RATE} } })"
}

cmd_name() { echo "Keyboard: key repeat delay and rate"; }

cmd_description() {
  load_conf
  echo "Delay before repeating: ${REPEAT_DELAY} ms; rate: ${REPEAT_RATE}/s (Omarchy: 250 ms, 40/s). A higher delay avoids accidental repeated pastes/keys."
}

cmd_status() {
  if common::block_present "$INPUT_FILE" "$NAME"; then
    echo "installed"
  else
    echo "not-installed"
  fi
}

cmd_install() {
  load_conf
  check_values
  render
  save_conf
  common::reload_hyprland
  echo "Installed: delay ${REPEAT_DELAY} ms, rate ${REPEAT_RATE}/s."
}

cmd_uninstall() {
  common::remove_marked_block "$INPUT_FILE" "$NAME"
  common::reload_hyprland
  echo "Uninstalled (Omarchy's values are back: 250 ms, 40/s)."
}

# Sliders for the graphical window: a JSON with the numeric options.
cmd_sliders() {
  load_conf
  jq -nc \
    --argjson dmin "$DELAY_MIN" --argjson dmax "$DELAY_MAX" --argjson dval "$REPEAT_DELAY" \
    --argjson rmin "$RATE_MIN" --argjson rmax "$RATE_MAX" --argjson rval "$REPEAT_RATE" \
    '[
      {key: "REPEAT_DELAY", label: "Delay before repeating (ms)", min: $dmin, max: $dmax, step: 10, value: $dval},
      {key: "REPEAT_RATE", label: "Repeat rate (per second)", min: $rmin, max: $rmax, step: 1, value: $rval}
    ]'
}

# `set KEY VALUE`: changes one option and, if installed, applies it.
cmd_set() {
  local key="${1:-}" value="${2:-}"
  load_conf
  case "$key" in
  REPEAT_DELAY) REPEAT_DELAY="$value" ;;
  REPEAT_RATE) REPEAT_RATE="$value" ;;
  *)
    echo "Unknown option: '$key'." >&2
    return 1
    ;;
  esac
  check_values
  save_conf
  if [ "$(cmd_status)" = "installed" ]; then
    render
    common::reload_hyprland
    echo "Applied: delay ${REPEAT_DELAY} ms, rate ${REPEAT_RATE}/s."
  else
    echo "Saved (install the improvement to apply it): delay ${REPEAT_DELAY} ms, rate ${REPEAT_RATE}/s."
  fi
}

cmd_configure() {
  load_conf
  echo "Delay: ${DELAY_MIN}-${DELAY_MAX} ms (higher = fewer accidental repeats)."
  echo "Rate: ${RATE_MIN}-${RATE_MAX} repeats per second."
  if command -v gum >/dev/null 2>&1; then
    REPEAT_DELAY=$(gum input --value "$REPEAT_DELAY" --header "Delay before repeating (ms)")
    REPEAT_RATE=$(gum input --value "$REPEAT_RATE" --header "Repeat rate (per second)")
  else
    read -r -p "Delay in ms [$REPEAT_DELAY]: " input && REPEAT_DELAY="${input:-$REPEAT_DELAY}"
    read -r -p "Rate per second [$REPEAT_RATE]: " input && REPEAT_RATE="${input:-$REPEAT_RATE}"
  fi
  check_values
  save_conf
  if [ "$(cmd_status)" = "installed" ]; then
    render
    common::reload_hyprland
    echo "Configuration updated and applied."
  else
    echo "Configuration saved. Install the improvement to apply it."
  fi
}

case "${1:-}" in
name) cmd_name ;;
description) cmd_description ;;
status) cmd_status ;;
install) cmd_install ;;
uninstall) cmd_uninstall ;;
configure) cmd_configure ;;
sliders) cmd_sliders ;;
set) shift; cmd_set "$@" ;;
*)
  echo "Usage: $0 {name|description|status|install|uninstall|configure|sliders|set KEY VALUE}" >&2
  exit 1
  ;;
esac
