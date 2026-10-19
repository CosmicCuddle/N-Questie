# NQ-DEV-089 — M0 negative suite interpretation

**Status:** research note only. No validator, fixture, workflow, or correction change.
**Base:** `test/nq-invalid-custom-quest-id-keys-2026-10-19` at `4111b097df44daa02751f4b7a2792689b1df89e6`
**Date of the local runs:** 2026-10-19 (clock read after the last validator run: `2026-10-19T19:55:20Z`)
**Interpreter:** Lua 5.1.5 (`lua5.1 -v`), with `bit32` 5.3.5.1-1 from `luarocks --lua-version=5.1`

A green run of `tests/test_validate_335_fixtures.sh` means each synthetic fixture was refused. The harness exit code is 0 only when, for every `tests/fixtures/validate335/*.lua` file, `cli/validate-335.lua` exits non-zero and the fixture's `-- EXPECT:` text occurs in that output. It is the opposite of a green validator run. The positive M0 command, run separately, exits 0 and prints `[validate-335] PASS: 232 checks`.

Claim labels used below: **VERIFIED** (this session executed it), **SOURCE ONLY** (read from the tree, not executed), **POTENTIAL ISSUE**, **UNKNOWN**, **NOT TESTED**.

## 1. What the suite is

There is no Busted or Lua test-function name for these cases. The harness case name is the fixture path it prints. **SOURCE ONLY** (`tests/test_validate_335_fixtures.sh` loops the glob and echoes that path). **VERIFIED** the five names below, in this order, on the command in section 3.

| Harness case (fixture path) | `-- EXPECT:` substring |
|---|---|
| `tests/fixtures/validate335/classic_chain_wrong_value.lua` | `PR #13 quest 225 requiredLevel 28` |
| `tests/fixtures/validate335/corrupted_correction.lua` | `1203 item objective is 3853` |
| `tests/fixtures/validate335/early_level_wrong_value.lua` | `PR #8 quest 169 requiredLevel 15` |
| `tests/fixtures/validate335/missing_quest.lua` | `quest 2001 missing after corrections` |
| `tests/fixtures/validate335/unexpected_field_change.lua` | `not allow-listed` |

CI calls the same script from two workflows. **SOURCE ONLY:**

- `.github/workflows/nquestie-validate-335.yml` step "Negative tests (synthetic faults must fail the harness)" sets `LUA: lua` and runs `bash tests/test_validate_335_fixtures.sh`. That job installs Lua 5.1 with `leafo/gh-actions-lua@v10` (`luaVersion: "5.1"`) and `luarocks install bit32`, so the binary name on that runner is `lua`.
- `.github/workflows/nquestie-m2-effective-export.yml` step "M0 negatives still fail as intended" sets `LUA: lua5.1` and runs the same script. That matches the command executed here.

The positive step in `nquestie-validate-335.yml` is "Validate effective 3.3.5a Questie DB with all 28 reviewed level corrections": `NQ_VALIDATE_EXPECT_LEVEL_COUNT=28` and `lua cli/validate-335.lua`. **SOURCE ONLY** for that workflow text. The local positive command in section 3 used `lua5.1`. On this machine `lua -v` is also Lua 5.1.5 (`/usr/bin/lua` via update-alternatives). **VERIFIED** the version string. **NOT TESTED:** a second harness or positive run launched under the argv name `lua`. GitHub Actions itself was **NOT TESTED**.

## 2. Fixture, corruption, expected rejection, source

The validator loads `Questie-335.toc`, then, when `NQ_VALIDATE_FIXTURE` is set, runs that file before `QuestieCorrections:Initialize()` (`cli/validate-335.lua` lines 989–999). **SOURCE ONLY.** Later `questData` callbacks overwrite fields because `QuestieCompat.LoadCorrections` calls `_LoadCorrections` without the no-overwrite flag, and `_LoadCorrections` assigns `QuestieDB[databaseTableName][id][key] = value` (`Database/Corrections/QuestieCorrections.lua` lines 261–266; `Compat/Compat.lua` line 1599). **SOURCE ONLY.** The observed `(got 29)` and `(got 16)` strings are the fixture values, so those later writes won on this run. **VERIFIED.**

`check` records a failure and writes `FAIL <message>` to stderr (`cli/validate-335.lua` lines 147–149 and 335–342). When `#failures > 0`, `run` prints `FAILED: N failure(s), M check(s) passed` and `os.exit(1)` (lines 1238–1240). A thrown error takes the `pcall` path and also `os.exit(1)` (lines 1316–1319). These five fixtures hit the `#failures` path: each log contains the `FAILED:` summary. **VERIFIED.** The `pcall` error path was **NOT TESTED**.

The harness sets `NQ_VALIDATE_SKIP_COMPILE=1`, so the compile block (`cli/validate-335.lua` line 1179) does not run for these cases. **SOURCE ONLY.** Rejection in this suite is from the correction checks, not from the compiled round trip.

| Fixture | What it corrupts | Validator outcome the harness requires | Lines that produce the grepped text |
|---|---|---|---|
| `classic_chain_wrong_value.lua` | After the reviewed Classic-chain callback has set quest 225 `requiredLevel` to 28, an extra N-Questie callback sets that field to 29. The reviewed row is `{25, 30, 28, 35}` (`Compat/NQuestieReviewedClassicChainLevels.lua` lines 18 and 40–44; the same tuple is `LEVEL_CORRECTIONS[225]` at `cli/validate-335.lua` line 197). | Exit **1**. Grep substring `PR #13 quest 225 requiredLevel 28`. Full line this run: `FAIL PR #13 quest 225 requiredLevel 28 (got 29)`. Summary: `FAILED: 1 failure(s), 176 check(s) passed`. | `cli/validate-335.lua` line 1160 builds `tag .. " requiredLevel " .. v[3] .. " (got " .. tostring(...) .. ")"` with `tag` = `PR #13 quest 225` and `v[3]` = 28. |
| `corrupted_correction.lua` | One callback replaces quest 1203 `objectives` with the string `"corrupted"`. The reviewed correction writes item 3853 into slot 3 (`Compat/NQuestieExistingQuestCorrections.lua` lines 33–37). A second callback returns the string `"not a table"`. | Exit **1**. Grep substring `1203 item objective is 3853`. That line was present. Two further failures were also present (see below). Summary: `FAILED: 3 failure(s), 170 check(s) passed`. | The grepped sentence is the failure text of the shape check at `cli/validate-335.lua` lines 1106–1108. The string return is a separate `check` at lines 388–390. |
| `early_level_wrong_value.lua` | A later callback sets quest 169 `requiredLevel` to 16. The reviewed row is `{11, 26, 15, 26}` (`Compat/NQuestieReviewedEarlyQuestLevels.lua` lines 19 and 41–43; copied into `LEVEL_CORRECTIONS` when the TOC contains that file, `cli/validate-335.lua` lines 176 and 186–192). `Questie-335.toc` line 92 lists the file. | Exit **1**. Grep substring `PR #8 quest 169 requiredLevel 15`. Full line: `FAIL PR #8 quest 169 requiredLevel 15 (got 16)`. Summary: `FAILED: 1 failure(s), 176 check(s) passed`. | Same builder as quest 225: `cli/validate-335.lua` line 1160, `tag` = `PR #8 quest 169`, `v[3]` = 15. |
| `missing_quest.lua` | Sets `NQuestieCustomQuestData.quests[2001] = nil` before corrections. The public table defines `[2001]` (`Compat/NQuestieCustomQuestData.lua` line 7). The loader walks `custom.quests` (`Compat/NQuestieCustomQuestLoader.lua` lines 62–64 and 105–110), so the nil entry is neither inserted nor linked on NPC 2121. | Exit **1**. Grep substring `quest 2001 missing after corrections` (the whole failure sentence). A second failure was also present. Summary: `FAILED: 2 failure(s), 166 check(s) passed`. | `cli/validate-335.lua` line 1080: `check(type(q) == "table", "quest 2001 missing after corrections")`. |
| `unexpected_field_change.lua` | Sets quest 1203 `questLevel` to 36 (key 5) and quest 1173 `name` to `"Synthetic unexpected rename"` (key 1). Quest 1203's allow-list is only `objectivesText` (key 8) and `objectives` (key 10) (`cli/validate-335.lua` line 218). Quest 1173 is not allow-listed. | Exit **1**. Grep substring `not allow-listed`. It matches two lines this run. Summary: `FAILED: 4 failure(s), 175 check(s) passed`. | `cli/validate-335.lua` lines 1043–1045: `dbName .. " " .. id .. " field " .. f .. " changed but is not allow-listed"`. |

Exact stderr lines from one `NQ_VALIDATE_SKIP_COMPILE=1` run of each fixture (ANSI stripped the same way as the harness). **VERIFIED.** Stdout was 0 bytes on all five; the local `print` writes to stderr, and the harness merges it with `2>&1`. **VERIFIED** the empty stdout. **SOURCE ONLY** the `2>&1` in the harness.

`classic_chain_wrong_value.lua` (exit 1, ~10s):

```
FAIL PR #13 quest 225 requiredLevel 28 (got 29)
[validate-335] FAILED: 1 failure(s), 176 check(s) passed
```

`corrupted_correction.lua` (exit 1, ~10s):

```
FAIL N-Questie questData correction returned string, expected table
FAIL 1203 item objective is 3853
FAIL M1: corrected 1203 must classify as EXPECTED_REPRESENTATION_DIFF only (got NEEDS_MANUAL_REVIEW)
[validate-335] FAILED: 3 failure(s), 170 check(s) passed
```

The M1 sentence is the `check` at `cli/validate-335.lua` lines 1141–1142. **SOURCE ONLY** for that statement. **VERIFIED** the `got NEEDS_MANUAL_REVIEW` text. `tools/validation/ObjectiveRules.lua` was **NOT TESTED** / not traced for why that class was chosen.

`early_level_wrong_value.lua` (exit 1, ~10s):

```
FAIL PR #8 quest 169 requiredLevel 15 (got 16)
[validate-335] FAILED: 1 failure(s), 176 check(s) passed
```

The fixture comment says that, without the early-level module in the TOC, this fault would fail earlier with `not allow-listed`. That alternate TOC was **NOT TESTED**. This commit's TOC includes the module, and the failure that actually printed was the level check.

`missing_quest.lua` (exit 1, ~10s):

```
FAIL quest 2001 missing after corrections
FAIL NPC 2121 questStarts/questEnds include 2001
[validate-335] FAILED: 2 failure(s), 166 check(s) passed
```

The NPC sentence is `cli/validate-335.lua` line 1095. **SOURCE ONLY** for the statement. **VERIFIED** that it printed. The harness substring does not name it.

`unexpected_field_change.lua` (exit 1, ~9s):

```
FAIL questData 1173 field 1 changed but is not allow-listed
FAIL questData 1203 field 5 changed but is not allow-listed
FAIL questData: 2 unexpected change(s)
FAIL 1203 levels stay 30/35
[validate-335] FAILED: 4 failure(s), 175 check(s) passed
```

Field 1 is `QK.name` and field 5 is `QK.questLevel` (`cli/validate-335.lua` lines 154–156). **SOURCE ONLY** for the key numbers; they match the two fields the fixture writes. The count line is line 1070. The levels line is line 1112 (`requiredLevel == 30 and questLevel == 35`), which fails because `questLevel` is 36. **SOURCE ONLY** for those statements. **VERIFIED** the four lines.

Raw stderr still contains the color codes. One captured line was `'\x1b[31mFAIL\x1b[0m PR #13 quest 225 requiredLevel 28 (got 29)'`. **VERIFIED.** The `-- EXPECT:` text sits in the message body, after the colored `FAIL` token, so the substring is present both before and after the harness `sed`. **VERIFIED** for that line. Removing the `sed` was **NOT TESTED**.

## 3. How a validator failure becomes a harness pass

```8:23:tests/test_validate_335_fixtures.sh
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
```

**SOURCE ONLY** for the script. The mapping was **VERIFIED** by the green run in this section and by the mutations in section 4.

For each fixture the script:

1. Reads the first `-- EXPECT: ` line (`head -n1`). An empty result prints `FAIL: <fixture> has no '-- EXPECT:' line` and sets status 1. Every current fixture has that line. **VERIFIED** by the PASS lines quoting those strings. A fixture with no `-- EXPECT:` line was **NOT TESTED**.
2. Runs `cli/validate-335.lua` with `NQ_VALIDATE_SKIP_COMPILE=1` and `NQ_VALIDATE_FIXTURE` set to that file. `LUA` selects the interpreter; the default is `lua5.1`.
3. Keeps the process exit code (`code=$?` after the command substitution). In bash that is the Lua process status. **VERIFIED** indirectly: the same fixtures, run alone, exited 1, and the harness still took the PASS branch. If `code` had been stuck at 0, the harness would have printed `was accepted`.
4. Strips ANSI CSI color sequences, then decides:
   - validator exit 0 → `FAIL: <fixture> was accepted` (the input was not refused)
   - validator exit non-zero, and `grep -qF` does not find the EXPECT text → `FAIL: <fixture> failed, but not with the expected message: <expect>` (refused for a reason that does not contain the required text)
   - otherwise → `PASS: <fixture> rejected with: <expect>`

`grep -qF` is a fixed-string substring search over the whole stripped output, not a full-line or sole-failure check. **SOURCE ONLY.** Any non-zero exit satisfies the exit half; the script does not require exit code 1 in particular. These five exits were 1. **VERIFIED.** Another non-zero code (for example a crash) was **NOT TESTED**.

Status starts at 0. Any of the three FAIL branches sets it to 1. The script then exits with that status. A harness exit of 0 means every fixture took the PASS branch: non-empty EXPECT text, non-zero validator exit, and a matching substring.

That is weaker than "rejected only for this reason":

- Extra `FAIL` lines do not flip a case to harness-fail. `corrupted_correction.lua` printed three failures and `missing_quest.lua` printed two; the harness still passed those cases because the required substring was present. **VERIFIED** both the extra lines and the harness PASS.
- A different failure line that happens to contain the EXPECT text also satisfies the grep. Section 4 mutation C is that case. **POTENTIAL ISSUE.**

### Commands and output (VERIFIED)

Installed with:

```
sudo apt-get update -qq
sudo apt-get install -y lua5.1 liblua5.1-0-dev luarocks
sudo luarocks --lua-version=5.1 install bit32
```

`lua5.1 -v` printed `Lua 5.1.5  Copyright (C) 1994-2012 Lua.org, PUC-Rio`. `require("bit32")` succeeded. `cli/validate-335.lua` line 51 does `bit = require("bit32")`. **SOURCE ONLY** for that `require`.

Negative suite, from the repository root, wall time 51s, exit 0:

```
LUA=lua5.1 bash tests/test_validate_335_fixtures.sh
```

```
PASS: tests/fixtures/validate335/classic_chain_wrong_value.lua rejected with: PR #13 quest 225 requiredLevel 28
PASS: tests/fixtures/validate335/corrupted_correction.lua rejected with: 1203 item objective is 3853
PASS: tests/fixtures/validate335/early_level_wrong_value.lua rejected with: PR #8 quest 169 requiredLevel 15
PASS: tests/fixtures/validate335/missing_quest.lua rejected with: quest 2001 missing after corrections
PASS: tests/fixtures/validate335/unexpected_field_change.lua rejected with: not allow-listed
```

Stderr of the harness was empty. The validator's own `FAIL` lines are swallowed on the PASS branch; they were captured by the separate per-fixture runs in section 2, which use the same environment variables the harness sets.

Positive M0 command, wall time 13s, exit 0. This is the validate-335 workflow's positive step, with `lua5.1` as the binary name:

```
NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 lua5.1 cli/validate-335.lua
```

Summary lines (ANSI stripped):

```
[validate-335] Corrections applied in 5.0s
[validate-335] questData  records=9158 before=f84abb0a after=d317619f unexpected=0
[validate-335] questData IDs added by N-Questie: 2001; removed: none
[validate-335] npcData    records=29615 before=d6e37a01 after=46c35e05 unexpected=0
[validate-335] objectData records=13043 before=8082022e after=8082022e unexpected=0
[validate-335] itemData   records=36767 before=441bb1af after=441bb1af unexpected=0
[validate-335] M1 rules on quest 1203: stock Questie = CONFIRMED_MISMATCH, effective N-Questie = EXPECTED_REPRESENTATION_DIFF
[validate-335] level corrections asserted: 28
[validate-335] Compiled in 1.7s
[validate-335] runtime questDataOverrides entries set aside: 22
[validate-335] compiled round trip: 82431 quest fields compared, 0 mismatches
[validate-335] PASS: 232 checks
```

The summary line is `[validate-335] PASS: 232 checks`. **VERIFIED.**

`tests/test_nquestie_m2_export_integration.sh` (the M2 workflow step "Full M0 + real-DB effective export integration") also greps for `PASS: 232 checks` and then runs export cases. That script was **NOT TESTED** here. The 232-check line above is from the validator command itself.

No `private/` directory was created by these runs. **VERIFIED** (`ls` failed with "No such file or directory" after the positive run and again after the worktrees were removed).

## 4. Disposable mutations

Mutations were applied only in detached git worktrees of `4111b097df44daa02751f4b7a2792689b1df89e6` under `/tmp` (`/tmp/nq-dev089-wt-a`, `-b`, `-c`). Nothing was committed. Each worktree was removed with `git worktree remove --force`. After that, `git worktree list` showed only `/workspace`. **VERIFIED.**

In mutation-testing terms: **KILLED** means the harness exited non-zero on the altered tree. **SURVIVED** means the harness still exited 0.

### (a) Make one fixture identical to the reviewed value — KILLED

In worktree A, the only edit was `classic_chain_wrong_value.lua`: `requiredLevel = 29` changed to `requiredLevel = 28`, the value `LEVEL_CORRECTIONS[225]` requires. The `-- EXPECT:` line was left as `PR #13 quest 225 requiredLevel 28`.

The harness (51s, exit 1) printed:

```
FAIL: tests/fixtures/validate335/classic_chain_wrong_value.lua was accepted
PASS: tests/fixtures/validate335/corrupted_correction.lua rejected with: 1203 item objective is 3853
PASS: tests/fixtures/validate335/early_level_wrong_value.lua rejected with: PR #8 quest 169 requiredLevel 15
PASS: tests/fixtures/validate335/missing_quest.lua rejected with: quest 2001 missing after corrections
PASS: tests/fixtures/validate335/unexpected_field_change.lua rejected with: not allow-listed
```

A direct validator run of that same mutated fixture (`NQ_VALIDATE_SKIP_COMPILE=1`) exited 0 and printed:

```
[validate-335] level corrections asserted: 28
[validate-335] PASS: 177 checks
```

No `FAIL` line was in that output. **VERIFIED.** The original fixture had 1 failure and 176 passes; 176 + 1 = 177, which matches this accepted run. The identification of the flipped check as the line-1160 `requiredLevel` assertion is **SOURCE ONLY** plus the disappearance of that `FAIL` line. The validator does not print the name of each passing check.

This is the `code -eq 0` branch: the harness reports failure when the malformed input is no longer malformed and the validator accepts it. **KILLED.**

### (b) Grep for a reason that is not in the output — KILLED

In worktree B, the only edit was the first line of `unexpected_field_change.lua`: `-- EXPECT: not allow-listed` changed to `-- EXPECT: this-reason-does-not-occur`. The callback body was unchanged, so the validator still rejects the fixture for the allow-list and level failures in section 2.

The harness (50s, exit 1) printed:

```
PASS: tests/fixtures/validate335/classic_chain_wrong_value.lua rejected with: PR #13 quest 225 requiredLevel 28
PASS: tests/fixtures/validate335/corrupted_correction.lua rejected with: 1203 item objective is 3853
PASS: tests/fixtures/validate335/early_level_wrong_value.lua rejected with: PR #8 quest 169 requiredLevel 15
PASS: tests/fixtures/validate335/missing_quest.lua rejected with: quest 2001 missing after corrections
FAIL: tests/fixtures/validate335/unexpected_field_change.lua failed, but not with the expected message: this-reason-does-not-occur
```

That is the "rejected, but the required text is absent" branch (harness lines 17–18). **KILLED.** The validator log for this mutant was not captured separately. The printed harness line is emitted only when the validator exit is non-zero and `grep -qF` fails. **SOURCE ONLY** for that branch condition. **VERIFIED** the printed line and the harness exit code.

### (c) Point EXPECT at a different real failure from the same run — SURVIVED

**POTENTIAL ISSUE.** In worktree C, the only edit was `-- EXPECT: not allow-listed` changed to `-- EXPECT: 1203 levels stay 30/35`. That second sentence is a real failure of this fixture (section 2, validator line 1112). It is not the allow-list reason the fixture comment names.

The harness (51s, exit 0) printed:

```
PASS: tests/fixtures/validate335/classic_chain_wrong_value.lua rejected with: PR #13 quest 225 requiredLevel 28
PASS: tests/fixtures/validate335/corrupted_correction.lua rejected with: 1203 item objective is 3853
PASS: tests/fixtures/validate335/early_level_wrong_value.lua rejected with: PR #8 quest 169 requiredLevel 15
PASS: tests/fixtures/validate335/missing_quest.lua rejected with: quest 2001 missing after corrections
PASS: tests/fixtures/validate335/unexpected_field_change.lua rejected with: 1203 levels stay 30/35
```

**SURVIVED.** The harness catches a grepped string that does not occur anywhere (mutation B). It does not catch a grepped string that occurs on a different failure line of the same run. `grep -qF` has no notion of "the" reason. The same limit applies to `corrupted_correction.lua` and `missing_quest.lua`: their extra `FAIL` lines are invisible to the harness as long as the `-- EXPECT:` substring is present.

## 5. Claim ledger

| Claim | Label |
|---|---|
| Base commit is `4111b097df44daa02751f4b7a2792689b1df89e6` on `test/nq-invalid-custom-quest-id-keys-2026-10-19` | **VERIFIED** (`git rev-parse HEAD` before and after the worktrees were removed) |
| Five fixtures, their `-- EXPECT:` strings, and the harness PASS lines in section 3 | **VERIFIED** |
| Each unmodified fixture's validator exit was 1, with the `FAIL` lines in section 2 | **VERIFIED** |
| Positive command exited 0 and printed `[validate-335] PASS: 232 checks`, 28 level corrections, 82431 compiled fields, 0 mismatches | **VERIFIED** |
| Harness branch logic (accept → harness fail; non-zero plus matching substring → harness pass; non-zero plus absent substring → harness fail) | **SOURCE ONLY** for the script; **VERIFIED** by the green run, mutation A, and mutation B |
| Message text is produced by the cited `check(...)` calls | **SOURCE ONLY** for the Lua; **VERIFIED** that those sentences appeared in the logs |
| Later fixture callbacks overwrite because `_LoadCorrections` assigns the field | **SOURCE ONLY**; **VERIFIED** only that the logged `(got …)` values were the fixture values |
| Early-level fixture would instead report `not allow-listed` if that module were absent from the TOC | **NOT TESTED** (TOC on this commit includes the module; the observed failure was the level check) |
| `ObjectiveRules.lua` reason for `NEEDS_MANUAL_REVIEW` | **NOT TESTED** |
| `pcall` error exit, a missing `-- EXPECT:` line, and a non-1 non-zero validator exit | **NOT TESTED** |
| Workflow YAML text, including `LUA: lua` versus `LUA: lua5.1`, and the overlay `if: ${{ false }}` holds | **SOURCE ONLY** |
| GitHub Actions runs of these workflows | **NOT TESTED** |
| `tests/test_nquestie_m2_export_integration.sh` | **NOT TESTED** |
| Launching the harness or the positive command under the argv name `lua` | **NOT TESTED** (`lua -v` is Lua 5.1.5 on this machine) |
| Mutation A: value 28 is accepted (validator exit 0, `PASS: 177 checks`) and the harness exits 1 with `was accepted` | **VERIFIED**. Result label **KILLED** |
| Mutation B: absent EXPECT text makes the harness exit 1 with `failed, but not with the expected message` | **VERIFIED**. Result label **KILLED** |
| Mutation C: EXPECT text taken from another failure line of the same fixture leaves the harness exit 0 | **VERIFIED**. Result label **SURVIVED**. **POTENTIAL ISSUE** |
| No private server or database was contacted; `private/` was absent | **VERIFIED** for the absence of `private/` and for which local commands ran. No network target other than apt/luarocks package mirrors was used |

## 6. Checkout after the experiments

Mutations stayed in the `/tmp` worktrees and were deleted with those worktrees. They are not in the index.

After removal, and before this file was added:

```
git status --porcelain --ignored --untracked-files=all
```

produced no output. `private/` did not exist. `git rev-parse HEAD` was `4111b097df44daa02751f4b7a2792689b1df89e6`. **VERIFIED.**

This note is the only file intended to be added after that check.
