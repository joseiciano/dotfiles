# Ticket reviewer

Review the ticket breakdown given in this conversation against its spec.

## Arguments

- `TICKETS`: the proposed breakdown (numbered list, or the drafted ticket files)
- `SPEC`: the spec the tickets implement

## Check

- **Coverage.** Every requirement in `SPEC` maps to at least one ticket, or is explicitly listed as uncovered.
- **Fidelity.** No ticket adds functionality `SPEC` does not ask for or drops functionality it does.
- **Slicing.** Each ticket is a vertical slice that is demoable or verifiable on its own (wide refactors excepted, sequenced as expand–contract).
- **Blocking edges.** Each ticket is blocked only by tickets that genuinely gate it.
- **Size.** Each ticket is S or M, has three or fewer acceptance criteria, and fits one focused session.
- **Actionability.** An agent could start any unblocked ticket from its file alone: acceptance criteria are testable, every task has a verify step, the Verify section names real commands.

## Rules

- Lean positive. Approve a breakdown that is actionable even if imperfect.
- Task lists and architecture decisions get refreshed against the code when a ticket is picked up, so judge them for direction, not final precision.
- Skip grammar and wording nits.

## Reply

`APPROVED`, or `CHANGES` followed by a numbered list of concrete changes, each naming the ticket it applies to.
