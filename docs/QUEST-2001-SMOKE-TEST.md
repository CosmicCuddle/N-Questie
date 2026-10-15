# First curated N-Questie quest: Ravenclaw Cleanup (2001)

**Status:** Custom quest 2001 marker lifecycle **confirmed in game by the maintainer on 14 October 2026**, on a temporary N-Questie QA addon. Changes remain **draft, unmerged and unreleased**. The private server SQL was inspected read-only and was not committed. Other new level/item corrections have **not** yet received in-game QA.

## Installation smoke test — verified by maintainer on 14 October 2026

**Step 1: PASS (5/5)** on the installed N-Questie QA addon:
- [x] Appears as N-Questie in character-selection AddOns list
- [x] Loads without Lua errors
- [x] Existing world-map quest icons still work
- [x] Existing minimap quest objective icons still work
- [x] Questie settings and existing preferences remain intact

### Verified in-game marker lifecycle — Quest 2001

- [x] Available quest starter displayed at Shadow Priest Allister (NPC 2121), supported by maintainer screenshot.
- [x] Quest objective markers and regular/Shift tooltips referenced Ravenclaw Servants (1868) and Ravenclaw Champions (1869), each initially showing **0/8**, supported by maintainer screenshots.
- [x] Quest became ready for turn-in, with the map tooltip showing **Ravenclaw Cleanup (2001) (Complete)** at NPC 2121, supported by maintainer screenshots.
- [x] After normal hand-in, the completed quest marker disappeared, directly confirmed by the maintainer (no separate screenshot for the removal).
- [x] Ordinary Questie world-map/minimap icons and settings remained functional during the preliminary QA checks.

**Not established by these observations:** individual interim kill-counter increments, independent comparison of every pin against active/phased server spawns, complete minimap-specific behaviour for quest 2001, and IP-stage eligibility on all characters. These remain separate checks. Quest prerequisite 437 is server-authoritative and must not be bypassed for future testing.

**Source reconciliation note:** These observations were preserved from the later nine documentation commits in [draft PR #2](https://github.com/CosmicCuddle/N-Questie/pull/2), which were missing from PR #3's original ancestry. Adding them to this temporary integration branch repairs this stale status text, **not the underlying Git branch ancestry conflict**.

## Exact source-derived quest facts

| Field | Selected acore_world export |
| --- | --- |
| Quest | 2001 — Ravenclaw Cleanup |
| Required / quest level | 12 / 16 |
| Zone | Silverpine Forest, area ID 130 |
| Allowable race mask | 690 (the original server field) |
| Server quest flag | 8 |
| Previous required quest | 437 |
| Starter / ender | Shadow Priest Allister, creature entry 2121 |
| Kill objective 1 | Ravenclaw Servant, creature entry 1868, eight kills |
| Kill objective 2 | Ravenclaw Champion, creature entry 1869, eight kills |

The inherited Questie WotLK NPC database already contains entries for NPCs **2121, 1868 and 1869**, including coordinates on zone 130. No new map coordinates have been invented. **Those Questie coordinates have not yet been compared against each individual active server spawn/phase**, so marker accuracy requires in-game QA.

## Implementation scope

- Custom quest metadata is kept in \`Compat/NQuestieCustomQuestData.lua\`, separated from the large upstream WotLK quest table.
- A generic callback in \`Compat/NQuestieCustomQuestLoader.lua\` registers a quest correction and adds missing quest relations to NPC 2121 **without deleting NPC 2121's existing quest start/turn-in list**.
- NPC kill targets use the existing Questie NPC spawn entries. The client quest log, not this static table, determines how many kills have been completed.
- \`Modules/QuestieInit.lua\` tracks \`nQuestieDataRevision\` and recompiles Questie's saved binary DB whenever the curated records change.
- \`Questie-335.toc\` continues to define the installed WoW addon identity and both Questie SavedVariables. The display name is N-Questie and version \`9.5.1.1\` in this **test branch only**, distinguishing it from upstream v9.5.1.

## Original safe manual QA procedure (partly completed; future regression checklist)

1. **Close WoW** and back up the existing Questie-335 addon folder and the relevant account/character Questie SavedVariables. Do not delete or overwrite them.
2. Install **one copy** of the draft test addon (once a validated QA build exists); do not install two Questies simultaneously.
3. Choose a Horde character that can accept quest 2001 and has completed prerequisite **quest 437**. **Do not edit the character's server progression** to make the test pass.
4. Open Silverpine Forest map and minimap before accepting the quest; look for a quest-start marker near Shadow Priest Allister.
5. Accept the quest if actually offered. Confirm kill-objective markers appear in the Ravenclaw Servant and Ravenclaw Champion areas.
6. After actual objective completion, check the turn-in marker at Shadow Priest Allister. Do not assume static markers prove quest eligibility.
7. Check a few ordinary Silverpine quests for unchanged icons. Reload UI and verify N-Questie settings and progress are intact.
8. Log any discrepancies, map clipping, warnings, wrong faction eligibility, stale cache or missing icons. Restore the backed-up addon directory if necessary.

**Scope of PASS:** Only the specific in-game marker lifecycle above has been observed. Never infer spawn-coordinate precision, all character/IP-stage availability, every kill-counter transition or the safety of newer PR #6/#7/#8/#13 corrections from this one test. Scripted restrictions and nonstandard phasing may require additional checks.
