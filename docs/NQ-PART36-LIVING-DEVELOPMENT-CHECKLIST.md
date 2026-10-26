# N-Questie — Part 36 Living Development Checklist

**26 October 2026 — initial LIVE checkpoint.** Read the [complete Part35 → Part36 handover](HANDOVERS/2026-10-26_PART35_TO_PART36.md), [twelve-gate master](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), [compiler blueprint](research/NQ-PART35-GATE08-TRANSACTIONAL-COMPILER-INTEGRATION-BLUEPRINT.md) and [439-record programme](NQ-MISSING-QUEST-COVERAGE-PROGRAMME.md) first. All engineering PRs below remain **DRAFT / NOT APPROVED TO MERGE**.

**Owner:** maintainer; **CS01:** engineering/project/integration lead; **CS02 (Grok):** independent reviewer. Team [coordination PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42). Protected `335`: `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. PUBLIC repository: NEVER copy owner-private SQL, NPC/GO/item/loot/IP source relationships.

## Twelve complete project gates — never only the first three quests

- [x] **01** Inventory research — **439** raw server-only IDs classified (12 candidates + 418 exploratory + 5 excluded + 3 placeholders + 1 already covered).
- [x] **02** Maintainer confirms quests **1207–1209 are offered**; this is not source/IP proof.
- [x] **03** Pinned Questie code/registration/source audit.
- [ ] **04** OPT-A manifest, provenance, loader staging / schema.
- [ ] **05** Runtime effective NPC/GO/item forward-reverse ownership + all writer/exclusion protection. Draft #177 is precompile-only.
- [ ] **06** Completion cache CLEAR vs ADD-ONLY and real-client confirmation; #169 canonical research, #170 comparison-only.
- [ ] **07** Item-start/loader integrated in real 3.3.5a; #168 item-only loader base.
- [ ] **08** Actual compiler transaction across all four kinds, epoch/snapshots, leases, fail-stop and revision correctness. Blueprint is DESIGN.
- [ ] **09** Private source/loot/IP and eligibility verification for individually approved quests.
- [ ] **10** **Entire 439-record missing-quest investigation / eligible implementation PROGRAMME**, owner-authorised development; pilot 1207–1209 **0/3** (not all 439 approved).
- [ ] **11** Actual WoW 3.3.5a and Individual Progression gameplay/GC/rollback QA, approved but technically pending.
- [ ] **12** Final integration/install/package/release approvals, technically pending.

**Status: 3 COMPLETE / 6 UNDERWAY / 3 OWNER-APPROVED TECHNICALLY PENDING.**

## Priority A — full effective-owner draft PR #177 review follow-ups

**Immutable reviewed parent:** [PR #177](https://github.com/CosmicCuddle/N-Questie/pull/177) `00f2b4d1d5814f64a7c2284469358299171d4baa` (child of [#168](https://github.com/CosmicCuddle/N-Questie/pull/168)). At snapshot, **7/7 PR + 5/5 push workflows SUCCESS; 0/12 artifacts**. Grok CS02 [APPROVE-WITH-FOLLOW-UP (DRAFT)](https://github.com/CosmicCuddle/N-Questie/pull/177#issuecomment-6415536358). Open an **isolated child draft** to preserve the reviewed branch.

- [ ] Add invented 22→**25** cases (same-size forward NPC substitution, override-only item foreign owner, faction-effective finisher override).
- [ ] Re-run both Lua versions; ensure new tests kill M5/M6 mutations as independently demonstrated by CS02.
- [ ] Replace `inspectReverse` nil-relation temporary table with direct return; desktop source-based performance/GC check, not in-game proof.
- [ ] Restore `Modules/QuestieInit.lua` **100755** Git file mode (accidentally changed to 100644).
- [ ] Correct six-file PR scope including revision **10→11**, pin updated strict loader SHA1, Stage1-before-Compile guard, and revision guard. **Do not remove guard.**
- [ ] Require previous **101/101 loader** and **12/12 item codec** tests per real Lua5.1 and Lua5.4, plus new 25/25 cases; inspect actual log.
- [ ] Document/test opposite-faction cached login override invariant; later writers still unbounded.
- [ ] Grok independently reviews new child exact head + mutations; no merge even if green (Gate08 source freeze remains missing).

## Part 36 LIVE engineering checkpoint — 26 October 2026

**NEW isolated [DRAFT #178](https://github.com/CosmicCuddle/N-Questie/pull/178)**, child of frozen #177 `00f2b4d1d5814f64a7c2284469358299171d4baa`. The current head at this checkpoint is `bebc6aab20104575220b8515158d3ae38bf18289`. Exactly **six net child paths**: loader nil-relation fast return, three fictional tests (22→25), CI 25-count gate, strict loader SHA1 repin (`20ffe65804c19dd9be25b3378a4b8cda02790158`), unchanged Init source with mode restored to **100755**, and custom data revision **11→12**. First initial #178 head (`bd469f5a`) had dedicated 25-case workflow PASS but **revision guard correctly FAILED** for unchanged revision 11. Revision 12 corrected the strict guard; a later workflow-only commit added **12/12 real pinned item codec checks on BOTH Lua5.1 and Lua5.4**. Exact new head dedicated PR workflow **SUCCESS**, with 25/25 owner probes and 12/12 item codec on both Lua versions, and strict revision guard **SUCCESS 11→12**. Existing loader 101/101 per Lua version and Lua5.1 item codec passed in actual overlay CI. At 12:53 GMT, **8/12 current-head PR+push workflow runs SUCCESS; four broad CI/M2 runs pending, no failed completed runs**. Do not call this full CI closure yet. Actual protected `335` remains `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.

- [x] Three CS02-requested fictional test probes committed on isolated child (#178).
- [x] Nil-relation temporary-allocation removal committed, subject to independent source and desktop GC/perf review.
- [x] File mode 100755 restored without changing `Modules/QuestieInit.lua` bytes.
- [x] Strict loader blob SHA1 repinned and revision **11→12** committed after initial guard refusal.
- [ ] Reverify **current** #178 PR+push workflow conclusions, actual Lua5.1/5.4 **25/25**, inherited **101/101** and **12/12**, exact-head zero artifact endpoints.
- [ ] Independent CS02 new-head M5/M6 mutation and cross-faction cached-login/writer safety review; actual 3.3.5a client not tested.
- [ ] NO merge of #178 or #177: precompile checker still does not freeze writer/epoch across compiler yields; Gate08 remains UNDERWAY.

**CS02 assignment:** [team #42](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6416337798) gives exact #178 review plus independent Gate08 TX01–TX11 / #175 12→14 poison mutant backup, no idle time while review pending.

## Priority B — Gate08 actual compiler source/transaction engineering

[Blueprint TX01–TX18](research/NQ-PART35-GATE08-TRANSACTIONAL-COMPILER-INTEGRATION-BLUEPRINT.md). Pinned `Database/compiler.lua` commits each NPC/GO/quest/item Bin/Ptrs separately; early returns leak streams, error paths publish partial data; Stage1 always advances revision. #167/#174/#175 are **research-only**.

- [ ] CS02 independent blueprint/source critique (give parallel backup Gate05 follow-up).
- [ ] Fresh draft owner-driven **reader and writer lease manager**, only return once when coroutine DEAD; suspend/poison => quarantine/BUSY. No unsafe global QuestieStream interception.
- [ ] Stage all **8** Bin/Ptrs fields locally for all 4 kinds, validate codec bounds and readback before any SavedVariables publish.
- [ ] COMPLETE writer/override/nested relation mutation exclusion or proven immutable snapshot, including **A→B→A** across coroutine yield.
- [ ] Publish with no-yield transaction boundary and explicit `SUCCESS/BUSY/RETRY/ERROR/ABORTED_QUARANTINED`, metadata/custom revision only on SUCCESS.
- [ ] Handle crash/relog SavedVariables recovery separately (cooperative in-memory atomicity ≠ disk atomicity).
- [ ] Source-backed Lua5.1 and Lua5.4 exact-head CI; practical in-game 3.3.5a RAM/GC/frame benchmarks/rollback only after owner-approved backups.
- [ ] Optional separate child #175 (reviewed `9ce74b5a`): CS02 two new poison/cleanup mutant cases 12→**14** on each Lua, without altering frozen #175.

## Priority C — 439-record full-coverage programme

- [ ] Keep 12 first-pass candidate records **UNDECIDED**, 418 exploratory **UNCLASSIFIED**, five owner-exclusions 30000–30004, three placeholders and covered quest 2001.
- [ ] Store private per-quest actual offering/NPC/GO/item/loot/events/scripts/IP/class/faction/phase/provenance **outside the public GitHub repository**. Never infer starter/finisher from server template alone.
- [ ] Pilot **1207, 1208, 1209: 0/3 implemented**, but DO NOT close Gate10 after completing them.
- [ ] Individually approve playable, source-correct and eligible quest batches; do not assume 439 implementation targets.
- [ ] Plan marker/objective/finisher/relog/faction/IP and memory QA once safe integration and private source proof exists.

## PR/CI/review safety

- [ ] Every time: fetch actual protected 335 SHA, current PR heads, CS02 comments and exact-sha CI; no stale approval transfer.
- [ ] [#176](https://github.com/CosmicCuddle/N-Questie/pull/176) `b42ccdbe`: 49/49 each Lua, CS02 approved **test only**; preserve.
- [ ] [#174](https://github.com/CosmicCuddle/N-Questie/pull/174) `fbb2332f`: 9/9 each, CS02 approved-with-follow-up; toy timeout cleanup unsafe.
- [ ] [#175](https://github.com/CosmicCuddle/N-Questie/pull/175) `9ce74b5a`: 12/12 each, CS02 approved-with-follow-up; poison M5/M9 mutants survive.
- [ ] Update authoritative master on docs [PR #96](https://github.com/CosmicCuddle/N-Questie/pull/96) after independently checked evidence, preserving historical entries.
- [ ] CS02 gets **backup tasks** when primary reviews are waiting; respect owner-announced breaks.
- [ ] NO merge, tag, packaging, QA artifact, install, client/server write, protected 335 edit, or public confidential source mapping. Back up client SavedVariables/addon folder before any future authorised install.

**Handover is PUBLIC SAFE. Research CI success is not in-game Questie/IP QA or release approval.**
