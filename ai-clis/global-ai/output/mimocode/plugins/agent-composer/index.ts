import type { Plugin, Config } from "@opencode-ai/plugin";
import { readdirSync, readFileSync, existsSync } from "fs";
import { join, basename, extname, dirname, resolve, isAbsolute, relative, normalize } from "path";
import { homedir } from "os";
import { fileURLToPath } from "url";
import YAML from "yaml";

const AGENTS_DIR = "agents";
const SHARED_DIR = "agents_shared";

function parseFrontmatter(
  content: string,
  contextLabel: string
): { frontmatter: Record<string, unknown>; body: string; warnings: string[] } {
  const warnings: string[] = [];
  const lines = content.split(/\r?\n/);

  if (lines.length === 0 || lines[0].trim() !== "---") {
    return { frontmatter: {}, body: content, warnings };
  }

  let endIndex = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === "---") {
      endIndex = i;
      break;
    }
  }

  if (endIndex === -1) {
    warnings.push(
      `[agent-composer] File ${contextLabel} starts with "---" but has no closing frontmatter delimiter; treating entire file as body`
    );
    return { frontmatter: {}, body: content, warnings };
  }

  const yamlText = lines.slice(1, endIndex).join("\n");
  const body = lines.slice(endIndex + 1).join("\n").trimStart();

  let frontmatter: Record<string, unknown> = {};
  if (yamlText.trim()) {
    try {
      frontmatter = YAML.parse(yamlText) ?? {};
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      warnings.push(
        `[agent-composer] Failed to parse frontmatter YAML in ${contextLabel}: ${message}`
      );
      frontmatter = {};
    }
  }

  return { frontmatter, body, warnings };
}

function normalizeFrontmatterAliases(frontmatter: Record<string, unknown>): Record<string, unknown> {
  const normalized = { ...frontmatter };
  if ("permissions" in normalized && !("permission" in normalized)) {
    normalized.permission = normalized.permissions;
    delete normalized.permissions;
  }
  if ("maxSteps" in normalized && !("steps" in normalized)) {
    normalized.steps = normalized.maxSteps;
    delete normalized.maxSteps;
  }
  return normalized;
}

function getSharedNames(frontmatter: Record<string, unknown>): string[] {
  const shared = frontmatter.shared;
  if (shared === undefined || shared === null) return [];
  if (typeof shared === "string") return [shared];
  if (Array.isArray(shared)) {
    return shared.filter((s): s is string => typeof s === "string");
  }
  return [];
}

function isSafeSharedName(name: string): boolean {
  if (!name || name.includes("\\")) return false;
  const clean = name.replace(/\//g, "").replace(/\\/g, "");
  if (!clean) return false;
  return true;
}

function getApprovedRoots(pluginDir: string): string[] {
  return [
    join(pluginDir, SHARED_DIR),
    join(pluginDir, "references"),
    join(pluginDir, "..", "..", "skills"),
    join(homedir(), ".config", "opencode", "skills"),
  ];
}

function isPathInside(filePath: string, root: string): boolean {
  const rel = relative(root, filePath);
  return !rel.startsWith("..") && !isAbsolute(rel);
}

function resolveSharedPath(
  pluginDir: string,
  fromFilePath: string,
  name: string
): { filePath: string; label: string } | null {
  let filePath: string;
  let label: string;

  if (name.includes("/") || name.includes("\\")) {
    filePath = resolve(dirname(fromFilePath), name);
    if (!name.endsWith(".md")) {
      filePath += ".md";
    }
    label = name;
  } else {
    const fileName = name.endsWith(".md") ? name : `${name}.md`;
    filePath = join(pluginDir, SHARED_DIR, fileName);
    label = `${SHARED_DIR}/${fileName}`;
  }

  const normalizedPath = normalize(filePath);
  const approvedRoots = getApprovedRoots(pluginDir);

  for (const root of approvedRoots) {
    if (isPathInside(normalizedPath, root)) {
      return { filePath: normalizedPath, label };
    }
  }

  return null;
}

function demoteHeadings(content: string, depth: number): string {
  if (depth <= 0) return content;
  const lines = content.split(/\r?\n/);
  const result: string[] = [];
  let inFence = false;
  let fenceChar = "";
  let fenceLen = 0;

  for (const line of lines) {
    const trimmed = line.trimStart();
    const fenceMatch = trimmed.match(/^(```+|~~~+)(?:\s|$)/);
    if (fenceMatch) {
      const char = fenceMatch[1][0];
      const len = fenceMatch[1].length;
      if (!inFence) {
        inFence = true;
        fenceChar = char;
        fenceLen = len;
      } else if (char === fenceChar && len >= fenceLen) {
        inFence = false;
        fenceChar = "";
        fenceLen = 0;
      }
      result.push(line);
      continue;
    }

    if (!inFence) {
      const match = line.match(/^(#{1,6})(\s+.*|$)/);
      if (match) {
        const currentLevel = match[1].length;
        const newLevel = Math.min(currentLevel + depth, 6);
        result.push("#".repeat(newLevel) + line.slice(currentLevel));
        continue;
      }
    }

    result.push(line);
  }

  return result.join("\n");
}

function composeShared(
  pluginDir: string,
  filePath: string,
  depth: number,
  stack: Set<string>
): { content: string; warnings: string[] } {
  const warnings: string[] = [];
  const parts: string[] = [];

  if (stack.has(filePath)) {
    warnings.push(
      `[agent-composer] Cyclic shared include detected at ${filePath}; skipping to avoid infinite recursion`
    );
    return { content: "", warnings };
  }

  if (!existsSync(filePath)) {
    warnings.push(`[agent-composer] Missing shared file: ${filePath}`);
    return { content: "", warnings };
  }

  let content: string;
  try {
    content = readFileSync(filePath, "utf-8");
  } catch {
    warnings.push(`[agent-composer] Failed to read shared file: ${filePath}`);
    return { content: "", warnings };
  }

  const label = relative(pluginDir, filePath) || filePath;
  const { frontmatter, body, warnings: parseWarnings } = parseFrontmatter(content, label);
  warnings.push(...parseWarnings);

  const sharedNames = getSharedNames(frontmatter);

  const newStack = new Set(stack);
  newStack.add(filePath);

  if (body.trim()) {
    parts.push(demoteHeadings(body.trim(), depth));
  }

  for (const name of sharedNames) {
    if (!isSafeSharedName(name)) {
      warnings.push(
        `[agent-composer] Rejected unsafe shared reference "${name}" in ${label}`
      );
      continue;
    }

    const resolved = resolveSharedPath(pluginDir, filePath, name);
    if (!resolved) {
      warnings.push(
        `[agent-composer] Rejected disallowed shared reference "${name}" in ${label} (resolved path is outside approved roots)`
      );
      continue;
    }

    const { content: nestedContent, warnings: nestedWarnings } = composeShared(
      pluginDir,
      resolved.filePath,
      depth + 1,
      newStack
    );
    warnings.push(...nestedWarnings);

    if (nestedContent) {
      parts.push(nestedContent);
    }
  }

  return { content: parts.join("\n\n"), warnings };
}

function loadSharedContent(
  pluginDir: string,
  sharedNames: string[],
  agentFileName: string
): { content: string; warnings: string[] } {
  const parts: string[] = [];
  const warnings: string[] = [];
  const agentFilePath = join(pluginDir, AGENTS_DIR, agentFileName);

  for (const name of sharedNames) {
    if (!isSafeSharedName(name)) {
      warnings.push(
        `[agent-composer] Rejected unsafe shared reference "${name}" in ${AGENTS_DIR}/${agentFileName}`
      );
      continue;
    }

    const resolved = resolveSharedPath(pluginDir, agentFilePath, name);
    if (!resolved) {
      warnings.push(
        `[agent-composer] Rejected disallowed shared reference "${name}" in ${AGENTS_DIR}/${agentFileName} (resolved path is outside approved roots)`
      );
      continue;
    }

    const { content, warnings: composeWarnings } = composeShared(
      pluginDir,
      resolved.filePath,
      1,
      new Set()
    );
    warnings.push(...composeWarnings);

    if (content) {
      parts.push(content);
    }
  }

  return { content: parts.join("\n\n"), warnings };
}

function buildAgentConfig(
  pluginDir: string,
  fileName: string,
  content: string
): { agentName: string; config: Record<string, unknown>; warnings: string[] } {
  const { frontmatter: rawFrontmatter, body, warnings: parseWarnings } = parseFrontmatter(
    content,
    `${AGENTS_DIR}/${fileName}`
  );
  const frontmatter = normalizeFrontmatterAliases(rawFrontmatter);

  const agentName =
    typeof frontmatter.name === "string" && frontmatter.name.trim()
      ? frontmatter.name.trim()
      : basename(fileName, extname(fileName));

  const sharedNames = getSharedNames(frontmatter);
  const { content: sharedContent, warnings: sharedWarnings } = loadSharedContent(
    pluginDir,
    sharedNames,
    fileName
  );

  const promptParts: string[] = [];
  if (body.trim()) promptParts.push(body.trim());
  if (sharedContent) promptParts.push(sharedContent);

  const { shared: _, name: __, ...restFrontmatter } = frontmatter;

  const agentConfig: Record<string, unknown> = {
    ...restFrontmatter,
  };

  if (promptParts.length > 0) {
    agentConfig.prompt = promptParts.join("\n\n");
  }

  return { agentName, config: agentConfig, warnings: [...parseWarnings, ...sharedWarnings] };
}

const agentComposerPlugin: Plugin = async (input) => {
  const pluginDir = dirname(fileURLToPath(import.meta.url));
  const agentsDir = join(pluginDir, AGENTS_DIR);

  return {
    config: async (config: Config) => {
      if (!existsSync(agentsDir)) {
        return;
      }

      const entries = readdirSync(agentsDir, { withFileTypes: true });
      const mdFiles = entries
        .filter((e) => e.isFile() && e.name.endsWith(".md"))
        .sort((a, b) => a.name.localeCompare(b.name));

      if (mdFiles.length === 0) {
        return;
      }

      const generatedAgents: Record<string, Record<string, unknown>> = {};
      const allWarnings: string[] = [];
      const seenNames = new Set<string>();

      for (const entry of mdFiles) {
        const filePath = join(agentsDir, entry.name);
        let content: string;
        try {
          content = readFileSync(filePath, "utf-8");
        } catch {
          allWarnings.push(`[agent-composer] Failed to read agent file: ${AGENTS_DIR}/${entry.name}`);
          continue;
        }

        const { agentName, config: agentConfig, warnings } = buildAgentConfig(
          pluginDir,
          entry.name,
          content
        );
        allWarnings.push(...warnings);

        if (seenNames.has(agentName)) {
          allWarnings.push(
            `[agent-composer] Duplicate agent name "${agentName}" resolved from ${AGENTS_DIR}/${entry.name}; overriding previous definition`
          );
        }
        seenNames.add(agentName);
        generatedAgents[agentName] = agentConfig;
      }

      if (allWarnings.length > 0) {
        for (const warning of allWarnings) {
          console.warn(warning);
        }
      }

      if (Object.keys(generatedAgents).length === 0) {
        return;
      }

      config.agent = config.agent ?? {};

      for (const [agentName, generatedConfig] of Object.entries(generatedAgents)) {
        const existing = config.agent[agentName] ?? {};
        config.agent[agentName] = {
          ...generatedConfig,
          ...existing,
        };
      }
    },
  };
};

export default agentComposerPlugin;
