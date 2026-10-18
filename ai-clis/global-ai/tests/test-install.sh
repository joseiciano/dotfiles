#!/usr/bin/env bash
# End-to-end regression test for `make install-opencode` and `make install`
# in ai-clis/global-ai.
#
# Proves:
#   1. `make -j install-opencode` runs setup fully before link (parallel-safe
#      ordering).
#   2. `make install-opencode` populates the retained opencode config folder under
#      ai-clis/clis/ with symlinks to generated output (correct targets); no
#      staging under $HOME/dotfiles.
#   3. Non-generated files already present in retained folders survive.
#   4. Stale symlinks whose target belongs to this output root and no longer
#      exists are removed; symlinks whose target still exists under the same
#      root, symlinks under a different output root, unrelated symlinks, and
#      real files/dirs are all preserved.
#   5. The whole retained folder is symlinked to its real HOME config path.
#   6. No $HOME/dotfiles/opencode staging dir is created.
#   7. `make install-opencode` is idempotent.
#   8. Skills and commands are not generated here: there is no `skills`
#      entry, and `command` links to $HOME/.claude/commands (built by
#      `make install-claude`) only once that folder exists. Old `skills`/`command`
#      symlinks into output/opencode are removed.
#   9. A real dir colliding with a generated entry fails the link and survives.
#  10. Top-level `make -j install` builds Claude before opencode: on a fresh
#      HOME, the first run already links opencode's `command` to the
#      ~/.claude/commands that install-claude created, and oh-my-pi is linked
#      too (with a stub `omp` on PATH, so the real omp config is untouched).
#
# Runs against a throwaway fixture (fake repo layout + fake HOME), so live
# HOME and live ai-clis/clis retained folders are never mutated.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_MAKEFILE="$ROOT/Makefile"
REAL_MAKE_DIR="$ROOT/make"
REAL_SETUP="$ROOT/setup"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-ai-install-test.XXXXXX")"
# Resolve physical path so symlinked prefixes (/tmp -> /private/tmp) don't
# mismatch the absolute paths `make` computes internally.
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
HOME_DIR="$TMP/home"
export HOME="$HOME_DIR"

GAI="$REPO/ai-clis/global-ai"
CLIS="$REPO/ai-clis/clis"

# Copy the real Makefile, make/ and setup trees into a fixture global-ai dir.
make_fixture() {
  mkdir -p "$1"
  cp "$REAL_MAKEFILE" "$1/Makefile"
  cp -R "$REAL_MAKE_DIR" "$1/make"
  cp -R "$REAL_SETUP" "$1/setup"
}

# --- fixture: mirror real repo layout (Makefile, make/ and setup trees) ---
make_fixture "$GAI"

# retained opencode config folder with non-generated files that must survive
mkdir -p "$CLIS/opencode/.config/opencode"
printf '{"custom":true}\n' > "$CLIS/opencode/.config/opencode/custom.jsonc"

# stale symlinks pointing into the output root (targets never exist even after setup)
ln -s "$GAI/output/opencode/stale-cmd" "$CLIS/opencode/.config/opencode/stale-cmd"

# old-layout links into output/opencode that setup no longer produces
ln -s "$GAI/output/opencode/skills" "$CLIS/opencode/.config/opencode/skills"
ln -s "$GAI/output/opencode/command" "$CLIS/opencode/.config/opencode/command"

# symlink under the matching output root whose target setup will create: must be kept
ln -s "$GAI/output/opencode/agents" "$CLIS/opencode/.config/opencode/keep-live-root"

# symlink whose (missing) target lives under a DIFFERENT output root: must be kept
ln -s "$GAI/output/claude/stale" "$CLIS/opencode/.config/opencode/cross-root"

# unrelated symlink + real dir that must survive reconciliation
printf 'ext\n' > "$TMP/ext-target"
ln -s "$TMP/ext-target" "$CLIS/opencode/.config/opencode/keep-x"
mkdir -p "$CLIS/opencode/.config/opencode/real-d"
printf 'ok\n' > "$CLIS/opencode/.config/opencode/real-d/keep.txt"

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

# --- run ---
check "make -j install-opencode succeeds" make -C "$GAI" -j4 install-opencode

# 1. generated entries linked inside retained folders with correct targets
check_link "opencode generated entry: agents" \
  "$CLIS/opencode/.config/opencode/agents" "$GAI/output/opencode/agents"
check_link "opencode generated file: opencode.json" \
  "$CLIS/opencode/.config/opencode/opencode.json" "$GAI/output/opencode/opencode.json"

# 2. non-generated files preserved in retained folders
check "opencode custom file preserved" [ -f "$CLIS/opencode/.config/opencode/custom.jsonc" ]

# 3. stale symlinks removed (asserted via ! -L: a dangling symlink would
#    otherwise satisfy ! -e), matching-root live-target + different-root
#    symlinks preserved, unrelated symlink + real dir preserved
check "stale symlink removed: stale-cmd" [ ! -L "$CLIS/opencode/.config/opencode/stale-cmd" ]
check_link "matching-root symlink with live target preserved: keep-live-root" \
  "$CLIS/opencode/.config/opencode/keep-live-root" "$GAI/output/opencode/agents"
check_link "different-root symlink preserved: cross-root" \
  "$CLIS/opencode/.config/opencode/cross-root" "$GAI/output/claude/stale"
check_link "unrelated symlink preserved: keep-x" \
  "$CLIS/opencode/.config/opencode/keep-x" "$TMP/ext-target"
check "real dir preserved: real-d" [ -f "$CLIS/opencode/.config/opencode/real-d/keep.txt" ]

# 4. whole retained folder linked into HOME
check "~/.config/opencode -> retained folder" \
  [ "$(readlink "$HOME_DIR/.config/opencode")" = "$CLIS/opencode/.config/opencode" ]

check "no ~/dotfiles/opencode staging dir" [ ! -e "$HOME_DIR/dotfiles/opencode" ]

# 8. skills/commands come from ~/.claude, not from this output
check "setup builds no output/opencode/skills" [ ! -e "$GAI/output/opencode/skills" ]
check "setup builds no output/opencode/command" [ ! -e "$GAI/output/opencode/command" ]
check "old skills link removed, no skills entry" \
  [ ! -L "$CLIS/opencode/.config/opencode/skills" -a ! -e "$CLIS/opencode/.config/opencode/skills" ]
check "no command entry while ~/.claude/commands is absent" \
  [ ! -L "$CLIS/opencode/.config/opencode/command" -a ! -e "$CLIS/opencode/.config/opencode/command" ]

mkdir -p "$HOME_DIR/.claude/commands"
printf 'cmd\n' > "$HOME_DIR/.claude/commands/from-claude.md"

# 7. idempotency (also -j)
check "make -j install-opencode idempotent" make -C "$GAI" -j4 install-opencode
check "~/.config/opencode still linked after 2nd run" \
  [ "$(readlink "$HOME_DIR/.config/opencode")" = "$CLIS/opencode/.config/opencode" ]
check_link "command -> \$HOME/.claude/commands once it exists" \
  "$CLIS/opencode/.config/opencode/command" "$HOME_DIR/.claude/commands"
check "claude commands reachable through opencode config" \
  [ -f "$HOME_DIR/.config/opencode/command/from-claude.md" ]
check "still no skills entry after 2nd run" \
  [ ! -L "$CLIS/opencode/.config/opencode/skills" -a ! -e "$CLIS/opencode/.config/opencode/skills" ]
check "make -j install-opencode idempotent with command linked" make -C "$GAI" -j4 install-opencode
check_link "command link stable across runs" \
  "$CLIS/opencode/.config/opencode/command" "$HOME_DIR/.claude/commands"


# 9. real collision: setup succeeds, link fails, real entry survives

rm -f "$CLIS/opencode/.config/opencode/agents"
mkdir -p "$CLIS/opencode/.config/opencode/agents"
printf 'real\n' > "$CLIS/opencode/.config/opencode/agents/marker.txt"
if make -C "$GAI" -j4 install-opencode >/dev/null 2>&1; then
  echo "FAIL - make install-opencode should fail on real collision"
  fail=1
else
  echo "ok   - make install-opencode fails on real collision"
fi
check "real collision dir preserved: agents/marker.txt" \
  [ -f "$CLIS/opencode/.config/opencode/agents/marker.txt" ]
check "collision not replaced by symlink" [ ! -L "$CLIS/opencode/.config/opencode/agents" ]

# 10. full `make -j install` on a fresh repo + HOME: Claude is built first
FULL_REPO="$TMP/full-repo"
FULL_GAI="$FULL_REPO/ai-clis/global-ai"
FULL_CLIS="$FULL_REPO/ai-clis/clis"
FULL_HOME="$TMP/full-home"
make_fixture "$FULL_GAI"

# stub omp so the real omp config is never written
STUB_BIN="$TMP/bin"
mkdir -p "$STUB_BIN"
cat > "$STUB_BIN/omp" <<EOF
#!/bin/sh
exit 0
EOF
chmod +x "$STUB_BIN/omp"

check "make -j install succeeds" \
  env HOME="$FULL_HOME" PATH="$STUB_BIN:$PATH" make -C "$FULL_GAI" -j4 install
check_link "~/.claude -> retained claude folder" \
  "$FULL_HOME/.claude" "$FULL_CLIS/claude/.claude"
check_link "opencode command -> ~/.claude/commands on the first install run" \
  "$FULL_CLIS/opencode/.config/opencode/command" "$FULL_HOME/.claude/commands"
check_link "~/.omp/agent/agents -> output/omp/agents" \
  "$FULL_HOME/.omp/agent/agents" "$FULL_GAI/output/omp/agents"

if [ "$fail" -ne 0 ]; then
  echo "install-test FAILED" >&2
  exit 1
fi
echo "install-test PASSED"
