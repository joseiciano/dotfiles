---
name: format-text
description: Format given text into a named target format. Use for "format this skill", "format this text", "format this doc", "format this AGENTS.md" on rough drafts or transcribed text.
argument-hint: "<target format> [file path]"
---

# Format Text

Request: `$ARGUMENTS`

The source is a rough draft or a transcription: the content is right, the shape is not. Reshape it; the author's meaning stays fixed.

## Steps

1. Identify the **target format** and the **source** (a file path, or text in the conversation). Done when both are named. If the target is missing, ask for it.
2. Load the standard for the target:
   - Skill, `AGENTS.md`, `CLAUDE.md`: the `writing-for-agents` skill (and its `SKILL-MECHANICS.md` for a skill).
   - Doc, RFC, README, PR description: the `technical-writing` skill.
   - Any other target: the `unslop` skill, plus the structure the user described.
3. Inventory the source. List every distinct claim, instruction, and decision in it. Done when no sentence is unaccounted for.
4. Rewrite into the target format. For transcriptions, drop filler and false starts, merge repeats into one statement, and correct words the transcriber misheard, judging from context. Done when every inventory item is present, merged, or dropped as filler.
5. Deliver. Edit a source file in place, or return pasted text in the reply. Close with the open questions: passages whose meaning was unclear, listed with the reading you chose, so the author can overrule it.
