# N-Questie — Part 40 Living Development Checklist

**Opened:** 27 October 2026 (Europe/London). **PUBLIC-SAFE DRAFT ENGINEERING ONLY — NO PRODUCTION MERGE/INSTALL/RELEASE APPROVAL.**

**Repository:** https://github.com/CosmicCuddle/N-Questie

**Start by reading BOTH documents FULLY:**
1. [Complete Part39 → Part40 Development Handover](HANDOVERS/2026-10-27_PART39_TO_PART40.md).
2. This entire Part40 Living Development Checklist.

Then inspect [authoritative twelve-gate master](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), [Part39 historical checklist](NQ-PART39-LIVING-DEVELOPMENT-CHECKLIST.md), [439-record programme](NQ-MISSING-QUEST-COVERAGE-PROGRAMME.md), compiler TX01–TX18 blueprint, source-writer E01–E08 audit and live [team coordination #42](https://github.com/CosmicCuddle/N-Questie/pull/42).

**Protected branch 335:** 8b23c6e2cfa00bb81cb26d40c44fef154e9e0070 on Part40 creation. Verify LIVE before changing anything.

## 1. Whole twelve-gate scoreboard — NEVER reduce project to G08 or the pilot

| Gate | Current status | Focus |
|---|---|---|
| G01 | COMPLETE | Raw research inventory |
| G02 | COMPLETE | Pilot owner confirmation |
| G03 | COMPLETE | Pinned server/client/source registration |
| G04 | UNDERWAY | OPT-A manifest/provenance/safe loader |
| G05 | UNDERWAY | Effective forward/reverse NPC/GO/item quest ownership, faction consistency |
| G06 | UNDERWAY | Quest completion-cache CLEAR/ADD correctness |
| G07 | UNDERWAY | Item-starter and 3.3.5a runtime loader |
| G08 | UNDERWAY, MAJOR BLOCKER | Codec/source epochs/global pool/four-kind atomicity/SavedVariables |
| G09 | UNDERWAY | Private historical/loot/phase/IP eligibility proof |
| G10 | TECHNICALLY PENDING | Eligible per-quest additions from complete 439 RAW research universe |
| G11 | TECHNICALLY PENDING | Actual client/IP QA, RAM/GC/frame, relog and rollback |
| G12 | TECHNICALLY PENDING | Separate owner-authorised integration/install/packaging/tag/release |

**Status = 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING.**

**439 RAW ≠ 439 to implement.** Audited buckets: 12 source-linked, 418 exploratory, 5 owner-excluded, 3 placeholders, 1 existing overlay. Eligible denominator UNKNOWN. Pilot quests 1207/1208/1209 are **0/3 implemented**, not the complete programme. NEVER commit private source NPC/GO/item/loot/IP relationships.

## 2. Mandatory live Part40 opening routine

- [ ] Verify protected 335 SHA. Stop if unexpected movement.
- [ ] Read and understand BOTH Part40 documents fully; revisit authoritative master and previous Part39 history. Avoid acting from summary snippets only.
- [ ] Refresh latest GitHub open PRs and all [#42](https://github.com/CosmicCuddle/N-Questie/pull/42) Grok collaboration comments. Other independent drafts may now exist.
- [ ] Pin exact HEAD/parent/draft state/file paths for each target before any edit. **Never push to reviewed frozen heads.**
- [ ] Query **original HEAD** Actions by SHA, not only GitHub's test-merge synthetic SHA. Read actual real Lua5.1 and Lua5.4 logs; verify the completion conclusion of every workflow and ALL artifact endpoints (including late extra push runs).
- [ ] Preserve every previously failed head: #240 hooksecurefunc; #241 l10n fixture/overlay timeout; earlier #226 interim YAML. Do not reinterpret historical red runs because a later child succeeds.

## 3. Most recent independently verified Part39 test-only checkpoint

All unmerged DRAFT, all real Lua5.1.5 and Lua5.4.6 test evidence as scoped:

| Topic | Reviewed frozen PR HEAD | Original-head CI at handover |
|---|---|---|
| Guarded public ITEM correction order | [#232](https://github.com/CosmicCuddle/N-Questie/pull/232) b0b5703eab88befd2c4ff2201f4874906a6e283c | 12/12 success, zero artifacts |
| Guarded public OBJECT correction order | [#235](https://github.com/CosmicCuddle/N-Questie/pull/235) fc7371172bdac0615728cb78b21a530f363e938d | 12/12 success, zero artifacts |
| Guarded public NPC correction order | [#238](https://github.com/CosmicCuddle/N-Questie/pull/238) 6647437079757bb4a52e46528c66eb639862e56a | **14/14 success, 0/14 artifact endpoints re-fetched** |
| Guarded public QUEST correction order | [#243](https://github.com/CosmicCuddle/N-Questie/pull/243) 547888b5932259892ddbc2fcbb63b9949f464b38 | **14/14 success, 0/14 artifact endpoints re-fetched** |
| Part39 docs master | [#244](https://github.com/CosmicCuddle/N-Questie/pull/244) f45b259741dfe7a458251ac0dec25d16ef578e5f | **7/7 success, 0/7 artifact endpoints re-fetched** |

All four kinds report **zero reordered and zero malformed simple compound fields** in the surveyed PUBLIC WotLK correction projections on both Lua versions. They DO NOT prove whole four-kind production-safe compiled output, unknown private writers, full complex codec support, atomic publish, or real client safety.

- Public ITEM each faction: 36,767 rows; 28,755 simple fields; 28,409 ordered, 346 empty; 1,432 manual correction writes; 11 actual simple override fields.
- Public OBJECT each faction: 13,043 rows; 803 fields; 789 ordered, 14 empty; 904 correction writes; **0** real simple overrides.
- Public NPC each faction: 29,615 rows; 6,023 fields all ordered, 0 empty; 2,627 manual writes, 84 WotLK automatics, 25/24 faction writes; **0** real simple overrides.
- Public QUEST per faction: 9,158 rows; Alliance 15,266 fields/13,360 ordered; Horde 15,267/13,361; 1,906 empty each; generated Classic reputation 4,254 writes and manual 7,603; ONE genuine Horde simple override. Simple families u8u24array / u12pair / s24pair / u8s24pairs only.

**Excluded** from those surveys: NPC/object spawnlist/waypointlist and full questgivers, objective lists, triggers, texts, extraObjectives, complex byte-accurate reader semantics, derived cross-kind faction updates, 335 Compat.LoadCorrections, unregistered/late source writers, real owner IP data and native client.

## 4. Highest-priority NEW Part40 test-only engineering — CS02 mutations

Independent reviewed exact-head findings:
- [CS02 NPC #238 review](https://github.com/CosmicCuddle/N-Questie/pull/238#issuecomment-6452407306): N2c a legitimate dense-array element drop with same number of fields is NOT caught by count pin; N3d call-site maps actual reordered→ordered and survives even with an injected reorder. Four other apparent survivors are equivalent in the CURRENT simple-field corpus, not guarantees for full data. All prior mutations reverted.
- [CS02 QUEST #243 review](https://github.com/CosmicCuddle/N-Questie/pull/243#issuecomment-6452407815): Q3c generated Classic reputation correction moved AFTER WotLK manual correction changes **two actual effective reward values per faction**, with unchanged count pins. Q8h lower s24pair bound and Q8i upper u12pair bound widened also survive because fixture lacks boundary witnesses. Missing quest index side-effect mutants Q2a/b/c are equivalent for this limited four-family audit, not untested production semantics. All mutations reverted.

**A. NPC guard next safe child** (make a NEW branch from #238 exact 66474370, not edit #238):
- [ ] Create canonical, **order-independent with respect to hash-map traversal** and deterministic across Lua5.1/5.4, PUBLIC aggregate simple-field **value digest per faction**. Sort numeric record keys + compiler field keys and encode values in a stable locale-independent representation. Print digest only (not IDs/relationships). Consider hash collisions and exact snapshot validation. Must be mutation-sensitive to N2c changing one dense item without field-count drift.
- [ ] Add a shared fixture to exercise the **real effective lookup → classify → stats accumulation → ORDER_BLOCKER** path; a classifier-only positive test does not kill N3d. Both Lua versions must reject the injected reversed 2–4-key array.
- [ ] Separately test real WotLK auto layer interactions; CS02 established the 84 automatic writes touch only excluded spawns, so skip/move automatics may be equivalent in the audited simple arrays. Never misrepresent counts as byte-exact NPC correction protection.
- [ ] Send CS02 exact-head mutation test request and record CIs/artifact endpoints; guard against leaking actual source relationships in Actions output.

**B. QUEST guard next safe child** (make a NEW branch from #243 exact 547888b5, not edit #243):
- [ ] Add a **canonical value digest per faction** for public four simple codec families, sorted ids/fields/array indices with stable signed pair encoding. It must detect Q3c's two changed reputation rewards even when counts match, without printing IDs or values. Preserve one actual Horde override and 23 empty-pair clears.
- [ ] Add fictional exact boundary pins: **u12 4095 accepted, 4096 refused**; **s24 -8388608 accepted, -8388609 refused**; ensure correct upper bounds, pair arity and legitimate negative reputation values remain accepted. Kill widened-bound Q8h/Q8i independently under both Lua VMs.
- [ ] Avoid reversed explicit-key constructors of length 5/6 as cross-Lua order witnesses; use verified 2–4 lengths and both real interpreters.
- [ ] Ask CS02 to rerun/revert the exact mutants; no acceptance before actual dual Lua and independent review.

**These test improvements are NOT a production solution to G08 source security.** Do not add a toy source-change counter or a final-value fingerprint as a substitute for unknown writer exclusion.

## 5. G08 substantive production safety still RED

- [ ] Genuine all-writer authenticated source epoch, immutable snapshot or enforced exclusion; detect source A→B→A including S7 non-name field. E01–E08 remain RED. [#224](https://github.com/CosmicCuddle/N-Questie/pull/224) and [#229](https://github.com/CosmicCuddle/N-Questie/pull/229) separately change the same fixture; future combination must preserve both S7 and independent per-witness outcome maps.
- [ ] Real global QuestieStream lease/generation quarantine that keeps healthy raw pooled reuse while preventing post-Finish aliases. [CS02 #227](https://github.com/CosmicCuddle/N-Questie/pull/227) 20/20 KNOWN UNSAFE on real compiler means defect reproduced, not fixed.
- [ ] Four-kind 8-field (NPC/Object/Quest/Item Bin+Ptrs) atomic **in-memory** commit including metadata, revision and locale, only after source-consistent verified attempt and all writers DEAD. Transaction TX01–TX18 and typed clean outcomes remain unaccepted.
- [ ] Separate **SavedVariables ON-DISK** crash/relog/restart recovery and rollback across generations, with native client tests and owner-side backups. RAM atomicity alone is insufficient.
- [ ] Complex codec types, stage-only pairs() ordering compatibility, real 335 Compat writers and actual reader byte parity beyond nine simple codecs remain unaccepted.

## 6. Remaining gates and 439 RAW research — active parallel obligations

- [ ] G04 OPT-A safe provenance/manifests/loading; G05 NPC/GO/item effective ownership and faction consistency; G06 completion cache; G07 actual item starter loading; G09 historical/IP/loot eligibility. Keep user-private details in private local evidence ONLY.
- [ ] G10 research all 439 RAW individually: 12 linked candidates, 418 exploratory, 5 excluded, 3 placeholders, 1 already handled. Document dispositions, not mass insertions. Eligible denominator unknown; pilot 1207–1209 still 0/3 implemented.
- [ ] G11 native WoW 3.3.5a/IP playability, actual objectives, quest markers, class/faction/source phases, performance, relog/SavedVariables and rollback needs separate authorisation and backup steps.
- [ ] G12 no integration merge, install, zip, tag or release without separate explicit owner approval and peer acceptance.

## 7. Governance and end-of-Part40 checkpoint rules

1. The GitHub repository is PUBLIC. NEVER publish private AzerothCore SQL, owner NPC/GO/item/loot relationships, IP/class/faction phase, real user data, audit worksheets, or private server log excerpts.
2. Work on NEW isolated public-safe DRAFT branches/PRs from exact frozen parents; never overwrite protected 335 or independently reviewed heads. Never merge, force-push, tag, release, package or install by default.
3. Distinguish **KNOWN UNSAFE reproduction** from defect remediation. Treat all upstream/intermediate failed attempts as historically failed; record final original-head CI only on its exact SHA. Test BOTH Lua5.1 and 5.4.
4. CS01 coordinates via [#42](https://github.com/CosmicCuddle/N-Questie/pull/42), requests independent nonduplicated CS02 reviews, documents all twelve gates in both this living checklist and the [master](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md).
5. At every check-in record protected SHA, current PR heads, actual Lua logs, full Actions and uploaded artifact counts, mutation outcomes, blockers, 3/6/3 and 439 RAW/0-of-3 pilot. Keep previous Part39 evidence and failures unchanged.
6. Owner is not required to perform routine synthetic public-safe draft work. For separately authorised owner-side installation/testing, give short dyslexia-friendly steps and insist on addon, SavedVariables and appropriate database backups FIRST, stored PRIVATE.

**Part40 beginning state:** Public four-kind limited simple-codec surveys independently reviewed with targeted mutation gaps; G08 still RED; score 3/6/3; 439 RAW, pilot 0/3; protected 335 unchanged; no production release consent. Independently refresh GitHub LIVE before engineering.


## 8. Live Part40 engineering checkpoint — 27 October 2026 (after startup)

**This is an additive snapshot, not a revision of Part39 evidence and not production acceptance.**

- [x] Both mandatory handover/checklist documents inspected; the 12-gate master, 439-record programme, historical Part39 ledger, TX01–TX18 blueprint, E01–E08 source-writer audit, owned-generation decision and latest Grok reviews consulted.
- [x] Protected `335` independently read unchanged at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.
- [x] Frozen peer-reviewed parents preserved: #238 NPC `6647437079757bb4a52e46528c66eb639862e56a`; #243 QUEST `547888b5932259892ddbc2fcbb63b9949f464b38`.
- [x] New **test-only DRAFT #246**, separate child of #238, adds sorted, length-delimited public aggregate value digest for both faction effective simple arrays plus **one injected reversed constructor through the same effective→classify→stats→ORDER_BLOCKER path**. CS02 targets N2c, N3d and N3d+real-reversal; no production change.
- [x] New **test-only DRAFT #247**, separate child of #243, adds sorted public value digest across four simple compound families; six invented boundary controls for u12 4095/4096 and signed s24 −8388608/−8388609, 8388607/8388608 (20 total). CS02 targets Q3c, Q8h, Q8i; no production change.
- [x] CS02 coordination request posted in [#42](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6453160696): wait for finalized digest pins and original-head dual-Lua CI before independent *reverted* mutation review. Do not overwrite source branches.
- [x] Initial CI-file edit on each NEW child produced **historical invalid workflow** first attempt (GitHub push checks: NPC run `40580944817` FAIL; quest run `40580951574` FAIL). Corrected *only new test-only branches*, preserving both failed runs in history. Repaired heads: NPC `b2325fa84d2275acab57b03c6e2ea8956f639059`; quest `4bc9dcc1c1cd91854d531ba7681aa4bbaa3ab87c`. Corrected workflow syntax re-read; their original-head complete CI/results/artifacts **still PENDING at this dated checkpoint**, not green.
- [ ] Require observed Lua5.1/5.4 identical per-faction hash outputs, then **pin exact expected hashes** in both Lua audits and CI, prove each named mutation fails, re-query all run/artifact endpoints and have CS02 independently review at final exact heads. Aggregate dual polynomial hashes are deterministic test witnesses subject to collisions, **never** an authenticated all-writer epoch or source snapshot proof.
- [ ] Keep G08 source-writer A→B→A/E01–E08, global QuestieStream lifetime quarantine, verified four-kind atomic eight-field + metadata publish, real SavedVariables crash/restart recovery and actual 3.3.5a client/Individual Progression measurements **RED**.
- [ ] Advance G04–G07 and G09 separately against public and owner-private evidence; G10 full 439 RAW triage remains required, no assumed eligible denominator or new quest additions. G11 client QA and G12 integration/release require separate owner approval.

**Whole-programme state unchanged:** 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; 439 RAW (12 linked + 418 exploratory + 5 owner-excluded + 3 placeholders + 1 existing overlay), pilot 1207–1209 **0/3 implemented**. No merge, install, package, tag, release, protected-branch push or private source publication.


## 9. Parallel public-code reconnaissance for G04–G07/G09 (no status promotion)

**Source at protected `335`, verified 27 October 2026; findings are test plans, NOT owner-private eligibility facts or native client results.**

- **G04 — loader manifest/provenance:** [Guarded custom-loader contract](NQ-CUSTOM-LOADER-SAFETY-DRAFT.md) documents public existing-quest safeguards: supported/unsupported fields, 255-entry reverse capacity and the `zoneOrSort` signed bound. Those are bounded source/fixture protections; full OPT-A provenance and real approved quest relationships are still missing.
- **G05 — effective owners:** separate [synthetic available starter marker contract](../tests/compat/nq_available_starter_marker_contract.lua) deliberately distinguishes a resolvable NPC/GO from a locatable one. Real source-linked forward↔reverse owners, cross-faction override-only records, late writers and Individual Progression restrictions remain unverified. Do not make markers from invented coordinates.
- **G06 — completion-cache CLEAR/ADD:** protected [`QuestieQuest.lua`](../Modules/Quest/QuestieQuest.lua) initialization sets `Questie.db.char.complete` to `QuestieCompat.GetQuestsCompleted()`; [`Compat.lua`](../Compat/Compat.lua) invokes `QueryQuestsCompleted()`, then the `QUEST_QUERY_COMPLETE` event updates the same cache and separately applies repeatable, daily and weekly rules. **Next test**: fictional delayed-event and repeatable/reset CLEAR/ADD sequences, with no false completion from stale entries. This is an asynchronous ordering boundary to test, **not a newly verified defect or an instruction to clear real SavedVariables**.
- **G07 — actual item starters:** the existing [starter-marker fixture](../tests/compat/nq_available_starter_marker_contract.lua) explicitly expects no fabricated NPC/GO map pins/tooltips for an item-only source *in that renderer*. Item starter detection, real client interaction and item-only UI parity must be tested in the relevant path separately; absence of an NPC map pin does NOT prove the quest ineligible.
- **G09 — historical/phase/loot/IP:** no owner-private eligibility evidence has been imported. Public source guesses are insufficient for real per-quest approval; keep all private proof offline and continue the full 439 RAW classification programme with owner decisions.

All of G04–G09 remain UNDERWAY. No code changes to any of these paths, no automatic quest additions, and no change to native client/release gates.


## 10. Part40 pinned-digest CI addendum — 27 October 2026

**Exact-current-head evidence at this check (not an all-green claim).**

- [x] **[#246 NPC](https://github.com/CosmicCuddle/N-Questie/pull/246)** now pinned `47d57044a6c9cfe26268ad41d3676704a14672e3`. Actual original-head dedicated [run 40581684328](https://github.com/CosmicCuddle/N-Questie/actions/runs/40581684328) **SUCCESS**; both real **Lua 5.1.5 and 5.4.6**, same digest each faction `010975264-451717832`; fictional reverse through actual accumulation path FAILS as expected. Snapshot asserts enforce values, not just field counts.
- [x] **[#247 QUEST](https://github.com/CosmicCuddle/N-Questie/pull/247)** now pinned `dc08cc608dedd192d9c882e649af6e180e431d99`. Actual original-head dedicated [run 40581697607](https://github.com/CosmicCuddle/N-Questie/actions/runs/40581697607) **SUCCESS**; both real Lua versions give Alliance digest `043054440-899980232` and Horde `429450508-289752222`; 20/20 fictional controls, including six boundary tests, PASS on each.
- [x] Both PRs independently re-fetched as DRAFT with exactly **two changed paths each**, their source-reviewed parent heads unchanged; corrected workflow-file syntax checked and historical first-attempt errors preserved. CS02 independent *reverted* mutation review requested in [#42](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6453310407) for N2c/N3d/N3d+N2a and Q3c/Q8h/Q8i.
- [x] All original-head uploaded artifact endpoints independently queried: **#246 0/13**, **#247 0/14** at this check; they may be rechecked after the last still-running workflow concludes.
- [ ] **Do not mark entire CI green yet:** at interim snapshot #246 had **12/13** completed-success and #247 **13/14**, with one M2 framework workflow still executing on each. Need final exact-head results and all artifact endpoints after completion.
- [ ] #248 documentation final HEAD is independently rechecked in GitHub after this append and then its exact-head CI/artifact endpoints checked; do not confuse its historical earlier heads with this addendum.
- [x] Protected `335` re-verified **UNCHANGED** at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. All reviewed parents remain untouched. Full Gate08 production red boundaries unchanged; test-only digest witnesses cannot supply source A→B→A security.

**Whole twelve-gate status:** 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; 439 RAW with unknown eligible denominator and 0/3 implemented pilot. No private source, merge, install, package, tag or release.


## 11. Later Part40 FULL NPC/QUEST Actions and artifact endpoint closeout — 27 October 2026

**This later snapshot supersedes the PENDING full-run status in §10; do not delete that accurately dated interim observation.**

- [x] Frozen original parent **#238 NPC** `6647437079757bb4a52e46528c66eb639862e56a`: **15/15** original-head workflow runs SUCCESS and **0/15** artifact endpoints individually fetched. Earlier 14/14 record remains accurate for its earlier moment.
- [x] Frozen original parent **#243 QUEST** `547888b5932259892ddbc2fcbb63b9949f464b38`: **15/15** success and **0/15** artifacts. Earlier 14/14 record remains historical.
- [x] Original Part40 handover **#245** `6011ad30234c1505dce15b166057d0a25b3bfd78`: **8/8** success and **0/8** artifacts. Initial seven-run pending/checkpoint remains historical.
- [x] New Part40 **#246 NPC** exact `47d57044a6c9cfe26268ad41d3676704a14672e3`: **13/13** original-head Actions SUCCESS; **0/13** artifacts individually re-fetched **AFTER every workflow concluded**. Dedicated real Lua5.1.5/5.4.6 exact [40581684328](https://github.com/CosmicCuddle/N-Questie/actions/runs/40581684328) SUCCESS.
- [x] New Part40 **#247 QUEST** exact `dc08cc608dedd192d9c882e649af6e180e431d99`: **14/14** original-head Actions SUCCESS; **0/14** artifacts individually re-fetched **AFTER every workflow concluded**. Dedicated real Lua5.1.5/5.4.6 exact [40581697607](https://github.com/CosmicCuddle/N-Questie/actions/runs/40581697607) SUCCESS, twenty invented controls.
- [x] Later full-run confirmation posted to [coordination #42](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6453506288). Grok CS02's independent reverted N2c/N3d/N3d+N2a and Q3c/Q8h/Q8i review **PENDING**, not assumed passed.
- [ ] This **#248 docs draft** remains separately subject to exact-final-head Actions and artifacts, which need verification after this addendum's source SHA is known. No publication or integration follows.

**UNCHANGED HARD STOP:** all-writer source A→B→A, global stream quarantine, atomic full four-kind plus metadata publish, SaveVariables disk/relog recovery, native 3.3.5a/IP QA and independent mutation review. No private data or release authorisation; 3 COMPLETE/6 UNDERWAY/3 PENDING, 439 RAW, pilot 0/3.


## 11. Part40 TX17 synthetic restart-contract checkpoint — 27 October 2026

**Scope: TEST-ONLY RESEARCH / historical source-safe public data. Native WoW SavedVariables crash/relog TX17 remains RED.**

- [x] Historical [#249](https://github.com/CosmicCuddle/N-Questie/pull/249) from protected `335`, exact frozen head `492c9acec2974529044872b2a6488b44d5df82ba`, added a fictional dual-slot restart model. Dedicated actual Lua5.1.5 and Lua5.4.6 [40583491254](https://github.com/CosmicCuddle/N-Questie/actions/runs/40583491254) **SUCCESS**, 38/38 fictional controls each, 0 dedicated artifacts. **Unsafe survivor despite green fixture:** it took the unverified generation number from a damaged active slot as evidence that the other valid-looking slot was safely older. A torn/forged active generation 3 can wrongly promote a never-committed spare generation 2. **DO NOT MERGE #249 or call it real recovery.**
- [x] Separate existing #249 protected-335-inherited overlay run [40583491055](https://github.com/CosmicCuddle/N-Questie/actions/runs/40583491055) automatically uploaded **ONE ~35 MB `N-Questie-335-PR-TestBuild` artifact**, independently fetched and identified. Total artifact count for #249 is **1, NOT ZERO**. It was not installed or released. GitHub connector offers no delete-artifact action; never falsely claim it was removed. Prefer later no-packaging source ancestry for subsequent isolated test research.
- [x] Corrected independent [#250](https://github.com/CosmicCuddle/N-Questie/pull/250) at **`2db33ab7cd6275ef77ff1355156059f98f249d22`**, child of the existing Part40 docs #248 exactly `570ac6a9102fee9c14b6e903e8b1b99fcac3af69`, not protected `335`. Three new public-safe test/workflow/research paths. The model **refuses any invalid selected active generation** instead of guessing alternate commitment, and adds counterexample C21 as the 39th fictional test.
- [x] Dedicated [#250 run 40584665531](https://github.com/CosmicCuddle/N-Questie/actions/runs/40584665531) original-head **SUCCESS** under *real* Lua **5.1.5 and 5.4.6**, **39/39 fictional controls each**, identical expected text, no production/source use and **0 dedicated artifacts**. Individually checked all **7** current PR-triggered original-head artifact endpoints: **0/7** including overlay. CI at this dated snapshot had successful dedicated/revision/overlay and remaining full tests still processing. Recheck all workflows and push-event CI before final whole-head conclusion.
- [x] The test deliberately accepts a modified and **resealed** synthetic checksum, clearly printed **KNOWN UNSAFE**. Neither #249 nor #250 enforces true writer authentication, durable active-marker ordering, source A→B→A protection, global QuestieStream lease quarantine or transactional eight Bin+Ptrs+metadata publication. A single client SavedVariables file containing two Lua tables is **not an atomic disk journal**; no native 3.3.5a/IP crash/relog, frame/memory/GC or rollback QA is accepted.
- [ ] **CS02 peer review pending:** primary assigned #246 N2c/N3d (+N3d+N2a) and #247 Q3c/Q8h/Q8i still take priority. Later independent #250 tests should mutate corrupt selected generation -> spurious fallback, scalar active marker, every 8-field/metadata integrity check, same-generation conflict, returned alias, and intentional forged checksum survivor. Mutants reverted, both interpreters, exact head only.
- [ ] Complete separate G08 TX01–TX18, real saved-generation persistence and rollback, E01–E08 writer exclusion, complex codecs, and native 3.3.5a/IP QA before any integration. No real data, private SQL/loot/IP mappings or client backups may be published.

**Whole-project scoreboard remains G01–G03 COMPLETE, G04–G09 UNDERWAY, G10–G12 TECHNICALLY PENDING (3/6/3). The research programme is 439 RAW with unknown eligibility; pilot quests 1207–1209 still 0/3 implemented. Protected `335` unchanged at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. No merge, client install, package/tag/release authorisation.**


## 12. Part40 independent mutation reviews, artifact deletion, new QUEST boundary child — 27 October 2026

- [x] **CS02 independently VERIFIED #246 NPC** at frozen `47d57044a6c9cfe26268ad41d3676704a14672e3`: real Lua5.1.5/5.4.6, real extracted CI-step and reverted mutations **N2c, N3d, N3d+N2a all uniquely killed**, plus new value/content controls. [Peer review](https://github.com/CosmicCuddle/N-Questie/pull/246#issuecomment-6453627548). Current simple public corpus has **0 real NPC simple-field faction overrides**, making reviewer N8c equivalent in scope, NOT proof for full NPC/late-writer semantics. Full exact-head **13/13 Actions success, 0/13 artifact endpoints** including push. No blocker in tested scope.
- [x] **CS02 independently VERIFIED #247 QUEST** at frozen `dc08cc608dedd192d9c882e649af6e180e431d99`: real Lua5.1.5/5.4.6, extracted CI-step, **Q3c, Q8h, Q8i uniquely killed**, real Horde effective override caught. [Peer review](https://github.com/CosmicCuddle/N-Questie/pull/247#issuecomment-6453628160). Whole exact-head **14/14 Actions success, 0/14 artifact endpoints** including push. Five further gaps/equivalent-today mutants noted: Q8h2/Q8h3 for `u8s24pairs` min/max, Q8j `u12pair` lower, Q8k `u8u24array` upper, and Q14 literal control count (a missing control can still print `20/20 PASS`). Do not call these real source defects; they are inadequate fictional edge coverage.
- [x] **#249 artifact incident resolved:** CS02 reports deleting artifact ID `12769864479` after **explicit owner approval**; [#42 proof](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6453735993). Independently fetched #249 overlay run `40583491055` afterward: **0 CURRENT artifacts**. Preserve the fact one ~35 MB PR test-build WAS uploaded at the historical checkpoint. Do not erase the earlier security accounting or suggest it was never built. No release/install.
- [x] Opened new isolated [TEST-ONLY DRAFT #252](https://github.com/CosmicCuddle/N-Questie/pull/252) `92b0f012baba6c53a512bd6f945136f98f8f7e6a`, child of unchanged #247 head. Adds seven wholly fictional simple-compound boundaries (`u8s24pairs` signed min/max, `u12pair` negative lower, `u8u24array` 24-bit upper), and asserts then *computes* the **27 control count**, addressing the five CS02 test-coverage gaps. Exactly two public quest-audit/CI paths; no production or private source changes. Original-head real Lua/CI was in progress when opened; **DO NOT mark green until verified**.
- [ ] CS02 later mutation review of #252: Q8h2/Q8h3/Q8j/Q8k/Q14 killed independently and reverted under both Lua VMs; preserve old #247 review head. Need exact-head Actions status and all artifact endpoints. CS02 #250 fictional TX17 review may follow after this without duplicate ownership.
- [ ] Core G08 E01–E08 true all-writer exclusion, global QuestieStream pool quarantine, source-consistent 8-field+metadata commit, real SavedVariables disk restart/recovery and native WoW 3.3.5a/IP profiling remain unaccepted. No merge/install/packaging/tag/release.

**Whole 12 gates unchanged (3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING), 439 RAW research not 439 additions, pilot 1207–1209 = 0/3. Protected `335` unchanged `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.**


## 13. Final synthetic TX17 CI and #252 QUEST extra-boundary correction — 27 October 2026

- [x] Corrected [#250 TX17 standalone fictional model](https://github.com/CosmicCuddle/N-Questie/pull/250) frozen `2db33ab7cd6275ef77ff1355156059f98f249d22` now has **9/9 exact-head original Actions SUCCESS** (including both push runs), **0/9 uploaded artifacts independently rechecked**. Dedicated [40584665531](https://github.com/CosmicCuddle/N-Questie/actions/runs/40584665531) confirms real Lua5.1.5 + 5.4.6, 39/39 invented fail-closed controls each. This is STILL not actual WoW SavedVariables recovery; marker durability and forged checksums are unsolved.
- [x] The FIRST [#252 quest extra-control head](https://github.com/CosmicCuddle/N-Questie/pull/252) `92b0f012baba6c53a512bd6f945136f98f8f7e6a` had **real dedicated CI failure** [40585450283](https://github.com/CosmicCuddle/N-Questie/actions/runs/40585450283) on Lua5.1 `PUBLIC_QUEST_COMPOUND_CONTROL_SET_CHANGED`. The legacy `20/20` represented **17 table controls + 3 separate override controls**; adding seven invented rows gives **24 table controls + 3 overrides = 27 TOTAL**, not 27 rows. Historical failure preserved.
- [x] The repaired, still DRAFT [#252](https://github.com/CosmicCuddle/N-Questie/pull/252) exact `17e332a49b3f4455bbf176a766ba816543ad2826` has runtime asserts for **24 table controls and three independently incremented successful override controls**, computed output **27/27**. Actual Lua5.1.5 + Lua5.4.6 [40585981618](https://github.com/CosmicCuddle/N-Questie/actions/runs/40585981618) **SUCCESS**, both previously pinned PUBLIC faction value digests unchanged, seven fictional extra Q8h2/Q8h3/Q8j/Q8k boundary checks. All **14** original-head uploaded artifact endpoints, including push, individually checked ZERO. At this snapshot **11/14 Actions success**, remaining CI/M2 in progress; do NOT call full CI green early.
- [ ] Grok CS02 independent *reverted* mutation review for **#252 Q8h2/Q8h3/Q8j/Q8k/Q14** requested via [coordination #42](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6453894967), same immutable exact head, both interpreters and extracted CI step. Do not conflate peer verification of frozen #247 with this new child.
- [ ] Both #250 and #252 remain public-safe test-only designs, NOT source E01–E08 ownership/ABA protection, global pool quarantine, full four-kind atomic memory and real SavedVariables crash/relog recovery, private IP-eligibility or native client approval. No merge, install, tag, package or release.

**Whole 12-gate ledger remains 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; 439 RAW records with unknown eligible denominator and pilot quests 1207–1209 0/3. Protected `335` unchanged at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.**


## 14. Part40 Gate06 historical API and source-backed completion-cache test checkpoint — 27 October 2026

- [x] **Outside Gate08, progressing G06** with isolated public-safe [TEST-ONLY DRAFT #253](https://github.com/CosmicCuddle/N-Questie/pull/253). Latest exact head `1f90cb84bb713c2b4459acfe4e88bd5f3e1e4a7f`, branch child of frozen #248 docs `570ac6a9102fee9c14b6e903e8b1b99fcac3af69`. Three NEW paths only: actual-public-`Compat.lua` function extraction test, read-only dual Lua dedicated workflow and [bounded research description](research/NQ-PART40-GATE06-COMPLETION-CACHE-EVENT-ORDER-AUDIT.md). Zero production edits, real owner quest mappings, private server records or SavedVariables.
- [x] Actual source functions invoked from checkout (not rewritten toy copies): `QuestieCompat.ResetDailyQuests`, `SetQuestComplete`, `GetQuestsCompleted`, `QUEST_QUERY_COMPLETE`, and `Merge`. A deliberately stubbed WoW event/API/timer surrounds them. [Historical patch 3.3.0 API notes](https://warcraft.wiki.gg/wiki/Patch_3.3.0/API_changes), [GetQuestsCompleted](https://warcraft.wiki.gg/wiki/API:GetQuestsCompleted) and [QueryQuestsCompleted](https://warcraft.wiki.gg/wiki/API:QueryQuestsCompleted) identify real historical **asynchronous** request and supplied-table **additive** semantics (unrelated keys unchanged). The existing completion-cache handler passes the prior cache table, so stale keys surviving a response are a **credible source-supported risk**, but real owner client effects/UI markers, reset controls and server behaviour are NOT verified.
- [x] Historical first #253 head `c49609f6f020177da2d09783380486b78c87975a` dedicated [40587853510](https://github.com/CosmicCuddle/N-Questie/actions/runs/40587853510) **FAIL**: the **fictional** CalculateNextResetTime stub wrongly overwrote an existing reset deadline before the actual ResetDailyQuests function could evaluate it. Fixed on own isolated draft (no review head altered), historical error preserved.
- [x] Corrected [original-head dedicated #253 run 40588294259](https://github.com/CosmicCuddle/N-Questie/actions/runs/40588294259) **SUCCESS** on actual **Lua 5.1.5 and 5.4.6**, **14/14** fictional controls each, with only three fixed aggregate log lines. Covers missing/stale cache, documented additive vs counterfactual clear+add behavior, delayed and uncorrelated synthetic events, repeatables and daily/weekly marking/reset branches. **All eight current-head original-run artifact endpoints independently fetched: 0/8**. At this dated snapshot full exact-head CI was **4/8 success, 4 pending**; never call whole run green prematurely.
- [ ] Request and receive CS02 **comment-only independent reverted-mutation review** of #253 after #252's peer task, anchored to exact current head. Specific independent checks: skip server query, skip actual completion event read, skip repeatable filter, skip daily reset/merge, skip weekly merge, turn on completion for all repeatables, or bypass the 14-control inventory; both real interpreters and CI validation step.
- [ ] **G06 native acceptance remains OPEN:** independently verify game API and event ordering on authorized WoW3.3.5a/IP owner client, actual weekly/daily reset, any false available/complete markers and real SavedVariables safety. Do not automatically wipe legitimate completion history or add a speculative token as a production solution. No install or server/database modification authorised.
- [x] Related independent [#252](https://github.com/CosmicCuddle/N-Questie/pull/252) QUEST extra-boundary head `17e332a49b3f4455bbf176a766ba816543ad2826` now **14/14 original-head Actions SUCCESS** and its 14 artifact endpoints already rechecked ZERO; CS02 Q8h2/Q8h3/Q8j/Q8k/Q14 review still PENDING, and historical first-head failure preserved. [#250](https://github.com/CosmicCuddle/N-Questie/pull/250) synthetic TX17 head remains 9/9 green / zero artifacts, NOT real disk recovery.

**Whole programme still 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; G04/G05/G07/G09 continue independently, G10 covers 439 RAW records (eligibility unknown) and pilot quests 1207–1209 remain 0/3. Gate08 true all-writer A→B→A source exclusion, global QuestieStream quarantine, atomic four-kind eight Bin+Ptrs+metadata commit and real crash/relog recovery remain RED. Protected `335` still `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. No owner-private SQL/IP/loot relationships, merge, install, package, tag or release.**


## 15. Part40 independent review closeout and NEW G06/TX17 child research — 27 October 2026 (~23:15 UTC)

- [x] New team [#42 CS02 checkpoint](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6454858698) independently reviewed exactly frozen **[#252 QUEST](https://github.com/CosmicCuddle/N-Questie/pull/252#issuecomment-6454791138)** `17e332a49b3f4455bbf176a766ba816543ad2826` (**Q8h2/Q8h3/Q8j/Q8k/Q14** independently killed, real Lua5.1/5.4 extracted CI, 14/14 Actions success and 0 artifacts), **[#253 G06](https://github.com/CosmicCuddle/N-Questie/pull/253#issuecomment-6454804442)** `1f90cb84bb713c2b4459acfe4e88bd5f3e1e4a7f` (eight requested mutation classes killed, 8/8 Actions success, 0 artifacts), and **[#250 TX17](https://github.com/CosmicCuddle/N-Questie/pull/250#issuecomment-6454847660)** `2db33ab7cd6275ef77ff1355156059f98f249d22` (fail-closed witnessed, nine Actions success and 0 artifacts). **No production integration**; three peer reviews only certify bounded tests and retain known limits.
- [x] CS02 additional surviving G06 mutants: **M4c** reset fails to remove `complete[id]` (hidden by prior repeatable filter), **M4d** reset `>` changed to `>=` (no equality fixture), **M9** disabling reset-option guard (no saved overlays while option off), **K2/K3** no-op function and no execution loop (count still reported). Built separately on frozen #253 new public-safe [TEST-ONLY DRAFT #255](https://github.com/CosmicCuddle/N-Questie/pull/255) exact `a844b7995a071f749162d6578a8cd9349b06bae5`, three existing test/workflow/research-only files, real extracted original public `Compat.lua`. Adds invented nonrepeatable daily reset clearing, exact-deadline boundary, off-option daily+weekly merge refusal and **per-test actual count of 17 controls/20 passed assertions**. Exact-head dedicated [40599802907](https://github.com/CosmicCuddle/N-Questie/actions/runs/40599802907) **SUCCESS** both real Lua 5.1.5/5.4.6. All **8 initial artifact endpoints 0**. At dated checkpoint whole Actions **7/8 successful**, M2 still in progress; no full CI claim. CS02 reverted M4c/M4d/M9/K2/K3 review requested via [#42](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6455811695).
- [x] CS02 additional TX17 survivors on frozen #250: **F1d** selecting newer staged spare after damaged old active, **G3/G4** valid-integer revision/count checksum omissions, **F7** per-field type check omitted, and aliasing both slots to the same Lua table. Separate public-safe [TEST-ONLY DRAFT #256](https://github.com/CosmicCuddle/N-Questie/pull/256) exact `e0288ffb90fdbc2cb0e3c473b40aa598f55e1ae9`, three existing test/workflow/research paths only, models fail-closed selection and **44 fictional controls** (43 individually named expected test cases plus one return-copy check), rejects same-table slots as `REFUSE_ALIASED_SLOTS`; no actual persistent storage. Dedicated real Lua5.1.5+5.4.6 [40600325437](https://github.com/CosmicCuddle/N-Questie/actions/runs/40600325437) **SUCCESS 44/44** each. All **8 current artifact endpoints 0**. At dated snapshot original-head Actions **4/8 successful**, four still processing; no full CI claim. Peer review requested via [#42](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6455883257).
- [x] CS02 further clarified: G06 current controls intentionally characterize in-place cached results rather than a proposed fresh-table fix; historical Patch 3.3 supplied-table additive semantics make stale-key retention plausible **only in suitable rollback/reset circumstances**, not an established in-game defect. `QueryQuestsCompleted` event timings and native WoW3.3.5a owner client remain UNKNOWN. TX17 two polynomial hashes are forgeable and test-only; client disk/flush order and provenance still UNKNOWN. No live SavedVariables clearing or production changes.
- [x] Documentation-only [#254](https://github.com/CosmicCuddle/N-Questie/pull/254) `8eb6bb4ff0cb1db6c2f1c73cc923619cc0e02334` whole original-head **8/8 Actions success**, 0/8 artifact endpoints previously independently checked. The new checklist addendum is an **isolated child documentation DRAFT** and does not rewrite reviewed branches.
- [ ] Recheck **all** exact-head Actions and artifact endpoints after #255/#256 M2 and other remaining workflow completions. Preserve historical first-head failures and any new ones. Request/consume CS02 independently reverted mutation results before describing test guards as peer-verified.
- [ ] Production blockers remain: Gate06 genuine native API/reset event/UI proof; Gate08 full writer-exclusion source A→B→A (E01–E08), global QuestieStream pool leases/poison quarantine, coherent NPC/GO/QUEST/ITEM Bin+Ptrs + metadata and actual SavedVariables disk/relog recovery; G04/G05/G07/G09 public/private evidence separation; G10 individually triage all **439 RAW** records with eligibility UNKNOWN; G11 actual client/IP testing; G12 separately authorised integration/release.

**Scoreboard unchanged: 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING. Pilot 1207–1209 = 0/3 implemented. Protected `335` unchanged `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. No private server SQL, NPC/GO/item/loot/IP relationships in public repo; no merge, install, package, tag or release.**
