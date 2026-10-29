# Part47 — original 335 CombatQueue mid-drain and reentrant-enqueue contract

**29 October 2026. TEST-ONLY. Original Lua code executes under a fabricated AnimationGroup host with manually fired callbacks, fabricated combat state and invented queued work. No real WoW3.3.5a gameplay/native timing, no addon bug confirmation or production authorization.**

## Provenance and immutable ancestry

- Historic genuine N-Questie addon-code commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` is different from owner-approved protected README-only live `335`, last `26053bd28b0df3a01e5859f779d5f3cb4f57b221`.
- Direct child of full-green frozen [TEST-ONLY #408](https://github.com/CosmicCuddle/N-Questie/pull/408) first submitted original `5277b8bd3dbd9a3dc1a633efb2f773df2293ee5a`, independently **37/37 full exact-head Actions SUCCESS** and **756/756 EXECUTED checks EACH actual Lua5.1.5 and Lua5.4.6**, NINE historical source SHA authentications, clean checkout, ZERO artifacts. Prior original FAILED #390/#396/#397/#405/#406/#407 heads remain unchanged.
- Execute **WHOLE unchanged historical `Modules/Libs/QuestieCombatQueue.lua`** Git blob `5f3fcbac09b95561e4e778a94936627e3c4e0a0e` and **EXACT unchanged contiguous historical `Compat/Compat.lua:131–190` animation timer source** Git blob `b3e273e82cabbd5b7b351ae5aa3d94d4675387be`, preserving original timer/cancellation/upvalue semantics. This fixture does NOT execute ThreadLib, QuestEventHandler, full Compat.ADDON_LOADED or QuestieInit; inherited other isolated fixtures test these separately.
- The fake `Animation:SetScript("OnFinished",...)` handler lives in a **distinct** `onFinished` field rather than original `timer.callback` user callback to avoid the synthetic collision documented in preserved RED #405–#407, corrected #408.

## New queue source-under-fake-clock behaviours

The fixture supplies **FAKE** `CreateAnimationGroup`, `CreateAnimation`, `SetScript`, `SetDuration`, `GetParent`, `SetLooping`, `Play`, `Stop`, manually fired OnFinished callbacks, `InCombatLockdown` and a synthetic QuestieLib.tpack/tunpack (the original queue source is unchanged). It verifies:

1. Original `Queue` ignores callbacks before `Initialize`; no timer created. Original queue startup creates original 335 NewTicker `0.1` repeated AnimationGroup and empty ticks do nothing.
2. A queued callback appends another callback and switches fabricated combat lockdown to true while executing. Original code checks combat after executing that entry and stops draining, leaving existing work. A tick during locked state does not run it; after fake unlock, original FIFO drains existing callbacks before appended work.
3. Original `tpack/tunpack` integration preserves a supplied four-argument callback with a nil second AND trailing nil fourth argument (synthetic QuestieLib helper; queue original).
4. Original source `maxUpdatesPerCircle=5` processes **six** of eight invented callbacks in the first manually fired fake timer tick (original counter initialized at zero and guard placed before increment), and two on the second. This is a **source-level off-by-one batch behaviour**, NOT demonstrated native performance impact.
5. An invented callback in a seven-item backlog enqueues a later callback. That appended callback stays after the pre-existing seventh in FIFO; original first source tick still drains only six callbacks and the second drains the seventh then appended one.
6. Under another invented callback that turns combat lockdown on, the original queue pauses immediately after it; it drains the rest on the fake tick after unlocking. Original repeating animation timer remains active throughout.

## Tests, safety and release bounds

Exactly **THREE isolated changed paths**: NEW `tests/compat/nq_part47_original_335_combatqueue_mid_drain.lua`, extension to existing test-only `.github/workflows/nquestie-part45-g08-original-orphan-child-epoch.yml`, NEW this research note `docs/research/NQ-PART47-G08-ORIGINAL-335-COMBATQUEUE-MID-DRAIN.md`. All NINE historical Git source blob SHA pins and original-addon protected Lua/SQL/TOC untouched. Zero ZIP/build/install/merge/tag/release/native client/player/SavedVariables.

**Proposed NEW 32 source-under-fake-animation assertions EACH actual Lua5.1.5 and Lua5.4.6** + inherited #408 **756/756 EACH** = **PROSPECTIVE 788/788 EXECUTED EACH**. Do NOT credit until new original-head dedicated Actions/job/logs independently show both versions passing, authenticated nine original source SHA pins, clean checkout, ZERO artifacts. Wider original-head 37/37 Actions separately checked.

Real 3.3.5a callback cadence, quest events during startup, native abandonment hook call ordering, objective 1→0 transitions, WasComplete and actual player effects remain **UNKNOWN**. **Gate08 MAJOR RED**, 439 RAW quest candidates unapproved and pilot quests 1207–1209 **0/3**. Any native client QA, production addon code/SQL/TOC, player/character/SavedVariables, ZIP/build/install/merge/tag/release requires separately explicit owner authorization, verified backup hashes and rollback.
