---
name: no-comments
description: "Strip comments from a diff or files via the comment-sicko subagent, fix the workarounds it flags, and offer encodings for claimed constraints. Use for /no-comments or a comment audit."
---

# No comments

Spawn comment-sicko and act on its accepted findings. Its fresh perspective wins by default: accept every kill and flag unless a rejection in step 2 applies.

## Scope

Use the caller's files or diff. Otherwise use the current diff against the base branch, default `main`, including the working tree.

## Steps

1. Start the `comment-sicko` subagent with the scope. Its own prompt carries its rules, so pass only the scope.
2. Inspect its report and diff.
   - Reject:
     - Application-code edits.
     - Scope escapes.
     - Exception-protected deletions.
     - Misstated `MUST KILL` reasons.
     - Flags that treat kept intentional code as guilty.
   - Reshape flags on our-code surprises stay actionable, and their comments stay deleted.
   - A keep survives only with proof it is about something we cannot change.
   - Audit missed scoped lint and TypeScript suppressions. Correctness or safety suppressions stay actionable `MUST KILL`s.
   - Restore deletions only with exact exceptions and scoped proof.
   - Before accepting thin `IMPORTANT` or `do not remove` kills or keeps, run `/how` or `/why` on their symbol.
     - An ambiguous kill stays deleted.
     - A refuted or still-ambiguous keep gets deleted.
   - Revert and rerun one rejected report with the failure named. Reject a second, report it open, and fail `/no-comments`.
   - Done when every deletion, keep, and flag is accepted or rejected.
3. Fix trivial accepted flags directly by deleting a dead path, dropping a parameter, or using the real API.
   - If any fix needs a shape, start the `Plan` agent once for the accepted set and surrounding code.
   - Stop at the sketch. Plan shapes. Step 4 implements.
4. Implement the smallest root-cause fix in scope.
   - Remove every named workaround, fixing the cause rather than guarding the symptom.
   - If the root cause is out of scope, land the smallest in-scope fix and report the rest open.
   - The `principle-debugging-and-error-recovery` skill guides intent only. The fence stays at the scope: report instances outside it open.
5. Handle constraint comments: ones that say `do not remove`, `do not change wording`, or `talk to X before changing`.
   - Leave keeps about things we cannot change.
   - Offer the cheapest in-scope type, runtime, test, or CI lint.
   - Wait for interactive approval. Unattended and eval runs require caller pre-approval.
   - If approved, encode then delete. Otherwise delete, report the constraint open, and sketch out-of-scope work.
6. Report:
   - The deletion count.
   - Restored comments.
   - Reruns.
   - Plan sketch.
   - Fixes.
   - Encoding offers.
   - Encodings.
   - Unenforced constraints.
   - Other open work.
