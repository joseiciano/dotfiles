# Knowledge Base

The user keeps a personal knowledge base per repo outside the repo. In a git repo, before starting work, run `bash ~/.claude/skills/knowledge-base/scripts/kb-path.sh`. If `INDEX.md` or `RULES.md` exists in that directory, read them and follow `RULES.md` as the user's rules for this repo. If neither exists, continue without them.

- `INDEX.md` maps where documentation lives. Check it before searching for docs.
- Write ADRs to `<kb>/adr/` and glossary terms to `<kb>/GLOSSARY.md`, not to the repo, unless the user asks for the repo copy.
- When you learn where something is documented, add it to `INDEX.md` (see the [knowledge-base skill](~/.claude/skills/knowledge-base/SKILL.md)).
