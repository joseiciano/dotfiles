#!/bin/bash

set -euo pipefail

pane_exists() {
	[ -n "$1" ] && tmux display-message -p -t "$1" '#{pane_id}' >/dev/null 2>&1
}

window_exists() {
	[ -n "$1" ] && tmux display-message -p -t "$1" '#{window_id}' >/dev/null 2>&1
}

get_window_tracked_pane() {
	pane=$(tmux show-options -wqv "$1" 2>/dev/null)

	if pane_exists "$pane"; then
		printf '%s\n' "$pane"
	else
		[ -n "$pane" ] && tmux set-option -wu "$1" >/dev/null 2>&1
	fi

	return 0
}

get_global_tracked_pane() {
	pane=$(tmux show-options -gqv "$1" 2>/dev/null)

	if pane_exists "$pane"; then
		printf '%s\n' "$pane"
	else
		[ -n "$pane" ] && tmux set-option -gu "$1" >/dev/null 2>&1
	fi

	return 0
}

get_global_tracked_window() {
	window=$(tmux show-options -gqv "$1" 2>/dev/null)

	if window_exists "$window"; then
		printf '%s\n' "$window"
	else
		[ -n "$window" ] && tmux set-option -gu "$1" >/dev/null 2>&1
	fi

	return 0
}

get_main_pane() {
	current_pane=$(tmux display-message -p '#{pane_id}')
	right_pane=$(get_window_tracked_pane '@toggle_right_pane')
	bottom_pane=$(get_window_tracked_pane '@toggle_bottom_pane')
	main_pane=$(get_window_tracked_pane '@toggle_main_pane')

	if [ -n "$main_pane" ] && [ "$main_pane" != "$right_pane" ] && [ "$main_pane" != "$bottom_pane" ]; then
		printf '%s\n' "$main_pane"
		return
	fi

	if [ "$current_pane" != "$right_pane" ] && [ "$current_pane" != "$bottom_pane" ]; then
		main_pane=$current_pane
	else
		main_pane=$(tmux list-panes -F '#{pane_id}' | awk -v right="$right_pane" -v bottom="$bottom_pane" '$1 != right && $1 != bottom { print; exit }')
	fi

	[ -n "$main_pane" ] && tmux set-option -wq '@toggle_main_pane' "$main_pane"
	printf '%s\n' "$main_pane"
}

main() {
	opencode_pane=$(get_global_tracked_pane '@toggle_opencode_attached_pane')

	if [ -z "$opencode_pane" ]; then
		main_pane=$(get_main_pane)
		[ -n "$main_pane" ] || exit 1

		pane_path=$(tmux display-message -p -t "$main_pane" '#{pane_current_path}')
		opencode_pane=$(tmux split-window -h -P -F '#{pane_id}' -t "$main_pane" -c "$pane_path" opencode)
		tmux set-option -gq '@toggle_opencode_attached_pane' "$opencode_pane"
		return
	fi

	current_window=$(tmux display-message -p '#{window_id}')
	pane_window=$(tmux display-message -p -t "$opencode_pane" '#{window_id}')
	holder_window=$(get_global_tracked_window '@toggle_opencode_attached_holder_window')

	if [ -n "$holder_window" ] && [ "$current_window" = "$holder_window" ] && [ "$pane_window" = "$holder_window" ]; then
		return
	fi

	if [ "$pane_window" = "$current_window" ]; then
		holder_window=$(tmux break-pane -dP -F '#{window_id}' -s "$opencode_pane" -n '__opencode_attached__')
		tmux set-option -gq '@toggle_opencode_attached_holder_window' "$holder_window"
		return
	fi

	main_pane=$(get_main_pane)
	[ -n "$main_pane" ] || exit 1
	tmux join-pane -d -h -s "$opencode_pane" -t "$main_pane"
	tmux set-option -gu '@toggle_opencode_attached_holder_window' >/dev/null 2>&1
}

main "$@"
