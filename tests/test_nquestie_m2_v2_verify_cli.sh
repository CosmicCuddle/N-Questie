#!/usr/bin/env bash
# Stage A2: the NQ_V2_VERIFY_IN clean-checkout gate through the real CLI.
# Fast: the gate runs before compile. Uses a temporary shared clone of HEAD
# (never the checkout itself) and private temp dirs. NQ_VERIFY_CLI_SRC (used
# by the mutation test) overlays cli/ and tools/validation/ from another tree
# and commits that in the clone, so the clone is clean at its own HEAD.
set -u
LUA=${LUA:-lua5.1}
ROOT=$(pwd -P)
T=$(mktemp -d); chmod 700 "$T"; trap 'rm -rf "$T"' EXIT
passes=0; fails=0
ok()  { passes=$((passes+1)); echo "PASS: $1"; }
bad() { fails=$((fails+1)); echo "FAIL: $1"; }
strip() { sed 's/\x1b\[[0-9;]*m//g'; }
git clone -q -s "$ROOT" "$T/c" && (cd "$T/c" && git checkout -q "$(git -C "$ROOT" rev-parse HEAD)") || { echo "FAIL: clone"; exit 1; }
if [ -n "${NQ_VERIFY_CLI_SRC:-}" ]; then
    cp "$NQ_VERIFY_CLI_SRC"/cli/validate-335.lua "$T/c/cli/"; cp "$NQ_VERIFY_CLI_SRC"/tools/validation/*.lua "$T/c/tools/validation/"
    (cd "$T/c" && git add -A && git -c user.name=mut -c user.email=mut@invalid commit -q -m mutant --allow-empty) || { echo "FAIL: overlay"; exit 1; }
fi
mkdir -m 700 "$T/in" "$T/home" "$T/tmp"; printf 'return {}' >"$T/in/v2.lua"; chmod 600 "$T/in/v2.lua"
snap() { (cd "$T/c" && find . -path ./.git -prune -o -printf '%P %s %T@ %m\n' | LC_ALL=C sort); find "$T/in" "$T/home" "$T/tmp" -printf '%p %s %T@ %m\n' | LC_ALL=C sort; }
# SKIP_COMPILE makes every run stop at the option check, so only the gate's own messages differ.
run() { (cd "$T/c" && env -i PATH="$PATH" HOME="$T/home" TMPDIR="$T/tmp" NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 NQ_VALIDATE_SKIP_COMPILE=1 \
    NQ_V2_VERIFY_IN="$T/in/v2.lua" "$LUA" cli/validate-335.lua >"$T/o" 2>&1); }
case_() { # name expected-text|CLEAN
    snap >"$T/b"; run; local c=$?; snap >"$T/a"; local out; out=$(strip <"$T/o")
    local unchanged=0; cmp -s "$T/b" "$T/a" && unchanged=1
    if [ "$2" = CLEAN ]; then
        if [ $c -ne 0 ] && grep -qF "needs the compiled database" <<<"$out" && ! grep -qE "not clean|cannot read git status|cannot read HEAD|not a git checkout" <<<"$out" && [ $unchanged = 1 ]; then
            ok "$1"; else bad "$1 (exit $c)"; echo "$out" | tail -4; fi
    elif [ $c -ne 0 ] && grep -qF "v2 verify: provenance: $2" <<<"$out" && ! grep -q "VERIFY PASS\|N-QUESTIE V2 VERIFY" <<<"$out" && [ $unchanged = 1 ]; then
        ok "$1"; else bad "$1 (exit $c)"; echo "$out" | tail -4; fi
}
case_ "clean checkout passes the gate (stops only at the skip-compile refusal), nothing written" CLEAN
printf x >"$T/c/untracked.txt"; case_ "untracked file refused, nothing written" "checkout is not clean"; rm "$T/c/untracked.txt"
mkdir -p "$T/c/sub/deeper"; printf x >"$T/c/sub/deeper/f"; case_ "untracked file in a new subdirectory refused" "checkout is not clean"; rm -r "$T/c/sub"
printf '\n' >>"$T/c/README.md"; case_ "modified tracked file refused, nothing written" "checkout is not clean"
(cd "$T/c" && git add README.md); case_ "staged change refused, nothing written" "checkout is not clean"; (cd "$T/c" && git reset -q --hard)
(cd "$T/c" && git rm -q --cached README.md); case_ "staged deletion refused" "checkout is not clean"; (cd "$T/c" && git reset -q --hard)
cp "$T/c/.git/index" "$T/index.keep"; printf garbage >"$T/c/.git/index"
case_ "git status failure (corrupt index) refused, nothing written" "cannot read git status"; cp "$T/index.keep" "$T/c/.git/index"
mv "$T/c/.git" "$T/git.keep"; case_ "no git repository refused" "not a git checkout"; mv "$T/git.keep" "$T/c/.git"
case_ "clean again after restoring" CLEAN
echo "v2 verify CLI gate: $passes passed, $fails failed"
[ $fails -eq 0 ]
