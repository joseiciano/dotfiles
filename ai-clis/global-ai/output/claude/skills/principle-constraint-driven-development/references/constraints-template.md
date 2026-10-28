# CONSTRAINTS.md template

The shape `<kb>/CONSTRAINTS.md` takes. Every row names the command that produces the verdict and the stage it runs at (`fast`, `task`, `full`). A dimension with a number and no command is an aspiration, not a constraint.

```markdown
# Constraints

Last reviewed: 2026-08-08 by @owner

## Floor (always enforced, no setup required)

- No new suppression comments: `@ts-ignore`, `eslint-disable`, `# noqa`, `# type: ignore`
- No unimplemented stubs: `throw new Error("Not implemented")`, empty `catch {}`
- No skipped or deleted tests without a reason in the commit message
- No secrets in source
- This file does not get weakened to make a change pass

## Enforced with numbers

| Dimension | Rule | Checked by | Stage |
|-----------|------|-----------|-------|
| Types | Zero type errors | `tsc --noEmit` | fast |
| Lint | Zero errors from our config | `biome check` | fast |
| Secrets | No secrets in source | `gitleaks detect --redact` | fast |
| Coverage | Changed lines ≥ 80% covered | `vitest run --coverage` + git diff | task |
| Security: code | No high findings | `semgrep scan --config p/default` | full |
| Security: deps | Nothing at high or above | `osv-scanner scan source -r .` | full |
| Accessibility | Zero critical or serious | `axe $PREVIEW_URL --tags wcag2a,wcag2aa,wcag21aa` | full |
| Performance | LCP ≤ 2500ms, CLS ≤ 0.1 | `lighthouse $PREVIEW_URL --output=json` | full |

## Measured, not yet enforced

| Metric | Today | Direction |
|--------|-------|-----------|
| Project coverage | 62.4% | must not fall |
| Bundle size (main) | 184 kB | must not grow |

## Exceptions

| ID | Rule | Path | Reason | Owner | Expires |
|----|------|------|--------|-------|---------|
| W1 | `no-explicit-any` | `src/legacy/**` | Rewrite tracked in ENG-441 | @owner | 2026-11-01 |
```
