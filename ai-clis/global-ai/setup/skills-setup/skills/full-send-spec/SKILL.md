---
name: full-send-spec
description: Take a spec or an idea to merged PRs with no one watching, one `full-send` per ticket. Use when the user says "full send" on a spec or an idea, or when `full-send` hands one over.
---

# Full Send Spec

The user said "full send" on a spec or an idea, so they are not watching this thread. You own it from planning to the last merged PR. Every grant, rule, and section of `full-send` applies here: its testing permission, [Proof](../full-send/SKILL.md#proof), [Merge gate](../full-send/SKILL.md#merge-gate), and [Asking the user](../full-send/SKILL.md#asking-the-user). This skill adds the ticket loop around it.

Tickets ship in **series**: each ticket's PR targets the default branch and merges before the next ticket starts. A later ticket sees the code of the tickets that block it because that code is already on the default branch, so no PR stacks on another.

## Steps

1. **Plan.** Run `build-from-idea` (given an idea) or `build-from-spec` (given a spec) in automatic mode. Stop once `build-from-spec`'s Step 4 gate passes, before its Step 5: this skill builds the tickets. Done when the tickets are published and every requirement ID is covered or listed as uncovered.
2. **Check the size.** Ask the user before building when the plan produced a capability map (`MAP.md`), more than **5** tickets, or an uncovered requirement. Put the ticket list, the build order, and your recommendation in the question.
3. **Ship each ticket.** Take the tickets whose status is not `Completed` in number order. For each one:
   1. Check out the default branch and pull it.
   2. Run `full-send` on the ticket, through its **Given a ticket** branch, steps 1–6. Its step 7 report folds into this skill's report.
   3. Halt the loop when that ticket stops short of merged. The tickets after it depend on code that is not on the default branch yet.

   Resuming a run: a ticket marked `Completed` whose PR is still open picks up at `full-send` step 5.

   Done when every ticket's PR is merged, or the loop halted on one ticket.
4. **Report** in your final message:
   - What the spec or idea now delivers, measured against its success criteria.
   - Each ticket: its PR link, its merge commit, and the proof `full-send` recorded.
   - Where a halt left things: which tickets merged, which PR is open and why, which tickets were not started.
   - Every assumption and decision, with the `decisions.tsv` path from `show-me-your-work`.

Stay active from step 1 to step 4. Ending your turn while checks or bots are pending stops the work, because nobody will prompt you again.

## Verification

Before reporting, confirm:

- [ ] Planning ran in automatic mode and stopped before `build-from-spec`'s Step 5.
- [ ] Each ticket was built from a freshly pulled default branch, after the ticket before it merged.
- [ ] Every merged PR passed `full-send`'s merge gate.
- [ ] The report names the state of every ticket.
