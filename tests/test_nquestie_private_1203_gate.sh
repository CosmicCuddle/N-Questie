#!/usr/bin/env bash
# Public synthetic tests only. No real acore_world input is ever loaded in CI.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d)
chmod 700 "$T"
trap 'rm -rf -- "$T"' EXIT
SRC=tests/fixtures/m2_input/quest1203_single_synthetic.lua
passes=0; fails=0
ok() { passes=$((passes+1)); echo "PASS: $1"; }
bad() { fails=$((fails+1)); echo "FAIL: $1"; }
[ -f "$SRC" ] && command -v lua5.1 >/dev/null && command -v sha256sum >/dev/null \
    && command -v sed >/dev/null || { echo "FAIL: prerequisites"; exit 1; }
cp -- "$SRC" "$T/valid.lua"
chmod 600 "$T/valid.lua"
run() { lua5.1 cli/check-private-1203.lua "$1" 2>&1; }
reject() {
    local label="$1" file="$2" expect="$3" output code
    output=$(run "$file"); code=$?
    if [ "$code" -ne 0 ] && [[ "$output" == *"$expect"* ]] && [[ "$output" != *"$T"* ]]; then
        ok "$label"
    else
        bad "$label (exit $code; output: $output)"
    fi
}
output=$(run "$T/valid.lua"); code=$?
if [ "$code" -eq 0 ] && [[ "$output" == *"PASS: quest 1203 M2.1 schema"* ]] \
    && [[ "$output" == *"NOT VERIFIED: private archive fingerprint"* ]] \
    && [[ "$output" != *"$T"* ]] && [[ "$output" != *"sha256:"* ]]; then
    ok "synthetic single 1203 accepted, output contains no provenance or path"
else
    bad "valid synthetic input (exit $code; output: $output)"
fi
# Explicitly keep source flags as unknown: a PASS is never an IP/conditions proof.
if [[ "$output" == *"NOT VERIFIED"* ]]; then ok "unknown server evidence stays unverified"; else bad "unknown evidence omitted"; fi

cp "$T/valid.lua" "$T/id.lua"
sed -i 's/ID = 1203,/ID = 1204,/' "$T/id.lua"
reject "reject wrong quest selection" "$T/id.lua" "not exactly quest 1203"

cp "$T/valid.lua" "$T/item.lua"
sed -i 's/RequiredItemId1 = 3853/RequiredItemId1 = 33110/' "$T/item.lua"
reject "reject stock item's incorrect ID" "$T/item.lua" "additional/different item objective"

cp "$T/valid.lua" "$T/count.lua"
sed -i 's/RequiredItemCount1 = 1/RequiredItemCount1 = 2/' "$T/count.lua"
reject "reject wrong item count" "$T/count.lua" "additional/different item objective"

cp "$T/valid.lua" "$T/extra.lua"
sed -i 's/RequiredItemId2 = 0, RequiredItemCount2 = 0/RequiredItemId2 = 3853, RequiredItemCount2 = 1/' "$T/extra.lua"
reject "reject duplicate/extra item slot" "$T/extra.lua" "does not have exactly one required item 3853 x1"

cp "$T/valid.lua" "$T/creature.lua"
sed -i 's/RequiredNpcOrGo1 = 0, RequiredNpcOrGoCount1 = 0/RequiredNpcOrGo1 = 199, RequiredNpcOrGoCount1 = 1/' "$T/creature.lua"
reject "reject unexpected creature objective" "$T/creature.lua" "unexpected creature/object objective"

cp "$T/valid.lua" "$T/provenance.lua"
sed -i 's/questCount = 1,/questCount = 2,/' "$T/provenance.lua"
reject "reject inconsistent document provenance count" "$T/provenance.lua" "input rejected"

cp "$T/valid.lua" "$T/flag.lua"
sed -i 's/ipGated = "unknown",/ipGated = "definitely-not",/' "$T/flag.lua"
reject "reject malformed tri-state IP evidence" "$T/flag.lua" "input rejected"

cp "$T/valid.lua" "$T/exec.lua"
printf '\nos.execute("touch %s/should-not-exist")\n' "$T" >> "$T/exec.lua"
reject "reject executable Lua in private input" "$T/exec.lua" "input rejected"
[ ! -e "$T/should-not-exist" ] && ok "untrusted Lua not executed" || bad "untrusted Lua was executed"

# The real-data helper is stricter than the public synthetic schema parser:
# readable-by-other-user inputs must never get a private-data PASS.
chmod 644 "$T/valid.lua"
reject "reject world-readable private input file" "$T/valid.lua" "private input permissions refused"
chmod 600 "$T/valid.lua"
mkdir -m 755 "$T/world-readable"
cp -- "$T/valid.lua" "$T/world-readable/valid.lua"
reject "reject world-readable private input directory" "$T/world-readable/valid.lua" "private input permissions refused"
chmod 700 "$T/world-readable"

reject "reject relative input path" "tests/fixtures/m2_input/quest1203_single_synthetic.lua" "input rejected"
reject "reject public checkout input path" "$(pwd -P)/tests/fixtures/m2_input/quest1203_single_synthetic.lua" "must resolve outside the public checkout"
ln -s "$(pwd -P)/tests/fixtures/m2_input/quest1203_single_synthetic.lua" "$T/public-symlink.lua"
reject "reject symlink to a public synthetic fixture" "$T/public-symlink.lua" "must resolve outside the public checkout"
reject "reject nonexistent input path" "$T/does-not-exist.lua" "input rejected"

# A private symlink pointing to a protected canonical target is permitted,
# but only if the actual target is the one validated and subsequently read.
ln -s "$T/valid.lua" "$T/valid-alias.lua"
out=$(run "$T/valid-alias.lua"); code=$?
[ "$code" -eq 0 ] && [[ "$out" == *"PASS: quest 1203 M2.1 schema"* ]] \
    && [[ "$out" != *"$T"* ]] && ok "accept stable symlink to protected private target" \
    || bad "stable protected symlink was refused"

# Deterministic synthetic symlink-switch check:
# first realpath returns a protected invalid private target, but the symlink
# is redirected to a public valid fixture before Input.LoadFile. Resolving
# the original symlink twice would incorrectly PASS. The canonical target
# verified for owner/mode must remain the source that we read.
cp "$T/valid.lua" "$T/private-invalid.lua"
sed -i 's/ID = 1203,/ID = 1204,/' "$T/private-invalid.lua"
ln -s "$T/private-invalid.lua" "$T/race-alias.lua"
mkdir -m 700 "$T/fake-realpath-bin"
cat > "$T/fake-realpath-bin/realpath" <<'RACE_REALPATH'
#!/bin/sh
target=$("$NQ_RACE_REALPATH_BIN" "$@") || exit 1
if [ "$3" = "$NQ_RACE_LINK" ] && [ ! -e "$NQ_RACE_MARK" ]; then
    ln -sfn "$NQ_RACE_PUBLIC" "$NQ_RACE_LINK" || exit 1
    : > "$NQ_RACE_MARK"
fi
printf '%s\n' "$target"
RACE_REALPATH
chmod 700 "$T/fake-realpath-bin/realpath"
RACE_REALPATH_BIN=$(command -v realpath)
out=$(NQ_RACE_REALPATH_BIN="$RACE_REALPATH_BIN" \
    NQ_RACE_LINK="$T/race-alias.lua" \
    NQ_RACE_PUBLIC="$(pwd -P)/tests/fixtures/m2_input/quest1203_single_synthetic.lua" \
    NQ_RACE_MARK="$T/race-was-triggered" \
    PATH="$T/fake-realpath-bin:$PATH" \
    lua5.1 cli/check-private-1203.lua "$T/race-alias.lua" 2>&1); code=$?
if [ "$code" -ne 0 ] && [[ "$out" == *"not exactly quest 1203"* ]] \
    && [[ "$out" != *"PASS:"* ]] && [[ "$out" != *"$T"* ]] \
    && [ -e "$T/race-was-triggered" ] \
    && [ "$(realpath -e -- "$T/race-alias.lua")" = "$(pwd -P)/tests/fixtures/m2_input/quest1203_single_synthetic.lua" ]; then
    ok "symlink retarget after vetting cannot substitute a public valid quest file"
else
    bad "symlink retarget was not safely rejected (exit $code; output: $out)"
fi

out=$(NQ_M2_INPUT="$T/valid.lua" lua5.1 cli/check-private-1203.lua 2>&1); code=$?
[ "$code" -eq 0 ] && [[ "$out" == *"PASS: quest 1203"* ]] && ok "optional environment input works" || bad "optional env input"

[ -f "$T/valid.lua" ] && [ "$(stat -c %a "$T/valid.lua")" = 600 ] && ok "source fixture left intact and private" || bad "fixture altered"

# SYNTHETIC archive byte-level provenance test: no private archive, no
# real ZIP/SQL records. Only the output of sha256sum is used by the verifier.
printf 'SYNTHETIC-ARCHIVE-BYTES-ONLY\n' > "$T/source-archive.zip"
chmod 600 "$T/source-archive.zip"
digest=$(sha256sum < "$T/source-archive.zip" | cut -d' ' -f1)
cp "$T/valid.lua" "$T/with-archive.lua"
sed -i "s/sha256:0000000000000000000000000000000000000000000000000000000000000000/sha256:$digest/" "$T/with-archive.lua"
archiveOut=$(lua5.1 cli/check-private-1203.lua "$T/with-archive.lua" --archive "$T/source-archive.zip" 2>&1); archiveCode=$?
if [ "$archiveCode" -eq 0 ] && [[ "$archiveOut" == *"PASS: supplied offline archive SHA-256 matches"* ]] \
    && [[ "$archiveOut" == *"NOT VERIFIED: whether exporter read that archive"* ]] \
    && [[ "$archiveOut" != *"$T"* ]] && [[ "$archiveOut" != *"$digest"* ]] \
    && [[ "$archiveOut" != *"sourceFingerprint"* ]]; then
    ok "synthetic archive SHA-256 match, only redacted verification printed"
else
    bad "synthetic archive match (exit $archiveCode; output: $archiveOut)"
fi

printf 'DIFFERENT-SYNTHETIC-ARCHIVE-BYTES\n' > "$T/other-source.zip"
chmod 600 "$T/other-source.zip"
archiveOut=$(lua5.1 cli/check-private-1203.lua "$T/with-archive.lua" --archive "$T/other-source.zip" 2>&1); archiveCode=$?
[ "$archiveCode" -ne 0 ] && [[ "$archiveOut" == *"differs from declared input provenance"* ]] \
    && [[ "$archiveOut" != *"$T"* ]] && ok "reject mismatching source archive" || bad "mismatching source archive not rejected"

chmod 644 "$T/source-archive.zip"
archiveOut=$(lua5.1 cli/check-private-1203.lua "$T/with-archive.lua" --archive "$T/source-archive.zip" 2>&1); archiveCode=$?
[ "$archiveCode" -ne 0 ] && [[ "$archiveOut" == *"source archive permissions refused"* ]] \
    && ok "reject world-readable archive" || bad "world-readable archive not rejected"
chmod 600 "$T/source-archive.zip"

mkdir -m 755 "$T/public-archive-parent"
cp -- "$T/source-archive.zip" "$T/public-archive-parent/source.zip"
archiveOut=$(lua5.1 cli/check-private-1203.lua "$T/with-archive.lua" --archive "$T/public-archive-parent/source.zip" 2>&1); archiveCode=$?
[ "$archiveCode" -ne 0 ] && [[ "$archiveOut" == *"source archive permissions refused"* ]] \
    && ok "reject world-readable archive parent" || bad "world-readable archive parent not rejected"

archiveOut=$(lua5.1 cli/check-private-1203.lua "$T/with-archive.lua" --archive "$T/missing-source.zip" 2>&1); archiveCode=$?
[ "$archiveCode" -ne 0 ] && [[ "$archiveOut" == *"source archive path rejected"* ]] \
    && ok "reject missing source archive" || bad "missing source archive not rejected"

archiveOut=$(lua5.1 cli/check-private-1203.lua "$T/with-archive.lua" --archive "$(pwd -P)/tests/fixtures/m2_input/quest1203_single_synthetic.lua" 2>&1); archiveCode=$?
[ "$archiveCode" -ne 0 ] && [[ "$archiveOut" == *"source archive must resolve outside"* ]] \
    && ok "reject public-checkout archive path" || bad "public-checkout archive not rejected"

archiveOut=$(lua5.1 cli/check-private-1203.lua "$T/with-archive.lua" --archive 2>&1); archiveCode=$?
[ "$archiveCode" -ne 0 ] && [[ "$archiveOut" == *"invalid arguments"* ]] \
    && ok "reject incomplete archive argument" || bad "incomplete archive argument accepted"

# Fail-closed subprocess status: a sha256sum executable may print a
# plausible valid digest then exit unsuccessfully. Never trust stdout alone.
mkdir -m 700 "$T/fake-hash-bin"
cat > "$T/fake-hash-bin/sha256sum" <<'FALSEHASH'
#!/bin/sh
printf '%s  -\n' "$NQ_TEST_FALSE_DIGEST"
exit 17
FALSEHASH
chmod 700 "$T/fake-hash-bin/sha256sum"
archiveOut=$(NQ_TEST_FALSE_DIGEST="$digest" PATH="$T/fake-hash-bin:$PATH" \
    lua5.1 cli/check-private-1203.lua "$T/with-archive.lua" --archive "$T/source-archive.zip" 2>&1); archiveCode=$?
[ "$archiveCode" -ne 0 ] && [[ "$archiveOut" == *"source archive SHA-256 unavailable"* ]] \
    && [[ "$archiveOut" != *"$digest"* ]] && [[ "$archiveOut" != *"$T"* ]] \
    && ok "reject plausible hash stdout from failed sha256sum process" \
    || bad "failed sha256sum stdout was trusted"

[ -f "$T/with-archive.lua" ] && [ -f "$T/source-archive.zip" ] \
    && [ "$(stat -c %a "$T/source-archive.zip")" = 600 ] \
    && ok "synthetic input and source bytes remained untouched" || bad "synthetic source/input changed"

echo "M2 private 1203 gate synthetic: $passes passed, $fails failed"
[ "$fails" -eq 0 ]
