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
