---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document that lets a fresh agent, with none of this conversation in context, continue the work.

1. **Set the focus.** If the user passed arguments, they describe what the next session will work on: tailor every section to that focus. With no arguments, the focus is the work in progress at the end of this conversation.
2. **Collect pointers.** List every artifact this conversation produced or relied on (specs, plans, ADRs, issues, commits, diffs, PRs) by path or URL. The handoff points at these; their content stays in them. Done when every artifact the next agent needs to open is on the list.
3. **Draft from the template.** Fill [`references/handoff-template.md`](references/handoff-template.md) section by section. Done when every section is filled or marked `None`, and every decision carries its reason.
4. **Redact.** Replace API keys, passwords, tokens, and personally identifiable information with `<redacted>`.
5. **Save.** Write the file to the OS temporary directory (`$TMPDIR`, else `/tmp`; `%TEMP%` on Windows), outside the workspace, named `handoff-<topic>-<YYYYMMDD-HHMM>.md`. Reply with its absolute path.
