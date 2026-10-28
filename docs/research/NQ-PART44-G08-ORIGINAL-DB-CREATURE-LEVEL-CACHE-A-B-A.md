# Part 44 Gate08 — original QuestieDB reader reinitialization and retained creature-level cache

**28 October 2026 · PUBLIC-SAFE TEST-ONLY DRAFT · NO ORIGINAL ADDON EDITS, INSTALL, ZIP, MERGE, TAG OR RELEASE**

## Source and provenance

Immutable protected public `335` commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. Source authenticated by immutable Git blob `Database/QuestieDB.lua` `5784cb65160175e1dce30fe20e8baada0af7e480`. Exact **whole unchanged original `QuestieDB:Initialize()` function** extracted from lines 220–311, genuine original `QuestieDB._CreatureLevelCache = {}` declaration at 1381, and **whole unchanged `QuestieDB:GetCreatureLevels(quest)` function** from lines 1384–1420; both source functions are compiled and executed without editing their bodies. The **full 1,741-line QuestieDB.lua module is NOT executed**. `QuestieDBCompiler:GetDBHandle` is a fictional closure-returning reader stub, and `QuestieDB:GetNPC`, NPC item records, frame/UI, combat and WoW 3.3.5a/Individual Progression are NOT genuine.

## Real source control-flow

Original `QuestieDB:Initialize` binds four `GetDBHandle` results, reassigns `QueryNPC/Quest/Object/Item` and `Query*Single` exports from each handle, installs per-kind `*Pointers`, and **resets exactly five private caches**: `_QuestieDB.questCache`, `itemCache`, `npcCache`, `objectCache`, `zoneCache` (lines 268–303). It contains no `_CreatureLevelCache` reset.

Original `GetCreatureLevels` first returns `QuestieDB._CreatureLevelCache[quest.Id]` when populated (1385–1387). On a miss it reads NPCs from kill objectives and item `npcDrops` via **current** `QuestieDB.QueryItemSingle` (1409) and `QuestieDB:GetNPC`, saves the level/rank map under `quest.Id` (1416–1418), and returns it. A separate source declaration initializes the creature-level cache, but that declaration isn't part of original Initialize.

## Planned dedicated exact-head dual-Lua test

- **38 synthetic assertions per Lua5.1.5 and Lua5.4.6**, pending independently inspected dedicated logs.
- Confirm source anchors; load complete unchanged original extracted function bodies and declaration; use invented old A and new B NPC+item rows, fictional four-kind `GetDBHandle`, original public `QueryItemSingle` rebinding and original five-cache resets.
- A: quest `7001` contains synthetic direct NPC and item-drop NPC objectives. Original `GetCreatureLevels` returns/caches `A_DIRECT` and `A_DROPS`.
- Reinitialize B under same `QuestieDB` module instance, using fictional recompiled global Bin/Ptrs. Original five caches clear and new `QueryItemSingle` reads B; stored OLD query closure/pointer alias remains A.
- Same quest ID `7001` now requesting B returns **A's cached creature-level map**. Different invented quest ID `7002` correctly builds B levels; an **explicit MODEL-ONLY cache clear** before rerunning real original `GetCreatureLevels` permits it to rebuild B for ID `7001`.
- Reinitialize A again (A→B→A) and observe B cache stale without another manual clear; demonstrate model-only second clear can rebuild A. This is a **constructed re-initialization demonstration**, NOT evidence the existing 3.3.5a client actually does hot-reinitialize mid-play or that QuestieDB already uses source epochs.
- Both the new and old query closures and current pointer tables are fictional and validated without real or private realm/account data.

## Engineering implications and limitations

Actual source shows a separately retained cache that future generation rebinds would need to invalidate, version or bind to a stable old read generation; resetting the original five private caches alone does not address creature-level-derived data. A generation-aware consumer census must also trace any other caches not cleared in `Initialize`, UI display state, deferred events, third-party observers and crash/relog SavedVariables semantics.

This is not an approved implementation. Actual binary decoder/QuestieStream pool, E01–E08/unknown writer ownership, coherent four-kind eight Bin+Ptrs+metadata publication, live reader ABI under Shared Module objects, native Individual Progression client and future backup/rollback tests remain **Gate08 MAJOR RED**. Overall 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING, 439 RAW candidates unapproved, denominator unknown, pilot 1207–1209 **0/3**. No protected runtime edits/SQL, private data, ZIP/build, install, merge, tag or release. Native test would require new explicit owner approval and full `Interface/AddOns/Questie-335` plus account/character SavedVariables backups and rollback.
