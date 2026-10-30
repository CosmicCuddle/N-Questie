# N-Questie — CURRENT Living Conversation & Engineering Handover

**Living entry point | opened 30 October 2026 UTC for Part 49 → Part 50 | public-safe | documentation only**

> **N-Questie is UNDER DEVELOPMENT and NOT READY FOR DOWNLOAD OR INSTALLATION.** This handover is a continuity index, not evidence of in-game QA, a merged patch, a distributed build, or approval for release. CosmicCuddle remains the final decision-maker.

## How the next conversation resumes (read in this order)

1. Read this complete `docs/HANDOVERS/CURRENT.md` on its **current reviewed draft branch**. Do not assume it has been merged into protected `335`.
2. Read the detailed [Part 48 → 49 engineering handover](2026-10-30_PART48_TO_PART49.md), and the [Part 49 living checklist](../NQ-PART49-LIVING-DEVELOPMENT-CHECKLIST.md). These contain historical context; this file records the **newest known checkpoint**, rather than replacing their evidence.
3. Cross-check the [master living project checklist](../NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), [native 3.3.5a evidence gate](../research/NQ-PART47-NATIVE-335-EVIDENCE-OBSERVATION-GATE.md), [PR #42 cross-developer coordination](https://github.com/CosmicCuddle/N-Questie/pull/42), and actual current GitHub issues/PRs, including new comments.
4. Recheck repository default branch, protection, exact SHA, current PR heads, exact-head CI and artifact state. **Every status below is a dated checkpoint**, not a running monitor.
5. Continue only in the approved **read-only research and isolated draft DOCS/TEST** boundary. Never treat "continue" alone as authorisation for a protected-branch merge, native game client test, original addon implementation, production operations or release.

## Project identity and immutable evidence

- Repository: [CosmicCuddle/N-Questie](https://github.com/CosmicCuddle/N-Questie), a custom WoW 3.3.5a Questie fork. Addon folder/TOC still use `Questie-335` for compatibility. Preserve the prominent public unfinished warning; no release has been approved.
- **Protected default `335` branch:** verified 30 October 2026 as **`26053bd28b0df3a01e5859f779d5f3cb4f57b221`**, branch protection **true**; this live repo branch contains README-only N-Questie messaging, **not** the unmerged development/test stack. "Live branch" means GitHub default branch here, **not proof of a deployed addon**.
- **Authentic historical original addon-source code pin**: `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, distinct from default `335`. Source-backed claims, source blob hashes and genuine method-under-fake-host tests refer to that historical code, **not automatically to a running client**.
- **Frozen older draft PR heads must remain frozen**, including intentionally preserved first-failure RED fixtures. Any correction must be in a separate child branch/PR. Do not force-push or rewrite someone else's work.
- **Documentation ancestry:** [#427](https://github.com/CosmicCuddle/N-Questie/pull/427) introduced the Part48→49 handover/checklist; [#428](https://github.com/CosmicCuddle/N-Questie/pull/428) added the reward-identity observation plan; [#430](https://github.com/CosmicCuddle/N-Questie/pull/430) added Gate08 debug-validator source/lease findings and appended Part49 checklist notes. **This living document is a new DOCS-only child of #430's verified first head `a2bc6031cf8508f36563579daf0ea0b7650b45c5`**; no original head is altered.
- Separate [TEST-only draft #431](https://github.com/CosmicCuddle/N-Questie/pull/431): exact first-submitted head `0b2d0fd1174576a2c2f8d70569ce2c104ea46e10`, based on frozen [#429](https://github.com/CosmicCuddle/N-Questie/pull/429), changes **two TEST/CI paths** (+165 test lines, +16 workflow lines, 0 deletions). 30 October exact-commit workflow census returned **37 completed/successful Actions workflow runs**; the workflow additionally checks a `31/31 PASS` marker from the fabricated-source validator fixture for **each Lua 5.1 and 5.4**. This does **not** mean native WoW testing passed, or that every CI/artifact and behavioral claim has been independently audited. Keep #431 DRAFT, UNMERGED.

## Current major blockers (do not turn RED into GREEN)

- **Gate08 = MAJOR RED**: untrusted source-table writers, source-generation/ABA race and reader lifetime, busy/poisoned `QuestieStream` leases, coherent publication of **eight compiled Bin/Ptrs fields plus relevant metadata**, interrupted-write/crash/relog `SavedVariables` persistence, and actual WoW 3.3.5a/IP RAM/GC/frame-time QA remain unresolved.
- **Gate10 candidate set:** **439 RAW** quest candidates **unapproved**; eligible/validated denominator not known. **Missing-quest pilots 1207–1209: 0/3 implemented**. These are distinct from older existing-quest correction proposals and synthetic M2.2 representability work.
- No Alpha0 game-client acceptance, no general player installation readiness, no production or public release. A passing synthetic/unit/Actions workflow is **not** equivalent to passing the game's Lua runtime, real client events, quest data, or server progression rules.
- Owner-approved Vanilla phase and level cap 60 should guide future quest policy; **never infer server-effective availability only from Questie's inherited database, private export, or a title match**.

## Part49 source-backed progress and precisely what remains unknown

### Quest acceptance, abandon and tracker

- Historical original Questie startup registers quest-event handling **before** CombatQueue initialization, with coroutine yields between. A `QUEST_ACCEPTED` arriving in the registered/prequeue window could lose acceptance-specific queue work; actual native arrival timing and visible consequences **are not established**.
- Original quest cache reconstruction and a separate delayed tracker synchronization can restore tracker state. **Do not** infer permanent empty tracker, or assume those mechanisms replay Journey/announcement side effects.
- A/B/C acceptance scenarios and observation-only native criteria are recorded in [#426](https://github.com/CosmicCuddle/N-Questie/pull/426) and its research document. Rapid abandon/reaccept conditional paths were already exercised in synthetic #422; avoid repeating tests just to increase counts.

### Quest reward identity and event completion

- Authentic historical `QuestieCompat.GetQuestIDFromName` scans quest-log rows and returns the **first** matching non-header title. The `GetQuestReward` post-hook uses that result in a title→quest ID cache, and completion-chat handling later uses it; a missing new lookup can leave a previous same-title cache mapping intact. These are **conditional source behaviors**, not a confirmed customer/player bug.
- Static duplicate quest titles are **not** proof that two active eligible quests of the same title coexist in a character's log. The alternate giver-aware resolver does not guarantee uniqueness. Do not assume stock WoW 3.3.5a supplies the modern `GetQuestID` API.
- [#428 reward identity gate](../research/NQ-PART49-335-REWARD-COMPLETION-IDENTITY-EVIDENCE-GATE.md) defines six future native observational cases R1–R6. [#429](https://github.com/CosmicCuddle/N-Questie/pull/429) runs the authentic historical first-title source and reward hook under invented client APIs; no native event-order proof or authorized client test.

### New Gate08 validator source-writer and reader cleanup issue

- [#430 source audit](../research/NQ-PART49-G08-DEBUG-VALIDATOR-SOURCE-WRITER-LEASE-BOUNDARY.md) identified a concrete **debug-only post-compile conditional mutation**: `ValidateQuests()` may assign `extraObjectives[i][4] = 0` inside the **original nested raw quest record** when comparing to a compiled zero. No real qualifying quest row or client consequence has been demonstrated.
- Original `ValidateNPCs/ValidateObjects/ValidateItems/ValidateQuests` acquire **1/1/3/1 stream readers**. Their ordinary successful exits call `finished()`; specific early mismatch/missing-drop returns can bypass that cleanup. This is an original-source handle-lifetime finding, **not a measured memory leak**.
- [#431 test draft](https://github.com/CosmicCuddle/N-Questie/pull/431) specifically executes unchanged original method bodies against **fake compiled/raw rows and fake reader handles**. It improves narrow source-path evidence, but does **not** test original real `QuestieStream` pool behavior, live contention, client persistence, or GC effects. Gate08 stays RED.
- Proposed W01/W02 and L01–L04 checks in #430 are **future acceptance proposals**; no owner-approved repair architecture has been selected.

## Safety, approval and collaboration

- Allowed without new special authorization in recorded handovers: **read-only research, carefully bounded DOCS-only and TEST-only draft PRs** with strict original-source immutability and no public package. Independently verify each new head, its diff, workflows and artifacts.
- **Not authorized:** original addon Lua/TOC/SQL/DB gameplay modifications, protected `335` edits or merges, real game client or account/character/`SavedVariables` testing, production/server edits, installer/ZIP/build/tag/release, server/database migrations, or GitHub protection/visibility changes.
- For any future in-game/native observation or instrumentation: get **fresh explicit CosmicCuddle approval** for disposable staging characters/quests/client scope, verified addon/WTF/DBC/DB backup hashes, tested rollback and privacy/stop criteria **before** execution.
- Keep private `acore_world.zip`, SQL exports, full discrepancy audits and personal/player records off public GitHub. Never confuse research candidates with approved content changes.
- [Coordination repo](https://github.com/CosmicCuddle/Naxxramas-Server-Coordination) is for **cross-project** questions, not N-Questie source/PR work. Check its README, open `to:information` Issues and any relevant Maintenance requests before creating a duplicate Issue. Current N-Questie source hypotheses **alone do not establish** a Maintenance/server-core dependency. Keep [#42](https://github.com/CosmicCuddle/N-Questie/pull/42) developer coordination concise; do not claim new Claude/Grok results without verification.

## Next safe work items

1. **Finish this documentation-only living-pointer review**: confirm its own branch/PR head, two intended docs file changes only, no added binaries/artifacts or edits to original add-on source, and exact-head CI. A draft PR is not merged documentation.
2. **Read-only analyze #431's source-method fixture limits** against [#430's W01/W02/L01–L04 matrix](../research/NQ-PART49-G08-DEBUG-VALIDATOR-SOURCE-WRITER-LEASE-BOUNDARY.md). Identify specific remaining discriminating tests, if any; do not create assertion-count-only duplicates.
3. **Prioritize Gate08 design/evidence** before expanding unapproved quest counts. Any actual stream lifetime, source-epoch, whole-cache publication fix needs a separately reviewed implementation decision and owner approval.
4. Maintain the future *observation-only* reward ID and startup A/B/C plans; do not infer native timing, player impact, leak or bug from synthetic fixtures.
5. Coordinate with Maintenance **only if a verified cross-project dependency arises**. Preserve all unmerged drafts and historical evidence.

## How to maintain this living file

- For **every new long chat**, use the URL to this file on the **latest reviewed GitHub draft branch/commit**; if the PR is still unmerged, **do not link only to `335`**. Recheck that URL and branch status first.
- When a material decision, exact-head CI result, source finding or blocker changes, **update `CURRENT.md` in a new controlled DOCS-only review branch**; preserve earlier frozen submitted PR heads. Refresh the dated verification statement and links, and keep the checklist in sync. Avoid editing many redundant handovers.
- Keep separate dated handovers (such as Part48→49) as immutable **historical snapshots**. The living file records the *current* state; GitHub Issues/PRs/commits are primary evidence.
- Use **CONFIRMED / PROPOSED / UNVERIFIED / OUTDATED** labels for changing facts, avoid silently upgrading test evidence to in-game success, and note what action CosmicCuddle approved.
- If new work is unmerged, record the branch and pull request link in the next update; do **not** say it has reached the protected default branch.

**Handover preparation/source check:** 30 October 2026 UTC, after #431 original-head workflow review. **Status:** continuation documented, original addon and protected `335` unchanged, major gates still open.

## Part50 continued source review — validator result boundary (30 October 2026 UTC)

- **New source finding, documentation-only:** four historical original debug validators emit `Questie:Warning/Error` and bare `return` on handled mismatches or missing item-drop references, but all ordinary success paths also return `nil`. Enclosing `runValidator()` neither checks those results nor stops the next validator; Stage1 can still print `Load and Validation complete.` before `QuestieCleanup:Run()`. This message is **not proof all four validations passed**. An actual thrown exception is a different control path.
- Read the new [Part50 source/diagnostic/lease acceptance memo](../research/NQ-PART50-G08-VALIDATOR-RESULT-STARTUP-STATUS-BOUNDARY.md) for exact original source pins and proposed future V01–V06 tests. No client mismatch, active stream leak or gameplay issue is claimed. The legacy debug validator is post-compile; it must not be treated as a future transactional prepublication success receipt.
- This is a separate **DOCS-only review child of frozen original Part50 living-handover [#432](https://github.com/CosmicCuddle/N-Questie/pull/432)** exact first head `329b479d58771218d960317629ac262ff53b2b79`. Its review branch is `docs/part50-g08-validator-status-propagation-cs01-20261030`; preserve #432 and #430 originals. After a new PR is opened, verify its exact-head checks and append its URL on the NEXT fresh review branch (do not rewrite submitted first heads).
- **Prioritize remaining Gate08 source ownership, driver leases, eight-field+metadata publication and native recovery evidence.** The V01–V06 diagnostic source distinction **does not** pass Gate08, authorize a code change or justify a cross-project Maintenance Issue.

## Part50 continued source writer inventory — precompiler raw table transformations (30 October 2026 UTC)

- **New first-party historic source facts** at original CODE commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`: `QuestieQuestFixes:LoadMissingQuests()` in `Database/Corrections/classicQuestFixes.lua` unconditionally replaces **12 selected `QuestieDB.questData[id]` rows with fresh empty tables** (it does not merge existing rows); `_QuestieDB:DeleteGatheringNodes()` in `Database/QuestieDB.lua` clears the `spawns` field of **24 selected `QuestieDB.objectData[id]` rows**. These are historical original source operations and are **not proof of wrong private gameplay content**.
- **Verified source order** in original `Modules/QuestieInit.lua`: `LoadBaseDB` → `QuestieCorrections:Initialize` (calls `LoadMissingQuests` early) → `DeleteGatheringNodes` → `QuestieCorrections:PreCompile`, with coroutine yield boundaries. All must be included in any *future* owned, stable precompile source generation. Merely pinning a snapshot before these transforms, or treating the table root as immutable, is insufficient. This does **not** solve unknown third-party writers, nested A→B→A, faction-effective overrides, or atomic capture.
- **New separate TEST-ONLY DRAFT [#434](https://github.com/CosmicCuddle/N-Questie/pull/434)**, branch `test/part50-original-source-writer-boundaries-cs01-20261030`, exact first head `d0f90a2bd37f8d266e27bf15004f5cf184120f77` and frozen test parent [#431](https://github.com/CosmicCuddle/N-Questie/pull/431) head `0b2d0fd1174576a2c2f8d70569ce2c104ea46e10`: two TEST/CI paths only (+166/-1); original method bodies under fictional rows, 17 expected source-backed checks each Lua 5.1/5.4, authentic source SHA pins. A fabricated missing gathering row can throw; **no evidence actual shipped data is missing a row**. **CI remains to be independently verified at its own exact head**, do not inherit #431's 37/37 successes.
- **Previously completed:** frozen docs [#432](https://github.com/CosmicCuddle/N-Questie/pull/432) head `329b479d58771218d960317629ac262ff53b2b79` and docs [#433](https://github.com/CosmicCuddle/N-Questie/pull/433) head `ed4a4c52be16f36f4702598cafc77b7dd39c5f5e` independently checked **7/7 exact-head workflow successes each and 0 artifacts at each of all 14 run endpoints**. Both remain DRAFT/UNMERGED.
- **Next engineering blockers, unchanged:** truthful source ownership through yields and unknown writers; driver-owned reader/writer streams and shared-pool poison quarantine; all eight compiled `Bin/Ptrs` fields plus metadata published/selected coherently and recovered across crash/relog; native 3.3.5a/IP RAM/GC/frame measurements with explicit user approval. Gate08 **MAJOR RED**. No original playable Lua/TOC/SQL, protected `335`, native client or server modification. 439 RAW Gate10 candidates unapproved; missing-quest 1207–1209 pilot 0/3.
