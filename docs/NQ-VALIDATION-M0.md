# N-Questie — Validation M0: Effective Questie Database Validation

**Date:** 14 October 2026
**Status:** Implemented on draft branch `feat/nq-validation-m0-2026-10-14` (PR #9). Workflow enabled by PR #10; GitHub run 38565400913 passed. Combined coverage with PR #8 on `feat/nq-validation-m0-pr8-integration-2026-10-14` (§9). Not merged. No in-game proof.
**Owner:** Grok Bot (validation workstream)
**Base:** PR #7 head `d1580bbf91cba731a7532489122802b294c59e83` (stacked on #7; the inherited Busted job depends on PR #4)
**Approval:** M0 approved by the maintainer, 14 October 2026

## 1. What M0 delivers

| Item | File |
|---|---|
| 3.3.5a effective-DB harness | `cli/validate-335.lua` |
| Synthetic fault fixtures (negative tests) | `tests/fixtures/validate335/*.lua` |
| Negative-test runner | `tests/test_validate_335_fixtures.sh` |
| CI workflow (**proposed, not active**) | `docs/proposed-workflows/nquestie-validate-335.yml`. Copy it to `.github/workflows/` to enable. The review token cannot push workflow files (GitHub requires the `workflow` OAuth scope), so the maintainer must add it. |
| Private-output ignores | `.gitignore` (`private/`, `*.validation.json`, `*.validation.csv`, `validation-report*`) |
| Review and design docs | `docs/REVIEW-2026-10-14.md`, `docs/VALIDATION-DESIGN-2026-10-14.md` |

No N-Questie correction file, `QuestieInit.lua`, the TOC, the revision system or any other developer's file was changed.

## 2. Implementation decisions

| Decision | Reason |
|---|---|
| Start from `cli/validate-wotlk.lua`, but load `Questie-335.toc` with `GetBuildInfo` returning `"3.3.5", "12340", …, 30300` and `GetAddOnMetadata` returning `X-WOW_PROJECT_ID = 11` and `Version = 9.5.1.1` | This selects the real 3.3.5a branches: `QuestieCompat.Is335` and `QuestieCorrections.lua:312` `QuestieCompat.LoadCorrections(...)`. Questie-WOTLKC.toc and build 30400 are not used. |
| Load the correction and blacklist registry from `Compat/Compat.lua` **by text section** (from `local correctionsRegistry = {}` to `function QuestieCompat:ADDON_LOADED`) instead of the whole file | The rest of Compat.lua needs a live client UI. The registry code that runs is the repository's own, and it is located by anchor text rather than line numbers, so it fails loudly if the anchors move. |
| Run `Compat/Corrections.lua` straight after `Modules/QuestieCompat.lua`, mirroring `Compat/embeds.xml` | The TOC loader skips `.xml` lines. This keeps the real registration order: inherited 335 compat corrections first, then the N-Questie files at TOC lines 88–91. |
| Snapshot every quest, NPC, object and item record **immediately before the first N-Questie callback**, and again when `QuestieCompat.LoadCorrections` returns | Isolates exactly the N-Questie window. Classic, TBC and WotLK layers and the 335 compat corrections are already applied in the "before" state, and the faction inference after `LoadCorrections` is excluded. |
| Per-field comparison of deterministic serialisations (sorted keys, `%.17g` numbers, `%q` strings) plus a 32-bit rolling hash (`h*33+byte mod 2^32`) per database | Exact field-level diffs with no `bit` library or 64-bit integers needed, so it is safe on Lua 5.1. The hash is printed so changes in DB state are easy to spot between runs. |
| Allow-list of (database, id, field): `questData` 2001 = new record; 1203 = fields 8, 10; each Dustwallow ID = field 5, plus field 4 only where its minimum level changes; `npcData` 2121 = fields 10, 11 | Any other difference fails, including new or removed records. |
| Per-quest expected values (`{before req, before lvl, after req, after lvl}`) checked against both the before snapshot and the result | Replaces PR #7's identical synthetic fixtures with real-DB checks per quest. |
| After the correction checks, run `QuestieDBCompiler:Compile` and read the values back through `QuestieDB.QueryQuestSingle` | Proves the values survive the real compiler. |
| Callbacks from `Compat/NQuestie*` are wrapped: a non-table return is a failure | Catches broken correction modules early. |
| Fault injection via `NQ_VALIDATE_FIXTURE` (applied after TOC load, before `Initialize`) and `NQ_VALIDATE_SKIP_COMPILE=1` | Negative tests use the same code path, and run faster without the compile step. |

## 3. Assertions

| Target | Checks |
|---|---|
| Environment | `Is335 == true`, `IsWotlk == true`, ≥4 N-Questie registrations, `questKeys` indices match (name 1 … questFlags 23). No load errors in `Database/`, `Compat/`, `QuestieInit` or `QuestieCompat` (headless-only UI files are listed but allowed). |
| Quest 2001 | Absent before; present after with name "Ravenclaw Cleanup", 12/16, zone 130, races 690, flags 8, startedBy and finishedBy `{{2121}}`, pre `{437}`, objectives `{{{1868},{1869}}}`. NPC 2121 questStarts and questEnds include 2001. |
| Quest 1203 | Item objective `{{3853}}` (exactly one). Text contains "Moonsteel Broadsword". Levels 30/35. startedBy `{{4792}}`, pre `{1206}`, exclusiveTo unchanged. Objective slots 1, 2, 4, 5, 6 identical. The original objectives table is not mutated. |
| Dustwallow ×8 | Base levels equal the expected Questie values. Results per ID: 1166/1168/1169/1170/1171 → 38/43, 1172 → 38/45, 1205 → 35/45, 1252 → 30/40. |
| Preservation | 0 unexpected field changes, new records or removed records across all four databases |
| Compiled | 1203 30/35 with item 3853, 2001 name, and all 8 Dustwallow levels, read back after compile |

## 4. How to run

```bash
# once: Lua 5.1 + LuaRocks + bit32 (same requirement as cli/validate-wotlk.lua)
luarocks --lua-version=5.1 install bit32
lua5.1 cli/validate-335.lua                  # full run, exit 0 on pass
bash tests/test_validate_335_fixtures.sh     # negative tests, exit 0 when every fault is caught
LUA=lua bash tests/test_validate_335_fixtures.sh   # if the interpreter is called "lua"
```

## 5. Local results (14 Oct 2026, ~13:30–14:00 BST, Lua 5.1.5)

| Check | Result |
|---|---|
| `lua5.1 cli/validate-335.lua` | **PASS, 89 checks**, ~9–17 s wall time including compile |
| Record counts and hashes before → after | quest 9158 `f84abb0a → 3d70d4e6`; npc 29615 `d6e37a01 → 46c35e05`; object 13043 `8082022e` unchanged; item 36767 `441bb1af` unchanged; 0 unexpected changes |
| `tests/test_validate_335_fixtures.sh` | **3/3 rejected with the expected message:** corrupted correction → "1203 item objective is 3853" (plus "returned string, expected table"); unexpected field → "not allow-listed" (1203 questLevel, 1173 name); missing quest → "quest 2001 missing after corrections" |
| `luac5.1 -p` on harness and fixtures | OK |
| `luacheck cli/validate-335.lua tests/fixtures/validate335/` | 0 warnings / 0 errors |
| `luacheck Database Localization Modules Questie.lua` | 2 warnings without the CI `--globals` args (pre-existing `WorldMapFrameTitle`, `QuestLogScrollFrameScrollBar`, which PR #2 and #4 already address). 0 with them (see the review). |
| Existing `tests/test_nquestie_*.lua` (3) | all PASS |
| Busted on this branch alone | 0 / 0 / **9 errors** (`QuestieCompat` nil, inherited, fixed by PR #4) |
| Busted on a throwaway merge of this branch + PR #4 | **18 successes / 0 failures / 0 errors**. The throwaway branch was deleted and never pushed. |

The new workflow is not active yet (see §1), so GitHub CI does **not** run this harness on the draft PR. Only the existing workflows run there. The inherited "CI" workflow is expected to keep failing on this branch until PR #4 is in its ancestry.

## 6. Cache revision safeguard (layer 1 implemented as a CI-only check on `feat/nq-revision-bump-guard-2026-10-14`; layer 2 deferred, see §9.5)

**How it works today:** `Modules/QuestieInit.lua` (PR #2) reads `rawget(_G, "NQuestieCustomQuestData").revision` (default 0) and adds `Questie.db.global.nQuestieDataRevision ~= nQuestieRevision` to the recompile condition. It stores the revision after `QuestieDBCompiler:Compile()`. `revision` lives only in `Compat/NQuestieCustomQuestData.lua` (#2 = 1, #6 = 2, #7 = 3). Changing `NQuestieExistingQuestCorrections.lua`, `NQuestieReviewedQuestLevelCorrections.lua` or the loader without bumping it leaves existing installs on the old compiled DB. The TOC version stays `9.5.1.1`, so `dbCompiledOnVersion` does not trigger a rebuild either.

**Proposal, two layers, both CI-only, no runtime change:**

1. **File-change guard (simple, cheap).** On pull requests, run `git diff --name-only <merge-base>...HEAD -- 'Compat/NQuestie*.lua' 'Questie-335.toc'`. If anything is listed, require `revision` in the head to be greater than in the merge base, or else fail with "N-Questie correction changed without a revision bump". Comment-only edits will also trip the guard, which is acceptable, because a bump costs only one extra recompile for players.
2. **Effective-content guard (catches semantic changes regardless of file).** `cli/validate-335.lua` already computes the post-correction `questData` and `npcData` hashes. Commit a small manifest, for example `cli/validate-335-revision.lua` returning `{revision = 3, questData = "3d70d4e6", npcData = "46c35e05"}`, and fail CI if the hashes differ while `revision` is unchanged. This also catches changes that arrive through upstream correction files. The manifest is updated in the same commit as the revision bump.

A runtime content hash inside the addon is not recommended. The client cannot read addon files, and hashing the full DB at login costs time on every load.

The lead developer owns the revision system. This proposal needs their agreement before anyone implements it.

## 7. Limitations

- **No in-game proof.** Headless Lua with stubbed APIs. Quest log text, map pins, the tracker and colours are not exercised.
- **Login timing:** `coroutine.yield` is a no-op here, so frame-split initialisation, `/reload` during compile and SavedVariables persistence are not tested.
- **Locale:** enUS only. `l10n:Initialize()` runs after corrections in the addon and replaces `objectivesText` on other locales (review C5).
- **Individual Progression and server scripts:** availability decided by IP stage, `conditions` or SmartAI is invisible to the harness.
- **Headless-skipped files:** four UI modules (tracker, message handler) fail to load headless. They do not affect the DB path, but they are not covered.
- **Allow-list maintenance:** every new approved correction must add its (id, field) pairs, otherwise CI fails. This is intended.
- **Runtime:** ~10–20 s for the main run and ~40 s for the three negative runs on a developer machine.

## 8. Next (M1, not started)

Export the effective records to local JSON under `private/` for the Python validator, add rule-catalogue fixtures, and add a schema check for the private export. See `docs/VALIDATION-DESIGN-2026-10-14.md` §5.

## 9. Combined coverage with PR #8 — 14 October 2026

**Branch:** `feat/nq-validation-m0-pr8-integration-2026-10-14`, created as PR #10 head `85158369` (which contains #9 `463bd1c8` and the active workflow), merged with PR #8 head `93981f5f`. No PR branch was changed. Merge conflicts: none (`docs/ROADMAP.md` and `docs/PROJECT-HANDOVER.md` auto-merged).

### 9.1 Harness changes

| Change | Detail |
|---|---|
| Level table | `LEVEL_CORRECTIONS` keeps 8 Dustwallow rows (PR #7). The 11 early-zone rows (PR #8) are added automatically when `Compat\NQuestieReviewedEarlyQuestLevels.lua` is in `Questie-335.toc`. Each row holds its own original and corrected min/quest level. |
| Allow-list | Only fields that actually change. 169, 180, 256, 398, 895 and 6284 allow `requiredLevel` only; 98, 126, 249, 304 and 442 allow `questLevel` only. The unchanged field is asserted equal to its original. |
| Count guard | `NQ_VALIDATE_EXPECT_LEVEL_COUNT=19` makes the run fail unless exactly 19 level corrections are asserted |
| Compiled round trip | For **every** quest (9,158 × 9 fields: levels, preQuestSingle/Group, exclusiveTo, nextQuestInChain, parentQuest, startedBy, finishedBy), the compiled value must equal the source table handed to the compiler, after normalising the compiler's `0`/`{}`/`nil` encodings. |
| Runtime overrides | `QuestieDB.questDataOverrides` (22 entries from inherited code) are set aside for the round trip. The run fails if any override targets 2001, 1203 or a level-corrected quest, because an override would hide the N-Questie value in game. |
| New negative fixture | `early_level_wrong_value.lua` sets quest 169's minimum level to 16. It must fail with "PR #8 quest 169 requiredLevel 15". |

### 9.2 PR #8 value check

`Compat/NQuestieReviewedEarlyQuestLevels.lua` at `93981f5f` matches the maintainer's table for all 11 quests (98 22/32→22/35, 126 15/21→15/25, 169 11/26→15/26, 180 11/26→15/26, 249 20/26→20/27, 256 9/22→17/22, 304 26/31→26/34, 398 4/10→6/10, 442 10/20→10/24, 895 9/16→11/16, 6284 12/21→15/21). The original values also match the public WotLK DB after inherited corrections, so every source guard is satisfied. **No mismatches.**

### 9.3 Local results (Lua 5.1.5, about 14:00–14:30 BST)

| Check | Result |
|---|---|
| `NQ_VALIDATE_EXPECT_LEVEL_COUNT=19 lua5.1 cli/validate-335.lua` | **PASS, 181 checks.** 19 level corrections plus 1203 and 2001. 0 unexpected changes (quest 9158 `f84abb0a → 777f7cba`, npc `d6e37a01 → 46c35e05`, object and item unchanged). Compiled round trip: 82,431 fields, 0 mismatches. |
| Negative fixtures | **4/4 rejected** with the expected messages (corrupted correction, missing quest, unexpected field, early-level wrong value) |
| `tests/test_nquestie_*.lua` | 4/4 PASS (including PR #8's early-level test) |
| `tools/test_*.py` | 4/4 exit 0 |
| luacheck (harness, fixtures, PR #8 module) | 0 warnings / 0 errors |
| Busted on the branch alone | 0/0/9 errors (inherited; needs PR #4) |
| Busted on a throwaway merge with PR #4 | 18 / 0 / 0 |

### 9.4 CI requirements and limitations

- **PR #4 dependency:** the inherited `CI` workflow's Busted job fails on every stacked branch until PR #4 is in the ancestry. That failure is expected and is not caused by this work.
- **Workflow scope:** the review token cannot create or modify files under `.github/workflows/`. This branch only carries PR #10's workflow unchanged, through its existing commit. New workflow steps are proposed under `docs/proposed-workflows/`.
- **Runtime:** about 17 s for the main run and about 15 s per negative fixture on a developer machine.
- The harness is headless (see §7). A CI pass is not an in-game pass.

### 9.5 Revision safeguard

**Layer 1 (CI-only, implemented on its own branch):** `cli/check-revision-bump.sh` checks for changes between the merge base and HEAD. If any of the following changed, then `NQuestieCustomQuestData.revision` must be strictly greater than at the merge base:

- `Compat/NQuestie*.lua`
- the `Compat\NQuestie*` lines in `Questie-335.toc`

Synthetic temporary git repos test four cases:

- a change without a bump fails
- a change with a bump passes
- an unrelated change passes
- a TOC-only change without a bump fails

**Layer 2 (deferred):** fingerprint the effective corrected data (the harness hashes) against a committed manifest. It is deferred until the lead developer agrees on the manifest format and ownership.

The runtime revision mechanism in `Modules/QuestieInit.lua` is unchanged.

### 9.6 Branch dependency map (documented, not resolved)

```
335 ── #1 ── #2 ─╳─ #3 ── #5 ── #6 ── #7 ─┬─ #8 (early levels, lead dev)
                 (#3 lacks 9 docs commits │
                  from #2; unresolved)    ├─ #9 (M0) ── #10 (workflow)
                                          └─ revision guard branch (this round)
335 ── #4 (Busted/luacheck repair, unmerged; needed by every inherited CI run)
integration branch = #10 (+#9) merged with #8
```

### 9.7 Issues found this round

- The compiler stores absent fields as `0`/`{}`. Comparisons must normalise, otherwise you get 16,450 false mismatches.
- 22 inherited runtime `questDataOverrides` change `startedBy`/`exclusiveTo` at query time, on top of the compiled data. None touch N-Questie quests today. The harness now guards this.
- PR #8 also modifies `.github/workflows/nquestie-overlay.yml`. Merging #8 needs a maintainer token with workflow scope.

### 9.8 Recommended next steps for M1 (not started)

1. Export the normalised effective records (the round-trip baseline) to local JSON under `private/` for the Python validator.
2. Start the rule catalogue with item and kill-credit rules plus synthetic fixtures. Quest 1203 is the anchor.
3. Agree with the lead developer how the harness allow-list is maintained when new correction modules land. One option is for each module to export its own expected table.
4. Decide the layer-2 fingerprint manifest.
