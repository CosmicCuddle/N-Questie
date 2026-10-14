# N-Questie — Development Roadmap

## Combined M1 integration milestone — 14 October 2026

- [x] Review Grok's M1 safety fixes and their completed local QA evidence ([draft #18](https://github.com/CosmicCuddle/N-Questie/pull/18)); require explicit complete creature KillCredit and no false one-to-one pairing.
- [x] Open [draft #20](https://github.com/CosmicCuddle/N-Questie/pull/20) on a separate branch from #19/#16 combining the report-only M1 rule engine and strict 28-quest M0 compiled database harness, preserving all 5 negative fixtures and the revision guard.
- [x] Initial [M1 GitHub 38580760515](https://github.com/CosmicCuddle/N-Questie/actions/runs/38580760515) green: 29 synthetic scenarios, 25 rules, 31 Busted tests; initial overlay and revision guard green.
- [x] Verify **all five** GitHub workflows on the PR #20 integrated source-and-documentation head `4470f3657483dfcdee08a080f22f258f6c1a51bd`: [M1 38581451391](https://github.com/CosmicCuddle/N-Questie/actions/runs/38581451391), [M0 38581451396](https://github.com/CosmicCuddle/N-Questie/actions/runs/38581451396), [overlay 38581451217](https://github.com/CosmicCuddle/N-Questie/actions/runs/38581451217), [revision 38581451165](https://github.com/CosmicCuddle/N-Questie/actions/runs/38581451165), [full inherited CI 38581451178](https://github.com/CosmicCuddle/N-Questie/actions/runs/38581451178), all PASS. Recheck any newer docs-only head before claiming it is also green.
- [ ] Agree Grok-owned **M2.1 strict input schema and validator** and **M2.2 compiled effective quest-record export**, with the lead adapting the private local exporter only afterward.
- [ ] Perform one private M2 pilot on quest 1203 before any batch of 24 item / 151 NPC discrepancies. Do not treat manual-review findings as approved corrections.
- [ ] Reconcile PR #2/#3 missing documentation ancestry with a separate approved plan and complete backed-up in-game QA before any merge/release.

**Current integration handover:** [INTEGRATION-M1-28QUEST-2026-10-14.md](INTEGRATION-M1-28QUEST-2026-10-14.md).

## M2 private intake foundation — 14 October 2026

- [x] Prepare **local-only selected quest objective exporter** (no SQL/code/report uploaded to GitHub): 12 synthetic Python tests passed; offline quest 1203 + quest 2001 records read successfully.
- [x] Require explicit tri-state `"unknown"` flags for unverified conditions, IP gates and scripted credits; never assert `killCreditComplete=true` from selected creature rows alone.
- [x] Record privacy and M2 interface handover in [draft PR #19](https://github.com/CosmicCuddle/N-Questie/pull/19) / [M2 intake contract](M2-PRIVATE-OBJECTIVE-INTAKE-HANDOVER.md), without touching Grok's implementation branch.
- [ ] Await Grok's **PR #18** pending negative-test, Python and full Busted-with-#4 verification; review final M1 regression evidence.
- [ ] Coordinate Grok-owned **M2.1** input schema and **M2.2** 3.3.5a effective-record exporter before converting broad private data.
- [ ] First report-only trial on known quest 1203, then a small reviewed mixed item/NPC/GO batch. No automatic correction generation.
- [ ] Keep full private database and all generated per-quest reports outside public GitHub; only approved aggregates in the project docs.

## Combined 28-quest test milestone — 14 October 2026

- [x] Create [draft PR #16](https://github.com/CosmicCuddle/N-Questie/pull/16), new testing-only branch from #13 integrating M0, the CI revision guard and the inherited test fixture repair without touching existing PR branches.
- [x] Extend strict M0 allow-list and pre/post/compiled-readback assertions to **all 28** reviewed quest level corrections; maintain exact per-field permissions.
- [x] [GitHub M0 validation 38571850030 PASS](https://github.com/CosmicCuddle/N-Questie/actions/runs/38571850030): 230 checks, 82,431 compiled fields, zero mismatches; five negative fixtures rejected, including a bad quest 225 minimum.
- [x] [GitHub revision guard 38571850279 PASS](https://github.com/CosmicCuddle/N-Questie/actions/runs/38571850279) after making test invocation independent of copied executable-file bits.
- [x] Verify the same PR #16 source head had **all four GitHub checks green**: [M0 38573190612](https://github.com/CosmicCuddle/N-Questie/actions/runs/38573190612), [revision 38573190572](https://github.com/CosmicCuddle/N-Questie/actions/runs/38573190572), [overlay 38573190614](https://github.com/CosmicCuddle/N-Questie/actions/runs/38573190614), [full inherited CI 38573190617](https://github.com/CosmicCuddle/N-Questie/actions/runs/38573190617). Newer documentation commits require rerun as usual; green CI is not permission to merge.
- [ ] Resolve PR #2/#3 nine-document-commit ancestry gap with a coordinated, separately approved plan; keep quest 2001 QA evidence.
- [ ] Do not merge or release until maintainer authorises the order, backups and game-client tests for markers, prerequisites, cache persistence, IP stage and locale.

**Full integration handover:** [INTEGRATION-28-QUEST-VALIDATION-2026-10-14.md](INTEGRATION-28-QUEST-VALIDATION-2026-10-14.md).

## Next integration gates — 14 October 2026

- [x] Activate Grok's reviewed CI-only cache revision-bump guard via separate draft [PR #14](https://github.com/CosmicCuddle/N-Questie/pull/14) without editing Grok's PR #12; first [revision guard CI 38569424455 PASS](https://github.com/CosmicCuddle/N-Questie/actions/runs/38569424455).
- [x] Privately investigate Hillsbrad quest 566/567 static `MinLevel`, GO starters, NPC turn-ins and target IDs. Document as *candidate differences only* in [HILLSBRAD-WANTED-QUESTS-REVIEW.md](HILLSBRAD-WANTED-QUESTS-REVIEW.md).
- [ ] Revisit 566/567 only after effective 3.3.5a record checks and IP/object/recipient conditions review; no auto-patching based on raw minimum levels.
- [ ] Coordinate PR #12/14 revision guard into a reviewed integration branch containing the **28** quest-level changes (#7/#8/#13), Grok's M0 harness and PR #4 Busted fix. A green isolated guard run is not combined CI.
- [ ] Continue Grok's independently assigned M1 objective-validation development, and preserve private source data, separate branches and maintainer merge/release approval.

## Latest multi-developer milestone — 14 October 2026

- [x] Stage **nine** source-verified Duskwood Mor'Ladim / Wetlands Nek'rosh chain level corrections in [draft PR #13](https://github.com/CosmicCuddle/N-Questie/pull/13), stacked on #8; objective, chain, starter/ender and GO metadata unchanged. See [Classic chain audit](CLASSIC-CHAIN-LEVEL-AUDIT.md).
- [x] Run current PR #13 scoped Lua 5.1 / original-Questie level baseline regressions: [38567305494 PASS](https://github.com/CosmicCuddle/N-Questie/actions/runs/38567305494).
- [x] Record Grok-owned draft #11 (integrated M0 covering **19** level corrections) and draft #12 (CI-only revision guard); keep Grok branch ownership intact.
- [ ] Expand M0 to the **28** level corrections across #7/#8/#13 in a separately coordinated draft integration PR. Do **not** disable strict unchanged-field checks.
- [ ] Resolve independent inherited fixture repair #4 and the #2→#3 docs ancestry conflict, then validate combined GitHub CI.
- [ ] Back up original installed Questie and SavedVariables before any approved in-game QA. No merges/releases until authorised.

**Current cross-developer status:** [COLLABORATION-INTEGRATION-STATUS.md](COLLABORATION-INTEGRATION-STATUS.md). Raw private world data and full mismatch workbook remain outside public GitHub.

## Immediate status — 14 October 2026 (PR #8 / external M0)

- [x] Curate 11 early-zone existing-quest level fixes into [draft PR #8](https://github.com/CosmicCuddle/N-Questie/pull/8), stacked on PR #7, with Lua 5.1 and public database-source guards.
- [x] Verify PR #8's initial dedicated overlay workflow [38562858874](https://github.com/CosmicCuddle/N-Questie/actions/runs/38562858874) passed.
- [ ] Wait for Grok's independent M0 real 3.3.5a database-loading validation in a **separate draft PR**; review and integrate only with maintainer approval.
- [ ] Coordinate repair for the independent PR #4 inherited test harness and #2/#3 document ancestry, then re-run **combined** CI before any merge.
- [ ] Back up installed addon and SavedVariables before later manually authorized in-game testing of PR #6, #7 and #8 corrections.
- [ ] Continue private all-server discrepancy triage and IP-specific gating checks; no bulk replacements from the 270 candidate list.

**Updated:** 13 October 2026  
**Baseline:** forked `divial28/Questie-335`, branch `335`, upstream addon v9.5.1.  
**Status:** First custom quest 2001's tested visual marker lifecycle PASSED in-game. PR #3's approved offline generator has additional safeguards pending latest CI. PR #4's standalone inherited full CI is PASS but not integrated. No merges or releases authorized.

## Phase 0 — Foundation and safety

- [x] Establish `CosmicCuddle/N-Questie` from the selected 3.3.5a source fork; retain branch `335`.
- [x] Confirm addon loader, database sources, correction layer and SavedVariables names in source.
- [x] Document safe backups, release boundaries, proposed import data contract and maintainer handover.
- [ ] Finish attribution/licence review for any redistributable custom Questie package; retain original credits.
- [ ] Verify baseline addon behaviour and current warnings in-game without modifying saved settings or quests.
- [ ] Determine whether baseline fork CI is applicable/passable or needs scoped 3.3.5a checks.

## Phase 1 — Reliable custom quest starter/ender map icons

- [x] Identify quest 2001 — Ravenclaw Cleanup as missing from Questie's raw WotLK quest table; its NPC giver, ender and kill target IDs were obtained from the private read-only world export.
- [ ] Confirm quest 2001 is available to a suitable character in-game; its missing marker must be reproduced before claiming a fix.
- [ ] Inspect **read-only** `world` quest starter/ender and spawn data; detect server-specific NPC/object or quest ID differences.
- [x] Implement first **unmerged** N-Questie-specific quest/NPC correction overlay, separate from generated WotLK tables, with cache revision invalidation.
- [ ] Validate in actual WoW 3.3.5a and refine unsupported cases.
- [ ] Verify correction loading order, compiled-DB invalidation/rebuild behavior, map conversion and marker filters.
- [ ] Add tests for custom IDs, malformed data rejection, duplicate-safe merges and optional hide/availability rules.
- [ ] Test one quest icon on the world map and minimap; preserve vanilla quest behavior.

**Acceptance:** A confirmed, available custom quest displays its correct start and end markers at real NPC/gameobject spawn locations; unrelated native quests still display as before. Markers must not appear on unrelated maps.

## Phase 2 — Simple future quest additions

- [ ] Create a versioned, human-readable custom quest manifest supported by a validation/generation script (format to be selected after the first proven quest).
- [x] Add initial Python read-only HeidiSQL SQL/ZIP extractor for **selected quest IDs** and JSON review output; deliberately reject unsupported NPC/objective situations.
- [ ] Convert reviewed JSON into curated Lua automatically (currently one small manually-reviewed Lua record).
- [ ] Validate referential integrity across quest IDs, starters, enders and spawn source records, including zones/maps.
- [ ] Support add/update/remove from a single manifest; generated Lua deterministic and reviewable.
- [ ] Require explicit record provenance and prevent silent overwrites of unrelated base quests.

**Acceptance:** Add one additional server quest through the documented manifest with no manual edits to large upstream generated database files.

## Phase 2A — Corrections for existing WotLK quests (added 14 October 2026)

**Full-server audit intake completed:** Exact installed quest database source verified (9,086 records; matches GitHub blob). Compared all 9,525 private world quest templates. Identified 270 level candidate quest IDs after static literal correction-layer approximation, 24 unresolved item objective cases after source-item normalization, and 18 linked non-placeholder server quest IDs missing from stock Questie. See `docs/FULL-SERVER-QUEST-AUDIT-CHECKPOINT.md` (aggregates only). Private seven-tab workbook delivered to maintainer separately; no private world export committed.

- [x] Compare full installed WotLK Questie database file with all private AzerothCore quest templates (read-only).
- [x] Explain standard source-item objective representation to eliminate 1,460 false positive item mismatches.
- [ ] Triage 270 numeric candidates against live client effective corrections and IP restrictions, then approve selective field-level changes.
- [ ] Review 24 remaining item-objective candidates; no automatic bulk replacement.
- [ ] Review 18 plausibly linked missing quests for playability, starter/end links, prerequisites and progression phase.
- [ ] Investigate quest NPC/GO objectives and chain/condition differences separately; preserve untouched fields.
- [ ] Integrate previously tested CI harness fix on a reviewed staging branch and validate combined QA before any merge.

## Phase 2A — Corrections for existing WotLK quests (added 14 October 2026)

**14 October checkpoint:** The maintainer supplied private acore_world.zip. Quest 1203 actual server levels equal stock Questie, but one Moonsteel Broadsword (3853) replaces inherited WotLK Razorspine's Sword (33110). Draft PR #6 proposes a narrow item/text correction. Of 134 Dustwallow server quests, eight confirmed numeric level disagreements are staged in guarded draft PR #7; 31 additional item discrepancy candidates remain unapproved for correction. See docs/DUSTWALLOW-QUEST-AUDIT.md.

- [x] Read-only parse of 9,525 unique quest_template entries in the private offline export.
- [x] Verify quest 1203 server item objective and its accurate already-matching levels; stage guarded item/text-only fix in PR #6.
- [x] Review numeric levels for Dustwallow Marsh quests and stage eight guarded field-level corrections in PR #7.
- [ ] Audit all other zones against effective 3.3.5a Questie data (including static correction layers).
- [ ] Resolve ambiguous item objective and scripted quest data before publishing further corrections.
- [ ] Verify IP era-specific quest conditions/gating and in-game marker/colour behaviour.
- [ ] Maintain backup and final merge/release approval gates.

## Phase 2A — Corrections for existing WotLK quests (added 14 October 2026)

**Audit implementation status (draft [PR #5](https://github.com/CosmicCuddle/N-Questie/pull/5)):** A read-only offline scanner can compare all server quest level fields against generated Questie WotLK data and literal Classic/TBC/WotLK correction levels without exporting the server SQL to GitHub. Dedicated synthetic QA [run 38551948617](https://github.com/CosmicCuddle/N-Questie/actions/runs/38551948617) passed on an earlier PR #5 commit; more realistic source-baseline regression was added afterward and needs its own CI result.

- [x] Identify user-reported example: **quest 1203 Jarl Needs a Blade**, stock Questie MinLevel 30, QuestLevel 35, no numeric correction for this ID in Classic/TBC/WotLK sources.
- [x] Implement a draft, read-only **mismatch discovery script** and synthetic SQL/ZIP + Lua fixture tests.
- [ ] Run the scanner against the **private acore_world archive**; no accessible copy is currently present in this conversation, and the real server quest 1203 values are not established.
- [ ] Triage every mismatch against custom modules, scripted availability, dynamic quest levels, runtime corrections and actual client observations; automatically discovered differences are *candidates*, not approved replacements.
- [ ] Propose separate explicit **field-level** correction records, with Lua 5.1/in-game tests and no bulk data overwrite.



**Purpose:** N-Questie must not only import new server quests: it must also correct existing quest IDs whose levels, difficulty colors, starter/ender relationships, objectives, item/NPC locations, prerequisites or available progression stages differ from stock WotLK.

**Source authority and comparison:**
- Compare the offline private `acore_world` export's `quest_template` / `quest_template_addon` fields (especially `QuestLevel`, `MinLevel`, objective IDs/counts and prerequisites) with Questie's **effective** compiled record, including inherited correction layers, not only raw generated files.
- Distinguish **displayed quest difficulty** (Questie's quest level vs character's actual level plus `GetQuestGreenRange`) from **minimum acceptance level** and **server-authoritative Individual Progression/phase eligibility**. Green/red color alone is not proof the server allows a quest. Existing Questie code calculates colors through `QuestieLib:GetColoredQuestName` → `GetTbcLevel` → `PrintDifficultyColor`.
- Inspect the actual Individual Progression/module restrictions before modeling progression-aware availability; an offline quest database cannot certify character-specific unlocks or phasing. Do not infer that a quest must turn green just because a player is in Vanilla.
- Require explicit review for negative quest levels (dynamic scaling), zone/sort encodings, class/race requirements, item/GO objectives, script/condition overrides and conflicting quest IDs. Never invent alternative values.

**Safe implementation path:**
- [ ] Introduce a separate reviewed **existing-quest corrections** manifest distinguishing `add` (missing quest) from `correct` (known quest). Correction records must carry quest ID, approved individual field differences and source provenance.
- [ ] Produce a **read-only mismatch audit** in private staging: server value, Questie effective value, field, relevant restriction/uncertainty and proposed action; default no change.
- [ ] Apply **field-level** corrections using the supported Questie correction pipeline without erasing unrelated base quest fields, spawn lists, reverse NPC links, gameobject links or previous correction behavior. Reject unapproved ID collisions and unchanged/unreviewed overrides.
- [ ] Regression-test a real level mismatch for red/orange/yellow/green/grey display across player levels; compare with normal WoW quest log behavior and verify no change to unrelated quests.
- [ ] Record a separate progression-aware investigation for IP/phase/character-state gating; do not pretend this can be solved by adjusting `questLevel` alone.
- [ ] Expand to reviewed quest chains, objectives and spawn links after difficulty-level corrections pass.

**Acceptance:** A real server-edited existing quest displays the correct level and difficulty relative to the character, with its unchanged fields and normal behavior preserved; restrictions and prerequisite availability are not falsely advertised as server-authoritative. Test on WoW 3.3.5a in a PR-only build with existing addon/SavedVariables backed up.

## Phase 3 — Objectives, custom rules and accuracy

- [ ] Support NPC kill objectives, gameobject interactions, item drops, location-based objectives when confirmed by source.
- [ ] Account for quest prerequisites, custom faction/race/class requirements and Individual Progression availability; never claim that client markers reflect server-authoritative unlock state until verified.
- [ ] Handle multiple spawns/maps and time/phasing carefully; choose truthful pin visibility rules.
- [ ] Review WoW 3.3.5a map/mini-map compatibility, icon scaling, tooltips and performance.

## Phase 4 — Packaging, regression, release

- [ ] Compare fork against upstream maintenance changes before broad rebases.
- [ ] Run Lua 5.1 checks and scoped database-lookup/marker tests, followed by WoW 3.3.5a manual QA.
- [ ] Preserve addon folder/TOC and SavedVariables continuity, including the ability to roll back.
- [ ] Produce a clear tagged **N-Questie** release only with explicit maintainer approval.
- [ ] Consider N-Addon-Collection import as a separate reviewed process after its standalone release.

## Out of scope until specifically requested

No auto-complete quests, server quest edits, account/character DB edits, progress unlock commands, live SQL sync from WoW, automatic client-server API, or silent mass replacement of vanilla quest icons.

## Active follow-up — 14 October 2026

- [ ] Verify Step 2 in game: quest 2001 starter, kill NPC markers 1868/1869 and NPC 2121 turn-in; preserve normal icon behavior. An eligible quest 437-complete Horde character is required; otherwise pick a genuinely available alternative.
- [ ] Review and test [stacked draft PR #3](https://github.com/CosmicCuddle/N-Questie/pull/3): offline reviewed-JSON → curated Lua generation with explicit quest/NPC approval. **Code proposed, not merged or released; CI result pending inspection.**
- [ ] Keep NPC spawn accuracy and special objective/GO handling as separate source-verified milestones; do not interpret syntactically valid Lua as working pins.
- [ ] Investigate inherited Busted suite initialization independently of successful scoped overlay tests.


- 2026-10-14: M2.1 input schema on feat/nq-validation-m2.1-input-schema-2026-10-14 (draft, based on PR #20). Schema nq-m2-input v1, data-only Lua parser, path gate, synthetic fixtures including quest 1203. M2.2 effective-export design only in docs/NQ-VALIDATION-M2.2-DESIGN.md.
- 2026-10-14: M2.1 path safety on PR #21. Inputs are fully resolved with realpath -e and rejected if they cannot be resolved; the resolved target governs. 29 symlink and path tests. Final CI YAML proposed in docs/proposed-workflows/nquestie-m2-input-schema.yml. The M2.2 implementation sequence is in the design doc.
- 2026-10-14: M2.2 Step 1 (effective schema nq-m2-effective v1, validator only) on feat/nq-validation-m2.2-step1-effective-schema-2026-10-14, stacked on PR #22. No export logic. Write-race review in the M2.2 design doc §6b.
- 2026-10-14: docs/NQ-VALIDATION-M2-ROADMAP.md: full M2.2–M2.5 technical roadmap (framework ours, data and corrections the lead developer's).
- 2026-10-14: private/ tracking guard (tests/check_no_tracked_private.sh) runs in CI via the M2.1 path test on the ci/nq-private-untracked-guard branch; a dedicated workflow step is proposed in docs/proposed-workflows/nquestie-private-untracked-guard.diff.
- 2026-10-14: M2.2 Steps 2-6 in draft PRs #26-#29 (snapshot, safe writer, harness export, tests and proposed CI). v1 cannot represent 752/9159 quests; decision pending. See docs/NQ-VALIDATION-M2.2-HANDOVER.md.
- 2026-10-14: M2.2 Option A follow-up (#33, #34): coverage report, pilot procedure, v2 design (draft). Next: activate M2 CI, approve v2.
