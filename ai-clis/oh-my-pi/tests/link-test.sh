#!/usr/bin/env bash
# Regression test for Oh My Pi's native skill and command links.
#
# Runs `make link` with a throwaway HOME. The source output is checked before
# the command runs so a missing generated fixture cannot masquerade as a link
# regression.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/omp-link-test.XXXXXX")"
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

HOME_DIR="$TMP/home"
mkdir -p "$HOME_DIR/.omp/agent"
SKILL_SOURCE="$ROOT/output/skills/plan-implementation-plan/SKILL.md"
COMMAND_SOURCE="$ROOT/output/command/plan-implementation-plan.md"

for source in "$SKILL_SOURCE" "$COMMAND_SOURCE"; do
  if [[ ! -f "$source" ]]; then
    printf 'fixture error: expected generated file is missing: %s\n' "$source" >&2
    exit 2
  fi
done

if ! HOME="$HOME_DIR" make -C "$ROOT" link; then
  printf 'FAIL - make link exited unsuccessfully\n' >&2
  exit 1
fi

fail=0
check_file() {
  local description="$1"
  local path="$2"
  if [[ -f "$path" ]]; then
    printf 'ok   - %s\n' "$description"
  else
    printf 'FAIL - %s (missing %s)\n' "$description" "$path"
    fail=1
  fi
}

check_link() {
  local description="$1"
  local link="$2"
  local expected_target="$3"
  if [[ -L "$link" ]] && [[ "$(readlink "$link")" == "$expected_target" ]]; then
    printf 'ok   - %s\n' "$description"
  else
    printf 'FAIL - %s (expected %s -> %s)\n' "$description" "$link" "$expected_target"
    fail=1
  fi
}

check_file \
  'make link installs plan-implementation-plan skill in native OMP path' \
  "$HOME_DIR/.omp/agent/skills/plan-implementation-plan/SKILL.md"
check_link \
  'make link keeps plan-implementation-plan command linked' \
  "$HOME_DIR/.claude/commands/plan-implementation-plan.md" \
  "$COMMAND_SOURCE"

if (( fail != 0 )); then
  echo 'omp-link-test FAILED' >&2
  exit 1
fi

echo 'omp-link-test PASSED'
