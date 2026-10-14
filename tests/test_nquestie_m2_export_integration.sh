#!/usr/bin/env bash
# M2.2 Steps 3+5 integration tests: real cli/validate-335.lua runs on the
# public 3.3.5a database, exporting to temporary directories only.
# Needs a CLEAN git checkout (the export refuses dirty trees). ~2-4 minutes.
set -u
cd "$(dirname "$0")/.."
LUA="${LUA:-lua5.1}"
fails=0; passes=0
ok()   { passes=$((passes+1)); echo "PASS: $1"; }
bad()  { fails=$((fails+1)); echo "FAIL: $1"; }
T="$(mktemp -d)"; chmod 700 "$T"
cleanup() { rm -rf -- "$T"; [ -n "${CLONE:-}" ] && rm -rf -- "$CLONE"; }
trap cleanup EXIT
strip() { sed 's/\x1b\[[0-9;]*m//g'; }
run() { "$@" 2>&1 | strip; return "${PIPESTATUS[0]}"; }

IDS="1203,2001,2784,30,25,28,498,532,553,786"

# 1. No export option: unchanged behaviour, nothing written
out=$(NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 run "$LUA" cli/validate-335.lua); code=$?
if [ $code -eq 0 ] && echo "$out" | grep -q "PASS: 232 checks" && ! echo "$out" | grep -q "export"; then
    ok "no export option: 232 checks, no export"; else bad "baseline run changed (code $code)"; fi
[ -z "$(ls -A "$T")" ] && ok "baseline wrote nothing" || bad "baseline wrote files"

# 2. Real export of representative quests
out=$(NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 NQ_EXPORT_EFFECTIVE_OUT="$T/eff.lua" NQ_EXPORT_QUESTS="$IDS" run "$LUA" cli/validate-335.lua); code=$?
if [ $code -eq 0 ] && echo "$out" | grep -q "PASS: 232 checks" && echo "$out" | grep -q "effective export written: 10"; then
    ok "export after 232 checks"; else bad "export run failed (code $code): $(echo "$out" | tail -3)"; fi
[ "$(stat -c %a "$T/eff.lua" 2>/dev/null)" = "600" ] && ok "export mode 0600" || bad "export mode"
if "$LUA" tests/check_m2_export_values.lua "$T/eff.lua"; then ok "exported values match the compiled DB facts"; else bad "exported values"; fi
cp "$T/eff.lua" "$T/eff.copy"

# 3. Existing file: refused without force, intact; replaced with force
out=$(NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 NQ_EXPORT_EFFECTIVE_OUT="$T/eff.lua" NQ_EXPORT_QUESTS="1203" run "$LUA" cli/validate-335.lua); code=$?
if [ $code -ne 0 ] && echo "$out" | grep -q "exists" && cmp -s "$T/eff.lua" "$T/eff.copy"; then
    ok "existing export refused and left intact"; else bad "existing file handling (code $code)"; fi
out=$(NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 NQ_EXPORT_FORCE=1 NQ_EXPORT_EFFECTIVE_OUT="$T/eff.lua" NQ_EXPORT_QUESTS="1203" run "$LUA" cli/validate-335.lua); code=$?
if [ $code -eq 0 ] && grep -q "questCount = 1," "$T/eff.lua"; then ok "NQ_EXPORT_FORCE=1 replaces the export"; else bad "force replace (code $code)"; fi

# 4. Selection from a validated nq-m2-input file
"$LUA" -e '
local X = dofile("tools/validation/EffectiveExport.lua")
local I = dofile("tools/validation/InputSchema.lua")
local d = assert(I.ParseString(io.open("tests/fixtures/m2_input/valid_selected_quests.lua"):read("*a")))
d.quests = { d.quests[1] }; d.provenance.questCount = 1
local f = io.open(arg[1], "w"); f:write(X.Serialize(d)); f:close()' "$T/sel.lua"
out=$(NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 NQ_EXPORT_EFFECTIVE_OUT="$T/fromsel.lua" NQ_EXPORT_SELECTION="$T/sel.lua" run "$LUA" cli/validate-335.lua); code=$?
if [ $code -eq 0 ] && grep -q "ID = 1203," "$T/fromsel.lua"; then ok "selection from an nq-m2-input file"; else bad "selection file (code $code)"; fi

# 5. Refusals before M0 (fast) and after M0
expect_refuse() { # name needle env...
    local name="$1" needle="$2"; shift 2
    local o c; o=$(env "$@" "$LUA" cli/validate-335.lua 2>&1 | strip); c=${PIPESTATUS[0]}
    if [ "$c" -ne 0 ] && echo "$o" | grep -qF "$needle"; then ok "$name"; else bad "$name (code $c): $(echo "$o" | tail -2)"; fi
}
E28=NQ_VALIDATE_EXPECT_LEVEL_COUNT=28
expect_refuse "duplicate selection" "duplicate quest ID 1203" $E28 NQ_EXPORT_EFFECTIVE_OUT="$T/x.lua" NQ_EXPORT_QUESTS="1203,1203"
expect_refuse "non-numeric selection" "not a quest ID" $E28 NQ_EXPORT_EFFECTIVE_OUT="$T/x.lua" NQ_EXPORT_QUESTS="1203,abc"
expect_refuse "empty selection" "exactly one of" $E28 NQ_EXPORT_EFFECTIVE_OUT="$T/x.lua"
expect_refuse "both selection kinds" "exactly one of" $E28 NQ_EXPORT_EFFECTIVE_OUT="$T/x.lua" NQ_EXPORT_QUESTS=1203 NQ_EXPORT_SELECTION="$T/sel.lua"
expect_refuse "selection without output" "without NQ_EXPORT_EFFECTIVE_OUT" $E28 NQ_EXPORT_QUESTS=1203
expect_refuse "missing level-count assertion" "NQ_VALIDATE_EXPECT_LEVEL_COUNT must be set" NQ_EXPORT_EFFECTIVE_OUT="$T/x.lua" NQ_EXPORT_QUESTS=1203
expect_refuse "export with fault fixture" "not allowed together with NQ_VALIDATE_FIXTURE" $E28 NQ_EXPORT_EFFECTIVE_OUT="$T/x.lua" NQ_EXPORT_QUESTS=1203 NQ_VALIDATE_FIXTURE=tests/fixtures/validate335/missing_quest.lua
expect_refuse "export with skip-compile" "needs the compiled database" $E28 NQ_EXPORT_EFFECTIVE_OUT="$T/x.lua" NQ_EXPORT_QUESTS=1203 NQ_VALIDATE_SKIP_COMPILE=1
expect_refuse "output inside the checkout" "inside the public checkout" $E28 NQ_EXPORT_EFFECTIVE_OUT="$PWD/docs/x.lua" NQ_EXPORT_QUESTS=1203
expect_refuse "output directory missing" "does not exist" $E28 NQ_EXPORT_EFFECTIVE_OUT="$T/nope/x.lua" NQ_EXPORT_QUESTS=1203
mkdir -m 755 "$T/open"
expect_refuse "output directory not 0700" "chmod 700" $E28 NQ_EXPORT_EFFECTIVE_OUT="$T/open/x.lua" NQ_EXPORT_QUESTS=1203
expect_refuse "invalid selection file" "selection file" $E28 NQ_EXPORT_EFFECTIVE_OUT="$T/x.lua" NQ_EXPORT_SELECTION="$PWD/cli/validate-335.lua"
expect_refuse "quest not in the DB" "not in the compiled Questie database" $E28 NQ_EXPORT_EFFECTIVE_OUT="$T/x.lua" NQ_EXPORT_QUESTS="1203,999999"
expect_refuse "v1-unrepresentable quest (reputation)" "reputation" $E28 NQ_EXPORT_EFFECTIVE_OUT="$T/x.lua" NQ_EXPORT_QUESTS="1203,1036"
expect_refuse "failed M0 (wrong level count) writes nothing" "FAILED" NQ_VALIDATE_EXPECT_LEVEL_COUNT=27 NQ_EXPORT_EFFECTIVE_OUT="$T/x.lua" NQ_EXPORT_QUESTS=1203
[ ! -e "$T/x.lua" ] && ok "no output file after any refusal" || bad "output written despite refusal"

# 6. Dirty checkout (temporary local clone, so the real checkout is untouched)
CLONE="$(mktemp -d)"
git clone -q . "$CLONE/c" && echo "untracked" > "$CLONE/c/UNTRACKED.txt"
o=$(cd "$CLONE/c" && NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 NQ_EXPORT_EFFECTIVE_OUT="$T/dirty.lua" NQ_EXPORT_QUESTS=1203 "$LUA" cli/validate-335.lua 2>&1 | strip); c=${PIPESTATUS[0]}
if [ "$c" -ne 0 ] && echo "$o" | grep -q "not clean" && [ ! -e "$T/dirty.lua" ]; then ok "dirty checkout refused, nothing written"; else bad "dirty checkout (code $c)"; fi

echo "== $passes passed, $fails failed"
[ $fails -eq 0 ] && echo "PASS: M2.2 export integration ($passes checks)" || exit 1
