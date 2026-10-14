# N-Questie — Development Roadmap

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


## Validation workstream (Grok Bot) — added 14 October 2026

*Separate workstream. Does not change the phases above.* Design: [VALIDATION-DESIGN-2026-10-14.md](VALIDATION-DESIGN-2026-10-14.md). Review: [REVIEW-2026-10-14.md](REVIEW-2026-10-14.md).

- [x] M0 — 3.3.5a effective-DB validation harness `cli/validate-335.lua`, preservation allow-list, negative fixtures, proposed CI workflow (needs a maintainer to add it under .github/workflows) ([NQ-VALIDATION-M0.md](NQ-VALIDATION-M0.md)). Draft PR stacked on #7, unmerged.
- [ ] Agree the cache revision safeguard with the lead developer (proposal in the M0 doc §6).
- [ ] M1 — effective-record JSON export and rule-catalogue fixtures.
- [ ] M2–M5 as per the design document.
- [x] M0 combined with PR #8 on `feat/nq-validation-m0-pr8-integration-2026-10-14`: 19 level corrections + 1203 + 2001, compiled round trip, 4 negative fixtures (NQ-VALIDATION-M0.md §9).
- [x] Revision safeguard layer 1 (CI-only bump check) on `feat/nq-revision-bump-guard-2026-10-14`; layer 2 fingerprint deferred.
- [x] M1 — quest objective validation rules (report only) on `feat/nq-validation-m1-objectives-2026-10-14`: 22 catalogued rules, 20 synthetic fixtures, quest 1203 confirmed mismatch on real stock data ([NQ-VALIDATION-M1.md](NQ-VALIDATION-M1.md)). Draft, unmerged. PR #13's chain corrections are not yet covered by the M0 allow-list (coordinated separately).
