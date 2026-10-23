---
name: create-daily-record
description: Create or update today's work-journal record of what was done in the last 24 hours.
argument-hint: "[context]"
disable-model-invocation: true
---

# Create Daily Record

Arguments: `$ARGUMENTS` is optional `$CONTEXT`: notes on what was done or is in progress.

## Steps

1. Gather the last 24 hours of work. `$SINCE` is yesterday's date as `YYYY-MM-DD`. Read every source:
   - `$CONTEXT`, which wins over every other source when they conflict.
   - Commits, via the `what-did-i-get-done` skill for the last 24 hours.
   - PRs you opened or reviewed across repos: `gh search prs --author=@me --updated=">=$SINCE"` and `gh search prs --reviewed-by=@me --updated=">=$SINCE"`.
   - The `Working on` section of the most recent earlier daily, to see what moved.

   Done when every source has been read or noted as missing.
2. Copy [the template](references/template.md) with today's date in the header. Done when the header is set.
3. Fill `Things done` with finished work and `Working on` with open work and what is next. A section with nothing gets `- None.` Done when every gathered item sits in one section.
4. Save it. See [Saving](#saving). Done when the file is written and its path is reported.

## Saving

Write to `~/documents/workspace/workjournal/daily/<YYYY-MM-DD>.md` with today's date. If the file exists, merge the new items into it instead of starting over. If `~/documents/workspace/workjournal/daily/` does not exist, create it and tell the user you created it.

## Writing rules

- **Point first.** The first line of each point is the outcome, direct and brief. Sub-bullets add context only if needed.
- **Plain.** Short sentences, one idea each, no jargon. Apply the `bro` skill to keep it simple. Leave out cosmetic changes.
