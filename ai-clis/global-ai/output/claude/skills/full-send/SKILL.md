---
name: full-send
description: Take a change from its current state to a merged PR with no one watching. Use only when the user says "full send".
---

# Full Send

The user said "full send" because they are not watching this thread. Your updates and final message go unread until long after you stop, so you own the work from its current state to a merged PR. Without an explicit "full send", none of the grants below apply.

The user grants you permission to:

- Merge the PR once the [merge gate](#merge-gate) passes.
- Rebase the PR's own branch and push it with `--force-with-lease`.
- Use the test methods [Proof](#proof) needs without asking first.

## Testing permission

A "full send" request is the permission. A project rule that says to ask before a test method, or to leave testing to the user, gives way to it for this task. That covers computer use, browser automation, simulators and devices, running the app or a dev server, screenshots, and visual checks. Use the method that gives direct proof and list it in the report.

Rules about *how* to test still apply: follow ones that name the correct command, fixture, or check. The permission covers only the tests this task needs. It grants nothing in [Asking the user](#asking-the-user), and it does not bypass a harness approval prompt.

## Steps

Full send drives exactly one PR. Given a spec or an idea, run `full-send-spec` instead: it plans the tickets and runs this skill once per ticket. If any other goal needs more than one ticket's worth of work (`to-ticket`'s size table), ask the user before starting.

1. **Finish the change.** On the default branch, create a branch first.
   - **Given a ticket:** run `build-from-ticket` in automatic mode, stop after its Step 5 report, and skip its Step 6. It runs the verification preflight itself, its reviewer loop stands in for step 3 here, and this skill opens the PR in step 4, with any preflight `verify:` changes as the first commit.
   - **Otherwise:** before writing code, run [`verification-preflight`](references/verification-preflight.md); when it changed the `verify` skill, commit that as the branch's first commit (`verify: ...`). Then make the smallest change that meets the goal: fix the case that happened, not every case that could.
2. **Prove it.** Get [proof](#proof) for every change in the diff.
3. **Review.** Run `interrogate` in gate mode on the diff, with the goal as the task spec. On `FIX`, address the Act on items, re-prove what changed, and call it again with the next cycle number. On `PASS`, continue. On `BLOCKED`, [ask the user](#asking-the-user).
4. **File the PR.** Rebase onto the latest default branch, then follow the `git` skill's `commit-pull-request` route. Its Testing section names the proof.
5. **Babysit.** Run `babysit` in autonomous mode. Get proof for each fix before you push it.
6. **Merge** when the [merge gate](#merge-gate) passes.
7. **Report** in your final message: the PR link, the merge commit, your proof, and every decision you made for the user. Log decisions as you go with `show-me-your-work`.

Stay active from step 1 to step 7: ending your turn while checks or bots are pending stops the work, because nobody will prompt you again. Wait on `babysit`'s `pr-wait` watcher under `Monitor`, so each PR event wakes you.

## Proof

Proof is evidence you observed yourself in this session: command output, a reproduction, a screenshot. Use the most direct proof the change allows:

- Reproduce the original failure, apply the fix, then watch the same reproduction pass.
- Run the checks the repo's CI runs (typecheck, lint, tests).
- Add one focused test that fails without the fix, when the behaviour has none and the repo has a test setup (`principle-test-driven-development`).
- For UI and runtime behaviour, drive every feature in the preflight's verify plan with the project's `verify` skill, and add the plan's new feature file when the change added a feature. Green mocked tests do not prove the user experience works. Attach screenshots to the PR when they help and you can upload them.
- When the diff changes an exported symbol, a DB schema, a wire format, or a feature flag, run `blast-radius` to prove the callers outside the diff still hold.

A change you cannot prove is a change you lack full confidence in: [ask the user](#asking-the-user).

## Merge gate

Merge only when all of these hold on the latest commit:

- Your proof covers every change in the diff.
- Required checks are green.
- Review bots have finished, and each finding is fixed or dismissed with a written reason.
- No review thread is unresolved, and no human review still requests changes.
- The branch is up to date with the default branch, and GitHub reports it mergeable.

Merge with the method the repo uses: check `gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed` and recent merged PRs, and default to squash. With a merge queue or auto-merge, stay until GitHub reports the PR merged. Merge through branch protection as configured, never with `--admin` or another bypass. An automated review that only asks for "human review" does not block the gate when your proof is complete.

## Asking the user

A question in a normal message goes unseen and makes the thread look done. Ask with `AskUserQuestion`, so the thread shows it is waiting, and put all the context in the question: the PR link, what blocks you, and the options with your recommendation first.

Ask only when you cannot continue alone:

- You cannot prove the change.
- The merge gate cannot pass and you cannot fix that yourself.
- The next step is outside the grant: deleting data, touching production, changing things outside the repo, closing a PR, or force-pushing any other branch.
- The goal is ambiguous in a way that changes the result.
- Another PR makes this one obsolete.

Decide everything else yourself with sensible defaults, and list those decisions in the report. If the question tool is unavailable or returns no answer, take the safe path: leave the PR open and unmerged, and start your final message with the question.
