---
description: Create story tickets for others to implement, covering details created by our product documents. 
agent: engineering-manager
---

## Pre-requisites

Arguments Received: `$ARGUMENTS`

Parse the arguments into the following: 
- `MILESTONE`: (optional) specific milestone we want to create tickets for
- `TICKET`: (optional) specific ticket we want to create tickets for

### Argument Rules

Both `MILESTONE` and `TICKET` are optional variables, but one must be filled in for this command to work. 

**IF NEITHER `MILESTONE` OR `TICKET` ARE FILLED IN, STOP HERE AND PROMPT THE USER**

If `TICKET` is not provided, the assumption is that we are to create a story ticket for every thing within `MILESTONE` (i.e. we will create multiple tickets).

## Goal 

Create story tickets/fill out the details for the story tickets provided. 

## Workflow 

### Step 1: Gather Files

For the stories we are to create, spawn @explorers to search for:

- `MILESTONE-FILE`: File path if available to the description of the milestone we are working on
- `MILESTONE-INFO`: The answer to "what is the end goal of this milestone"?  The milestone that the ticket is for, figure out what is the end goal of the milestone. 
- `FUNCTIONAL-DOCS`: List of functional spec/design diagrams that relate to the ticket/milestone 
- `PRD-PATH`: Path to the PRD file to understand the end goal for the stories. 

### Step 2: Analyze Files 

Analyze the files generated from step 1 for the following questions: 

- `FILES-MODIFIED`: What areas in the codebase will we need to modify? 
- `GREENFIELD`: boolean true/false on if we are creating something from scratch or will be adding onto something pre-existing (created in a previous ticket)?
- `HAS-FOLLOW-UP`: After the implementation of the ticket(s) we are creating, will the feature be complete? Or will it be added to in follow up tickets? 
- `DEPENDENCIES`: What stories will be needed to work on this (what are pre-requisites)?
Spawn @oracle to analyze the files generated from step 1.

### Step 3: Plan 

Based on step 2, think of an implementation plan that satisfies the given ticket/milestone tickets. 

#### Guidelines
- Be thorough in your investigation. The end of the ticket should signal the completion of the feature. 
- Do not leave details out. We want this plan to be easily worked on by another. 
- Do not leave anything up to "assumptions". If you are unsure about something, ask. Otherwise, it should be written as part of the plan. 
- Tickets must be actionable. No "double checking" tickets. 
- Story tickets must always be created in `docs/product/stories/milestones/<milestone>/x-<short-mention-of-goal>.md`, where `x` **always** increments (even past milestones i.e.`milestone-4/5-foo.md` is followed by `milestone-5/6-foo2.md`)


#### What Not To Ticket 

Do not write tickets on the following: 

- General "documentation hardening"
- "Documentation locking" tickets

### Step 4: Output

For the ticket(s) we are defining, fill out with the following format: 

```markdown
# Story X: <Short Title>

**Milestone**: (Milestone the story is for)
**Description**: Short 1-2 sentence on what we are achieving
**Status**: Todo
**Pre-requisites**: 
  - List of pre-requisite stories. Use the path of the file. 

## Goal 

<Short 1-2 sentence detailing what is the goal of this story> 

## Implementation Notes
- Short bullet point list of any important details needed for this ticket

## What Needs To Be Done

### 1. (Step 1 Checklist)
- [ ] Checklist entry of what needs to be done 
- [ ] Checklist entry of what needs to be done 
- [ ] Checklist entry of what needs to be done 
  - Sub bullet point list if needed

### 2. (Step 2 Checklist)
- [ ] Checklist entry of what needs to be done 
- [ ] Checklist entry of what needs to be done 
- [ ] Checklist entry of what needs to be done 
  - Sub bullet point list if needed
```

#### Section Details 

**Goal**: 
- `Goal` is just a short 1-2 liner mentioning what should we done after this ticket is completed. 
- Do not be overly verbose here. Leave that to the implementation checklist. 

**Implementation Notes**:
- Here is any short notes we may need for the ticket. 
- This is for any caveats or details not shown in the implementation checklist
- Examples: (What is to be implemented in follow up ticket, why we are not implementing something, etc)
- If there are tests expected for a bullet point (either created or modified), it should be written as a sub-bullet point

**What Needs To Be Done**:
- This is the actual implementation checklist. Here is where you want to be granular and plan out what is to be done. 

## Example 

```markdown
# Story 3.11: Session Lifecycle Frontend Controls and Tim
**Milestone**: Milestone 3: The Interview Experience (P2P Core)
**Description**: Add session lifecycle controls and workflow-backed timer UX to `/interviews/:id/session` without collapsing frontend state boundaries.
**Status**: Todo
**Prerequisites**:
- `docs/product/stories/stories/milestone-3-the-interview-experience-p2p-core/3-3-whiteboard-session-route-and-ui-shell.md`
- `docs/product/stories/stories/milestone-3-the-interview-experience-p2p-core/3-8-session-lifecycle.md`
- `docs/product/stories/stories/milestone-3-the-interview-experience-p2p-core/3-10-session-workflow-timer-orchestration.md`
- `docs/system/system-design/frontend-pages.md`
- `docs/system/system-design/state-management-lifecycle.md`
- `docs/infrastructure/frontend.md`

## What Needs to Be Done

### 1. Extend session route dependencies and smart/dumb boundaries
- [ ] Update `docs/system/system-design/frontend-pages.md` so `/interviews/:id/session` explicitly lists lifecycle control and timer dependencies in addition to join provisioning dependencies.
- [ ] Extend route implementation in `apps/frontend/src/routes/` with lifecycle control data/mutations and timer state consumption.
- [ ] Keep component structure aligned with frontend smart/dumb patterns:
  - smart layer owns query/mutation orchestration
  - dumb layer renders lifecycle and timer states

### 2. Implement deterministic lifecycle control UX
- [ ] Add `Start Session` and `End Session` controls to `/interviews/:id/session`.
- [ ] Use TanStack Query for server-backed lifecycle/timer state and TanStack Store for local UI state only.
- [ ] Implement deterministic UI gating:
  - show `Start Session` only when participant is joined and interview is `scheduled`
  - show timer and `End Session` only when interview is `ongoing`
  - show terminal completed/cancelled UX states with no further lifecycle actions

### 3. Implement timer rendering and retry behavior
- [ ] Render workflow-backed timer state with refresh/reconnect continuity.
- [ ] Show warning and terminal session states with explicit user-facing copy.
- [ ] Handle lifecycle failures/retries with explicit feedback, including duplicate-click and in-flight protection.

### 4. Add frontend coverage
- [ ] Add/update route/component tests for:
  - lifecycle control visibility by status
  - timer rendering and continuity on refresh/reconnect
  - warning and terminal state UX
  - retry/error behavior for start/end actions

## Implementation Notes
- Backend lifecycle transitions stay in Story 3.8.
- Workflow timer orchestration stays in Story 3.10.
- Concurrency hardening and lifecycle observability stay in Story 3.12.

## End Goal
Participants can start and end sessions from `/interviews/:id/session`, see accurate workflow-backed timer state, and receive clear lifecycle feedback across refreshes and retries.
```

