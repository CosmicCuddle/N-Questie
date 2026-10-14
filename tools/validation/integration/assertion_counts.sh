#!/usr/bin/env bash
# Static assertion counts per test file, source refs vs an integration target
# (read-only git). Counts assertion-like calls: in Lua ok(, check(, expect(,
# eq(, it(, assert*(; in shell pass/fail/check/expect/assert helpers. For each
# test file present in a source, the target count must be >= the source count
# (a smaller count means assertions were dropped in a merge). Prints a table
# and exits 1 on any drop. Executed pass counts are compared separately from
# suite logs (see docs/NQ-INTEGRATION-PLAN.md section 4).
# Usage: assertion_counts.sh <target-ref> <source-ref>...
set -euo pipefail
[ $# -ge 2 ] || { echo "usage: $0 <target-ref> <source-ref>..." >&2; exit 2; }
files() { git ls-tree -r --name-only "$1" | grep -E '^tests/(test_|check_)[^/]+\.(lua|sh)$|\.test\.lua$|_spec\.lua$'; }
count() {
  local ref=$1 f=$2
  case "$f" in
    *.lua) git show "$ref:$f" | { grep -oE '(^|[^A-Za-z0-9_.:])(ok|check|expect|eq|it|assert[A-Za-z_.]*)[[:space:]]*\(' || true; } | wc -l ;;
    *.sh)  git show "$ref:$f" | { grep -oE '(^|[^A-Za-z0-9_])(pass|fail|check|expect|assert)[A-Za-z_]*[[:space:]]+["$]' || true; } | wc -l ;;
  esac
}
target=$1; shift
drop=0
printf '%-55s %-10s %6s %6s\n' file source src target
for src in "$@"; do
  s=$(git rev-parse --short "$src")
  for f in $(files "$src"); do
    a=$(count "$src" "$f")
    if git cat-file -e "$target:$f" 2>/dev/null; then b=$(count "$target" "$f"); else b=MISSING; fi
    flag=""
    if [ "$b" = MISSING ] || [ "$b" -lt "$a" ]; then flag="  DROP"; drop=1; fi
    printf '%-55s %-10s %6s %6s%s\n' "$f" "$s" "$a" "$b" "$flag"
  done
done
[ $drop = 0 ] && echo "PASS: no test file lost assertions" || { echo "FAIL: assertions dropped"; exit 1; }
