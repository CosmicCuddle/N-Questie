# N-Questie Part47 — Original QuestAccepted reentry and real CombatQueue source under simulated timing

**29 October 2026. TEST-ONLY draft research note. Never construe synthetic event ordering as native gameplay evidence or a production fix.**

## Immutable original source provenance

- Historical first-party 335 **CODE pin**: `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, not current README-only live `335`.
- **New eighth authentic Git blob**: `Modules/Libs/QuestieCombatQueue.lua` = `5f3fcbac09b95561e4e778a94936627e3c4e0a0e`. New fixture executes the **WHOLE unchanged original module**.
- Original `Modules/Quest/QuestEventHandler.lua` blob `fa3950ad5078ed299226fe384ea20eba2674b853`: unchanged entire **QuestAccepted, HandleQuestAccepted, QuestRemoved, MarkQuestAsAbandoned FUNCTION BODIES**, loaded as extracted source under fabricated surrounding local state. Not entire handler initialization or genuine event ingress.
- Original `Modules/Quest/QuestLogCache.lua` blob `09e9989922731f899994e6eb09af24465ae196ce`: whole unchanged module, fake quest log and objectives.
- Five earlier historical blobs from the inherited suite remain independently hash-checked in dedicated CI. All **eight** source pins verified by the extended workflow. Individual source bodies within the new fixture do not imply entire original addon integration.

## First-party source sequencing

`QuestEventHandler.lua:203–233`: when the tracked removed quest has a timer, **QuestAccepted cancels it, then enqueues a closure invoking MarkQuestAsAbandoned**, then sets `questLog[questId] = {}`, then enqueues `HandleQuestAccepted`. Source `MarkQuestAsAbandoned` checks whether `questLog[questId].state == QUEST_REMOVED`, and only then invokes original `QuestLogCache.RemoveQuest`.

`QuestieCombatQueue.lua:19–43`: its original `Initialize` starts a `C_Timer.NewTicker(0.1,...)`, and `Queue` inserts callback records into internal `_Queue` only after initialization. The original ticker respects `InCombatLockdown`, with bounded drain per tick. **Enqueue is not inline execution in this original module**. Native 3.3.5a `C_Timer.NewTicker` scheduling and actual WoW event sequences have not been measured.

## Deliberately fabricated fixture sequences

A. Fake `QuestRemoved` starts an invented 1-second abandonment timer; fake `QuestAccepted` cancels it and enqueues both real original callback closures via whole original combat queue; the synthetic host changes objective list 1→0 before explicitly firing a fake 0.1-second queue tick. The queued original abandonment method observes the now-replaced quest tracking state and does not remove the cache. Original `HandleQuestAccepted` can then set accepted while original cache retains the old one-objective snapshot under these invented data. This is **source-possible only**, not proof native 1→0 is possible between these events.

B. With an explicitly test-host reset cache and fresh fake one-objective quest, fake removed timer fires **before** accept, invoking original abandoned method and clearing original QuestLogCache. Subsequent queued original accepted handling rebuilds a zero-objective cache because the fake client now reports zero. This is a **counterexample under invented timing**, not a demonstrated client fix.

C. With a further **test-host cache cleanup**, fake `InCombatLockdown` keeps the original combat queue from draining; synthetic unlock allows a later tick, and the same delayed pending-abandon callback sees replaced state, with old cache still present. Does not test actual combat or frame scheduling.

All WoW game log, objectives, `GetQuestTimers`, C_Timer callback scheduling, cancellation semantics, combat flag, loader, Questie, journey/announcement sinks, cache availability and initial event order are **FAKE**. The original queue and cache code and the four original handler function bodies are real.

## Dedicated CI, historical preservation and gates

Branch is an **isolated direct child** of frozen successful [#383](https://github.com/CosmicCuddle/N-Questie/pull/383) original `4a9d71fbd8f796300b492f73a46e762f523e5e38`. Exactly one new `tests/compat/nq_part47_original_reaccept_combatqueue_cache.lua`, one existing test-only workflow extension and this new docs/research file. No protected addon sources, SQL, TOC, game client, installation or ZIP.

**Proposed** 40/40 new checks on each actual Lua5.1.5/5.4.6, plus inherited 494/494 each = prospective **534/534 each**. Do NOT credit until exact-head dedicated workflow green, clean checkout, eight Git source blob authentication, no artifacts and broader CI checked. Preserve all earlier immutable failed #361/#362/#373/#374/#377 and successful #380/#383 heads.

**Gate08 MAJOR RED**; 439 RAW candidates remain unapproved; pilot quests 1207–1209 are 0/3 implemented. Real 3.3.5a event timing, reacceptance sequences, 1→0 objective reachability, genuine `WasComplete`, animation and ThreadLib child lifetimes remain UNKNOWN. No merge/production/game client/real SavedVariables/build/release without new specific owner authorization and backup/rollback.
