# N-Questie — Part 39 Living Development Checklist

**Opened:** 27 October 2026, Europe/London. **PUBLIC-SAFE / DRAFT DEVELOPMENT ONLY / NO MERGE OR RELEASE APPROVAL.**  
**Repository:** https://github.com/CosmicCuddle/N-Questie  
**Protected 335:** 8b23c6e2cfa00bb81cb26d40c44fef154e9e0070 (verified unchanged when opening Part39).  
**Team:** Owner/maintainer; CosmicScript01 (ChatGPT) technical lead and engineer; CosmicScript02 (Grok) independent review and assigned isolated test-only tasks via [PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42).  
**Read FIRST:** [COMPLETE Part38 → Part39 Handover](HANDOVERS/2026-10-27_PART38_TO_PART39.md) and this checklist **in full**, then [whole twelve-gate master](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), [historical Part38 checklist](NQ-PART38-LIVING-DEVELOPMENT-CHECKLIST.md), TX01–TX18 blueprint, E01–E08 writer audit, owned-source decision and [439-record programme](NQ-MISSING-QUEST-COVERAGE-PROGRAMME.md).

**Meaning of checks:** [x] means verified at the exact named HEAD and date, NOT production-accepted. [ ] means a next task or blocker. Passing KNOWN UNSAFE witnesses means genuine defects still exist; no gate can be promoted on that evidence alone.

## 1. Whole-project scoreboard — do not focus exclusively on Gate08 or 1207–1209

| Gate | Status | Current scope |
|---|---|---|
| G01 | COMPLETE | Raw quest-inventory reconciliation |
| G02 | COMPLETE | Offered-pilot owner confirmation |
| G03 | COMPLETE | Pinned source/client/registration audit |
| G04 | UNDERWAY | OPT-A manifest/provenance and safe loader |
| G05 | UNDERWAY | Effective NPC/GO/item forward and reverse quest ownership, faction and races |
| G06 | UNDERWAY | Completion cache CLEAR/ADD-only semantics |
| G07 | UNDERWAY | Item-starter/actual 3.3.5a loading |
| G08 | UNDERWAY (MAJOR BLOCKER) | Source/codec/stream/atomic commit/persistent recovery |
| G09 | UNDERWAY | Private historical/phase/loot/IP eligibility proof — private records NEVER in public GitHub |
| G10 | TECHNICALLY PENDING | Evaluate eligible quest additions over entire research inventory |
| G11 | TECHNICALLY PENDING | Native 3.3.5a/IP + RAM/GC/frame, relog and rollback QA |
| G12 | TECHNICALLY PENDING | Separate owner-approved integration/install/package/release |

**3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING.** Missing quest research = **439 RAW** records, NOT 439 approved additions (12 linked first-pass + 418 exploratory + 5 owner exclusions + 3 placeholders + 1 existing overlay). Eligible denominator unknown. Initial pilot quests 1207, 1208 and 1209 = **0/3 implemented**. Never invent or publicly reveal private NPC/GO/item/loot/IP links. Full 439-record coverage must be investigated, not replaced by a three-quest pilot.

## 2. Mandatory fresh Part39 opening checks

- [ ] Refresh protected 335 exact SHA. Stop and report any unexpected movement, rather than silently proceeding.
- [ ] Search newest GitHub draft PRs, branches, independent Grok comments in #42, #211/#212/#214 and subsequent children. New work may have appeared since the handover.
- [ ] Record HEAD, ancestry, draft status and exact changed paths for each active task before editing. Do not push to, rebase or rewrite another reviewed head.
- [ ] Query Actions by **exact source HEAD** (not merged PR simulation); inspect both Lua 5.1 and 5.4 logs. Re-audit each artifact endpoint after workflows finish. Different attempts/new runs get separate evidence.
- [ ] Record any failed historical heads separately; never convert an earlier failure into a green event.

### Latest VERIFIED Part38 closeout when Part39 opened

| PR | Exact HEAD | Dual Lua source tests | Full CI and artifacts |
|---|---|---|---|
| [#211](https://github.com/CosmicCuddle/N-Questie/pull/211) | ad855f0bc515648875ef59208e68c01534cb039f | 157/157 each | 9/9 Actions success, 0/9 artifacts (previously checked); CS02 reviewed |
| [#212](https://github.com/CosmicCuddle/N-Questie/pull/212) | 235488b73a6c86ca96367a64c8970a29aeed58d4 | 8/8 KNOWN UNSAFE/positive each | 10/10 success, 0/10 (previously checked); CS02 reviewed |
| [#214](https://github.com/CosmicCuddle/N-Questie/pull/214) | df4fdfb86a5846a267baf23e989de146d6051067 | 19/19 KNOWN UNSAFE each | 10/10 success, 0/10 (previously checked); CS02 reviewed |
| [#216](https://github.com/CosmicCuddle/N-Questie/pull/216) | 98ba7ab1b9ed34987c581f03879cc54c331b28b8 | 169/169 each | **10/10 success, 0/10 artifacts rechecked at handover** |
| [#217](https://github.com/CosmicCuddle/N-Questie/pull/217) | f77c5eb4d55e7df86583ef5e24fc78dca31f984a | Documentation | **8/8 success, 0/8 artifacts rechecked at handover** |
| [#218](https://github.com/CosmicCuddle/N-Questie/pull/218) | 4e23cb43b8d02e03aa21f3fec5b4cf4765f12fb0 | 9/9 KNOWN UNSAFE/positive each | **10/10 success, 0/10 artifacts rechecked at handover** |
| [#219](https://github.com/CosmicCuddle/N-Questie/pull/219) | b2c0aa868f4b2aa53aa29b5dfdf0ea22b9b30522 | 174/174 each | **9/9 success, 0/9 artifacts rechecked at handover** |
| [#220](https://github.com/CosmicCuddle/N-Questie/pull/220) | 38496c000778236e373ce3533144bf76becc62d1 | Documentation | **7/7 success, 0/7 artifacts rechecked at handover** |

The five most recent #216–#220 contain **44/44 successful original-head Actions, zero artifacts across all 44 endpoints independently checked**. All are isolated DRAFT, unmerged. Older pending M2 notes in Part38 are historical. **[#209](https://github.com/CosmicCuddle/N-Questie/pull/209) standalone MUST NOT MERGE:** rejects ~2,265 legitimate public Questie Correction {} clear records (including 23 pair-field empties); #211 corrects optional-stage semantics.

## 3. Part39 Priority A — independent review and targeted stage-compound accuracy

- [x] #211 corrected optional stage preserves deliberate {} clears, normal WotLK and SoD codec unchanged, actual dual Lua 157/157; CS02 exact-head review verified **264 historical cross-head no-stage/SoD byte parity cases**, 93 accepted exact and 171 correct-field refusals. [CS02 review](https://github.com/CosmicCuddle/N-Questie/pull/211#issuecomment-6447069874).
- [x] #216 12 additional real four-kind × three-shape synthetic WotLK/SoD within-head byte comparisons; 169/169 dual Lua, dedicated + whole CI green at recorded HEAD.
- [x] #219 stage-only conservative actual pairs() enumeration order guard; refuses non-1..count traversal, including reversed dense hash-part sources, pins M07/M09/M14 and exact error field M17; 174/174 dual Lua, whole CI green at recorded HEAD.
- [ ] CS02 independent **exact-head review of #219**: rerun M07/M09/M14/M17, reverse dense-hash array and pair-array mutations, inspect source-key exceptions and first-failure type, check no-stage/SoD byte invariants. Do not assume CI passed = all mutations killed.
- [ ] **PUBLIC effective-corpus compatibility audit**: quantify hash-part dense table sources that #219's conservative order guard may reject; inspect public corrections and overlays only, NEVER owner-private SQL. Decide whether the writer must canonicalize order instead of rejecting legitimate numeric arrays; treat any new changes as isolated child draft, not editing frozen #219.
- [ ] Pin M21/M22 **rejection-path DEAD/Finish lifecycle** mutants separately. Keep Lua 5.1 yield/pcall caveats.
- [ ] Expand safety beyond nine simple codecs: complex nested spawn/waypoint/questgiver/trigger/objective/extra-objective/string/count/sentinel formats and actual reader exactness remain RED.

## 4. Part39 Priority B — global QuestieStream pool

- [x] #206 real global pool aliases and ambiguous synthetic post-Finish errors reproduced as **KNOWN UNSAFE**; review explicitly rejects idempotent-finish-only as adequate quarantine.
- [x] #212 positive raw_assert reuse + cross-borrower synthetic method contamination, 8/8 dual Lua. CS02 Q4/Q9 mutations uniquely killed; Q10 raw-mode pool-disable survived.
- [x] #218 adds production raw-mode positive clean pooled reuse before poisoning, 9/9 dual Lua; all 10 Actions green, 0 artifact endpoints at handover. No real quarantine implementation.
- [ ] CS02 review exact #218 Q10 mutant: disabling raw pooling should FAIL the new positive control; verify normal and ambiguous cases stay isolated and don't mask each other. Identify unique mutant killers.
- [ ] **CS02 delegated #206 source-owned ambiguous Finish actual compiler path**: independently test BEFORE/AFTER true pool return, typed/clean error, driver cleanup only after DEAD and exactly once, positive normal raw reuse. New TEST-ONLY isolated draft expected; check #42 first to avoid duplicate engineering.
- [ ] Design and eventually test actual global pool quarantine/lease generations, method-slot reset and double-finish/alias refusal across all consumers **without disabling valid pooling**. No production adoption before independent review.

## 5. Part39 Priority C — truthful source generation and A→B→A recovery

- [x] #207 actual mid-source compiler A49/B49/A22 produces authenticated scratch receipts although source returns to all A. Any start/end source fingerprint-only RETRY is UNSAFE.
- [x] #214 checks every live source record (120 A) and all actual GetDBHandle decoded rows (A49/B49/A22); 19/19 dual Lua KNOWN UNSAFE, reviewed by CS02. Non-name field S7 and reader method-slot hygiene remain gaps.
- [ ] **CS02 delegated #214 per-witness RETRY flip map:** replace test driver abort-on-first-error with independent recorded {ok,reason,verified} for each source mutation; ensure hypothetical typed/clean RETRY produces reported flips for ALL witnesses, including final E02m, rather than stopping in compileStage/drive. No fake production source fix.
- [ ] Pin non-name source field S7, both faction views, real override merges, nested mutations, unknown source writers, append/delete while compiling, and global consistency beyond fictional NPC names.
- [ ] Choose real all-writer exclusion/immutable snapshot or compatible generation/epoch strategy; **E01–E08 still NOT accepted**. Don't substitute a final-value fingerprint or a toy registered-writer counter that unknown writers bypass.

## 6. Part39 Priority D — atomic four-kind memory and disk transaction

- [ ] Actual driver over NPC, object, quest, item: four committed pairs = **eight Bin+Ptrs fields**, plus revision, compiled count, locale/language and metadata, all derived from a verified coherent source attempt.
- [ ] Typed SUCCESS/BUSY/RETRY/ERROR/ABORTED_QUARANTINED outcomes with no-yield atomic in-memory swap only after all writers DEAD, readable and source-consistent. Poisoned leases must not re-enter pool.
- [ ] Separate SavedVariables **on-disk** relog/crash-interruption recovery and no mixed-generation restart; TX01–TX18 independent acceptance all still RED.
- [ ] No publishing/uploading saved real account data. Actual client testing later must use owner-approved local backups.

## 7. Part39 Priority E — full quest and remaining gates

- [ ] G04 safe OPT-A manifest provenance, runtime loader; G05 effective reverse/forward owners, cross-faction/source races; G06 completion cache; G07 item starters/3.3.5a loader; G09 private IP/historical/loot evidence remain underway.
- [ ] G10 triage **all 439 raw records**, preserving 12 linked candidates, 418 exploratory, 5 owner exclusions, 3 placeholders and 1 existing overlay. Classify each individually; eligible denominator unknown. Pilot 1207–1209 **0/3** until validated implementation. Do NOT claim 439 additions are pending or build fake quest associations.
- [ ] G11 native 3.3.5a AzerothCore/IP gameplay, RAM/frame/GC, relog, faction, rollback, SavedVariables testing only with separate owner authorization and addon/SavedVariables backups.
- [ ] G12 install/packaging/tag/release only with separate approvals after successful technical and peer gates.

## 8. Operating rules and end-of-part checkpoint

1. GitHub repository is **PUBLIC**. Use imaginary test IDs/relationships only; never publish owner SQL, real NPC/GO/item/loot links, private IP mapping/source or worksheet/database dumps.
2. Protected 335 remains at pinned baseline until owner authorizes any protected change. Fresh isolated branches from exact parent SHA, DRAFT PR only. Never merge, rebase reviewed heads, install, package, tag or release by default.
3. **Verify actual Lua 5.1 and 5.4**, no source/writer hidden escapes; inspect original-head Actions logs and ALL run artifact endpoints. Green tests and KNOWN UNSAFE results must not be represented as client or production acceptance.
4. Coordinate Grok in [PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42) with exact head and concrete independent mutation challenge; keep delegated tasks distinct. Don't ask owner for routine permission to perform safe public synthetic draft work.
5. Keep this Part39 living checklist and [authoritative master](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md) current through isolated **documentation DRAFTS**, preserving older handovers and previous failed CI heads. At every checkpoint: exact GitHub PRs, SHAs, dual-Lua logs, full Actions and artifact status, Grok feedback, technical blocks, gates **3/6/3**, research **439 raw**, pilot **0/3**.
6. Before any separately authorized owner-client/server installation or testing, provide small readable steps and ensure addon folder, SavedVariables, and relevant private server/database backups; do not upload backups to the public repo.

**Part39 opening state:** Everything in this checklist is development evidence only. No protected-335 changes, no merges, no client installation, no ZIP upload, no tags and no release. Continue useful code/test work on bounded real blockers, not repeated status narration.


## 9. Live Part39 checkpoint — 27 October 2026, 17:24–17:30 UTC

**Newer than the Part39 opening ledger; all evidence is exact-head draft-only and not integration acceptance.**

- [x] Protected `335` re-fetched unchanged at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. Existing #216–#221 reviewed heads remain unchanged on this check.
- [x] Grok CS02's comment-only reviews received: [#218](https://github.com/CosmicCuddle/N-Questie/pull/218#issuecomment-6448363078) Q10 killed at positive raw reuse #1; [#219](https://github.com/CosmicCuddle/N-Questie/pull/219#issuecomment-6448363736) reversed-order tests #116/#117, M14, M17 verified with M07/M09 single-guard equivalence caveat; [#222](https://github.com/CosmicCuddle/N-Questie/pull/222#issuecomment-6448364387) base-only public WotLK corpus 47,084 simple fields, no reordered/malformed on Lua5.1/5.4. Never convert this into effective-corpus or client acceptance.
- [x] #224 exact `dc3f21006ab97a27d51f0d2aa300ff0f4beaf035`: documented dedicated real Lua 5.1/5.4 21/21 KNOWN UNSAFE, 10/10 CI success, 0/10 artifacts. S7 non-name `minLevel` A→B→A torn reads still pass receipts: defect reproduced, NOT fixed.
- [x] #226 exact `d8a83c2435f51c153ab8abf5cea572b4758a1670`: live GitHub Actions queried by exact HEAD, **10/10** completed-success (9 pull_request and 1 push) and every one of the **10/10 individual run artifact endpoints** directly queried, **zero artifacts**. Runs: `40548415801`, `40548415446`, `40548415949`, `40548415447`, `40548415473`, `40548415772`, `40548415627`, `40548415783`, `40548415547`, `40548407090`. Dedicated `40548415627` reports six fictional order controls on Lua 5.1 and 5.4; independent CS02 exact-head mutation review **still pending**. Preserve historical failed interim YAML head `960db1be`; do not rewrite.
- [ ] CS02 delegated T1 actual compiler-owned Finish and T2 per-witness RETRY are **claimed but no delivered PR verified at this checkpoint**; see [coordination #42](https://github.com/CosmicCuddle/N-Questie/pull/42). Do not duplicate their scope without a fresh activity check.
- [ ] Next engineering: audit *effective public Corrections/overrides*, not just generated base; S7/method-slot source witnesses and real all-writer epoch; targeted global pool quarantine with healthy reuse; four-kind atomic publication; disk restart recovery. All remain RED.

**Programme unchanged:** gates **3 complete / 6 underway / 3 technically pending**; **439 raw** research records, eligible denominator unknown; pilot 1207–1209 **0/3 implemented**. No private server data, protected commits, merge, packaging, installation, tag or release.

## 10. Part39 follow-up — independent CS02 T1/T2 and public item correction-order investigation

**Checkpoint:** 27 October 2026, original exact-head GitHub Actions, no production/Stage1 acceptance.

- [x] CS02 **T1 delivered** TEST-ONLY draft [#227](https://github.com/CosmicCuddle/N-Questie/pull/227), HEAD `0af76d4ce69dd59a9a9aa55391b8906b85bd5218`. Actual dual Lua 5.1.5/5.4.6 dedicated [run 40548358877](https://github.com/CosmicCuddle/N-Questie/actions/runs/40548358877): **20/20 each** KNOWN UNSAFE/healthy positives, including real compiler-owned post-Finish alias/borrower collision. Full **11/11 original-head Actions success**, **0/11 artifacts independently fetched**. This proves quarantine remains missing, NOT safe.
- [x] CS02 **T2 delivered** TEST-ONLY draft [#229](https://github.com/CosmicCuddle/N-Questie/pull/229), HEAD `7085d24415100d2b0af4ebcf5165a353a39293af`. Dedicated [run 40550913339](https://github.com/CosmicCuddle/N-Questie/actions/runs/40550913339) on both real Lua versions shows 19 independent witnesses × baseline/four hypothetical typed/clean RETRY paths, **zero flip-map mismatches**; start/end comparison alone misses E02 and E02m while per-row check flips E02m but misses pre-encode edits. Full **11/11 Actions success**, **0/11 artifacts directly checked**. This is NOT a production RETRY implementation and E01–E08 stay RED.
- [x] [#228](https://github.com/CosmicCuddle/N-Questie/pull/228) HEAD `9060bbfa0bdd8f707d0a368a2e0c733d9839e26f`: **7/7 original-head Actions success**, **0/7 artifacts individually checked**.
- [x] New isolated TEST-ONLY [#230](https://github.com/CosmicCuddle/N-Questie/pull/230) initial HEAD `ff0b5b617bc693ee9d605155e55791d3d53e7567`, child of frozen #226. New two-file read-only PUBLIC item correction ordering survey includes Classic/TBC/WotLK item Load corrections, automatic item start non-overwrite policy and both faction overlay-first projections. Real dual Lua dedicated [run 40555966348](https://github.com/CosmicCuddle/N-Questie/actions/runs/40555966348) SUCCESS, both VM/factions: **36,767 rows / 28,755 simple fields / 28,409 ordered / 0 dense reordered / 0 malformed / 346 intentional empties**. Synthetic audit sensitivity controls **6/6** each; **1,432** patch writes, faction overlay writes **12 Alliance / 11 Horde**, override simple fields **11**. Original-head wider workflow status **10/11 success, 1 M2 still running** on this snapshot; all **11 artifact endpoints checked zero so far**, MUST recheck after finish and never label total green before completion.
- [ ] Independent CS02 review requested for #226/#230, especially classifier mutants, corrections application order, prospective compile-time vs read-time faction overrides, proper exclusion boundaries. Public ITEM partial evidence is not whole-four-kind effective source compatibility, unknown/custom private writers, actual Lua compiler reader, or Stage1 approval.
- [ ] Genuine source epoch/all-writer control, real stream quarantine, no-yield four-kind atomic eight-field memory commit and durable SavedVariables restart/rollback remain RED. Continue other G04–G07, G09 and full G10 quest research; do not narrow scope.

**Governance remains:** G01–03 COMPLETE; G04–09 UNDERWAY; G10–12 TECHNICALLY PENDING (**3/6/3**). Missing-quest research **439 RAW**, denominator unknown, pilot 1207–1209 **0/3**. Protected `335` unchanged at pinned `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` at Part39 opening; repeat live check before any new engineering. Public-only, no private relationships or owner server data; no merge/install/release/tag/package authorization.

## 11. Part39 checkpoint — CS02 audit challenge and guarded item layer (27 October 2026)

- [x] Grok CS02's comment-only review of frozen #226 `d8a83c2435f51c153ab8abf5cea572b4758a1670` independently killed the A1 reversed-order removal mutant and other density/empty/order mutants, verified six controls and real dual-Lua 10/10 original-head Actions, 0/10 artifacts. [Review](https://github.com/CosmicCuddle/N-Questie/pull/226#issuecomment-6449843705). Still **public WotLK BASE** only, not effective four-kind data.
- [x] Grok CS02 independently reviewed #230 `ff0b5b617bc693ee9d605155e55791d3d53e7567` and verified real **read-time** override-first semantics from `QuestieCorrections:MinimalInit` to `GetDBHandle`. Public item survey counts (each faction) 36,767 rows, 28,755 fields, 28,409 ordered, 346 deliberate empties, 0 reordered/malformed. [First review and C3–C5 survivors](https://github.com/CosmicCuddle/N-Questie/pull/230#issuecomment-6449845073); [C6 and override accounting](https://github.com/CosmicCuddle/N-Questie/pull/230#issuecomment-6449875358). **Surviving mutations found:** C3 base-first instead of override-first; C4 inserted reversed dense field passes unpinned workflow; C5 omit automatic item starts; C6 double count override-only rows. These are **test audit weaknesses**, not proof current public source data malformed.
- [x] #230 original HEAD rechecked **11/11 Actions SUCCESS** after previous running M2 completed. Its source survey remains historically weak under C3–C6; do not retroactively call those mutants killed.
- [x] Opened isolated two-path TEST-ONLY [draft #232](https://github.com/CosmicCuddle/N-Questie/pull/232), HEAD `b0b5703eab88befd2c4ff2201f4874906a6e283c`, exact child of unchanged #230. Reuses **one** override-first resolver in fictional positive controls and actual source scan; adds fictional override-only counting/clear controls (**11/11 total**), fails closed when reordered/malformed >0, and pins public aggregate counts and layer write totals in Lua **and** CI. [Dedicated actual dual Lua5.1.5/5.4.6 run 40561258243](https://github.com/CosmicCuddle/N-Questie/actions/runs/40561258243) independently read: 11/11 controls, 0 reordered/malformed, both faction outputs unchanged. Wider CI **8/11 successful, three still running at initial checkpoint**; do not claim full green without a later exact-head query. All **11 original-head run artifact endpoints** checked zero so far; recheck after completion.
- [ ] CS02 independent #232 mutation review requested in [team #42](https://github.com/CosmicCuddle/N-Questie/pull/42): rerun/revert C3–C6, empty-versus-nil, count drift, and privacy. No mutation killers accepted until independently shown on real Lua5.1/5.4. Any unexplained pinned-count movement must fail and trigger source investigation, not automatic approval.
- [ ] Extend effective correction-order investigation to the other **three** PUBLIC kinds (NPC, object, quest), then any public `Compat.LoadCorrections` and late writer paths with independently proven semantics, respecting all private server-data boundaries. Full source ownership, global stream quarantine, four-kind atomic memory, SavedVariables crash recovery and native client tests remain **RED**.
- [ ] G04/05/06/07/09 continue in parallel; full G10 eligibility triage for all 439 RAW research records remains technically pending, NOT 439 approved quests. Pilot 1207–1209 0/3. G11 live client and G12 release only after separate owner authorization.

**Gate scoreboard unchanged: 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**. All changes are isolated unmerged drafts; no private NPC/GO/item/loot/IP mappings, protected `335` writes, installs, packages, tags or releases.

## 12. Part39 public object correction pilot and independent CS01 T1/T2 review

**Additive checkpoint — 27 October 2026; DRAFT TESTS ONLY. Older workflow snapshots remain historical.**

- [x] Frozen Grok TEST-ONLY [#227](https://github.com/CosmicCuddle/N-Questie/pull/227) compiler-owned Finish 20/20 real dual-Lua KNOWN UNSAFE and [#229](https://github.com/CosmicCuddle/N-Questie/pull/229) 19-witness/4-shim RETRY flip map independently reviewed by CS01 in [#227 comment](https://github.com/CosmicCuddle/N-Questie/pull/227#issuecomment-6450702288) and [#229 comment](https://github.com/CosmicCuddle/N-Questie/pull/229#issuecomment-6450703309). They demonstrate current alias and incomplete epoch protection, not fixes. #229 textual conflict with #224 S7 fixture MUST retain both witness sets in a new future integration draft; do not mutate either reviewed source head.
- [x] New isolated public read-only WotLK **object** correction-order audit [TEST-ONLY DRAFT #234](https://github.com/CosmicCuddle/N-Questie/pull/234), exact HEAD `4003926b59fb89603b24b3e4f7edd80bc66bbd95`, child of frozen #232. **Two new files only**. Reads actual public WotLK object base/ZoneDB and applies Classic→TBC→WotLK object patch Load(), projections from faction LoadFactionFixes() for Alliance and Horde; only simple `questStarts`/`questEnds` u8u24array audited, NOT spawnlist/complex kinds or private owner server data. Actual dedicated dual Lua5.1.5/5.4.6 [run 40562607944](https://github.com/CosmicCuddle/N-Questie/actions/runs/40562607944) **SUCCESS**, 10/10 fictional controls on each; each faction: **13,043 public object rows, 803 simple fields, 789 ordered, zero dense reordered/malformed, 14 intentional empties, 904 patch writes, 8 faction correction writes, 0 simple override fields and 0 override-only rows**. Last zero means actual simple overlay replacement is not exercised by this public object corpus, only by fictional controls. Full original-head broader Actions ongoing, do not claim all-green; artifacts must be checked after completion.
- [x] New isolated TEST-ONLY child [#235](https://github.com/CosmicCuddle/N-Questie/pull/235) exact `fc7371172bdac0615728cb78b21a530f363e938d`, parent FROZEN #234, changed paths: same audit and CI files only. Pins the **observed** object counts in Lua assertions and workflow expected lines, refuses future drift without independent examination; no production code. Real dedicated dual-Lua #235 and wider CI **pending** at creation, no success claim. Independent CS02 mutation challenge requested via coordination #42.
- [ ] No promotion of #219 Stage1 staged ordering until actual effective **all four kinds**, public Compat, late writers, source epochs, global stream quarantine, no-yield atomic eight-field+metadata publication and SavedVariables disk recovery are verified. Item and object audits are *partial* read-only projections. Remaining **NPC/quest** public correction investigations not yet done, and complex spawns/objectives excluded.
- [ ] Full G04–G09 sources and G10–G12 commitments remain unchanged: **3 complete, 6 underway, 3 technically pending**; full missing-quest study **439 RAW records** (12+418+5+3+1), no approved addition denominator, initial quests 1207–1209 **0/3 implemented**. No owner-private NPC/GO/item/loot/IP relationships, protected `335` edits, merge, install, package, tag or release.


## 13. Part39 — third public correction kind (NPC) and peer review closeout

**27 October 2026, public-safe TEST-ONLY DRAFT; previous status paragraphs remain historical.**

- [x] CosmicScript02 independent dual-Lua mutation reviews: [#232 item C3–C6 and clear/counts](https://github.com/CosmicCuddle/N-Questie/pull/232#issuecomment-6451195588), [#234 object wiring and O5/O6 survivors](https://github.com/CosmicCuddle/N-Questie/pull/234#issuecomment-6451196195), [#235 guarded object audit O5/O6/O8 killed](https://github.com/CosmicCuddle/N-Questie/pull/235#issuecomment-6451196975). All remain tests, not production fixes. Verified historical exact-head CI: #232 12/12 SUCCESS zero artifacts, #234 13/13 per independent CS02 zero artifacts (13 individually checked), #235 12/12 per independent CS02 zero artifacts.
- [x] New isolated [public WotLK NPC correction audit #237](https://github.com/CosmicCuddle/N-Questie/pull/237) at exact cf6e219a64ca2dea527c1b3ace323f7ffefb0f5e, child of frozen #235, two new test/CI paths. Dedicated real Lua5.1.5 and 5.4.6 [40568077450](https://github.com/CosmicCuddle/N-Questie/actions/runs/40568077450) SUCCESS: both factions 29,615 NPC rows, 6,023 simple questStarts/questEnds fields, all 6,023 ordered, zero reordered/malformed/empty, 2,627 manual correction field writes, 84 WotLK automatic writes, faction fix writes 25 Alliance/24 Horde, simple override fields 0 and override-only rows 0. Ten purely fictional classifier/fallback/empty/extra-row controls pass on each VM.
- [x] New guarded [TEST-ONLY child #238](https://github.com/CosmicCuddle/N-Questie/pull/238), exact 6647437079757bb4a52e46528c66eb639862e56a from FROZEN #237, modifies existing 2 test/CI paths only to pin observed public NPC counts/auto-writes in both Lua and workflow. Actual dual-Lua dedicated [40568280891](https://github.com/CosmicCuddle/N-Questie/actions/runs/40568280891) SUCCESS, 10/10 controls and unchanged aggregate counts. #237 wider CI historically 11/14 success with 3 running; #238 6/13 with 7 running at initial checkpoint, no all-green claim. All 14 and 13 run artifact endpoints individually queried zero so far; re-query if additional runs created. CS02 independent #238 mutation review requested in [#42](https://github.com/CosmicCuddle/N-Questie/pull/42).
- [ ] NPC scope is partial. Excluded: spawnlist and waypointlist (two synthetic placeholder waypoint presets only permit non-audited fields to load), derived cross-quest faction patches, 335 Compat/custom/late writers and 3.3.5a client. There are zero real simple-array override fields, so override-first is tested synthetically only.
- [ ] Fourth kind, public QUEST correction audit needs its own source-backed fixture: questDB has several simple array and pair formats plus excluded complex questgiver, objectives, trigger, objective-text and extra-objective formats. Correct load order includes Classic LoadMissingQuests, Classic reputation corrections, then Classic/TBC/WotLK quest Load with missing-index inserts and Classic/TBC faction overrides. Check the real enum/profession dependencies before any implementation; no fabricated private mappings.
- [ ] Global G08 owner/epoch/quarantine/four-kind atomic disk/relog protection, all-writer and full client acceptance remain RED. Twelve-gate scoreboard 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; 439 RAW research not approved, pilot 1207–1209 = 0/3 implemented. G04–G07 and G09 investigations continue, G10–12 separately gated. Protected 335 unchanged, no owner-private SQL/NPC/GO/item/loot/IP data, merge/install/package/tag/release.
