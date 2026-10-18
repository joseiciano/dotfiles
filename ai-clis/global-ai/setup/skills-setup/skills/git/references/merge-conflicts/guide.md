# Merge Conflicts

Use when a branch has an in-progress merge or rebase with conflicts, and it needs a reliable path to a buildable state.

Do not just pick ours or theirs. Choose the holistically best result: understand why each side changed, and make our changes work on the latest version of the code, even if that means rewriting our logic. If the right resolution is unclear from the sources, ask before changing.

## Workflow

1. **See the current state.** Check the merge or rebase in progress, its history, and every conflicting file (git status and conflict markers).
2. **Find the primary sources for each conflict.** Understand why each change was made and what it intended: read the commit messages, PRs, and original issues or tickets.
3. **Resolve each hunk.** Preserve both intents where possible. Where they are incompatible, pick the one matching the merge's stated goal and note the trade-off. Do not invent new behavior. Prefer minimal, correctness-first edits that compile and keep public behavior stable.
4. **Regenerate lockfiles** with the package manager instead of hand-editing them.
5. **Run the project's automated checks:** typecheck, lint, tests, then format. Fix anything the merge broke.
6. **Finish the merge or rebase.** Stage everything and commit. If rebasing, continue until every commit is rebased. Always resolve; never `--abort`.

## Guardrails

- Keep changes minimal and readable; avoid broad refactors while resolving conflicts.
- Do not leave conflict markers in any file.
- Do not push or tag during conflict resolution.

## Output

- Files resolved
- Notable resolution choices and trade-offs
- Build and test outcome
