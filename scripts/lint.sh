#!/usr/bin/env bash
# scripts/lint.sh -- fast static checks across all Sangaku Lisp, no interpreter needed.
#
# Catches the cheap-but-real mistakes before you ever run the suite:
#   * unbalanced parentheses (counts ( vs ), ignoring those inside strings and ; comments)
#   * parentheses embedded inside a symbol name (these silently break the s-expression reader,
#     e.g. a quoted symbol like  foo=1/(s^2+1)  -- a bug actually hit during development)
#   * tab characters (Sangaku uses spaces) and trailing whitespace
#
#   scripts/lint.sh            # check src/, examples/, tests/
#   scripts/lint.sh src/cas    # check a subdirectory
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2

DIRS="${*:-src examples tests}"
problems=0

# Paren balance, ignoring string contents and ; comments. Implemented in awk for portability.
check_parens () {
  awk '
    BEGIN { depth = 0 }
    {
      n = length($0); instr = 0
      for (i = 1; i <= n; i++) {
        c = substr($0, i, 1)
        if (instr) {
          if (c == "\\") { i++; continue }     # skip escaped char in string
          if (c == "\"") instr = 0
          continue
        }
        if (c == ";") break                     # rest of line is a comment
        if (c == "\"") { instr = 1; continue }
        if (c == "(") depth++
        else if (c == ")") depth--
      }
    }
    END { print depth }
  ' "$1"
}

for d in $DIRS; do
  [ -d "$d" ] || { [ -f "$d" ] && files="$d" || continue; }
  files="$(find "$d" -name '*.lisp' 2>/dev/null)"
  for f in $files; do
    bal="$(check_parens "$f")"
    if [ "$bal" != "0" ]; then
      echo "  PAREN IMBALANCE ($bal) in $f"
      problems=$((problems + 1))
    fi
    # parens embedded inside an atom in CODE (not comments or strings): a paren glued to symbol
    # characters with no separating space, e.g. a quoted symbol  foo=1/(s^2+1)  -- which silently
    # breaks the s-expression reader. We first strip ; comments and "..." strings, then look for a
    # paren adjacent to atom characters within a single token. (Comments routinely contain math like
    # 1/(x^2-1), so they must be removed before this check or it is all false positives.)
    stripped="$(sed -E 's/"([^"\\]|\\.)*"/ /g; s/;.*$//' "$f")"
    if printf '%s\n' "$stripped" | grep -nE '[A-Za-z0-9^/*=._+-]\)[A-Za-z0-9^/*=._+-]|[A-Za-z0-9^/*=._+-]\([A-Za-z0-9^/*=._+-]' >/dev/null 2>&1; then
      echo "  PAREN-IN-ATOM in $f (a paren glued inside a code token can break the reader):"
      printf '%s\n' "$stripped" | grep -nE '[A-Za-z0-9^/*=._+-]\)[A-Za-z0-9^/*=._+-]|[A-Za-z0-9^/*=._+-]\([A-Za-z0-9^/*=._+-]' | head -3 | sed 's/^/      /'
      problems=$((problems + 1))
    fi
    # tabs
    if grep -nP '\t' "$f" >/dev/null 2>&1; then
      echo "  TAB CHARACTER in $f (use spaces)"
      problems=$((problems + 1))
    fi
    # trailing whitespace
    if grep -nE ' +$' "$f" >/dev/null 2>&1; then
      echo "  TRAILING WHITESPACE in $f ($(grep -cE ' +$' "$f") line(s))"
      problems=$((problems + 1))
    fi
  done
done

echo ""
if [ $problems -eq 0 ]; then echo "LINT CLEAN"; exit 0; else echo "LINT PROBLEMS: $problems"; exit 1; fi
