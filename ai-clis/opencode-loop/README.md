# opencode-loop

Iterative implement + review loop for [OpenCode](https://github.com/sst/opencode).

Given a ticket, `opencode-loop` resolves the ticket's story file, then runs:

1. **resolve story** — locate exactly one Markdown file at `docs/product/stories/stories/**/<ticket>-*.md` (relative to `--cwd`) before any work begins
2. **implement** — `opencode run --command implement` in a fresh session, with the ticket plus story file path passed as a single positional prompt
3. **review** — `opencode run --command review` in a separate fresh session, with the same ticket + story file positional (the configured `/review` slash command still runs noninteractively)
4. reads the generated review Markdown report (`prompts/code_review/code_review_x.md`)
5. **repeats** implementation + review until the report's `**Final Decision**` is exactly `LGTM`

Every non-LGTM decision — `LGTM with Comments`, `Minor Issues`, `Blocked` — triggers another
iteration. Follow-up implement commands use the `implement` slash command with a single positional
argument that carries the ticket plus the story file path, the exact review report path and
directions to fix every `[BLOCKING]` and `[WARNING]` finding (the report body is never pasted into
the argument).

The full prompt is never passed as the `--command` value: `--command` always receives just the slash
command name (`implement` or `review`), and the ticket/story context is passed as a separate single
positional argument. That keeps argv parseable by the opencode CLI and preserves a fresh slash
command session per invocation.

## Requirements

- [Bun](https://bun.sh) ≥ 1.x
- [`opencode`](https://github.com/sst/opencode) on `PATH` (or pass `--opencode-bin`)
- The `review` skill installed for the target project (writes reports to `prompts/code_review/code_review_x.md`)
- A story file for the ticket at `docs/product/stories/stories/**/<ticket>-*.md` (relative to `--cwd`) — exactly one; zero or multiple abort before the loop starts

## Usage

```bash
# from a project directory
bunx opencode-loop TICKET-123

# via package script
bun run src/cli.ts TICKET-123

# if installed as a bin
opencode-loop TICKET-123
```

Run from inside the target project, or point at it explicitly:

```bash
opencode-loop TICKET-123 --cwd ../my-project
```

### Options

| Option | Default | Description |
|---|---|---|
| `<ticket>` | *(required)* | Ticket/issue identifier. Resolves the story file at `docs/product/stories/stories/**/<ticket>-*.md` and is passed (with that path) to `implement` and `review`. |
| `--max-attempts N` | `5` | Maximum implement→review iterations before giving up. Must be a positive integer. |
| `--cwd DIR` | current directory | Project directory to run in. Must exist and be a directory; the story file is resolved relative to it. |
| `--opencode-bin BIN` | `opencode` | Path or name of the opencode binary. |

### Exit codes

| Code | Meaning |
|---|---|
| `0` | Final Decision is exactly `LGTM`. |
| `1` | Invalid arguments, no or multiple matching story files, child process failed, no fresh report found, malformed report, lock already held, or `--max-attempts` exhausted without `LGTM`. |

## How it works

```
opencode-loop <ticket>
  └─▶ resolve story file: docs/product/stories/stories/**/<ticket>-*.md
        ├─▶ exactly one match  → absolute path carried in every prompt
        └─▶ zero / multiple    → clear error listing the problem, exit 1
  └─▶ acquire lock: prompts/code_review/.opencode-loop.lock (atomic exclusive create)
  └─▶ opencode run --command implement "<ticket>
                                      Story file: <abs path>"       (fresh session, stdout inherited)
  └─▶ snapshot prompts/code_review/
  └─▶ opencode run --command review "<ticket>
                                     Story file: <abs path>"         (fresh session, stdout inherited)
  └─▶ find the NEW/MODIFIED code_review_x.md (never a stale one)
  └─▶ parse `**Final Decision**: <value>`
        ├─▶ "LGTM"                    → done, exit 0
        └─▶ anything else             → opencode run --command implement \
                                           "<ticket>
                                            Story file: <abs path>
                                            The previous review was not approved (...)
                                            Read the review report at: <abs path>
                                            Fix every [BLOCKING] and [WARNING] finding..."
                                          then review again
  └─▶ release lock (always, success or failure)
```

### Story file resolution

Before the loop begins, `opencode-loop` recursively walks
`docs/product/stories/stories/` (relative to `--cwd`) for Markdown files named `<ticket>-*.md`.
Exactly one match is required:

- no match → exit 1 with the ticket, the searched root, and the expected `<ticket>-*.md` pattern
- multiple matches → exit 1 listing every candidate path

The resolved absolute path is stored on `CliOptions.storyPath` and is passed as part of the single
positional prompt to every `implement`, `review`, and follow-up invocation, so each agent reads the
exact same story file.

### Concurrency safety

`opencode-loop` acquires an atomic project-scoped lock file at
`prompts/code_review/.opencode-loop.lock` (relative to `--cwd`) before the loop begins and releases
it in a `finally` block — on success, on failure, and on every error path. The lock file is created
with an exclusive open (`wx`), so two loops started in the same target project cannot both run: the
second one aborts with a clear error naming the lock path (the lock file holds the running process
pid). If a loop is killed hard (e.g. SIGKILL), the lock file may remain; the next run reports it
clearly and it can be removed by hand.

The lock file is ignored by report snapshotting and fresh-report selection — only `code_review_*.md`
files count. `prompts/code_review/` is created on demand if it does not exist yet.

### Review context

The `review` step runs `opencode run --command review` with a single positional holding the ticket
plus the resolved story file path — the review agent knows what was implemented and can read the
exact story file. This does not modify the configured `/review` slash command workflow: it still
runs noninteractively and produces the report at `prompts/code_review/code_review_x.md`.

### Report contract

Relies on the `review` skill contract:

- report path: `prompts/code_review/code_review_x.md` (relative to `--cwd`), `x` increments from 1
- report contains `**Final Decision**: <LGTM | LGTM with Comments | Minor Issues | Blocked>`

`opencode-loop` snapshots the report directory before each review and only accepts files that are
newly written or modified by that review run (detected via mtime). Missing or malformed reports
abort the loop with an error — stale reports are never trusted.

## Development

```bash
bun install            # install dev deps
bun test               # run test suite
bun run typecheck      # tsc --noEmit
```

TDD: tests live next to sources (`src/*.test.ts`). The loop, command construction, story file
resolution, lock lifecycle, decision parsing, and fresh-report selection are all unit-tested; the
CLI itself is dependency-injected so the loop is tested without spawning real opencode processes.

## License

MIT
