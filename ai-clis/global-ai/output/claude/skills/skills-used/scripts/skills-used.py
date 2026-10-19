#!/usr/bin/env python3
"""List skills triggered in Claude Code session transcripts."""
import argparse, json, os, re, sys, time
from collections import OrderedDict
from pathlib import Path

HOME = Path.home()
ROOTS = {"claude": HOME / ".claude" / "projects", "omp": HOME / ".omp" / "agent" / "sessions"}
SKILL_URI = re.compile(r"^skill://([^/]+)/?$")
BUILTIN = {"clear", "help", "compact", "model", "config", "resume", "exit", "context", "cost", "fast", "init", "login", "logout", "status", "agents", "mcp", "memory", "permissions"}
CMD = re.compile(r"<command-name>/?([^<\s]+)</command-name>")


def project_dir(harness, arg):
    root = ROOTS[harness]
    if arg:
        return root / arg
    cwd = os.getcwd()
    if harness == "claude":
        return root / re.sub(r"[^A-Za-z0-9]", "-", cwd)
    # omp names the directory after the cwd relative to $HOME, "/" as "-".
    try:
        return root / ("-" + str(Path(cwd).relative_to(HOME)).replace("/", "-"))
    except ValueError:
        return root / ("--" + cwd.strip("/").replace("/", "-"))


def newest_mtime(pdir):
    times = [p.stat().st_mtime for p in pdir.glob("*.jsonl")]
    return max(times, default=0)


def detect_harness(arg):
    """The harness running us is the one writing the newest transcript."""
    return max(ROOTS, key=lambda h: newest_mtime(project_dir(h, arg)))


def scan_omp(path):
    """omp loads a skill by reading skill://<name>; subpaths are reference reads."""
    with open(path, errors="replace") as fh:
        for line in fh:
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            msg = rec.get("message") or {}
            content = msg.get("content")
            if rec.get("type") != "message" or msg.get("role") != "assistant" or not isinstance(content, list):
                continue
            for block in content:
                if block.get("type") == "toolCall" and block.get("name") == "read":
                    m = SKILL_URI.match(str((block.get("arguments") or {}).get("path", "")))
                    if m:
                        yield m.group(1), "model", rec.get("timestamp", "")


def scan(path):
    """Yield (skill, trigger, timestamp) for each invocation in one transcript."""
    with open(path, errors="replace") as fh:
        for line in fh:
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            msg = rec.get("message") or {}
            content = msg.get("content")
            ts = rec.get("timestamp", "")
            if rec.get("type") == "assistant" and isinstance(content, list):
                for block in content:
                    if block.get("type") == "tool_use" and block.get("name") == "Skill":
                        name = (block.get("input") or {}).get("skill")
                        if name:
                            yield name, "model", ts
            elif rec.get("type") == "user" and isinstance(content, str):
                m = CMD.search(content)
                if m and m.group(1) not in BUILTIN:
                    yield m.group(1), "user", ts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--session")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--days", type=int)
    ap.add_argument("--project")
    ap.add_argument("--harness", choices=sorted(ROOTS), help="default: whichever has the newest transcript for this project")
    a = ap.parse_args()

    a.harness = a.harness or detect_harness(a.project)
    pdir = project_dir(a.harness, a.project)
    files = sorted(pdir.glob("*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not files:
        sys.exit(f"no transcripts in {pdir}")
    if a.session:
        files = [f for f in files if f.stem.startswith(a.session)]
        if len(files) != 1:
            sys.exit(f"{len(files)} sessions match {a.session!r}")
    elif a.all:
        if a.days:
            cutoff = time.time() - a.days * 86400
            files = [f for f in files if f.stat().st_mtime >= cutoff]
    else:
        files = files[:1]

    stats = OrderedDict()
    for f in files:
        for name, trig, ts in (scan_omp if a.harness == "omp" else scan)(f):
            s = stats.setdefault((name, trig), {"n": 0, "first": ts})
            s["n"] += 1
            s["first"] = min(s["first"], ts) if ts else s["first"]

    print(f"harness: {a.harness}  project: {pdir.name}  sessions: {len(files)}" + (f"  ({files[0].stem})" if len(files) == 1 else ""))
    if not stats:
        print("no skills triggered")
        return
    print(f"{'count':>5}  {'trigger':<7}  {'first seen':<20}  skill")
    for (name, trig), s in sorted(stats.items(), key=lambda kv: -kv[1]["n"]):
        print(f"{s['n']:>5}  {trig:<7}  {s['first'][:19]:<20}  {name}")


if __name__ == "__main__":
    main()
