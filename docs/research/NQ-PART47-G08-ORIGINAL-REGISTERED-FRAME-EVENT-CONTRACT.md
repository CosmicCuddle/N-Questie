# N-Questie Part47 — original registered frame dispatch into pre-init CombatQueue (TEST ONLY)

**29 October 2026. Isolated first-party-source test under invented WoW frame and event timing; not native 3.3.5a QA or a production bug/fix.**

## Exact provenance and preserved parents

- Separate child of **TEST-ONLY #388** frozen original `9fa515eabc6d287f0591aab51407c5bd82952d91` whose **37/37 exact-head GitHub Actions** were independently confirmed. This child leaves that PR unchanged.
- Original historic addon code commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` (NOT the live README-only `335`). Workflow inherits **NINE authentic original source blob SHA pins**, including `Modules/QuestieInit.lua` blob `22fffa1b1bbeb81ba067f34151949c0938a316c1`.
- Whole original `Modules/Libs/QuestieCombatQueue.lua` blob `5f3fcbac09b95561e4e778a94936627e3c4e0a0e` and whole original `Modules/Quest/QuestLogCache.lua` blob `09e9989922731f899994e6eb09af24465ae196ce` execute unchanged, freshly in each fake-host scenario.
- Additional **unchanged, entire original QuestEventHandler method bodies** extracted from `Modules/Quest/QuestEventHandler.lua` blob `fa3950ad5078ed299226fe384ea20eba2674b853`: **RegisterEvents, InitQuestLog, OnEvent, QuestAccepted, HandleQuestAccepted, QuestRemoved, MarkQuestAsAbandoned**. The whole handler module's top-level initialization and real Blizzard API are NOT executed. The original `QuestieInit.lua` source order is READ but its whole initialization coroutine is NOT executed.

## Newly covered source chain

Original `QuestEventHandler:RegisterEvents` registers `QUEST_ACCEPTED`, `QUEST_REMOVED` and other events to its `eventFrame`, installs `eventFrame:SetScript("OnEvent", _QuestEventHandler.OnEvent)`, attaches secure hooks and invokes original `InitQuestLog`. Under a **fake frame** implementing `RegisterEvent`, `SetScript` and explicitly-invoked `Fire`, the original `OnEvent` method dispatches invented `QUEST_ACCEPTED` and `QUEST_REMOVED` into genuine unchanged original handler methods. QuestLogCache and CombatQueue still run whole original modules, but game data/frame timing/event delivery/hook registrations/timers/sinks are simulated.

New scenarios **D and E** (20 NEW assertions) add to the carried-forward **31 fake preinit source assertions from #388**, now 51/51 assertions in this new fixture. D: simulate original registration and original quest cache initialization on a fake frame, invent QUEST_ACCEPTED before CombatQueue initialization, verify original queued callback is not retained and second fake accepted event after original queue initialization drains successfully. E: invent native-looking QUEST_REMOVED→QUEST_ACCEPTED via the fake registered frame before init; compare cancellation and no replay with post-init response. Unregistered event rejection is a **fake frame harness check**, not a real Blizzard behaviour claim.

**Proposed dual-Lua census**: inherited #388 **565 checks per interpreter** plus newly executed **51 checks per interpreter in this new fixture** = **616/616 executed EACH Lua5.1.5+5.4.6**. **31 of the new fixture's 51 duplicate the prior fixture's checks**, while **20 distinct new checks exercise original registration, InitQuestLog and OnEvent dispatch.** Do not credit CI until original-head dedicated job and logs verify both interpreters, exact nine Git blob hashes, clean checkout and 0 artifacts.

## Hard boundaries

No real WoW 3.3.5a event is observed, no actual game `OnEvent` callback fired, no original full initialization coroutine executed, no source 1→0 objective transition proved native reachable, no user data or native client. Source gap before CombatQueue.Initialize remains a **hypothesis of potential ingress**, not a demonstrated real dropped callback or player impact. Peer independent native timing, `WasComplete` and AnimationGroup/ThreadLib feasibility remain UNKNOWN.

**Gate08 MAJOR RED**, 439 RAW candidates unapproved, pilot quests 1207–1209 **0/3**. Exactly one new `tests/compat/nq_part47_original_registered_frame_dispatch.lua`, one test-only workflow edit, this research note; no production addon Lua/SQL/TOC, SavedVariables, client execution, build/ZIP, merge/install/tag/release without new explicit owner authorization/backups/verified hashes/rollback.
