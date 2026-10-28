---
description: Implement tasks incrementally — build, test, verify, commit. Add "auto" to run the whole plan in one approved pass.
---

Invoke the incremental-implementation skill alongside test-driven-development.

## Modes

- **`/build`** — implement the *next* pending task, then stop (careful, one slice at a time).
- **`/build auto`** — generate the plan if needed, get a single approval, then implement *every* task without stopping between them.

`$ARGUMENTS` selects the mode. Treat `auto` (canonical) or `all` as autonomous mode; anything else (or empty) is the default single-task mode. Note: autonomous mode is not faster *per task* — it runs the same test-driven loop — it only removes the human stepping *between* tasks.

## Default: one task

Pick the next pending task from the plan: `todo.md` in the current branch's work item (the knowledge-base skill's "Work items" section finds it). Then:

1. Read the task's acceptance criteria
2. Load relevant context (existing code, patterns, types)
3. Write a failing test for the expected behavior (RED)
4. Implement the minimum code to pass the test (GREEN)
5. Run the full test suite to check for regressions
6. Run the build to verify compilation
7. Commit with a descriptive message
8. Mark the task complete in `todo.md` and stop. `todo.md` is in the KB, outside the repo: edit it, never commit it.

## Autonomous: the whole plan (`/build auto`)

Use this once a spec exists and you want to collapse plan + build into one run. It removes the manual stepping between tasks — **not** the verification. Every task still earns a passing test and its own commit.

1. **Require a spec.** Find the current branch's work item (knowledge-base skill, "Work items") and look for its `SPEC.md`. A team-owned spec committed to the repo (`SPEC.md` at the root, `docs/SPEC.md`, or a file under `spec/`) also counts. A README or arbitrary doc does **not** count. If none exists, stop and tell the user to run `/spec` first — do not invent requirements.
2. **Establish a clean baseline.** Run `git status --porcelain`. If there are any uncommitted changes, stop and ask the user to commit, stash, or confirm how to handle them. The spec, plan and task list live in the KB, outside the repo, so they never show up here. Autonomous per-task commits must not absorb unrelated local work, or the clean-rollback guarantee breaks.
3. **Plan if needed.** If the work item has no `plan.md` with tasks, invoke planning-and-task-breakdown to generate one.
4. **Single checkpoint.** Present the full plan and wait for an unambiguous affirmative (e.g. "approve", "go", "yes"). Treat hedged responses ("looks reasonable", "I guess") as **not** approved. This is the only human gate — after approval, run autonomously. Do not commit the plan: it lives in the KB.
5. **Execute every task in dependency order.** Use each task's declared dependencies; if they aren't explicit, execute in the order the plan lists them. For each task, run the full default loop above (RED → GREEN → regression → build → commit → mark complete). Stage only the files that task touched — never `git add -A` blindly — and make one commit per task so any point is a clean rollback. The task-status update goes in the KB's `todo.md`, not the commit.

   Keep a decision trail with the show-me-your-work skill in the work item's `decisions.tsv`, writing rows as you go: a `start` row naming `/build auto`, one row per finished task (phase = task id, evidence = commit SHA, result = verification), and a row for every blocker you stop on, revert, skipped check, choice between real alternatives, and call you made where the spec was silent.
6. **Stop and ask the user** (do not push through) when:
   - a test can't be made to pass or the build breaks without an obvious fix → follow principle-debugging-and-error-recovery
   - the spec is ambiguous, or a task needs a decision the spec doesn't cover
   - a task is high-risk or irreversible — auth/permission changes, destructive data migrations, payments, deletions, deploys, anything touching secrets, **or anything you can't undo with `git revert`** → follow doubt-driven-development and get explicit sign-off before continuing

   After the user resolves a blocker, they re-invoke `/build auto` — it resumes from the next pending task.
7. **Summarize at the end:** tasks completed, tests added, commits made, and anything skipped, flagged, or left for the user. Give the `decisions.tsv` path and end with show-me-your-work's **Attention** section.

If any step fails, follow the principle-debugging-and-error-recovery skill.
