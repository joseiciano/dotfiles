# Code Quality Review

Each reviewer applies this code-quality lens in addition to the rubric: a strict standard for implementation quality, maintainability, abstraction quality, and codebase health.

## Core Prompt

Start from this baseline:

> Perform a deep code quality audit of the current branch's changes.
> Rethink how to structure / implement the changes to meaningfully improve code quality without impacting behavior.
> Work to improve abstractions, modularity, reduce Spaghetti code, improve succinctness and legibility.
> Be ambitious, if there is a clear path to improving the implementation that involves restructuring some of the codebase, go for it.
> Be extremely thorough and rigorous. Measure twice, cut once.

## Dimensions

0. **Hunt for code judo.** A code-judo move is a behavior-preserving restructuring that uses the existing architecture more effectively and makes the implementation dramatically simpler, smaller, more direct, and more elegant. Assume one is often available. Look past local cleanup for reframings that make whole branches, helpers, modes, conditionals, or layers disappear. Push hardest for moves that delete complexity rather than rearrange it.

1. **Keep files under 1k lines.** A PR that pushes a file from under 1k lines to over 1k lines is a strong smell. When the diff crosses that threshold, ask whether the code should be decomposed first into extracted helpers, subcomponents, or modules. Waive only for a compelling structural reason where the resulting file stays clearly organized.

2. **Keep existing flows untangled.** Treat new ad-hoc conditionals, scattered special cases, and one-off branches inserted into unrelated flows ("weird if statements in random places") as spaghetti growth: a design problem, not a style nit. Push that logic into a dedicated helper, state machine, or module.

3. **Clean the design, beyond accepting working code.** When behavior can stay the same while the structure becomes meaningfully cleaner, push for the cleaner version. Prefer simplifications that remove moving pieces over refactors that spread the same complexity around.

4. **Prefer direct, boring, maintainable code.** Treat brittle, ad-hoc, or "magic" behavior as a problem. Be skeptical of generic mechanisms that hide simple data-shape assumptions. Flag thin abstractions, identity wrappers, or pass-through helpers that add indirection without buying clarity.

5. **Make type boundaries explicit where it affects maintainability.** Question unnecessary optionality, `unknown`, `any`, or cast-heavy code when a clearer type boundary could exist. Prefer explicit typed models over loosely-shaped ad-hoc objects. When a branch leans on a silent fallback to paper over an unclear invariant, ask whether the boundary should be made explicit.

6. **Keep logic in the canonical layer and reuse existing helpers.** Call out feature logic leaking into shared paths or implementation details leaking through APIs. Prefer existing canonical utilities over bespoke one-offs. Push code toward the right package, service, or module instead of normalizing drift.

7. **Parallelize independent work and keep related updates atomic, when the cleaner structure is obvious.** Flag independent work serialized for no reason, and related updates that can leave state half-applied. Aim at avoidable orchestration complexity that makes the code more brittle, rather than micro-optimizations.

## Output Expectations

Prioritize structural code-quality regressions and missed simplifications first, then spaghetti and branching complexity, then boundary, type, and file-size concerns, then smaller modularity and legibility issues.

## Approval Bar

Approve on structure as well as behavior: correct behavior alone is not enough. Treat these as presumptive blockers unless the author can justify them:

- Incidental complexity kept where a code-judo move would delete it (dimension 0).
- A file pushed from below 1000 lines to above 1000 lines (dimension 1).
- Ad-hoc branching that tangles an existing flow, or feature checks scattered across shared code (dimension 2).
- An unnecessary abstraction, wrapper, or cast-heavy contract (dimensions 4 and 5).
- A duplicated existing helper, or logic in the wrong layer when there is a clear canonical home (dimension 6).

If none of those conditions are met, leave explicit, actionable feedback and push for a cleaner decomposition.

## Review Tone

Be direct, serious, and demanding about quality, and stay civil. Name major maintainability issues as major, at full strength. If the code is making the codebase messier, say so. If the implementation missed an obvious dramatic simplification, say that too. When the real issue is structural, report the structural issue rather than settling for "maybe rename this".
