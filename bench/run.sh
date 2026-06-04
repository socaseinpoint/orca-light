#!/usr/bin/env bash
# orca-light benchmark — exercises the real flow on a throwaway `tempo` project
# and prints numbers for the 5 things orca claims to deliver. Fast + reproducible.
#
#   B1 context cost   bytes/words/~tokens of `orca now` (vs claude-mem's dump)
#   B2 trust          fabrication catch-rate of `orca verify`
#   B3 latency        wall time of now / verify (the hook budget)
#   B4 resume         does `orca now` alone carry done-when + where-you-stopped
#   B5 parallel       two arks written concurrently both survive intact
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
export ORCA_HOME="$TMP/meta/.orca"
PROJ="$TMP/tempo"
trap 'rm -rf "$TMP"' EXIT

toks() { wc -c < "$1" | awk '{printf "%d", ($1+3)/4}'; }   # rough chars/4
now_ms() { python3 -c 'import time;print(int(time.time()*1000))'; }

# --- scaffold a real, tiny project so anchors are genuine ----------------------
mkdir -p "$PROJ"; cd "$PROJ"
git init -q; git config user.email b@b.b; git config user.name b
cat > tempo.py <<'PY'
def c2f(c): return c * 9 / 5 + 32
def f2c(f): return (f - 32) * 5 / 9
def c2k(c): return c + 273.15
def k2c(k): return k - 273.15
PY
cat > test_tempo.py <<'PY'
from tempo import c2f, f2c, c2k, k2c
def test_roundtrip():
    assert abs(f2c(c2f(100)) - 100) < 1e-9
    assert abs(k2c(c2k(0)) - 0) < 1e-9
    assert c2f(0) == 32
PY
git add -A; git commit -q -m "tempo: c/f/k conversion core"
HASH="$(git rev-parse --short HEAD)"

"$ORCA" init >/dev/null 2>&1

# --- thread (goal) + two parallel task arks with REAL anchors -----------------
cat > "$ORCA_HOME/threads/tempo-mvp.md" <<MD
# thread: tempo-mvp
goal: ship a c/f/k temperature CLI
updated: 2026-06-04
MD

cat > .orca/arks/convert-core.md <<MD
# ark: convert-core
thread: tempo-mvp
done-when: c<->f<->k roundtrip passes
state: active

## handoff
- core conversions implemented in tempo.py. [file:tempo.py:4]
- committed the core. [commit:$HASH]
- roundtrip test green. [test:python3 -c "from tempo import c2f,f2c,c2k,k2c; assert abs(f2c(c2f(100))-100)<1e-9 and c2f(0)==32"]
MD

cat > .orca/arks/cli-parse.md <<MD
# ark: cli-parse
thread: tempo-mvp
done-when: bad CLI input exits non-zero with a message
state: active

## handoff
- BLOCKER: argparse layer not started yet, design open.
MD

echo "================ orca-light benchmark (project: tempo) ================"

# --- B1 context cost ----------------------------------------------------------
"$ORCA" now > "$TMP/now.txt" 2>&1
NB=$(wc -c < "$TMP/now.txt" | tr -d ' '); NW=$(wc -w < "$TMP/now.txt" | tr -d ' '); NT=$(toks "$TMP/now.txt")
echo
echo "B1 context cost (orca now):"
echo "    $NB bytes / $NW words / ~$NT tokens   (claude-mem SessionStart dump ≈ 15673 tokens)"

# --- B3 latency (time the views/verify the hooks call) ------------------------
t0=$(now_ms); for i in 1 2 3 4 5; do "$ORCA" now >/dev/null 2>&1; done; t1=$(now_ms)
NOW_MS=$(( (t1 - t0) / 5 ))
t0=$(now_ms); "$ORCA" verify --no-tests >/dev/null 2>&1; t1=$(now_ms); VF_MS=$(( t1 - t0 ))
t0=$(now_ms); "$ORCA" verify >/dev/null 2>&1; t1=$(now_ms); VT_MS=$(( t1 - t0 ))
echo
echo "B3 latency:"
echo "    orca now            ${NOW_MS}ms  (avg of 5; SessionStart budget)"
echo "    orca verify --no-tests ${VF_MS}ms  (Stop budget)"
echo "    orca verify (w/ tests) ${VT_MS}ms"

# --- B2 trust: good ark PASS, then 4 fabrication modes each FAIL --------------
pass=0; tot=0
chk() { tot=$((tot+1)); if [ "$1" = "$2" ]; then echo "    ✓ $3"; pass=$((pass+1)); else echo "    ✗ $3 (got rc=$1 want $2)"; fi; }
"$ORCA" verify .orca/arks/convert-core.md --no-tests >/dev/null 2>&1; chk $? 0 "honest ark      -> PASS"
"$ORCA" verify .orca/arks/convert-core.md           >/dev/null 2>&1; chk $? 0 "honest +tests   -> PASS"

cat > .orca/arks/fake-line.md <<MD
# ark: fake
## handoff
- claims a line that does not exist. [file:tempo.py:9999]
MD
"$ORCA" verify .orca/arks/fake-line.md --no-tests >/dev/null 2>&1; chk $? 1 "fake file:line  -> FAIL"

cat > .orca/arks/fake-commit.md <<MD
# ark: fake
## handoff
- claims a commit that never was. [commit:deadbeef]
MD
"$ORCA" verify .orca/arks/fake-commit.md --no-tests >/dev/null 2>&1; chk $? 1 "fake commit     -> FAIL"

cat > .orca/arks/fake-test.md <<MD
# ark: fake
## handoff
- claims a passing test that fails. [test:python3 -c "import sys;sys.exit(1)"]
MD
"$ORCA" verify .orca/arks/fake-test.md >/dev/null 2>&1; chk $? 1 "fake test        -> FAIL"

cat > .orca/arks/bare.md <<MD
# ark: bare
## handoff
- pure prose, no anchor, trust me bro.
MD
"$ORCA" verify .orca/arks/bare.md --no-tests >/dev/null 2>&1; chk $? 1 "bare claim       -> FAIL"
rm -f .orca/arks/fake-*.md .orca/arks/bare.md
echo
echo "B2 trust: $pass/$tot fabrication-modes caught"

# --- B4 resume fidelity: does `orca now` alone carry the essentials? ----------
"$ORCA" now > "$TMP/now.txt" 2>&1
r=0; rt=0
has() { rt=$((rt+1)); if grep -qF "$1" "$TMP/now.txt"; then r=$((r+1)); echo "    ✓ $2"; else echo "    ✗ $2"; fi; }
has "ship a c/f/k" "goal present"
has "convert-core" "task 1 listed"
has "cli-parse"    "task 2 listed (parallel)"
has "done-when:"   "stop-condition present"
has "stopped:"     "where-you-stopped present"
has "blocker"      "blocker surfaced"
echo
echo "B4 resume fidelity: $r/$rt resume-essentials present in 'orca now'"

# --- B5 parallel safety: two arks written at once, both intact ---------------
( for i in $(seq 1 50); do printf '# ark: p1\nthread: tempo-mvp\ndone-when: a\nstate: active\n\n## handoff\n- step %s. [file:tempo.py:1]\n' "$i" > .orca/arks/par1.md; done ) &
( for i in $(seq 1 50); do printf '# ark: p2\nthread: tempo-mvp\ndone-when: b\nstate: active\n\n## handoff\n- step %s. [file:tempo.py:2]\n' "$i" > .orca/arks/par2.md; done ) &
wait
ok5=0
"$ORCA" verify .orca/arks/par1.md --no-tests >/dev/null 2>&1 && ok5=$((ok5+1))
"$ORCA" verify .orca/arks/par2.md --no-tests >/dev/null 2>&1 && ok5=$((ok5+1))
"$ORCA" now >/dev/null 2>&1 && ok5=$((ok5+1))   # view doesn't choke on concurrent writes
rm -f .orca/arks/par1.md .orca/arks/par2.md
echo
echo "B5 parallel safety: $ok5/3 (both arks intact + view renders after concurrent writes)"

echo
echo "====================================================================="
[ "$pass" = "$tot" ] && [ "$r" = "$rt" ] && [ "$ok5" = 3 ] \
  && echo "VERDICT: all green — trust + resume + parallel safety hold." \
  || echo "VERDICT: see failures above."
