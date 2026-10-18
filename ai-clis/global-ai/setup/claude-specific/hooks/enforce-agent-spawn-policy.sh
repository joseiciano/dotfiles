#!/usr/bin/env bash
set -euo pipefail

deny() {
  printf 'Agent spawn denied: %s\n' "$1" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 \
  || deny "spawn policy requires jq"

input="$(cat)"
if ! jq -e '
  type == "object"
  and (.tool_input | type == "object")
  and (.tool_input.subagent_type | type == "string" and length > 0)
' >/dev/null 2>&1 <<<"$input"; then
  deny "invalid PreToolUse Agent payload"
fi

agent_id="$(jq -r '.agent_id // ""' <<<"$input")"
agent_type="$(jq -r '.agent_type // ""' <<<"$input")"
subagent_type="$(jq -r '.tool_input.subagent_type' <<<"$input")"

# The main session has no agent_id. Keep its direct delegation surface explicit
# so internal agents and newly installed agent types cannot be spawned by
# accident.
if [[ -z "$agent_id" ]]; then
  case "$subagent_type" in
    scout|librarian|Plan|product-manager|designer|reviewer|tester|sonic|task|council)
      exit 0
      ;;
    *)
      deny "parent may not spawn '${subagent_type}' directly"
      ;;
  esac
fi

# Claude Code ignores Agent(type) narrowing when an agent runs as a subagent,
# so enforce the two intentional nested delegation edges here.
case "$agent_type" in
  council)
    [[ "$subagent_type" == "councillor" ]] \
      || deny "council may only spawn 'councillor'"
    ;;
  Plan)
    case "$subagent_type" in
      scout|librarian) ;;
      *) deny "Plan may only spawn 'scout' or 'librarian'" ;;
    esac
    ;;
esac
