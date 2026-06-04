#!/usr/bin/env bash
# Ark schema v2: per-session blocks with two zones.
#   proven zone  (done:)            -> MUST carry an anchor; verify enforces it
#   orient zone  (why:/next:/head:) -> free narrative; verify must NEVER flag it
# v1 `## handoff` bullets stay enforced (backward compat).
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
PROJ="$TMP/proj"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$PROJ/.orca/arks"; cd "$PROJ"
git init -q; git config user.email t@t.t; git config user.name t
echo x > f.txt; git add f.txt; git commit -q -m seed
H="$(git rev-parse HEAD)"

pass=0; fail=0
run() { "$ORCA" verify "$1" --no-tests >/tmp/orca_z 2>&1; echo $?; }
expect() { # expect <exit> <label>
  got="$(run .orca/arks/a.md)"
  if [ "$got" = "$1" ]; then echo "  ok   — $2"; pass=$((pass+1));
  else echo "  FAIL — $2 (want exit $1, got $got)"; sed 's/^/         /' /tmp/orca_z; fail=$((fail+1)); fi
}

echo "zones proof:"

# 1. done: anchored + free-text orient zone -> PASS
cat > .orca/arks/a.md <<EOF
# ark: a
state: active

## sessions
### 2026-06-04
done: detector shipped. [commit:$H]
why:  content-based beats mtime — mtime lies after checkout
next: wire the resume skill
head: was stuck on hooks not being able to call the model
EOF
expect 0 "done: anchored, orient free text -> PASS"

# 2. done: WITHOUT anchor -> FAIL (proven zone unproven)
cat > .orca/arks/a.md <<EOF
# ark: a
state: active

## sessions
### 2026-06-04
done: shipped the thing but no proof
why:  reasons
EOF
expect 1 "done: with no anchor -> FAIL"

# 3. orient zone alone is never the thing that fails: anchored done + wild orient -> PASS
cat > .orca/arks/a.md <<EOF
# ark: a
state: active

## sessions
### 2026-06-04
done: ok. [commit:$H]
why:  this line has no anchor and must not be flagged
next: neither does this one
head: nor this
EOF
expect 0 "why/next/head never flagged when done: is proven"

# 4. v1 handoff bullet without anchor still FAILs (back-compat)
cat > .orca/arks/a.md <<EOF
# ark: a
state: active

## handoff
- did a thing with no anchor
EOF
expect 1 "v1 handoff bare bullet still FAILs"

# 5. v1 handoff bullet WITH anchor still PASSes
cat > .orca/arks/a.md <<EOF
# ark: a
state: active

## handoff
- did a thing. [commit:$H]
EOF
expect 0 "v1 handoff anchored bullet still PASSes"

# 6. anchors quoted in orient prose (why/next/head) are NOT checked — only done: is
cat > .orca/arks/a.md <<EOF
# ark: a
state: active

## sessions
### 2026-06-04
done: real work. [commit:$H]
why:  session 2 wrote a bad anchor [test:test_does_not_exist] — quoting it must not fail verify
next: also mentioning [file:nope.py:999] here is fine
head: and [commit:deadbeef] in prose too
EOF
expect 0 "anchors quoted in orient prose are ignored (only done: is verified)"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
