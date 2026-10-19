---
name: ai-review
description: "Code review of git changes: staged or unstaged changes, a commit, a branch comparison, a pull request, or a pasted diff. Combines the open-code-review (`ocr` CLI) delegation workflow with a five-axis review (correctness, readability, architecture, security, performance). Use when asked to review code or a pull request, before merging any change, or to assess code quality. Pass `ocr`, `quality`, or `both` (default) to choose the mode. Produces file:line findings and can apply fixes when requested."
compatibility: "The `ocr` and `both` modes need the `ocr` CLI (`npm install -g @alibaba-group/open-code-review` or a GitHub release binary); it needs no LLM endpoint. The `quality` mode needs no tools."
references: 
  - ocr-delegation
  - code-review-and-quality
---

# AI Review

Arguments: `$ARGUMENTS`

Pick the mode from the first word of the arguments. If there are no arguments, or the first word is not a mode, use `both`.

| Mode | Use when | Follow |
| --- | --- | --- |
| `both` (default) | A normal review of changes in a git repository | [references/ocr-delegation/guide.md](references/ocr-delegation/guide.md), reviewing each file against the five axes in [references/code-review-and-quality/guide.md](references/code-review-and-quality/guide.md) |
| `ocr` | You want only the OCR workflow: its file selection, rules, and report | [references/ocr-delegation/guide.md](references/ocr-delegation/guide.md) as written |
| `quality` | No `ocr` CLI, a pasted diff, or a review without OCR rules | [references/code-review-and-quality/guide.md](references/code-review-and-quality/guide.md) as written |

Each route is a procedure: follow its workflow step by step.

## Both mode

1. Run the OCR workflow in `references/ocr-delegation/guide.md` for file selection, rules, and diffs.
2. In its "Review Each File" step, check every file against the OCR rules **and** the five axes in `references/code-review-and-quality/guide.md` (correctness, readability, architecture, security, performance).
3. Report with the OCR workflow's output format and priorities.

## When `ocr` is unavailable

If `command -v ocr` fails, say so once and run the `quality` mode instead. Do not install tools without asking.
