# N-Questie Part47 — Native 3.3.5a evidence gate and observation plan (NOT AUTHORIZED QA)

**29 October 2026 — Research/documentation only.** This is a proposal for a future **separately owner-authorized** isolated native-client observation. No Blizzard client was run for this document; no addon Lua, client files, player/account, character, SavedVariables, install ZIP, server, SQL, release asset or production branch was modified. This is **not** an invitation to deploy tests without permission.

## 1. Preflight that must be separately approved first

1. Obtain **explicit owner permission** specifically for a disposable/staging WoW 3.3.5a client, a non-production character, an independently reviewable observation method and the precise quest scenarios. Current authorization is **none**. Maintain a separate decision record identifying the owner, scope and rollback procedure. A documentation draft is not such approval.
2. Identify isolated client build and AzerothCore/server/module revisions, addon installation snapshot, original addon source commit and exact hashes of every relevant file. Current protected GitHub `335` remains owner-approved README-only; historic actual addon source is Git commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, not something to deploy by assumption.
3. Before any approved staging action, make timestamped **verified backups** of staging addon folder, staging WTF/SavedVariables, all staging DBC/patch assets, and any database state that could be touched. Hash before/after, verify restore on disposable copies and retain the rollback result privately. Do **not** export private player data or client files to GitHub or this research.
4. Require a no-production-write boundary, no live account, no protected addon edits and no ZIP/build/install/merge/release unless **separately** explicitly authorized; any native observation instrumentation would itself need reviewed, reversible, minimal changes and owner signoff. Stop upon any unexpected state mutation or uncontrolled frame timing.

## 2. Original-source observation questions and baselines

The immutable historical original 335 code shows these first-party boundaries, which are **not** evidence of native event arrival:

- `Modules/QuestieInit.lua:296–317` invokes `QuestEventHandler:RegisterEvents()`, has seven explicit coroutine yield calls before `QuestieCombatQueue.Initialize()`. The source region includes eight yields counting the one immediately before registration. The **whole original Stage3 has not executed** in current tests.
- `Modules/Libs/ThreadLib.lua` resumes the init coroutine through `QuestieCompat.C_Timer.NewTicker(delay or 0,...)`; original `Compat/Compat.lua:131–190` backs it with `AnimationGroup` and clamps 0-delay to 0.01. Prior fake tests manually triggered `OnFinished` but have **not measured a single live tick or frame**.
- `Modules/Libs/QuestieCombatQueue.lua:40–44` rejects `Queue` calls before initialized; its 0.1 ticker checks combat before and during draining. Latest synthetic #410 original source-under-fake-animation fixture covers mid-drain combat and FIFO reentrant enqueue, but **not real native timing**.
- `Compat/Compat.lua:1384–1423` post-hooks original `RegisterEvents`, unregistering `QUEST_REMOVED` and `QUEST_TURNED_IN` and substituting reward/abandon hooks. Treat modern-frame synthetic `QUEST_REMOVED` / `QUEST_TURNED_IN` delivery as **source-method testing**, not normal post-compat 3.3.5a ingress proof.
- `Compat/Compat.lua:1419–1422` computes a local fallback abandoned quest ID but invokes `QuestRemoved` with the captured `QuestieCompat.abandonQuestID`. Whether native `AbandonQuest` can be called without preceding `SetAbandonQuest` (or with a stale captured value) is **UNKNOWN**.
- Original real quest objective 1→0 transitions, `WasComplete` evolution, AnimationGroup/ThreadLib callback lifecycle, client event times, addon state after login and user-visible impact remain **UNKNOWN**.

## 3. Evidence protocol, after separate approval only

Use a reviewed **read-only trace** in a disposable approved client (or source-native test environment if separately approved), with a monotonic in-client timestamp and stable per-session sequence number. The trace must not modify event registration, quest states, timers, queue order or lock state just to make the suspected window appear.

Capture the **actual order** and timestamps of: compatible addon `ADDON_LOADED` hook installation; `QuestEventHandler:RegisterEvents()` start/end; real post-hook registration changes; genuine `QUEST_ACCEPTED` and relevant update callbacks; entry into original `QuestieCombatQueue:Queue` with observed initialized state; `QuestieCombatQueue.Initialize()`; actual original 335 AnimationGroup `OnFinished` invocations; queued callback execution; and unrelated combat state if it naturally changes. Trace records must distinguish the **event was delivered** from **callback execution attempted** and from **callback successfully applied**.

For abandonment, observe naturally occurring `SetAbandonQuest`, `AbandonQuest`, quest-log selection, captured quest ID, computed fallback ID and actual `QuestRemoved` argument. Do not force out-of-order hooks merely to obtain a desired result. Redact quest/character/session identifiers as needed; no raw private SavedVariables or account information in public PRs.

For completion and objective state, distinguish true 3.3.5a compatible `GetQuestReward` and system-message flow from events absent in the client, and capture *actual* objective before/after plus `WasComplete` transitions on an owner-approved staging-only quest. Do not use unapproved 439 RAW candidate data or claim pilot IDs 1207–1209 are implemented.

## 4. Evidence grading, pass/fail and abort criteria

- **Source observation only**: original Lua code and Git blob hashes inspected. Cannot confirm a native event occurred.
- **Synthetic execution**: real first-party Lua methods executed under fake APIs/timers. Cannot confirm real frame timing, client event availability or player effects.
- **Native observation**: only an owner-approved client trace with exact reproducible steps, unmodified source identity, event/order timestamps, session/client build, observed queue initialization and before/after state can show a real occurrence. If the event does not occur, report that as an inconclusive *negative observation*, not impossible globally.
- **Regression/release candidate**: requires separately approved implementation, verified backups/hashes/rollback, native reproduction, tests, CI and owner release authorization. No such status is granted.

Stop immediately if protected `335` changes, staging writes leave the approved boundary, data privacy is at risk, trace instrumentation itself changes timing materially, authentication of original source fails, or any unreviewed fix is suggested.

## 5. Current ledger and pointers

- **Gate08 MAJOR RED**; 439 RAW quest candidates not approved; pilot quests 1207–1209 **0/3 implemented**. No client QA, merge, production patch, installation, distribution or release performed.
- [Frozen TEST-ONLY #408](https://github.com/CosmicCuddle/N-Questie/pull/408) exact `5277b8bd3dbd9a3dc1a633efb2f773df2293ee5a`: **37/37 broad exact-head Actions SUCCESS**, dedicated 756/756 source/model assertions EACH real Lua5.1.5/5.4.6, nine historic source blob pins, zero artifacts.
- [TEST-ONLY #410](https://github.com/CosmicCuddle/N-Questie/pull/410) submitted frozen exact `8f69ca4703106f25d4f0cc97dfb1659e4459fce8`, direct child #408. Dedicated [run 40902455127](https://github.com/CosmicCuddle/N-Questie/actions/runs/40902455127), job `123548124640`: **all steps success**, 32 new + inherited 756 = **788/788 EXECUTED EACH real Lua5.1.5 and Lua5.4.6**, nine original source SHA pins, clean checkout and ZERO artifacts. Wider full exact-head 37/37 Actions were **still pending when this note was authored**, do not call broad full green until independently verified.
- Prior original failed synthetic heads remain frozen **#390/#396/#397/#405/#406/#407**, with separate corrective green PRs; no original test failure is erased.
- Original DOCS-only #409 `9e9a24ff57fc7957d0cd7c928955df2370406c15` is independently **7/7 full exact-head Actions SUCCESS**, immutable parent of the present docs work.

**Next gate**: separate user authorization and reproducible native observation—not more synthetic passing checks alone. This plan is only a prepared artifact, **not an action request or authority to proceed**.

## 6. Part48 focused acceptance-window evidence matrix (PROPOSAL ONLY; NOT AUTHORIZED)

**30 October 2026, source review only.** This appendix narrows an existing question; it does **not** approve running a client, changing addon Lua, adding observer hooks, accepting a quest, using an account, producing a build, or publishing a trace. Sections 1–5 and all owner approval, staging isolation, backups/hashes/restore and privacy stop conditions still apply. This document lives on an isolated unmerged DOCS-ONLY draft.

### 6.1 Immutable first-party control-flow facts

At the historical original addon source commit \`8b23c6e2cfa00bb81cb26d40c44fef154e9e0070\`:

- \`Modules/QuestieInit.lua:296–317\` performs \`QuestEventHandler:RegisterEvents()\`, then **seven explicit coroutine yields**, later \`QuestieQuest:GetAllQuestIds()\`, \`QuestieTracker.Initialize()\` and finally \`QuestieCombatQueue.Initialize()\`. Yield count is **not** a measured duration.
- \`Modules/Quest/QuestEventHandler.lua:56–71,179–196\` registers the quest events and runs \`InitQuestLog()\` during registration; this initial quest-log import is not an acceptance callback replay.
- \`Modules/Quest/QuestEventHandler.lua:203–263\` starts a new acceptance event with \`questLog[questId] = {}\`; \`HandleQuestAccepted()\` is deferred by \`QuestieCombatQueue:Queue()\`. If reached, the handler marks state \`QUEST_ACCEPTED\` and invokes the Journey/optional announcement and \`QuestieQuest:AcceptQuest()\` or special phase branch.
- \`Modules/Libs/QuestieCombatQueue.lua:12–44\` drops submissions while its private local \`started\` is false; \`Initialize()\` subsequently starts its timer and marks started true.
- \`Modules/Quest/QuestEventHandler.lua:430–460\` constructs the later full-scan candidate set from event-handler entries already marked \`QUEST_ACCEPTED\`. A still-empty entry is excluded, so that scan does not by itself re-run a missing \`HandleQuestAccepted()\`.
- \`Modules/Quest/QuestieQuest.lua:681–724\` reconstructs cached quest information; \`Modules/Tracker/QuestieTracker.lua:83–~261\` has an independent one-second delayed sync when tracker enabled. Neither source path calls the acceptance-specific Journey handler.
- \`Modules/QuestieEventHandler.lua:~90–95\` also registers an earlier \`QUEST_ACCEPTED\` route for \`QuestieAuto\`; \`Modules/Auto/QuestieAuto.lua:270–275\` performs only a conditional UI workaround, **not** acceptance state recovery.

A community-maintained 3.3.5 interface snapshot (\`wowgaming/3.3.5-interface-files/QuestLogFrame.lua\`, blob \`0bbdf48d4987b3205c34373e41baf2e0f8ad5885\`) registers and handles \`QUEST_ACCEPTED\`. It is **not** authoritative evidence of the engine's timing in this addon. Genuine event delivery during the Stage3 gap remains **UNKNOWN**.

### 6.2 Distinguish three possible windows, never infer their occurrence

| Case | Native event timing *if observed* | First-party source implication | What remains unknown |
|---|---|---|---|
| A | Acceptance before \`QuestEventHandler:RegisterEvents()\` | That handler never receives this event; registration-time \`InitQuestLog()\` may import a quest already represented by valid game cache data | Whether the import captures this quest and all appropriate state |
| **B — primary hypothesis** | \`QUEST_ACCEPTED\` actually delivered **after** registration and **before** \`QuestieCombatQueue.Initialize()\` | \`QuestAccepted()\` can leave an empty event-handler entry when its deferred \`HandleQuestAccepted()\` submission is dropped; ordinary later selective scans exclude that entry | Whether this event ever occurs natively; independent recovery and actual player impact |
| C — control | Acceptance delivered **after** combat queue initialization | Deferred handler can be retained; execution still depends on native timer delivery, combat, quest cache and later processing | Actual callback completion and UI side effects |

**Do not convert an event documented as supported into an assertion that Case B occurs.** Do not force input/event ordering, assume a delay of \`7 × initDelay\`, or replay a journey entry or chat announcement to make a particular case appear.

### 6.3 Minimal discriminating observations, only after separate explicit approval

For a disposable *approved* staging session, the separately reviewed observation plan would record one monotonic timestamp and ordered sequence ID for each meaningful boundary, with source build/hash identity and the following fields:

1. **Initialization markers:** registration began/completed; \`InitQuestLog()\` snapshot done; each actual Stage3 resume relevant to the event; combat queue \`Initialize()\` began/completed. Capture which original 335 compatibility post-hook registrations are active.
2. **Event receipt:** actual \`QUEST_ACCEPTED\` receipt and its two arguments (log index and quest ID), plus whether the quest is visible in the genuine quest log and \`QuestLogCache\`. Distinguish an event dispatched to the separate auto-accept listener from an event handled by \`_QuestEventHandler:QuestAccepted()\`.
3. **Callback life cycle:** queue submission attempted, accepted/discarded (only if securely observable), callback start, \`HandleQuestAccepted()\` completion/retry and genuine timer/combat state. A simple external hook **cannot by itself read the queue's private local \`started\`**; any additional instrumentation of that state is **separately owner-reviewed and authorized** or else classify the state as unobserved.
4. **After-state, not just UI:** event-handler accepted/empty state; quest membership in \`QuestLogCache\` and \`QuestiePlayer.currentQuestlog\`; whether a later \`UpdateAllQuests()\` selected the quest; Journey acceptance count/timestamp; enabled/disabled announcement setting; special quest flag effects where applicable; tracker state after the separate delayed sync. Distinguish *callback never ran* from *callback ran but was blocked/retried*.
5. **Baseline/control:** a previously active quest imported at login (A-type import, no new acceptance), an ordinary new quest accepted after queue initialization (C-type control), and a naturally occurring B-type event **only if it happens without fabricated timing**. Use only owner-approved non-production quests, never unapproved candidate/pilot quest data.

Observing a B-type event plus an unexecuted handler and unrecovered relevant after-state would substantiate the specific *native* acceptance-loss hypothesis. Observing successful independent recovery would narrow or negate that claimed downstream effect **for that session**. Seeing no B-type event in a session is **inconclusive**, not proof that B cannot happen. Seeing only the source's queue-drop condition is **source/synthetic evidence**, not native reproduction.

### 6.4 Decision and safety holds

- **Current evidence grade: SOURCE ONLY / inherited SYNTHETIC, not native.** No new Lua fixture is justified merely to re-show the already established drop behavior.
- **Approval gate still closed:** owner must separately approve exact disposable staging environment, test quest scope, observation/instrumentation approach and rollback; verify full backups/hashes and restore privately before any test.
- **Stop / do not publish:** any unexpected writes, uncertain source identity, privacy exposure, timing-modifying hooks, missing backup restore proof, or owner scope mismatch.
- **No automatic fix:** do not change protected addon source, reorder startup, backfill Journey history, replay chat announcements, merge, build or release based on this appendix.
- **Gate08 MAJOR RED:** 439 RAW candidates unapproved; pilot quests 1207–1209 are 0/3 implemented. Existing immutable PR heads and the protected README-only \`335\` branch remain untouched.
