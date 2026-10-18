#!/usr/bin/env bash
# Regression test for Slim agent/config source ownership.
#
# Proves real Slim generators keep Global-AI-only agents out of both generated
# agent files and opencode.json. Non-append Slim agents belong under agents/;
# append files belong only under oh-my-opencode-slim/.
#
# Runs real generators against a throwaway repository fixture; live sources and
# output are never mutated.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GA_ROOT="$(cd "$ROOT/../global-ai" && pwd)"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/oh-my-opencode-slim-agent-source-test.XXXXXX")"
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
SLIM="$REPO/ai-clis/oh-my-opencode-slim"
GA="$REPO/ai-clis/global-ai"
SLIM_AGENT_SETUP="$SLIM/setup/agent_setup"
SLIM_CONFIG_SETUP="$SLIM/setup/config"
GA_AGENT_SETUP="$GA/setup/agent-setup"
GA_CONFIG_SETUP="$GA/setup/config/opencode-and-clones-only"
GA_AGENTS_OUTPUT="$GA/output/opencode/agents"
SLIM_OUTPUT="$SLIM/output/opencode"
SLIM_AGENTS_OUTPUT="$SLIM_OUTPUT/agents"
SLIM_APPEND_OUTPUT="$SLIM_OUTPUT/oh-my-opencode-slim"

mkdir -p \
  "$SLIM_AGENT_SETUP/agents" \
  "$SLIM_CONFIG_SETUP" \
  "$GA_AGENT_SETUP/agents" \
  "$GA_AGENT_SETUP/agents-shared" \
  "$GA/setup/config" \
  "$GA_AGENTS_OUTPUT"
cp "$ROOT/setup/agent_setup/generate-slim-agents.sh" "$SLIM_AGENT_SETUP/"
cp "$ROOT/setup/config/generate-slim-config.sh" "$SLIM_CONFIG_SETUP/"
cp "$GA_ROOT/setup/agent-setup/generate-agents-md-opencode.sh" "$GA_AGENT_SETUP/"
cp -R "$GA_ROOT/setup/config/opencode-and-clones-only" "$GA_CONFIG_SETUP"

# Remove unrelated static agent registrations so generated keys come only from
# fixture source metadata.
cat > "$GA_CONFIG_SETUP/config.jsonc" <<'JSONC'
{
  "default_agent": "orchestration",
  "agent": {}
}
JSONC

cat > "$GA_AGENT_SETUP/agents/orchestration.md" <<'MD'
---
description: Agent available only from Global AI.
mode: primary
model: openai/global-only-model
---

GLOBAL-ONLY-BODY
MD

cat > "$SLIM_AGENT_SETUP/agents/slim_only.md" <<'MD'
---
description: Agent owned by Slim.
mode: subagent
model: openai/slim-only-model
---

SLIM-ONLY-BODY
MD

cat > "$SLIM_AGENT_SETUP/agents/librarian_append.md" <<'MD'
---
description: Slim extension fixture.
mode: subagent
model: openai/append-only-model
---

APPEND-ONLY-BODY
MD

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

check_exact_files() {
  local desc="$1" dir="$2"
  shift 2
  local expected=("$@") actual=() file

  shopt -s nullglob
  for file in "$dir"/*.md; do
    actual+=("$(basename "$file")")
  done
  shopt -u nullglob

  if [[ "${actual[*]}" == "${expected[*]}" ]]; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc (expected: ${expected[*]}; actual: ${actual[*]})"
    fail=1
  fi
}

# Build realistic Global AI output first. Slim must not inherit it.
check "Global AI fixture agent generation succeeds" \
  env AGENTS_DIR="$GA_AGENT_SETUP/agents" \
      SHARED_DIR="$GA_AGENT_SETUP/agents-shared" \
      OUTPUT_DIR="$GA_AGENTS_OUTPUT" \
      bash "$GA_AGENT_SETUP/generate-agents-md-opencode.sh"
check "Slim agent generation succeeds" bash "$SLIM_AGENT_SETUP/generate-slim-agents.sh"

check_exact_files \
  "agents directory contains only non-append Slim source agents" \
  "$SLIM_AGENTS_OUTPUT" \
  "slim-only.md"
check "Slim agent output contains Slim body" \
  grep -q 'SLIM-ONLY-BODY' "$SLIM_AGENTS_OUTPUT/slim-only.md"
check_exact_files \
  "Slim extension directory contains append source files only" \
  "$SLIM_APPEND_OUTPUT" \
  "librarian_append.md"
check "append output contains extension body" \
  grep -q 'APPEND-ONLY-BODY' "$SLIM_APPEND_OUTPUT/librarian_append.md"

check "Slim config generation succeeds" bash "$SLIM_CONFIG_SETUP/generate-slim-config.sh"
if node - "$SLIM_OUTPUT/opencode.json" <<'JS'
const fs = require('fs');
const config = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const actual = Object.keys(config.agent || {}).sort();
const expected = ['slim-only'];

if (JSON.stringify(actual) === JSON.stringify(expected)) {
  console.log('ok   - opencode.json registers only non-append Slim source agents');
  process.exit(0);
}

console.log(
  'FAIL - opencode.json registers only non-append Slim source agents ' +
  `(expected: ${expected.join(' ')}; actual: ${actual.join(' ')})`
);
process.exit(1);
JS
then
  :
else
  fail=1
fi

if node - "$SLIM_OUTPUT/opencode.json" <<'JS'
const fs = require('fs');
const config = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const slimOwnedAgents = ['slim-only'];

if (
  config.default_agent === undefined ||
  slimOwnedAgents.includes(config.default_agent)
) {
  console.log('ok   - opencode.json default_agent is absent or Slim-owned');
  process.exit(0);
}

console.log(
  'FAIL - opencode.json default_agent is absent or Slim-owned ' +
  `(actual: ${config.default_agent})`
);
process.exit(1);
JS
then
  :
else
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo "agent-source-boundary-test FAILED" >&2
  exit 1
fi
echo "agent-source-boundary-test PASSED"
