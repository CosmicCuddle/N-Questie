# N-Questie — Reviewed Early-Game Quest Levels

**Date:** 14 October 2026  
**Status:** Draft, not installed or verified in-game.  
**Scope:** Eleven individually checked existing quests, with no objective changes.

## Evidence and method

The maintainer supplied a private offline `acore_world.zip` and the currently installed `Database/Wotlk/wotlkQuestDB.lua`. The installed Questie file was verified byte-identical to the repository's inherited source (git blob `abbf2831b6d6b54b5d9383ba2c3e5cce5147379d`).

Using the private world `quest_template.QuestLevel` and `quest_template.MinLevel`, the following IDs differ from that inherited Questie record. These records have no direct numeric `requiredLevel` or `questLevel` entry in the reviewed static Classic/TBC/WotLK Questie correction tables. The server database was read-only and is **not included in this repository**.

| Quest ID | Name | Area | Questie min | Server min | Questie quest level | Server quest level |
|---:|---|---|---:|---:|---:|---:|
| 98 | The Legend of Stalvan | Duskwood | 22 | 22 | 32 | 35 |
| 126 | Howling in the Hills | Redridge Mountains | 15 | 15 | 21 | 25 |
| 169 | Wanted: Gath'Ilzogg | Redridge Mountains | 11 | 15 | 26 | 26 |
| 180 | Wanted: Lieutenant Fangore | Redridge Mountains | 11 | 15 | 26 | 26 |
| 249 | Morganth | Redridge Mountains | 20 | 20 | 26 | 27 |
| 256 | WANTED: Chok'sul | Loch Modan | 9 | 17 | 22 | 22 |
| 304 | A Grim Task | Wetlands | 26 | 26 | 31 | 34 |
| 398 | Wanted: Maggot Eye | Tirisfal Glades | 4 | 6 | 10 | 10 |
| 442 | Assault on Fenris Isle | Silverpine Forest | 10 | 10 | 20 | 24 |
| 895 | WANTED: Baron Longshore | The Barrens | 9 | 11 | 16 | 16 |
| 6284 | Arachnophobia | Stonetalon Mountains | 12 | 15 | 21 | 21 |

All eleven have a quest starter (NPC or gameobject) and recipient association in the private export. Existing starter/ender associations remain **untouched**. In particular, wanted posters may use gameobject starters, so an absent `creature_queststarter` row does not imply a missing quest.

## Proposed implementation

- New `Compat/NQuestieReviewedEarlyQuestLevels.lua`: register a 3.3.5a-only `questData` correction callback and return just level fields whose values actually differ.
- Before producing each correction, ensure **both** current inherited `requiredLevel` and `questLevel` equal the reviewed original Questie values. Refuse to overwrite newer/unexpected values.
- Never replace full quest rows, objectives, starter/ender links, NPC locations, prerequisites, names, item data, faction/race/class gates or scripts.
- Update the existing N-Questie compiled revision marker from **3 to 4** for future in-game QA builds; cache handling itself is subject to the independent integration review.
- Lua 5.1 synthetic regression checks each ID, unmodified metadata, client guard and refusal of unexpected values.
- Python source-fixture checks verify actual public Questie levels and absence of direct static correction-layer conflicts, independently of the private world archive.

**Colour policy:** The addon does not force any quest colour. Correct nominal quest levels will be used by the existing Questie colour calculation relative to the character's real level. Minimum quest level is an independent acceptance constraint; an Individual Progression unlock may impose further restrictions not encoded in the static world export.

## Limitations and validation gate

1. This is a **source-verified mismatch**, **not yet an independently observed in-game display bug** for each ID. Questie's live database compilation, cache and module-progression logic require separate inspection (assigned to the external integration reviewer).
2. Static records cannot prove quest availability on an individual character or particular IP era; respect script, condition and server-module differences.
3. Test using a reviewed temporary PR-only N-Questie QA package *after backing up* the currently installed `Interface/AddOns/Questie-335` folder and the account/character SavedVariables containing `QuestieConfig` / `QuestieConfigCharacter`.
4. For representative examples, compare quest level and colour on world map/Questie tooltip with the server's actual quest log and quest eligibility. Check quest starters, objectives, turn-in markers and chained quest tracking have not regressed.
5. Log evidence and approve field-level changes explicitly before any merge/tag/release or N-Addon-Collection update.

## Coordination

The external collaborator **Grok** is initially assigned a separate read-only review of correction registration, compilation timing, cache invalidation and test fidelity. This draft change set does **not** alter their assigned architecture/validation files. Report any discovered integration issues against the relevant PR before applying further fixes.

**This document contains only the 11 curated IDs and numeric level pairs approved for draft investigation.** Never upload the raw world SQL, full private audit workbook or private full mismatch report to public GitHub.
