# Map Template

The format of `MAP.md`. One row per module, one line per build-order step.

## Fields

- **Module id** — Stable kebab-case id. The folder name for the module's spec: `<kb>/work/<slug>/<module-id>/SPEC.md`.
- **Responsibility** — What the module owns, in a few words.
- **Depends on** — Module ids this one consumes. `—` for none.
- **Status** — `planned`, `specced`, `built`, or `dropped`.

## Format

```markdown
# Capability Map: [Initiative Name]

| Module id | Responsibility | Depends on | Status |
|---|---|---|---|
| identity | Accounts, sessions, SSO | — | planned |
| billing | Plans, invoices, payments | identity | planned |
| notifications | Email and webhook fan-out | identity | planned |
| reporting | Usage dashboards | billing, notifications | planned |

Build order: identity → billing, notifications → reporting
```

Modules on the same build-order step (separated by commas) can be specced and built in parallel.
