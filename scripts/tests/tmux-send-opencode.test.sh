#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SEND_SCRIPT="$REPO_ROOT/scripts/tmux/send-opencode.sh"

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

option_file() {
  printf '%s/%s\n' "$STATE_DIR" "${1#@}"
}

option_value() {
  local file
  file="$(option_file "$1")"

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

filter_target() {
  local filter="$1"

  case "$filter" in
    '#{==:#{pane_id},'*)
      filter="${filter#\#\{==:\#\{pane_id\},}"
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

paste_target_fails() {
  case " ${FAIL_PASTE_TARGETS:-} " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

case "$1" in
  display-message)
    if [ "${2:-}" = '-p' ] && [ "${3:-}" = '#{pane_id}' ]; then
      printf '%s\n' "${CURRENT_PANE:-%1}"
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '-t' ] && [ "${5:-}" = '#{pane_id}' ] && ! target_missing "${4:-}"; then
      printf '%s\n' "${4:-}"
    elif [ "${2:-}" = '-p' ] && [ "${3:-}" = '-t' ] && [ "${5:-}" = '#{pane_current_path}' ]; then
      printf '%s\n' "${PANE_PATH:-/workspace/current}"
    else
      exit 1
    fi
    ;;
  show-options)
    option_value "${3:-}"
    ;;
  set-option)
    printf '%s\n' "$*" >>"$LOG_FILE"

    if [ "${2:-}" = '-gu' ]; then
      rm -f "$(option_file "${3:-}")"
    elif [ "${2:-}" = '-gq' ]; then
      printf '%s' "${4:-}" >"$(option_file "${3:-}")"
    fi
    ;;
  list-panes)
    if [ "${2:-}" = '-a' ] && [ "${3:-}" = '-f' ]; then
      target="$(filter_target "${4:-}")"
      if [ -n "$target" ] && ! target_missing "$target"; then
        printf '%s\n' "$target"
      fi
    else
      print_filtered_items "${LIST_PANES:-%1}" ''
    fi
    ;;
  split-window)
    printf '%s\n' "$*" >>"$LOG_FILE"
    printf '%s\n' "${SPLIT_PANE_ID:-%9}"
    ;;
  set-buffer|send-keys)
    printf '%s\n' "$*" >>"$LOG_FILE"
    ;;
  paste-buffer)
    printf '%s\n' "$*" >>"$LOG_FILE"

    if [ "${2:-}" = '-d' ] && [ "${3:-}" = '-p' ] && [ "${4:-}" = '-b' ] && [ "${6:-}" = '-t' ] && paste_target_fails "${7:-}"; then
      printf "can't find pane: %s\n" "${7:-}" >&2
      exit 1
    fi
    ;;
  kill-session)
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

: >"$TMUX_LOG"
printf '%s' '%9' >"$TMUX_STATE_DIR/opencode_pane"
printf 'line 1\nline 2' | PATH="$BIN_DIR:$PATH" TMUX_LOG="$TMUX_LOG" TMUX_STATE_DIR="$TMUX_STATE_DIR" LIST_PANES=$'%1\n%9' bash "$SEND_SCRIPT"
assert_log_contains 'set-buffer -b opencode-send-buffer -- line 1'
assert_log_contains 'paste-buffer -d -p -b opencode-send-buffer -t %9'
assert_log_lacks 'send-keys -t %9 Enter'

: >"$TMUX_LOG"
rm -f "$TMUX_STATE_DIR/opencode_pane"
printf 'line 1' | PATH="$BIN_DIR:$PATH" TMUX_LOG="$TMUX_LOG" TMUX_STATE_DIR="$TMUX_STATE_DIR" bash "$SEND_SCRIPT"
assert_log_contains 'split-window -h -P -F #{pane_id} -t %1 -c /workspace/current opencode'
assert_log_contains 'set-option -gq @opencode_pane %9'
assert_log_contains 'set-option -gq @opencode_mode split'
assert_log_contains 'paste-buffer -d -p -b opencode-send-buffer -t %9'
assert_log_lacks 'send-keys -t %9 Enter'

: >"$TMUX_LOG"
printf '%s' '%7' >"$TMUX_STATE_DIR/opencode_pane"
printf 'line 1' | PATH="$BIN_DIR:$PATH" TMUX_LOG="$TMUX_LOG" TMUX_STATE_DIR="$TMUX_STATE_DIR" MISSING_PANES='%7' bash "$SEND_SCRIPT"
assert_log_contains 'set-option -gu @opencode_pane'
assert_log_contains 'split-window -h -P -F #{pane_id} -t %1 -c /workspace/current opencode'
assert_log_contains 'paste-buffer -d -p -b opencode-send-buffer -t %9'
assert_log_lacks 'paste-buffer -d -p -b opencode-send-buffer -t %7'
assert_log_lacks 'send-keys -t %9 Enter'

: >"$TMUX_LOG"
printf '%s' '%15' >"$TMUX_STATE_DIR/opencode_pane"
printf 'line 1' | PATH="$BIN_DIR:$PATH" TMUX_LOG="$TMUX_LOG" TMUX_STATE_DIR="$TMUX_STATE_DIR" FAIL_PASTE_TARGETS='%15' LIST_PANES=$'%1\n%15' SPLIT_PANE_ID='%16' bash "$SEND_SCRIPT"
assert_log_contains 'paste-buffer -d -p -b opencode-send-buffer -t %15'
assert_log_contains 'set-option -gu @opencode_pane'
assert_log_contains 'split-window -h -P -F #{pane_id} -t %1 -c /workspace/current opencode'
assert_log_contains 'set-option -gq @opencode_pane %16'
assert_log_contains 'set-option -gq @opencode_mode split'
assert_log_contains 'paste-buffer -d -p -b opencode-send-buffer -t %16'

printf 'ok\n'
