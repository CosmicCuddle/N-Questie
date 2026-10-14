# N-Questie — Dustwallow Marsh Quest Comparison

**Date:** 14 October 2026
**Status:** Curated offline read-only comparison. Proposed client corrections remain **draft, unmerged, unreleased**.

## Sources and limits

- Server: user-provided **private** offline HeidiSQL acore_world.zip (not published).
- Client: inherited 3.3.5a Database/Wotlk/wotlkQuestDB.lua, with checked Classic/TBC/WotLK literal level correction tables.
- Compared server quests assigned QuestSortID 15 (Dustwallow Marsh) for nominal quest level, minimum required level, and IDs of required item objectives.
- Questie can represent or override objectives through other mechanisms. Candidate item differences are not automatically fixes.
- Client-dependent and Individual Progression eligibility rules still require separate review.

## Results: 134 server records in this zone

- 126 quest IDs were located in the original WotLK Questie quest table; 8 were absent from that raw table (some may be deprecated/unused).
- **8** server-versus-Questie nominal or minimum level differences were found.
- **32** candidate required-item-ID differences were found. **One** of those (Jarl Needs a Blade, 1203) is independently reviewed and fixed in [draft PR #6](https://github.com/CosmicCuddle/N-Questie/pull/6); the remaining candidates need source-by-source analysis.
- One quest was counted in both the level-difference and item-difference categories. Do not add category totals and treat the sum as unique broken quests.

## Reviewed level differences proposed in this PR

| Quest ID | Name | Questie minimum | Server minimum | Questie quest level | Server quest level |
|---|---|---:|---:|---:|---:|
| 1166 | Overlord Mok'Morokk's Concern | 37 | 38 | 41 | 43 |
| 1168 | Army of the Black Dragon | 37 | 38 | 41 | 43 |
| 1169 | Identifying the Brood | 37 | 38 | 41 | 43 |
| 1170 | The Brood of Onyxia | 37 | 38 | 41 | 43 |
| 1171 | The Brood of Onyxia | 37 | 38 | 41 | 43 |
| 1172 | The Brood of Onyxia | 37 | 38 | 41 | 45 |
| 1205 | Deadmire | 35 | 35 | 41 | 45 |
| 1252 | Lieutenant Paval Reethe | 30 | 30 | 35 | 40 |

**Safety rule:** only these explicitly reviewed existing-quest level fields can be updated, and only when the inherited Questie record still contains the expected original minimum/quest level values. Any unexpected upstream or server-specific state is left alone.

The module does not manually set red/green colour. It updates the actual quest level so Questie's standard PrintDifficultyColor uses the corrected value relative to the player's level.

## Separate objective correction: Jarl Needs a Blade (1203)

- Quest 1203 itself already matches the server's QuestLevel=35 and MinLevel=30.
- The server requires **1 Moonsteel Broadsword (3853)**, rather than the inherited WotLK Questie item objective Razorspine's Sword (33110).
- [Draft PR #6](https://github.com/CosmicCuddle/N-Questie/pull/6) proposes the isolated item objective/text fix; the item must still be tested in game.
- Leave all starter/ender relationships and prerequisites untouched.

## Follow-on audit

1. Investigate the remaining 31 **item-difference candidates**, considering source items, scripted objectives and client Questie conventions before proposing corrections.
2. Verify the 8 raw-Questie-missing zone IDs and distinguish true custom quests from placeholders or obsolete records.
3. Extend the same read-only comparison across every zone and server-specific quest ID. Preserve full private SQL and private audit JSON outside GitHub.
4. Review dynamic quest levels (-1), Individual Progression gating, quest conditions, NPC/gameobject objectives and quest chains separately. A static SQL mismatch does **not** establish actual character eligibility.

## Test and approval gates

- Lua 5.1 syntax and mocked field-level regression must pass.
- Verify Questie's normal map markers, objective tooltips and quest colour changes on an eligible client character.
- No automatic live SQL updates, progression edits, SavedVariables resets, addon replacements or bulk quest table regeneration.
- Explicit maintainer approval is required before merge, release or N-Addon-Collection update.
