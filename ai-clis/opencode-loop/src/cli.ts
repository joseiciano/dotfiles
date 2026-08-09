#!/usr/bin/env bun
/**
 * opencode-loop executable entrypoint.
 *
 * Usage: opencode-loop <ticket> [--max-attempts N] [--cwd DIR] [--opencode-bin BIN]
 */

import { readFile } from "node:fs/promises"
import { parseArgs } from "./args"
import { runLoop } from "./loop"
import { realRunner } from "./process-runner"
import { acquireLock, snapshotReportDir, findFreshReport, parseFinalDecision } from "./report"

async function main() {
	const options = parseArgs(process.argv.slice(2))

	console.log(`[opencode-loop] ticket:        ${options.ticket}`)
	console.log(`[opencode-loop] cwd:           ${options.cwd}`)
	console.log(`[opencode-loop] max-attempts:  ${options.maxAttempts}`)
	console.log(`[opencode-loop] opencode-bin:  ${options.opencodeBin}`)

	const result = await runLoop(options, {
		runner: realRunner,
		acquireLock,
		snapshotReportDir,
		findFreshReport,
		readReport: (path) => readFile(path, "utf8"),
		parseFinalDecision,
	})

	console.log(`\n[opencode-loop] LGTM after ${result.attempts} attempt(s).`)
	console.log(`[opencode-loop] report: ${result.reportPath}`)
	process.exit(0)
}

main().catch((err) => {
	console.error(`\n[opencode-loop] error: ${err instanceof Error ? err.message : String(err)}`)
	process.exit(1)
})
