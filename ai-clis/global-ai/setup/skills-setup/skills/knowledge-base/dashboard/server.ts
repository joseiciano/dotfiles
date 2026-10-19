#!/usr/bin/env bun
// Local dashboard for the personal knowledge bases under $KNOWLEDGE_BASE_DIR
// (default ~/.knowledge). Serves index.html and a small JSON API that reads
// and edits KB files. Listens on 127.0.0.1 only.
//
// Usage: bun server.ts [--port N]
//
// Writes are limited to existing or new .md files inside one KB, need the
// X-KB-Dashboard header (a cross-site page cannot send it without a CORS
// preflight this server never answers), and carry the mtime the client read so
// an edit made elsewhere in the meantime is refused instead of overwritten.

import { existsSync, lstatSync, mkdirSync, readdirSync, readFileSync, realpathSync, statSync, writeFileSync } from 'node:fs'
import { homedir } from 'node:os'
import { dirname, join, relative, resolve, sep } from 'node:path'

const portArg = process.argv.indexOf('--port')
const port = Number(portArg !== -1 ? process.argv[portArg + 1] : process.env.KB_DASHBOARD_PORT || 4777)
const rootDir = resolve(process.env.KNOWLEDGE_BASE_DIR || join(homedir(), '.knowledge'))
const indexHtml = join(import.meta.dir, 'index.html')

const KB_MARKERS = ['INDEX.md', 'RULES.md', 'GLOSSARY.md', 'CONSTRAINTS.md', 'adr', 'work']

class HttpError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message)
  }
}

function isKb(dir: string): boolean {
  return KB_MARKERS.some((m) => existsSync(join(dir, m)))
}

function subdirs(dir: string): string[] {
  try {
    return readdirSync(dir, { withFileTypes: true })
      .filter((e) => e.isDirectory() && !e.name.startsWith('.'))
      .map((e) => e.name)
      .sort()
  } catch {
    return []
  }
}

// KBs live at <root>/<host>/<owner>/<repo> or <root>/local/<name>.
function listKbs(): string[] {
  const found: string[] = []
  for (const host of subdirs(rootDir)) {
    if (host === 'local') {
      for (const name of subdirs(join(rootDir, host))) found.push(`local/${name}`)
      continue
    }
    for (const owner of subdirs(join(rootDir, host))) {
      for (const repo of subdirs(join(rootDir, host, owner))) found.push(`${host}/${owner}/${repo}`)
    }
  }
  return found.filter((id) => isKb(join(rootDir, id)))
}

// Resolve a KB id and an optional path inside it, refusing anything that
// escapes the KB, including through a symlink.
function resolveInKb(kbId: string | null, path = ''): { kbDir: string; full: string } {
  if (!kbId || kbId.includes('..') || !/^(local\/[^/]+|[^/]+\/[^/]+\/[^/]+)$/.test(kbId)) throw new HttpError(400, 'bad kb id')
  const kbDir = resolve(rootDir, kbId)
  if (!kbDir.startsWith(rootDir + sep)) throw new HttpError(400, 'bad kb id')
  const full = resolve(kbDir, path)
  if (full !== kbDir && !full.startsWith(kbDir + sep)) throw new HttpError(400, 'path escapes the kb')
  // existsSync follows links, so a dangling symlink would look like a new file
  // and the write would follow it out of the KB.
  if (!existsSync(full) && lstatSync(full, { throwIfNoEntry: false })?.isSymbolicLink()) {
    throw new HttpError(400, 'path escapes the kb')
  }
  let probe = full
  while (!existsSync(probe) && probe !== kbDir) probe = dirname(probe)
  if (existsSync(probe)) {
    const real = realpathSync(probe)
    const realKb = existsSync(kbDir) ? realpathSync(kbDir) : kbDir
    if (real !== realKb && !real.startsWith(realKb + sep)) throw new HttpError(400, 'path escapes the kb')
  }
  return { kbDir, full }
}

function read(path: string): string | null {
  try {
    return readFileSync(path, 'utf8')
  } catch {
    return null
  }
}

function frontmatter(text: string): Record<string, string | string[]> {
  const out: Record<string, string | string[]> = {}
  const lines = text.split('\n')
  if (lines[0] !== '---') return out
  let list: string[] | null = null
  for (let i = 1; i < lines.length && lines[i] !== '---'; i++) {
    const line = lines[i]
    const item = line.match(/^\s+-\s*(.*)$/)
    if (item && list) {
      list.push(unquote(item[1]))
      continue
    }
    const kv = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/)
    if (!kv) continue
    list = null
    const [, key, value] = kv
    if (value.startsWith('[')) out[key] = value.replace(/[[\]]/g, '').split(',').map(unquote).filter(Boolean)
    else if (value === '') {
      list = []
      out[key] = list
    } else out[key] = unquote(value)
  }
  return out
}

function unquote(s: string): string {
  return s.trim().replace(/^["']|["']$/g, '')
}

function todoProgress(text: string | null): { done: number; total: number } | null {
  if (text === null) return null
  const boxes = text.match(/^\s*[-*] \[[ xX]\]/gm) ?? []
  return { done: boxes.filter((b) => /\[[xX]\]/.test(b)).length, total: boxes.length }
}

function firstHeading(text: string | null): string | null {
  return text?.match(/^#\s+(.+)$/m)?.[1].trim() ?? null
}

function countRows(text: string | null): number {
  if (!text) return 0
  return text.split('\n').filter((l) => l.trim()).length - 1
}

function workItem(kbDir: string, rel: string) {
  const dir = join(kbDir, rel)
  const plan = read(join(dir, 'plan.md'))
  const fm = plan ? frontmatter(plan) : {}
  const branches = Array.isArray(fm.branches) ? fm.branches : fm.branches ? [fm.branches] : []
  const files = readdirSync(dir, { withFileTypes: true })
    .filter((e) => e.isFile())
    .map((e) => e.name)
    .sort()
  return {
    path: rel,
    title: firstHeading(read(join(dir, 'SPEC.md'))) ?? firstHeading(plan),
    branches,
    todo: todoProgress(read(join(dir, 'todo.md'))),
    decisions: countRows(read(join(dir, 'decisions.tsv'))),
    files,
  }
}

function kbSummary(kbId: string) {
  const { kbDir } = resolveInKb(kbId)
  const top = ['INDEX.md', 'RULES.md', 'CONSTRAINTS.md', 'GLOSSARY.md'].map((name) => ({
    name,
    exists: existsSync(join(kbDir, name)),
  }))
  const adrs = existsSync(join(kbDir, 'adr'))
    ? readdirSync(join(kbDir, 'adr'))
        .filter((f) => f.endsWith('.md'))
        .sort()
        .map((f) => ({ path: `adr/${f}`, title: firstHeading(read(join(kbDir, 'adr', f))) ?? f }))
    : []
  const work = subdirs(join(kbDir, 'work')).map((slug) => ({
    ...workItem(kbDir, `work/${slug}`),
    modules: subdirs(join(kbDir, 'work', slug)).map((m) => workItem(kbDir, `work/${slug}/${m}`)),
  }))
  return { id: kbId, dir: kbDir, exists: existsSync(kbDir), top, adrs, work }
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), { status, headers: { 'content-type': 'application/json' } })
}

function checkHost(req: Request) {
  const host = req.headers.get('host') ?? ''
  if (host !== `127.0.0.1:${port}` && host !== `localhost:${port}`) throw new HttpError(403, 'bad host')
}

async function handle(req: Request): Promise<Response> {
  checkHost(req)
  const url = new URL(req.url)
  const kb = url.searchParams.get('kb')

  if (url.pathname === '/' && req.method === 'GET') {
    return new Response(Bun.file(indexHtml), { headers: { 'content-type': 'text/html; charset=utf-8' } })
  }
  if (url.pathname === '/api/health') return json({ ok: true, root: rootDir })
  if (url.pathname === '/api/kbs') return json({ root: rootDir, kbs: listKbs() })
  if (url.pathname === '/api/kb') return json(kbSummary(kb ?? ''))

  if (url.pathname === '/api/file') {
    const path = url.searchParams.get('path') ?? ''
    const { full, kbDir } = resolveInKb(kb, path)
    if (full === kbDir) throw new HttpError(400, 'path required')

    if (req.method === 'GET') {
      if (!existsSync(full)) return json({ path, exists: false, content: '', mtime: null })
      return json({ path, exists: true, content: readFileSync(full, 'utf8'), mtime: statSync(full).mtimeMs })
    }

    if (req.method === 'PUT') {
      if (req.headers.get('x-kb-dashboard') !== '1') throw new HttpError(403, 'missing X-KB-Dashboard header')
      if (!full.endsWith('.md')) throw new HttpError(400, 'only .md files are editable; decisions.tsv is append-only')
      const body: unknown = await req.json()
      if (typeof body !== 'object' || body === null || !('content' in body) || typeof body.content !== 'string') {
        throw new HttpError(400, 'content must be a string')
      }
      const expected = 'mtime' in body && typeof body.mtime === 'number' ? body.mtime : null
      const current = existsSync(full) ? statSync(full).mtimeMs : null
      if (current !== expected) throw new HttpError(409, 'the file changed since you opened it; reload it')
      mkdirSync(dirname(full), { recursive: true })
      writeFileSync(full, body.content)
      return json({ path: relative(kbDir, full), mtime: statSync(full).mtimeMs })
    }
  }

  throw new HttpError(404, 'not found')
}

const server = Bun.serve({
  hostname: '127.0.0.1',
  port,
  async fetch(req) {
    try {
      return await handle(req)
    } catch (err) {
      if (err instanceof HttpError) return json({ error: err.message }, err.status)
      return json({ error: String(err) }, 500)
    }
  },
})

console.log(`kb-dashboard: http://127.0.0.1:${server.port} (root ${rootDir})`)
