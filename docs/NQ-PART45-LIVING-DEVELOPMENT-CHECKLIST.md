# N-Questie — Part 45 Living Development Checklist

**28 October 2026 · Public-safe, append-only engineering status · DRAFT ONLY**

**Read first and completely:** [Part44→45 Engineering Handover](HANDOVERS/2026-10-28_PART44_TO_PART45.md), [Part44 checklist](NQ-PART44-LIVING-DEVELOPMENT-CHECKLIST.md), [master checklist](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), [PR #42 cross-team coordination](https://github.com/CosmicCuddle/N-Questie/pull/42). This document records independently verified source/test evidence and remaining acceptance barriers, NOT native gameplay release authorisation.

## 0. Immutable safety gate

- [x] Public protected production `335` verified unchanged/protected `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` at Part45 handover.
- [x] Explicit safety boundary carried forward: **Gate08 MAJOR RED**, project **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**. No approved playable Alpha0, build, ZIP, release, native install, protected edit, SQL, merge, tag, or real realm/account/character/SavedVariables use.
- [x] **439 RAW unapproved**, eligible denominator UNKNOWN, pilot 1207–1209 **0/3 implemented**.
- [ ] Before *any later separately approved native* test: whole `Interface/AddOns/Questie-335` backup, account- and character-level SavedVariables backups, original revision/hash verification and tested rollback. Not authorised today.

## 1. Part44 frozen exact-head evidence carried forward

- [x] Test [#323](https://github.com/CosmicCuddle/N-Questie/pull/323) `5283d41633bfaaef09201d696f0cf67605041aaf` — original complete AvailableQuests/fictional scheduler, **37/37 EACH Lua5.1/5.4**; **30/30 Actions SUCCESS**.
- [x] Test [#324](https://github.com/CosmicCuddle/N-Questie/pull/324) `73b8be5b9aca0c4b54f9303a7b780b939bec9e35` — real complete ThreadLib+AvailableQuests with fabricated C_Timer, **32/32 EACH**, **31/31 Actions SUCCESS**.
- [x] Test [#326](https://github.com/CosmicCuddle/N-Questie/pull/326) `873dfba432b2e8cf8bd13b43a038be193d3c0334` — original full V1/V2 QuestieComms synthetic, fake packet transport only, **46/46 EACH**, **32/32 Actions SUCCESS**.
- [x] **Preserve FAILED** [#328](https://github.com/CosmicCuddle/N-Questie/pull/328) `9edaf9a542b82e9442ef7fbfe0b8c99fed44dc1f` — **32 Actions SUCCESS, 1 FAILED** in original fictional T32 override fixture (not native); [run 40739785678](https://github.com/CosmicCuddle/N-Questie/actions/runs/40739785678), 0 artifacts.
- [x] Corrective [#329](https://github.com/CosmicCuddle/N-Questie/pull/329) `13d98c12d1aeae007d3ef0c03e113f1f893364dc` — original Tracker `SetItem` **FRAGMENT**, corrected synthetic class override, **35/35 EACH**, **33/33 Actions SUCCESS**.
- [x] **Preserve FAILED** [#330](https://github.com/CosmicCuddle/N-Questie/pull/330) `0bb3772f8497cfb55d0ccb0632c94c56729e0595` — **33 SUCCESS, 1 FAILED**, 40 executed fixture controls but final census expected 38; [run 40742369106](https://github.com/CosmicCuddle/N-Questie/actions/runs/40742369106), no Lua5.4 execution on failed original.
- [x] Corrective [#331](https://github.com/CosmicCuddle/N-Questie/pull/331) `567dfaadd0c8e1fceea9fb9c4a07bbc078a1fae8` — original QuestieDB Initialize/GetCreatureLevels, **40/40 EACH**, **34/34 Actions SUCCESS**; separate `_CreatureLevelCache` survives fictional A→B→A until model invalidation.
- [x] Test [#333](https://github.com/CosmicCuddle/N-Questie/pull/333) `e7921454a776420405cacddda28effc6d8132437` — whole real QuestieStream + original GetDBHandle fragment, **33/33 EACH**, **35/35 Actions SUCCESS**, deliberate premature `finished()` lease misuse illustrates old query closure reading reused stream data; no normal/native misuse established.
- [x] Test [#335](https://github.com/CosmicCuddle/N-Questie/pull/335) `04a0b48a1ee5688743e75aece4581502766309b2` — original SmoothReset function + full ThreadLib, invented AvailableQuests calculator/clock, **22/22 EACH**; **35/35 Actions SUCCESS**. Constructed supersession or error loses completion callback and can strand reset latch, **potential native effect unknown**.
- [x] Docs-only [#336](https://github.com/CosmicCuddle/N-Questie/pull/336) `80d830e2018216722903e756482600ef9db2cd67` **8/8 Actions SUCCESS**; source status captured append-only through SmoothReset. All cited PRs independently observed still open/draft/unmerged at Part45 handover.
- [ ] If any new GitHub CI runs, reviews or artifact uploads appear on exact heads after handover, verify independently and append dated evidence. Do not overwrite original failed heads or erase historical pending checkpoints.

## 2. Part45 priority A: authentic reset/scheduler ownership

- [ ] Inspect CS02 [original ThreadLib/Compat/AvailableQuests trace](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6477005216), its [reviews/mutations](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6477029934), CS01 [source-bound SmoothReset trace](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6477110628) and [#335](https://github.com/CosmicCuddle/N-Questie/pull/335) exact full test details.
- [ ] Extend source-executed **real Compat ticker + original SmoothReset + full original AvailableQuests/ThreadLib** where feasible with a fictional frame scheduler; pin original 335 blobs. Identify the actual effects of cancellation, reentrant reset, error, all original child timers and queued callback ownership.
- [ ] Test callback liveness and explicit **PENDING / ABORT / ERROR / COMPLETE** model outcomes without declaring false READY. A→B→A epoch must reject stale pending task even if source pointers match by identity; model only, no production patch.
- [ ] Preserve existing frames, tooltips, availableQuest cache and pending child-task evidence across source transitions; specify rollback/cleanup for partially drawn result sets.
- [ ] Check negative mutants (callback dropped vs double-fired vs error, stale epoch accepted, child task persists, timer Cancel semantics) and record killed/surviving using exact source lines. Native event overlap remains unverified.

## 3. Part45 priority B: original DB reader/stream and derived holder ownership

- [ ] Source-prove original `QuestieDB:Initialize` five cache resets, `_CreatureLevelCache` bypass, original `QuestieStream` GetStream and GetDBHandle live reader closure holder lifetime across generations.
- [ ] Separate **actual safe stream return**, **deliberate early finish**, **double finish**, **abort quarantine**, and **late reference** outcomes. Never convert intentional misuse witness to production bug claim.
- [ ] Propose fail-closed monotonic source-owner and reader-epoch contract for all four NPC/object/quest/item Bin+Ptrs, associated metadata, external references, stored callbacks, Search LastResult, Comms outbound queue, Tracker button/item cache and AvailableQuests children.
- [ ] Re-execute authentic original compiler/reader integration under fictional data if it meaningfully increases original code coverage; do not modify original protected runtime.

## 4. Part45 priority C: original writer and persisted generation proof gaps

- [ ] Classify actual E01–E08, unknown writers and correction-scope ownership; source-backed BUSY/RETRY/ERROR/ABORT with A→B→A protection and no partial publication.
- [ ] Four-kind publication must be all eight Bin+Ptrs + metadata atomically to original reader exports with compatible cache transition, not shadow-only model.
- [ ] SavedVariables writing, interrupted disk/relog/crash recovery and individual progression native client remain unaccepted. Planning only unless owner separately authorises.
- [ ] 439 RAW remains unapproved; pilot 1207–1209 unimplemented. No test-data fixture values become approved gameplay data.

## 5. Team and documentation

- [x] Real CS02 latest original source + simulated Compat report documented via GitHub PR #42 comments 6477005216 and 6477029934. Peer completion credit limited to verified comments, not unconfirmed Grok, Claude, CS03 responses.
- [ ] Recheck [PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42) for new CS02/CS03/Grok/Claude replies; issue **focused independent** source, mutation and integration tasks in comment-only mode, no repetitive broad review.
- [ ] Keep [master checklist](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), [Part44 checklist](NQ-PART44-LIVING-DEVELOPMENT-CHECKLIST.md) and this Part45 checklist current by append-only documents on isolated draft PRs. For each source test record exact 335 SHA/blob, original PR head, dedicated run+job, Lua versions and assertions, broader original-head Actions, negative evidence, artifacts, source vs mock boundary and blocked gates.
- [ ] If the chat reaches its limit, create a **Part45→46 complete handover** + next living checklist on a fresh docs-only draft, pin exact links and results before transferring.

**Permanent safety:** Protected `335` unchanged; **Gate08 MAJOR RED**. No protected code/SQL, package, real network, private realm/account/SavedVariables, client native install, merge, tag, release or build until separately authorised. Test-only and docs-only public-safe draft engineering is permitted and should proceed without a new permission request.


### Part45 checkpoint — original UpdateQuest self-supersession (28 Oct 2026, append-only)

- [x] Independently recheck protected public `335` ref and original code at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`; no production writes.
- [x] Read newer CS02 [#42 comment 6478068402](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6478068402) and original code. Source facts: `SmoothReset` step8 passes a completion callback to `AvailableQuests.CalculateAndDrawAll` (QuestieQuest:335–337); step9 calls original `UpdateQuest` (342), whose `isComplete==0` / `WasComplete` or missing-source-item path calls callback-less `AvailableQuests.CalculateAndDrawAll()` (611–638). Actual AvailableQuests:44–52 cancels the previous outer timer; ThreadLib:39–50 only calls completion on normal coroutine death. This is a **plausible source path**, not native event evidence.
- [x] Create isolated **[TEST-ONLY DRAFT #338](https://github.com/CosmicCuddle/N-Questie/pull/338)** exact original head `1268bc9261723f4fe3bb824ed056d7189294e4b5`, direct child frozen #335 `04a0b48a1ee5688743e75aece4581502766309b2`; 3 additive test-only paths, 253 additions/0 deletions. Exact original unmodified `SmoothReset` + `UpdateQuest` *function bodies* and complete original `AvailableQuests` + `ThreadLib` modules with fictional quest/clock/database. **24 assertions proposed per real Lua5.1/5.4, NOT credited pending dedicated CI.** Actual Compat AnimationGroup C_Timer, full QuestieQuest module and WoW client NOT executed.
- [x] Issue focused CS02/Grok, CS03 and Claude comment-only challenge on [coordination #42 comment 6478294111](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6478294111). Assignment requests are not evidence of acceptance or completion.
- [ ] Inspect #338 dedicated run/job dual-Lua logs, correct source blob verification, original-head complete Actions and artifacts; preserve failed original head if a fixture is wrong, make distinct corrective child. Check independent negative mutants and source-event ordering.
- [ ] PR [#337](https://github.com/CosmicCuddle/N-Questie/pull/337) original `63f9564e4bc4904ad4a1ae0539a0497346a5f51d`: at independent 28 Oct refresh **7/8 Actions SUCCESS, one M2 in progress**. Original handover's 7 queued/1 in progress was historical, not final. Refresh before claiming complete.
- [ ] Original Compat animation timer source integration, callback error/cancel ownership, stale child cleanup and native-event feasibility remain unaccepted. No gameplay/native/Individual Progression evidence, no patch authority.

**Permanent:** Gate08 **MAJOR RED**. Project 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING. 439 RAW not approved, eligible denominator unknown, pilot 1207–1209 0/3. No protected change, merge, native test, build, ZIP, install, tag, release or private SavedVariables.
