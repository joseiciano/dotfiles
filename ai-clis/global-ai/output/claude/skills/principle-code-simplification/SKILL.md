---
name: principle-code-simplification
description: Simplifies working code without changing behavior. Use when code is harder to read or maintain than it should be, or to deslop a branch of AI-generated code patterns. For prose, use unslop.
user-invocable: false
---

# Code Simplification

Simplification makes code faster to **comprehend** while its behavior stays exactly the same. Every change passes one test: would a new team member understand this faster than the original? Line count is not the measure.

## Branches

Read the reference for the branch you are on when you reach it:

| Branch | Reference |
|---|---|
| Deslop: code an agent wrote, or a request to deslop or remove slop | [references/ai-patterns.md](references/ai-patterns.md) |

## Process

### 1. Understand before touching

The scope is the current branch's changes unless the user names a wider one. Simplify only code that is staying; a module about to be rewritten is left alone.

Apply **Chesterton's Fence**: before changing anything, answer for each piece in scope:

- What is its responsibility, what calls it, and what does it call?
- What are its edge cases and error paths, and which tests pin them?
- Why was it written this way? `git blame` gives the original context: a performance need, a platform constraint, a past bug.
- How do CLAUDE.md and the neighbouring code handle the same pattern: imports, declaration style, naming, error handling, type annotation depth?

Done when every piece in scope has all four answers. A fence whose reason you cannot find stays up.

### 2. Find opportunities

Check every hunk in scope against every row of the [pattern tables](#patterns). Done when each hunk has met each row.

### 3. Apply one change at a time

For each simplification: make the change, run the tests, keep it on green, revert it on red. Existing tests pass unmodified; a test that needs editing means behavior changed. Refactoring commits stay separate from feature and fix commits.

Past roughly 500 lines touched, use a codemod, script, or AST transform instead of hand edits.

### 4. Compare before and after

Read the whole diff. Revert every change that is not easier to understand than what it replaced, or that brings in a pattern the surrounding code does not use.

## Principles

### Behavior is the contract

Same output for every input, same error behavior, same side effects in the same order. When you are unsure a change preserves all of these, keep the original.

### Project conventions win

Simplification moves code toward the codebase's own style. A change toward an outside preference is **churn**.

### Abstractions earn their place

Judge every abstraction, existing or new, with `principle-codebase-design`'s **deletion test**. One that only passes calls through gets inlined; one whose deletion would spread complexity across its callers stays, as does a helper whose name carries a concept. A seam stays when something actually varies across it. Extract a function or shared helper only when the result passes the same test.

### Comprehension over line count

Two focused functions read faster than one merged one; five plain lines read faster than a one-line nested ternary.

## Patterns

**Structure:**

| Pattern | Signal | Simplification |
|---|---|---|
| Deep nesting (3+ levels) | Hard to follow control flow | Guard clauses, or a helper that passes the deletion test |
| Long function (50+ lines) | Several responsibilities | Split by responsibility, where each piece passes the deletion test |
| Nested ternaries | Needs a mental stack to parse | if/else chain, switch, or lookup object |
| Boolean flag parameters | `doThing(true, false, true)` | Options object or separate functions |
| Repeated conditional | Same `if` in several places | One well-named predicate |

**Naming:**

| Pattern | Signal | Simplification |
|---|---|---|
| Generic name | `data`, `result`, `temp`, `val` | Name the content: `userProfile`, `validationErrors` |
| Abbreviation | `usr`, `cfg`, `evt` | Full words, except universal ones (`id`, `url`, `api`) |
| Misleading name | A `get` that also mutates | Name the actual behavior |
| What-comment | `// increment counter` above `count++` | Delete it |
| Why-comment | `// Retry: the API is flaky under load` | Keep it |

**Redundancy:**

| Pattern | Signal | Simplification |
|---|---|---|
| Duplicated logic | Same 5+ lines in several places | Shared function, where it passes the deletion test |
| Dead code | Unreachable branches, unused variables, commented-out blocks | Remove once confirmed dead |
| Pass-through abstraction | Wrapper, or a seam with one adapter | Inline per [Abstractions earn their place](#abstractions-earn-their-place) |
| Redundant type assertion | Cast to an already-inferred type | Remove it |

## Verification

After a simplification pass:

- [ ] Every existing test passes unmodified
- [ ] The build succeeds with no new warnings, and the linter and formatter pass
- [ ] Every simplification is its own reviewable step, and the diff carries no unrelated changes
- [ ] Every change follows CLAUDE.md and the conventions of the surrounding code
- [ ] Every piece of error handling a caller relies on is intact
- [ ] Every added, removed, or inlined abstraction passes the deletion test
- [ ] No dead code is left behind: unused imports, unreachable branches
- [ ] For deslop, every hunk passed the checks in [references/ai-patterns.md](references/ai-patterns.md)
