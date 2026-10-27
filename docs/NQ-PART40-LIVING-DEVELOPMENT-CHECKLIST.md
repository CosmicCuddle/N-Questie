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
