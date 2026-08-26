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
// sole source for `model`, `fallback_models`, `variant`, `temperature`,
// `skills`, and `mcps`. The filename (without .md) maps to the config key
// agent.<name>.
const agentsDir = process.env.AGENTS_DIR || path.join(__dirname, '..', '..', 'agent-setup', 'agents');

// Parse only the root frontmatter keys this pipeline owns, robustly:
//   model: <scalar string>
//   variant: <scalar string>
//   temperature: <finite numeric scalar>
//   fallback_models:          (indented YAML list)
//     - <item>
//   fallback_models: []       (inline empty list)
//   skills:                   (indented YAML list)
//     - <item>
//   skills: []                (inline empty list)
//   mcps:                     (indented YAML list)
//     - <item>
//   mcps: []                  (inline empty list)
// Malformed metadata raises a clear error naming the file and field instead of
// silently producing bad config. Returns null when the file has no frontmatter
// or no owned keys.
function parseStringList(file, key, rest, lines, startIndex) {
    if (/^\s*\[\s*\]/.test(rest)) {
        return { items: [], nextIndex: startIndex - 1 };
    }
    if (rest.trim() !== '') {
        throw new Error(file + ": malformed frontmatter '" + key + "': expected indented list items or inline []");
    }

    const items = [];
    let j = startIndex;
    for (; j < lines.length; j++) {
        const l = lines[j];
        // List block ends only at the frontmatter delimiter or the next root
        // (column-zero) frontmatter key. Blank lines and comment-only lines
        // keep the list open so later items are still captured.
        if (l.trim() === '---' || /^[A-Za-z_][A-Za-z0-9_-]*\s*:/.test(l)) break;
        // List items must be indented under the root list key.
        const itemMatch = l.match(/^\s+-\s+(.*)$/);
        if (!itemMatch) continue;

        let item = itemMatch[1].replace(/\s*#.*$/, '').trim();
        item = item.replace(/^["']|["']$/g, '');
        if (!item) {
            throw new Error(file + ": malformed frontmatter '" + key + "': empty list item");
        }
        items.push(item);
    }
    if (items.length === 0) {
        throw new Error(file + ": malformed frontmatter '" + key + "': block form requires list items (use inline [] for an empty list)");
    }
    return { items: items, nextIndex: j - 1 };
}
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

        // Owned metadata keys are root-only: only column-zero keys count, so
        // nested options.variant / temperature / skills / mcps stay inert here.
        const keyMatch = line.match(/^([A-Za-z_][A-Za-z0-9_-]*)\s*:(.*)$/);
        if (!keyMatch) continue; // blank lines and non-key lines inside frontmatter

        const key = keyMatch[1];
        const rest = keyMatch[2];

        if (key === 'model' || key === 'variant') {
            let value = rest.replace(/\s*#.*$/, '').trim();
            value = value.replace(/^["']|["']$/g, '');
            if (!value || /^\[/.test(value)) {
                throw new Error(path.basename(file) + ": malformed frontmatter '" + key + "': expected a scalar string (e.g. " + key + ": <value>)");
            }
            meta[key] = value;
            sawKey = true;
        } else if (key === 'temperature') {
            let value = rest.replace(/\s*#.*$/, '').trim();
            value = value.replace(/^["']|["']$/g, '');
            const num = Number(value);
            if (!value || !Number.isFinite(num)) {
                throw new Error(path.basename(file) + ": malformed frontmatter 'temperature': expected a finite numeric value (e.g. temperature: 0.1)");
            }
            meta.temperature = num;
            sawKey = true;
        } else if (key === 'fallback_models' || key === 'skills' || key === 'mcps') {
            const list = parseStringList(path.basename(file), key, rest, lines, i + 1);
            meta[key] = list.items;
            i = list.nextIndex;
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
    if (meta.variant !== undefined) merged.agent[name].variant = meta.variant;
    if (meta.temperature !== undefined) merged.agent[name].temperature = meta.temperature;
    if (meta.skills !== undefined) merged.agent[name].skills = meta.skills;
    if (meta.mcps !== undefined) merged.agent[name].mcps = meta.mcps;
}

fs.writeFileSync(outputFile, JSON.stringify(merged, null, 2));
