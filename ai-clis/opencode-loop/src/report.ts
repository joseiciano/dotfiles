/**
 * Review report handling.
 *
 * Contract (see review SKILL.md): the review agent writes its report to
 * `prompts/code_review/code_review_x.md` (x starts at 1, increments when the
 * file exists) relative to the project cwd, containing a line
 * `**Final Decision**: <LGTM | LGTM with Comments | Minor Issues | Blocked>`.
 */

import { promises as fs } from "node:fs"
import { join } from "node:path"

/** Report directory relative to the project cwd. */
export const REPORT_DIR = "prompts/code_review"

/** Only `code_review_*.md` files count as reports. */
export const REPORT_FILE_RE = /^code_review_\d+\.md$/

/** Lock file placed inside the report directory while a loop is running. */
export const LOCK_FILE_NAME = ".opencode-loop.lock"

/** Handle to an acquired project lock. */
export interface LockHandle {
	path: string
	release(): Promise<void>
}

/**
 * Atomically acquire the per-project lock (`.opencode-loop.lock` inside
 * `prompts/code_review/`). `wx` open fails with EEXIST if another loop is
 * already running in the same project, so concurrent runs can never race on
 * the shared report directory. Throws a clear error on contention.
 */
export async function acquireLock(cwd: string): Promise<LockHandle> {
	const reportDir = join(cwd, REPORT_DIR)
	const lockPath = join(reportDir, LOCK_FILE_NAME)
	await fs.mkdir(reportDir, { recursive: true })

	let handle: Awaited<ReturnType<typeof fs.open>> | undefined
	try {
		handle = await fs.open(lockPath, "wx")
		await handle.writeFile(`${process.pid}\n`)
	} catch (err) {
		if ((err as NodeJS.ErrnoException).code === "EEXIST") {
			throw new Error(
				`opencode-loop is already running in this project ` +
					`(lock file: ${lockPath}). ` +
					`If the previous run crashed, delete the lock file and re-run.`
			)
		}
		// Leave no half-created lock behind on non-contention errors.
		if (handle) await fs.rm(lockPath, { force: true }).catch(() => {})
		throw err
	}

	return {
		path: lockPath,
		async release() {
			if (handle) {
				try {
					await handle.close()
				} catch {
					// already closed — ignore
				}
			}
			await fs.rm(lockPath, { force: true })
		},
	}
}

/** The four contract values for `**Final Decision**`. */
export const KNOWN_DECISIONS = [
	"LGTM",
	"LGTM with Comments",
	"Minor Issues",
	"Blocked",
] as const

type KnownDecision = (typeof KNOWN_DECISIONS)[number]

/**
 * Parse the `**Final Decision**: <value>` line out of a review report.
 * Returns the raw decision value. Throws when the line is missing or the
 * value is not one of the four contract decisions (malformed report).
 */
export function parseFinalDecision(content: string): string {
	const match = content.match(/^\*\*\s*Final Decision\s*\*\*\s*:\s*(.+?)\s*$/m)
	if (!match || !match[1]) {
		throw new Error(
			"Malformed review report: missing `**Final Decision**: <value>` line"
		)
	}
	const value = match[1].trim()
	if (!KNOWN_DECISIONS.includes(value as KnownDecision)) {
		throw new Error(
			`Malformed review report: unrecognized final decision "${value}". ` +
				`Expected one of: ${KNOWN_DECISIONS.join(", ")}`
		)
	}
	return value
}

/**
 * Only an exact "LGTM" passes. "LGTM with Comments" must repeat because the
 * loop only stops on a bare LGTM.
 */
export function isLgtm(decision: string): boolean {
	return decision === "LGTM"
}

/**
 * Snapshot every existing report file (relative path -> mtimeMs) BEFORE a
 * review run starts, so a fresh report can be distinguished from stale ones.
 * A missing report directory is not an error (nothing to snapshot).
 */
export async function snapshotReportDir(cwd: string): Promise<Map<string, number>> {
	const map = new Map<string, number>()
	const reportDir = join(cwd, REPORT_DIR)
	let entries: import("node:fs").Dirent[]
	try {
		entries = await fs.readdir(reportDir, { withFileTypes: true })
	} catch (err) {
		if ((err as NodeJS.ErrnoException).code === "ENOENT") return map
		throw err
	}
	for (const entry of entries) {
		if (!entry.isFile() || !REPORT_FILE_RE.test(entry.name)) continue
		const stat = await fs.stat(join(reportDir, entry.name))
		map.set(join(REPORT_DIR, entry.name), stat.mtimeMs)
	}
	return map
}

/**
 * Find the report written or modified by the most recent review run.
 *
 * Freshness is determined purely by the diff against the pre-review snapshot:
 * a candidate is a `code_review_*.md` file that is either brand new (absent
 * from the snapshot) or whose mtime moved past its snapshot value. There is no
 * wall-clock time gate — filesystem mtime can be rounded down below `Date.now`
 * and still be a valid fresh report. Among candidates, the file with the
 * latest mtime wins.
 *
 * Throws when no fresh report exists after the review run.
 */
export async function findFreshReport(
	cwd: string,
	before: Map<string, number>
): Promise<string> {
	const reportDir = join(cwd, REPORT_DIR)
	let entries: import("node:fs").Dirent[]
	try {
		entries = await fs.readdir(reportDir, { withFileTypes: true })
	} catch (err) {
		if ((err as NodeJS.ErrnoException).code === "ENOENT") {
			throw new Error(
				`No fresh review report found: ${REPORT_DIR} does not exist after review run`
			)
		}
		throw err
	}

	let best: { path: string; mtimeMs: number } | null = null
	for (const entry of entries) {
		if (!entry.isFile() || !REPORT_FILE_RE.test(entry.name)) continue
		const stat = await fs.stat(join(reportDir, entry.name))

		const prevMtimeMs = before.get(join(REPORT_DIR, entry.name))
		const isNew = prevMtimeMs === undefined
		const isModified = !isNew && stat.mtimeMs > prevMtimeMs
		const isFresh = isNew || isModified

		if (!isFresh) continue

		if (!best || stat.mtimeMs > best.mtimeMs) {
			best = { path: join(reportDir, entry.name), mtimeMs: stat.mtimeMs }
		}
	}

	if (!best) {
		throw new Error(
			`No fresh review report found in ${REPORT_DIR} after review run`
		)
	}
	return best.path
}
