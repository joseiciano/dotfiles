import { describe, test, expect, mock } from "bun:test"
import { runLoop, LoopDeps, ProcessResult } from "./loop"
import type { CliOptions } from "./args"

interface IterStep {
	implementExit: number
	reviewExit: number
	reportPath: string
	reportContent: string
	decision: string
}

function makeDeps(iters: IterStep[]) {
	const calls: Array<{ command: string[]; cwd: string }> = []
	const runner = mock(async (command: string[], opts: { cwd: string }): Promise<ProcessResult> => {
		calls.push({ command, cwd: opts.cwd })
		const callIndex = calls.length - 1
		const iterIndex = Math.floor(callIndex / 2)
		const isReview = callIndex % 2 === 1
		const step = iters[iterIndex]
		if (!step) throw new Error(`no mocked step for call ${callIndex}`)
		return { code: isReview ? step.reviewExit : step.implementExit }
	})

	const release = mock(async () => {})
	const acquireLock = mock(async () => ({
		path: "/proj/prompts/code_review/.opencode-loop.lock",
		release,
	}))

	let iter = 0
	const deps: LoopDeps = {
		runner: { run: runner },
		acquireLock,
		snapshotReportDir: mock(async () => new Map<string, number>()),
		findFreshReport: mock(async () => iters[iter].reportPath),
		readReport: mock(async () => iters[iter].reportContent),
		parseFinalDecision: mock((content: string) => {
			const decision = iters[iter].decision
			iter++
			return decision
		}),
	}
	return { deps, calls, acquireLock, release }
}

function options(overrides?: Partial<CliOptions>): CliOptions {
	return {
		ticket: "TICKET-42",
		maxAttempts: 5,
		cwd: "/proj",
		opencodeBin: "opencode",
		...overrides,
	}
}

describe("runLoop", () => {
	describe("first pass LGTM", () => {
		test("runs implement then review once, returns LGTM, exit 0 path", async () => {
			const r1 = "prompts/code_review/code_review_1.md"
			const { deps, calls, acquireLock, release } = makeDeps([
				{
					implementExit: 0,
					reviewExit: 0,
					reportPath: r1,
					reportContent: "**Final Decision**: LGTM",
					decision: "LGTM",
				},
			])

			const result = await runLoop(options(), deps)

			expect(result.decision).toBe("LGTM")
			expect(result.attempts).toBe(1)
			expect(result.reportPath).toBe(r1)
			expect(calls).toHaveLength(2)
			expect(calls[0].command).toEqual([
				"opencode",
				"run",
				"--command",
				"implement",
				"TICKET-42",
			])
			expect(calls[1].command).toEqual([
				"opencode",
				"run",
				"--command",
				"review",
				"TICKET-42",
			])
			expect(calls[0].cwd).toBe("/proj")
			expect(calls[1].cwd).toBe("/proj")
			expect(acquireLock).toHaveBeenCalledTimes(1)
			expect(acquireLock).toHaveBeenCalledWith("/proj")
			expect(release).toHaveBeenCalledTimes(1)
		})
	})

	describe("LGTM with Comments must repeat", () => {
		test("repeats implementation with report path until exact LGTM", async () => {
			const r1 = "prompts/code_review/code_review_1.md"
			const r2 = "prompts/code_review/code_review_2.md"
			const { deps, calls } = makeDeps([
				{
					implementExit: 0,
					reviewExit: 0,
					reportPath: r1,
					reportContent: "**Final Decision**: LGTM with Comments",
					decision: "LGTM with Comments",
				},
				{
					implementExit: 0,
					reviewExit: 0,
					reportPath: r2,
					reportContent: "**Final Decision**: LGTM",
					decision: "LGTM",
				},
			])

			const result = await runLoop(options(), deps)

			expect(result.decision).toBe("LGTM")
			expect(result.attempts).toBe(2)
			expect(result.reportPath).toBe(r2)

			// implement, review, follow-up implement, review
			expect(calls).toHaveLength(4)
			const followUp = calls[2].command
			expect(followUp[0]).toBe("opencode")
			expect(followUp[1]).toBe("run")
			expect(followUp[2]).toBe("--command")
			expect(followUp[3]).toBe("implement")
			const arg = followUp[4]
			expect(arg).toContain(r1)
			expect(arg).toContain("[BLOCKING]")
			expect(arg).toContain("[WARNING]")
			expect(arg).toContain("LGTM with Comments")
			expect(arg).toContain("TICKET-42")
			expect(arg).toContain("Do not paste")
			// Final review carries the ticket too
			expect(calls[3].command).toEqual([
				"opencode",
				"run",
				"--command",
				"review",
				"TICKET-42",
			])
		})
	})

	describe("minor issues repeat chain", () => {
		test("repeats on Minor Issues until LGTM", async () => {
			const r1 = "prompts/code_review/code_review_1.md"
			const r2 = "prompts/code_review/code_review_2.md"
			const { deps } = makeDeps([
				{
					implementExit: 0,
					reviewExit: 0,
					reportPath: r1,
					reportContent: "**Final Decision**: Minor Issues",
					decision: "Minor Issues",
				},
				{
					implementExit: 0,
					reviewExit: 0,
					reportPath: r2,
					reportContent: "**Final Decision**: LGTM",
					decision: "LGTM",
				},
			])
			const result = await runLoop(options(), deps)
			expect(result.attempts).toBe(2)
			expect(result.decision).toBe("LGTM")
		})
	})

	describe("max attempts exhausted", () => {
		test("throws after maxAttempts without LGTM", async () => {
			const r1 = "prompts/code_review/code_review_1.md"
			const r2 = "prompts/code_review/code_review_2.md"
			const { deps, calls } = makeDeps([
				{
					implementExit: 0,
					reviewExit: 0,
					reportPath: r1,
					reportContent: "**Final Decision**: Blocked",
					decision: "Blocked",
				},
				{
					implementExit: 0,
					reviewExit: 0,
					reportPath: r2,
					reportContent: "**Final Decision**: Blocked",
					decision: "Blocked",
				},
			])

			await expect(runLoop(options({ maxAttempts: 2 }), deps)).rejects.toThrow(
				/max|attempt|exhausted/i
			)
			// 2 implement runs + 2 review runs
			expect(calls).toHaveLength(4)
		})
	})

	describe("nonzero child process", () => {
		test("throws when implement exits nonzero", async () => {
			const { deps } = makeDeps([
				{
					implementExit: 1,
					reviewExit: 0,
					reportPath: "x",
					reportContent: "x",
					decision: "LGTM",
				},
			])
			await expect(runLoop(options(), deps)).rejects.toThrow(/implement.*(failed|exit)/i)
		})

		test("throws when review exits nonzero", async () => {
			const { deps } = makeDeps([
				{
					implementExit: 0,
					reviewExit: 3,
					reportPath: "x",
					reportContent: "x",
					decision: "LGTM",
				},
			])
			await expect(runLoop(options(), deps)).rejects.toThrow(/review.*(failed|exit)/i)
		})
	})

	describe("fresh report wiring", () => {
		test("snapshots before review and passes the snapshot to findFreshReport", async () => {
			const r1 = "prompts/code_review/code_review_1.md"
			const snap = mock(async () => new Map<string, number>())
			const find = mock(async (_cwd: string, _before: Map<string, number>) => {
				return r1
			})

			const { deps, calls } = makeDeps([
				{
					implementExit: 0,
					reviewExit: 0,
					reportPath: r1,
					reportContent: "**Final Decision**: LGTM",
					decision: "LGTM",
				},
			])
			deps.snapshotReportDir = snap
			deps.findFreshReport = find

			const result = await runLoop(options(), deps)

			expect(result.decision).toBe("LGTM")
			expect(snap).toHaveBeenCalledTimes(1)
			expect(find).toHaveBeenCalledTimes(1)
			expect(find.mock.calls[0][0]).toBe("/proj")
			expect(calls).toHaveLength(2)
		})
	})

	describe("lock lifecycle", () => {
		test("releases lock when implement command fails", async () => {
			const { deps, release, calls } = makeDeps([
				{
					implementExit: 1,
					reviewExit: 0,
					reportPath: "x",
					reportContent: "x",
					decision: "LGTM",
				},
			])
			await expect(runLoop(options(), deps)).rejects.toThrow(/implement.*(failed|exit)/i)
			expect(release).toHaveBeenCalledTimes(1)
			expect(calls).toHaveLength(1)
		})

		test("releases lock when review command fails", async () => {
			const { deps, release } = makeDeps([
				{
					implementExit: 0,
					reviewExit: 3,
					reportPath: "x",
					reportContent: "x",
					decision: "LGTM",
				},
			])
			await expect(runLoop(options(), deps)).rejects.toThrow(/review.*(failed|exit)/i)
			expect(release).toHaveBeenCalledTimes(1)
		})

		test("releases lock when report is missing", async () => {
			const { deps, release } = makeDeps([
				{
					implementExit: 0,
					reviewExit: 0,
					reportPath: "x",
					reportContent: "x",
					decision: "LGTM",
				},
			])
			deps.findFreshReport = mock(async () => {
				throw new Error("No fresh review report found")
			})
			await expect(runLoop(options(), deps)).rejects.toThrow(/No fresh review report/)
			expect(release).toHaveBeenCalledTimes(1)
		})

		test("propagates lock contention without spawning any child", async () => {
			const { deps, calls } = makeDeps([
				{
					implementExit: 0,
					reviewExit: 0,
					reportPath: "x",
					reportContent: "x",
					decision: "LGTM",
				},
			])
			deps.acquireLock = mock(async () => {
				throw new Error(
					"opencode-loop is already running in this project (lock file: /proj/prompts/code_review/.opencode-loop.lock)"
				)
			})
			await expect(runLoop(options(), deps)).rejects.toThrow(/already running/)
			expect(calls).toHaveLength(0)
		})
	})
})
