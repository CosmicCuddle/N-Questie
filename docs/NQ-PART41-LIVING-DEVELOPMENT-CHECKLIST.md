# N-Questie — Part 41 Living Development Checklist

**Opened:** 28 October 2026 (Europe/London)  
**Repository:** https://github.com/CosmicCuddle/N-Questie  
**Live coordination:** [PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42)  
**Safety:** ALL OPEN PRS ARE DRAFTS. PUBLIC-SAFE TEST/DOCS ONLY; NO MERGE, INSTALL, PACKAGE, TAG OR RELEASE AUTHORISATION.

**Mandatory first reading, in full:**
1. [Complete Part 40 → Part 41 Development Handover](HANDOVERS/2026-10-28_PART40_TO_PART41.md).
2. **This complete Part 41 living checklist.**
3. [Authoritative twelve-gate master checklist](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md) and [Part 40 history](NQ-PART40-LIVING-DEVELOPMENT-CHECKLIST.md).
4. [439 RAW research programme](NQ-MISSING-QUEST-COVERAGE-PROGRAMME.md), Gate08 TX01–TX18 and E01–E08 source-writer designs, and newest reviews in [#42](https://github.com/CosmicCuddle/N-Questie/pull/42).

**Protected `335` last independently checked:** `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. Verify anew; never push it without separate approval.

## 1. Whole-project twelve-gate scoreboard

| Gate | Status | Part 41 responsibility |
|---|---|---|
| G01 | COMPLETE | Research inventory remains traceable |
| G02 | COMPLETE | Pilot owner confirmation recorded; NOT implemented |
| G03 | COMPLETE | Server/client/source registration retained |
| G04 | UNDERWAY | OPT-A manifest/provenance and safe public loader |
| G05 | UNDERWAY | Actual effective NPC/GO/item forward+reverse owners; factions |
| G06 | UNDERWAY | Completion-cache additive update, reset boundaries and native event QA |
| G07 | UNDERWAY | Item start lineage, exact protected-335 source identity, real runtime |
| G08 | UNDERWAY / major RED blockers | Codec/source epochs, global pool, four-kind atomicity and disk recovery |
| G09 | UNDERWAY | Historical/loot/phase/IP eligibility (OWNER-PRIVATE) |
| G10 | TECHNICALLY PENDING | Disposition/approval of full 439 RAW, eligible denominator unknown |
| G11 | TECHNICALLY PENDING | Owner-approved real client/IP gameplay and RAM/GC/frame/relog QA |
| G12 | TECHNICALLY PENDING | Separate merge/install/package/release approval |

**3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING.** No new completion gate claimed. **439 RAW = 12 linked + 418 exploratory + 5 owner-excluded + 3 placeholders + 1 handled overlay**, not 439 approved quests. Pilot **1207–1209 = 0/3 implemented**.

## 2. Mandatory live session start and immutable evidence

- [ ] Refresh protected `335` HEAD and expected SHA. If changed, inspect and report before work.
- [ ] Refresh all open PRs, new comments in #42 and PR-specific CS02 comments. Do not rely on any old "review pending" line without refreshing it.
- [ ] Pin original HEAD SHA, parent/base SHA, draft state, file diff and workflow statuses before touching a branch.
- [ ] Use source GitHub Actions by **exact commit HEAD**, including push runs. Verify actual Lua 5.1.5 and Lua 5.4.6 logs or note version differences if local peer Lua 5.4.7.
- [ ] Inspect **every** original-head workflow artifact endpoint. Avoid PR test-build ZIP side effects and never install or distribute any auto-built ZIP.
- [ ] Preserve all historically failing heads (#240/#241, early #246/#247 workflow errors, #249 unsafe model/test ZIP, #252 count error, #253 stub reset, #258 first two failures). A later green head does not change a historical failure.
- [ ] Make any new engineering changes on fresh isolated draft children. Do not push to frozen independently reviewed source branches.

## 3. Immediate latest PR verification

| PR / kind | Exact HEAD | Latest evidence at 28 Oct handover | Required action |
|---|---|---|---|
| [#260 G07 four-blob guard](https://github.com/CosmicCuddle/N-Questie/pull/260) | `2afeebd06c2909c42966edcad7f66555c561830e` | **7/8 original-head Actions successful**, M2 running; **0/8 artifacts** checked; dedicated 15/15 Lua 5.1.5/5.4.6 success | [ ] Refresh M2/full CI; obtain CS02 exact-head blob mutation review |
| [#261 Part40 docs](https://github.com/CosmicCuddle/N-Questie/pull/261) | `894485e79feb198c6ac0eb91db767c9faec6b2cf` | **7/8 Actions successful**, M2 running; **0/8 artifacts** checked | [ ] Recheck full CI; retain as frozen docs parent |
| [#258 G07 public item lineage](https://github.com/CosmicCuddle/N-Questie/pull/258) | `f6572aca694aaf0992569dc579b33dbd205bf5d8` | **9/9 Actions success**, CS02 scoped verified; zero artifacts; 15/15 synthetic | [x] Preserve frozen parent and earlier two failed heads |
| [#255 G06 cache tests](https://github.com/CosmicCuddle/N-Questie/pull/255) | `a844b7995a071f749162d6578a8cd9349b06bae5` | **8/8 Actions success**, CS02 verified; zero artifacts, 17 tests/20 assertions | [x] Scope accepted as tests only; native client NOT accepted |
| [#256 TX17 model](https://github.com/CosmicCuddle/N-Questie/pull/256) | `e0288ffb90fdbc2cb0e3c473b40aa598f55e1ae9` | **8/8 Actions success**, CS02 verified; zero artifacts, 44 fictional controls | [x] Test peer review recorded; disk correctness NOT accepted |
| [#257 Part40 docs](https://github.com/CosmicCuddle/N-Questie/pull/257) | `e001660b8cce506fa4cc5dfe70a77146201d70d4` | **9/9 Actions success**, zero artifacts | [x] Retain cumulative review record |
| [#259 G07 docs](https://github.com/CosmicCuddle/N-Questie/pull/259) | `77fd6c560a1ed284c47634a197681eebf6e08327` | **9/9 Actions success**, zero artifacts | [x] Retain historic baseline mismatch details |

**Peer-review status:** [CS02 #258 review](https://github.com/CosmicCuddle/N-Questie/pull/258#issuecomment-6456828927) is complete; new [#260 exact-blob challenge request](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6466585466) is OPEN at this checkpoint. Do not report #260 peer-verified until independent mutation evidence arrives. Four-blob identity is not full future source integrity.

## 4. Parallel engineering tasks — advance all underway gates

### G04 OPT-A safe provenance and loader

- [ ] Independently review manifest/source registration, usable public loader limits, unsupported field rejection, reverse capacity and signed bounds; preserve guarded existing-quest behaviour.
- [ ] Identify remaining verified provenance/writer coverage without public leakage of owner-private world data. Test derived/late writers explicitly.
- [ ] Document actionable isolated public-safe test or small proof, not an owner-unauthorised integration patch.

### G05 effective NPC/GO/item ownership and factions

- [ ] Trace real public forward/reverse source registration, override-only records, GO/NPC/item starter paths and faction consistency from exact source.
- [ ] Keep real server source associations, NPC/GO/item/loot/IP gating PRIVATE. Invent fixture IDs only; no invented map coordinates that become user-visible markers.
- [ ] Separate available-quest marker **locatability** from item-start **eligibility** and from already-completed state.

### G06 completion-cache events and daily/weekly resets

- [x] Source-backed [#253](https://github.com/CosmicCuddle/N-Questie/pull/253) and refined [#255](https://github.com/CosmicCuddle/N-Questie/pull/255) real Lua fixture + independent mutation audits completed in narrow scope.
- [ ] Verify actual 3.3.5a `QueryQuestsCompleted` timing and `GetQuestsCompleted(table)` additive semantics with approved client evidence; test whether any stale key is actually observed in UI, not merely hypothetically possible.
- [ ] Confirm native daily/weekly reset boundary, option-off behaviour, relog and repeatables before a patch. Current fixture's WoW APIs/timers are fictional and current in-place cache behaviour is intentionally characterised, NOT a fix.
- [ ] Do not clear users' SavedVariables or abandon legitimate completion history. Any authorised owner test needs a backup and rollback plan.

### G07 item starters and actual 3.3.5a client loading

- [x] [#258](https://github.com/CosmicCuddle/N-Questie/pull/258) bounded source tests; item-only no invented NPC/GO map pin, mixed item+NPC/GO valid markers preserved; 15/15 dual Lua, peer verified.
- [x] [#260](https://github.com/CosmicCuddle/N-Questie/pull/260) initial four-blob test and dedicated actual Lua **15/15 success**; four pinned file SHA-1s compare tree and temporary staged source.
- [ ] Refresh #260 whole-head M2, artifacts and review. Independent tampering checks: alter harmless staged comment, wrong expected blob ID, changed item `startedBy[3]` after bypass, and baseline success. Record surviving/equivalent alterations.
- [ ] Do not claim full `GetQuest` execution: test extracts Starts assignment only. Native item click/start, reverse lookup, owner-private IP phase and actual UI remain unverified.

### G08 four-kind compiler, all-writer source integrity and persistence (RED)

- [x] Independent public simple correction-order guards for ITEM/OBJECT/NPC/QUEST; #246/#247/#252 tested and reviewed with aggregate value digests and mutation witnesses. Excluded complex fields remain unapproved.
- [x] #250/#256 **synthetic** fail-closed restart-selection and aliased slot controls tested/reviewed. Preserve unsafe #249 history and artifact deletion fact.
- [ ] **E01–E08 ALL-WRITER** inventory and genuine A→B→A detection: counters alone do not prove source identity or exclusion of unknown writers. Require real writer ownership and an invalidation/quarantine plan before compile use.
- [ ] **Global QuestieStream** ownership, pooled handle contamination, leases, poison/quarantine and cross-generation cache lifetimes. Previous public known-unsafe examples are not fixes.
- [ ] Full NPC/GO/QUEST/ITEM complex codecs (spawnlist/waypoints/objectives/texts etc.), source-correction precedence and byte-accurate reader parity; distinguish public-only survey from complete server behaviour.
- [ ] **Atomic four-kind memory publication**: all eight Bin/Ptrs outputs plus metadata/locale/revision/count must become visible as a coherent generation; no partial/reentrant reader exposure.
- [ ] **TX01–TX18 / TX17 disk recovery**: a two-Lua-table fixture plus forgeable polynomial checksum is neither authenticated writer protection nor durable WoW SavedVariables journal. Crash/flush/relog and real rollback remain RED until native owner QA.

### G09 private phase/history/loot/IP eligibility

- [ ] Continue research from public evidence without importing the owner's SQL/loot/NPC/item/IP relationships to GitHub, issues or CI logs.
- [ ] Keep doubtful records UNKNOWN/PENDING until approved private proof; do not deduce eligibility from a map icon, absent reverse mapping or synthetic public fixture.

### G10 whole missing-quest programme

- [ ] Continue **all 439 RAW individual records**, maintaining the 12/418/5/3/1 buckets, explicit evidence and disposition.
- [ ] Count only independently eligible, owner-approved per-quest additions, NOT all 439. Pilot 1207–1209 still 0/3 implemented.
- [ ] Preserve existing handled overlay, owner exclusions, placeholders and historical uncertainty; no mass SQL/quest additions.

## 5. Gates G11 and G12 remain on HOLD

- [ ] G11 actual WoW3.3.5a client and Individual Progression phase QA: perform only after appropriate owner permission and privately retained backups of addon + SavedVariables. Require representative NPC/GO/item starters, completion events, UI pins, RAM/GC/frame costs, logout/relog and rollback validation.
- [ ] G12 release: **NEVER merge into 335, install, package, tag or release** without separate explicit owner authorisation and independent review. GitHub auto-artifact publication is not permission to distribute.
- [ ] Preserve historical CI failures rather than rewriting summary claims. Parent source review and documentation branches must stay immutable.

## 6. Carry-forward historical and governance facts

- #249's 38-case green fixture had an **unsafe automatic fallback design**; its inherited 335 test-build ZIP was temporarily uploaded and **then deleted with explicit owner permission**, not silently denied. #250/#256 fix *synthetic* cases only.
- #258 first two failing heads were **test harness and older docs-baseline** issues; protected 335 already contained relevant nil guards. Do not describe them as new source regressions.
- #255 assertion execution counting and #256 named-control census can still be defeated through deliberate coordinated test edits; reviewer vigilance is required.
- Grok uses actual local Lua5.1.5 and sometimes Lua5.4.7 while GitHub CI has actual Lua5.1.5/Lua5.4.6; report versions accurately.
- Public repository must never contain private server SQL, NPC/GO/item/loot/IP relationships, account data or unapproved real client SavedVariables. Never overwrite existing reviewed branches.

## 7. End-of-Part41 handover requirements (maintain during work)

- [ ] Keep this Part41 checklist and authoritative master aligned with actual new source/CI/peer evidence. Timestamp snapshots, retain complete historical failures.
- [ ] At handover time, independently refresh all 12 gate statuses, 439-RAW counts and pilot state.
- [ ] Produce Part 41 → Part 42 **full handover** and a new checklist in a separate docs-only draft PR if the conversation needs a new part.
- [ ] Provide the owner one copy-ready next-chat message with full documents, exact pinned SHA/PR and explicit safety/governance constraints.

**No owner action is needed to continue public-safe isolated research.** If real client/private data becomes essential, explain one step at a time and prepare backups first. Never act beyond separately approved scope.

## 8. Part 41 live engineering checkpoint — 28 October 2026, after handover

**This is a later checkpoint; historical handover rows above remain intentionally unchanged.** The latest independently fetched protected `335` HEAD is still `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.

### Original-head Actions and artifact re-audit

- [x] [#260](https://github.com/CosmicCuddle/N-Questie/pull/260) `2afeebd06c2909c42966edcad7f66555c561830e`: **8/8 exact-original-head Actions SUCCESS** (including the push run and previously running M2); **0/8 individual artifact endpoints**. Dedicated [40671956841](https://github.com/CosmicCuddle/N-Questie/actions/runs/40671956841) source blob tests remain 15/15 on actual Lua 5.1.5 and 5.4.6. **CS02 mutation review remains PENDING** as of this checkpoint, not falsely promoted.
- [x] [#261](https://github.com/CosmicCuddle/N-Questie/pull/261) `894485e79feb198c6ac0eb91db767c9faec6b2cf`: **9/9 original-head Actions SUCCESS** (including TWO push CI runs), **0/9 individual artifact endpoints**.
- [x] [#262](https://github.com/CosmicCuddle/N-Questie/pull/262) `9224b8a7a44e769155d3ae0f8ee48f7d3166f9c2`: **8/8 original-head Actions SUCCESS**, including formerly pending M2 [40673090482](https://github.com/CosmicCuddle/N-Questie/actions/runs/40673090482); **0/8 individual artifact endpoints**.
- [x] All **25 distinct** #260/#261/#262 original-head Actions artifact endpoints were fetched individually (including all push runs), all empty. These are current-status observations, not revisions of the original handover's earlier pending results or a perpetual release safety guarantee.

### New isolated public-source engineering draft

- [x] Created separate **TEST-ONLY DRAFT [#263](https://github.com/CosmicCuddle/N-Questie/pull/263)**, initial frozen HEAD `727631466e4e318f15a36531ce8afa909a78d947`, child of #260 exact HEAD, with 3 new paths (Lua, dedicated workflow, [public-source research note](../docs/research/NQ-PART41-GATE05-PUBLIC-GETITEM-SOURCE-LINEAGE.md)). It executes the real complete protected-335 `QuestieDB:GetItem` function under **invented** QueryItem records; stages exact pinned 335 item/quest/QuestieDB file blob IDs; no source production edit.
- [x] Dedicated [#263 G05 run 40674232076](https://github.com/CosmicCuddle/N-Questie/actions/runs/40674232076) **SUCCESS**, log confirms **Lua 5.1.5 + 5.4.6**, **14/14** actual executed synthetic tests under each. It separates `startQuest` from monster/vendor/GO `Sources` and documents that this `GetItem` code path does not turn `itemDrops` into `Sources` entries. **9/9 original-head artifact endpoints individually fetched EMPTY** at the initial run snapshot.
- [ ] #263 broader exact-head Actions completion, any additional push runs, new artifacts, independent CS02 test mutation review and true source/adapter coverage remain open. Do not claim full CI green or peer VERIFIED from dedicated tests alone.
- [ ] CS02 #260 exact-four-blob mutation challenge: no newly returned PR #260 / #42 review at this checkpoint; retain original open request.
- [ ] Continue G04 OPT-A provenance and effective loader, G05 faction/override-only forward/reverse consistency, G06 native cache events, G07 client item-use interaction, G08 E01–E08 + TX01–TX18, G09 OWNER-PRIVATE phase/history, and 439 individual RAW research; these are still NOT resolved by G05 public fixture.
- [ ] Keep original protected 335 untouched; retain #249 unsafe fixture and owner-approved testbuild deletion history, #258 early failures, no private SQL/IP/loot data, no merge/install/package/tag/release.

**Whole-project scoreboard stays 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING.** RAW research stays 439 (12 linked + 418 exploratory + 5 excluded + 3 placeholders + 1 handled overlay), approved eligible total UNKNOWN; pilot 1207–1209 still **0/3 implemented**. A successfully executed synthetic adapter test is NOT server source/quest approval, full item-start lineage, real client QA, all-writer epoch, atomic four-kind memory or durable SavedVariables recovery.

## 9. Part41 second live checkpoint — 28 October 2026, Gate04 lifecycle and CI

**Append-only dated observation. Earlier snapshot tables and pending statements above remain historical evidence, not overwritten.**

- [x] [#263 Gate05 public GetItem adapter](https://github.com/CosmicCuddle/N-Questie/pull/263) exact original HEAD `727631466e4e318f15a36531ce8afa909a78d947`: **9/9 current original-head Actions SUCCESS** including prior pending M2, **0/9 individual artifact endpoints** checked earlier; dedicated actual Lua 5.1.5 + 5.4.6 **14/14** fictional controls. CS02 independent source mutation review **NOT RETURNED**. Real forward/reverse cross-kind consistency and owner-private eligibility still UNKNOWN.
- [x] [#264 Part41 checklist/master documentation](https://github.com/CosmicCuddle/N-Questie/pull/264) exact original HEAD `85e8eead0cdf0f8f1a2b9a15cd9408ff531fdb27`: **8/8 Actions SUCCESS** including prior pending M2 and both CI triggers; **0/8 individually queried artifacts** from original initial audit. Frozen docs remain untouched.
- [x] NEW isolated [TEST-ONLY DRAFT #265](https://github.com/CosmicCuddle/N-Questie/pull/265) initial HEAD `71b7f95d3d768890673aa3132f774afecd0e3853`, independently based on frozen #260 `2afeebd06c2909c42966edcad7f66555c561830e`, 3 NEW paths only: actual public loader fixture, dedicated workflow, [bounded Gate04 research note](https://github.com/CosmicCuddle/N-Questie/blob/71b7f95d3d768890673aa3132f774afecd0e3853/docs/research/NQ-PART41-GATE04-PUBLIC-MANIFEST-LIFECYCLE.md). Both exact protected-335 public `Compat/NQuestieCustomQuestLoader.lua` and `Compat/NQuestieCustomQuestData.lua` Git blob identities checked against Git tree AND staged temp bytes; no production edits.
- [x] Dedicated original-head [run 40675656894](https://github.com/CosmicCuddle/N-Questie/actions/runs/40675656894) **SUCCESS**, actual Lua **5.1.5 and 5.4.6**, **16/16** invented controls each, including six callback permutations. **TWO controls intentionally reproduce KNOWN UNSAFE source lifecycle states:** an accepted mutable manifest row's requiredLevel can be modified after first approval and emitted without revalidation; deleting an approved starter source can leave emitted forward quest data without its reverse source correction. These are **test-only demonstrations of currently unprotected late writes**, not approvals or confirmed real-client timing. If guarded later, these positive unsafe-witness expectations must be reversed appropriately.
- [x] #265 original-head Actions artifact endpoints **0/9 individually queried** at this dated snapshot; broader Actions **4/9 SUCCESS, other five in progress**, so **do not claim full CI green** until refreshed. No workflow generated any found artifact at this snapshot.
- [ ] Independent CS02 comment-only #265 review AFTER still-open #260 and #263 mutation challenges: registration version gate, unknown field, item-starter rejection, distinct role ordering, and both known-unsafe post-approval modification witnesses. Do not conflate a successful unsafe reproduction with a vulnerability fix.
- [ ] G04 manifest provenance/immutability and all-writer quarantine still RED. G05 effective overrides/faction ownership, G06 actual completion API timing, G07 client item use, G08 E01–E08/QuestieStream/global atomic four-kind/disk restart, G09 owner-private IP/history and G10 439 individual private evidence dispositions all remain outstanding.

**Whole-project status unchanged:** G01–G03 COMPLETE, G04–G09 UNDERWAY, G10–G12 TECHNICALLY PENDING (**3/6/3**). **439 RAW NOT approved additions**: 12 first linked, 418 exploratory, 5 owner excluded, 3 placeholders, 1 already handled; approved eligible number unknown; pilot 1207–1209 remains **0/3 implemented**. No client QA or release authority. Protected `335` last rechecked unchanged at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. No owner-private SQL, NPC/GO/item/loot or IP relationships, merge/install/package/tag/release.

## 10. Part41 third live checkpoint — 28 October 2026, G09/G10 RAW evidence model

**Dated append-only evidence, not a rewrite of earlier historical CI snapshots.** Protected `335` unchanged at independently checked `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.

- [x] [#265 G04 public loader known-unsafe lifecycle](https://github.com/CosmicCuddle/N-Questie/pull/265), exact original HEAD `71b7f95d3d768890673aa3132f774afecd0e3853`: **9/9 original-head Actions SUCCESS** including previous outstanding M2; all **0/9 artifacts individually fetched AFTER completion** including push run; dedicated dual Lua 5.1.5/5.4.6 **16/16**, with two deliberate known-unsafe late-write outcomes. **NOT a fix**, no peer acceptance.
- [x] [#266 prior Part41 docs](https://github.com/CosmicCuddle/N-Questie/pull/266), exact original HEAD `83dd366a2288de444b1ce39d945410ae35bf86e5`: **8/8 Actions SUCCESS**, all **0/8 original-head artifacts individually fetched AFTER completion** (including push). Frozen parent untouched.
- [x] New parallel **TEST-ONLY [#267](https://github.com/CosmicCuddle/N-Questie/pull/267)** exact initial HEAD `b0459e681029f21266bf5067470e20cd77377ca4`, direct isolated child of frozen #266, with THREE NEW paths: fictional [Lua G09/G10 admission test](https://github.com/CosmicCuddle/N-Questie/blob/b0459e681029f21266bf5067470e20cd77377ca4/tests/compat/nq_part41_g10_public_research_admission.lua), dedicated dual-Lua workflow, bounded [research note](https://github.com/CosmicCuddle/N-Questie/blob/b0459e681029f21266bf5067470e20cd77377ca4/docs/research/NQ-PART41-G09-G10-PUBLIC-RAW-ADMISSION-CONTRACT.md). It stages the exact published programme from #266 HEAD with pinned Git blob `86a91568e6619f161552e6682bc6b9eb557d592b`; no private workbook or quest relationships.
- [x] [#267 dedicated run 40677746505](https://github.com/CosmicCuddle/N-Questie/actions/runs/40677746505) **SUCCESS**, actual **Lua 5.1.5 and Lua 5.4.6**, **21/21 fictional controls EACH**. Validates public **12+418+5+3+1=439 RAW**, exclusion/placeholder/overlay no-addition and **0/3 pilot implemented**, plus explicit fictional distinct private source/IP/owner per-quest evidence, independent implementation review, native QA/rollback and separate release gates. **This tests an invented decision contract; it does NOT classify, validate, approve or implement even one private quest.** No private source identities printed.
- [x] #267 original-head artifact endpoints **0/9 individually queried** at initial CI snapshot, including the push-triggered run. Broader **4/9 Actions SUCCESS, five IN PROGRESS** when the snapshot was made; do not claim full-green before refreshing.
- [ ] Independent CS02 challenge for #267 can follow #260, #263, #265 in sequence: mutate/raw→approved bypass, ignore one private evidence gate, permit pilot double-count, allow ownerless implementation, skip G11/G12 QA or release authority; revert all mutants; distinguish blocked unsafe cases from independently evidenced real research dispositions.
- [ ] Public G09/G10 model is NOT a substitute for the owner-private 439 per-record workbook, historical IP eligibility, faction/source/loot evidence or approved 3.3.5a client QA. The eligible count remains **UNKNOWN**. G04 immutable source writer, G05 effective reverse/faction, G06 completion cache native, G07 item-use, G08 all-writer A→B→A/global QuestieStream/atomic four-kind/durable SavedVariables and G11/G12 remain open.

**Whole gate classification unchanged 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING.** 439 RAW = 12 linked + 418 exploratory + 5 excluded + 3 placeholders + 1 handled overlay; no 439-addition promise, no `0/439 implemented` claim, pilot 1207–1209 0/3 implemented. Preserve historical #249 unsafe restart fallback and owner-approved upload/deletion, early #258 failing heads, and every earlier failure. Protected 335 untouched; no private SQL/GO/NPC/item/loot/IP relations, merge, install, package, tag or release.

## 11. Part41 independent CS02 review and source/test closeouts — 28 October 2026

**This entry supersedes only the earlier date-scoped "review pending"/"CI pending" claims; it does not erase the earlier correct-in-time snapshots or historical failing heads.**

- [x] [CS02 exact-head #260 G07 four-blob peer review](https://github.com/CosmicCuddle/N-Questie/pull/260#issuecomment-6467378193): **VERIFIED in scoped CI-content and fictional lineage**, 4/4 requested mutation classes killed; wrong source-blob pins and staged-content changes fail, amended `startedBy[3]` route reaches named `G07_ITEM_ONLY_FORWARD_MAPPING` when the local gate is deliberately bypassed. Local reviewer Lua 5.1.5/5.4.7; runner Lua 5.1.5/5.4.6. Independently refreshed original HEAD `2afeebd06c2909c42966edcad7f66555c561830e`: **10/10 Actions SUCCESS, 0/10 artifact endpoints**, including three push runs. Low: CI pin-failure diagnostics are unnamed, direct Lua test without CI blob gates does not authenticate staged sources.
- [x] [CS02 exact-head #263 G05 real GetItem adapter review](https://github.com/CosmicCuddle/N-Questie/pull/263#issuecomment-6467384563): **VERIFIED in scope**, 31/35 mutants killed; 3 equivalent and one J1 extraction-boundary widening observation. Full source content pin catches source-file edits in workflow; extractor's later `---@param questId number` marker can otherwise widen chunk silently under bypass. Real 5.1.5 and local 5.4.7, pristine 14/14. Original head `727631466e4e318f15a36531ce8afa909a78d947` 9/9 Actions SUCCESS, 0/9 individually checked artifacts. Does NOT prove actual reciprocal item/quest owners or native item-start.
- [x] [CS02 exact-head #265 G04 loader lifecycle review](https://github.com/CosmicCuddle/N-Questie/pull/265#issuecomment-6467395633): **VERIFIED scoped known-unsafe reproduction**, all targeted loader/blob mutations killed, pristine 16/16; independently refreshed original HEAD `71b7f95d3d768890673aa3132f774afecd0e3853` **9/9 SUCCESS, 0/9 artifacts**. Low residuals: six callback-order slots might contain a duplicate, witness W4 fabricated reverse source and actual W3 fix share a failure reason, initial V1 u8 range and V2 sparse-list changes were not covered. These are **fixture gaps**, not production fixes or real-client known-writer proof.
- [x] NEW isolated [TEST-ONLY #270](https://github.com/CosmicCuddle/N-Questie/pull/270) exact initial HEAD `a268cc9280b725e8871a00c84dedb02c4ffecc96`, direct child of **frozen reviewed #265**. Three updated test/workflow/[research](https://github.com/CosmicCuddle/N-Questie/blob/a268cc9280b725e8871a00c84dedb02c4ffecc96/docs/research/NQ-PART41-GATE04-PUBLIC-MANIFEST-LIFECYCLE.md) files ONLY; six callback permutations now checked distinct; new initial invalid `requiredLevel=300` and sparse NPC starter controls; W1 named expected-unsafe-fix failure; distinct W3 real forward refusal vs W4 fabricated reverse failure. Dedicated [run 40678739486](https://github.com/CosmicCuddle/N-Questie/actions/runs/40678739486) **SUCCESS actual Lua 5.1.5 and 5.4.6, 18/18 fictional controls EACH**, two final **KNOWN UNSAFE** witnesses deliberately still reproduce. Initial **4/9 broader original-head Actions SUCCESS, five in progress, 0/9 artifacts individually checked**; peer review of #270 pending. Not a production loader patch.
- [x] [#267 G09/G10 439-RAW test-only](https://github.com/CosmicCuddle/N-Questie/pull/267) original HEAD `b0459e681029f21266bf5067470e20cd77377ca4`: **9/9 original-head Actions SUCCESS, 0/9 individual artifact endpoints rechecked AFTER final M2**; dedicated public-only **21/21 on Lua 5.1.5/5.4.6**. Independent CS02 fiction-model mutation challenge still pending; no private quest dispositions have been inferred or approved.
- [ ] Docs-only [#268](https://github.com/CosmicCuddle/N-Questie/pull/268) initial head `7bb2461e65003f345b3602b9f548a9e5fd9db5f9`: **7/9 Actions SUCCESS, M2 plus later push CI in progress, 0/9 current artifact endpoints**. Docs-only [#269](https://github.com/CosmicCuddle/N-Questie/pull/269) initial `c9f5cbcdca22287a9741593ce95fb4a1b52f85b0` repairs the cross-branch research/test links with immutable full URLs: **7/8 Actions SUCCESS, M2 running, 0/8 endpoints** at audit. Recheck later without changing frozen drafts.
- [ ] Continue G04 true all-writer source exclusion and real manifest snapshot, G05 actual effective forward/reverse faction integrity, G06 native completed-query/reset, G07 real item use/client, G08 E01–E08/QuestieStream/four-kind atomic in-RAM and disk SavedVariables restart, G09 owner-private history/IP, and G10 per-record 439 dispositions. None are accepted from green invented fixtures.

**Whole twelve-gate state remains 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; 439 RAW = 12+418+5+3+1, NOT 439 approved additions; eligible denominator unknown; pilot 1207–1209 0/3 implemented.** Protected `335` independently unchanged at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. Preserve unsafe #249 and deleted PR testbuild history and early failing heads. No merge/install/package/tag/release, private owner SQL/NPC/GO/item/loot/IP data or real SavedVariables publication.

## 12. Part41 fourth live checkpoint — G08 source-backed compiler negative cases

**28 October 2026; append-only.** Earlier snapshot tables and pending labels above are historical statements and remain intact.

- [x] [#271 previous docs-only peer-review and Gate10 ledger](https://github.com/CosmicCuddle/N-Questie/pull/271), exact frozen HEAD `c5401d816b4ddee8a8bbb11022f41d901bee3073`: **9/9 original-head Actions SUCCESS**, including extra push CI, **0/9 individual artifact endpoints rechecked**. No merge.
- [x] New isolated **TEST-ONLY [#272](https://github.com/CosmicCuddle/N-Questie/pull/272)** initial HEAD `5a8db6bbabce1840e1ff0befc941ecf442cf6f64`, direct child of frozen #271, exactly THREE NEW test/workflow/[research](https://github.com/CosmicCuddle/N-Questie/blob/5a8db6bbabce1840e1ff0befc941ecf442cf6f64/docs/research/NQ-PART41-G08-EXACT-COMPILER-FAILURE-PROPAGATION.md) files. Source is actual unmodified public protected-`335` `Database/compiler.lua` blob `abba0249f44d14711dbdd46bbde969ccffbc2963` and `Modules/QuestieInit.lua` blob `22fffa1b1bbeb81ba067f34151949c0938a316c1`, both independently pinned by commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, tree ID and staged bytes.
- [x] Dedicated [#272 run 40680255205](https://github.com/CosmicCuddle/N-Questie/actions/runs/40680255205) **SUCCESS real Lua 5.1.5 AND 5.4.6, 12/12 fictional controls EACH**, executing the **exact** `QuestieDBCompiler:CompileTableCoroutine` and `Compile` functions with an invented four-kind database and deliberately minimal fake stream; only checks the true source text of the Stage1 revision assignment, **not** whole Stage1 runtime.
- [x] Three **KNOWN UNSAFE** negative reproductions from actual compiler functions: (1) one invalid fictional object type returns early, leaves object old, other kinds published, yet outer `Compile` marks compiled and increments metadata; (2) injected quest writer exception leaves earlier kinds published, quest stream unfinished and `_isCompiling` sticky, suppressing a retry; (3) injected item pointer encoding error publishes new `itemBin` before `itemPtrs`, leaving a mismatched half-pair and stale metadata. Healthy fictional four-kind baseline also tested. Passing known-unsafe controls **does not fix any bug** or prove real client timing/codec pool behaviour.
- [x] At initial observation #272 broad original-head Actions **4/9 SUCCESS, five in progress, no failure**, all **0/9 individually checked artifact endpoints including push**. Refresh exact head before any full-green claim. CS02 independent mutation review **NOT RETURNED**; queue after #267, #270.
- [ ] Gate08 remains **RED** for E01–E08 all-writer source epoch and A→B→A, global QuestieStream actual pool and reader/writer lease quarantine, actual codec/serialization limits, all-four-kind eight-field plus metadata no-yield atomic publication and genuine SavedVariables crash/relog recovery. Do not infer any of these from the minimal stream fixture or static Stage1 source anchor.

**Whole twelve-gate classification unchanged 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**. 439 RAW investigations = 12 linked + 418 exploratory + 5 owner-excluded + 3 placeholders + 1 already handled; approved eligible count unknown, pilot 1207–1209 0/3 implemented. Protected `335` unchanged. No owner-private SQL/NPC/GO/item/loot/IP data or SavedVariables committed, and no merge, install, package, tag or release.

## 13. Part41 real QuestieStream pool lifetime checkpoint — 28 October 2026

**Append-only dated record. Preserve the earlier failed exact HEAD and all historical pending/failure snapshots above.**

- [x] **#272 source-backed real compiler failure witness** initial head `5a8db6bbabce1840e1ff0befc941ecf442cf6f64`: **10/10 original-head GitHub Actions SUCCESS**, including two push CI runs, **0/10 artifact endpoints individually checked AFTER final runs**. Actual pinned public compiler dual Lua 5.1.5/5.4.6 **12/12** negative controls, three deliberately KNOWN UNSAFE behaviours, NOT production fixes or actual 3.3.5a gameplay.
- [x] **#273 docs ledger** frozen head `eb7afc2134cc870d1e921080d3e10d7a5d11c0bc`: **8/9 Actions SUCCESS**, latest additional push CI **in progress**, **0/9 artifact endpoints individually checked at this snapshot**; later status must be rechecked.
- [x] **[TEST-ONLY #274](https://github.com/CosmicCuddle/N-Questie/pull/274)** initial immutable head `55d6accc1ebfede4e0d6141abfdb4943cc50c655`, isolated child of frozen #272, three new real-stream fixture/workflow/[research](https://github.com/CosmicCuddle/N-Questie/blob/55d6accc1ebfede4e0d6141abfdb4943cc50c655/docs/research/NQ-PART41-GATE08-REAL-STREAM-POOL-OWNERSHIP-WITNESS.md) paths. Dedicated original-head [40681430799](https://github.com/CosmicCuddle/N-Questie/actions/runs/40681430799) **FAILED before any stream-ownership assertion** with `attempt to call global 'tremove' (a nil value)` (plain PUC Lua fixture missing WoW's `tremove` global). **Not** a protected-335 loader bug, production regression or a test of the intended witness. Historical failure retained, not reclassified or deleted. Exact-head status **9/11 Actions SUCCESS, 1 dedicated FAILURE and M2 running**, **0/11 individually audited artifact endpoints**, including push.
- [x] **[TEST-ONLY correction child #275](https://github.com/CosmicCuddle/N-Questie/pull/275)** exact initial head `affc24ce49e39e4d8308fc583ce148796d56d311`, direct child of frozen failed #274, **ONE Lua fixture file changed** to supply `tremove=table.remove` in the isolated environment. The **complete unmodified** public protected-335 `Modules/QuestieStream.lua` blob `1819aeea11148eae0742810dbd2338410edda238` and `Database/compiler.lua` blob `abba0249f44d14711dbdd46bbde969ccffbc2963` are staged with independent Git tree and staged-byte hash verification; no production modifications.
- [x] Dedicated corrected original-head [40681668438](https://github.com/CosmicCuddle/N-Questie/actions/runs/40681668438) **SUCCESS** with actual **Lua 5.1.5 and 5.4.6, 14/14 fictional controls EACH**. The tests run the actual entire global `QuestieStream.lua`, and deliberately reproduce **KNOWN UNSAFE caller-violation schedules**: stale alias writes after finished/reuse; double `finished` enqueues one table twice for two active borrowers; premature return of a suspended coroutine's stream enables post-resume contamination. Healthy borrowed streams are isolated if not returned prematurely. These scenarios are **NOT established as actual normal gameplay/Questie compiler calls**.
- [x] #275 broader original-head Actions **9/10 SUCCESS, M2 running**, **0/10 individually checked artifact endpoints including push**, no failures at this snapshot. CS02 independent #275 exact-head mutation review NOT returned; the prior assigned queue is **#267 → #270 → #272 before optional #275**.
- [ ] G08 all-writer monotonic E01–E08/A→B→A proof, real `GetDBHandle` global reader/owner capture, unauthorized return exclusion, source snapshot, actual compiler and QuestieStream integration, eight `Bin`+`Ptrs` all-kind no-yield atomic transaction, actual SavedVariables torn disk crash/relog, live WoW 3.3.5a IP and GC/frame acceptance all remain RED. No global `GetStream` monkey-patching or inferred safe quarantine.

**No gate promotion: G01–G03 COMPLETE, G04–G09 UNDERWAY, G10–G12 TECHNICALLY PENDING (3/6/3)**. 439 RAW (12 linked + 418 exploratory + 5 excluded + 3 placeholders + 1 handled) not approved; eligible denominator unknown, pilot 1207–1209 **0/3 implemented**. Protected `335` `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` unchanged. Historical #249 unsafe fallback and uploaded/deleted test package preserved. No private SQL/NPC/GO/item/loot/IP or SavedVariables published; no merge/install/package/tag/release.

## 14. Part41 → Part42 COMPLETE documentation handover — 28 October 2026

**Append-only closeout**. New separate public-safe DOCS-ONLY branch `docs/part41-to-part42-full-handover-20261028-cs01`, isolated direct child of frozen **[#276](https://github.com/CosmicCuddle/N-Questie/pull/276)** original exact HEAD `f3159b764e5ad473a0c2402da2532d7486a079a3`. [Complete Part41→42 handover](HANDOVERS/2026-10-28_PART41_TO_PART42.md) and [new Part42 living checklist](NQ-PART42-LIVING-DEVELOPMENT-CHECKLIST.md) were added as NEW documents; authoritative master receives matching pointer. This branch's PR/CI is pending at the point of document creation. Frozen #276 and all other review heads remain untouched.

**Independently refreshed original-head evidence:** #267 9/9 Actions SUCCESS 0/9 artifacts; #270 9/9 0/9; #272 10/10 0/10; #273 9/9 0/9; **historically failed #274 10/11 success, one dedicated `40681430799` FAILED on missing plain-Lua WoW `tremove` global, 0/11 artifacts**; corrected one-test-file child #275 10/10 SUCCESS 0/10 artifacts, dedicated entire real pinned `QuestieStream.lua` **14/14 on Lua 5.1.5 and 5.4.6**. Its success does not retroactively erase #274. #276 frozen exact original `f3159b764e5ad473a0c2402da2532d7486a079a3`: **7/8 Actions SUCCESS and M2 `40682287019` IN PROGRESS, 0/8 artifacts individually queried**, snapshot must be refreshed next session.

**CS02 queue PENDING in order:** #267 public fictional 439-RAW approval refusal; #270 G04 callback order/known-unsafe fixes; #272 true pinned compiler false-success/sticky stream/half pair; optional #275 complete stream module double return/stale alias/prematurely suspended lease. Earlier scoped independent reviews #260, #263, #265 complete and not to be repeated. The last [coordination thread #6468117904](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6468117904) contains full instructions.

**All 12 gates unchanged: 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING.** 439 RAW investigation records (12+418+5+3+1), approved eligible count UNKNOWN, pilot 1207–1209 **0/3 implemented**. G08 all-writer E01–E08 A→B→A, actual global pool leases and readback, coherent four-kind eight binary/pointer + metadata memory publication and genuine SavedVariables disk crash/relog remain RED. Preserved #249 historical unsafe fallback/test ZIP owner-approved deletion and early #258 failing test heads. Protected `335` verified unchanged `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. NO production changes, owner-private SQL/NPC/GO/item/loot/IP mappings, SavedVariables, merge/install/package/tag/release. Continue in Part42 via frozen handover and both checklists.
