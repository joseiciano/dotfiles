#!/usr/bin/env bun
// Copy skill folders into a build output, making each one self-contained.
//
// Usage: bun copy-skills.js <src-skills-dir> <out-skills-dir> [--references <dir>]
//
// Every folder in <src-skills-dir> that has a SKILL.md is copied to
// <out-skills-dir>/<name>; a name that already exists in the output fails the
// build, so two skill sources cannot overwrite each other. Other entries
// (README.md, ...) are skipped.
//
// With --references, links in the copied markdown that resolve into the shared
// references dir (e.g. `../../../references/definition-of-done.md` from a
// SKILL.md in skills-setup/skills/<skill>/, or `../../../../references/...` from its references/)
// are inlined: the file is copied into the skill's own references/
// folder and the link is rewritten to point at the copy. A link into the shared
// dir that names a missing file, or a copy that would clash with a different
// file the skill already has, fails the build.

const fs = require('fs');
const path = require('path');

function die(message) {
  console.error('error: ' + message);
  process.exit(1);
}

const args = process.argv.slice(2);
let referencesDir = null;
const refIndex = args.indexOf('--references');
if (refIndex !== -1) {
  referencesDir = args[refIndex + 1] ? path.resolve(args[refIndex + 1]) : die('missing value for --references');
  args.splice(refIndex, 2);
}
const [srcArg, outArg] = args;
if (!srcArg || !outArg) die('usage: copy-skills.js <src-skills-dir> <out-skills-dir> [--references <dir>]');
const srcDir = path.resolve(srcArg);
const outDir = path.resolve(outArg);
if (!fs.existsSync(srcDir)) die('skills directory not found: ' + srcDir);
if (referencesDir && !fs.existsSync(referencesDir)) die('references directory not found: ' + referencesDir);

const walk = (dir) =>
  fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    const p = path.join(dir, e.name);
    return e.isDirectory() ? walk(p) : [p];
  });

// Relative paths that end in references/<file>.md, e.g. ../../../references/x.md
// or ../../../../references/x.md; only ones resolving into the shared
// dir are inlined.
const SHARED_LINK = /(?:\.\.\/)+(?:[A-Za-z0-9._-]+\/)*references\/([A-Za-z0-9._-]+\.md)/g;

fs.mkdirSync(outDir, { recursive: true });
for (const name of fs.readdirSync(srcDir).sort()) {
  const src = path.join(srcDir, name);
  if (!fs.statSync(src).isDirectory() || !fs.existsSync(path.join(src, 'SKILL.md'))) continue;
  const dest = path.join(outDir, name);
  if (fs.existsSync(dest)) die(`skill '${name}' already exists in ${outDir}`);
  fs.cpSync(src, dest, { recursive: true });
  if (!referencesDir) continue;

  for (const file of walk(dest).filter((f) => f.endsWith('.md'))) {
    const srcFile = path.join(src, path.relative(dest, file));
    const text = fs.readFileSync(file, 'utf8');
    const rewritten = text.replace(SHARED_LINK, (link, ref) => {
      const target = path.resolve(path.dirname(srcFile), link);
      if (path.dirname(target) !== referencesDir) return link;
      if (!fs.existsSync(target)) die(`${srcFile}: links to missing shared reference ${link}`);
      const copy = path.join(dest, 'references', ref);
      const shared = fs.readFileSync(target);
      if (fs.existsSync(copy)) {
        if (!fs.readFileSync(copy).equals(shared)) die(`${name}: references/${ref} differs from the shared ${ref}`);
      } else {
        fs.mkdirSync(path.dirname(copy), { recursive: true });
        fs.writeFileSync(copy, shared);
      }
      return path.relative(path.dirname(file), copy);
    });
    if (rewritten !== text) fs.writeFileSync(file, rewritten);
  }
}
