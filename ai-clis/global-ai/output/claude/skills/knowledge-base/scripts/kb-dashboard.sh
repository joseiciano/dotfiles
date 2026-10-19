#!/usr/bin/env bash
set -euo pipefail

# Start (or reuse) the local knowledge-base dashboard and print its URL, opened
# on the KB of the git repo containing the current directory when there is one.
#
# Usage: kb-dashboard.sh [--open] [--stop] [--port N]
#
# The server (dashboard/server.ts, run with bun) listens on 127.0.0.1 only and
# runs in the background; its pid and log live in ${TMPDIR:-/tmp}. A server
# already answering on the port is reused. --stop stops it.

die() {
  printf 'kb-dashboard: %s\n' "$1" >&2
  exit 1
}

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
server="$here/../dashboard/server.ts"
port="${KB_DASHBOARD_PORT:-4777}"
open_browser=0
stop=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --open) open_browser=1 ;;
    --stop) stop=1 ;;
    --port) port="${2:?--port needs a value}"; shift ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done

state="${TMPDIR:-/tmp}"
state="${state%/}/kb-dashboard-$port"
pidfile="$state.pid"
logfile="$state.log"

if [[ "$stop" == 1 ]]; then
  if [[ -f "$pidfile" ]] && kill "$(cat "$pidfile")" 2>/dev/null; then
    rm -f "$pidfile"
    printf 'kb-dashboard: stopped\n'
  else
    rm -f "$pidfile"
    printf 'kb-dashboard: not running\n'
  fi
  exit 0
fi

healthy() {
  curl -fsS --max-time 1 "http://127.0.0.1:$port/api/health" >/dev/null 2>&1
}

if ! healthy; then
  command -v bun >/dev/null 2>&1 || die "bun is required (https://bun.sh)"
  nohup bun "$server" --port "$port" >"$logfile" 2>&1 &
  printf '%s\n' "$!" >"$pidfile"
  for _ in $(seq 50); do
    healthy && break
    sleep 0.1
  done
  healthy || die "server did not start; see $logfile"
fi

url="http://127.0.0.1:$port/"
root="${KNOWLEDGE_BASE_DIR:-$HOME/.knowledge}"
if kb="$(bash "$here/kb-path.sh" 2>/dev/null)"; then
  id="${kb#"$root"/}"
  url="$url#kb=$(printf '%s' "$id" | sed 's|/|%2F|g')"
fi

printf '%s\n' "$url"

if [[ "$open_browser" == 1 ]]; then
  if command -v open >/dev/null 2>&1; then open "$url"
  elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$url" >/dev/null 2>&1
  fi
fi
