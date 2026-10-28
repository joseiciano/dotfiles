# TypeScript example: Hono + Supabase

A worked `foo` package for the [`controller-service-repo`](../SKILL.md) layering. Adapt the framework and client to the repo's own stack.

## `foo/types.ts`

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

## `foo/foo-repository.ts`

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

## `foo/foo-service.ts`

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

## `foo/foo-controller.ts`

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

    // requesterId is set by auth middleware.
    const requesterId = c.get('requesterId') as string | null;

    const result = await service.createFoo({ userId }, { requesterId });
    return c.json(result, 201);
  });
};
```

## `foo/index.ts`

```ts
export * from './types';
export * from './foo-repository';
export * from './foo-service';
export * from './foo-controller';
```
