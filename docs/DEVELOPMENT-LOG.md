# N-Questie — Development Log

## 13 October 2026 — Private world database intake

**Input:** Maintainer supplied a ZIP containing a HeidiSQL export of the Naxxramas AzerothCore `acore_world` database. This is private source material, **not** a public repository file.

**Inspection:** Locally and read-only verified the presence and structure of quest definitions, quest addon data, NPC/gameobject quest starter/ender links, NPC/gameobject templates, spawn records, quest POI records, conditions and SmartAI scripts. Conducted a preliminary ID and relationship comparison against the maintainer's original Questie-335 ZIP. The private audit is provided directly to the maintainer, not committed to public GitHub.

**Limit:** Raw Questie source comparisons can flag candidates but cannot prove current in-game availability or map accuracy: runtime correction layers, phase/spawn conditions, scripted quest objectives, database caching and map transforms still require inspection. Do not import everything automatically before this is validated.

**Privacy:** Neither the SQL archive, server host metadata, nor server-derived quest records/spawn coordinates have been uploaded to GitHub. Before adding generated custom quest data to the **public** N-Questie repository, obtain explicit maintainer approval about publishing quest IDs, NPC/object IDs and map coordinates.

**Next:** Build a generic reproducible importer and tests without sensitive fixtures; then use one verified real quest to prove starter/objective/turn-in markers. Back up the installed addon and SavedVariables before any in-game test.

## 13 October 2026 — Repository established and architecture reviewed

**Decision:** Name the customised fork **N-Questie**, retaining `Questie-335` as the installed addon/TOC identity initially for compatibility. Work from `CosmicCuddle/N-Questie` and its `335` branch (fork parent `divial28/Questie-335`).

**Verified source:** TOC targets WoW 3.3.5a `30300`, records upstream addon v9.5.1 and SavedVariables `QuestieConfig`/`QuestieConfigCharacter`. Source defines separate quest, NPC, object and item tables, plus a `QuestieCorrections` loader for WotLK corrections. Existing CI is inherited but no N-Questie test result has been accepted.

**User goal:** Improve map/minimap quest icons for this customised AzerothCore server, especially allow new or modified quests to be added in a straightforward, repeatable workflow. Initial emphasis: icons for quest starters and turn-ins before attempting full objective automation or progression-aware filtering.

**Implementation today:** Planning/documentation only, on a new feature branch. No runtime Lua, TOC, NPC/quest/SQL data, installed addon, SavedVariables or N-Addon-Collection was edited. An example real missing quest is still required before implementing data.

**Next:** Get a quest ID; inspect narrowly scoped read-only `world` records and exact spawn map/coordinates. Design a deterministic, isolated quest overlay, validate loader/compiled DB behavior and test in game.

**Safety:** Back up installed `Questie-335` and applicable SavedVariables first. Preserve all upstream history, original credits and compatible files. Do not merge/release without maintainer review.

## Entry format for future changes

- **Reason:** What the maintainer observed or requested.
- **Source evidence:** GitHub file/commit, SQL table/query excerpt or in-game screenshot.
- **Change:** Branch/PR, exact files, behavior and compatibility guarantees.
- **Tests:** Automated and in-game outcomes, stating **not run** where appropriate.
- **Rollback:** Addon/SavedVariables backup and commit revert steps.
- **Next:** Highest-priority unresolved item.
