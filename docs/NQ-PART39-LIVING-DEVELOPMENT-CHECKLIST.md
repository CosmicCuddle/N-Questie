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

## Part39 opening checkpoint — independent GitHub recheck and public base audit (27 October 2026)

- Protected `335` rechecked via GitHub branch endpoint at exactly `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, unchanged. Draft #216–#221 heads match their handover ledger; no merge or review-head rewrite.
- [#221](https://github.com/CosmicCuddle/N-Questie/pull/221) exact `5fd7aaf2e93b0032bc4db6b5f73c005314a63578`: **7/7 complete original-head workflows SUCCESS, 0/7 artifact endpoints**, newly verified in Part39. This does not demonstrate in-game QA.
- Team [#42](https://github.com/CosmicCuddle/N-Questie/pull/42) rechecked through Part39 opening. Last observed CS02 allocations remain **undelivered/unverified** for real compiler-owned ambiguous Finish and per-witness RETRY map; CS02 #218 Q10 and #219 mutation/corpus verdicts not yet returned at this checkpoint.
- New isolated TEST-ONLY [draft #222](https://github.com/CosmicCuddle/N-Questie/pull/222), **head `f742e1f69e841c28155e5be51a671485381bd553`**, exact parent frozen #219 `b2c0aa868f4b2aa53aa29b5dfdf0ea22b9b30522`. Two new files only: a **read-only PUBLIC WotLK base** numeric compound `pairs()` ordering audit over four source tables and no-artifact dual-Lua CI. It summarizes counts only; no item/NPC/GO/quest relationship values or private data printed.
- #222 initial exact-head Actions: **10 original-head runs in progress**, including the new source-audit job; **NOT yet green**, no artifact closeout or result-based compatibility claim. Recheck after CI, including Lua 5.1/5.4 logs. The audit **does not** apply runtime Corrections/faction overrides/effective views or owner-private IP data; Stage1/corpus acceptance remains RED.
- Global stream-pool quarantine, compiler-owned ambiguous Finish, source A→B→A generation, complex codec, four-kind atomic memory/durable disk, native client acceptance remain blocked. All twelve gates remain **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**; **439 RAW** records, 1207–1209 **0/3** implementation.

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

