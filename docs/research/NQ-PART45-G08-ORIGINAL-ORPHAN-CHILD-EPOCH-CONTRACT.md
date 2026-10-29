# G08 Part45 — original independent child after parent cancellation + counterfactual ownership contract

**PUBLIC-SAFE TEST-ONLY RESEARCH / DRAFT / NO MERGE.** Date: 28 October 2026.

## Exact source scope

Source baseline is historical protected original `335` **`8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`**, prior to the **README-only** owner-approved merge of PR #351 (`26053bd28b0df3a01e5859f779d5f3cb4f57b221`). These four exact blobs have not changed because of that documentation merge:

- `Modules/Quest/QuestieQuest.lua`: `cd4239c5b40c1f5b1ced823dfa12d8a895091719` — **exact authentic SmoothReset and UpdateQuest function bodies only**.
- `Modules/Quest/AvailableQuests.lua`: `2664f09fdf1f5df4d94581414e9d5ea88e9af4e7` — **whole original module**.
- `Modules/Libs/ThreadLib.lua`: `8f564049ad2a4af49473fac939b7c276c4227dd7` — **whole original module**.
- `Compat/Compat.lua`: `b3e273e82cabbd5b7b351ae5aa3d94d4675387be` — **timer fragment only**, not the entire Compat module.

**The test host is invented**: fake AnimationGroup/timer callback loop, fictional quest pointers and DB, game API replacements, no real client or realm. The test reuses previously authenticated #348 source execution and adds a separate scenario using genuine original `_DrawAvailableQuest` → `ThreadLib.ThreadSimple` child code.

## Observable original-source witness (not a native claim)

Source `CalculateAndDrawAll` cancels its one retained outer `timer`. Original `_DrawAvailableQuest` starts independent `NewThread(function() ... end, 0)` children without retaining/ownership-parenting their timer handles. The new scenario executes original child after the original outer callback-owner was superseded by real `UpdateQuest` under the synthetic host. Test-only counters record original `QuestieDB.GetQuestTagInfo` being called, entry to whole original `AvailableQuests.DrawAvailableQuest`, original child cancel after completion, and the original reset-completion callback still absent.

These events are synthetic callback scheduling observations, not established actual in-game map corruption. Our fake `GetNPC` and `GetObject` intentionally resolve to nil, so **no real map frames, NPC/GO DB, inventory or on-screen graphics are exercised**. We do not assert frame rendering effects or native ordering.

## Counterfactual design contract — model only, NOT a production patch

Separate self-contained host-side `newLedger()` models:

1. Globally monotonic serials and typed `PENDING`, `COMPLETED`, `ABORTED`, `ERROR` terminal states, counted exactly once.
2. Completion waits for an actual parent finish **and** all tracked children, never treating an aborted/errored owner as successful.
3. Starting a newer calculation ABORTS a still-pending owner; stale children cannot publish or report completion.
4. Even when a visible label changes A→B→A, serial mismatch rejects the first A's late callback.
5. Current-owner errors invalidate outstanding writes, duplicate terminal events are rejected; no terminal `COMPLETED` on error.

The ledger is **a deliberately invented proposed interface**, not present in `335` or the user-approved codebase. This synthetic model demonstrates desired isolation properties; actual source currently does **not** implement them. It must not be mistaken for a fix, native acceptance, rollout readiness, or new owner authorization.

## Test and governance

**69 assertions proposed per Lua 5.1.5 and Lua 5.4.6; do not mark passed before verifying pinned exact-head Actions/job logs, clean test checkout, and artifact census.** The first 31 are the previously verified #348 combined original-source checks. New assertions 32–39 target orphan-child source execution; new model checks M01–M30 target the hypothetical contract.

Historical test-only #345 / #346 remain original FAILED fixture heads; corrected #348 original head `fdb0507fcec1e4d903c879425c9b35b0ef4ce128` dedicated [run 40759854445](https://github.com/CosmicCuddle/N-Questie/actions/runs/40759854445) independently **31/31 per Lua** and now **37/37 exact-head Actions SUCCESS**. #347 docs **9/9**, #349 docs **8/8** SUCCESS, each unmerged/draft. Original-source blob pins remain immutable.

CS02 [PR #42 coordination checkpoint](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6479424206) independently reports **438/438 synthetic dual-Lua timing/callback checks** with the caveat **native AnimationGroup event ordering is unknown**; about N≥25 versus N≤24 quest-pointer frame scheduling is a source-based hypothesis, not measured live. Consult source-anchored peer comments before any design decision.

**Gate08 MAJOR RED; 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; 439 RAW candidates unapproved; eligible denominator unknown; pilot 1207–1209 0/3.** No production Lua/SQL, native builds/tests, ZIP, SavedVariables, private data, install, merge, release, tags or outside network. Separate owner authorization and complete addon/account+character backups plus verified rollback are required for native work.


## Original test-only #352 fixture failure (frozen) and separate correction

Original [DRAFT #352](https://github.com/CosmicCuddle/N-Questie/pull/352) exact `693fd4aea95939be40e64221c26a2f7dae482b02` had dedicated [run 40766799344](https://github.com/CosmicCuddle/N-Questie/actions/runs/40766799344), job `123092992675`. Original 335 source blobs authenticated and Lua5.1.5/5.4.6 installed. Existing combined **31/31 source** printed PASS on Lua5.1, and added original-child source checks executed without error, but a **model-only fixture assertion `M20_FRESH_CHILD_ALLOWED` failed** because the fifth model step incorrectly expected third-A serial **3**, rather than **4** (models issue A1, A2, B3, A4, C5). Lua5.4 did not execute; dedicated artifacts **0**. This is a *test expected-value mistake*, not a failure of native 3.3.5a, original source, or a production ownership implementation (none exists). Preserve the original #352 head and its red job unchanged.

New distinct child corrects only two expected counterfactual model serial values: the fresh third-A child expects **4**, the subsequent C token expects **5**. All original source-executed tests, ownership-model logic, workflow, anchors, and 69-assertion census are unchanged. The corrected child is **PENDING independent CI**, not green by assertion or inference. Gate08 MAJOR RED and all production/native protections remain unchanged.


## Part46 isolated child: original writer call-path and failure ordering (TEST-ONLY)

**Scope:** Distinct unmerged child of the frozen corrected #353 original exact head \`5c7df752c0e6ca8aa3d99c4fcc0d14c9e0eb89da\`. No code from \`335\` changed. The test still authenticates the four exact original blobs listed above. Exact original \`SmoothReset\` and \`UpdateQuest\` function bodies, whole original \`AvailableQuests\` and \`ThreadLib\`, and only the original \`Compat\` timer fragment are executed inside a **fabricated** frame scheduler/quest DB. This is not real WoW execution.

**Additional first-party source anchors:**
- \`Modules/Quest/AvailableQuests.lua:233–244\`: \`_DrawAvailableQuest\` launches an independent \`NewThread\` and calls \`QuestieDB.GetQuestTagInfo\` before \`DrawAvailableQuest\`.
- \`Modules/Quest/AvailableQuests.lua:56–79\`: \`DrawAvailableQuest\` looks up starter NPCs/objects and delegates to \`_AddStarter\`.
- \`Modules/Quest/AvailableQuests.lua:270–307\`: original \`_AddStarter\` calls \`QuestieTooltips:RegisterQuestStartTooltip\`, then \`QuestieMap:DrawWorldIcon\` when synthetic NPC spawn coords are present.
- \`Modules/Libs/ThreadLib.lua:38–57\`: coroutine error gets reported and cancels the **child** timer without the parent completion callback.
- \`Modules/Quest/QuestieQuest.lua:335–357, 615–638\`: source reset latch + UpdateQuest supersession, already exercised in the parent fixture.

**Added Part46 source-backed scenarios (S40–S61):** After actual original parent cancellation, the old original child is deliberately resumed in the fake host. A **fictional** NPC (\`id\`, \`name\`, \`spawns\` only) exercises unchanged original tooltip registration then world-icon call. The test records writer inputs in **fake counters/sinks**; no game frame or tooltip is created. Two separate injected fake errors test (a) map sink failure *after* tooltip entry, (b) tag lookup failure *before* DrawAvailableQuest. The unchanged original ThreadLib reports the synthetic exception, cancels that child handle, and does not release the original reset latch. The host determines when callbacks fire, so client reachability and real native consequences remain **UNKNOWN**.

**Added counterfactual contract tests (M31–M45):** A separate invented \`guardedSink\` tests whether a proposed epoch-aware publication veto rejects old A after A→B→A, rejects aborted/error writes, and permits only a fresh owner. This **does not patch** map code, reset code, QuestieDB, or ThreadLib, and is **not** evidence that any such guard already exists.

**CI intent:** 106 checks per interpreter (69 previously checked + 22 authentic-source-under-fake-host assertions + 15 separate model assertions); require exact interpreter job logs and artifact census before claiming success. The original 69-check print is retained as an intermediate check, not a substitute for the 106-check result. A failing head must remain frozen and any fix should use a **separate** child. No new source, SQL, TOC, native QA, real SavedVariables, ZIP/build, installation, tag, merge or release permission. Gate08 MAJOR RED; pilots 1207–1209 remain 0/3.


## Part46 next test-only child: authentic source quest-log and item-check bodies

**Separate child of frozen #357 at \`d5fc41b89219ffe704b52ec44d49cdcea5f77a5c\`**, not a rewrite of any earlier green/red head. Only the same test/CI/research paths changed. Historical source is still exact \`QuestieQuest.lua\` blob \`cd4239c5b40c1f5b1ced823dfa12d8a895091719\`; the previous three original blobs remain pinned and unchanged.

**What is new real original 335 code:**
1. \`QuestieQuest:GetAllQuestIdsNoObjectives\` full **unchanged original function body** from \`QuestieQuest.lua:835–860\`, which clears and rebuilds \`QuestiePlayer.currentQuestlog\` by retaining the object returned by \`QuestieDB.GetQuest\`. Its two separately imported source-item objective *helpers* are mocked as no-ops; those helper functions are **not** executed from original code.
2. \`QuestieQuest:CheckQuestSourceItem\` full **unchanged original function body** from \`QuestieQuest.lua:890–927\`, checking bag slots via \`QuestieCompat.GetContainerNumSlots\` and tenth return value of \`QuestieCompat.GetContainerItemInfo\`, and creating an objective only for absent item with a fake leaderboard/QueryItemSingle.
3. Original \`SmoothReset\`, \`UpdateQuest\`, \`AvailableQuests\`, \`ThreadLib\`, Compat timer fragment continue to execute in the already documented invented AnimationGroup host.

**Control distinction:** The *actual original QuestieDB.GetQuest body*, real quest-cache initialization and actual account/quest-log/bag state remain **UNEXECUTED**. A synthetic \`db.GetQuest(1)\` returns a stable fake quest object, fake \`QuestLogCache.questLog_DO_NOT_MODIFY\` lists ID 1, fake bag returns empty or present item ID 5, and fake source-objective helpers avoid unrelated drawing. This verifies only original **quest-log and item-check branch logic** when these fictional inputs are supplied. It does **not** prove retained \`WasComplete\` occurs or a missing source item is present in actual client memory.

**New S62–S84 checks (23 added):** one cached-object \`WasComplete\` path, one original source-item **missing** path which constructs the original missing-item objective, and a **present-item control** which follows the original normal path and releases the callback. These are source function execution in a fake scheduler/DB and remain synthetic; real 3.3.5a timing and native reachability remain **UNKNOWN**.

**CI proposal:** 129 checks EACH Lua5.1.5 and Lua5.4.6; source blob validation, clean checkout, zero distributed artifacts. **Pending independent exact-head Actions at draft creation; never claim PASS without run/job/log verification.** No actual addon Lua/SQL/TOC changes, native client/realm/account/character/SavedVariables, builds/ZIPs, merge or release. Gate08 remains MAJOR RED; 439 RAW unapproved; pilots 1207–1209 remain 0/3.


## Part46 source-only continuation: whole original QuestLogCache under fake quest-log APIs

**Separate TEST-ONLY child of frozen #359 original exact \`0d11fd60cdef2978ab7b9b4137307ed74dc2172f\`; no production Lua edit, merge or client test.** This child adds a NEW self-contained test \`tests/compat/nq_part46_original_questlogcache_readiness.lua\`, changes the test-only workflow and appends these notes. Original history and every earlier failed/successful PR head stay immutable.

**New fifth original Git blob**: \`Modules/Quest/QuestLogCache.lua\` = \`09e9989922731f899994e6eb09af24465ae196ce\` at historical original \`335\` \`8b23c6e2cfa00bb81cb26d40c44fef154e9e0070\`. The **whole original module** executes unchanged, including its private \`GetNewObjectives\`, \`CheckForChanges\`, \`TestGameCache\`, \`GetQuest\` and \`GetQuestObjectives\`, under **fake client** \`GetQuestLogTitle\`, \`HaveQuestData\`, \`C_QuestLog.GetQuestObjectives\`, sounds and QuestieLib. Its own returned \`questLog_DO_NOT_MODIFY\` table is therefore authentic first-party cache logic; source is hashed before Lua runs.

**New original reset bridge**: unchanged original \`QuestieQuest:GetAllQuestIdsNoObjectives\` body executes against the genuinely built original \`QuestLogCache.questLog_DO_NOT_MODIFY\` table, but its \`QuestieDB.GetQuest\` still returns a **fictional stable quest object** and two source-objective helper functions remain no-op stubs. This distinguishes **QuestLogCache (game quest-log snapshot IDs, title, completion and objectives)** from **QuestieDB's separate quest-object cache (can hold \`WasComplete\`)**, and does not prove the game's real quest item, cache lifetime or reset timing.

**42 explicit positive/negative controls** target: cold empty/valid cache; original objective normalization; authentic cache getters; reset resolving an ID to a separate fake quest object; completed-quest transition/sound; missing \`HaveQuestData\` with retained prior cache; uncached objective text fallback to previous objective; recovery to new objective; cold missing-data and cold missing-objective cases; and header exclusion. Especially significant: a previously cached objective with temporarily unavailable text may be reused by \`CheckForChanges\` **without setting its \`cacheMiss\` result**, even though \`TestGameCache\` returns false. Both behaviours are exact original source branch outcomes under fake inputs, NOT a demonstrated native cache race or defect.

**CI plan:** 129 previously verified source/mocks/model checks per Lua interpreter remain unchanged, plus new 42 authentic-QuestLogCache-under-fake-API assertions per interpreter, distinct logs. Require clean checkout, exact five historical blob pins, all exact-head Actions, and 0 distributed artifacts. At draft creation **no new CI result is claimed**.

**Open:** original real \`QuestieDB.GetQuest\` body and native game data remain unexecuted; real Animation OnFinished timing, first-party sequencing of reset with QuestEventHandler, error terminal release and descendant owner propagation remain unconfirmed. This fixture does **not** justify production code changes, live API tests, account/character access, ZIP, install or release. Gate08 MAJOR RED, 439 RAW unapproved, pilot 1207–1209 0/3.


## Frozen original #361 fixture failure and isolated loader correction (Part46, 28 Oct 2026)

The original [TEST-ONLY DRAFT #361](https://github.com/CosmicCuddle/N-Questie/pull/361), exact head \`8ff8dd38a112c174d302a469840a4c831d81a56a\`, **FAILED its dedicated original-head CI** [run 40772988435](https://github.com/CosmicCuddle/N-Questie/actions/runs/40772988435), job \`123114826568\` on Lua5.1 during the new standalone QuestLogCache host fixture. Authentic exact five source blobs, clean Lua installation and **unchanged pre-existing 129/129 checks on both Lua versions all PASSED BEFORE this failure**. Lua5.4 did **NOT** execute the new 42 checks; zero dedicated artifacts. The failure was **\`attempt to index global 'QuestLogCache' (a nil value)\`** in the unchanged original reset function body after a test-host module-load mismatch. The host registered \`modules.QuestLogCache\` through \`QuestieLoader:CreateModule\` but did not mirror the normal global \`QuestLogCache\` symbol used by the separate extracted original reset method.

This is a **test harness missing global binding**, not proof of an original-source QuestLogCache defect or any native 3.3.5a runtime issue. Freeze original #361 SHA, workflow and its red job as permanent evidence; do **NOT** rewrite or rerun it as a corrected original. Separate corrective child only binds \`env.QuestLogCache=cache\` after successful original module load, leaving the authentic source blobs and all source/control assertions unchanged. **Correction pending independent exact new-head CI at draft creation**, no PASS claimed. Entire game questlog/item and QuestieDB remain fake, and Gate08 MAJOR RED.


## Frozen #362 synthetic completion-sound assertion failure; nil-versus-zero control (Part46)

The separate corrective [TEST-ONLY DRAFT #362](https://github.com/CosmicCuddle/N-Questie/pull/362), original exact \`62a7932f36d0a5c917949c34280d474602ae4f3f\`, **FAILED** its [dedicated run 40773218471](https://github.com/CosmicCuddle/N-Questie/actions/runs/40773218471), job \`123115624544\`, on Lua5.1 at \`C17_ORIGINAL_CACHE_QUEST_COMPLETE_SIGNAL\`; Lua5.4 did not reach the added full-QuestLogCache test. The isolated module binding issue was repaired and authentic source blob verification, 129/129 previous source/model checks on **both** interpreters and earlier new cache assertions C01–C16 passed. **Zero dedicated artifacts.** Freeze its original failure and exact head unchanged.

**Precise original-source root cause, not a game defect:** \`Modules/Quest/QuestLogCache.lua:198–200\` plays completion sound only for \`cachedQuest and (not cachedQuest.isComplete) and isComplete == 1\`. In Lua, numeric **0 is truthy**, so \`not 0\` is FALSE. The invented input \`isComplete=0\` then \`1\` cannot satisfy that sound condition, contrary to the old fixture assumption. A first-party cached \`nil\` completion value followed by \`1\` *can* satisfy the condition. The test expectation was wrong, not the original QuestLogCache source. Do not infer native sound issues or gameplay frequency.

Distinct subsequent corrective child keeps whole original source unchanged and adds explicit **negative \`0→1\` sound count = 0** and **positive \`nil→1\` sound count = 1** controls; new proposed original-cache census becomes **43 per Lua interpreter**, with earlier 129 each unchanged. This is **PENDING separate exact-head GitHub Actions**, not accepted native QA. Original failed #361 and #362 are immutable evidence, and no production code, SQL, client, SavedVariables, install, ZIP, merge or release has been touched or approved.


## Part46 — authentic whole QuestieDB.GetQuest cold create, hit and rebind, test-only (29 October 2026)

This new isolated draft branch is a **child of frozen successful #363 original `7a38bcb09f558cf865ba9aa426644d2e235002fb`**, not a rewrite. Its separate `tests/compat/nq_part46_original_questiedb_object_cache.lua` harness executes the **complete and unchanged original `QuestieDB.GetQuest` function body** from historical `Database/QuestieDB.lua` Git blob `5784cb65160175e1dce30fe20e8baada0af7e480`, the **whole unchanged original `QuestLogCache.lua`** blob `09e9989922731f899994e6eb09af24465ae196ce`, and original `QuestieQuest:GetAllQuestIdsNoObjectives` unchanged body from Git blob `cd4239c5b40c1f5b1ced823dfa12d8a895091719`. The test CI pins all six originals, with the existing reset/thread/available/Compat sources still authenticated.

The test input for QuestieDB is deliberately synthetic `QuestieDB.QueryQuest` rawdata with fake adapter keys `startedBy`, `finishedBy`, and `sourceItemId`, plus fake `QuestieLib.GetTbcLevel`. The original `GetQuest` **source body is unchanged**; its surrounding original private cache local `_QuestieDB` is injected as a synthetic empty table, its original `_IsComplete` dependency is replaced by a trivial unused fake function, and unrelated original entire QuestieDB module initialization and raw query adapters are **not executed**.

Intended independently checkable cases: original cold path creates and inserts the Quest object once; original hot path returns the **same object** without rawdata requery; original `QuestLogCache` separately caches game quest-log title/completion/objectives via fake game APIs; original reset reader takes **game-log IDs** and retains the **original QuestieDB-produced object**. The fixture itself artificially writes `WasComplete=true` to that quest object and demonstrates that repeated original cache lookups / reset log rebuild retain the *same* object/flag, while an explicit **invented host cache clear** changes the identity. The fixture does **not** prove how a real quest flagged complete becomes incomplete, whether original `QuestieDB.Initialize` is invoked at reset, or any native 3.3.5a timing.

39 proposed new checks EACH real Lua5.1.5 and Lua5.4.6, in addition to preserved 129+43 existing checks. **At initial draft this is a proposed census, NOT a verified CI pass.** Source SHA authentication, clean checkout, zero artifacts and no production code changes are mandatory. Protect prior source/fixture failure heads #361 and #362. Gate08 remains MAJOR RED; 439 RAW unapproved, pilot 1207–1209 0/3, no native client/character/bag state, SQL, merge, ZIP, installation or release.

**Independent peer mutation evidence (28 October ~23:20 GMT):** CS02 [PR #42 checkpoint 6483017202](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6483017202) verified original #357 writer-sink source guards kill 15/17 scratch mutants, with model-only `publish` guards G2 and G3 surviving; original #353 legacy model had seven survivors. This confirms that original `AvailableQuests` writer calls are guarded **only in the model**, not source, and suggests follow-on adversarial *forged/retained serial* tickets to make the epoch guard itself load-bearing. **No mutant patch or production fix has been approved or made.** Native scheduler remains unknown.


## Part46 — peer-surviving model-only guard mutants and forged active-owner tickets (29 October 2026)

**New independent child of frozen source-authenticated #366** exact `2387efc957b09ed35bf9bf8c95d6ededdb68eb1b`. Peer CS02 [6483017202](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6483017202) found **model-only** `publish` guards G2/G3 (state-only and same-label plus pending) survived earlier source-writer test assertions; ordinary A→B→A already aborts the old ticket and does not require generation validation to reject it.

A new separate `tests/compat/nq_part46_g08_epoch_forged_ticket_mutant_controls.lua` reuses the *actual test's counterfactual `newLedger` source text unchanged*, constructs a current still-PENDING owner, and tests invalid child tickets having the same current owner **but old or future serial**, and forged different owner object **with same label and serial**. The unchanged test-model guard must reject these while allowing valid child writes. The fixture creates **two deliberately weakened test-model copies only** (publishing based solely on state; publishing based on label+PENDING) by rewriting the extracted `publish` predicate in memory. Both altered copies should **accept** invalid child tickets, demonstrating adversarial controls are now load-bearing. It additionally exposes a *real limitation of the invented model*: an unregistered fabricated child with correct owner+serial and `done=false` can still publish, since children are counted but not individually registered. **This is a counterfactual design issue, not an original-addon defect.**

Proposed new checks 32/32 each Lua5.1.5 and Lua5.4.6 alongside unchanged original source suites 129+43+39 each. **No CI success asserted until new exact-head Actions job/logs verified.** No production addon writer guard, game UI, native timers, actual quest/character data or release permission exists. The real original source writer remains unguarded in synthetic host; native impact and intended descendant ownership policy remain unconfirmed. Gate08 MAJOR RED, 439 RAW unapproved, pilot 1207–1209 0/3.
