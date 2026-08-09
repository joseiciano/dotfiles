import { describe, test, expect, beforeAll, afterAll } from "bun:test"
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, existsSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import {
	parseFinalDecision,
	isLgtm,
	KNOWN_DECISIONS,
	snapshotReportDir,
	findFreshReport,
	acquireLock,
	LOCK_FILE_NAME,
	REPORT_DIR,
} from "./report"

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms))

describe("final decision parsing", () => {
	test("parses exact LGTM", () => {
		expect(parseFinalDecision("**Final Decision**: LGTM")).toBe("LGTM")
	})

	test("parses LGTM with Comments as its own value (not LGTM)", () => {
		expect(parseFinalDecision("**Final Decision**: LGTM with Comments")).toBe(
			"LGTM with Comments"
		)
	})

	test("parses Minor Issues and Blocked", () => {
		expect(parseFinalDecision("**Final Decision**: Minor Issues")).toBe("Minor Issues")
		expect(parseFinalDecision("**Final Decision**: Blocked")).toBe("Blocked")
	})

	test("tolerates surrounding whitespace and finds line anywhere in doc", () => {
		const doc = [
			"## AI Code Review",
			"",
			"**Reason**: looks good",
			"**Final Decision**:    LGTM   ",
			"",
			"### Code Quality",
		].join("\n")
		expect(parseFinalDecision(doc)).toBe("LGTM")
	})

	test("throws when Final Decision line is missing", () => {
		expect(() => parseFinalDecision("## AI Code Review\n\nno decision here")).toThrow(
			/Final Decision/
		)
	})

	test("throws on empty report", () => {
		expect(() => parseFinalDecision("")).toThrow(/Final Decision/)
	})

	test("throws on unknown/unrecognized decision value", () => {
		expect(() =>
			parseFinalDecision("**Final Decision**: Maybe")
		).toThrow(/unrecognized|Unexpected/i)
	})

	test("KNOWN_DECISIONS are the four contract values", () => {
		expect(KNOWN_DECISIONS).toEqual([
			"LGTM",
			"LGTM with Comments",
			"Minor Issues",
			"Blocked",
		])
	})
})

describe("isLgtm", () => {
	test("only exact LGTM is a pass", () => {
		expect(isLgtm("LGTM")).toBe(true)
	})

	test("LGTM with Comments is NOT a pass", () => {
		expect(isLgtm("LGTM with Comments")).toBe(false)
	})

	test("Minor Issues and Blocked are NOT passes", () => {
		expect(isLgtm("Minor Issues")).toBe(false)
		expect(isLgtm("Blocked")).toBe(false)
	})
})

describe("fresh report selection", () => {
	let dir: string
	const reports = () => join(dir, REPORT_DIR)

	beforeAll(() => {
		dir = mkdtempSync(join(tmpdir(), "opencode-loop-report-"))
	})

	afterAll(() => {
		rmSync(dir, { recursive: true, force: true })
	})

	test("selects the newly written report, not the stale pre-existing one", async () => {
		// Stale report already on disk before review starts
		mkdirSync(reports(), { recursive: true })
		const stalePath = join(reports(), "code_review_1.md")
		writeFileSync(stalePath, "**Final Decision**: LGTM\n")
		await sleep(20)

		// Snapshot taken right before the review process starts
		const before = await snapshotReportDir(dir)
		expect(before.has(join(REPORT_DIR, "code_review_1.md"))).toBe(true)

		await sleep(20)
		// Review writes a NEW report during the run
		const freshPath = join(reports(), "code_review_2.md")
		writeFileSync(freshPath, "**Final Decision**: LGTM with Comments\n")

		const selected = await findFreshReport(dir, before)
		expect(selected).toBe(freshPath)
	})

	test("detects a modified existing report (re-write of code_review_x.md)", async () => {
		mkdirSync(reports(), { recursive: true })
		const stalePath = join(reports(), "code_review_1.md")
		writeFileSync(stalePath, "**Final Decision**: LGTM\n")
		await sleep(20)

		const before = await snapshotReportDir(dir)
		await sleep(20)
		// Same file name, modified during review (higher number)
		const modifiedPath = join(reports(), "code_review_1.md")
		writeFileSync(modifiedPath, "**Final Decision**: Minor Issues\n")

		const selected = await findFreshReport(dir, before)
		expect(selected).toBe(modifiedPath)
	})

	test("throws when no report exists in prompts/code_review/", async () => {
		const emptyDir = mkdtempSync(join(tmpdir(), "opencode-loop-empty-"))
		try {
			const before = await snapshotReportDir(emptyDir)
			expect(before.size).toBe(0)
			expect(findFreshReport(emptyDir, before)).rejects.toThrow(
				/No fresh review report/
			)
		} finally {
			rmSync(emptyDir, { recursive: true, force: true })
		}
	})

	test("accepts a new report even when its mtime precedes the review start (fs rounding)", async () => {
		const roundingDir = mkdtempSync(join(tmpdir(), "opencode-loop-rounding-"))
		try {
			mkdirSync(join(roundingDir, REPORT_DIR), { recursive: true })
			writeFileSync(
				join(roundingDir, REPORT_DIR, "code_review_1.md"),
				"**Final Decision**: LGTM\n"
			)
			await sleep(20)
			const before = await snapshotReportDir(roundingDir)
			// Filesystems round mtime down below Date.now, so a report written
			// during the review run can carry an mtime older than the review
			// start. Freshness must not rely on a wall-clock gate: the report is
			// fresh purely because it is absent from the pre-review snapshot.
			const freshPath = join(roundingDir, REPORT_DIR, "code_review_2.md")
			writeFileSync(freshPath, "**Final Decision**: LGTM with Comments\n")

			const selected = await findFreshReport(roundingDir, before)
			expect(selected).toBe(freshPath)
		} finally {
			rmSync(roundingDir, { recursive: true, force: true })
		}
	})

	test("throws when only stale (pre-review) reports exist", async () => {
		const staleOnlyDir = mkdtempSync(join(tmpdir(), "opencode-loop-stale-"))
		try {
			mkdirSync(join(staleOnlyDir, REPORT_DIR), { recursive: true })
			writeFileSync(
				join(staleOnlyDir, REPORT_DIR, "code_review_1.md"),
				"**Final Decision**: LGTM\n"
			)
			await sleep(20)
			const before = await snapshotReportDir(staleOnlyDir)
			// Only pre-existing, unchanged reports — no fresh diff against the snapshot
			expect(findFreshReport(staleOnlyDir, before)).rejects.toThrow(
				/No fresh review report/
			)
		} finally {
			rmSync(staleOnlyDir, { recursive: true, force: true })
		}
	})

	test("ignores non-matching files in the report directory", async () => {
		mkdirSync(reports(), { recursive: true })
		writeFileSync(join(reports(), "notes.txt"), "not a report\n")
		await sleep(20)
		const before = await snapshotReportDir(dir)
		await sleep(20)
		const freshPath = join(reports(), "code_review_3.md")
		writeFileSync(freshPath, "**Final Decision**: LGTM\n")
		const selected = await findFreshReport(dir, before)
		expect(selected).toBe(freshPath)
	})
})

describe("lock file", () => {
	test("acquire creates .opencode-loop.lock, second acquire errors clearly, release frees it", async () => {
		const lockDir = mkdtempSync(join(tmpdir(), "opencode-loop-lock-"))
		try {
			const lock = await acquireLock(lockDir)
			const lockPath = join(lockDir, REPORT_DIR, LOCK_FILE_NAME)
			expect(lock.path).toBe(lockPath)
			expect(existsSync(lockPath)).toBe(true)

			// Second concurrent loop in the same project is rejected clearly.
			await expect(acquireLock(lockDir)).rejects.toThrow(/already running/)
			await expect(acquireLock(lockDir)).rejects.toThrow(/lock file/)

			// Cleanup finally: release removes the lock.
			await lock.release()
			expect(existsSync(lockPath)).toBe(false)

			// Re-acquirable after release.
			const lock2 = await acquireLock(lockDir)
			expect(existsSync(lockPath)).toBe(true)
			await lock2.release()
			expect(existsSync(lockPath)).toBe(false)
		} finally {
			rmSync(lockDir, { recursive: true, force: true })
		}
	})

	test("release is safe even when called twice", async () => {
		const lockDir = mkdtempSync(join(tmpdir(), "opencode-loop-lock2-"))
		try {
			const lock = await acquireLock(lockDir)
			await lock.release()
			await lock.release()
			expect(existsSync(join(lockDir, REPORT_DIR, LOCK_FILE_NAME))).toBe(false)
		} finally {
			rmSync(lockDir, { recursive: true, force: true })
		}
	})

	test("lock file is ignored by snapshot and fresh-report selection", async () => {
		const lockDir = mkdtempSync(join(tmpdir(), "opencode-loop-lock3-"))
		try {
			const lock = await acquireLock(lockDir)
			const before = await snapshotReportDir(lockDir)
			expect(before.size).toBe(0)

			await sleep(20)
			const freshPath = join(lockDir, REPORT_DIR, "code_review_1.md")
			mkdirSync(join(lockDir, REPORT_DIR), { recursive: true })
			writeFileSync(freshPath, "**Final Decision**: LGTM\n")

			const selected = await findFreshReport(lockDir, before)
			expect(selected).toBe(freshPath)
			await lock.release()
		} finally {
			rmSync(lockDir, { recursive: true, force: true })
		}
	})
})
