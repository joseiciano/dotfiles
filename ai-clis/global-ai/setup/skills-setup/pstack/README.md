# pstack (imported)

`how` and `why` imported once from the vendored pstack plugin in `ai-clis/vendor/pstack`,
so the suite no longer depends on pstack being loaded as a Claude Code plugin (`teach`
runs both). `show-me-your-work` was imported later for the decision trail that `/build auto`
and the `ticket-stack` workflow keep. `create-verification-skill` and `maintain-verification-skill` were moved out of the vendor
copy (not copied) so they list the generated verify skill in the knowledge base. These copies are ours to edit; the build does not re-read the vendor copy.

## Changes from upstream
- Subagents are our agents instead of pstack's `general-purpose` / `poteto-agent-*` /
  `effort-*` dispatch: `how` explorers are `scout`, its explainer is `task`; `why`
  investigators and synthesizer are `task`. Read-only behavior is an instruction.
- Removed the `pstack-models.md` model override sheet and the reasoning-effort sections;
  each agent's per-harness model settings apply instead.
- Removed `how`'s Codex and Copilot platform-mapping links (to pstack's `poteto-mode`).
- `why`'s MCP discovery is worded for any harness, not just Claude Code.
- Restored `why/references/sources/` playbooks (linear, notion, slack, datadog, sentry,
  databricks) from git (`630155c`); they had been deleted from the vendor copy but
  `source-playbook.md` links to them.
- `show-me-your-work` is trimmed for `/build auto` and `ticket-stack`: the log lives in the
  work item's `decisions.tsv` in the knowledge base instead of the working directory; the
  transcript audit and the mandatory cross-model review are removed (ticket-stack already
  reviews each ticket), replaced by a reread of the run's own rows before handing back;
  `references/decision-log-template.tsv` is dropped because `log.sh` writes the header; the
  link to pstack's `encode-lessons-in-structure` is removed.
- `create-verification-skill` step 5 and `maintain-verification-skill` step 7 write a
  `## Verification Processes` section to the knowledge base's INDEX.md.
