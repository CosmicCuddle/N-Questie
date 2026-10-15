#!/usr/bin/env bash
# Stage A2 real-DB acceptance (spec section 9, F1-F8) for the opt-in v2 export
# mode of cli/validate-335.lua over ALL public compiled 3.3.5a quests.
# Writes only into its own private temporary directories (mktemp -d, 0700),
# never into the checkout; a temporary clone is used for the dirty-checkout
# and private/ cases. Needs a clean checkout. Any changed baseline fails
# (expectations are never adjusted). About 3-4 minutes.
set -u
cd "$(dirname "$0")/.."
LUA="${LUA:-lua5.1}"
fails=0; passes=0
ok()  { passes=$((passes+1)); echo "PASS: $1"; }
bad() { fails=$((fails+1)); echo "FAIL: $1"; }
T="$(mktemp -d)"; chmod 700 "$T"
trap 'chmod -R u+rwx "$T" 2>/dev/null; rm -rf -- "$T"' EXIT
strip() { sed 's/\x1b\[[0-9;]*m//g'; }
E28=NQ_VALIDATE_EXPECT_LEVEL_COUNT=28
ROOT="$(pwd -P)"
CHK="$LUA tests/check_m2_v2_export_file.lua"
PIN_SHA=e7dfb2a99642544b66359b6721887083a3bdab783986d75de32296c783edb6a3

if [ -n "$(git status --porcelain --untracked-files=all)" ]; then echo "STOP: checkout must be clean"; exit 1; fi

# ---------------------------------------------------------------- mode guards (before M0, nothing written)
mkdir -m 700 "$T/g"
refuse() { # name expected-text env...
    local name="$1" want="$2"; shift 2
    env "$@" "$LUA" cli/validate-335.lua >"$T/log" 2>&1; local c=$?
    if [ $c -ne 0 ] && strip <"$T/log" | grep -qF -- "$want" && ! strip <"$T/log" | grep -q "PASS: 232"; then
        ok "refused before M0: $name"; else bad "refused before M0: $name (exit $c)"; strip <"$T/log" | grep -v Updating | tail -3; fi
    [ -z "$(find "$T/g" -mindepth 1 -not -name keep -not -name link -not -name dlink -not -name repolink -not -path "$T/g/sub*" -not -path "$T/g/real*" -print -quit)" ] \
        || bad "file appeared after refusal: $name"
}
OUT="$T/g/v2.lua"
refuse "schema version without path" "NQ_EXPORT_SCHEMA_VERSION given without NQ_EXPORT_V2_OUT" $E28 NQ_EXPORT_SCHEMA_VERSION=2
refuse "path without schema version" "NQ_EXPORT_V2_OUT given without NQ_EXPORT_SCHEMA_VERSION=2" $E28 NQ_EXPORT_V2_OUT="$OUT"
refuse "schema version 1" "NQ_EXPORT_SCHEMA_VERSION must be 2" $E28 NQ_EXPORT_SCHEMA_VERSION=1 NQ_EXPORT_V2_OUT="$OUT"
refuse "schema version 3" "NQ_EXPORT_SCHEMA_VERSION must be 2" $E28 NQ_EXPORT_SCHEMA_VERSION=3 NQ_EXPORT_V2_OUT="$OUT"
refuse "relative path" "must be absolute" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT=v2.lua
refuse "dot-dot path" ". or .. segments" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$T/g/../g/v2.lua"
refuse "non-plain file name" "file name must be plain" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$T/g/a b.lua"
refuse "missing directory" "does not exist" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$T/g/none/v2.lua"
for v in "NQ_EXPORT_EFFECTIVE_OUT=$T/g/e.lua" NQ_EXPORT_QUESTS=1203 "NQ_EXPORT_SELECTION=$T/g/s.lua" NQ_EXPORT_FORCE=1 \
         "NQ_COVERAGE_MANIFEST_OUT=$T/g/m.lua" "NQ_COVERAGE_AGGREGATE_OUT=$T/g/a.txt" NQ_V2_ROUNDTRIP=1 \
         "NQ_V2_VERIFY_IN=$T/g/x.lua" NQ_VALIDATE_FIXTURE=tests/fixtures/validate335/missing_quest.lua; do
    refuse "conflict ${v%%=*}" "not allowed together with" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$OUT" "$v"
done
refuse "skip-compile" "needs the compiled database" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$OUT" NQ_VALIDATE_SKIP_COMPILE=1
refuse "missing level-count assertion" "NQ_VALIDATE_EXPECT_LEVEL_COUNT must be set" NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$OUT"
mkdir -m 755 "$T/open"
refuse "group/other-accessible directory" "chmod 700" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$T/open/v2.lua"
printf keep >"$T/g/keep"; chmod 600 "$T/g/keep"
refuse "existing file" "already exists" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$T/g/keep"
[ "$(cat "$T/g/keep")" = keep ] && ok "existing file untouched" || bad "existing file changed"
mkdir -m 700 "$T/tgt"; printf t >"$T/tgt/file"
ln -s "$T/tgt/file" "$T/g/link"
refuse "final path symlink to a file" "already exists or is a symlink" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$T/g/link"
ln -s "$T/tgt/nowhere" "$T/g/dlink"
refuse "final path dangling symlink" "already exists or is a symlink" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$T/g/dlink"
[ "$(cat "$T/tgt/file")" = t ] && [ ! -e "$T/tgt/nowhere" ] && ok "symlink targets untouched" || bad "symlink target written"
mkdir -m 700 "$T/g/real"; ln -s "$T/g/real" "$T/g/sub"
refuse "symlinked output directory" "contains a symlink" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$T/g/sub/v2.lua"
mkdir -m 700 "$T/g/real/inner"; ln -s "$T/g/real" "$T/g/subp"
refuse "symlinked parent directory" "contains a symlink" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$T/g/subp/inner/v2.lua"
[ -z "$(ls -A "$T/g/real/inner")" ] && ok "nothing written through symlinked directories" || bad "written through symlink"
refuse "directory inside the checkout" "inside the public checkout" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$ROOT/tests/v2.lua"
ln -s "$ROOT/tests" "$T/g/repolink"
refuse "symlink into the checkout" "inside" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$T/g/repolink/v2.lua"
[ ! -e "$ROOT/tests/v2.lua" ] && ok "nothing written into the checkout" || bad "file written into the checkout"
refuse "verify mode with relative path" "must be absolute" $E28 NQ_V2_VERIFY_IN=v2.lua
refuse "verify mode with skip-compile" "needs the compiled database" $E28 NQ_V2_VERIFY_IN="$T/g/keep" NQ_VALIDATE_SKIP_COMPILE=1
refuse "round trip with verify" "not allowed together with NQ_V2_VERIFY_IN" $E28 NQ_V2_ROUNDTRIP=1 NQ_V2_VERIFY_IN="$T/g/keep"

# ---------------------------------------------------------------- full exports (F1-F6)
listing() { find . -path ./.git -prune -o -printf '%P %s %T@ %m\n' | LC_ALL=C sort; git status --porcelain --ignored --untracked-files=all; }
mkdir -m 700 "$T/d1" "$T/d2" "$T/home" "$T/tmp" "$T/cov"
listing >"$T/before"
exp() { env HOME="$T/home" TMPDIR="$T/tmp" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$1/v2.lua" \
    /usr/bin/env time -v "$LUA" cli/validate-335.lua >"$2.out" 2>"$2.err" || return 1; }
if command -v time >/dev/null 2>&1 || [ -x /usr/bin/time ]; then :; fi
exp_plain() { env HOME="$T/home" TMPDIR="$T/tmp" $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$1/v2.lua" "$LUA" cli/validate-335.lua >"$2.out" 2>"$2.err"; }
if [ -x /usr/bin/time ]; then exp "$T/d1" "$T/r1"; c1=$?; else exp_plain "$T/d1" "$T/r1"; c1=$?; fi
sleep 1
exp_plain "$T/d2" "$T/r2"; c2=$?
listing >"$T/after"
[ $c1 -eq 0 ] && [ $c2 -eq 0 ] && ok "two full v2 exports exit 0" || { bad "export exit $c1/$c2"; strip <"$T/r1.err" | grep -v Updating | tail -15; }
cmp -s "$T/before" "$T/after" && ok "checkout unchanged by the exports (listing + git status)" || { bad "checkout changed"; diff "$T/before" "$T/after" | head; }
[ -z "$(find "$T/home" "$T/tmp" -mindepth 1 -print -quit)" ] && ok "HOME and TMPDIR still empty" || bad "files appeared in HOME/TMPDIR"
strip <"$T/r1.err" >"$T/c1"
grep -q "PASS: 232 checks" "$T/c1" && ok "all 232 M0 checks passed before the export" || bad "M0"
grep -q "82431 quest fields compared, 0 mismatches" "$T/c1" && ok "82,431 compiled fields, 0 mismatches" || bad "M0 integrity"
m0=$(grep -n "PASS: 232 checks" "$T/c1" | cut -d: -f1); wr=$(grep -n "v2 export written" "$T/c1" | cut -d: -f1)
[ -n "$m0" ] && [ -n "$wr" ] && [ "$wr" -gt "$m0" ] && ok "export only after M0 passed" || bad "export order"
F1="$T/d1/v2.lua"; F2="$T/d2/v2.lua"
[ "$(ls -A "$T/d1")" = v2.lua ] && [ "$(ls -A "$T/d2")" = v2.lua ] && ok "exactly one file per export, no temp files" || bad "unexpected files in output dirs"
[ "$(stat -c %a "$F1")" = 600 ] && [ "$(stat -c %a "$T/d1")" = 700 ] && [ "$(stat -c %u "$F1")" = "$(id -u)" ] && ok "file 0600 owner-only in a 0700 directory" || bad "permissions"
[ ! -L "$F1" ] && [ -f "$F1" ] && ok "regular file, not a symlink" || bad "file type"
grep -Eq "^quests exported +9159$" "$T/r1.out" && ok "CLI reports 9159 exported" || bad "exported count line"
# F1 quest set
[ "$($CHK ids "$F1" | wc -l)" = 9159 ] && ok "F1: 9159 records in the file" || bad "F1 record count"
[ "$($CHK ids "$F1" | sha256sum | cut -d' ' -f1)" = "$PIN_SHA" ] && ok "F1: ID-list sha256 equals the pin" || bad "F1 ID-set pin"
# F2, F4 baselines read from the file's own records
$CHK counts "$F1" >"$T/counts" || bad "counts helper failed"
want() { grep -qx "$1=$2" "$T/counts" && ok "$3: $1 = $2" || bad "$3: $1 expected $2, got $(grep "^$1=" "$T/counts")"; }
want quests 9159 F1; want questCount 9159 F1; want sorted 1 F1
want supported 8401 F2; want unsupported 758 F2
want reason.EXTRA_CREATURE_REF 359 F2; want reason.EXTRA_OBJECT_REF 243 F2; want reason.REPUTATION_OBJECTIVE 181 F2
want reason.KILLCREDIT_FIRST_REORDER 16 F2; want reason.DUPLICATE_CREATURE 7 F2; want reason.DUPLICATE_OBJECT 1 F2
[ "$(grep -c '^reason\.' "$T/counts")" = 6 ] && ok "F2: exactly 6 reason codes" || bad "F2 reason code set"
want refs 801 F4; want monster 466 F4; want object 335 F4; want item 0 F4
want reputation 181 F4; want reputationZero 22 F4; want killCreditFirst 16 F4; want duplicates 10 F4
want extraEntries 730 F4; want spawnOnly 78 F4; want idx0 696 F4; want idxPast 5 F4
# F2 against the coverage manifest of the same commit
env $E28 NQ_COVERAGE_MANIFEST_OUT="$T/cov/manifest.lua" "$LUA" cli/validate-335.lua >"$T/cov.out" 2>&1 || bad "coverage run failed"
$CHK coverage "$F1" "$T/cov/manifest.lua" >"$T/covcmp"
grep -qx "compared=9159" "$T/covcmp" && grep -qx "differing=0" "$T/covcmp" && grep -qx "manifestOnly=0" "$T/covcmp" \
    && ok "F2: per-quest status and reasons equal the coverage manifest (9159, 0 differing)" || { bad "F2 coverage comparison"; cat "$T/covcmp"; }
# F3, F4, F5 on the written file: re-read, rebuild, compare with the compiled data
env HOME="$T/home" TMPDIR="$T/tmp" $E28 NQ_V2_VERIFY_IN="$F1" "$LUA" cli/validate-335.lua >"$T/v.out" 2>"$T/v.err"; cv=$?
[ $cv -eq 0 ] && strip <"$T/v.err" | grep -q "v2 verify PASS" && ok "verify mode on the written file passes" || { bad "verify exit $cv"; strip <"$T/v.err" | tail -5; }
vwant() { grep -Eq "^$1 +$2\$" "$T/v.out" && ok "$3: $1 = $2" || bad "$3: $1 expected $2, got '$(grep -E "^$1 " "$T/v.out" | sed -E 's/ +/ /g')'"; }
vwant "quests processed" 9159 F3; vwant "quests in file" 9159 F3
vwant "round trip: quests compared" 9159 F3; vwant "round trip: quests differing" 0 F3; vwant "round trip: differences" 0 F3
vwant "positions checked \(quests\)" 9159 F3; vwant "record validation errors" 0 F3; vwant "build errors" 0 F3
vwant "m1 status disagreeing with v2 ExpectedM1" 0 F2
vwant "unsupported no-loss refs" 801 F4; vwant "unsupported no-loss monster" 466 F4; vwant "unsupported no-loss object" 335 F4
vwant "unsupported no-loss reputation" 181 F4; vwant "unsupported no-loss reputationZero" 22 F4
vwant "unsupported no-loss killCreditFirst" 16 F4; vwant "unsupported no-loss duplicates" 10 F4
vwant "v1 equivalence: quests compared" 8401 F5; vwant "v1 equivalence: quests differing" 0 F5
vwant "file provenance matches this checkout" yes F3; vwant "file harnessVersion" "1\.3\.0" F7
vwant "write/process attempts blocked" 0 F3
[ -z "$(find "$T/home" "$T/tmp" -mindepth 1 -print -quit)" ] && cmp -s "$T/before" <(listing) && ok "verify mode wrote nothing" || bad "verify wrote something"
# Verify mode detects a tampered file (one creature id changed)
mkdir -m 700 "$T/tam"; $CHK tamper "$F1" "$T/tam/v2.lua"; chmod 600 "$T/tam/v2.lua"
env $E28 NQ_V2_VERIFY_IN="$T/tam/v2.lua" "$LUA" cli/validate-335.lua >"$T/tv.out" 2>"$T/tv.err"; ct=$?
[ $ct -ne 0 ] && strip <"$T/tv.err" | grep -q "V2 VERIFY FAILED" && strip <"$T/tv.err" | grep -q "differ" \
    && ok "verify mode fails closed on a tampered file" || bad "tampered file not detected (exit $ct)"
# F6 determinism
$CHK canon "$F1" "$F2" >"$T/canon"
grep -qx "canonicalEqualExcludingExportedAt=true" "$T/canon" && ok "F6: two exports equal after Canonical(doc, {exportedAt})" || bad "F6 canonical"
pd=$(sed -n 's/^provenanceDiffering=//p' "$T/canon")
{ [ "$pd" = "exportedAt" ] || [ "$pd" = "" ]; } && ok "F6: only provenance.exportedAt may differ (differing: '${pd}')" || bad "F6 provenance differs in: $pd"
[ "$(sed -E 's/exportedAt="[^"]*"//' "$F1" | sha256sum)" = "$(sed -E 's/exportedAt="[^"]*"//' "$F2" | sha256sum)" ] \
    && ok "F6: files byte-identical apart from the exportedAt value" || bad "F6 bytes differ beyond exportedAt"
grep -Eq 'exportedAt="[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z"' "$F1" && ok "F6: real UTC timestamp kept in production provenance" || bad "timestamp"
grep -Eq 'sourceDirty=false' "$F1" && grep -Eq "sourceCommit=\"$(git rev-parse HEAD)\"" "$F1" && ok "provenance: clean tree, this commit" || bad "provenance commit/dirty"
# F8 unwritable destination (passes the pre-M0 checks, fails at write): no file
mkdir -m 500 "$T/ro"
env $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$T/ro/v2.lua" "$LUA" cli/validate-335.lua >"$T/ro.out" 2>"$T/ro.err"; cr=$?
chmod 700 "$T/ro"
[ $cr -ne 0 ] && strip <"$T/ro.err" | grep -q "V2 EXPORT FAILED" && [ -z "$(ls -A "$T/ro")" ] && ok "F8: unwritable directory -> export fails, no file" || bad "F8 unwritable (exit $cr)"
# F7 default run unchanged (golden from the Stage A1 head, timings normalised)
env -u NQ_EXPORT_SCHEMA_VERSION -u NQ_EXPORT_V2_OUT $E28 "$LUA" cli/validate-335.lua >"$T/def.out" 2>"$T/def.err"; cd_=$?
norm() { sed -E 's/ in [0-9]+\.[0-9]+s$/ in N.Ns/'; }
{ echo "== stdout"; norm <"$T/def.out"; echo "== stderr"; norm <"$T/def.err"; } >"$T/def.txt"
[ $cd_ -eq 0 ] && cmp -s "$T/def.txt" tests/fixtures/m2_v2_export/default_cli_golden.txt && ok "F7: default CLI output byte-identical to the golden (timings normalised)" \
    || { bad "F7: default CLI output changed (exit $cd_)"; diff "$T/def.txt" tests/fixtures/m2_v2_export/default_cli_golden.txt | head; }

# ---------------------------------------------------------------- dirty checkout and private/ (temporary clone)
git clone -q --no-hardlinks "$ROOT" "$T/clone" 2>/dev/null && (cd "$T/clone" && git checkout -q "$(cd "$ROOT" && git rev-parse HEAD)") || bad "temporary clone"
mkdir -m 700 "$T/d3"
printf x >"$T/clone/untracked.txt"
(cd "$T/clone" && env $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$T/d3/v2.lua" "$LUA" cli/validate-335.lua >"$T/dirty.out" 2>"$T/dirty.err"); cdirty=$?
[ $cdirty -ne 0 ] && strip <"$T/dirty.err" | grep -q "checkout is not clean" && [ -z "$(ls -A "$T/d3")" ] \
    && ok "dirty checkout: export refused after M0, no file" || bad "dirty checkout handling (exit $cdirty)"
rm -f "$T/clone/untracked.txt"
mkdir -m 700 "$T/clone/private"
(cd "$T/clone" && env $E28 NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT="$T/clone/private/v2.lua" "$LUA" cli/validate-335.lua >"$T/priv.out" 2>"$T/priv.err"); cp=$?
[ $cp -ne 0 ] && strip <"$T/priv.err" | grep -q "inside the git checkout (private/ included)" && [ -z "$(ls -A "$T/clone/private")" ] \
    && ok "private/ inside the checkout refused before M0, no file" || bad "private/ destination (exit $cp)"

# ---------------------------------------------------------------- verify mode needs a clean verifying checkout
# The clone is at the same commit as $F1, so a clean clone verifies; any dirt or
# an unreadable git status refuses before compile, and nothing is written.
rmdir "$T/clone/private"
snap() { (cd "$T/clone" && find . -path ./.git -prune -o -printf '%P %s %T@ %m\n' | LC_ALL=C sort)
         find "$T/home" "$T/tmp" "$(dirname "$F1")" -printf '%p %s %T@ %m\n' | LC_ALL=C sort; }
vclone() { (cd "$T/clone" && env HOME="$T/home" TMPDIR="$T/tmp" $E28 NQ_V2_VERIFY_IN="$F1" "$LUA" cli/validate-335.lua >"$T/vc.out" 2>"$T/vc.err"); }
vrefuse() { # name expected-text
    snap >"$T/vs.before"; vclone; local c=$?
    snap >"$T/vs.after"
    if [ $c -ne 0 ] && strip <"$T/vc.out" "$T/vc.err" | grep -qF "$2" && ! strip <"$T/vc.out" "$T/vc.err" | grep -q "v2 verify PASS" \
        && ! grep -q "N-QUESTIE V2 VERIFY" "$T/vc.out" && cmp -s "$T/vs.before" "$T/vs.after"; then
        ok "verify refused, nothing written: $1"
    else bad "verify with $1 (exit $c)"; strip <"$T/vc.out" | tail -3; diff "$T/vs.before" "$T/vs.after" | head -5; fi
}
printf x >"$T/clone/untracked-verify.txt"; vrefuse "untracked file in the verifying checkout" "checkout is not clean"; rm -f "$T/clone/untracked-verify.txt"
printf '\n' >>"$T/clone/README.md"; vrefuse "modified tracked file" "checkout is not clean"
(cd "$T/clone" && git add README.md); vrefuse "staged change" "checkout is not clean"; (cd "$T/clone" && git reset -q --hard)
cp "$T/clone/.git/index" "$T/clone/.git/index.keep"; printf garbage >"$T/clone/.git/index"
vrefuse "git status failure (corrupt index)" "cannot read git status"; mv "$T/clone/.git/index.keep" "$T/clone/.git/index"
snap >"$T/vs.before"; vclone; cvc=$?; snap >"$T/vs.after"
[ $cvc -eq 0 ] && strip <"$T/vc.out" | grep -q "v2 verify PASS" && grep -Eq "^file provenance matches this checkout +yes$" "$T/vc.out" \
    && cmp -s "$T/vs.before" "$T/vs.after" && grep -Eq "^write/process attempts blocked +0$" "$T/vc.out" \
    && ok "verify in a truly clean checkout passes, nothing written" || { bad "clean clone verify (exit $cvc)"; strip <"$T/vc.out" | tail -5; }

# ---------------------------------------------------------------- performance (informational)
if grep -q "Maximum resident" "$T/r1.err"; then
    echo "info: wall $(grep 'Elapsed' "$T/r1.err" | sed 's/.*): //'), peak RSS $(grep 'Maximum resident' "$T/r1.err" | sed 's/.*: //') KiB, output $(stat -c %s "$F1") bytes"
fi
grep -E "^(cpu seconds|lua heap|output bytes)" "$T/r1.out" | sed 's/^/info: /'
echo "v2 export integration: $passes passed, $fails failed"
[ $fails -eq 0 ]
