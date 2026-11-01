---
name: create-skill
description: Create a new skill in the dotfiles skills suite from an idea, then install it.
argument-hint: '<idea> [name]'
disable-model-invocation: true
---

# Create skill

Turn the idea in `$ARGUMENTS` into a new skill in the suite at `~/dotfiles/ai-clis/global-ai/setup/skills-setup/skills/`, then install it. The suite root is `~/dotfiles/ai-clis/global-ai`; work there whatever the current directory is.

1. **Read the arguments.** The idea is the description of what the skill does. A name, if given, is a single kebab-case token, usually last (`name: foo` or `--name foo` also count). With no name, derive one: a short, lowercase, hyphenated leading word for what the skill does (`blast-radius`, `ketchup`). Done when you hold an idea and a name matching `^[a-z0-9]+(-[a-z0-9]+)*$`, at most 64 characters.
2. **Check for a collision.** The name must be unused as both a directory under `skills/` and a `name:` value in any `skills/*/SKILL.md` frontmatter (they differ for some skills). On a collision with a given name, stop and ask for another; with a derived name, pick a new one.
3. **Load the `writing-for-agents` skill** and read its `SKILL-MECHANICS.md`. Every choice below follows them.
4. **Write `skills/<name>/SKILL.md`.** Frontmatter carries `name`, `description`, and `argument-hint` when the skill takes input. Choose the invocation: user-invoked (`disable-model-invocation: true`, human-facing one-line description) unless the agent or another skill must reach it on its own, in which case write a model-facing description with one trigger per branch. Write the body from the idea: steps each ending on a completion criterion, reference co-located under headings, branch-only material disclosed into sibling files in the same folder. Read two or three existing skills first to match the suite's voice and length. Done when the file exists and every line passes the `writing-for-agents` pruning checks.
5. **Install.** Run `make -C ~/dotfiles/ai-clis/global-ai install`. Done when it exits 0 and `~/.claude/skills/<name>/SKILL.md` exists. On failure, fix the skill (unclosed frontmatter and invalid names are the usual causes) and rerun.

Report the skill's path, its name, the invocation you chose and why, and its description.
