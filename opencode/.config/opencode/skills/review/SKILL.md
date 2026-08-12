---
name: review
description: Run a comprehensive AI code review against current git changes using the ai-review CLI. Detects issues with code quality, thoroughness, security, performance, and documentation.
---

## Overview

Run the external `ai-review` CLI against the current git changes. The CLI handles diff gathering, file classification, risk tiering, and subagent orchestration. Do not re-implement any of that logic in-session. Do not edit the checkout.

## Requirements

- Must run inside a git checkout.
- The CLI bundle lives at `/Users/joseiciano/documents/workspace/ai-reviewer/packages/cli/dist/ai-review.js`. If it is absent, build it first from the CLI repo (`/Users/joseiciano/documents/workspace/ai-reviewer`) with:

  ```bash
  make generate
  ```

- Invoke the CLI by its absolute path, so no PATH linking is required:

  ```bash
  node /Users/joseiciano/documents/workspace/ai-reviewer/packages/cli/dist/ai-review.js
  ```

## Input Arguments

- **Optional input** (a description, ticket reference, or other context about the changes): pass it through to the CLI as review instructions.
- **Optional target branch**: if the user specifies a target branch to diff against, pass it with `--target <branch>`. Otherwise let the CLI auto-detect.

## Steps

1. Verify the CLI bundle exists; if not, run `make generate` in `/Users/joseiciano/documents/workspace/ai-reviewer` and confirm `packages/cli/dist/ai-review.js` was produced.

2. Build the command. Pass the optional context through the `AI_REVIEW_INSTRUCTIONS` environment variable to avoid shell quoting bugs. If the input is long or contains quotes/backticks, write it to a temp file and pass via env substitution:

   ```bash
   TMP_FILE="$(mktemp)" && printf '%s\n' "<context>" > "$TMP_FILE" && AI_REVIEW_INSTRUCTIONS="$(cat "$TMP_FILE")" node /Users/joseiciano/documents/workspace/ai-reviewer/packages/cli/dist/ai-review.js && rm -f "$TMP_FILE"
   ```

   If no context was provided, omit `AI_REVIEW_INSTRUCTIONS` entirely.

   Include `--target <branch>` only when the user explicitly gave a target branch.

3. Run the CLI. Standard output is the review result. Report the result to the user; do not duplicate or re-run the review in chat.

4. Only if the user asks to save the review to a file, use the CLI's output option (e.g. `--output <path>`) to write it. Do not save or redirect output otherwise.

## Notes

- The CLI writes no prompt files on its own; the temp file above is only for safely passing instructions.
- If the CLI exits with an error, report the error output to the user and suggest checking the CLI repo for build issues.
