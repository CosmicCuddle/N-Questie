#!/usr/bin/env bash
# Public/synthetic regression tests for run-m2-pilot.sh preflight only.
# No private data, no real exporter invocation, no persistent output.
set -u
cd "$(dirname "$0")/.."
SCRIPT=tools/validation/run-m2-pilot.sh
ROOT=$(pwd -P)
T=$(mktemp -d)
chmod 700 "$T"
trap 'rm -rf -- "$T"' EXIT
passes=0; fails=0
ok() { passes=$((passes+1)); echo "PASS: $1"; }
bad() { fails=$((fails+1)); echo "FAIL: $1"; }
[ -z "$(git status --porcelain --untracked-files=all)" ] || { echo "STOP: checkout must be clean"; exit 1; }
# LUA=bash passes executable detection, but intentionally cannot execute Lua.
# Every reject case must stop *before* the first fixture or harness run.
reject() {
    local label="$1" path="$2" mode="$3" want="$4" result code
    result=$(LUA=bash bash "$SCRIPT" "$path" "$mode" 2>&1); code=$?
    if [ "$code" -ne 0 ] && printf '%s\n' "$result" | grep -qF -- "STOP: $want"; then
        ok "$label"
    else
        bad "$label (exit $code)"
    fi
}
reject "reject public repo as output destination" "$ROOT" 1203 "OUT_DIR resolves inside the public checkout"
[ ! -e "$ROOT/negatives-1203.log" ] && ok "public checkout not written" || bad "public checkout received output"
reject "reject directory dot segments" "$T/../escape" 1203 "must not contain . or .. segments"
ln -s "$ROOT" "$T/to-repo"
reject "reject symlink redirecting into checkout" "$T/to-repo" pilot "OUT_DIR resolves inside the public checkout"
rm "$T/to-repo"
mkdir -m 700 "$T/real"
ln -s "$T/real" "$T/alias"
reject "reject final output-directory symlink" "$T/alias" 1203 "OUT_DIR must not be a symlink"
rm "$T/alias"

printf 'KEEP-MY-NEGATIVE-LOG\n' >"$T/negatives-1203.log"
reject "do not overwrite existing negative log" "$T" 1203 "output already exists (no clobber)"
[ "$(cat "$T/negatives-1203.log")" = "KEEP-MY-NEGATIVE-LOG" ] && ok "negative log unchanged" || bad "negative log overwritten"
[ ! -e "$T/effective-1203.lua" ] && ok "no exported Lua after refusal" || bad "export appeared"
rm "$T/negatives-1203.log"

printf 'KEEP-MY-CHECKSUM\n' >"$T/SHA256SUMS-pilot"
reject "do not overwrite existing checksum" "$T" pilot "output already exists (no clobber)"
[ "$(cat "$T/SHA256SUMS-pilot")" = "KEEP-MY-CHECKSUM" ] && ok "checksum unchanged" || bad "checksum overwritten"
rm "$T/SHA256SUMS-pilot"

ln -s "$T/does-not-exist" "$T/verify-pilot.log"
reject "reject dangling symlink in an output filename" "$T" pilot "output already exists (no clobber)"
[ -L "$T/verify-pilot.log" ] && ok "existing symlink unchanged" || bad "symlink changed"
rm "$T/verify-pilot.log"

printf 'KEEP-EXPORT\n' >"$T/effective-1203.lua"
reject "do not overwrite existing export" "$T" 1203 "output already exists (no clobber)"
[ "$(cat "$T/effective-1203.lua")" = "KEEP-EXPORT" ] && ok "export unchanged" || bad "export overwritten"
rm "$T/effective-1203.lua"

chmod 755 "$T"
reject "reject group/other-readable output directory" "$T" 1203 "OUT_DIR must be mode 0700"
chmod 700 "$T"

# Positive preflight: create a new private output directory outside the repo.
# The deliberately invalid Lua interpreter then fails the fixture step;
# the script is not expected to reach any real M0/export work.
D="$T/new-private"
result=$(LUA=bash bash "$SCRIPT" "$D" 1203 2>&1); code=$?
[ "$code" -ne 0 ] && printf '%s\n' "$result" | grep -qF "STOP: negatives failed; not exporting" \
    && ok "safe directory passed preflight and reached fixture gate" || bad "safe directory did not pass preflight"
[ -d "$D" ] && [ "$(stat -c %a -- "$D")" = 700 ] && ok "new directory private (0700)" || bad "new directory permissions"
[ -f "$D/negatives-1203.log" ] && [ "$(stat -c %a -- "$D/negatives-1203.log")" = 600 ] \
    && ok "fixture log private (0600)" || bad "fixture log permissions"
[ ! -e "$D/effective-1203.lua" ] && ok "no export on negative fixture failure" || bad "unexpected export"

echo "M2 pilot preflight: $passes passed, $fails failed"
[ "$fails" -eq 0 ]
