import { describe, test, expect, beforeAll, afterAll } from "bun:test"
import { mkdtempSync, rmSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { parseArgs, DEFAULT_MAX_ATTEMPTS, DEFAULT_OPENCODE_BIN } from "./args"

let dir: string
beforeAll(() => {
	dir = mkdtempSync(join(tmpdir(), "opencode-loop-args-"))
})
afterAll(() => {
	rmSync(dir, { recursive: true, force: true })
})

describe("parseArgs", () => {
	test("parses ticket positional with defaults", () => {
		const opts = parseArgs(["TICKET-1"], dir)
		expect(opts.ticket).toBe("TICKET-1")
		expect(opts.maxAttempts).toBe(DEFAULT_MAX_ATTEMPTS)
		expect(opts.cwd).toBe(dir)
		expect(opts.opencodeBin).toBe(DEFAULT_OPENCODE_BIN)
	})

	test("parses --max-attempts", () => {
		const opts = parseArgs(["TICKET-1", "--max-attempts", "3"], dir)
		expect(opts.maxAttempts).toBe(3)
	})

	test("parses --cwd", () => {
		const opts = parseArgs(["TICKET-1", "--cwd", dir], dir)
		expect(opts.cwd).toBe(dir)
	})

	test("parses --opencode-bin", () => {
		const opts = parseArgs(["TICKET-1", "--opencode-bin", "/usr/bin/oc"], dir)
		expect(opts.opencodeBin).toBe("/usr/bin/oc")
	})

	test("flags may appear in any position", () => {
		const opts = parseArgs(["--max-attempts", "2", "TICKET-1", "--opencode-bin", "oc"], dir)
		expect(opts.ticket).toBe("TICKET-1")
		expect(opts.maxAttempts).toBe(2)
		expect(opts.opencodeBin).toBe("oc")
	})

	test("throws when ticket is missing", () => {
		expect(() => parseArgs([], dir)).toThrow(/ticket/)
		expect(() => parseArgs(["--max-attempts", "3"], dir)).toThrow(/ticket/)
	})

	test("throws when ticket is empty string", () => {
		expect(() => parseArgs(["", "--max-attempts", "3"], dir)).toThrow(/ticket/)
		expect(() => parseArgs(["   "], dir)).toThrow(/ticket/)
	})

	test("throws when --max-attempts is not a positive integer", () => {
		expect(() => parseArgs(["T", "--max-attempts", "0"], dir)).toThrow(/max-attempts/)
		expect(() => parseArgs(["T", "--max-attempts", "-2"], dir)).toThrow(/max-attempts/)
		expect(() => parseArgs(["T", "--max-attempts", "abc"], dir)).toThrow(/max-attempts/)
		expect(() => parseArgs(["T", "--max-attempts", "2.5"], dir)).toThrow(/max-attempts/)
	})

	test("throws when --cwd does not exist or is not a directory", () => {
		expect(() => parseArgs(["T", "--cwd", join(dir, "does-not-exist")], dir)).toThrow(
			/cwd/
		)
		const filePath = join(dir, "not-a-dir.txt")
		require("node:fs").writeFileSync(filePath, "x")
		expect(() => parseArgs(["T", "--cwd", filePath], dir)).toThrow(/cwd/)
	})

	test("throws when --opencode-bin is empty", () => {
		expect(() => parseArgs(["T", "--opencode-bin", ""], dir)).toThrow(/opencode-bin/)
		expect(() => parseArgs(["T", "--opencode-bin", "   "], dir)).toThrow(/opencode-bin/)
	})

	test("throws on unknown flag", () => {
		expect(() => parseArgs(["T", "--bogus"], dir)).toThrow(/Unknown option|bogus/)
	})

	test("defaults --cwd to process.cwd() when flag absent", () => {
		const opts = parseArgs(["T"], dir)
		expect(opts.cwd).toBe(dir)
	})
})
