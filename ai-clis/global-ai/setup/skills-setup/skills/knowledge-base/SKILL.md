---
name: knowledge-base
description: Personal, per-repo knowledge base kept outside the repo in ~/.knowledge — a map of where docs live (in the repo and external, e.g. Confluence, GitHub wiki, Notion), a personal rules file, ADRs, CONSTRAINTS.md, and per-work-item specs, plans and task lists. Use for /setup-knowledge-base, /kb and /kb dashboard, when you learn where something is documented, or before writing an ADR, spec, plan, task list or CONSTRAINTS.md, all of which go here instead of the repo.
---

# Knowledge Base

A personal KB for one repo. It is never committed to the repo, so teammates never see it, and every harness reads it from the same place. Every clone and worktree of the repo shares one KB.

## Location

Resolve the directory with:

```bash
bash ~/.claude/skills/knowledge-base/scripts/kb-path.sh
```

It prints `~/.knowledge/<host>/<owner>/<repo>`, keyed by the normalized git remote, so all clones and worktrees share it. Set `KNOWLEDGE_BASE_DIR` to move the root. The directory may not exist yet; create it when you have something to write.

```
<kb>/
  INDEX.md          map: where documentation lives
  RULES.md          personal rules file (context-engineering Level 1, not committed)
  CONSTRAINTS.md    constraint-driven-development quality bar
  adr/NNNN-slug.md
  work/<slug>/      one work item: SPEC.md, plan.md, todo.md
    decisions.tsv   show-me-your-work decision log for unattended runs
    MAP.md          capability map, only when the work is split into modules
    <module>/       one module: SPEC.md, plan.md, todo.md
```

## Where repo docs go instead

Other skills name repo paths. Write these to the KB instead, whether or not the KB exists yet:

| Skill's repo path | KB path |
|---|---|
| `docs/adr/`, `docs/decisions/` | `<kb>/adr/` |
| `GLOSSARY.md` (and `<context>/GLOSSARY.md`) | `<kb>/GLOSSARY.md` (`<kb>/<context>/GLOSSARY.md`) |
| `CONSTRAINTS.md` | `<kb>/CONSTRAINTS.md` |
| `SPEC.md`, `tasks/plan.md`, `tasks/todo.md` | `<work>/SPEC.md`, `<work>/plan.md`, `<work>/todo.md` |
| capability map, `SPEC-<module>.md` | `<kb>/work/<slug>/MAP.md`, `<kb>/work/<slug>/<module>/SPEC.md` |
| a line added to `CLAUDE.md` / `AGENTS.md` | a line in `<kb>/RULES.md` |

KB files are outside the repo: never `git add` or commit them. Read the repo's committed copies too if they exist; they are team-owned and take precedence on conflict, and editing a file git already tracks stays in the repo. Write to the repo only when the user asks for the repo copy.

In Claude Code a PreToolUse hook enforces this: a new, untracked repo file on the list is refused with its KB path. Starting Claude Code with `KB_ALLOW_REPO_DOCS=1` turns the hook off.

## Work items

A work item is one piece of work with its own spec, plan and task list. `<work>` is its directory: `<kb>/work/<slug>/`, or `<kb>/work/<slug>/<module>/` when the work is split into modules.

Find the work item for the current branch with:

```bash
bash ~/.claude/skills/knowledge-base/scripts/kb-work.sh
```

It prints every work item (or module) whose `plan.md` frontmatter lists the checked-out branch:

```markdown
---
branches: [feat/billing-api, feat/billing-api-2]
---
```

- One line: use it.
- Several lines: ask the user which one this task is for.
- None: ask whether to create a new work item (default slug: the branch name, with `/` replaced by `-`) or attach the branch to an existing one. Create `plan.md` with the branch in `branches:` when you create the work item, before the spec is written, so the next session finds it.
- Detached HEAD prints nothing: ask which work item.

A branch may belong to several work items, and a work item may span several branches (stacked PRs): append each new branch to `branches:`.

When `spec-driven-development` splits the work into modules (its Phase 0), save the approved capability map as `<kb>/work/<slug>/MAP.md` and give each module its own directory named by its module id. Each module's `plan.md` lists the branches building that module. The interface between two modules (an API, a queue message contract) lives in the providing module's `SPEC.md`; the consumer links to it.

## Files

### INDEX.md

A map, not a copy. One line per source: what it covers, then where it is. Group by area.

```markdown
# <repo> knowledge index

## In repo
- Architecture overview — `docs/architecture.md`
- API contracts — `packages/api/openapi.yaml`

## External
- Payments runbooks — Confluence space PAY (https://…)
- Incident postmortems — Notion › Engineering › Postmortems
- Product specs — GitHub wiki https://github.com/acme/billing/wiki

## Access
- Confluence: via the atlassian MCP (`mcp__atlassian__*`)
```

Rules:
- Link to the source; never paste its contents.
- Note which MCP or CLI can read each external source, if one exists.
- Keep it under ~100 lines. It is read at the start of every session.

### RULES.md

The rules file `context-engineering` describes (tech stack, commands, conventions, boundaries, patterns), for this user only. Follow that skill's Level 1 template. Do not duplicate what a committed CLAUDE.md or AGENTS.md already says.

### adr/, CONSTRAINTS.md, work/

Written by `documentation-and-adrs`, `constraint-driven-development`, `spec-driven-development`, `planning-and-task-breakdown` and `show-me-your-work` using their own formats, at the KB paths in the table above.

`CONSTRAINTS.md` in the KB is enforced by the agent only: run the commands it lists, and do not add check scripts to the repo's `package.json` or CI unless the user asks. Add `Read <kb>/CONSTRAINTS.md before writing code. Do not weaken it to make a change pass.` to RULES.md.

## Operations

### Setup (`/setup-knowledge-base`)

Run this when the user asks, and also, without waiting to be asked, when you find the KB has no INDEX.md (the write hook says so). Do steps 1–3 and 5's INDEX.md without asking anything, then ask step 4's question and show the RULES.md draft.

1. Resolve the KB path. If it already has files, read them and update rather than overwrite.
2. Scan the repo for documentation: README files, `docs/`, ADR folders (`docs/adr`, `docs/decisions`, `.adr-dir`), `CONTRIBUTING.md`, CLAUDE.md / AGENTS.md, OpenAPI / schema files, runbooks. Skip `node_modules`, build output, and vendored code.
3. List connected MCP servers and CLIs (`gh`, Confluence, Notion, Linear, etc.) that can reach external docs.
4. Ask the user, in one message, where external documentation lives (Confluence spaces, wikis, Notion pages, Google Drive folders, team channels). Offer what step 3 found as a starting point. Accept "none".
5. Write INDEX.md. Draft RULES.md from what the repo shows (stack, commands, conventions) and show it to the user before writing; skip it if they decline.
6. If the KB root (`~/.knowledge` or `$KNOWLEDGE_BASE_DIR`) is not a git repo, offer to `git init` it so the KB can sync across machines. Leave adding a remote to the user: the KB holds internal URLs, so it must be private.
7. Report the KB path and what was written.

### Add (`/kb add <pointer>`)

Append one line to the right section of INDEX.md. If the pointer is ambiguous (no location, or unclear area), ask one question. Do not add duplicates; update the existing line instead.

### Show (`/kb` or `/kb show`)

Print the KB path and the contents of INDEX.md, plus a list of ADR titles and work items with their branches.

### Rule (`/kb rule <text>`)

Add the rule to the right section of RULES.md.

### Dashboard (`/kb dashboard`)

Start the local dashboard and give the user its URL:

```bash
bash ~/.claude/skills/knowledge-base/scripts/kb-dashboard.sh --open
```

It shows every KB under the root, opened on this repo's, and renders INDEX.md, RULES.md, ADRs and work items (task progress, branches, decision logs). Markdown files are editable in place and todo checkboxes toggle; `decisions.tsv` is read-only. The server (bun, 127.0.0.1 only, port `$KB_DASHBOARD_PORT` or 4777) keeps running in the background and is reused on the next call; `--stop` stops it. The UI is `dashboard/index.html`; change it there, not per run.

## Ongoing capture

When you find where something is documented during normal work (for example, a `why` investigation lands on a Confluence page), add it to INDEX.md if it is not there, and say so in one line.

RULES.md is the user's standing rules for the repo; the current request overrides it. INDEX.md, ADRs, specs and plans are notes: if one conflicts with the code, trust the code and offer to fix the entry.
