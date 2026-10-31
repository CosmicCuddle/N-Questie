# N-Questie Part53 — missing-source preprovision acceptance contract (PUBLIC-SAFE)

**31 October 2026. DESIGN/TEST ONLY. NOT APPROVED FOR RUNTIME IMPLEMENTATION, GAME CLIENT QA, PACKAGE OR RELEASE.**

## The actual blocker

On protected N-Questie `335` (commit `26053bd28b0df3a01e5859f779d5f3cb4f57b221`):

1. `Compat/NQuestieCustomQuestLoader.lua` blob `1feb6b5e8a55c68686a4a6bcb9f2355f89454970` calls `parseQuest()` inside `approvedQuests()`. It demands that referenced `npcData`, `objectData`, and `itemData` rows already exist. `approved` is cached on the first call and can be permanently empty for a newly rejected quest until a new loader evaluation.
2. The custom loader currently registers only `questData`, `npcData`, `objectData` correction callbacks. It has **no source itemData provisioner**.
3. `Compat/Compat.lua` blob `b3e273e82cabbd5b7b351ae5aa3d94d4675387be` runs `for dbName in pairs(correctionsRegistry)`; only callbacks **within each group** run in insertion order via `ipairs`. The order between `itemData`, `questData`, `npcData` and `objectData` is **not guaranteed**.
4. `Database/Corrections/QuestieCorrections.lua` `_LoadCorrections()` mutates live working source tables field by field, and `QuestieCorrections:Initialize()` calls the 335 registered corrections after inherited Classic/TBC/WotLK corrections. Simply registering `itemData` callbacks cannot ensure they run before `approvedQuests()`, and cannot promise an all-or-none multi-table update.

Thus a missing item row can reject a genuine quest; adding it later in the same loader lifetime cannot necessarily recover the rejected quest. A placeholder item row may satisfy `hasId()` yet have no verified drops or coordinates. **A correct quest record alone does not fix objective visibility.**

## Owner-private evidence boundary

The owner-private `v4_SOURCE_CLOSURE` audit under `Server-Side-Information / Private N-Questie Quest Audits` has a passing internal consistency verifier for **3 pilot quests, 4 missing NPC, 1 GO and 5 item records**. These are source-closure counts, not native-client proof. No private names/source IDs beyond the historical 1207–1209 quest pilot, coordinates, loot, SQL or source-row schema values may be added to this public repository. Historic 439 raw versus 438 effective quest delta, existing quest 2001 and deferred 30000–30004 remain protected.

## Minimum implementation requirements — proposal, not approval

1. **Source preflight before any approval callback.** Determine the first safe, deterministic post-inherited-correction point. Validate a *complete* candidate batch before mutating `QuestieDB`, including id uniqueness, u24/u8 encoding limits, expected source-field schema, reverse links, drop-source provenance, NPC/GO spawn positions, source collisions, owner exclusions and phase/faction/IP gates. A raw row's existence is insufficient.
2. **Collision-safe provision.** Never overwrite inherited/curated source rows, reject conflicting existing IDs, and preserve all unrelated source attributes and reverse indexes. Fail the entire proposed batch before any writes if any required source or dependency is unresolved; do not allow partial quest or orphan source records.
3. **Fixed order independent of `pairs`.** Only after all source rows are valid and present may `approvedQuests()` first run. Updating late callbacks or resetting an `approved` cache without a coherent source transaction does not meet this criterion.
4. **Complete quest/objective semantics.** Verify 3.3.5a item-objective slot order, positive source drop locations and correct zone-map coordinate decoding against the original real compiler/reader, without inventing health/friendliness fields, text, creature names or unverified drop positions. Resolve owner-private quest text versus required-item-count discrepancies through a separate owner decision before proposing any server SQL change.
5. **Original quest protection and rollback.** Curated quest 2001, existing corrections, cached pointer generation, saved preferences and default filters stay intact. After approval, use an isolated reviewed patch and stage with exact source SHA, backup checksums and rollback. Leave Gate08 publication/persistence separately MAJOR RED.

## Existing executable witness — narrow purpose

[Part53 isolated test source](../../tests/compat/nq_part53_source_preprovision_boundary.lua) uses fabricated IDs, real unmodified loader method execution and fake in-memory QuestieDB. It distinguishes:
- absent item before first approval → reject;
- late item insertion after rejected memoization → still reject;
- all sources present before first approval → admit invented quest, including reverse NPC relation;
- missing NPC despite present item → reject;
- legacy curated quest 2001 preserved;
- placeholder item row satisfies existence check despite unknown real drop locations.

**Execution status:** GitHub source branch holds the TEST-only script; dedicated CI workflow creation was blocked, so this test's actual runtime PASS is **not established**. Do not call it a client, compiler, phase or release test. Existing Part52 #456 has separate verified 12/12 synthetic availability-filter assertions, but it does not cover this source-order witness.

## Coordination

CS02's existing [Gate10 implementation claim](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6543752922) remains intact; CS01 has told CS02 that Part53 work is **TEST-only**, and that private v4 corrects the aggregate NPC count. Do not create a competing implementation. Hold any original-addon/source-data patch for a safely reviewable design and explicit CosmicCuddle authorization. No cross-project Maintenance issue is required solely for addon loader architecture.

**Decisions still needed:** final source-provision architecture, private-data publication strategy, owner handling of quest text/item-count disagreements and separately authorized native testing scope. No completed user-visible missing-quest fix is claimed.
