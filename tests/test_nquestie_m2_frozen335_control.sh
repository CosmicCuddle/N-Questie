#!/usr/bin/env bash
# N-Questie Part55 TEST-ONLY: original M2 real-DB controls on original 335.
# This is NOT a Gate10 variant, runtime change, export artifact or release.
# Do not re-pin/modify the historical acceptance scripts or golden fixtures.
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
PIN="26053bd28b0df3a01e5859f779d5f3cb4f57b221"
RT_SHA="a940065a1b198e7ad6ceb2a9a25af5ae01f35608"
EXPORT_SHA="b900ae331b15f6cc9f01c379d17f7ca1d056c8a4"
export LUA=lua5.1

test -z "$(git status --porcelain --untracked-files=all)" || {
  echo "REFUSE: candidate checkout is not clean" >&2; exit 2;
}
command -v "$LUA" >/dev/null || {
  echo "REFUSE: genuine Lua 5.1 unavailable" >&2; exit 2;
}
"$LUA" -e 'assert(type(require("bit32")) == "table")' || {
  echo "REFUSE: Lua 5.1 bit32 unavailable" >&2; exit 2;
}
git cat-file -e "$PIN^{commit}" || {
  echo "REFUSE: pinned original 335 commit unavailable; use fetch-depth 0" >&2; exit 2;
}

T="$(mktemp -d)"
chmod 700 "$T"
trap 'chmod -R u+rwx "$T" 2>/dev/null || :; rm -rf -- "$T"' EXIT
BASE="$T/original-335"
git clone -q --no-hardlinks "$(pwd -P)" "$BASE"
git -C "$BASE" checkout -q --detach "$PIN"
test "$(git -C "$BASE" rev-parse HEAD)" = "$PIN"
test -z "$(git -C "$BASE" status --porcelain --untracked-files=all)"
test "$(git -C "$BASE" rev-parse HEAD:tests/test_nquestie_m2_v2_roundtrip_integration.sh)" = "$RT_SHA"
test "$(git -C "$BASE" rev-parse HEAD:tests/test_nquestie_m2_v2_export_integration.sh)" = "$EXPORT_SHA"
echo "CONTROL: frozen 335 commit and both original test blobs verified"

run_control() {
  local label="$1" name="$2" expected="$3" log="$4"
  local status=0
  (cd "$BASE" && timeout --signal=TERM --kill-after=5s 1050s bash "$name") >"$log" 2>&1 || status=$?
  if [ "$status" -ne 0 ]; then
    echo "FAIL: original 335 $label control (exit $status); last 35 public log lines:" >&2
    tail -n 35 "$log" >&2 || :
    exit "$status"
  fi
  if ! grep -Eq "^$expected: [0-9]+ passed, 0 failed$" "$log"; then
    echo "FAIL: original 335 $label control did not report zero failures" >&2
    tail -n 35 "$log" >&2 || :
    exit 1
  fi
  grep -E "^$expected: [0-9]+ passed, 0 failed$" "$log"
  test -z "$(git -C "$BASE" status --porcelain --untracked-files=all)" || {
    echo "FAIL: original 335 checkout was changed by the $label control" >&2
    exit 1
  }
  echo "PASS: original 335 $label unchanged, clean, zero failures"
}

run_control "M2 A1 real-DB round-trip" \
  "tests/test_nquestie_m2_v2_roundtrip_integration.sh" \
  "v2 round-trip integration" "$T/roundtrip.log"
run_control "M2 A2 real-DB export F1-F8" \
  "tests/test_nquestie_m2_v2_export_integration.sh" \
  "v2 export integration" "$T/export.log"

test -z "$(git status --porcelain --untracked-files=all)"
echo "PASS: original 335 M2 frozen-control checks (candidate checkout unchanged)"
echo "NOT CLAIMED: Gate10 candidate's historical M2 tests pass"
echo "NOT TESTED: native 3.3.5a, IP, Gate08, private SQL or release"
