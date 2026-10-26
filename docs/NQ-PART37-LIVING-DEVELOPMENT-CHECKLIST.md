# N-Questie — Part 37 Living Development Checklist

**26 October 2026 · OPENING CHECKPOINT · PUBLIC-SAFE · All source and documentation PRs are DRAFT / DO NOT MERGE**

**Read first:** [Complete Part36 → Part37 Handover](HANDOVERS/2026-10-26_PART36_TO_PART37.md), [twelve-gate authoritative master](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), [Gate08 TX01–TX18 integration blueprint](research/NQ-PART35-GATE08-TRANSACTIONAL-COMPILER-INTEGRATION-BLUEPRINT.md), [source writer audit](research/NQ-PART36-GATE08-SOURCE-WRITER-COVERAGE-AUDIT.md), [full 439-record programme](NQ-MISSING-QUEST-COVERAGE-PROGRAMME.md), [CS02 team PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42).

**Protected `335` exact SHA:** `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. **PUBLIC repo**. CosmicScript01: project/integration/engineering lead. CosmicScript02 (Grok): independent reviewer. Keep all changes in new isolated DRAFT branches. **No private SQL, NPC, GO, item, loot or IP mappings. No merge, client installation, ZIP, artifact upload, tag or release.**

## 1. All twelve gates and the complete programme

- [x] **G01 — Raw inventory research.** **439** records reconciled (12 review candidates + 418 exploratory + 5 explicitly excluded + 3 placeholders + 1 already present).
- [x] **G02 — Maintainer offer confirmation.** Pilot quests **1207–1209 offered**, but source/IP evidence is **not** proven.
- [x] **G03 — Pinned client/source/registration audit.**
- [ ] **G04 — OPT-A manifest/provenance/schema and safe loader.** Underway.
- [ ] **G05 — All effective forward/reverse NPC/GO/item ownership, faction and writer/exclusion proof.** Underway; #178 is precompile-only.
- [ ] **G06 — Completion-cache CLEAR/ADD-ONLY.** Underway; #169 canonical research, #170 comparison-only.
- [ ] **G07 — Item-starter/loader integrated with genuine 3.3.5a.** Underway; #168 item-only draft.
- [ ] **G08 — Actual four-kind compiler transaction: source freeze, stream leases, status, atomic in-memory publish, disk recovery.** Underway; #180–#186 only optional non-production seams.
- [ ] **G09 — Private per-quest eligibility/source/loot/phase/IP verification.** Underway; do not leak evidence.
- [ ] **G10 — Full 439-record investigation and individually approved eligible implementations.** Broad development owner-approved, technically pending. Pilot **0/3 implemented**. Not 439 approved additions.
- [ ] **G11 — Real client, server/IP gameplay, memory/GC/frame, rollback/relog QA.** Broad development owner-approved, technically pending.
- [ ] **G12 — Final installation, packaging, integration and release.** Broad development owner-approved, technically pending; separate actual approval required.

**Total: 3 COMPLETE / 6 UNDERWAY / 3 OWNER-APPROVED TECHNICALLY PENDING.** The actual eligible quest denominator is **UNKNOWN**.

## 2. Opening exact-head engineering ledger

All these are draft/unmerged and **not based on `335` for merging**. Freshly verify SHAs/CI/reviews before any change.

| Area | PR / exact SHA | Source-backed test evidence and review | Work |
|---|---|---|---|
| Loader item starter | [#168](https://github.com/CosmicCuddle/N-Questie/pull/168) `17a44252` | 101/101 loader + 12/12 codec each Lua | Base draft; client integration blocked |
| Effective sources | [#177](https://github.com/CosmicCuddle/N-Questie/pull/177) `00f2b4d1` → [#178](https://github.com/CosmicCuddle/N-Questie/pull/178) `bebc6aab` | #178 **25/25**, 101/101, 12/12 both Lua; **12/12 own CI, 0 artifacts**; CS02 APPROVE-WITH-FOLLOW-UP DRAFT | Current faction preflight only, revision 11→12; no cross-yield/source or opposite-faction proof |
| CS02 poison toy driver | [#179](https://github.com/CosmicCuddle/N-Questie/pull/179) `dcb368a8` | **14/14** both Lua, 9/9 CI, 0 artifacts; CS01 reviewed TEST ONLY | Not production pool isolation |
| Four-kind stage | [#180](https://github.com/CosmicCuddle/N-Questie/pull/180) `87c88b98` | **18/18** both Lua, 13/13 CI | Scratch-only 8 fields |
| Writer finish ordering | [#181](https://github.com/CosmicCuddle/N-Questie/pull/181) `72d4b650` | **21/21** both Lua, 13/13 CI; CS02 APPROVE-WITH-FOLLOW-UP | Finish-before-expose, stage only |
| Explicit writer owner | [#182](https://github.com/CosmicCuddle/N-Questie/pull/182) `3450e50a` | **31/31** both Lua, 13/13 CI; CS02 APPROVE-WITH-FOLLOW-UP | No pool-global intercept, but poison pool remains unsafe |
| Explicit pre-handle reader owner | [#183](https://github.com/CosmicCuddle/N-Questie/pull/183) `22686e48` | **41/41** both Lua, 13/13 CI; CS02 review pending | Optional sixth reader lease argument |
| Nonthrowing error fix | [#184](https://github.com/CosmicCuddle/N-Questie/pull/184) `b47135da` | **45/45** both Lua, 9/9 CI and 0 artifacts; CS02 review pending | Actual `Questie:Error` only prints; staged invalid type now explicitly fails |
| Current generation receipt | [#185](https://github.com/CosmicCuddle/N-Questie/pull/185) **`610e490e8625276f4f86e69af056ab8ccd5a621a`** | **58/58** both Lua; **13/13 own CI SUCCESS, 0 artifacts**, fully rechecked at handover; CS02 review pending | New scratch generation, current per-kind receipt, reject eight stale values |
| Suspended scratch ABA | [#186](https://github.com/CosmicCuddle/N-Questie/pull/186) **`f325a78022e28f1ce48c82885d0b3e3ff129c5e6`** | **63/63** both Lua in [run 40345915903](https://github.com/CosmicCuddle/N-Questie/actions/runs/40345915903); **8/9 own CI SUCCESS, only M2 PR run 40345916004 pending, 0/9 artifacts at handover**; CS02 review pending | Per-stage scratch attempt serial fences suspended stale coroutine + scratch token A→B→A |

**#186 CI caveat:** the earlier experimental head `0860dacb41d7a3bdaf5ca3e6adfea30a26ea73f6` **FAILED** the dedicated runner because the fixture accidentally kept an old lease owner for a new recovered attempt; fixture corrected on `f325a780`, then dual-Lua **63/63 PASS**. Do not claim the old commit passed. Check M2 completion and final nine artifact endpoints anew.

## 3. PRIORITY A — CI closure and CS02 review

- [ ] Check #186 **M2 pull-request run `40345916004`** on exact `f325a780`: green **9/9** only if that run succeeds. Recheck artifacts for all nine original branch runs.
- [x] #185 exact 13/13 successful/zero artifacts rechecked at Part37 handover. Recheck again if PR head changes.
- [ ] Read new CS02 comments in [#42](https://github.com/CosmicCuddle/N-Questie/pull/42) and PRs #183–#186; obtain **independent exact-head reviews**, not inherited approvals.
- [ ] Request typed mutation challenge of #185 missing/forged/stale receipts, #186 suspended writer and scratch A→B→A, #184 nonthrowing error, #183 pointer errors before handle.
- [ ] Keep **all prior peer-approved heads immutable**. Changes must stack on fresh isolated drafts; no merge.
- [ ] Verify `335` remains at `8b23c6e2...` and check exact-head Actions/artifact endpoints before closing a checkpoint.

## 4. PRIORITY B — Complete source epoch proof (Gate05/Gate08 BLOCKED)

- [ ] Read [source writer audit](research/NQ-PART36-GATE08-SOURCE-WRITER-COVERAGE-AUDIT.md) in full.
- [ ] Build E01–E08 source-backed fictional tests in new test-only draft: permanent late NPC edit, source relation **A→B→A**, nested array edit, override-only source, opposite-faction view, unrelated writer rule, third-party unknown writer failure, legacy no-stage compatibility.
- [ ] Enumerate **all** source-writing functions, including `_LoadCorrections`, `MinimalInit/addOverride`, direct `requiredRaces`, yielding `PreCompile`, raw and effective override tables, and late third-party writes.
- [ ] Decide from verified evidence whether **fully guarded monotonic writer epoch** is possible, or whether a genuinely owned **immutable input generation** can fit 3.3.5a RAM/GC budgets.
- [ ] Do not use #186 scratch serial as proof of SOURCE A→B→A: it protects only reused stage scratch.
- [ ] Treat any uninstrumented writer as Gate08 blocker. Do not switch Stage1 to optional staging yet.

## 5. PRIORITY C — Real compiler transaction, pool and persistence

- [ ] Design and source-test driver-owned writer+reader leases, with DEAD/SUSPENDED distinction and no Lua5.1 pcall-across-yield.
- [ ] Solve **global QuestieStream pool** alias/poison after `finished()` mutates pool and throws; toy-driver local BUSY is insufficient to prevent unrelated consumers from re-leasing.
- [ ] Add all-four-kind current generation encoding and **readback** of every Bin/Ptrs pair, ownership verification, bounds checks and validated status contract `SUCCESS/BUSY/RETRY/ERROR/ABORTED_QUARANTINED`.
- [ ] Plan no-yield in-memory publication of eight fields plus compiled version/lang/count/custom revision **only on SUCCESS**; test abort leaves all old fields/revision intact.
- [ ] Separately design **SavedVariables disk/relog/crash-generation recovery**; cooperative Lua no-yield publication does NOT make disk writes atomic.
- [ ] Pass complete blueprint **TX01–TX18**, including real client 3.3.5a RAM/GC/frame/IP and crash/relog tests **before** calling Gate08 complete.
- [ ] Test genuine SoD/no-stage legacy path and retained Git file mode/revision/hash guards; no claimed compatibility based only on fictional fixtures.

## 6. PRIORITY D — Other review and whole quest programme

- [ ] Gate05 #178: test-only mutants for GO second finisher group and nil/falsy relation, review opposite-faction cached login safety; no new public real source relationship.
- [ ] Gate08 #181: test-only double-finish and legacy SoD mutants (21→23 proposed), detached from frozen reviewed head.
- [ ] Gate08 #182: test-only owner validation/returned-lease registration and finite suspended coroutine survivors; preserve full original writer tests.
- [ ] Gate06 #169 remains canonical completion cache research; #170 comparison only; no dual merge.
- [ ] Gate09 private per-quest historical gameplay, server SQL/loot/IP eligibility proofs must remain **outside public GitHub**.
- [ ] Gate10 **all 439 raw records**, individually classify 12 candidates and 418 exploratory records; preserve five owner exclusions, three placeholders and one already-covered quest. Do not imply all 439 eligible.
- [ ] Pilot **1207, 1208, 1209: 0/3 implemented**, pending private proof and Gate05/08; do not make pilot the only work or require new broad approval.
- [ ] Gate11–12: no client installation/package/release until explicitly approved; take real addon folder and `SavedVariables` backups at future authorised test boundary.

## 7. Part 37 working rules

**Do real, reviewable development** (one safe source-backed slice per fresh branch), independently verify changed source and exact CI, keep Grok busy with substantive review/no-idle backup, and update this checklist plus the authoritative master without erasing dated Part36 history. Statuses cannot advance on CI alone; independent code review, real client QA, source completeness, crash recovery and specific owner gates matter.

**Public confidentiality:** no real AzerothCore database SQL, private workbook or NPC/GO/item/loot/phase/IP mapping, ever. Only invented fixture data. **Never merge into `335`, publish ZIP, alter releases, tag, install or claim a production-ready transaction during this handover.**

**Opening Part37 truth: 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; #185 13/13 green/0 artifacts; #186 8/9 green with M2 pending/0 artifacts at check; 63/63 dual Lua source-backed; actual source writer epoch and stream pool isolation remain blocked; 439-row programme, pilot 0/3.**
