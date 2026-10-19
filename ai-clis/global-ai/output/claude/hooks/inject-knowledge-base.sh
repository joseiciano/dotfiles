#!/usr/bin/env bash
set -euo pipefail

# SessionStart hook: print this repo's personal KB INDEX.md and RULES.md so they
# load as context without relying on the agent to read them. Silent outside a
# git repo or when the KB has neither file.

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
kb="$(bash "$HOME/.claude/skills/knowledge-base/scripts/kb-path.sh" "$dir" 2>/dev/null)" || exit 0

for file in INDEX.md RULES.md; do
  [[ -f "$kb/$file" ]] || continue
  printf '<knowledge-base file="%s">\n' "$kb/$file"
  cat "$kb/$file"
  printf '\n</knowledge-base>\n'
done
