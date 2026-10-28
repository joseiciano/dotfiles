---
name: principle-performance-optimization
description: "Measures and fixes performance across frontend, backend, and database. Use when a performance budget or SLA exists, a regression is suspected, Core Web Vitals or load times need improving, slow queries or N+1 patterns need fixing, or profiling shows a bottleneck. Also routes to a Chrome DevTools / Lighthouse audit (\"why is my site slow\") and to Vercel's React/Next.js performance rules when writing, reviewing, or refactoring React or Next.js code."
user-invocable: false
references: 
  - optimization-patterns
  - web-perf
  - vercel-react-best-practices
---

# Performance Optimization

**Measure** before you optimize. Profile, find the actual bottleneck, fix that one thing, measure again, and keep only what the measurement proves. Start from evidence of a problem: a budget missed, a user report, a regression, a profile.

## Routes

The workflow below is the general method. For these cases, follow the matching route:

| Route | Kind | Use when |
| --- | --- | --- |
| [web-perf](references/web-perf/guide.md) | procedure: follow it step by step | Auditing a web page with Chrome DevTools MCP: performance trace, Core Web Vitals, network and accessibility analysis |
| [vercel-react-best-practices](references/vercel-react-best-practices/guide.md) | standard | Writing, reviewing, or refactoring React or Next.js code for performance (rules in `references/vercel-react-best-practices/rules/`) |
| [performance-checklist](../../../references/performance-checklist.md) | reference | Line-by-line frontend and backend checklist, caching strategies (coalescing, write strategies, negative caching), measurement commands |
| Postgres | standard | Slow queries, indexes, or connection limits: use the separate `postgres-best-practices` skill |

## The workflow

```
1. MEASURE  → Establish a baseline with real data
2. IDENTIFY → Find the actual bottleneck, not the assumed one
3. FIX      → Address that bottleneck only
4. VERIFY   → Re-measure; keep or revert
5. GUARD    → Budget or monitor so it cannot regress silently
```

### Step 1: Measure

Use both kinds of measurement:

- **Synthetic** (Lighthouse, DevTools Performance trace, a benchmark script): controlled and reproducible. Use it to isolate an issue and to gate CI.
- **Field / RUM** (`web-vitals` library, CrUX, APM, query logs with timing): real users in real conditions. Use it to prove a fix improved what users feel.

Record the baseline as a number with its command, conditions, and run-to-run variance. Step 4 replays exactly this.

**Core Web Vitals targets (p75):**

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| **LCP** (Largest Contentful Paint) | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| **INP** (Interaction to Next Paint) | ≤ 200ms | ≤ 500ms | > 500ms |
| **CLS** (Cumulative Layout Shift) | ≤ 0.1 | ≤ 0.25 | > 0.25 |

Let the symptom pick what to measure first:

```
What is slow?
├── First page load
│   ├── Large bundle? --> Measure bundle size, check code splitting
│   ├── Slow server response? --> Measure TTFB in the Network waterfall; split DNS, TCP/TLS, and server wait
│   └── Render-blocking resources? --> Check the Network waterfall for blocking CSS/JS
├── Interaction feels sluggish
│   ├── UI freezes on click? --> Profile main thread, look for long tasks (>50ms)
│   ├── Form input lag? --> Check re-renders, controlled component overhead
│   └── Animation jank? --> Check layout thrashing, forced reflows
├── Page after navigation
│   ├── Data loading? --> Measure API response times, check for waterfalls
│   └── Client rendering? --> Profile component render time, check for N+1 fetches
└── Backend / API
    ├── Single endpoint slow? --> Profile database queries, check indexes
    ├── All endpoints slow? --> Check connection pool, memory, CPU
    └── Intermittent slowness? --> Check for lock contention, GC pauses, external deps
```

### Step 2: Identify the bottleneck

The step is done when one bottleneck is named and the profile, trace, or query plan shows it owns the time.

| Symptom | Likely cause | Investigation |
|---------|-------------|---------------|
| Slow LCP | Large images, render-blocking resources, slow server | Network waterfall, image sizes |
| High CLS | Images without dimensions, late-loading content, font shifts | Layout shift attribution |
| Poor INP | Heavy JavaScript on main thread, large DOM updates | Long tasks in the Performance trace |
| Slow initial load | Large bundle, many network requests | Bundle size, code splitting |
| Slow API responses | N+1 queries, missing indexes, unoptimized queries | Database query log, `EXPLAIN ANALYZE` |
| Memory growth | Leaked references, unbounded caches, large payloads | Heap snapshot |
| CPU spikes | Synchronous heavy computation, regex backtracking | CPU profile |
| High latency | Missing caching, redundant computation, network hops | Trace the request through the stack |

### Step 3: Fix the bottleneck

Fix the one thing Step 2 named. The anti-patterns below are the usual suspects; each gives the rule and the signature to recognize it, and links to a worked fix in [references/optimization-patterns.md](references/optimization-patterns.md). Open the one you need when you reach that code.

**Backend**

- **N+1 queries.** One query per row is the most common backend bottleneck. Fetch the relation in the same query (join/include) instead of in the loop. [Pattern](references/optimization-patterns.md#n1-queries-backend).
- **Unbounded data fetching.** Every list endpoint paginates with a limit and a stable order. [Pattern](references/optimization-patterns.md#unbounded-data-fetching).
- **Queries that ignore their index.** "Add an index" is the guess; `EXPLAIN ANALYZE` is the measurement. Signature: a `Seq Scan` where you expected an index, a `rows=` estimate off by an order of magnitude, or a `Sort` node above the scan; each calls for a different fix. Re-run the plan afterwards; an index that did not change it is a revert. [Pattern](references/optimization-patterns.md#queries-that-ignore-their-index).
- **Connection pool exhaustion.** Signature: *every* endpoint slows at once, time goes to waiting for a connection rather than executing, and the database shows mostly idle sessions. Find what holds connections; a bigger pool only relocates the queue to the database. [Pattern](references/optimization-patterns.md#connection-pool-exhaustion).
- **Missing caching.** Cache what is expensive to produce *and* read far more often than it changes. Every input that changes the response belongs in the key (tenant, locale, permissions, feature flags): a key that omits the viewer serves one user's data to another. Before keeping a cache, state its invalidation strategy, its staleness window, and its stampede guard. [Pattern](references/optimization-patterns.md#missing-caching-backend).

**Frontend**

- **Missing image optimization.** Every image declares `width` and `height` (CLS). The LCP image gets `fetchpriority="high"`, modern formats (AVIF, WebP) through `<picture>`, and `srcset`/`sizes`; below-the-fold images get `loading="lazy"` and `decoding="async"`. [Pattern](references/optimization-patterns.md#missing-image-optimization-frontend).
- **Unnecessary re-renders.** An object or function created in render is a new reference every time and re-renders every child that receives it. Hoist constants; reserve `React.memo` and `useMemo` for work the profile shows is expensive. [Pattern](references/optimization-patterns.md#unnecessary-re-renders-react).
- **Large bundle size.** Modern bundlers tree-shake ESM named imports on their own; the real gains are route-level code splitting and lazy-loading heavy, rarely used features behind `Suspense`. [Pattern](references/optimization-patterns.md#large-bundle-size).

### Step 4: Verify (keep or revert)

A fix is a hypothesis until you re-measure.

- **Replay the baseline:** same command, same conditions, same fixed budget (wall-clock, sample count, or request count). A cold-cache baseline against a warm-cache result measures the cache.
- **One change per measurement.** Three optimizations landed together produce one number you cannot attribute. If they must ship together, measure each in isolation first.
- **Beat the noise.** Repeat the measurement and compare the delta against run-to-run variance. A 3% gain inside ±5% variance is a different sample.
- **Correctness gates the metric.** The suite stays green *and* the number moves. A win that drops work the product needed (a validation, a load-bearing `await`, freshness) is a regression.

Then decide:

| Result vs. baseline | Action |
|---|---|
| Past the noise, tests green | **Keep.** Commit with the before/after numbers in the message. |
| Within noise | **Revert.** |
| Worse | **Revert.** |
| Improved, but a test went red | **Revert.** |

Neutral is a **revert**. Sunk cost pulls toward keeping already-written code; every kept line is maintained forever, so it pays for itself in measured gain or it goes.

**Log every attempt, reverted ones included.** Reverted work leaves no trace in git, so the same dead idea comes back next quarter. Keep a ledger in the PR description or a `PERF.md`, and read it before proposing an experiment:

| Idea | Baseline → Result | Verdict | Why |
|---|---|---|---|
| Memoize the row component | INP 240ms → 235ms | reverted | Inside noise (±15ms). Rows weren't the bottleneck. |
| Virtualize the list | INP 240ms → 90ms | kept | Long tasks gone from the trace. |
| Preconnect to the API origin | LCP 2.8s → 2.8s | reverted | Already same-origin. |

### Step 5: Guard against regression

Guard the metric the user feels, the same LCP, INP, p95 latency, or other primary metric that justified the fix. For a user-facing surface, use both layers:

- **Synthetic CI gate:** a performance budget checked before merge (`npx lhci autorun`, `npx bundlesize`). Compare a median or repeated runs so normal variance does not make the gate flaky.
- **Field monitoring:** alert on a meaningful p75 move in RUM data; use attributed `web-vitals` data to locate the cause, and treat CrUX's rolling window as confirmation rather than an alert.

When either guard fires, return to Step 1 with a fresh baseline.

Default budgets when the project states none:

```
JavaScript bundle: < 200KB gzipped (initial load)
CSS: < 50KB gzipped
Images: < 200KB per image (above the fold)
Fonts: < 100KB total
API response time: < 200ms (p95)
Time to Interactive: < 3.5s on 4G
Lighthouse Performance score: ≥ 90
```

## Common rationalizations

| Rationalization | Reality |
|---|---|
| "We'll optimize later" | Performance debt compounds. Fix obvious anti-patterns now, defer micro-optimizations. |
| "It's fast on my machine" | Your machine isn't the user's. Profile on representative hardware and networks. |
| "The improvement is obvious, no need to re-measure" | Then re-measuring is cheap and proves it. Unmeasured wins are how neutral complexity lands. |

## Verification

The work is done when every box holds for every change kept:

- [ ] Before and after numbers exist, measured the same way (same command, same conditions)
- [ ] Each kept change was measured on its own, and its improvement exceeds run-to-run variance
- [ ] Changes that didn't beat the baseline are reverted
- [ ] Every attempt, kept and reverted, is in the ledger
- [ ] The named bottleneck from Step 2 is the one addressed
- [ ] Existing tests pass unchanged: none edited, skipped, or deleted to get the win
- [ ] Core Web Vitals sit in "Good"; bundle size has not grown without review
- [ ] New data fetching has no N+1 queries, and every list endpoint paginates
- [ ] Any new image declares dimensions, lazy loading below the fold, and responsive sizes
- [ ] Any new index is justified by a query plan before and after, with its write cost considered
- [ ] Any new cache states its key inputs, its invalidation strategy, and its staleness window
- [ ] Any pool change follows from finding what held connections
- [ ] `React.memo` / `useMemo` appear only where the profile shows expensive work
- [ ] The user-facing metric has a synthetic budget or field monitor that will catch a regression
