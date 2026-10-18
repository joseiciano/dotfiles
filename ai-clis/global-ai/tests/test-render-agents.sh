#!/usr/bin/env bash
# Regression test for setup/agent-setup/render-agents.js.
#
# Proves:
#   1. Shared agents (agents/<name>.md): rendering harness H writes H's block
#      verbatim plus name/description, drops the other harness blocks and
#      `shared`, and appends top-level `shared` fragments with headings shifted
#      one level deeper (except inside ``` fences).
#   2. A block-level `shared` replaces the top-level list.
#   3. A block set to `false` skips the agent for that harness only.
#   4. A block `name` renames the output file (Plan -> plan for omp).
#   5. `inherit` omits the model/tools key from the rendered file.
#   6. agents-<H>/<name>.md render only for H, with their own `shared`.
#   7. opencode: `name` dropped, `mode` filled in only when absent, metadata
#      keys moved to --meta-out; generate-config.sh consumes the meta files
#      into opencode.json (including an empty skills list).
#   8. Re-running after removing a source agent removes its output.
#   9. Build errors exit non-zero and produce no output: unknown top-level
#      key, name/filename mismatch, missing harness block, missing model,
#      missing tools/permission, duplicate output name, missing fragment.
#      A failing re-run keeps the previous output intact.
#  10. `prompt` mode drops frontmatter and one leading blank line, and appends
#      the file's `shared` fragments.
#
# Runs against throwaway fixture trees; live sources and outputs are never
# touched.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RENDER="$ROOT/setup/agent-setup/render-agents.js"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-ai-render-agents-test.XXXXXX")"
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

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

# check_fm <desc> <file> <js-expr>: evaluates <js-expr> with `fm` (parsed
# frontmatter) and `body` (text after frontmatter) bound.
FM_HELPER="$TMP/fm.js"
cat > "$FM_HELPER" <<'JS'
const fs = require('fs');
const [file, expr] = process.argv.slice(2);
const text = fs.readFileSync(file, 'utf8');
let fm = null;
let body = text;
if (text.startsWith('---\n')) {
  const close = text.indexOf('\n---\n', 3);
  fm = Bun.YAML.parse(text.slice(4, close + 1)) ?? {};
  body = text.slice(close + 5);
}
const eq = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const keys = (o) => Object.keys(o).sort();
process.exit(new Function('fm', 'body', 'eq', 'keys', 'return (' + expr + ');')(fm, body, eq, keys) ? 0 : 1);
JS
check_fm() {
  local desc="$1" file="$2" expr="$3"
  check "$desc" bun "$FM_HELPER" "$file" "$expr"
}

# --- fixture source tree ---
SRC="$TMP/src"
mkdir -p "$SRC/agents" "$SRC/agents-claude" "$SRC/agents-opencode" "$SRC/agents-shared"

cat > "$SRC/agents/Plan.md" <<'MD'
---
name: Plan
description: Plans work.
shared:
  - frag-a
claude:
  model: opus
  tools: Read, Grep
  color: blue
opencode:
  model: openai/gpt-x
  fallback_models:
    - opencode/fb-1
    - openai/fb-2
  variant: high
  temperature: 0.2
  skills: []
  mcps:
    - "*"
  permission:
    edit: deny
  shared:
    - frag-b
omp:
  name: plan
  model: inherit
  tools: read, grep
---
# Plan
PLAN-BODY
MD

cat > "$SRC/agents/helper.md" <<'MD'
---
name: helper
description: Helps.
claude: false
opencode:
  mode: primary
  model: inherit
  permission: inherit
omp:
  model: omp/m
  tools: inherit
---
HELPER-BODY
MD

cat > "$SRC/agents/doomed.md" <<'MD'
---
name: doomed
description: Removed later.
claude:
  model: sonnet
  tools: Read
opencode: false
omp: false
---
DOOMED-BODY
MD

cat > "$SRC/agents-claude/solo.md" <<'MD'
---
description: Claude-only agent.
model: haiku
tools: Bash
shared:
  - frag-b
---
SOLO-BODY
MD

cat > "$SRC/agents-shared/frag-a.md" <<'MD'
# Frag A
FRAG-A-TEXT
## Frag A sub
```
# not a heading
```
MD
printf 'FRAG-B-TEXT\n' > "$SRC/agents-shared/frag-b.md"

render() {
  local harness="$1"
  shift
  bun "$RENDER" "$harness" --src "$SRC" "$@"
}

C_OUT="$TMP/out/claude"
O_OUT="$TMP/out/opencode"
O_META="$TMP/out/opencode-meta"
P_OUT="$TMP/out/omp"

check "claude render succeeds" render claude --out "$C_OUT"
check "opencode render succeeds" render opencode --out "$O_OUT" --meta-out "$O_META"
check "omp render succeeds" render omp --out "$P_OUT"

# --- 1/5/6. claude ---
check_fm "claude Plan: block copied with name+description, other blocks dropped" "$C_OUT/Plan.md" \
  "eq(fm, {name: 'Plan', description: 'Plans work.', model: 'opus', tools: 'Read, Grep', color: 'blue'})"
check_fm "claude Plan: body kept, top-level shared fragment appended" "$C_OUT/Plan.md" \
  "body.startsWith('# Plan\nPLAN-BODY\n') && body.includes('FRAG-A-TEXT') && !body.includes('FRAG-B-TEXT')"
check_fm "claude Plan: fragment headings shifted one level" "$C_OUT/Plan.md" \
  "/^## Frag A\$/m.test(body) && /^### Frag A sub\$/m.test(body) && !/^# Frag A\$/m.test(body)"
check_fm "claude Plan: agent's own heading not shifted" "$C_OUT/Plan.md" "/^# Plan\$/m.test(body)"
check_fm "claude Plan: headings inside code fences untouched" "$C_OUT/Plan.md" \
  "/^# not a heading\$/m.test(body)"
check "claude skips agent with claude: false" test ! -e "$C_OUT/helper.md"
check_fm "claude-only agent rendered with name from filename" "$C_OUT/solo.md" \
  "eq(fm, {description: 'Claude-only agent.', model: 'haiku', tools: 'Bash', name: 'solo'})"
check_fm "claude-only agent appends its own shared fragment" "$C_OUT/solo.md" \
  "body.includes('SOLO-BODY') && body.includes('FRAG-B-TEXT')"
check "claude-only agent not rendered for opencode" test ! -e "$O_OUT/solo.md"
check "claude-only agent not rendered for omp" test ! -e "$P_OUT/solo.md"

# --- 4/5. omp ---
# Compare the directory listing: macOS filesystems are case-insensitive.
check "omp block name renames output file (only plan.md, not Plan.md)" \
  test "$(ls "$P_OUT" | tr '\n' ' ')" = "helper.md plan.md "
check_fm "omp plan: inherit model omitted, renamed name in frontmatter" "$P_OUT/plan.md" \
  "eq(fm, {name: 'plan', description: 'Plans work.', tools: 'read, grep'})"
check_fm "omp helper: inherit tools omitted" "$P_OUT/helper.md" \
  "eq(fm, {name: 'helper', description: 'Helps.', model: 'omp/m'})"

# --- 2/7. opencode ---
check_fm "opencode Plan: name and metadata keys removed, mode defaulted" "$O_OUT/Plan.md" \
  "eq(keys(fm), ['description', 'mode', 'permission']) && fm.mode === 'subagent' && eq(fm.permission, {edit: 'deny'})"
check_fm "opencode Plan: block-level shared replaces top-level list" "$O_OUT/Plan.md" \
  "body.includes('FRAG-B-TEXT') && !body.includes('FRAG-A-TEXT')"
check_fm "opencode helper: explicit mode kept, inherit keys omitted" "$O_OUT/helper.md" \
  "eq(fm, {description: 'Helps.', mode: 'primary'})"
check "opencode helper: no meta file when nothing to move" test ! -e "$O_META/helper.md"
check "opencode Plan: meta file written" test -f "$O_META/Plan.md"

# End to end: the real config generator consumes the meta files.
CONFIG_TREE="$TMP/config"
cp -R "$ROOT/setup/config/opencode-and-clones-only" "$CONFIG_TREE"
printf '{\n  "agent": {}\n}\n' > "$CONFIG_TREE/config.jsonc"
check "generate-config.sh accepts rendered meta files" \
  env AGENTS_DIR="$O_META" bash "$CONFIG_TREE/generate-config.sh" "$TMP/cfg" opencode
check "opencode.json Plan entry matches rendered metadata" bun -e '
const cfg = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
const a = cfg.agent.Plan;
const ok = a.model === "openai/gpt-x"
  && JSON.stringify(a.fallback_models) === JSON.stringify(["opencode/fb-1", "openai/fb-2"])
  && a.variant === "high" && a.temperature === 0.2
  && Array.isArray(a.skills) && a.skills.length === 0
  && JSON.stringify(a.mcps) === JSON.stringify(["*"])
  && !("helper" in cfg.agent);
process.exit(ok ? 0 : 1);
' "$TMP/cfg/opencode.json"

# --- 8. removed source agent disappears on re-run ---
check "claude output has doomed before removal" test -f "$C_OUT/doomed.md"
rm "$SRC/agents/doomed.md"
check "claude re-render succeeds" render claude --out "$C_OUT"
check "removed agent no longer in output" test ! -e "$C_OUT/doomed.md"
check "surviving agent still in output" test -f "$C_OUT/Plan.md"

# --- 9. build errors ---
# expect_error <desc> <harness> <error-substring>: renders $BAD (prepared by
# the caller) into a fresh output dir; must exit non-zero, name the problem,
# and create no output.
expect_error() {
  local desc="$1" harness="$2" needle="$3"
  local out="$TMP/bad-out/$harness" meta="$TMP/bad-out/meta" log="$TMP/bad.log"
  rm -rf "$TMP/bad-out"
  if bun "$RENDER" "$harness" --src "$BAD" --out "$out" --meta-out "$meta" >"$log" 2>&1; then
    echo "FAIL - $desc: should exit non-zero"
    fail=1
    return
  fi
  if grep -qF -- "$needle" "$log" && [ ! -e "$out" ] && [ ! -e "$meta" ]; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc: output: $(cat "$log")"
    fail=1
  fi
}

new_bad() {
  BAD="$TMP/bad-src"
  rm -rf "$BAD"
  mkdir -p "$BAD/agents" "$BAD/agents-shared"
}

good_agent() { # <name>
  cat <<MD
---
name: $1
description: d
claude:
  model: m
  tools: t
opencode:
  model: m
  permission: inherit
omp:
  model: m
  tools: t
---
body
MD
}

new_bad
good_agent x | sed 's/^opencode:/opencod:/' > "$BAD/agents/x.md"
expect_error "typo'd top-level key rejected" claude "unknown top-level key 'opencod'"

new_bad
good_agent other > "$BAD/agents/x.md"
expect_error "name not matching filename rejected" claude "does not match file name 'x'"

new_bad
good_agent x | sed '/^omp:/,/^---$/{/^---$/!d;}' > "$BAD/agents/x.md"
expect_error "missing harness block rejected" omp "missing \`omp:\` block"

new_bad
good_agent x | sed '/^claude:/,/^opencode:/{/  model: m/d;}' > "$BAD/agents/x.md"
expect_error "missing model rejected" claude "must set \`model\`"

new_bad
good_agent x | sed '/  permission: inherit/d' > "$BAD/agents/x.md"
expect_error "missing permission rejected for opencode" opencode "must set \`permission\`"

new_bad
good_agent x | sed '/^omp:/,/^---$/{/  tools: t/d;}' > "$BAD/agents/x.md"
expect_error "missing tools rejected for omp" omp "must set \`tools\`"

new_bad
good_agent x > "$BAD/agents/x.md"
mkdir -p "$BAD/agents-claude"
printf -- '---\nname: x\ndescription: d\nmodel: m\ntools: t\n---\nbody\n' > "$BAD/agents-claude/x.md"
expect_error "duplicate output name across agents/ and agents-claude/ rejected" claude "duplicate agent 'x'"

new_bad
good_agent x > "$BAD/agents/x.md"
cat > "$BAD/agents/y.md" <<'MD'
---
name: y
description: d
claude: false
opencode: false
omp:
  name: x
  model: m
  tools: t
---
body
MD
expect_error "duplicate output name via block rename rejected" omp "duplicate agent 'x'"

new_bad
{ printf -- '---\nname: x\ndescription: d\nshared:\n  - nope\n'; good_agent x | sed '1,3d'; } > "$BAD/agents/x.md"
expect_error "missing shared fragment rejected" claude "shared fragment 'nope' not found"

# A failing re-run must keep the previous good output.
cp -R "$C_OUT" "$TMP/claude-before"
printf -- '---\ndescription: d\nmodel: m\ntools: t\nshared:\n  - nope\n---\nbody\n' > "$SRC/agents-claude/broken.md"
check "failing re-render exits non-zero" bash -c '! bun "$0" claude --src "$1" --out "$2"' "$RENDER" "$SRC" "$C_OUT"
check "failing re-render leaves previous output unchanged" diff -r "$TMP/claude-before" "$C_OUT"
rm "$SRC/agents-claude/broken.md"

# --- 10. prompt mode ---
cat > "$TMP/prompt-src.md" <<'MD'
---
shared:
  - frag-a
---

# Prompt
PROMPT-BODY
MD
check "prompt render succeeds" bun "$RENDER" prompt "$TMP/prompt-src.md" "$TMP/prompt-out/p.md" --src "$SRC"
check_fm "prompt: frontmatter and leading blank line dropped" "$TMP/prompt-out/p.md" \
  "fm === null && body.startsWith('# Prompt\nPROMPT-BODY\n')"
check_fm "prompt: shared fragment appended with shifted headings" "$TMP/prompt-out/p.md" \
  "body.includes('FRAG-A-TEXT') && /^## Frag A\$/m.test(body)"

if [ "$fail" -ne 0 ]; then
  echo "render-agents-test FAILED" >&2
  exit 1
fi
echo "render-agents-test PASSED"
