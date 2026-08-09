/**
 * Command construction for the opencode-loop.
 *
 * Each `opencode run` invocation starts a fresh, non-interactive session, so
 * every implement / review step is built as a standalone argv array. No
 * session state is shared between invocations; follow-up prompts must carry
 * the full ticket context plus the exact path of the previous review report.
 *
 * The opencode `--command` flag takes the custom command NAME (`implement` /
 * `review`); everything else is passed as message positionals. That keeps the
 * prompt out of argv[0] position and out of any shell.
 */

/** First implementation pass argv: `opencode run --command implement <ticket>`. */
export function buildImplementCommand(bin: string, ticket: string): string[] {
	return [bin, "run", "--command", "implement", ticket]
}

/** Review pass argv: `opencode run --command review <ticket>`. */
export function buildReviewCommand(bin: string, ticket: string): string[] {
	return [bin, "run", "--command", "review", ticket]
}

/**
 * Single message positional carrying all follow-up directives. The agent
 * receives the ticket, the exact path of the review report and what to fix —
 * WITHOUT pasting the report body; the agent must read the file itself.
 */
export function buildFollowUpArg(
	ticket: string,
	reportPath: string,
	decision: string
): string {
	return [
		ticket,
		"",
		`The previous review was not approved (Final Decision: ${decision}).`,
		`Read the review report at: ${reportPath}`,
		"",
		"Fix every [BLOCKING] and [WARNING] finding in that report.",
		"Do not paste the report content here — read the file at the given path.",
	].join("\n")
}

/**
 * Follow-up implementation pass argv: `opencode run --command implement`
 * followed by one message positional holding all directives.
 */
export function buildFollowUpCommand(
	bin: string,
	ticket: string,
	reportPath: string,
	decision: string
): string[] {
	return [bin, "run", "--command", "implement", buildFollowUpArg(ticket, reportPath, decision)]
}
