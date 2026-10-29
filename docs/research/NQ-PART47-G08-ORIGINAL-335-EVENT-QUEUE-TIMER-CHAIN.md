# Part47 — genuine 3.3.5a quest-event → WasComplete → original CombatQueue and C_Timer source

**29 October 2026 — TEST-ONLY. No real game client, quest state, account, native AnimationGroup timing, or production addon source was accessed.**

## Immutable evidence and source boundaries

Direct child of frozen full-green [TEST-ONLY #420](https://github.com/CosmicCuddle/N-Questie/pull/420) first submitted original `481069bdf369bbec4028e030b8ae21ecb4dba4db`, independently **37/37 original-head GitHub Actions SUCCESS**, dedicated **913/913 EXECUTED EACH actual Lua5.1.5+5.4.6**, NINE authentic historical original 335 Git source blob hashes, clean checkout, zero artifacts. Protected README-only production `335` latest `26053bd28b0df3a01e5859f779d5f3cb4f57b221`; true historical first-party addon-code source pinned at Git commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. All earlier red synthetic PRs, including #390/#396/#397/#405/#406/#407/#414/#415, remain frozen and unmodified.

**Authentic complete original methods actually coexecuted:** four unchanged original `_QuestEventHandler:OnEvent`, `QuestWatchUpdate`, `QuestLogUpdate`, `UpdateAllQuests` bodies (historic source blob `fa3950ad5078ed299226fe384ea20eba2674b853`), whole unchanged original QuestLogCache (`09e9989922731f899994e6eb09af24465ae196ce`), genuine original 335 Compat objective parser and C_QuestLog / HaveQuestData / GetQuestLogTitle code (`b3e273e82cabbd5b7b351ae5aa3d94d4675387be`), original QuestieDB.IsComplete (`5784cb65160175e1dce30fe20e8baada0af7e480`), and five original QuestieQuest method bodies UpdateQuest, SetObjectivesDirty, PopulateQuestLogInfo, ObjectiveUpdate and GetAllLeaderBoardDetails (`cd4239c5b40c1f5b1ced823dfa12d8a895091719`).

**NEW genuine first-party subsystems, not replacement sink:** WHOLE unchanged `Modules/Libs/QuestieCombatQueue.lua` (historic blob `5f3fcbac09b95561e4e778a94936627e3c4e0a0e`) and exact contiguous original `Compat/Compat.lua:131–190` AnimationGroup-backed C_Timer code (same Compat source blob). Previous #420 had a dummy queue and immediate dummy `C_Timer.After`; this separate fixture replaces those with real first-party queue and C_Timer source, but **still fakes the Blizzard AnimationGroup implementation and actual OnFinished callbacks**.

**NOT executed:** whole genuine QuestEventHandler top-level/RegisterEvents/CreateFrame, whole original Compat/ADDON_LOADED, whole QuestieDB/QuestieQuest top-level/GetQuest quest constructor, true 3.3.5a Blizzard game client/frame scheduler, real quest or player state. All user-visible sinks (tracker, map, nameplate), login state and QuestieLib argument packing are fake; native `GetQuestLogTitle` complete 1→nil and raw quest objective data are intentionally fabricated.

## Distinct new source-under-fake-animation observations

1. Genuine original QuestieCombatQueue.Initialize calls authentic C_Timer.NewTicker(0.1,...) and creates a repeating timer, represented by one synthetic AnimationGroup. Original `QuestLogUpdate` without scan flag enqueues a tracker update but does not run it before a **FAKE animation callback**. Changed-data paths in original UpdateAllQuests enqueue three independent `C_Timer.After(1.0,...)` callback work items via the original queue, not immediate tracker updates.
2. Under fake `InCombatLockdown()=true`, manually firing queue Animation.OnFinished does not execute the queued callbacks or schedule the delayed timers.
3. After fabricated combat unlock, manually firing the queue timer processes four source-enqueued callbacks in original FIFO: one direct tracker update and three original C_Timer.After(1) calls, creating three separate fabricated 1-second AnimationGroup timers. This is an invented schedule and **does not prove Blizzard ticks every 0.1 or 1 second**.
4. Manually firing each of the three invented delay timers runs the genuine first-party one-shot timer's callback path to update a fake tracker, and auto-cancels its animation. The original repeating queue ticker remains active; an extra empty fake tick does not replay callbacks.
5. Earlier #420 source-level qualification remains: unchanged raw/metadata fake QUEST_WATCH_UPDATE/QUEST_LOG_UPDATE traffic does not by itself retrigger QuestieQuest.UpdateQuest, so the conditional WasComplete reset/re-complete effect needs a later actual change as identified under synthetic inputs.

This new fixture does not authenticate real 3.3.5a event receipt order, real AnimationGroup elapsed time, user-facing tracker latency, real WasComplete oscillation, or a native gameplay defect. Source correctness within fake host is the only claimed conclusion.

## CI scope and safety contract

Exactly THREE isolated paths: new `tests/compat/nq_part47_original_335_event_queue_timer_chain.lua`, edited existing TEST-ONLY `.github/workflows/nquestie-part45-g08-original-orphan-child-epoch.yml`, this new `docs/research/NQ-PART47-G08-ORIGINAL-335-EVENT-QUEUE-TIMER-CHAIN.md`. Historical NINE immutable authentic source Git blob SHA checks unchanged; protected production `335` and all original addon Lua/SQL/TOC untouched. No native WoW game client/player/SavedVariables, ZIP/build/install/merge/tag/release.

**PROPOSED** 19 new source-under-synthetic-clock assertions EACH real Lua5.1.5 and Lua5.4.6, inherited #420 **913 EACH**, prospective **932/932 EXECUTED EACH**. Do not credit until exact original-head dedicated dual-Lua CI and decoded logs confirm 19/19 new each, nine original source SHA pins, clean checkout and ZERO artifacts. Full wider 37/37 GitHub Actions separately audited.

**Gate08 MAJOR RED**, 439 RAW quest candidates unapproved, pilot quest IDs 1207–1209 **0/3**. Native test/observation gate remains explicitly permission-controlled via `docs/research/NQ-PART47-NATIVE-335-EVIDENCE-OBSERVATION-GATE.md`; a documentation plan is not actual owner approval. Any future native QA requires separate explicit owner permission, verified staging backups/hashes and rollback.
