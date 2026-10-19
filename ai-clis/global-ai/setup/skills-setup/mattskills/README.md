# mattskills (imported)

Imported once from [mattpocock/skills](https://github.com/mattpocock/skills)
(`mattpocock-skills` v1.3.1), using the vendored copy in `ai-clis/vendor/mattskills`.
These copies are ours to edit; the build does not re-read the vendor copy. To pick up
upstream changes, update the vendor copy and diff it against these files.

## Imported
- Skills (8): `codebase-design`, `improve-codebase-architecture`, `handoff`, `retro`, `prototype`, `wizard`, `writing-for-agents`, `to-questionnaire`

Not imported: skills our suite already covers (tdd, diagnosing-bugs, grilling, grill-me,
grill-with-docs, code-review, implement, implement-spec, pr, research, wait-what, teach),
the issue-tracker skills (to-tickets, to-spec, wayfinder, triage) and their setup skill
(setup-matt-pocock-skills), ask-matt, course- or stack-specific skills, and in-progress ones.
`domain-modeling` was imported and later dropped: its glossary was written to the
knowledge base but nothing loaded it, and `documentation-and-adrs` owns ADRs.

## Changes from upstream
- Each skill's `agents/` folder (Codex-only `openai.yaml` metadata) is left out.
- `improve-codebase-architecture` hands the chosen candidate to our `interview-me` skill
  instead of upstream's `grilling`, offers ADRs through `documentation-and-adrs`, and
  takes domain terms from the code instead of a `GLOSSARY.md`.
- `codebase-design`'s design-it-twice briefs use the code's domain terms instead of a
  `GLOSSARY.md`.
- `retro` adds a **Skills** category (new or edited skills from improvised procedures,
  repeated instructions, and misfired skills) and follows a plan or handoff back to the
  session that wrote it.
