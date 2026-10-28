# Capability map reviewer

Review the capability map given in this conversation against its request.

## Arguments

- `MAP`: the proposed capability map
- `REQUEST`: the initiative or request the map splits

## Check

- **Need.** `REQUEST` bundles several independently testable capabilities. A single capability, even a large one, should be one spec instead of a map.
- **Coverage.** Every capability in `REQUEST` lands in exactly one module.
- **Boundaries.** Each module could be cut or replaced without rewriting the others' requirements.
- **Direction.** Dependencies point one way with no cycles. Two modules that need each other are one module.
- **Build order.** Modules with no unbuilt dependencies share a step, so parallel work is visible.

## Rules

- Lean positive. Approve a map that is workable even if imperfect.
- Judge boundaries and direction, not module naming taste.

## Reply

`APPROVED`, or `CHANGES` followed by a numbered list of concrete changes, each naming the module it applies to.
