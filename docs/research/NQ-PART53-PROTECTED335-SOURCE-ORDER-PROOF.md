# N-Questie Part53 — corrected protected-335 source-order witness

**31 October 2026 • PUBLIC-SAFE • TEST/DOCS only • NOT an installable package, production correction or release.**

## Corrected test provenance

A previous Part53 TEST/DOCS branch `test/part53-source-preprovision-lease-boundary-20261031-cs01` was stacked on a long DOCS/TEST history, and its `Compat/NQuestieCustomQuestLoader.lua` did **not** equal protected `335`: different registered callback set, so the new test failed at its first assertion on that stacked branch. Do **not** use the stacked branch to claim an original-loader PASS. [CS02's independent correction and test account](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6544339149) documents the difference.

**This new isolated branch** `test/part53-preprovision-335-source-proof-20261031-cs01` starts **directly from** protected `335` at `26053bd28b0df3a01e5859f779d5f3cb4f57b221`. The loader's **exact Git blob** is `1feb6b5e8a55c68686a4a6bcb9f2355f89454970`, matching the protected 335 loader. The parent regression source at `7aa25eba5c9fbd8f081f15cd3c64f9fcc31bafdc` was byte-identical to the earlier Part53 TEST fixture (`ee39511806997f4a4f8818485899c3c9cfe393b1`). This separate child branch adds three new test assertions covering the public 2001 prerequisite-437 exception; the new test blob and execution status differ from that reviewed parent. No original addon Lua/TOC or world data was edited.

## Existing real execution evidence

CS02 independently ran the **original 12-assertion parent regression**, byte-identical to the Part53 original fixture, against the protected 335 loader with Lua 5.1 and 5.4: **12/12 PASS on both**, exit code 0. The **15-assertion child version has NOT been executed or confirmed passing**; do not transfer the parent's PASS to this child. CS02 also confirmed three source mutations were detected (unconditional `hasId`, extra `itemData` callback, and removed memoization return). One deliberate `quest 2001/437` exemption deletion survived because the original fixture supplies quest 437 as an existing raw quest, rendering that mutant equivalent for the 12-assertion parent. The child now additionally tests the protected 2001 exception when the raw 437 entry is absent. Its ability to kill that mutation requires independent execution. **Do not claim 4/4 mutation coverage.**

CS02's 12/12 result is only for the parent protected-335 regression, **not a fresh GitHub Actions run on either new branch**, nor a genuine 3.3.5a client run. The 15-assertion child is unexecuted at this checkpoint, although it still points to the unchanged exact protected-335 loader. A dedicated CI workflow was not added because a previous attempt was blocked and existing pull-request triggers can generate unauthorized addon ZIP artifacts. No PR created.

## Source-backed loader-order blocker

- The original loader requires referenced NPC, GO and item source rows before `approvedQuests()` evaluates. `approved` memoizes the first result.
- A missing item/NPC row rejects an otherwise valid quest; a later row cannot rehabilitate its earlier cached rejection in the same source-loader lifetime.
- `QuestieCompat.LoadCorrections()` iterates correction database groups with `pairs`, so merely registering another `itemData` callback cannot ensure it runs before validation.
- `QuestieCorrections:Initialize()` applies correction tables against the mutable raw QuestieDB, not a preflighted transaction. **Do not use unreviewed partial source writes, global filter bypass, or dummy source positions.**

## Next acceptance design

**Proposal only, subject to CosmicCuddle approval:**
1. Validate every candidate source addition and quest dependency before any change, rejecting conflicts with inherited corrections and existing curated content.
2. Set a deterministic preprovision phase before first `approvedQuests()` in the **fresh compile path**, with coherent source/quest/reverse indexes and no partial admission on error.
3. Verify real 3.3.5a item objective ordering, source drop/GO/NPC coordinate provenance and faction/IP eligibility from owner-private v4 audit; do not infer any field.
4. Test original 2001, owner-deferred 30000–30004 exclusions, compiled lookup, cache invalidation/relog, and phase restrictions. Gate08 publication/stream/SavedVariables safety remains **MAJOR RED**.
5. Obtain explicit owner consent and exact backup/rollback before any actual client or server testing.

## Ownership / confidentiality

CS02 retains the [1207–1209 Gate10 implementation claim](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6543752922). The owner-private v4 source-closure package lives in the private Library `Server-Side-Information / Private N-Questie Quest Audits`, not in public GitHub. It identifies 4 NPC + 1 GO + 5 item missing source candidates and 3 quest records; those rows and coordinates must remain private. The v4 internal verifier passed, but no pilot quest is installed or accepted in-game.

**Immediate next step:** use this exact protected-base regression as a reference and allow CS02 to review the deterministic preprovision requirements before any privately staged data authoring.

## 31 October 2026 addendum — independent CS02 execution and raw-ID 2001 collision guard

[CS02's latest independent review](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6545138574) **VERIFIED 15/15 PASS on actual Lua 5.1 and 5.4** for previous fixture `8f0a51a8586c340362d249423898762cba8e267b`, in addition to the 12-check parent. Mutation challenge M1 (drop 2001/437 exemption) and M3 (change 437 to 438) were killed on both Lua runtimes. M2 (remove 2001's narrow exception for an **already occupied raw questData[2001]**) survived because no previous fixture supplied a raw 2001 row; this is a test-coverage gap, **not a demonstrated addon defect**. The earlier section describing the 15-assertion child as unexecuted is superseded by this dated independent result.

**This current child** `test/part53-public2001-raw-collision-contract-20261031-cs01` adds exactly **three** more synthetic assertions: existing raw 2001 is present, original public 2001 still approved, and raw source 2001 untouched. This produces **18 total checks**. **18-check execution and mutation coverage are NOT YET VERIFIED.** It does not alter `Compat/NQuestieCustomQuestLoader.lua`, any addon runtime module, the addon TOC, real source rows or SavedVariables.

**Effective source collision limitation:** Read-only reviewed protected-`335` source files `classicNPCFixes.lua`, `tbcNPCFixes.lua`, `wotlkNPCFixes.lua`, their three ObjectFixes counterparts and three ItemFixes counterparts (nine files) for literal bracketed table-key definitions corresponding to the ten owner-private pilot source candidate IDs (4 NPC / 1 GO / 5 item). **No matching literal `[sourceId] = {` correction definition was found** in that narrow static scan. This does **NOT** establish runtime-effective absence: `QuestieWotlkItemFixes:Load()` calls `InsertMissingItemIds()` and directly mutates working itemData; `QuestieWotlkNpcFixes:LoadAutomatics()` adds a separate correction table, plus inherited conditional faction corrections and any external addon source mutator. Source records must be checked **after real inherited 3.3.5a corrections execute** and before owner-private source provision; a raw-DB or regex-only gap is not a collision proof.

**Coordination blocker:** CS02 [confirmed in the same review](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6545138574) they cannot access the owner's private Library; their claimed 1207–1209 implementation is on hold until an **owner-authorised private handoff**, never a public GitHub post. The owner-private audit is already preserved in `/Server-Side-Information/Private N-Questie Quest Audits/`; no re-upload of `acore_world.zip` is needed in this project. No implicit permission to disclose those records to an external collaborator. Gate08 stays MAJOR RED.
