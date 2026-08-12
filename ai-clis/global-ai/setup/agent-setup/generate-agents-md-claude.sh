#!/usr/bin/env bash
set -euo pipefail

# Generate Claude Code agent files from agent templates plus shared prompt snippets.
#
# Source layout:
#   global-ai/agent-setup/agents/<agent>.md
#   global-ai/agent-setup/agents-shared/<shared-name>
#
# Agent templates may include frontmatter like:
#   ---
#   description: Example agent.
#   shared:
#     - coding-shared
#   ---
#
# The `shared` frontmatter key is build-only metadata. Generated agent files
# omit that key, convert `permissions` frontmatter to Claude Code `tools`,
# then append matching files from agents-shared/ to end.
#
# Output layout:
#   global-ai/output/claude-code/agents/<agent>.md

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="${AGENTS_DIR:-"${SCRIPT_DIR}/agents"}"
SHARED_DIR="${SHARED_DIR:-"${SCRIPT_DIR}/agents-shared"}"
OUTPUT_DIR="${OUTPUT_DIR:-"${SCRIPT_DIR}/../../output/claude-code/agents"}"
MODELS_FILE="${MODELS_FILE:-"${SCRIPT_DIR}/models.json"}"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_dir() {
  local dir="$1"
  local label="$2"

  [[ -d "$dir" ]] || die "${label} directory not found: ${dir}"
}

get_claude_model() {
  local agent_name="$1"

  python3 - "$MODELS_FILE" "$agent_name" <<'PY'
import json
import sys

models_file, agent_name = sys.argv[1], sys.argv[2]
with open(models_file, "r", encoding="utf-8") as fh:
    models = json.load(fh)

agent_models = models.get(agent_name)
if not isinstance(agent_models, dict):
    sys.exit(1)

model = agent_models.get("claude")
if not model:
    sys.exit(1)

print(model)
PY
}

extract_shared_names() {
  local file="$1"

  awk '
    BEGIN { in_frontmatter = 0; in_shared = 0 }
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && /^[[:space:]]*---[[:space:]]*$/ { exit }
    in_frontmatter && /^[[:space:]]*shared:[[:space:]]*$/ { in_shared = 1; next }
    in_frontmatter && in_shared && /^[^[:space:]-]/ { in_shared = 0 }
    in_frontmatter && in_shared && /^[[:space:]]*-[[:space:]]*/ {
      line = $0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      sub(/[[:space:]]*#.*/, "", line)
      gsub(/^[[:space:]"'"'"']+|[[:space:]"'"'"']+$/, "", line)
      if (line != "") print line
    }
  ' "$file"
}

write_agent_for_claude() {
  local source_file="$1"
  local output_file="$2"
  local model="$3"

  awk -v model="$model" '
    function indent_width(s, prefix) {
      prefix = s
      sub(/[^[:space:]].*$/, "", prefix)
      gsub(/\t/, "  ", prefix)
      return length(prefix)
    }

    function trim(s) {
      gsub(/^[[:space:]]+|[[:space:],]+$/, "", s)
      gsub(/^["'"'"']|["'"'"']$/, "", s)
      return s
    }

    function add_tool(tool, action) {
      tool = trim(tool)
      action = trim(action)

      if (tool == "" || tool == "*" || tool == "external_directory") return
      if (action != "allow" && action != "ask") return
      if (seen_tool[tool]) return

      tools[++tool_count] = tool
      seen_tool[tool] = 1
    }

    function flush_permissions(i) {
      if (!in_permissions) return

      if (tool_count > 0) {
        print "tools:"
        for (i = 1; i <= tool_count; i++) {
          print "  - " tools[i]
        }
      }

      delete tools
      delete seen_tool
      tool_count = 0
      in_permissions = 0
      permissions_child_indent = -1
      current_permission_tool = ""
    }

    function parse_permission_line(line, current_indent, key, action) {
      sub(/[[:space:]]*#.*/, "", line)
      if (line !~ /^[[:space:]]*[^:]+:/) return

      key = line
      sub(/^[[:space:]]*/, "", key)
      sub(/:.*/, "", key)

      action = line
      sub(/^[[:space:]]*[^:]+:[[:space:]]*/, "", action)

      if (permissions_child_indent < 0 || current_indent <= permissions_child_indent) {
        permissions_child_indent = current_indent
        current_permission_tool = key
        add_tool(key, action)
      } else {
        add_tool(current_permission_tool, action)
      }
    }

    BEGIN {
      in_frontmatter = 0
      in_shared = 0
      in_permissions = 0
      permissions_child_indent = -1
    }

    NR == 1 && $0 == "---" { in_frontmatter = 1; print; print "model: " model; next }
    in_frontmatter && /^[[:space:]]*---[[:space:]]*$/ { flush_permissions(); in_frontmatter = 0; in_shared = 0; print "---"; next }
    in_frontmatter && /^[[:space:]]*model:[[:space:]]*/ { next }
    in_frontmatter && /^[[:space:]]*shared:[[:space:]]*$/ { in_shared = 1; next }
    in_frontmatter && in_shared && /^[[:space:]]*-[[:space:]]*/ { next }
    in_frontmatter && in_shared { in_shared = 0 }
    in_frontmatter && /^[[:space:]]*permissions:[[:space:]]*$/ {
      flush_permissions()
      in_permissions = 1
      permissions_indent = indent_width($0)
      next
    }
    in_frontmatter && in_permissions {
      current_indent = indent_width($0)

      if ($0 ~ /^[[:space:]]*$/ || current_indent > permissions_indent) {
        parse_permission_line($0, current_indent)
        next
      }

      flush_permissions()
    }
    { print }
  ' "$source_file" > "$output_file"
}

shift_markdown_headers() {
  local file="$1"

  awk '
    /^[[:space:]]*(```|~~~)/ {
      in_fence = !in_fence
      print
      next
    }

    !in_fence && /^[[:space:]]{0,3}#+([[:space:]]|$)/ {
      sub(/^[[:space:]]{0,3}#+/, "&#")
    }

    { print }
  ' "$file"
}

append_shared_file() {
  local shared_name="$1"
  local output_file="$2"
  local shared_file="${SHARED_DIR}/${shared_name}"

  if [[ ! -f "$shared_file" && -f "${shared_file}.md" ]]; then
    shared_file="${shared_file}.md"
  fi

  [[ -f "$shared_file" ]] || die "shared file not found for '${shared_name}': ${SHARED_DIR}/${shared_name}"

  {
    printf '\n\n'
    shift_markdown_headers "$shared_file"
  } >> "$output_file"
}

main() {
  require_dir "$AGENTS_DIR" "agents"
  require_dir "$SHARED_DIR" "agents-shared"
  [[ -f "$MODELS_FILE" ]] || die "Claude models file not found: ${MODELS_FILE}"
  mkdir -p "$OUTPUT_DIR"

  shopt -s nullglob
  local agent_files=("${AGENTS_DIR}"/*.md)
  ((${#agent_files[@]} > 0)) || die "no agent .md files found in ${AGENTS_DIR}"

  local agent_file agent_name model output_file shared_names shared_name

  for agent_file in "${agent_files[@]}"; do
    agent_name="$(basename -- "$agent_file" .md)"
    model="$(get_claude_model "$agent_name")" || die "model not found for agent '${agent_name}' in ${MODELS_FILE}"
    output_file="${OUTPUT_DIR}/$(basename -- "$agent_file")"
    mapfile -t shared_names < <(extract_shared_names "$agent_file")

    write_agent_for_claude "$agent_file" "$output_file" "$model"

    for shared_name in "${shared_names[@]}"; do
      append_shared_file "$shared_name" "$output_file"
    done

    printf 'generated %s\n' "$output_file"
  done
}

main "$@"
