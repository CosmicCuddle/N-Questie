#!/usr/bin/env bash
# Gate10 TEST-ONLY A1 variant. Actual read-only M2 round-trip mode over
# candidate 9,162 public quests. Original 335 M2 tests remain untouched.
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
LUA=lua5.1
test -z "$(git status --porcelain --untracked-files=all)" || {
  echo "REFUSE: Gate10 checkout must be clean" >&2; exit 2;
}
"$LUA" -e 'assert(type(require("bit32")) == "table")'
T="$(mktemp -d)"
chmod 700 "$T"
STAGE="initialization"
finish() {
  local code=$?
  trap - EXIT
  if [ "$code" -ne 0 ]; then
    echo "FAIL: Gate10 A1 round-trip stage $STAGE (exit $code)" >&2
    for f in "$T/r1.err" "$T/r1.out" "$T/r2.err" "$T/r2.out"; do
      if [ -f "$f" ]; then
        echo "LOG: ${f##*/} last 16 public lines" >&2
        tail -n 16 "$f" >&2 || :
      fi
    done
  fi
  chmod -R u+rwx "$T" 2>/dev/null || :
  rm -rf -- "$T"
  exit "$code"
}
trap finish EXIT
mkdir -m 700 "$T/home" "$T/tmp"
STAGE="first actual read-only round trip"
env -u NQ_EXPORT_EFFECTIVE_OUT HOME="$T/home" TMPDIR="$T/tmp" \
  NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 NQ_V2_ROUNDTRIP=1 \
  "$LUA" cli/validate-335.lua >"$T/r1.out" 2>"$T/r1.err"
STAGE="second independent process round trip"
env -u NQ_EXPORT_EFFECTIVE_OUT HOME="$T/home" TMPDIR="$T/tmp" \
  NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 NQ_V2_ROUNDTRIP=1 \
  "$LUA" cli/validate-335.lua >"$T/r2.out" 2>"$T/r2.err"
STAGE="assert actual mode and counts"
grep -q "PASS: 232 checks" "$T/r1.err"
grep -q "PASS: 232 checks" "$T/r2.err"
grep -q "v2 round trip PASS (read-only, nothing written)" "$T/r1.err"
grep -q "v2 round trip PASS (read-only, nothing written)" "$T/r2.err"
# An M0 PASS does not guarantee the declared Gate10 source batch survived.
STAGE="verify the complete Gate10 source batch was admitted"
grep -Fqx '[validate-335] questData IDs added by N-Questie: 1207,1208,1209,2001; removed: none' "$T/r1.out" || {
  echo "FAIL: candidate Questie custom batch missing despite M0 PASS" >&2
  grep -F 'questData IDs added by N-Questie:' "$T/r1.out" >&2 || :
  exit 1
}
grep -Fqx '[validate-335] questData IDs added by N-Questie: 1207,1208,1209,2001; removed: none' "$T/r2.out"
STAGE="assert actual mode and counts"
expect() { grep -Eq -- "^$1 +$2$" "$T/r1.out" || { echo "FAIL: expected $1 = $2" >&2; exit 1; }; }
expect "quests processed" 9162
expect "compiled quest IDs" 9162
expect "records built" 9162
expect "m1 SUPPORTED \\(v1 representable\\)" 8404
expect "m1 UNSUPPORTED_BY_RULES \\(v1 unsupported\\)" 758
expect "build errors" 0
expect "record validation errors" 0
expect "unclassified" 0
expect "m1 status disagreeing with v2 ExpectedM1" 0
expect "round trip: quests compared" 9162
expect "round trip: quests differing" 0
expect "round trip: differences" 0
expect "positions checked \\(quests\\)" 9162
expect "v1 equivalence: quests compared" 8404
expect "v1 equivalence: quests differing" 0
expect "source data unchanged \\(fingerprint\\)" yes
expect "repeat run aggregate identical" yes
expect "write/process attempts blocked" 0
STAGE="identical aggregates and unchanged original checkout"
grep -vE '^(cpu seconds|lua heap)' "$T/r1.out" >"$T/a1"
grep -vE '^(cpu seconds|lua heap)' "$T/r2.out" >"$T/a2"
cmp -s "$T/a1" "$T/a2"
test -z "$(find "$T/home" "$T/tmp" -mindepth 1 -print -quit)"
test -z "$(git status --porcelain --untracked-files=all)"
echo "PASS: Gate10 A1 actual in-memory v2 round-trip, 9162 quests, 8404 supported"
echo "PASS: 0 build/record/round-trip/v1 discrepancies, 0 writes, two identical runs"
echo "NOT CLAIMED: original 335 historical tests pass against candidate counts"
echo "NOT TESTED: native 3.3.5a, IP, Gate08, private SQL or release"
