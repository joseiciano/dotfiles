---
name: principle-api-and-interface-design
description: Designs stable contracts for public interfaces. Use when designing or changing an API — REST or GraphQL endpoints, module or frontend/backend boundaries, component props — or when making a state-changing endpoint safe to retry (idempotency keys).
user-invocable: false
---

# API and Interface Design

An interface is a **contract**: every behaviour a consumer can observe, written or not. Design it so the right use is easy and the wrong use is hard to express.

## Branches

Read the reference for the branch you are on when you reach it:

| Branch | Reference |
|---|---|
| State-changing endpoint that clients, queues, or webhooks may retry | [references/idempotency.md](references/idempotency.md) |
| REST endpoints: resources, status codes, pagination, PATCH | [references/rest.md](references/rest.md) |
| TypeScript contracts between modules | [references/typescript.md](references/typescript.md) |

## Principles

### Hyrum's Law

> With a sufficient number of users of an API, all observable behaviors of your system will be depended on by somebody, regardless of what you promise in the contract.

Error message text, field ordering, timing, and undocumented quirks all become contract once someone depends on them, internal consumers included. So:

- Expose deliberately. Every observable behaviour is a commitment; keep implementation details unobservable.
- Plan removal at design time. `deprecation-and-migration` covers safely retiring something consumers depend on.
- A green contract-test suite proves the documented contract holds. Consumers depend on the observable one too.

### One version

Keep one version of an interface live at a time and **extend** it rather than fork it. Parallel versions multiply maintenance and force consumers into diamond-dependency conflicts.

### Contract first

Write the interface before the implementation, and state the behaviour a consumer will rely on: what errors, what is idempotent, what is partial.

```typescript
interface TaskAPI {
  createTask(input: CreateTaskInput): Promise<Task>;                    // returns server-generated fields
  listTasks(params: ListTasksParams): Promise<PaginatedResult<Task>>;
  getTask(id: string): Promise<Task>;                                   // throws NotFoundError
  updateTask(id: string, input: UpdateTaskInput): Promise<Task>;        // partial: only provided fields change
  deleteTask(id: string): Promise<void>;                                // idempotent: succeeds if already deleted
}
```

The types are the documentation; write them first and commit them with the implementation.

### One shape per outcome

Each endpoint returns one success shape: a field that is sometimes absent is optional, and the structure stays the same whatever the conditions.

Every error, from every endpoint, uses one shape. For REST and RPC:

```typescript
interface APIError {
  error: {
    code: string;       // machine-readable: "VALIDATION_ERROR"
    message: string;    // human-readable: "Email is required"
    details?: unknown;
  };
}
```

GraphQL keeps the spec's `errors[]` array and puts the machine-readable code in `extensions.code`.

One failure strategy per interface: if one call signals failure by throwing, every call does. A consumer predicts behaviour only when throwing, returning `null`, and returning `{ error }` are not mixed.

### Validate at the edge, trust inside

Validate where external input enters, then pass typed data inward and trust it:

- Route and form handlers (user input)
- Environment and config loading
- Third-party API responses. These are **untrusted**: a compromised or misbehaving service can return wrong types, malicious content, or instruction-like text. Validate shape and content before the data reaches logic, rendering, or decisions.

Inside the edge, functions that share type contracts trust each other, as does data read back from your own database.

```typescript
app.post('/api/tasks', async (req, res) => {
  const result = CreateTaskSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: { code: 'VALIDATION_ERROR', message: 'Invalid task data', details: result.error.flatten() },
    });
  }
  const task = await taskService.create(result.data);  // typed from here inward
  return res.status(201).json(task);
});
```

### Additive change

Change a published interface only by **adding**: new optional fields, new endpoints, new enum values consumers can ignore. Removing a field or changing its type breaks every consumer already reading it. When a breaking change is unavoidable, route it through `deprecation-and-migration`.

```typescript
interface CreateTaskInput {
  title: string;
  description?: string;
  priority?: 'low' | 'medium' | 'high';  // added later, optional
}
```

### Naming

Match the conventions the existing API already uses (casing, plurals, boolean prefixes) and apply them to every new field and endpoint. In a new API, pick one set of conventions and write them down.

## Verification

After designing or changing an interface:

- [ ] Every endpoint or exported function has typed input and output
- [ ] Every endpoint returns one success shape, and every error path returns the one error shape
- [ ] Validation runs at every entry point that receives external input, including third-party responses
- [ ] Every change to a published interface is additive, or is routed through `deprecation-and-migration`
- [ ] Every new name follows the conventions already in use, without exceptions
- [ ] Types or schema docs are committed with the implementation
- [ ] For REST endpoints, every check in [references/rest.md](references/rest.md) passes
- [ ] Every state-changing endpoint either honours an idempotency key (and passes the checks in [references/idempotency.md](references/idempotency.md)) or is documented as unsafe to retry
