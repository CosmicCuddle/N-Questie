#!/usr/bin/env bash
# M2.2 coverage / preflight integration: real cli/validate-335.lua runs over
# ALL public compiled 3.3.5a quests. Writes only to a temporary 0700
# directory. Needs a CLEAN git checkout (provenance). ~1-3 minutes.
set -u
cd "$(dirname "$0")/.."
LUA="${LUA:-lua5.1}"
fails=0; passes=0
ok()  { passes=$((passes+1)); echo "PASS: $1"; }
bad() { fails=$((fails+1)); echo "FAIL: $1"; }
T="$(mktemp -d)"; chmod 700 "$T"
trap 'rm -rf -- "$T"' EXIT
strip() { sed 's/\x1b\[[0-9;]*m//g'; }
E28=NQ_VALIDATE_EXPECT_LEVEL_COUNT=28

refuse() { # name expected-text env...
    local name="$1" want="$2"; shift 2
    env "$@" "$LUA" cli/validate-335.lua >"$T/log" 2>&1; local c=$?
    if [ $c -ne 0 ] && strip <"$T/log" | grep -qF -- "$want" && ! strip <"$T/log" | grep -q "PASS: "; then
        ok "refused before M0: $name"; else bad "refused before M0: $name (exit $c)"; fi
}
refuse "manifest inside checkout outside private/" "coverage: manifest" $E28 NQ_COVERAGE_MANIFEST_OUT="$PWD/coverage-manifest.lua"
[ ! -e coverage-manifest.lua ] && ok "nothing written in checkout" || { bad "file written in checkout"; rm -f coverage-manifest.lua; }
refuse "aggregate without manifest" "without NQ_COVERAGE_MANIFEST_OUT" $E28 NQ_COVERAGE_AGGREGATE_OUT="$T/a.txt"
refuse "together with export" "not allowed together with an effective export" $E28 NQ_COVERAGE_MANIFEST_OUT="$T/m.lua" NQ_EXPORT_EFFECTIVE_OUT="$T/e.lua" NQ_EXPORT_QUESTS=1203
refuse "missing level-count assertion" "NQ_VALIDATE_EXPECT_LEVEL_COUNT must be set" NQ_COVERAGE_MANIFEST_OUT="$T/m.lua"
refuse "skip-compile" "needs the compiled database" $E28 NQ_VALIDATE_SKIP_COMPILE=1 NQ_COVERAGE_MANIFEST_OUT="$T/m.lua"
refuse "same manifest and aggregate path" "must differ" $E28 NQ_COVERAGE_MANIFEST_OUT="$T/m.lua" NQ_COVERAGE_AGGREGATE_OUT="$T/m.lua"
[ ! -e "$T/m.lua" ] && [ ! -e "$T/a.txt" ] && ok "nothing written on refusal" || bad "file written on refusal"

# Real run over every compiled quest
mkdir -m 700 "$T/priv"
env $E28 NQ_COVERAGE_MANIFEST_OUT="$T/priv/manifest.lua" NQ_COVERAGE_AGGREGATE_OUT="$T/priv/aggregate.txt" \
    "$LUA" cli/validate-335.lua >"$T/log" 2>&1; c=$?
strip <"$T/log" >"$T/clean"
[ $c -eq 0 ] && ok "coverage run exit 0" || bad "coverage run exit $c"
grep -q "PASS: 232 checks" "$T/clean" && ok "all 232 M0 checks passed first" || bad "M0 checks"
grep -q "82431 quest fields compared, 0 mismatches" "$T/clean" && ok "82,431 compiled fields, 0 mismatches" || bad "integrity"
line=$(grep -n "PASS: 232 checks" "$T/clean" | cut -d: -f1); cov=$(grep -n "COVERAGE REPORT" "$T/clean" | cut -d: -f1)
[ -n "$line" ] && [ -n "$cov" ] && [ "$cov" -gt "$line" ] && ok "report produced after M0" || bad "report order"
grep -q "not an export" "$T/clean" && ok "labelled not an export" || bad "label"
grep -Eq "^total quests +9159$" "$T/clean" && ok "total 9159" || bad "total"
grep -Eq "^unclassified +0$" "$T/clean" && ok "0 unclassified" || bad "unclassified"
grep -q "^reconciled:" "$T/clean" && ok "reconciled" || bad "reconciled"
[ "$(stat -c %a "$T/priv/manifest.lua")" = 600 ] && ok "manifest mode 0600" || bad "manifest mode"
[ "$(stat -c %a "$T/priv/aggregate.txt")" = 600 ] && ok "aggregate mode 0600" || bad "aggregate mode"
NQ_M="$T/priv/manifest.lua" NQ_A="$T/priv/aggregate.txt" "$LUA" -e '
local S = dofile("tools/validation/EffectiveSchema.lua")
local f = io.open(os.getenv("NQ_M")); local src = f:read("*a"); f:close()
local d = S.ParseString(src); assert(d, "manifest does not parse as data")
assert(d.kind == "nq-m2-coverage-manifest", "kind")
local rep, uns, combos = 0, 0, {}
for _, q in ipairs(d.quests) do
  if q.status == "REPRESENTABLE" then assert(#q.reasons == 0); rep = rep + 1
  else assert(q.status == "UNSUPPORTED" and #q.reasons > 0); uns = uns + 1 end
  assert(q.objectives == nil and q.questLevel == nil, "manifest must not carry records")
end
assert(#d.quests == d.aggregate.total and rep == d.aggregate.representable and uns == d.aggregate.unsupported, "reconcile")
assert(d.provenance and #d.provenance.sourceCommit == 40, "provenance")
local by = {}
for _, q in ipairs(d.quests) do by[q.ID] = table.concat(q.reasons, "+") end
assert(by[1203] == "" and by[11142] == "DUPLICATE_OBJECT+EXTRA_CREATURE_REF" and by[1367] == "EXTRA_CREATURE_REF+REPUTATION_OBJECTIVE", "known quests")
local a = io.open(os.getenv("NQ_A")):read("*a"); assert(not a:find("ID = ", 1, true), "aggregate has per-quest data")
' && ok "manifest parses, reconciles, keeps all reasons, carries no records" || bad "manifest content"

# The exporter refuses an unsupported id with every reason, writes nothing
env $E28 NQ_EXPORT_EFFECTIVE_OUT="$T/priv/e.lua" NQ_EXPORT_QUESTS="1203,11142" "$LUA" cli/validate-335.lua >"$T/log" 2>&1; c=$?
[ $c -ne 0 ] && strip <"$T/log" | grep -q "quest 11142: refused, reasons: DUPLICATE_OBJECT,EXTRA_CREATURE_REF" && [ ! -e "$T/priv/e.lua" ] \
    && ok "export refuses 11142 with both reasons; nothing written" || bad "export refusal of 11142 (exit $c)"

echo "coverage integration: $passes passed, $fails failed"
[ $fails -eq 0 ]
