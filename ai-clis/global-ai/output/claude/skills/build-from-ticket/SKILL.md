---
name: build-from-ticket
argument-hint: '[ticket path, issue, or URL] [manual]'
description: Build one ticket end to end: implement it through a subagent, loop a reviewer until it approves, mark the ticket Completed, and open a pull request on request. Use when given a ticket file, tracker issue, or ticket URL to build, or a small body of work to ticket and then build.
---

# Build From Ticket

Take one **ticket** (the unit `to-ticket` produces) from intake to a reviewed, completed change. The ticket is the contract: its acceptance criteria and Verify section define done at every step below.

## Mode

- **Automatic (default):** agents do every review. The run ends with a pull request and never waits on the user.
- **`manual`** (in the arguments, or passed down by `build-from-spec`): the user reviews the change before anything is committed.

## Process

### Step 1: Get a ticket

- **Ticket given** (a `ticket-<NN>-*.md` path, an issue number, or a tracker URL): read it in full and go to "Pick it up" below.
- **No ticket given:** judge whether the requested work fits one ticket using the size table and split triggers in `to-ticket` Step 4. Fits means XS, S, or M with no split trigger firing.
  - **Fits:** run `to-ticket` on the request to produce exactly one ticket, then treat that ticket as given. If `to-ticket` produces more than one ticket, the work did not fit; take the branch below.
  - **Does not fit:** stop and tell the user why (which size bound or split trigger it breaks). Ask them to scope the work, offering `to-spec` then `to-ticket` to break it into tickets. Build nothing in this run; once tickets exist, `build-from-spec` runs each through this skill.

**Pick it up.** Apply `to-ticket`'s "Picking up a ticket" rule: re-read the code the ticket touches and refresh its Architecture Decisions and Task List in place. Keep the acceptance criteria fixed; if they no longer hold, raise it with the user before building.

Done when you hold one ticket whose task list matches the current code.

### Step 2: Implement

Route by the ticket's own fields:

| Ticket | Agent |
|--------|-------|
| Scope XS or S, and two or fewer files under **Files Likely Touched** | `sonic` |
| Scope M, or more than two files | `task` |

If the refreshed task list clearly touches more files than the ticket lists, route by the real count.

Pass the agent the full ticket text and the repo's build and test commands. Tell it to:

- Load `principle-incremental-implementation` and `principle-test-driven-development`, plus every skill in the ticket's **Principles** section, before writing code.
- Load any other `principle-*` skill whose trigger the work matches once it is in the code, and name it in its report.
- Work through the task list in order as thin slices, tick each task as it lands, and run the ticket's Verify commands before returning.
- On a failing check, follow `principle-debugging-and-error-recovery` instead of retrying blind.
- Report what changed, the principle skills it loaded, and the Verify results.

Done when the agent reports every task ticked and Verify passing. A failing Verify goes back to the same agent with the failure output before moving on.

### Step 3: Review until approved

Spawn a `reviewer` agent on the uncommitted diff and have it review by running the `ai-review` skill (default `both` mode). Give it the ticket's acceptance criteria and Architecture Decisions so it judges the work against the ticket as well as general quality. Give it the principle skills the implementer loaded, so it checks the diff against them; add `principle-security-and-hardening` when the diff touches input handling, auth, secrets, or stored data. Give it this reply contract:

- `APPROVED`, or
- `CHANGES` followed by a numbered list, each item naming the file and the concrete fix.

Only correctness bugs, unmet acceptance criteria, security issues, and departures from the ticket's decisions block approval. Style preferences are noted, not blocking.

On `CHANGES`, send the list to the original implementer with `SendMessage` so it keeps its context, have it re-run Verify, then send the new diff to the same reviewer. Cap the loop at **3 rounds**; still not approved after the third, stop and show the user the outstanding items and ask how to proceed.

Done when the reviewer replies `APPROVED`.

### Step 4: Update the ticket status

- **Local ticket:** set the frontmatter to `status: Completed` and tick the Complete checkpoint. `build-from-spec` matches on that exact word.
- **Tracker ticket:** set the tracker's own status field (or label) to its done state, and comment a short summary of the change.

### Step 5: Report

Tell the user:

- What the ticket now delivers, in one or two sentences.
- Files changed.
- Verify results and the number of review rounds.
- Anything deferred or flagged by the reviewer as non-blocking.

Then continue by mode:

- **Automatic:** go to Step 6 and take its **Yes** branch.
- **`manual`:** show the diff, ask the user to review it and whether to create a merge request, then **end your turn**. Leave the changes uncommitted until the user answers. Requested changes go back to the implementer as in Step 3, then repeat this step.

### Step 6: Merge request

- **Yes:** load the `git` skill and follow its `commit-pull-request` route for the branch, commit, and PR format. Create a new branch for this ticket off the branch you are on, unless you are already on one made for it, and target the PR at the branch you started from. Link the ticket in the PR body. For a local ticket, add `branch: <name>` to its frontmatter so `build-from-spec` can stack the next ticket on it. Return the PR URL.
- **No:** stop. Tell the user the changes are in the working tree, uncommitted, and the ticket is marked Completed.

## Verification

Before reporting in Step 5, confirm:

- [ ] Exactly one ticket was built, and its acceptance criteria were not edited.
- [ ] The implementer matched the routing table.
- [ ] The implementer loaded the core principle skills and the ticket's Principles, and the reviewer checked against them.
- [ ] The ticket's Verify commands pass on the final diff.
- [ ] The reviewer's last reply was `APPROVED`.
- [ ] The ticket status reads `Completed` (or the tracker's done state).
- [ ] In `manual`, nothing was committed or pushed without the user's yes.
