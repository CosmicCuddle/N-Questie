# N-Questie — Part 47 Living Development Checklist

**29 October 2026. PUBLIC-SAFE, APPEND-ONLY DRAFT.** This document records evidence and work queues, not game testing, merge authority or release acceptance.

**READ BOTH COMPLETE DOCUMENTS before Part47 action:**
1. [Complete Part46 → Part47 Engineering Handover](HANDOVERS/2026-10-29_PART46_TO_PART47.md).
2. **This entire Part47 Living Development Checklist.**

Also reference [Part46 Checklist](NQ-PART46-LIVING-DEVELOPMENT-CHECKLIST.md), [Master Checklist](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), [Coordination PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42), and the historic original source pinned at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. This checklist is on a **docs-only DRAFT branch**; its existence does not mean anything is merged to the protected production branch.

## A. Frozen production and approvals (MANDATORY)

- [x] Last independently verified (29 October 2026), protected live production `335` = **`26053bd28b0df3a01e5859f779d5f3cb4f57b221`**; owner-approved root README-only #351 merge. The HISTORICAL source code SHA `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` is NOT the live head. Verify both provenance and live state on Part47 entry.
- [x] N-Questie is an intentionally public WIP fork of Questie-335. Keep the prominent no-emoji incomplete-project banner. No visibility/fork changes without explicit owner request.
- [x] **Gate08 MAJOR RED**; 3 complete / 6 underway / 3 technically pending. **439 RAW** quest candidates unapproved; eligible denominator unknown; pilot IDs **1207–1209 0/3 implemented**. No Alpha0/gameplay-ready status or native acceptance.
- [ ] **Absolute no-touch boundary without separately renewed permission:** no edits/merges on protected `335`; no original addon Lua/TOC/SQL DB, native client, real player/account/character/SavedVariables, ZIP/build/package, installation, release, tag, protected branch changes, realm migration or hidden live tests. The earlier owner-approved README change never constitutes gameplay permission.
- [ ] If owner later separately approves native QA, first make full addon and SavedVariables backups with hashes, safe rollback, and explicit test scope. Never claim test-host/synthetic dual Lua equals actual 3.3.5a QA.

## B. Latest exact original heads and independently verified CI

- [x] [TEST-ONLY #378](https://github.com/CosmicCuddle/N-Questie/pull/378), exact original `656462e4f80d12860c0cf81779d4e7745c251833`: **37/37 full GitHub Actions SUCCESS**, dedicated [40870920243](https://github.com/CosmicCuddle/N-Questie/actions/runs/40870920243), job `123437443703` verifies **426/426 EACH real Lua 5.1.5 and Lua 5.4.6**, six historical original blobs and clean checkout; zero artifacts. New 32 model-only witnesses cover CS02's two surviving child-parent and terminal-identity model guards. No addon writer/owner guard exists in production.
- [x] [DOCS-ONLY #379](https://github.com/CosmicCuddle/N-Questie/pull/379), exact original `40020a0210e3940c6f903acb8f2358f8acc0ae4b`: **7/7 Actions SUCCESS**, only append-only Part46/master checklist, unmerged.
- [x] [TEST-ONLY #380](https://github.com/CosmicCuddle/N-Questie/pull/380), exact frozen original `9d44e8c8229ead538c45165aed73927d06ec858a`, dedicated [40871795068](https://github.com/CosmicCuddle/N-Questie/actions/runs/40871795068), job `123440421119`: **38/38 NEW source-under-fake-client plus inherited 426/426 = 464/464 EACH Lua 5.1.5 and 5.4.6; seven historical Git source blobs authenticated; clean checkout; zero artifacts; dedicated ALL STEPS SUCCESS**. Runs whole original `QuestLogCache.lua` plus unchanged original `_QuestEventHandler:UpdateAllQuests` body with fictional game/event/API data and mock `QuestieQuest:UpdateQuest` sink. No native event or real game client.
- [ ] At last Part46→47 handover check, #380 full original-head GitHub Actions **36/37 SUCCESS, ONE M2 in progress**, zero failures. **RECHECK**, do not premark 37/37.
- [x] [DOCS-ONLY #381](https://github.com/CosmicCuddle/N-Questie/pull/381), original frozen `7932e726bcd54035b754cb5f8b05732cd664a270`, append-only Part46/master #380 source and CI checkpoint, unmerged.
- [ ] At handover check, #381 full exact-head GitHub Actions **6/7 SUCCESS, one M2 in progress**, no failures. **RECHECK**, do not premark 7/7.
- [x] This new Part47 entry handover/checklist is a SEPARATE docs-only draft branch FROM frozen #381 head, never mutate its original SHA or any failed/successful test PR.
- [ ] Confirm current Part47 handover DOCS-ONLY draft PR number, exact SHA, changed files and CI after creation. Keep all drafts unmerged by default.

## C. Source truth vs mock model and native uncertainty

- [x] Seventh added original 335 blob `Modules/Quest/QuestEventHandler.lua` = `fa3950ad5078ed299226fe384ea20eba2674b853`. Other authentic six from historic code SHA: `QuestieQuest.lua` `cd4239c5b40c1f5b1ced823dfa12d8a895091719`; `QuestLogCache.lua` `09e9989922731f899994e6eb09af24465ae196ce`; `QuestieDB.lua` `5784cb65160175e1dce30fe20e8baada0af7e480`; `AvailableQuests.lua` `2664f09fdf1f5df4d94581414e9d5ea88e9af4e7`; `ThreadLib.lua` `8f564049ad2a4af49473fac939b7c276c4227dd7`; `Compat.lua` `b3e273e82cabbd5b7b351ae5aa3d94d4675387be`.
- [x] Authentic whole QuestLogCache + original `UpdateAllQuests` body under synthetic accepted quest objective 1→0 leaves old cached objective; no reported `changes[questId]`; no call to FAKE UpdateQuest despite `TestGameCache` potentially passing. Explicit host invocation of original `RemoveQuest` causes rebuild. **Source execution is real; quest data/event/sink are not.**
- [x] Original event handler `QuestEventHandler.lua:432–463` checks accepted quest IDs and updates only reported changes; `RemoveQuest` observed in turn-in/abandon and child-quest cleanup elsewhere. No direct `RemoveQuest` inside original `SmoothReset:282–384`.
- [x] Earlier dual-Lua tests separately execute original `SmoothReset`, `UpdateQuest`, `QuestieDB.GetQuest`, `IsComplete`, `CheckQuestSourceItem`, `AvailableQuests`, `ThreadLib`, original Compat timer FRAGMENT, and fake map/tooltip writer sinks. **No single native integration of all original modules ever tested.**
- [x] Counterfactual epoch/descendant `issued[child]` models are **invented test proposals, not original-addon protection**; CS02 [peer #369 result](https://github.com/CosmicCuddle/N-Questie/pull/369#issuecomment-6496106585) independently found two gaps; #378 new model-only 32/32 each addresses them. CS02 did not approve production changes.
- [ ] Native 3.3.5a real quest objective 1→0 without turn-in/abandon, actual `WasComplete` stale state, real AnimationGroup OnFinished/ThreadLib lifetime and map/tooltip stale writes all remain **UNKNOWN**. Do not present them as reproduced or as accepted production defects.

## D. Part47 task queue (work within permission)

- [ ] FIRST refresh protected live `335`, #380/#381 exact original-head CI, new peer comments on #42, any new draft heads and docs-only handover PR. Record verified data, not stale counts.
- [ ] Inspect `tests/compat/nq_part46_original_eventhandler_updateall_cache_bridge.lua` and authenticate all original source blobs, tagging original body vs fake handler upvalues/sinks. Identify only genuinely useful next source-level question.
- [ ] Research original QuestEventHandler accepted/turn-in/abandon lifecycle and whether original code `QuestLogCache.RemoveQuest` can precede or follow an objective-count transition that matters. Prefer read-only source-backed call-site verification and bounded synthetic fixtures, never invented 3.3.5a game facts.
- [ ] Trace original `QuestieQuest.UpdateQuest` `WasComplete`/missing source item conditions into step9 of original `SmoothReset`, noting that original step8 callback-bound available quests and fake-host scheduling do not prove native client event order. A coherent isolated test-only new draft may be appropriate with independently hashed source.
- [ ] Verify real/native scheduling and quest data ONLY if the owner explicitly approves a separate native QA task and the backup/rollback plan; otherwise mark UNKNOWN and stop at source/model boundary.
- [ ] Keep any additional tests and docs on NEW dedicated child branches, DRAFT PRs targeting corresponding draft branches, never rewriting frozen failing/successful original heads. Authenticate original immutable source, run actual Lua5.1.5+5.4.6 CI, verify logs, clean checkout, no build artifact before success claims.
- [ ] Preserve frozen failures #361/#362/#373/#374/#377 and earlier #328/#330/#338/#340/#345/#346/#352 as diagnostic history. No retroactive "fixed original" claims.
- [ ] Coordinate with CS02/Grok and CS03/Claude only via narrow, evidence-driven requests; avoid unnecessary duplicate work. The latter's native feasibility review has NOT been verified complete.
- [ ] Update Part47 and master checklists append-only with exact source/test/model/native boundaries. Keep owner-facing summaries readable and step-by-step.

## E. Handover and next chat

- [x] Part46→47 full handover and new Part47 checklist created in a separate docs-only draft child of #381.
- [ ] At Part47 start read both files IN FULL before development and recheck CI/peers/live SHAs.
- [ ] Continue active engineering and documentation in allowed test/docs-only drafts; do not mistake "please continue" for owner approval to run a client, edit protected production, or release.

**All gating decisions remain unchanged: Gate08 MAJOR RED; 439 RAW candidates unapproved; pilot 1207–1209 = 0/3; protected live 335 untouched.**
