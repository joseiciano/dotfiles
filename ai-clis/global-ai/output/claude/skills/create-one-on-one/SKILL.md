---
name: create-one-on-one
description: Create a 1:1 doc with anyone other than your manager from the template, optionally filled from context you pass.
argument-hint: "[name] [context]"
disable-model-invocation: true
---

# Create One-on-One

Arguments: `$ARGUMENTS`. The other person's `$NAME` is a leading quoted string, a `Name: ...` prefix, or else the first word if it reads as a name; the rest is optional `$CONTEXT`.

## Steps

1. Copy [the template](references/template.md). Replace `(Name)` with `$NAME` when one is given; otherwise leave `(Name)` as is. Done when the header is set.
2. Fill sections from `$CONTEXT` only. Place each point from `$CONTEXT` under the section it fits. With no `$CONTEXT`, keep every section as the template's blank prompt. `$CONTEXT` is the only source: look up nothing else. Done when every point in `$CONTEXT` sits under a section, or the template is untouched.
3. Save it. See [Saving](#saving). Done when the file is written and its path is reported.

## Saving

Write to `~/documents/workspace/workjournal/one-on-one/<YYYY-MM-DD>-<name>.md`, using today's date and `$NAME` in lowercase kebab-case (omit `-<name>` with no `$NAME`). If the file exists, edit it instead of starting over. If `~/documents/workspace/workjournal/one-on-one/` does not exist, create it and tell the user you created it.

## Writing rules

- **Point first.** The first line of each point is direct and brief. Sub-bullets add context only if needed.
- **Plain.** Short sentences, one idea each, no jargon.
