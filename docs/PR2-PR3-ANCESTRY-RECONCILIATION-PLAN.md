# N-Questie — PR #2 / PR #3 Documentation Ancestry Review

**Date:** 14 October 2026  
**Purpose:** Document a pre-existing merge/history problem without modifying original contributor branches.  
**Status:** Read-only investigation and content-only smoke-test reconciliation on testing draft PR #16.

## Verified branch graph

Using the public GitHub compare operation:

- **Older custom quest branch:** [PR #2](https://github.com/CosmicCuddle/N-Questie/pull/2), `feat/n-questie-curated-quest-overlay-2026-10-13`.
- **Offline generator branch:** [PR #3](https://github.com/CosmicCuddle/N-Questie/pull/3), `feat/n-questie-reviewed-json-generator-2026-10-14`.
- Current PR #3 and PR #2 have **diverged** from merge base `8c017f4679725ad69998d2af7b973d15db603bf5`.
- Relative to PR #3, PR #2 has **nine additional commits**; PR #3 has 20 commits that PR #2 does not have. These are documentation-only differences in the compare result.

## Four affected documentation paths

| File | Missing/reconciliation concern |
|---|---|
| `docs/QUEST-2001-SMOKE-TEST.md` | PR #3 said **not in-game tested**, whereas PR #2's later QA evidence confirms the observed quest 2001 available → objectives → complete turn-in → marker removal lifecycle. This is the clearest inaccurate documentation. |
| `docs/PROJECT-HANDOVER.md` | PR #2 has more detailed post-test quest 2001 evidence and earlier QA checkpoints than PR #3's historical ancestry. Newer PR #13/#16 handover sections must be preserved. |
| `docs/DEVELOPMENT-LOG.md` | PR #2 contains separately recorded screenshot observations and maintainer confirmation absent from PR #3's commit history. |
| `docs/ROADMAP.md` | PR #2 has newer checked milestones for actual in-game quest 2001 behaviour, whereas PR #3 still has older unchecked statements in some historical sections. |

**Current action:** In draft PR #16's own `docs/QUEST-2001-SMOKE-TEST.md`, the obsolete `NOT YET RUN` text was replaced with the real, narrowly scoped in-game evidence from PR #2. The limitations remain explicit: actual phased-spawn coordinates, interim kill counters, all character/IP availability and the 28 newly staged existing-quest corrections were not proven by that QA.

This **does not repair Git ancestry**: PR #3 and subsequent branches still don't have those nine PR #2 commits as ancestors.

## Proposed safe eventual reconciliation (requires maintainer approval)

1. Pick a **single coordinated integration/landing branch**, keep all existing PR heads unchanged and preserve the approved merge order. Do not force-push PR #2 or #3 or silently change their PR bases.
2. Merge/cherry-pick the missing PR #2 documentation history into a temporary branch based on the complete current stack. The separate Grok review reported merge conflicts in `DEVELOPMENT-LOG.md`, `PROJECT-HANDOVER.md` and `ROADMAP.md`; manually reconcile these, maintaining the latest handover sections and the specific quest 2001 QA evidence.
3. Ensure `QUEST-2001-SMOKE-TEST.md` retains its proven marker lifecycle and honest unverified limitations rather than reverting to the stale pre-test template.
4. Confirm `git merge-base --is-ancestor <PR2-head-sha> <integration-head>` succeeds, then compare resulting file content and the expected PR diff. Do not call this branch history repaired simply because the docs have been copied.
5. Run inherited CI, M0 (exact 28 correction count, compiled roundtrip and negative fixtures), revision guard and dedicated Lua 5.1 tests on the **actual final integration head**. Run approved backed-up client QA separately.
6. Obtain explicit maintainer approval before merging any PR or publishing stable addon files.

**Nothing in this report merges PR #2/#3, modifies the working game or SavedVariables, publishes private server data, or authorizes a release.**

## Evidence limits

The current GitHub compare lists the four changed document paths and the divergent commit counts. Grok's earlier local merge trial reported actual conflicts in three of those files. Both sources agree on the existence of the document history gap, but **a future conflict resolution must be tested against the actual current PR heads**, which can change.
