#!/usr/bin/env bash
# Regression coverage for the knowledge-base skill's kb-work.sh.
#
# kb-work.sh prints each <kb>/work/<slug>[/<module>] directory whose plan.md
# frontmatter `branches:` lists the branch checked out in $1 (default $PWD).
# Proves:
#   1. Inline lists (bare or quoted items) and block lists (bare or quoted
#      items) both match the current branch.
#   2. Module-level plans match, and a slug and its module both listing the
#      branch are both printed.
#   3. Matching is exact in both directions (feat/x vs feat/x-2).
#   4. Only frontmatter counts: a `branches:` line in the body, or in a file
#      that does not start with `---`, never matches; a block list ends at
#      the next key.
#   5. Detached HEAD and a missing <kb>/work print nothing and exit 0, even
#      when a plan would otherwise match.
#   6. Outside a git repo: nonzero exit, empty stdout.
#   7. $1 defaults to $PWD.
#   8. A linked worktree reads the main checkout's KB with its own branch.
#
# Every repo lives in a throwaway temp dir; KNOWLEDGE_BASE_DIR always points
# inside it and global/system git config is ignored so url.insteadOf rewrites
# cannot leak in.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KB_WORK="$ROOT/setup/skills-setup/skills/knowledge-base/scripts/kb-work.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-ai-kb-work-test.XXXXXX")"
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

# new_repo <dir> <branch>: a repo on <branch> with one commit and no remote,
# so its KB is $KNOWLEDGE_BASE_DIR/local/<dir name>.
new_repo() {
  git init -q -b "$2" "$1"
  git -C "$1" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
}

# write_plan <work-item dir> <plan.md contents>
write_plan() {
  mkdir -p "$1"
  printf '%s\n' "$2" >"$1/plan.md"
}

# expect_items <description> <expected stdout, sorted> <kb-work args...>
expect_items() {
  local description="$1" expected="$2"
  shift 2
  local out status
  if out="$("$KB_WORK" "$@" 2>&1)"; then status=0; else status=$?; fi
  out="$(sort <<<"$out")"
  if [[ "$status" -eq 0 && "$out" == "$expected" ]]; then
    ok "$description"
  else
    not_ok "$description (expected exit 0 and '$expected', got exit $status: '$out')"
  fi
}

# 1. Inline and block list syntax.
while IFS='|' read -r name branches; do
  repo="$TMP/syntax-$name"
  new_repo "$repo" feat/x
  write_plan "$KNOWLEDGE_BASE_DIR/local/syntax-$name/work/billing" \
    "$(printf -- '---\ntitle: Billing\n%b\n---\n# Plan' "$branches")"
  expect_items "matches $name" \
    "$KNOWLEDGE_BASE_DIR/local/syntax-$name/work/billing" "$repo"
done <<'EOF'
inline-list|branches: [main, feat/x]
inline-double-quoted|branches: ["main", "feat/x"]
inline-single-quoted|branches: ['feat/x']
block-list|branches:\n  - main\n  - feat/x
block-list-quoted|branches:\n  - "feat/x"
EOF

# 2. Module-level plans.
repo="$TMP/modules"
new_repo "$repo" feat/x
kb="$KNOWLEDGE_BASE_DIR/local/modules"
write_plan "$kb/work/billing" $'---\nbranches: [feat/x]\n---'
write_plan "$kb/work/billing/api" $'---\nbranches: [feat/x]\n---'
write_plan "$kb/work/billing/ui" $'---\nbranches: [feat/y]\n---'
write_plan "$kb/work/other" $'---\nbranches: [feat/y]\n---'
expect_items 'prints a slug and its module when both list the branch' \
  "$(printf '%s\n' "$kb/work/billing" "$kb/work/billing/api" | sort)" "$repo"

repo="$TMP/module-only"
new_repo "$repo" feat/x
kb="$KNOWLEDGE_BASE_DIR/local/module-only"
write_plan "$kb/work/billing" $'---\nbranches: [main]\n---'
write_plan "$kb/work/billing/api" $'---\nbranches:\n  - feat/x\n---'
expect_items 'prints only the module when only the module lists the branch' \
  "$kb/work/billing/api" "$repo"

# 3. Exact match only.
repo="$TMP/prefix"
new_repo "$repo" feat/x
write_plan "$KNOWLEDGE_BASE_DIR/local/prefix/work/a" $'---\nbranches: [feat/x-2]\n---'
write_plan "$KNOWLEDGE_BASE_DIR/local/prefix/work/b" $'---\nbranches:\n  - feat/x-2\n---'
expect_items 'feat/x does not match a plan listing feat/x-2' '' "$repo"

repo="$TMP/suffix"
new_repo "$repo" feat/x-2
write_plan "$KNOWLEDGE_BASE_DIR/local/suffix/work/a" $'---\nbranches: [feat/x]\n---'
write_plan "$KNOWLEDGE_BASE_DIR/local/suffix/work/b" $'---\nbranches:\n  - feat/x\n---'
expect_items 'feat/x-2 does not match a plan listing feat/x' '' "$repo"

# 4. Only the frontmatter counts.
repo="$TMP/body"
new_repo "$repo" feat/x
write_plan "$KNOWLEDGE_BASE_DIR/local/body/work/a" \
  $'---\ntitle: A\n---\nbranches: [feat/x]\nbranches:\n  - feat/x'
expect_items 'ignores branches: in the body after the frontmatter' '' "$repo"

repo="$TMP/no-frontmatter"
new_repo "$repo" feat/x
write_plan "$KNOWLEDGE_BASE_DIR/local/no-frontmatter/work/a" \
  $'# Plan\nbranches: [feat/x]\n---\nbranches: [feat/x]\n---'
expect_items 'ignores a plan that does not start with ---' '' "$repo"

repo="$TMP/next-key"
new_repo "$repo" feat/x
write_plan "$KNOWLEDGE_BASE_DIR/local/next-key/work/a" \
  $'---\nbranches:\n  - main\ntags:\n  - feat/x\n---'
expect_items 'a block list ends at the next frontmatter key' '' "$repo"

# 5. Detached HEAD and missing work dir.
repo="$TMP/detached"
new_repo "$repo" feat/x
git -C "$repo" checkout -q --detach
write_plan "$KNOWLEDGE_BASE_DIR/local/detached/work/a" \
  $'---\nbranches: [feat/x, HEAD]\n---'
expect_items 'detached HEAD prints nothing' '' "$repo"

repo="$TMP/no-work"
new_repo "$repo" feat/x
mkdir -p "$KNOWLEDGE_BASE_DIR/local/no-work"
expect_items 'a KB without a work dir prints nothing' '' "$repo"

# 6. Outside a git repo.
mkdir -p "$TMP/not-a-repo"
if out="$("$KB_WORK" "$TMP/not-a-repo" 2>/dev/null)"; then status=0; else status=$?; fi
if [[ "$status" -ne 0 && -z "$out" ]]; then
  ok 'outside a git repo exits nonzero with empty stdout'
else
  not_ok "outside a git repo (expected nonzero exit and empty stdout, got exit $status: '$out')"
fi

# 7. $1 defaults to $PWD.
repo="$TMP/default-dir"
new_repo "$repo" feat/x
mkdir -p "$repo/sub"
write_plan "$KNOWLEDGE_BASE_DIR/local/default-dir/work/a" $'---\nbranches: [feat/x]\n---'
if out="$(cd "$repo/sub" && "$KB_WORK" 2>&1)"; then status=0; else status=$?; fi
if [[ "$status" -eq 0 && "$out" == "$KNOWLEDGE_BASE_DIR/local/default-dir/work/a" ]]; then
  ok 'defaults to the current directory when no argument is given'
else
  not_ok "defaults to the current directory (got exit $status: '$out')"
fi

# 8. Linked worktree: main checkout's KB, worktree's branch.
main="$TMP/wt-main"
new_repo "$main" main
git -C "$main" worktree add -q "$TMP/wt-linked" -b feat/wt
write_plan "$KNOWLEDGE_BASE_DIR/local/wt-main/work/a" $'---\nbranches: [feat/wt]\n---'
expect_items 'linked worktree matches its branch in the main checkout KB' \
  "$KNOWLEDGE_BASE_DIR/local/wt-main/work/a" "$TMP/wt-linked"
expect_items 'main checkout on another branch does not match' '' "$main"

if (( fail != 0 )); then
  echo 'kb-work-test FAILED' >&2
  exit 1
fi

echo 'kb-work-test PASSED'
