#!/bin/bash
# Generate merged config files for opencode and clones

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.jsonc"
BASES_DIR="$SCRIPT_DIR/bases"
OUTPUT_DIR="$1"
VARIANT="$2"

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

# Use node to parse JSONC and merge with base
node "$SCRIPT_DIR/parse-jsonc.js" "$CONFIG_FILE" "$base_file" "$output_file"

echo "Generated: $output_file"
