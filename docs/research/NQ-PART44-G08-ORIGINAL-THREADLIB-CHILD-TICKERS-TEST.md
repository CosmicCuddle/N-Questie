# Part 44 Gate08 — genuine original ThreadLib + AvailableQuests child ticker lifetime

**28 October 2026 · PUBLIC-SAFE TEST-ONLY DRAFT · NO PRODUCTION EDITS, BUILD, ZIP, INSTALL, MERGE OR RELEASE**

## Independently authenticated original source

- Immutable protected `335` commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.
- Entire unmodified original `Modules/Libs/ThreadLib.lua`, Git blob `8f564049ad2a4af49473fac939b7c276c4227dd7`, all 138 source lines executed as a module with synthetic globals.
- Entire unmodified original `Modules/Quest/AvailableQuests.lua`, Git blob `2664f09fdf1f5df4d94581414e9d5ea88e9af4e7`, all 359 source lines loaded and actual paths exercised.
- This is a direct test-only child of frozen [#323](https://github.com/CosmicCuddle/N-Questie/pull/323) original `5283d41633bfaaef09201d696f0cf67605041aaf`. Prior frozen #319 FAILED and #320 corrected GREEN remain unchanged.

## Source-backed scheduling issue, accurately scoped

Actual original `ThreadLib.Thread` (lines 21–59) creates a coroutine and an independent `newTicker` to resume it. Its callback checks suspended/dead state, catches Lua coroutine failures via `Questie:Error`, cancels the timer on exception/death and can invoke an optional completion callback. Actual `ThreadLib.ThreadSimple` (86–88) delegates to `ThreadLib.Thread` and also obtains its own ticker.

Actual `AvailableQuests.CalculateAndDrawAll` (44–52) stores and cancels its **outer** ticker; the real `_DrawAvailableQuest` (233–244) schedules independent `NewThread` closure(s). There is **no visible parent→child cancellation mechanism in these original paths**. The full original calculator captures a quest pointer table and yields every 25 processed IDs (93, 189–199). Original child draws fetch `QuestieDB.GetQuest` when their independent callback later runs (235). That is the source-level safety boundary being tested.

## New original-source execution: expected 32 assertions PER Lua interpreter

A fake `C_Timer.NewTicker` only stores callbacks and supplies `Cancel`; the test invokes those callbacks manually. **The original ThreadLib timer callbacks, coroutine scheduling logic, child `ThreadSimple` delegation and original AvailableQuests coroutine/child bodies are NOT rewritten.**

The synthetic test shows: first original outer tick queues 25 independently ticker-backed child draws; one child runs under matching OLD test rows; switching the fake public source and invoking `CalculateAndDrawAll` cancels the original outer ticker but does not cancel another previously queued child ticker; that original child callback subsequently queries OLD quest ID under NEW fictional DB, the original ThreadLib error handler catches its thrown nil-quest error and cancels just that child ticker; a fresh NEW outer + NEW child can draw under coherent fictional NEW rows. It checks original source pins, exact ticker statuses, child ownership, loaded source and lack of build outputs. Expected counts **must not be promoted to PASS until dedicated exact-head GitHub Action and job logs are inspected**.

## Limitations and future acceptance

- The actual original C_Timer/QuestieCompat implementation, host WoW event loop, game data, addon startup, QuestieDB decoder, compiler, network/QuestieComms, real QuestieStream pool and native 3.3.5a/IP were **not executed**.
- The scenario deliberately switches fictional source tables mid-flight and is **not** proof real player data has been observed to mix. It does establish that the authentic code path has independent child timer lifetimes under a legal invented scheduler.
- Cancellation of prior parent ticker cannot by itself be counted as cancellation of already spawned child ticker(s), nor rolled-back map or tooltip outputs; future reader-generation acceptance needs source-owned lease/fence for parent AND children, and evidence for existing caches and callbacks.
- Full coherent eight Bin+Ptrs + metadata, E01–E08 and unknown writers, global stream lifetime/quarantine, source ABA, SavedVariables/crash/relog, direct `QuestieComms` generation membership/zone coherence, Tracker/QuestieSearch retained caches and native IP test remain **MAJOR RED**.
- No production changes are authorised by this test, no ZIP/package generated. Future native test requires separate owner approval, backups of `Interface/AddOns/Questie-335`, account and character SavedVariables, and documented rollback.
