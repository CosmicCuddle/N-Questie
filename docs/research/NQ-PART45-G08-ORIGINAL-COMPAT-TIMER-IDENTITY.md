# Part45 — genuine Compat timer identity and ThreadLib callback ownership

**28 October 2026 · PUBLIC-SAFE TEST-ONLY DRAFT · NO PRODUCTION CHANGES OR NATIVE TESTING.**

## Immutable sources and exact execution boundary

- Protected `335` exact `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.
- Genuine `Compat/Compat.lua` blob `b3e273e82cabbd5b7b351ae5aa3d94d4675387be`, specifically the unmodified timer region from `local activeTimers = {}` (line 131) up to the next `local mapIdToUiMapId = {}` (line 192). **Original fragment, not whole Compat.**
- Genuine complete `Modules/Libs/ThreadLib.lua` blob `8f564049ad2a4af49473fac939b7c276c4227dd7`.
- The frame / AnimationGroup / Animation objects, repeated ticks, quest/game host and callback failures are invented. **No actual 3.3.5a event loop**, real frame, quest data, user account, character, SavedVariables or networking.

## The specific source contract

Original Compat `timerCancel` stops the animation, clears the ID and puts it into an inactive pool. Original `timerOnFinished` captures the old ID before callback and checks `if id == self.id then` afterwards (lines 145–158), protecting a new owner if the callback cancels the old handle and immediately reuses the pooled animation. `NewTicker` allocates a new table ID, clamps duration to at least 0.01 and starts the group. Original ThreadLib normal coroutine death calls callback, whereas a coroutine exception or explicit timer Cancel does not call the completion callback. This is separate from the original SmoothReset/UpdateQuest internal-supersession scenario.

## Proposed dual-Lua execution matrix

27 assertions on each Lua 5.1.5 and Lua 5.4.6: authenticate source guards, run normal callback exactly once including extra frame, error callback zero with one recorded error, cancellation callback zero, pooled animation/new handle distinct, same-animation reentrant cancellation of old ID versus new owner, stale old ID cancellation inert, one-shot After and two-iteration expiry. All original timer/ThreadLib functions run in the **synthetic frame host**.

**CI PENDING until exact original-head job logs and artifacts are independently inspected.** No `SmoothReset`, full original `AvailableQuests`, whole `Compat`, source generation swap, original game UI, real network or native IP client executed in this fixture. This must not be interpreted as a production defect/fix or Alpha 0 readiness. Existing #338 and #340 failed test heads remain preserved independently from corrective #341; this draft is based directly on frozen #335 to avoid inheriting their failures.

## Release gates

Gate08 remains **MAJOR RED**. 439 RAW quest candidates unapproved; eligible denominator unknown; pilot quest IDs 1207–1209 still 0/3. No production Lua/SQL edits, merge, package, ZIP, install, tag, release or private data. Any later separately approved native test requires full `Questie-335` and account/character SavedVariables backups, hashes, and verified rollback.