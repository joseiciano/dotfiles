#!/bin/bash

set -euo pipefail

OPENCODE_PANE_KEY='@opencode_pane'
OPENCODE_MODE_KEY='@opencode_mode'
OPENCODE_LEGACY_HOLDER_WINDOW_KEY='@opencode_holder_window'
OPENCODE_LEGACY_SPLIT_PANE_KEY='@toggle_opencode_pane'
OPENCODE_LEGACY_ATTACHED_PANE_KEY='@toggle_opencode_attached_pane'
OPENCODE_LEGACY_ATTACHED_HOLDER_WINDOW_KEY='@toggle_opencode_attached_holder_window'
OPENCODE_HOLDER_SESSION='__opencode_holder__'

pane_exists() {
	local pane match
	pane="${1:-}"
	[ -n "$pane" ] || return 1
	match=$(tmux list-panes -a -f "#{==:#{pane_id},${pane}}" -F '#{pane_id}' 2>/dev/null)
	[ "$match" = "$pane" ]
}

session_exists() {
	local session
	session="${1:-}"
	[ -n "$session" ] || return 1
	tmux has-session -t "$session" 2>/dev/null
}

window_exists() {
	local window match
	window="${1:-}"
	[ -n "$window" ] || return 1
	match=$(tmux list-windows -a -f "#{==:#{window_id},${window}}" -F '#{window_id}' 2>/dev/null)
	[ "$match" = "$window" ]
}

get_window_tracked_pane() {
	local key pane
	key="$1"
	pane=$(tmux show-options -wqv "$key" 2>/dev/null)

	if pane_exists "$pane"; then
		printf '%s\n' "$pane"
	else
		[ -n "$pane" ] && tmux set-option -wu "$key" >/dev/null 2>&1
	fi

	return 0
}

get_global_option() {
	tmux show-options -gqv "$1" 2>/dev/null
}

get_global_tracked_pane() {
	local key pane
	key="$1"
	pane=$(get_global_option "$key")

	if pane_exists "$pane"; then
		printf '%s\n' "$pane"
	else
		[ -n "$pane" ] && unset_global_option "$key"
	fi

	return 0
}

set_global_option() {
	tmux set-option -gq "$1" "$2"
}

unset_global_option() {
	tmux set-option -gu "$1" >/dev/null 2>&1
}

get_opencode_pane() {
	local pane
	pane=$(get_global_tracked_pane "$OPENCODE_PANE_KEY")
	if [ -n "$pane" ]; then
		printf '%s\n' "$pane"
		return 0
	fi

	pane=$(get_global_tracked_pane "$OPENCODE_LEGACY_ATTACHED_PANE_KEY")
	if [ -n "$pane" ]; then
		set_global_option "$OPENCODE_PANE_KEY" "$pane"
		printf '%s\n' "$pane"
		return 0
	fi

	pane=$(get_window_tracked_pane "$OPENCODE_LEGACY_SPLIT_PANE_KEY")
	if [ -n "$pane" ]; then
		set_global_option "$OPENCODE_PANE_KEY" "$pane"
		printf '%s\n' "$pane"
		return 0
	fi

	return 0
}

ensure_holder_session() {
	if ! session_exists "$OPENCODE_HOLDER_SESSION"; then
		tmux new-session -d -s "$OPENCODE_HOLDER_SESSION" -n "$OPENCODE_HOLDER_SESSION"
	fi
}

get_legacy_holder_window() {
	local window
	window=$(get_global_option "$OPENCODE_LEGACY_HOLDER_WINDOW_KEY")
	if [ -z "$window" ]; then
		window=$(get_global_option "$OPENCODE_LEGACY_ATTACHED_HOLDER_WINDOW_KEY")
	fi

	if window_exists "$window"; then
		printf '%s\n' "$window"
	else
		[ -n "$window" ] && unset_global_option "$OPENCODE_LEGACY_HOLDER_WINDOW_KEY"
		[ -n "$window" ] && unset_global_option "$OPENCODE_LEGACY_ATTACHED_HOLDER_WINDOW_KEY"
	fi

	return 0
}

destroy_holder_session() {
	tmux kill-session -t "$OPENCODE_HOLDER_SESSION" >/dev/null 2>&1 || true
}

set_opencode_mode() {
	set_global_option "$OPENCODE_MODE_KEY" "$1"
}

clear_opencode_state() {
	unset_global_option "$OPENCODE_PANE_KEY"
	unset_global_option "$OPENCODE_MODE_KEY"
	unset_global_option "$OPENCODE_LEGACY_HOLDER_WINDOW_KEY"
	unset_global_option "$OPENCODE_LEGACY_ATTACHED_PANE_KEY"
	unset_global_option "$OPENCODE_LEGACY_ATTACHED_HOLDER_WINDOW_KEY"
	tmux set-option -wu "$OPENCODE_LEGACY_SPLIT_PANE_KEY" >/dev/null 2>&1
	destroy_holder_session
}

get_main_pane() {
	local current_pane right_pane bottom_pane main_pane
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

create_opencode_pane() {
	local mode main_pane pane_path opencode_pane
	mode="$1"
	main_pane=$(get_main_pane)
	[ -n "$main_pane" ] || return 1

	pane_path=$(tmux display-message -p -t "$main_pane" '#{pane_current_path}')
	opencode_pane=$(tmux split-window -h -P -F '#{pane_id}' -t "$main_pane" -c "$pane_path" opencode)
	set_global_option "$OPENCODE_PANE_KEY" "$opencode_pane"
	unset_global_option "$OPENCODE_LEGACY_HOLDER_WINDOW_KEY"
	unset_global_option "$OPENCODE_LEGACY_ATTACHED_PANE_KEY"
	unset_global_option "$OPENCODE_LEGACY_ATTACHED_HOLDER_WINDOW_KEY"
	tmux set-option -wu "$OPENCODE_LEGACY_SPLIT_PANE_KEY" >/dev/null 2>&1
	set_opencode_mode "$mode"
	printf '%s\n' "$opencode_pane"
}

hide_opencode_pane() {
	local opencode_pane
	opencode_pane="$1"
	ensure_holder_session
	tmux break-pane -d -s "$opencode_pane" -t "$OPENCODE_HOLDER_SESSION:" -n '__opencode__'
	tmux kill-window -t "$OPENCODE_HOLDER_SESSION:$OPENCODE_HOLDER_SESSION" >/dev/null 2>&1 || true
}

show_opencode_pane() {
	local mode opencode_pane current_window current_session pane_window pane_session legacy_holder_window main_pane
	mode="$1"
	opencode_pane=$(get_opencode_pane)

	if [ -z "$opencode_pane" ]; then
		create_opencode_pane "$mode" >/dev/null
		return
	fi

	current_window=$(tmux display-message -p '#{window_id}')
	current_session=$(tmux display-message -p '#{session_name}')
	pane_window=$(tmux display-message -p -t "$opencode_pane" '#{window_id}')
	pane_session=$(tmux display-message -p -t "$opencode_pane" '#{session_name}')
	legacy_holder_window=$(get_legacy_holder_window)

	if [ "$current_session" = "$OPENCODE_HOLDER_SESSION" ] && [ "$pane_session" = "$OPENCODE_HOLDER_SESSION" ]; then
		return
	fi

	if [ -n "$legacy_holder_window" ] && [ "$current_window" = "$legacy_holder_window" ] && [ "$pane_window" = "$legacy_holder_window" ]; then
		return
	fi

	if [ "$pane_window" = "$current_window" ] && [ "$pane_session" = "$current_session" ]; then
		hide_opencode_pane "$opencode_pane"
		set_opencode_mode "$mode"
		return
	fi

	main_pane=$(get_main_pane)
	[ -n "$main_pane" ] || return 1
	tmux join-pane -d -h -s "$opencode_pane" -t "$main_pane"
	unset_global_option "$OPENCODE_LEGACY_HOLDER_WINDOW_KEY"
	unset_global_option "$OPENCODE_LEGACY_ATTACHED_PANE_KEY"
	unset_global_option "$OPENCODE_LEGACY_ATTACHED_HOLDER_WINDOW_KEY"
	tmux set-option -wu "$OPENCODE_LEGACY_SPLIT_PANE_KEY" >/dev/null 2>&1
	destroy_holder_session
	set_opencode_mode "$mode"
}

ensure_opencode_pane() {
	local script_dir opencode_pane
	opencode_pane=$(get_opencode_pane)
	if [ -n "$opencode_pane" ]; then
		printf '%s\n' "$opencode_pane"
		return
	fi

	script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
	"$script_dir/toggle-opencode.sh"

	opencode_pane=$(get_opencode_pane)
	if [ -n "$opencode_pane" ]; then
		printf '%s\n' "$opencode_pane"
		return
	fi

	printf 'Failed to open opencode pane\n' >&2
	return 1
}
