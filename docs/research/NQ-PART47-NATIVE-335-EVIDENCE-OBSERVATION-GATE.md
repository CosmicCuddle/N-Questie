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
