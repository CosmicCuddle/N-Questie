# N-Questie Part47 — full original ThreadLib executing contiguous QuestieInit registration window (TEST ONLY)

**29 October 2026. This research tests original Lua source under a fabricated timer and stage environment; it does NOT execute the real entire QuestieInit stage or WoW 3.3.5a client. No release, native QA or production source changes authorized.**

## Exact historical source identity and immutable parent

- Direct child of [TEST-ONLY DRAFT #392](https://github.com/CosmicCuddle/N-Questie/pull/392) original frozen successful exact `26bd57d5832a69462428b82099e113df2aca3ef4` (**37/37 full exact-head GitHub Actions**, dedicated **616/616 source/model checks each real Lua5.1.5 and Lua5.4.6**, 9 historical source Git blob hashes, no artifacts). Do not rewrite original #390 failed or #392 successful heads.
- Original addon source-code pin `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` (NOT protected live `335`).
- Authentic WHOLE `Modules/Libs/ThreadLib.lua` Git blob `8f564049ad2a4af49473fac939b7c276c4227dd7` executed, not replaced by a synthetic coroutine simulator.
- Authentic WHOLE `Modules/Libs/QuestieCombatQueue.lua` Git blob `5f3fcbac09b95561e4e778a94936627e3c4e0a0e` executed.
- Authentic historical `Modules/QuestieInit.lua` Git blob `22fffa1b1bbeb81ba067f34151949c0938a316c1`: **only the exact unchanged contiguous source fragment from its source line 296 through 317** is extracted, wrapped into a generated fake-host coroutine function and executed. Full `QuestieInit.lua` initialization stage/method, real Questie database setup, frames and client API are NOT executed.
- Inherited CI authenticates the same NINE immutable original source blob identities, including original QuestEventHandler and QuestLogCache, whose full modules are NOT executed in this new fragment-specific test. Previous #392 source-authentic registered-frame tests remain inherited and separately green.

## What the source-under-fake-scheduler fixture checks

Historical `QuestieInit.lua:296–317` calls `coYield()`, original `QuestEventHandler:RegisterEvents()`, seven more `coYield()` barriers interleaved with `ChatFilter:RegisterEvents`, `QuestieMap:InitializeQueue`, quest initialization, map button, early quest-ID queries, `Townsfolk.PostBoot`, tracker initialization and hooks, before original `QuestieCombatQueue.Initialize()`. The **exact source fragment** is reused unchanged; dependent call targets are FAKE counters/markers. Only the *whole original* ThreadLib creates/resumes/terminates the coroutine via its real `ThreadError`/Thread path, using a **fake C_Timer.NewTicker** timer whose ticks are manually fired.

Under the fixture's **explicitly invented delivery schedule**:
1. Fake quest event before original source RegisterEvents is rejected by the test harness.
2. Synthetic quest event after original fragment's RegisterEvents but before CombatQueue.Initialize is accepted by the fake frame, yet original CombatQueue `Queue` (not initialized) does not retain its callback.
3. A second fabricated event late in the source window also does not get retained.
4. On the ninth manually fired stage ticker invocation, the unchanged source fragment invokes CombatQueue.Initialize and the original module registers a fake 0.1-second timer.
5. An invented event after initialization inserts a callback that the original queue defers during fabricated combat lockdown and drains after fake unlock.
6. Original ThreadLib detects dead coroutine on its subsequent manually invoked tick and cancels its fake timer.

This adds a **new proof of source scheduling under fake timing**, not actual delivery of QUEST_ACCEPTED during game initialization. It does NOT call the genuine QuestEventHandler in this new fixture (its prior separate #392 test runs genuine handler bodies under fake Frame).

## CI and safety conditions

Exactly THREE isolated changes: NEW `tests/compat/nq_part47_original_threadlib_init_fragment.lua`, edited pre-existing **test-only** `.github/workflows/nquestie-part45-g08-original-orphan-child-epoch.yml`, NEW `docs/research/NQ-PART47-G08-ORIGINAL-THREADLIB-INIT-WINDOW-CONTRACT.md`.

**PROPOSED** 40/40 new assertions on each real Lua5.1.5 and Lua5.4.6, plus inherited #392 616/616 each = **656/656 EXECUTED checks each interpreter** pending independent original-head dedicated job logs, 9 authentic source hash verification, clean checkout, zero distributed artifacts. Do NOT claim until verified. Synthetic tests are not native 3.3.5a gameplay evidence.

**Gate08 MAJOR RED**; 439 RAW candidates unapproved, pilot quests 1207–1209 0/3 implemented. No protected production addon Lua/SQL/TOC, native client, player/character data or SavedVariables, ZIP/build/install/merge/tag/release without fresh explicit owner authorization with backups, hashes and verified rollback.
