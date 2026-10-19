#!/usr/bin/env bash
set -euo pipefail

# Print each KB work item for the branch checked out in the current directory
# (or $1), one directory per line. A work item is <kb>/work/<slug>/ or a module
# of one, <kb>/work/<slug>/<module>/, and it belongs to every branch its
# plan.md frontmatter lists:
#   branches: [feat/billing-1, feat/billing-2]
# or
#   branches:
#     - feat/billing-1
#
# Prints nothing on a detached HEAD or when no plan lists the branch.

dir="${1:-$PWD}"
kb="$(bash "$(dirname "${BASH_SOURCE[0]}")/kb-path.sh" "$dir")"
branch="$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"

[[ -n "$branch" && -d "$kb/work" ]] || exit 0

shopt -s nullglob
for plan in "$kb"/work/*/plan.md "$kb"/work/*/*/plan.md; do
  awk -v branch="$branch" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    function trim(s) { gsub(/^[ \t"'\'']+|[ \t"'\'']+$/, "", s); return s }
    /^branches:/ {
      in_list = 1
      rest = $0
      sub(/^branches:[ \t]*/, "", rest)
      if (rest ~ /^\[/) {
        gsub(/[][]/, "", rest)
        n = split(rest, items, ",")
        for (i = 1; i <= n; i++) if (trim(items[i]) == branch) found = 1
        in_list = 0
      }
      next
    }
    in_list && /^[ \t]*-/ {
      item = $0
      sub(/^[ \t]*-/, "", item)
      if (trim(item) == branch) found = 1
      next
    }
    { in_list = 0 }
    END { exit found ? 0 : 1 }
  ' "$plan" && dirname "$plan"
done
exit 0
