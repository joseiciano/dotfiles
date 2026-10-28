#!/usr/bin/env bash
# Regression test for setup/skills-setup/copy-skills.js, run directly on
# throwaway skill trees (never the live sources or output/).
#
# Proves:
#   1. Every folder with a SKILL.md is copied; other entries (README.md, a
#      folder without SKILL.md) are skipped.
#   2. With --references, a `../../references/<f>.md` link in SKILL.md (as a
#      markdown link, or a backticked path with a #anchor as upstream writes
#      them) is rewritten to `references/<f>.md`, and the shared file is
#      copied there byte-for-byte.
#   3. A `../../../references/<f>.md` link in a skill's nested references/ file
#      is rewritten to `<f>.md`, and the shared file is copied next to it.
#   4. Shared files linked from both SKILL.md and a nested file are copied
#      once and every link points at that one copy; the run succeeds.
#   5. A link matching the pattern but resolving outside the shared dir (here
#      `../references/own.md` from a nested file, which is the skill's own
#      file) is left untouched.
#   6. No .md link or backticked .md path in the output resolves outside its
#      own skill, and each resolves to an existing file.
#   7. A link to a missing shared file fails the run.
#   8. A skill that already has a different file with a shared file's name
#      fails the run.
#   9. A second run that would add an existing skill name fails, and the first
#      run's copy is left intact.
#  10. A link that climbs out of the skill and back down through intermediate
#      folders (`../../../../../addy/references/<f>.md` from a nested
#      references/<sub>/guide.md, as own skills link setup/references) is
#      inlined into the skill's references/ and rewritten relative to the
#      linking file; the same shape from SKILL.md is rewritten too.
#  11. An intermediate-folder link to an existing file outside the shared dir
#      (`.../other/references/x.md`) is left untouched and not copied.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COPY="$ROOT/setup/skills-setup/copy-skills.js"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-ai-copy-skills-test.XXXXXX")"
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

fail=0
ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1"; fail=1; }
check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else bad "$desc"; fi
}
# Runs copy-skills.js, expecting failure with stderr containing $2.
check_run_fails() {
  local desc="$1" needle="$2" status=0
  shift 2
  bun "$COPY" "$@" >/dev/null 2>"$TMP/err" || status=$?
  if [ "$status" -ne 0 ] && grep -qF -- "$needle" "$TMP/err"; then
    ok "$desc"
  else
    bad "$desc (status $status; stderr: $(cat "$TMP/err"))"
  fi
}
check_listing() {
  local desc="$1" dir="$2" expected="$3" actual
  actual="$(cd "$dir" && LC_ALL=C ls -1 | tr '\n' ' ')"
  if [ "$actual" = "$expected" ]; then ok "$desc"; else bad "$desc (got: $actual; want: $expected)"; fi
}

skill_md() { # skill_md <dir> <body>
  mkdir -p "$1"
  printf -- '---\nname: %s\ndescription: fixture\n---\n\n%s\n' "$(basename "$1")" "$2" > "$1/SKILL.md"
}

# --- fixture: upstream layout ---
SRC="$TMP/addy/skills"
SHARED="$TMP/addy/references"
OUT="$TMP/out"
mkdir -p "$SHARED"
printf '%s\n' '- [ ] security item' > "$SHARED/security.md"
printf '%s\n' '- [ ] perf item' > "$SHARED/perf.md"

skill_md "$SRC/alpha" 'See [security](../../references/security.md), `../../references/perf.md#core`, and [patterns](references/patterns.md).'
mkdir -p "$SRC/alpha/references"
cat > "$SRC/alpha/references/patterns.md" <<'MD'
Baseline: [security](../../../references/security.md) and
[perf](../../../references/perf.md). Also see [own](../references/own.md).
MD
printf '%s\n' 'own notes' > "$SRC/alpha/references/own.md"
skill_md "$SRC/beta" 'Plain skill, no links.'
mkdir -p "$SRC/not-a-skill"
printf '%s\n' 'no SKILL.md here' > "$SRC/not-a-skill/notes.md"
printf '%s\n' '# not a skill' > "$SRC/README.md"

check "copy with --references succeeds" bun "$COPY" "$SRC" "$OUT" --references "$SHARED"

# --- 1. only SKILL.md folders copied ---
check_listing "only folders with SKILL.md are copied" "$OUT" "alpha beta "

# --- 2. SKILL.md link inlined ---
check "SKILL.md link rewritten to references/security.md" \
  grep -qF '[security](references/security.md)' "$OUT/alpha/SKILL.md"
check "backticked SKILL.md path rewritten, #anchor kept" \
  grep -qF '`references/perf.md#core`' "$OUT/alpha/SKILL.md"
check "inlined copy from SKILL.md equals the shared file" \
  cmp -s "$OUT/alpha/references/security.md" "$SHARED/security.md"

# --- 3. nested link inlined ---
check "nested link rewritten to perf.md" \
  grep -qF '[perf](perf.md)' "$OUT/alpha/references/patterns.md"
check "inlined copy from nested file equals the shared file" \
  cmp -s "$OUT/alpha/references/perf.md" "$SHARED/perf.md"

# --- 4. shared file linked twice is copied once; both links hit it ---
check "nested link to an already-inlined file rewritten to security.md" \
  grep -qF '[security](security.md)' "$OUT/alpha/references/patterns.md"
check_listing "alpha/references holds own files plus one copy per shared file" \
  "$OUT/alpha/references" "own.md patterns.md perf.md security.md "

# --- 5. matching link outside the shared dir untouched ---
check "link to the skill's own ../references/own.md left untouched" \
  grep -qF '[own](../references/own.md)' "$OUT/alpha/references/patterns.md"
check "own references file copied unchanged" \
  cmp -s "$OUT/alpha/references/own.md" "$SRC/alpha/references/own.md"

# --- 6. no link resolves outside its own skill; all resolve ---
escaped=""
while IFS= read -r file; do
  skill_dir="$OUT/$(printf '%s' "${file#"$OUT"/}" | cut -d/ -f1)"
  while IFS= read -r link; do
    [ -n "$link" ] || continue
    target_dir="$(cd "$(dirname "$file")/$(dirname "$link")" 2>/dev/null && pwd -P)" || target_dir=""
    case "$target_dir/" in
      "$skill_dir"/*) [ -f "$target_dir/$(basename "$link")" ] || escaped="$escaped ${file#"$OUT"/}->$link(missing)" ;;
      *) escaped="$escaped ${file#"$OUT"/}->$link" ;;
    esac
  done < <(grep -oE '(\]\(|`)[A-Za-z0-9._/-]+\.md' "$file" | sed -E 's/^(\]\(|`)//')
done < <(find "$OUT" -type f -name '*.md' | LC_ALL=C sort)
if [ -z "$escaped" ]; then ok "every .md link/path in the output resolves inside its own skill"; else bad "links escaping or dangling:$escaped"; fi

# --- 7. missing shared file fails ---
MISS="$TMP/addy/skills-missing" # sibling of the shared dir
skill_md "$MISS/gamma" 'See [gone](../../references/gone.md).'
check_run_fails "link to a missing shared file fails" "gone.md" \
  "$MISS" "$TMP/missing-out" --references "$SHARED"

# --- 8. differing same-name file fails ---
CLASH="$TMP/addy/skills-clash" # sibling of the shared dir
skill_md "$CLASH/delta" 'See [security](../../references/security.md).'
mkdir -p "$CLASH/delta/references"
printf '%s\n' 'a different security file' > "$CLASH/delta/references/security.md"
check_run_fails "skill's own differing references/security.md fails" "security.md" \
  "$CLASH" "$TMP/clash-out" --references "$SHARED"

# --- 9. name collision across two runs fails, first copy kept ---
OWN="$TMP/own/skills"
skill_md "$OWN/beta" 'Own beta, must not be overwritten.'
COLL_OUT="$TMP/coll-out"
check "first run (own skills) succeeds" bun "$COPY" "$OWN" "$COLL_OUT"
check_run_fails "second run with an existing skill name fails" "beta" \
  "$SRC" "$COLL_OUT" --references "$SHARED"
check "first run's copy of the colliding skill is intact" \
  cmp -s "$COLL_OUT/beta/SKILL.md" "$OWN/beta/SKILL.md"

# --- 10/11. intermediate-folder links (own skills -> addy/references) ---
OWN2="$TMP/own2/skills"
mkdir -p "$TMP/other/references"
printf '%s\n' 'not shared' > "$TMP/other/references/x.md"
skill_md "$OWN2/eps" 'See [perf](../../../addy/references/perf.md) and [guide](references/sub/guide.md).'
mkdir -p "$OWN2/eps/references/sub"
cat > "$OWN2/eps/references/sub/guide.md" <<'MD'
Checklist: `../../../../../addy/references/security.md`.
Elsewhere: [x](../../../../../other/references/x.md).
MD
OWN2_OUT="$TMP/own2-out"
check "copy of own skills with intermediate-folder links succeeds" \
  bun "$COPY" "$OWN2" "$OWN2_OUT" --references "$SHARED"
check "nested intermediate-folder link rewritten to ../security.md" \
  grep -qF '`../security.md`' "$OWN2_OUT/eps/references/sub/guide.md"
check "intermediate-folder link inlined as a copy of the shared file" \
  cmp -s "$OWN2_OUT/eps/references/security.md" "$SHARED/security.md"
check "SKILL.md intermediate-folder link rewritten to references/perf.md" \
  grep -qF '[perf](references/perf.md)' "$OWN2_OUT/eps/SKILL.md"
check "SKILL.md intermediate-folder link inlined as a copy of the shared file" \
  cmp -s "$OWN2_OUT/eps/references/perf.md" "$SHARED/perf.md"
check "intermediate-folder link outside the shared dir left untouched" \
  grep -qF '[x](../../../../../other/references/x.md)' "$OWN2_OUT/eps/references/sub/guide.md"
check "file outside the shared dir is not copied into the skill" \
  test ! -e "$OWN2_OUT/eps/references/x.md"

if [ "$fail" -ne 0 ]; then
  echo "copy-skills-test FAILED" >&2
  exit 1
fi
echo "copy-skills-test PASSED"
