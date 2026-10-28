---
name: what-to-build
description: interview the user on what specifically they want to build. The goal is the creation of a high level idea that can be transferred to an implementation spec. From a raw idea converge to a sharp goal. Triggers on "ideate", "refine this idea", or "stress-test my plan"
---

# What to Build

## Overview

What people ask for and what they actually want are different things. They ask for "a dashboard" because that's what one asks for, not because a dashboard solves their problem. They say "make it faster" without a number to hit.

The cheapest moment to find this gap is before any spec or code exists. Once building starts, the user rationalizes the wrong thing into a "good enough" thing and the misfit gets locked in.

This skill runs in four phases: find the real intent, open up the options, converge on one direction, then lock it as a confirmed brief that a spec can consume.

Requires a live user. In non-interactive contexts (CI, `/loop`, scheduled runs), flag the underspecified ask as a blocker instead of guessing.

## Phase 1: Find the Intent

### Hypothesize, with a confidence number

Before asking anything, write your best read of what the user wants in one sentence, plus an honest confidence number:

```
HYPOTHESIS: You want a way to answer "how are we doing?" in standup, and "dashboard" was the convention that came to mind.
CONFIDENCE: ~30% — missing: who it's for, what "metrics" means, what success looks like
```

Below ~70%, always name what's missing on the same line.

### Ask one question at a time, each with a guess

```
Q:     <one focused question>
GUESS: <your hypothesis for the answer, with the reasoning behind it>
```

Wait for the user to react before asking the next one. The third question often depends on the first; batching locks in the wrong framing. A guess is faster to correct than an answer is to generate. Guard against a polite user agreeing to be agreeable: be visibly willing to be wrong, and occasionally guess in a direction you expect them to push back on.

Cover, in whatever order the conversation allows: **who** it's for, **why now**, what **success** looks like, the binding **constraint**, and **what's been tried before**.

### Listen for "want vs. should want"

Watch for answers that sound thoughtful but say nothing:

- Best-practice talk without specifics ("scalable", "clean architecture")
- Deference to convention ("the way most apps do it")
- "I should probably…", "good engineering practice says…"

When you hear these, ask:

> *"If you didn't have to justify this to anyone, what would you actually want?"*

**Exit Phase 1** when you can state who it's for and what success looks like without guessing.

## Phase 2: Diverge

Restate the intent as a "How Might We" problem statement, then generate **5-8 variations**. Pick the lenses that fit; don't run them all mechanically:

- **Inversion:** what if we did the opposite?
- **Simplification:** what's the version that's 10x simpler?
- **Constraint removal:** what if time/budget/tech weren't factors?
- **Audience shift:** what if this were for a different user?
- **Combination:** what if we merged this with an adjacent idea?
- **10x version:** what does this look like at massive scale?
- **Expert lens:** what would a domain expert find obvious that an outsider wouldn't?

Each variation gets a one-line reason it exists. Ideas without a story are noise.

If you're inside a codebase, scan it first. Existing architecture, patterns, and prior art are both constraints and opportunities; reference specific files when they matter.

Push past what the user asked for, but every variation must still serve the intent from Phase 1. Ask which ones resonate and wait.

## Phase 3: Converge

1. **Cluster** what resonated into 2-3 directions that are meaningfully different, not variations on a theme.
2. **Stress-test** each direction:
   - **User value:** painkiller or vitamin? What does the user do today instead?
   - **Feasibility:** what's the hardest part? Is there a version that delivers value in days, not months?
   - **Differentiation:** what does this do that the current workaround doesn't?
3. **Surface hidden assumptions** for each:
   - What you're betting is true but haven't validated
   - What would kill it
   - What you're choosing to ignore, and why that's fine for now
4. **Recommend one direction** and say why.

Be honest, not supportive. If a direction is weak, say so specifically.

## Phase 4: Lock It

### Restate in the user's own words

```
Here's what I now think you want to build:

- Outcome:      <one line>
- User:         <one line — who benefits>
- Why now:      <one line — what changed>
- Success:      <one line — how we know it worked>
- Constraint:   <one line — the binding limit>
- Direction:    <one line — the chosen direction from Phase 3>
- MVP:          <one line — the minimum version that tests the core bet>
- Assumptions:  <the 1-3 bets that must hold, each with how to test it>
- Out of scope: <what we're explicitly not doing, and why>

Yes / no / refine?
```

"Out of scope" is non-negotiable. Half of misalignment is silent disagreement about what is *not* being built.

### Confirm: an explicit yes

These are **not** yes:

- "Whatever you think is best." — Delegation. Re-ask with two concrete options as a choice.
- "Sounds good." / "Sure, let's go." — Ask: "Anything you'd refine?"
- Silence, then "okay let's start." — They've given up, not converged. Ask what you missed.

On a correction, fold it in and restate. Loop until an explicit yes.

### The stop test

You're done when you can answer yes to:

> *Can I predict the user's reaction to the next three questions I would ask?*

If several rounds pass and you still can't, stop and say so: "I've asked X questions and still can't predict your reactions. Something foundational is missing. Want to step back?"

### Terminal turn

On an explicit yes: deliver the confirmed brief, offer to save it or hand it to the spec step, then **stop the turn**. Don't invoke tools or start downstream work until the user picks the next step.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The ask is clear enough" | If you can't write the desired outcome in one sentence, it isn't. |
| "Asking questions wastes their time" | A handful of targeted questions is cheap. Building the wrong thing is not. |
| "I'll batch the questions to save round-trips" | Batches get skimmed, and later questions depend on earlier answers. |
| "The first idea is obviously right, skip diverging" | Then the variations will confirm it quickly. If you skip them, you never find out. |
| "I'll generate 20 ideas to cover all bases" | 5-8 considered variations beat 20 shallow ones. |
| "The user needs encouragement, not critique" | A yes-machine produces weak ideas. |
| "We'll surface assumptions once we start building" | Untested assumptions are the #1 killer. Surface them now. |
| "They said 'whatever you think', so I'll decide" | That's delegation. Re-ask with two concrete options. |

## Red Flags

- More than one question in a message during Phase 1
- A question without your guess attached
- Accepting a buzzword ("scalable", "modern") as a goal without probing
- Diverging before you know who it's for and what success looks like
- Variations that drift away from the Phase 1 intent
- Ignoring existing codebase constraints when ideating inside a project
- A direction recommended without its assumptions named
- A restate missing "Out of scope"
- Treating "sounds good" as confirmation
- Starting a spec, plan, or code before an explicit yes

## Verification

- [ ] An initial hypothesis with a confidence number was stated, with a reason whenever it was below ~70%
- [ ] Phase 1 questions were asked one at a time, each with a guess
- [ ] A "what would you actually want?" probe ran on any convention- or buzzword-shaped answer
- [ ] 5-8 variations were generated against the confirmed intent, each with a reason
- [ ] 2-3 directions were stress-tested on value, feasibility, and differentiation
- [ ] Hidden assumptions were named for the recommended direction
- [ ] The final restate includes every field, including Out of scope
- [ ] The user gave an explicit yes
- [ ] The turn ended after confirmation without starting downstream work
