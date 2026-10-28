---
name: to-capability-map
argument-hint: '[initiative or idea]'
description: Split a request that bundles several independently testable capabilities into a capability map (module ids, dependency direction, build order) before any spec is written. Hierarchy of work is 'capability map (here now) -> spec per module -> tickets'. Use when a spec skill detects a multi-capability request, or when an initiative needs breaking into modules.
---

# To-Capability-Map

Decide the shape of the work before specifying it: one spec, or a map of modules with one spec each.

Most requests describe one capability. If this one does, skip the map and write a single spec. The map exists for the exception, not the rule.

## When to map

Produce a map when a single requirement bundles several independently testable capabilities:

- The requirement names distinct capabilities with their own consumers or data (e.g. identity, billing, notifications, reporting).
- Acceptance criteria cluster into groups that could ship and be verified separately.
- One capability could be cut or replaced without rewriting the others' requirements.

One capability, even a large one, gets a single spec. Ticketing slices it later.

## Process

1. **Propose the map.** Use [the map template](./references/map-template.md). Keep it small and reviewable: a module table plus a build order, not a project plan.

2. **Apply the map rules.**
   - **Stable module ids.** Kebab-case, chosen once, never renamed mid-initiative. Specs, tickets, and downstream commands select work by these ids instead of guessing which spec is active.
   - **Dependency direction, no cycles.** Arrows point one way. If two modules each need the other, they are one module.
   - **A graph, not a chain.** Modules that share only already-built dependencies can be specced and built in parallel. Write them on the same build-order step.
   - **Interfaces live at the boundary.** The map records that `billing` depends on `identity`; the contract between them belongs in the provider module's spec (see `principle-api-and-interface-design` for designing it).

3. **Gate the map.** Get module boundaries, dependency direction, and build order approved before any module spec is written. Getting the map wrong is expensive; reviewing ten lines is not. Pick the reviewer by how this skill was reached:
   - **Manual** (the user invoked this skill directly, or asked to review the map): present the map and stop your turn. The user approves or corrects it; approval is a ten-line review, not an interview. Revise until the user approves.
   - **Automated** (reached from another skill or workflow): spawn a fresh `Plan` subagent with [references/reviewer-prompt.md](references/reviewer-prompt.md), passing the map and the request. Revise until it replies `APPROVED`.

4. **Save the approved map** as `<kb>/work/<slug>/MAP.md`, outside the repo (the knowledge-base skill, "Work items"). The map, not filename guessing, is the index of what exists.

5. **Hand off to `to-spec`.** Spec the first build-order step (the modules with no dependencies), one spec per module. Later modules are specced when their dependencies are approved or built; see `to-spec`'s "When there is a capability map".

## Keeping the map alive

- Update a module's status column as it is specced and built.
- If building a module reveals a boundary was wrong, change the map first, get it re-approved, then change the affected specs.
- Module ids are permanent. Mark a cut module `dropped` and keep its row.

## Red Flags

- One spec whose requirements span several independently testable capabilities
- Module boundaries or build order decided implicitly during implementation because no map was approved up front
- A map with a cycle, or two modules that cannot be tested without each other
- Module specs written before the map is approved
- Every module specced up front in full detail before the first one is built
