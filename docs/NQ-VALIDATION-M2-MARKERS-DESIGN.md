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

One record per quest, derived from the compiled data. Every coordinate is Questie's own stored value, copied exactly (no conversion, rounding, clustering or deduplication). Nothing is invented.

```
{ ID,
  starters  = { {type, id} }, finishers = { {type, id} },
  objectives = { { position, kind, targets = { {type, id, via, sourceKind?, path?} } } },
  extraObjectives = { { position, objectiveIndex, icon,
                        refs = { {type, id, refIndex} },        -- all refs, compiled order
                        displayRef = {type, id} | nil,          -- = refs[1]; Questie's Type/Id
                        customSpawns = { { zone, pins = { {x, y, pinIndex} } } } } },  -- raw extraObjectives[1]
  points = { { origin, ownerId?, extraPosition?, zone, x, y, pinIndex } },
  waypoints = { { npcId, zone, path } } }
```

**Origins.** `points[*].origin` is one of:

| Origin | Source | Owner |
|---|---|---|
| `db_npc` | `npcDB` `spawns` of the NPC | `ownerId` = NPC ID |
| `db_object` | `objectDB` `spawns` of the object | `ownerId` = object ID |
| `custom_extra` | the raw custom `spawns` table of an extra objective (`extraObjectives[n][1]`), including spawn-only entries with no refs and `objectiveIndex = 0` | `extraPosition` = n; no DB owner |

`pinIndex` is the 1-based position of the point in its source list (per owner and zone, or per extra and zone), so two pins in the same zone stay distinct and traceable. Every custom pin must appear exactly once in `points` with identical x/y, and every `custom_extra` point must match a pin. Zone-only custom data is rejected.

**First reference vs merged spawns.** Questie takes `Type`/`Id` from the first reference only but draws the spawns of all references. The record keeps both: `displayRef` (must equal `refs[1]`) and the full `refs` list with their DB points.

**Waypoints** come from `npcKeys.waypoints` and are kept only in `waypoints`. They are never points and never spawn evidence.

**Item source categories.** An item objective's targets keep their category from `itemDB` and the relationship path:

| `sourceKind` | itemDB field | Target type | Note |
|---|---|---|---|
| `npcDrop` | `npcDrops` (2) | monster | loot icon at runtime |
| `objectDrop` | `objectDrops` (3) | object | object icon at runtime |
| `vendor` | `vendors` (14) | monster | Questie draws vendors with the loot icon; the category is kept anyway |
| `itemDrop` | `itemDrops` (4) | item | `QuestieDB:GetItem` does not add itemDrops to `Sources` (only npcDrops, vendors, objectDrops), and the spawn-list `item` function also skips item-type sources; recorded but not drawn |

`path` = `{ objective item ID, ..., source ID }`. Item sources are never flattened into direct kill targets.

## 4. Comparison with AzerothCore (location level)

### 4.1 Map bounds and coordinate frames (maintainer decision, 14 October 2026)

- Questie stores **zone percentages** (0-100 of a zone map, keyed by AreaTable zone ID, converted at draw time through `ZoneDB:GetUiMapIdByAreaId`). AzerothCore stores **world coordinates** per map. They are never assumed equal.
- Map bounds come from verified 3.3.5a client map data (WorldMapArea bounds) and Questie's existing coordinate systems, cross-checked against independently verified locations (for example a starter NPC whose position is confirmed in game and in the server table).
- Until a bounds table passes that cross-check, `transformVerified = false` and every location result is NEEDS_MANUAL_REVIEW.
- The 1.0 zone-percent tolerance is **provisional**, an investigation parameter only. Results inside or outside it are `WITHIN_PROVISIONAL_TOLERANCE` / `OUTSIDE_PROVISIONAL_TOLERANCE`, never confirmed and never used to correct data automatically.

### 4.2 Rules

Server records must come from a separately verified private export (`creature`, `gameobject` spawn rows with map, zone, position, phase mask, spawn mask; queststarter/questender tables; loot and vendor tables for item sources).

| Rule | Detail |
|---|---|
| No active-spawn assumption | a server spawn row is "present", not "active". Activity depends on phase, game event, pooling, conditions, scripts. |
| Unknown never decides | unknown phase, conditions, IP or spawn activity, or an unverified transform, gives NEEDS_MANUAL_REVIEW, never a positional match or mismatch |
| Missing on server | Questie point with no server spawn of that owner in the zone → NEEDS_MANUAL_REVIEW (phase, event, pool or removed) |
| Missing in Questie | server spawn with no Questie point → informational |
| Custom pins | compared only with verified area triggers or scripted positions when such evidence exists; otherwise NEEDS_MANUAL_REVIEW |
| Phases, conditions, IP | recorded as evidence items as in M2.3; no assumption about a player's progression stage |
| Starters/enders | compared as ID sets (structural, not location) |

Draft: `LocationResult` (tested) has no confirmed outcome at all.

### 4.3 Three separate results for markers (A6)

Structure (IDs and origins), location (§4.1-4.2) and in-game lifecycle (appears, updates, disappears; roadmap M2.5 QA) are reported as three separate results. Existing quest 2001 observations are partial lifecycle QA, not proof of every spawn. Marker tooltip **text** belongs to the separate text/tooltip QA lane (correction workflow §7), not to this format.

### 4.4 Synthetic tests

`tests/fixtures/m2_markers_draft/markers_synthetic.lua` (invented IDs, zones and coordinates) and `tests/test_nquestie_m2_markers_draft.lua` (39 checks): A1 spawn-only custom pins (loss, rounding, invention, zone-only, collapsed index), A2 mixed refs and pins (displayRef, relabelling), A3 waypoints separate, A4 item source categories and paths, A5 unknown phase/conditions/IP/activity and unverified transform never decide; no confirmed location result exists.

## 5. Limitations and approval gates

- Needs a verified map-bounds table (§4.1) and a private spawn export; neither exists.
- In-game behaviour (icon limit, clustering, minimap edges, completion removal) can only be checked in game (roadmap M2.5 QA).
- A marker exporter, the server spawn export and the comparison each need separate maintainer approval.
