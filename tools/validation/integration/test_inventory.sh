#!/usr/bin/env bash
# Test-preservation check for an integration candidate (read-only git).
# Usage: test_inventory.sh <target-ref> <source-ref>...
# Inventories, per ref: test files (tests/test_*, tests/check_*, *.test.lua,
# *_spec.lua), run_m2_suite.sh step lines, busted wrapper entries
# (M22Libraries.test.lua) and workflow "run:" commands. Every item present in
# any source must be present in the target; prints counts per ref and the
# missing items. Exit 1 if anything is missing. Writes nothing.
set -euo pipefail
[ $# -ge 2 ] || { echo "usage: $0 <target-ref> <source-ref>..." >&2; exit 2; }
inv() {
  local ref=$1
  git ls-tree -r --name-only "$ref" | grep -E '^tests/(test_|check_)[^/]+\.(lua|sh)$|\.test\.lua$|_spec\.lua$' | sed 's/^/file: /'
  git show "$ref:tests/run_m2_suite.sh" 2>/dev/null | grep -E '^step ' | sed -E 's/^step "[^"]*" /suite: /' || true
  git show "$ref:tools/validation/M22Libraries.test.lua" 2>/dev/null | grep -oE '"tests/[^"]+"' | sed 's/^/busted: /' || true
  for wf in $(git ls-tree -r --name-only "$ref" .github/workflows 2>/dev/null); do
    git show "$ref:$wf" | grep -E '^\s+(run:|lua5\.1|bash|busted)' | sed -E 's/^\s+//; s/^run: //' | sed "s|^|workflow $wf: |"
  done
}
target=$1; shift
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
inv "$target" | sort -u > "$tmp/target"
printf '%-12s %6s %6s %6s %6s\n' ref files suite busted wf
row() { printf '%-12s %6d %6d %6d %6d\n' "$1" "$(grep -c '^file:' "$2" || true)" "$(grep -c '^suite:' "$2" || true)" "$(grep -c '^busted:' "$2" || true)" "$(grep -c '^workflow' "$2" || true)"; }
row target "$tmp/target"
missing=0
for src in "$@"; do
  inv "$src" | sort -u > "$tmp/src"
  row "$(git rev-parse --short "$src")" "$tmp/src"
  m=$(comm -23 "$tmp/src" "$tmp/target" || true)
  if [ -n "$m" ]; then missing=1; echo "MISSING in target from $src:"; echo "$m" | sed 's/^/  /'; fi
done
[ $missing = 0 ] && echo "PASS: every test file, suite step, busted entry and workflow command from the sources is in the target" || { echo "FAIL: items missing"; exit 1; }
