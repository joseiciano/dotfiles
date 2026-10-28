---
name: controller-service-repo
description: Controller-Service-Repository layering for backend code. Use when adding or refactoring a backend endpoint, route, or feature package.
author: joseiciano
version: "1.1.0"
---

# Controller-Service-Repository

Each backend feature is one package split into three **layers**. Dependencies run one way: controller → service → repository. A layer calls only the layer below it.

## Package layout

```text
foo/
├─ foo-controller.ts
├─ foo-service.ts
├─ foo-repository.ts
├─ types.ts
└─ index.ts      # barrel: re-exports the package
```

Match the repo's existing file naming and extension where it differs; the three-layer split and the barrel are the fixed part.

## Layers

### Controller: the HTTP boundary

Owns routes, request parsing and input validation (path params, query, body), and HTTP responses. It converts framework request objects into plain service inputs, calls the service, and maps the result to a response. Business rules and data access live below it.

### Service: business logic

Owns authentication and permission checks, invariants, and use-case orchestration. It receives plain inputs, shapes data for the repository, and calls it. It works with domain shapes, leaving raw request objects to the controller and query details to the repository.

### Repository: data access

Owns DB queries and external API calls, and maps raw persistence or API responses to domain shapes. Routing and authorization decisions stay in the layers above.

## Example

For a full TypeScript package (Hono + Supabase), read [`references/typescript-example.md`](references/typescript-example.md).

## Done when

Every feature you touched has all three layers and a barrel, each piece of logic sits in the layer that owns it, and every import points one way: controller → service → repository.
