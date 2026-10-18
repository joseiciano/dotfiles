#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SLIM_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
GA_DIR="$(cd "${SLIM_DIR}/../global-ai" && pwd)"
SLIM_AGENTS_DIR="${SLIM_DIR}/setup/agent_setup/agents"
OUTPUT_DIR="${SLIM_DIR}/output/opencode"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

for slim_file in "$SLIM_AGENTS_DIR"/*.md; do
  [ -e "$slim_file" ] || continue
  filename="$(basename "$slim_file")"
  [[ "$filename" == *_append.md ]] && continue
  [ -s "$slim_file" ] || continue
  agent_name="${filename%.md}"
  agent_name="${agent_name//_/-}"
  cp "$slim_file" "$TMP_DIR/${agent_name}.md"
done

AGENTS_DIR="$TMP_DIR" \
  bash "${GA_DIR}/setup/config/opencode-and-clones-only/generate-config.sh" "$OUTPUT_DIR" opencode

node - "$OUTPUT_DIR/opencode.json" "$TMP_DIR" <<'JS'
const fs = require('fs');
const path = require('path');

const configPath = process.argv[2];
const agentsDir = process.argv[3];
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const allowedAgents = new Set(
  fs.readdirSync(agentsDir)
    .filter((file) => file.endsWith('.md'))
    .map((file) => path.basename(file, '.md')),
);

if (config.agent) {
  config.agent = Object.fromEntries(
    Object.entries(config.agent).filter(([name]) => allowedAgents.has(name)),
  );
}
if (config.default_agent && !allowedAgents.has(config.default_agent)) {
  delete config.default_agent;
}

fs.writeFileSync(configPath, `${JSON.stringify(config, null, 2)}\n`);
JS

echo "Slim config generated: ${OUTPUT_DIR}/opencode.json"
