---
name: principle-documentation-and-adrs
description: Records architecture decisions (ADRs) and the docs around a change. Use when making a decision that's expensive to reverse, changing a public API, shipping user-facing behaviour, or updating a README, changelog, or rules file.
user-invocable: false
---

# Documentation and ADRs

Code records *what* was built; documentation records the **why**: the context, constraints, and rejected alternatives a reader cannot recover from the code.

## Branches

Read the reference for the branch you are on when you reach it:

| Branch | Reference |
|---|---|
| Decision that's expensive to reverse: framework or major dependency, data model, auth strategy, API style, build or hosting infrastructure | [references/adr.md](references/adr.md) |
| Editing the prose of any doc | [references/prose-review.md](references/prose-review.md) |

## Principles

### Decisions get an ADR

A decision that's expensive to reverse gets an ADR in the same change that makes it. When a decision changes, write a new ADR that supersedes the old one; the old one stays as history.

### Comments carry the why

Comment non-obvious intent and known gotchas at the line they affect, linking the ADR when one exists. Delete dead code and finish TODOs in the same change; `no-comments` audits the rest.

### Public interfaces are documented with their types

Every exported function or endpoint documents its inputs, outputs, and errors in the project's existing doc style. `principle-api-and-interface-design` owns the contract itself.

### Docs follow behaviour

A change to user-facing behaviour updates the changelog in its existing format. A change to how the project runs updates the README's run commands. Rules files and skills follow `writing-for-agents`.

## Verification

After documenting a change:

- [ ] Every decision in this change that's expensive to reverse has an ADR with Status, Context, Decision, Alternatives, and Consequences, located and numbered per [references/adr.md](references/adr.md)
- [ ] Every superseded ADR links to its replacement and still exists
- [ ] Every changed public interface documents its inputs, outputs, and errors
- [ ] Every user-facing behaviour change has a changelog entry
- [ ] Every non-obvious line touched carries a why-comment; no commented-out code or TODOs remain
- [ ] For prose edits, every check in [references/prose-review.md](references/prose-review.md) passes
