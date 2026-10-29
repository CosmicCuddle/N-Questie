# N-Questie Part47 — original pre-initialization quest event queue contract (TEST ONLY)

**29 October 2026. Research / isolated test-only draft. This document is not native 3.3.5a event-order evidence, production bug acceptance, or authorization to touch the live addon.**

## Source provenance

This branch is an isolated child of frozen successful **TEST-ONLY #385** exact original `49e46ebaeb3012646bb38eb99a5514f2657244f0`. Historical original addon CODE commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` is NOT current production `335`.

**New ninth authentic source Git blob**: `Modules/QuestieInit.lua` = `22fffa1b1bbeb81ba067f34151949c0938a316c1`. The new fixture **reads and anchors its exact source call order** but does NOT execute QuestieInit's complete initialization coroutine or native Blizzard API.

Inherited eighth source blob `Modules/Libs/QuestieCombatQueue.lua` = `5f3fcbac09b95561e4e778a94936627e3c4e0a0e` is **executed as the WHOLE unchanged original module** in three fresh synthetic Lua hosts. Whole original `Modules/Quest/QuestLogCache.lua` blob `09e9989922731f899994e6eb09af24465ae196ce` is executed too. Exact unchanged function bodies `QuestAccepted`, `HandleQuestAccepted`, `QuestRemoved`, `MarkQuestAsAbandoned` are extracted from first-party `QuestEventHandler.lua` Git blob `fa3950ad5078ed299226fe384ea20eba2674b853` and run under invented handler upvalues.

All NINE historical sources are independently SHA-authenticated by inherited/extended test-only GitHub CI; **the other source modules are not all run together in this fixture**.

## Source-only ordering and bounded fake-host questions

- `QuestieInit.lua:297` invokes original `QuestEventHandler:RegisterEvents()`; multiple explicit `coYield()` calls separate it from original `QuestieCombatQueue.Initialize()` at `:317`. Only static genuine source order is established. Real game event delivery between them is UNKNOWN.
- Whole authentic original `QuestieCombatQueue.lua:13–14,40–44` retains `started=false` initially and its `Queue(func,...)` only `tinsert`s if initialized. In a fictitious host, calls before initialization can therefore fail to enter original queue. It does **not** show any real game/character quest callback was dropped.
- Source `QuestAccepted` enqueues `HandleQuestAccepted`; when a pending removed quest has a timer, it also enqueues `MarkQuestAsAbandoned` then replaces its quest state. Whole original cache is exercised under fake game-log data, but no native objective sequence or real reset is asserted.

The separate new fixture stages three **explicitly fabricated** event-orders and timers:
A. fake QuestAccepted before queue init -> callback not queued, then fake queue initialized and its 0.1-second ticker fired -> no replay; another fabricated accepted event after init -> original callback executes.
B. fake QuestRemoved then reacceptance before init -> original pending timer cancellation and replacement state, but both callbacks dropped; a later fabricated post-init accepted event can enqueue successfully.
C. control case: fake queue initialized before removal/reacceptance -> original deferred callbacks run at a manually fired fake ticker; accepted state is set and abandonment guarded.

WoW events, player data, game quest objectives, `C_Timer.NewTicker` callback delivery, combat state, module loader, other addon handlers, SavedVariables and game cache are **FAKE**. No 3.3.5a native client, real event, external character state or actual `QuestieInit` coroutine executed. This is a **potential early-init source path**, not a user-visible defect or verified startup race.

## CI / immutable PR preservation

Exactly three isolated changed paths: NEW `tests/compat/nq_part47_original_preinit_quest_queue_window.lua`, one extension to the test-only `.github/workflows/nquestie-part45-g08-original-orphan-child-epoch.yml` and this new research document. New **31 source-under-fake-event checks per Lua5.1.5/5.4.6 PROPOSED**; previous #385 534/534 each are independently confirmed on immutable original #385, so the new total **565/565 EACH is PROSPECTIVE and must not be credited before exact-head dual-Lua job/log success, all nine Git source hash checks, clean checkout and zero artifacts**. Preserve all previous frozen success/failure heads, including historical red #361/#362/#373/#374/#377. No production code or release assets.

**Gate08 MAJOR RED**, 439 RAW quest candidates unapproved, pilot quests 1207–1209 = 0/3 implemented. No original addon Lua/SQL/TOC, native client/character/SavedVariables, ZIP/build/install/merge/tag/release without fresh explicit user authorization, verified backups/file hashes and rollback.
