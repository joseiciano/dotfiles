# TypeScript Contract Patterns

## Separate input from output

The input type holds what the caller provides; the output type adds what the system generates. One shared type either forces callers to invent `id` and timestamps or leaves them optional on read.

```typescript
interface CreateTaskInput {
  title: string;
  description?: string;
}

interface Task {
  id: TaskId;
  title: string;
  description: string | null;
  createdAt: Date;
  updatedAt: Date;
  createdBy: UserId;
}
```

## Discriminated unions for variants

When a field's validity depends on state, model each state as its own variant so the invalid combinations can't be expressed:

```typescript
type TaskStatus =
  | { type: 'pending' }
  | { type: 'in_progress'; assignee: UserId; startedAt: Date }
  | { type: 'completed'; completedAt: Date; completedBy: UserId }
  | { type: 'cancelled'; reason: string; cancelledAt: Date };
```

## Branded IDs

Brand every ID type so a `UserId` cannot be passed where a `TaskId` is expected:

```typescript
type TaskId = string & { readonly __brand: 'TaskId' };
type UserId = string & { readonly __brand: 'UserId' };

function getTask(id: TaskId): Promise<Task> { ... }
```

Brand IDs at the edge, where they are validated, so code further in only ever holds branded values.
