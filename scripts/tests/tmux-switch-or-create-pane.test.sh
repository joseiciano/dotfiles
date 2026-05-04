#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/tmux-switch-or-create-pane.sh"

TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

BIN_DIR="$TEST_TMPDIR/bin"
TMUX_LOG="$TEST_TMPDIR/tmux.log"
mkdir -p "$BIN_DIR"

cat >"$BIN_DIR/tmux" <<'EOF'
#!/bin/bash
set -euo pipefail

LOG_FILE="${TMUX_LOG:?}"

case "$1" in
display-message)
  if [ "${3:-}" = '#{pane_id}' ]; then
    printf '%%1\n'
  elif [ "${3:-}" = '#{pane_current_path}' ]; then
    printf '/workspace/current\n'
  fi
  ;;
list-panes)
  printf '%%1 1.1 editor: zsh\n'
  printf '%%2 1.2 server: npm\n'
  ;;
new-window)
  printf '%s\n' "$*" >>"$LOG_FILE"
  printf '@3\n'
  ;;
switch-client|confirm-before|select-window)
  printf '%s\n' "$*" >>"$LOG_FILE"
  ;;
*)
  printf 'Unexpected tmux invocation: %s\n' "$*" >&2
  exit 1
  ;;
esac
EOF

cat >"$BIN_DIR/fzf-tmux" <<'EOF'
#!/bin/bash
set -euo pipefail
printf '%s' "${FZF_OUTPUT:-}"
EOF

chmod +x "$BIN_DIR/tmux" "$BIN_DIR/fzf-tmux"

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

assert_log_empty() {
	if [ -s "$TMUX_LOG" ]; then
		printf 'Expected empty tmux log, got:\n%s\n' "$(<"$TMUX_LOG")" >&2
		exit 1
	fi
}

run_case() {
	: >"$TMUX_LOG"
	PATH="$BIN_DIR:$PATH" TMUX_LOG="$TMUX_LOG" FZF_OUTPUT="$1" "$SCRIPT"
}

run_case $'server\n%2 1.2 server: npm\n'
assert_log_contains 'switch-client -t %2'

run_case $'docs\n'
assert_log_contains 'confirm-before -p Pane '\''docs'\'' not found. Create a new window? (y/n)'
assert_log_contains 'run-shell'
assert_log_contains '--create /workspace/current docs'

: >"$TMUX_LOG"
PATH="$BIN_DIR:$PATH" TMUX_LOG="$TMUX_LOG" "$SCRIPT" --create '/workspace/current' 'docs'
assert_log_contains 'new-window -P -F #{window_id} -n docs -c /workspace/current'
assert_log_contains 'select-window -t @3'

run_case ''
assert_log_empty

printf 'ok\n'
