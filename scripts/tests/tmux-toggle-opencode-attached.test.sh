#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ATTACHED_SCRIPT="$REPO_ROOT/scripts/tmux/toggle-opencode-attached.sh"

TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

BIN_DIR="$TEST_TMPDIR/bin"
TMUX_LOG="$TEST_TMPDIR/tmux.log"
TMUX_STATE_DIR="$TEST_TMPDIR/state"
mkdir -p "$BIN_DIR" "$TMUX_STATE_DIR"

cat >"$BIN_DIR/tmux" <<'EOF'
#!/bin/bash
set -euo pipefail

LOG_FILE="${TMUX_LOG:?}"
STATE_DIR="${TMUX_STATE_DIR:?}"
CURRENT_PANE="${CURRENT_PANE:-%1}"
CURRENT_WINDOW="${CURRENT_WINDOW:-@1}"
PANE_PATH="${PANE_PATH:-/workspace/current}"
LIST_PANES="${LIST_PANES:-%1}"
LIST_WINDOWS="${LIST_WINDOWS:-@1}"
CURRENT_SESSION="${CURRENT_SESSION:-main}"
SPLIT_PANE_ID="${SPLIT_PANE_ID:-%9}"
BREAK_WINDOW_ID="${BREAK_WINDOW_ID:-@20}"

option_file() {
  printf '%s/%s_%s\n' "$STATE_DIR" "$1" "${2#@}"
}

option_value() {
  local scope="$1"
  local file
  file="$(option_file "$scope" "$2")"

  if [ -f "$file" ]; then
    <"$file" tr -d '\n'
  fi
}

target_missing() {
  case " ${MISSING_PANES:-} " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

window_missing() {
  case " ${MISSING_WINDOWS:-} " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

session_missing() {
  case " ${MISSING_SESSIONS:-} " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

value_after_flag() {
  local flag="$1"
  shift
  local arg

  while [ "$#" -gt 0 ]; do
    arg="$1"
    shift

    if [ "$arg" = "$flag" ]; then
      printf '%s\n' "${1:-}"
      return 0
    fi
  done

  return 1
}

filter_target() {
  local filter="$1"

  case "$filter" in
    '#{==:#{pane_id},'*)
      filter="${filter#\#\{==:\#\{pane_id\},}"
      printf '%s\n' "${filter%\}}"
      ;;
    '#{==:#{window_id},'*)
      filter="${filter#\#\{==:\#\{window_id\},}"
      printf '%s\n' "${filter%\}}"
      ;;
  esac
}

print_filtered_items() {
  local items="$1"
  local filter="$2"
  local target=""
  local item

  if [ -n "$filter" ]; then
    target="$(filter_target "$filter")"
  fi

  while IFS= read -r item; do
    [ -n "$item" ] || continue

    if [ -z "$target" ] || [ "$item" = "$target" ]; then
      printf '%s\n' "$item"
    fi
  done <<ITEMS
$items
ITEMS
}

pane_window() {
  while IFS=' ' read -r pane window; do
    [ -n "${pane:-}" ] || continue
    if [ "$pane" = "$1" ]; then
      printf '%s\n' "$window"
      return 0
    fi
  done <<MAP
${PANE_WINDOW_MAP:-}
MAP

  printf '%s\n' "$CURRENT_WINDOW"
}

pane_session() {
  while IFS=' ' read -r pane session; do
    [ -n "${pane:-}" ] || continue
    if [ "$pane" = "$1" ]; then
      printf '%s\n' "$session"
      return 0
    fi
  done <<MAP
${PANE_SESSION_MAP:-}
MAP

  printf '%s\n' "$CURRENT_SESSION"
}

option_file_for_pane() {
  printf '%s/pane_%s_%s\n' "$STATE_DIR" "$1" "${2#%}"
}

case "$1" in
  display-message)
    if [ "${2:-}" = '-p' ] && [ "${3:-}" = '#{pane_id}' ]; then
      printf '%s\n' "$CURRENT_PANE"
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '#{window_id}' ]; then
      printf '%s\n' "$CURRENT_WINDOW"
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '#{session_name}' ]; then
      printf '%s\n' "$CURRENT_SESSION"
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '-t' ] && [ "${5:-}" = '#{pane_current_path}' ]; then
      printf '%s\n' "$PANE_PATH"
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '-t' ] && [ "${5:-}" = '#{pane_id}' ]; then
      if ! target_missing "${4:-}"; then
        printf '%s\n' "${4:-}"
      fi
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '-t' ] && [ "${5:-}" = '#{session_name}' ]; then
      if [[ "${4:-}" == %* ]] && ! target_missing "${4:-}"; then
        pane_session "${4:-}"
      elif ! session_missing "${4:-}"; then
        printf '%s\n' "${4:-}"
      fi
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '-t' ] && [ "${5:-}" = '#{window_id}' ]; then
      if [[ "${4:-}" == %* ]] && ! target_missing "${4:-}"; then
        pane_window "${4:-}"
      elif [[ "${4:-}" == @* ]] && ! window_missing "${4:-}"; then
        printf '%s\n' "${4:-}"
      fi
    else
      printf 'Unexpected display-message invocation: %s\n' "$*" >&2
      exit 1
    fi
    ;;
  show-options)
    case "${2:-}" in
      -gqv) option_value global "${3:-}" ;;
      -wqv) option_value window "${3:-}" ;;
      *) printf 'Unexpected show-options invocation: %s\n' "$*" >&2; exit 1 ;;
    esac
    ;;
  set-option)
    printf '%s\n' "$*" >>"$LOG_FILE"

    case "${2:-}" in
      -gq) printf '%s' "${4:-}" >"$(option_file global "${3:-}")" ;;
      -gu) rm -f "$(option_file global "${3:-}")" ;;
      -wq) printf '%s' "${4:-}" >"$(option_file window "${3:-}")" ;;
      -wu) rm -f "$(option_file window "${3:-}")" ;;
    esac
    ;;
  list-panes)
    if [ "${2:-}" = '-a' ] && [ "${3:-}" = '-f' ]; then
      print_filtered_items "$LIST_PANES" "${4:-}"
    else
      print_filtered_items "$LIST_PANES" ''
    fi
    ;;
  list-windows)
    if [ "${2:-}" = '-a' ] && [ "${3:-}" = '-f' ]; then
      print_filtered_items "$LIST_WINDOWS" "${4:-}"
    else
      print_filtered_items "$LIST_WINDOWS" ''
    fi
    ;;
  split-window)
    printf '%s\n' "$*" >>"$LOG_FILE"
    printf '%s\n' "$CURRENT_WINDOW" >"$(option_file pane_window "$SPLIT_PANE_ID")"
    printf '%s\n' "$CURRENT_SESSION" >"$(option_file_for_pane session "$SPLIT_PANE_ID")"
    printf '%s\n' "$SPLIT_PANE_ID"
    ;;
  has-session)
    target="$(value_after_flag -t "$@")"
    if [ -n "$target" ] && [ -f "$STATE_DIR/session_$target" ] && ! session_missing "$target"; then
      exit 0
    fi

    exit 1
    ;;
  new-session)
    printf '%s\n' "$*" >>"$LOG_FILE"
    target="$(value_after_flag -s "$@")"
    [ -n "$target" ] || exit 1
    : >"$STATE_DIR/session_$target"
    ;;
  break-pane)
    printf '%s\n' "$*" >>"$LOG_FILE"
    pane="$(value_after_flag -s "$@")"
    target="$(value_after_flag -t "$@")"
    target="${target%:}"
    printf '%s\n' "$BREAK_WINDOW_ID" >"$(option_file pane_window "$pane")"
    printf '%s\n' "$target" >"$(option_file_for_pane session "$pane")"
    ;;
  join-pane)
    printf '%s\n' "$*" >>"$LOG_FILE"
    pane="$(value_after_flag -s "$@")"
    printf '%s\n' "$CURRENT_WINDOW" >"$(option_file pane_window "$pane")"
    printf '%s\n' "$CURRENT_SESSION" >"$(option_file_for_pane session "$pane")"
    ;;
  kill-session)
    printf '%s\n' "$*" >>"$LOG_FILE"
    target="$(value_after_flag -t "$@")"
    rm -f "$STATE_DIR/session_$target"
    ;;
  kill-window)
    printf '%s\n' "$*" >>"$LOG_FILE"
    ;;
  *)
    printf 'Unexpected tmux invocation: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF

chmod +x "$BIN_DIR/tmux"

assert_log_contains() {
	local expected="$1"
	local log_contents=""

	if [ -f "$TMUX_LOG" ]; then
		log_contents="$(<"$TMUX_LOG")"
	fi

	case "$log_contents" in
	*"$expected"*) ;;
	*)
		printf 'Expected tmux log to contain: %s\n' "$expected" >&2
		printf 'Actual tmux log:\n%s\n' "$log_contents" >&2
		exit 1
		;;
	esac
}

run_script() {
	: >"$TMUX_LOG"
	PATH="$BIN_DIR:$PATH" TMUX_LOG="$TMUX_LOG" TMUX_STATE_DIR="$TMUX_STATE_DIR" "$@" bash "$ATTACHED_SCRIPT"
}

run_script env
assert_log_contains 'split-window -h -P -F #{pane_id} -t %1 -c /workspace/current opencode'
assert_log_contains 'set-option -gq @opencode_pane %9'
assert_log_contains 'set-option -gq @opencode_mode attached'

printf '%s' '%9' >"$TMUX_STATE_DIR/global_opencode_pane"
printf '%s' 'split' >"$TMUX_STATE_DIR/global_opencode_mode"
run_script env PANE_WINDOW_MAP='%9 @20' PANE_SESSION_MAP='%9 __opencode_holder__' LIST_PANES=$'%1\n%9' LIST_WINDOWS=$'@1\n@20'
assert_log_contains 'join-pane -d -h -s %9 -t %1'
assert_log_contains 'kill-session -t __opencode_holder__'
assert_log_contains 'set-option -gq @opencode_mode attached'

printf '%s' '%11' >"$TMUX_STATE_DIR/global_toggle_opencode_attached_pane"
printf '%s' '@21' >"$TMUX_STATE_DIR/global_toggle_opencode_attached_holder_window"
run_script env PANE_WINDOW_MAP='%11 @21' LIST_PANES=$'%1\n%11' LIST_WINDOWS=$'@1\n@21'
assert_log_contains 'join-pane -d -h -s %11 -t %1'
assert_log_contains 'set-option -gu @toggle_opencode_attached_holder_window'
assert_log_contains 'set-option -gq @opencode_mode attached'

printf 'ok\n'
