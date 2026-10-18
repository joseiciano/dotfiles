---
name: neon
description: >-
  Neon Serverless Postgres skill covering both the Neon platform and Claimable
  Postgres (neon.new). Routes to a procedure for provisioning instant, temporary,
  no-signup Postgres databases (REST API, CLI, SDK, Vite plugin), or to the Neon
  platform guide: getting started, local development, connection methods and
  drivers, Neon Auth (@neondatabase/auth), PostgREST-style data API
  (@neondatabase/neon-js), Neon CLI, Platform API/SDKs, branching, autoscaling,
  scale to zero, read replicas, pooling, and diagnosing/fixing excessive Postgres
  egress. Use for any Neon-related question. Also use when users ask for a quick
  Postgres environment or a throwaway DATABASE_URL ("quick postgres",
  "temporary postgres", "no signup database", "no credit card database",
  "instant DATABASE_URL", "just give me a DB now", "npx neon-new", "neon.new",
  "claimable postgres API"), or mention high database bills, unexpected data
  transfer costs, egress spikes, "why is my Neon bill so high", SELECT *
  optimization, query overfetching, or reviewing query patterns for cost
  efficiency, even if they don't explicitly mention egress.
references:
  - claimable-postgres
  - neon-postgres
---

# Neon

Router for Neon Serverless Postgres. Pick the route below, then load that guide before acting.

## Routing

### "I need a database right now" → Claimable Postgres

Load `references/claimable-postgres/guide.md`.

Use when:

- The user wants a quick, temporary, throwaway, or no-signup Postgres database.
- The user mentions `neon.new`, `npx neon-new`, `neon-new/sdk`, `vite-plugin-neon-new`, or claim URLs.
- A task needs a database (e.g. "build me a todo app with a real database") and the user has not provided a connection string.

This route is a procedure. Follow its agent workflow step by step and finish with its output checklist.

### Everything else Neon → Neon platform

Load `references/neon-postgres/guide.md`, then follow its links to the topic docs.

Use when:

- The user works with an existing or permanent Neon project.
- The question covers architecture, getting started, connection methods and drivers, Neon Auth, the Neon JS SDK / Data API, `neonctl`, the Admin API or SDKs, branching, autoscaling, scale to zero, instant restore, read replicas, pooling, IP allow lists, or logical replication.
- The user has high bills, egress or network transfer spikes, or query overfetching. Go straight to `references/neon-postgres/egress-optimization.md`.

### Overlap

- After a claimable database is claimed, it is a normal Neon project. Use the Neon platform route for anything beyond provisioning.
- For production workloads, recommend standard Neon provisioning (platform route) over a claimable database.

## Shared Rules

- The Neon docs are the source of truth. Fetch any page as markdown by appending `.md` to the URL. Find pages via https://neon.com/docs/llms.txt. Do not guess URLs.
- Hostnames with `-pooler` are pooled connections (use for application queries). Remove `-pooler` for a direct connection (use for migrations, e.g. Prisma).
- Never overwrite an existing `DATABASE_URL` (or other env key) without confirmation. After writing credentials to a `.env` file, check that `.gitignore` covers it.
