# Part 41 Gate 04 — pinned public manifest registration and late-writer lifecycle

**Status 28 October 2026: PUBLIC-SAFE TEST ONLY, NOT A PRODUCTION FIX, NOT RELEASE APPROVAL.**

## Exact real public source used

The test stages the **unmodified, complete** protected-335 `Compat/NQuestieCustomQuestLoader.lua` and the public `Compat/NQuestieCustomQuestData.lua` from commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. It checks Git tree and temporary staged bytes against independent literal Git blob SHA-1 identities:
- Loader: `1feb6b5e8a55c68686a4a6bcb9f2355f89454970`.
- Public manifest: `1d48353b796bdccd179b7aaa964cba21d6d0462c`.

The actual loader chunk is executed unmodified in a fresh, separately constructed Lua 5.1/5.4 global environment. Only stub QuestieDB public schema keys and **entirely invented** quest/NPC/GO records are supplied to its runtime. The pinned public manifest is loaded separately and checked for revision/one-record shape; its existing public quest relationships are never logged or imported into the invented cases. No owner SQL, item/loot relationship, Individual Progression/phase data, account or SavedVariables is read or published.

## Narrow positive and rejection tests

16 public fixture controls (once CI is proven) cover absence of QuestieCompat, non-3.3.5a mode, missing registration callback, missing/invalid manifest, public manifest pin, registration of precisely quest/NPC/object correction callbacks (never item), valid invented quest+reverse role preservation, unknown policy field rejection, unsupported item-start schema rejection, unresolved NPC rejection, distinct NPC and GO start/finish, all **six** correction callback call orders and no direct mutation of source database records by the emitted correction callbacks.

**Important: expected unsafe observations are NOT safe-pass results.** The final two synthetic controls deliberately mutate a fictional accepted record AFTER the first correction callback has memoized `approvedQuests()`:

1. An approved manifest table retains an alias in `entry.data`. A later unregistered change of `requiredLevel` from valid 20 to invalid 300 can then be copied to an emitted quest correction without calling `parseQuest` again. This is a **source-lifecycle vulnerability witness under the invented mutation schedule**, not proof that such a change happens on a real client.
2. Removing an invented NPC source row after the approval cache is populated can leave a quest correction published while its matching reverse source correction is absent. This is a **coherence risk witness**, not a confirmed real gameplay bug.

These are *deliberate KNOWN UNSAFE reproductions* of the current public loader's mutable-reference and source-ownership limits. A later real fix should reverse the expected outcomes; passing this current test **does not accept the defect**. In particular, forbidding unknown late writers, capturing coherent owned input or invalidating the cache requires a **complete source-writer ownership contract**: a cosmetic root epoch or final-value comparison cannot detect arbitrary nested writes and A→B→A.

## Review request and remaining work

- CI must run actual Lua 5.1.5 and 5.4.6, verify the three exact output lines and both source blobs, check the original HEAD and individual artifact endpoints. Historical failures and mutation survivors must remain visible.
- Independent CS02 comment-only challenge **after** already assigned #260/#263 work: delete or bypass the `Is335` guard, allow an unknown manifest key or unsupported item starter, swap distinct NPC/GO start/finish indexes, weaken the six-order matrix and attempt to remove or mask either known-unsafe witness. Report baseline PASS and mutant outcomes on actual Lua 5.1/5.4, revert all mutations and do not push or merge.
- **No claim of full source writer exclusion:** unknown built-in/third-party addon writers, E01–E08 A→B→A, effective faction/override-only records, 3.3.5a client memory and timing, actual item use and server/IP eligibility remain RED. G08 global QuestieStream lease quarantine, complex codecs, atomic four-kind Bin/Ptrs + metadata publication and real SavedVariables crash/relog remain separately RED.
- The 439-RAW quest investigation retains its 12 source-linked / 418 exploratory / 5 owner-excluded / 3 placeholders / 1 already-handled overlay buckets; owner-approved eligible denominator unknown, pilot quests 1207–1209 are **0/3 implemented**. No bulk additions.

**Governance:** standalone source-backed test-only draft, no production addon code, protected `335` unaffected. All PRs draft and unmerged. No merge, install, package, tag, release or owner-private data publication without separate authorisation.
