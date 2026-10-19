#!/usr/bin/env bash
set -euo pipefail

# Print the personal knowledge-base directory for the git repo containing the
# current directory (or $1). The directory may not exist yet.
#
# The key is the normalized remote URL (origin, else the first remote), so every
# clone and worktree of a repo shares one KB:
#   git@github.com:Acme/billing.git      -> github.com/acme/billing
#   https://user@github.com/acme/billing -> github.com/acme/billing
# A repo with no remote falls back to local/<main checkout folder name>.
#
# Root: $KNOWLEDGE_BASE_DIR, default ~/.knowledge.

die() {
  printf 'kb-path: %s\n' "$1" >&2
  exit 1
}

dir="${1:-$PWD}"
root="${KNOWLEDGE_BASE_DIR:-$HOME/.knowledge}"

git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository: $dir"

remote="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"
if [[ -z "$remote" ]]; then
  first="$(git -C "$dir" remote | head -n 1)"
  [[ -n "$first" ]] && remote="$(git -C "$dir" remote get-url "$first")"
fi

if [[ -n "$remote" ]]; then
  key="$remote"
  key="${key#*://}"
  key="${key#*@}"
  # scp-style host:path becomes host/path; a URL's host:port drops the port so
  # both forms of one remote share a key.
  if [[ "$remote" != *://* ]]; then
    key="${key/://}"
  elif [[ "$key" =~ ^([^/:]+):[0-9]+(/.*)$ ]]; then
    key="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
  fi
  key="${key%/}"
  key="${key%.git}"
  key="$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')"
else
  common="$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir)"
  key="local/$(basename "$(dirname "$common")")"
fi

[[ "$key" != *..* ]] || die "refusing unsafe key: $key"

printf '%s/%s\n' "$root" "$key"
