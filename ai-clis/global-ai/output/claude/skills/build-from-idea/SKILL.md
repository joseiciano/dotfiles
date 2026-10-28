---
name: build-from-idea
argument-hint: '[idea] [manual]'
description: Build an idea end to end by writing its spec, breaking the spec into tickets, then implementing them. Hierarchy is 'idea (here now) -> spec -> tickets -> built changes'. Use when given a feature idea or request with no spec yet, such as "add a route for X".
---

# Build From Idea

Take one **idea** to built changes. This skill owns the chain and delegates each unit of work:

- `grill` owns intent.
- `to-capability-map` and `to-spec` own specification.
- `build-from-spec` owns ticketing and implementation.

## Mode

- **Automatic (default):** agents review the spec, map, tickets, and code. The run never waits on the user except when a reviewer loop fails to converge.
- **`manual`** (in the arguments): the user pins the intent, reviews the spec or map, and gates the build. Pass `manual` to every skill this one runs.

A run spans several turns: an interview, the build gate, a merge-request question. The knowledge base holds the run's state. Every step writes an artifact to `<work>`, and Step 1 resumes at the first step whose artifact is missing.

## Process

### Step 1: Resolve the work item

Find or create `<work>` with the knowledge-base skill's `kb-work.sh`, using a slug drawn from the idea. Pick where to resume:

| `<work>` holds | Resume at |
|----------------|-----------|
| Nothing | Step 2 |
| `INTENT.md` only, or a spec or map not yet approved | Step 3 |
| An approved `SPEC.md` | Step 4 |
| An approved `MAP.md` | Step 5, at the first module whose status is not `built` or `dropped` |

`to-spec` writes the file before its review, so a file without an approval marker is still in review.

Done when you hold `<work>` and the step to resume at.

### Step 2: Pin the intent

By default, skip the interview. If you can state the outcome and its success criterion in one sentence each, write `<work>/INTENT.md` and go to Step 3. Draw them from the idea, the codebase, and the conversation. "Add a `/health` route that returns the build SHA" qualifies.

Otherwise:

- **`manual`:** run `grill`. Its rule ends the turn on the user's explicit yes. The user's next message resumes this skill at Step 3. Save the confirmed statement as `INTENT.md`.
- **Automatic:** write your best reading to `INTENT.md` and list each guess under an **Assumptions** heading. Log each guess with `show-me-your-work`.

Run `what-to-build` instead of `grill` only when the user asks to explore options. Run `prototype` only when an open design question blocks the spec, such as a state shape or a UI layout.

Done when `INTENT.md` holds an outcome, a testable success criterion, and an out-of-scope line.

### Step 3: Specify

Apply `to-spec`'s Scope Check to `INTENT.md`:

- **One capability:** run `to-spec`, passing `INTENT.md` as `SOURCE`. Save the spec as `<work>/SPEC.md`. Go to Step 4.
- **Several capabilities:** run `to-capability-map`. Save the map as `<work>/MAP.md`. Go to Step 5.

Pick the reviewer branch by mode:

- **Automatic:** take the **Automated** branch. Cap each reviewer loop at **3 rounds**. If the reply is still `CHANGES` after the third round, stop, show the user the outstanding items, and ask how to proceed.
- **`manual`:** take the **Manual** branch, so the user reviews. Its turn boundary holds; the user's next message resumes this skill at Step 3.

On approval, write `APPROVED (agent)` or `APPROVED (user)` at the top of the spec or map. Step 1 resumes on that marker.

Done when the spec or map carries an approval marker.

### Step 4: Build the spec

Run `build-from-spec` on `<work>/SPEC.md`. Pass `manual` through when it was given. At `build-from-spec`'s Step 4 gate, also show the spec path and its success criteria.

Done when `build-from-spec` reports. Go to Step 6.

### Step 5: Build the capability map

`build-from-spec` refuses a `MAP.md`, so this step runs the module loop itself. Take modules in build order. For each module:

1. **Spec it, just in time.** Run `to-spec` on the module as Step 3 describes. Save the spec at `<work>/<module-id>/SPEC.md`. Set the module's status in `MAP.md` to `specced`.
2. **Check out its base.** For the first module, use the current branch. For each later module, check out the final ticket branch of the module built just before it. `build-from-spec` stacks its first ticket on the current branch, so this checkout is how a dependent module sees its dependencies' code. Build order is topological, so one linear stack works.
3. **Build it.** Run `build-from-spec` on the module spec as Step 4 describes. Its tickets go in `<work>/<module-id>/tickets/`.
4. **Mark it.** When every ticket of the module is `Completed`, set the module's status to `built`.

A module that ends with only one ticket goes through `build-from-ticket`. In automatic mode it opens the pull request itself. In `manual` it ends the turn on its merge-request question. The next module needs that work on a branch, so if the user declines the merge request, stop and ask how to proceed.

If a module halts on a failed ticket or unresolved review items, stop the loop. Every module after it depends on code that does not exist yet.

Done when every module is `built` or `dropped`, or the loop stopped on a module that halted.

### Step 6: Report

Tell the user:

- What the idea now delivers, measured against the success criterion in `INTENT.md`.
- The paths to `INTENT.md`, `MAP.md` when one exists, and each spec.
- Each ticket: whether it was built, its branch, and its PR URL.
- Each assumption made in automatic mode.
- What remains: failed tickets, outstanding review items, uncovered requirements, and unbuilt modules.
- The `decisions.tsv` path, when one was produced.

## Verification

Before reporting, confirm:

- [ ] `INTENT.md` exists. In `manual`, any interview ended on the user's explicit yes; in automatic mode, its assumptions are logged.
- [ ] Every spec and map carries an approval marker. Agent approvals took 3 rounds or fewer.
- [ ] Every module spec was written only after the modules it depends on were built.
- [ ] Each later module was built on top of the branch of the module before it.
- [ ] `MAP.md` statuses match what was built.
- [ ] In `manual`, the user passed every `build-from-spec` gate.
