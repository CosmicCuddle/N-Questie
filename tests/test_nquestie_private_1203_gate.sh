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
[ -f "$SRC" ] && [ -n "$(command -v lua5.1)" ] || { echo "FAIL: prerequisites"; exit 1; }
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

reject "reject relative input path" "tests/fixtures/m2_input/quest1203_single_synthetic.lua" "input rejected"
reject "reject public checkout input path" "$(pwd -P)/tests/fixtures/m2_input/quest1203_single_synthetic.lua" "must resolve outside the public checkout"
ln -s "$(pwd -P)/tests/fixtures/m2_input/quest1203_single_synthetic.lua" "$T/public-symlink.lua"
reject "reject symlink to a public synthetic fixture" "$T/public-symlink.lua" "must resolve outside the public checkout"
reject "reject nonexistent input path" "$T/does-not-exist.lua" "input rejected"
out=$(NQ_M2_INPUT="$T/valid.lua" lua5.1 cli/check-private-1203.lua 2>&1); code=$?
[ "$code" -eq 0 ] && [[ "$out" == *"PASS: quest 1203"* ]] && ok "optional environment input works" || bad "optional env input"

[ -f "$T/valid.lua" ] && [ "$(stat -c %a "$T/valid.lua")" = 600 ] && ok "source fixture left intact and private" || bad "fixture altered"

echo "M2 private 1203 gate synthetic: $passes passed, $fails failed"
[ "$fails" -eq 0 ]
