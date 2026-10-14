#!/usr/bin/env bash
# Negative tests for cli/validate-335.lua. Each synthetic fault fixture must
# make the harness exit non-zero AND report the failure named on the
# fixture's "-- EXPECT:" line. Public data and synthetic faults only.
set -u
cd "$(dirname "$0")/.."
status=0
for fixture in tests/fixtures/validate335/*.lua; do
    expect=$(sed -n 's/^-- EXPECT: //p' "$fixture" | head -n1)
    raw=$(NQ_VALIDATE_SKIP_COMPILE=1 NQ_VALIDATE_FIXTURE="$fixture" "${LUA:-lua5.1}" cli/validate-335.lua 2>&1)
    code=$?
    output=$(printf '%s\n' "$raw" | sed 's/\x1b\[[0-9;]*m//g')
    if [ -z "$expect" ]; then
        echo "FAIL: $fixture has no '-- EXPECT:' line"; status=1
    elif [ "$code" -eq 0 ]; then
        echo "FAIL: $fixture was accepted"; status=1
    elif ! printf '%s\n' "$output" | grep -qF "$expect"; then
        echo "FAIL: $fixture failed, but not with the expected message: $expect"; status=1
    else
        echo "PASS: $fixture rejected with: $expect"
    fi
done
exit $status
