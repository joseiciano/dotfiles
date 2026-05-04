#!/bin/bash

set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

create_session() {
	local current_path="$1"
	local session_name="$2"
	local new_session

	new_session="$(tmux new-session -d -P -F '#{session_id}' -s "$session_name" -c "$current_path")"
	tmux switch-client -t "$new_session"
}

main() {
	local current_path session_list result query selected_line selected_session line_number line
	local create_command current_path_q query_q script_path_q

	if [ "${1:-}" = "--create" ]; then
		if [ "$#" -ne 3 ]; then
			printf 'Usage: %s --create <path> <session-name>\n' "$0" >&2
			exit 1
		fi

		create_session "$2" "$3"
		return 0
	fi

	current_path="$(tmux display-message -p '#{pane_current_path}')"

	session_list="$(tmux list-sessions -F '#{session_id} #{session_name} (#{session_windows} windows)')"

	result="$({ printf '%s' "$session_list"; } | fzf-tmux -p 80%,60% --reverse --with-nth=2.. --bind 'enter:accept' --print-query --exit-0 || true)"

	query=""
	selected_line=""
	line_number=0
	while IFS= read -r line || [ -n "$line" ]; do
		if [ "$line_number" -eq 0 ]; then
			query="$line"
		elif [ "$line_number" -eq 1 ]; then
			selected_line="$line"
			break
		fi

		line_number=$((line_number + 1))
	done <<<"$result"

	selected_session="${selected_line%% *}"

	if [ -n "$selected_line" ] && [ -n "$selected_session" ]; then
		tmux switch-client -t "$selected_session"
		return 0
	fi

	if [ -z "$query" ]; then
		return 0
	fi

	if tmux has-session -t "=$query" 2>/dev/null; then
		tmux switch-client -t "=$query"
		return 0
	fi

	printf -v current_path_q '%q' "$current_path"
	printf -v query_q '%q' "$query"
	printf -v script_path_q '%q' "$SCRIPT_PATH"
	create_command="run-shell \"$script_path_q --create $current_path_q $query_q\""

	tmux confirm-before -p "Session '$query' not found. Create it? (y/n)" "$create_command"
}

main "$@"
