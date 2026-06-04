#!/usr/bin/env bash
# The deterministic layer proves the ANCHOR is real; it cannot prove the anchor
# SUPPORTS the claim. A separate judge model closes that seam. This test injects a
# fake judge (ORCA_JUDGE_CMD) so it stays hermetic — no network, no real model.
# It proves: same ark, judge OFF -> PASS (anchor real), judge ON -> FAIL (claim
# not grounded). That is exactly dyra #1, closed.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ORCA="$ROOT/bin/orca"
TMP="$(mktemp -d)"
PROJ="$TMP/proj"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$PROJ/.orca/arks"; cd "$PROJ"
git init -q; git config user.email t@t.t; git config user.name t
echo x > f.txt; git add f.txt; git commit -q -m "fix typo in readme"
H="$(git rev-parse --short HEAD)"

# fake judge: reads the prompt on stdin; says NO when the claim mentions OAUTH
# (a real commit unrelated to OAUTH), YES otherwise. Deterministic, offline.
cat > "$TMP/judge.sh" <<'EOF'
#!/usr/bin/env bash
in="$(cat)"
case "$in" in
  *OAUTH*) echo "NO the commit is a readme typo fix, unrelated to OAuth" ;;
  *)       echo "YES evidence matches the claim" ;;
esac
EOF
chmod +x "$TMP/judge.sh"
export ORCA_JUDGE_CMD="$TMP/judge.sh"

cat > .orca/arks/a.md <<EOF
# ark: a
state: active

## sessions
### 2026-06-04
done: implemented full OAUTH2 login. [commit:$H]
done: committed the seed file. [commit:$H]
EOF

pass=0; fail=0
check() { # check <exit> <label>  (reads /tmp/orca_j)
  if [ "$1" = "$2" ]; then echo "  ok   — $3"; pass=$((pass+1));
  else echo "  FAIL — $3 (want $1, got $2)"; sed 's/^/         /' /tmp/orca_j; fail=$((fail+1)); fi
}

echo "judge proof:"

"$ORCA" verify .orca/arks/a.md --no-tests >/tmp/orca_j 2>&1; det=$?
check 0 "$det" "judge OFF: real anchors -> PASS (deterministic layer is blind to claim<->evidence)"

"$ORCA" verify .orca/arks/a.md --no-tests --judge >/tmp/orca_j 2>&1; jud=$?
check 1 "$jud" "judge ON: false OAuth claim -> FAIL (dyra #1 closed)"
grep -q "UNGR" /tmp/orca_j && { echo "  ok   — UNGROUND flagged on the false claim"; pass=$((pass+1)); } \
  || { echo "  FAIL — no UNGROUND tag"; sed 's/^/         /' /tmp/orca_j; fail=$((fail+1)); }
grep -q "GRND" /tmp/orca_j && { echo "  ok   — GROUND on the honest claim"; pass=$((pass+1)); } \
  || { echo "  FAIL — honest claim not grounded"; sed 's/^/         /' /tmp/orca_j; fail=$((fail+1)); }

# judge unavailable must not break the deterministic core (skipped = grounded)
export ORCA_JUDGE_CMD="/no/such/judge/binary"
"$ORCA" verify .orca/arks/a.md --no-tests --judge >/tmp/orca_j 2>&1; miss=$?
check 0 "$miss" "judge missing -> skipped, deterministic PASS stands (core never depends on judge)"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
