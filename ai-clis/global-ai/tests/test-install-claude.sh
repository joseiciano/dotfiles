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

# --- skills are linked per entry into a real dir ---
SKILLS_DIR="$CLAUDE_DIR/skills"

# Every built skill has its own link in the real skills dir.
skills_linked_per_entry() {
  [ -d "$SKILLS_DIR" ] && [ ! -L "$SKILLS_DIR" ] || return 1
  local src name
  for src in "$OUT/skills"/*; do
    name="$(basename "$src")"
    [ -L "$SKILLS_DIR/$name" ] && [ "$(readlink "$SKILLS_DIR/$name")" = "$src" ] || return 1
  done
}

link_claude_fails_with() {
  local expected="$1" err
  if err="$(make -C "$GAI" link-claude 2>&1)"; then return 1; fi
  case "$err" in *"$expected"*) return 0 ;; esac
  return 1
}

# 6. a whole-dir skills link into a managed root becomes a real dir of links
for target in "$OUT/skills" "$OLD_CC/skills" "$OLD_GA/skills"; do
  label="${target#"$REPO"/}"
  rm -rf "$SKILLS_DIR"
  ln -s "$target" "$SKILLS_DIR"
  check "link-claude succeeds with skills -> $label" make -C "$GAI" link-claude
  check "skills -> $label replaced by real dir of per-skill links" skills_linked_per_entry
done
check "no links written into output/claude/skills" \
  bash -c '! find "$1" -mindepth 1 -maxdepth 1 -type l | grep -q .' _ "$OUT/skills"

# 7. a skills link to an unrelated path is refused and left untouched
# (output/claudeX shares a prefix with output/claude but is not managed)
for target in "$ELSEWHERE" "$GAI/output/claudeX/skills"; do
  label="${target#"$TMP"/}"
  rm -rf "$SKILLS_DIR"
  ln -s "$target" "$SKILLS_DIR"
  check "link-claude refuses skills -> $label" \
    link_claude_fails_with "refusing to replace unrelated symlink"
  check_link "unrelated skills link -> $label kept" "$SKILLS_DIR" "$target"
done
rm -f "$SKILLS_DIR"
check "link-claude restores skills dir" make -C "$GAI" link-claude

# 8. real entries Claude Code writes survive link-claude and a full rebuild
mkdir -p "$SKILLS_DIR/synced/foo" "$SKILLS_DIR/user-skill"
printf 'mine\n' > "$SKILLS_DIR/user-skill/SKILL.md"
ln -s "$ELSEWHERE/missing" "$SKILLS_DIR/foreign-dangling"
printf 'synced\n' > "$SKILLS_DIR/synced/foo/SKILL.md"
mkdir -p "$SKILLS_SRC/extra"
printf -- '---\nname: extra\ndescription: Fixture skill removed later.\n---\n\nExtra.\n' \
  > "$SKILLS_SRC/extra/SKILL.md"
check "make install-claude with real synced/ dir succeeds" make -C "$GAI" install-claude
check "synced/ kept after rebuild" [ -f "$SKILLS_DIR/synced/foo/SKILL.md" ]
check "synced/ is still a real dir" [ ! -L "$SKILLS_DIR/synced" ]
check "synced/ not in build output" absent "$OUT/skills/synced"
check "user skill not in build output" absent "$OUT/skills/user-skill"
check_link "new skill linked" "$SKILLS_DIR/extra" "$OUT/skills/extra"

# 9. a removed skill's link is pruned; other links and real entries stay
rm -rf "$SKILLS_SRC/extra"
check "make install-claude after removing a skill succeeds" make -C "$GAI" install-claude
check "removed skill link pruned" absent "$SKILLS_DIR/extra"
check_link "remaining skill link kept" "$SKILLS_DIR/ours" "$OUT/skills/ours"
check "synced/ kept after pruning" [ -f "$SKILLS_DIR/synced/foo/SKILL.md" ]
check "user skill kept after pruning" [ -f "$SKILLS_DIR/user-skill/SKILL.md" ]
check_link "foreign dangling skill link kept after pruning" \
  "$SKILLS_DIR/foreign-dangling" "$ELSEWHERE/missing"

# 10. a real entry under a built skill name is refused and preserved
rm -f "$SKILLS_DIR/ours"
mkdir -p "$SKILLS_DIR/ours"
printf 'mine\n' > "$SKILLS_DIR/ours/SKILL.md"
check "link-claude refuses real dir colliding with built skill" \
  link_claude_fails_with "refusing to replace existing path"
check "colliding real skill dir preserved" \
  bash -c '[ ! -L "$1" ] && [ "$(cat "$1/SKILL.md")" = mine ]' _ "$SKILLS_DIR/ours"

if [ "$fail" -ne 0 ]; then
  echo "install-claude-test FAILED" >&2
  exit 1
fi
echo "install-claude-test PASSED"
