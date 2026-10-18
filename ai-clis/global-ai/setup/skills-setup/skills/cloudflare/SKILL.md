---
name: cloudflare
description: Comprehensive Cloudflare platform skill covering Workers, Pages, storage (KV, D1, R2), AI (Workers AI, Vectorize, Agents SDK), Durable Objects, Sandbox SDK, Email Service, networking (Tunnel, Spectrum), security (WAF, DDoS), infrastructure-as-code (Terraform, Pulumi), and the Wrangler CLI. Use for any Cloudflare development task — including writing new Workers, reviewing Worker code, configuring wrangler.jsonc, or checking for common Workers anti-patterns (streaming, floating promises, global state, secrets, bindings, observability) — plus stateful agents, MCP servers, chat/voice agents, Durable Objects (RPC, SQLite, alarms, WebSockets, Vitest testing), sandboxed/untrusted code execution and code interpreters, and transactional email (sending, routing, SPF/DKIM/DMARC deliverability) — and load before running wrangler commands to ensure correct syntax and best practices. Biases towards retrieval from Cloudflare docs over pre-trained knowledge.
references:
  - wrangler
  - workers
  - pages
  - d1
  - durable-objects
  - agents-sdk
  - sandbox
  - email-service
  - workers-ai
---

# Cloudflare Platform Skill

Consolidated skill for building on the Cloudflare platform. Use decision trees below to find the right product, then load detailed references.

Your knowledge of Cloudflare APIs, types, limits, and pricing may be outdated. **Prefer retrieval over pre-training** — the references in this skill are starting points, not source of truth.

## Retrieval Sources

Fetch the **latest** information before citing specific numbers, API signatures, or configuration options. Do not rely on baked-in knowledge or these reference files alone.

| Source | How to retrieve | Use for |
|--------|----------------|---------|
| Cloudflare docs | `cloudflare-docs` search tool or `https://developers.cloudflare.com/` | Limits, pricing, API reference, compatibility dates/flags |
| Workers best practices | `https://developers.cloudflare.com/workers/best-practices/workers-best-practices/` | Canonical rules, patterns, anti-patterns |
| Wrangler docs | `https://developers.cloudflare.com/workers/wrangler/` | CLI commands, flags, config reference |
| Workers types | `npm pack @cloudflare/workers-types` or check `node_modules` | Type signatures, binding shapes, handler types |
| Wrangler config schema | `node_modules/wrangler/config-schema.json` | Config fields, binding shapes, allowed values |
| Product changelogs | `https://developers.cloudflare.com/changelog/` | Recent changes to limits, features, deprecations |

When a reference file and the docs disagree, **trust the docs**. This is especially important for: numeric limits, pricing tiers, type signatures, and configuration options.

## Quick Decision Trees

### "I need to run a wrangler command"

→ `references/wrangler/commands.md` (full CLI reference) · `references/wrangler/configuration.md` (wrangler.jsonc, bindings) · `references/wrangler/gotchas.md` (troubleshooting)

### "I need to write or review Workers code"

→ `references/workers/best-practices.md` (rules quick reference, anti-patterns, review workflow) · `references/workers/rules.md` (full rules with code examples) · `references/workers/review.md` (type/config validation, review process)

### "I need a product-specific SDK guide"

Start with the guide file, then follow its links to sibling files in the same directory.

| Building... | Start here |
|-------------|------------|
| Stateful AI agents, chat agents, MCP servers, voice/browser agents | `references/agents-sdk/sdk-guide.md` |
| Durable Objects (RPC, SQLite, alarms, WebSockets, Vitest) | `references/durable-objects/skill-guide.md` |
| Sandboxed / untrusted code execution, code interpreters | `references/sandbox/sdk-guide.md` |
| Sending or receiving email | `references/email-service/README.md` |

### "I need to run code"

```
Need to run code?
├─ Serverless functions at the edge → workers/
├─ Full-stack web app with Git deploys → pages/
├─ Stateful coordination/real-time → durable-objects/
├─ Long-running multi-step jobs → workflows/
├─ Run containers → containers/
├─ Multi-tenant (customers deploy code) → workers-for-platforms/
├─ Scheduled tasks (cron) → cron-triggers/
├─ Lightweight edge logic (modify HTTP) → snippets/
├─ Process Worker execution events (logs/observability) → tail-workers/
└─ Optimize latency to backend infrastructure → smart-placement/
```

### "I need to store data"

```
Need storage?
├─ Key-value (config, sessions, cache) → kv/
├─ Relational SQL → d1/ (SQLite) or hyperdrive/ (existing Postgres/MySQL)
├─ Object/file storage (S3-compatible) → r2/
├─ Versioned file trees (repos, build outputs, checkpoints) → artifacts/
├─ Message queue (async processing) → queues/
├─ Vector embeddings (AI/semantic search) → vectorize/
├─ Strongly-consistent per-entity state → durable-objects/ (DO storage)
├─ Secrets management → secrets-store/
├─ Streaming ETL to R2 → pipelines/
└─ Persistent cache (long-term retention) → cache-reserve/
```

### "I need AI/ML"

```
Need AI?
├─ Run inference (LLMs, embeddings, images) → workers-ai/
├─ Vector database for RAG/search → vectorize/
├─ Build stateful AI agents → agents-sdk/
├─ Gateway for any AI provider (caching, routing) → ai-gateway/
└─ AI-powered search widget → ai-search/
```

### "I need networking/connectivity"

```
Need networking?
├─ Expose local service to internet → tunnel/
├─ TCP/UDP proxy (non-HTTP) → spectrum/
├─ WebRTC TURN server → turn/
├─ Private network connectivity → network-interconnect/
├─ Optimize routing → argo-smart-routing/
├─ Optimize latency to backend (not user) → smart-placement/
└─ Real-time video/audio → realtimekit/ or realtime-sfu/
```

### "I need security"

```
Need security?
├─ Web Application Firewall → waf/
├─ DDoS protection → ddos/
├─ Bot detection/management → bot-management/
├─ API protection → api-shield/
├─ CAPTCHA alternative → turnstile/
└─ Credential leak detection → waf/ (managed ruleset)
```

### "I need media/content"

```
Need media?
├─ Image optimization/transformation → images/
├─ Video streaming/encoding → stream/
├─ Browser automation/screenshots → browser-rendering/
└─ Third-party script management → zaraz/
```

### "I need analytics/metrics data"

```
Need analytics?
├─ Query across all Cloudflare products (HTTP, Workers, DNS, etc.) → graphql-api/
├─ Custom high-cardinality metrics from Workers → analytics-engine/
├─ Client-side (RUM) performance data → web-analytics/
├─ Workers Logs and real-time debugging → observability/
└─ Raw logs (Logpush to external tools) → Cloudflare docs
```

### "I need email"

```
Need email?
├─ Send transactional email (Workers binding or REST API) → email-service/
├─ Receive/forward inbound email → email-service/routing.md or email-routing/
├─ Process inbound email in a Worker → email-workers/
├─ Email from an Agents SDK agent → agents-sdk/email.md + email-service/sending.md
└─ Deliverability (SPF/DKIM/DMARC) → email-service/deliverability.md
```

### "I need infrastructure-as-code"

```
Need IaC? → pulumi/ (Pulumi), terraform/ (Terraform), or api/ (REST API)
```

## Product Index

### Compute & Runtime
| Product | Reference |
|---------|-----------|
| Workers | `references/workers/` |
| Pages | `references/pages/` |
| Pages Functions | `references/pages-functions/` |
| Durable Objects | `references/durable-objects/` (start: `skill-guide.md`) |
| Workflows | `references/workflows/` |
| Containers | `references/containers/` |
| Workers for Platforms | `references/workers-for-platforms/` |
| Cron Triggers | `references/cron-triggers/` |
| Tail Workers | `references/tail-workers/` |
| Snippets | `references/snippets/` |
| Smart Placement | `references/smart-placement/` |

### Storage & Data
| Product | Reference |
|---------|-----------|
| KV | `references/kv/` |
| D1 | `references/d1/` |
| R2 | `references/r2/` |
| Artifacts | `references/artifacts/` |
| Queues | `references/queues/` |
| Hyperdrive | `references/hyperdrive/` |
| DO Storage | `references/do-storage/` |
| Secrets Store | `references/secrets-store/` |
| Pipelines | `references/pipelines/` |
| R2 Data Catalog | `references/r2-data-catalog/` |
| R2 SQL | `references/r2-sql/` |

### AI & Machine Learning
| Product | Reference |
|---------|-----------|
| Workers AI | `references/workers-ai/` |
| Vectorize | `references/vectorize/` |
| Agents SDK | `references/agents-sdk/` (start: `sdk-guide.md`) |
| AI Gateway | `references/ai-gateway/` |
| AI Search | `references/ai-search/` |

### Networking & Connectivity
| Product | Reference |
|---------|-----------|
| Tunnel | `references/tunnel/` |
| Spectrum | `references/spectrum/` |
| TURN | `references/turn/` |
| Network Interconnect | `references/network-interconnect/` |
| Argo Smart Routing | `references/argo-smart-routing/` |
| Workers VPC | `references/workers-vpc/` |

### Security
| Product | Reference |
|---------|-----------|
| WAF | `references/waf/` |
| DDoS Protection | `references/ddos/` |
| Bot Management | `references/bot-management/` |
| API Shield | `references/api-shield/` |
| Turnstile | `references/turnstile/` |

### Media & Content
| Product | Reference |
|---------|-----------|
| Images | `references/images/` |
| Stream | `references/stream/` |
| Browser Rendering | `references/browser-rendering/` |
| Zaraz | `references/zaraz/` |

### Real-Time Communication
| Product | Reference |
|---------|-----------|
| RealtimeKit | `references/realtimekit/` |
| Realtime SFU | `references/realtime-sfu/` |

### Developer Tools
| Product | Reference |
|---------|-----------|
| Wrangler | `references/wrangler/` |
| Miniflare | `references/miniflare/` |
| C3 | `references/c3/` |
| Observability | `references/observability/` |
| GraphQL Analytics API | `references/graphql-api/` |
| Analytics Engine | `references/analytics-engine/` |
| Web Analytics | `references/web-analytics/` |
| Sandbox | `references/sandbox/` (start: `sdk-guide.md`) |
| Workerd | `references/workerd/` |
| Workers Playground | `references/workers-playground/` |

### Infrastructure as Code
| Product | Reference |
|---------|-----------|
| Pulumi | `references/pulumi/` |
| Terraform | `references/terraform/` |
| API | `references/api/` |

### Other Services
| Product | Reference |
|---------|-----------|
| Email Service (Sending + Routing) | `references/email-service/` |
| Email Routing | `references/email-routing/` |
| Email Workers | `references/email-workers/` |
| Static Assets | `references/static-assets/` |
| Bindings | `references/bindings/` |
| Cache Reserve | `references/cache-reserve/` |
