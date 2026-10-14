# N-Questie nq-m2-markers: design

Status: **design only**. No marker exporter exists and none is authorised here. No coordinates are invented and no spawn is assumed active. Stacked on the M2.3 design (PR #42).

Date: 14 October 2026. Source read: this repository at the #39/#41/#42 stack (Questie-335 code, unchanged).

## 1. Why a separate format

`nq-m2-effective` is structural only (`displayScope = "structural-only"`): it holds which targets an objective has, not where Questie draws them. Markers answer a different question: *what would the player see on the map*. Mixing the two would let a location error look like an objective error and the reverse. So there are three separate correctness levels, never merged:

| Level | Question | Evidence | Format |
|---|---|---|---|
| Structural | are the objective targets right? | M2.2 export vs M2.1 server data | nq-m2-effective, M2.3 |
| Location | are the drawn points places where the target really exists? | marker export vs separately verified server spawn records | nq-m2-markers (this design) |
| In-game behaviour | does the marker appear, update and disappear correctly while playing? | manual in-game QA | QA checklist (roadmap M2.5) |

## 2. How Questie 3.3.5a represents and draws markers

### 2.1 Data

| Data | Where | Shape |
|---|---|---|
| NPC spawns | `Database/npcDB.lua` `npcKeys.spawns` (7) | `{[zoneID] = {{x, y}, ...}}`, x/y in percent of the zone map |
| NPC waypoints | `npcKeys.waypoints` (8) | same shape, patrol paths |
| NPC starts/ends | `npcKeys.questStarts` (10), `questEnds` (11) | quest ID lists |
| Object spawns, starts/ends | `Database/objectDB.lua` `objectKeys.spawns` (4), `questStarts` (2), `questEnds` (3) | as above |
| Item sources | `Database/itemDB.lua` `npcDrops` (2), `objectDrops` (3), `itemDrops` (4), `vendors` (14) | ID lists |
| Quest givers | `Database/questDB.lua` `startedBy` (2), `finishedBy` (3) | `{ {npc}, {object}, {item} }` |
| Extra objectives | `questKeys.extraObjectives` (27) | `{spawns, icon, text, objectiveIndex, refs}`; `spawns` uses the npc spawn shape |

### 2.2 Code paths

| Behaviour | File and function |
|---|---|
| Quest object build: Starts, Finisher, ObjectiveData, SpecialObjectives | `Database/QuestieDB.lua` `QuestieDB.GetQuest` (Finisher built around lines 1175-1190; requiredSourceItems special objectives around 1310-1336; extraObjectives loop around 1340-1374) |
| Item sources expanded | `QuestieDB:GetItem` (Sources from npcDrops, objectDrops, vendors) |
| Starter markers (available quests) | `Modules/Quest/AvailableQuests.lua` `AvailableQuests.DrawAvailableQuest` → `_AddStarter` (NPC and GameObject starters) |
| Finisher markers | `Modules/Quest/QuestieQuest.lua` `QuestieQuest:AddFinisher` (monster or object finisher; waypoints drawn with `QuestieMap:DrawWaypoints`) |
| Objective spawn lists | `Modules/Quest/QuestieQuestPrivates.lua` `_QuestieQuest.objectiveSpawnListCallTable` (`monster`, `object`, `item`, `killcredit`, `event`, `spell`). `item` follows Sources to monsters (loot icon) and objects (object icon); `killcredit` draws every ID in `IdList` |
| Objective icons | `QuestieQuest:PopulateObjective` → `_DetermineIconsToDraw` → `_DrawObjectiveIcons`; icon limit `Questie.db.profile.iconLimit` (max 300 per type); clustering around one zone centre when the objective is in one zone |
| Extra objectives | `QuestieDB.GetQuest`: Type/Id from the **first** ref only, but spawns of **all** refs merged; icon overridden by the correction's icon (1 slay, 2 loot, 3 event, 4 object, 5 talk) |
| World map and minimap | `Modules/Map/QuestieMap.lua` `DrawWorldIcon` (zone → uiMapID via `ZoneDB:GetUiMapIdByAreaId`, falling back to the parent map); queued and placed by `QuestieMap.ProcessQueue` with `HBDPins:AddWorldMapIconMap` and `HBDPins:AddMinimapIconMap`. Dungeon zones are redirected by `ZoneDB:GetDungeonLocation` |
| Progress transitions | `_QuestieQuest.ObjectiveUpdate` reads the quest log (numFulfilled/numRequired/finished); `PopulateObjective` calls `_UnloadAlreadySpawnedIcons` once an objective is complete; `QuestieQuest:UpdateQuest` unloads all quest frames and calls `AddFinisher` when the quest is complete (`IsComplete() == 1`), and removes them on failure (-1) |
| Quest-log line mapping | `QuestieQuest:PopulateQuestLogInfo`: line N uses `ObjectiveData[N]` |

### 2.3 Consequences for comparison

- Multiple spawns are all drawn (subject to the icon limit and clustering). Clustering and the limit are display choices, not data; markers compare the data before them.
- A killCredit objective draws every NPC in the ID list, not only the root.
- An item objective draws its sources, not the item.
- Scripted and trigger objectives (`event`) draw only the correction's custom spawns; there is nothing on the server side to compare them with except area triggers and scripts, which need manual review.
- requiredSourceItems that are not also item objectives become extra special objectives (item sources drawn).

## 3. Marker record (proposed `nq-m2-markers` v1)

One record per quest, derived from the same compiled data, structural IDs plus Questie's own spawn coordinates **as stored**. Nothing computed, nothing invented.

```
{ ID, starters = { {type, id} }, finishers = { {type, id} },
  objectives = { { position, kind, targets = { {type, id, via = "direct"|"killCredit"|"itemSource"|"extraRef"} } } },
  extraObjectives = { { position, objectiveIndex, icon, targets = {...}, customSpawnZones = {...} } },
  locations = { [ "type:id" ] = { [zoneID] = { {x, y}, ... } } }   -- copied from npcDB/objectDB spawns only
}
```

`locations` keeps Questie's percent coordinates exactly as stored; no conversion, rounding or clustering. Waypoints are listed separately and never used as spawn evidence.

## 4. Comparison with AzerothCore (location level)

Server records must come from a separately verified M2.1-style private export (`creature`, `gameobject` spawn rows, map, zone, position, phase mask, spawn mask; `creature_queststarter/questender`, `gameobject_queststarter/questender`; loot templates for item sources). Rules:

| Rule | Detail |
|---|---|
| No active-spawn assumption | a server spawn row is "present", not "active". Activity depends on phase, game event, pooling, conditions, scripts; unknown activity never confirms. |
| Coordinate frame | server world coordinates must be converted to the Questie zone percent frame with a separately verified map-bounds table; until that table is verified, location checks stay NEEDS_MANUAL_REVIEW. |
| Tolerance | a Questie point matches a server spawn when within a stated tolerance in zone percent (proposed 1.0); tolerance is a reviewed parameter, not a guess at the moment of comparison. |
| Missing on server | Questie point with no server spawn of that ID in the zone → finding, NEEDS_MANUAL_REVIEW (could be phase, event, pooled or removed). |
| Missing in Questie | server spawn with no Questie point → finding, informational unless the target is the only source of the objective. |
| Phases | server `phaseMask` recorded; Questie 3.3.5a has no phase data, so phased spawns are never claimed to match or mismatch without manual evidence. |
| Conditions, IP | the IP (Individual Progression) module and `conditions` rows can hide spawns or quests; recorded as evidence items exactly as in M2.3 (`ip`, `conditions`); unknown → review. No assumption about which progression stage a player is in. |
| Starters/enders | compared as ID sets against the queststarter/questender tables; this is structural, not location. |

Outcomes reuse the M2.3 axes (export status + comparison outcome) per marker group, so no new status vocabulary is introduced.

## 5. Limitations and approval gates

- Needs a verified map-bounds table and a private spawn export; neither exists.
- In-game behaviour (icon limit, clustering, minimap edges, completion removal) can only be checked in game (roadmap M2.5 QA).
- A marker exporter, the server spawn export and the comparison each need separate maintainer approval.
