# Ticket template

One file per ticket at `<work>/tickets/ticket-<NN>-<slug>.md`. Keep every heading in the order shown. A section that does not apply keeps its heading with `None.` beneath it.

```markdown
---
status: ready-for-agent
---

# <NN>: [Short descriptive ticket title]

## Overview
[At most one paragraph: the end-to-end behaviour this ticket makes work, from the user's perspective. Not a layer-by-layer list.]

**Scope:** [XS | S | M] · [Complete goal | Partial — follow-up work: ...]

## Requirements & Constraints
- **REQ-001**: [Functional requirement this ticket implements, ID traced from the spec]
- **CON-001**: [Constraint on how it is implemented]

## Blocked by
- [Ticket NN: title, or "None (can start immediately)"]

## Dependencies
- [External library, service, or migration this ticket relies on. Not other tickets; those go in Blocked by.]

## Architecture Decisions
- [Key decision and rationale]

## Alternatives Considered
- [Approach not taken and why it was rejected]

## Principles
- [`principle-*` skill this ticket triggers beyond incremental implementation and TDD, and why: e.g. `principle-security-and-hardening` (parses untrusted input)]

## Acceptance Criteria
- [ ] [Specific, testable condition]
- [ ] [Specific, testable condition]
- [ ] [At most three. More means the ticket should split.]

## Task List
- [ ] Task 1: [One change] → verify: [test or check that proves it]
- [ ] Task 2: ...
- [ ] Task 3: ...

### Checkpoint
- [ ] Tests pass, build clean

- [ ] Task 4: ...

### Checkpoint: Complete
- [ ] Every acceptance criterion met
- [ ] Verify section passes
- [ ] Ready for review

## Verify
- [ ] Tests pass: `[focused test command]`
- [ ] Build succeeds: `[build command]`
- [ ] Manual check: [the screen to open, the request to send, what you should see]

## Files Likely Touched
- `[path]`

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk] | [High/Med/Low] | [Strategy] |

## Open Questions
- [Question needing human input]
```

## Tracker variant

When publishing to an issue tracker, drop the frontmatter and the `<NN>:` title prefix. Put status on the tracker's own field or label (`ready-for-agent` unless told otherwise), and express **Blocked by** through the tracker's native blocking link, falling back to the issue identifiers in the section. Keep every other section as written.
