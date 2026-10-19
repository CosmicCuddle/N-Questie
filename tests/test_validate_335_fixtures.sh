#!/usr/bin/env bash
# Negative tests for cli/validate-335.lua. Each synthetic fault fixture must
# make the validator fail with specific reviewed FAIL diagnostic(s).
# The fixture's -- EXPECT: header is checked against a pinned value here so
# changing it to an unrelated, real error cannot make the harness pass.
# Public quest records and synthetic faults only; no private or live data.
set -u
cd "$(dirname "$0")/.."
status=0
for fixture in tests/fixtures/validate335/*.lua; do
    # Fail closed for new/renamed fixtures until their diagnostic is reviewed.
    required_extra=""
    case "$fixture" in
        tests/fixtures/validate335/classic_chain_wrong_value.lua)
            pinned_expect="PR #13 quest 225 requiredLevel 28"
            required_line="FAIL PR #13 quest 225 requiredLevel 28 (got 29)" ;;
        tests/fixtures/validate335/corrupted_correction.lua)
            pinned_expect="1203 item objective is 3853"
            required_line="FAIL 1203 item objective is 3853"
            required_extra="FAIL N-Questie questData correction returned string, expected table" ;;
        tests/fixtures/validate335/early_level_wrong_value.lua)
            pinned_expect="PR #8 quest 169 requiredLevel 15"
            required_line="FAIL PR #8 quest 169 requiredLevel 15 (got 16)" ;;
        tests/fixtures/validate335/missing_quest.lua)
            pinned_expect="quest 2001 missing after corrections"
            required_line="FAIL quest 2001 missing after corrections"
            required_extra="FAIL NPC 2121 questStarts/questEnds include 2001" ;;
        tests/fixtures/validate335/unexpected_field_change.lua)
            pinned_expect="not allow-listed"
            required_line="FAIL questData 1173 field 1 changed but is not allow-listed"
            required_extra="FAIL questData 1203 field 5 changed but is not allow-listed" ;;
        *)
            echo "FAIL: unreviewed synthetic negative fixture: $fixture"
            status=1
            continue ;;
    esac
    expect=$(sed -n 's/^-- EXPECT: //p' "$fixture" | head -n1)
    if [ -z "$expect" ]; then
        echo "FAIL: $fixture has no '-- EXPECT:' line"
        status=1
        continue
    fi
    if [ "$expect" != "$pinned_expect" ]; then
        echo "FAIL: $fixture changed its pinned '-- EXPECT:' text"
        status=1
        continue
    fi
    raw=$(NQ_VALIDATE_SKIP_COMPILE=1 NQ_VALIDATE_FIXTURE="$fixture" "${LUA:-lua5.1}" cli/validate-335.lua 2>&1)
    code=$?
    output=$(printf '%s\n' "$raw" | sed 's/\x1b\[[0-9;]*m//g')
    if [ "$code" -eq 0 ]; then
        echo "FAIL: $fixture was accepted"; status=1
    elif ! printf '%s\n' "$output" | grep -Fxq -- "$required_line"; then
        echo "FAIL: $fixture rejected without its pinned failure: $required_line"; status=1
    elif [ -n "$required_extra" ] && ! printf '%s\n' "$output" | grep -Fxq -- "$required_extra"; then
        echo "FAIL: $fixture rejected without its second pinned failure: $required_extra"; status=1
    else
        echo "PASS: $fixture rejected with reviewed failure diagnostics"
    fi
done
exit $status
