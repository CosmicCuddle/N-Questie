# Part45 Gate08 — original reset self-supersession source-execution test

**28 October 2026. Public-safe TEST-ONLY draft. No protected production changes, native test, player data, build, ZIP, install, merge, tag or release.**

## Why this fixture exists

CS02's [coordination checkpoint](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6478068402) identified a potential *internal* lost-callback route beyond an external competing caller. Original `QuestieQuest:SmoothReset` step 8 queues a callback-bearing `AvailableQuests.CalculateAndDrawAll` (QuestieQuest lines 335–337), then step 9 invokes `QuestieQuest:UpdateQuest` for log quests (lines 339–354). Unmodified original `UpdateQuest` lines 611–638 can invoke callback-less `CalculateAndDrawAll()` for an incomplete quest that previously completed, or whose source item is missing. The original AvailableQuests lines 44–52 cancel the existing outer ticker; original ThreadLib lines 39–50 invoke completion only upon normal coroutine death, not cancel/error. The original SmoothReset step 10 remains blocked by `_resetNeedsAvailables` if that callback is lost.

## Immutable source and test scope

- Protected `335` commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` read-only and exact Git blobs verified in CI.
- `Modules/Quest/QuestieQuest.lua` blob `cd4239c5b40c1f5b1ced823dfa12d8a895091719`: exact unchanged original `SmoothReset` and `UpdateQuest` function bodies source-executed, not full QuestieQuest module.
- `Modules/Quest/AvailableQuests.lua` blob `2664f09fdf1f5df4d94581414e9af4e7`: entire unchanged original module executed.
- `Modules/Libs/ThreadLib.lua` blob `8f564049ad2a4af49473fac939b7c276c4227dd7`: entire unchanged original module executed.
- Fictional `C_Timer`, quest pointer table, QuestLogCache, QuestieDB, map, tooltips, source-item lookup, quest object and clock. **The original Compat AnimationGroup `C_Timer` is not executed.** No WoW client or private data.
- Source scenarios: normal incomplete quest control with callback; prior-`WasComplete` and missing-source-item scenarios where *genuine UpdateQuest source* starts a callback-less replacement. Original available-quest child timer ownership is recorded. Separate monotonic A→B→A model proves only model serial mismatch.
- Designed test census: **24 checks each on Lua 5.1.5 and Lua 5.4.6**; CI results PENDING until exact original head logs, jobs, total workflows and artifacts inspected. Do not claim a pass or native regression at creation.

## Interpretation / safety

Even an eventual green test would establish a **constructed source-execution witness** of potential reset latch stranding, **not** actual game-frame interleaving, a source defect accepted for patching, native 3.3.5a compatibility, or production readiness. No callback ownership fix, protected branch change, release or native test is authorised. Investigate real Compat timing and native event-order trigger separately. Negative original-head CI evidence is never rewritten if fixture fails; use new corrective child instead. Gate08 stays **MAJOR RED**; 439 RAW still unapproved; denominator unknown; pilot 1207–1209 remains 0/3.
