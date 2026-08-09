import { describe, test, expect } from "bun:test"
import {
	buildImplementCommand,
	buildReviewCommand,
	buildFollowUpCommand,
	buildFollowUpArg,
} from "./commands"

describe("command construction", () => {
	describe("buildImplementCommand", () => {
		test("builds `opencode run --command implement <ticket>`", () => {
			expect(buildImplementCommand("opencode", "TICKET-123")).toEqual([
				"opencode",
				"run",
				"--command",
				"implement",
				"TICKET-123",
			])
		})

		test("uses custom opencode bin", () => {
			expect(buildImplementCommand("/usr/local/bin/oc", "ABC-1")).toEqual([
				"/usr/local/bin/oc",
				"run",
				"--command",
				"implement",
				"ABC-1",
			])
		})

		test("ticket with spaces and special chars stays a single positional", () => {
			const cmd = buildImplementCommand("opencode", "my ticket /path @x")
			expect(cmd).toEqual([
				"opencode",
				"run",
				"--command",
				"implement",
				"my ticket /path @x",
			])
			// bin + run + --command + implement + one message arg
			expect(cmd.length).toBe(5)
		})
	})

	describe("buildReviewCommand", () => {
		test("builds `opencode run --command review <ticket>`", () => {
			expect(buildReviewCommand("opencode", "TICKET-42")).toEqual([
				"opencode",
				"run",
				"--command",
				"review",
				"TICKET-42",
			])
		})

		test("uses custom opencode bin", () => {
			expect(buildReviewCommand("oc", "T-1")).toEqual([
				"oc",
				"run",
				"--command",
				"review",
				"T-1",
			])
		})
	})

	describe("buildFollowUpCommand", () => {
		test("all directives live in the single positional after implement", () => {
			const cmd = buildFollowUpCommand(
				"opencode",
				"TICKET-42",
				"/abs/path/prompts/code_review/code_review_2.md",
				"Minor Issues"
			)
			expect(cmd[0]).toBe("opencode")
			expect(cmd[1]).toBe("run")
			expect(cmd[2]).toBe("--command")
			expect(cmd[3]).toBe("implement")
			expect(cmd.length).toBe(5)
			expect(cmd[4]).toContain("TICKET-42")
			expect(cmd[4]).toContain("/abs/path/prompts/code_review/code_review_2.md")
			expect(cmd[4]).toContain("[BLOCKING]")
			expect(cmd[4]).toContain("[WARNING]")
			expect(cmd[4]).toContain("Minor Issues")
			expect(cmd[4]).toContain("Do not paste")
		})

		test("does not embed the report body — only the path is referenced", () => {
			const arg = buildFollowUpArg(
				"TICKET-42",
				"prompts/code_review/code_review_3.md",
				"Blocked"
			)
			// report content never lives in the message arg
			expect(arg).not.toContain("**Final Decision**")
		})
	})

	describe("buildFollowUpArg", () => {
		test("single arg carries ticket plus directives", () => {
			const arg = buildFollowUpArg("TICKET-42", "reports/r.md", "LGTM with Comments")
			expect(arg.startsWith("TICKET-42")).toBe(true)
			expect(arg).toContain("reports/r.md")
			expect(arg).toContain("Fix every [BLOCKING] and [WARNING] finding")
			expect(arg).toContain("LGTM with Comments")
			expect(arg).toContain("Read the review report at:")
		})
	})
})
