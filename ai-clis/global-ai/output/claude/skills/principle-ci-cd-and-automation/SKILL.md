---
name: principle-ci-cd-and-automation
description: Sets up CI pipelines and their quality gates. Use when creating or modifying a CI pipeline, adding automated checks or test runners to CI, adding preview deploys, or speeding up a slow pipeline.
user-invocable: false
---

# CI/CD and Automation

CI is the enforcement mechanism for every other skill: no change merges without passing every gate.

For a failing CI run, use the `fix-ci` skill. For production rollout and rollback, use `shipping-and-launch`.

## Steps

1. **Read the environment.** Find the CI provider (`.github/workflows/`, `.gitlab-ci.yml`, ...), the language and package manager, and the scripts the project already defines (`package.json`, `Makefile`, `pyproject.toml`, ...). The pipeline calls those scripts and adds no commands of its own.
2. **Map each gate to a command.** Walk the gate list below and pick the project's command for each. When a gate has no command, add the script to the project first, then call it from CI.
3. **Write the pipeline config.** Order the gates cheapest first. For GitHub Actions, start from [`references/github-actions.md`](references/github-actions.md).
4. **Verify.** The work is done when every box in Verification is checked.

## Quality gates

Every change passes these gates before merge, cheapest first:

1. Lint and format
2. Type check
3. Unit tests
4. Build
5. Integration tests (API, database)
6. E2E tests, when the project has a UI
7. Dependency audit
8. Bundle size, when the project ships a frontend bundle

Every gate is mandatory. When a gate fails, fix what it flagged: fix the lint error rather than disable the rule, and fix the code rather than skip the test.

## Secrets

- CI holds only CI secrets. Production secrets live in the deployment platform.
- Test database credentials also come from the secrets store, never as literals in the workflow file, so they can't be reused elsewhere.
- Commit `.env.example` and a secret-free `.env.test`; keep `.env` out of git.

## Common rationalizations

| Rationalization | Reality |
|---|---|
| "CI is too slow" | Optimize the pipeline with [`references/ci-optimization.md`](references/ci-optimization.md); every gate still runs. |
| "This change is trivial, skip CI" | Trivial changes break builds, and CI is fast for them anyway. |
| "The test is flaky, just re-run" | Flaky tests mask real bugs. Fix the flakiness. |
| "We'll add CI later" | Projects without CI accumulate broken states. Set it up on day one. |
| "Manual testing is enough" | Manual testing isn't repeatable. Automate it. |

## Verification

- [ ] Every applicable gate above runs, each through a project script
- [ ] The pipeline runs on every PR and every push to the default branch
- [ ] Failures block merge: CI is a required status check under branch protection
- [ ] No secret appears as a literal in the repo or the workflow files
- [ ] The pipeline finishes in under 10 minutes; if not, apply `references/ci-optimization.md`
