#!/usr/bin/env bash
# Regression coverage for Claude's redirect-docs-to-kb PreToolUse hook.
#
# The hook is exercised as an external process with representative Claude hook
# payloads, run from a directory outside any repo so only the payload cwd can
# locate relative paths. Proves:
#   1. New, untracked KB-owned docs (ADRs, decisions, glossaries,
#      CONSTRAINTS.md) written through Write, Edit, MultiEdit or NotebookEdit
#      exit 2 naming the KB target, and the KB directory is created.
#   2. Relative paths resolve against the payload cwd but map relative to the
#      repo root; missing parent directories are fine.
#   3. Specs, plans and task lists map into the single work item listing the
#      current branch; with zero or several matches the message names a
#      <slug> placeholder and points at "Work items".
#   4. The Setup hint appears only while <kb>/INDEX.md is missing.
#   5. Tracked files, files under the KB root (even when it is a git repo),
#      files outside any repo, non-doc files, other tools, empty paths and
#      KB_ALLOW_REPO_DOCS=1 are all allowed.
#   6. Bash `>`, `>>`, `tee` and `tee -a` targets get the same check; fd
#      redirections and /dev targets are ignored; every target is checked.
#
# Every repo lives in a throwaway temp dir; KNOWLEDGE_BASE_DIR always points
# inside it and global/system git config is ignored so url.insteadOf rewrites
# cannot leak in.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/setup/claude-specific/hooks/redirect-docs-to-kb.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-ai-redirect-docs-test.XXXXXX")"
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

export KNOWLEDGE_BASE_DIR="$TMP/kb"
export KB_SCRIPTS_DIR="$ROOT/setup/skills-setup/skills/knowledge-base/scripts"
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
unset KB_ALLOW_REPO_DOCS

OUTSIDE="$TMP/not-a-repo"
mkdir -p "$OUTSIDE"

fail=0

ok() { printf 'ok   - %s\n' "$1"; }
not_ok() {
  printf 'FAIL - %s\n' "$1" >&2
  fail=1
}

# new_repo <dir> [<branch>]: a repo with no remote, so its KB is
# $KNOWLEDGE_BASE_DIR/local/<dir name>.
new_repo() {
  git init -q -b "${2:-main}" "$1"
}

# write_payload <tool> <cwd> <file_path>
write_payload() {
  jq -nc --arg t "$1" --arg c "$2" --arg p "$3" \
    '{hook_event_name:"PreToolUse",tool_name:$t,cwd:$c,tool_input:{file_path:$p}}'
}

# notebook_payload <cwd> <notebook_path>
notebook_payload() {
  jq -nc --arg c "$1" --arg p "$2" \
    '{hook_event_name:"PreToolUse",tool_name:"NotebookEdit",cwd:$c,tool_input:{notebook_path:$p}}'
}

# bash_payload <cwd> <command>
bash_payload() {
  jq -nc --arg c "$1" --arg cmd "$2" \
    '{hook_event_name:"PreToolUse",tool_name:"Bash",cwd:$c,tool_input:{command:$cmd}}'
}

# run_hook <payload>: sets $status and $err.
run_hook() {
  if (cd "$OUTSIDE" && printf '%s\n' "$1" | "$HOOK" 2>"$TMP/stderr" >/dev/null); then
    status=0
  else
    status=$?
  fi
  err="$(cat "$TMP/stderr")"
}

# expect_deny <description> <payload> <kb dir> <expected target>
expect_deny() {
  run_hook "$2"
  if [[ "$status" -eq 2 && "$err" == *"$4"* && -d "$3" ]]; then
    ok "$1"
  else
    not_ok "$1 (expected exit 2, '$4' in stderr and $3 created; got exit $status: '$err')"
  fi
}

# expect_allow <description> <payload>
expect_allow() {
  run_hook "$2"
  if [[ "$status" -eq 0 ]]; then
    ok "$1"
  else
    not_ok "$1 (expected exit 0, got exit $status: '$err')"
  fi
}

# 1. KB-owned docs through each file tool; the KB dir is created on deny.
repo="$TMP/docs"
new_repo "$repo"
kb="$KNOWLEDGE_BASE_DIR/local/docs"
if [[ -e "$kb" ]]; then
  not_ok "$kb exists before the first deny"
fi
expect_deny 'Write to a new docs/adr file redirects to <kb>/adr and creates the KB dir' \
  "$(write_payload Write "$repo" "$repo/docs/adr/0001-use-x.md")" \
  "$kb" "$kb/adr/0001-use-x.md"
expect_deny 'Edit of a context ADR redirects to <kb>/<ctx>/adr' \
  "$(write_payload Edit "$repo" "$repo/svc/docs/adr/0002.md")" \
  "$kb" "$kb/svc/adr/0002.md"
expect_deny 'MultiEdit of docs/decisions redirects to <kb>/adr' \
  "$(write_payload MultiEdit "$repo" "$repo/docs/decisions/0003.md")" \
  "$kb" "$kb/adr/0003.md"
expect_deny 'NotebookEdit of an ADR notebook redirects to <kb>/adr' \
  "$(notebook_payload "$repo" "$repo/docs/adr/0004.ipynb")" \
  "$kb" "$kb/adr/0004.ipynb"
expect_deny 'GLOSSARY.md redirects to <kb>/GLOSSARY.md' \
  "$(write_payload Write "$repo" "$repo/GLOSSARY.md")" \
  "$kb" "$kb/GLOSSARY.md"
expect_deny 'a context GLOSSARY.md redirects to <kb>/<ctx>/GLOSSARY.md' \
  "$(write_payload Write "$repo" "$repo/billing/GLOSSARY.md")" \
  "$kb" "$kb/billing/GLOSSARY.md"
expect_deny 'CONSTRAINTS.md redirects to <kb>/CONSTRAINTS.md' \
  "$(write_payload Write "$repo" "$repo/CONSTRAINTS.md")" \
  "$kb" "$kb/CONSTRAINTS.md"

# 2. Relative paths: resolved against payload cwd, mapped from the repo root.
mkdir -p "$repo/svc"
expect_deny 'relative path from a subdirectory cwd maps from the repo root' \
  "$(write_payload Write "$repo/svc" GLOSSARY.md)" \
  "$kb" "$kb/svc/GLOSSARY.md"
expect_deny 'relative ADR path with missing parent dirs resolves against cwd' \
  "$(write_payload Write "$repo" docs/adr/0005.md)" \
  "$kb" "$kb/adr/0005.md"

repo="$TMP/remote"
git init -q "$repo"
git -C "$repo" remote add origin git@github.com:Acme/Billing.git
expect_deny 'KB target uses the normalized origin remote key' \
  "$(write_payload Write "$repo" "$repo/GLOSSARY.md")" \
  "$KNOWLEDGE_BASE_DIR/github.com/acme/billing" \
  "$KNOWLEDGE_BASE_DIR/github.com/acme/billing/GLOSSARY.md"

repo="$TMP/sym-real"
git init -q "$repo"
git -C "$repo" remote add origin git@github.com:acme/symlinked.git
ln -s "$repo" "$TMP/sym-link"
expect_deny 'a cwd reached through a symlink still maps from the repo root' \
  "$(write_payload Write "$TMP/sym-link" GLOSSARY.md)" \
  "$KNOWLEDGE_BASE_DIR/github.com/acme/symlinked" \
  "$KNOWLEDGE_BASE_DIR/github.com/acme/symlinked/GLOSSARY.md"

# 3. Work-item files.
repo="$TMP/one-item"
new_repo "$repo" feat/x
kb="$KNOWLEDGE_BASE_DIR/local/one-item"
mkdir -p "$kb/work/billing/api" "$kb/work/other"
printf -- '---\nbranches: [feat/x]\n---\n' >"$kb/work/billing/api/plan.md"
printf -- '---\nbranches: [feat/y]\n---\n' >"$kb/work/other/plan.md"
while IFS='|' read -r rel name; do
  expect_deny "$rel maps into the single matching work item" \
    "$(write_payload Write "$repo" "$repo/$rel")" \
    "$kb" "$kb/work/billing/api/$name"
done <<'EOF'
SPEC.md|SPEC.md
SPEC-auth.md|SPEC.md
docs/SPEC.md|SPEC.md
tasks/plan.md|plan.md
tasks/todo.md|todo.md
EOF

repo="$TMP/no-item"
new_repo "$repo" feat/x
kb="$KNOWLEDGE_BASE_DIR/local/no-item"
expect_deny 'with no matching work item the target is a <slug> placeholder' \
  "$(write_payload Write "$repo" "$repo/tasks/plan.md")" \
  "$kb" "$kb/work/<slug>/[<module>/]plan.md"
if [[ "$err" == *'Work items'* ]]; then
  ok 'placeholder target points at the Work items section'
else
  not_ok "placeholder target does not mention Work items: '$err'"
fi

repo="$TMP/two-items"
new_repo "$repo" feat/x
kb="$KNOWLEDGE_BASE_DIR/local/two-items"
mkdir -p "$kb/work/a" "$kb/work/b"
printf -- '---\nbranches: [feat/x]\n---\n' >"$kb/work/a/plan.md"
printf -- '---\nbranches: [feat/x]\n---\n' >"$kb/work/b/plan.md"
expect_deny 'with two matching work items the target is a <slug> placeholder' \
  "$(write_payload Write "$repo" "$repo/SPEC.md")" \
  "$kb" "$kb/work/<slug>/[<module>/]SPEC.md"

# 4. Setup hint only while INDEX.md is missing.
repo="$TMP/no-index"
new_repo "$repo"
expect_deny 'deny in a repo without INDEX.md' \
  "$(write_payload Write "$repo" "$repo/GLOSSARY.md")" \
  "$KNOWLEDGE_BASE_DIR/local/no-index" "$KNOWLEDGE_BASE_DIR/local/no-index/GLOSSARY.md"
if [[ "$err" == *Setup* ]]; then
  ok 'missing INDEX.md asks for Setup'
else
  not_ok "missing INDEX.md does not mention Setup: '$err'"
fi

repo="$TMP/with-index"
new_repo "$repo"
mkdir -p "$KNOWLEDGE_BASE_DIR/local/with-index"
: >"$KNOWLEDGE_BASE_DIR/local/with-index/INDEX.md"
expect_deny 'deny in a repo with INDEX.md' \
  "$(write_payload Write "$repo" "$repo/GLOSSARY.md")" \
  "$KNOWLEDGE_BASE_DIR/local/with-index" "$KNOWLEDGE_BASE_DIR/local/with-index/GLOSSARY.md"
if [[ "$err" != *Setup* ]]; then
  ok 'present INDEX.md does not ask for Setup'
else
  not_ok "present INDEX.md still mentions Setup: '$err'"
fi

# 5. Allowed writes.
repo="$TMP/tracked"
new_repo "$repo"
mkdir -p "$repo/docs/adr"
: >"$repo/GLOSSARY.md"
: >"$repo/docs/adr/0001.md"
git -C "$repo" add GLOSSARY.md docs/adr/0001.md
expect_allow 'tracked GLOSSARY.md stays editable' \
  "$(write_payload Edit "$repo" "$repo/GLOSSARY.md")"
expect_allow 'tracked ADR stays editable' \
  "$(write_payload Edit "$repo" "$repo/docs/adr/0001.md")"

repo="$TMP/allowed"
new_repo "$repo"
expect_allow 'non-doc file is allowed' \
  "$(write_payload Write "$repo" "$repo/src/a.ts")"
expect_allow 'a non-writing tool is allowed' \
  "$(write_payload Read "$repo" "$repo/GLOSSARY.md")"
expect_allow 'empty file_path is allowed' \
  "$(write_payload Write "$repo" '')"
expect_allow 'missing tool_input is allowed' \
  "$(jq -nc --arg c "$repo" '{hook_event_name:"PreToolUse",tool_name:"Write",cwd:$c}')"
expect_allow 'GLOSSARY.md outside any git repo is allowed' \
  "$(write_payload Write "$OUTSIDE" "$OUTSIDE/GLOSSARY.md")"

repo="$TMP/opt-out"
new_repo "$repo"
if (cd "$OUTSIDE" && write_payload Write "$repo" "$repo/GLOSSARY.md" \
  | KB_ALLOW_REPO_DOCS=1 "$HOOK" >/dev/null 2>&1); then status=0; else status=$?; fi
if [[ "$status" -eq 0 && ! -e "$KNOWLEDGE_BASE_DIR/local/opt-out" ]]; then
  ok 'KB_ALLOW_REPO_DOCS=1 allows a KB-owned doc without creating the KB dir'
else
  not_ok "KB_ALLOW_REPO_DOCS=1 (expected exit 0 and no KB dir, got exit $status)"
fi

git init -q "$KNOWLEDGE_BASE_DIR"
expect_allow 'writes under the KB root are allowed even when it is a git repo' \
  "$(write_payload Write "$KNOWLEDGE_BASE_DIR" "$KNOWLEDGE_BASE_DIR/GLOSSARY.md")"
expect_allow 'KB ADR writes are allowed even when the KB root is a git repo' \
  "$(write_payload Write "$KNOWLEDGE_BASE_DIR" "$KNOWLEDGE_BASE_DIR/local/docs/docs/adr/x.md")"

ln -s "$KNOWLEDGE_BASE_DIR" "$TMP/kb-link"
if (cd "$OUTSIDE" && write_payload Write "$KNOWLEDGE_BASE_DIR" "$KNOWLEDGE_BASE_DIR/GLOSSARY.md" \
  | KNOWLEDGE_BASE_DIR="$TMP/kb-link" "$HOOK" >/dev/null 2>"$TMP/stderr"); then status=0; else status=$?; fi
if [[ "$status" -eq 0 ]]; then
  ok 'a symlinked KNOWLEDGE_BASE_DIR still allows writes under its real path'
else
  not_ok "symlinked KNOWLEDGE_BASE_DIR (expected exit 0, got exit $status: '$(cat "$TMP/stderr")')"
fi

# 6. Bash redirection targets.
repo="$TMP/bash"
new_repo "$repo"
kb="$KNOWLEDGE_BASE_DIR/local/bash"
expect_deny 'Bash heredoc into tasks/plan.md is denied' \
  "$(bash_payload "$repo" $'cat > tasks/plan.md <<EOF\n# Plan\nEOF')" \
  "$kb" "$kb/work/<slug>/[<module>/]plan.md"
expect_deny 'Bash tee -a into GLOSSARY.md is denied' \
  "$(bash_payload "$repo" 'echo x | tee -a GLOSSARY.md')" \
  "$kb" "$kb/GLOSSARY.md"
expect_deny 'Bash tee into CONSTRAINTS.md is denied' \
  "$(bash_payload "$repo" 'echo x | tee CONSTRAINTS.md')" \
  "$kb" "$kb/CONSTRAINTS.md"
expect_deny 'Bash quoted >> target is denied' \
  "$(bash_payload "$repo" 'echo x >>"docs/adr/0001.md"')" \
  "$kb" "$kb/adr/0001.md"
expect_deny 'Bash checks every redirection, not just the first' \
  "$(bash_payload "$repo" 'echo a > src/a.ts && echo b >> GLOSSARY.md')" \
  "$kb" "$kb/GLOSSARY.md"
expect_allow 'Bash redirect into a non-doc file is allowed' \
  "$(bash_payload "$repo" 'echo hi > src/a.ts')"
expect_allow 'Bash 2>/dev/null is allowed' \
  "$(bash_payload "$repo" 'cat GLOSSARY.md 2>/dev/null')"
expect_allow 'Bash 2>&1 is allowed' \
  "$(bash_payload "$repo" 'cat GLOSSARY.md 2>&1')"
expect_allow 'Bash without redirection is allowed' \
  "$(bash_payload "$repo" 'cat GLOSSARY.md')"

if (( fail != 0 )); then
  echo 'redirect-docs-to-kb-test FAILED' >&2
  exit 1
fi

echo 'redirect-docs-to-kb-test PASSED'
