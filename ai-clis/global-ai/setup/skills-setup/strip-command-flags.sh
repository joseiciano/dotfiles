#!/usr/bin/env bash
set -euo pipefail

# Remove the `command: true` frontmatter key from the final output copies of
# skills. The source skills keep the key (it drives command generation in
# generate-skill-commands.sh); the skills published to the CLIs must not
# expose it.
#
# Usage: strip-command-flags.sh <skills-output-dir>
#
# For each immediate <skills-output-dir>/<skill>/SKILL.md, only the first YAML
# frontmatter block (between the opening and closing `---` lines) is touched.
# A top-level exact `command: true` line is deleted; everything else —
# `command: false`, indented/nested keys, and body text — is preserved
# byte-for-byte. Files without frontmatter are left unchanged.
# Idempotent: running again is a no-op.

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

[ "$#" -eq 1 ] || die "usage: $0 <skills-output-dir>"

SKILLS_DIR="$1"
[ -d "$SKILLS_DIR" ] || die "skills output directory not found: ${SKILLS_DIR}"

shopt -s nullglob

for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
  tmp="$(mktemp "${skill_file%.md}.XXXXXX")"
  awk '
    BEGIN { opened = 0; closed = 0 }
    NR == 1 && $0 == "---" { opened = 1; print; next }
    opened && !closed && /^[[:space:]]*---[[:space:]]*$/ { closed = 1; print; next }
    opened && !closed && /^command:[[:space:]]*true[[:space:]]*$/ { next }
    { print }
  ' "$skill_file" > "$tmp"
  # awk's print adds a trailing newline; restore the original's missing one.
  if [ -n "$(tail -c 1 "$skill_file")" ]; then
    LC_ALL=C perl -e 'truncate $ARGV[0], ((-s $ARGV[0]) - 1) or exit 1' "$tmp"
  fi
  if cmp -s "$tmp" "$skill_file"; then
    rm -f "$tmp"
  else
    mv "$tmp" "$skill_file"
    printf 'stripped command flag from %s\n' "$skill_file"
  fi
done
