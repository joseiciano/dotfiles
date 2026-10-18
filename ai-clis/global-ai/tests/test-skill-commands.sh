#!/usr/bin/env bash
# Regression test for skill-to-command generation in `make build-claude`.
#
# Skills and commands are built once, by `make build-claude`, into
# output/claude/skills and output/claude/commands; opencode and oh-my-pi read
# them from ~/.claude. Source skills under setup/skills-setup/skills/*/SKILL.md
# may carry a `command: true` frontmatter key, which must generate
# output/claude/commands/<skill-name>.md (from the frontmatter `name`) with a fixed
# stub body that passes the user's raw arguments through to the skill.
#
# Proves:
#   1. A skill with `command: true` in frontmatter generates
#      output/claude/commands/command-enabled.md with exact content.
#   2. A skill with `command: false` generates nothing.
#   3. A skill whose BODY merely contains the literal text `command: true`
#      (frontmatter does not declare it) generates nothing.
#   4. The output skill copies have `command: true` stripped from their
#      frontmatter and otherwise match the source byte-for-byte; the source
#      skill keeps the key.
#   5. Stripping preserves `command: false` keys and body text, including the
#      literal `command: true` in the body-only fixture.
#   6. Seeded commands from setup/command-setup/command are copied into
#      output/claude/commands alongside generated ones.
#   7. build-claude renames nothing: every source skill is published under
#      its source dir name.
#  7a. Every setup/skills-setup/addyskills/skills/<skill>/ dir is copied into
#      output/claude/skills alongside the own skills, with links into
#      addyskills/references/ inlined into the skill's own references/;
#      addyskills/README.md is not copied. (copy-skills.js details live in
#      test-copy-skills.sh.)
#  7b. Every setup/skills-setup/mattskills/skills/<skill>/ dir (with its
#      sidecar files) is copied into output/claude/skills alongside the
#      others; mattskills/README.md is not copied.
#  7c. Every setup/skills-setup/pstack/skills/<skill>/ dir (with its
#      references/) is copied into output/claude/skills alongside the others;
#      pstack/README.md is not copied.
#
# Every skill source dir that make/claude.mk passes to copy-skills.js is
# emptied in the fixture, so a newly added source cannot leak live skills into
# the exact listings below.
#   8. Without a seeded command folder, `make build-claude` still succeeds
#      and output/claude/commands holds only generated commands (the rebuild
#      drops the stale seeded command).
#   9. The Agent spawn-policy hook is built at the path settings.json runs
#      (output/claude/hooks/enforce-agent-spawn-policy.sh) and still enforces
#      the policy from there.
#
# Isolated direct-generator regressions (invoke generate-skill-commands.sh on
# throwaway skill trees, never the live sources):
#  10. An enabled skill with `name: ../escaped` must fail the generator and
#      must not create any file outside the command output directory.
#  11. An enabled valid skill whose target command file already exists must
#      fail the generator and preserve the pre-existing command content.
#  12. Two enabled skill dirs declaring the same valid `name:` must fail the
#      generator rather than silently overwrite one another.
#  13. A SKILL.md whose frontmatter starts with `---` but never closes, with
#      body-like text later containing a top-level `command: true`, must fail
#      the generator and generate nothing.
#
# Runs against a throwaway fixture (real Makefile, make/ and setup trees +
# fixture skills), so live output/, live sources, and HOME are never mutated.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-ai-skill-commands-test.XXXXXX")"
# Resolve physical path so symlinked prefixes (/tmp -> /private/tmp) don't
# mismatch the absolute paths `make` computes internally.
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
export HOME="$TMP/home"

GAI="$REPO/ai-clis/global-ai"
SKILLS_SRC="$GAI/setup/skills-setup/skills"
SEEDED="$GAI/setup/command-setup/command"
ADDY_SRC="$GAI/setup/skills-setup/addyskills"
MATT_SRC="$GAI/setup/skills-setup/mattskills"
PSTACK_SRC="$GAI/setup/skills-setup/pstack"

# --- fixture: mirror real repo layout (Makefile, make/ and setup trees) ---
mkdir -p "$GAI"
cp "$ROOT/Makefile" "$GAI/Makefile"
cp -R "$ROOT/make" "$GAI/make"
cp -R "$ROOT/setup" "$GAI/setup"

# Replace the live skills with fixtures only, so the expected skill and
# command sets are exactly known. Every source dir build-claude copies skills
# from (read from the copy-skills.js calls in make/claude.mk) is emptied first;
# the named source roots are then rebuilt below from fixtures. A live seeded
# folder (if any) is replaced by a fixture one.
SKILL_SOURCES="$(grep -oE 'copy-skills\.js \$\(SKILLS_SETUP\)/[^ ]+' "$GAI/make/claude.mk" \
  | sed -E 's#^copy-skills\.js \$\(SKILLS_SETUP\)/##' | LC_ALL=C sort -u)"
case " $(echo $SKILL_SOURCES) " in
  *" skills "*) ;;
  *) echo "FAIL - could not read skill sources from make/claude.mk (got: $(echo $SKILL_SOURCES))" >&2; exit 1 ;;
esac
for src in $SKILL_SOURCES; do
  [ -d "$GAI/setup/skills-setup/$src" ] || { echo "FAIL - make/claude.mk skill source missing: $src" >&2; exit 1; }
  rm -rf "${GAI:?}/setup/skills-setup/$src"
  mkdir -p "$GAI/setup/skills-setup/$src"
done
rm -rf "$SKILLS_SRC" "$SEEDED" "$ADDY_SRC" "$MATT_SRC" "$PSTACK_SRC"
mkdir -p "$SKILLS_SRC" "$SEEDED" "$ADDY_SRC" "$MATT_SRC" "$PSTACK_SRC"

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

# 7a. imported addyskills (upstream layout): skills/<skill>/ + shared
#     references/ + a README.md that is not a skill.
mkdir -p "$ADDY_SRC/skills/addy-alpha/references" "$ADDY_SRC/skills/addy-beta" \
  "$ADDY_SRC/references"
cat > "$ADDY_SRC/skills/addy-alpha/SKILL.md" <<'MD'
---
name: addy-alpha
description: Imported skill with its own checklist and a shared one.
---

See [the checklist](references/checklist.md) and
[the shared checklist](../../references/shared-checklist.md).
MD
cat > "$ADDY_SRC/skills/addy-alpha/references/checklist.md" <<'MD'
- [ ] Imported checklist item.
MD
cat > "$ADDY_SRC/references/shared-checklist.md" <<'MD'
- [ ] Shared checklist item.
MD
cat > "$ADDY_SRC/skills/addy-beta/SKILL.md" <<'MD'
---
name: addy-beta
description: Second imported skill.
---

Run addy-beta.
MD
cat > "$ADDY_SRC/README.md" <<'MD'
# addyskills (imported) -- not a skill
MD

# 7b. imported mattskills: skills/<skill>/ with a sidecar doc + a README.md
#     that is not a skill.
mkdir -p "$MATT_SRC/skills/matt-gamma"
cat > "$MATT_SRC/skills/matt-gamma/SKILL.md" <<'MD'
---
name: matt-gamma
description: Imported mattskills skill with a sidecar doc.
---

Read [the format](FORMAT.md).
MD
cat > "$MATT_SRC/skills/matt-gamma/FORMAT.md" <<'MD'
Sidecar format doc.
MD
cat > "$MATT_SRC/README.md" <<'MD'
# mattskills (imported) -- not a skill
MD

# 7c. imported pstack: skills/<skill>/ with a references/ doc + a README.md
#     that is not a skill.
mkdir -p "$PSTACK_SRC/skills/pstack-delta/references"
cat > "$PSTACK_SRC/skills/pstack-delta/SKILL.md" <<'MD'
---
name: pstack-delta
description: Imported pstack skill with a reference doc.
---

Read [the prompt](references/prompt.md).
MD
cat > "$PSTACK_SRC/skills/pstack-delta/references/prompt.md" <<'MD'
Reference prompt.
MD
cat > "$PSTACK_SRC/README.md" <<'MD'
# pstack (imported) -- not a skill
MD

# 6. seeded command copied verbatim.
cat > "$SEEDED/seeded-cmd.md" <<'MD'
---
description: A hand-written seeded command
---

Do the seeded thing.
MD

# --- expected generated command content (exact) ---
EXPECTED="$TMP/expected-command-enabled.md"
cat > "$EXPECTED" <<'EOF'
---
description: Calls command-enabled skill with given arguments
---

Call the `command-enabled` skill with the following `$ARGUMENTS`:
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

check_listing() {
  local desc="$1" dir="$2" expected="$3" actual
  actual="$(cd "$dir" 2>/dev/null && LC_ALL=C ls -1 | tr '\n' ' ')" || true
  if [ "$actual" = "$expected" ]; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc (got: $actual; want: $expected)"
    fail=1
  fi
}

OUT_CMDS="$GAI/output/claude/commands"
OUT_SKILLS="$GAI/output/claude/skills"
OUT_HOOK="$GAI/output/claude/hooks/enforce-agent-spawn-policy.sh"

# --- run ---
check "make build-claude succeeds" make -C "$GAI" build-claude

# --- 1. command-enabled generated, exact content ---
check_content "command generated with exact content: command-enabled.md" \
  "$OUT_CMDS/command-enabled.md" "$EXPECTED"

# --- 2/3/6. exact command set: no disabled/body-only entries ---
check_listing "output/claude/commands holds generated + seeded commands only" \
  "$OUT_CMDS" "command-enabled.md seeded-cmd.md "
check_content "seeded command copied verbatim" \
  "$OUT_CMDS/seeded-cmd.md" "$SEEDED/seeded-cmd.md"

# --- 7/7a. own + imported skills under their source names; README.md is not ---
check_listing "output/claude/skills holds own + addyskills + mattskills + pstack skills, no README.md" \
  "$OUT_SKILLS" "addy-alpha addy-beta body-only command-disabled command-enabled matt-gamma pstack-delta "
check "pstack skill copied with its references/ verbatim" \
  diff -r "$PSTACK_SRC/skills/pstack-delta" "$OUT_SKILLS/pstack-delta"
check_listing "mattskills skill copied with its sidecar files" \
  "$OUT_SKILLS/matt-gamma" "FORMAT.md SKILL.md "
check_content "mattskills skill copied verbatim" \
  "$OUT_SKILLS/matt-gamma/SKILL.md" "$MATT_SRC/skills/matt-gamma/SKILL.md"
check_content "imported skill keeps its own references/ file" \
  "$OUT_SKILLS/addy-alpha/references/checklist.md" \
  "$ADDY_SRC/skills/addy-alpha/references/checklist.md"
check_content "imported skill's shared checklist inlined into its references/" \
  "$OUT_SKILLS/addy-alpha/references/shared-checklist.md" \
  "$ADDY_SRC/references/shared-checklist.md"
check "imported skill links the inlined copy, not the shared dir" \
  grep -qF '(references/shared-checklist.md)' "$OUT_SKILLS/addy-alpha/SKILL.md"
check_content "second addyskills skill copied verbatim" \
  "$OUT_SKILLS/addy-beta/SKILL.md" "$ADDY_SRC/skills/addy-beta/SKILL.md"

# --- 4/5. output skills stripped of command: true; sources and bodies intact ---
STRIP_EXPECTED="$TMP/expected-stripped-command-enabled.md"
grep -v '^command: true$' "$SKILLS_SRC/command-enabled/SKILL.md" > "$STRIP_EXPECTED"
check_content "output skill stripped exactly: command-enabled" \
  "$OUT_SKILLS/command-enabled/SKILL.md" "$STRIP_EXPECTED"
check_content "output skill keeps command: false: command-disabled" \
  "$OUT_SKILLS/command-disabled/SKILL.md" "$SKILLS_SRC/command-disabled/SKILL.md"
check_content "output body-only skill unchanged" \
  "$OUT_SKILLS/body-only/SKILL.md" "$SKILLS_SRC/body-only/SKILL.md"
check "source skill keeps command: true (stripping touches output only)" \
  grep -q '^command: true$' "$SKILLS_SRC/command-enabled/SKILL.md"

# --- 8. no seeded folder: rebuild yields generated commands only ---
rm -rf "$SEEDED"
check "make build-claude succeeds without seeded command folder" make -C "$GAI" build-claude
check_listing "rebuild drops stale seeded command, keeps generated" \
  "$OUT_CMDS" "command-enabled.md "

# --- 9. built hook enforces the spawn policy from the settings.json path ---
# Exit status of the built hook for one PreToolUse Agent payload.
hook_status() {
  local status=0
  printf '%s\n' "{\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"Agent\",\"tool_input\":{\"subagent_type\":\"$1\"}}" \
    | LC_ALL=C "$OUT_HOOK" >/dev/null 2>&1 || status=$?
  echo "$status"
}
check "built hook allows parent scout spawn" [ "$(hook_status scout)" = 0 ]
check "built hook denies parent councillor spawn (exit 2)" [ "$(hook_status councillor)" = 2 ]

# ==========================================================================
# Isolated direct-generator regressions. Each case runs the real generator
# against its own throwaway skill tree + output dir.
# ==========================================================================
GEN="$GAI/setup/skills-setup/generate-skill-commands.sh"

# --- 10. enabled skill whose name escapes the output directory ---
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

# --- 11. enabled skill whose target command file already exists ---
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

# --- 12. two enabled skills declaring the same name ---
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

# --- 13. SKILL.md with unclosed frontmatter; body-like text has command: true ---
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
