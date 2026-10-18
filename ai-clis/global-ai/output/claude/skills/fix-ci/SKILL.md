---
name: fix-ci
description: Find failing PR checks, inspect logs or external check links, and apply focused fixes
---

# Fix CI

## Trigger

Branch or PR CI is failing and needs a fast, iterative path to green checks.

## Workflow

1. Resolve the active PR and inspect why the job is failing
  - If Github: `gh pr checks --json name,bucket,state,workflow,link`.
  - If Gitlab: `glab ci get --output json` (pipeline and per-job name, status, and web_url for the current branch; add `-b <branch>` to target another branch).
2. Inspect failed jobs and extract the first actionable error. Use GitHub Actions logs when available; otherwise use the check link to identify the failing command or service.
3. Apply the smallest safe fix.
4. Push, re-check the PR check set, and repeat until green.

## Guardrails

- Fix one actionable failure at a time.
- Prefer minimal, low-risk changes before broader refactors.
- Keep the CLI check listing as the source of truth for overall PR CI state.
  - If Github: `gh pr checks`.
  - If Gitlab: `glab ci get`.

## Output

- Primary failing job and root error
- Fixes applied in iteration order
- Current CI status and next action
