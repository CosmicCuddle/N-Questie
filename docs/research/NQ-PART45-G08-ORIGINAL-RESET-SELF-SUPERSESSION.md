# Part45 Gate08 — original reset self-supersession source-execution test

**28 October 2026. Public-safe TEST-ONLY draft. No protected production changes, native test, player data, build, ZIP, install, merge, tag or release.**

## Why this fixture exists

CS02's [coordination checkpoint](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6478068402) identified a potential *internal* lost-callback route beyond an external competing caller. Original `QuestieQuest:SmoothReset` step 8 queues a callback-bearing `AvailableQuests.CalculateAndDrawAll` (QuestieQuest lines 335–337), then step 9 invokes `QuestieQuest:UpdateQuest` for log quests (lines 339–354). Unmodified original `UpdateQuest` lines 611–638 can invoke callback-less `CalculateAndDrawAll()` for an incomplete quest that previously completed, or whose source item is missing. The original AvailableQuests lines 44–52 cancel the existing outer ticker; original ThreadLib lines 39–50 invoke completion only upon normal coroutine death, not cancel/error. The original SmoothReset step 10 remains blocked by `_resetNeedsAvailables` if that callback is lost.

## Immutable source and test scope

- Protected `335` commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` read-only and exact Git blobs verified in CI.
- `Modules/Quest/QuestieQuest.lua` blob `cd4239c5b40c1f5b1ced823dfa12d8a895091719`: exact unchanged original `SmoothReset` and `UpdateQuest` function bodies source-executed, not full QuestieQuest module.
- `Modules/Quest/AvailableQuests.lua` blob `2664f09fdf1f5df4d94581414e9d5ea88e9af4e7`: entire unchanged original module executed.
- `Modules/Libs/ThreadLib.lua` blob `8f564049ad2a4af49473fac939b7c276c4227dd7`: entire unchanged original module executed.
- Fictional `C_Timer`, quest pointer table, QuestLogCache, QuestieDB, map, tooltips, source-item lookup, quest object and clock. **The original Compat AnimationGroup `C_Timer` is not executed.** No WoW client or private data.
- Source scenarios: normal incomplete quest control with callback; prior-`WasComplete` and missing-source-item scenarios where *genuine UpdateQuest source* starts a callback-less replacement. Original available-quest child timer ownership is recorded. Separate monotonic A→B→A model proves only model serial mismatch.
- Designed test census: **24 checks each on Lua 5.1.5 and Lua 5.4.6**; CI results PENDING until exact original head logs, jobs, total workflows and artifacts inspected. Do not claim a pass or native regression at creation.

## Interpretation / safety

Even an eventual green test would establish a **constructed source-execution witness** of potential reset latch stranding, **not** actual game-frame interleaving, a source defect accepted for patching, native 3.3.5a compatibility, or production readiness. No callback ownership fix, protected branch change, release or native test is authorised. Investigate real Compat timing and native event-order trigger separately. Negative original-head CI evidence is never rewritten if fixture fails; use new corrective child instead. Gate08 stays **MAJOR RED**; 439 RAW still unapproved; denominator unknown; pilot 1207–1209 remains 0/3.

## Original failed-head preservation (append-only correction record)

Original draft [#338](https://github.com/CosmicCuddle/N-Questie/pull/338) frozen head `1268bc9261723f4fe3bb824ed056d7189294e4b5`, dedicated [run 40752710384](https://github.com/CosmicCuddle/N-Questie/actions/runs/40752710384), job `123043353661`, failed **before Lua installation or execution** in the immutable source authentication step because the authored AvailableQuests blob was truncated to 32 hex characters. This is a **fixture provenance typo only**, not a reproduced production/client failure. Correct known original protected source Git blob is `2664f09fdf1f5df4d94581414e9d5ea88e9af4e7`. This separately corrected child preserves the failed #338 head unmodified. Any corrected Lua outcome still awaits exact-head CI; no native/client evidence or gameplay authorisation is implied.


## Second original-head correction, isolated child (28 October 2026)

Corrected pin draft [#340](https://github.com/CosmicCuddle/N-Questie/pull/340) exact original `92037fe063f90c7fbd5ec973b29acd1b8dd0e163`, dedicated [run 40753123706](https://github.com/CosmicCuddle/N-Questie/actions/runs/40753123706), job `123044810530`, verified source pins and Lua 5.1/5.4 interpreter install, **then failed** the synthetic `S06_NORMAL_NO_SUPERSESSION` assertion on Lua5.1. Lua5.4 did not run. The fixture incorrectly assumed `timers[#timers]` was the outer calculation; complete original AvailableQuests legitimately creates independent child `ThreadSimple` tickers before the UpdateQuest step, so the last timer may be an old child. This is a **test-fixture timer-classification mistake**, not production evidence. This new distinct child identifies replacement outer timer by comparing ticker counts immediately before/after original UpdateQuest source execution. Preserve the exact #340 failed head and job log; test acceptance waits for new exact-head dual-Lua CI.
