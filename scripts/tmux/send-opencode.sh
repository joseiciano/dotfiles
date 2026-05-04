#!/bin/bash

set -euo pipefail

pane_exists() {
	[ -n "$1" ] && tmux display-message -p -t "$1" '#{pane_id}' >/dev/null 2>&1
}

get_tracked_pane() {
	pane=$(tmux show-options -wqv '@toggle_opencode_pane' 2>/dev/null)

	if pane_exists "$pane"; then
		printf '%s\n' "$pane"
	else
		[ -n "$pane" ] && tmux set-option -wu '@toggle_opencode_pane' >/dev/null 2>&1
	fi
}

ensure_opencode_pane() {
	opencode_pane=$(get_tracked_pane)
	if [ -n "$opencode_pane" ]; then
		printf '%s\n' "$opencode_pane"
		return
	fi

	script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
	"$script_dir/toggle-opencode.sh"

	opencode_pane=$(get_tracked_pane)
	if [ -n "$opencode_pane" ]; then
		printf '%s\n' "$opencode_pane"
		return
	fi

	printf 'Failed to open opencode pane\n' >&2
	exit 1
}

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

	tmux set-option -wu '@toggle_opencode_pane' >/dev/null 2>&1
	opencode_pane=$(ensure_opencode_pane)
	paste_selection "$opencode_pane"
}

main "$@"
