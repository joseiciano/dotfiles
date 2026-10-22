---
name: self-improve
description: Improve the agent's environment and skill suite. Run a retrospective audit, create a skill for a topic, or apply a direct change.
argument-hint: "[retro [session] | new <topic> | <instruction>]"
disable-model-invocation: true
---

# Self-Improve

Arguments: `$ARGUMENTS`

Only run this skill when the user calls it manually. Do not trigger it on your own.

## Rules for every mode

- Call the Skill tool with `writing-for-agents` and read its `SKILL-MECHANICS.md` before you write anything. Its rules govern every skill or steering file you write.
- Skills live in `~/dotfiles/ai-clis/global-ai/setup/skills-setup/skills/`. Add new skills there and edit existing ones there.
- Before you add a skill, search the installed skills for one that already covers the topic. Extending a skill beats adding one.
- After you change any skill, run `make install-claude` from `~/dotfiles/ai-clis`.

## Choose the mode

| Arguments | Mode |
| --- | --- |
| empty, `retro`, or a session reference | Audit |
| `new <topic>` | Create |
| any other instruction | Apply |

## Audit

Run a retrospective on a coding session and suggest improvements to the agent's environment.

1. Follow `references/audit.md`. It covers which sessions to read, the improvement categories, and how to present the candidates.
2. After you present the candidates, offer to apply the ones that are skill or steering-file changes. Run Apply on the ones the user picks.

## Create

Write a new skill for the topic.

1. If the topic is empty, ask the user for it.
2. Search the skill suite for skills that already cover the topic. If extending one of them is just as good, switch to Apply and extend it.
3. Choose the invocation mode. Make the skill model-invoked only if the agent or another skill must reach it unprompted. Otherwise make it user-invoked with `disable-model-invocation: true`.
4. Write the skill.

## Apply

Close a gap in the skill suite by changing an existing skill or adding a new one.

1. Identify the gap. If the user gave a direct instruction or picked candidates from an audit, use that as the source of truth. Otherwise review the current conversation for what in the skill suite could be better.
2. Change the existing skill, or add a new one through the Create steps.
