#!/usr/bin/env bash
# Regression coverage for the knowledge-base skill's kb-path.sh.
#
# kb-path.sh prints $KNOWLEDGE_BASE_DIR/<key> for the git repo containing $1
# (default $PWD), without creating it. Proves:
#   1. Every spelling of one remote (scp-style, https with userinfo and a
#      trailing slash, ssh:// with a port, mixed case, .git suffix) maps to the
#      same lowercased host/path key.
#   2. origin wins over other remotes; without origin the first remote is used.
#   3. A repo with no remote maps to local/<main checkout dir name>, and a
#      linked worktree resolves to the same path as its main checkout, with and
#      without a remote. A subdirectory resolves like the repo root.
#   4. $1 defaults to $PWD.
#   5. Outside a git repo: nonzero exit, stderr message, empty stdout.
#   6. A key containing `..` is refused.
#   7. The printed directory is never created.
#
# Every repo lives in a throwaway temp dir; KNOWLEDGE_BASE_DIR always points
# inside it and global/system git config is ignored so url.insteadOf rewrites
# cannot leak in.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KB_PATH="$ROOT/setup/skills-setup/skills/knowledge-base/scripts/kb-path.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-ai-kb-path-test.XXXXXX")"
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

export KNOWLEDGE_BASE_DIR="$TMP/kb"
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

fail=0

ok() { printf 'ok   - %s\n' "$1"; }
not_ok() {
  printf 'FAIL - %s\n' "$1" >&2
  fail=1
}

# new_repo <dir> [<remote-name> <url>]...
new_repo() {
  local dir="$1"
  shift
  git init -q "$dir"
  while (( $# )); do
    git -C "$dir" remote add "$1" "$2"
    shift 2
  done
}

# new_repo_with_commit <dir>: a repo with one commit, so worktrees can be added.
new_repo_with_commit() {
  git init -q "$1"
  git -C "$1" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
}

# expect_path <description> <expected stdout> <kb-path args...>
expect_path() {
  local description="$1" expected="$2"
  shift 2
  local out status
  if out="$("$KB_PATH" "$@" 2>&1)"; then status=0; else status=$?; fi
  if [[ "$status" -eq 0 && "$out" == "$expected" ]]; then
    ok "$description"
  else
    not_ok "$description (expected exit 0 and '$expected', got exit $status: '$out')"
  fi
}

# expect_refused <description> <kb-path args...>
expect_refused() {
  local description="$1"
  shift
  local out err status
  if out="$("$KB_PATH" "$@" 2>"$TMP/stderr")"; then status=0; else status=$?; fi
  err="$(cat "$TMP/stderr")"
  if [[ "$status" -ne 0 && -z "$out" && -n "${err//[[:space:]]/}" ]]; then
    ok "$description"
  else
    not_ok "$description (expected nonzero exit, empty stdout, stderr message; got exit $status, stdout '$out', stderr '$err')"
  fi
}

# 1. Remote URL normalization: all spellings of one remote share a key.
want="$KNOWLEDGE_BASE_DIR/github.com/acme/billing"
while IFS='|' read -r name url; do
  repo="$TMP/norm-$name"
  new_repo "$repo" origin "$url"
  expect_path "normalizes $name remote ($url)" "$want" "$repo"
done <<'EOF'
scp-style-mixed-case|git@github.com:Acme/Billing.git
https-userinfo-trailing-slash|https://user@github.com/acme/billing/
ssh-url-with-port|ssh://git@github.com:22/acme/billing.git
https-plain|https://github.com/acme/billing.git
scp-style-no-user|github.com:acme/billing
https-port-and-userinfo|https://user@github.com:8443/acme/billing
EOF

repo="$TMP/norm-nested"
new_repo "$repo" origin "git@gitlab.example.com:Group/Sub/Project.git"
expect_path 'keeps nested path segments of an scp-style remote' \
  "$KNOWLEDGE_BASE_DIR/gitlab.example.com/group/sub/project" "$repo"

# 2. Remote selection.
repo="$TMP/origin-wins"
new_repo "$repo" alpha "https://github.com/acme/fork.git" \
  origin "https://github.com/acme/billing.git"
expect_path 'origin wins over an earlier-added remote' "$want" "$repo"

repo="$TMP/first-remote"
new_repo "$repo" alpha "https://github.com/acme/billing.git" \
  zeta "https://github.com/acme/other.git"
expect_path 'falls back to the first remote when there is no origin' "$want" "$repo"

# 3. No remote: local/<main checkout dir>; worktrees and subdirs agree.
main="$TMP/My-Repo"
new_repo_with_commit "$main"
git -C "$main" worktree add -q "$TMP/linked-wt" -b wt
mkdir -p "$main/sub/dir"
expect_path 'no remote maps to local/<checkout dir name>' \
  "$KNOWLEDGE_BASE_DIR/local/My-Repo" "$main"
expect_path 'linked worktree without remote resolves to the main checkout key' \
  "$KNOWLEDGE_BASE_DIR/local/My-Repo" "$TMP/linked-wt"
expect_path 'subdirectory resolves like the repo root' \
  "$KNOWLEDGE_BASE_DIR/local/My-Repo" "$main/sub/dir"

remote_main="$TMP/remote-main"
new_repo_with_commit "$remote_main"
git -C "$remote_main" remote add origin "git@github.com:Acme/Billing.git"
git -C "$remote_main" worktree add -q "$TMP/remote-wt-elsewhere" -b wt
expect_path 'linked worktree with a remote resolves to the main checkout key' \
  "$want" "$TMP/remote-wt-elsewhere"

# 4. $1 defaults to $PWD.
if out="$(cd "$main/sub" && "$KB_PATH" 2>&1)"; then status=0; else status=$?; fi
if [[ "$status" -eq 0 && "$out" == "$KNOWLEDGE_BASE_DIR/local/My-Repo" ]]; then
  ok 'defaults to the current directory when no argument is given'
else
  not_ok "defaults to the current directory (got exit $status: '$out')"
fi

# 5. Outside a git repo.
mkdir -p "$TMP/not-a-repo"
expect_refused 'outside a git repo exits nonzero with stderr only' "$TMP/not-a-repo"

# 6. Path traversal in the key.
repo="$TMP/traversal"
new_repo "$repo" origin "https://github.com/acme/../../escape"
expect_refused 'refuses a key containing ..' "$repo"

repo="$TMP/traversal-scp"
new_repo "$repo" origin "git@github.com:../escape.git"
expect_refused 'refuses an scp-style key containing ..' "$repo"

# 7. Nothing is created under the KB root.
if [[ -e "$KNOWLEDGE_BASE_DIR" ]]; then
  not_ok "kb-path created $KNOWLEDGE_BASE_DIR"
else
  ok 'never creates the knowledge-base directory'
fi

if (( fail != 0 )); then
  echo 'kb-path-test FAILED' >&2
  exit 1
fi

echo 'kb-path-test PASSED'
