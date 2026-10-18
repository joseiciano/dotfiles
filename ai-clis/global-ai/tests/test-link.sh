#!/usr/bin/env bash
# Regression test for `make link-opencode` in ai-clis/global-ai.
#
#   1. Generated output entries are symlinked inside the retained opencode
#      folder under ai-clis/clis/, with targets pointing at the real output
#      paths. Claude is linked by `make link-claude`, not here.
#   2. Non-generated files already present in retained folders survive.
#   3. Stale symlinks whose target belongs to this output root and no longer
#      exists are removed; symlinks whose target still exists under the same
#      root, symlinks under a different output root, unrelated symlinks, and
#      real files/dirs are all preserved.
#   4. The whole retained folder is symlinked to its real HOME config path.
#   5. No $HOME/dotfiles/opencode staging dir is created.
#   6. `make link-opencode` is idempotent.
#   7. A real file/dir colliding with a generated entry name is never deleted;
#      `make link-opencode` fails clearly instead.
#
# Runs against a throwaway fixture (fake repo layout + fake HOME), so live
# HOME and live ai-clis/clis retained folders are never mutated.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_MAKEFILE="$ROOT/Makefile"
REAL_MAKE_DIR="$ROOT/make"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-ai-link-test.XXXXXX")"
# Resolve physical path so symlinked prefixes (/tmp -> /private/tmp) don't
# mismatch the absolute paths `make` computes internally.
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
HOME_DIR="$TMP/home"
export HOME="$HOME_DIR"

GAI="$REPO/ai-clis/global-ai"
CLIS="$REPO/ai-clis/clis"

# --- fixture: mirror real repo layout (ai-clis/global-ai + ai-clis/clis) ---
mkdir -p "$GAI"
cp "$REAL_MAKEFILE" "$GAI/Makefile"
cp -R "$REAL_MAKE_DIR" "$GAI/make"

# generated output fixture
mkdir -p "$GAI/output/opencode/agents" "$GAI/output/opencode/extra-dir"
printf '{"v":1}\n' > "$GAI/output/opencode/opencode.json"

# retained opencode config folder with non-generated files that must survive
mkdir -p "$CLIS/opencode/.config/opencode"
printf '{"custom":true}\n' > "$CLIS/opencode/.config/opencode/custom.jsonc"

# stale symlinks pointing into the output root (targets never exist)
ln -s "$GAI/output/opencode/stale-command" "$CLIS/opencode/.config/opencode/stale-command"
ln -s "$GAI/output/opencode/old.json" "$CLIS/opencode/.config/opencode/old.json"

# symlink under the matching output root whose target still exists: must be kept
ln -s "$GAI/output/opencode/agents" "$CLIS/opencode/.config/opencode/keep-live-root"

# symlink whose (missing) target lives under a DIFFERENT output root: must be kept
ln -s "$GAI/output/claude/stale" "$CLIS/opencode/.config/opencode/cross-root"

# unrelated symlink + real dir that must survive reconciliation
printf 'external\n' > "$TMP/external-target"
ln -s "$TMP/external-target" "$CLIS/opencode/.config/opencode/keep-extra"
mkdir -p "$CLIS/opencode/.config/opencode/real-dir"
printf 'real\n' > "$CLIS/opencode/.config/opencode/real-dir/keep.txt"

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
check "make link-opencode succeeds" make -C "$GAI" link-opencode

# 1. generated entries linked inside retained folders with correct targets
for e in agents extra-dir; do
  check_link "opencode generated entry: $e" \
    "$CLIS/opencode/.config/opencode/$e" "$GAI/output/opencode/$e"
done
check_link "opencode generated file: opencode.json" \
  "$CLIS/opencode/.config/opencode/opencode.json" "$GAI/output/opencode/opencode.json"

# 2. non-generated files preserved in retained folders
check "opencode custom file preserved" [ -f "$CLIS/opencode/.config/opencode/custom.jsonc" ]

# 3. stale symlinks removed (asserted via ! -L: a dangling symlink would
#    otherwise satisfy ! -e), matching-root live-target + different-root
#    symlinks preserved, unrelated symlink + real dir preserved
check "stale symlink removed: stale-command" [ ! -L "$CLIS/opencode/.config/opencode/stale-command" ]
check "stale symlink removed: old.json" [ ! -L "$CLIS/opencode/.config/opencode/old.json" ]
check_link "matching-root symlink with live target preserved: keep-live-root" \
  "$CLIS/opencode/.config/opencode/keep-live-root" "$GAI/output/opencode/agents"
check_link "different-root symlink preserved: cross-root" \
  "$CLIS/opencode/.config/opencode/cross-root" "$GAI/output/claude/stale"
check_link "unrelated symlink preserved: keep-extra" \
  "$CLIS/opencode/.config/opencode/keep-extra" "$TMP/external-target"
check "real dir preserved: real-dir" [ -f "$CLIS/opencode/.config/opencode/real-dir/keep.txt" ]

# 4. whole retained folder linked into HOME
check "~/.config/opencode -> retained folder" \
  [ "$(readlink "$HOME_DIR/.config/opencode")" = "$CLIS/opencode/.config/opencode" ]

check "no ~/dotfiles/opencode staging dir" [ ! -e "$HOME_DIR/dotfiles/opencode" ]

# 6. idempotency
check "make link-opencode idempotent" make -C "$GAI" link-opencode
check "~/.config/opencode still linked after 2nd run" \
  [ "$(readlink "$HOME_DIR/.config/opencode")" = "$CLIS/opencode/.config/opencode" ]

# 7. real collision on a generated entry name: fail, preserve the real entry

rm -f "$CLIS/opencode/.config/opencode/agents"
mkdir -p "$CLIS/opencode/.config/opencode/agents"
printf 'real\n' > "$CLIS/opencode/.config/opencode/agents/marker.txt"
if make -C "$GAI" link-opencode >/dev/null 2>&1; then
  echo "FAIL - make link-opencode should fail on real collision"
  fail=1
else
  echo "ok   - make link-opencode fails on real collision"
fi
check "real collision dir preserved: agents/marker.txt" \
  [ -f "$CLIS/opencode/.config/opencode/agents/marker.txt" ]
check "collision not replaced by symlink" [ ! -L "$CLIS/opencode/.config/opencode/agents" ]

if [ "$fail" -ne 0 ]; then
  echo "link-test FAILED" >&2
  exit 1
fi
echo "link-test PASSED"

