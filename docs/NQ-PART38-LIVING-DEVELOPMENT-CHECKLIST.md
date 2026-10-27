# N-Questie — Part 38 Living Development Checklist

**Opened:** 27 October 2026. **PUBLIC-SAFE — Development DRAFTS / DO NOT MERGE.** 
**Repository:** https://github.com/CosmicCuddle/N-Questie
**Protected `335`:** `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, verified unchanged on 27 October.
**Team:** Owner/maintainer; CosmicScript01 technical project/integration/engineering lead; CosmicScript02 (Grok) independent review via [PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42).

**MANDATORY: Read [the COMPLETE Part37→Part38 handover](HANDOVERS/2026-10-27_PART37_TO_PART38.md) and THIS complete living checklist before changing anything.** Also read [authoritative twelve-gate master](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), [TX01–TX18 blueprint](research/NQ-PART35-GATE08-TRANSACTIONAL-COMPILER-INTEGRATION-BLUEPRINT.md), [source-writer audit E01–E08](research/NQ-PART36-GATE08-SOURCE-WRITER-COVERAGE-AUDIT.md), [owned source decision paper](research/NQ-PART37-GATE08-OWNED-SOURCE-GENERATION-DECISION.md) and [whole 439-record programme](NQ-MISSING-QUEST-COVERAGE-PROGRAMME.md). Dated historical Part37 records remain preserved. Verify all GitHub live data at the new session.

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
- [ ] **CS02 review #199**: separately mutate public `ptrs` diagnostics M10b, `token` / `serial` M10d, and never-begun tokenless forged public token M11. Record exact new tests #99/#100/#101/#102 which kill/survive on BOTH Lua5.1 and Lua5.4; green baseline 102/102 is not an independent mutation kill.
- [ ] **CS02 review #202**: nine named simple compound shapes, exact signed offsets and array counts, malformed/sparse/extra-key pairs, boolean/string/non-numeric, NaN/±infinity, Lua5.1/Lua5.4 divergence, zero/default, genuine GetDBHandle readback, no-stage and SoD byte parity. Document mutant kills/survivors separately from 123/123 baseline.
- [ ] **CS02 review #201**: challenge 120-row torn source Verify, deleted row error plus DEAD-only cleanup, appended-ID omission, and a future real `RETRY`/refusal contract. Its 17/17 proves known defects, not safety.
- [ ] **CS02 review #198**: registered-writer toy vs direct unregistered bypass and externally mutable owned copy; never mistake a test-supplied `certified=true` flag for a real source-writer authority.
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
