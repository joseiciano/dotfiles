# Architecture Decision Records

## Location

ADRs go in the personal knowledge base at `<kb>/adr/` (the `knowledge-base` skill resolves `<kb>`). Write the repo copy only when the user asks for it.

## Format and numbering

In either location, follow the repository's established ADR convention when one exists. Find it in existing ADRs, project instructions, and ADR tooling or config (e.g. an `.adr-dir` file). Match:

- **Directory, file extension, and markup**: e.g. `docs/adr/*.md`, `Documentation/Decisions/*.rst`, a MADR layout, an `adr-tools` setup.
- **Numbering and filename pattern**: continue the existing sequence (`ADR-004-Title.rst`, `0004-title.md`, …) with the existing scheme.
- **Section headings**: the project's heading set.

When the evidence conflicts, surface the conflict to the user. Apply the default template below only when no convention exists, numbering sequentially from `ADR-001`.

## Default template

```markdown
# ADR-001: Use PostgreSQL for primary database

## Status
Proposed | Accepted | Superseded by ADR-XXX | Deprecated

## Date
2025-01-15

## Context
The forces at play: requirements, constraints, what made a decision necessary now.

## Decision
Use PostgreSQL with Prisma ORM.

## Alternatives Considered

### MongoDB
- Pros: Flexible schema, easy to start with
- Cons: Our data is relational; relationships would be managed by hand
- Rejected: Relational data in a document store leads to complex joins or duplication

## Consequences
What becomes easier, what becomes harder, and what the team now has to know or run.
```

Every rejected alternative carries the reason it lost: that reason is what stops the decision being re-litigated later.

## Lifecycle

```
PROPOSED → ACCEPTED → (SUPERSEDED or DEPRECATED)
```

A changed decision gets a new ADR that references the old one; the old ADR's Status becomes `Superseded by ADR-XXX` and the file stays.
