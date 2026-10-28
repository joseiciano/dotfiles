---
name: interrogate
description: "Interrogate code changes or a design with an adversarial, multi-model review: one reviewer per model, then a lead verdict. Use for \"interrogate\" or \"stress test this\", or as the review gate inside an automated implement workflow."
---

# Interrogate

Spawn one reviewer per model to adversarially review code changes or a design sketch. The adversarial signal comes from model diversity, not assigned personas. The deliverable is a synthesized verdict for the user or caller to act on; interrogate never applies changes itself.

Reviewers are `task` subagents. Tell each one to read and review only, leaving every file unedited.

Run interrogate from the top-level session or workflow orchestrator, since a subagent cannot spawn the reviewers. If you are a subagent, stop and report that interrogate must run from the orchestrator; that report is your whole output, with no single-model review in its place.

## Modes

- **Interactive** (default): a user is present. Ask the user when the intent is unclear. Return the verdict for the user to act on.
- **Gate**: a workflow calls interrogate as a step, for example after each task of an implement run. No user is present, so never ask a question. The caller passes the task spec, the diff, and the cycle number (1 on the first review of a change). Return the verdict plus the gate status in [Gate loop](#gate-loop).

## Step 1, Scope

Identify what to review from context:

- If the user or caller points at specific files or a diff, use that.
- If on a feature branch, run `git diff main...HEAD` (or the appropriate base branch) for the full changeset.
- If the user's message references recent work, gather the relevant files.
- If the target is a plan or design sketch (no code yet), review that document. See the premise note in Step 3.

Package the diff or file contents with any surrounding context files the reviewers need to understand the code.

## Step 2, Intent

Before spawning reviewers, state the intent in one clear paragraph from the user's message, the task spec, commit messages, the PR description if one exists, and the code.

If you're unsure about the intent: in interactive mode, ask the user before proceeding. In gate mode, take the intent from the task spec. If the spec does not settle it, return `BLOCKED: spec gap` with the open question and spawn no reviewers.

## Step 3, Spawn Reviewers

Launch all reviewers in a single message with the `Agent` tool, one per model, labeled Reviewer A, B, and so on.

| Reviewer | Model |
|----------|-------|
| Reviewer A | `opus` |
| Reviewer B | `fable` |
| Reviewer C | `sonnet` |
| Reviewer D | `haiku` |

Pass each reviewer's model as `model`. If the harness has no per-call model choice or rejects a model, run that reviewer on the default model and say in the verdict that model diversity was reduced.

Read `references/reviewer-prompt.md` and fill in the same template for every reviewer with the stated intent, the diff or file contents, the rubric from `references/rubric.md`, and the code-quality lens from `references/code-quality-review.md`.

The template tells reviewers not to question the intent, so a code review cannot catch a wrong premise. To doubt the premise, review the plan or design sketch before implementation starts: when the target is a design, fill the template's design variant, which lets reviewers challenge whether the approach meets the requirement.

## Step 4, Synthesize

As results come back, build a unified picture. Merge findings that describe the same issue differently, and note which models raised each one. Findings two or more models raised independently are the highest signal; a lone model's finding gets read and weighted accordingly. When one model flags something and another explicitly says the opposite, record the disagreement as context for the verdict.

Done when every reviewer's every finding sits in exactly one merged entry with its models listed.

## Step 5, Lead Judgment

You are the lead reviewer, a pragmatic senior engineer, not a neutral aggregator. Read `references/lead-judgment.md` for the full framework. Re-read the code or document against each finding before you classify it; a reviewer's claim is data, not a verdict. Put every finding in the first bucket that matches, with the model(s) that raised it and a one-line rationale.

1. **Spec gap**. The finding exists because the intent or spec was unclear or incomplete, not because the code is wrong. The fix lives in the intent or spec, never in the code. If the gap is only context you left out of the intent paragraph, add that context and keep it for the next cycle. If the spec itself is ambiguous in a way that changes behavior, it needs a decision: ask the user (interactive) or return `BLOCKED: spec gap` (gate).
2. **Act on**. Real issues affecting correctness, security, or maintainability given the actual goals. They would block a real PR.
3. **Consider**. Legitimate, but you're not sure they outweigh the cost of addressing them now. Worth the user's attention.
4. **Noted**. Technically valid but not actionable. Context-dependent, premature optimization, or low-impact at this stage.
5. **Dismissed**. Wrong, nitpicky, or missing context, with a brief reason. Ask whether a sentence in the intent would have prevented it; if so, add it for the next cycle.

## Gate loop

In gate mode, interrogate reviews once per call and the caller owns the loop:

1. Interrogate returns the verdict and one status line:
   - `PASS`: no Act on and no Spec gap findings.
   - `FIX`: Act on findings exist and the cycle number is below 3.
   - `BLOCKED: spec gap`: a behavior-changing Spec gap finding exists.
   - `BLOCKED: unresolved after 3 cycles`: Act on findings remain at cycle 3.
2. On `FIX`, the caller has its implementer address the Act on items only, then calls interrogate again with the new diff, the cycle number plus one, and any intent context the lead added in Step 5.
3. On either `BLOCKED`, the caller stops that task and surfaces the verdict for a human. The cap stays at 3: three unresolved cycles say the change or its spec is not ready, or that the task is too big and needs splitting.

Consider, Noted, and Dismissed findings never block the gate. The caller logs them, for example in the work item's `decisions.tsv` when `show-me-your-work` is active.

If a later cycle raises only findings that were already dismissed or noted in an earlier cycle, return `PASS` rather than looping on them. If two cycles in a row dismiss every substantive finding, say so in the verdict: either the reviewers lack context the intent should carry, or the lead is rubber-stamping.

## Output Format

### Intent
> [The stated intent paragraph from Step 2]

### Reviewers
- Reviewer [label]: [model name], [N findings] (one bullet per reviewer)

### Spec Gap
[Each: the ambiguity, which models raised it, and the decision it needs. Omit when empty.]

### Act On
[Each: description, which models raised it, why it matters.]

### Consider
[Each: description, which models raised it, the tradeoff.]

### Noted
[Brief list.]

### Dismissed
[Each with a brief rationale.]

### Agreement Map
[Where models agreed and diverged, and what that pattern tells us.]

### Gate
[Gate mode only: cycle N of 3, and the status line from [Gate loop](#gate-loop).]
