---
description: Break work into small verifiable tasks with acceptance criteria and dependency ordering
---

Invoke the planning-and-task-breakdown skill.

Find the current branch's work item with the knowledge-base skill ("Work items"). Read its spec (`SPEC.md`, or a team-owned one committed to the repo) and the relevant codebase sections. Then:

1. Enter plan mode — read only, no code changes
2. Identify the dependency graph between components
3. Slice work vertically (one complete path per task, not horizontal layers)
4. Write tasks with acceptance criteria and verification steps
5. Add checkpoints between phases
6. Present the plan for human review

Save the plan to the work item's `plan.md` (keep its `branches:` frontmatter) and the task list to its `todo.md`. Both live in the KB, outside the repo; never commit them.

If that `plan.md` or `todo.md` already has unchecked tasks for different work, stop and ask before writing — never silently overwrite an incomplete plan. Different work usually belongs in its own work item.
