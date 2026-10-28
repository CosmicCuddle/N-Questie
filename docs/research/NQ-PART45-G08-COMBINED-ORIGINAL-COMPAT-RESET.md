# Part45 G08 — Integrated original Compat timer and reset ownership (PUBLIC-SAFE TEST ONLY)

**28 October 2026. DRAFT, NO MERGE.** Exact protected original 335 commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, unchanged. All quest records, timer-frame transitions, bag/source-item decisions, map and tooltips are invented; no private game state, real network, builds, ZIPs or installed addon.

## Original source executed, precisely scoped

- Unmodified original `QuestieQuest:SmoothReset` and `QuestieQuest:UpdateQuest` **function bodies** from `Modules/Quest/QuestieQuest.lua`, blob `cd4239c5b40c1f5b1ced823dfa12d8a895091719`; whole module is **not** loaded.
- Complete unchanged original `Modules/Quest/AvailableQuests.lua`, blob `2664f09fdf1f5df4d94581414e9d5ea88e9af4e7`.
- Complete unchanged original `Modules/Libs/ThreadLib.lua`, blob `8f564049ad2a4af49473fac939b7c276c4227dd7`.
- Authentic unchanged `Compat/Compat.lua` blob `b3e273e82cabbd5b7b351ae5aa3d94d4675387be`, **timer FRAGMENT ONLY**, original lines 131–190, responsible for `timerCancel`, `timerOnFinished`, `NewTicker`, `After`, ID protection and pool. The remaining Compat module **does not** execute.
- External test host provides only fake `frame:CreateAnimationGroup`, `CreateAnimation`, `OnFinished`, tick stepping and invented QuestieDB and game APIs. A passive wrapper records original `Compat.C_Timer.NewTicker` handle identities; a separate test-only callback-counting observer forwards to genuine original `CalculateAndDrawAll`, without changing its source.

## Target behaviours and limits

Exactly **31 proposed assertions per Lua 5.1.5 and Lua 5.4.6** (do **not** credit until exact-head Actions/job logs): baseline source anchors, normal callback count exactly once and reset cleared, incomplete `WasComplete` and missing-source-item call paths from actual `UpdateQuest` canceling reset's parent calculator and retaining its latch, original independent child timer remaining active after parent cancel, original pooled Compat timer owner guard, intentionally failing fake DB coroutine error dropping callback, plus **model-only** A→B→A monotonic epoch distinction. Do not generalize fake game-frame stepping into native 3.3.5a/IP event scheduling. No source patch, real population or acceptance.

## Relation to historical frozen heads

- Original failed #338 exact `1268bc9261723f4fe3bb824ed056d7189294e4b5` was a 32-character pin error *before* Lua.
- Original corrected-but-failed #340 exact `92037fe063f90c7fbd5ec973b29acd1b8dd0e163` was a synthetic child-ticker accounting assertion.
- Corrected independent #341 exact `04c4ffc66af6cd327580b2896fde401dd7398c5c`, 24/24 on each Lua 5.1.5/5.4.6, full original-head 36/36 Actions; **this PR is a separate child** and does not rewrite #341.
- Independent #342 exact `da0b89ab917c11427e4af092b928f13b2afb3ce6`, 27/27 on each Lua 5.1.5/5.4.6, full original-head 36/36 Actions for genuine Compat timer **fragment** and ThreadLib under invented frame host. This integrates previous separate scopes but is still a synthetic test.

Native client event order, original full Compat and whole QuestieQuest, actual cache invalidation/stream leases, SavedVariables/relog, quest IP/eligibility and rollout remain **UNACCEPTED**. Gate08 **MAJOR RED**, 439 RAW not approved, eligible denominator UNKNOWN, pilot 1207–1209 0/3. Any native testing needs separate owner approval, complete addon plus account/character SavedVariables backups and verified rollback first.
