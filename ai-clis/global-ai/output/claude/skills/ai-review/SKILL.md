---
name: ai-review
description: "Code review of git changes: staged or unstaged changes, a commit, a branch comparison, a pull request, or a pasted diff. Runs the open-code-review (`ocr` CLI) delegation workflow: OCR picks the files and supplies per-file rules, the agent reviews. Use when asked to review code or a pull request, before merging any change, or to assess code quality. Produces file:line findings and can apply fixes when requested."
compatibility: "Needs the `ocr` CLI (`npm install -g @alibaba-group/open-code-review` or a GitHub release binary) for file selection and rules; it needs no LLM endpoint. Without it, the review runs on the raw diff."
references: 
  - ocr-delegation
---

# AI Review

Arguments: `$ARGUMENTS`

Follow [references/ocr-delegation/guide.md](references/ocr-delegation/guide.md) step by step. It is the whole procedure: file selection, per-file rules, diffs, review, report, fix, and re-review.

## Without `ocr`

If `command -v ocr` fails, or the input is a pasted diff rather than a git repository, say so once and run the same workflow with these substitutions. Do not install tools without asking.

- **Step 1:** build the file list from `git diff --stat` for the requested range, or from the pasted diff's file headers.
- **Step 2:** skip it. Review each file against the rule areas in Step 4 of the guide.
- **Steps 3–8:** unchanged.
