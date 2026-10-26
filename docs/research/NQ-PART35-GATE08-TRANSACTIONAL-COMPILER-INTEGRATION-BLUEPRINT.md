# Part 35 — Gate08 transactional compiler integration blueprint

**Status:** Public-safe DESIGN ONLY, not implemented or approved to merge. **Snapshot:** 26 October 2026. **Source:** protected `335` commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. Related test-only research: [#167](https://github.com/CosmicCuddle/N-Questie/pull/167), [#174](https://github.com/CosmicCuddle/N-Questie/pull/174), [#175](https://github.com/CosmicCuddle/N-Questie/pull/175). Actual precompile-only owner-verifier candidate: unmerged [#177](https://github.com/CosmicCuddle/N-Questie/pull/177).

## Verified production failure boundaries

1. [`Database/compiler.lua`](../../Database/compiler.lua) `CompileTableCoroutine` writes compiled bytes and pointer maps directly to the **live global SavedVariables** independently for NPC, object, quest and item. This yields **four kinds / eight fields** (`npcBin`, `npcPtrs`, `objBin`, `objPtrs`, `questBin`, `questPtrs`, `itemBin`, `itemPtrs`). An error while compiling a later kind leaves earlier kinds published. There is no atomic all-four-kind transaction.
2. This coroutine can return early for invalid data without safely returning its writer stream, and can throw on codec errors. `GetDBHandle` acquires a reader stream **before** its pointer decode and `coroutine.yield()` steps; a failure before a handle is returned cannot safely be cleaned by the absent handle.
3. `QuestieDBCompiler:Compile()` sets `_isCompiling`, invokes all kinds, then marks version, language, compiled flag/count, but lacks a checked `SUCCESS/BUSY/RETRY/ERROR` result and robust error release.
4. [`Modules/QuestieInit.lua`](../../Modules/QuestieInit.lua) Stage1 calls full load, compile and **unconditionally** advances `nQuestieDataRevision` and local compiled state. The new [#177](https://github.com/CosmicCuddle/N-Questie/pull/177) source verifier is *before* this point and is only a precompile check; it does not protect ownership through the compiler's many yields.
5. `QuestieCorrections:Initialize()`, `MinimalInit()` and other source writers can change raw and faction-effective override views. Comparing only raw NPC/GO, only items, or final values after a transient A→B→A mutation is insufficient.

## Required architecture (all conditions, not interchangeable)

**Transaction owner.** Explicit driver-owned object tracks a lock, all acquired **writer and reader** stream leases, input epoch or owned immutable snapshots, four-kind staged bytes and pointer maps, and status. Do not globally monkey-patch `QuestieStream:GetStream` to intercept unrelated Questie subsystems. A Lua 5.1 `pcall` cannot generally protect a coroutine yielding through `coroutine.yield`; the top-level scheduler that calls `coroutine.resume` handles fail/DEAD/abort.

**Source writer boundary.** Before approval and on each compile yield, require either (a) a complete monotonic epoch incremented by *every* source and nested override mutation which can affect output, or (b) compilation from a proven immutable snapshot. If full writer coverage cannot be proven, **keep the production path blocked**. A→B→A must force RETRY despite equality of final values. Full snapshots may exceed 3.3.5a memory budgets: assess on-client, never assume copying all source DBs is cheap.

**Reader and writer lifetime.** Acquire leases before any decode, codec, or yield. Exactly once return streams only when their owning coroutine is DEAD and pool release is known safe. A suspended or poisoned `finished()` stream is quarantined and prevents another compilation until an explicit, tested reset. There is no general safe cancellation of a suspended Lua 5.1 coroutine. A failed pool return after partial mutation must be treated as pool-unknown, not normal retry.

**Four-kind staging.** Per-kind compilers return `{bin,ptrs}` into transaction-local stage for `npc,obj,quest,item`. No live SavedVariables fields or metadata may be touched while building. Run exact codec bounds and readback validation (16-bit map-count and 24-bit ID/pointer limits, supported types, sparse ID considerations, effective source closure). Once complete, recheck source epoch and publish **all eight fields and matching version/language/count/custom revision in one no-yield, non-interleaving critical section**. This gives cooperative in-memory consistency, **not multi-field disk/crash atomicity**. Native SavedVariables restart/save recovery must be designed independently.

**Statuses:**
- `SUCCESS`: all four kinds validated and published once, leases accounted for, metadata and `nQuestieDataRevision` advanced once.
- `BUSY`: another transaction owns compiler; acquire no extra streams; leave compiled state untouched.
- `RETRY`: source epoch drift; preserve old generation, clean only DEAD leases; explicit later retry after eligible source stabilisation.
- `ERROR`: validation/codec/reader/writer failure; preserve previous generation and revision; only safe cleanup.
- `ABORTED_QUARANTINED`: still-suspended coroutine or poisoned stream; do not reclaim/pool the stream or automatically retry.

## Engineering implementation sequence

1. **Preserve baseline and backups:** protect `335`; pin source blobs and capture fixture heads (#167/#174/#175/#177), duplicate client SavedVariables before any future authorised game installation. No private server SQL/source relationships in GitHub.
2. Implement **pure Lua 5.1 lease and transaction driver** on a fresh draft branch, with explicit pass-through to QuestieStream, no unrelated module interception. Model DEAD vs SUSPENDED, `BUSY`, `RETRY` and `ERROR`.
3. Modify source writer API behind a draft flag to stage each `Bin/Ptrs` pair without live assignments. Fix early-return writer leaks and verify all actual 20 root codecs/Questie writer families with source-backed Lua 5.1 and 5.4 tests.
4. Add driver-owned `GetDBHandle` reader acquisition before pointer decode. Test pre-handle pointer failure, post-handle load failure, and exactly-once cleanup.
5. Build either a complete source-writer epoch exclusion or proven immutable input ownership, including *nested* NPC/GO/item/quest relation fields, faction overrides, and late third-party writers. Do not describe #177 as this freeze.
6. Read back all staged kinds, validate expected ownership and detect source epoch drift. Then publish together in a no-yield section, with status, compiled count and custom revision coupled.
7. Verify full CLI and WoW 3.3.5a client: startup duration, RAM/GC/frame, relog/reload, interrupted compile, corrupted SavedVariables recovery, and Individual Progression markers under authorised test conditions.
8. Obtain independent CS02 mutation review and maintainer integration approval. **Only after** full Gate05/08/09 and separately approved gameplay/release gates may quest additions be installed, merged or packaged.

## Acceptance matrix

| ID | Probe | Required observable behaviour |
|---|---|---|
| TX01 | Clean compile NPC/GO/quest/item, full pointer readback | SUCCESS; eight fields coherent; metadata/revision advanced once |
| TX02 | Concurrent compile request | BUSY; no stream acquired; no changed fields |
| TX03 | Invalid NPC during writer stage | ERROR; old eight fields and revision retained |
| TX04 | GO writer fails after NPC stage complete | ERROR; no partial NPC publish |
| TX05 | Quest writer fails after NPC+GO | ERROR; no partial publish |
| TX06 | Item writer fails last | ERROR; no earlier-kind publish |
| TX07 | Pre-handle reader pointer decoding fails | ERROR; DEAD reader lease returned once |
| TX08 | `finished()` fails before/after possible pool mutation | Quarantine poisoned lease; no unproved reuse |
| TX09 | Coroutine suspended when watchdog budget ends | ABORTED_QUARANTINED; fail-closed BUSY; no pool reuse |
| TX10 | Source epoch changes during yield | RETRY, old revision/data unchanged |
| TX11 | Source A→B→A across yields | RETRY, despite same final values |
| TX12 | Approved NPC/GO forward subset or superset | Typed ownership refusal, no revision |
| TX13 | Extra override-only NPC/GO/item reverse owner | Typed refusal, no revision |
| TX14 | Unrelated-only legacy duplicate/sparse reverse array | Tolerated, preserving existing Questie semantics |
| TX15 | Approved-related duplicate/sparse reverse array | Typed refusal |
| TX16 | ERROR after safe cleanup, then repaired input | Next requested compile SUCCESS, no stale lock |
| TX17 | Crash/relog/reload at stage/publish boundary | No mixed generation accepted as valid; conservative recovery |
| TX18 | Full database WoW3.3.5a client profiling | Explicit RAM/GC/frame budget recorded and owner accepted |

These are **required acceptance cases**, not claimed green tests. Only synthetic source-backed portions have prior test evidence; full client and persistence proofs remain missing.

## Dependency and scope warning

This work cannot by itself complete Milestone 10. The [439-record missing-quest programme](../NQ-MISSING-QUEST-COVERAGE-PROGRAMME.md) requires per-quest eligibility/private source and IP evidence. Quests 1207–1209 are only its pilot (0/3 implemented). Do not add automatically, publish NPC/GO/item/loot source mappings, merge, package, install or release based on this design. **Next draft engineering priority:** source-backed transactional staging and driver-owned lease cleanup with TX01–TX11, followed by independent source writer/epoch freeze.
