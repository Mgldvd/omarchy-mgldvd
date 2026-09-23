# Helpers shared by the omarchy-mgldvd "improvements".
# This file is sourced, not executed directly.

HYPR_CONFIG_DIR="$HOME/.config/hypr"
BINDINGS_FILE="$HYPR_CONFIG_DIR/bindings.lua"
INPUT_FILE="$HYPR_CONFIG_DIR/input.lua"
LOOKNFEEL_FILE="$HYPR_CONFIG_DIR/looknfeel.lua"
MGLDVD_HYPR_DIR="$HYPR_CONFIG_DIR/mgldvd"
MGLDVD_STATE_DIR="$HOME/.config/omarchy-mgldvd"

common::ensure_mgldvd_dir() { mkdir -p "$MGLDVD_HYPR_DIR"; }
common::ensure_state_dir() { mkdir -p "$MGLDVD_STATE_DIR"; }

# Keeps a single backup of a file as it was before omarchy-mgldvd first
# touched it.
common::backup_once() {
  local file="$1"
  local backup="${file}.mgldvd-backup"
  [ -f "$file" ] && [ ! -f "$backup" ] && cp "$file" "$backup"
  return 0
}

common::block_present() {
  local file="$1" name="$2"
  grep -qF -- "-- >>> omarchy-mgldvd:${name} >>>" "$file" 2>/dev/null
}

# Idempotently appends a block of configuration lines, delimited by unique
# markers, to $file so it can be removed cleanly later. $content may span
# several lines.
common::add_marked_block() {
  local file="$1" name="$2" content="$3"
  common::backup_once "$file"
  if ! common::block_present "$file" "$name"; then
    {
      echo ""
      echo "-- >>> omarchy-mgldvd:${name} >>>"
      printf '%s\n' "$content"
      echo "-- <<< omarchy-mgldvd:${name} <<<"
    } >>"$file"
  fi
}

common::remove_marked_block() {
  local file="$1" name="$2"
  [ -f "$file" ] || return 0
  sed -i "/^-- >>> omarchy-mgldvd:${name} >>>\$/,/^-- <<< omarchy-mgldvd:${name} <<<\$/d" "$file"
}

# The three require helpers accept an optional target file (2nd arg); it
# defaults to bindings.lua, where most improvements live.
common::require_block_present() {
  local name="$1" file="${2:-$BINDINGS_FILE}"
  common::block_present "$file" "$name"
}

common::add_require_block() {
  local name="$1" file="${2:-$BINDINGS_FILE}"
  common::add_marked_block "$file" "$name" "require(\"hypr.mgldvd.${name}\")"
}

common::remove_require_block() {
  local name="$1" file="${2:-$BINDINGS_FILE}"
  common::remove_marked_block "$file" "$name"
}

# Builds the key expression for o.bind(), with or without a modifier.
common::bind_key() {
  local modifier="$1" code="$2"
  if [ -n "$modifier" ]; then
    echo "${modifier} + mouse:${code}"
  else
    echo "mouse:${code}"
  fi
}

common::reload_hyprland() {
  command -v hyprctl >/dev/null 2>&1 || return 0
  hyprctl reload >/dev/null 2>&1 || true
  local errors
  errors="$(hyprctl configerrors 2>/dev/null || true)"
  if [ -n "$errors" ] && [ "$errors" != "no errors" ]; then
    echo "Warning: hyprctl configerrors reported the following:" >&2
    echo "$errors" >&2
  fi
}
