#!/usr/bin/env bash
# Gate10 TEST-ONLY v2 export proof. Historical Stage A2 baseline is untouched.
# Public Questie records only, never owner-private SQL. No install or release.
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
LUA="$(printenv LUA 2>/dev/null || printf lua5.1)"
PIN_SHA=e7dfb2a99642544b66359b6721887083a3bdab783986d75de32296c783edb6a3
test -z "$(git status --porcelain --untracked-files=all)" || {
 echo "REFUSE: clean checkout required" >&2; exit 2;
}
command -v "$LUA" >/dev/null || { echo "REFUSE: Lua unavailable" >&2; exit 2; }
T="$(mktemp -d)"
chmod 700 "$T"
trap 'chmod -R u+rwx "$T" 2>/dev/null || :; rm -rf -- "$T"' EXIT
mkdir -m 700 "$T/export" "$T/coverage"
F="$T/export/v2.lua"
expect() { grep -qx -- "$1" "$2" || { echo "FAIL: $1" >&2; exit 1; }; }
env NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 NQ_EXPORT_SCHEMA_VERSION=2 \
 NQ_EXPORT_V2_OUT="$F" "$LUA" cli/validate-335.lua \
 >"$T/export.out" 2>"$T/export.err"
test -f "$F" && test ! -L "$F"
test "$(stat -c %a "$F")" = 600
grep -q "PASS: 232 checks" "$T/export.err"
grep -Eq '^quests exported +9162$' "$T/export.out"
"$LUA" tests/check_m2_v2_export_file.lua ids "$F" >"$T/all-ids"
test "$(wc -l <"$T/all-ids")" -eq 9162
for id in 1207 1208 1209; do test "$(grep -xc -- "$id" "$T/all-ids")" -eq 1; done
grep -Ev '^(1207|1208|1209)$' "$T/all-ids" >"$T/base-ids"
test "$(wc -l <"$T/base-ids")" -eq 9159
test "$(sha256sum "$T/base-ids" | cut -d ' ' -f1)" = "$PIN_SHA"
"$LUA" tests/check_m2_v2_export_file.lua counts "$F" >"$T/counts"
for kv in quests=9162 questCount=9162 supported=8404 unsupported=758 sorted=1 \
 reason.EXTRA_CREATURE_REF=359 reason.EXTRA_OBJECT_REF=243 \
 reason.REPUTATION_OBJECTIVE=181 reason.KILLCREDIT_FIRST_REORDER=16 \
 reason.DUPLICATE_CREATURE=7 reason.DUPLICATE_OBJECT=1; do expect "$kv" "$T/counts"; done
test "$(grep -c '^reason\.' "$T/counts")" -eq 6
env NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 \
 NQ_COVERAGE_MANIFEST_OUT="$T/coverage/manifest.lua" \
 "$LUA" cli/validate-335.lua >"$T/coverage.out" 2>"$T/coverage.err"
"$LUA" tests/check_m2_v2_export_file.lua coverage "$F" "$T/coverage/manifest.lua" >"$T/covcheck"
for kv in compared=9162 differing=0 manifestOnly=0; do expect "$kv" "$T/covcheck"; done
env NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 NQ_V2_VERIFY_IN="$F" \
 "$LUA" cli/validate-335.lua >"$T/verify.out" 2>"$T/verify.err"
grep -q "v2 verify PASS" "$T/verify.err"
for spec in \
 '^round trip: quests compared +9162$' \
 '^round trip: quests differing +0$' \
 '^round trip: differences +0$' \
 '^v1 equivalence: quests compared +8404$' \
 '^v1 equivalence: quests differing +0$' \
 '^file provenance matches this checkout +yes$' \
 '^write/process attempts blocked +0$'; do grep -Eq "$spec" "$T/verify.out"; done
test -z "$(git status --porcelain --untracked-files=all)"
echo "PASS: Gate10 = protected 9159-ID set + exactly three new quests"
echo "PASS: 8404 supported; 758 unsupported; 0 reason/manifest/round-trip differences"
echo "NOT TESTED: client, IP/phase, world spawn transforms, Gate08 or release"
