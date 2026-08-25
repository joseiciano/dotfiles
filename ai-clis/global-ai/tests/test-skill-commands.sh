#!/usr/bin/env bash
# Regression test for skill-to-command generation in ai-clis/global-ai.
#
# Source skills under setup/skills-setup/skills/*/SKILL.md may carry a
# `command: true` frontmatter key. `make setup` must generate a matching
# command file `command/<skill-name>.md` (from the frontmatter `name`) into
# the CLIs that generate skill commands (opencode, claude-code, and mimocode
# via its opencode clone), with a fixed stub body that passes the user's raw
# arguments through to the skill.
#
# Proves:
#   1. A skill with `command: true` in frontmatter generates
#      command-enabled.md in output/opencode/command and
#      output/claude-code/command with the exact expected content.
#   2. Mimocode receives the generated command via its opencode clone
#      (`cp -R output/opencode output/mimocode`).
#   3. A skill with `command: false` generates nothing.
#   4. A skill whose BODY merely contains the literal text `command: true`
#      (frontmatter does not declare it) generates nothing.
#   5. Reasonix never receives generated skill commands (its command dir is
#      only seeded from setup/command-setup/command, never from skills).
#
# Isolated direct-generator regressions (invoke generate-skill-commands.sh on
# throwaway skill trees, never the live sources):
#   6. An enabled skill with `name: ../escaped` must fail the generator and
#      must not create any file outside the command output directory.
#   7. An enabled valid skill whose target command file already exists must
#      fail the generator and preserve the pre-existing command content.
#   8. Two enabled skill dirs declaring the same valid `name:` must fail the
#      generator rather than silently overwrite one another.
#   9. A SKILL.md whose frontmatter starts with `---` but never closes, with
#      body-like text later containing a top-level `command: true`, must fail
#      the generator and generate nothing.
#
# Runs against a throwaway fixture (real Makefile + setup tree + fixture
# skills), so live output/ and live sources are never mutated.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_MAKEFILE="$ROOT/Makefile"
REAL_SETUP="$ROOT/setup"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-ai-skill-commands-test.XXXXXX")"
# Resolve physical path so symlinked prefixes (/tmp -> /private/tmp) don't
# mismatch the absolute paths `make` computes internally.
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
HOME_DIR="$TMP/home"
export HOME="$HOME_DIR"

GAI="$REPO/ai-clis/global-ai"
SKILLS_SRC="$GAI/setup/skills-setup/skills"

# --- fixture: mirror real repo layout (Makefile + setup tree) ---
mkdir -p "$GAI"
cp "$REAL_MAKEFILE" "$GAI/Makefile"
cp -R "$REAL_SETUP" "$GAI/setup"

# --- fixture: three source skills ---
# 1. command-enabled: frontmatter declares command: true -> command generated.
mkdir -p "$SKILLS_SRC/command-enabled"
cat > "$SKILLS_SRC/command-enabled/SKILL.md" <<'MD'
---
name: command-enabled
description: Test skill enabled as a command.
command: true
---

Run the command-enabled skill with the user-provided arguments.
MD

# 2. command-disabled: frontmatter declares command: false -> no command.
mkdir -p "$SKILLS_SRC/command-disabled"
cat > "$SKILLS_SRC/command-disabled/SKILL.md" <<'MD'
---
name: command-disabled
description: Test skill disabled as a command.
command: false
---

Run the command-disabled skill with the user-provided arguments.
MD

# 3. body-only: frontmatter has no `command` key, but the BODY contains the
#    literal text `command: true`. Must NOT generate a command.
mkdir -p "$SKILLS_SRC/body-only"
cat > "$SKILLS_SRC/body-only/SKILL.md" <<'MD'
---
name: body-only
description: Test skill whose body mentions command: true.
---

Run the body-only skill with the user-provided arguments.

For reference, command: true appears in this body but never in the
frontmatter, so it must not enable a generated command.
MD

# --- fixture: expected generated command content (exact) ---
EXPECTED="$TMP/expected-command-enabled.md"
cat > "$EXPECTED" <<'EOF'
---
description: Runs command-enabled skill with given arguments
---

Run `command-enabled` skill with arguments: `$ARGUMENTS`
EOF

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

check_content() {
  local desc="$1" file="$2" expected="$3"
  if cmp -s "$file" "$expected"; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc"
    fail=1
  fi
}

check_fail() {
  local desc="$1"
  shift
  if ! "$@" >/dev/null 2>&1; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc"
    fail=1
  fi
}

# --- run ---
check "make setup succeeds" make -C "$GAI" setup

# --- 1. command-enabled generated for opencode and claude-code, exact content ---
for cli in opencode claude-code; do
  cmd="$GAI/output/$cli/command/command-enabled.md"
  check "$cli command generated: command-enabled.md" [ -f "$cmd" ]
  check_content "$cli command content matches exactly" "$cmd" "$EXPECTED"
done

# --- 2. mimocode receives it via the opencode clone ---
mimo_cmd="$GAI/output/mimocode/command/command-enabled.md"
check "mimocode (opencode clone) command generated: command-enabled.md" [ -f "$mimo_cmd" ]
check_content "mimocode command content matches exactly" "$mimo_cmd" "$EXPECTED"

# --- 3/4. disabled and body-only commands are absent everywhere ---
for cli in opencode claude-code mimocode; do
  check "$cli has no command for command: false skill" \
    [ ! -e "$GAI/output/$cli/command/command-disabled.md" ]
  check "$cli has no command for body-only skill" \
    [ ! -e "$GAI/output/$cli/command/body-only.md" ]
done

# --- 5. reasonix never receives generated skill commands ---
check "reasonix has no generated command: command-enabled.md" \
  [ ! -e "$GAI/output/reasonix/command/command-enabled.md" ]
check "reasonix command dir exactly mirrors seeded command-setup" \
  diff -r "$GAI/setup/command-setup/command" "$GAI/output/reasonix/command"

# ==========================================================================
# Isolated direct-generator regressions. Each case runs the real generator
# against its own throwaway skill tree + output dir.
# ==========================================================================
GEN="$GAI/setup/skills-setup/generate-skill-commands.sh"

# --- 6. enabled skill whose name escapes the output directory ---
TRAVERSAL_DIR="$TMP/traversal"
mkdir -p "$TRAVERSAL_DIR/skills/escape-attempt"
cat > "$TRAVERSAL_DIR/skills/escape-attempt/SKILL.md" <<'MD'
---
name: ../escaped
description: Skill whose name tries to escape the command output directory.
command: true
---

Run me.
MD
mkdir -p "$TRAVERSAL_DIR/out"

check_fail "generator rejects name escaping output dir (../escaped)" \
  "$GEN" "$TRAVERSAL_DIR/skills" "$TRAVERSAL_DIR/out"
check "no file created outside output dir by ../escaped name" \
  [ ! -e "$TRAVERSAL_DIR/escaped.md" ]

# --- 7. enabled skill whose target command file already exists ---
PREEXIST_DIR="$TMP/preexist"
mkdir -p "$PREEXIST_DIR/skills/clobber-attempt"
cat > "$PREEXIST_DIR/skills/clobber-attempt/SKILL.md" <<'MD'
---
name: clobber
description: Skill whose command target already exists.
command: true
---

Run me.
MD
mkdir -p "$PREEXIST_DIR/out"
PREEXISTING="$PREEXIST_DIR/out/clobber.md"
cat > "$PREEXISTING" <<'EOF'
This command already exists and must be preserved exactly.
EOF
cp "$PREEXISTING" "$PREEXIST_DIR/existing-expected.md"

check_fail "generator rejects overwriting existing command file (clobber.md)" \
  "$GEN" "$PREEXIST_DIR/skills" "$PREEXIST_DIR/out"
check_content "existing command file content preserved" \
  "$PREEXISTING" "$PREEXIST_DIR/existing-expected.md"

# --- 8. two enabled skills declaring the same name ---
DUP_DIR="$TMP/duplicate-name"
mkdir -p "$DUP_DIR/skills/dup-a" "$DUP_DIR/skills/dup-b"
for dup in dup-a dup-b; do
  cat > "$DUP_DIR/skills/$dup/SKILL.md" <<'MD'
---
name: same-name
description: Duplicate skill name.
command: true
---

Run me.
MD
done
mkdir -p "$DUP_DIR/out"

check_fail "generator rejects duplicate skill names (same-name)" \
  "$GEN" "$DUP_DIR/skills" "$DUP_DIR/out"

# --- 9. SKILL.md with unclosed frontmatter; body-like text has command: true ---
UNCLOSED_DIR="$TMP/unclosed-frontmatter"
mkdir -p "$UNCLOSED_DIR/skills/unclosed-skill"
cat > "$UNCLOSED_DIR/skills/unclosed-skill/SKILL.md" <<'MD'
---
name: unclosed
description: Skill with frontmatter that never closes.

Body-like text after the missing closing delimiter.
command: true
MD
mkdir -p "$UNCLOSED_DIR/out"

check_fail "generator rejects SKILL.md with unclosed frontmatter" \
  "$GEN" "$UNCLOSED_DIR/skills" "$UNCLOSED_DIR/out"
check "nothing generated for unclosed-frontmatter skill" \
  [ ! -e "$UNCLOSED_DIR/out/unclosed.md" ]

if [ "$fail" -ne 0 ]; then
  echo "skill-commands-test FAILED" >&2
  exit 1
fi
echo "skill-commands-test PASSED"
