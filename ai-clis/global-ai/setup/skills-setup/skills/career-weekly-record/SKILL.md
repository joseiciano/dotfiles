---
name: create-weekly-record
description: Create or update the work-journal record for the past week, rolled up from that week's daily records.
argument-hint: "[context]"
disable-model-invocation: true
---

# Create Weekly Record

Arguments: `$ARGUMENTS` is optional `$CONTEXT`: notes on the week.

## Steps

1. Set the window. `$START` is 6 days before today and `$END` is today. Done when both are concrete `YYYY-MM-DD` dates.
2. Read every daily record in `~/documents/workspace/workjournal/daily/` dated from `$START` to `$END`. List the weekdays with no record. Done when every daily in the window is read and the missing weekdays are listed.
3. Fill gaps. For each missing weekday, use the `what-did-i-get-done` skill for that day and mark what it finds `(from commits)`. Done when every missing weekday is backfilled or confirmed empty.
4. Copy [the template](references/template.md) with `$START - $END` in the header. Done when the header is set.
5. Roll up. Merge the dailies, the backfill and `$CONTEXT` into `Things done`: one bullet per piece of work, combining days that advanced the same thing. `Working on` comes from the latest daily's `Working on`, minus anything finished later in the week. Done when every daily item is either merged into a bullet or judged too minor for a weekly.
6. Save it. See [Saving](#saving). Report the file path and the weekdays that had no daily. Done when both are reported.

## Saving

Write to `~/documents/workspace/workjournal/weekly/<START>_<END>.md`. If the file exists, edit it instead of starting over. If `~/documents/workspace/workjournal/weekly/` does not exist, create it and tell the user you created it.

## Writing rules

- **Point first.** The first line of each point is the outcome, direct and brief. Sub-bullets add context only if needed.
- **Plain.** Short sentences, one idea each, no jargon. Apply the `bro` skill to keep it simple.
