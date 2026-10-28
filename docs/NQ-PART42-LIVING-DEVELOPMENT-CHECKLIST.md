# N-Questie — Part 42 LIVING Development Checklist

**Created:** Wednesday 28 October 2026 (Europe/London).  
**Lead:** CS01 / CosmicScript01. **Peer reviewer:** CS02 / CosmicScript02 (Grok), coordination [PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42).  
**Authority:** PUBLIC-SAFE research, independent tests, documentation and isolated unmerged GitHub **DRAFT** PRs only. No owner-private data, protected-`335` edit, production merge, install, ZIP/package, tag, release, client/SQL change or SavedVariables access without separate explicit owner approval.  
**Complete reading required:** [full Part41→42 engineering handover](HANDOVERS/2026-10-28_PART41_TO_PART42.md), [authoritative master](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), [entire Part41 ledger](NQ-PART41-LIVING-DEVELOPMENT-CHECKLIST.md), [439 RAW programme](NQ-MISSING-QUEST-COVERAGE-PROGRAMME.md), and [PR #42 coordination](https://github.com/CosmicCuddle/N-Questie/pull/42). Read these BEFORE Part42 work.

## 1. Handover baseline — exact public evidence, 28 October 2026

- [x] Protected `335` independently re-fetched at handover: **`8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`**, unchanged. Recheck live on Part42 entry.
- [x] **All 12 gates unchanged:** G01–G03 COMPLETE, G04–G09 UNDERWAY, G10–G12 TECHNICALLY PENDING (**3/6/3**). G08 all-writer epoch, real global stream ownership, atomic four-kind memory and SavedVariables crash/relog remain **MAJOR RED**.
- [x] Public **439 RAW** investigations = 12 linked + 418 exploratory + 5 excluded + 3 placeholders + 1 already covered. Real eligible and approved counts **UNKNOWN**, not 439 missing quests. Pilot 1207–1209 **0/3 IMPLEMENTED**.
- [x] Frozen independently reviewed [#260](https://github.com/CosmicCuddle/N-Questie/pull/260) exact `2afeebd06c2909c42966edcad7f66555c561830e`: CS02 scoped VERIFIED, 10/10 original-head Actions SUCCESS, 0/10 artifacts.
- [x] Frozen independently reviewed [#263](https://github.com/CosmicCuddle/N-Questie/pull/263) exact `727631466e4e318f15a36531ce8afa909a78d947`: CS02 scoped VERIFIED (31/35 mutations killed, three equivalent, J1 low extractor boundary), 9/9 Actions SUCCESS, 0/9 artifacts.
- [x] Frozen independently reviewed [#265](https://github.com/CosmicCuddle/N-Questie/pull/265) exact `71b7f95d3d768890673aa3132f774afecd0e3853`: CS02 scoped VERIFIED known-unsafe G04 lifetime witnesses, 9/9 Actions SUCCESS, 0/9 artifacts. Not a fix.
- [x] [#267 public 439-RAW fictional admission](https://github.com/CosmicCuddle/N-Questie/pull/267) exact `b0459e681029f21266bf5067470e20cd77377ca4`: **9/9 SUCCESS, 0/9 artifacts**, dedicated 21/21 dual Lua. **CS02 peer mutation review still PENDING**.
- [x] [#270 G04 public lifecycle peer-gap follow-up](https://github.com/CosmicCuddle/N-Questie/pull/270) exact `a268cc9280b725e8871a00c84dedb02c4ffecc96`: **9/9 SUCCESS, 0/9 artifacts**, dedicated 18/18 actual dual Lua, still reproduces two intentionally known-unsafe late-writer scenarios. **Peer review PENDING**.
- [x] [#272 actual pinned public compiler negative witnesses](https://github.com/CosmicCuddle/N-Questie/pull/272) exact `5a8db6bbabce1840e1ff0befc941ecf442cf6f64`: **10/10 SUCCESS, 0/10 artifacts**; dedicated 12/12 real Lua 5.1.5/5.4.6. Actual unmodified compiler functions + fictional stream; invalid object false-success, codec writer sticky flag, pointer encoder new-Bin/old-Ptrs all intentionally **KNOWN UNSAFE**. **Peer review PENDING**.
- [x] [#273 docs](https://github.com/CosmicCuddle/N-Questie/pull/273) exact `eb7afc2134cc870d1e921080d3e10d7a5d11c0bc`: **9/9 SUCCESS, 0/9 artifacts**, including extra push CI.
- [x] **Historical failed head retained:** [#274 real-stream fixture](https://github.com/CosmicCuddle/N-Questie/pull/274) exact `55d6accc1ebfede4e0d6141abfdb4943cc50c655`: **10/11 Actions SUCCESS, one dedicated [40681430799](https://github.com/CosmicCuddle/N-Questie/actions/runs/40681430799) FAILURE**, 0/11 artifacts. Test died before lease assertions because PUC Lua lacks WoW `tremove`; NOT a real-client production failure. Never erase or retcon.
- [x] **Corrective** [#275 real QuestieStream test-only child](https://github.com/CosmicCuddle/N-Questie/pull/275) exact `affc24ce49e39e4d8308fc583ce148796d56d311`: **10/10 original-head Actions SUCCESS, 0/10 artifacts**, real entire public module dual Lua 5.1.5/5.4.6 **14/14 PASS** after adding only local `tremove=table.remove` test shim. Intentionally unsafe synthetic stale alias, duplicate `finished`, premature return while suspended; **NOT proof normal client misuses the pool, NOT safety acceptance**. **CS02 review PENDING**.
- [x] Last frozen **docs parent [#276](https://github.com/CosmicCuddle/N-Questie/pull/276)** exact `f3159b764e5ad473a0c2402da2532d7486a079a3`, based on #273; both authoritative Part41/master checklists synchronized, full historical #274 failure preserved. At handover **7/8 original-head Actions SUCCESS, M2 run `40682287019` in progress, 0/8 artifacts individually fetched**. Do not mark all green until live refresh.
- [x] Dedicated source pinned `Modules/QuestieStream.lua` blob `1819aeea11148eae0742810dbd2338410edda238`, `Database/compiler.lua` `abba0249f44d14711dbdd46bbde969ccffbc2963`, `Modules/QuestieInit.lua` `22fffa1b1bbeb81ba067f34151949c0938a316c1` at exact protected-335 commit. CI compares git tree **and** staged temporary bytes. This only authenticates the public files loaded in the tests, not live server eligibility or all writer ownership.

## 2. Immediate Part42 operations (next session)

- [ ] Recheck live protected `335`, exact PR #276 and this new handover/docs PR HEAD/base/draft/merged flags, **all** exact original-head CI runs and **each** artifact endpoint including push workflows.
- [ ] Close out remaining original-head #276 M2, if completed; preserve latest run counts and all earlier dated snapshots.
- [ ] Verify reviewer comment queue from PR #42 and exact #267/#270/#272/#275. Do not repeat CS02 reviews already completed for #260/#263/#265.
- [ ] CS02 FIRST #267: mutate fictional RAW→approval without private source/IP/offered/faction evidence, per-quest owner approval, native QA and release; differentiate policy-fixture proof from private quest evidence.
- [ ] CS02 SECOND #270: mutate duplicate callback orders, u8-range and sparse-list admission; distinguish W3 true fail-closed fix from W4 reverse fabrication; revert local scratch.
- [ ] CS02 THIRD #272: actual pinned compiler false-success/half pair/sticky retry; good fixes should make intentionally unsafe witness fail. Verify limits of fictional codec.
- [ ] CS02 FOURTH OPTIONAL #275: complete real QuestieStream stale alias, double-return, premature return of suspended coroutine, actual pool pin and healthy held-lease control; never imply real client misuse merely from fictional caller schedules.
- [ ] Continue safe TEST-ONLY source-backed Gate08 **real `GetDBHandle` reader-yield + actual full QuestieStream owner lifetime** research or all-writer E01–E08/A→B→A proof. Avoid global stream monkey-patch or unauthorized production fixes. Any new work: new isolated DRAFT.
- [ ] Develop falsifiable design for checked `SUCCESS/BUSY/RETRY/ERROR`, four-kind **eight Bin/Ptrs plus metadata** private staging and no-yield coherent RAM publish with all-writer epoch. Treat disk flush/relog/crash separately RED.
- [ ] Update **both** Part42 and master checklists by append-only dated docs-only DRAFT child after every substantive checkpoint. Link cross-branch research with immutable complete GitHub commit URL. Coordinate CS02 on #42 comment-only with exact head and status.

## 3. Open safety gates — cannot be “green” from synthetic CI

### G04–G07

- [ ] G04 approved manifest must not retain source mutable alias across late writes; epoch/ownership proof and correct forward/reverse source coherence required. Exact #265 known-unsafe and #270 follow-up are diagnostic, not repairs.
- [ ] G05 public `GetItem` source mapping is distinct from real server starter/finisher, item acquisition and faction. Effective join and full bidirectional owner proof remain.
- [ ] G06 public completion-cache controls insufficient for real asynchronous server/client completion/reset behaviour.
- [ ] G07 actual real 3.3.5a item use and source registration, no invented NPC/GO pin or itemDrops-as-starter inference.

### G08 — major blocker

- [ ] E01–E08 complete all-writer source epoch including **A→B→A**, or immutable snapshot with proof that no writer can alter approved inputs.
- [ ] Global real QuestieStream `GetStream/finished/reset` ownership and `GetDBHandle` coroutine suspensions across all readers and writers, exact-once return, lease quarantine after abort and no double enqueue or stale aliases.
- [ ] Real codec limits and readback, mixed-kind, half `Bin`/`Ptrs`, sticky `_isCompiling`, publisher metadata and retry after partial failure. The actual source-backed negative fixtures intentionally reproduce unsafe paths rather than fix them.
- [ ] All four NPC/object/quest/item binary+pointer pairs (EIGHT fields) and corresponding revision/version/lang/expansion/count/source-gen metadata stage privately, validate and publish as **one coherent no-yield in-RAM transaction**, with checked statuses.
- [ ] Native WoW3.3.5a SavedVariables true disk persistence, interruption, torn write, crash/relog, profile preservation and guaranteed recovery remain RED even if RAM publish becomes safe.
- [ ] No temporary test-build ZIP, normal global `GetStream` monkey-patch, cache-backed durability claims or borrowed real player data.

### G09–G12

- [ ] Owner-private quest-by-quest 439 RAW dispositions and eligibility proofs; 12 linked + 418 exploratory + 5 excluded + 3 placeholders + 1 covered are **not** approved additions.
- [ ] Pilot 1207–1209 remain **0/3 implemented**, no owner-private relationships on GitHub, no bypass of IP history/faction/phase/loot/active-offered eligibility.
- [ ] Owner-authorized 3.3.5a/IP native client lifecycle, display, map, memory/GC/frame, reload/rollback before any integration or release.
- [ ] Distinct owner authorization for merge, client installation, packaging, tagging, deployment and release.

## 4. Historical failures and prohibited conflations

- [x] Preserve early #258 failed test heads and parent mismatch, plus later frozen 9/9 success.
- [x] Preserve #249 known-unsafe fallback test ZIP ~35 MB and owner's authorized deletion evidence; do not rebuild a test ZIP.
- [x] Preserve #274 original dedicated 40681430799 failed Lua plain-runtime `tremove` parity run; #275 fixes only the **test environment**, not protected source.
- [x] Preserve each historical snapshot and all original-head artifacts/push workflow inventories. Never claim “everything green” when a frozen head had a failed run.
- [x] “CS02 scoped VERIFIED” for earlier pinned fictional code is not proof of live in-game, authenticated E01–E08 writer exclusion, private eligibility or SavedVariables real disk success.

## 5. Living Part42 activity — APPEND ONLY BELOW

**At creation:** new Part42 handover and checklist are public-safe **DOCS-ONLY DRAFT** children of frozen #276; GitHub exact-head CI/artifact results for this newly created handover are initially **pending**. Its actual PR URL and final HEAD should be recorded on PR #42 when available. Follow-up entries must record timestamp, immutable branch SHA, files changed, dedicated and aggregate tests, each artifact endpoint, review findings and RED limits without replacing prior records.

### Part42 checkpoint template

**UTC date/time:** TBD. **Exact isolated DRAFT PR and HEAD:** TBD. **Base SHA:** TBD. **Changed files:** TBD. **Actions original HEAD:** TBD successful / TBD total including push, TBD failed, TBD running; **artifacts:** TBD individually fetched. **Independent CS02 review:** TBD. **Source/fixture scope:** TBD. **Privacy/backup/release restrictions:** unchanged unless separately owner authorized. **Gate totals:** default unchanged 3/6/3; explicitly justify any future promotion with native acceptance and owner authority.
