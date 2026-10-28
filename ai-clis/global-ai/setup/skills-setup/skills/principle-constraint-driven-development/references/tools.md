# Tools per dimension

Used in Step 4. Each dimension the user picked in Step 2 (coverage, security, accessibility, …) needs a program that checks it. Find the dimension's row, install the tool, and copy its **Run** command into the `Checked by` column of `CONSTRAINTS.md`. **Gate on** is the result that counts as a failure.

These are the standard tools for each dimension. Use them rather than a hand-written checker, so every run sets up the same tools and the team's existing config keeps working.

| Dimension | Tool | Install | Run | Gate on |
|-----------|------|---------|-----|---------|
| Types (TS) | tsc | already there | `tsc --noEmit` | any error |
| Types (Python) | mypy | `pip install mypy` | `mypy .` | any error |
| Lint | your existing config | already there | `eslint .` / `biome check` / `ruff check` | any error |
| Coverage (JS) | your test runner | already there | `vitest run --coverage` (or `jest --coverage`) | coverage of changed lines |
| Coverage (Python) | pytest-cov | `pip install pytest-cov` | `pytest --cov --cov-report=lcov` | same |
| Security: code | Semgrep | `pipx install semgrep` | `semgrep scan --config p/default --config p/owasp-top-ten` | any high finding |
| Security: secrets | gitleaks | `brew install gitleaks` | `gitleaks detect --redact --no-banner` | any finding |
| Security: dependencies | osv-scanner | `brew install osv-scanner` | `osv-scanner scan source -r .` | high or above |
| Performance: page | Lighthouse | `npm i -D lighthouse` | `lighthouse $URL --output=json --quiet` | LCP, CLS, performance score |
| Performance: bundle | size-limit | `npm i -D size-limit` | `size-limit --json` | per-entry byte budget |
| Accessibility | axe-core | `npm i -D @axe-core/cli` | `axe $URL --tags wcag2a,wcag2aa,wcag21aa` | zero critical or serious |
| Architecture | dependency-cruiser | `npm i -D dependency-cruiser` | `depcruise --validate src` | any violation |
| Assertion quality | Stryker | `npm i -D @stryker-mutator/core` | `stryker run --mutate <changed files>` | mutation score |

## Gotchas

1. **Always pass `--redact` to gitleaks.** Without it the matched secret lands in the agent's transcript, and from there in a log, a summary, or a commit message. Report the rule and the location, never the value.
2. **Lighthouse and axe need a URL.** They run against a live app (a preview deploy, or a local server started first), so they sit in the `full` stage. A project with no URL to hit (a CLI, a library, a desktop app) drops the dimension.
3. **Scope the expensive ones to the diff.** `stryker run --mutate` on the whole repo takes hours and gets switched off; on the changed files it takes under a minute. Semgrep takes a path list the same way.
4. **Coverage reads the lcov the suite already writes**, intersected with `git diff`. One test run, one number.
5. **Check the licence before redistributing Semgrep registry rules** (running them is free). `opengrep` is a drop-in fork with the same rule format and JSON output.

## Repo scripts (only when the user asks)

The commands live in `CONSTRAINTS.md`, which is canonical. If the user wants them in the repo too, mirror the stages:

```json
{
  "scripts": {
    "check:fast": "tsc --noEmit && eslint . && gitleaks detect --redact --no-banner",
    "check:task": "npm run check:fast && vitest run --coverage",
    "check:full": "npm run check:task && semgrep scan --config p/default && osv-scanner scan source -r ."
  }
}
```

When the scripts and `CONSTRAINTS.md` drift, `CONSTRAINTS.md` wins.
