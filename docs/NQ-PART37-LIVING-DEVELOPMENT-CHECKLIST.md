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
| Suspended scratch ABA | [#186](https://github.com/CosmicCuddle/N-Questie/pull/186) **`f325a78022e28f1ce48c82885d0b3e3ff129c5e6`** | **63/63** both Lua in [run 40345915903](https://github.com/CosmicCuddle/N-Questie/actions/runs/40345915903); **9/9 own CI SUCCESS including M2 PR run 40345916004; zero artifacts across all 9 endpoints independently rechecked**; CS02 review pending | Per-stage scratch attempt serial fences suspended stale coroutine + scratch token A→B→A |

**#186 CI caveat:** the earlier experimental head `0860dacb41d7a3bdaf5ca3e6adfea30a26ea73f6` **FAILED** the dedicated runner because the fixture accidentally kept an old lease owner for a new recovered attempt; fixture corrected on `f325a780`, then dual-Lua **63/63 PASS**. Do not claim the old commit passed. The corrected head is now confirmed 9/9 CI SUCCESS and 0 artifacts; check only for newer activity or changed head.

## 2A. 27 October 2026 — new CS02 reviews and immediate safety work

**Verified reviews:** [#183](https://github.com/CosmicCuddle/N-Questie/pull/183#issuecomment-6419675853), [#184](https://github.com/CosmicCuddle/N-Questie/pull/184#issuecomment-6419677184), [#185](https://github.com/CosmicCuddle/N-Questie/pull/185#issuecomment-6419635928), [#186](https://github.com/CosmicCuddle/N-Questie/pull/186#issuecomment-6419662316). All **APPROVE-WITH-FOLLOW-UP / DRAFT ONLY**. Historic “review pending” entries above are superseded.

- [x] Review CS02's actual exact-head #183–#186 findings, including non-throwing error, pointer, stream and stage mutants.
- [x] **Draft implementation in #187 (review pending):** isolated child of #186 with private scratch generation and receipts, forged receipt/full public token+serial rollback tests; CS02 mutation review and all CI still required.
- [x] **Draft implementation in #187 (review pending):** post-Finish guard moved **before Bin/Ptrs writes**, tokenless suspended writer and re-entrant Begin probes, plus Q1–Q6-inspired 73/73 dual Lua source-backed checks; exact-head peer review and full CI pending.
- [x] **Partially engineered as draft #189:** scalar u16 wrap, fractional u8, u24/u32/signed bounds fail closed in staged mode with 94/94 dedicated dual-Lua source-backed tests; **still pending**: independent review, entire CI, compound numeric bounds, empty-source semantics and failure-stage invalidation. Original legacy compiler is unchanged.
- [ ] New test-only child reviews of #183 reader lease shape, decoded pointer error phase, handle.stream identity and duplicate stream pool returns; #185 pointer/empty/token-receipt mutants.
- [ ] **Separate Gate08 hard stop:** scratch serial still does NOT protect original Questie source tables A→B→A. E01–E08, stream-pool isolation, atomic publication, relog recovery and real WoW3.3.5a/IP profiling remain pending. No merge or Stage1 integration.

## 2B. 27 October 2026 — isolated private scratch-stage fix #187 (Part37 active)

**DRAFT ENGINEERING, NOT MERGE OR CLIENT ACCEPTANCE.** [PR #187](https://github.com/CosmicCuddle/N-Questie/pull/187) is a fresh isolated child of frozen #186 `f325a78022e28f1ce48c82885d0b3e3ff129c5e6`, exact initial head `768ded74ecdad26a4398caa51bd36a2862cc2b3b`. Protected `335` reverified unchanged at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. Three paths vs #186: real `Database/compiler.lua`, source-backed synthetic test suite and no-upload dual-Lua workflow.

- [x] **Draft code:** weak-keyed module-private per-stage token, monotonic attempt serial and private receipt registry. Visible stage token/serial/receipts are compatibility/diagnostics, not receipt authority. An attacker editing public stage fields cannot create private writer receipts.
- [x] **Draft code:** resume check and post-`Finish` **pre-Bin/pre-Ptrs** check confirm private identity, including a suspended tokenless writer and a `Begin` re-entered from lease `Finish`.
- [x] **Dedicated exact-head [Actions run 40496621925](https://github.com/CosmicCuddle/N-Questie/actions/runs/40496621925) SUCCESS:** source-backed **73/73 Lua 5.1 and 73/73 Lua 5.4** checks (previous 63 retained plus ten new adversarial probes); Lua parse steps passed; its artifact endpoint returned zero artifacts. Other exact-head CI was still running when this note was authored; audit all own PR/push runs separately before marking broad CI green.
- [x] **CS02 independent review assignment** issued in [team PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6440827736) to challenge private registry integrity, full visible ABA, nil serial reset, tokenless/re-entrant stale writes, pool/lease safety and legacy byte identity.
- [ ] Receive exact-head CS02 independent mutations and close all original-branch workflow/artifact endpoints, preserving failed-run truth if any.
- [ ] Independently validate test specificity (including explicit mutant kills). Lua success alone does **not** prove all 73 test assertions reject each independent broken implementation.
- [ ] **Still blocked:** full raw/effective source epoch E01–E08 and source A→B→A, global Questie shared pool poison isolation, real transaction driver and eight-field atomic publication/revision, crash/relog SavedVariables recovery, genuine client 3.3.5a/Individual Progression RAM/frame QA.

**Public safety / whole scope:** no private owner SQL, real NPC/GO/item/loot/IP mappings. No Stage1 integration, merge, install, package, tag or release. Twelve gates remain **3 complete / 6 underway / 3 technically pending**. Gate10 still owns all **439 raw records**, not 439 approved quests; first pilot 1207–1209 **0/3**.

## 2C. 27 October 2026 — staged scalar numeric-range guard #189 (Part37 active)

**Code remains DRAFT / UNMERGED.** [#187](https://github.com/CosmicCuddle/N-Questie/pull/187) is frozen at `768ded74ecdad26a4398caa51bd36a2862cc2b3b`: 9/9 original exact-head PR/push Actions **SUCCESS** and **zero artifacts over all nine endpoints**; actual Lua5.1 + 5.4 **73/73** source-backed tests. Independent CS02 review is still outstanding.

**New isolated [PR #189](https://github.com/CosmicCuddle/N-Questie/pull/189)** is stacked directly on #187 (unchanged parent), current source head `81ca757d8dc4d501af1fd9312a821ac36af82834`. Only `Database/compiler.lua`, `tests/compat/nq_gate08_four_kind_stage_source.lua`, and its no-upload dual-Lua workflow changed. The protected `335` branch is unchanged.

- [x] **Real staged scalar safety:** `s8/u8/s16/u16/s24/u24/u32` require integral values within the exact reversible bounds of their actual public QuestieStream codecs, including historical signed offsets (not assumed two's complement). Lua-version-specific fractional truncation and wrapped values cause `GATE08_STAGE_NUMERIC_RANGE` before a raw encoder write.
- [x] **Strict legacy isolation:** guard is scoped to optional `stage ~= nil`. Legacy no-stage/raw and SoD source are untouched. A source-backed negative-control test confirms legacy `u16` 70000→4464 continues on the unmodified legacy path; not an endorsement of that lossy behaviour.
- [x] **Actual dedicated [Actions 40500843829](https://github.com/CosmicCuddle/N-Questie/actions/runs/40500843829) SUCCESS:** Lua 5.1 and Lua 5.4 each pass **94/94**, retaining 73 and adding 21 authentic public-source writer/reader fixtures. New negatives cover fractional/negative/overflow u8/u16/u24/u32 and offset s16/s24; positive exact readback boundaries, no scratch publish on invalid values, unchanged live binary fields/revision and DEAD-only synthetic lease cleanup. Dedicated run's artifact endpoint returned **0**.
- [ ] **Whole #189 exact-head CI**: only 4/9 original PR/push runs completed SUCCESS at the initial review point; five still processing. All nine artifacts endpoints individually checked, 0 at that checkpoint. Requery before updating success counts.
- [ ] **CS02 mutation challenge:** delete scalar range guard, invert signed offsets, weaken integer test, check u8 fractional on both Lua runtimes, high integer positive boundary, exact legacy no-stage/SoD byte identities, and malformed compound numeric paths. Separate #187 private-stage review still pending.
- [ ] **Separate, NOT covered by #189:** nested numeric table/list bounds, waypoints, spawns and pointer identities; E01–E08 full raw/effective **source** writer epoch and source A→B→A; global stream pool poison isolation; transaction owner, atomic all-eight+metadata publication, SavedVariables crash/relog recovery; native WoW 3.3.5a/IP and memory QA.

**Policy/whole scope:** All code and docs are stacked drafts. No Stage1 installation, merge, package, tag or release. PUBLIC repo contains only invented fixtures, never private SQL or NPC/GO/item/loot/IP source mappings. Twelve gates unchanged: **3 complete / 6 underway / 3 technically pending**. Full Gate10 investigation still **439 raw research records**, 1207–1209 pilot **0/3**.

## 2D. 27 October 2026 — independent CS02 #187 review and TEST-ONLY #191

- [x] **Independent CS02 exact-head review of #187 received:** [comment 6441339456](https://github.com/CosmicCuddle/N-Questie/pull/187#issuecomment-6441339456), confirms 73/73 dual Lua and 9/9 CI/zero artifacts, and identifies surviving fixture mutants **M1** (remove per-resume stale-writer guard: writer may call `Finish` before eventual refusal), **M10** (diagnostic-only receipt tampering), plus intentional begun-stage→tokenless fail-closed policy. #187 remains frozen, DRAFT and unmerged, not merge approval.
- [x] **Source draft #189 full original-head CI closure:** 9/9 completed SUCCESS, including M2 run `40500843802`; all nine individual artifact endpoints rechecked after completion returned 0. Real compiler stage tests **94/94 Lua 5.1 and Lua 5.4**. No peer mutation approval implied.
- [x] **Fresh TEST-ONLY [PR #191](https://github.com/CosmicCuddle/N-Questie/pull/191)** at `d98dedcd876ebd2f844196e3f9b3ca0f439a3807` stacks on immutable #189; **two changed paths only** (source-backed fixture and no-upload workflow; no production compiler implementation changed). Adds independent `writerFinishCount` vs external DEAD cleanup and new assertions for M1 plain reset/full visible ABA, M10 diagnostic-only receipt edit, and begun-stage tokenless downgrade. 94→**98** checks.
- [x] **Dedicated exact-head [Actions 40502134255](https://github.com/CosmicCuddle/N-Questie/actions/runs/40502134255) SUCCESS**, real Lua5.1 and 5.4 **98/98 each** including new #95–98. Full nine-workflow CI still processing at first checkpoint; do not label all green until requery. No release artifacts expected/authorised.
- [ ] **CS02 independently rerun M1 and M10 against #191**, show both mutants KILLED on Lua5.1 and Lua5.4, test unchanged parent production compiler. Task recorded on [team PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6441613965).
- [ ] **Hard stops unchanged:** E01–E08 genuine full source writer epoch and A→B→A, owner/faction visibility through yields, compound numeric fields, actual global stream pool poison isolation, production four-kind transaction/publish/revision, SavedVariables relog/crash recovery, native WoW 3.3.5a/IP and RAM/frame testing.

**Preservation:** all code PRs #187, #189 and #191 are DRAFT/unmerged. Protected 335 untouched. Public fictional fixtures only, no private SQL or real NPC/GO/item/loot/IP mapping. Project status 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING, full 439-record programme still open, initial pilot 1207–1209 0/3. No Stage1 rollout, package, install, tag or release.

## 2E. 27 October 2026 — real source epoch known-gap characterization #192

- [x] **#191 exact-head CI CLOSED:** draft test-only [#191](https://github.com/CosmicCuddle/N-Questie/pull/191) frozen `d98dedcd876ebd2f844196e3f9b3ca0f439a3807`: **9/9 original-branch PR+push workflows SUCCESS**; all **nine** artifact endpoints independently rechecked after M2, each **0 artifacts**. Source-backed **98/98 actual Lua5.1 and Lua5.4**. CS02 independent M1/M10 mutation retest is **still pending**; source branch is not merge-approved.
- [x] **New isolated source-research [DRAFT #192](https://github.com/CosmicCuddle/N-Questie/pull/192):** exact initial `6073c03616f179c13ca0ef07731786737ae27057`, stacked on unchanged #191, two new paths only: `tests/compat/nq_gate08_source_epoch_known_gaps.lua` and strict no-upload `.github/workflows/nquestie-part37-source-epoch-known-gaps.yml`. **No compiler / Stage1 changes.** Fictional source relationships only.
- [x] **Dedicated source-backed [Actions run 40503963215](https://github.com/CosmicCuddle/N-Questie/actions/runs/40503963215) SUCCESS**: **6/6 known unsafe behaviours characterized under actual Lua 5.1 and Lua 5.4**, NOT fixed and NOT E01–E08 pass. Confirms a persistent late NPC source edit stages altered bytes (E01 witness), transient NPC A→B→A with restored final bytes (E02 witness, not a real quest ownership relation), nested NPC `questStarts[1]` edit (E03 witness), unregistered item source write (E07 witness), unresolved unrelated-writer policy (E06 witness), and narrow legacy no-stage equality (E08 fixture only).
- [ ] **#192 full exact-original-branch Actions/artifact audit** and Grok review pending. Requery latest CI; dedicated witness success must never be mislabeled as source-epoch acceptance. Source-writer E01–E08 are **STILL BLOCKED**, particularly real approved quest relation ABA, actual override-only E04, opposite-faction E05, unknown addon writer lock/exclusion and client memory.
- [ ] **Next actual SOURCE engineering:** enumerate every real `_LoadCorrections`, `Initialize`, `MinimalInit/addOverride`, yielding `PreCompile`, loader/QuestieFixes and third-party nested mutation surface, plus the opposite-faction cached-login effective view; then choose fully enforceable writer exclusion/epoch or measured immutable owned inputs. Do not increment one cosmetic counter and publish.
- [ ] **Independent review queue:** [PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6441897361) tasks CS02 with #191 M1/M10 mutant reruns and #192 witness scrutiny; #189 scalar-bound review remains scheduled. Full source epoch, shared-stream pool global poison safety, production transaction/atomic all-eight+revision, disk crash-relog recovery and WoW3.3.5a/IP RAM QA remain hard stops.

**Whole project/safety unchanged:** protected `335` still `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`; all GitHub code/docs drafts UNMERGED. 12 gates **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**; 439 **raw** missing-quest research rows, pilot 1207–1209 0/3. No private SQL, real NPC/GO/item/loot/IP mappings, no Stage1 integration, installation, package, tags or release.

## 2F. 27 October 2026 — source writer override-only / opposite-view witnesses #194

- [x] **Full #192 frozen-head CI closed**: [draft #192](https://github.com/CosmicCuddle/N-Questie/pull/192) `6073c03616f179c13ca0ef07731786737ae27057` has **10/10 original-branch GitHub Actions SUCCESS**, including M2 `40503962663`. Every one of the ten artifact endpoints independently fetched after completion: **0 artifacts each**. Actual Lua5.1 / Lua5.4 source suite remains **6/6 KNOWN GAPS reproduced**, **not E01–E08 acceptance**.
- [x] **New TEST-ONLY [draft #194](https://github.com/CosmicCuddle/N-Questie/pull/194)** stacked directly on frozen #192; exactly two changed paths vs parent: the public-source epoch witness script and its no-upload workflow. No real compiler or Stage1 changes. First source head `0678bd7e05b70f8d7ed353fbb1ec514e9182e637` had a **FAILED dedicated Actions run `40508045901`**: test stub omitted `QuestieWotlkObjectFixes.LoadFactionFixes`, abort after test 7. This was a fixture setup omission, not source-epoch protection. Corrected HEAD `42c4ce89da5b449f08d06a04248c1cbd01f0ab02`; failed head retained in review record.
- [x] **Corrected dedicated [Actions run 40508269607](https://github.com/CosmicCuddle/N-Questie/actions/runs/40508269607) SUCCESS**: **11/11 expected KNOWN UNSAFE cases reproduced on actual Lua 5.1.5 and Lua 5.4.6**. Existing 6 retained, with five additional cases: E04 no base pointer initial condition; E04 real `QuestieCorrections:MinimalInit` inserts a synthetic override-only quest late; E04 real local `addOverride` in-place nested merge; E05 simulated opposite-faction view drift after current-view preflight; E05 simulated opposite-view A→B→A. All exercise actual `GetDBHandle` reader on encoded data.
- [ ] **#194 full original-branch PR+push CI closure, artifacts endpoint audit and CS02 review** needed. Do NOT describe 11/11 witness success as transaction acceptance or source epoch implementation.
- [ ] **E05 interpretation limit:** only the **source correction merge and reader are real**; faction-specific `LoadFactionFixes` records and A/H selector are controlled fictional doubles. Actual WoW 3.3.5a faction detection, approved source ownership, IP overlay precedence, cached login, cross-character effective views, RAM/frame are **NOT TESTED**. Neither E04 nor E05 has a writer-lock or owned immutable generation.
- [ ] **Next engineering decision gate:** enumerate `_LoadCorrections`, yielding `PreCompile`, direct derived `requiredRaces`, `MinimalInit/addOverride`, other base/nested writers and third-party source edits. Select either a proven **complete writer epoch/exclusion** or a RAM-validated immutable source + effective-view generation, then write falsifying E01–E08 *acceptance* tests. Snapshot of only one faction or root-table metatable is insufficient.
- [ ] **Other Gate08 stops:** global `QuestieStream` pool alias after ambiguous `finished()`; real four-kind staged driver/atomic all-eight and metadata/revision publication; SavedVariables crash/relog recovery; native WoW 3.3.5a/IP QA. No Stage1 changes allowed without proofs/reviews.

**Whole project and public-safety unchanged:** protected `335` stays `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`; code/docs drafts unmerged. Twelve gates 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; full Gate10 **439 raw research records**, pilot 1207–1209 **0/3**. Never publish real owner-private SQL, NPC/GO/item/loot/IP mappings, and no install/package/tag/release.

## 3. PRIORITY A — CI closure and CS02 review

- [x] #186 exact `f325a780`: M2 PR run `40345916004` **SUCCESS**, full **9/9** original branch workflows SUCCESS, **0 artifacts** independently rechecked. Recheck only if new commits/workflows appear.
- [x] #185 exact 13/13 successful/zero artifacts rechecked at Part37 handover. Recheck again if PR head changes.
- [x] Exact-head CS02 reviews for #183–#186 received and incorporated in the 27 October addendum; further reviewer follow-ups required.
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

**Opening Part37 truth: 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; #185 13/13 green/0 artifacts; #186 9/9 green/0 artifacts; 63/63 dual Lua source-backed; actual source writer epoch and stream pool isolation remain blocked; 439-row programme, pilot 0/3.**
