# N-Questie — Hillsbrad Wanted Quest Review

**Date:** 14 October 2026  
**Status:** Read-only source investigation; **no correction applied**.  
**Owner:** Lead quest-data workstream; Grok is separately responsible for M1 objective validation and M0 integration.

## Why these two deserve a separate review

Questie 3.3.5a currently uses a very permissive minimum level for two Horde wanted-poster quests in Hillsbrad Foothills. The Naxxramas AzerothCore `acore_world` export uses higher `MinLevel` values. In particular, Baron Vardus's minimum level differs by **18 levels**. A mistaken minimum-level correction affects map availability markers, so the correct approach is to verify the server links and conditions before publishing an addon fix.

## Source-verified findings (private world export vs installed Questie)

| Field | WANTED: Baron Vardus (566) | Dangerous! (567) |
|---|---|---|
| Server `MinLevel` | **35** | **19** |
| Installed Questie `requiredLevel` | 17 | 17 |
| Server `QuestLevel` | 40 | 28 |
| Installed Questie `questLevel` | 40 | 28 |
| Gameobject quest starter | **1763** | **2008** |
| Creature quest ender | **2215** | **2215** |
| Server `PrevQuestID` | 0 | 0 |
| Server race mask | 690 | 690 |
| Server objective | Item **3626** ×1 | Kill creatures **2448, 2449, 2450, 2451** (each ×1) |

The **installed Questie source** agrees with the exported server's gameobject starter IDs, ender NPC, nominal quest level, race mask and item/creature objective **target IDs**. Only the minimum acceptance level differs in this focused comparison. The full inherited Classic, TBC and WotLK numeric correction-layer audit found **no direct literal minimum-level override for either quest ID**.

A read-only scan of **17,701** exported `conditions` rows found no row explicitly containing the numeric quest IDs **566** or **567**. This does **not** prove unrestricted availability: a condition may be attached to the starter object or ender NPC, and Individual Progression / SmartAI or other server scripts can impose additional state- or era-specific rules.

## Why this remains a candidate, not an automatic correction

The differences `17 → 35` for 566 and `17 → 19` for 567 are **confirmed static data mismatches**, but that alone is not proof of the exact in-game marker display or IP-era eligibility.

Before implementing an optional field-level `requiredLevel` correction:

1. **Check module restrictions:** Review relevant Individual Progression / server conditions for gameobjects 1763 and 2008 and recipient NPC 2215 where possible.
2. **Use the real effective Questie 3.3.5a validator:** Verify the inherited `requiredLevel` remains 17 after dynamic corrections, not just in the source file. Coordinate with Grok's M0 workstream.
3. **Preserve objective semantics:** Do not change either quest's item/NPC kill objectives, gameobject starter or turn-in links, which match the server ID associations in this offline comparison.
4. **If approved for staging:** Emit a source-guarded minimum-level-only fix on a separate draft branch, bump `NQuestieCustomQuestData.revision` and use synthetic plus real-database regression tests.
5. **Before any in-game QA:** Back up the current `Interface/AddOns/Questie-335` and the Questie SavedVariables. Verify character-stage eligibility and marker behaviour with the maintainer.

**No changes to the live server, installed addon, character progression, database or SavedVariables; no merge/release approval.** The original private SQL ZIP and the full private audit remain off GitHub.
