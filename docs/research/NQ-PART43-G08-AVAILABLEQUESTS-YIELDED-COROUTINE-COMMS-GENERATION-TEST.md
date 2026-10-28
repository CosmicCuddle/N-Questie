# Part43 Gate08 — original AvailableQuests coroutine yield and QuestieComms pointer/query risk (TEST ONLY)

**28 October 2026 · PUBLIC SAFE · isolated test, no runtime changes, ZIP/build/client/install/merge/tag/release**

## Why this is the next boundary

Prior isolated [#317](https://github.com/CosmicCuddle/N-Questie/pull/317) executed complete unchanged original `QuestieDB:Initialize()` plus complete unchanged `QuestieSearch.lua` using a fictional decoder/dispatcher and demonstrated coherent *shadow* reader+search cache staging. This does not protect an original AvailableQuests coroutine already running, or the network quest export function selecting pointers/query fields individually.

Original protected `335` immutable commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` authentic blobs:
- `Modules/Quest/AvailableQuests.lua` `2664f09fdf1f5df4d94581414e9d5ea88e9af4e7`: lines **89–93** capture `local questData = QuestieDB.QuestPointers or QuestieDB.questData`, then lines **189–199** loop this local and call `yield()` every 25 quests (threshold `QUESTS_PER_YIELD=24`, increment and `> 24`). The full task body uses further mutable `QuestieDB` queries (e.g. `QueryQuestSingle` for child quests at line 207), active-child quest cache resets and map/tooltip side effects. `ThreadLib.Thread(_CalculateAvailableQuests,...)` schedules it.
- `Modules/Network/QuestieComms.lua` `400dbfaec895517cea7cd283e6ec20404f46a7b7`: original sending paths at **531/541** and **648/658** check `QuestieDB.QuestPointers[questId]`, then obtain `QuestieDB.QueryQuestSingle(questId, "zoneOrSort")`, then compare `entry.zoneOrSort > 0`. This is two distinct source-field reads. A deliberately mismatched pointer/query set can pass the first check and yield a nil from the second (followed by numeric comparison).
- `Modules/Tracker/TrackerLinePool.lua` `e7e9f6b8539080b3934def64779a49c0fc2a6b6b`: direct `QuestieDB.QueryItemSingle(...,"class")` lookups around 500–547. This path is **only source-anchored**, not executed in the fixture.

## What the executable fixture DOES and DOES NOT run

The dedicated workflow authenticates all three full protected public Git blobs. Under real Lua 5.1/5.4, it extracts and executes the **unaltered original AvailableQuests local-pointer assignment and exact original 189–199 iterator/yield source fragment**, preserving the exact 25-quest yield and local pointer reference lifetime. It substitutes a tiny synthetic `_DrawQuestIfAvailable` callback (not the genuine large function body) which calls an invented quest query and records matches/misses for fictional numbered quest IDs.

One task starts with 52 OLD quest IDs. Its original iteration yields after the first 25. The test then switches **invented** global pointers + query functions to NEW and resumes; the captured local still enumerates the remaining OLD quest IDs while the new fictional query cannot find them. Stable OLD and freshly started coherent NEW tasks demonstrate this mismatch is constructed by the test schedule, not intrinsic to every run. A hypothetical owner-epoch guard is separately modelled: it detects a stale task after yield and refuses to publish its results.

The QuestieComms fixture executes its unchanged original **pointer-index and query expressions** in a reduced synthetic function, checking matching OLD/NEW and mismatch cases including a fabricated nil `zoneOrSort` numeric comparison failure. It DOES **NOT** execute the complete 1099-line original QuestieComms function, full AvailableQuests calculator, the real `GetDBHandle` decoder, ThreadLib scheduling, actual QuestieDB, live quest inputs, world map/tracker updates, network sends, real source ownership or QuestieStream.

The suite requires **40/40 explicit source and model assertions per Lua interpreter** before being marked green. Record dedicated exact-head run, logs, source authentication and 0-artifact count; do not claim passage before inspection.

## Concrete future acceptance work (NOT implementation approval)

The design contract must ensure each long-lived AvailableQuests task either **pins a complete OLD read-generation across all yields** and safely discards its output if superseded, or **stops and retries** as soon as its source epoch changes, without contaminating new cache, map frame or tooltip state. This is a broader requirement than matching the two pointers during a synchronous search. QuestieComms must resolve quest membership and fields against a **single coherent generation** before formatting outgoing data; avoid speculative mixed-generation error handling that masks source ownership failures. QuestieTracker and further consumers need separate lifecycle tests.

All E01–E08 source owner capture and external writers, shared QuestieStream lease/abort quarantine, 4-kind 8 Bin/Ptrs + metadata atomic publish, existing query exports, old-format SavedVariables compatibility, disk/relog/crash native 3.3.5a + Individual Progression remain unaccepted. Protected 335 unchanged. Gate08 **MAJOR RED**, project **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**, 439 RAW research unapproved, eligible denominator unknown, pilot 1207–1209 **0/3**. Owner explicitly approves any later native package/install separately after full backups of `Interface/AddOns/Questie-335` and both SavedVariables sets, with rollback; do not invoke legacy build/release scripts.
