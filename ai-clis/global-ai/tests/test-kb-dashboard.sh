#!/usr/bin/env bash
# Regression coverage for the knowledge-base dashboard: dashboard/server.ts and
# its launcher scripts/kb-dashboard.sh.
#
# The server runs as a real bun process on a random high port with
# KNOWLEDGE_BASE_DIR inside a temp dir and is driven over HTTP with curl.
# Proves:
#   1. /api/kbs lists exactly the dirs at <root>/<host>/<owner>/<repo> and
#      <root>/local/<name> holding a KB marker; dot-dirs at any level and
#      marker-less dirs are excluded.
#   2. /api/kb summarizes work items: branches from inline and block
#      frontmatter lists, todo progress including nested and `*` checkboxes,
#      decisions.tsv rows minus the header, modules nested under their work
#      item, and ADR titles from the first H1.
#   3. GET /api/file for a missing file reports exists:false and mtime:null.
#   4. PUT /api/file writes with the current mtime and X-KB-Dashboard: 1,
#      creates parent dirs and a not-yet-existing KB when mtime is null, and
#      refuses a stale mtime (409), a missing header (403) and non-.md paths
#      such as decisions.tsv (400), leaving the file untouched each time.
#   5. `..` traversal, malformed kb ids and symlinks inside the KB that point
#      outside it are refused on read and write, and nothing outside the KB
#      is written.
#   6. A Host header other than 127.0.0.1:<port> or localhost:<port> gets 403.
#   7. The launcher starts a server and prints the URL with the url-encoded KB
#      id of the current repo, reuses a running server, stops it with --stop,
#      and reports "not running" (exit 0) when nothing is running.
#
# Every server is killed in the EXIT trap; global/system git config is ignored
# so url.insteadOf rewrites cannot leak in. Skips (exit 0) when bun is missing.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT/setup/skills-setup/skills/knowledge-base"
SERVER="$SKILL/dashboard/server.ts"
LAUNCHER="$SKILL/scripts/kb-dashboard.sh"

if ! command -v bun >/dev/null 2>&1; then
  echo 'kb-dashboard-test SKIPPED (bun not installed)'
  exit 0
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-ai-kb-dashboard-test.XXXXXX")"
TMP="$(cd "$TMP" && pwd -P)"

SERVER_PIDS=()
cleanup() {
  local pid pidfile
  for pid in "${SERVER_PIDS[@]+"${SERVER_PIDS[@]}"}"; do
    kill "$pid" 2>/dev/null || true
  done
  for pidfile in "$TMP"/kb-dashboard-*.pid; do
    [[ -f "$pidfile" ]] && kill "$(cat "$pidfile")" 2>/dev/null || true
  done
  rm -rf "$TMP"
}
trap cleanup EXIT

export KNOWLEDGE_BASE_DIR="$TMP/kb"
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
unset KB_DASHBOARD_PORT

fail=0

ok() { printf 'ok   - %s\n' "$1"; }
not_ok() {
  printf 'FAIL - %s\n' "$1" >&2
  fail=1
}

# check <description> <actual> <expected>
check() {
  if [[ "$2" == "$3" ]]; then ok "$1"; else not_ok "$1 (expected '$3', got '$2')"; fi
}

up() { curl -s -o /dev/null --max-time 1 "http://127.0.0.1:$1/api/health"; }

# free_port: a random high port nothing answers on.
free_port() {
  local p
  while :; do
    p=$((20000 + RANDOM % 40000))
    up "$p" || { echo "$p"; return; }
  done
}

wait_up() {
  local _
  for _ in $(seq 100); do up "$1" && return 0; sleep 0.1; done
  return 1
}

wait_down() {
  local _
  for _ in $(seq 100); do up "$1" || return 0; sleep 0.1; done
  return 1
}

BODY="$TMP/body.json"
# req <method> <path?query> [curl args...]: sets STATUS; response body in $BODY.
req() {
  local method="$1" path="$2"
  shift 2
  STATUS="$(curl -s -o "$BODY" -w '%{http_code}' -X "$method" "$@" "http://127.0.0.1:$PORT$path" || true)"
}

# put <kb> <path> <content> <mtime json> [curl args...]
put() {
  local kb="$1" path="$2" content="$3" mtime="$4"
  shift 4
  req PUT "/api/file?kb=$kb&path=$path" -H 'content-type: application/json' "$@" \
    --data "$(jq -nc --arg c "$content" --argjson m "$mtime" '{content:$c,mtime:$m}')"
}

K="$KNOWLEDGE_BASE_DIR"

# --- Fixtures ---------------------------------------------------------------
mkdir -p "$K/github.com/acme/billing/adr" \
  "$K/github.com/acme/no-marker/docs" \
  "$K/github.com/acme/.hidden-repo/adr" \
  "$K/github.com/.hidden-owner/repo/adr" \
  "$K/.hidden-host/acme/repo/adr" \
  "$K/gitlab.com/team/api/work" \
  "$K/local/notes" \
  "$K/local/empty" \
  "$K/local/.cache/adr" \
  "$TMP/outside"
touch "$K/local/notes/RULES.md" "$K/github.com/acme/no-marker/README.md"

KB="github.com/acme/billing"
KBD="$K/$KB"
printf '# Billing index\n' >"$KBD/INDEX.md"
printf '# Use Postgres\n\nBody.\n' >"$KBD/adr/0001-postgres.md"
printf 'No heading here.\n' >"$KBD/adr/0002-untitled.md"

mkdir -p "$KBD/work/invoices/api" "$KBD/work/refunds"
printf -- '---\ntitle: Invoices\nbranches: [main, "feat/inv"]\n---\n# Invoice plan\n' \
  >"$KBD/work/invoices/plan.md"
printf -- '- [x] one\n  - [x] nested done\n  - [ ] nested open\n* [X] star done\n- [ ] open\nnot - [x] a box\n' \
  >"$KBD/work/invoices/todo.md"
printf 'when\twhat\twhy\n2026-01-01\ta\tb\n2026-01-02\tc\td\n\n' >"$KBD/work/invoices/decisions.tsv"
printf -- '---\nbranches:\n  - feat/api\n  - "feat/api-2"\nstatus: wip\n---\n' \
  >"$KBD/work/invoices/api/plan.md"
printf '# Refunds spec\n' >"$KBD/work/refunds/SPEC.md"
printf 'when\twhat\twhy\n' >"$KBD/work/refunds/decisions.tsv"

PORT="$(free_port)"
KNOWLEDGE_BASE_DIR="$K" bun "$SERVER" --port "$PORT" >"$TMP/server.log" 2>&1 &
SERVER_PIDS+=("$!")
if ! wait_up "$PORT"; then
  not_ok "server did not start on port $PORT: $(cat "$TMP/server.log")"
  echo 'kb-dashboard-test FAILED' >&2
  exit 1
fi

# --- 1. /api/kbs ------------------------------------------------------------
req GET /api/kbs
check '/api/kbs lists only marker-bearing KB dirs at valid depths' \
  "$STATUS $(jq -c '.kbs | sort' "$BODY")" \
  '200 ["github.com/acme/billing","gitlab.com/team/api","local/notes"]'

# --- 2. /api/kb summary -----------------------------------------------------
req GET "/api/kb?kb=$KB"
check '/api/kb lists top-level work items only, modules excluded' \
  "$(jq -c '[.work[].path]' "$BODY")" '["work/invoices","work/refunds"]'
check 'inline branches list is parsed with quotes stripped' \
  "$(jq -c '.work[0].branches' "$BODY")" '["main","feat/inv"]'
check 'todo progress counts nested and * checkboxes, not mid-line ones' \
  "$(jq -c '.work[0].todo' "$BODY")" '{"done":3,"total":5}'
check 'decisions counts rows excluding the header and blank lines' \
  "$(jq -c '[.work[].decisions]' "$BODY")" '[2,0]'
check 'module is nested under its work item with block-list branches' \
  "$(jq -c '.work[0].modules | map({path, branches})' "$BODY")" \
  '[{"path":"work/invoices/api","branches":["feat/api","feat/api-2"]}]'
check 'work item title prefers SPEC.md H1, else plan.md H1' \
  "$(jq -c '[.work[].title]' "$BODY")" '["Invoice plan","Refunds spec"]'
check 'a work item without todo.md reports todo null' \
  "$(jq -c '.work[1].todo' "$BODY")" 'null'
check 'ADR titles come from the first H1, else the file name' \
  "$(jq -c '[.adrs[].title]' "$BODY")" '["Use Postgres","0002-untitled.md"]'

# --- 3. GET missing file ----------------------------------------------------
req GET "/api/file?kb=$KB&path=work/nope/SPEC.md"
check 'GET of a missing file reports exists:false, mtime:null' \
  "$STATUS $(jq -c '{exists, mtime}' "$BODY")" '200 {"exists":false,"mtime":null}'

# --- 4. PUT -----------------------------------------------------------------
req GET "/api/file?kb=$KB&path=INDEX.md"
mtime="$(jq '.mtime' "$BODY")"
put "$KB" INDEX.md $'# Edited\n' "$mtime" -H 'X-KB-Dashboard: 1'
check 'PUT with current mtime and header writes the file' \
  "$STATUS $(cat "$KBD/INDEX.md")" '200 # Edited'
req GET "/api/file?kb=$KB&path=INDEX.md"
check 'GET returns the content just written' "$(jq -r '.content' "$BODY")" '# Edited'
mtime="$(jq '.mtime' "$BODY")"

put "$KB" INDEX.md 'stale write' "$(jq -n --argjson m "$mtime" '$m - 1000')" -H 'X-KB-Dashboard: 1'
check 'PUT with a stale mtime is refused with 409 and leaves the file' \
  "$STATUS $(cat "$KBD/INDEX.md")" '409 # Edited'

put "$KB" INDEX.md 'no header' "$mtime"
check 'PUT without X-KB-Dashboard is refused with 403 and leaves the file' \
  "$STATUS $(cat "$KBD/INDEX.md")" '403 # Edited'

put "$KB" work/new-item/SPEC.md 'no header' null
if [[ "$STATUS" == 403 && ! -e "$KBD/work/new-item" ]]; then
  ok 'PUT of a new file without the header creates nothing'
else
  not_ok "PUT of a new file without the header (got $STATUS, exists: $([[ -e "$KBD/work/new-item" ]] && echo yes || echo no))"
fi

decisions_before="$(cat "$KBD/work/invoices/decisions.tsv")"
req GET "/api/file?kb=$KB&path=work/invoices/decisions.tsv"
put "$KB" work/invoices/decisions.tsv 'overwritten' "$(jq '.mtime' "$BODY")" -H 'X-KB-Dashboard: 1'
check 'PUT to decisions.tsv is refused with 400 and leaves the file' \
  "$STATUS $([[ "$(cat "$KBD/work/invoices/decisions.tsv")" == "$decisions_before" ]] && echo unchanged || echo changed)" \
  '400 unchanged'

put "$KB" work/new-item/deep/plan.md 'fresh' null -H 'X-KB-Dashboard: 1'
check 'PUT with mtime null creates the file and its parent dirs' \
  "$STATUS $(cat "$KBD/work/new-item/deep/plan.md" 2>/dev/null)" '200 fresh'

put "$KB" work/new-item/deep/plan.md 'clobber' null -H 'X-KB-Dashboard: 1'
check 'PUT with mtime null over an existing file is refused with 409' \
  "$STATUS $(cat "$KBD/work/new-item/deep/plan.md")" '409 fresh'

put local/brand-new INDEX.md '# New KB' null -H 'X-KB-Dashboard: 1'
check 'PUT with mtime null into a not-yet-existing KB creates it' \
  "$STATUS $(cat "$K/local/brand-new/INDEX.md" 2>/dev/null)" '200 # New KB'
req GET /api/kbs
check 'the newly created KB is listed by /api/kbs' \
  "$(jq -c '.kbs | index("local/brand-new") != null' "$BODY")" 'true'

# --- 5. Path safety ---------------------------------------------------------
printf 'secret\n' >"$TMP/outside/secret.md"
printf 'theirs\n' >"$K/github.com/acme/no-marker/README.md"

# expect_refused <description> <kb> <path>: GET and PUT both get 400.
expect_refused() {
  local description="$1" kb="$2" path="$3" get_status
  req GET "/api/file?kb=$kb&path=$path"
  get_status="$STATUS"
  put "$kb" "$path" 'pwned' null -H 'X-KB-Dashboard: 1'
  check "$description is refused on read and write" "$get_status $STATUS" '400 400'
}

expect_refused '`..` traversal out of the KB root' "$KB" '../../../../outside/escape.md'
expect_refused '`..` traversal into a sibling KB' "$KB" '../no-marker/README.md'
expect_refused 'kb id `..`' '..' 'escape.md'
expect_refused 'kb id with a `..` segment' 'github.com/acme/..' 'escape.md'
expect_refused 'single-segment kb id' 'foo' 'INDEX.md'
expect_refused 'four-segment kb id' 'github.com/acme/billing/work' 'INDEX.md'
expect_refused 'absolute kb id with leading slash' '%2Ftmp%2Fa%2Fb' 'INDEX.md'
req GET '/api/kb?kb=..'
check '/api/kb refuses a bad kb id' "$STATUS" '400'

ln -s "$TMP/outside/secret.md" "$KBD/link-file.md"
expect_refused 'symlinked file pointing outside the KB' "$KB" 'link-file.md'
ln -s "$TMP/outside" "$KBD/link-dir"
expect_refused 'new file under a symlinked dir pointing outside the KB' "$KB" 'link-dir/new.md'

ls_outside="$(cd "$TMP/outside" && ls -A | sort | tr '\n' ' ')"
check 'refused requests wrote nothing outside the KB' \
  "$ls_outside$(cat "$TMP/outside/secret.md") $(cat "$K/github.com/acme/no-marker/README.md")" \
  'secret.md secret theirs'
if [[ -e "$K/../escape.md" || -e "$TMP/escape.md" || -e "$TMP/outside/escape.md" ]]; then
  not_ok 'traversal created escape.md outside the KB'
else
  ok 'no escape.md was created outside the KB'
fi

# A dangling symlink: existsSync follows the link and sees nothing, so the
# containment check must not treat the target as "inside the KB".
ln -s "$TMP/outside/dangling-target.md" "$KBD/dangling.md"
put "$KB" dangling.md 'pwned' null -H 'X-KB-Dashboard: 1'
if [[ "$STATUS" == 4* && ! -e "$TMP/outside/dangling-target.md" ]]; then
  ok 'PUT through a dangling symlink pointing outside the KB is refused'
else
  not_ok "PUT through a dangling symlink pointing outside the KB (got $STATUS $(cat "$BODY"); outside file created: $([[ -e "$TMP/outside/dangling-target.md" ]] && echo yes || echo no))"
fi

# --- 6. Host header ---------------------------------------------------------
host_statuses=''
for host in "evil.example:$PORT" "127.0.0.1:$((PORT + 1))" '127.0.0.1' "localhost.evil.example:$PORT"; do
  req GET /api/kbs -H "Host: $host"
  host_statuses+="$STATUS "
done
check 'foreign Host headers get 403' "$host_statuses" '403 403 403 403 '
req GET /api/kbs -H "Host: localhost:$PORT"
check 'Host localhost:<port> is accepted' "$STATUS" '200'

# --- 7. Launcher ------------------------------------------------------------
repo="$TMP/my-repo"
git init -q -b main "$repo"
LPORT="$(free_port)"
pidfile="$TMP/kb-dashboard-$LPORT.pid"

launch() { (cd "$repo" && TMPDIR="$TMP" bash "$LAUNCHER" "$@" 2>&1); }

if out="$(launch --port "$LPORT")"; then status=0; else status=$?; fi
pid1="$(cat "$pidfile" 2>/dev/null || true)"
check 'launcher prints the URL with the url-encoded KB id' \
  "$status $out" "0 http://127.0.0.1:$LPORT/#kb=local%2Fmy-repo"
if up "$LPORT"; then ok 'launcher started a server on the port'; else not_ok 'launcher left nothing listening'; fi

if out="$(launch --port "$LPORT")"; then status=0; else status=$?; fi
pid2="$(cat "$pidfile" 2>/dev/null || true)"
if [[ "$status" -eq 0 && -n "$pid1" && "$pid1" == "$pid2" ]] && kill -0 "$pid1" 2>/dev/null; then
  ok 'second launch reuses the running server'
else
  not_ok "second launch (exit $status, pid $pid1 -> $pid2: '$out')"
fi

if out="$(launch --port "$LPORT" --stop)"; then status=0; else status=$?; fi
if [[ "$status" -eq 0 && "$out" == 'kb-dashboard: stopped' ]] && wait_down "$LPORT" && [[ ! -e "$pidfile" ]]; then
  ok '--stop stops the server and the port goes down'
else
  not_ok "--stop (exit $status: '$out'; port up: $(up "$LPORT" && echo yes || echo no))"
fi

if out="$(launch --port "$LPORT" --stop)"; then status=0; else status=$?; fi
check '--stop with nothing running says not running and exits 0' \
  "$status $out" '0 kb-dashboard: not running'

if (( fail != 0 )); then
  echo 'kb-dashboard-test FAILED' >&2
  exit 1
fi

echo 'kb-dashboard-test PASSED'
