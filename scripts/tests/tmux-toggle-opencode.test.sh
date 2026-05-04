#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OPENCODE_SCRIPT="$REPO_ROOT/scripts/tmux/toggle-opencode.sh"

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
PANE_PATH="${PANE_PATH:-/workspace/current}"
LIST_PANES="${LIST_PANES:-%1}"
SPLIT_PANE_ID="${SPLIT_PANE_ID:-%9}"

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
    @toggle_opencode_pane)
      printf '%s' "${TOGGLE_OPENCODE_PANE:-}"
      ;;
  esac
}

case "$1" in
  display-message)
    if [ "${2:-}" = '-p' ] && [ "${3:-}" = '#{pane_id}' ]; then
      printf '%s\n' "$CURRENT_PANE"
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '-t' ] && [ "${5:-}" = '#{pane_current_path}' ]; then
      printf '%s\n' "$PANE_PATH"
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '-t' ] && [ "${5:-}" = '#{pane_id}' ]; then
      printf '%s\n' "${4:-}"
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
  kill-pane)
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
	PATH="$BIN_DIR:$PATH" TMUX_LOG="$TMUX_LOG" bash "$OPENCODE_SCRIPT"
}

run_script
assert_log_contains 'split-window -h -P -F #{pane_id} -t %1 -c /workspace/current opencode'
assert_log_contains 'set-option -wq @toggle_opencode_pane %9'

: >"$TMUX_LOG"
PATH="$BIN_DIR:$PATH" TMUX_LOG="$TMUX_LOG" TOGGLE_OPENCODE_PANE='%9' bash "$OPENCODE_SCRIPT"
assert_log_contains 'kill-pane -t %9'
assert_log_contains 'set-option -wu @toggle_opencode_pane'

printf 'ok\n'
