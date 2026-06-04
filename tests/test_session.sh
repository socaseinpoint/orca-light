#!/usr/bin/env bash
# The session-context ledger is the MUST-tier correctness layer: it makes resume
# live-aware, set-based, and correctly attributed. Prove `orca session pending`
# excludes exactly the unsafe sources — the current session (freshest transcript),
# any LIVE concurrent session (recently-touched transcript), already-compressed
# sessions, and sessions from other projects — and lists the rest oldest-first.
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
PROJ="$TMP/proj"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$PROJ"; cd "$PROJ"
git init -q; git config user.email t@t.t; git config user.name t
echo x > f.txt; git add f.txt; git commit -q -m seed
"$ORCA" init >/dev/null 2>&1

# set a file's mtime to (now - N seconds)
age() { python3 -c "import os,sys,time; t=time.time()-int(sys.argv[2]); os.utime(sys.argv[1],(t,t))" "$1" "$2"; }

pass=0; fail=0
ok()  { echo "  ok   — $1"; pass=$((pass+1)); }
bad() { echo "  FAIL — $1"; sed 's/^/         /' /tmp/sp 2>/dev/null; fail=$((fail+1)); }
has() { grep -qF "$1" /tmp/sp && ok "$2" || bad "$2 (missing: $1)"; }
hasnt(){ grep -qF "$1" /tmp/sp && bad "$2 (unexpected: $1)" || ok "$2"; }

echo "session-ledger proof:"

# --- record writes a project-local record from hook JSON on stdin ---
echo '{"session_id":"CUR","transcript_path":"'"$PROJ"'/cur.jsonl","cwd":"'"$PROJ"'"}' | "$ORCA" session record
[ -f .orca/sessions/CUR.json ] && ok "record writes .orca/sessions/<id>.json" || bad "no record file"
grep -qF '"transcript": "'"$PROJ"'/cur.jsonl"' .orca/sessions/CUR.json && ok "record stores the exact transcript path" || bad "transcript path not stored"

# --- four more sessions with controlled transcript mtimes ---
for s in PRIOR LIVE COMP; do
  echo '{"session_id":"'"$s"'","transcript_path":"'"$PROJ"'/'"$s"'.jsonl","cwd":"'"$PROJ"'"}' | "$ORCA" session record
done
# an OTHER-project record written by hand (cwd outside this repo) — tests attribution
printf '{"session":"OTHER","transcript":"%s/OTHER.jsonl","cwd":"/tmp","compressed":false}' "$PROJ" > .orca/sessions/OTHER.json

# transcripts on disk; mtime is the liveness heartbeat
: > cur.jsonl; : > PRIOR.jsonl; : > LIVE.jsonl; : > COMP.jsonl; : > OTHER.jsonl
age cur.jsonl 0        # freshest -> the CURRENT session
age LIVE.jsonl 8       # touched 8s ago (< 45 window) -> LIVE, must be skipped
age PRIOR.jsonl 600    # idle 10min -> safe to compress
age COMP.jsonl 600     # idle, but marked compressed -> excluded
age OTHER.jsonl 600    # idle, but other project -> excluded

"$ORCA" session compressed COMP >/dev/null

"$ORCA" session pending > /tmp/sp 2>&1

has "pending"$'\t'"PRIOR" "PRIOR (idle, this project, uncompressed) is pending"
hasnt "pending"$'\t'"CUR"  "current session (freshest transcript) excluded"
hasnt "pending"$'\t'"LIVE" "live session (recent transcript) not in pending"
has  "live"$'\t'"LIVE"     "live session reported as a live warning (skipped, not silent)"
hasnt "pending"$'\t'"COMP" "already-compressed session excluded"
hasnt "COMP"               "compressed session absent entirely"
hasnt "pending"$'\t'"OTHER" "other-project session excluded (cwd attribution)"
hasnt "OTHER"              "other-project session absent entirely"

# --- marking PRIOR compressed removes it from pending (no double-fold) ---
"$ORCA" session compressed PRIOR >/dev/null
"$ORCA" session pending > /tmp/sp 2>&1
hasnt "pending"$'\t'"PRIOR" "compressing PRIOR drops it from pending (set converges)"

# --- prune drops only OLD + COMPRESSED records, never an unfolded one ---
# PRIOR is compressed (above); age its record's `started` past the 30d cutoff.
agerec() { python3 -c "import json,time,sys; p=sys.argv[1]; r=json.load(open(p)); r['started']=int(time.time())-int(sys.argv[2])*86400; json.dump(r,open(p,'w'))" "$1" "$2"; }
agerec .orca/sessions/PRIOR.json 40
agerec .orca/sessions/CUR.json 40     # CUR is uncompressed; old but must survive (still owed a block)
"$ORCA" session prune --days 30 >/dev/null
[ ! -f .orca/sessions/PRIOR.json ] && ok "prune drops old compressed record" || bad "old compressed record not pruned"
[ -f .orca/sessions/CUR.json ]    && ok "prune keeps uncompressed record (still owed a block)" || bad "prune wrongly dropped an unfolded record"
[ -f .orca/sessions/COMP.json ]   && ok "prune keeps young compressed record" || bad "prune dropped a young compressed record"

# --- record never breaks the hook: empty/no stdin -> exit 0, no crash ---
printf '' | "$ORCA" session record; [ $? -eq 0 ] && ok "empty stdin -> exit 0 (hook-safe)" || bad "empty stdin should exit 0"
echo 'not json at all' | "$ORCA" session record; [ $? -eq 0 ] && ok "garbage stdin -> exit 0 (hook-safe)" || bad "garbage stdin should exit 0"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
