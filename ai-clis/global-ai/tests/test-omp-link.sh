#!/usr/bin/env bash
# Regression test for `make link-omp` in ai-clis/global-ai.
#
# Skills and commands are built once, by `make build-claude`, into ~/.claude;
# oh-my-pi reads them from there via its enableClaudeUser settings. The old
# build root ai-clis/oh-my-pi/output is treated as ours: links into it are
# replaced or removed.
#
# Proves:
#   1. output/omp/agents and output/omp/APPEND_SYSTEM.md are symlinked into
#      ~/.omp/agent, replacing links into the old oh-my-pi/output root.
#   2. Our old skill copies in ~/.omp/agent/skills are removed: symlinks into
#      oh-my-pi/output/skills or output/omp, and real dirs named after a skill
#      in setup/skills-setup/skills or old-skills. Anything else (a foreign
#      `workmux` skill dir, a symlink elsewhere) is kept.
#   3. Symlinks in ~/.claude/commands pointing into oh-my-pi/output/command
#      are removed; other symlinks and real files are kept.
#   4. The old ~/.omp/agent/commands -> oh-my-pi/output/command link is
#      removed.
#   5. With `omp` on PATH, exactly `config set skills.enableClaudeUser true`
#      and `config set commands.enableClaudeUser true` are run.
#   6. Without `omp` on PATH, link still succeeds and prints a WARNING.
#   7. Workflows are linked into ~/.pi/workflows/saved, replacing a link into
#      oh-my-pi/output/workflows; dangling links into either the old root or
#      output/omp/workflows are removed; an unrelated real file is kept; a
#      real file colliding with a workflow name fails the link and survives.
#   8. `make link-omp` is idempotent.
#
# Runs against a throwaway fixture (copied Makefile and make/, fixture output
# and skill names, throwaway HOME, stub `omp`), so the live output/, HOME, and the real
# omp config are never touched.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/omp-link-test.XXXXXX")"
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
GAI="$REPO/ai-clis/global-ai"
OUT="$GAI/output/omp"
LEGACY="$REPO/ai-clis/oh-my-pi/output"
SKILLS_SETUP="$GAI/setup/skills-setup"
HOME_DIR="$TMP/home"
ELSEWHERE="$TMP/elsewhere"
MAKE_BIN="$(command -v make)"

# --- fixture: global-ai Makefiles with generated omp output ---
mkdir -p "$OUT/agents" "$OUT/workflows"
cp "$ROOT/Makefile" "$GAI/Makefile"
cp -R "$ROOT/make" "$GAI/make"
printf 'agent\n' > "$OUT/agents/scout.md"
printf 'prompt\n' > "$OUT/APPEND_SYSTEM.md"
printf 'workflow\n' > "$OUT/workflows/flow.js"

# --- fixture: old oh-my-pi build output, still on disk ---
mkdir -p "$LEGACY/agents" "$LEGACY/workflows"
printf 'old\n' > "$LEGACY/APPEND_SYSTEM.md"
printf 'old\n' > "$LEGACY/workflows/flow.js"

# --- fixture: skill names we own (current and retired) ---
mkdir -p "$SKILLS_SETUP/skills/ours-current" "$SKILLS_SETUP/old-skills/ours-retired"

mkdir -p "$ELSEWHERE"
printf 'x\n' > "$ELSEWHERE/other.md"

# --- fixture: HOME with old-layout leftovers and foreign entries ---
AGENT="$HOME_DIR/.omp/agent"
mkdir -p "$AGENT/skills" "$HOME_DIR/.claude/commands" "$HOME_DIR/.pi/workflows/saved"
ln -s "$LEGACY/agents" "$AGENT/agents"
ln -s "$LEGACY/APPEND_SYSTEM.md" "$AGENT/APPEND_SYSTEM.md"
ln -s "$LEGACY/skills/linked-ours" "$AGENT/skills/linked-ours"
ln -s "$OUT/skills/linked-new" "$AGENT/skills/linked-new"
mkdir -p "$AGENT/skills/ours-current" "$AGENT/skills/ours-retired" "$AGENT/skills/workmux"
printf 'keep\n' > "$AGENT/skills/workmux/SKILL.md"
ln -s "$ELSEWHERE" "$AGENT/skills/foreign-link"
ln -s "$LEGACY/command" "$AGENT/commands"

CMDS="$HOME_DIR/.claude/commands"
ln -s "$LEGACY/command/omp-cmd.md" "$CMDS/omp-cmd.md"
ln -s "$ELSEWHERE/other.md" "$CMDS/other.md"
printf 'real\n' > "$CMDS/real.md"

SAVED="$HOME_DIR/.pi/workflows/saved"
ln -s "$LEGACY/workflows/flow.js" "$SAVED/flow.js"
ln -s "$LEGACY/workflows/gone.js" "$SAVED/gone.js"
ln -s "$OUT/workflows/gone-new.js" "$SAVED/gone-new.js"
printf 'mine\n' > "$SAVED/mine.js"

# --- stub omp: records each invocation's arguments, one line per call ---
STUB_BIN="$TMP/bin"
OMP_CALLS="$TMP/omp-calls"
mkdir -p "$STUB_BIN"
cat > "$STUB_BIN/omp" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$OMP_CALLS"
EOF
chmod +x "$STUB_BIN/omp"

# --- minimal PATH without omp, for the missing-omp case ---
NO_OMP_BIN="$TMP/no-omp-bin"
mkdir -p "$NO_OMP_BIN"
for tool in sh mkdir rm ln readlink basename; do
  ln -s "$(command -v "$tool")" "$NO_OMP_BIN/$tool"
done

fail=0
check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc"
    fail=1
  fi
}

check_link() {
  local desc="$1" dest="$2" expected="$3"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$expected" ]; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc"
    fail=1
  fi
}

absent() { [ ! -L "$1" ] && [ ! -e "$1" ]; }

run_link() {
  HOME="$HOME_DIR" PATH="$STUB_BIN:$PATH" "$MAKE_BIN" -C "$GAI" link-omp
}

# --- run ---
check "make link-omp succeeds" run_link

# 1. agents and APPEND_SYSTEM.md
check_link "~/.omp/agent/agents: oh-my-pi/output link replaced by output/omp" \
  "$AGENT/agents" "$OUT/agents"
check_link "~/.omp/agent/APPEND_SYSTEM.md: oh-my-pi/output link replaced by output/omp" \
  "$AGENT/APPEND_SYSTEM.md" "$OUT/APPEND_SYSTEM.md"

# 2. skills cleanup
check "old skill link into oh-my-pi/output/skills removed" absent "$AGENT/skills/linked-ours"
check "skill link into output/omp removed" absent "$AGENT/skills/linked-new"
check "real copy of a current skill removed" absent "$AGENT/skills/ours-current"
check "real copy of a retired skill removed" absent "$AGENT/skills/ours-retired"
check "foreign skill dir kept: workmux" [ -f "$AGENT/skills/workmux/SKILL.md" ]
check_link "foreign skill symlink kept" "$AGENT/skills/foreign-link" "$ELSEWHERE"

# 3. ~/.claude/commands cleanup
check "command link into oh-my-pi/output/command removed" absent "$CMDS/omp-cmd.md"
check_link "unrelated command symlink kept" "$CMDS/other.md" "$ELSEWHERE/other.md"
check "real command file kept" [ -f "$CMDS/real.md" ]

# 4. old command dir link
check "old ~/.omp/agent/commands link removed" absent "$AGENT/commands"

# 5. omp settings
EXPECTED_CALLS="$TMP/expected-calls"
printf '%s\n' \
  'config set skills.enableClaudeUser true' \
  'config set commands.enableClaudeUser true' > "$EXPECTED_CALLS"
check "omp config set called for skills and commands enableClaudeUser" \
  cmp -s "$OMP_CALLS" "$EXPECTED_CALLS"

# 7. workflows
check_link "workflow link into oh-my-pi/output replaced by output/omp" \
  "$SAVED/flow.js" "$OUT/workflows/flow.js"
check "dangling workflow link into oh-my-pi/output removed" absent "$SAVED/gone.js"
check "dangling workflow link into output/omp removed" absent "$SAVED/gone-new.js"
check "unrelated saved workflow kept" [ -f "$SAVED/mine.js" ]

# 8. idempotency
check "make link-omp idempotent" run_link
check_link "agents link stable after 2nd run" "$AGENT/agents" "$OUT/agents"
check_link "workflow link stable after 2nd run" \
  "$SAVED/flow.js" "$OUT/workflows/flow.js"
check "foreign skill dir survives 2nd run" [ -f "$AGENT/skills/workmux/SKILL.md" ]

# 6. omp missing from PATH
: > "$OMP_CALLS"
NO_OMP_ERR="$TMP/no-omp.err"
if HOME="$HOME_DIR" PATH="$NO_OMP_BIN" "$MAKE_BIN" -C "$GAI" link-omp >/dev/null 2>"$NO_OMP_ERR"; then
  echo "ok   - make link-omp succeeds without omp on PATH"
else
  echo "FAIL - make link-omp succeeds without omp on PATH"
  fail=1
fi
check "missing omp prints WARNING naming both settings" \
  grep -Eq 'WARNING: omp not found.*skills\.enableClaudeUser.*commands\.enableClaudeUser' "$NO_OMP_ERR"
check "no omp calls without omp on PATH" [ ! -s "$OMP_CALLS" ]

# 7b. real file colliding with a workflow name: link fails, file survives
rm -f "$SAVED/flow.js"
printf 'real\n' > "$SAVED/flow.js"
if run_link >/dev/null 2>&1; then
  echo "FAIL - make link-omp should fail on real workflow collision"
  fail=1
else
  echo "ok   - make link-omp fails on real workflow collision"
fi
check "colliding workflow file preserved" \
  [ ! -L "$SAVED/flow.js" -a "$(cat "$SAVED/flow.js")" = real ]

if (( fail != 0 )); then
  echo 'omp-link-test FAILED' >&2
  exit 1
fi

echo 'omp-link-test PASSED'
