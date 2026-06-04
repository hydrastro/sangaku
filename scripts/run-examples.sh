#!/usr/bin/env bash
# scripts/run-examples.sh -- run only the example suite (quicker than the full test.sh).
set -u
ROOT="${SANGAKU_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
LIZARD="${LIZARD:-lizard}"
PRELUDE="$ROOT/src/prelude.lisp"
cd "$ROOT" || exit 2
pass=0; fail=0
for e in examples/*.lisp; do
  [ -e "$e" ] || continue
  out="$(cat "$PRELUDE" "$e" | "$LIZARD" 2>&1)"
  if ! printf '%s' "$out" | grep -q "Error:"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "  FAIL $(basename "$e")"; fi
done
echo "examples: $pass passed, $fail failed"
[ $fail -eq 0 ]
