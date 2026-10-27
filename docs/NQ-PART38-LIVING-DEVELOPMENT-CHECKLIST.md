# N-Questie — Part 38 Living Development Checklist

**Opened:** 27 October 2026. **PUBLIC-SAFE — Development DRAFTS / DO NOT MERGE.** 
**Repository:** https://github.com/CosmicCuddle/N-Questie
**Protected `335`:** `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, verified unchanged on 27 October.
**Team:** Owner/maintainer; CosmicScript01 technical project/integration/engineering lead; CosmicScript02 (Grok) independent review via [PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42).

**MANDATORY: Read [the COMPLETE Part37→Part38 handover](HANDOVERS/2026-10-27_PART37_TO_PART38.md) and THIS complete living checklist before changing anything.** Also read [authoritative twelve-gate master](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), [TX01–TX18 blueprint](research/NQ-PART35-GATE08-TRANSACTIONAL-COMPILER-INTEGRATION-BLUEPRINT.md), [source-writer audit E01–E08](research/NQ-PART36-GATE08-SOURCE-WRITER-COVERAGE-AUDIT.md), [owned source decision paper](research/NQ-PART37-GATE08-OWNED-SOURCE-GENERATION-DECISION.md) and [whole 439-record programme](NQ-MISSING-QUEST-COVERAGE-PROGRAMME.md). Dated historical Part37 records remain preserved. Verify all GitHub live data at the new session.

### Part38 next checkpoint — true midstream ABA and whole Gate08 safety

- **[#204](https://github.com/CosmicCuddle/N-Questie/pull/204)** frozen `21f709a72cecd31fc4e920656dbe50589940a5e9`: **132/132 source-backed tests per real Lua version; 9/9 original-head Actions SUCCESS and 0/9 artifact endpoints**. Prior 8/8 snapshot below is historical; mutation kills/dense-array exactness still unproved.
- **[#206](https://github.com/CosmicCuddle/N-Questie/pull/206)** corrected `18b5ab70c319c757ef8656d49f062801caa51b01`: actual pinned QuestieStream **6/6 KNOWN UNSAFE** tests per Lua 5.1 and 5.4, original `38691dcf...` dedicated head FAILED because test-only wrapper teardown was wrong (preserve). **9/10** full original-head CI SUCCESS, M2 IN PROGRESS at this checkpoint; **0/10 artifacts** individually checked. A real production pool quarantine has **not** been implemented.
- **New [#207](https://github.com/CosmicCuddle/N-Questie/pull/207)** exact `21aeabbb63fec0ad93c0ee09c1b0e7681f3f5443` stacked on frozen #201 `886adc4a1d5d74bb6cc982fc3c7368a3ed760766`: **18/18 source-coroutine KNOWN UNSAFE checks per real Lua 5.1 and 5.4** (dedicated original-head run 40524946938 SUCCESS; full logs checked). New E02m runs 120 invented NPCs through real first A batch, middle B batch, then restores all live source rows A before final A batch. Real reader finds A/B/A despite source all A and authenticated scratch receipts. **9/10** full exact-head CI SUCCESS, M2 IN PROGRESS; **0/10 artifact endpoints**, Grok review requested in [team #42](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6445180501). THIS IS A FAILURE WITNESS, NOT A SAFETY FIX.
- **Documentation:** #205 previously frozen head `fefc4ad2ae65917ec39f4151ce32dd6183558029` separately **7/7 CI SUCCESS, 0/7 artifacts**; #205 was subsequently advanced to `e90c2f2336ca9c14380831ff2a45e3499ddba82a` with different CI, and this new docs child was based on that later head without rewriting it.
- [ ] Close all **original exact-head** pending M2 jobs and requery artifacts before all-green claims; obtain separate CS02 challenges for #204 pins and #207 source ABA, and test dense/exact compound representation, unknown source writers and global stream quarantine.
- **Unchanged:** G01–G03 complete, G04–G09 underway, G10–G12 technically pending (**3/6/3**). **439 raw research records** are not 439 approved quests; 1207–1209 pilot **0/3**. E01–E08 actual source exclusion, global pool quarantine, complex codecs, eight Bin/Ptrs+revision atomic publication, disk SavedVariables crash/relog recovery and real 3.3.5a/IP gameplay/RAM/GC remain RED. PUBLIC invented sources only; `335` unchanged `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`; DRAFT, no merge/install/package/tag/release.

### Part38 exact-head closeout addendum — subsequent same-day checks

- **[#204](https://github.com/CosmicCuddle/N-Questie/pull/204) frozen TEST-ONLY head `21f709a72cecd31fc4e920656dbe50589940a5e9`**: actual source-backed stage suite **132/132 on EACH Lua5.1 and Lua5.4** via original branch dedicated [run 40523080593](https://github.com/CosmicCuddle/N-Questie/actions/runs/40523080593); **8/8** original-head workflows SUCCESS; all **8/8 artifact endpoints independently fetched, zero artifacts**. This is mutation regression PIN COVERAGE, not proof all 8 survivors independently killed or dense/pair/complex codec safety. CS02 exact-head retest requested via [team thread](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6444905353).
- **[#206](https://github.com/CosmicCuddle/N-Questie/pull/206) shared global QuestieStream pool KNOWN-UNSAFE witness**, new test plus strict no-upload workflow, frozen parent #202. **Initial `38691dcf46e29a6561ab2ef7e2ccc199fcbca86a` dedicated run `40524398587` FAILED** after 4/6 because injected synthetic throwing `finished()` wrapper persisted on same-mode reborrow; correction restores that wrapper before double-return witness in current head `18b5ab70c319c757ef8656d49f062801caa51b01`. Corrected dedicated [run 40524756081](https://github.com/CosmicCuddle/N-Questie/actions/runs/40524756081) **6/6 KNOWN UNSAFE witnesses on each real Lua version**. Whole nine-run exact-head CI and artifacts **still pending** at this documentation checkpoint; do not reclassify the initial failure as a pass. This synthetic *post-return* exception reveals the module-global pool alias/duplicate-return hazard, but does not establish how often actual production Finish throws or quarantine correctness.
- **Previous [#205](https://github.com/CosmicCuddle/N-Questie/pull/205) documentation head `fefc4ad2ae65917ec39f4151ce32dd6183558029`**: **6/6** original-head workflows SUCCESS and all **6/6 artifact endpoints ZERO**. This updated documentation commit is a *new head* requiring its own fresh CI and artifact closeout.
- No production stream-pool fix, source epoch, complex codec safety, transactional four-kind publication or disk/relog acceptance; all G08 blockers remain active. Protected `335` stays `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` at last verified check. Whole programme remains **3/6/3**, **439 RAW** records, pilot **0/3**; owner approvals unchanged.

## Part38 active engineering update — 27 October 2026 (CS01)

**New isolated [TEST-ONLY DRAFT #204](https://github.com/CosmicCuddle/N-Questie/pull/204)**: exact first head `21f709a72cecd31fc4e920656dbe50589940a5e9` on FROZEN #202 `c9b487fd29eaf32a65025b0fc111b593e5e7240b`; only `tests/compat/nq_gate08_four_kind_stage_source.lua` and the no-upload dual-Lua stage workflow changed. Adds nine fictional-source checks targeted at CS02's eight non-equivalent #202 mutation survivors. Expected test total **132/132 per Lua version**. **CI was still running at initial Part38 documentation update; success/artifacts/peer mutation results must be separately rechecked at this exact head.** No production compiler changed. PUBLIC-SAFE only.

**CS02's newer reviews received and read** (supersede the old pending queue, preserve prior historical wording): [#199](https://github.com/CosmicCuddle/N-Questie/pull/199#issuecomment-6444268186) 5/5 targeted M10b/M10d/M11 mutations killed, 102/102 baseline; [#202](https://github.com/CosmicCuddle/N-Questie/pull/202#issuecomment-6444268954) 12 killed, 8 *non-equivalent* survivors, 1 equivalent, 4 unreachable; valid-shape bounds work but sparse/hash/extra keys and nil/sentinel exactness fail; [#201](https://github.com/CosmicCuddle/N-Questie/pull/201#issuecomment-6444269806) real middle-batch A→B→A source mutation restores starting values yet creates mixed bytes accepted by both cosmetic/fingerprint RETRY concepts; [#198](https://github.com/CosmicCuddle/N-Questie/pull/198#issuecomment-6444270637) cooperative writer version is bypassed by unregistered changes and registeredWrite dropping the actual `fn()` survives. *These are not E01–E08 acceptances.*

**Handover [DRAFT #203](https://github.com/CosmicCuddle/N-Questie/pull/203)** frozen `a42d87677b383f51235dbacfeee39e62f3293c4c`: checked all 6 workflow runs SUCCESS and individually checked all 6 artifact endpoints ZERO on 27 October. Protected `335` verified still `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.

**Now next:** exact-head #204 dual-Lua/CI/artifact audit and CS02 mutation kills; #201 true midstream A→B→A #18 test-only witness with readable status and lease-cleanup invariants; source-backed dense array/exact pair contract with nil/default/sentinel investigation **before altering production stage codec**, then complex nested types, global StreamPool poison, coherent source capture, actual 4-kind publish, disk/relog. Contact via [team PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6444905353).

**Unchanged WHOLE PROJECT:** 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING, 439 raw records NOT approved additions, 1207–1209 pilot 0/3 implemented. Nothing merged, installed, packaged or released; private source associations remain offline.

## 1. Entire twelve-gate work (not just compiler or three quests)

- [x] **G01** Full raw research inventory reconciled (439 records: 12 initial, 418 exploratory, 5 excluded, 3 placeholders, 1 already present).
- [x] **G02** Owner offered pilot 1207–1209; **0/3 implemented**, not approved source relations.
- [x] **G03** Client/source/registration audit.
- [ ] **G04** OPT-A manifest/provenance/schema/loader — UNDERWAY.
- [ ] **G05** Effective forward+reverse quest/NPC/GO/item, true faction, source writer/exclusion — UNDERWAY.
- [ ] **G06** CLEAR/ADD-only completion cache — UNDERWAY.
- [ ] **G07** Item-starter/3.3.5a loader — UNDERWAY.
- [ ] **G08** Four-kind compiler source epoch, numeric schemas, stream leases, atomic transaction and persistent recovery — UNDERWAY.
- [ ] **G09** Private eligibility/loot/IP/phase proof — UNDERWAY.
- [ ] **G10** All 439 raw records individually investigate, classify, then implement only those independently eligible — owner-approved but technically PENDING.
- [ ] **G11** Native 3.3.5a client+server/IP memory, gameplay, relog/recovery, rollback QA — owner-approved but technically PENDING.
- [ ] **G12** Owner-governed install/packaging/integration/release — owner-approved broad work but technically PENDING; separate action approval required.

**Programme status: 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING.** Do not mark Gate10 complete for a three-quest pilot or treat all 439 records as eligible. Preserve exclusions and 0/3 pilot.

## 2. New-session exact-head closeout ledger — Part37 final verification

| PR | Exact frozen SHA | Source-backed/dedicated verification | Own original-branch Actions / artifacts |
|---|---|---|---|
| [#187](https://github.com/CosmicCuddle/N-Questie/pull/187) private scratch | `768ded74ecdad26a4398caa51bd36a2862cc2b3b` | 73/73 real Lua5.1 and Lua5.4 | 9/9 SUCCESS; 0 artifacts |
| [#189](https://github.com/CosmicCuddle/N-Questie/pull/189) scalar stage bounds | `81ca757d8dc4d501af1fd9312a821ac36af82834` | 94/94 real Lua5.1 and Lua5.4 | 9/9 SUCCESS; 0 artifacts |
| [#191](https://github.com/CosmicCuddle/N-Questie/pull/191) M1/M10 test-only | `d98dedcd876ebd2f844196e3f9b3ca0f439a3807` | 98/98 real Lua5.1 and Lua5.4 | 9/9 SUCCESS; 0 artifacts |
| [#194](https://github.com/CosmicCuddle/N-Questie/pull/194) actual corrections, synthetic faction witness | `42c4ce89da5b449f08d06a04248c1cbd01f0ab02` | 11/11 real Lua5.1 and Lua5.4 — KNOWN UNSAFE, not fixed | 10/10 SUCCESS; 0 artifacts |
| [#196](https://github.com/CosmicCuddle/N-Questie/pull/196) tiny owned-copy feasibility | `6449f59ad439fc16ed99a36b72112bf481df77a6` | 11/11 real Lua5.1 and Lua5.4 — bounded, mixed-epoch remains | 11/11 SUCCESS; 0 artifacts |
| [#198](https://github.com/CosmicCuddle/N-Questie/pull/198) versioned capture toy | `e28e7db7a9d04d081992264c5b21f78fe0ce6155` | 20/20 real Lua5.1 and Lua5.4 — unregistered bypass proven | **11/11 SUCCESS; 0 artifacts** |
| [#199](https://github.com/CosmicCuddle/N-Questie/pull/199) follow-up diagnostics | `d8382bfba81a803c64e0464c1aa6089704d8ee37` | **102/102** real Lua5.1 and Lua5.4 | **9/9 SUCCESS; 0 artifacts** |
| [#201](https://github.com/CosmicCuddle/N-Questie/pull/201) true torn rows, delete, append | `886adc4a1d5d74bb6cc982fc3c7368a3ed760766` | **17/17** known UNSAFE witnesses real Lua5.1/5.4 | **10/10 SUCCESS; 0 artifacts** |
| [#202](https://github.com/CosmicCuddle/N-Questie/pull/202) nine staged simple compound guards | `c9b487fd29eaf32a65025b0fc111b593e5e7240b` | **123/123** real Lua5.1 and Lua5.4 | **9/9 SUCCESS; 0 artifacts** |

**Newest audit:** all **39/39** original-head GitHub Actions for #198/#199/#201/#202 completed SUCCESS; all **39 artifact endpoints fetched, each zero** on 27 October. On any new commit/head rerun, verify again. Earlier comments mentioning “M2 pending” have been superseded. **All these PRs remain DRAFT, UNMERGED.**

## 3. PRIORITY A — fresh peer review and substantive integration research

- [ ] Verify current GitHub `335` SHA, all exact PR heads, Actions statuses, original-branch artifact endpoints and latest [CS02 PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42) messages. Do not conflate test runs on different branch names at same SHA.
- [x] **CS02 #191 M1 and M10 independently killed** on real Lua5.1 and Lua5.4. [Evidence](https://github.com/CosmicCuddle/N-Questie/pull/191#issuecomment-6442766591).
- [x] **CS02 review #199** (completed; [five independent kills](https://github.com/CosmicCuddle/N-Questie/pull/199#issuecomment-6444268186)): separately mutate public `ptrs` diagnostics M10b, `token` / `serial` M10d, and never-begun tokenless forged public token M11. Record exact new tests #99/#100/#101/#102 which kill/survive on BOTH Lua5.1 and Lua5.4; green baseline 102/102 is not an independent mutation kill.
- [x] **CS02 review #202** (completed as **partial coverage**, [8 non-equivalent survivors](https://github.com/CosmicCuddle/N-Questie/pull/202#issuecomment-6444268954); NOT numerically complete): nine named simple compound shapes, exact signed offsets and array counts, malformed/sparse/extra-key pairs, boolean/string/non-numeric, NaN/±infinity, Lua5.1/Lua5.4 divergence, zero/default, genuine GetDBHandle readback, no-stage and SoD byte parity. Document mutant kills/survivors separately from 123/123 baseline.
- [x] **CS02 review #201** (completed as [KNOWN UNSAFE counterexample review](https://github.com/CosmicCuddle/N-Questie/pull/201#issuecomment-6444269806); NOT source safety): challenge 120-row torn source Verify, deleted row error plus DEAD-only cleanup, appended-ID omission, and a future real `RETRY`/refusal contract. Its 17/17 proves known defects, not safety.
- [x] **CS02 review #198** (completed as [writer-bypass falsification](https://github.com/CosmicCuddle/N-Questie/pull/198#issuecomment-6444270637); NOT accepted source authority): registered-writer toy vs direct unregistered bypass and externally mutable owned copy; never mistake a test-supplied `certified=true` flag for a real source-writer authority.
- [ ] Use [current team assignment](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6443771231), check for newer replies, keep reviewer busy with independently useful no-idle work. No merges on “approve with follow-up DRAFT” statements.

## 4. PRIORITY B — genuine source E01–E08 proof (HARD BLOCKED)

- [ ] Enumerate actual base/effective writer surfaces: `QuestieCorrections::_LoadCorrections`, `Initialize` and derived `requiredRaces`, yielding `PreCompile`, `MinimalInit/addOverride`, raw/nested `*Data`, effective `*DataOverrides`, third-party addons, faction cross-character relog.
- [ ] Obtain a truthful global writer exclusion/monotonic **SOURCE** epoch, not a cosmetic counter nor scratch generation serial. Test source A→B→A even when final bytes equal original, before and DURING actual encoding (including NPC/GO/item/loot-related *fictional* relationship-shaped fields).
- [ ] Or design a **coherently captured and privately immutable** owned-generation graph covering four kinds and all effective views, from before first copy read to after last view, with source writer exclusion and native client RAM/GC/frame measurements. Toy #196/#198 demonstrates torn capture and unknown-writer bypass; does not fix them.
- [ ] Improve known-unsafe E01–E08 tests to assert explicit no-RETRY/no-error inside each fixture, and require a future actual fail-closed solution to turn them red. #201's true mid-stream checks should be used as regression baselines, not called acceptance.
- [ ] Do not integrate optional staged compiler into Stage1 until E01–E08 are green on **actual safe behaviour**, independently reviewed.

## 5. PRIORITY C — full codec, real transaction, global pool, persistent recovery

- [x] Stage-only basic scalar guards: #189.
- [x] Stage-only nine **simple** compound pair/array guards: #202 (DRAFT code, dedicated 123/123 and CI green, **independent review pending**).
- [ ] Complex nested numeric and schema shapes: `spawnlist`, `waypointlist`, `questgivers`, `trigger`, `objectives`, `extraobjectives`, polymorphic sub-records, float coords, strings/count limits, sparse/extra table keys and source-null semantics. New isolated source-backed negative tests, fail-closed guard only if proven, no legacy change.
- [ ] Global QuestieStream reuse poisoning after ambiguous `finished()` exception, beyond toy local BUSY lease.
- [ ] Real four-kind writer+reader driver, DEAD-vs-SUSPENDED lifecycle, no Lua5.1 pcall-across-yield, input/source verification and readback of all eight fields; status `SUCCESS/BUSY/RETRY/ERROR/ABORTED_QUARANTINED`.
- [ ] Atomic NO-YIELD in-memory publication of all eight Bin+Ptrs plus metadata/lang/compiledCount/revision ONLY on SUCCESS, no partial edits on abort.
- [ ] SavedVariables DISK/crash/relog consistency and safe generation rollback, separate from Lua-field atomicity. TX01–TX18 remain RED.
- [ ] Native 3.3.5a and server/IP RAM/frame/GC, gameplay, faction cross-relog, rollback and SavedVariables testing, only after owner-specific authorization; backup addon and SavedVariables before any install.

## 6. PRIORITY D — whole quest and other-gate programme

- [ ] G05 effective source, both faction reverse/forward links and preflight; prior #178 remains bounded and does not cover real opposite faction/source after yields.
- [ ] G06 completion cache CLEAR/ADD-only reference #169, #170 comparison only.
- [ ] G07 real item-starter/loader, prior item-only #168 draft.
- [ ] G09 **PRIVATE** historical quest/source/IP/loot/eligibility evidence, not public SQL.
- [ ] G10 investigate full **439 raw records** and classify each independently; distinguish exclusions/placeholder/existing quest. Pilot 1207–1209 stays 0/3 and must NOT replace project plan.
- [ ] G11/G12 remain future client QA and owner-authorised install/release, not tasks to perform silently.

## 7. Operating and safety rules

1. **PUBLIC repo** — never upload private AzerothCore owner SQL, real quest-to-NPC/GO/item/loot, phase/IP mapping or private worksheets.
2. **DRAFT branches only** — fresh branch from verified parent SHA; preserve prior reviewed/CI heads, no force-rewriting, no merges to protected `335`, no ZIP/build artifact upload, tag, install or release without separate approval.
3. **Evidence before green claim** — actual Lua5.1/5.4 both, exact source head, full original-branch Actions, each artifact endpoint, no unstated owner acceptance; failed earlier heads remain logged.
4. **Do real, independently reviewable engineering** rather than only status repetition. Keep docs current in new draft and coordinate Grok with exact head and targeted mutants.
5. **Backups/rollback** — for any future owner-approved local client/server testing, first prepare addon folder, SavedVariables and relevant private database backups; never publish them.
6. **End of each Part38 work pass** — record code/docs PR links, exact heads, real test results, peer feedback, blockers, next action and whole 3/6/3, 439, 0/3 status.

**Part38 opening checkpoint:** `335` unchanged; #198 11/11, #199 9/9, #201 10/10, #202 9/9 original-branch workflows PASS and 0/39 artifacts. #202 is bounded functional staged codec work 123/123 actual Lua5.1/5.4, **not full acceptance**. Source E01–E08, stream pool, commit, disk and native 3.3.5a/IP remain unproven. No merge/release, and owner needs to do nothing for current draft-source work.
