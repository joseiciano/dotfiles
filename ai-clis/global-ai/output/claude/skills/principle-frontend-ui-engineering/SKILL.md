---
name: principle-frontend-ui-engineering
description: Builds and reviews user-facing UI that is accessible, responsive, and visibly designed. Use when building or styling pages and components, choosing a visual direction, managing UI state, or reviewing a UI or its accessibility.
user-invocable: false
argument-hint: <file-or-pattern>
---

# Frontend UI Engineering

Production UI is **intentional**: every colour, spacing value, and layout choice traces back to the design system or to a direction chosen for this product. The default it replaces is the **AI aesthetic**, the look a model converges on when nothing was chosen.

## Branches

Read the reference for the branch you are on when you reach it:

| Branch | Reference |
|---|---|
| New surface with no established design system: landing page, marketing page, new product | [references/visual-direction.md](references/visual-direction.md) |
| Reviewing a UI, its UX, or its accessibility | [references/review.md](references/review.md) |

## Process

### 1. Read the guidelines

Read [references/web-interface-guidelines.md](references/web-interface-guidelines.md). It is the source of truth for accessibility, focus, forms, animation, typography, content handling, images, navigation, touch, theming, i18n, and hydration. Every rule in it is a hard constraint the visual direction works within. Done when the rules are in context.

### 2. Settle the direction

With a design system, its tokens, spacing scale, type hierarchy, and palette are the direction. Without one, take the visual-direction branch and write the design contract first. Done when every visual decision ahead has a source to trace to.

### 3. Build

Apply the [principles](#principles), one component at a time.

### 4. Verify

Run the [verification](#verification) checklist against the rendered result, driving the browser with `principle-browser-testing-with-devtools`.

## Principles

### Components split smart and dumb

Every component is a smart file holding hooks, state, auth, HTTP, and query params, and a dumb file that renders from props. `smart-dumb-component` owns the rules and file layout. Compose children (`<Card><CardHeader/>…</Card>`) over configuration props, and split any component past 200 lines.

### State lives at the lowest level that works

| State | Home |
|---|---|
| One component's UI state | Local state |
| Shared by 2–3 siblings | Lifted state |
| Theme, auth, locale (read-heavy, write-rare) | Context |
| Filters, pagination, anything shareable | URL search params |
| Remote data | Server-state library; `tanstack` owns TanStack Query, including optimistic updates |
| Complex client state shared app-wide | Global store |

Props pass through at most 3 levels; past that, use context or restructure the tree.

### Every value comes from a token

Spacing comes from the project's scale, colour from semantic tokens (`text-primary`, `bg-surface`), radius and shadow from the design system. A raw hex, an inline style, or an off-scale value (`13px`, `2.3rem`) is a missing token: add it to the system or use the nearest one.

### Content is real

Lay out with realistic content: real lengths, wrapping, overflow, and the loading, empty, error, success, and permission states. Loading content gets a skeleton in the content's shape; an empty state names what is missing and offers the next action.

### Mobile first

Write the base styles for 320px and add breakpoints upward.

## Verification

After building UI:

- [ ] Every rule in the Web Interface Guidelines holds
- [ ] Every colour, spacing, radius, and font traces to a token or the design contract
- [ ] Every interactive element is reachable and operable by keyboard alone, with visible focus
- [ ] The accessibility tree gives every interactive element a name and runs headings without gaps
- [ ] axe-core and the dev-tools console report zero errors
- [ ] The layout holds at 320px, 768px, 1024px, and 1440px
- [ ] Every applicable loading, empty, error, success, and permission state renders
- [ ] Every component is split smart and dumb per `smart-dumb-component`
