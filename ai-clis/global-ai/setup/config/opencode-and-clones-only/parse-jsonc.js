const fs = require('fs');
const path = require('path');

const configContent = fs.readFileSync(process.argv[2], 'utf8');
const baseContent = fs.readFileSync(process.argv[3], 'utf8');
const outputFile = process.argv[4];

// Parse JSONC: remove comments and trailing commas
function parseJsonc(content) {
    // Remove single-line comments (but not inside strings)
    let cleaned = content.replace(/("(?:[^"\\]|\\.)*")|\/\/.*$/gm, '$1');
    // Remove multi-line comments
    cleaned = cleaned.replace(/\/\*[\s\S]*?\*\//g, '');
    // Remove trailing commas
    cleaned = cleaned.replace(/,(\s*[}\]])/g, '$1');
    // Remove empty lines (including lines with only whitespace)
    cleaned = cleaned.split('\n').filter(line => line.trim().length > 0).join('\n');
    return JSON.parse(cleaned);
}

// --- Build-only agent metadata -------------------------------------------------
// Source agents under AGENTS_DIR (setup/agent-setup/agents by default) are the
// sole source for `model` and `fallback_models`. The filename (without .md)
// maps to the config key agent.<name>. Other agent.<name> fields (variant,
// temperature, skills, mcps, ...) remain owned by config.jsonc.
const agentsDir = process.env.AGENTS_DIR || path.join(__dirname, '..', '..', 'agent-setup', 'agents');

// Parse only the root frontmatter keys this pipeline owns, robustly:
//   model: <scalar>
//   fallback_models:          (indented YAML list)
//     - <item>
//   fallback_models: []       (inline empty list)
// Malformed metadata raises a clear error instead of silently producing bad
// config. Returns null when the file has no frontmatter or no owned keys.
function parseFrontmatterMeta(file) {
    const content = fs.readFileSync(file, 'utf8');
    const lines = content.split('\n');
    if (lines.length === 0 || lines[0].trim() !== '---') return null;

    const meta = {};
    let sawKey = false;
    let i = 1;

    for (; i < lines.length; i++) {
        const line = lines[i];
        if (line.trim() === '---') break;

        const keyMatch = line.match(/^\s*([A-Za-z_][A-Za-z0-9_-]*)\s*:(.*)$/);
        if (!keyMatch) continue; // blank lines and non-key lines inside frontmatter

        const key = keyMatch[1];
        const rest = keyMatch[2];

        if (key === 'model') {
            let value = rest.replace(/\s*#.*$/, '').trim();
            value = value.replace(/^["']|["']$/g, '');
            if (!value) {
                throw new Error(path.basename(file) + ": malformed frontmatter 'model': expected a scalar value (e.g. model: openai/gpt-5.6-sol)");
            }
            meta.model = value;
            sawKey = true;
        } else if (key === 'fallback_models') {
            if (/^\s*\[\s*\]/.test(rest)) {
                meta.fallback_models = [];
                sawKey = true;
                continue;
            }
            if (rest.trim() !== '') {
                throw new Error(path.basename(file) + ": malformed frontmatter 'fallback_models': expected indented list items or inline []");
            }

            const items = [];
            let j = i + 1;
            for (; j < lines.length; j++) {
                const l = lines[j];
                if (l.trim() === '---') break;
                if (l.trim() === '') continue;

                const itemMatch = l.match(/^\s*-\s*(.*)$/);
                if (!itemMatch) break; // next root frontmatter key: block ended

                let item = itemMatch[1].replace(/\s*#.*$/, '').trim();
                item = item.replace(/^["']|["']$/g, '');
                if (!item) {
                    throw new Error(path.basename(file) + ": malformed frontmatter 'fallback_models': empty list item");
                }
                items.push(item);
            }
            if (items.length === 0) {
                throw new Error(path.basename(file) + ": malformed frontmatter 'fallback_models': block form requires list items (use inline [] for an empty list)");
            }
            meta.fallback_models = items;
            i = j - 1;
            sawKey = true;
        }
    }

    return sawKey ? meta : null;
}

// Merge: base overrides config
const config = parseJsonc(configContent);
const base = parseJsonc(baseContent);
const merged = { ...config, ...base };

if (!fs.existsSync(agentsDir) || !fs.statSync(agentsDir).isDirectory()) {
    console.error('error: AGENTS_DIR not found: ' + agentsDir);
    process.exit(1);
}

const agentFiles = fs.readdirSync(agentsDir).filter((f) => f.endsWith('.md')).sort();
for (const file of agentFiles) {
    const name = file.slice(0, -3);
    let meta;
    try {
        meta = parseFrontmatterMeta(path.join(agentsDir, file));
    } catch (err) {
        console.error('error: ' + err.message);
        process.exit(1);
    }
    if (!meta) continue;

    if (!merged.agent) merged.agent = {};
    if (!merged.agent[name]) merged.agent[name] = {};
    if (meta.model !== undefined) merged.agent[name].model = meta.model;
    if (meta.fallback_models !== undefined) merged.agent[name].fallback_models = meta.fallback_models;
}

fs.writeFileSync(outputFile, JSON.stringify(merged, null, 2));
