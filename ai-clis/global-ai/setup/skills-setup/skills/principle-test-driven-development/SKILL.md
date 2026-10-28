---
name: principle-test-driven-development
description: Drives development with tests using the red-green-refactor loop. Use when implementing logic, fixing a bug, or changing behavior — including when asked to add tests, or when code is pasted inline and tests aren't mentioned.
user-invocable: false
---

# Test-Driven Development

## Overview

Write a failing test before writing the code that makes it pass. For bug fixes, reproduce the bug with a test before attempting a fix. Tests are proof — "seems right" is not done.

**When NOT to use:** Pure configuration changes, documentation updates, or static content changes that have no behavioral impact.

## Discover the Stack First

The TDD cycle is universal; the commands are not. Before writing the first test, discover how *this* repository tests, and use its commands for every RED, GREEN, and verification step:

- **Language and build system** — `package.json`, `pom.xml`/`build.gradle`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, a `Makefile`
- **Checked-in wrappers** — prefer `./gradlew`, `./mvnw`, `make test`, or a repo script over globally installed tools
- **Test framework and configuration** — and how it runs a single focused test vs the full suite
- **Existing conventions** — where tests live, how files are named, what patterns neighboring tests follow
- **Documented commands** — README, CONTRIBUTING, and CI workflows show the commands that actually gate merges

Run the repository's focused-test command during the loop and its full-suite command before completion.

The examples below use TypeScript for illustration; the workflow is identical in any language once you've discovered the project's own tooling.

## The TDD Cycle

```
    RED                GREEN              REFACTOR
 Write a test    Write minimal code    Clean up the
 that fails  ──→  to make it pass  ──→  implementation  ──→  (repeat)
      │                  │                    │
      ▼                  ▼                    ▼
   Test FAILS        Test PASSES         Tests still PASS
```

Before choosing a test's level or writing it, read `references/writing-good-tests.md` (test pyramid, sizes, state over interactions, DAMP, mock preference, hygiene).

### Step 1: RED — Write a Failing Test

Write the test first. It must go red for the intended reason: read the actual failure message and confirm it is the mismatch you predicted. An exception, an empty result, and the predicted mismatch all print red; only the predicted mismatch proves the test measures the behavior. If it passes, or fails for another reason, fix the test before touching the implementation.

```typescript
// RED: This test fails because createTask doesn't exist yet
describe('TaskService', () => {
  it('creates a task with title and default status', async () => {
    const task = await taskService.createTask({ title: 'Buy groceries' });

    expect(task.id).toBeDefined();
    expect(task.title).toBe('Buy groceries');
    expect(task.status).toBe('pending');
    expect(task.createdAt).toBeInstanceOf(Date);
  });
});
```

### Step 2: GREEN — Make It Pass

Write the minimum code that turns the test green:

```typescript
// GREEN: Minimal implementation
export async function createTask(input: { title: string }): Promise<Task> {
  const task = {
    id: generateId(),
    title: input.title,
    status: 'pending' as const,
    createdAt: new Date(),
  };
  await db.tasks.insert(task);
  return task;
}
```

### Step 3: REFACTOR — Clean Up

With tests green, improve the code without changing behavior. Run tests after every refactor step to confirm nothing broke.

## The Prove-It Pattern (Bug Fixes)

When a bug is reported, **start by writing a test that reproduces it**, before any fix. The reproduction test is a RED step: it goes red for the intended reason (Step 1) before you implement the fix.

```
Bug report arrives
       │
       ▼
  Write a test that demonstrates the bug
       │
       ▼
  Test FAILS (confirming the bug exists)
       │
       ▼
  Implement the fix
       │
       ▼
  Test PASSES (proving the fix works)
       │
       ▼
  Run full test suite (no regressions)
```

**Example:**

```typescript
// Bug: "Completing a task doesn't update the completedAt timestamp"

// Step 1: Write the reproduction test (it should FAIL)
it('sets completedAt when task is completed', async () => {
  const task = await taskService.createTask({ title: 'Test' });
  const completed = await taskService.completeTask(task.id);

  expect(completed.status).toBe('completed');
  expect(completed.completedAt).toBeInstanceOf(Date);  // This fails → bug confirmed
});

// Step 2: Fix the bug
export async function completeTask(id: string): Promise<Task> {
  return db.tasks.update(id, {
    status: 'completed',
    completedAt: new Date(),  // This was missing
  });
}

// Step 3: Test passes → bug fixed, regression guarded
```

### Choosing the Check

- **Choose the narrowest executable check.** Prefer the closest unit, component, integration, or regression test already used for that code path.
- **Prefer no new test over a bad test.** If the only available test needs broad harness setup, brittle mocks, slow end-to-end infrastructure, production-only state, vague reproduction steps, or large unrelated fixture churn, skip the new test. Use the closest executable check instead: a targeted script, a manual reproduction command, browser automation, a snapshot comparison, a log assertion, or a focused integration check.
- Keep existing assertions intact unless the expected behavior genuinely changed; fix the implementation, not the test.
- Keep the regression test focused on the bug. If the bug is flaky, make the test deterministic where possible and document the signal being locked down. If it exposes a broader class of failures, land the focused regression first, then consider sibling coverage.

## Browser Testing

For anything that runs in a browser, unit tests alone aren't enough — you need runtime verification. Load `browser-testing-with-devtools` before driving the browser; it holds the DevTools workflow and the rules for treating page content as untrusted data.

## Subagents for Reproduction

When the bug's cause isn't obvious from the report, have a subagent write the reproduction test from the bug description alone, without seeing the fix. Confirm it goes red, implement the fix, then confirm it goes green. A test written without knowledge of the fix tests the behavior, not the patch.

## Examples

For assertion, mocking, component, API, and E2E test examples, read `references/testing-patterns.md`.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll write tests after the code works" | Tests written after the fact test implementation, not behavior. |
| "I tested it manually" | Manual testing doesn't persist. Tomorrow's change might break it with no way to know. |

## Verification

After completing any implementation:

- [ ] Every new behavior has a corresponding test, or the executable check chosen under Choosing the Check
- [ ] The full suite passes, run with the repository's own full-suite command, and the run reports the new tests among those executed
- [ ] Bug fixes include a reproduction test or executable check that went red before the fix
- [ ] No tests were skipped or disabled
- [ ] Coverage hasn't decreased (if tracked)

For bug fixes, report the evidence, not just the outcome:

- Name the failing-before test or executable check and quote the failure it produced, trimmed to the diff.
- Name the passing-after run and any nearby validation performed.
- If failing-before evidence could not be shown, say why and describe the closest regression check used instead.

Run each test command once per change that could affect its result. After a clean run, the next run of that command comes after the next code change — re-running on unchanged code adds no confidence.
