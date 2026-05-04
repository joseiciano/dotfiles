#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ATTACHED_SCRIPT="$REPO_ROOT/scripts/tmux/toggle-opencode-attached.sh"

TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

BIN_DIR="$TEST_TMPDIR/bin"
TMUX_LOG="$TEST_TMPDIR/tmux.log"
mkdir -p "$BIN_DIR"

cat >"$BIN_DIR/tmux" <<'EOF'
#!/bin/bash
set -euo pipefail

LOG_FILE="${TMUX_LOG:?}"
CURRENT_PANE="${CURRENT_PANE:-%1}"
CURRENT_WINDOW="${CURRENT_WINDOW:-@1}"
PANE_PATH="${PANE_PATH:-/workspace/current}"
LIST_PANES="${LIST_PANES:-%1}"
SPLIT_PANE_ID="${SPLIT_PANE_ID:-%9}"
HOLDER_WINDOW_ID="${HOLDER_WINDOW_ID:-@8}"

option_value() {
  case "$1" in
    @toggle_right_pane)
      printf '%s' "${TOGGLE_RIGHT_PANE:-}"
      ;;
    @toggle_bottom_pane)
      printf '%s' "${TOGGLE_BOTTOM_PANE:-}"
      ;;
    @toggle_main_pane)
      printf '%s' "${TOGGLE_MAIN_PANE:-}"
      ;;
    @toggle_opencode_attached_pane)
      printf '%s' "${TOGGLE_OPENCODE_ATTACHED_PANE:-}"
      ;;
    @toggle_opencode_attached_holder_window)
      printf '%s' "${TOGGLE_OPENCODE_ATTACHED_HOLDER_WINDOW:-}"
      ;;
  esac
}

case "$1" in
  display-message)
    if [ "${2:-}" = '-p' ] && [ "${3:-}" = '#{pane_id}' ]; then
      printf '%s\n' "$CURRENT_PANE"
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '#{window_id}' ]; then
      printf '%s\n' "$CURRENT_WINDOW"
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '-t' ] && [ "${5:-}" = '#{pane_current_path}' ]; then
      printf '%s\n' "$PANE_PATH"
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '-t' ] && [ "${5:-}" = '#{pane_id}' ]; then
      printf '%s\n' "${4:-}"
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '-t' ] && [ "${5:-}" = '#{window_id}' ]; then
      if [ "${4:-}" = "${HOLDER_WINDOW_ID:-}" ] && [ -n "${TOGGLE_OPENCODE_ATTACHED_HOLDER_WINDOW:-}" ]; then
        printf '%s\n' "${HOLDER_WINDOW_ID:-}"
      elif [ "${4:-}" = "${TOGGLE_OPENCODE_ATTACHED_PANE:-}" ]; then
        printf '%s\n' "${OPENCODE_PANE_WINDOW:-$CURRENT_WINDOW}"
      else
        printf '%s\n' "$CURRENT_WINDOW"
      fi
    else
      printf 'Unexpected display-message invocation: %s\n' "$*" >&2
      exit 1
    fi
    ;;
  show-options)
    option_value "${3:-}"
    ;;
  set-option)
    printf '%s\n' "$*" >>"$LOG_FILE"
    ;;
  list-panes)
    printf '%s\n' "$LIST_PANES"
    ;;
  split-window)
    printf '%s\n' "$*" >>"$LOG_FILE"
    printf '%s\n' "$SPLIT_PANE_ID"
    ;;
  break-pane)
    printf '%s\n' "$*" >>"$LOG_FILE"
    printf '%s\n' "$HOLDER_WINDOW_ID"
    ;;
  join-pane)
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

assert_log_lacks() {
	local unexpected="$1"
	local log_contents=""

	if [ -f "$TMUX_LOG" ]; then
		log_contents="$(<"$TMUX_LOG")"
	fi

	case "$log_contents" in
	*"$unexpected"*)
		printf 'Expected tmux log not to contain: %s\n' "$unexpected" >&2
		printf 'Actual tmux log:\n%s\n' "$log_contents" >&2
		exit 1
		;;
	*) ;;
	esac
}

run_script() {
	: >"$TMUX_LOG"
	PATH="$BIN_DIR:$PATH" TMUX_LOG="$TMUX_LOG" bash "$ATTACHED_SCRIPT"
}

run_script
assert_log_contains 'split-window -h -P -F #{pane_id} -t %1 -c /workspace/current opencode'
assert_log_contains 'set-option -gq @toggle_opencode_attached_pane %9'

: >"$TMUX_LOG"
PATH="$BIN_DIR:$PATH" TMUX_LOG="$TMUX_LOG" TOGGLE_OPENCODE_ATTACHED_PANE='%9' OPENCODE_PANE_WINDOW='@1' bash "$ATTACHED_SCRIPT"
assert_log_contains 'break-pane -dP -F #{window_id} -s %9 -n __opencode_attached__'
assert_log_contains 'set-option -gq @toggle_opencode_attached_holder_window @8'
assert_log_lacks 'set-option -wu @toggle_opencode_attached_pane'

: >"$TMUX_LOG"
PATH="$BIN_DIR:$PATH" TMUX_LOG="$TMUX_LOG" TOGGLE_OPENCODE_ATTACHED_PANE='%9' TOGGLE_OPENCODE_ATTACHED_HOLDER_WINDOW='@8' OPENCODE_PANE_WINDOW='@8' CURRENT_WINDOW='@8' bash "$ATTACHED_SCRIPT"
assert_log_lacks 'split-window -h -P -F #{pane_id} -t %1 -c /workspace/current opencode'
assert_log_lacks 'break-pane -dP -F #{window_id} -s %9 -n __opencode_attached__'
assert_log_lacks 'join-pane -d -h -s %9 -t %1'

: >"$TMUX_LOG"
PATH="$BIN_DIR:$PATH" TMUX_LOG="$TMUX_LOG" TOGGLE_OPENCODE_ATTACHED_PANE='%9' TOGGLE_OPENCODE_ATTACHED_HOLDER_WINDOW='@8' OPENCODE_PANE_WINDOW='@8' CURRENT_WINDOW='@1' bash "$ATTACHED_SCRIPT"
assert_log_contains 'join-pane -d -h -s %9 -t %1'
assert_log_contains 'set-option -gu @toggle_opencode_attached_holder_window'

printf 'ok\n'
