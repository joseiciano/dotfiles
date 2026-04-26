---
name: controller-service-repo
description: Enforces the Controller-Service-Repository backend pattern.
author: joseiciano
version: "1.0.0"
---

# Controller-Service-Repository Pattern

Use this skill when implementing or refactoring backend code inside a package.

The examples below use typescript, but this pattern is extendable for any language. 

## Goal

Always structure backend features using **Controller → Service → Repository**.
This keeps concerns separated, improves testability, and makes code easier to maintain.

## Package Structure

```text
packages/
└─ foo/
   ├─ foo-controller.ts
   ├─ foo-service.ts
   ├─ foo-repository.ts
   ├─ types.ts
   └─ index.ts
```

## Layer Responsibilities

### 1) Controller (HTTP boundary)

- Defines routes.
- Parses and validates request inputs (path params, query params, body).
- Converts framework request/response objects into plain service inputs.
- Calls service layer.
- Returns HTTP responses.

**Controller must not contain business logic or direct DB/API calls.**

### 2) Service (business logic)

- Handles validation and authorization checks.
  - Example: authentication, permission checks, invariants.
- Orchestrates use cases.
- Shapes data for repository calls.
- Calls repository layer.

**Service must not parse raw HTTP request objects and should avoid low-level query details.**

### 3) Repository (data access)

- Handles low-level operations.
  - DB queries
  - External API calls
- Maps raw persistence/API responses to domain-friendly shapes when needed.

**Repository must not contain route logic or authorization decisions.**

## TypeScript Example

### `foo/types.ts`

```ts
export interface WorkerBindings {
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;
}

export interface FooInput {
  userId: string;
}

export interface FooResult {
  id: string;
  userId: string;
  createdAt: string;
}
```

### `foo/foo-repository.ts`

```ts
import type { SupabaseClient } from '@supabase/supabase-js';
import type { FooResult } from './types';

export class FooRepository {
  constructor(private readonly supabase: SupabaseClient) {}

  async createFoo(userId: string): Promise<FooResult> {
    const { data, error } = await this.supabase
      .from('foos')
      .insert({ user_id: userId })
      .select('id, user_id, created_at')
      .single();

    if (error) throw error;

    return {
      id: data.id,
      userId: data.user_id,
      createdAt: data.created_at,
    };
  }
}
```

### `foo/foo-service.ts`

```ts
import { FooRepository } from './foo-repository';
import type { FooInput, FooResult } from './types';

export class FooService {
  constructor(private readonly fooRepository: FooRepository) {}

  async createFoo(input: FooInput, context: { requesterId: string | null }): Promise<FooResult> {
    if (!context.requesterId) {
      throw new Error('Unauthorized');
    }

    if (context.requesterId !== input.userId) {
      throw new Error('Forbidden');
    }

    return this.fooRepository.createFoo(input.userId);
  }
}
```

### `foo/foo-controller.ts`

```ts
import type { Hono } from 'hono';
import type { SupabaseClient } from '@supabase/supabase-js';
import { FooRepository } from './foo-repository';
import { FooService } from './foo-service';
import type { WorkerBindings } from './types';

interface FooControllerOptions {
  supabaseFactory: (bindings: WorkerBindings) => SupabaseClient;
}

export const registerFooController = (
  app: Hono<{ Bindings: WorkerBindings }>,
  options: FooControllerOptions,
): void => {
  app.post('/foo/:userId', async (c) => {
    const userId = c.req.param('userId');
    if (!userId) return c.json({ error: 'Missing userId' }, 400);

    const supabase = options.supabaseFactory(c.env);
    const repository = new FooRepository(supabase);
    const service = new FooService(repository);

    // Example: requesterId extracted from auth middleware/context.
    const requesterId = c.get('requesterId') as string | null;

    const result = await service.createFoo({ userId }, { requesterId });
    return c.json(result, 201);
  });
};
```

### `foo/index.ts` (barrel)

```ts
export * from './types';
export * from './foo-repository';
export * from './foo-service';
export * from './foo-controller';
```

## Rules to Enforce

- Every backend feature should include controller, service, and repository files.
- Controllers only parse inputs + map outputs.
- Services own business logic and authorization checks.
- Repositories own DB/API access.
- Use `index.ts` as the package barrel export.
