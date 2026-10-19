---
name: git
description: "Git workflow: commits and pull requests in the required format, cleaning up a PR for review, resolving merge or rebase conflicts, branching, splitting messy uncommitted work into atomic commits, pushing, releases, semantic version bumps, tags, and changelogs. Load whenever a commit or pull request is created. Use for \"make this easy to review\", \"tidy this PR\", \"clean up commits\", \"annotate the diff\", or when a merge or rebase has conflicts."
references: 
  - commit-pull-request
  - make-pr-easy-to-review
  - merge-conflicts
  - git-workflow-and-versioning
---

# Git

Pick the route that matches the task. Several can apply: a conflicted rebase that ends in a PR uses `merge-conflicts` and then `commit-pull-request`.

| Route | Kind | Use when |
| --- | --- | --- |
| [commit-pull-request](references/commit-pull-request/guide.md) | standard | Creating any commit or pull request: title and body format, PR template, and the pre-PR checklist |
| [make-pr-easy-to-review](references/make-pr-easy-to-review/guide.md) | procedure: follow it step by step | Cleaning noisy history, improving a PR description, or adding reviewer guidance without changing behavior |
| [merge-conflicts](references/merge-conflicts/guide.md) | procedure: follow it step by step | A merge or rebase is in progress with conflicts |
| [git-workflow-and-versioning](references/git-workflow-and-versioning/guide.md) | standard | Branching strategy, splitting work into atomic commits, parallel work streams, releases, version bumps, tags, and changelogs |

## Shared rules

- `commit-pull-request` is the source of truth for commit messages and PR descriptions. Where `git-workflow-and-versioning` suggests a different format, follow `commit-pull-request`.
