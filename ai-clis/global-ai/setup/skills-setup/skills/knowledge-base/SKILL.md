---
name: knowledge-base
description: Personal, per-repo knowledge base kept outside the repo in ~/.knowledge — a map of where docs live (in the repo and external, e.g. Confluence, GitHub wiki, Notion), a personal rules file, a glossary, and ADRs. Use for /setup-knowledge-base and /kb, when you learn where something is documented, or when recording an ADR or glossary term in a repo whose team does not own those conventions.
---

# Knowledge Base

A personal KB for one repo. It is never committed to the repo, so teammates never see it, and every harness reads it from the same place.

## Location

Resolve the directory with:

```bash
bash ~/.claude/skills/knowledge-base/scripts/kb-path.sh
```

It prints `~/.knowledge/<host>/<owner>/<repo>`, keyed by the normalized git remote, so all clones and worktrees share it. Set `KNOWLEDGE_BASE_DIR` to move the root. The directory may not exist yet; create it only when you have something to write.

```
<kb>/
  INDEX.md        map: where documentation lives
  RULES.md        personal rules file (context-engineering Level 1, not committed)
  GLOSSARY.md     domain-modeling glossary
  adr/NNNN-slug.md
```

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

### GLOSSARY.md and adr/

Written by `domain-modeling` and `documentation-and-adrs` using their own formats. When this KB exists, those skills write here instead of to the repo's `GLOSSARY.md` and `docs/adr/`. Read the repo's committed ones too if they exist; they are team-owned and take precedence on conflict.

## Operations

### Setup (`/setup-knowledge-base`)

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

Print the KB path and the contents of INDEX.md, plus a list of ADR titles and glossary terms.

### Rule (`/kb rule <text>`)

Add the rule to the right section of RULES.md.

## Ongoing capture

When you find where something is documented during normal work (for example, a `why` investigation lands on a Confluence page), add it to INDEX.md if it is not there, and say so in one line.

RULES.md is the user's standing rules for the repo; the current request overrides it. INDEX.md, GLOSSARY.md, and ADRs are notes: if one conflicts with the code, trust the code and offer to fix the entry.
