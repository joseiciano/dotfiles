#!/bin/bash
set -euo pipefail
# Generate merged config files for opencode and clones.
#
# `model`, `fallback_models`, `variant`, `temperature`, `skills`, and `mcps`
# for each agent are build-only metadata owned by the source agent frontmatter
# under AGENTS_DIR (default: setup/agent-setup/agents). parse-jsonc.js reads
# them and merges them into agent.<filename-without-.md>. AGENTS_DIR is
# environment-overridable so tests can point at a fixture.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.jsonc"
BASES_DIR="$SCRIPT_DIR/bases"
OUTPUT_DIR="${1:-}"
VARIANT="${2:-}"

if [ -z "$OUTPUT_DIR" ] || [ -z "$VARIANT" ]; then
    echo "Usage: $0 <output-dir> <variant>"
    exit 1
fi

# Process the specified variant
base_file="$BASES_DIR/$VARIANT.json"
if [ ! -f "$base_file" ]; then
    echo "Base file not found: $base_file"
    exit 1
fi

output_file="$OUTPUT_DIR/$VARIANT.json"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Source agent dir owning build-only `model` / `fallback_models` / `variant` /
# `temperature` / `skills` / `mcps` metadata
AGENTS_DIR="${AGENTS_DIR:-"$(cd "$SCRIPT_DIR/../../agent-setup/agents" && pwd)"}"
export AGENTS_DIR

# Use node to parse JSONC and merge with base
node "$SCRIPT_DIR/parse-jsonc.js" "$CONFIG_FILE" "$base_file" "$output_file"

echo "Generated: $output_file"
