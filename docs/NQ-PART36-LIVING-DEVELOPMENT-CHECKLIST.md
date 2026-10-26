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

## Part36 Gate08 — current-attempt receipts and suspended scratch ABA (26 October 2026)

**Immutable parent:** [draft #184](https://github.com/CosmicCuddle/N-Questie/pull/184) `b47135da0b1b84e2bd411786e84ee1b932581dd8`, **9/9 original-head CI SUCCESS and 0 artifacts**, dual-Lua **45/45**. No merge/installation/tag/release.

**NEW [draft #185](https://github.com/CosmicCuddle/N-Questie/pull/185)**, exact original `610e490e8625276f4f86e69af056ab8ccd5a621a` (child of #184): optional compiler-owned `BeginNQStagedGeneration(stage)` fresh token clears all eight `npc/obj/quest/item Bin/Ptrs`; `VerifyNQStagedGeneration(stage,token)` refuses missing/stale/tampered eight fields and receipts. Existing four writers stamp per-kind Bin/Ptrs **after writer finish**. Real source-backed test **45→58** invented cases; dedicated [run 40345016005](https://github.com/CosmicCuddle/N-Questie/actions/runs/40345016005) **SUCCESS 58/58 under both actual Lua5.1 and Lua5.4**. **Exact-head CI now CLOSED: all 13/13 PR+push workflows SUCCESS, all thirteen artifact endpoints independently rechecked and ZERO artifacts.** Independent CS02 review remains required; no Gate08 acceptance. Not an atomic eight-field publish, not source freeze.

**NEW [draft #186](https://github.com/CosmicCuddle/N-Questie/pull/186)**, child of frozen #185. Scratched staged-generation replay issue: a writer suspended during `coroutine.yield` could resume after the same stage is reinitialized, and mistakenly stamp its old bytes with the *new* token. Optional staged writer now captures scratch token + monotonic attempt serial at entry, checks both after yield and before stamping; Begin increments serial. Five added fictional source-backed checks **58→63** exercise suspended actual writer, DEAD-only lease cleanup, token A→B→A while serial advances and successful new attempt. **The initial #186 head `0860dacb` correctly FAILED its dedicated job after tests #59–61 because the test accidentally reused the old transaction's lease owner in a new attempt**; test harness corrected on subsequent head `f325a78022e28f1ce48c82885d0b3e3ff129c5e6`, whose dedicated GitHub Actions run 40345915903 is now **SUCCESS: 63/63 under both Lua5.1 and Lua5.4** at exact head. Broader own-branch CI was 7/9 green with two jobs pending at last check; final artifacts and CS02 independent review are still required. This serial only guards reuse of the **scratch staging destination**, *not* source NPC/GO/item/quest A→B→A.

**Gate08 remains BLOCKED:** no production transaction owner/Stage1 integration, full source-writer epoch or immutable source snapshot, global pool poison isolation, eight-field+revision atomic publication, relog/SavedVariables recovery, real 3.3.5a/IP memory/frame QA. [Source writer coverage audit](research/NQ-PART36-GATE08-SOURCE-WRITER-COVERAGE-AUDIT.md) identifies actual `_LoadCorrections`, nested corrections, faction overrides and yielding `PreCompile`; unknown third-party writes prevent a complete epoch claim. CS02 independent new-head review required.

Protected `335` remains `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. Twelve gates **3 COMPLETE / 6 UNDERWAY / 3 technically pending**. Entire **439-record** Gate10 investigation remains in scope; 1207–1209 pilot **0/3**. Never publish confidential NPC/GO/item/loot/IP/SQL source relationships, and do not merge/install/package/tag/release.

## Part36 Gate08 checkpoint — strict staged datatype refusal and writer coverage (26 October 2026)

**PR #183 closed CI:** [draft #183](https://github.com/CosmicCuddle/N-Questie/pull/183) at `22686e486d15f7f3350f5e3fe7d55fc677a34f81` finished **13/13** original-branch GitHub Actions SUCCESS; real source-backed Lua5.1/5.4 **41/41**, previous regressions passed. Independent exact-head CS02 review remains separately required. No merge.

**NEW [draft #184](https://github.com/CosmicCuddle/N-Questie/pull/184)** stacked on frozen #183, initial head `b47135da0b1b84e2bd411786e84ee1b932581dd8`. CS02 found that real `Questie:Error` merely reports, so unsupported game-object data previously could leave no staged `objBin/objPtrs` yet let a toy driver report SUCCESS. The optional `CompileTableCoroutine(...,stage)` path now explicitly raises `GATE08_STAGE_INVALID_DATATYPE` after reporting; `stage=nil` legacy behavior and normal startup are unchanged. Added **four** actual-source fictional checks with print-only `Questie:Error`: refusal, old stage/live/revision preservation, DEAD-owner lease cleanup and repaired-input retry. Dedicated [run 40341502842](https://github.com/CosmicCuddle/N-Questie/actions/runs/40341502842) **SUCCESS: 45/45 Lua5.1 and 45/45 Lua5.4**. **Exact-head CI CLOSED:** All **9/9** original-head PR+push workflows completed SUCCESS; all **nine** artifact endpoints independently checked, **0 artifacts**. Dedicated 45/45 passed per actual Lua5.1 and Lua5.4. Independently verified `Questie.lua:115–117` that `Questie:Error` calls `Questie:Print` and does **not** throw. **CS02 new-head review still outstanding; not an integration or Gate08 approval.**

**Gate08 epoch hard stop:** Source-backed [Part36 writer-coverage audit](research/NQ-PART36-GATE08-SOURCE-WRITER-COVERAGE-AUDIT.md) documents actual correction, faction override and nested writer sites including `_LoadCorrections`, `MinimalInit/addOverride`, `Initialize` direct quest field writes and yielding `PreCompile`, plus external/unknown mutations. A root metatable or single covered writer epoch is **insufficient**: old values could be changed A→B→A during yields. New E01–E08 monotonic-epoch/snapshot probes are **planned, not implemented**. No complete writer coverage or immutable snapshot currently exists, so no Stage1 transaction switch.

**Remaining hard stops:** an after-pool-return stream failure can be re-leased by unrelated Questie consumers despite toy-driver BUSY; no production driver or isolated global pool, no complete current-generation eight-field+metadata commit, no Lua5.1 abort/recovery or crash/relog SavedVariables proof, no native client memory/frame/IP QA. All milestones remain **3 COMPLETE / 6 UNDERWAY / 3 technically pending**. Entire **439-record Gate10 investigation** remains in scope (not automatic inclusion); pilot 1207–1209 **0/3**. Protected `335` remains `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. Public repository must not contain owner-private SQL/NPC/GO/item/loot/IP relationships. All drafts unmerged, uninstalled, unreleased.

## Part 36 live Gate08 writer+reader lease engineering — 26 October 2026

**Frozen Gate08 writer parent:** [DRAFT #182](https://github.com/CosmicCuddle/N-Questie/pull/182) source head `3450e50a7e9d553fb6087aaa073c1c19b113519f`. Filtered the actual run list to its **own head branch** (exclude extra push runs created later when opening a child): **13/13 PR+push CI SUCCESS**, **zero artifacts across those 13 endpoints**, real Lua5.1+5.4 **31/31** source-backed tests. Exact head and reviewed ancestors preserved; no merge.

**NEW [DRAFT #183](https://github.com/CosmicCuddle/N-Questie/pull/183)**, child of #182, initial head `22686e486d15f7f3350f5e3fe7d55fc677a34f81`. Three changed paths. Real `Database/compiler.lua:GetDBHandle(data,pointers,skipMap,keyToRootIndex,overrides,readerLeaseOwner)` adds an **optional explicit reader stream lease** acquired **before its first yield/pointer decode**; existing 5-argument callers are unmodified and do not use the owner. Returned handle carries `readerLease`; no global `GetStream` monkeypatch. The prior 31 real source-backed writer and staging checks are retained, with **10 new reader cases**, giving **41/41 PASS per actual Lua5.1 and Lua5.4** in dedicated [run 40338094131](https://github.com/CosmicCuddle/N-Questie/actions/runs/40338094131), job `121624975997`. Cases include pre-handle corrupt pointer DEAD cleanup, post-handle error, pre-acquire zero lease, failure before/after pool return quarantined without double finish, suspended reader (no return) and invalid owner contract. **Full current-head CI/zero-artifact final audit and independent CS02 review remain PENDING.**

**Unresolved production hard stops:** test driver only; no Stage1 connection, real globally isolated stream pool quarantine, production transaction owner or reader/writer all-stage scheduling. A source A→B→A race cannot be prevented by the present precompile-only owner checker. All-eight-field publish+custom revision, crash/relog SavedVariables recovery, WoW3.3.5a/Individual Progression client tests and memory/frame profiling remain unimplemented. An ambiguous `finished()` that mutates the shared stream pool then throws can still affect unrelated Questie consumers; toy BUSY is NOT pool isolation. No merge, packages, installation or release. Protected `335` remains `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.

**Project milestones remain 3 COMPLETE / 6 UNDERWAY / 3 OWNER-APPROVED TECHNICALLY PENDING.** Entire **439 raw records** still require eligibility investigation (not 439 automatically approved additions); initial 1207–1209 pilot **0/3**. Never put owner-private SQL, NPC/GO/item/loot/IP mappings on the PUBLIC repository.

## Part 36 continued — Gate08 explicit writer lease seam (26 October 2026)

**Previous draft [#181](https://github.com/CosmicCuddle/N-Questie/pull/181)** is fixed at `72d4b65039aa0b73e4dd00171318e586eee08e16`, now **13/13 exact-head PR/push workflows SUCCESS**, with **0 artifacts independently checked across all thirteen**. The original optional stage requires `finished()` before exposing staged fields, and actual source-backed **21/21 on both Lua5.1/5.4**. Neither Stage1 nor legacy Compile() switches to staging; #181 stays draft and peer-review pending.

**NEW isolated [DRAFT #182](https://github.com/CosmicCuddle/N-Questie/pull/182)**, child of immutable #181, exact initial HEAD `3450e50a7e9d553fb6087aaa073c1c19b113519f`. Three child paths: actual `Database/compiler.lua` accepts an *optional caller-owned explicit writer lease* in the staged path only (`stage._nqWriterLeaseOwner:Acquire(QuestieStream, mode)`, `:Finish(lease)`); no global interception or Stage1/legacy compiler change. Fictional source-backed regression cases advance **21→31**, exercising all four kinds, exactly-once successful finish, terminated-writer cleanup, acquisition error, pool return throwing before/after pool mutation, BUSY quarantine, suspended writer and invalid owner contract. Dedicated [Actions run 40336738800](https://github.com/CosmicCuddle/N-Questie/actions/runs/40336738800), job `121620225281` **SUCCESS**, observed **31/31 on real Lua 5.1 AND real Lua 5.4**. At the latest exact-head audit **11 of 13 PR/push workflows SUCCESS, only the two M2 PR/push runs still in progress; all thirteen artifact endpoints queried 0 so far**. Full CI closure still pending. Must recheck full CI and final artifacts after completion. Independent CS02 exact-head review is pending. This is **a staging interface and synthetic owner proof**, not a production transaction driver; quarantine in test driver cannot shield Questie's global pool after an ambiguous partial return. Reader leases, complete source writer epoch/exclusion across yields, all-eight in-memory publication+revision, disk/relog recovery and client profiling are **NOT IMPLEMENTED**.

**CS02 backup queue:** independent source review of #181/#182, adversarial real stream partial-finish and no-GetStream-interception mutations, plus TX01–TX18 source writer/reader and scheduler design. Optional additional PR #178 P4/P6 synthetic mutant killers (25→27) on a separate child; never rewrite frozen reviewed ancestor. Protected `335` `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` unchanged. All twelve gates stay **3 COMPLETE / 6 UNDERWAY / 3 technically pending**. Gate10 means the whole **439-record investigation**, not only initial 1207–1209 pilot (0/3). Public GitHub must never contain private SQL, NPC/GO/item/loot/IP associations. No merge, packaging, installation, tag or release.

## Part 36 continued — Gate05/Gate08 review and staged-writer failure safety (26 October 2026)

**Exact immutable ancestors:** protected `335` `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`; reviewed #178 `bebc6aab20104575220b8515158d3ae38bf18289`; compiler-stage #180 `87c88b9837f2649b57e52fdf530bb3d1ea585b0a`. No merges or client/server writes.

**Gate05 #178:** CS02 [independent APPROVE-WITH-FOLLOW-UP](https://github.com/CosmicCuddle/N-Questie/pull/178#issuecomment-6416752692) at immutable head. 25/25 owner cases, 101/101 loader, 12/12 pinned codec on BOTH real Lua5.1/5.4, 12/12 branch workflows successful/0 artifacts. Mutants M5/M6 now killed; two additional minor test-survivors remain (GO finisher ends[2] omission; false-vs-nil relation), with reviewer P6/P4 proposal. The opposite-faction cached-login source invariant remains *ungated* and real 3.3.5a memory/frame/IP tests not run. Desktop public DB measurement only: around 26ms/3.7KiB transient garbage in Lua5.1 with nil-return; not a client proof.

**Gate08 #179 (CS02):** [draft PR #179](https://github.com/CosmicCuddle/N-Questie/pull/179) `dcb368a814b5bb186bad59ea094749febfc47ddf`, test-only isolated child of frozen #175. Two poison/cleanup regressions extend 12→14 on Lua5.1+5.4 and kill the two prior M5/M9 survivors. All 9 exact-head workflows SUCCESS, all nine artifact endpoints zero. CS01 [independent APPROVE-WITH-FOLLOW-UP (TEST ONLY)](https://github.com/CosmicCuddle/N-Questie/pull/179#issuecomment-6417239817). Simulated finish failure occurs before pool mutation: real after-pool-mutation poison, suspended coroutine restoration, driver-owned reader/writer lifecycle **remain unproven**.

**Gate08 #180:** real source [draft PR #180](https://github.com/CosmicCuddle/N-Questie/pull/180), staged local NPC/obj/quest/item Bin/Ptrs seam (eight scratch fields) via optional `stage` parameter. Original 13 PR+push Actions completed SUCCESS, all artifact endpoints zero and dedicated actual Lua5.1/5.4 source-backed **18/18**. **NOT** a four-kind transaction: Stage1/normal Compile still legacy; no source freeze, stream lease guarantee, no-yield full commit or disk recovery.

**Gate08 NEW #181:** [draft PR #181](https://github.com/CosmicCuddle/N-Questie/pull/181) initial head `72d4b65039aa0b73e4dd00171318e586eee08e16`, isolated child of frozen #180. Optional stage branch now requires `stream:finished()` to return **before exposing the scratch Bin/Ptrs pair**, preserving previous scratch values on a synthetic finish failure; no-stage legacy path unmodified. Dedicated exact-head [run 40331576828](https://github.com/CosmicCuddle/N-Questie/actions/runs/40331576828) completed SUCCESS, source-backed **21/21** checks under real Lua5.1 AND Lua5.4, including three failure-injection assertions. **Broader exact-head CI at follow-up: 11/13 PR+push workflows SUCCESS, both M2 workflows still in progress, no completed failures; all thirteen current-head artifact endpoints returned zero at last inspection.** Full CI closure and CS02 exact-#181 independent review remain pending. This intentionally does NOT recover a poisoned stream; without future ownership/quarantine fail-stop, staged path remains unsuitable for normal Stage1 integration.

**CS02 coordination:** [#42 assignment](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6417306099): peer source review #180/#181, TX01–TX18 driver/lease/ABA critique, optional separate owner mutation P4/P6. No idle waiting for feedback.

**Twelve gates unchanged: 3 COMPLETE / 6 UNDERWAY / 3 OWNER-APPROVED TECHNICALLY PENDING.** Gate10 scope = whole **439-record research inventory** with individually approved eligible future implementation only. Pilot 1207–1209 **0/3**. No confidential NPC/GO/item/loot/IP source mappings in public GitHub; no merge, client install, package, release, protected 335 alteration or final Gate12 approval.

## Part 36 continuation — new Gate08 production-source staging seam (26 October 2026)

**Gate05 #178 CI CLOSEOUT.** Frozen head `bebc6aab20104575220b8515158d3ae38bf18289` has **7/7 PR + 5/5 push workflows SUCCESS**, **0 artifacts across all twelve exact-head endpoints** independently checked, 25/25 effective-source cases each real Lua5.1/5.4, 101/101 inherited loader cases each, 12/12 real pinned item codec each, strict revision bump 11→12. **CS02 independent new-head M5/M6 mutation/faction and desktop performance review is still outstanding**. Older pending-CI notes are superseded, not erased; no merge or actual client/IP approval.

**Gate08 new [DRAFT PR #180](https://github.com/CosmicCuddle/N-Questie/pull/180)** stacked on frozen #178. New `Database/compiler.lua` optional `stage` table on the actual NPC/GO/quest/item coroutine writer methods, outputs eight `Bin/Ptrs` fields to caller-owned scratch instead of direct live SavedVariables; no-stage original path is unchanged. Adds a fictional 18-check **actual codec/source readback** Lua5.1/5.4 test and PR-only no-artifact workflow. The first head `9d0bd101` **FAILED in the workflow's Lua version regex step before running the tests**; corrected on current `87c88b9837f2649b57e52fdf530bb3d1ea585b0a`. **Dedicated exact-head run [40328363512](https://github.com/CosmicCuddle/N-Questie/actions/runs/40328363512) SUCCESS**: real Lua5.1 and Lua5.4 each **18/18** pinned actual compiler/staging/readback checks. At last check **11/13 exact-head PR+push workflows SUCCESS; only two M2 PR/push runs in progress, 0 artifacts across all 13 endpoints inspected**; do not claim full CI closure or actual compiler transaction acceptance. No writer/reader lease lifecycle fix, writer epoch A→B→A exclusion, immutable snapshot, full readback, atomic eight-field publish, SUCCESS-only revision, SavedVariables crash/relog recovery or WoW client memory/frame proof is implemented; this seam cannot be connected to Stage1 yet.

**CS02 independent queue**: review #178 exact-head mutations and faction cache; independent compiler-stage diff/mutation analysis of #180; no-idle backup true Gate08 TX01–TX18 safe stream driver and #175 poison/cleanup 12→14 work. [Team coordination](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6416793224). **Whole 439-record investigation** remains Gate10; initial pilot 1207–1209 **0/3**; eligibility denominator unknown. **Milestones still 3 COMPLETE / 6 UNDERWAY / 3 OWNER-APPROVED TECHNICALLY PENDING**. No confidential source relations in public GitHub, merge/package/install/release or protected `335` edits.

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

**NEW isolated [DRAFT #178](https://github.com/CosmicCuddle/N-Questie/pull/178)**, child of frozen #177 `00f2b4d1d5814f64a7c2284469358299171d4baa`. The current head at this checkpoint is `bebc6aab20104575220b8515158d3ae38bf18289`. Exactly **six net child paths**: loader nil-relation fast return, three fictional tests (22→25), CI 25-count gate, strict loader SHA1 repin (`20ffe65804c19dd9be25b3378a4b8cda02790158`), unchanged Init source with mode restored to **100755**, and custom data revision **11→12**. First initial #178 head (`bd469f5a`) had dedicated 25-case workflow PASS but **revision guard correctly FAILED** for unchanged revision 11. Revision 12 corrected the strict guard; a later workflow-only commit added **12/12 real pinned item codec checks on BOTH Lua5.1 and Lua5.4**. Exact new head dedicated PR workflow **SUCCESS**, with 25/25 owner probes and 12/12 item codec on both Lua versions, and strict revision guard **SUCCESS 11→12**. Existing loader 101/101 per Lua version and Lua5.1 item codec passed in actual overlay CI. At 12:53 GMT, **10/12 current-head PR+push workflow runs SUCCESS; only PR and push M2 runs remain in progress, no failed completed runs**. All twelve current-head Actions artifact endpoints were independently checked and were **empty at the check**; recheck after M2 completes. Do not call this full CI closure yet. Actual protected `335` remains `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.

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
