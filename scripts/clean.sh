#!/usr/bin/env bash
# scripts/clean.sh -- remove build artifacts, Nix results, and editor/OS cruft from the repo.
#
# Sangaku itself has nothing to compile, so this mostly clears Nix `result` symlinks, any
# stray interpreter build output, and editor backups. Safe to run anytime; it never touches
# source, examples, tests, or docs.
#
#   scripts/clean.sh           # clean
#   scripts/clean.sh --dry-run # show what would be removed, delete nothing
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

removed=0
zap () {
  # zap GLOB... -- remove matching paths (files or dirs), honoring --dry-run
  for p in "$@"; do
    [ -e "$p" ] || continue
    if [ $DRY -eq 1 ]; then
      echo "  would remove: $p"
    else
      rm -rf "$p" && echo "  removed: $p"
    fi
    removed=$((removed + 1))
  done
}

echo "== cleaning Sangaku =="

# Nix build results
zap result result-*

# Interpreter build artifacts (only present if a local/vendored Lizard was ever built here)
zap build
find . -type f \( -name '*.o' -o -name '*.a' -o -name '*.so' -o -name '*.d' \) 2>/dev/null | while read -r f; do
  if [ $DRY -eq 1 ]; then echo "  would remove: $f"; else rm -f "$f" && echo "  removed: $f"; fi
done

# Editor / OS cruft
find . -type f \( -name '*.swp' -o -name '*~' -o -name '*.orig' -o -name '.DS_Store' \) 2>/dev/null | while read -r f; do
  if [ $DRY -eq 1 ]; then echo "  would remove: $f"; else rm -f "$f" && echo "  removed: $f"; fi
done

# Scratch outputs sometimes left in the repo root
zap /tmp/sangaku-scratch.lisp 2>/dev/null

echo ""
if [ $DRY -eq 1 ]; then
  echo "dry run complete (nothing deleted)."
else
  echo "clean complete."
fi
