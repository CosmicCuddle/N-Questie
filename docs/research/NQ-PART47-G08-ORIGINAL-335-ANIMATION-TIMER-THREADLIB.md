# N-Questie Part47 — genuine historical 3.3.5a animation timer, ThreadLib and CombatQueue

**29 October 2026. Isolated TEST-ONLY draft. This is original Lua source executed against a fabricated AnimationGroup/OnFinished delivery host. Not real WoW gameplay, not native timer measurement and not an accepted production fix.**

## Original provenance and boundaries

The first-party original historical pre-README addon code commit is `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, NOT current protected live `335` `26053bd28b0df3a01e5859f779d5f3cb4f57b221`. Direct child of frozen green [TEST-ONLY #400](https://github.com/CosmicCuddle/N-Questie/pull/400), first submitted `7a94dd80b2f8d1677bf2ed79051586eeca475a03` (dedicated 676/676 each Lua5.1.5/5.4.6, nine authenticated original Git source hash pins, clean checkout, zero artifacts; broader exact-head 37/37 Actions already green before branch creation).

This new fixture extracts and executes the **unchanged contiguous authentic first-party block of `Compat/Compat.lua:131–190`** from original Git blob `b3e273e82cabbd5b7b351ae5aa3d94d4675387be`. The block includes ORIGINAL `activeTimers` and `inactiveTimers` tables, original `timerCancel`, original `timerOnFinished`, original `QuestieCompat.C_Timer.NewTicker` and original `QuestieCompat.C_Timer.After`, preserving closure/upvalue identity. It also executes WHOLE unchanged original `Modules/Libs/ThreadLib.lua` Git blob `8f564049ad2a4af49473fac939b7c276c4227dd7` and WHOLE unchanged original `Modules/Libs/QuestieCombatQueue.lua` Git blob `5f3fcbac09b95561e4e778a94936627e3c4e0a0e` **in the same fake host**. It READS the authentic original `QuestieInit.lua` call order and seven intervening `coYield()` markers, but does NOT execute QuestieInit or real QuestEventHandler in this particular fixture. Other inherited fixtures test those source functions separately.

**The whole original Compat.lua, Compat:ADDON_LOADED, actual Blizzard Frame and animation clock are NOT executed.** The fixture supplies **FAKE** `Frame:CreateAnimationGroup`, `AnimationGroup:CreateAnimation`, `Animation:SetScript`, `SetDuration`, `GetParent`, `AnimationGroup:SetLooping`, `Play`, `Stop` and manually fired `Animation.OnFinished` events. No actual elapsed-time, event interleaving, WoW API behaviour, real player data or native game access measured. Source-backed transition only.

## Distinct source contracts under fabricated animation callbacks

- Original `NewTicker(0,...)` clamps duration to **0.01 seconds** in the source, whereas earlier fake timer hosts used 0. Initial group setup uses `SetLooping("REPEAT")` and `Play`.
- Original `:Cancel` stops the animation group, removes its timer ID from active mapping and pools the underlying animation. A second cancel on the same ID has no effect. `After` uses one-iteration NewTicker and automatically cancels.
- Original timer reuse obtains inactive animation groups; each activation creates a new timer ID. An intentionally synthetic callback that cancels then restarts a ticker **inside the same OnFinished** exercises the original identity guard `if id == self.id then`; the newly reused timer does not inherit the old callback's iteration decrement.
- Original `ThreadLib.ThreadCallback` driven by this genuine timer implementation resumes a coroutine via fake OnFinished ticks, receives a 0→0.01 clamp, and cancels the timer **on a subsequent tick after the coroutine becomes dead**, calling the completion callback.
- Original `QuestieCombatQueue.Initialize` uses the genuine `NewTicker(0.1,...)`; pre-init Queue submissions are dropped. Under manually fabricated combat lockdown, queue execution waits. The original `maxUpdatesPerCircle = 5` code processes **six** pending entries on the first fake ticker callback (because `count` starts at zero and is checked before increment), and the seventh on the next callback. This source-under-fake-host count is NOT proof of real native timing or player-visible issue.
- No original addon source mutations; test-only workflow still authenticates all **NINE exact original historical Git blob hashes** inherited from #400.

## CI, release and peer boundaries

Exactly **THREE isolated test-only paths**: new `tests/compat/nq_part47_original_335_animation_timer_threadlib.lua`, extension to test-only `.github/workflows/nquestie-part45-g08-original-orphan-child-epoch.yml`, and this new research document `docs/research/NQ-PART47-G08-ORIGINAL-335-ANIMATION-TIMER-THREADLIB.md`.

New fixture proposes **45 distinct source-under-fake-animation assertions EACH actual Lua5.1.5 and Lua5.4.6**. Inherited #400 **676/676 EACH** → **PROSPECTIVE 721/721 EXECUTED EACH**; do NOT credit until exact original-head GitHub Actions job/logs, nine source hash checks, clean checkout and ZERO artifacts independently confirmed. Broader 37/37 must also be checked separately.

Native 3.3.5a animation tick frequency, live timer lifecycle, specific event ingress and reward/abandon hooks, 1→0 objective reachability, `WasComplete` and actual gameplay impact still UNKNOWN. Prior red original heads #390/#396/#397 preserved. Gate08 **MAJOR RED**, 439 RAW candidates unapproved and pilot quests 1207–1209 0/3 implemented. No production addon Lua/SQL/TOC, native client, account/player/SavedVariables, ZIP/build/install/merge/tag/release absent new explicit owner approval and backups/hash/rollback.
