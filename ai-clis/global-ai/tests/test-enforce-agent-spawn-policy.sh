#!/usr/bin/env bash
# Regression coverage for Claude's Agent PreToolUse spawn policy.
#
# The hook is exercised as an external process with representative Claude hook
# payloads. Allowed calls must exit successfully; denied calls must either exit
# 2 with a reason or return a Claude-compatible deny decision with a reason.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/setup/claude-specific/hooks/enforce-agent-spawn-policy.sh"

fail=0

check_allow() {
  local description="$1"
  local input="$2"
  local output
  local status

  if output="$(printf '%s\n' "$input" | LC_ALL=C "$HOOK" 2>&1)"; then
    status=0
  else
    status=$?
  fi

  if [[ "$status" -eq 0 ]]; then
    printf 'ok   - %s\n' "$description"
  else
    printf 'FAIL - %s (expected allow/exit 0, got exit %s: %s)\n' \
      "$description" "$status" "$output" >&2
    fail=1
  fi
}

check_deny() {
  local description="$1"
  local input="$2"
  local output
  local status

  if output="$(printf '%s\n' "$input" | LC_ALL=C "$HOOK" 2>&1)"; then
    status=0
  else
    status=$?
  fi

  # Claude accepts either a blocking exit status with a human-readable reason,
  # or a PreToolUse JSON denial carrying permissionDecisionReason.
  if [[ "$status" -eq 2 ]]; then
    if [[ -n "${output//[[:space:]]/}" ]]; then
      printf 'ok   - %s\n' "$description"
    else
      printf 'FAIL - %s (exit 2 without denial reason)\n' "$description" >&2
      fail=1
    fi
  elif [[ "$status" -eq 0 ]] \
    && printf '%s\n' "$output" \
      | grep -Eiq '"permissionDecision"[[:space:]]*:[[:space:]]*"deny"' \
    && printf '%s\n' "$output" \
      | grep -Eiq '"permissionDecisionReason"[[:space:]]*:[[:space:]]*"[^"]+"'; then
    printf 'ok   - %s\n' "$description"
  else
    printf 'FAIL - %s (expected deny JSON or exit 2 with reason, got exit %s: %s)\n' \
      "$description" "$status" "$output" >&2
    fail=1
  fi
}

check_no_decision() {
  local description="$1"
  local input="$2"
  local output
  local status

  if output="$(printf '%s\n' "$input" | LC_ALL=C "$HOOK" 2>&1)"; then
    status=0
  else
    status=$?
  fi

  if [[ "$status" -eq 0 && -z "${output//[[:space:]]/}" ]]; then
    printf 'ok   - %s\n' "$description"
  else
    printf 'FAIL - %s (expected no decision/exit 0, got exit %s: %s)\n' \
      "$description" "$status" "$output" >&2
    fail=1
  fi
}

# Parent session: only the public orchestration agent types may be spawned.
check_allow \
  'parent allows scout Agent spawn' \
  '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"subagent_type":"scout"}}'
check_allow \
  'parent allows security-reviewer Agent spawn' \
  '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"subagent_type":"security-reviewer"}}'
check_allow \
  'parent allows web-performance-auditor Agent spawn' \
  '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"subagent_type":"web-performance-auditor"}}'
check_allow \
  'parent allows comment-sicko Agent spawn (no-comments starts it)' \
  '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"subagent_type":"comment-sicko"}}'
check_deny \
  'parent denies councillor Agent spawn' \
  '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"subagent_type":"councillor"}}'
check_deny \
  'parent denies unknown Agent spawn' \
  '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"subagent_type":"unknown-agent"}}'

# Council may dispatch only its internal councillor participants.
check_allow \
  'council allows councillor Agent spawn' \
  '{"hook_event_name":"PreToolUse","agent_id":"council-1","agent_type":"council","tool_name":"Agent","tool_input":{"subagent_type":"councillor"}}'
check_deny \
  'council denies non-councillor Agent spawn' \
  '{"hook_event_name":"PreToolUse","agent_id":"council-1","agent_type":"council","tool_name":"Agent","tool_input":{"subagent_type":"scout"}}'

# Plan may dispatch only research agents.
check_allow \
  'Plan allows scout Agent spawn' \
  '{"hook_event_name":"PreToolUse","agent_id":"plan-1","agent_type":"Plan","tool_name":"Agent","tool_input":{"subagent_type":"scout"}}'
check_allow \
  'Plan allows librarian Agent spawn' \
  '{"hook_event_name":"PreToolUse","agent_id":"plan-1","agent_type":"Plan","tool_name":"Agent","tool_input":{"subagent_type":"librarian"}}'
check_deny \
  'Plan denies other Agent spawn' \
  '{"hook_event_name":"PreToolUse","agent_id":"plan-1","agent_type":"Plan","tool_name":"Agent","tool_input":{"subagent_type":"sonic"}}'

# Hook must not override tool restrictions configured for unrelated nested agents.
check_no_decision \
  'unrelated nested agent receives no hook decision' \
  '{"hook_event_name":"PreToolUse","agent_id":"reviewer-1","agent_type":"reviewer","tool_name":"Agent","tool_input":{"subagent_type":"councillor"}}'

# Missing or malformed subagent_type must fail closed.
check_deny \
  'missing subagent_type is denied' \
  '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{}}'
check_deny \
  'malformed hook JSON is denied' \
  '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"subagent_type":"scout"}'

if (( fail != 0 )); then
  echo 'agent-spawn-policy-test FAILED' >&2
  exit 1
fi

echo 'agent-spawn-policy-test PASSED'
