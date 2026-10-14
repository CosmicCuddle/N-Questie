# First curated N-Questie quest: Ravenclaw Cleanup (2001)

**Status:** Curated quest marker lifecycle **tested successfully in game, 14 October 2026** on the draft N-Questie feature branch. Not merged or released. Server SQL remains private and was inspected locally and read-only.

### Confirmed in-game acceptance (quest 2001)

- [x] Starter at Shadow Priest Allister appears as available (screenshot).
- [x] Map objective pins / regular and Shift tooltips show Ravenclaw Servants (1868), Ravenclaw Champions (1869), each 0/8 (screenshots).
- [x] Completed quest's turn-in NPC shows `Ravenclaw Cleanup (2001) (Complete)` (screenshots).
- [x] After normal quest hand-in, the completed marker disappears (maintainer explicitly confirmed in chat).
- [x] Unrelated Questie world-map/minimap icons, addon load and existing settings remained functional in Step 1.

**Separate verification still needed:** all actual active-spawn coordinates, interim kill-counter transitions, progression-specific availability and the next custom quest. Do not claim an entire server quest audit from this one scenario.

## Installation smoke test — verified by maintainer on 14 October 2026

**Step 1: PASS (5/5)** on the installed N-Questie QA addon:
- [x] Appears as N-Questie in character-selection AddOns list
- [x] Loads without Lua errors
- [x] Existing world-map quest icons still work
- [x] Existing minimap quest objective icons still work
- [x] Questie settings and existing preferences remain intact

**Custom quest 2001 test: NOT YET RUN / NOT YET REPORTED.** An eligible character must meet the quest's actual server eligibility and prerequisite quest 437. Do not bypass progression or mark quest-marker tests passed based only on standard icon functionality.

**Next:** Confirm whether the maintainer can access the quest naturally, then test the starter at NPC 2121, objective markers for NPCs 1868 and 1869, and ender NPC 2121 in the world map and minimap. If not accessible, choose a different ordinary playable custom quest from the private audit. Always back up the previous installed Questie folder and relevant SavedVariables before any subsequent addon replacement.

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

## Safe manual test (pending)

1. **Close WoW** and back up the existing Questie-335 addon folder and the relevant account/character Questie SavedVariables. Do not delete or overwrite them.
2. Install **one copy** of the draft test addon (once a validated QA build exists); do not install two Questies simultaneously.
3. Choose a Horde character that can accept quest 2001 and has completed prerequisite **quest 437**. **Do not edit the character's server progression** to make the test pass.
4. Open Silverpine Forest map and minimap before accepting the quest; look for a quest-start marker near Shadow Priest Allister.
5. Accept the quest if actually offered. Confirm kill-objective markers appear in the Ravenclaw Servant and Ravenclaw Champion areas.
6. After actual objective completion, check the turn-in marker at Shadow Priest Allister. Do not assume static markers prove quest eligibility.
7. Check a few ordinary Silverpine quests for unchanged icons. Reload UI and verify N-Questie settings and progress are intact.
8. Log any discrepancies, map clipping, warnings, wrong faction eligibility, stale cache or missing icons. Restore the backed-up addon directory if necessary.

**Do not mark this test PASS from source analysis alone.** Scripted restrictions and nonstandard spawn/phasing may require further fixes.
