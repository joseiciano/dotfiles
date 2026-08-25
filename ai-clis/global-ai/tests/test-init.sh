#!/usr/bin/env bash
# End-to-end regression test for `make init` in ai-clis/global-ai.
#
# Proves:
#   1. `make -j init` runs setup fully before link (parallel-safe ordering).
#   2. `make init` populates retained per-CLI config folders under
#      ai-clis/clis/ (opencode, claude, mimocode) with symlinks to generated
#      output (correct targets), not copies, no staging under $HOME/dotfiles.
#   3. Non-generated files already present in retained folders survive.
#   4. Stale symlinks whose target belongs to this output root and no longer
#      exists are removed; symlinks whose target still exists under the same
#      root, symlinks under a different output root, unrelated symlinks, and
#      real files/dirs are all preserved.
#   5. Each whole retained folder is symlinked to its real HOME config path.
#   6. No $HOME/dotfiles/{opencode,claude,mimocode} staging dirs are created.
#   7. Reasonix remains linked directly into $HOME/.reasonix.
#   8. `make init` is idempotent.
#
# Runs against a throwaway fixture (fake repo layout + fake HOME), so live
# HOME and live ai-clis/clis retained folders are never mutated.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_MAKEFILE="$ROOT/Makefile"
REAL_SETUP="$ROOT/setup"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-ai-init-test.XXXXXX")"
# Resolve physical path so symlinked prefixes (/tmp -> /private/tmp) don't
# mismatch the absolute paths `make` computes internally.
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
HOME_DIR="$TMP/home"
export HOME="$HOME_DIR"

GAI="$REPO/ai-clis/global-ai"
CLIS="$REPO/ai-clis/clis"

# --- fixture: mirror real repo layout (Makefile + setup tree) ---
mkdir -p "$GAI"
cp "$REAL_MAKEFILE" "$GAI/Makefile"
cp -R "$REAL_SETUP" "$GAI/setup"

# retained per-CLI config folders with non-generated files that must survive
mkdir -p "$CLIS/opencode/.config/opencode"
printf '{"custom":true}\n' > "$CLIS/opencode/.config/opencode/custom.jsonc"
mkdir -p "$CLIS/claude/.claude"
printf '{"theme":"x"}\n' > "$CLIS/claude/.claude/settings.json"
mkdir -p "$CLIS/mimocode/.config/mimocode"
printf '{"base":true}\n' > "$CLIS/mimocode/.config/mimocode/mimocode-base.json"

# stale symlinks pointing into the output root (targets never exist even after setup)
ln -s "$GAI/output/opencode/stale-cmd" "$CLIS/opencode/.config/opencode/stale-cmd"

# symlink under the matching output root whose target setup will create: must be kept
ln -s "$GAI/output/opencode/agents" "$CLIS/opencode/.config/opencode/keep-live-root"

# symlink whose (missing) target lives under a DIFFERENT output root: must be kept
ln -s "$GAI/output/claude-code/stale" "$CLIS/opencode/.config/opencode/cross-root"

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
check "make -j init succeeds" make -C "$GAI" -j4 init

# 1. generated entries linked inside retained folders with correct targets
for e in agents command plugins skills; do
  check_link "opencode generated entry: $e" \
    "$CLIS/opencode/.config/opencode/$e" "$GAI/output/opencode/$e"
done
check_link "opencode generated file: opencode.json" \
  "$CLIS/opencode/.config/opencode/opencode.json" "$GAI/output/opencode/opencode.json"
check_link "opencode generated file: opencode-fallback.jsonc" \
  "$CLIS/opencode/.config/opencode/opencode-fallback.jsonc" "$GAI/output/opencode/opencode-fallback.jsonc"
for e in agents command skills; do
  check_link "claude generated entry: $e" \
    "$CLIS/claude/.claude/$e" "$GAI/output/claude-code/$e"
done
for e in agents command plugins skills; do
  check_link "mimocode generated entry: $e" \
    "$CLIS/mimocode/.config/mimocode/$e" "$GAI/output/mimocode/$e"
done
check_link "mimocode generated file: mimocode.json" \
  "$CLIS/mimocode/.config/mimocode/mimocode.json" "$GAI/output/mimocode/mimocode.json"
check_link "mimocode generated file: opencode-fallback.jsonc" \
  "$CLIS/mimocode/.config/mimocode/opencode-fallback.jsonc" "$GAI/output/mimocode/opencode-fallback.jsonc"

# 2. non-generated files preserved in retained folders
check "opencode custom file preserved" [ -f "$CLIS/opencode/.config/opencode/custom.jsonc" ]
check "claude settings preserved" [ -f "$CLIS/claude/.claude/settings.json" ]
check "mimocode base file preserved" [ -f "$CLIS/mimocode/.config/mimocode/mimocode-base.json" ]

# 3. stale symlinks removed (asserted via ! -L: a dangling symlink would
#    otherwise satisfy ! -e), matching-root live-target + different-root
#    symlinks preserved, unrelated symlink + real dir preserved
check "stale symlink removed: stale-cmd" [ ! -L "$CLIS/opencode/.config/opencode/stale-cmd" ]
check_link "matching-root symlink with live target preserved: keep-live-root" \
  "$CLIS/opencode/.config/opencode/keep-live-root" "$GAI/output/opencode/agents"
check_link "different-root symlink preserved: cross-root" \
  "$CLIS/opencode/.config/opencode/cross-root" "$GAI/output/claude-code/stale"
check_link "unrelated symlink preserved: keep-x" \
  "$CLIS/opencode/.config/opencode/keep-x" "$TMP/ext-target"
check "real dir preserved: real-d" [ -f "$CLIS/opencode/.config/opencode/real-d/keep.txt" ]

# 4. whole retained folders linked into HOME
check "~/.config/opencode -> retained folder" \
  [ "$(readlink "$HOME_DIR/.config/opencode")" = "$CLIS/opencode/.config/opencode" ]
check "~/.claude -> retained folder" \
  [ "$(readlink "$HOME_DIR/.claude")" = "$CLIS/claude/.claude" ]
check "~/.config/mimocode -> retained folder" \
  [ "$(readlink "$HOME_DIR/.config/mimocode")" = "$CLIS/mimocode/.config/mimocode" ]

# 5. no $HOME/dotfiles staging dirs
for d in opencode claude mimocode; do
  check "no ~/dotfiles/$d staging dir" [ ! -e "$HOME_DIR/dotfiles/$d" ]
done

# 6. reasonix still linked directly
check "~/.reasonix/commands linked" \
  [ "$(readlink "$HOME_DIR/.reasonix/commands")" = "$GAI/output/reasonix/command" ]

# 7. idempotency (also -j)
check "make -j init idempotent" make -C "$GAI" -j4 init
check "~/.config/opencode still linked after 2nd run" \
  [ "$(readlink "$HOME_DIR/.config/opencode")" = "$CLIS/opencode/.config/opencode" ]

# 8. real collision: setup succeeds, link fails, real entry survives
rm -f "$CLIS/opencode/.config/opencode/agents"
mkdir -p "$CLIS/opencode/.config/opencode/agents"
printf 'real\n' > "$CLIS/opencode/.config/opencode/agents/marker.txt"
if make -C "$GAI" -j4 init >/dev/null 2>&1; then
  echo "FAIL - make init should fail on real collision"
  fail=1
else
  echo "ok   - make init fails on real collision"
fi
check "real collision dir preserved: agents/marker.txt" \
  [ -f "$CLIS/opencode/.config/opencode/agents/marker.txt" ]
check "collision not replaced by symlink" [ ! -L "$CLIS/opencode/.config/opencode/agents" ]

if [ "$fail" -ne 0 ]; then
  echo "init-test FAILED" >&2
  exit 1
fi
echo "init-test PASSED"
