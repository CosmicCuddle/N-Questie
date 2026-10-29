# N-Questie Part47 — original registered quest frame and original ThreadLib inside one fake initialization window

**29 October 2026. TEST-ONLY source integration research. Fake timers, events, dependencies and early 3.3.5a delivery; NOT observed real-game behaviour, accepted fix or release permission.**

## Original historical code and exact scope

- The original code commit is `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, not protected live `335`.
- Whole unchanged original `Modules/Libs/ThreadLib.lua` (Git blob `8f564049ad2a4af49473fac939b7c276c4227dd7`), `Modules/Libs/QuestieCombatQueue.lua` (`5f3fcbac09b95561e4e778a94936627e3c4e0a0e`) and `Modules/Quest/QuestLogCache.lua` (`09e9989922731f899994e6eb09af24465ae196ce`) all EXECUTE in the same fabricated host.
- **SEVEN complete unchanged original method bodies** from `Modules/Quest/QuestEventHandler.lua` (`fa3950ad5078ed299226fe384ea20eba2674b853`): `RegisterEvents`, `InitQuestLog`, `OnEvent`, `QuestAccepted`, `HandleQuestAccepted`, `QuestRemoved`, `MarkQuestAsAbandoned`; extracted as complete source bodies under a simulated private upvalue environment, **not whole original handler top-level module**.
- **Contiguous unchanged `Modules/QuestieInit.lua:296–317` source fragment** (`22fffa1b1bbeb81ba067f34151949c0938a316c1`), wrapped in a **generated fake dependency stage coroutine**. The whole genuine `QuestieInit.lua` stage does NOT execute; fabricated stage dependencies stand in for other Questie modules, and the actual native WoW event frame and C_Timer API are NOT present.
- Test-only workflow authenticates the same **NINE** exact original historical 335 Git blob SHA pins inherited from the existing suite, with clean checkout and no artifacts required.

## Integrated synthetic event schedule

The original ThreadLib scheduler creates its stage timer; manually fired fake ticks resume the unchanged original source fragment. At the exact fragment point, original QuestEventHandler:RegisterEvents initializes original cache and installs original OnEvent on the **fake** frame.

The fake frame deliberately delivers a QUEST_ACCEPTED event, then a fake QUEST_REMOVED and fake QUEST_ACCEPTED reacceptance **before original CombatQueue.Initialize**. This invokes genuine original OnEvent and original acceptance/removal bodies; original queue remains uninitialized and does not retain their queued closures. The generated fragment subsequently invokes actual original CombatQueue.Initialize via original ThreadLib tick. A manually fired fake combat ticker does not replay preinit closures; a newly invented QUEST_ACCEPTED event after initialization enters and drains from genuine original queue, held first by synthetic combat-lockdown then unlocked.

Unlike prior separate fixture #392's original handler + queue and #394's original ThreadLib + contiguous fragment (the latter's broader CI was still pending), this test joins the original ThreadLib, original frame handler, original CombatQueue and original QuestLogCache **in one synthetic host**.

All WoW events, startup occurrence, timer frequency, combat state, frame bindings, quest objectives, startup dependencies, journey/tracker sinks and any player effects are FAKE. Even if all assertions pass, it does NOT show native 3.3.5a can deliver this event order, has an initialization bug, or requires a production patch.

## Isolated workflow and validation gates

New isolated branch is **direct child of independently full-green TEST-ONLY #392** original frozen `26bd57d5832a69462428b82099e113df2aca3ef4`; the original #390 failed head and all previous frozen PRs remain unchanged. Exactly three changed paths: NEW `tests/compat/nq_part47_original_integrated_frame_threadlib_window.lua`, one extension of test-only `.github/workflows/nquestie-part45-g08-original-orphan-child-epoch.yml`, this NEW research note. No original addon Lua/SQL/TOC edited.

**PROPOSED** 30/30 new same-host source checks EACH real Lua5.1.5 and Lua5.4.6, inherited **616/616** each = **646/646 EXECUTED** each; do NOT credit until dedicated exact-head CI job/log success, nine blob hashes, clean checkout, zero artifacts. This branch is independent of #394, whose 40 tests are **not inherited** and must NOT be included in this branch's totals.

**Gate08 MAJOR RED**; 439 RAW quest candidates unapproved, pilot quests 1207–1209 0/3. Native event reachability, actual 1→0 objective semantics, `WasComplete` and AnimationGroup/ThreadLib real lifecycle UNKNOWN. No native client QA, real character/account/SavedVariables, protected addon/SQL/TOC, ZIP/build/install/merge/tag/release without explicit owner permission and backups/hashes/rollback.
