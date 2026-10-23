---
name: create-manager-one-on-one
description: Create the weekly 1:1 doc with your manager, filled from work done since last Monday plus any context you pass.
argument-hint: "[manager name] [context]"
disable-model-invocation: true
---

# Create Manager One-on-One

Arguments: `$ARGUMENTS`. The manager's `$NAME` is a leading quoted string, a `Name: ...` prefix, or else the first word if it reads as a name; the rest is optional `$CONTEXT`.

## Steps

1. Set the window. `$START` is the most recent Monday before today; run on a Monday, it is the Monday a week earlier. `$END` is today. Done when both are concrete `YYYY-MM-DD` dates.
2. Gather the work done from `$START` to `$END`. Read every source:
   - `$CONTEXT`, which wins over every other source when they conflict.
   - Daily and weekly records in `~/documents/workspace/workjournal/daily/` and `weekly/` dated in the window.
   - Commits, via the `what-did-i-get-done` skill for the window.
   - PRs you opened or reviewed across repos: `gh search prs --author=@me --updated=">=$START"` and `gh search prs --reviewed-by=@me --updated=">=$START"`.

   Done when every source has been read or noted as missing.
3. Copy [the template](references/template.md). Replace `(Name)` with `$NAME` when one is given, and `date` in the Status Updates header with `$END`. Done when the header is set.
4. Fill each section with the few points that matter most to a manager, under the [caps](#caps). A section with nothing worth raising gets `- None this week.` Done when every section is filled or marked empty, and every cap holds.
5. Save it. See [Saving](#saving). Done when the file is written and its path is reported.

## Caps

- At most 5 bullets per section. FYIs stays at 3 or fewer.
- At most 2 sub-bullets per bullet. Use one only when the bullet cannot stand alone.
- The Status Updates table has one row per active project, each cell a short phrase.
- Each bullet is one line: the outcome, plus a metric or link when there is one. Leave out the how.

## Saving

Write to `~/documents/workspace/workjournal/manager-one-on-one/<END>.md`. If the file exists, edit it instead of starting over. If `~/documents/workspace/workjournal/manager-one-on-one/` does not exist, create it and tell the user you created it.

## Writing rules

- **Point first.** The first line of each point is direct and brief.
- **Plain.** Short sentences, one idea each, no jargon. Apply the `bro` skill to keep it simple.
