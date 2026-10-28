---
name: principle-constraint-driven-development
description: Constraints — a project's quality bar written down in CONSTRAINTS.md with numbers and commands, and guarded against agents lowering it. Use when setting up quality standards or gates (coverage, security, accessibility, performance), when you need a threshold and have no number, or when an agent silences checks, skips tests, or edits thresholds down to get green.
user-invocable: false
---

# Constraint-Driven Development

This skill produces `<kb>/CONSTRAINTS.md`: this project's quality bar, with numbers, each one checked by a command at a named stage. It outlives the session, and any agent on any harness reads it before writing code.

Four terms run through it:

- **Check**: one rule paired with the command that verifies it, such as "zero type errors" checked by `tsc --noEmit`. It passes or fails, and it is one row of `CONSTRAINTS.md`.
- **Floor**: the checks every project gets with no setup (no new suppressions, stubs, skipped tests, or secrets, and no weakening of the file itself).
- **Dimension**: one area of quality measured by a tool against a number, such as types, lint, secrets, coverage, security, performance, accessibility, or architecture boundaries. Types, lint and secrets are the usual `fast` checks; the user picks the rest in Q1. Each dimension gets its own checks in `CONSTRAINTS.md`.
- **Ratchet**: a measured value that may improve and may never fall.

Every check runs at one of three **stages**, chosen by cost:

| Stage | When | Budget | Typical checks |
|-------|------|--------|----------------|
| `fast` | after each edit, changed files only | a few seconds | types, lint, secrets, the floor |
| `task` | when the agent believes the task is done | under 90s | related tests, coverage of changed lines |
| `full` | review and CI | minutes | security scans, accessibility, performance, ratchets |

**When NOT to use:**

- `CONSTRAINTS.md` already exists and the user isn't changing it: read it and follow it.
- One-off scripts, spikes, throwaway prototypes.
- The user wants a code review now (`ai-review`) or a CI pipeline built (`principle-ci-cd-and-automation`).

**Non-interactive runs** (CI, `/loop`, autonomous work) have no user to interview. With no `CONSTRAINTS.md`, enforce the floor, say that you did, and flag the rest for a human.

## Step 1: Detect

Read the stack, test runner, linters, existing coverage output, CI config, and agent harness from the repo before asking anything.

Done when you've reported what you found in two lines.

## Step 2: Interview

Ask one question at a time and wait for each answer. Every question carries a guess and a default, so "I don't know" still produces a working config.

```
Q1: Beyond the floor, which of these dimensions do you want enforced?
    (a) Test coverage on new code
    (b) Security scanning
    (c) Performance budgets
    (d) Accessibility
    (e) Architecture boundaries
GUESS: (a) and (b) — you have a test runner already and you're handling user input.
DEFAULT if unsure: (a) and (b).
Say what each pick costs: (c) and (d) need a running URL, (e) needs a rules file written.
```

```
Q2: When a check fails while the agent is mid-task, should it block or warn?
GUESS: Block. You're running agents unattended and a warning nobody reads is a warning.
DEFAULT if unsure: Block on the floor, warn on everything else for the first two weeks.
```

```
Q3: Do you have target numbers in mind, or should I measure where you are today and hold that line?
GUESS: Measure. Most teams don't have a number, and an invented one gets ignored.
DEFAULT if unsure: Measure and hold (a ratchet, Step 7).
```

```
Q4: What's the slowest check you'll tolerate before the agent hands work back?
GUESS: About 90 seconds. Longer and you'll stop running it.
DEFAULT if unsure: 90 seconds at the task stage, unlimited at full.
```

Stop after 4 question. A longer process does not necessarily mean a better one - it will be harder for the user to understand. 

## Step 3: Write CONSTRAINTS.md

Write it to the knowledge base (refer to `knowledge-base` skill) under `<kb>/CONSTRAINTS.md`, following [references/constraints-template.md](references/constraints-template.md). Then add this line to `<kb>/RULES.md`:

`Read <kb>/CONSTRAINTS.md before writing code. Do not weaken it to make a change pass.`

Done when every enforced row has a rule, a command, a stage, and a stated reason for its number.

## Step 4: Install a tool per dimension

Every dimension the user picked gets its de facto tool, installed and run once. [references/tools.md](references/tools.md) lists the tool, install, run command and gate for each, plus the gotchas (gitleaks `--redact`, URL-only checks, diff scoping). The agent runs the commands from `CONSTRAINTS.md`; add repo scripts or CI steps only when the user asks.

Done when every picked dimension has a command that runs today. A dimension that can't run here (accessibility on a CLI, say) gets dropped and noted.

## Step 5: Place each check by cost

Put each check at the cheapest stage it fits. A check that stalls the agent gets switched off, and a switched-off check is worse than none, because the bar still looks like it exists.

- **Scope to the diff.** Check the lines this change touched. Coverage of changed lines is a number the agent can move; project coverage is one it inherited, so that one becomes a ratchet.
- **Anything over a few seconds moves out of `fast`.**

Done when every row's stage fits that stage's budget.

## Step 6: Guard the bar

Under a red check, agents take the cheapest road to green. At the `full` stage, look for these five loosening moves:

1. **The threshold moved.** A budget lowered, a severity dropped, a check moved out of `fast`. `CONSTRAINTS.md` lives outside the repo, so compare it against its last reviewed state: `git -C <kb> diff -- <path>` when the KB is a git repo, otherwise any edit since `Last reviewed` needs the user's sign-off.
2. **A test got easier.** `.skip` added, a test file deleted, assertions pulled from a test that stayed.
3. **A checker got silenced.** A new `@ts-ignore` or `eslint-disable`. Watch hardest for `istanbul ignore`, `Stryker disable`, `nosemgrep` and `gitleaks:allow`, which each switch off a check the bar relies on.
4. **Work is unfinished.** A stub that throws, an empty `catch`, a `TODO` where the implementation should be.
5. **An exception appeared.** A new Exceptions row nobody discussed.

Tightening is silent; loosening is loud. When a check fails, fix the code or route it through an Exceptions row with an owner and an expiry. Keep the threshold where it is.

Moves 2–4 show up in the repo diff. Enforce them with [references/floor-guard.md](references/floor-guard.md), adapted rather than rewritten, so every run and stack uses the same guard. Moves 1 and 5 live in the KB file and come from the KB diff above.

**Rank checks by circularity**: can the agent make it pass with code that doesn't work?

- **External**: axe-core encodes WCAG, osv-scanner reads a vulnerability database, Lighthouse measures a real browser.
- **Project**: your lint rules and layer boundaries, in a file a human owns.
- **Suite**: your own tests. The most useful kind, and the only fully circular one.

The bar needs at least one external constraint.

## Step 7: Ratchets

A target the codebase fails today (80% coverage on a codebase at 62%) gives a permanently red build and a team that learns to ignore red. Record today's value in "Measured, not yet enforced" with a direction instead. Each check compares against the recorded value. When the number improves, update it; when it falls, that's the finding.

## Sane defaults

Use these when the user has no opinion. Most codebases meet them on day one. Write the reason beside the number in `CONSTRAINTS.md`: a threshold without one gets deleted by the next person who hits it.

| Constraint | Default | Why this number |
|------------|---------|-----------------|
| Coverage of changed lines | ≥ 80% | High enough to force a test, low enough to allow a config line |
| Project coverage | today's value, must not fall | No argument needed to adopt |
| Mutation score (if used) | ≥ 60% to start | Typical for a suite never mutated before; 80% is mature |
| Dependency vulnerabilities | nothing at high or above | Below that is mostly noise |
| LCP | ≤ 2500 ms | Core Web Vitals "good" threshold |
| CLS | ≤ 0.1 | Same |
| Accessibility | zero critical or serious axe violations | Moderate and minor are often debatable |
| Exception lifetime | 90 days | Long enough to plan the fix, short enough to remember |
| Ratchet tolerance | 0.5% | Absorbs drift when an unrelated file moves the number |

## Escalation path

Start at level 1. Most projects stop at 2.

1. **Written.** `CONSTRAINTS.md` exists and agents run its commands. A first run can be floor-only: add numbered dimensions as each tool is installed.
2. **Scripted.** The commands wired into the agent's post-edit hook, and into repo scripts or CI if the user asks.
3. **Tool-backed.** A dedicated runner handling diff scoping, budgets, ratchets and the guard. Move here when check-running shell passes about thirty lines; floor-guard is the starting point.

## Common rationalizations

| Excuse | Reality |
|--------|---------|
| "We'll add constraints once the code settles" | Code settles around whatever was allowed while it was moving |
| "The tests are the constraints" | Tests prove you agree with yourself; they say nothing about dependency risk, bundle growth, or coverage of new code |
| "This threshold is wrong, I'll lower it" | Fix the code, or add an exception with an owner and a date. Lowering it unblocks everyone forever |

## Verification

The skill was applied correctly when:

- [ ] `<kb>/CONSTRAINTS.md` exists, and every number in it has a stated reason
- [ ] The floor passes on the current codebase without changes
- [ ] Every picked dimension has an installed tool and a command that runs today
- [ ] Every row names its stage, and `fast` stays within a few seconds
- [ ] At least one constraint is external
- [ ] Ratchets record today's value and a direction
- [ ] Every exception has an owner and an expiry within a year
- [ ] `<kb>/RULES.md` points at the file
- [ ] A trial run on the current branch produces no failures the user disagrees with

## See also

- `ai-review`: how to review; this skill decides what the review enforces
- `principle-ci-cd-and-automation`: the pipeline these constraints run in
- `principle-security-and-hardening`: what the security dimension should contain
- `principle-performance-optimization`: where the performance numbers come from
