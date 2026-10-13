# N-Questie — Development Handover

**Project:** N-Questie  
**Maintainer:** CosmicCuddle  
**Established:** 13 October 2026  
**Repository:** https://github.com/CosmicCuddle/N-Questie  
**Default/source branch:** `335`  
**Fork parent:** https://github.com/divial28/Questie-335  
**Client:** World of Warcraft 3.3.5a (`## Interface: 30300`)  
**Inherited addon identity:** `Questie-335.toc`, display title `Questie-335`, upstream version `9.5.1`  

## Purpose

Maintain a Naxxramas-server-specific Questie fork and make it straightforward to add or correct map and minimap markers for custom AzerothCore quests. The first milestone is reliable quest starter and ender markers; objective markers follow only when their world locations and underlying Questie record types are known.

**Priority:** Keep existing Questie working while building a *small, reviewable custom data overlay*. Never hand-edit thousands of generated WotLK records for each server change.

## Verified starting point

- `CosmicCuddle/N-Questie` was created on 13 October 2026 as a fork of `divial28/Questie-335`; the copied/default branch is `335`.
- Initial `335` head: `13c958005c0e3b27e3ef0ea3472998fa522a11a5`.
- The original `Questie-335.toc` registers `QuestieConfig` and `QuestieConfigCharacter` as SavedVariables, targets `30300`, loads the WotLK quest/NPC/object/item databases, then the correction modules.
- `Database/questDB.lua`, `npcDB.lua`, and `objectDB.lua` define symbolic field keys. `Database/Corrections/QuestieCorrections.lua` merges existing Classic/TBC/WotLK corrections during database initialization.
- The quest and spawn data are related but distinct: quest start/turn-in references use NPC/object IDs; spawn coordinates belong to the corresponding NPC/object records. **A quest ID alone does not establish an icon location.**
- Compiled/cached Questie database state may require a supported recompile/refresh after adding overlay entries; determine exact invalidation behavior in code before implementing a loader.
- The inherited GitHub Actions workflow includes Lua 5.1 and database validation stages, but it has **not been accepted as a passing N-Questie run**. CI and in-game testing must be recorded separately.
- The original README currently refers to the previous upstream fork and the installed addon folder `Questie-335`. Preserve compatible installed folder/TOC names initially, even though the GitHub repository is called **N-Questie**.

## Working rules

1. **Back up first:** Before any test installation, close WoW and back up the current working `Interface/AddOns/Questie-335/` directory (or the exact installed Questie folder) and the Questie SavedVariables for the account/character. Keep the baseline ZIP for rollback.
2. **Scope controls:** Make addon changes only in this repository/feature branch. Do not change live AzerothCore world/characters/auth databases, custom quests, quest flags or NPC placements without separate explicit approval.
3. **Read-only server data:** Use a narrowly scoped, read-only export from the AzerothCore `world` DB to author custom quest records. Do not request credentials or whole database dumps. Confirm actual table names and schema before drafting SQL queries.
4. **Quest IDs and positions:** Never invent quest IDs, NPC IDs, gameobject IDs, coordinates, availability, phases or map conversions. Validate map-specific coordinates before showing markers.
5. **Client compatibility:** Lua 5.1 / WoW 3.3.5a only. Respect `QuestieLoader`, correction application order, existing database compilation and marker filtering. Do not quietly change existing quest records or progression gating.
6. **Fork attribution:** Preserve upstream history, credits, and all inherited licence/third-party notices. Complete a licence and redistribution review before any public download or release; no custom origin claims.
7. **Repository practices:** One focused topic per PR, source/QA distinctions explicit, with development log, test evidence and rollback. Do not merge, tag or update N-Addon-Collection until maintainer authorizes it.
8. **Accessibility:** Short, clear walkthroughs, readable map markers/tooltips and a simple repeatable import workflow.

## Roadmap and working files

- [ROADMAP.md](ROADMAP.md): phased milestones and acceptance gates.
- [CUSTOM-QUEST-DATA-DESIGN.md](CUSTOM-QUEST-DATA-DESIGN.md): proposed overlay, source fields, map-coordinate requirements.
- [TESTING.md](TESTING.md): safe read-only test sequence and expected observations.
- [DEVELOPMENT-LOG.md](DEVELOPMENT-LOG.md): decisions and evidence.

## First deliverable

1. Receive **one real quest ID** for a quest that currently has missing or wrong icons; optionally NPC/gameobject ID and spawn evidence.
2. Query/inspect `quest_template`, quest starter/ender relationships, NPC/gameobject templates and spawn records **read-only**; reconcile with this server's actual schema and phasing.
3. Prove one quest starter and ender icon, using the existing correction architecture with the smallest possible code change and minimal regression tests.
4. Extend to objectives and batch import only after the first quest passes in-game.

The first documentation PR is **foundation only**. It does not implement or install a new custom quest overlay.

## Continue development in a new chat

> Continue N-Questie on https://github.com/CosmicCuddle/N-Questie (branch `335`). Read docs/PROJECT-HANDOVER.md, ROADMAP.md, CUSTOM-QUEST-DATA-DESIGN.md, TESTING.md and DEVELOPMENT-LOG.md; check current PRs and state. Prioritize a small, non-destructive server-specific quest overlay and a reproducible read-only quest import. Request the example quest ID and only the necessary world-DB records. Preserve WoW 3.3.5a, the installed Questie addon identity, upstream credits, backups and PR-based testing. Update the handover after each milestone.
