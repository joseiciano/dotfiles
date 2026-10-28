---
name: why
description: "Investigates why code is the way it is: design rationale, tradeoffs, regressions, postmortems, data-backed thresholds. Use for \"why does X work this way\" or \"why did we pick Y\". Queries every available evidence source in parallel and returns a cited read. Use how for runtime behavior."
---

# Why

Investigate the motivation and intent behind code. The companion `how` skill answers what the code does and how it works. `why` answers what forces led to its shape.

Spawn every investigator and the synthesizer as a `task` subagent, not a read-only agent: read-only agents may lack MCP access, which disables the MCP-backed investigators and the synthesizer's citation spot-checks. Tell each one to read only, leaving every file unedited.

Every claim carries its confidence. `references/epistemics.md` is the confidence framework and phrasing guide; the synthesizer follows it, and so do you when you present.

## Step 1. Understand the Target and the Question

The **target** is usually a chunk of code, a pattern, a feature, or a named design decision. The **question** is usually a design rationale, a tradeoff, a motivating edge case, an external constraint, dead code, or a broad history sweep.

If the target is vague ("why do we do it this way?" with no clear referent), make your best guess from conversation context (open files, recent edits, cursor location, what was just discussed). State your interpretation briefly so the user can redirect, then proceed.

## Step 2. Establish the Code Anchor

Before spawning investigators, build the seed context inline. The anchor goes to every investigator and to the synthesizer, and holds:

- file paths and line ranges, and key symbols (functions, classes, constants)
- the commits that shaped the target, traced back through renames (`git log --follow`, `git blame -L`) past the most recent one: the current shape is often the accretion of many earlier decisions
- PR numbers from merge commits (pattern `(#1234)` in the subject line) and any linked ticket IDs
- the body and discussion of each substantive PR: `gh pr view <number> --json title,body,author,createdAt,mergedAt,labels,closingIssuesReferences,comments,reviews`

## Step 3. Spawn Parallel Investigators

**Default to the full parallel investigation.** The goal is a complete coverage map: document the null rather than skip the search.

### Discovery

List the MCP servers available in this session. Use your tool list (MCP tools are named after their server, e.g. `mcp__<server>__<name>` in Claude Code). Otherwise read the harness's MCP config (`.mcp.json`, the `mcp` section of `opencode.json`, or oh-my-pi's config), or run `claude mcp list` on Claude Code.

Map each available MCP to one evidence category from the roster below, classifying by the MCP name, server instructions, tool names, and resource descriptors. If an MCP could fit more than one category, choose the one matching its primary evidence, and record the ambiguity in the coverage map.

Spawn one investigator per category that has a matching MCP, all in a single message so they run concurrently, each owning exactly one tool or MCP.

Each investigator's prompt is `references/investigator-prompt.md` filled in, plus:
- the category playbook `references/sources/<source>.md` for the selected MCP, adapted from the examples in `references/source-playbook.md`
- `references/sources/incident-postmortem.md` **if the target code looks defensive** (null checks, retry logic, timeout handling, rate limiting, feature flags, egress guards, OOM handlers)
- the code anchor and the user's original question

### Investigator roster, one per available evidence category

Each category is uniquely positioned to surface one shape of "why", shown after "Best at". Use it to know what to expect back, to name a gap when a category returns empty, and, only in the rare provably-irrelevant case, to justify a skip.

1. **Source control** (git history, `gh` for PRs, code comments, tests). Always spawn: always available through git and `gh`, the only guaranteed source. Best at *implementation-time rationale captured during review*.
2. **Issue / ticket tracker** (e.g. Linear, Jira, GitHub Issues, Plane, Shortcut MCP). Best at *the product or business forcing function*. Strongest when the why is external to engineering.
3. **Long-form documents** (e.g. Notion, Confluence, Google Docs, Coda MCP). Best at *long-form design rationale*, written out before it becomes code.
4. **Real-time team chat** (e.g. Slack, Discord, Microsoft Teams, Mattermost MCP). Best at *real-time deliberation that never reached a doc*. Especially important when the source control, ticket, and doc paper trail is thin.
5. **Infrastructure observability** (e.g. Datadog, New Relic, Honeycomb, Grafana, Splunk MCP). Best at *infrastructure and runtime reality that motivated the code*. Strongest when the target reacts to an infra signal (timeouts, retries, rate limits, circuit breakers).
6. **Error / exception tracking** (e.g. Sentry, Rollbar, Bugsnag, Airbrake MCP). Best at *the specific exceptions and error trajectories that motivated defensive or corrective code*. Strongest for catch blocks, null guards, type checks, retries, and other defenses.
7. **Product analytics warehouse** (e.g. Databricks, Snowflake, BigQuery, ClickHouse, dbt, Redshift MCP). Best at *product and data reality that shaped the code*. Strongest for flag-gated code, experiment-driven ships, data migrations, and "where did this number come from" questions.

### When to skip an investigator

Only with an **explicit, written justification** that goes in the final Sources Consulted. Two valid reasons:

- **No MCP is available for that category** in this environment. Flag it as a gap, not a choice: "Real-time team chat skipped. No matching MCP available, so the conversational record was not searchable."
- **The source is provably irrelevant**, not just "probably irrelevant." A high bar: "Error / exception tracking skipped. Target is a build-time script with no runtime code path."

If the target is a single-commit trivial change whose PR description already contains the complete answer, you may answer inline **only after** confirming every available category search would be redundant. Say so explicitly. This should be rare.

## Step 4. Synthesize

Spawn one synthesizer. It gets:
1. The investigator findings, including any null results and any categories skipped with justification
2. The code anchor
3. The user's original question
4. The epistemics framework from `references/epistemics.md`
5. The synthesizer prompt template from `references/synthesizer-prompt.md`

## Step 5. Present

Present the synthesizer's output in the structure `references/synthesizer-prompt.md` defines. Light edits for clarity or added context from the conversation are fine; keep the confidence language exactly as the synthesizer wrote it, the confidence separation intact, and Sources Consulted as one line per investigator, including the ones that returned nothing or were skipped, with the reason.

After Sources Consulted, if the user's `why` question is a precursor to changing this code, convert the lineage findings into a Preserve / Change / Avoid / Risk constraint set for planning the change.
