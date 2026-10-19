#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook (Write|Edit|MultiEdit|NotebookEdit|Bash): keep personal docs
# out of version control. A new, untracked repo file that the knowledge-base
# skill owns (ADRs, glossaries, specs, plans, CONSTRAINTS.md) is refused with
# the KB path to write it to instead. The KB directory is created so the retry
# succeeds, and a repo without a KB index is told to run Setup afterwards.
#
# Files git already tracks are team-owned and stay editable. Bash is checked
# only for `>`, `>>` and `tee` targets; `->` and `=>` are not redirects. KB_ALLOW_REPO_DOCS=1 turns the hook off.

[[ "${KB_ALLOW_REPO_DOCS:-}" == 1 ]] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

SCRIPTS="${KB_SCRIPTS_DIR:-$HOME/.claude/skills/knowledge-base/scripts}"
kb_root="${KNOWLEDGE_BASE_DIR:-$HOME/.knowledge}"
[[ -d "$kb_root" ]] && kb_root="$(cd -P "$kb_root" && pwd)"

input="$(cat)"
tool="$(jq -r '.tool_name // ""' <<<"$input" 2>/dev/null)" || exit 0
cwd="$(jq -r '.cwd // ""' <<<"$input")"
[[ -n "$cwd" ]] || cwd="$PWD"

# Print the absolute physical form of $1, resolved against $cwd, even when its
# directories do not exist yet.
absolute() {
  local path="$1" dir rest=""
  [[ "$path" == /* ]] || path="$cwd/$path"
  dir="$(dirname "$path")"
  rest="$(basename "$path")"
  while [[ ! -d "$dir" ]]; do
    rest="$(basename "$dir")/$rest"
    dir="$(dirname "$dir")"
  done
  printf '%s/%s\n' "$(cd -P "$dir" && pwd)" "$rest"
}

# Print the KB file that should hold repo-relative path $1, or nothing if the
# path is not a KB-owned doc. Work-item files name the matching work item when
# exactly one plan lists the current branch.
kb_target() {
  local rel="$1" kb="$2" top="$3" name ctx items
  case "$rel" in
    docs/adr/* | */docs/adr/*)
      ctx="${rel%%docs/adr/*}"
      printf '%s/%sadr/%s\n' "$kb" "$ctx" "${rel##*docs/adr/}"
      ;;
    docs/decisions/* | */docs/decisions/*)
      ctx="${rel%%docs/decisions/*}"
      printf '%s/%sadr/%s\n' "$kb" "$ctx" "${rel##*docs/decisions/}"
      ;;
    GLOSSARY.md | */GLOSSARY.md | CONSTRAINTS.md)
      printf '%s/%s\n' "$kb" "$rel"
      ;;
    SPEC.md | SPEC-*.md | docs/SPEC.md | tasks/plan.md | tasks/todo.md)
      name="$(basename "$rel")"
      [[ "$name" == SPEC* ]] && name=SPEC.md
      items="$(bash "$SCRIPTS/kb-work.sh" "$top" 2>/dev/null || true)"
      if [[ -n "$items" && "$items" != *$'\n'* ]]; then
        printf '%s/%s\n' "$items" "$name"
      else
        printf '%s/work/<slug>/[<module>/]%s\n' "$kb" "$name"
      fi
      ;;
  esac
}

# check <path>: exit 2 with the redirect if <path> must go to the KB.
check() {
  local file dir top rel kb target
  file="$(absolute "$1")"
  [[ "$file" == "$kb_root"/* ]] && return 0
  dir="$(dirname "$file")"
  while [[ ! -d "$dir" ]]; do dir="$(dirname "$dir")"; done
  top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || return 0
  top="$(cd -P "$top" && pwd)"
  rel="${file#"$top"/}"
  [[ "$rel" != "$file" ]] || return 0
  kb="$(bash "$SCRIPTS/kb-path.sh" "$top" 2>/dev/null)" || return 0
  target="$(kb_target "$rel" "$kb" "$top")"
  [[ -n "$target" ]] || return 0
  git -C "$top" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1 && return 0

  mkdir -p "$kb"
  {
    printf 'Personal docs stay out of the repo. Write %s to %s instead.\n' "$rel" "$target"
    if [[ "$target" == *'<slug>'* ]]; then
      printf 'Pick the work item as the knowledge-base skill'"'"'s "Work items" section describes, and list the current branch in its plan.md frontmatter.\n'
    fi
    if [[ ! -f "$kb/INDEX.md" ]]; then
      printf 'This repo has no knowledge base index yet. After this write, run the knowledge-base skill'"'"'s Setup operation.\n'
    fi
    printf 'Only if the user explicitly asked for the repo copy, tell them to rerun with KB_ALLOW_REPO_DOCS=1.\n'
  } >&2
  exit 2
}

case "$tool" in
  Write | Edit | MultiEdit)
    path="$(jq -r '.tool_input.file_path // ""' <<<"$input")"
    [[ -n "$path" ]] && check "$path"
    ;;
  NotebookEdit)
    path="$(jq -r '.tool_input.notebook_path // ""' <<<"$input")"
    [[ -n "$path" ]] && check "$path"
    ;;
  Bash)
    command="$(jq -r '.tool_input.command // ""' <<<"$input")"
    while IFS= read -r target; do
      target="${target#[ 0-9|;&]}"
      target="${target#tee}"
      target="${target#"${target%%[! >]*}"}"
      target="${target#-a }"
      target="${target#"${target%%[! ]*}"}"
      target="${target//[\"\']/}"
      [[ -n "$target" && "$target" != /dev/* && "$target" != '&'* ]] && check "$target"
    done < <(grep -oE '(^|[ 0-9|;&])(>>?|tee( +-a)?) *[^ ;|&<>()]+' <<<"$command" || true)
    ;;
esac
exit 0
