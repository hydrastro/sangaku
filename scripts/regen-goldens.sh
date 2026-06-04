#!/usr/bin/env bash
# scripts/regen-goldens.sh -- regenerate golden .expected files from the current interpreter output.
#
# Use this AFTER an intentional change to a module that alters its (correct) output, to refresh the
# recorded golden. It runs each tests/cas_*.lisp through Lizard (prelude first) and writes the result
# to tests/cas_*.expected. Then it re-runs once and diffs to confirm the new golden is deterministic.
#
# IMPORTANT: this overwrites goldens. Only run it when you have verified the new output is correct --
# a golden is only as trustworthy as the moment it was blessed. Review `git diff tests/` afterward.
#
#   scripts/regen-goldens.sh                 # regenerate ALL goldens
#   scripts/regen-goldens.sh cas_defint      # regenerate one (name with or without .lisp)
#   scripts/regen-goldens.sh cas_defint cas_axmode   # regenerate several
#
# Set LIZARD to the interpreter if it is not on PATH. Lizard: https://github.com/hydrastro/lizard
set -u
ROOT="${SANGAKU_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
LIZARD="${LIZARD:-lizard}"
PRELUDE="$ROOT/src/prelude.lisp"
cd "$ROOT" || exit 2

if ! command -v "$LIZARD" >/dev/null 2>&1 && [ ! -x "$LIZARD" ]; then
  echo "error: Lizard interpreter not found (set LIZARD=/path/to/lizard)." >&2
  echo "       Lizard lives at https://github.com/hydrastro/lizard" >&2
  exit 2
fi

# Build the target list: all goldens, or the named subset.
targets=""
if [ $# -eq 0 ]; then
  targets="$(ls tests/cas_*.lisp 2>/dev/null)"
else
  for a in "$@"; do
    name="$(basename "$a" .lisp)"
    if [ -f "tests/$name.lisp" ]; then targets="$targets tests/$name.lisp"
    else echo "  skip: tests/$name.lisp not found"; fi
  done
fi

regen=0; nondet=0
for t in $targets; do
  [ -e "$t" ] || continue
  name="$(basename "$t" .lisp)"
  cat "$PRELUDE" "$t" | "$LIZARD" > "tests/$name.expected" 2>&1
  # determinism check: run again, compare
  second="$(cat "$PRELUDE" "$t" | "$LIZARD" 2>&1)"
  if [ "$second" = "$(cat "tests/$name.expected")" ]; then
    echo "  regenerated: $name"
    regen=$((regen + 1))
  else
    echo "  WARNING: $name is NON-DETERMINISTIC (two runs differ) -- golden may be unreliable"
    nondet=$((nondet + 1))
  fi
done

echo ""
echo "regenerated $regen golden(s); $nondet non-deterministic."
echo "Review the changes:  git diff tests/"
[ $nondet -eq 0 ]
