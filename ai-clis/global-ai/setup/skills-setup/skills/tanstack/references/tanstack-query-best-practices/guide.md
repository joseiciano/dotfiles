# TanStack Query Best Practices

Comprehensive guidelines for implementing TanStack Query (React Query) patterns in React applications. These rules optimize data fetching, caching, mutations, and server state synchronization.

## When to Apply

- Creating new data fetching logic
- Setting up query configurations
- Implementing mutations and optimistic updates
- Configuring caching strategies
- Integrating with SSR/SSG
- Refactoring existing data fetching code

## Rule Categories by Priority

| Priority | Category | Rules | Impact |
|----------|----------|-------|--------|
| CRITICAL | Query Keys | 5 rules | Prevents cache bugs and data inconsistencies |
| CRITICAL | Caching | 5 rules | Optimizes performance and data freshness |
| HIGH | Mutations | 6 rules | Ensures data integrity and UI consistency |
| HIGH | Error Handling | 3 rules | Prevents poor user experiences |
| MEDIUM | Prefetching | 4 rules | Improves perceived performance |
| MEDIUM | Parallel Queries | 2 rules | Enables dynamic parallel fetching |
| MEDIUM | Infinite Queries | 3 rules | Prevents pagination bugs |
| MEDIUM | SSR Integration | 4 rules | Enables proper hydration |
| LOW | Performance | 4 rules | Reduces unnecessary re-renders |
| LOW | Offline Support | 2 rules | Enables offline-first patterns |

## Quick Reference

### Query Keys (Prefix: `qk-`)

- `qk-array-structure` — Always use arrays for query keys
- `qk-include-dependencies` — Include all variables the query depends on
- `qk-hierarchical-organization` — Organize keys hierarchically (entity → id → filters)
- `qk-factory-pattern` — Use query key factories for complex applications
- `qk-serializable` — Ensure all key parts are JSON-serializable

### Caching (Prefix: `cache-`)

- `cache-stale-time` — Set appropriate staleTime based on data volatility
- `cache-gc-time` — Configure gcTime for inactive query retention
- `cache-defaults` — Set sensible defaults at QueryClient level *(index only)*
- `cache-invalidation` — Use targeted invalidation over broad patterns
- `cache-placeholder-vs-initial` — Understand placeholder vs initial data differences

### Mutations (Prefix: `mut-`)

- `mut-invalidate-queries` — Always invalidate related queries after mutations
- `mut-optimistic-updates` — Implement optimistic updates for responsive UI
- `mut-rollback-context` — Provide rollback context from onMutate *(index only)*
- `mut-error-handling` — Handle mutation errors gracefully *(index only)*
- `mut-loading-states` — Use isPending for mutation loading states *(index only)*
- `mut-mutation-state` — Use useMutationState for cross-component tracking

### Error Handling (Prefix: `err-`)

- `err-error-boundaries` — Use error boundaries with useQueryErrorResetBoundary
- `err-retry-config` — Configure retry logic appropriately *(index only)*
- `err-fallback-data` — Provide fallback data when appropriate *(index only)*

### Prefetching (Prefix: `pf-`)

- `pf-intent-prefetch` — Prefetch on user intent (hover, focus)
- `pf-route-prefetch` — Prefetch data during route transitions *(index only)*
- `pf-stale-time-config` — Set staleTime when prefetching *(index only)*
- `pf-ensure-query-data` — Use ensureQueryData for conditional prefetching *(index only)*

### Infinite Queries (Prefix: `inf-`)

- `inf-page-params` — Always provide getNextPageParam
- `inf-loading-guards` — Check isFetchingNextPage before fetching more *(index only)*
- `inf-max-pages` — Consider maxPages for large datasets *(index only)*

### SSR Integration (Prefix: `ssr-`)

- `ssr-dehydration` — Use dehydrate/hydrate pattern for SSR
- `ssr-client-per-request` — Create QueryClient per request *(index only)*
- `ssr-stale-time-server` — Set higher staleTime on server *(index only)*
- `ssr-hydration-boundary` — Wrap with HydrationBoundary *(index only)*

### Parallel Queries (Prefix: `parallel-`)

- `parallel-use-queries` — Use useQueries for dynamic parallel queries
- `query-cancellation` — Implement query cancellation properly

### Performance (Prefix: `perf-`)

- `perf-select-transform` — Use select to transform/filter data
- `perf-structural-sharing` — Leverage structural sharing *(index only)*
- `perf-notify-change-props` — Limit re-renders with notifyOnChangeProps *(index only)*
- `perf-placeholder-data` — Use placeholderData for instant UI *(index only)*

### Offline Support (Prefix: `offline-`)

- `network-mode` — Configure network mode for offline support
- `persist-queries` — Configure query persistence for offline support

## Rule Files

Detailed rules live in `rules/<rule-id>.md`, next to this guide. The rule format and the *(index only)* marker are explained in the wrapper `SKILL.md`.
