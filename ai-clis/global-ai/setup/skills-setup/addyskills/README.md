# addyskills (imported)

Imported once from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)
v0.6.13, using the vendored copy in `ai-clis/vendor/addyskills`. These copies are ours
to edit; the build does not re-read the vendor copy. To pick up upstream changes,
update the vendor copy and diff it against these files.

## Imported
- Skills (24 imported; `code-review-and-quality` and `git-workflow-and-versioning` were later
  folded into our `ai-review` and `git` wrappers): `api-and-interface-design`, `browser-testing-with-devtools`, `ci-cd-and-automation`, `code-review-and-quality`, `code-simplification`, `constraint-driven-development`, `context-engineering`, `debugging-and-error-recovery`, `deprecation-and-migration`, `documentation-and-adrs`, `doubt-driven-development`, `frontend-ui-engineering`, `git-workflow-and-versioning`, `idea-refine`, `incremental-implementation`, `interview-me`, `observability-and-instrumentation`, `performance-optimization`, `planning-and-task-breakdown`, `security-and-hardening`, `shipping-and-launch`, `source-driven-development`, `spec-driven-development`, `test-driven-development`
- Commands (in `global-ai/setup/command-setup/command/`): `/build`, `/code-simplify`, `/constraints`, `/plan-tasks`, `/review`, `/ship`, `/spec`, `/test`, `/webperf`
- Agents (in `global-ai/setup/agent-setup/agents/`): `security-reviewer`, `web-performance-auditor`

Not imported: `using-agent-skills` (all harnesses route skills natively), `docs/`,
`hooks/`, `evals/`, `scripts/`, the Gemini `.toml` commands, plugin packaging.

## Changes from upstream
- Same layout as upstream: `skills/<skill>/` and the shared `references/` checklists,
  so upstream's `../../references/<file>` links resolve unchanged. The Claude build
  (`copy-skills.js`) copies each linked checklist into the installed skill's own
  `references/` folder, so installed skills are self-contained.
- `agent-skills:<skill>` plugin names are plain `<skill>` names.
- Agent names: `code-reviewer` -> `reviewer`, `test-engineer` -> `tester`.
- `security-auditor` is `security-reviewer`, so it replaces oh-my-pi's built-in agent of
  that name; its `omp:` block keeps the built-in's tools and `output` schema, which
  oh-my-pi's security scan relies on.
- `/plan` is `/plan-tasks`: Claude Code and oh-my-pi have a built-in `/plan`.
- `/ship` and `web-performance-auditor` link to the checklists inside
  `doubt-driven-development` and `performance-optimization`.
- Agents use our per-harness frontmatter blocks; upstream `docs/agents.md` links removed.
- `code-simplification` absorbed our retired `deslop` skill: its triggers and its
  "AI-Generated Code Patterns" checklist.

## Folds with our skills
- `test-driven-development` absorbed our retired `tdd`: confirming the failure reason,
  "prefer no new test over a bad test", and the evidence report.
- `frontend-ui-engineering` absorbed our retired `frontend-design`: the Web Interface
  Guidelines fetch, choosing a visual direction (an existing design system wins), and UI
  review mode.
- `performance-optimization` is a wrapper: its own method plus our `web-perf` and
  `vercel-react-best-practices` as `references/<name>/guide.md`.
- `code-review-and-quality` moved into our `ai-review` wrapper and
  `git-workflow-and-versioning` into our `git` wrapper; the upstream copies are in
  `old-skills/`.
