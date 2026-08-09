/**
 * Story file resolution.
 *
 * Every ticket maps to exactly one story Markdown file at
 * `docs/product/stories/stories/` in any nested subdirectory, named
 * `<ticket>-*.md`, relative to `--cwd`. The absolute path is resolved once,
 * before the loop starts, so every implement / review invocation receives the
 * exact same story file as part of its prompt.
 */

import { readdirSync } from "node:fs"
import { join } from "node:path"

/** Story root relative to the project cwd. */
export const STORY_DIR = "docs/product/stories/stories"

/**
 * Recursively locate the single story file matching `<ticket>-*.md` anywhere
 * under `docs/product/stories/stories/` in `cwd`. Returns the absolute path.
 *
 * Throws when nothing matches (naming the ticket and the searched root) or
 * when several files match (listing every candidate) so the CLI can fail
 * clearly before any loop work begins.
 */
export function resolveStoryPath(cwd: string, ticket: string): string {
	const root = join(cwd, STORY_DIR)
	const prefix = `${ticket}-`
	const matches: string[] = []

	walk(root)

	if (matches.length === 0) {
		throw new Error(
			`No story file found for ticket "${ticket}": ` +
				`expected exactly one file matching ${ticket}-*.md ` +
				`under ${STORY_DIR}/ (searched ${root}).`
		)
	}
	if (matches.length > 1) {
		throw new Error(
			`Multiple story files match ticket "${ticket}" (expected exactly one):\n` +
				matches.map((path) => `  - ${path}`).join("\n")
		)
	}
	return matches[0]

	function walk(dir: string): void {
		let entries
		try {
			entries = readdirSync(dir, { withFileTypes: true })
		} catch (err) {
			// Only a missing story root (ENOENT) means "no story" — unreadable
			// dirs and any nested readdir error are real failures that must
			// surface instead of silently yielding a "no story found" error.
			if (dir === root && isMissingDir(err)) return
			throw err
		}
		for (const entry of entries) {
			const full = join(dir, entry.name)
			if (entry.isDirectory()) {
				walk(full)
			} else if (
				entry.isFile() &&
				entry.name.endsWith(".md") &&
				entry.name.startsWith(prefix)
			) {
				matches.push(full)
			}
		}
	}
}

/** True when the error means the directory itself does not exist (ENOENT). */
function isMissingDir(err: unknown): boolean {
	return (
		typeof err === "object" &&
		err !== null &&
		"code" in err &&
		(err as NodeJS.ErrnoException).code === "ENOENT"
	)
}
