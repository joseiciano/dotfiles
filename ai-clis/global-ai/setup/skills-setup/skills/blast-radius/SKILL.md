---
name: blast-radius
argument-hint: '[diff, PR, symbol, or brief]'
description: "Find what a change breaks somewhere else, beyond the diff, and prove the one fact it's safe because of by running real code. Use for 'blast radius of X', 'what could this break', a small diff you don't trust, or a brief that asserts something about existing code ('make X public', 'X already handles Y') before designing against it."
---

# Blast radius

Find what a change breaks somewhere else, before it ships. Run it before design, not only before shipping, when a brief asserts something about existing code ("make endpoint X public"): the assertion is a hypothesis, and the consumer census decides the design.

Companion to `how` and `why`. `how` tells you what the code does. `why` tells you why it's shaped that way. Blast radius tells you what it breaks somewhere else.

Listing the callers is not the job. Grep finds those in a second. The job is the breakage grep won't show you.

## Mode

- **Manual (default):** the user invoked this skill. Ask when the change or the question is unclear, and reply with the writeup in [What to hand back](#what-to-hand-back).
- **Automated:** another skill or workflow reached this one, passing the change and its intent. No user is present, so never ask a question; when the intent is unclear, take it from the caller's spec or ticket. Reply with the writeup plus the status line in [Status](#status).

## Don't trust your own writeup

A blast-radius writeup that sounds right is worthless. It reads as convincing whether or not it's true. Find the one or two facts the whole thing depends on and prove them by running code.

### Evidence ladder

For each fact the change's safety depends on, climb this ladder as far as is cheap, and say where it stopped.

1. You said so. Worthless on its own.
2. You pointed at the line. A real `file:line`, or the library's own source.
3. You showed the bad case can't happen. You walked the failure step by step and it doesn't reach.
4. You ran it. A probe script that calls the real code and fails loud if you're wrong.
5. You reproduced it in the running app.

Step 4 is usually one small probe that imports the same library the app ships and calls the exact function you're worried about.

## Steps

1. **Read the change.** The diff, the symbols it adds, changes, and deletes, and what it now does differently, including the part the diff doesn't spell out. Pull the PR and commits as in `why` Step 2. Done when you can state the behaviour change in two sentences.
2. **Find the one fact it's safe because of.** Most changes that look risky are safe because of a single fact, like "this call only drops already-dead cache entries and does nothing else". If it holds, most risky cases clear at once. Spend your time here, not on a long list of maybes. Done when the fact is written as one falsifiable sentence.
3. **Look where grep stops.** Read the source of the library you call, at its pinned version and with any local patch. Work out when things run: microtasks, framework lifecycle (effects, unmount, teardown). Follow what a symbol search misses: the JSON an API returns, a DB column, a wire format, another language reading the same bytes, a feature flag, code three hops downstream. Done when every one of those channels the change touches is followed or named as not applicable.
4. **Weigh each risk.** Give it a real chance of happening and a real cost if it does. Keep the confirmed risks; list the checked-and-cleared ones separately. Same rules as `why`: cite a real `file:line`, a search that finds nothing is still an answer, and every caller and API named exists. Done when every risk sits in Risks or Cleared.
5. **Prove the one fact.** Write a probe in the scratchpad that runs the real code, run it, and paste what happened. The probe is evidence, not a test: it stays out of the repo. Done when the fact reaches ladder step 4 or 5, or is marked unproven with the reason.
6. **For a big or wide change, run `interrogate`** on the writeup and the diff, and merge its Act on findings into Risks. `interrogate` runs only from the top-level session; as a subagent, skip this step and say so in the writeup.

## What to hand back

- **What it does.** What changed, including the part that isn't obvious.
- **The one fact it's safe because of.** State it, name its ladder step, and show the proof. If you couldn't prove it, write unproven.
- **Risks.** Each names how it breaks, the `file:line`, how likely and how bad, and how to check. Paste the proof for the ones that matter.
- **Cleared.** What you checked and why it's fine.
- **Before you merge.** The cheapest test or repro that catches the real bug, including the probe. A probe worth keeping goes to the `tester` agent to become a real test.

Write it through `unslop`, cite real code, and strip anything private before it goes anywhere public.

## Status

Automated mode ends the writeup with one status line:

- `SAFE`: the one fact reached ladder step 4 or 5 and no confirmed risk remains.
- `RISKS`: one or more confirmed risks remain; the caller acts on the Risks list.
- `UNPROVEN: <fact>`: the safety fact stopped below ladder step 4. The caller treats the change as unverified and surfaces it for a human.

## Verification

Before replying, confirm:

- [ ] The one safety fact is stated, with its ladder step and proof, or marked unproven.
- [ ] Every risk cites a real `file:line` and sits in Risks or Cleared.
- [ ] The channels grep misses (library source, timing, wire formats, data, flags) were each followed or ruled out.
- [ ] The probe ran, and its output is pasted.
- [ ] In automated mode, no question was asked and the status line is present.
