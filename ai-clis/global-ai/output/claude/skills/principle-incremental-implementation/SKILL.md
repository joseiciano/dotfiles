---
name: principle-incremental-implementation
description: Delivers a change in thin vertical slices, each green and committed before the next. Use when implementing a change that spans more than one file, picking up the next task from a plan, landing unfinished work behind a feature flag, or when a change feels too big for one step.
user-invocable: false
---

# Incremental Implementation

Build in **thin vertical slices**: the smallest piece that works end to end, taken to green and committed before the next slice begins. After every slice the system builds, passes its tests, and can be reverted one commit at a time.

```
┌──────────────────────────────────────┐
│                                      │
│   Implement ──→ Test ──→ Verify ──┐  │
│       ▲                           │  │
│       └───── Commit ◄─────────────┘  │
│              │                       │
│              ▼                       │
│          Next slice                  │
│                                      │
└──────────────────────────────────────┘
```

**When NOT to use:** a single-function change whose scope is already minimal.

## Steps

Work Steps 1–4 once per slice, carrying forward from the last slice, until the task is done.

### 1. Pick the slice

Choose the next slice by strategy:

- **Vertical** (default): one complete path through the stack, so each slice is something a user can do.
  ```
  Slice 1: create a task (DB + API + UI)
  Slice 2: list tasks (query + API + UI)
  Slice 3: edit a task (update + API + UI)
  ```
- **Risk-first**: when one piece is uncertain (an untried protocol or library), prove it alone first, so a failure surfaces before anything is built on it.
- **Contract-first**: when backend and frontend proceed in parallel, slice 0 defines the contract (types, interfaces, OpenAPI spec); the backend builds against it with API tests, the frontend against mocks matching it, and a final slice integrates them.

**Done when** you can name the slice in one sentence that states the behavior it adds, and that sentence holds one logical change.

### 2. Implement

Write the simplest thing that could work (see [Simplicity](#simplicity)), touching only what the slice requires (see [Scope](#scope)). Cap a slice at roughly 100 lines between test runs; past that, split it.

**Done when** the slice's behavior exists in code and every changed line serves it.

### 3. Go green

Using the repository's own commands (see principle-test-driven-development's _Discover the Stack First_), write a test first when the behavior has none, then run:

- the full test suite
- the build
- the type check, where the stack has one
- the linter

Then exercise the new behavior directly. Run each command once per code change: a repeat on unchanged code adds no information.

**Done when** every check is green and the behavior named in Step 1 works.

### 4. Commit

Commit the slice on its own with a descriptive message (the `git` skill covers atomic commits).

**Done when** the working tree is clean and the commit reverts cleanly by itself.

## Simplicity

Implement the naive, obviously correct version first; optimize only once tests prove it correct. Before committing, check the slice:

- Could it be fewer lines?
- Does each abstraction earn its complexity today?
- Would a staff engineer ask "why didn't you just…"?
- Does it serve the current task, or a hypothetical future one?

```
✗ Generic EventBus with middleware pipeline for one notification
✓ A direct function call

✗ Abstract factory for two similar components
✓ Two straightforward components sharing a utility

✗ Config-driven form builder for three forms
✓ Three form components
```

Three similar lines beat a premature abstraction; build the abstraction at the third use.

## Scope

Change only the lines the task requires. Leave adjacent code, imports, comments, and the syntax of files you only read exactly as you found them, and build only what the spec asks for. Record anything worth improving outside scope and offer it as a separate task:

```
NOTICED BUT NOT TOUCHING:
- src/utils/format.ts has an unused import (unrelated to this task)
- The auth middleware could use better error messages (separate task)
→ Want me to create tasks for these?
```

Each slice is one logical change: a new component, a refactor of an existing one, and a build-config update are three slices and three commits.

## Safe landing

- **Feature flag**: when a slice merges before the feature is ready for users, gate it behind a flag that defaults off.
  ```typescript
  const ENABLE_TASK_SHARING = process.env.FEATURE_TASK_SHARING === 'true';
  ```
- **Safe defaults**: new options default to the conservative behavior, so callers opt in.
  ```typescript
  export function createTask(data: TaskInput, options?: { notify?: boolean }) {
    const shouldNotify = options?.notify ?? false;
  }
  ```
- **Revertable**: prefer additive changes (new files, new functions); pair every database migration with a rollback migration; land a deletion and its replacement in separate commits.

## Common rationalizations

| Rationalization | Reality |
|---|---|
| "I'll test it all at the end" | Bugs compound: a bug in slice 1 makes slices 2–5 wrong. Take each slice to green. |
| "It's faster to do it all at once" | Until something breaks and you can't tell which of 500 changed lines caused it. |
| "These changes are too small to commit separately" | Small commits are free; large ones hide bugs and make rollback painful. |
| "I'll add the feature flag later" | An incomplete feature is hidden from users from its first merge. Add the flag now. |
| "This refactor is small enough to include" | A refactor mixed into a feature makes both harder to review and debug. Give it its own slice. |

## Verification

After the last slice:

- [ ] Every slice went green and was committed on its own
- [ ] The full suite and build are green on the final commit
- [ ] The feature works end to end as specified
- [ ] The working tree is clean
- [ ] The project-wide Definition of Done is met: [`references/definition-of-done.md`](references/definition-of-done.md)
