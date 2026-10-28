# Part42 Gate08 — actual GetDBHandle reader suspension and global QuestieStream pool

**Date:** 28 October 2026. **Scope:** PUBLIC-SAFE, TEST-ONLY isolated draft. No protected-335, production, private game data, install, package, release, or SavedVariables changes. This is a diagnosis, not an accepted fix.

## Authentic unmodified public source

The dedicated GitHub Actions job must fetch exact protected-335 commit [`8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`](https://github.com/CosmicCuddle/N-Questie/commit/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070), verify the tree blobs **and** the staged temporary files:

| Source | Pinned Git blob | Scope executed |
| --- | --- | --- |
| [`Database/compiler.lua`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/compiler.lua) | `abba0249f44d14711dbdd46bbde969ccffbc2963` | Exactly extracted, unmodified `DecodePointerMap` and full `GetDBHandle` function bodies |
| [`Modules/QuestieStream.lua`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Modules/QuestieStream.lua) | `1819aeea11148eae0742810dbd2338410edda238` | Entire module, including its actual module-local `StreamPool`, `GetStream`, `finished`, `Load`, raw byte readers |

The **fictional** one-entry pointer payload is `00 01 00 00 07 00 00 01` (one pointer, synthetic ID 7, offset 1). The invented data byte is `41` (ASCII A); it is not a real quest, NPC, item, server mapping, SavedVariables file, or player's data. A minimal `readers.u8`, `skippers` and `min` binding makes these exact real functions runnable outside WoW; a pure-Lua `bit` shim and scoped `tremove=table.remove` are solely host-environment parity, not global/runtime source patches. No `QuestieStream:GetStream` monkey-patch is used.

## Falsifiable controls

The Lua fixture requires **exactly 16 labelled checks**, run separately on actual PUC **Lua 5.1** and **Lua 5.4** in GitHub Actions. Each assertion is fail-fast, with a strict CI output-census gate. These controls address:

1. Real function bodies and required acquisition/return anchors, not an invented pool.
2. Reader acquires an actual pooled object **before its first coroutine yield**.
3. A second live global-pool borrower remains distinct while the reader holds the stream.
4. Second suspension occurs after the real pointer blob is loaded.
5. A further suspension happens **inside the actual `DecodePointerMap`** after reading the one invented pointer.
6. The subsequent reader suspension still retains the same pool object.
7. Returned handle holds the same real stream and decoded pointer.
8. The actual returned `QuerySingle` succeeds for the invented byte and refuses an unknown ID.
9. Actual `Query` and `QueryValidator` access the tiny invented data.
10. Another active caller writing to a separate stream does not alter the reader's byte.
11. An unfinished live handle is not reissued by the global pool.
12–13. **EXPECTED KNOWN UNSAFE, invalid external caller schedule:** forcibly calling `finished()` on a still-suspended `GetDBHandle` reader reissues that exact object to another subsystem; when the original reader resumes, its real `Load` replaces the borrower's content. Passing these assertions documents vulnerability **under forbidden synthetic misuse**, not evidence native client follows that schedule.
14–16. A deliberately truncated pointer blob terminates the real decoder coroutine with an error before returning a handle; the primed borrowed stream is not automatically returned, and the caller has no returned handle for recovery. This is an in-memory failure-path lifetime observation, not durable crash recovery.

The workflow forbids a ZIP/release artefact. If any named assertion fails, preserve the original failing commit and full run logs rather than rewriting it, and place subsequent correction on an isolated child.

## Boundaries and next design conditions (still RED)

This improves on frozen [#272](https://github.com/CosmicCuddle/N-Questie/pull/272) (real compiler but toy stream) and [#275](https://github.com/CosmicCuddle/N-Questie/pull/275) (real pool, invented caller coroutines, no actual `GetDBHandle`). It does **not** execute the complete normal stage-one initialization, actual active client call graph, or normal caller disposal; it cannot establish that production actually calls `finished` too early. Successful synthetic failure witnesses must not be inverted into green safety evidence.

To unlock Gate08, separately prove each E01–E08 real source writer including invisible A→B→A epoch changes, real reader/writer exact-once lease ownership and abort quarantine, checked `SUCCESS/BUSY/RETRY/ERROR`, one coherent atomic **eight-field** NPC/object/quest/item Bin+Ptrs plus all corresponding metadata and source epoch, and **actual** WoW 3.3.5a SavedVariables flush/crash/relog recovery. Owner-private eligibility and native client QA remain distinct RED gates.

All twelve gates remain **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**, 439 RAW public candidates are not accepted quests, actual eligible denominator **UNKNOWN**, and pilots 1207–1209 remain **0/3 implemented**. No production modifications without distinct owner approval.

## Independent review request (after CI)

CS02 may review this original frozen head only, via comments on [PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42): run pristine dual Lua, mutate exactly one reader yield, pointer decode, early-return behaviour, or source anchor at a time in scratch, distinguish corrective fixes from harmful escapes, report survivors/equivalents and preserve the original immutable test HEAD. The earlier #267 → #270 → #272 → #275 peer queue is **already complete**, as reported in [CS02 checkpoint](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6468800240). No queued review becomes accepted without actual independent results.
