# Part47 — historical 3.3.5a compatibility quest event registration and hook routing (TEST ONLY)

**29 October 2026. Isolated test-only source verification; not a native 3.3.5a client test, production patch, or release permission.**

## Original sources and preserved branch

This test is an isolated direct child of full original-head **37/37 green** [TEST-ONLY #398](https://github.com/CosmicCuddle/N-Questie/pull/398), exact frozen original `e9c0d3174b318c0890a71b9bc37878449a154230`. Original historical pre-README addon code pin `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, not live owner-approved README-only `335` `26053bd28b0df3a01e5859f779d5f3cb4f57b221`.

- Original `Modules/Quest/QuestEventHandler.lua` Git blob `fa3950ad5078ed299226fe384ea20eba2674b853`, **entire unchanged original `QuestEventHandler:RegisterEvents` method body** executed under synthetic event frame/private init method.
- Original `Compat/Compat.lua` Git blob `b3e273e82cabbd5b7b351ae5aa3d94d4675387be`, **entire unchanged original `QuestieCompat.QuestEventHandler_RegisterEvents` and `QuestieCompat:CHAT_MSG_SYSTEM` method bodies** executed with synthetic data. The exact unchanged `hooksecurefunc(QuestEventHandler, "RegisterEvents", QuestieCompat.QuestEventHandler_RegisterEvents)` installer LINE is extracted from the real `Compat:ADDON_LOADED` source and EXECUTED in a generated fake-host wrapper. **The whole original `Compat:ADDON_LOADED` and entire `Compat.lua` are NOT executed.**
- Existing test-only CI independently authenticates **NINE** original Git blob hashes; the source verification does not mean every original module executes in this particular fixture. Historic red #390/#396/#397 heads remain frozen, and green #398 not modified.

## First-party 335 event routing (source contract)

The original core `QuestEventHandler:RegisterEvents` registers `QUEST_ACCEPTED`, `QUEST_TURNED_IN` and `QUEST_REMOVED` on its event frame and sets real original `OnEvent`. The original 335 compat `ADDON_LOADED` source installs a *post-hook* on `RegisterEvents`. Under the original 335 `QuestieCompat.QuestEventHandler_RegisterEvents` body, the post-hook then **UNREGISTERS `QUEST_TURNED_IN` and `QUEST_REMOVED`** from `QuestieQuestEventFrame`, while preserving `QUEST_ACCEPTED` and `QUEST_LOG_UPDATE`. It registers `CHAT_MSG_SYSTEM` and `QUEST_QUERY_COMPLETE` on the compatibility frame and securely hooks `GetQuestReward`, `SetAbandonQuest` and `AbandonQuest`.

The original `GetQuestReward` hook stores a quest ID by title in a local `completeQuestCache`; later original `QuestieCompat:CHAT_MSG_SYSTEM` converts a matching synthesized system completion message into genuine private handler `QuestTurnedIn` followed by `QuestRemoved`. The original `SetAbandonQuest` hook remembers an abandoned quest ID and original `AbandonQuest` hook invokes genuine private `QuestRemoved`. The fake fixture stubs the PRIVATE methods to record parameters instead of executing them; other inherited source tests handle real original method bodies under different fake hosts.

**Conditional source hazard, not a proven defect:** Original `AbandonQuest` hook computes a local fallback `questId` from quest-log selection but calls `_QuestEventHandler:QuestRemoved(QuestieCompat.abandonQuestID)` rather than passing this local fallback. Under a deliberately fabricated invocation lacking a preceding SetAbandonQuest, this sends nil to fake private sink. Actual WoW 3.3.5a UI call order and whether this branch can happen are UNKNOWN. This is not a production-fix recommendation.

## Fake-host scope / CI

This NEW fixture calls authentic original method bodies and installer LINE, but mocks `hooksecurefunc` by posthook chaining, quest/compat event frames, GetQuestReward/SetAbandonQuest/AbandonQuest invocations, quest name resolution, system message, questlog, private handler methods and addon initialization timing. It checks **30 independent source-under-fake-host assertions EACH Lua5.1.5 and Lua5.4.6**. Inherited #398 **646/646** executed each interpreter → **PROPOSED total 676/676 executed EACH**; do NOT credit until new exact original-head dedicated Actions success, all nine source hash authentications, clean checkout, **ZERO artifacts**. Source-aware interpretation supersedes the assumption that ordinary QUEST_REMOVED/QUEST_TURNED_IN frame delivery is the normal post-compat native path.

Exactly three isolated paths: NEW `tests/compat/nq_part47_original_335_compat_quest_hooks.lua`, existing test-only workflow extension, NEW this `docs/research/NQ-PART47-ORIGINAL-335-COMPAT-QUEST-HOOK-ROUTING.md`. No addon Lua/SQL/TOC edit, native client execution, player/character or SavedVariables access, build, ZIP, install, merge, tag or release.

**Gate08 MAJOR RED**; 439 RAW candidates unapproved and pilot quest IDs 1207–1209 **0/3**. All other native event timing, Objective 1→0, `WasComplete`, AnimationGroup and ThreadLib lifetimes UNKNOWN until independently measured with separately approved native QA and verified backups/hashes/rollback.
