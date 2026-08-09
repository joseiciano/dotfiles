/**
 * Core loop: implement -> review -> inspect report -> repeat until exact LGTM.
 *
 * Dependencies are injected so the loop is testable without spawning real
 * opencode processes. `src/process-runner.ts` provides the production runner
 * (child processes with inherited stdio).
 */

import type { CliOptions } from "./args"
import {
	buildImplementCommand,
	buildReviewCommand,
	buildFollowUpCommand,
} from "./commands"
import { isLgtm } from "./report"

export interface ProcessResult {
	/** Exit code, or null when the process was killed by a signal. */
	code: number | null
}

export interface ProcessRunner {
	run(command: string[], opts: { cwd: string }): Promise<ProcessResult>
}

/** Handle to the per-project lock acquired before the loop starts. */
export interface LockHandle {
	path: string
	release(): Promise<void>
}

export interface LoopDeps {
	runner: ProcessRunner
	acquireLock: (cwd: string) => Promise<LockHandle>
	snapshotReportDir: (cwd: string) => Promise<Map<string, number>>
	findFreshReport: (cwd: string, before: Map<string, number>) => Promise<string>
	readReport: (path: string) => Promise<string>
	parseFinalDecision: (content: string) => string
}

export interface LoopResult {
	decision: string
	attempts: number
	reportPath: string
}

export async function runLoop(options: CliOptions, deps: LoopDeps): Promise<LoopResult> {
	const lock = await deps.acquireLock(options.cwd)
	let lastReportPath: string | null = null
	let lastDecision: string | null = null

	try {
		for (let attempt = 1; attempt <= options.maxAttempts; attempt++) {
			console.log(`\n[opencode-loop] --- attempt ${attempt}/${options.maxAttempts} ---`)

			const implementCommand =
				attempt === 1
					? buildImplementCommand(options.opencodeBin, options.ticket)
					: buildFollowUpCommand(
							options.opencodeBin,
							options.ticket,
							lastReportPath as string,
							lastDecision as string
						)

			console.log(`[opencode-loop] $ ${implementCommand.join(" ")}`)
			const implResult = await deps.runner.run(implementCommand, { cwd: options.cwd })
			if (implResult.code !== 0) {
				throw new Error(
					`implement command failed with exit code ${implResult.code ?? "spawn error"}`
				)
			}

			// Snapshot report files before the review starts so a fresh report can
			// be distinguished from stale ones purely by the snapshot diff.
			const before = await deps.snapshotReportDir(options.cwd)

			const reviewCommand = buildReviewCommand(options.opencodeBin, options.ticket)
			console.log(`[opencode-loop] $ ${reviewCommand.join(" ")}`)
			const reviewResult = await deps.runner.run(reviewCommand, { cwd: options.cwd })
			if (reviewResult.code !== 0) {
				throw new Error(
					`review command failed with exit code ${reviewResult.code ?? "spawn error"}`
				)
			}

			const reportPath = await deps.findFreshReport(options.cwd, before)
			const content = await deps.readReport(reportPath)
			const decision = deps.parseFinalDecision(content)

			console.log(`[opencode-loop] review report: ${reportPath}`)
			console.log(`[opencode-loop] final decision: ${decision}`)

			if (isLgtm(decision)) {
				return { decision, attempts: attempt, reportPath }
			}

			lastReportPath = reportPath
			lastDecision = decision
		}

		throw new Error(
			`no LGTM after ${options.maxAttempts} attempt(s) ` +
				`(last decision: ${lastDecision ?? "none"}, last report: ${lastReportPath ?? "none"}). ` +
				`Fix findings and re-run, or raise --max-attempts.`
		)
	} finally {
		await lock.release()
	}
}
