#!/usr/bin/env bash
# scripts/find-orphans.sh -- report repo hygiene issues that accumulate over time:
#   * goldens with no matching .lisp (or .lisp with no .expected)
#   * cas modules that NOTHING imports (not another module, not an example, not a golden) --
#     candidate dead code worth reviewing (a leaf module is only "alive" if something uses it)
#
# This is advisory: an "orphan" module may be a genuine top-level entry point that is only ever
# imported by a user's own program. Review before deleting anything.
#
#   scripts/find-orphans.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2

echo "== unpaired goldens =="
unpaired=0
for t in tests/cas_*.lisp; do
  [ -e "$t" ] || continue
  n="$(basename "$t" .lisp)"
  [ -f "tests/$n.expected" ] || { echo "  $n.lisp has no .expected"; unpaired=$((unpaired + 1)); }
done
for x in tests/cas_*.expected; do
  [ -e "$x" ] || continue
  n="$(basename "$x" .expected)"
  [ -f "tests/$n.lisp" ] || { echo "  $n.expected has no .lisp"; unpaired=$((unpaired + 1)); }
done
[ $unpaired -eq 0 ] && echo "  none -- every golden is paired"

echo ""
echo "== modules imported by nothing (candidate dead code) =="
# Collect every import target across the whole repo. Imports may be plain --
#   (import "cas/poly.lisp")
# or aliased --
#   (import "cas/integral-cert.lisp" :as ic)
# so we match the quoted path regardless of what follows it, not requiring a ')' right after.
imports="$(grep -rhoE '\(import[[:space:]]+"cas/[^"]+"' src examples tests 2>/dev/null \
            | sed -E 's/.*"cas\/([^"]+)".*/\1/' | sort -u)"
orphans=0
for m in $(find src/cas -name '*.lisp'); do
  base="$(basename "$m")"
  # Is this module's filename referenced by any import anywhere?
  if ! printf '%s\n' "$imports" | grep -qx "$base"; then
    echo "  $base -- imported by nothing"
    orphans=$((orphans + 1))
  fi
done
if [ $orphans -eq 0 ]; then
  echo "  none -- every module is imported somewhere"
else
  echo ""
  echo "  ($orphans module(s) imported by nothing -- review: a true entry point may legitimately"
  echo "   be imported only by user code; otherwise these are candidates for removal or a test.)"
fi

echo ""
echo "== examples without a corresponding golden topic (informational) =="
echo "  (examples need not have goldens; this is just a count)"
echo "  examples: $(ls examples/*.lisp 2>/dev/null | wc -l), goldens: $(ls tests/cas_*.lisp 2>/dev/null | wc -l)"
