# Skills Guide

The following skills are **needed** when referring to code changes. **Always** refer to them for coding changes. 

This document is to give information on the skills available, and guidance on when to use them. 

## Skills

For the skills mentioned below, **Always** use them for the context given under "When to use".

**General**

| Skill | Description | When to use |
|---|---|---|
| [Wrangler](~/.config/opencode/skills/wrangler/SKILL.md) | Best practices for working with Wrangler | Whenever a change involves using Wrangler, modifying Wrangler file for a project |
|[`Cloudflare`](~/.config/opencode/skills/cloudflare/SKILL.md)|Decision tree for calling other Cloudflare skills. | When working on a change involving anything Cloudflare related. |


**Frontend**

| Skill | Description | When to use |
|---|---|---|
|[Smart-Dumb Component Patterns](~/.config/opencode/skills/smart-dumb-component/SKILL.md)| Smart-dumb component pattern for separating business from rendering logic | When implementing logic in frontend codebases. |
|[Tanstack-Start](~/.config/opencode/skills/tanstack-start-best-practices/SKILL.md) | Best practices for working with Tanstack Start | Whenever changes are in a Tanstack-Start based project |
|[Tanstack-Router](~/.config/opencode/skills/tanstack-router-best-practices/SKILL.md) | Tanstack Router best practices | Whenever changes are in a code using Tanstack router |
|[Tanstack-Query](~/.config/opencode/skills/tanstack-query-best-practices/SKILL.md) | Tanstack Query best practices | Whenever changes necessitate speaking to backend from the frontend, when working on a codebase that uses Tanstack Query |
|[Tanstack-Integration](~/.config/opencode/skills/tanstack-integration-best-practices/SKILL.md) | Best practices for integrating Tanstack Query with Tanstack Router and Tanstack Start | When working on codebases that uses Tanstack Router, Tanstack Start, and Tanstack Query |
|[Vercel React Best Practices](~/.config/opencode/skills/vercel-react-best-practices/SKILL.md) | Best practices for working with React | When working on changes in a react codebase. This allows for optimization of the website |
| [Frontend Design](~/.config/opencode/skills/frontend-design/SKILL.md) | Production-grade frontend design patterns and UI polish | When building or refining user-facing interfaces, layouts, pages, and components |
| [Web Design Guidelines](~/.config/opencode/skills/web-design-guidelines/SKILL.md) | Review UI work against web interface and accessibility guidelines | When reviewing UI/UX quality, accessibility, or design compliance |
| [Web Perf](~/.config/opencode/skills/web-perf/SKILL.md) | Analyze and improve web performance using browser metrics | When auditing or optimizing frontend performance, Lighthouse-related issues, or Core Web Vitals |


**Backend**

| Skill | Description | When to use |
|---|---|---|
|[Controller-Service-Repository Patterns](~/.config/opencode/skills/controller-service-repo/SKILL.md)| Controller Service Repository pattern and setup | Working on implementing backend changes.|
| [Better Auth](~/.config/opencode/skills/better-auth-best-practices/SKILL.md) | Best practices for configuring Better Auth server and client | When working with Better Auth setup, adapters, sessions, plugins, or auth environment variables |
|[`Cloudflare`](~/.config/opencode/skills/cloudflare/SKILL.md)|Decision tree for calling other Cloudflare skills. | When working on a change involving anything Cloudflare related. |
| [`Workers`](~/.config/opencode/skills/workers-best-practices/SKILL.md) | Best practices for using cloudflare workers | When working on a change involving a Cloudflare Worker |
| [Durable Objects](~/.config/opencode/skills/durable-objects/SKILL.md) | Best practices for working with Cloudflare Durable OBjects | When working on a Cloudflare Durable Object |
| [Wrangler](~/.config/opencode/skills/wrangler/SKILL.md) | Best practices for working with Wrangler | Whenever a change involves using Wrangler, modifying Wrangler file for a project |
| [Postgres Best Practices](~/.config/opencode/skills/supabase-postgres-best-practices/SKILL.md) | Best practices for SQL operations in Postgres | When working on SQL queries, Database Migrations, Postgres changes |
| [Neon](~/.config/opencode/skills/neon-postgres/SKILL.md) | Best practices for working with Neon Postgres databases | When working on a database hosted by Neon |
| [Neon Postgres Egress Optimizer](~/.config/opencode/skills/neon-postgres-egress-optimizer/SKILL.md) | Reduce excessive Postgres network transfer and overfetching | When investigating high Postgres egress costs or optimizing query payload size |
| [Neon Claimable API](~/.config/opencode/skills/claimable-postgres/SKILL.md) | Best practices for working with Neon's claimable api | When wanting to test a database in a live environment  |
| [Agents SDK](~/.config/opencode/skills/agents-sdk/SKILL.md) | Build stateful Cloudflare agents and agent-powered systems | When building agent workflows, stateful agents, MCP servers, or real-time agent apps on Cloudflare |
| [Cloudflare Email Service](~/.config/opencode/skills/cloudflare-email-service/SKILL.md) | Send and receive email with Cloudflare Email Service | When implementing transactional email, email routing, or email bindings with Cloudflare |
| [Sandbox SDK](~/.config/opencode/skills/sandbox-sdk/SKILL.md) | Build secure sandboxed code execution environments | When implementing secure code execution, interpreters, CI-like sandboxes, or untrusted runtime environments |
| [Test-Driven Development](~/.config/opencode/skills/test-driven-development/SKILL.md) | Write tests first before implementing features or fixes | When implementing backend features or bugfixes where you want a TDD workflow |
