#!/usr/bin/env bash
# Regression test for `make install-claude` replacing links left by the old
# Claude build locations (ai-clis/claude-code and global-ai/output/claude-code).
#
# The retained ai-clis/clis/claude/.claude folder (linked to ~/.claude) still
# holds links into those old roots. After `make install-claude`:
#   1. A whole-dir link into ai-clis/claude-code/output (agents, workflows) is
#      replaced by a link into output/claude, seen through ~/.claude.
#   2. In a real dir (skills, commands), an entry linking into an old root
#      under a name the build produces is replaced by the output/claude entry.
#   3. Dangling links into either old root are removed; a dangling link
#      elsewhere and real user entries are kept.
#   4. The old `command` link into global-ai/output/claude-code is removed,
#      while a `command` link to an unrelated path is kept.
#   5. ~/.claude still points at the retained folder, and a re-run is stable.
#
# Runs against a throwaway fixture (real Makefile, make/ and setup trees,
# fixture skills, fake HOME), so live sources, outputs, and HOME are never
# mutated.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-ai-install-claude-test.XXXXXX")"
# Resolve physical path so symlinked prefixes (/tmp -> /private/tmp) don't
# mismatch the absolute paths `make` computes internally.
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
HOME_DIR="$TMP/home"
export HOME="$HOME_DIR"

GAI="$REPO/ai-clis/global-ai"
CLAUDE_DIR="$REPO/ai-clis/clis/claude/.claude"
OUT="$GAI/output/claude"
OLD_CC="$REPO/ai-clis/claude-code/output"
OLD_GA="$GAI/output/claude-code"
ELSEWHERE="$TMP/elsewhere"

# --- fixture: mirror real repo layout (Makefile, make/ and setup trees) ---
mkdir -p "$GAI"
cp "$ROOT/Makefile" "$GAI/Makefile"
cp -R "$ROOT/make" "$GAI/make"
cp -R "$ROOT/setup" "$GAI/setup"

# Fixture skills only, so the built skill and command names are known.
SKILLS_SRC="$GAI/setup/skills-setup/skills"
rm -rf "$SKILLS_SRC" "$GAI/setup/command-setup/command"
mkdir -p "$SKILLS_SRC/ours"
cat > "$SKILLS_SRC/ours/SKILL.md" <<'MD'
---
name: ours
description: Fixture skill published as a command.
command: true
---

Run ours.
MD

# --- fixture: old build output that still exists on disk ---
mkdir -p "$OLD_CC/agents" "$OLD_CC/workflows" "$OLD_CC/skills/ours" "$ELSEWHERE"
printf 'old\n' > "$OLD_CC/agents/old-agent.md"
printf 'old\n' > "$OLD_CC/skills/ours/SKILL.md"

# --- fixture: retained claude folder with old-layout links ---
mkdir -p "$CLAUDE_DIR/skills/user-skill" "$CLAUDE_DIR/commands"
ln -s "$OLD_CC/agents" "$CLAUDE_DIR/agents"
ln -s "$OLD_CC/workflows" "$CLAUDE_DIR/workflows"
ln -s "$OLD_GA/command" "$CLAUDE_DIR/command"
ln -s "$OLD_CC/skills/ours" "$CLAUDE_DIR/skills/ours"
ln -s "$OLD_CC/skills/gone" "$CLAUDE_DIR/skills/gone"
ln -s "$OLD_GA/skills/gone-ga" "$CLAUDE_DIR/skills/gone-ga"
ln -s "$ELSEWHERE/missing" "$CLAUDE_DIR/skills/foreign-dangling"
printf 'mine\n' > "$CLAUDE_DIR/skills/user-skill/SKILL.md"
ln -s "$OLD_CC/commands/old.md" "$CLAUDE_DIR/commands/old.md"
ln -s "$OLD_CC/commands/ours.md" "$CLAUDE_DIR/commands/ours.md"
printf 'mine\n' > "$CLAUDE_DIR/commands/user-cmd.md"
mkdir -p "$HOME_DIR"
ln -s "$CLAUDE_DIR" "$HOME_DIR/.claude"

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

# --- run ---
check "make install-claude succeeds" make -C "$GAI" install-claude

# 1. whole-dir links into the old root are replaced
check_link "~/.claude/agents: claude-code/output link replaced by output/claude" \
  "$HOME_DIR/.claude/agents" "$OUT/agents"
check_link "~/.claude/workflows: claude-code/output link replaced by output/claude" \
  "$HOME_DIR/.claude/workflows" "$OUT/workflows"

# 2. same-name entries into the old root are replaced
check_link "~/.claude/skills/ours: claude-code/output link replaced" \
  "$HOME_DIR/.claude/skills/ours" "$OUT/skills/ours"
check_link "~/.claude/commands/ours.md: claude-code/output link replaced" \
  "$HOME_DIR/.claude/commands/ours.md" "$OUT/commands/ours.md"

# 3. dangling old-root links removed; foreign and user entries kept
check "dangling skill link into claude-code/output removed" absent "$CLAUDE_DIR/skills/gone"
check "dangling skill link into output/claude-code removed" absent "$CLAUDE_DIR/skills/gone-ga"
check "dangling command link into claude-code/output removed" absent "$CLAUDE_DIR/commands/old.md"
check_link "dangling link elsewhere kept" \
  "$CLAUDE_DIR/skills/foreign-dangling" "$ELSEWHERE/missing"
check "user skill dir kept" [ -f "$CLAUDE_DIR/skills/user-skill/SKILL.md" ]
check "user command file kept" [ -f "$CLAUDE_DIR/commands/user-cmd.md" ]

# 4. old command link into output/claude-code removed
check "old command link into output/claude-code removed" absent "$CLAUDE_DIR/command"

# 5. ~/.claude still the retained folder
check_link "~/.claude -> retained claude folder" "$HOME_DIR/.claude" "$CLAUDE_DIR"

# 4b. an unrelated `command` link is not ours to remove
rm -f "$CLAUDE_DIR/command"
ln -s "$ELSEWHERE" "$CLAUDE_DIR/command"
check "make install-claude re-run succeeds" make -C "$GAI" install-claude
check_link "unrelated command link kept" "$CLAUDE_DIR/command" "$ELSEWHERE"
check_link "skills entry stable after re-run" \
  "$HOME_DIR/.claude/skills/ours" "$OUT/skills/ours"
check_link "agents link stable after re-run" "$HOME_DIR/.claude/agents" "$OUT/agents"

if [ "$fail" -ne 0 ]; then
  echo "install-claude-test FAILED" >&2
  exit 1
fi
echo "install-claude-test PASSED"
