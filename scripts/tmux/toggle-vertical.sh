pane_exists() {
	[ -n "$1" ] && tmux display-message -p -t "$1" '#{pane_id}' >/dev/null 2>&1
}

get_tracked_pane() {
	pane=$(tmux show-options -wqv "$1" 2>/dev/null)

	if pane_exists "$pane"; then
		printf '%s\n' "$pane"
	else
		[ -n "$pane" ] && tmux set-option -wu "$1" >/dev/null 2>&1
	fi
}

get_main_pane() {
	current_pane=$(tmux display-message -p '#{pane_id}')
	right_pane=$(get_tracked_pane '@toggle_right_pane')
	bottom_pane=$(get_tracked_pane '@toggle_bottom_pane')
	main_pane=$(get_tracked_pane '@toggle_main_pane')

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
	split_size="${1:-}"
	bottom_pane=$(get_tracked_pane '@toggle_bottom_pane')

	if [ -n "$bottom_pane" ]; then
		tmux kill-pane -t "$bottom_pane"
		tmux set-option -wu '@toggle_bottom_pane' >/dev/null 2>&1
		return
	fi

	main_pane=$(get_main_pane)
	[ -n "$main_pane" ] || exit 1

	pane_path=$(tmux display-message -p -t "$main_pane" '#{pane_current_path}')
	if [ -n "$split_size" ]; then
		bottom_pane=$(tmux split-window -v -P -F '#{pane_id}' -t "$main_pane" -c "$pane_path" -p "$split_size")
	else
		bottom_pane=$(tmux split-window -v -P -F '#{pane_id}' -t "$main_pane" -c "$pane_path")
	fi
	tmux set-option -wq '@toggle_bottom_pane' "$bottom_pane"
}

main "$@"
