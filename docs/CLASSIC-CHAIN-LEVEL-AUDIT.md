# N-Questie — Reviewed Classic Quest Chain Levels

**Date:** 14 October 2026
**Status:** Draft proposal, no in-game QA or merge authorised.
**Scope:** Existing Duskwood and Wetlands quest chains; field-level corrections only.

## Evidence and review method

The maintainer supplied a private **offline** AzerothCore `acore_world.zip` export and their installed 3.3.5a Questie WotLK quest data. The installed `wotlkQuestDB.lua` matches the public N-Questie source Git blob `abbf2831b6d6b54b5d9383ba2c3e5cce5147379d`.

This batch was checked against the private server's `quest_template.MinLevel` and `quest_template.QuestLevel`, `quest_template_addon.PrevQuestID`, and `creature_queststarter`, `creature_questender`, `gameobject_queststarter`, `gameobject_questender` associations, then compared to the installed Questie source's initial levels, links and predecessor chain.

Only the nine individually curated quest IDs/level pairs below are published. **Never commit or share the full private world archive or seven-tab private audit workbook publicly.**

## Duskwood — Mor'Ladim chain

| Quest ID | Name | Questie required / nominal | Server required / nominal | Server preceding quest |
|---:|---|---|---|---:|
| 225 | The Weathered Grave | 25 / 30 | **28 / 35** | None |
| 227 | Morgan Ladimore | 25 / 30 | **28 / 35** | 225 |
| 228 | Mor'Ladim | 25 / 30 | **28 / 35** | 227 |
| 229 | The Daughter Who Lived | 25 / 30 | **28 / 35** | 228 |
| 231 | A Daughter's Love | 25 / 30 | **28 / 35** | 229 |

**Starter/turn-in preservation:** Quest 225 starts at gameobject **61** (the grave) and ends with NPC **268**. Quest 231 starts with NPC **576** and ends at gameobject **61**. Intermediate NPC links and all five `preQuestSingle`/chain fields stay inherited from Questie.

**Inherited correction check:** `Database/Corrections/tbcQuestFixes.lua` has a literal `requiredLevel = 25` for quest 225, which **does not change** the original WotLK 25 / 30 pair. That value was explicitly considered when preparing the source-value guard. The other four IDs have no direct numeric inherited level override in the checked Classic/TBC/WotLK static correction tables.

## Wetlands — Nek'rosh sequence

| Quest ID | Name | Questie required / nominal | Server required / nominal | Server preceding quest |
|---:|---|---|---|---:|
| 473 | Report to Captain Stoutfist | 23 / 26 | **23 / 28** | None |
| 464 | War Banners | 23 / 26 | **23 / 28** | 473 |
| 465 | Nek'rosh's Gambit | 23 / 26 | **23 / 31** | 464 |
| 474 | Defeat Nek'rosh | 23 / 26 | **23 / 32** | 465 |

**Starter/turn-in preservation:** The starter/turn-in links progress through NPCs **2086** and **2104**, with gameobject **1609** involved in the latter two quests. Existing item objectives, conditions, next-in-chain fields and gameobject links must not be altered.

## Proposed correction implementation

- `Compat/NQuestieReviewedClassicChainLevels.lua`: 3.3.5a-only callback for these nine existing quest IDs, returning only `requiredLevel` and/or `questLevel` changed fields.
- The callback refuses to overwrite a quest if either of its inherited numeric fields does not match the reviewed baseline. It does not touch any quest starter/end marker, quest name, objective, race/class filter, reputation, faction, prerequisite or exclusion.
- `Compat/NQuestieCustomQuestData.lua`: compiled-data `revision = 5` (increased from 4, since this branch is stacked on the earlier 11-quest draft PR #8).
- Lua 5.1 regression: nine expected IDs, source-value guards, no unrelated field writes, preservation of predecessors and synthetic GO/NPC relationships.
- Python public-source regression: all nine nominal/minimum source pairs; static TBC correction for 225 recognised, and any new numeric correction for these IDs causes review.
- Dedicated `.github/workflows/nquestie-overlay.yml` job and PR-only QA packaging updated.

**Colour and availability are different concepts:** Questie derives difficulty colour using a player's actual level versus the corrected nominal level. Server `MinLevel`, IP stage, conditions and character quest history can additionally affect whether a character may pick up a quest. This patch does **not** force a colour or predict progression-phase eligibility.

## QA / integration gates

1. Dedicated Lua 5.1 / baseline test run must pass on this draft branch.
2. Grok owns the separate M0 real-3.3.5a effective-DB validation harness in [draft PR #9](https://github.com/CosmicCuddle/N-Questie/pull/9). When branches are coordinated, add these nine per-ID/field allow-list values, verify exact pre/post levels and compiled read-back **without disabling preservation assertions**.
3. The independent inherited Busted fixture repair from [draft PR #4](https://github.com/CosmicCuddle/N-Questie/pull/4) remains unmerged. Full combined inherited CI is not yet green.
4. In-game tests must first back up the working `Interface/AddOns/Questie-335` addon folder and Questie SavedVariables; verify NPC/GO start/end pins, objective tracker, prerequisite chain, and normal difficulty colours on eligible characters.
5. No live world SQL change, installed-addon replacement, SavedVariables reset, character state changes, releases, merges, `335` updates or N-Addon-Collection modifications without explicit maintainer approval.

## Intentionally deferred

The next review queue includes WANTED: Baron Vardus (quest 566) and Dangerous! (567) in Hillsbrad. Quest 566's large minimum change (17→35) merits separate progression/conditions review; neither Hillsbrad record is modified in this batch.
