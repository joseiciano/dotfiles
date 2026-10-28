---
name: to-spec
argument-hint: '[idea]'
description: Research and design a high level implementation spec to be then broken down into smaller units of tasks. Hierarchy of work is 'spec (here now) -> tickets'. This is meant to be a 30-ft view of the feature or product that is to be implemented. 
--- 

# To-Spec

This skill takes details from the codebase, existing documentation, and current conversation (if available) in order to produce a finalized spec for it. 

Unless absolutely necessary, Do NOT interview the user; synthesize what is known. 

Understand what the user wants to build and generate a structured spec to cover the following: 
  - objective
  - commands
  - project structure
  - code style
  - testing strategy
  - project boundaries 

## Overview

Write a structured specification before writing any code. 

The spec is the shared source of truth between you and the human engineer. 

It defines the following: 
  - What we're building
  - Why we are building it 
  - How it will be built 

## Scope Check

Before writing, check scope. If the request bundles several independently testable capabilities (distinct consumers or data, acceptance criteria that cluster into separately shippable groups), use the to-capability-map skill and get the map approved first. Otherwise, write one spec.

If a work item already has an approved `MAP.md`, follow "When there is a capability map" below.

### When there is a capability map

Run this skill once per module, in the map's build order. The map is the index of what exists.

1. **One spec per module, scoped to the module.** Problem, user stories, decisions, and out-of-scope cover only that module. Save it as `<kb>/work/<slug>/<module-id>/SPEC.md`, outside the repo (the knowledge-base skill, "Work items"). Never commit it.
2. **Contracts live in the provider's spec.** A contract between two modules is written once, in the spec of the module that provides it. The consuming module only names the dependency by module id.
3. **Spec just in time.** Spec the modules with no dependencies first. Spec each later module once its dependencies' specs are approved or built. Specs written far ahead go stale as building the earlier modules teaches you something. If the user wants every module specced up front, mark the later ones as drafts.
4. **Issue tracker.** Publish one parent issue for the map and one child issue per module, linked with the tracker's blocked-by relation. 
5. **Update the map.** Set the module's status to `specced` in `MAP.md` after its spec is approved.


## Process

### Step 1: Identify Goal 


**Reframe instructions as success criteria.** When receiving vague requirements, translate them into concrete conditions:

```
REQUIREMENT: "Make the dashboard faster"

REFRAMED SUCCESS CRITERIA:
- Dashboard LCP < 2.5s on 4G connection
- Initial data load completes in < 500ms
- No layout shift during load (CLS < 0.1)
→ Are these the right targets?
```

This lets you loop, retry, and problem-solve toward a clear goal rather than guessing what "faster" means.

### Step 2: Codebase exploration 

Explore the repository to understand the current state of the codebase, if you have not already.

Make sure to respect any knowledge-base or product docs (ADRs). 

### Step 3: Identify key details

Sketch out the seams that will be used to test this feature. 

Existing seams should be preferred to new ones. Use the highest seam possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better - the ideal number is one.

If unclear, bring up and make sure that these seams match expectations. 

### Step 4: Create Spec

Write the spec using the designed output format. 

For the output format, use (`./references/spec-template.md`). **Always** use this template. 

### Step 5: Review

Pick the reviewer by how this skill was reached:

- **Manual** (the user invoked this skill directly, or asked to review the spec): present the spec and stop your turn. The user reviews. Revise with this same process until the user approves.
- **Automated** (reached from another skill or workflow): spawn a fresh `Plan` subagent with [references/reviewer-prompt.md](references/reviewer-prompt.md), passing the spec and its source. Revise until it replies `APPROVED`.

## Post-Creation

The spec is a living document, not a one-time artifact:

- **Update when decisions change** — If you discover the data model needs to change, update the spec first, then implement.
- **Update when scope changes** — Features added or cut should be reflected in the spec.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "This is simple, I don't need a spec" | Simple tasks don't need *long* specs, but they still need acceptance criteria. A two-line spec is fine. |
| "I'll write the spec after I code it" | That's documentation, not specification. The spec's value is in forcing clarity *before* code. |
| "The spec will slow us down" | A 15-minute spec prevents hours of rework. Waterfall in 15 minutes beats debugging in 15 hours. |
| "Requirements will change anyway" | That's why the spec is a living document. An outdated spec is still better than no spec. |
| "The user knows what they want" | Even clear requests have implicit assumptions. The spec surfaces those assumptions. |
| "It's one big feature; splitting it is overhead" | If acceptance criteria cluster into independently testable groups, a monolithic spec forces every downstream task to reason over the whole contract. A ten-line capability map is the cheap alternative. |
| "I'll decompose during ticketing" | Ticketing slices work within a spec. By then the oversized artifact already exists — module boundaries and dependency direction must be decided before the spec is written, not after. |

## Red Flags

- Starting to write code without any written requirements
- Asking "should I just start building?" before clarifying what "done" means
- Implementing features not mentioned in any spec or task list
- Making architectural decisions without documenting them
- Skipping the spec because "it's obvious what to build"
- Writing the spec and starting the tickets or code in the same turn
- One spec whose requirements span several independently testable capabilities
- Module boundaries or build order decided implicitly during implementation because no capability map was approved up front

## Verification

Before proceeding to implementation, confirm:

- [ ] The spec covers all six core areas
- [ ] Success criteria are specific and testable
- [ ] The spec is saved to a file in the repository **or** within the knowledge-base
- [ ] If the request bundles several independently testable capabilities, a capability map (module ids, dependency direction, build order) was approved before any module spec was written
- [ ] Every module spec traces to a module id in the approved map

