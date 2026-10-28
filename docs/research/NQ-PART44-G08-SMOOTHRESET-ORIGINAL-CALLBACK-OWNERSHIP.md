# Part44 Gate08: original SmoothReset callback ownership — synthetic source execution

**28 October 2026 — PUBLIC-SAFE TEST ONLY. No production edits, merge, ZIP, install, release or native client.**

Immutable protected 335 `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, authenticated original source blobs:
- `Modules/Quest/QuestieQuest.lua` `cd4239c5b40c1f5b1ced823dfa12d8a895091719`
- `Modules/Quest/AvailableQuests.lua` `2664f09fdf1f5df4d94581414e9d5ea88e9af4e7`
- `Modules/Libs/ThreadLib.lua` `8f564049ad2a4af49473fac939b7c276c4227dd7`

This test compiles the **exact original unmodified `QuestieQuest:SmoothReset` function fragment** and loads the **whole unmodified original `ThreadLib` module**, with a **fictional** available quest calculator closure, fake frame timers and invented game/DB/world state. Unlike authentic full-AvailableQuests tests #323/#324 it does **not** execute the full original available-quest calculator; it authenticates relevant original `AvailableQuests.CalculateAndDrawAll` source anchors. The constructed timer clock is not WoW's actual `QuestieCompat.C_Timer` or native AnimationGroup system.

Original source: `SmoothReset` sets `_resetNeedsAvailables=true` before registering a callback to clear it (QuestieQuest L335–337). Later step waits for flag false (L357); `_isResetting` clears only at L360. `_resetAgain` cancellation requires `not _resetNeedsAvailables` (L377–381). `ThreadLib.Thread` only calls completion callback after coroutine dead, not on explicit cancellation or error (ThreadLib L39–50). `AvailableQuests.CalculateAndDrawAll` cancels its previous timer (AvailableQuests L44–52).

**22 proposed dual-Lua controls**:
- Real source anchors authenticated and original reset function/ThreadLib executed in a bounded fake host.
- Normal synthetic calculator completion fires callback and original SmoothReset clears `_isResetting`.
- A second synthetic `CalculateAndDrawAll` call cancels the first ticker and loses its callback; original reset remains waiting even after synthetic repeated ticks, and subsequent SmoothReset records `_resetAgain` without progress.
- Synthetic coroutine error also cancels the callback owner without firing original completion callback.
- Separate **fictional model-only** monotonic epoch distinguishes ABORTED from COMPLETED. This is not an implementation or release fix.

**Do not claim success until exact-head GitHub Actions and job logs confirm the Lua 5.1.5 / 5.4.6 result and lack of artifacts.** A failure should be frozen and corrected only in a separate child. CS02's earlier more integrated real Compat+ThreadLib+AvailableQuests research is a peer witness, not itself this CI test.

**Known native unknowns:** whether event ordering can actually supersede SmoothReset in native WoW 3.3.5a; any safe public API callback contract; cleanup of orphaned child tasks, map/tooltip state, independent C_Timer timers, reader leases and pending QuestieComms; persisted SavedVariables relog and Individual Progression. Owner has given no permission for native install, production patch, build, ZIP, merge, tag or release. Gate08 MAJOR RED, protected 335 unchanged. Future native test requires full Questie-335 and account/character SavedVariables backups and rollback.
