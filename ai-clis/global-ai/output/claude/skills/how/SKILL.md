---
name: how
description: "Explains how code works: runtime flow, subsystem architecture, a walkthrough before changing something. Use for \"how does X work\" and placement questions (\"where should this live\"). Use why for motivation."
---

# How

Explore the codebase to answer "how does X work?" questions. Pitch the explanation at a senior engineer onboarding onto a subsystem: a working mental model, at the altitude of architecture rather than annotated source.

Explorers are `scout` subagents. The explainer is a `task` subagent; tell it to read and explain only, leaving every file unedited.

## 1. Assess complexity

If the scope is ambiguous, state your interpretation and explore. The user can redirect.

- **Simple** (a single module, a small utility, a narrow question such as "how does function X work"): no explorers. Spawn one explainer that explores and explains in one pass, built from `references/explainer-prompt.md` without the explorer-findings section. Go to step 4.
- **Complex** (a subsystem spanning multiple files or services, a cross-cutting feature, a full architectural overview): go to step 2.

When in doubt, take the simple path.

## 2. Explore (complex only)

Decompose the question into 2 to 4 angles, each a distinct slice of the subsystem. Spawn all explorers in a single message, each with `references/explorer-prompt.md` and its angle filled in.

## 3. Synthesize (complex only)

Once every explorer has returned, spawn one explainer with `references/explainer-prompt.md` and every explorer's findings filled in.

## 4. Present

Present the explainer's output in the section structure `references/explainer-prompt.md` defines. Keep its substance as written; light edits for clarity or context from the conversation are fine.
