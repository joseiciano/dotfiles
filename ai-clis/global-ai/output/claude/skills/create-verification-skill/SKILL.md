---
name: create-verification-skill
description: "Generate a project-local `verify` skill that drives the app the way a user does. Use when a repo has no scripted way to prove UI/CLI/service behavior, or for \"make a driver skill for this repo\"."
---

# Create a verification skill

Generate a scripted way to drive the real app and prove behavior: launch it, exercise a feature the way a user would, and capture evidence. It ships as a project-local skill tailored to the repo (`.claude/skills/verify/`). Name it `verify`. At the repo root a project skill by that name replaces Claude Code's bundled `/verify`, which only the user can invoke, so every playbook that names the driver skill can call the project one ([Claude Code 2.1.200 or later](https://code.claude.com/docs/en/skills#run-and-verify-your-app)). In a monorepo, write it in the touched package directory instead.

## 0. Verify the build works

If the checkout doesn't build or start as-is, fix that first (or report it precisely) before generating; a skill written against a broken base teaches wrong steps. When an irrelevant missing asset blocks startup (a static dir the API never serves, a sample config), the generated skill may create it, clearly marked as verification scaffolding, and remove it in cleanup.

## 1. Interview the repo, not the user

Answer these from the codebase and only ask the user what you cannot observe:

- **Surface:** what does a user actually touch? A web UI, a CLI/TUI, a desktop app, an API, a mobile app, a library? A repo can have several; pick the primary one and note the rest.
- **Run:** how does the app start locally? Prefer the repo's own documented dev command (package scripts, Makefile, README quickstart). Note ports, env vars, seed data, auth.
- **Drive:** how can an agent interact with it programmatically? Existing harnesses first — Playwright/Cypress specs, expect scripts, PTY helpers, curl-able endpoints, a debug port. Only then pick a generic recipe: browser/CDP for web and Electron, a tmux/PTY harness for CLI/TUI, plain HTTP for services.
- **Observe:** what evidence can be captured? Screenshots, terminal transcripts, response bodies, logs, exit codes, DB state.
- **Isolate:** can two instances run side by side (ports, data dirs, profiles)? If not, say so in the generated skill: refusing to double-drive a shared instance beats corrupting the user's session.

Done when each of the five has an answer citing a file or command, or a question queued for the user.

## 2. Generate the skill

Write it following the `writing-for-agents` skill: the reader is an agent running verification.

Write `.claude/skills/verify/SKILL.md` with YAML frontmatter (without it the skill never registers): `name: verify` and a `description` that names the app, the surface, and when to reach for it. The body has these sections, each grounded in what the interview found, with no placeholders left:

- **Launch:** the exact command that starts the app for verification, and how to tell it's ready (a log line, a prompt). Launch must reach a usable state from an empty data dir, including any migrations and seed data. Ready means usable, not just that a process answers. A database health check can pass while its init scripts are still running. Include teardown. For a short-lived CLI or TUI there is no server to keep alive: launch means build the binary (or install deps) once, then start each drive in its own isolated PTY or tmux session.
- **Doctor:** one read-only check that answers "is this instance worth driving?" — process up, right version/build, port owned by us, auth valid. An agent runs this first whenever anything looks off.
- **Drive:** the harness recipe with real selectors/commands from this repo, not examples. Prefer stable handles (ARIA labels, data attributes, prompt strings, route paths) over coordinates and tab order.
- **Evidence:** what evidence to capture and where it goes. State the standards: exercise the real user path, not internal setters or test-only endpoints; capture the action and the resulting state, not just the final screen; verify side effects (files written, rows inserted, messages sent) alongside what's visible; mocks only where a production boundary already isolates the external system. When the safe path is a dry-run or test mode, observe what it actually skips (files, network, git refs): some dry-runs still touch the network or open a browser.
- **Cleanup:** how to tear down instances the run created. Kill only what you started, by PID or session name; a process-name kill can take the user's own instances with it. Cleanup removes instances and scratch state and leaves the evidence in a location the skill names.
- **Helpers:** any script the skill ships is executable and its invocation is shown in the skill body. A helper the reader has to reverse-engineer is not a helper.

## 3. Seed the feature map

Create `.claude/skills/verify/features/README.md` plus one file per user-facing feature you can identify (aim for the top 3-5 to start, from routes, commands, menus, or docs). Follow the shape in [`references/feature-map-example/`](references/feature-map-example/), with a README index and one file per feature. Each file answers, from the user's point of view: what the feature is, how to reach it, how to drive it with the harness, and what observable end state proves it works.

The four H2s are `Sub-features`, `How to get to it (user POV)`, `Driving it with <harness>`, and `Gotchas`. If the seed data lacks a precondition that a journey needs, the journey reports a failure and the reason goes in that feature's `Gotchas`; the journey stays as the user would walk it. The map is the repo's maintained verification source; evidence from one convenient entry point is incomplete when the map lists others.

## 4. Prove the generated skill before handing it over

Run its own instructions end to end once: launch, doctor, drive ONE mapped feature (one is enough; the map exists so later runs can cover the rest), capture evidence, clean up. After cleanup, confirm the evidence still exists at the named location — a cleanup that eats the evidence fails this step. Fix what fails, and run the generated cleanup after every failed iteration too, so each attempt releases its processes and ports. A generated skill that was never executed is a draft, not a deliverable. If you proved it in a stand-in for the real target (a container in place of a fresh VM, a local stack in place of a remote one), list every setup step the stand-in did that the target will not. Those steps stay unverified until a run on the real target covers them.

## 5. List it in the knowledge base

Only after step 4 passes. Resolve the KB with `bash ~/.claude/skills/knowledge-base/scripts/kb-path.sh`; if it fails or the directory has no `INDEX.md`, skip this step.

In `INDEX.md`, replace the `## Verification Processes` section (or add it) with one line naming the skill directory, then one line per entry in the feature map README's `## Features` list: the feature name, its one-line blurb, and its file path. In a monorepo, give each package's skill its own `###` subheading.

```markdown
## Verification Processes
Driver skill: `.claude/skills/verify/` (run with /verify)
- Create a note: browser and CLI creation, cancellation, persistence, cleanup. `.claude/skills/verify/features/create-note.md`
- Search notes: toolbar, keyboard and CLI search. `.claude/skills/verify/features/search.md`
```

## 6. Offer the maintenance loop

Point the user at `/maintain-verification-skill` for keeping the map honest as the app changes. Suggest a cadence only if they ask.
