#!/usr/bin/env bash
# scripts/test.sh -- run the Sangaku test suite (golden tests + example suite).
#
# Honest by construction: a golden test passes only if the interpreter's output matches the
# recorded .expected byte-for-byte; an example passes only if it exits 0 with no "Error:".
#
# Sangaku is pure Lisp and runs on the Lizard interpreter. Since Lizard executes a single
# script, each run feeds it the prelude (which puts the library on the module path) followed
# by the target file, concatenated on standard input. Set LIZARD to the interpreter binary
# (the Nix build and dev shell do this); otherwise this script looks for `lizard` on PATH.
# Lizard lives at https://github.com/hydrastro/lizard
set -u

ROOT="${SANGAKU_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
LIZARD="${LIZARD:-lizard}"
PRELUDE="$ROOT/src/prelude.lisp"
cd "$ROOT" || exit 2

if ! command -v "$LIZARD" >/dev/null 2>&1 && [ ! -x "$LIZARD" ]; then
  echo "error: Lizard interpreter not found (set LIZARD=/path/to/lizard, or put 'lizard' on PATH)." >&2
  echo "       Lizard lives at https://github.com/hydrastro/lizard" >&2
  exit 2
fi

run () { cat "$PRELUDE" "$1" | "$LIZARD" 2>&1; }

pass=0; fail=0; failed_names=""

echo "== Sangaku golden tests =="
for t in tests/cas_*.lisp; do
  [ -e "$t" ] || continue
  name="$(basename "$t" .lisp)"
  expected="tests/$name.expected"
  [ -f "$expected" ] || { echo "  SKIP $name (no .expected)"; continue; }
  if [ "$(run "$t")" = "$(cat "$expected")" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1)); failed_names="$failed_names $name"; echo "  FAIL $name"
  fi
done
echo "  golden: $pass passed, $fail failed"

echo ""
echo "== Sangaku example suite =="
expass=0; exfail=0
for e in examples/*.lisp; do
  [ -e "$e" ] || continue
  name="$(basename "$e")"
  out="$(run "$e")"
  if ! printf '%s' "$out" | grep -q "Error:"; then
    expass=$((expass + 1))
  else
    exfail=$((exfail + 1)); failed_names="$failed_names example:$name"; echo "  FAIL $name"
  fi
done
echo "  examples: $expass passed, $exfail failed"

echo ""
total_fail=$((fail + exfail))
if [ $total_fail -eq 0 ]; then
  echo "ALL PASS ($pass goldens, $expass examples)"; exit 0
else
  echo "FAILURES:$failed_names"; exit 1
fi
