#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/opencode-common.sh"

paste_selection() {
	tmux paste-buffer -d -p -b opencode-send-buffer -t "$1"
}

main() {
	selection=$(cat)
	[ -n "$selection" ] || exit 0

	tmux set-buffer -b opencode-send-buffer -- "$selection"

	opencode_pane=$(ensure_opencode_pane)
	if paste_selection "$opencode_pane" 2>/dev/null; then
		return
	fi

	clear_opencode_state
	opencode_pane=$(ensure_opencode_pane)
	paste_selection "$opencode_pane"
}

main "$@"
