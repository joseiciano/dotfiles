const fs = require('fs');
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

const config = parseJsonc(configContent);
const base = parseJsonc(baseContent);

// Merge: base overrides config
const merged = { ...config, ...base };

fs.writeFileSync(outputFile, JSON.stringify(merged, null, 2));
