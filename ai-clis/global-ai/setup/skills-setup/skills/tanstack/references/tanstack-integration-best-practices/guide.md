# TanStack Integration Best Practices

Guidelines for integrating TanStack Query, Router, and Start together effectively. These patterns ensure optimal data flow, caching coordination, and type safety across the stack.

## When to Apply

- Setting up a new TanStack Start project
- Integrating TanStack Query with TanStack Router
- Configuring SSR with query hydration
- Coordinating caching between router and query
- Setting up type-safe data fetching patterns

## Rule Categories by Priority

| Priority | Category | Rules | Impact |
|----------|----------|-------|--------|
| CRITICAL | Setup | 3 rules | Foundational configuration |
| CRITICAL | SSR Integration | 1 rule | Router + Query SSR setup |
| HIGH | Data Flow | 4 rules | Correct data fetching patterns |
| MEDIUM | Caching | 3 rules | Performance optimization |
| MEDIUM | SSR | 2 rules | Additional SSR patterns |

## Quick Reference

### Setup (Prefix: `setup-`)

- `setup-query-client-context` — Pass QueryClient through router context
- `setup-provider-wrapping` — Correctly wrap with QueryClientProvider *(index only)*
- `setup-stale-time-coordination` — Coordinate staleTime between router and query *(index only)*

### Data Flow (Prefix: `flow-`)

- `flow-loader-query-pattern` — Use loaders with ensureQueryData
- `flow-suspense-query-component` — Use useSuspenseQuery in components *(index only)*
- `flow-mutations-invalidation` — Coordinate mutations with query invalidation *(index only)*
- `flow-server-functions-queries` — Use server functions for query functions *(index only)*

### Caching (Prefix: `cache-`)

- `cache-single-source` — Let TanStack Query manage caching
- `cache-preload-coordination` — Coordinate preloading between router and query *(index only)*
- `cache-invalidation-patterns` — Unified invalidation patterns *(index only)*

### SSR Integration (Prefix: `ssr-`)

- `ssr-dehydrate-hydrate` — Use setupRouterSsrQueryIntegration for automatic SSR

### Additional SSR (Prefix: `ssr-`)

- `ssr-per-request-client` — Create QueryClient per request *(index only)*
- `ssr-streaming-queries` — Handle streaming with queries *(index only)*

## Rule Files

Detailed rules live in `rules/<rule-id>.md`, next to this guide. The rule format and the *(index only)* marker are explained in the wrapper `SKILL.md`.
