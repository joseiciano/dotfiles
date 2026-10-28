# Spec reviewer

Review the spec given in this conversation against its source.

## Arguments

- `SPEC`: the drafted spec
- `SOURCE`: what the spec was written from (the request, conversation, issue, or capability map module)

## Check

- **Fidelity.** The spec covers what `SOURCE` asks for, and adds nothing it does not.
- **Template.** Every section of the spec template is filled, or marked not applicable with a reason.
- **Testable success.** Success criteria are specific and checkable, not "faster" or "better".
- **Scope.** The spec covers one independently testable capability. A spec spanning several should have been a capability map.
- **Boundaries.** Out-of-scope is explicit, and module contracts sit in the provider's spec.

## Rules

- Lean positive. Approve a spec that is actionable even if imperfect.
- Skip grammar and wording nits.

## Reply

`APPROVED`, or `CHANGES` followed by a numbered list of concrete changes, each naming the section it applies to.
