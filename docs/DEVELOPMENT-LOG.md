# N-Questie — Development Log

## 14 October 2026 — Revision guard CI enablement and Hillsbrad quest analysis

- Reviewed Grok's independently owned draft PR #12 CI-only correction revision guard: `cli/check-revision-bump.sh`, seven synthetic regression cases and proposed workflow. No runtime revision changes.
- Activated its proposed workflow as a **separate draft [PR #14](https://github.com/CosmicCuddle/N-Questie/pull/14)** stacked on PR #12, leaving #12 untouched. Real [GitHub guard workflow 38569424455](https://github.com/CosmicCuddle/N-Questie/actions/runs/38569424455) **PASSED**; existing overlay checks passed; inherited Busted `unit-tests` remains failing without independent unmerged #4. No merge, release or production changes.
- Investigated Hillsbrad quest 566 and 567 using the private offline world export and installed Questie source. Verified `MinLevel` discrepancy (566: Questie 17/server 35; 567: 17/19), while starter GO 1763/2008, ender NPC 2215, quest-level 40/28 and target item/NPC IDs match. Searched 17,701 exported `conditions` rows, found none directly referring to numeric quest IDs 566/567; other scripted conditions and IP state remain unknown. **No correction proposed or applied for these two** pending effective-DB/IP review. See [HILLSBRAD-WANTED-QUESTS-REVIEW.md](HILLSBRAD-WANTED-QUESTS-REVIEW.md).
- Grok owns M1 objective validation independently; no edits to its PR branches. The private world archive and full comparison workbook remain off public GitHub.

## 14 October 2026 — Duskwood and Wetlands quest-chain level review

Read-only verified the private AzerothCore world records, individual `PrevQuestID` links, creature/gameobject starters and enders, and original Questie level fields for Duskwood quests **225, 227, 228, 229, 231** and Wetlands quests **473, 464, 465, 474**. Quest 225's inherited TBC `requiredLevel=25` fix was explicitly included in the source comparison. No Questie quest objective, GO, NPC or chain field needs replacing in this narrow batch.

Staged the nine field-level, fail-closed WoW 3.3.5a numeric corrections in [draft PR #13](https://github.com/CosmicCuddle/N-Questie/pull/13); added synthetic Lua 5.1, real public Questie baseline Python tests, TOC, cache revision 4→5 and new [CLASSIC-CHAIN-LEVEL-AUDIT.md](CLASSIC-CHAIN-LEVEL-AUDIT.md). [Scoped CI PASS 38567305494](https://github.com/CosmicCuddle/N-Questie/actions/runs/38567305494). Inherited Busted tests still need independent PR #4. New corrections have **not** been tested in game.

Grok has simultaneously opened [draft #11](https://github.com/CosmicCuddle/N-Questie/pull/11) covering M0 validation of 19 level quests and [draft #12](https://github.com/CosmicCuddle/N-Questie/pull/12) covering CI-only cache revision guard. Sent the nine new source-verified IDs/values to Grok's PR #11 discussion; keep the combined 28-level validator in a separate integrated branch. See [COLLABORATION-INTEGRATION-STATUS.md](COLLABORATION-INTEGRATION-STATUS.md) for owners and dependencies.

No code merges, releases, N-Addon-Collection updates, installed WoW addon/SavedVariables modifications or live AzerothCore world changes. Full private SQL and comprehensive audit remain off public GitHub.

## 14 October 2026 — Early-zone level corrections, draft PR #8

- Individually cross-checked **11** early-game `MinLevel` / `QuestLevel` differences against the private offline world index and the installed Questie database. IDs: 98, 126, 169, 180, 249, 256, 304, 398, 442, 895, 6284.
- Opened [draft PR #8](https://github.com/CosmicCuddle/N-Questie/pull/8), stacked on PR #7, with `Compat/NQuestieReviewedEarlyQuestLevels.lua`, a 3.3.5a-only fail-closed callback, source-level Python checks, synthetic Lua 5.1 tests, TOC packaging and cache revision 3→4.
- [Scoped workflow 38562858874](https://github.com/CosmicCuddle/N-Questie/actions/runs/38562858874) **passed** on initial PR #8 head. Full inherited CI still needs the isolated PR #4 fixture repair and a reviewed integrated test branch.
- Grok delivered an independent read-only integration review and M0 effective-database-validation proposal (private communication). The reviewer found no blocking functional error in PR #6/#7 callback logic in their local 3.3.5a harness, but identified workflow risks: cache revision not automatically enforced, no real-335 CI integration, missing PR #4 in stack, and documentation ancestry conflicts from PR #2 to PR #3. M0 is assigned separately to Grok; do not overlap branch ownership.
- No in-game QA of these 11 quests yet, no live SQL or installed client changes, no merge, release, or N-Addon-Collection update.

## 14 October 2026 — Full installed Questie file and private world comparison

**Source confirmed:** `wotlkQuestDB.lua` uploaded from the installed addon is byte-identical (git blob `abbf2831b6d6b54b5d9383ba2c3e5cce5147379d`) to the GitHub original WotLK Questie file. It contains 9,086 records. The private exported AzerothCore world contains 9,525 records.

**Full read-only results:** 439 server-only quest IDs (many placeholders or unlinked; 18 appear to have starter and ender relationships without placeholder tags). Raw level differences: 139 `questLevel`, 150 minimum, 259 unique. After static literal Classic→TBC→WotLK correction interpretation: 270 candidate quests, 148 nominal fields and 154 minimum fields (some overlap). Initial 1,484 item-ID differences shrink to 24 for review after matching 1,460 to Questie's separate source-item representation. Additional NPC starter/ender, kill-objective and chain candidates require runtime/IP condition review.

**Deliverable:** Seven-tab **private Excel review workbook** prepared for the maintainer; kept off public GitHub. Public documentation records only aggregate statistics and methodology, see `docs/FULL-SERVER-QUEST-AUDIT-CHECKPOINT.md`. No runtime patches, SQL updates, installed addon edits or client QA in this step. PRs #6/#7 remain draft.

# N-Questie — Development Log

## 14 October 2026 — Private acore_world re-upload: quest 1203 and Dustwallow audit

**Input/privacy:** Maintainer uploaded a fresh private HeidiSQL acore_world.zip in chat. Read-only local inspection confirmed 9,525 unique server quest_template records. No raw SQL, host/server details, connection strings, or complete exported quest data have been committed to GitHub.

**Quest 1203:** Jarl Needs a Blade has server QuestLevel 35 and MinLevel 30 (same as stock WotLK Questie), but its required item is Moonsteel Broadsword (3853, quantity one), whereas Questie WotLK references Razorspine's Sword (33110). Jarl, the objective text, and prerequisite 1206 were verified locally. **Draft PR #6** proposes a fail-closed correction of item objective and objective text only, preserving the already-correct levels, quest chain and NPC links. Dedicated Lua 5.1 scoped checks passed [38554593796](https://github.com/CosmicCuddle/N-Questie/actions/runs/38554593796). No new in-game correction QA yet.

**Dustwallow comparison:** 134 server quest records for QuestSortID 15; 126 present in raw WotLK Questie, 8 absent (classification pending). Found **eight numeric quest-level/minimum-level differences**, plus **32 candidate required-item objective differences** (one is Jarl; 31 others require manual interpretation of source-item and scripted mechanisms). Direct Classic/TBC/WotLK literal correction inspection found no conflicting numeric level changes for those eight. **Draft PR #7** adds guarded, level-field-only patches for quests 1166, 1168, 1169, 1170, 1171, 1172, 1205 and 1252, preserving all unrelated quest fields; in-game test pending. See docs/DUSTWALLOW-QUEST-AUDIT.md.

**Remaining work:** Complete automatic *all-zone* discrepancy review, classify item-objective candidates, check quest-specific / Individual Progression conditions and character eligibility, and validate the fix through an approved backed-up QA build. Exact user character colour at quest 1203 was not independently established; do not claim changing item objectives fixes a colour symptom.

**Safety:** PR #5 audit and PR #6/#7 corrections are stacked **draft/unmerged**. Original private export and full comparison remain offline. Do not merge, release, update N-Addon-Collection, modify live DB/progression or replace installed Questie/SavedVariables without approval.

# N-Questie — Development Log

## 14 October 2026 — First known existing-quest mismatch and offline audit PR #5

**Maintainer report:** Jarl Needs a Blade displays incorrect quest information in the customised AzerothCore / Individual Progression environment; remaining differences should be discovered through systematic comparison.

**Verified public-source fact:** Quest 1203 (Jarl Needs a Blade, Dustwallow Marsh) has `requiredLevel = 30` and `questLevel = 35` in the inherited WotLK Questie Lua data. Direct examination of the stock Classic/TBC/WotLK numeric level correction tables found no entry for quest 1203. **The private current-world quest 1203 fields were not available to inspect in this chat**, so no replacement level has been asserted.

**Change:** Created [draft PR #5](https://github.com/CosmicCuddle/N-Questie/pull/5), stacked on PR #3. Added `tools/audit_world_quest_levels.py`, synthetic private-format tests and a dedicated import/QA guide. It scans an *offline* HeidiSQL ZIP/SQL export, compares `MinLevel` and `QuestLevel` against base Questie plus literal corrections and produces a **private review report outside the repository**. Can include quest 1203 explicitly or audit all quest IDs. Zero live database/character/addon mutations.

**Tests:** Scoped workflow [38551948617](https://github.com/CosmicCuddle/N-Questie/actions/runs/38551948617) passed synthetic audit fixtures and all existing overlay/generator checks on the earlier PR #5 commit. A further test was added against the real public Questie source file; its latest CI requires confirmation. **No private full-database comparison completed yet.**

**Limit:** Static corrections differ from runtime/individual-progression state. Field-level changes will require separate source verification, review, tests and game confirmation. No merge, release, Addon Collection edit or database upload authorized.

## 14 October 2026 — Existing-quest correction scope formally added

**Request:** Repair existing WotLK quest entries modified by the Naxxramas server and progression modules, including incorrect quest levels, colours, objectives and availability; not just missing custom quests.

**Source finding:** `QuestieLib:GetColoredQuestName` gets the quest's effective level from `GetTbcLevel` and applies `PrintDifficultyColor` against `QuestiePlayer.GetPlayerLevel()` (with `GetQuestGreenRange`). A stale Questie quest-level record can therefore cause a wrong red/green display. `requiredLevel` / `MinLevel` and server progression unlock rules must be audited separately.

**Decision:** Added Phase 2A to the roadmap. Start with **read-only mismatch reporting** and exact per-field correction approvals; preserve unrelated Questie fields. Do not alter colours artificially to match IP stage, assume IP makes a quest available, or publish the original private world SQL. Next obtain a specific discrepant quest ID and compare live observed colour/level to the server-sourced `QuestLevel` and current effective addon record.

**Tests / changes:** Documentation-only scope approval. No client, live database or character state edits; no claim that a quest-colour correction has been implemented or tested yet.

# N-Questie — Development Log

## 14 October 2026 — Importer deletion protection and isolated CI repair

**Latest verified gameplay (from draft PR #2):** Maintainer screenshots confirmed quest 2001 available at Shadow Priest Allister; Ravenclaw Servant/Champion kill-objective tooltips; completed turn-in state; and maintainer directly confirmed the quest marker disappears after normal hand-in. First custom quest visual-marker lifecycle **PASS**; exact active-spawn accuracy and individual kill-progress increments were not separately proven.

**PR #3 development:** The reviewed JSON-to-Lua generator now rejects overwriting an existing generated file if previously curated quest IDs would disappear, unless *each* removal is explicitly named using `--approve-removal-quest`. It also requires a higher data revision, refuses unrelated Lua outputs, and verifies exact approved quest/NPC ID sets. A synthetic test exercises partial-update refusal, wrong approval refusal and intentional removal. **Latest edited PR #3 code requires new CI verification.** The successful earlier [dedicated N-Questie run 38547219011](https://github.com/CosmicCuddle/N-Questie/actions/runs/38547219011) predates this safety follow-up.

**Independent CI repair PR #4:** [Full inherited CI run 38549456997](https://github.com/CosmicCuddle/N-Questie/actions/runs/38549456997) **PASS**: LuaCheck, Busted unit tests, Era/SoD/WotLK database validators; publication skipped appropriately. That success belongs to [draft PR #4](https://github.com/CosmicCuddle/N-Questie/pull/4) based on `335` and does not prove combined PR #2/#3/#4 CI.

**Safety/next:** Continue offline import validation and investigate safe source-verified second quest; do not publish original `acore_world.zip` or private JSON. Keep all PRs draft/unmerged, preserve installed addon and SavedVariables, and do not update N-Addon-Collection or release without approval.

## 14 October 2026 — Reviewed quest JSON-to-Lua generator (draft PR #3)

**Reason:** Reduce repetitive manual Lua editing when adding curated custom Naxxramas quests, without exposing the private acore_world export or guessing NPC spawn coordinates.

**Change:** Draft [PR #3](https://github.com/CosmicCuddle/N-Questie/pull/3) is stacked on draft PR #2 and introduces `tools/generate_custom_quests.py`, offline synthetic Python tests, dedicated CI coverage, and an import guide update. It requires the exact approved quest set, exact verified NPC set and an explicit cache revision before producing small, deterministic Lua output. It does not read or connect to the live server, and it does not change existing Questie Lua on the maintainer's machine.

**Evidence/status:** Newly submitted code, **CI outcomes to verify on PR #3**. No new in-game data: the verified Step 1 installation pass remains 5/5. Step 2 quest 2001 starter/objective/ender markers remain **NOT TESTED** until reported by maintainer. The inherited Questie CI continues to require separate triage.

**Safety:** Private review JSON/SQL/ZIP and server details are not included in commits. Any generated Lua must be reviewed before copying to the public curated overlay. NPC coordinates, progression rules and active phases cannot be verified by this generator. No merge, stable release, or N-Addon-Collection update authorized. Revert PR #3 to remove this proposed development change; the installed test addon is untouched.

**Next:** Run and inspect scoped CI; obtain in-game evidence on eligible quest 2001 or a different legitimately available custom quest; then expand verified NPC and gameobject mapping.

## 14 October 2026 — Maintainer's in-game installation checks: PASS (Step 1)

The maintainer installed the temporary N-Questie QA addon and reported **five explicit PASS results**:

- Character-selection AddOns list identifies N-Questie.
- Addon loads without Lua errors.
- Existing world-map Questie quest icons appear normally.
- Existing minimap quest-objective icons appear normally.
- Existing Questie settings and user preferences persist.

**Result:** This verifies baseline installation and visual/regression smoke behavior on the maintainer's client. It **does not** verify custom quest 2001 starter, kill/quest objective, or turn-in icons. No new SQL data was required, and no live database changes were made by development.

**CI:** Dedicated N-Questie overlay GitHub Actions workflow passed ([run 38461711184](https://github.com/CosmicCuddle/N-Questie/actions/runs/38461711184)); broader inherited GitHub CI failed ([run 38461710869](https://github.com/CosmicCuddle/N-Questie/actions/runs/38461710869)) on upstream Busted test setup. Both must be resolved/reviewed before merge.

**Next:** Ask which legitimate character can accept custom quest 2001 (quest 437 prerequisite); if unavailable, select an accessible real server quest. Carry forward the install QA PASS and record each additional tested marker separately. No merge, release or N-Addon-Collection change without explicit approval.

## 13 October 2026 — Initial N-Questie overlay implementation (unreleased)

**Approval:** The maintainer explicitly authorized publishing the limited server quest IDs, names, NPCs, objectives and map coordinates required by N-Questie. The **full `acore_world.zip` remains private**.

**Source-backed trial:** Quest 2001 (`Ravenclaw Cleanup`, level 12/16, Silverpine Forest zone 130) references NPC 2121 as starter/ender, NPC 1868 and 1869 as eight-kill objectives, prerequisite quest 437, server race mask 690 and quest flag 8. Existing raw Questie WotLK NPC data already has those NPC IDs and their zone 130 spawn positions; no new map coordinates were inferred.

**Prototype:** Added `Compat/NQuestieCustomQuestData.lua` containing only curated data, `Compat/NQuestieCustomQuestLoader.lua` registering quest and reverse NPC corrections without erasing existing NPC quests, and added those files to the original TOC. Updated `Modules/QuestieInit.lua` to recompile the cached DB after the custom data revision changes, without resetting SavedVariables. The installed TOC name remains `Questie-335.toc`; its display title is N-Questie and test version is `9.5.1.1`.

**Importer:** Added `tools/export_world_quests.py` to read one private SQL or ZIP export and extract **only nominated quest IDs** into a review-only JSON file; unsupported gameobject quests/objectives, negative prerequisites or missing NPC links fail closed. The tool does **not** yet automatically convert JSON into the curated Lua file, nor calculate replacement spawn coords. Added Lua 5.1 mock and Python fixture tests, plus a focused GitHub Actions workflow (runs not yet observed on this fork).

**Not yet validated:** In-game starter/kills/turn-in icons, active spawn/phase accuracy, manual/progression eligibility, any full GitHub CI success, broader quest import and packaging. No release and no merge has been approved. Back up the current Questie addon folder and Questie SavedVariables before any in-game build.

**Next:** Review feature PR, run tests/enable Actions if necessary, prepare a safely packaged single-addon QA build and test quest 2001 in-game. Keep the full database and any secrets off public GitHub.

## 13 October 2026 — Private world database intake

**Input:** Maintainer supplied a ZIP containing a HeidiSQL export of the Naxxramas AzerothCore `acore_world` database. This is private source material, **not** a public repository file.

**Inspection:** Locally and read-only verified the presence and structure of quest definitions, quest addon data, NPC/gameobject quest starter/ender links, NPC/gameobject templates, spawn records, quest POI records, conditions and SmartAI scripts. Conducted a preliminary ID and relationship comparison against the maintainer's original Questie-335 ZIP. The private audit is provided directly to the maintainer, not committed to public GitHub.

**Limit:** Raw Questie source comparisons can flag candidates but cannot prove current in-game availability or map accuracy: runtime correction layers, phase/spawn conditions, scripted quest objectives, database caching and map transforms still require inspection. Do not import everything automatically before this is validated.

**Privacy:** Neither the SQL archive, server host metadata, nor server-derived quest records/spawn coordinates have been uploaded to GitHub. Before adding generated custom quest data to the **public** N-Questie repository, obtain explicit maintainer approval about publishing quest IDs, NPC/object IDs and map coordinates.

**Next:** Build a generic reproducible importer and tests without sensitive fixtures; then use one verified real quest to prove starter/objective/turn-in markers. Back up the installed addon and SavedVariables before any in-game test.

## 13 October 2026 — Repository established and architecture reviewed

**Decision:** Name the customised fork **N-Questie**, retaining `Questie-335` as the installed addon/TOC identity initially for compatibility. Work from `CosmicCuddle/N-Questie` and its `335` branch (fork parent `divial28/Questie-335`).

**Verified source:** TOC targets WoW 3.3.5a `30300`, records upstream addon v9.5.1 and SavedVariables `QuestieConfig`/`QuestieConfigCharacter`. Source defines separate quest, NPC, object and item tables, plus a `QuestieCorrections` loader for WotLK corrections. Existing CI is inherited but no N-Questie test result has been accepted.

**User goal:** Improve map/minimap quest icons for this customised AzerothCore server, especially allow new or modified quests to be added in a straightforward, repeatable workflow. Initial emphasis: icons for quest starters and turn-ins before attempting full objective automation or progression-aware filtering.

**Implementation today:** Planning/documentation only, on a new feature branch. No runtime Lua, TOC, NPC/quest/SQL data, installed addon, SavedVariables or N-Addon-Collection was edited. An example real missing quest is still required before implementing data.

**Next:** Get a quest ID; inspect narrowly scoped read-only `world` records and exact spawn map/coordinates. Design a deterministic, isolated quest overlay, validate loader/compiled DB behavior and test in game.

**Safety:** Back up installed `Questie-335` and applicable SavedVariables first. Preserve all upstream history, original credits and compatible files. Do not merge/release without maintainer review.

## Entry format for future changes

- **Reason:** What the maintainer observed or requested.
- **Source evidence:** GitHub file/commit, SQL table/query excerpt or in-game screenshot.
- **Change:** Branch/PR, exact files, behavior and compatibility guarantees.
- **Tests:** Automated and in-game outcomes, stating **not run** where appropriate.
- **Rollback:** Addon/SavedVariables backup and commit revert steps.
- **Next:** Highest-priority unresolved item.
