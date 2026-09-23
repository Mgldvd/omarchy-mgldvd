#!/usr/bin/env bash
# Improvement: in the foot terminal, Ctrl+V pastes (in addition to Shift+Insert
# and Ctrl+Shift+V). Ctrl+C is NOT touched: it keeps interrupting processes,
# because foot can't "copy only if there is a selection"; to copy, use
# Ctrl+Shift+C or Super+C.
# Side effect: foot consumes Ctrl+V, so terminal apps that use Ctrl+V for
# themselves (vim in block mode, pasting images in some CLIs) stop receiving it.
# foot does not reload its configuration live: it only applies to new windows.
set -euo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=../../lib/common.sh
source "$DIR/../../lib/common.sh"

NAME="terminal-ctrl-v"
FOOT_FILE="$HOME/.config/foot/foot.ini"

has_line() { grep -q '^clipboard-paste=' "$FOOT_FILE" 2>/dev/null; }
has_binding() { grep -qE '^clipboard-paste=(.* )?Control\+v( |$)' "$FOOT_FILE" 2>/dev/null; }

cmd_name() { echo "Terminal (foot): Ctrl+V pastes"; }

cmd_description() {
  echo "Ctrl+V pastes in foot (in addition to Shift+Insert and Ctrl+Shift+V). Ctrl+C still interrupts; copy with Ctrl+Shift+C or Super+C. New windows only; vim block mode and image pasting in some CLIs stop receiving Ctrl+V."
}

cmd_status() {
  if has_binding; then
    echo "installed"
  else
    echo "not-installed"
  fi
}

cmd_install() {
  if [ ! -f "$FOOT_FILE" ] || ! has_line; then
    echo "Could not find the 'clipboard-paste=' line in $FOOT_FILE; no changes were made." >&2
    exit 1
  fi
  if has_binding; then
    echo "Already installed."
    return 0
  fi
  common::backup_once "$FOOT_FILE"
  sed -i -E 's|^(clipboard-paste=.*)$|\1 Control+v|' "$FOOT_FILE"
  echo "Installed: Ctrl+V pastes in foot. Open a new terminal to try it."
}

cmd_uninstall() {
  if [ -f "$FOOT_FILE" ]; then
    sed -i -E '/^clipboard-paste=/{s/ Control\+v( |$)/\1/;s/=Control\+v /=/}' "$FOOT_FILE"
  fi
  echo "Uninstalled: Ctrl+V reaches terminal apps again (new windows)."
}

cmd_configure() {
  echo "This improvement has no options: it is only installed or uninstalled."
}

case "${1:-}" in
name) cmd_name ;;
description) cmd_description ;;
status) cmd_status ;;
install) cmd_install ;;
uninstall) cmd_uninstall ;;
configure) cmd_configure ;;
*)
  echo "Usage: $0 {name|description|status|install|uninstall|configure}" >&2
  exit 1
  ;;
esac
