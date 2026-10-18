#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SLIM_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
GA_DIR="$(cd "${SLIM_DIR}/../global-ai" && pwd)"
SLIM_AGENTS_DIR="${SCRIPT_DIR}/agents"
GA_SHARED_DIR="${GA_DIR}/setup/agent-setup/agents-shared"
OUTPUT_DIR="${SLIM_DIR}/output/opencode/agents"
APPEND_OUTPUT_DIR="${SLIM_DIR}/output/opencode/oh-my-opencode-slim"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

AGENTS_DIR="$SLIM_AGENTS_DIR" \
  SHARED_DIR="$GA_SHARED_DIR" \
  OUTPUT_DIR="$TMP_DIR" \
  bash "${GA_DIR}/setup/agent-setup/generate-agents-md-opencode.sh"

rm -rf "$OUTPUT_DIR" "$APPEND_OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR" "$APPEND_OUTPUT_DIR"

for slim_file in "$TMP_DIR"/*.md; do
  [ -e "$slim_file" ] || continue
  filename="$(basename "$slim_file")"
  if [[ "$filename" == *_append.md ]]; then
    cp "$slim_file" "${APPEND_OUTPUT_DIR}/${filename}"
    echo "  preserve ${filename}"
  else
    agent_name="${filename%.md}"
    agent_name="${agent_name//_/-}"
    target="${OUTPUT_DIR}/${agent_name}.md"
    cp "$slim_file" "$target"
    echo "  replace ${filename} -> ${agent_name}.md"
  fi
done

echo "Slim agents generated in ${OUTPUT_DIR}"
