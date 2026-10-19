# Knowledge Base

The user keeps a personal knowledge base per repo outside the repo. In a git repo, before starting work, run `bash ~/.claude/skills/knowledge-base/scripts/kb-path.sh`. If `INDEX.md` or `RULES.md` exists in that directory, read them and follow `RULES.md` as the user's rules for this repo. If neither exists, continue without them.

- `INDEX.md` maps where documentation lives. Check it before searching for docs.
- ADRs, `CONSTRAINTS.md`, specs, plans and task lists go in the KB, not the repo, even when another skill names a repo path such as `docs/adr/`, `SPEC.md` or `tasks/plan.md`. The [knowledge-base skill](~/.claude/skills/knowledge-base/SKILL.md) maps each repo path to its KB path, and its "Work items" section finds the spec and plan for the current branch. Write to the repo only when the user asks for the repo copy, and never commit KB files.
- When you learn where something is documented, add it to `INDEX.md`.
