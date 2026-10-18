#!/usr/bin/env bun
// Render agent sources into one harness's native agent files.
//
// Usage:
//   bun render-agents.js <claude|opencode|omp> --out <dir> [--meta-out <dir>] [--src <dir>]
//   bun render-agents.js prompt <source.md> <output.md> [--src <dir>]
//
// Source layout (under --src, default: this script's directory):
//   agents/<name>.md            shared agents, one block per harness
//   agents-<harness>/<name>.md  agents for one harness only, native frontmatter
//   agents-shared/<fragment>.md prompt fragments appended via `shared:`
//
// A shared agent's frontmatter holds `name`, `description`, `shared`, and one
// block per harness (`claude:`, `opencode:`, `omp:`). Each block is written in
// that harness's native format and copied as is; nothing is translated. A
// block set to `false` skips the agent for that harness. A block may set
// `shared` to replace the top-level list, and `name` to rename the output.
//
// Every rendered agent must state `model`, plus `tools` (claude, omp) or
// `permission` (opencode). The value `inherit` omits the key so the harness
// default applies.
//
// opencode keeps `model`, `fallback_models`, `variant`, `temperature`,
// `skills`, and `mcps` out of the agent file: they are written to --meta-out
// as frontmatter-only files that generate-config.sh merges into opencode.json.
//
// Prompt mode drops the source frontmatter and appends its `shared` fragments.

const fs = require('fs');
const path = require('path');

const HARNESSES = ['claude', 'opencode', 'omp'];
const TOP_LEVEL_KEYS = new Set(['name', 'description', 'shared', ...HARNESSES]);
const ACCESS_KEY = { claude: 'tools', opencode: 'permission', omp: 'tools' };
const OPENCODE_META_KEYS = ['model', 'fallback_models', 'variant', 'temperature', 'skills', 'mcps'];

function die(message) {
  console.error('error: ' + message);
  process.exit(1);
}

function parseArgs(argv) {
  const positional = [];
  const flags = {};
  for (let i = 0; i < argv.length; i++) {
    if (argv[i].startsWith('--')) {
      if (i + 1 >= argv.length) die('missing value for ' + argv[i]);
      flags[argv[i].slice(2)] = argv[++i];
    } else {
      positional.push(argv[i]);
    }
  }
  return { positional, flags };
}

function readSource(file) {
  const text = fs.readFileSync(file, 'utf8');
  if (!text.startsWith('---\n')) return { frontmatter: {}, body: text };
  const close = text.indexOf('\n---\n', 3);
  if (close === -1) die(file + ': unclosed frontmatter');
  let frontmatter;
  try {
    frontmatter = Bun.YAML.parse(text.slice(4, close + 1)) ?? {};
  } catch (err) {
    die(file + ': invalid frontmatter YAML: ' + err.message);
  }
  if (typeof frontmatter !== 'object' || Array.isArray(frontmatter)) {
    die(file + ': frontmatter must be a mapping');
  }
  return { frontmatter, body: text.slice(close + 5) };
}

// Nest fragment headings one level under the agent's own headings, skipping
// fenced code blocks.
function shiftHeaders(text) {
  let inFence = false;
  return text
    .split('\n')
    .map((line) => {
      if (/^\s*(```|~~~)/.test(line)) {
        inFence = !inFence;
        return line;
      }
      return !inFence && /^ {0,3}#+(\s|$)/.test(line) ? line.replace(/#+/, '$&#') : line;
    })
    .join('\n');
}

function appendShared(body, sharedNames, sharedDir, where) {
  if (sharedNames === undefined || sharedNames === null) return body;
  if (!Array.isArray(sharedNames)) die(where + ': `shared` must be a list');
  let out = body;
  for (const name of sharedNames) {
    const candidates = [path.join(sharedDir, name), path.join(sharedDir, name + '.md')];
    const file = candidates.find((c) => fs.existsSync(c) && fs.statSync(c).isFile());
    if (!file) die(where + ": shared fragment '" + name + "' not found in " + sharedDir);
    out += '\n\n' + shiftHeaders(fs.readFileSync(file, 'utf8'));
  }
  return out;
}

function writeAgent(file, frontmatter, body) {
  fs.writeFileSync(file, '---\n' + Bun.YAML.stringify(frontmatter, null, 2).replace(/\n?$/, '\n') + '---\n' + body);
}

// Metadata files are read by parse-jsonc.js, which accepts scalars, block
// lists, and inline [] for an empty list.
function writeMeta(file, meta) {
  const lines = Object.entries(meta).map(([key, value]) => {
    if (!Array.isArray(value)) return key + ': ' + JSON.stringify(value);
    if (value.length === 0) return key + ': []';
    return key + ':\n' + value.map((item) => '  - ' + JSON.stringify(item)).join('\n');
  });
  fs.writeFileSync(file, '---\n' + lines.join('\n') + '\n---\n');
}

// Resolve one source file into the harness's view: { name, frontmatter, shared }.
// Returns null when the agent is skipped for this harness.
function resolveAgent(file, harness, harnessOnly) {
  const stem = path.basename(file, '.md');
  const { frontmatter, body } = readSource(file);
  let view;
  let shared;

  if (harnessOnly) {
    ({ shared, ...view } = frontmatter);
    if (view.name !== undefined && view.name !== stem) {
      die(file + ": name '" + view.name + "' does not match file name '" + stem + "'");
    }
    view.name ??= stem;
  } else {
    for (const key of Object.keys(frontmatter)) {
      if (!TOP_LEVEL_KEYS.has(key)) die(file + ": unknown top-level key '" + key + "'");
    }
    if (frontmatter.name !== stem) {
      die(file + ": name '" + frontmatter.name + "' does not match file name '" + stem + "'");
    }
    const block = frontmatter[harness];
    if (block === false) return null;
    if (block === undefined) die(file + ': missing `' + harness + ':` block (set it to false to skip this harness)');
    if (typeof block !== 'object' || block === null || Array.isArray(block)) {
      die(file + ': `' + harness + ':` must be a mapping or false');
    }
    const { shared: blockShared, ...rest } = block;
    shared = 'shared' in block ? blockShared : frontmatter.shared;
    view = { name: frontmatter.name, description: frontmatter.description, ...rest };
  }

  if (!view.description) die(file + ': missing description');
  for (const key of ['model', ACCESS_KEY[harness]]) {
    if (view[key] === undefined) die(file + ': ' + harness + ' agent must set `' + key + '` (use inherit for the harness default)');
    if (view[key] === 'inherit') delete view[key];
  }
  return { name: view.name, frontmatter: view, body, shared, file };
}

function renderAgents(harness, flags) {
  const src = path.resolve(flags.src ?? __dirname);
  const out = flags.out ? path.resolve(flags.out) : die('--out is required');
  const metaOut = flags['meta-out'] ? path.resolve(flags['meta-out']) : null;
  if (harness === 'opencode' && !metaOut) die('--meta-out is required for opencode');
  const sharedDir = path.join(src, 'agents-shared');

  const sources = [];
  for (const [dir, harnessOnly] of [[path.join(src, 'agents'), false], [path.join(src, 'agents-' + harness), true]]) {
    if (!fs.existsSync(dir)) {
      if (!harnessOnly) die('agents directory not found: ' + dir);
      continue;
    }
    for (const f of fs.readdirSync(dir).filter((f) => f.endsWith('.md')).sort()) {
      sources.push({ file: path.join(dir, f), harnessOnly });
    }
  }

  const agents = [];
  const seen = new Map();
  for (const { file, harnessOnly } of sources) {
    const agent = resolveAgent(file, harness, harnessOnly);
    if (!agent) continue;
    // Case-insensitive: macOS treats Plan.md and plan.md as the same file.
    const key = agent.name.toLowerCase();
    if (seen.has(key)) die("duplicate agent '" + agent.name + "' in " + seen.get(key) + ' and ' + file);
    seen.set(key, file);
    agents.push(agent);
  }

  // Build into a temp dir and swap it in, so agents removed from the source
  // disappear from the output.
  const stage = (dir) => {
    fs.mkdirSync(path.dirname(dir), { recursive: true });
    return fs.mkdtempSync(dir + '.tmp-');
  };
  const tmpOut = stage(out);
  const tmpMeta = metaOut ? stage(metaOut) : null;
  // die() exits directly, so remove leftover staging dirs on any exit.
  process.on('exit', () => {
    for (const tmp of [tmpOut, tmpMeta]) if (tmp) fs.rmSync(tmp, { recursive: true, force: true });
  });

  for (const agent of agents) {
    const body = appendShared(agent.body, agent.shared, sharedDir, agent.file);
    const fm = { ...agent.frontmatter };
    if (harness === 'opencode') {
      delete fm.name;
      fm.mode ??= 'subagent';
      const meta = {};
      for (const key of OPENCODE_META_KEYS) {
        if (key in fm) {
          meta[key] = fm[key];
          delete fm[key];
        }
      }
      if (Object.keys(meta).length > 0) writeMeta(path.join(tmpMeta, agent.name + '.md'), meta);
    }
    writeAgent(path.join(tmpOut, agent.name + '.md'), fm, body);
    console.log('generated ' + path.join(out, agent.name + '.md'));
  }

  for (const [tmp, dir] of [[tmpOut, out], [tmpMeta, metaOut]]) {
    if (!tmp) continue;
    fs.rmSync(dir, { recursive: true, force: true });
    fs.renameSync(tmp, dir);
  }
}

function renderPrompt(positional, flags) {
  const [source, output] = positional;
  if (!source || !output) die('usage: render-agents.js prompt <source.md> <output.md>');
  const src = path.resolve(flags.src ?? __dirname);
  const { frontmatter, body } = readSource(source);
  fs.mkdirSync(path.dirname(path.resolve(output)), { recursive: true });
  fs.writeFileSync(output, appendShared(body.replace(/^\n/, ''), frontmatter.shared, path.join(src, 'agents-shared'), source));
  console.log('generated ' + output);
}

const { positional, flags } = parseArgs(process.argv.slice(2));
const mode = positional.shift();
if (mode === 'prompt') renderPrompt(positional, flags);
else if (HARNESSES.includes(mode)) renderAgents(mode, flags);
else die('usage: render-agents.js <' + HARNESSES.join('|') + '> --out <dir> | prompt <source.md> <output.md>');
