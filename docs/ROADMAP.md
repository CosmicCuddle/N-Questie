# N-Questie — Development Roadmap

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

