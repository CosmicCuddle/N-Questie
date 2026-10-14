# N-Questie — Development Roadmap

**Updated:** 13 October 2026  
**Baseline:** forked `divial28/Questie-335`, branch `335`, upstream addon v9.5.1.  
**Status:** first curated overlay implemented on an **unmerged QA branch**; quest 2001's visual starter → objectives → completed turn-in → marker removal lifecycle **verified in game on 14 October 2026**. No release or merge authorized.

## Phase 0 — Foundation and safety

- [x] Establish `CosmicCuddle/N-Questie` from the selected 3.3.5a source fork; retain branch `335`.
- [x] Confirm addon loader, database sources, correction layer and SavedVariables names in source.
- [x] Document safe backups, release boundaries, proposed import data contract and maintainer handover.
- [ ] Finish attribution/licence review for any redistributable custom Questie package; retain original credits.
- [x] Verify baseline addon loading, normal world-map/minimap icons and preference persistence in game (5/5). More exhaustive warnings/regressions remain future work.
- [ ] Determine whether baseline fork CI is applicable/passable or needs scoped 3.3.5a checks.

## Phase 1 — Reliable custom quest starter/ender map icons

- [x] Identify quest 2001 — Ravenclaw Cleanup as missing from Questie's raw WotLK quest table; its NPC giver, ender and kill target IDs were obtained from the private read-only world export.
- [x] Confirm quest 2001 available to an eligible character in game and verify its starter marker tooltip. Original fork absence was established by comparing source records, not a separately captured before/after screenshot.
- [ ] Inspect **read-only** `world` quest starter/ender and spawn data; detect server-specific NPC/object or quest ID differences.
- [x] Implement first **unmerged** N-Questie-specific quest/NPC correction overlay, separate from generated WotLK tables, with cache revision invalidation.
- [x] Validate quest 2001's visible marker lifecycle in actual WoW 3.3.5a (available, objective tooltip, complete, disappears after hand-in). Further quest types remain unverified.
- [ ] Verify correction loading order, compiled-DB invalidation/rebuild behavior, map conversion and marker filters.
- [ ] Add tests for custom IDs, malformed data rejection, duplicate-safe merges and optional hide/availability rules.
- [x] Test quest 2001 on the world map and objective marker tooltips; baseline minimap icons still work. Dedicated custom quest 2001 minimap icon verification remains unrecorded.

**Acceptance:** A confirmed, available custom quest displays its correct start and end markers at real NPC/gameobject spawn locations; unrelated native quests still display as before. Markers must not appear on unrelated maps.

## Phase 2 — Simple future quest additions

- [ ] Create a versioned, human-readable custom quest manifest supported by a validation/generation script (format to be selected after the first proven quest).
- [x] Add initial Python read-only HeidiSQL SQL/ZIP extractor for **selected quest IDs** and JSON review output; deliberately reject unsupported NPC/objective situations.
- [ ] Convert reviewed JSON into curated Lua automatically (currently one small manually-reviewed Lua record).
- [ ] Validate referential integrity across quest IDs, starters, enders and spawn source records, including zones/maps.
- [ ] Support add/update/remove from a single manifest; generated Lua deterministic and reviewable.
- [ ] Require explicit record provenance and prevent silent overwrites of unrelated base quests.

**Acceptance:** Add one additional server quest through the documented manifest with no manual edits to large upstream generated database files.

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
