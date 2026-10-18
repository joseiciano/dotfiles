# TanStack Router Best Practices

Comprehensive guidelines for implementing TanStack Router patterns in React applications. These rules optimize type safety, data loading, navigation, and code organization.

## When to Apply

- Setting up application routing
- Creating new routes and layouts
- Implementing search parameter handling
- Configuring data loaders
- Setting up code splitting
- Integrating with TanStack Query
- Refactoring navigation patterns

## Rule Categories by Priority

| Priority | Category | Rules | Impact |
|----------|----------|-------|--------|
| CRITICAL | Type Safety | 4 rules | Prevents runtime errors and enables refactoring |
| CRITICAL | Route Organization | 5 rules | Ensures maintainable route structure |
| HIGH | Router Config | 1 rule | Global router defaults |
| HIGH | Data Loading | 6 rules | Optimizes data fetching and caching |
| HIGH | Search Params | 5 rules | Enables type-safe URL state |
| HIGH | Error Handling | 1 rule | Handles 404 and errors gracefully |
| MEDIUM | Navigation | 5 rules | Improves UX and accessibility |
| MEDIUM | Code Splitting | 3 rules | Reduces bundle size |
| MEDIUM | Preloading | 3 rules | Improves perceived performance |
| LOW | Route Context | 3 rules | Enables dependency injection |

## Quick Reference

### Type Safety (Prefix: `ts-`)

- `ts-register-router` — Register router type for global inference
- `ts-use-from-param` — Use `from` parameter for type narrowing
- `ts-route-context-typing` — Type route context with createRootRouteWithContext *(index only)*
- `ts-query-options-loader` — Use queryOptions in loaders for type inference *(index only)*

### Router Config (Prefix: `router-`)

- `router-default-options` — Configure router defaults (scrollRestoration, defaultErrorComponent, etc.)

### Route Organization (Prefix: `org-`)

- `org-file-based-routing` — Prefer file-based routing for conventions *(index only)*
- `org-route-tree-structure` — Follow hierarchical route tree patterns *(index only)*
- `org-pathless-layouts` — Use pathless routes for shared layouts *(index only)*
- `org-index-routes` — Understand index vs layout routes *(index only)*
- `org-virtual-routes` — Understand virtual file routes

### Data Loading (Prefix: `load-`)

- `load-use-loaders` — Use route loaders for data fetching
- `load-loader-deps` — Define loaderDeps for cache control *(index only)*
- `load-ensure-query-data` — Use ensureQueryData with TanStack Query
- `load-deferred-data` — Split critical and non-critical data *(index only)*
- `load-error-handling` — Handle loader errors appropriately *(index only)*
- `load-parallel` — Leverage parallel route loading

### Search Params (Prefix: `search-`)

- `search-validation` — Always validate search params
- `search-type-inheritance` — Leverage parent search param types *(index only)*
- `search-middleware` — Use search param middleware *(index only)*
- `search-defaults` — Provide sensible defaults *(index only)*
- `search-custom-serializer` — Configure custom search param serializers

### Error Handling (Prefix: `err-`)

- `err-not-found` — Handle not-found routes properly

### Navigation (Prefix: `nav-`)

- `nav-link-component` — Prefer Link component for navigation
- `nav-active-states` — Configure active link states *(index only)*
- `nav-use-navigate` — Use useNavigate for programmatic navigation *(index only)*
- `nav-relative-paths` — Understand relative path navigation *(index only)*
- `nav-route-masks` — Use route masks for modal URLs

### Code Splitting (Prefix: `split-`)

- `split-lazy-routes` — Use .lazy.tsx for code splitting
- `split-critical-path` — Keep critical config in main route file *(index only)*
- `split-auto-splitting` — Enable autoCodeSplitting when possible *(index only)*

### Preloading (Prefix: `preload-`)

- `preload-intent` — Enable intent-based preloading
- `preload-stale-time` — Configure preload stale time *(index only)*
- `preload-manual` — Use manual preloading strategically *(index only)*

### Route Context (Prefix: `ctx-`)

- `ctx-root-context` — Define context at root route
- `ctx-before-load` — Extend context in beforeLoad *(index only)*
- `ctx-dependency-injection` — Use context for dependency injection *(index only)*

## Rule Files

Detailed rules live in `rules/<rule-id>.md`, next to this guide. The rule format and the *(index only)* marker are explained in the wrapper `SKILL.md`.
