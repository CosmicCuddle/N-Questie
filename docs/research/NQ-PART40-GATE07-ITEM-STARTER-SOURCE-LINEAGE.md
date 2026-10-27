# Part 40 Gate07 — Public item-starter source lineage research

**Status: PUBLIC-SAFE, test-only, 27 October 2026. Native 3.3.5a item-start eligibility, quest interaction, owner Individual Progression and runtime acceptance remain OPEN.**

## Actual public source observations

- `Database/questDB.lua` declares quest `startedBy` as key `2`, compiled as `questgivers`, and `sourceItemId` as a **different** key `11`.
- `Database/itemDB.lua` declares reverse item `startQuest` key `5`, type `u24`, and includes this in the compiler order. The dedicated test **executes this public schema**; it does not read actual item records.
- `Database/QuestieDB.lua`'s public `GetQuest` function constructs `QO.Starts = { NPC=startedBy[1], GameObject=startedBy[2], Item=startedBy[3] }`. The dedicated fixture extracts and runs that **exact assignment snippet** from the source file with invented arrays, but does **not** run the whole `GetQuest` implementation.
- `Modules/Quest/AvailableQuests.lua` has direct drawing loops for NPC and GameObject starter sources and no matching item-map marker path in `DrawAvailableQuest`. The dedicated test loads and calls **the real renderer** under fictional public stubs. That absence of a map marker does **not mean the item-started quest is missing, invalid, ineligible or unstartable**.

The [public source-backed test](../../tests/compat/nq_gate07_public_item_starter_lineage.lua) checks synthetic item-only, multiple items, item+NPC, item+GO, all three kinds, unresolved NPC/GO plus item, unambiguous tooltips, and no added fabricated item pins. It distinguishes quest `sourceItemId` (a provided quest item) from `startedBy[3]` (an item that starts the quest). All fixture IDs and coordinates are *invented*; logs emit only the aggregate control count and limitations, not raw IDs or source relations.

A dedicated GitHub workflow validates syntax and those controls with actual Lua 5.1.5 and Lua 5.4.6. It uploads no artifacts or releases. Original-head run status and all artifact endpoints must be verified before a green statement.

## What this cannot establish

- Running only the `GetQuest` assignment fragment does not validate `GetQuest`'s full objective construction, pointer/codec decoding, correction layering, faction overrides or late writers.
- The actual client may start an item quest via inventory UI rather than a map marker; this has **not** been measured. No reverse item-start mapping is asserted correct against the owner's private server.
- `itemDB.startQuest` existing in the schema does not prove correct matching, one-to-one direction, loot source, source item inventory ownership, faction/IP phase, or all-writer A→B→A consistency.
- Actual server quest eligibility, how item loot/use grants or starts the quest, persistent client completion cache, and missing quest pilot 1207–1209 are not determined.
- No live 3.3.5a GUI, frame, memory or relog evidence has been collected. Owner-private data must never be moved into public CI.

## Next bounded proof obligations

Independently mutate `startedBy[3]` to `[1]` or `nil`, remove item `startQuest` from the public compiler order, divert one item-only path into fabricated NPC/GO map drawing, and remove an NPC or GO from a mixed starter. Run both Lua interpreters and extracted CI-step, then revert all mutants. Keep the native item-starting and phase correctness gates RED until authorized owner-side verification with backups.

**Project state unchanged:** 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; 439 RAW records require individual triage and eligibility is unknown; pilot 1207–1209 still 0/3 implemented. Protected `335` remains `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. Gate08 source epoch, global QuestieStream pool, four-kind atomic publish and SavedVariables crash/relog are RED. No merge, installation, artifact package, tag or release.
