/**
 * CLI argument parsing + validation.
 *
 * Usage: opencode-loop <ticket> [--max-attempts N] [--cwd DIR] [--opencode-bin BIN]
 */

import { statSync } from "node:fs"
import { resolve } from "node:path"

export const DEFAULT_MAX_ATTEMPTS = 5
export const DEFAULT_OPENCODE_BIN = "opencode"

export interface CliOptions {
	ticket: string
	maxAttempts: number
	cwd: string
	opencodeBin: string
}

/**
 * Parse argv (everything after the script path) into validated options.
 * Throws on invalid input so the CLI can exit non-zero with a clear message.
 */
export function parseArgs(argv: string[], fallbackCwd: string = process.cwd()): CliOptions {
	let ticket: string | undefined
	let maxAttempts = DEFAULT_MAX_ATTEMPTS
	let cwd = fallbackCwd
	let opencodeBin = DEFAULT_OPENCODE_BIN

	const args = [...argv]
	while (args.length > 0) {
		const arg = args.shift() as string
		switch (arg) {
			case "--max-attempts": {
				const value = args.shift()
				if (value === undefined) throw new Error("--max-attempts requires a value")
				const n = Number(value)
				if (!Number.isInteger(n) || n < 1) {
					throw new Error(
						`--max-attempts must be a positive integer, got "${value}"`
					)
				}
				maxAttempts = n
				break
			}
			case "--cwd": {
				const value = args.shift()
				if (value === undefined) throw new Error("--cwd requires a value")
				cwd = value
				break
			}
			case "--opencode-bin": {
				const value = args.shift()
				if (value === undefined) throw new Error("--opencode-bin requires a value")
				opencodeBin = value
				break
			}
			default: {
				if (arg.startsWith("-")) {
					throw new Error(`Unknown option: ${arg}`)
				}
				if (ticket === undefined) {
					ticket = arg
				} else {
					throw new Error(`Unexpected extra argument: ${arg}`)
				}
			}
		}
	}

	if (ticket === undefined || ticket.trim().length === 0) {
		throw new Error(
			"Missing required ticket (positional). Usage: opencode-loop <ticket> [--max-attempts N] [--cwd DIR] [--opencode-bin BIN]"
		)
	}
	if (opencodeBin.trim().length === 0) {
		throw new Error("--opencode-bin must not be empty")
	}

	const resolvedCwd = resolve(cwd)
	let stat
	try {
		stat = statSync(resolvedCwd)
	} catch {
		throw new Error(`--cwd does not exist: ${resolvedCwd}`)
	}
	if (!stat.isDirectory()) {
		throw new Error(`--cwd is not a directory: ${resolvedCwd}`)
	}

	return {
		ticket: ticket.trim(),
		maxAttempts,
		cwd: resolvedCwd,
		opencodeBin: opencodeBin.trim(),
	}
}
