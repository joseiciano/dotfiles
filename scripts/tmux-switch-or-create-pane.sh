#!/bin/bash

set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

create_pane() {
  local current_path="$1"
  local query="$2"
  local new_window

  new_window="$(tmux new-window -P -F '#{window_id}' -n "$query" -c "$current_path")"
  tmux select-window -t "$new_window"
}

main() {
  local current_pane current_path pane_list line result query selected_line selected_pane line_number
  local create_command current_path_q query_q script_path_q

  if [ "${1:-}" = "--create" ]; then
    if [ "$#" -ne 3 ]; then
      printf 'Usage: %s --create <path> <title>\n' "$0" >&2
      exit 1
    fi

    create_pane "$2" "$3"
    return 0
  fi

  current_pane="$(tmux display-message -p '#{pane_id}')"
  current_path="$(tmux display-message -p '#{pane_current_path}')"

  pane_list=""
  while IFS= read -r line; do
    case "$line" in
    "$current_pane "*) ;;
    *)
      pane_list+="$line"$'\n'
      ;;
    esac
  done < <(tmux list-panes -s -F '#{pane_id} #{window_index}.#{pane_index} #{window_name}: #{pane_title} #{pane_current_command}')

  result="$({ printf '%s' "$pane_list"; } | fzf-tmux -p 80%,60% --reverse --with-nth=2.. --bind 'enter:accept' --print-query --exit-0 || true)"

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

  selected_pane="${selected_line%% *}"

  if [ -n "$selected_line" ] && [ -n "$selected_pane" ]; then
    tmux switch-client -t "$selected_pane"
    return 0
  fi

  if [ -z "$query" ]; then
    return 0
  fi

  printf -v current_path_q '%q' "$current_path"
  printf -v query_q '%q' "$query"
  printf -v script_path_q '%q' "$SCRIPT_PATH"
  create_command="run-shell \"$script_path_q --create $current_path_q $query_q\""

  tmux confirm-before -p "Pane '$query' not found. Create a new window? (y/n)" "$create_command"
}

main "$@"
