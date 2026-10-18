/**
 * Knowledge-base extension for oh-my-pi.
 *
 * Appends this repo's personal KB INDEX.md and RULES.md to the system prompt
 * each turn, the omp counterpart of Claude's inject-knowledge-base.sh hook.
 * Silent outside a git repo or when the KB has neither file.
 */

import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const KB_PATH = join(homedir(), ".claude/skills/knowledge-base/scripts/kb-path.sh");

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", async (event, ctx) => {
    const result = await pi.exec("bash", [KB_PATH, ctx.cwd]).catch(() => undefined);
    const kb = result?.code === 0 ? result.stdout.trim() : "";
    if (!kb) return;

    const blocks: string[] = [];
    for (const file of ["INDEX.md", "RULES.md"]) {
      const path = join(kb, file);
      const text = await readFile(path, "utf8").catch(() => undefined);
      if (text) blocks.push(`<knowledge-base file="${path}">\n${text}\n</knowledge-base>`);
    }
    if (blocks.length === 0) return;

    return { systemPrompt: [...(event.systemPrompt ?? []), blocks.join("\n")] };
  });
}
