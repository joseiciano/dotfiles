#!/usr/bin/env bash
set -euo pipefail

# Generate opencode agent files from agent templates plus shared prompt snippets.
#
# Source layout:
#   global-ai/agent-setup/agents/<agent>.md
#   global-ai/agent-setup/agents-shared/<shared-name>
#
# Agent templates may include frontmatter like:
#   ---
#   description: Example agent.
#   mode: subagent
#   shared:
#     - coding-shared
#   permission:
#     edit: deny
#   ---
#
# The `shared` frontmatter key is build-only metadata. Generated agent files
# omit that key, then append matching files from agents-shared/ to end.
#
# Output layout:
#   global-ai/output/opencode/agents/<agent>.md

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="${AGENTS_DIR:-"${SCRIPT_DIR}/agents"}"
SHARED_DIR="${SHARED_DIR:-"${SCRIPT_DIR}/agents-shared"}"
OUTPUT_DIR="${OUTPUT_DIR:-"${SCRIPT_DIR}/../../output/opencode/agents"}"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_dir() {
  local dir="$1"
  local label="$2"

  [[ -d "$dir" ]] || die "${label} directory not found: ${dir}"
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

write_agent_without_shared_key() {
  local source_file="$1"
  local output_file="$2"

  awk '
    BEGIN { in_frontmatter = 0; in_shared = 0; in_permission_block = 0; seen_edit = 0 }
    NR == 1 && $0 == "---" { in_frontmatter = 1; print; next }
    in_frontmatter && /^[[:space:]]*---[[:space:]]*$/ { in_frontmatter = 0; in_shared = 0; in_permission_block = 0; seen_edit = 0; print; next }
    in_frontmatter && /^[[:space:]]*shared:[[:space:]]*$/ { in_shared = 1; next }
    in_frontmatter && in_shared && /^[[:space:]]*-[[:space:]]*/ { next }
    in_frontmatter && in_shared { in_shared = 0 }

    # Detect permissions: block and convert to permission:
    in_frontmatter && /^[[:space:]]*permissions:[[:space:]]*$/ {
      sub(/^[[:space:]]*permissions:/, "permission:")
      print
      in_permission_block = 1
      seen_edit = 0
      next
    }

    # Detect permission: block (already correct)
    in_frontmatter && /^[[:space:]]*permission:[[:space:]]*$/ {
      in_permission_block = 1
      seen_edit = 0
      print
      next
    }

    # Inside permission block, track if edit: exists (skip if we already converted write: to edit:)
    in_permission_block && /^[[:space:]]*edit:[[:space:]]*/ {
      if (!seen_edit) {
        seen_edit = 1
        print
      }
      next
    }

    # Inside permission block, convert top-level write: to edit: (only if edit: not already seen)
    in_permission_block && /^[[:space:]]*write:[[:space:]]*/ {
      if (!seen_edit) {
        sub(/^[[:space:]]*write:/, "  edit:")
        seen_edit = 1
        print
      }
      # If edit: already exists, skip this write: line entirely (duplicate)
      next
    }

    # Exit permission block if we hit another frontmatter key at root level
    in_permission_block && /^[[:space:]]*[a-zA-Z_]+:[[:space:]]*$/ && !/^[[:space:]]+/ {
      in_permission_block = 0
      seen_edit = 0
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
  mkdir -p "$OUTPUT_DIR"

  shopt -s nullglob
  local agent_files=("${AGENTS_DIR}"/*.md)
  ((${#agent_files[@]} > 0)) || die "no agent .md files found in ${AGENTS_DIR}"

  local agent_file output_file shared_names shared_name

  for agent_file in "${agent_files[@]}"; do
    output_file="${OUTPUT_DIR}/$(basename -- "$agent_file")"
    mapfile -t shared_names < <(extract_shared_names "$agent_file")

    write_agent_without_shared_key "$agent_file" "$output_file"

    for shared_name in "${shared_names[@]}"; do
      append_shared_file "$shared_name" "$output_file"
    done

    printf 'generated %s\n' "$output_file"
  done
}

main "$@"
