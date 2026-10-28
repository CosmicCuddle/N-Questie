# Part 44 Gate 08 — full original 335 AvailableQuests coroutine lifetime, synthetic host

**28 October 2026 · PUBLIC-SAFE TEST-ONLY DRAFT · NO RUNTIME PATCH, PACKAGE, INSTALL, MERGE, TAG OR RELEASE**

## Source provenance and expanded execution boundary

Immutable public protected `335` commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, original `Modules/Quest/AvailableQuests.lua` exact Git blob `2664f09fdf1f5df4d94581414e9d5ea88e9af4e7`. The dedicated read-only job authenticates both the source commit and blob, then loads the **ENTIRE ORIGINAL 359-line module unchanged** using Lua 5.1/5.4 `loadstring/load` into a tiny fabricated QuestieLoader/QuestieDB/ThreadLib/QuestieMap/QuestieTooltips host.

Unlike fragment-only [failed #319](https://github.com/CosmicCuddle/N-Questie/pull/319) and corrected frozen [#320](https://github.com/CosmicCuddle/N-Questie/pull/320), the new harness invokes the actual original `AvailableQuests.CalculateAndDrawAll()`, full `_CalculateAvailableQuests`, `_DrawAvailableQuest`'s deferred closure, `AvailableQuests.DrawAvailableQuest`, `_GetQuestIcon`, `_AddStarter`, `_GetIconScaleForAvailable` and `UnloadUndoable()` under **FICTIONAL** reader data, game globals and **FICTIONAL** scheduler. Original source is not patched, wrapped, or replaced. It does NOT execute the original ThreadLib library, network broadcast, actual QuestieDB decoder, original compiler or real WoW client.

## Proposed 37 test controls — not passed until exact original-head logs independently inspected

1. Source anchors and exact pinned module identify original pointer capture, coroutine thread launch, 25-ID yield, `activeChildQuests` reset, private `availableQuests` write, deferred `GetQuest`, tooltip and frame drawing.
2. In original `CalculateAndDrawAll`, a fake scheduler resumes the **real original complete calculator** to first yield, with exactly 25 fake `ThreadSimple` draw closures queued; five of those run the original quest-tag caching, NPC starter, tooltip and world-icon drawing paths successfully under matching OLD data.
3. Switch only the fake shared `QuestieDB.QuestPointers` and `QuestieDB.GetQuest` source from OLD to NEW while the original coroutine is suspended. Its captured OLD local pointer list continues to schedule old-ID callbacks after resume; a queued callback later using NEW `GetQuest` can error under fabricated data. This is a deliberate **KNOWN-UNSAFE synthetic interleaving**, not evidence native timers ignore cancellation or that the normal 335 addon hot-swaps data mid-yield.
4. Starting the same **unchanged original module** under a coherent NEW fictional data set draws all 52 NEW IDs in any `pairs()` order, invokes real original tooltip/icon/tag paths, and the private original `availableQuests` list can subsequently trigger 52 `UnloadUndoable` frame-unloads when artificial `IsDoable` becomes false.
5. Calling `CalculateAndDrawAll()` a second time invokes the prior fake `timer:Cancel()`; the fictional scheduler deliberately retains already-queued `ThreadSimple` closures. This is a **source risk for task ownership**, NOT verification that the actual `ThreadLib` scheduler retains or executes them.
6. A **separate, hypothetical model-only** monotonic owner-epoch check refuses to resume an old task, explicitly drops its queued callbacks and restarts with a fresh coherent NEW source. An A→B→A change reusing the same OLD pointer object remains rejected by epoch. The policy is not implemented in the addon and cannot be advertised as an actual fix.

## Engineering consequence (NOT production authorization)

- A future real dispatcher must account not only for the outer `timer:Cancel()` but also for children already queued with `ThreadSimple` and any previously drawn frames/tooltips, `availableQuests`, `activeChildQuests` and stale local quest pointers. A post-yield check alone is not sufficient if earlier deferred callbacks remain unfenced.
- Need independent source inspection of actual `ThreadLib.Thread`, `ThreadSimple`, ticker cancellation and callbacks, rather than equating the synthetic scheduler with native scheduling.
- Never mix a captured quest pointer table with later public `QuestieDB.GetQuest`, `QueryQuestSingle`, per-kind handles or stale private caches; viable choices for later authorization are full old-generation reader lease with atomic effects or abort/drain/restart with generation-aware derived state.
- QuestieComms must independently receive coherent membership/zone data; #320 only executed extracted pointer/query expressions, not full original BroadcastQuestLog. Tracker callbacks and first-party/third-party retained aliases also remain outside this test.
- Persisted eight Bin+Ptrs and metadata, source owner E01–E08 and unknown writers, global `QuestieStream` pool quarantine, disk/SavedVariables interrupted write/relog, native WoW 3.3.5a/Individual Progression are still unproven. **Gate08 MAJOR RED**; overall 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING.

## Release and evidence safety

- The canonical `335` branch must stay unchanged. This is an isolated child of frozen #320 exact head `42beb1e926dc2e18d0764665f26608419f97729a`.
- The job is read-only to protected source, with no upload-artifact, build, ZIP, install, release, tag or merge operations.
- Dedicated GitHub Action result, Lua versions, pass/fail and artifact endpoints must be independently audited before documenting success. Any failure requires preserving this exact original head, then a distinct corrective child — never overwrite a failed or successful historical test.
- Owner approval plus cold backups of `Interface/AddOns/Questie-335` and both account/character SavedVariables sets, with an explicit restoration procedure, remain prerequisites for a future native install test. No such permission exists today.
