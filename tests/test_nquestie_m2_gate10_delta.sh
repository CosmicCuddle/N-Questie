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
# Exact public objective projection check: source-closure pilot is five item
# objectives in 3 quests. This does not establish server-required counts or
# native quest-log text/order; those remain separate owner/3.3.5a gates.
"$LUA" - "$F" <<'NQ_GATE10_OBJECTIVES'
local p = assert(arg[1], "expected a validated v2 export file")
local f = assert(io.open(p, "rb"))
local txt = assert(f:read("*a"))
f:close()
local Export = dofile("tools/validation/ExportV2.lua")
local doc, errs = Export.ParseAndValidate(txt)
assert(doc, "v2 document invalid: " .. table.concat(errs or {}, ";"))
local expected = {
    [1207] = {166},
    [1208] = {167},
    [1209] = {160, 161, 162},
}
local found, total = {}, 0
for _, q in ipairs(doc.quests) do
    local wants = expected[q.ID]
    if wants then
        assert(not found[q.ID], "duplicate Gate10 quest")
        found[q.ID] = true
        assert(q.m1Status == "SUPPORTED", "Gate10 objective is not M1-supported")
        assert(q.requiredLevel == 18 and q.questLevel == 21,
            "unexpected level in Gate10 quest")
        assert(#q.objectives == #wants, "wrong objective count for Gate10 quest")
        for i, objective in ipairs(q.objectives) do
            assert(objective.kind == "item" and objective.slotIndex == i
                and objective.id == wants[i],
                "objective identity/order differs from reviewed Gate10 source")
            total = total + 1
        end
    end
end
assert(found[1207] and found[1208] and found[1209], "Gate10 quest missing")
assert(total == 5, "not exactly five Gate10 item objectives")
print("PASS: Gate10 3 quests, 5 item objectives, exact IDs/order/levels in v2")
NQ_GATE10_OBJECTIVES
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
# Optional deep control: compare every inherited v2 quest record against a
# fresh PUBLIC 335 export, not only the original 9159-ID fingerprint.
# Slow and opt-in. Refuse any non-0/1 mode rather than silently skipping it.
COMPARE_335="$(printenv NQ_GATE10_COMPARE_335 2>/dev/null || printf 0)"
case "$COMPARE_335" in
0) : ;;
1)
  git clone -q --no-hardlinks "$(pwd -P)" "$T/pinned-335"
  (cd "$T/pinned-335" &&
    git checkout -q --detach 26053bd28b0df3a01e5859f779d5f3cb4f57b221 &&
    test -z "$(git status --porcelain --untracked-files=all)")
  mkdir -m 700 "$T/base-export"
  (cd "$T/pinned-335" &&
    env NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 NQ_EXPORT_SCHEMA_VERSION=2 \
      NQ_EXPORT_V2_OUT="$T/base-export/v2.lua" "$LUA" cli/validate-335.lua \
      >"$T/base-stdout" 2>"$T/base-stderr")
  test -f "$T/base-export/v2.lua"
  grep -q "PASS: 232 checks" "$T/base-stderr"
  "$LUA" - "$T/base-export/v2.lua" "$F" <<'NQ_GATE10_RECORD_COMPARE'
local Export = dofile("tools/validation/ExportV2.lua")
local Schema = dofile("tools/validation/EffectiveSchemaV2.lua")
local function doc(path)
    local f = assert(io.open(path, "rb"))
    local text = assert(f:read("*a"))
    f:close()
    local d, errors = Export.ParseAndValidate(text)
    assert(d, table.concat(errors or {}, ";"))
    return d
end
local base, proposed = doc(arg[1]), doc(arg[2])
assert(#base.quests == 9159 and #proposed.quests == 9162, "unexpected quest count")
local before, after = {}, {}
for _, q in ipairs(base.quests) do
    assert(not before[q.ID], "duplicate ID in original 335")
    before[q.ID] = q
end
for _, q in ipairs(proposed.quests) do
    assert(not after[q.ID], "duplicate ID in Gate10")
    after[q.ID] = q
end
local compared = 0
for id, q in pairs(before) do
    assert(after[id], "original quest disappeared: " .. id)
    assert(Schema.Canonical(q, {}) == Schema.Canonical(after[id], {}),
        "existing v2 quest record changed: " .. id)
    compared = compared + 1
end
assert(compared == 9159)
local additions, expected = {}, { [1207]=true, [1208]=true, [1209]=true }
for id in pairs(after) do
    if not before[id] then
        assert(expected[id], "unexpected new quest: " .. id)
        additions[id] = true
    end
end
for id in pairs(expected) do assert(additions[id], "missing new quest: " .. id) end
print("PASS: all 9159 inherited v2 structural quest records unchanged")
print("PASS: exactly 1207,1208,1209 added; provenance intentionally excluded")
NQ_GATE10_RECORD_COMPARE
  ;;
*) echo "REFUSE: NQ_GATE10_COMPARE_335 must be 0 or 1" >&2; exit 2 ;;
esac
test -z "$(git status --porcelain --untracked-files=all)"
echo "PASS: Gate10 = protected 9159-ID set + exactly three new quests"
echo "PASS: 8404 supported; 758 unsupported; 0 reason/manifest/round-trip differences"
echo "NOT TESTED: client, IP/phase, world spawn transforms, Gate08 or release"
