---
name: principle-doubt-driven-development
description: Subjects non-trivial decisions to a fresh-context adversarial review before they stand. Use before an architectural decision under uncertainty or a non-trivial commit, when asserting a property you can't prove (safe, idempotent, scales, matches the spec), when working in unfamiliar code, or when the stakes are high or irreversible (auth, security, migrations, deploys).
user-invocable: false
---

# Doubt-Driven Development

Catch wrong directions while course-correction is still cheap: before a non-trivial decision stands, hand it to a fresh-context reviewer biased to **disprove**, not approve.

## When to Use

A decision is **non-trivial** when at least one of these is true:

- It introduces or modifies branching logic
- It crosses a module or service boundary
- It asserts a property the type system or compiler cannot verify (thread safety, idempotence, ordering, invariants)
- Its correctness depends on context the future reader cannot see
- Its blast radius is irreversible (production deploy, data migration, public API change)

Everything else proceeds without doubt: mechanical operations (renames, formatting, file moves), clear user instructions, reading or summarizing code, one-line changes with obvious correctness, pure tooling runs, and work where the user asked for speed over verification.

## Loading Constraints

Run this skill from the **main session**: the orchestrator spawns the reviewers and reconciles their findings.

Spawn reviewers as `readonly-task` agents using the settings in [`references/reviewer-models.md`](references/reviewer-models.md), one per entry. The `reviewer` agent runs `ocr`, which this review has no use for.

## The Process

Copy this checklist when applying the skill:

```
Doubt cycle:
- [ ] Step 1: CLAIM — wrote the claim + why-it-matters
- [ ] Step 2: EXTRACT — packaged ARTIFACT + CONTRACT, stripped reasoning
- [ ] Step 3: DOUBT — invoked fresh-context reviewers with the adversarial prompt
- [ ] Step 4: RECONCILE — classified every finding against the artifact text
- [ ] Step 5: STOP — met a stop condition
```

### Step 1: CLAIM — Surface what stands

State the decision in two or three lines:

```
CLAIM: "The new caching layer is thread-safe under the
        read-heavy workload described in the spec."
WHY THIS MATTERS: a race here corrupts user data and is
                  hard to detect in QA.
```

If you can't write the claim that compactly, you have a vibe, not a decision. The CLAIM is your hypothesis; it stays with you.

### Step 2: EXTRACT — Smallest reviewable unit

Find the material to review:

- If the caller points at specific files or a diff, use that.
- If on a feature branch, run `git diff main...HEAD` (or the appropriate base branch).
- If the caller references recent work, gather the relevant files.

Package two things for the reviewer:

- **ARTIFACT**: the diff or the function (not the whole file), plus any surrounding files the reviewer needs to read it.
- **CONTRACT**: what the artifact must satisfy: the requirements, constraints, and the property under test, stated as a requirement ("must be safe under concurrent reads"), never as a conclusion ("is safe").

Strip your reasoning from both. Done when the ARTIFACT covers one decision and stays under ~200 changed lines; anything larger, decompose and run a cycle per piece.

### Step 3: DOUBT — Invoke the fresh-context reviewers

Fill [`references/reviewer-prompt-template.md`](references/reviewer-prompt-template.md) with the ARTIFACT and CONTRACT and send it to each reviewer. The prompt is adversarial on purpose: framing decides the answer.

The CLAIM stays out of the prompt: handing the reviewer your conclusion biases it toward agreement. The reviewer independently determines whether the ARTIFACT satisfies the CONTRACT.

### Step 4: RECONCILE — Fold findings back

Merge the reviewers' findings into one picture: combine findings that describe the same issue differently, mark which ones both reviewers found independently, and note where only one flagged something.

The findings are data, not a verdict, and you are still the orchestrator. A fresh reviewer lacks your context and can be wrong; disagreement is information. Re-read the artifact text against each finding, then classify it in this **precedence order** (first matching class wins):

- **Contract Drift**: the finding stems from an unclear or incomplete CONTRACT. Fix the contract, then re-classify on the next cycle.
- **Act on**: a real issue affecting correctness, security, or maintainability given the actual goals. It would block a real PR.
- **Consider**: legitimate, but unclear whether it outweighs the cost of addressing now. Surface it to the user.
- **Noted**: technically valid but not actionable: context-dependent, premature optimization, or low impact at this stage.
- **Dismissed**: wrong, nitpicky, or missing context, with a one-line reason.

Done when every finding has a class.

### Step 5: STOP — Bounded loop

Stop when:

- The next cycle returns only trivial or already-classified findings, **or**
- 3 cycles are complete: escalate to the user instead of running a fourth, **or**
- The user says "ship it"

Substantive findings after 3 cycles are information about the artifact: it may not be ready, so surface that. If 3 cycles feels too few because the artifact is large, the artifact is too big: return to Step 2 and decompose rather than lifting the bound.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'm confident, skip the doubt step" | Confidence correlates poorly with correctness on novel problems. Moments of certainty are exactly when blind spots hide. |
| "Spawning a reviewer is expensive" | Debugging a wrong commit in production is more expensive. The check is bounded; the bug isn't. |
| "The reviewer will just nitpick" | Only when the CONTRACT is vague. Scope it to what would make the artifact fail. |

## Red Flags

- Skipping doubt under time pressure on a high-stakes decision
- Re-spawning reviewers on an unchanged artifact: you'll get the same findings; you're stalling
- **Doubt theater (checkable signal)**: across 2 or more cycles with substantive findings, none classified **Act on**. You are validating, not doubting: stop and escalate.

## Interaction with Other Skills

- **`ai-review` / `/review`**: `/review` is the post-hoc gate on a finished PR; doubt-driven is in-flight, per decision, while course-correction is cheap. Use both.
- **`source-driven-development`**: verifies *facts about frameworks* against official docs. Doubt-driven verifies *your reasoning about the artifact*: SDD checks the API exists; doubt-driven checks you used it correctly under the contract.
- **`principle-test-driven-development`**: TDD's RED step is doubt made concrete. When TDD applies, the failing test *is* the doubt step for behavioral claims.
- **`principle-debugging-and-error-recovery`**: when a reviewer surfaces a real failure mode, use it to localize and fix.

## Verification

- [ ] Every non-trivial decision was named as a CLAIM before standing
- [ ] Each non-trivial artifact got at least one doubt cycle (a TDD RED test counts for behavioral claims)
- [ ] Reviewers received ARTIFACT + CONTRACT only
- [ ] Every finding carries a class from Step 4, assigned after re-reading the artifact
- [ ] A Step 5 stop condition was met
