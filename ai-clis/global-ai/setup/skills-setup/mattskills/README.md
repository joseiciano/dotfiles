# mattskills (imported)

Imported once from [mattpocock/skills](https://github.com/mattpocock/skills)
(`mattpocock-skills` v1.3.1), using the vendored copy in `ai-clis/vendor/mattskills`.
These copies are ours to edit; the build does not re-read the vendor copy. To pick up
upstream changes, update the vendor copy and diff it against these files.

## Imported
- Skills (9): `codebase-design`, `improve-codebase-architecture`, `domain-modeling`, `handoff`, `retro`, `prototype`, `wizard`, `writing-for-agents`, `to-questionnaire`

Not imported: skills our suite already covers (tdd, diagnosing-bugs, grilling, grill-me,
grill-with-docs, code-review, implement, implement-spec, pr, research, wait-what, teach),
the issue-tracker skills (to-tickets, to-spec, wayfinder, triage) and their setup skill
(setup-matt-pocock-skills), ask-matt, course- or stack-specific skills, and in-progress ones.

## Changes from upstream
- Each skill's `agents/` folder (Codex-only `openai.yaml` metadata) is left out.
- `improve-codebase-architecture` hands the chosen candidate to our `interview-me` skill
  instead of upstream's `grilling`.
