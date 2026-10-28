---
name: build-from-spec
argument-hint: '[spec path] [manual]'
description: Build a spec end to end, creating its tickets when missing, then implementing them. Hierarchy is 'spec -> tickets -> built changes (here now)'. Use when given a spec to implement.
---

# Build From Spec

Orchestrate one **spec** through to built changes. Delegate every unit of work: `to-ticket` owns ticketing; `build-from-ticket` owns implementing each ticket. This skill owns the order and stacks each ticket's branch on the one before.

## Mode

- **Automatic (default):** agents review the tickets and the code, and the run never waits on the user.
- **`manual`** (in the arguments, or passed down by `build-from-idea`): the user reviews the tickets and gates the build. Pass `manual` to every skill this one runs.

## Process

### Step 1: Resolve the spec

- **Path given:** read it in full.
- **None given:** use the work item's spec in the knowledge base (`<work>/SPEC.md`; find `<work>` with the knowledge-base skill's `kb-work.sh`).
- **No spec exists:** stop and offer `to-spec`.
- **Pointed at a capability map (`MAP.md`):** stop and tell the user to run this skill on each module spec, in the map's build order.

Done when you hold one spec and the list of its requirement IDs (`REQ-*`, `CON-*`).

### Step 2: Check for existing tickets

Read every `<work>/tickets/ticket-*.md`, or the tracker's issues when the project's agent rules designate one. Map each requirement ID against the tickets' **Requirements & Constraints** sections.

| Finding | Action |
|---------|--------|
| Every requirement ID is covered | Go to Step 4. |
| Some IDs covered by this spec's breakdown, others missing | Step 3, extending those tickets in place. |
| No tickets | Step 3, creating them. |
| Tickets from a different breakdown, or ones you cannot map to this spec | Stop and ask; `to-ticket`'s "Open tickets are sacred" rule governs. |

Done when every requirement ID is marked covered or missing.

### Step 3: Create tickets

Run `to-ticket` on the spec and pick its Step 7 reviewer branch by mode:

- **Automatic:** take the **Automated** branch. Cap the reviewer loop at **3 rounds**. Still `CHANGES` after the third: stop, show the user the outstanding items, and ask how to proceed.
- **`manual`:** take the **Manual** branch, so the user reviews the breakdown.

Done when `to-ticket`'s Verification checklist passes and the tickets are published.

### Step 4: Gate the build

Show the user:

- The numbered tickets: title, scope, blocked by, and whether each was reused or created.
- Requirement coverage, including any requirement listed as uncovered.
- The reviewer rounds Step 3 took.
- The build order. In `manual`, say that the user reviews each ticket's diff before its PR, one ticket per turn.

- **Automatic:** pass the gate and log it with `show-me-your-work`.
- **`manual`:** end your turn and wait for a go-ahead.

### Step 5: Implement

Take the tickets whose status is not `Completed` in number order. Ticket numbers already follow the blocking edges, so number order is the build order. None left: report that the spec is already built, and stop.

For each ticket:

1. **Check out its base.** For the first ticket built in this spec, use the current branch. For each later one, check out the `branch:` recorded on the ticket numbered just before it. This is how a ticket sees the code of the tickets that block it.
2. **Build it.** Run `build-from-ticket` on it, passing `manual` when given. It implements, reviews, marks the ticket `Completed`, and opens a PR from a new branch targeting the base.
3. **Stop on a halt.** If `build-from-ticket` stops without a PR (its review loop did not converge, Verify kept failing, or the user declined the merge request), stop the loop and report. Every later ticket would stack on code that does not exist.

In `manual`, `build-from-ticket` ends the turn on its merge-request question. The user's next message resumes this step at the first ticket not `Completed`.

Done when every ticket is `Completed` with a PR, or the loop stopped on a ticket that halted.

### Step 6: Report

Tell the user:

- What the spec now delivers, in one or two sentences.
- Each ticket: built or not, its branch, and its PR URL.
- What remains: failed tickets, outstanding review items, uncovered requirements.
- The `decisions.tsv` path, when the run logged to one.

## Verification

Before reporting, confirm:

- [ ] Every requirement ID of the one spec maps to a ticket or is listed as uncovered.
- [ ] Existing tickets were reused or extended; tickets from a different breakdown are untouched.
- [ ] Every new or extended breakdown carries the reviewer's `APPROVED`, or the user's approval in `manual`.
- [ ] In `manual`, the user passed the Step 4 gate.
- [ ] Every ticket is `Completed`, or the report names why not.
- [ ] Each ticket after the first was built on the branch of the ticket before it.
