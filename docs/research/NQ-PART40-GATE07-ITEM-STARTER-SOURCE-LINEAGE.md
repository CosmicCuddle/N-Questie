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

## Scope-correction: stale documentation ancestry vs protected 335 (historical failure retained)

The first two dedicated original-head runs on this test-only draft **FAILED** and must not be relabelled green:
- First head `d7e0677e5bc4231d4928045ec989cafc34e87d66`, [run 40602947536](https://github.com/CosmicCuddle/N-Questie/actions/runs/40602947536): the fictional schema fixture did not install the `QuestieLoader:ImportModule("QuestieDB")` stub before loading real `itemDB.lua`; harness error.
- Second head `0f73b56965e249d5b4d2e0904301eb3b0794b637`, [run 40603050388](https://github.com/CosmicCuddle/N-Questie/actions/runs/40603050388): the draft's documentation ancestor #248 contains an **older** `Modules/Quest/AvailableQuests.lua` which dereferences an unresolved NPC/GO lookup. Protected `335` SHA `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` already has explicit `if npc and npc.id` and `if obj and obj.id` guards. This failure is a **source-baseline mismatch** and is **not** a new defect discovered in protected 335. The historical failed-head result is preserved.

To test the right production source **without changing protected 335 or importing its release-packaging workflow**, the dedicated CI now fetches that *exact immutable public protected commit* into a temporary runner directory, verifies the fetched commit SHA, copies the four **public source files** using `git show`, and sets `NQ_G07_SOURCE_ROOT`. The draft Lua fixture requires that variable and executes the public schema and actual renderer from the pinned directory, while the test/workflow/documentation live exclusively on a safer documentation-ancestry draft branch. No temporary files are committed or uploaded. All four production source inputs are from a **single** protected commit, avoiding mixed-version attribution.

The test still executes only a `GetQuest` assignment excerpt, not the whole function. Lua VM/CI result, every artifact endpoint, and CS02 mutation review must be rechecked on the NEW exact head. No early green claim.
