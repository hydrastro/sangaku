#!/usr/bin/env bash
# scripts/check-structure.sh -- verify the Sangaku repo is internally consistent:
#   * every cas module imports only cas/... and the bundled logic.lisp
#   * every golden .lisp has a matching .expected (and vice versa)
#   * the prelude registers the library path
# This does NOT need the interpreter; it is a fast static check.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2
problems=0

echo "== module count =="
echo "  src/cas modules: $(ls src/cas/*.lisp 2>/dev/null | wc -l)"
echo "  examples:        $(ls examples/*.lisp 2>/dev/null | wc -l)"
echo "  golden pairs:    $(ls tests/cas_*.lisp 2>/dev/null | wc -l) lisp / $(ls tests/cas_*.expected 2>/dev/null | wc -l) expected"

echo "== external imports (should be only logic.lisp) =="
# match the quoted path regardless of trailing ':as alias', then drop the cas/ ones
ext="$(grep -rhoE '\(import[[:space:]]+"[^"]+"' src/cas/*.lisp 2>/dev/null | sed -E 's/.*"([^"]+)".*/\1/' | grep -v '^cas/' | sort -u)"
if [ -z "$ext" ]; then
  echo "  none beyond cas/ — fully self-contained"
elif [ "$ext" = 'logic.lisp' ]; then
  echo "  only logic.lisp (bundled at src/logic.lisp) — ok"
  [ -f src/logic.lisp ] || { echo "  ERROR: logic.lisp imported but src/logic.lisp missing"; problems=$((problems+1)); }
else
  echo "  ERROR: unexpected external imports:"; echo "$ext" | sed 's/^/    /'; problems=$((problems+1))
fi

echo "== golden pairing =="
for t in tests/cas_*.lisp; do
  [ -e "$t" ] || continue
  n="$(basename "$t" .lisp)"
  [ -f "tests/$n.expected" ] || { echo "  ERROR: $n.lisp has no .expected"; problems=$((problems+1)); }
done
for x in tests/cas_*.expected; do
  [ -e "$x" ] || continue
  n="$(basename "$x" .expected)"
  [ -f "tests/$n.lisp" ] || { echo "  ERROR: $n.expected has no .lisp"; problems=$((problems+1)); }
done
echo "  checked"

echo "== prelude =="
grep -q "add-module-path!" src/prelude.lisp && echo "  prelude registers the library path — ok" || { echo "  ERROR: prelude missing add-module-path!"; problems=$((problems+1)); }

echo ""
if [ $problems -eq 0 ]; then echo "STRUCTURE OK"; exit 0; else echo "STRUCTURE PROBLEMS: $problems"; exit 1; fi
