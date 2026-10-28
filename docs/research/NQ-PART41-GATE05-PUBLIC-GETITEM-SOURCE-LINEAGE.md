# Part 41 — Gate 05 public GetItem adapter lineage (TEST ONLY)

**28 October 2026. Public source, imaginary fixture IDs, no private server data.**
This is an isolated child of draft PR #260, exact source parent `2afeebd06c2909c42966edcad7f66555c561830e`. It changes no shipped Questie Lua code and grants no integration/install/release authority.

## Actual public source and test boundary

The dedicated test extracts the **actual complete public** `QuestieDB:GetItem(itemId)` function from `Database/QuestieDB.lua` on immutable protected-335 commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, preserving the exact original body. It executes the actual `Database/itemDB.lua` schema from that same source, while `Database/questDB.lua` supplies an independently asserted public forward-quest schema reference.

The workflow checks commit identity plus three **Git blob SHA-1** identities (both tree path and staged temporary bytes): itemDB `a714c1a11ce0513276de3f9ce9015d7db22efa80`, questDB `9503b16031e739d9c0f046939058229b1a18d9b1`, QuestieDB `5784cb65160175e1dce30fe20e8baada0af7e480`. This verifies **exact source-file contents in CI**, not future third-party writers or a trustworthy runtime epoch.

The fixture supplies **invented records only** to a stub `QueryItem` and runs 14 named positive/negative controls in real Lua 5.1 and 5.4 on Actions. Controls cover nil/zero/missing item guard, `startQuest` retention, NPC drop and vendor `monster` sources, object `object` sources, mixed entries independent of `pairs` ordering, retained `itemDrops` without a fabricated `GetItem.Sources` item entry, questRewards/relatedQuests retention, blacklist `Hidden`, cache bypass and missing startQuest. The schema identifies `startQuest` as item field 5 (`u24`), different from quest `startedBy` field 2 and `sourceItemId` field 11. Controls report only aggregate counts and scope statements.

## Important lineage distinction

`GetItem.Sources` is a list of **where an item is documented as obtainable** via the currently inspected NPC drops, vendors and gameobject drops. It is **not** proof that an item starts a playable quest, a full reverse quest-owner index, or even a complete inventory of item acquisition chains. The function currently copies `itemDrops` into its item record but does **not** convert it into an entry in `Sources` in this code path; do not infer that missing item-drop Sources means absent loot, a bad quest, or incorrect private server data.

A returned `startQuest` scalar does not establish that the matching quest's `startedBy[3]` includes that item. The test does not compare actual server/item/loot relationship IDs and must never fabricate those as public truth. Item-only availability is distinct from the Gate 07 map-pin test in #258/#260, actual start/use mechanism, completion history and Individual Progression phase approval.

## Required independent review and RED items

Review exact Lua source-extraction boundary, original-head Actions runs and each run's artifact endpoint. Independently mutate: drop `startQuest` copy, remove NPC/vendor/object Source loop, mislabel an object source, manufacture itemDrops Sources, omit the cache guard, replace the expected blob pin or append a harmless comment to staged source. Mutants must be reverted; report equivalent/surviving cases instead of claiming a proof by fixture count.

**Unverified:** complete `GetQuest` and item/quest bidirectional consistency, effective override-only rows, faction and late writer semantics, all 439 RAW quest dispositions, private IP/history/loot eligibility, native WoW 3.3.5a use/start/relog, global stream ownership, atomic four-kind publication and saved-variable disk recovery. No production merge/install/package/tag/release.

**Whole-project state remains:** G01–G03 complete, G04–G09 underway, G10–G12 technically pending (3/6/3); 439 RAW records are research only (12 linked, 418 exploratory, 5 excluded, 3 placeholders, 1 handled overlay), eligible count unknown; pilot quests 1207–1209 = 0/3 implemented.
