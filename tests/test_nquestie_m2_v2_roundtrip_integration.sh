#!/usr/bin/env bash
# Stage A1 real-DB integration: cli/validate-335.lua with NQ_V2_ROUNDTRIP=1
# over ALL public compiled 3.3.5a quests. Read-only: the test proves that no
# file is created or changed (checkout listing and git status before/after,
# empty HOME and TMPDIR) and that the in-process guard blocked nothing.
# Asserts the measured baseline; any difference fails (never adjusted).
# ~1-2 minutes. Writes only to its own temporary directory.
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
refuse "value other than 1" "NQ_V2_ROUNDTRIP must be 1" $E28 NQ_V2_ROUNDTRIP=yes
refuse "with v1 export" "not allowed together with NQ_EXPORT_EFFECTIVE_OUT" $E28 NQ_V2_ROUNDTRIP=1 NQ_EXPORT_EFFECTIVE_OUT="$T/e.lua" NQ_EXPORT_QUESTS=1203
refuse "with selection" "not allowed together with NQ_EXPORT_QUESTS" $E28 NQ_V2_ROUNDTRIP=1 NQ_EXPORT_QUESTS=1203
refuse "with force" "not allowed together with NQ_EXPORT_FORCE" $E28 NQ_V2_ROUNDTRIP=1 NQ_EXPORT_FORCE=1
refuse "with coverage" "not allowed together with NQ_COVERAGE_MANIFEST_OUT" $E28 NQ_V2_ROUNDTRIP=1 NQ_COVERAGE_MANIFEST_OUT="$T/m.lua"
refuse "with v2 export variables" "not allowed together with NQ_EXPORT_V2_OUT" $E28 NQ_V2_ROUNDTRIP=1 NQ_EXPORT_V2_OUT="$T/v2.lua"
refuse "with schema version" "not allowed together with NQ_EXPORT_SCHEMA_VERSION" $E28 NQ_V2_ROUNDTRIP=1 NQ_EXPORT_SCHEMA_VERSION=2
refuse "with fixture" "not allowed together with NQ_VALIDATE_FIXTURE" $E28 NQ_V2_ROUNDTRIP=1 NQ_VALIDATE_FIXTURE=tests/fixtures/validate335/missing_quest.lua
refuse "skip-compile" "needs the compiled database" $E28 NQ_V2_ROUNDTRIP=1 NQ_VALIDATE_SKIP_COMPILE=1
refuse "missing level-count assertion" "NQ_VALIDATE_EXPECT_LEVEL_COUNT must be set" NQ_V2_ROUNDTRIP=1
[ -z "$(ls -A "$T" | grep -v '^log$')" ] && ok "nothing written on refusal" || bad "file written on refusal"

listing() { find . -path ./.git -prune -o -printf '%P %s %T@ %m\n' | LC_ALL=C sort; git status --porcelain --ignored --untracked-files=all; }
mkdir -m 700 "$T/home" "$T/tmp"
listing >"$T/before"
run_rt() {
    env -u NQ_EXPORT_EFFECTIVE_OUT HOME="$T/home" TMPDIR="$T/tmp" $E28 NQ_V2_ROUNDTRIP=1 "$LUA" cli/validate-335.lua >"$T/$1.out" 2>"$T/$1.err"
}
run_rt r1; c1=$?
run_rt r2; c2=$?
listing >"$T/after"
cmp -s "$T/before" "$T/after" && ok "checkout unchanged: no file created, changed or removed (listing + git status)" || { bad "checkout changed"; diff "$T/before" "$T/after" | head; }
[ -z "$(find "$T/home" "$T/tmp" -mindepth 1 -print -quit)" ] && ok "HOME and TMPDIR still empty" || bad "files appeared in HOME/TMPDIR"
[ $c1 -eq 0 ] && [ $c2 -eq 0 ] && ok "round trip runs exit 0" || { bad "round trip exit $c1/$c2"; strip <"$T/r1.err" | tail -20; cat "$T/r1.out"; }
strip <"$T/r1.err" >"$T/clean"
grep -q "PASS: 232 checks" "$T/clean" && ok "all 232 M0 checks passed first" || bad "M0 checks"
grep -q "82431 quest fields compared, 0 mismatches" "$T/clean" && ok "82,431 compiled fields, 0 mismatches" || bad "M0 integrity"
grep -q "v2 round trip PASS (read-only, nothing written)" "$T/clean" && ok "mode reports PASS after M0" || bad "mode PASS line"
O="$T/r1.out"
want() { # label value
    if grep -Eq "^$1 +$2\$" "$O"; then ok "$1 = $2"; else bad "$1: expected $2, got '$(grep -E "^$1 " "$O" | sed -E 's/ +/ /g')'"; fi
}
want "quests processed" 9159
want "compiled quest IDs" 9159
want "records built" 9159
want "build errors" 0
want "record validation errors" 0
want "unclassified" 0
want "m1 SUPPORTED \(v1 representable\)" 8401
want "m1 UNSUPPORTED_BY_RULES \(v1 unsupported\)" 758
want "m1 status disagreeing with v2 ExpectedM1" 0
want "round trip: quests compared" 9159
want "round trip: quests differing" 0
want "round trip: differences" 0
want "positions checked \(quests\)" 9159
want "v1 equivalence: quests compared" 8401
want "v1 equivalence: quests differing" 0
want "extra refs \(occurrences\)" 801
want "  extra refs monster" 466
want "  extra refs object" 335
want "  extra refs item" 0
want "extra objective entries" 730
want "quests with extra objectives" 632
want "spawn-only extra entries" 78
want "extra objectiveIndex 0" 696
want "extra objectiveIndex past DB objectives" 5
want "reputation pairs" 181
want "reputation pairs with value 0" 22
want "killCreditFirst quests" 16
want "duplicate objective occurrences" 10
want "  duplicate creature" 9
want "  duplicate object" 1
want "  reason EXTRA_CREATURE_REF \(quests\)" 359
want "  reason EXTRA_OBJECT_REF \(quests\)" 243
want "  reason REPUTATION_OBJECTIVE \(quests\)" 181
want "  reason KILLCREDIT_FIRST_REORDER \(quests\)" 16
want "  reason DUPLICATE_CREATURE \(quests\)" 7
want "  reason DUPLICATE_OBJECT \(quests\)" 1
want "unsupported no-loss refs" 801
want "unsupported no-loss monster" 466
want "unsupported no-loss object" 335
want "unsupported no-loss reputation" 181
want "unsupported no-loss reputationZero" 22
want "unsupported no-loss killCreditFirst" 16
want "unsupported no-loss duplicates" 10
want "source data unchanged \(fingerprint\)" yes
want "repeat run aggregate identical" yes
want "write/process attempts blocked" 0
n_reason=$(grep -c "^  reason " "$O")
[ "$n_reason" -eq 6 ] && ok "exactly 6 reason codes occur" || bad "reason codes: $n_reason"
grep -q "build error:" "$O" && bad "build error kinds listed" || ok "no build error kinds"
grep -Eq "[0-9]{4,} *:|quest [0-9]" "$O" && bad "output contains quest IDs" || ok "output is aggregate only (no quest IDs)"
# Determinism across processes (timing lines excluded)
grep -vE "^(cpu seconds|lua heap)" "$T/r1.out" >"$T/a1"; grep -vE "^(cpu seconds|lua heap)" "$T/r2.out" >"$T/a2"
cmp -s "$T/a1" "$T/a2" && ok "two separate processes give identical aggregates" || bad "aggregates differ between processes"
# Default run unchanged: no round trip, M0 still passes
env -u NQ_V2_ROUNDTRIP $E28 "$LUA" cli/validate-335.lua >"$T/d.out" 2>"$T/d.err"; cd_=$?
[ $cd_ -eq 0 ] && strip <"$T/d.err" | grep -q "PASS: 232 checks" && ! grep -qiE "v2 round trip|V2 ROUND TRIP" "$T/d.out" "$T/d.err" \
    && ok "default run unchanged: M0 232, no round-trip output" || bad "default run changed (exit $cd_)"
echo "v2 round-trip integration: $passes passed, $fails failed"
[ $fails -eq 0 ]
