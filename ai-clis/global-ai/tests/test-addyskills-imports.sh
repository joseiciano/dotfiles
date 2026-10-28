#!/usr/bin/env bash
# Regression test for the addyskills, mattskills and pstack imports, over the
# REAL committed sources.
# Sources are only read; the one build step writes to a throwaway dir.
#
# The imported skills (setup/skills-setup/addyskills/skills/<skill>/, shared
# checklists in setup/references/) and commands
# (setup/command-setup/command/) were rewritten from upstream so they work as
# plain skills in ~/.claude. A re-import or hand edit that reintroduces an
# upstream-only shape breaks them silently, so this test proves:
#   1. No imported file (addyskills/README.md excluded) or command uses the
#      `agent-skills:` plugin prefix or the upstream agent names
#      `code-reviewer`, `test-engineer`, `security-auditor`.
#   2. Every `../../../../references/` / `../../../../../references/` link in
#      addyskills/skills resolves, from the file that holds it, to an existing
#      file in setup/references (a wrong depth would be silently left
#      un-inlined by copy-skills.js).
#   3. No skill name exists in more than one skill source (every dir
#      make/claude.mk passes to copy-skills.js: skills/, addyskills/skills/,
#      mattskills/skills/, ...); build-claude would refuse to
#      build.
#   4. A real `make build-claude`, `make setup-opencode` and `make build-omp`
#      (Makefile, make/ and setup/ copied into a throwaway dir, fake HOME)
#      succeed; copy-skills.js refuses to build when an own and an imported
#      skill share a name, so this also proves none do.
#   5. Every `~/.claude/skills/<path>` mentioned under setup/agent-setup and
#      setup/command-setup exists in that build, except the allowlisted stale
#      rows in STALE_PATHS.
#   6. Folded wrappers are flat: no SKILL.md below any installed skill's top
#      level, every `references:` entry of ai-review and git has
#      references/<entry>/guide.md, and principle-performance-optimization has web-perf
#      and vercel-react-best-practices guides.
#   7. No installed ai-review file names addyskills/references.
#   8. No retired skill is installed as a top-level skill.
#   9. No `references/<file>.md` path in an installed skill points outside
#      that skill.
#  10. Every mattskills/skills/<skill>/ is installed by the build, file for
#      file identical to its source.
#  11. No mattskills skill ships an `agents/` folder (Codex-only upstream
#      metadata is intentionally left out).
#  12. Every skill a mattskills skill calls via `call the Skill tool with
#      "<name>"` is installed by the build, and improve-codebase-architecture
#      hands off to `interview-me`, not upstream's `grilling`.
#  13. The pstack skills `how` and `why` are installed by the build, and no
#      installed file under them names pstack, poteto, pstack-models,
#      general-purpose or readonly (upstream plugin dispatch and model sheet).
#  14. Every `./sources/<name>.md` link in the installed
#      why/references/source-playbook.md resolves to an installed file.
#  15. The installed teach skill names `how` and `why`, and both are installed
#      skills (teach runs them).
#  16. engineering-principles stays removed: no built claude, omp or
#      opencode agent (or opencode.json) names it; check 8 covers the skill.
#  17. no-comments starts `comment-sicko`, without pstack, /architect or
#      principle- names, and comment-sicko is built for claude, omp and
#      opencode.
#  18. No file under setup/agent-setup, setup/command-setup or our own
#      setup/skills-setup/skills uses a `pstack:` plugin-namespaced name.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_SETUP="$ROOT/setup/skills-setup"
SKILLS="$SKILLS_SETUP/skills"
ADDY="$SKILLS_SETUP/addyskills"
ADDY_SKILLS="$ADDY/skills"
MATT_SKILLS="$SKILLS_SETUP/mattskills/skills"
SHARED="$ROOT/setup/references"
COMMANDS="$ROOT/setup/command-setup/command"
AGENTS="$ROOT/setup/agent-setup/agents"
AGENT_SETUP="$ROOT/setup/agent-setup"
COMMAND_SETUP="$ROOT/setup/command-setup"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-ai-addyskills-test.XXXXXX")"
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

fail=0
ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1"; fail=1; }

for dir in "$SKILLS" "$ADDY_SKILLS" "$MATT_SKILLS" "$SHARED" "$COMMANDS" "$AGENTS"; do
  [ -d "$dir" ] || { echo "FAIL - missing source dir: $dir"; exit 1; }
done
SHARED_REAL="$(cd "$SHARED" && pwd -P)"

imported_files() {
  find "$ADDY" -type f ! -path "$ADDY/README.md"
  find "$COMMANDS" -type f
}

# --- 1. forbidden upstream names ---
check_absent() {
  local desc="$1" pattern="$2" hits
  hits="$(imported_files | LC_ALL=C sort | while IFS= read -r f; do
    grep -HnE -- "$pattern" "$f" || true
  done)"
  if [ -z "$hits" ]; then
    ok "$desc"
  else
    bad "$desc"
    printf '%s\n' "$hits" | sed 's/^/       /'
  fi
}
check_absent "no agent-skills: plugin prefix" 'agent-skills:'
check_absent "no upstream code-reviewer agent name" 'code-reviewer'
check_absent "no upstream test-engineer agent name" 'test-engineer'
check_absent "no upstream security-auditor agent name" 'security-auditor'

# --- 2. shared-reference links resolve by location ---
missing=""
count=0
while IFS= read -r f; do
  while IFS= read -r link; do
    [ -n "$link" ] || continue
    count=$((count + 1))
    target_dir="$(cd "$(dirname "$f")/$(dirname "$link")" 2>/dev/null && pwd -P)" || target_dir=""
    if [ "$target_dir" != "$SHARED_REAL" ] || [ ! -f "$target_dir/$(basename "$link")" ]; then
      missing="$missing ${f#"$ROOT"/}->$link"
    fi
  done < <(grep -oE '(\.\./)+references/[A-Za-z0-9._-]+\.md' "$f" | LC_ALL=C sort -u)
done < <(find "$ADDY_SKILLS" -type f -name '*.md' | LC_ALL=C sort)
if [ "$count" -eq 0 ]; then
  bad "found shared-reference links to check (extraction broken?)"
elif [ -z "$missing" ]; then
  ok "all $count shared-reference links resolve to a file in setup/references"
else
  bad "shared-reference links that do not resolve into setup/references:$missing"
fi

# --- 3. no skill name in more than one source ---
# Sources are the dirs make/claude.mk copies skills from.
SKILL_SOURCES="$(grep -oE 'copy-skills\.js \$\(SKILLS_SETUP\)/[^ ]+' "$ROOT/make/claude.mk" \
  | sed -E 's#^copy-skills\.js \$\(SKILLS_SETUP\)/##' | LC_ALL=C sort -u)"
missing=""
for want in skills addyskills/skills mattskills/skills; do
  printf '%s\n' "$SKILL_SOURCES" | grep -qxF -- "$want" || missing="$missing $want"
done
for src in $SKILL_SOURCES; do
  [ -d "$SKILLS_SETUP/$src" ] || missing="$missing $src(no dir)"
done
if [ -z "$missing" ]; then
  ok "make/claude.mk copies skills from $(echo $SKILL_SOURCES)"
else
  bad "skill sources read from make/claude.mk incomplete or missing:$missing"
fi
dupes="$(for src in $SKILL_SOURCES; do
  find "$SKILLS_SETUP/$src" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
done | LC_ALL=C sort | uniq -d)"
if [ -z "$dupes" ]; then
  ok "no skill name exists in more than one of $(echo $SKILL_SOURCES)"
else
  bad "skill names in more than one skill source: $(echo $dupes)"
fi

# --- 4. real build into a throwaway copy ---
GAI="$TMP/global-ai"
mkdir -p "$GAI" "$TMP/home"
cp "$ROOT/Makefile" "$GAI/Makefile"
cp -R "$ROOT/make" "$GAI/make"
cp -R "$ROOT/setup" "$GAI/setup"
BUILT="$GAI/output/claude/skills"
if HOME="$TMP/home" make -C "$GAI" build-claude >/dev/null 2>"$TMP/err"; then
  ok "make build-claude succeeds on a copy of the real sources"
else
  bad "make build-claude succeeds on a copy of the real sources: $(tail -5 "$TMP/err")"
  echo "addyskills-imports-test FAILED" >&2
  exit 1
fi
for target in setup-opencode build-omp; do
  if HOME="$TMP/home" make -C "$GAI" "$target" >/dev/null 2>"$TMP/err"; then
    ok "make $target succeeds on a copy of the real sources"
  else
    bad "make $target succeeds on a copy of the real sources: $(tail -5 "$TMP/err")"
    echo "addyskills-imports-test FAILED" >&2
    exit 1
  fi
done

# --- 5. installed paths named by agents and commands exist ---
# Known-stale table rows (skills retired without a replacement row yet).
STALE_PATHS="
~/.claude/skills/agents-sdk/SKILL.md
~/.claude/skills/cloudflare-email-service/SKILL.md
~/.claude/skills/durable-objects/SKILL.md
~/.claude/skills/sandbox-sdk/SKILL.md
~/.claude/skills/workers-best-practices/SKILL.md
"
missing=""
count=0
while IFS= read -r path; do
  [ -n "$path" ] || continue
  printf '%s\n' "$STALE_PATHS" | grep -qxF -- "$path" && continue
  count=$((count + 1))
  [ -e "$BUILT/${path#\~/.claude/skills/}" ] || missing="$missing $path"
done < <(
  grep -rohE '~/\.claude/skills/[A-Za-z0-9._/-]+' "$AGENT_SETUP" "$COMMAND_SETUP" \
    | sed -E 's/\.$//' | LC_ALL=C sort -u
)
if [ "$count" -eq 0 ]; then
  bad "found ~/.claude/skills/<path> mentions to check (extraction broken?)"
elif [ -z "$missing" ]; then
  ok "all $count ~/.claude/skills/<path> mentions exist in the build"
else
  bad "~/.claude/skills/<path> mentions missing from the build:$missing"
fi

# --- 6. folded wrappers ---
nested="$(cd "$BUILT" && find . -mindepth 3 -name SKILL.md | LC_ALL=C sort)"
if [ -z "$nested" ]; then
  ok "no SKILL.md below any installed skill's top level"
else
  bad "nested SKILL.md files in the build: $(echo $nested)"
fi

# Prints the top-level block list <key>: of a Markdown file's first
# frontmatter block, one item per line, surrounding quotes stripped.
frontmatter_list() {
  awk -v key="$2" '
    NR == 1 && /^---[[:space:]]*$/ { fm = 1; next }
    fm && /^---[[:space:]]*$/ { exit }
    fm && $0 ~ ("^" key ":[[:space:]]*$") { list = 1; next }
    fm && list && /^[[:space:]]+-[[:space:]]+/ { sub(/^[[:space:]]+-[[:space:]]+/, ""); sub(/[[:space:]]+$/, ""); gsub(/^"|"$/, ""); print; next }
    { list = 0 }
  ' "$1"
}
frontmatter_references() { frontmatter_list "$1" references; }
for wrapper in ai-review git; do
  entries="$(frontmatter_references "$BUILT/$wrapper/SKILL.md")"
  if [ -z "$entries" ]; then
    bad "$wrapper: frontmatter has a references: list"
    continue
  fi
  missing=""
  for entry in $entries; do
    [ -f "$BUILT/$wrapper/references/$entry/guide.md" ] || missing="$missing $entry"
  done
  if [ -z "$missing" ]; then
    ok "$wrapper: every references: entry has references/<entry>/guide.md ($(echo $entries))"
  else
    bad "$wrapper: references: entries without references/<entry>/guide.md:$missing"
  fi
done
for route in web-perf vercel-react-best-practices; do
  check_file="$BUILT/principle-performance-optimization/references/$route/guide.md"
  if [ -f "$check_file" ]; then
    ok "principle-performance-optimization: references/$route/guide.md installed"
  else
    bad "principle-performance-optimization: references/$route/guide.md installed"
  fi
done

# --- 7. ai-review does not name addyskills/references ---
if grep -rqF 'addyskills/references' "$BUILT/ai-review"; then
  bad "installed ai-review still names addyskills/references: $(grep -rlF 'addyskills/references' "$BUILT/ai-review" | sed "s#$BUILT/##" | tr '\n' ' ')"
else
  ok "installed ai-review no longer names addyskills/references"
fi

# --- 8. retired skills are not installed ---
installed_retired=""
for name in tdd deslop plan-prd frontend-design web-perf vercel-react-best-practices \
  commit-pull-request make-pr-easy-to-review resolving-merge-conflicts fix-merge-conflicts \
  code-review-and-quality git-workflow-and-versioning supabase-postgres-best-practices \
  engineering-principles; do
  [ ! -e "$BUILT/$name" ] || installed_retired="$installed_retired $name"
done
if [ -z "$installed_retired" ]; then
  ok "no retired skill is installed as a top-level skill"
else
  bad "retired skills installed as top-level skills:$installed_retired"
fi

# --- 9. no installed skill references a path outside itself ---
escaped=""
while IFS= read -r skill_dir; do
  skill_dir="$(cd "$skill_dir" && pwd -P)"
  while IFS= read -r f; do
    while IFS= read -r link; do
      [ -n "$link" ] || continue
      target_dir="$(cd "$(dirname "$f")/$(dirname "$link")" 2>/dev/null && pwd -P)" || target_dir=""
      case "$target_dir/" in
        "$skill_dir"/*) [ -f "$target_dir/$(basename "$link")" ] || escaped="$escaped ${f#"$BUILT"/}->$link(missing)" ;;
        *) escaped="$escaped ${f#"$BUILT"/}->$link" ;;
      esac
    done < <(grep -oE '(\.\./)+([A-Za-z0-9._-]+/)*references/[A-Za-z0-9._-]+\.md' "$f" | LC_ALL=C sort -u)
  done < <(find "$skill_dir" -type f -name '*.md' | LC_ALL=C sort)
done < <(find "$BUILT" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort)
if [ -z "$escaped" ]; then
  ok "installed skills only reference files inside themselves"
else
  bad "installed skills reference paths outside themselves:$escaped"
fi

# --- 10. every mattskills skill is installed, identical to its source ---
count=0
missing=""
while IFS= read -r skill_dir; do
  name="$(basename "$skill_dir")"
  count=$((count + 1))
  diff -r "$skill_dir" "$BUILT/$name" >/dev/null 2>&1 || missing="$missing $name"
done < <(find "$MATT_SKILLS" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort)
if [ "$count" -eq 0 ]; then
  bad "found mattskills skills to check (source empty?)"
elif [ -z "$missing" ]; then
  ok "all $count mattskills skills installed identical to their sources"
else
  bad "mattskills skills missing from or differing in the build:$missing"
fi

# --- 11. no Codex-only agents/ folder in mattskills ---
agent_dirs="$(find "$MATT_SKILLS" -mindepth 2 -maxdepth 2 -name agents | LC_ALL=C sort)"
if [ -z "$agent_dirs" ]; then
  ok "no mattskills skill ships an agents/ folder"
else
  bad "mattskills skills ship agents/ folders: $(echo ${agent_dirs//"$MATT_SKILLS"\//})"
fi

# --- 12. Skill-tool handoffs in mattskills resolve to installed skills ---
# Prints every skill name a file calls via `Skill tool with "<name>"` (or `<name>`).
skill_calls() {
  grep -oE 'Skill tool with ["`][A-Za-z0-9._-]+["`]' "$@" \
    | sed -E 's/.*with ["`]([^"`]+)["`]$/\1/' | LC_ALL=C sort -u
}
missing=""
count=0
while IFS= read -r called; do
  [ -n "$called" ] || continue
  count=$((count + 1))
  [ -f "$BUILT/$called/SKILL.md" ] || missing="$missing $called"
done < <(find "$MATT_SKILLS" -type f -name '*.md' -exec cat {} + | skill_calls /dev/stdin)
if [ "$count" -eq 0 ]; then
  bad "found Skill-tool handoffs in mattskills (extraction broken?)"
elif [ -z "$missing" ]; then
  ok "all $count skills called from mattskills are installed"
else
  bad "skills called from mattskills but not installed:$missing"
fi
ICA_CALLS="$(skill_calls "$MATT_SKILLS/improve-codebase-architecture/SKILL.md" | tr '\n' ' ')"
case " $ICA_CALLS" in
  *" interview-me "*) ok "improve-codebase-architecture hands off to interview-me" ;;
  *) bad "improve-codebase-architecture hands off to interview-me (calls: $ICA_CALLS)" ;;
esac
if grep -rqw 'grilling' "$MATT_SKILLS/improve-codebase-architecture"; then
  bad "improve-codebase-architecture no longer names upstream's grilling skill"
else
  ok "improve-codebase-architecture no longer names upstream's grilling skill"
fi

# --- 13. pstack skills installed, rewritten off upstream names ---
for name in how why; do
  if [ -f "$BUILT/$name/SKILL.md" ] && diff -r "$SKILLS_SETUP/skills/$name" "$BUILT/$name" >/dev/null 2>&1; then
    ok "pstack skill $name installed identical to its source"
  else
    bad "pstack skill $name installed identical to its source"
  fi
done
hits="$(grep -rniE 'pstack|poteto|general-purpose|readonly' "$BUILT/how" "$BUILT/why" 2>/dev/null \
  | sed "s#^$BUILT/##" || true)"
if [ -z "$hits" ]; then
  ok "no installed how/ or why/ file names pstack, poteto, pstack-models, general-purpose or readonly"
else
  bad "installed how/ or why/ files name upstream pstack terms"
  printf '%s\n' "$hits" | sed 's/^/       /'
fi

# --- 14. why's source-playbook links resolve in the installed copy ---
PLAYBOOK="$BUILT/why/references/source-playbook.md"
missing=""
count=0
while IFS= read -r link; do
  [ -n "$link" ] || continue
  count=$((count + 1))
  [ -f "$(dirname "$PLAYBOOK")/$link" ] || missing="$missing $link"
done < <(grep -oE '\./sources/[A-Za-z0-9._-]+\.md' "$PLAYBOOK" 2>/dev/null | LC_ALL=C sort -u)
if [ "$count" -eq 0 ]; then
  bad "found ./sources/<name>.md links in installed why source-playbook (extraction broken?)"
elif [ -z "$missing" ]; then
  ok "all $count ./sources/ links in installed why source-playbook resolve"
else
  bad "installed why source-playbook links missing files:$missing"
fi

# --- 15. teach's how/why dependencies are installed skills ---
for dep in how why; do
  if ! grep -qF "\`$dep\`" "$BUILT/teach/SKILL.md" 2>/dev/null; then
    bad "installed teach names \`$dep\`"
  elif grep -qxF "name: $dep" "$BUILT/$dep/SKILL.md" 2>/dev/null; then
    ok "teach dependency $dep is an installed skill"
  else
    bad "teach dependency $dep is an installed skill (no $dep/SKILL.md with name: $dep)"
  fi
done

# --- 16. engineering-principles stays removed ---
OPENCODE_JSON="$GAI/output/opencode/opencode.json"
hits="$(grep -rlF 'engineering-principles' "$GAI/output/claude/agents" "$GAI/output/omp/agents" \
  "$GAI/output/opencode/agents" "$OPENCODE_JSON" 2>/dev/null | sed "s#^$GAI/##" || true)"
if [ -z "$hits" ]; then
  ok "no built agent or opencode.json names engineering-principles"
else
  bad "built agents name the removed engineering-principles skill: $(echo $hits)"
fi

# --- 17. no-comments' comment-sicko is built for every harness ---
NO_COMMENTS="$BUILT/no-comments/SKILL.md"
if grep -qF '`comment-sicko`' "$NO_COMMENTS" 2>/dev/null; then
  ok "installed no-comments starts \`comment-sicko\`"
else
  bad "installed no-comments starts \`comment-sicko\`"
fi
hits="$(grep -nE 'pstack|/architect|principle-' "$NO_COMMENTS" 2>/dev/null || true)"
if [ -z "$hits" ]; then
  ok "installed no-comments names no pstack, /architect or principle- terms"
else
  bad "installed no-comments names pstack, /architect or principle- terms"
  printf '%s\n' "$hits" | sed 's/^/       /'
fi
for harness in claude omp; do
  if grep -qxF 'name: comment-sicko' "$GAI/output/$harness/agents/comment-sicko.md" 2>/dev/null; then
    ok "comment-sicko agent built for $harness"
  else
    bad "comment-sicko agent built for $harness (no agents/comment-sicko.md with name: comment-sicko)"
  fi
done
if [ -f "$GAI/output/opencode/agents/comment-sicko.md" ] \
  && jq -e '.agent["comment-sicko"] | type == "object"' "$OPENCODE_JSON" >/dev/null 2>&1; then
  ok "comment-sicko agent built for opencode (agents/comment-sicko.md and opencode.json entry)"
else
  bad "comment-sicko agent built for opencode (agents/comment-sicko.md and opencode.json entry)"
fi

# --- 18. no pstack: plugin-namespaced names in our sources ---
hits="$(grep -rnF 'pstack:' "$AGENT_SETUP" "$COMMAND_SETUP" "$SKILLS" 2>/dev/null | sed "s#^$ROOT/##" || true)"
if [ -z "$hits" ]; then
  ok "no pstack: plugin-namespaced name under setup/agent-setup, setup/command-setup or own skills"
else
  bad "pstack: plugin-namespaced names under setup/agent-setup, setup/command-setup or own skills"
  printf '%s\n' "$hits" | sed 's/^/       /'
fi

if [ "$fail" -ne 0 ]; then
  echo "addyskills-imports-test FAILED" >&2
  exit 1
fi
echo "addyskills-imports-test PASSED"
