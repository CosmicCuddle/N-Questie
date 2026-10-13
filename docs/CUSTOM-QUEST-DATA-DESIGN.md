# N-Questie — Custom Quest Data Design

**Status:** architecture proposal based on the actual Questie-335 source. **No loader or importer implemented yet.**

## Why an overlay

Questie-335 already has four related database types and a correction loader:

| Data | Source schema | Important fields |
| --- | --- | --- |
| Quest | `Database/questDB.lua` | `questKeys.name`, `startedBy`, `finishedBy`, `objectives`, `requiredLevel`, `questLevel`, `zoneOrSort`, requirements |
| NPC | `Database/npcDB.lua` | `npcKeys.name`, `spawns`, `zoneID`, `questStarts`, `questEnds`, faction/flags |
| Gameobject | `Database/objectDB.lua` | `objectKeys.name`, `spawns`, `zoneID`, `questStarts`, `questEnds` |
| Item | `Database/itemDB.lua` | Item starts, objectives and related item data; verify per-record use |

`Database/Corrections/QuestieCorrections.lua` already calls `_LoadCorrections` for Classic, TBC and WotLK. The correct insertion point for an isolated Naxxramas overlay must be chosen by examining the full 3.3.5a compatibility corrections and compilation order. It is **not yet confirmed** whether simply adding a file to the TOC will safely update compiled cache state.

**Design target:** keep Naxxramas input records apart from upstream-generated `Database/Wotlk/wotlkQuestDB.lua`, `wotlkNpcDB.lua`, and `wotlkObjectDB.lua`. Apply quest, NPC, object and (where necessary) item corrections together, without erasing unrelated existing fields.

## Proposed human-readable record

A future validated manifest might hold fields like these (**illustrative schema only; IDs below are deliberately not invented**):

```text
quest_id: <actual server quest ID>
title: <actual server quest title>
start:
  type: npc | gameobject | item
  id: <actual quest starter entry>
finish:
  type: npc | gameobject
  id: <actual quest ender entry>
required_level: <validated value>
quest_level: <validated value>
zone_or_sort: <Questie-compatible zone/sort ID>
locations:
  - type: npc | gameobject
    entry: <starter/ender/objective entry>
    map_id: <AzerothCore map ID>
    world_position: <actual x, y, z, orientation from spawn>
    questie_zone_id: <verified Questie-compatible zone ID>
    map_percent_x_y: <verified 0-100 map coordinates>
availability: <verified prerequisites/faction/progression state>
source: <database export revision or approved source record>
```

Do not paste these placeholders into a Lua database. Choose JSON, CSV or another schema **after** validating one real quest. The validator should reject missing references, unsupported maps, malformed numbers and duplicate/conflicting overrides; never manufacture a spawn position.

## Source-of-truth workflow (development machine, not in the WoW client)

1. Verify the deployed AzerothCore `world` schema with read-only `SHOW TABLES` / `DESCRIBE` or HeidiSQL structure browsing; custom module/world patches may alter names and columns.
2. For the supplied quest ID, inspect quest definition and availability (typically `quest_template` and relevant addon/conditions tables), starter and ender relationships (typically `creature_queststarter`, `creature_questender`, `gameobject_queststarter`, `gameobject_questender`), and NPC/gameobject template identities.
3. Read actual creature/gameobject spawn rows from `creature` or `gameobject`; include phase/condition information and multiple spawns as appropriate. Query only needed quest IDs, never a whole production dump.
4. Convert world coordinates to **the correct UI map's 0–100 percent coordinates** using confirmed 3.3.5a map boundaries/transforms, not raw world coordinates. `map_id` (world continent/instance) and the Questie zone identifier are not interchangeable.
5. Generate validated Lua for quest, NPC/object spawns and reverse questStarts/questEnds indexes as needed. Check existing base record collisions; overlay the **minimal required keys**.
6. Execute Lua 5.1/static tests and examine the exact loader/compile path. Do not assume an ordinary `/reload` makes changes to compiled SavedVariables immediately visible.
7. Install a test build **only after backing up** the working Questie addon folder and `QuestieConfig`/`QuestieConfigCharacter` SavedVariables. Verify the starter icon, turn-in icon and visibility conditions in game.

## Risks and design constraints

- **Quest availability:** adding a quest record does not guarantee Questie's filtering logic will display it. Required level, faction, race, class, prerequisites, completion state and current quests must be tested separately.
- **Server progression:** AzerothCore and Individual Progression modules may hide quests through additional conditions. Questie should not pretend a quest is available merely because an NPC spawns.
- **Multiple points:** some quest givers or objects have many spawns. Include only grounded coordinates and appropriate zone/map references.
- **Compatibility:** preserve existing 3.3.5a `Questie-335.toc` name, loader dependencies, upstream authors/third-party notices, SavedVariables and original quest tracking.
- **Distribution:** review inherited licence and third-party assets before tagging a redistributed fork. GitHub fork ownership does not imply authorship of underlying code.

## Information still needed

**One real custom server quest ID** and confirmation of what is missing: starter, objective, ender or all. Additional data is only requested if the source does not resolve the entries and coordinates. Never request a database login or write privileges.
