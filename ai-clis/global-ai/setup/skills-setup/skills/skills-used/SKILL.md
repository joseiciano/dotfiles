---
name: skills-used
description: Report which skills were triggered in a Claude Code or oh-my-pi conversation by reading its session transcript. Use for /skills-used, "what skills did you use", "which skills fired this session", or to count skill usage across recent sessions.
---

# Skills Used

Reads session transcripts and lists every skill invoked, how it was triggered, and how often.

## Run

```bash
python3 -I ~/.claude/skills/skills-used/scripts/skills-used.py [--session <id>] [--all] [--days N] [--project <dir>] [--harness claude|omp]
```

- No flags: the most recently modified session of the current project (this conversation).
- `--session <id>`: one specific session (id or unique prefix).
- `--all`: every session of the current project. Add `--days N` to limit to the last N days.
- `--project=<dir>`: a different project directory name (use `=`, names start with `-`).
- `--harness claude|omp`: `claude` reads `~/.claude/projects/`, `omp` reads `~/.omp/agent/sessions/`. Without it the script picks the harness with the newest transcript for this project, which is the live session. The first output line names the harness used; pass the flag if it is wrong, for example when both tools are active in one repo.

Output is one row per skill: count, trigger (`model` for a skill the agent loaded, `user` for a typed slash command), first-seen time. Summarize it for the user; don't paste raw output unless asked.

## Limits

- Only a short list of built-in commands (`/clear`, `/help`, ...) is skipped, so other built-ins like `/plugin` can show up as `user` rows.
- oh-my-pi has no `Skill` tool: a skill counts when the transcript shows a `read` of `skill://<name>`. Reads of `skill://<name>/<subpath>` are ignored, and typed slash commands are not detected there.
- A SKILL.md read directly with `cat` is not counted; only the loads above are.
- The transcript shows that a skill ran, not why it was chosen.
