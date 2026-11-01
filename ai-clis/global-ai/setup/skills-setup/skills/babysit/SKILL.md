---
name: babysit
description: Watch an open PR — fix failing CI, handle review comments and bot findings, keep it rebased, and drive it to a mergeable state. Use after opening a PR when the user wants the agent to shepherd it without re-prompting, or as the PR stage of `full-send`.
---

# Babysit a PR

Shepherd one open PR until it is ready (or merged, in `full-send`). Only the session that owns the PR babysits it: a subagent that opens a PR returns to its parent instead.

## Modes

- **Attended** (default): stop at ready and report. Merge only on an explicit request. Clear any force-push with the user first.
- **Autonomous**: `full-send` passes this down. You may rebase and `git push --force-with-lease` the PR's own branch, and the caller merges once its merge gate passes. Ask the user only for the cases in `full-send`'s "Asking the user".

## Waiting

Wait with one event-driven watcher per PR. Every watcher on a GitHub account shares one rate limit.

**GitHub:** run the bundled `pr-wait` with the `Monitor` tool (`timeout_ms: 3600000`), so each event line wakes you:

```bash
python3 -I ~/.claude/skills/babysit/scripts/pr-wait <pr> [--repo owner/name] [--until ready|green|any-change]
```

- `ready`: required checks green, Greptile or Macroscope reviewed the head, no unresolved threads, branch not BEHIND. It only exits `0` once one of those bots has reviewed, so use it only when one has a check run, review, or comment on this PR.
- `green`: required checks only. Use it on every other repo; it ignores threads and BEHIND, so check those yourself (see [When to stop](#when-to-stop)).
- `any-change`: exit on the first event.
- Before arming it, read `gh pr view --json mergeStateStatus,statusCheckRollup`. A repo can have an active workflow and still create no run for the PR. When no required checks are configured and no check appears on the head within three minutes, `pr-wait` exits with a "no checks" line (`0` for `green`, `1` for `ready`): CI did not start, so nothing on GitHub gates the PR. Decide from the verification you ran locally, and name the missing CI run in the report.

Exit `0` means the condition is met or the PR merged; `1` means it needs you (failed check, conflict, unresolved threads, closed); `2` is bad input or another `pr-wait` already watches the PR. Restart it after every push, after handling an exit `1`, and after a resume; its state file keeps what arrived in between. If another pid already watches the PR, reuse that watcher; kill it only when its events stop reaching you. When an event needs no action, end your turn silently.

**GitLab or no `Monitor` tool:** pace re-checks with the `loop` skill: blocking on the pipeline while CI runs, a 20–30 min heartbeat while awaiting a reviewer.

**Rate limits:** `gh pr view` and `gh pr checks` use GraphQL. When it runs out (`gh api rate_limit --jq .resources.graphql`), read through REST, which has its own budget: `gh api repos/<owner>/<repo>/pulls/<n>` and `gh api repos/<owner>/<repo>/commits/<sha>/check-runs`.

## Triage

Act only on checks and comments newer than the latest push, in this order:

1. **Conflicts or BEHIND** (`mergeStateStatus` `DIRTY` or `BEHIND`, or `pr-wait` reports base commits touching this PR's files): rebase onto the base branch, using the `git` skill's `merge-conflicts` route for conflicts. Push per the mode.
2. **Failing checks:** run the `fix-ci` skill. Tell repository failures from infrastructure flakes; re-run a flake once, and fix a real failure at its root.
3. **Review comments and bot findings:** run `get-pr-comments` for the list, then verify each finding against the source before touching code.
   - **Real bug in the intended case:** make the smallest fix, preferring one that deletes or narrows code, and quote the comment in the commit message.
   - **Not worth addressing** (unneeded tests, guards for edge cases that do not matter, extra compatibility, small performance costs, wrong claims): reply with a written reason, resolve the thread, and list it as a follow-up in the report.
   - **Judgement call or unclear ask** (attended mode): leave it and reply with what you would have done.
   - CodeRabbit is advisory: treat its findings like any other, and never wait or hold a merge for it. If the repo has `.macroscope/check-run-agents/*.md`, read those rules before replying to a Macroscope finding.

Keep the PR at the size the goal needs: review loops grow a PR one cheap-looking fix at a time.

## Comments posted for the user

Every comment, reply, or dismissal reason posted on the user's behalf opens with this note, using the model name the harness reports (or the harness name when it reports none):

```md
> [!NOTE]
> 🤖 **<model> responding on behalf of <user>**

Reply starts here.
```

Lead with the conclusion, cite the code, check, or reproduction, and separate verified fact from judgement. Check the whole comment for secrets before posting, confirm GitHub returned its URL, and resolve a thread only after its reply posted.

## When to stop

- **Ready:** required checks are green, every review thread is resolved, no human review requests changes, and the branch is up to date with its base. `pr-wait --until ready` exiting `0` proves all but the human review; after `--until green`, check the rest with `gh pr view --json reviewDecision,mergeStateStatus` and the PR's unresolved threads. A "no checks" exit proves nothing about the code: the local gate (typecheck, build, tests) stands in for CI, and the report says so. Right before calling it ready or merging, `git fetch` and re-check: base commits that landed after the last green run and touch this PR's files mean rebase, push, and wait for green again.
- **Merged or closed:** the watcher exits; report.
- **Obsolete:** an overlapping PR makes this one obsolete. Stop watching, report it, and ask before closing.
- **Stuck** (attended mode): three fix → push → recheck rounds without green. Stop and summarise what is still broken.
- **Design choice:** the next fix forces one. Put it to the user with `AskUserQuestion`.

## Hard rules

- Rewrite history only on the PR's own branch, with `--force-with-lease`, and in attended mode only after the user agrees.
- Change a test's expected value only when the behaviour genuinely changed and the assertion was pinned to the old behaviour.
- Run every hook: commits and pushes go through without `--no-verify`.
- Keep required checks required, and merge through branch protection as configured, never with `--admin`.

## Report

Fixes applied (each with its commit SHA), comments addressed, comments declined with the reason, follow-ups, and the current PR status.

Use `unslop` on prose you write here (comments, commit messages, the report).
