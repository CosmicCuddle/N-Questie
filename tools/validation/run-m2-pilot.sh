#!/usr/bin/env bash
# N-Questie M2.2 pilot procedure (quest 1203 first, then the v1 pilot list).
#
# Reproducible, read-only on the checkout. Writes ONLY to OUT_DIR, which must be
# an absolute 0700 directory outside the checkout (or under private/). Nothing
# here publishes anything. Public Questie data only; no private server data is
# read. The comparison with private acore_world data is M2.3 and is NOT done here.
#
# Usage: tools/validation/run-m2-pilot.sh /abs/private/dir [1203|pilot]
#   1203  (default) export quest 1203 only
#   pilot export the proposed v1 pilot list (docs/NQ-VALIDATION-M2.2-PILOT.md)
set -u
cd "$(dirname "$0")/../.."
LUA="${LUA:-lua5.1}"
OUT="${1:-}"; MODE="${2:-1203}"
PILOT="1203,2001,498,553,786,2784,3377,9666,4022,532,10392,1045,611,717,30,25"
fails=0
ok()  { echo "PASS: $1"; }
bad() { fails=$((fails+1)); echo "FAIL: $1"; }
die() { echo "STOP: $1"; exit 1; }
strip() { sed 's/\x1b\[[0-9;]*m//g'; }

# 0. Preconditions (fail closed)
[ -n "$OUT" ] && [ "${OUT#/}" != "$OUT" ] || die "OUT_DIR must be an absolute path"
case "$MODE" in 1203) IDS=1203 ;; pilot) IDS="$PILOT" ;; *) die "mode must be 1203 or pilot" ;; esac
realpath --version 2>/dev/null | head -1 | grep -q GNU || die "GNU realpath required"
command -v "$LUA" >/dev/null && command -v git >/dev/null && command -v sha256sum >/dev/null || die "lua5.1, git and sha256sum required"
[ -z "$(git status --porcelain --untracked-files=all)" ] || die "checkout must be clean (provenance)"
[ -d "$OUT" ] || { mkdir -p -- "$OUT" && chmod 700 -- "$OUT"; } || die "cannot create $OUT"
[ "$(stat -c %a "$OUT")" = 700 ] || die "$OUT must be mode 0700"
FILE="$OUT/effective-$MODE.lua"
[ ! -e "$FILE" ] || die "$FILE exists; remove it or choose another OUT_DIR (no clobber)"
HEAD=$(git rev-parse HEAD)
echo "N-Questie M2.2 pilot: mode=$MODE commit=$HEAD out=$FILE"

# 1. M0 negatives: the five fault-injection fixtures must still be rejected
LUA="$LUA" bash tests/test_validate_335_fixtures.sh >"$OUT/negatives.log" 2>&1; c=$?
n=$(strip <"$OUT/negatives.log" | grep -c "rejected with")
[ $c -eq 0 ] && [ "$n" -eq 5 ] && ok "5 M0 negative fixtures rejected" || bad "M0 negatives (exit $c, $n rejected)"
[ $fails -eq 0 ] || die "negatives failed; not exporting"

# 2. M0 + export in one harness run (export happens only after every check passes)
NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 NQ_EXPORT_EFFECTIVE_OUT="$FILE" NQ_EXPORT_QUESTS="$IDS" \
    "$LUA" cli/validate-335.lua 2>&1 | strip >"$OUT/harness.log"; c=${PIPESTATUS[0]}
L="$OUT/harness.log"
[ $c -eq 0 ] && ok "harness exit 0" || bad "harness exit $c"
grep -q "PASS: 232 checks" "$L" && ok "232 M0 checks passed" || bad "232 M0 checks"
grep -q "level corrections asserted: 28" "$L" && ok "28 level corrections" || bad "28 corrections"
grep -q "82431 quest fields compared, 0 mismatches" "$L" && ok "82,431 compiled fields, 0 mismatches" || bad "integrity"
grep -q "M1 rules on quest 1203: stock Questie = CONFIRMED_MISMATCH, effective N-Questie = EXPECTED_REPRESENTATION_DIFF" "$L" \
    && ok "M1 on 1203: stock CONFIRMED_MISMATCH, effective EXPECTED_REPRESENTATION_DIFF" || bad "M1 1203 line"
grep -q "effective export written" "$L" && [ -f "$FILE" ] && ok "export written after PASS" || bad "export not written"
[ $fails -eq 0 ] || die "harness failed; see $L"
[ "$(stat -c %a "$FILE")" = 600 ] && ok "export mode 0600" || bad "export mode"

# 3. Stock value from the public source line (unchanged upstream data)
grep -q '^\[1203\] = {"Jarl Needs a Blade".*{nil,nil,{{33110}}}' Database/Wotlk/wotlkQuestDB.lua \
    && ok "stock Questie 1203 objective item 33110 (Database/Wotlk/wotlkQuestDB.lua)" || bad "stock 33110"

# 4. Effective values and provenance from the written file
NQ_F="$FILE" NQ_H="$HEAD" NQ_IDS="$IDS" "$LUA" -e '
local E = dofile("tools/validation/EffectiveSchema.lua")
local root = io.popen("pwd -P"):read("*l")
local d, errs = E.LoadFile(os.getenv("NQ_F"), root, { expectKind = "effective", expectCorrectionCount = 28 })
if not d then print(table.concat(errs, "\n")) os.exit(1) end
local p = d.provenance
assert(p.sourceCommit == os.getenv("NQ_H"), "sourceCommit is not HEAD")
assert(p.nQuestieDataRevision == 5 and p.correctionCount == 28 and p.m0Checks == 232, "provenance facts")
local want, n = {}, 0
for id in os.getenv("NQ_IDS"):gmatch("%d+") do n = n + 1; want[n] = tonumber(id) end
assert(#d.quests == n, "record count")
for i, q in ipairs(d.quests) do assert(q.ID == want[i], "order") end
local q = d.quests[1]
assert(q.ID == 1203 and q.requiredLevel == 30 and q.questLevel == 35, "1203 levels 30/35")
assert(#q.objectives.items == 1 and q.objectives.items[1] == 3853, "1203 effective item 3853")
print("effective 1203: levels 30/35, item 3853; records " .. n .. "; sourceCommit " .. p.sourceCommit:sub(1, 9) ..
      "; revision " .. p.nQuestieDataRevision .. "; corrections " .. p.correctionCount .. "; M0 " .. p.m0Checks)
' >"$OUT/verify.log" 2>&1 && ok "$(tail -1 "$OUT/verify.log")" || bad "export verification: $(tail -3 "$OUT/verify.log")"

sha256sum "$FILE" | sed "s|$OUT/||" >"$OUT/SHA256SUMS"
echo "sha256: $(cut -d' ' -f1 "$OUT/SHA256SUMS")"
[ $fails -eq 0 ] && echo "PILOT PASS ($MODE). Files stay in $OUT; publish nothing." || { echo "PILOT FAILED ($fails)"; exit 1; }
