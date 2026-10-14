# N-Questie — Validation M0: Effective Questie Database Validation

**Date:** 14 October 2026
**Status:** Implemented on draft branch `feat/nq-validation-m0-2026-10-14`. Not merged. No in-game proof.
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

## 6. Cache revision safeguard (proposal only, not implemented)

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
