---
name: tanstack
description: >-
  TanStack best practices covering TanStack Query (React Query), TanStack
  Router, TanStack Start, and integrating them together. Routes to rule sets
  for data fetching, caching, mutations, optimistic updates, and server state
  management (Query); type-safe routing, route organization, data loaders,
  search params, navigation, code splitting, and preloading (Router);
  full-stack React apps with server functions, middleware, SSR, authentication,
  API routes, and deployment (Start); and full-stack data flow, SSR query
  hydration, and caching coordination when Query is used with Router or Start
  (Integration). Activate when building data-driven React applications with
  server state, React applications with complex routing needs, or full-stack
  apps with TanStack Start.
references:
  - tanstack-query-best-practices
  - tanstack-router-best-practices
  - tanstack-start-best-practices
  - tanstack-integration-best-practices
---

# TanStack

Router for TanStack best practices. Pick every route that matches the task, then load those guides before you write or review code. Each route is a standard: apply its rules while you write or review code, in priority order (CRITICAL first).

## Routing

### Server state and data fetching → Query

Load `references/tanstack-query-best-practices/guide.md`.

Use when:

- You create or refactor data fetching logic with `useQuery`, `useSuspenseQuery`, `useQueries`, or `useInfiniteQuery`.
- You design query keys, set `staleTime` / `gcTime`, or configure `QueryClient` defaults.
- You implement mutations, optimistic updates, rollback, or invalidation.
- You configure prefetching, infinite queries, SSR dehydration, render performance, or offline support.

### Routing and navigation → Router

Load `references/tanstack-router-best-practices/guide.md`.

Use when:

- You set up application routing, or create routes and layouts (file-based, pathless, index, or virtual routes).
- You register the router type, use `from` narrowing, or type route context.
- You write route loaders, `loaderDeps`, or deferred data.
- You validate or serialize search params, build navigation (`Link`, `useNavigate`, route masks), or configure code splitting and preloading.

### Full-stack apps → Start

Load `references/tanstack-start-best-practices/guide.md`.

Use when:

- You write server functions (`createServerFn`), request or function middleware, or API routes.
- You implement authentication, sessions, cookies, CSRF protection, or route protection.
- You configure SSR, streaming, selective SSR, prerendering, or hydration safety.
- You organize server and client code, manage environment config, or pick a deployment adapter.

### Query with Router or Start → Integration

Load `references/tanstack-integration-best-practices/guide.md` in addition to the product guides above.

Use when:

- You set up a new TanStack Start project.
- You pass `QueryClient` through router context, or wrap with `QueryClientProvider`.
- You call `ensureQueryData` in loaders, or use `useSuspenseQuery` in route components.
- You set up SSR query hydration (`setupRouterSsrQueryIntegration`), coordinate `staleTime` or preloading between router and query, or call server functions from query functions.

## Overlap

- If a topic shows up in a product guide and in the integration guide, and the products are used together, follow the integration rule. Known overlaps:
  - `ensureQueryData` in loaders: Query `pf-ensure-query-data`, Router `load-ensure-query-data`, Integration `flow-loader-query-pattern`.
  - One `QueryClient` per request on the server: Query `ssr-client-per-request`, Integration `ssr-per-request-client`.
  - Query SSR hydration: Query `ssr-dehydration` / `ssr-hydration-boundary`, Integration `ssr-dehydrate-hydrate`.
  - Caching: when Router and Query are used together, Query owns the cache. Turn off Router's preload cache with `defaultPreloadStaleTime: 0` (Integration `cache-single-source`).
- Rule IDs are only unique inside one guide. For example, `err-not-found` exists in both Router and Start. When you cite a rule, name the guide too (e.g. "Start `err-not-found`").

## Shared Rules

Every guide has a "Quick Reference" index of rule IDs. Detailed rules live in `references/<guide>/rules/<rule-id>.md`. Each rule file contains:

1. **Explanation**: why the pattern matters.
2. **Bad Example**: the anti-pattern to avoid.
3. **Good Example**: the recommended implementation.
4. **Context**: when to apply or skip the rule.

Rules marked *(index only)* have no rule file. Apply them from the one-line summary, and check the current TanStack docs if you need detail. Do not go looking for a file that does not exist.
