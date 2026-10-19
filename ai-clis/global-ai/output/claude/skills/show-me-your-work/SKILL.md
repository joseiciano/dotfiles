---
name: show-me-your-work
description: "Keep a reviewable decision trail for long-running or unattended work: a TSV log in the knowledge base with one row per decision (what, why, evidence, result). Use for /build auto, the ticket-stack workflow, other autonomous or multi-phase runs, or work a human reviews after stepping away."
---

# Show me your work

Keep one decision log per work item, so a human who stepped away can read what happened in a minute instead of scrolling a transcript.

## The format

A single TSV file, one row per decision. Cells stay single-line. Evidence is a pointer, not prose.

- **ts.** ISO8601 timestamp.
- **phase.** The task, ticket or workstream.
- **decision.** What was chosen or done, one line.
- **why.** The reason in plain words.
- **evidence.** A pointer that proves it: commit SHA, PR URL, `file:line`, a test command, or an artifact path. Never a paragraph.
- **result.** The outcome: `tests green`, `reverted`, `open`, `INCONCLUSIVE`, `shipped-with-findings`.

```
ts	phase	decision	why	evidence	result
2026-05-24T09:02:00Z	task-1	cached rates in an in-memory map, not Redis	the spec says one instance; Redis adds a service for no gain	commit 3a9f1c2	tests green
2026-05-24T09:40:00Z	task-2	reverted the batch-insert rewrite	it broke ordering the importer relies on	commit 7c21e0a reverted by 91b0d4e	reverted
2026-05-24T10:15:00Z	task-3	treated a blank currency as USD	the spec is silent; every fixture uses USD	src/rates.ts:42	open
```

## Where it lives

`<work>/decisions.tsv`, in the current branch's work item in the knowledge base (the knowledge-base skill's "Work items" section finds `<work>`). It is outside the repo: never commit it. When a run has no work item, use `<kb>/work/<slug>/decisions.tsv` with the slug the caller names.

## Logging a row

```bash
bash ~/.claude/skills/show-me-your-work/scripts/log.sh <logfile> <phase> <decision> <why> <evidence> <result>
```

It stamps `ts`, writes the header on first use, keeps cells on one line, and neutralizes cells a spreadsheet would read as formulas. Use it instead of a bare `printf`.

Write each row the way you'd tell a teammate what you did, and apply the unslop skill to the text.

Log decision points, not every action:

- a task or ticket finished, with its verification result
- a choice between real alternatives
- a call you made where the spec or ticket was silent or ambiguous
- a revert or change of approach, with what triggered it
- a check skipped or not run, and why
- a blocker hit

Skip the trivial and self-evident.

## Runs

A run is one agent conversation, or one workflow sub-agent. When a run adds to a log that already has rows, its first row has phase `start` and names the run (`/build auto`, `ticket-stack #3 implement`) in evidence. Use phase `start` for nothing else.

## Rules

- Append-only. A wrong row gets a new row that supersedes it. Never edit or delete history.
- Log as you go, not at the end. A log reconstructed from memory loses the reverts and the silent calls, which are the rows a reviewer needs most.
- Before handing back, read this run's rows once. If a fork, revert or skipped check that shaped the work is missing, append it.

## Handing back

End the reply with the log path and an **Attention** section listing the rows a reviewer should check first: `open`, `INCONCLUSIVE`, `reverted`, skipped checks, and calls made where the spec was silent. "No flags" is a valid value.

## Reviewing the trail

`column -s$'\t' -t <logfile>` renders it in a terminal. Read top to bottom and follow the evidence pointers.

## Composing this skill

Other skills and workflows route their audit trail here instead of inventing one. Reference it by name and let it own the format.
