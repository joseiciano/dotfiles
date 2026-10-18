---
name: fix-merge-conflicts
description: Resolve merge conflicts non-interactively, validate build and tests, and finalize conflict resolution
---

# Fix merge conflicts

## Trigger

Branch has unresolved merge conflicts and needs a reliable path to a buildable state.

Do not just blindly pick ours or theirs. We want to choose the holistically best path forward. If that means we remove some changes we did or have to redo it, so be it. 

Make sure our changes are applied on the latest version of the code (even if we need to rewrite our logic after updating to this version of the code).

## Workflow

1. Detect all conflicting files from git status and conflict markers.
2. Resolve each conflict with minimal, correctness-first edits.
3. Prefer preserving both sides when safe. Otherwise, choose the variant that compiles and keeps public behavior stable.
4. Regenerate lockfiles with package manager tools instead of hand-editing.
5. Run compile, lint, and relevant tests.
6. Stage resolved files and summarize key decisions.

## Guardrails

- Keep changes minimal and readable.
- Do not leave conflict markers in any file.
- Avoid broad refactors while resolving conflicts.
- Do not push or tag during conflict resolution.

## Output

- Files resolved
- Notable resolution choices
- Build/test outcome
