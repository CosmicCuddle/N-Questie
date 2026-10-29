# Part47 — genuine original 335 compatibility reward/abandon hooks into genuine private handler lifecycle

**29 October 2026. TEST-ONLY source integration under FABRICATED reward/abandon actions, quest log and AnimationGroup. Native event/hook ordering, actual player effects and 3.3.5a client behaviour remain UNKNOWN. No production fix, release, client or account use.**

## Original source authentication and ancestry

This draft is a direct child of [TEST-ONLY #410](https://github.com/CosmicCuddle/N-Questie/pull/410) frozen original head `8f69ca4703106f25d4f0cc97dfb1659e4459fce8`, which has dedicated exact-head **788/788 checks EACH real Lua5.1.5 and Lua5.4.6**, nine authenticated historical original Git source blob hashes, clean checkout, zero artifacts. Full #410 original-head 37/37 broader CI was 36/37 with M2 still running at branch preparation. Do not call #410 fully green until separately rechecked.

The **historical original addon CODE** commit is `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, separate from protected README-only live `335` `26053bd28b0df3a01e5859f779d5f3cb4f57b221`.

- Original unchanged `Modules/Quest/QuestEventHandler.lua` Git blob `fa3950ad5078ed299226fe384ea20eba2674b853`. This fixture executes the **three complete authentic private handler method bodies** `_QuestEventHandler:QuestTurnedIn`, `_QuestEventHandler:QuestRemoved`, `_QuestEventHandler:MarkQuestAsAbandoned`. It does NOT load the full original module top-level or genuine QuestLogCache/QuestieQuest/Journey/Announce sink modules, which are FAKE stubs.
- Original unchanged `Compat/Compat.lua` Git blob `b3e273e82cabbd5b7b351ae5aa3d94d4675387be`. The fixture executes the **complete unchanged original** `QuestieCompat:CHAT_MSG_SYSTEM` and `QuestieCompat.QuestEventHandler_RegisterEvents` method bodies, and the **exact contiguous unchanged original 335 animation timer block `Compat.lua:131–190`**. Whole `Compat.lua` / `Compat:ADDON_LOADED`, actual `hooksecurefunc`, client API and Blizzard AnimationGroup engine are NOT executed.
- Inherited suite still SHA-authenticates the exact same NINE historical first-party Git source blobs. This new fixture does NOT run all nine modules; it uses the referenced bodies and timer block.

## New integration contract tested only under fake host

1. Calling original compat registration under a fake frame unregisters modern `QUEST_TURNED_IN` and `QUEST_REMOVED`, keeps `QUEST_ACCEPTED`, registers `CHAT_MSG_SYSTEM` and attaches original reward, abandon-selection and abandon secure-hook callbacks via a **FAKE hooksecurefunc recorder**.
2. Fabricated `GetQuestReward` caches the synthetic quest title and ID; a fabricated matching `CHAT_MSG_SYSTEM` then calls the **genuine original private QuestTurnedIn then QuestRemoved**, not a stub as prior #400 did. The real private bodies update local quest state, call fake Cache/Quest/Journey/Announce sinks and broadcast, and clear quest log state without an abandonment timer. Duplicate completion message does not repeat effects.
3. Fabricated `SetAbandonQuest` records the synthetic selected quest ID. Fabricated `AbandonQuest` calls the **genuine original private QuestRemoved** with it. This sets original REMOVED state and schedules an **original 335 C_Timer.NewTicker(1,...,1)** through the real first-party timer block and fake `AnimationGroup`. A manually delivered fake OnFinished invokes genuine original MarkQuestAsAbandoned, its fake cache/sinks and cancellation. This is an end-to-end source route (with fabricated external APIs), not native 335 timing.
4. Separately, the fabricated event sequence calls `AbandonQuest` **without first calling `SetAbandonQuest`**. Original compat hook calculates a fallback `questId` from the fake selected quest log but calls `_QuestEventHandler:QuestRemoved(QuestieCompat.abandonQuestID)` instead. With the fabricated captured ID nil, the actual original QuestRemoved attempts to assign into `questLog[nil]`, which raises a Lua nil-table-index error in the fake host BEFORE broadcaster/timer. The previous #400 test only witnessed a nil stub argument. **Whether Blizzard's actual 3.3.5a UI/API ever supplies this hook sequence is UNKNOWN**. No live addon bug, user impact or production fix is established, and this deliberately malformed call cannot be used as proof of native reachability.
5. The fake `Animation:SetScript("OnFinished")` is deliberately stored in distinct `onFinished` field from the genuine timer's `callback` field, preserving the previous #405–#407 synthetic failure evidence and corrected #408 behaviour.

## CI counts and safety boundaries

Exactly THREE isolated test-only paths: new `tests/compat/nq_part47_original_335_compat_real_handler_lifecycle.lua`, edited existing **test-only** `.github/workflows/nquestie-part45-g08-original-orphan-child-epoch.yml`, new this research note `docs/research/NQ-PART47-335-COMPAT-REAL-PRIVATE-HANDLER-BRIDGE.md`. No genuine addon source/SQL/TOC/protected production edits, native client or SavedVariables/character access, ZIP/build/install/merge/tag/release.

**Proposed 32 NEW assertions per actual Lua5.1.5 and Lua5.4.6** plus inherited #410 **788/788 EACH = prospective 820/820 EXECUTED EACH**. Do not credit before independent exact original-head dedicated job/log dual-Lua pass, nine authentic historic original source SHA checks, clean checkout and zero artifacts. Full broader CI independently tracked.

**Gate08 MAJOR RED**, 439 RAW quest candidates unapproved and pilots 1207–1209 0/3. A separate owner-approved native 335 observation with verified staging backups, file hashes and rollback would be required to determine actual reward/abandon hook order, quest objective 1→0, WasComplete/AnimationGroup timing or player impact.
