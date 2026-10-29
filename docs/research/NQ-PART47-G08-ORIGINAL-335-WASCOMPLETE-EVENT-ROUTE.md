# Part47 — original 3.3.5a QUEST_WATCH_UPDATE/QUEST_LOG_UPDATE event path to WasComplete

**29 October 2026 — TEST-ONLY, fabricated event arrival and quest state.** This research does not authorize native WoW client QA or production source changes.

## Provenance and exact original source boundaries

Direct child of independently FULL GREEN [TEST-ONLY #418](https://github.com/CosmicCuddle/N-Questie/pull/418) first submitted exact original head `72071baa99b08433035b6f1338a61bade16824d6`, **37/37 full exact-head GitHub Actions SUCCESS**, dedicated **894/894 EXECUTED EACH actual Lua5.1.5+Lua5.4.6**, nine authentic original Git blob SHA identities, clean checkout, zero artifacts. Original historical addon-code Git commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` separate from owner-approved protected README-only live `335` `26053bd28b0df3a01e5859f779d5f3cb4f57b221`. Earlier failed original heads #390/#396/#397/#405/#406/#407/#414/#415 retained.

**Inherited authentic source executed within this new fixture:** whole unchanged original `Modules/Quest/QuestLogCache.lua` Git blob `09e9989922731f899994e6eb09af24465ae196ce`; unchanged original 335 `Compat/Compat.lua` questlog-title / objective-parser / C_QuestLog / HaveQuestData regions Git blob `b3e273e82cabbd5b7b351ae5aa3d94d4675387be`; whole original first-party `QuestieDB.IsComplete` function body Git blob `5784cb65160175e1dce30fe20e8baada0af7e480`; and five complete original `QuestieQuest` method bodies (UpdateQuest, SetObjectivesDirty, PopulateQuestLogInfo, ObjectiveUpdate, GetAllLeaderBoardDetails) Git blob `cd4239c5b40c1f5b1ced823dfa12d8a895091719`.

**NEW original event dispatch source coexecuted**: exact unchanged complete `_QuestEventHandler:OnEvent`, `_QuestEventHandler:QuestWatchUpdate`, `_QuestEventHandler:QuestLogUpdate` and `_QuestEventHandler:UpdateAllQuests` from original `Modules/Quest/QuestEventHandler.lua` Git blob `fa3950ad5078ed299226fe384ea20eba2674b853`. These originals share authentic local `doFullQuestLogScan` and a generated fake accepted-quest state. The genuine event frame's actual RegisterEvents/SetScript wiring, other QuestEventHandler functions, entire original QuestieDB/QuestieQuest modules and original QuestieDB.GetQuest constructor are **NOT executed here**; prior inherited independent suites exercise those separately.

**All game inputs are FAKE:** original `OnEvent` is invoked manually (no client Frame); fabricated `QUEST_WATCH_UPDATE` and `QUEST_LOG_UPDATE` arrival and ordering, client completeness 1→nil, GetQuestLogTitle / GetQuestLogLeaderBoard, raw objective 1/2→0/2, quest title metadata change, QuestiePlayer/quest state, map/nameplate/tracker/CombatQueue/timer effects and sound sinks. Original QuestieCombatQueue is NOT executed in this new fixture; the queue sink is deliberately fake to avoid conflating event logic with timer delivery.

## Why this is different from prior 894 assertions

Prior #418 invoked genuine `QuestieQuest:UpdateQuest` manually. The new fixture tests the **actual original four-method event-dispatch path** and distinguishes source event presence from cache-delta gating:

1. On a fabricated complete client status, original cache and genuine UpdateQuest produce `WasComplete=true`.
2. Fabricated client switches to `nil`. A lone manually invoked original `OnEvent("QUEST_LOG_UPDATE")` with original `doFullQuestLogScan=false` does not run the cache scan and simply enqueues fake tracker work.
3. The invented `QUEST_WATCH_UPDATE` then `QUEST_LOG_UPDATE` pair sets original `doFullQuestLogScan=true`, enters genuine `UpdateAllQuests`, notices the genuine cache metadata change and runs genuine SetObjectivesDirty + UpdateQuest. Real original DB.IsComplete maps cached client nil with objective to addon-level 0; original update clears WasComplete but repopulates from stale normalized 2/2.
4. Repeating the same fabricated event pair with **identical raw and metadata values** does not cause another `UpdateQuest` because original `QuestLogCache.CheckForChanges` reports no changed quest; therefore the all-complete fallback does **not** spontaneously remark WasComplete due solely to unchanged event traffic.
5. A separate fabricated quest title metadata change triggers original UpdateAllQuests again while cache normalized objectives remain 2/2, so genuine `QuestieQuest:UpdateQuest` can mark WasComplete true via fallback despite original QuestieDB.IsComplete=0. A fabricated raw objective update to 0/2 triggers another actual source event update and correctly sets incomplete objective state.
6. The fake nameplate/tracker sinks count source calls but cannot establish live UI or timing effects.

**All observations are conditional source behaviour with fabricated game inputs.** Actual 3.3.5a client 1→nil temporal reachability, event delivery sequence, saved character state, WasComplete display impact and performance are unverified. No production bug/fix is accepted.

## CI and safety

Exactly **THREE test/workflow/research paths**, all isolated: new `tests/compat/nq_part47_original_335_wascomplete_event_route.lua`; an extension to existing test-only `.github/workflows/nquestie-part45-g08-original-orphan-child-epoch.yml`; this research note `docs/research/NQ-PART47-G08-ORIGINAL-335-WASCOMPLETE-EVENT-ROUTE.md`. NINE original historical first-party Git blob SHA authenticators unchanged; no protected addon Lua/SQL/TOC, production client/player/SavedVariables, build/ZIP/install/merge/tag/release.

**PROPOSED 19 new source-under-fake-event checks EACH actual Lua5.1.5 and Lua5.4.6**, inherited #418 **894/894 EACH**, prospective **913/913 EXECUTED EACH**. Do NOT credit until exact original-head dedicated GitHub Actions dual-Lua job logs, all nine historic source hashes, clean checkout and ZERO artifacts independently confirmed. Wider 37/37 CI separately verified.

**Gate08 MAJOR RED**, 439 RAW quests unapproved, pilot 1207–1209 0/3. Native observation remains explicitly permission-gated by `docs/research/NQ-PART47-NATIVE-335-EVIDENCE-OBSERVATION-GATE.md`; no actual game-client QA approved or run, and any future attempt requires specific owner consent, verified staging backups/hashes/rollback.
