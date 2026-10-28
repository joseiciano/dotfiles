# CI optimization

When the pipeline takes over 10 minutes, apply these in order of impact, re-timing after each:

1. **Cache dependencies.** Use the setup action's cache option or `actions/cache`, keyed on the lockfile.
2. **Run gates in parallel.** Split lint, typecheck, test, and build into separate jobs or a matrix.
3. **Run only what changed.** Use path filters, for example to skip E2E on docs-only PRs.
4. **Shard the test suite.** Split tests across runners with a matrix.
5. **Move slow tests off the critical path.** Run them on a schedule, and keep a fast subset on every PR.
6. **Use larger runners.** Use larger hosted or self-hosted runners for CPU-heavy builds.

Every gate still runs on every PR, only faster. Moving a test to a schedule is fine; deleting it is not.
