#!/usr/bin/env bash
set -euo pipefail

# Generate per-skill command stubs from skills whose SKILL.md frontmatter
# declares `command: true`.
#
# Usage: generate-skill-commands.sh <skills-source-dir> <command-output-dir>
#
# For each immediate <skills-source-dir>/<skill>/SKILL.md, only the first YAML
# frontmatter block (between the opening and closing `---` lines) is read. A
# top-level exact `command: true` key enables command generation; the top-level
# `name:` key supplies the output filename <command-output-dir>/<name>.md.
# `command: false`, a missing key, indented/nested keys, and body text never
# trigger generation. An enabled skill without a name fails the build.
#
# Every skill is parsed and validated before anything is written. Malformed
# (unclosed) frontmatter, an invalid or duplicate name, and a target file that
# already exists or is a symlink abort the build with no output file emitted.

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

[ "$#" -eq 2 ] || die "usage: $0 <skills-source-dir> <command-output-dir>"

SKILLS_DIR="$1"
OUTPUT_DIR="$2"

[ -d "$SKILLS_DIR" ] || die "skills source directory not found: ${SKILLS_DIR}"
mkdir -p "$OUTPUT_DIR"

shopt -s nullglob

# --- preflight: parse and validate every skill before writing anything ---
declare -a skill_files skill_names
count=0

for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
  rec="$(awk '
    BEGIN { opened = 0; closed = 0; enabled = 0; name = "" }
    NR == 1 && $0 == "---" { opened = 1; next }
    opened && !closed && /^[[:space:]]*---[[:space:]]*$/ { closed = 1; next }
    opened && !closed && /^command:[[:space:]]*true[[:space:]]*$/ { enabled = 1 }
    opened && !closed && /^name:[[:space:]]*/ {
      line = $0
      sub(/^name:[[:space:]]*/, "", line)
      gsub(/^["'"'"']+|[[:space:]]*#.*/, "", line)
      gsub(/["'"'"']+$/, "", line)
      gsub(/[[:space:]]+$/, "", line)
      if (line != "") name = line
    }
    END {
      if (opened && !closed) { printf "MALFORMED\t\n"; exit }
      printf "OK\t%d\t%s\n", enabled, name
    }
  ' "$skill_file")"

  IFS=$'\t' read -r status enabled name <<< "$rec"

  if [ "$status" = "MALFORMED" ]; then
    die "unclosed frontmatter in ${skill_file}: opening '---' has no closing delimiter"
  fi
  [ "$status" = "OK" ] || die "unexpected parse status for ${skill_file}: ${status}"

  [ "$enabled" = "1" ] || continue
  [ -n "$name" ] || die "skill enables command: true but has no name: ${skill_file}"
  [ "${#name}" -le 64 ] || die "invalid skill name '${name}' in ${skill_file}: exceeds 64 characters"
  [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] ||
    die "invalid skill name '${name}' in ${skill_file}: must be <=64 chars, lowercase alphanumerics separated by single hyphens"

  i=0
  while [ "$i" -lt "$count" ]; do
    if [ "${skill_names[i]}" = "$name" ]; then
      die "duplicate skill name '${name}' in ${skill_file} and ${skill_files[i]}"
    fi
    i=$((i + 1))
  done

  target="${OUTPUT_DIR}/${name}.md"
  if [ -e "$target" ] || [ -L "$target" ]; then
    die "refusing to overwrite existing command file: ${target}"
  fi

  skill_files[count]="$skill_file"
  skill_names[count]="$name"
  count=$((count + 1))
done

# --- write phase: every enabled skill already validated, so emit stubs ---
i=0
while [ "$i" -lt "$count" ]; do
  name="${skill_names[i]}"
  cat > "$OUTPUT_DIR/$name.md" <<EOF
---
description: Calls ${name} skill with given arguments
---

Call the \`${name}\` skill with the following \`\$ARGUMENTS\`:
EOF
  printf 'generated %s\n' "$OUTPUT_DIR/$name.md"
  i=$((i + 1))
done
