# DEV-082 — M0 validate-335 check families (232)

| Field | Value |
|---|---|
| Task | DEV-082. Docs/research only, no behaviour change. |
| Base SHA | `4111b097df44daa02751f4b7a2792689b1df89e6` |
| Date | 2026-10-19 |
| Author | CosmicScript02 |
| Scope | One new file. No M0/M1 code, workflow, test, fixture, database, correction, or TOC edit. |

Labels used below: **VERIFIED** (this run executed it, or the cited source/log line says it), **POTENTIAL ISSUE**, **UNKNOWN**, **NOT TESTED**.

## 1. Method

1. **VERIFIED** the guarded overlay workflow on this SHA. `.github/workflows/nquestie-overlay.yml:71` and `:95` are both `if: ${{ false }}` on the Assemble and Upload steps.
2. Read `.github/workflows/nquestie-validate-335.yml` (workflow name "N-Questie 3.3.5a effective DB validation (M0)", job `validate-335`) and `cli/validate-335.lua` in full, plus `docs/NQ-VALIDATION-M0.md`.
3. Read the attached job log for GitHub Actions run `39289631786`, job `118186591876` (19 Oct 2026) on this same SHA. Log line 586 is `[validate-335] PASS: 232 checks`.
4. Reproduced the workflow commands locally with Lua 5.1.5 and `bit32` 5.3.5.1-1 (section 5).
5. Tallied every successful `check()` call with a copy of the harness that lives only at `/tmp/validate-335-tally.lua`. That copy is not in the git tree. It wrote `/tmp/m0-check-tally.txt` (232 lines) and `/tmp/m0-override-ids.txt` (22 IDs). After that run, `git status --porcelain` was empty.

The 232 figure is the `passes` counter inside one process: `NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 lua cli/validate-335.lua`. The negative-fixture step is a separate process per fixture and is not added to 232.

## 2. How `passes` increments

**VERIFIED.** There is one increment site:

```lua
-- cli/validate-335.lua:335-341
local function check(cond, message)
    if cond then
        passes = passes + 1
    else
        failures[#failures + 1] = message
        print("\27[31mFAIL\27[0m " .. message)
    end
end
```

`cli/validate-335.lua:1242` prints `PASS: %d checks` from `passes` only when `#failures == 0`. A failing `check()` does not increment `passes`. On this run failures were 0, so attempted checks and passes are the same 232.

`pairs()` walks level corrections and overrides in an unspecified order. Family counts below are counts of calls, not a stable order. The `/tmp` tally confirmed the counts; the order in that file is not a contract.

### Call sites that succeed on the PASS path

| Site | Successful calls on this run |
|---|---|
| `cli/validate-335.lua:967` | 1 (`Is335`) |
| `cli/validate-335.lua:968` | 1 (`IsWotlk`) |
| `cli/validate-335.lua:969` | 1 (`nqCallbacks >= 6`; the tally message says `got 6`) |
| `cli/validate-335.lua:986` | 13 (one per key in `QK`, `cli/validate-335.lua:154-156`) |
| `cli/validate-335.lua:1023` | 1 (pre-N-Questie `questData` snapshot exists) |
| `cli/validate-335.lua:1070` | 4 (one per database that has both snapshots) |
| `cli/validate-335.lua:1079-1090` | 10 (quest 2001) |
| `cli/validate-335.lua:1095` | 1 (NPC 2121 reverse links) |
| `cli/validate-335.lua:1104-1122` | 13 (quest 1203, including five objective slots) |
| `cli/validate-335.lua:1140-1142` | 2 (M1 classes for quest 1203) |
| `cli/validate-335.lua:1155-1166` | 129 (28 level-correction records) |
| `cli/validate-335.lua:1173` | 1 (count equals `NQ_VALIDATE_EXPECT_LEVEL_COUNT`) |
| `cli/validate-335.lua:1198` | 1 (compiled 1203 levels) |
| `cli/validate-335.lua:1200` | 1 (compiled 1203 item) |
| `cli/validate-335.lua:1201` | 1 (compiled 2001 name) |
| `cli/validate-335.lua:1203` | 28 (compiled levels, one per `LEVEL_CORRECTIONS` id) |
| `cli/validate-335.lua:1214` | 22 (one per `questDataOverrides` entry) |
| `cli/validate-335.lua:1235` | 1 (compiled mismatches == 0) |
| **Sum** | **232** |

### `check()` sites that contribute 0 on this PASS

These call `check(false, ...)` only when something is wrong. They did not run on this pass, so they are not part of 232. **VERIFIED** by reading the branches and by the tally containing none of their messages.

| Site | When it would fire |
|---|---|
| `cli/validate-335.lua:389` | An N-Questie callback returns a non-table |
| `cli/validate-335.lua:963` | A load error in `Database/`, `Compat/`, `QuestieInit.lua`, or `QuestieCompat.lua` |
| `cli/validate-335.lua:1036` | A new record is not allow-listed |
| `cli/validate-335.lua:1045` | A changed field is not allow-listed |
| `cli/validate-335.lua:1053` | A record disappears |
| `cli/validate-335.lua:1097` | NPC 2121 is not a table |

Prints that are not checks: the four database hash lines (`cli/validate-335.lua:1058`), the added-ID line (`:1067-1068`), the M1 class line (`:1139`), `level corrections asserted` (`:1170`), the override count (`:1218`), and `compiled round trip: N quest fields compared` (`:1234`). `docs/NQ-VALIDATION-M2.2-QUEST-ID-SET.md:37` says the added-ID line is informational and does not change the count. **VERIFIED** against `:1059-1068`.

## 3. Classification rule

Each successful `check()` call is in exactly one class:

| Class | Rule used here |
|---|---|
| identity | The quest record is present or absent, or the correction is expected to store a specific quest/NPC ID (starter, ender, prerequisite, reverse link). |
| quest level | The compared fields are `requiredLevel` and/or `questLevel`, and the expected value is the post-correction level (source table or compiled read-back). |
| objective | Objectives, objective text, objective slots, the compiled item objective, or the two M1 objective classes. |
| baseline | The value is compared with the pre-N-Questie snapshot, or with a pinned public original that the correction must leave unchanged (preservation, original levels, unchanged level field, quest 1203 starter/prerequisite/exclusiveTo/unmutated objectives). |
| missing reference | A successful check whose assertion is that a referenced quest, NPC, object, or item ID resolves to an existing record. |
| other | Named in the family row. |

**VERIFIED:** missing reference = **0**. The harness compares stored IDs to literals (2121, 437, 1868, 1869, 4792, 1206, 3853). It does not look those IDs up in `npcData`, `itemData`, or `questData`, except that NPC 2121 must already be a table for the reverse-link check at `:1095` to be the success branch. A missing NPC 2121 would hit `:1097`, which does not increment `passes`.

## 4. Family table

Counts are from the source call structure and from the `/tmp` tally of this run. They sum to 232.

| ID | Family | Class | Checks | What it asserts | Records | Data origin | Source |
|---|---|---|---|---|---|---|---|
| F01 | Harness environment | other (client path) | 3 | `QuestieCompat.Is335`, `Questie.IsWotlk`, and at least 6 N-Questie `RegisterCorrection` callbacks. This run registered exactly 6. | No quest body. The 6 callbacks are the two in `Compat/NQuestieCustomQuestLoader.lua` (quest 2001 quest+NPC), plus one each in `NQuestieExistingQuestCorrections.lua` (1203), `NQuestieReviewedQuestLevelCorrections.lua`, `NQuestieReviewedEarlyQuestLevels.lua`, and `NQuestieReviewedClassicChainLevels.lua`. | Protected public source (TOC load of this repo). | `cli/validate-335.lua:967-969` |
| F02 | questKeys index schema | other (schema) | 13 | `QuestieDB.questKeys[name]` equals the index hardcoded in `QK` for all 13 names (`name` 1 through `questFlags` 23). | Schema only. | Pinned indices in the harness, checked against the loaded public DB. | `cli/validate-335.lua:154-156`, `:985-987` |
| F03 | Correction window opened | other (window) | 1 | `snapshots.before.questData` is non-nil, so an N-Questie quest callback ran. The failure text is "corrections never ran"; on this run the condition was true. | The pre-callback quest snapshot (9,158 records; see F04). | Protected public source, after inherited corrections and before N-Questie. | `cli/validate-335.lua:1023` |
| F04 | Preservation | baseline | 4 | `unexpected == 0` for `questData`, `npcData`, `objectData`, and `itemData`. Any new, removed, or changed field outside `ALLOWED` would have called `check(false)` and would not be one of these four passes. | Before-snapshot sizes printed by this run and by the CI log: quest 9,158, NPC 29,615, object 13,043, item 36,767. After the callbacks the quest set gains 2001 only (`added: 2001; removed: none`). | Protected public source, compared with itself across the N-Questie window. Allow-list is harness data (`cli/validate-335.lua:217-228`). | `cli/validate-335.lua:1024-1071` |
| F05 | Quest 2001 record identity | identity | 2 | ID 2001 is absent in the before snapshot and is a table afterwards. | 2001 | Before side: protected public DB. After side: public `Compat/NQuestieCustomQuestLoader.lua`. | `cli/validate-335.lua:1079-1080` |
| F06 | Quest 2001 name | other (name) | 1 | Name is `Ravenclaw Cleanup`. | 2001 | Pinned literal in the harness, matching the public correction module. | `cli/validate-335.lua:1082` |
| F07 | Quest 2001 levels | quest level | 1 | `requiredLevel` 12 and `questLevel` 16, one check. | 2001 | Pinned literal. | `cli/validate-335.lua:1083` |
| F08 | Quest 2001 zone, race, flags | other (zone/race/flags) | 3 | `zoneOrSort` 130, `requiredRaces` 690, `questFlags` 8. | 2001 | Pinned literals. | `cli/validate-335.lua:1084-1086` |
| F09 | Quest 2001 starter, ender, prerequisite | identity | 3 | `startedBy {{2121}}`, `finishedBy {{2121}}`, `preQuestSingle {437}`. | 2001. IDs named: NPC 2121, quest 437. | Pinned literals. | `cli/validate-335.lua:1087-1089` |
| F10 | Quest 2001 kill objectives | objective | 1 | `objectives` serialises as `{{{1868},{1869}}}`. | 2001. Creature IDs 1868 and 1869. | Pinned literal. | `cli/validate-335.lua:1090` |
| F11 | NPC 2121 reverse links | identity | 1 | `npcData[2121]` fields 10 and 11 (`questStarts` / `questEnds`) both include 2001. | NPC 2121, quest 2001 | Protected public NPC record plus the public N-Questie NPC callback. | `cli/validate-335.lua:1092-1095` |
| F12 | Quest 1203 record identity | identity | 1 | Quest 1203 is a table after corrections and was present before. | 1203 | Protected public source. | `cli/validate-335.lua:1104` |
| F13 | Quest 1203 item objective | objective | 1 | `objectives[3]` has exactly one entry and its item ID is 3853. | 1203, item 3853 | Public correction module, pinned in the harness. | `cli/validate-335.lua:1107-1108` |
| F14 | Quest 1203 objective text | objective | 1 | `objectivesText[1]` contains the substring `Moonsteel Broadsword`. | 1203 | Public correction module, pinned substring. | `cli/validate-335.lua:1109-1111` |
| F15 | Quest 1203 levels | quest level | 1 | Levels stay 30/35. | 1203 | Pinned literal. | `cli/validate-335.lua:1112` |
| F16 | Quest 1203 starter and prerequisite stay pinned | baseline | 2 | `startedBy` serialises as `{{4792}}` and `preQuestSingle` as `{1206}`. | 1203. NPC 4792, quest 1206. | Pinned public values the correction must not change. | `cli/validate-335.lua:1113-1114` |
| F17 | Quest 1203 exclusiveTo | baseline | 1 | `exclusiveTo` equals the before-snapshot serialisation (or `"nil"`). | 1203 | Pre-N-Questie public snapshot. | `cli/validate-335.lua:1115` |
| F18 | Quest 1203 objectives table not mutated | baseline | 1 | The objectives table captured before the N-Questie callback still serialises to that snapshot. | 1203 | Pre-callback public snapshot. | `cli/validate-335.lua:1116-1118` |
| F19 | Quest 1203 other objective slots | objective | 5 | Slots 1, 2, 4, 5, and 6 serialise equal to the original table. Slot 3 is the item slot and is F13. | 1203 | Comparison with the pre-callback objectives table. | `cli/validate-335.lua:1119-1124` |
| F20 | M1 classes for quest 1203 | objective | 2 | Stock objectives classify as `CONFIRMED_MISMATCH`. Effective objectives classify as `EXPECTED_REPRESENTATION_DIFF`. | 1203 | Stock side: pre-callback public objectives. Server-shaped row: invented synthetic `{ ID = 1203, RequiredItemId1 = 3853, RequiredItemCount1 = 1 }` (`cli/validate-335.lua:1128-1135`). The comment says that row is taken from public facts in `docs/REVIEW-2026-10-14.md`. It is not a private database read. | `cli/validate-335.lua:1140-1142` |
| F21 | Level-correction presence | identity | 28 | Each `LEVEL_CORRECTIONS` quest exists before and after. | The 28 IDs in section 4.1 | Protected public source. | `cli/validate-335.lua:1151-1155` |
| F22 | Level-correction original levels | baseline | 28 | Before `requiredLevel` and `questLevel` equal the pinned public originals in the table (both fields, one check per quest). | The 28 IDs | Pinned originals in `cli/validate-335.lua:160-206`, compared with the before snapshot. | `cli/validate-335.lua:1157-1159` |
| F23 | Level-correction requiredLevel | quest level | 28 | After `requiredLevel` equals column 3 of the table. | The 28 IDs | Public correction modules, pinned in the harness. | `cli/validate-335.lua:1160` |
| F24 | Level-correction questLevel | quest level | 28 | After `questLevel` equals column 4 of the table. | The 28 IDs | Public correction modules, pinned in the harness. | `cli/validate-335.lua:1161` |
| F25 | Unchanged level field | baseline | 17 | When original and corrected `requiredLevel` are equal, the after value must still equal the before snapshot. Same for `questLevel`. No row in the table leaves both fields unchanged, and none changes neither, so each of 17 quests adds one check. | requiredLevel held: 98, 126, 249, 304, 442, 1205, 1252, 464, 465, 473, 474. questLevel held: 169, 180, 256, 398, 895, 6284. | Before snapshot versus the after value. | `cli/validate-335.lua:1162-1167` |
| F26 | Level-correction count | other (count guard) | 1 | The number of `LEVEL_CORRECTIONS` entries equals `NQ_VALIDATE_EXPECT_LEVEL_COUNT` (28). | 28 records, not 28 checks. | Environment variable set by the workflow (`nquestie-validate-335.yml:41`). | `cli/validate-335.lua:1171-1173` |
| F27 | Compiled quest 1203 levels | quest level | 1 | `QueryQuestSingle` returns questLevel 35 and requiredLevel 30. | 1203 | Compiled public DB, pinned expected levels. | `cli/validate-335.lua:1198` |
| F28 | Compiled quest 1203 item | objective | 1 | Compiled `objectives[3][1][1]` is 3853. | 1203, item 3853 | Compiled public DB. | `cli/validate-335.lua:1199-1200` |
| F29 | Compiled quest 2001 name | other (name) | 1 | Compiled name is `Ravenclaw Cleanup`. | 2001 | Compiled public DB. | `cli/validate-335.lua:1201` |
| F30 | Compiled level corrections | quest level | 28 | Compiled requiredLevel and questLevel match the corrected pair, one check per ID. | The 28 IDs | Compiled public DB. | `cli/validate-335.lua:1202-1204` |
| F31 | Runtime overrides do not shadow N-Questie | other (override guard) | 22 | For each `questDataOverrides` entry, the ID is not in `LEVEL_CORRECTIONS` and is not 1203 or 2001. | 687, 737, 1718, 1947, 1953, 2861, 5050, 6681, 7562, 8151, 8233, 8250, 8254, 8417, 8419, 8904, 9063, 9330, 9331, 9332, 9388, 9389 | Protected public source. These 22 keys are exactly `questFixesHorde` in `Database/Corrections/classicQuestFixes.lua:4010-4078`. The harness defaults `UnitFactionGroup` to Horde when no argument is passed (`cli/validate-335.lua:68-70`); the workflow passes none. TBC Horde faction fixes contain only 2861 (`tbcQuestFixes.lua:5414-5417`), which is already in that set. | `cli/validate-335.lua:1211-1216` |
| F32 | Compiled round-trip aggregate | other (compiler fidelity) | 1 | `mismatches == 0` after comparing every quest in the post-correction source with `QueryQuestSingle` on the nine `COMPILED_KEYS`. | 9,159 quests × 9 keys = 82,431 comparisons inside this one check. 9,158 before-snapshot quests plus added 2001 is 9,159. `9159 * 9 = 82431`. | Post-correction in-memory quest table versus the compiled DB. This is not a comparison to stock Questie, and it is not 82,431 increments of `passes`. | `cli/validate-335.lua:283-284`, `:1220-1235` |
| — | Missing reference | missing reference | 0 | No successful `check()` resolves a referenced ID to another record. | — | — | See section 3 |
| | **Total** | | **232** | | | | |

### 4.1 The 28 level-correction quest IDs

**VERIFIED** from `LEVEL_CORRECTIONS` (`cli/validate-335.lua:160-212`) and from the tally, which contained every ID below. The early and classic rows are inserted only when `Questie-335.toc` names those two files (`:186-212`). This TOC does, and the run printed `level corrections asserted: 28`.

| Group | IDs | Before → after (required/quest) | F25 extra check |
|---|---|---|---|
| PR #7 Dustwallow, 8 | 1166, 1168, 1169, 1170, 1171 | 37/41 → 38/43 | none (both fields change) |
| | 1172 | 37/41 → 38/45 | none |
| | 1205 | 35/41 → 35/45 | requiredLevel |
| | 1252 | 30/35 → 30/40 | requiredLevel |
| PR #8 early zones, 11 | 98 | 22/32 → 22/35 | requiredLevel |
| | 126 | 15/21 → 15/25 | requiredLevel |
| | 169, 180 | 11/26 → 15/26 | questLevel |
| | 249 | 20/26 → 20/27 | requiredLevel |
| | 256 | 9/22 → 17/22 | questLevel |
| | 304 | 26/31 → 26/34 | requiredLevel |
| | 398 | 4/10 → 6/10 | questLevel |
| | 442 | 10/20 → 10/24 | requiredLevel |
| | 895 | 9/16 → 11/16 | questLevel |
| | 6284 | 12/21 → 15/21 | questLevel |
| PR #13 classic chains, 9 | 225, 227, 228, 229, 231 | 25/30 → 28/35 | none |
| | 473, 464 | 23/26 → 23/28 | requiredLevel |
| | 465 | 23/26 → 23/31 | requiredLevel |
| | 474 | 23/26 → 23/32 | requiredLevel |

Per-quest pre-compile checks: 11 quests × 4 (presence, original, requiredLevel, questLevel) + 17 quests × 5 (those four plus F25) = 44 + 85 = 129. Plus F26 = 130 pre-compile level checks. Plus F30 = 28 compiled level checks. Quest 2001 and quest 1203 level checks are F07, F15, and F27, outside this table.

### 4.2 Class rollup

| Class | Families | Checks |
|---|---|---|
| identity | F05, F09, F11, F12, F21 | 35 |
| quest level | F07, F15, F23, F24, F27, F30 | 87 |
| objective | F10, F13, F14, F19, F20, F28 | 11 |
| baseline | F04, F16, F17, F18, F22, F25 | 53 |
| missing reference | none | 0 |
| other | F01, F02, F03, F06, F08, F26, F29, F31, F32 | 46 |
| **Total** | | **232** |

### 4.3 Data origin, in one place

- **Protected public source.** The Questie database loaded through `Questie-335.toc`, inherited faction fixes, and the public `Compat/NQuestie*.lua` modules in this repository. **VERIFIED:** the check path does not open `private/`, SQL, or SavedVariables. The file header says so (`cli/validate-335.lua:26`).
- **Invented synthetic.** Only F20's server-shaped quest-1203 row, built in the harness (`cli/validate-335.lua:1135`). The negative fixtures under `tests/fixtures/validate335/` are also synthetic. They are not inside the 232.
- **Reported private aggregate.** None of the 232 checks. **VERIFIED** by reading the harness. **NOT TESTED** against any private server.

Hashes printed by this local run match the attached CI log lines 575-585: quest `f84abb0a → d317619f` (9,158 before), NPC `d6e37a01 → 46c35e05` (29,615), object `8082022e` unchanged (13,043), item `441bb1af` unchanged (36,767), 22 overrides, 82,431 fields, 0 mismatches.

## 5. Reproduction

Workflow commands, from `.github/workflows/nquestie-validate-335.yml:36-46`:

```bash
# Lua 5.1.5 and LuaRocks from apt; bit32 into the user tree (CI uses leafo/gh-actions-lua and `luarocks install bit32`)
sudo apt-get install -y lua5.1 luarocks
luarocks --lua-version=5.1 --local install bit32 LUA_INCDIR=/usr/include/lua5.1 LUA_LIBDIR=/usr/lib/x86_64-linux-gnu
eval "$(luarocks path --lua-version=5.1 --local)"

luac -p cli/validate-335.lua tests/fixtures/validate335/*.lua
NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 lua cli/validate-335.lua
LUA=lua bash tests/test_validate_335_fixtures.sh
```

**VERIFIED** on 2026-10-19, Lua 5.1.5, `bit32` 5.3.5.1-1, cwd this checkout at `4111b097df44daa02751f4b7a2792689b1df89e6` before the research file existed:

| Command | Result |
|---|---|
| `luac -p` | exit 0 |
| `NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 lua cli/validate-335.lua` | exit 0, stdout/stderr contained `[validate-335] PASS: 232 checks` |
| `LUA=lua bash tests/test_validate_335_fixtures.sh` | exit 0. All five fixtures rejected with their `-- EXPECT:` text: classic chain 225, corrupted 1203 item, early quest 169, missing quest 2001, unexpected field. |

The same `PASS: 232 checks` line is log line 586 of run `39289631786` / job `118186591876`. That log's lines 600-604 show the same five fixture rejections. **VERIFIED** by reading the log. The negative step is not part of the 232.

`git status --porcelain` after those commands, and after the `/tmp` tally, listed no files. The tally script was not copied into the repo.

## 6. Statements the current source does not support

Search: `rg -n '232' docs README.md`. `README.md` has no match. **VERIFIED.** The hits below are the `docs/*.md` lines that talk about the M0 232 (or an older total a reader could take as the current one). Other `docs/*.md` lines that simply say the harness pass count is 232 agree with `passes` on this SHA. Those historical runs were **NOT TESTED** again here. The attached log and the local run are the runs that were checked.

Do not edit those docs under this task. Recommendations only.

1. **`docs/NQ-DRAFT-PR-CONSOLIDATION-PLAN.md:45`** — "232 M0 checks / 28 reviewed-level checks / 82,431 compiled-field read-back".
   - **VERIFIED** mismatch. `28` is `LEVEL_CORRECTIONS` cardinality (`level corrections asserted: 28`), not 28 `check()` calls. Pre-compile level checks are 129 + 1 count guard, and compiled level read-backs are another 28 (F21–F26 and F30), before counting quest 2001 and 1203 level checks.
   - **VERIFIED** mismatch if 82,431 is read as a check count. It is the inner comparison count of F32, one `check()` at `cli/validate-335.lua:1235`. The log text is `82431 quest fields compared`.
   - Recommendation: say "232 successful `check()` calls; 28 level-correction records; one aggregate check over 82,431 compiled field comparisons".

2. **`docs/INTEGRATION-M1-28QUEST-2026-10-14.md:31`** — "232 assertions" and "82,431 quest fields checked".
   - **POTENTIAL ISSUE.** "232 assertions" matches `passes` on a green run. "quest fields checked" matches the comparison count, which is easy to add into the 232. The same paragraph says these results are not in-game QA. That limitation agrees with section 7.
   - Recommendation: "82,431 field comparisons inside one check".

3. **`docs/ROADMAP.md:41`** and **`docs/PROJECT-HANDOVER.md:25`** — run `38571850030` "230 checks", with 28 level corrections and 82,431 fields.
   - **VERIFIED** for this SHA: `cli/validate-335.lua` prints 232, because the two M1 checks at `:1140-1142` are included. 230 is not this file's pass count.
   - **NOT TESTED:** that historical run's log was not re-downloaded. `docs/NQ-VALIDATION-M1.md:126` describes an older 19-correction harness going from 181 to 183 when the same two M1 checks were added, which is the same +2.
   - Recommendation: keep 230 as that run's printed total only.

4. **`docs/NQ-VALIDATION-M0.md:62`** "PASS, 89 checks" and **`:124`** "PASS, 181 checks" with `NQ_VALIDATE_EXPECT_LEVEL_COUNT=19`.
   - **VERIFIED:** the current TOC includes the early-zone and classic-chain modules, the workflow sets the count to 28, and this harness prints 232. It does not print 89 or 181.
   - **NOT TESTED:** those 14 Oct 2026 local results were not replayed on the old trees. Section 3 of that doc describes the earlier assertion set (quest 2001, quest 1203, eight Dustwallow rows). It is not a breakdown of the current 232.
   - Recommendation: label 89 and 181 as historical harness shapes.

5. **`docs/NQ-VALIDATION-M1.md:126`** and **`:218`** — "PASS, 183 checks" with `NQ_VALIDATE_EXPECT_LEVEL_COUNT=19`.
   - **VERIFIED:** the workflow command on this SHA uses 28 and prints 232. 183 is the older 19-correction configuration plus the two M1 checks, as that doc itself says at line 126.
   - **NOT TESTED** as a replay of that older configuration.
   - Recommendation: do not cite 183 as the current M0 total.

6. **`docs/NQ-INTEGRATION-PLAN.md:169-171`** — "validate-335 fixtures (3 rejections)" in the paragraph that also says M0 passed all 232 checks.
   - **VERIFIED:** `tests/test_validate_335_fixtures.sh` globs `tests/fixtures/validate335/*.lua`, and that directory has five fixtures. The local run and CI log lines 600-604 each report five rejections.
   - **NOT TESTED:** the historical trial SHA named in that section was not re-run.
   - Recommendation: pair the current 232-check harness with five negative fixtures.

7. **In-game behaviour.** **VERIFIED** by the `docs/*.md` and `README.md` search: no sentence says the 232 checks prove in-game eligibility, markers, spawns, or minimap behaviour. Nearby lines say the opposite (`docs/INTEGRATION-M1-28QUEST-2026-10-14.md:31`, `docs/PROJECT-HANDOVER.md:25`, `docs/NQ-PRIVATE-1203-PILOT-AND-INGAME-QA.md:14`, `docs/NQ-VALIDATION-M0.md` section 7).

8. **Comment, not a 232 count.** `cli/validate-335.lua:152` says the expectations are "public, curated values from PR #2, #6 and #7". The table also pins PR #8 and PR #13 (`:171-206`), which account for 20 of the 28 level records. **POTENTIAL ISSUE** for attribution. Recommendation: mention #8 and #13 in that comment when the file is next edited. This task does not edit it.

## 7. Limitations

**VERIFIED** from the harness and from this run.

M0 PASS is an effective-database comparison. It loads public Questie through `Questie-335.toc` with stubbed client APIs, runs the real correction callbacks, and compares fields. It does not prove in-game eligibility, markers, spawns, or minimap behaviour.

Also out of scope for these 232 checks:

- Headless-skipped UI files (the run notes `QuestieTracker.lua`, `TrackerMenu.lua`, `MessageHandler.lua`, `TrackerUtils.lua`). They are printed, not checked.
- Locale other than `enUS` (`GetLocale` is stubbed at `cli/validate-335.lua:77-78`).
- Individual Progression, conditions, SmartAI, live spawns, and SavedVariables.
- Whether referenced IDs 437, 1868, 1869, 4792, 1206, and 3853 exist as records (missing-reference class is 0).
- Private server data. None is read.
- The five negative fixtures. They must fail the harness. Their own `passes` counters are discarded when the process exits 1.

`docs/NQ-VALIDATION-M0.md` section 7 states the same headless limits for the earlier harness. That section does not use the number 232.

## 8. UNKNOWN and NOT TESTED

| Item | Label |
|---|---|
| Contents of the 22 faction overrides beyond "this ID must not be an N-Questie corrected quest". The check does not compare starter fields. | UNKNOWN |
| Whether quest 437, creatures 1868 and 1869, NPC 4792, quest 1206, and item 3853 exist in the loaded databases. Not a passing check. | UNKNOWN |
| `Questie.IsSoD` on this run. The override ID set matched the 22 Horde classic keys, so no extra quest override was present. | UNKNOWN for the flag; the ID set is VERIFIED |
| Historical runs cited as 89, 181, 183, or 230 checks, and the integration-plan trial's "3 rejections". | NOT TESTED |
| In-game eligibility, markers, spawns, minimap, tracker text, and colours. | NOT TESTED |
| GitHub Actions on the documentation commit that adds this file. The attached log is for `4111b097`, which does not contain this file. | NOT TESTED at the time this file was written |
| Any private aggregate or live realm database. | NOT TESTED, and not used |
