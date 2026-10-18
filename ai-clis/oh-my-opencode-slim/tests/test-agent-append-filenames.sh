#!/usr/bin/env bash
# Regression test for Slim agent filenames ending in `_append.md`.
#
# Proves a source agent named x_append.md is installed as a Slim extension,
# not as an agent, and is not merged into the Slim-owned x.md agent.
#
# Runs real generators against a throwaway repository fixture; live sources and
# output are never mutated.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GA_ROOT="$(cd "$ROOT/../global-ai" && pwd)"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/oh-my-opencode-slim-agent-filename-test.XXXXXX")"
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
SLIM="$REPO/ai-clis/oh-my-opencode-slim"
GA="$REPO/ai-clis/global-ai"
SLIM_AGENT_SETUP="$SLIM/setup/agent_setup"
GA_AGENT_SETUP="$GA/setup/agent-setup"
GA_OUTPUT="$GA/output/opencode/agents"
SLIM_AGENTS_OUTPUT="$SLIM/output/opencode/agents"
SLIM_EXTENSION_OUTPUT="$SLIM/output/opencode/oh-my-opencode-slim"

mkdir -p "$SLIM_AGENT_SETUP/agents" "$GA_AGENT_SETUP/agents-shared" "$GA_OUTPUT"
cp "$ROOT/setup/agent_setup/generate-slim-agents.sh" "$SLIM_AGENT_SETUP/"
cp "$GA_ROOT/setup/agent-setup/generate-agents-md-opencode.sh" "$GA_AGENT_SETUP/"

cat > "$SLIM_AGENT_SETUP/agents/x_append.md" <<'MD'
---
description: Append filename regression fixture.
mode: subagent
---

APPEND-FILE-BODY
MD

cat > "$SLIM_AGENT_SETUP/agents/x.md" <<'MD'
---
description: Slim-owned base agent fixture.
mode: subagent
---

SLIM-BASE-FILE-BODY
MD
cp "$SLIM_AGENT_SETUP/agents/x.md" "$TMP/expected-x.md"

cat > "$GA_OUTPUT/x.md" <<'MD'
---
description: Global AI base agent fixture.
mode: subagent
---

GLOBAL-AI-BASE-FILE-BODY
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

check "Slim agent generation succeeds" bash "$SLIM_AGENT_SETUP/generate-slim-agents.sh"
check "x_append.md is generated in the Slim extension directory" \
  grep -q 'APPEND-FILE-BODY' "$SLIM_EXTENSION_OUTPUT/x_append.md"
check "x_append.md is not generated in the agents directory" \
  test ! -e "$SLIM_AGENTS_OUTPUT/x_append.md"
check "x.md comes from the Slim non-append source without appended content" \
  cmp -s "$TMP/expected-x.md" "$SLIM_AGENTS_OUTPUT/x.md"

if [ "$fail" -ne 0 ]; then
  echo "agent-append-filename-test FAILED" >&2
  exit 1
fi
echo "agent-append-filename-test PASSED"
