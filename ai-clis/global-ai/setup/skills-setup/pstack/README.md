# pstack (imported)

`how` and `why` imported once from the vendored pstack plugin in `ai-clis/vendor/pstack`,
so the suite no longer depends on pstack being loaded as a Claude Code plugin (`teach`
runs both). These copies are ours to edit; the build does not re-read the vendor copy.

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
