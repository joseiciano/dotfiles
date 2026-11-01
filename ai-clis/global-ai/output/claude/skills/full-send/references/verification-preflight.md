# Verification preflight

Run before implementation starts, so the work has a proven way to show it works live. The output is a **verify plan**: the project's `verify` skill, the doctor command, and the mapped features to drive as proof once the change lands.

## 1. Decide whether the change has a surface

A surface is anything a user touches: a web UI, a CLI or TUI, a desktop or mobile app, an API or service. A change with no surface (a library internal, a refactor with no visible behaviour, build or docs-only work) skips the rest: its proof is tests and the repo's checks. Record `preflight: skipped (no surface)` with the reason, and stop here.

## 2. Find the verify skill

Look for the project-local driver skill: `.claude/skills/verify/` at the repo root, or in the touched package's directory in a monorepo (`.claude/skills/verify-*/` from an older generator counts too).

- **Found:** go to step 3.
- **Missing:** run `create-verification-skill` for the touched surface. In an unattended run (automatic mode, `full-send`) run it without asking; in `manual`, ask the user first. Point its evidence location outside the repo or at a gitignored path. It ends on its own end-to-end proof; if that proof fails, stop and put the blocker to the user. Then go to step 3.

## 3. Prove it still drives the touched features

1. Read the feature map (`features/README.md`) and pick the features this work touches: the ones the change alters, plus the one a user passes through to reach a new feature.
2. Launch per the skill, run its doctor, and drive each picked feature once, capturing evidence. Clean up as the skill says.
3. On drift (a doctor or drive failure caused by the verify skill itself, or a touched feature the map lacks), run `maintain-verification-skill` in its **scoped** mode on those features. A failure that is the app's own behaviour is a product gap: record it in the verify plan and continue, since the work may be the fix.

Done when every picked feature drove green against a doctored instance (or is recorded as a product gap or `verified-unreachable` with its prerequisite), and the evidence exists at the skill's named location.

## 4. Hand over the verify plan

Record it where the caller keeps decisions (`show-me-your-work` when active), in this shape:

```
verify skill: <path>   doctor: <command>
drive as proof: <feature file> — <end state that proves it>, ...
new feature file to add: <name> (when the work adds a user-facing feature)
pre-existing product gaps: <none | feature: observed behaviour (targeted by this work: yes/no)>
```

Changes the preflight made to the verify skill (created or scoped fixes) are part of the work: they land as their own `verify:` commit, the first on the work branch, ahead of the implementation commits. That commit stages only the verify skill's own directory; drive evidence is never committed.

## After implementation

The verify plan is the live proof. Drive every listed feature against the changed app, and add the new feature file when the work added a feature, driving it once. A listed feature passes when it drives green, or when it fails exactly as its recorded pre-existing gap does and the work does not target that gap. A gap the work targets must drive green. Evidence from these drives goes in the report and the PR's Testing section.
