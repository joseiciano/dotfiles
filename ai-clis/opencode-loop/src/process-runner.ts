/**
 * Production process runner: spawns child processes with inherited stdio so
 * opencode's output stays visible on the terminal.
 */

import { spawn } from "node:child_process"
import type { ProcessResult, ProcessRunner } from "./loop"

export const realRunner: ProcessRunner = {
	run(command, opts) {
		return new Promise((resolve) => {
			const child = spawn(command[0], command.slice(1), {
				cwd: opts.cwd,
				stdio: "inherit",
			})
			child.on("exit", (code) => resolve({ code }))
			child.on("error", (err) => {
				console.error(`[opencode-loop] failed to spawn ${command[0]}: ${err.message}`)
				resolve({ code: -1 })
			})
		})
	},
}
