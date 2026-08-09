import { describe, test, expect, beforeAll, afterAll } from "bun:test"
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, chmodSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { resolveStoryPath, STORY_DIR } from "./story"

let dir: string
const storyRoot = () => join(dir, STORY_DIR)

beforeAll(() => {
	dir = mkdtempSync(join(tmpdir(), "opencode-loop-story-"))
})

afterAll(() => {
	rmSync(dir, { recursive: true, force: true })
})

describe("resolveStoryPath", () => {
	test("returns the absolute path of the single matching story file at any depth", () => {
		const nested = join(storyRoot(), "domain", "deeply", "nested")
		mkdirSync(nested, { recursive: true })
		const storyFile = join(nested, "TICKET-42-add-login.md")
		writeFileSync(storyFile, "# Story\n")
		// A sibling ticket must not count.
		writeFileSync(join(nested, "TICKET-99-unrelated.md"), "# Other\n")

		expect(resolveStoryPath(dir, "TICKET-42")).toBe(storyFile)
	})

	test("resolves relative to the given cwd", () => {
		const sub = join(dir, "sub")
		mkdirSync(sub, { recursive: true })
		const nested = join(sub, STORY_DIR, "another", "level")
		mkdirSync(nested, { recursive: true })
		const storyFile = join(nested, "ABC-7-fix-bug.md")
		writeFileSync(storyFile, "# Story\n")

		expect(resolveStoryPath(sub, "ABC-7")).toBe(storyFile)
	})

	test("ignores non-markdown files and files that do not start with the ticket prefix", () => {
		const nested = join(storyRoot(), "misc")
		mkdirSync(nested, { recursive: true })
		writeFileSync(join(nested, "MISC-8-notes.txt"), "not md\n")
		writeFileSync(join(nested, "MISC-4x-short.md"), "# no\n")
		const storyFile = join(nested, "MISC-8-real.md")
		writeFileSync(storyFile, "# yes\n")

		expect(resolveStoryPath(dir, "MISC-8")).toBe(storyFile)
	})

	test("throws with a clear error naming the ticket and root when nothing matches", () => {
		expect(() => resolveStoryPath(dir, "NO-SUCH-1")).toThrow(/NO-SUCH-1/)
		expect(() => resolveStoryPath(dir, "NO-SUCH-1")).toThrow(STORY_DIR)
	})

	test("throws listing every candidate when multiple files match", () => {
		const nested = join(storyRoot(), "dupes")
		mkdirSync(nested, { recursive: true })
		const a = join(nested, "DUP-5-first.md")
		const b = join(dir, STORY_DIR, "DUP-5-second.md")
		writeFileSync(a, "# a\n")
		writeFileSync(b, "# b\n")

		expect(() => resolveStoryPath(dir, "DUP-5")).toThrow(/Multiple story files/)
		expect(() => resolveStoryPath(dir, "DUP-5")).toThrow(a)
		expect(() => resolveStoryPath(dir, "DUP-5")).toThrow(b)
	})

	test("propagates non-ENOENT readdir errors from unreadable nested directories", () => {
		const nested = join(storyRoot(), "ok", "secret")
		mkdirSync(nested, { recursive: true })
		chmodSync(nested, 0o000)
		try {
			expect(() => resolveStoryPath(dir, "LOCKED-1")).toThrow(/EACCES|permission denied/i)
		} finally {
			chmodSync(nested, 0o755)
		}
	})

	test("throws when the stories directory does not exist", () => {
		const empty = mkdtempSync(join(tmpdir(), "opencode-loop-nostory-"))
		try {
			expect(() => resolveStoryPath(empty, "TICKET-1")).toThrow(/TICKET-1/)
		} finally {
			rmSync(empty, { recursive: true, force: true })
		}
	})
})
