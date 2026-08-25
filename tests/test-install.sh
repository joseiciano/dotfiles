#!/usr/bin/env bash
# Regression test for install.sh AI-CLI config ownership.
#
# Proves:
#   1. Unrelated .config trees (nvim, karabiner) are still linked.
#   2. AI CLI-owned .config trees (ai-clis/clis/{opencode,mimocode}) are skipped.
#   3. Legacy top-level $DOTFILES_DIR/opencode/.config and
#      $DOTFILES_DIR/mimocode/.config staging dirs are skipped exactly (not
#      other unrelated nested opencode/.config trees).
#   4. No ~/.claude link is created (owned by ai-clis/global-ai `make link`).
#   5. A nested unrelated opencode/.config tree is NOT skipped (proves the
#      legacy exclusion is anchored to exact root-level paths).
#   6. install.sh runs `make init` in ai-clis/global-ai (guarded on Makefile
#      presence so partial copies don't fail).
#
# Runs against a throwaway fixture repo + fake HOME; live HOME is not touched.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_INSTALL="$ROOT/install.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/install-test.XXXXXX")"
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
HOME_DIR="$TMP/home"
export HOME="$HOME_DIR"

# --- fixture repo ---
mkdir -p "$REPO"
cp "$REAL_INSTALL" "$REPO/install.sh"

# unrelated configs (must still be linked)
mkdir -p "$REPO/nvim/.config/nvim"
printf 'init\n' > "$REPO/nvim/.config/nvim/init.lua"
mkdir -p "$REPO/karabiner/.config/karabiner"
printf '{}\n' > "$REPO/karabiner/.config/karabiner/karabiner.json"

# legacy top-level staging dirs (must be skipped exactly)
mkdir -p "$REPO/opencode/.config/opencode"
printf 'x\n' > "$REPO/opencode/.config/opencode/opencode.json"
mkdir -p "$REPO/mimocode/.config/mimocode"
printf 'x\n' > "$REPO/mimocode/.config/mimocode/mimocode.json"

# nested unrelated opencode/.config (must NOT be skipped — proves anchoring)
mkdir -p "$REPO/tools/opencode/.config/nested-opencode"
printf 'deep\n' > "$REPO/tools/opencode/.config/nested-opencode/settings.json"

# minimal ai-clis/global-ai Makefile whose `init` records invocation under HOME
mkdir -p "$REPO/ai-clis/global-ai"
printf 'init:\n\tmkdir -p $(HOME)/.global-ai-init\n\ttouch $(HOME)/.global-ai-init/invoked\n' \
  > "$REPO/ai-clis/global-ai/Makefile"

# AI CLI-owned retained trees (must be skipped)
mkdir -p "$REPO/ai-clis/clis/opencode/.config/opencode"
printf 'x\n' > "$REPO/ai-clis/clis/opencode/.config/opencode/opencode.json"
mkdir -p "$REPO/ai-clis/clis/mimocode/.config/mimocode"
printf 'x\n' > "$REPO/ai-clis/clis/mimocode/.config/mimocode/mimocode.json"
mkdir -p "$REPO/ai-clis/clis/claude/.claude"
printf 'x\n' > "$REPO/ai-clis/clis/claude/.claude/settings.json"

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

# --- run ---
check "install.sh succeeds" bash "$REPO/install.sh"

# install.sh invoked `make init` in ai-clis/global-ai
check "install.sh runs make init for ai-clis/global-ai" \
  [ -f "$HOME_DIR/.global-ai-init/invoked" ]

# unrelated configs linked
check "~/.config/nvim linked" \
  [ "$(readlink "$HOME_DIR/.config/nvim")" = "$REPO/nvim/.config/nvim" ]
check "~/.config/karabiner linked" \
  [ "$(readlink "$HOME_DIR/.config/karabiner")" = "$REPO/karabiner/.config/karabiner" ]

# legacy root-level .config dirs skipped (exclusion anchored to exact repo paths)
check "no ~/.config/opencode (legacy root skipped)" [ ! -e "$HOME_DIR/.config/opencode" ]
check "no ~/.config/mimocode (legacy root skipped)" [ ! -e "$HOME_DIR/.config/mimocode" ]
check "no ~/.claude (AI-owned, not linked here)" [ ! -e "$HOME_DIR/.claude" ]

# nested unrelated opencode/.config linked (proves anchoring doesn't block it)
check "nested unrelated .config linked: ~/.config/nested-opencode" \
  [ "$(readlink "$HOME_DIR/.config/nested-opencode")" \
    = "$REPO/tools/opencode/.config/nested-opencode" ]

if [ "$fail" -ne 0 ]; then
  echo "install-test FAILED" >&2
  exit 1
fi
echo "install-test PASSED"
