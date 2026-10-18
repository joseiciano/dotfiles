---
description: Sync skills from ~/.agents/skills into local opencode skills.
agent: orchestration
---

Sync skills from `~/.agents/skills` into `~/dotfiles/opencode/.config/opencode/skills/`.

## Workflow

1. Use @explorer to enumerate every skill directory under `~/.agents/skills`.
2. For each source skill:
   - If it does not exist in `~/dotfiles/opencode/.config/opencode/skills/`, add the full skill directory there immediately.
   - If it already exists, compare the source and target versions across all files in the skill directory.
3. Build a summary for every skill that differs. Use this format:

```md
- <Skill>: <list of differences>
```

Differences should be concrete and file-level when possible, for example:
- `SKILL.md changed`
- `references/api.md missing in target`
- `metadata.json differs`
- `target has extra file rules/old-rule.md`

4. After showing the summary list, ask the user what to do for each differing skill: `update`, `merge`, or `ignore`.
   - If the user chooses `ignore`, stop for that skill and make no changes to it.
   - If the user chooses `update`, overwrite the target skill in `~/dotfiles/opencode/.config/opencode/skills/` with the source version from `~/.agents/skills`.
   - If the user chooses `merge`, merge the source and target differences into a single final version, preserving relevant content from both, then write that merged result into `~/dotfiles/opencode/.config/opencode/skills/`.
5. Check [`skills-guide`](../references/skills-guide.md) to make sure that it is accurately mentioned in the respective table. 
  - Make sure if it goes in it's respective table. Do not put a backend skill in the frontend table, for example. 
  - If you are not sure where something is to go, prompt the user for clarification. 

## Agents

- Use @explorer for discovery and comparison.
- Use @fixer for any file copying or merge implementation after the user decides.
- Use @oracle only if merge decisions are ambiguous and need a judgment call.

## Output

First report:

```md
Added:
- <skill>

Differences:
- <Skill>: <list of differences>
```

Then ask the user for the next action on each differing skill.
