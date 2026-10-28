---
name: to-ticket
argument-hint: '[spec path, issue, or description]'
description: Break a spec into tickets, the lowest unit of work. Hierarchy is 'spec -> tickets (here now)'. Each ticket is a tracer-bullet vertical slice sized for one session, carrying its requirements, blocking edges, design decisions, task list, and verification, so an agent can build it from the file alone.
---

# To-Ticket

Break a spec, issue, or conversation into **tickets**: tracer-bullet vertical slices, each declaring the tickets that **block** it. The ticket is the lowest unit of work. There is no separate implementation plan: the ticket carries its own decisions, task list, and verification.

Every ticket is small enough to implement, test, and verify in a single focused session.

## Process

### Step 1: Gather context

Read the source: the current conversation, plus the spec path, issue number, or ticket URL given. With none given, use the work item's spec in the knowledge base (`<work>/SPEC.md`; find `<work>` with the knowledge-base skill's `kb-work.sh`).

From it:
- Extract every requirement and constraint and give each a stable ID (`REQ-001`, `CON-001`). Reuse the spec's IDs when it has them.
- Map dependencies between components.
- Note risks and unknowns.

### Step 2: Explore the codebase

Explore the code each requirement touches, if you have not already. Use the project's domain vocabulary and respect ADRs in the area.

Note existing patterns, the test and build commands, and where each test seam sits. Prefer existing seams, at the highest point possible.

Look for prefactoring that makes the work easier: "make the change easy, then make the easy change." Prefactoring becomes its own first ticket.

Write no code in this skill. The output is ticket files.

### Step 3: Draft vertical slices

Each slice cuts a narrow but complete path through every layer (schema, API, UI, tests), is demoable or verifiable on its own, and fits one fresh context window.

**Horizontal (wrong):**
```
1: Build entire database schema
2: Build all API endpoints
3: Build all UI components
```

**Vertical (right):**
```
1: User can create an account (schema + API + UI for registration)
2: User can log in (auth schema + API + UI for login)
3: User can view task list (query + API + UI for list view)
```

**Wide refactors** are the exception. A wide refactor is one mechanical change (rename a column, retype a shared symbol) whose blast radius breaks call sites across the codebase at once, so no vertical slice lands green. Sequence it as **expand–contract**:

1. **Expand:** add the new form beside the old so nothing breaks.
2. **Migrate:** move call sites in batches sized by blast radius (per package, per directory), one ticket per batch, each blocked by the expand.
3. **Contract:** delete the old form in a ticket blocked by every migrate batch.

When batches cannot stay green alone, keep the sequence but put them on a shared integration branch, all blocking a final integrate-and-verify ticket.

### Step 4: Size each slice

| Size | Files | Scope | Example |
|------|-------|-------|---------|
| **XS** | 1 | Single function or config change | Add a validation rule |
| **S** | 1-2 | One component or endpoint | Add a new API endpoint |
| **M** | 3-5 | One feature slice | User registration flow |
| **L** | 5-8 | Too large, split it | Search with filtering and pagination |

Split a slice when any of these hold:
- It needs more than one focused session (roughly 2+ hours of agent work).
- Its acceptance criteria need more than three bullets.
- It touches two or more independent subsystems (e.g. auth and billing).
- Its title needs an "and".

### Step 5: Order by blocking edges

Give each ticket its **blocking edges**: the tickets that must complete before it starts. A ticket with no blockers starts immediately. Build foundations first, following the dependency graph bottom-up.

Among tickets free to go in either order, put the riskiest first, so a wrong assumption surfaces before the work built on it. Number tickets from `01` in this order.

Tickets safe to run in parallel: independent slices, tests for finished features, docs. Tickets that must serialize: migrations, shared state changes, dependency chains. Tickets sharing an API contract need the contract defined in an earlier ticket first.

### Step 6: Check coverage

Map every requirement ID to the tickets that implement it. A requirement with no ticket is either a missing ticket or out of scope: add the ticket, or list the requirement as uncovered.

### Step 7: Review the breakdown

Present the breakdown as a numbered list. For each ticket:

- **Title**
- **Implements:** requirement IDs
- **Blocked by:** ticket numbers, or none
- **Delivers:** the end-to-end behaviour it makes work

Then list uncovered requirements.

Pick the reviewer by how this skill was reached:

- **Manual** (the user invoked this skill directly, or asked to review the tickets): present the breakdown and stop your turn. Ask whether the granularity is right, whether the blocking edges are real, which tickets to merge or split, and whether uncovered requirements get tickets. Revise until the user approves.
- **Automated** (reached from another skill or workflow): spawn a fresh `Plan` subagent with [references/reviewer-prompt.md](references/reviewer-prompt.md), passing the breakdown and the spec. Revise until it replies `APPROVED`.

### Step 8: Write the tickets

Fill [references/template.md](references/template.md) for each approved ticket. Every ticket gets:
- Acceptance criteria that are specific and testable, three at most.
- A task list where every task names its verify step, with a checkpoint after every 2-3 tasks.
- A Verify section with the real test and build commands from Step 2.
- A Principles section naming each `principle-*` skill whose trigger the ticket matches (UI, API contract, untrusted input or auth, logging, performance budget). Leave out `principle-incremental-implementation` and `principle-test-driven-development`; every ticket gets those.

Leave out exact code. File paths go only in **Files Likely Touched**. Exception: when a prototype produced a snippet that encodes a decision more precisely than prose (state machine, reducer, schema, type shape), inline its decision-rich part under Architecture Decisions and note that it came from a prototype.

### Step 9: Publish

- **Local files (default):** one file per ticket at `<work>/tickets/ticket-<NN>-<slug>.md`. `build-from-spec` builds them in `<NN>` order and skips any whose frontmatter `status` is `Completed`.
- **Issue tracker:** only when the project's agent rules (`CLAUDE.md`, `AGENTS.md`, `<kb>/RULES.md`) or the user designate one. Publish one issue per ticket using the template's tracker variant, blockers first, so each ticket's blocking edges reference real identifiers. When the source was an existing issue, make each ticket its sub-issue.

**Open tickets are sacred.** Before writing, check `<work>/tickets/` (or the tracker) for tickets whose status is not `Completed`:

- Same breakdown being revised or extended at the user's request → update those tickets in place.
- A different breakdown → stop and ask. Those tickets may be mid-build in another session. Leave them exactly as they are until the user decides.

## Picking up a ticket

A ticket's Architecture Decisions and Task List were written before earlier tickets landed. When starting one, re-read the code it touches and update those two sections in place before building. Keep the acceptance criteria fixed. If they no longer hold, raise it with the user.

## Verification

Before publishing, confirm:

- [ ] Every requirement ID maps to a ticket or is listed as uncovered.
- [ ] Every ticket is XS, S, or M, with three or fewer acceptance criteria.
- [ ] Every task has a verify step, and checkpoints sit every 2-3 tasks.
- [ ] Blocking edges form a graph with no cycles, and numbering follows it.
- [ ] Each ticket's Verify section names real commands.
- [ ] No open ticket from a different breakdown was changed.
- [ ] The reviewer (user or subagent) approved the breakdown.
