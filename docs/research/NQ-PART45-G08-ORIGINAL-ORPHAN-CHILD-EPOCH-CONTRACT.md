# G08 Part45 — original independent child after parent cancellation + counterfactual ownership contract

**PUBLIC-SAFE TEST-ONLY RESEARCH / DRAFT / NO MERGE.** Date: 28 October 2026.

## Exact source scope

Source baseline is historical protected original `335` **`8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`**, prior to the **README-only** owner-approved merge of PR #351 (`26053bd28b0df3a01e5859f779d5f3cb4f57b221`). These four exact blobs have not changed because of that documentation merge:

- `Modules/Quest/QuestieQuest.lua`: `cd4239c5b40c1f5b1ced823dfa12d8a895091719` — **exact authentic SmoothReset and UpdateQuest function bodies only**.
- `Modules/Quest/AvailableQuests.lua`: `2664f09fdf1f5df4d94581414e9d5ea88e9af4e7` — **whole original module**.
- `Modules/Libs/ThreadLib.lua`: `8f564049ad2a4af49473fac939b7c276c4227dd7` — **whole original module**.
- `Compat/Compat.lua`: `b3e273e82cabbd5b7b351ae5aa3d94d4675387be` — **timer fragment only**, not the entire Compat module.

**The test host is invented**: fake AnimationGroup/timer callback loop, fictional quest pointers and DB, game API replacements, no real client or realm. The test reuses previously authenticated #348 source execution and adds a separate scenario using genuine original `_DrawAvailableQuest` → `ThreadLib.ThreadSimple` child code.

## Observable original-source witness (not a native claim)

Source `CalculateAndDrawAll` cancels its one retained outer `timer`. Original `_DrawAvailableQuest` starts independent `NewThread(function() ... end, 0)` children without retaining/ownership-parenting their timer handles. The new scenario executes original child after the original outer callback-owner was superseded by real `UpdateQuest` under the synthetic host. Test-only counters record original `QuestieDB.GetQuestTagInfo` being called, entry to whole original `AvailableQuests.DrawAvailableQuest`, original child cancel after completion, and the original reset-completion callback still absent.

These events are synthetic callback scheduling observations, not established actual in-game map corruption. Our fake `GetNPC` and `GetObject` intentionally resolve to nil, so **no real map frames, NPC/GO DB, inventory or on-screen graphics are exercised**. We do not assert frame rendering effects or native ordering.

## Counterfactual design contract — model only, NOT a production patch

Separate self-contained host-side `newLedger()` models:

1. Globally monotonic serials and typed `PENDING`, `COMPLETED`, `ABORTED`, `ERROR` terminal states, counted exactly once.
2. Completion waits for an actual parent finish **and** all tracked children, never treating an aborted/errored owner as successful.
3. Starting a newer calculation ABORTS a still-pending owner; stale children cannot publish or report completion.
4. Even when a visible label changes A→B→A, serial mismatch rejects the first A's late callback.
5. Current-owner errors invalidate outstanding writes, duplicate terminal events are rejected; no terminal `COMPLETED` on error.

The ledger is **a deliberately invented proposed interface**, not present in `335` or the user-approved codebase. This synthetic model demonstrates desired isolation properties; actual source currently does **not** implement them. It must not be mistaken for a fix, native acceptance, rollout readiness, or new owner authorization.

## Test and governance

**69 assertions proposed per Lua 5.1.5 and Lua 5.4.6; do not mark passed before verifying pinned exact-head Actions/job logs, clean test checkout, and artifact census.** The first 31 are the previously verified #348 combined original-source checks. New assertions 32–39 target orphan-child source execution; new model checks M01–M30 target the hypothetical contract.

Historical test-only #345 / #346 remain original FAILED fixture heads; corrected #348 original head `fdb0507fcec1e4d903c879425c9b35b0ef4ce128` dedicated [run 40759854445](https://github.com/CosmicCuddle/N-Questie/actions/runs/40759854445) independently **31/31 per Lua** and now **37/37 exact-head Actions SUCCESS**. #347 docs **9/9**, #349 docs **8/8** SUCCESS, each unmerged/draft. Original-source blob pins remain immutable.

CS02 [PR #42 coordination checkpoint](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6479424206) independently reports **438/438 synthetic dual-Lua timing/callback checks** with the caveat **native AnimationGroup event ordering is unknown**; about N≥25 versus N≤24 quest-pointer frame scheduling is a source-based hypothesis, not measured live. Consult source-anchored peer comments before any design decision.

**Gate08 MAJOR RED; 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; 439 RAW candidates unapproved; eligible denominator unknown; pilot 1207–1209 0/3.** No production Lua/SQL, native builds/tests, ZIP, SavedVariables, private data, install, merge, release, tags or outside network. Separate owner authorization and complete addon/account+character backups plus verified rollback are required for native work.
