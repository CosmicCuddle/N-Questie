# Part 41 Gate 08 — real pinned compiler source, fictional failure-injection witness

**28 October 2026 — TEST-ONLY engineering research. RED / KNOWN UNSAFE, NOT a compiler fix.**

## Source provenance and scope

This isolated test executes the exact unmodified functions `QuestieDBCompiler:CompileTableCoroutine(...)` and `QuestieDBCompiler:Compile()` extracted from the **actual protected-335 public `Database/compiler.lua`** at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. The same immutable commit's `Modules/QuestieInit.lua` is read to verify the **static source order** of calling `Compile()`, assigning `nQuestieDataRevision` and setting the local `dbCompiled = true`.

The dedicated workflow checks both tree and fetched temporary-file Git blob identities:
- `Database/compiler.lua`: `abba0249f44d14711dbdd46bbde969ccffbc2963`
- `Modules/QuestieInit.lua`: `22fffa1b1bbeb81ba067f34151949c0938a316c1`

Function boundaries are searched by exact unique signatures. The test runs **only the two actual compiler functions**. It supplies one **invented** row per NPC, GO, quest and item kind, an intentionally minimal in-memory fake stream and codec, and inert Questie/version/logger objects. It does **NOT** execute the complete actual QuestieStream pool or entire initializer, compile real Questie databases, model addon third-party writers, or read owner-private world/loot/IP mappings. Names of fictional source rows are generic and never real server facts.

## Distinct intentional negative cases

Twelve strict controls (to be independently verified on actual Lua 5.1 and 5.4) distinguish the following from a healthy run:

1. **Healthy baseline:** on initial coroutine yield none of eight published fields has changed. A complete one-row compile for all four kinds publishes each `Bin`+ `Ptrs` pair, advances version/count metadata and finishes each stub stream. This avoids an always-failing fixture.
2. **Invalid object type:** the exact real per-kind function logs `Questie:Error`, returns early without signalling a checked result or returning its fake stream, while outer `Compile()` carries on to quest and item, leaves object fields old, **and marks `dbIsCompiled=true` with an incremented version count**. This is a bounded *negative reproduction* against the actual code path; not proof of client-specific data containing this error.
3. **Writer raises in quest:** actual `pcall(writers[t])` catches then rethrows; the current coroutine aborts, prior kind fields remain new, later item fields old, writer stream unfinished. Because the real outer `_isCompiling` flag is still set, a direct retry is refused. A full job/stream-pool reset is not provided by this fixture.
4. **Pointer encoding raises in item:** the real per-kind function writes **`itemBin` before `itemPtrs`**. A manufactured encoder exception leaves new binary paired with old pointers, earlier three kinds already published, metadata still old and fake stream unfinished. This shows why even *within one kind* a non-atomic publish is unsafe.
5. **Stage1 metadata boundary:** static exact-source anchor shows the initializer assigns `nQuestieDataRevision` immediately after calling `Compile()` without testing a checked `SUCCESS` result. **This is a static source assertion, not a dynamic run of the entire Stage1 client coroutine**; do not claim full Stage1 runtime proof.

The assertions deliberately **PASS when known-unsafe behaviours are reproduced**. When a future real fix blocks the unsafe path, these witness assertions must be updated to the new fail-closed expected result, not mislabelled as a regression of safety. Actual WoW 3.3.5a scheduling, UI acceptance, memory use, all writers, and crash/relog durability are NOT TESTED.

## Exit design remains blocked

Only a driver-owned transaction with all-writer source epoch or proven immutable inputs, global QuestieStream pool lease/refcount/quarantine, exact four-kind staging of all eight `Bin`/`Ptrs` fields, metadata and revision validation, checked `SUCCESS/BUSY/RETRY/ERROR` statuses and a strictly no-yield coherent memory publication could safely replace these failure paths. Even that would **NOT** make SavedVariables writes disk atomic; actual client crash/relog and torn persisted-state recovery must remain independently RED. Never monkey-patch global `QuestieStream:GetStream`, assume equivalent final values catch A→B→A, or return a suspended poisoned stream to the global pool.

**Independent CS02 mutation review to request after already queued #267/#270:** bypass the early-return branch, suppress the outer false-success state, swallow a writer exception, make pointer encoding occur before the binary assignment, remove sticky lock/flag or change Stage1 revision order; run pinned source/dual Lua from the original head, revert scratch changes and report harmful survivors. A mutation which **fixes** an expected-unsafe witness should break that named test (not be called a malicious survivor). Audit all original-head workflows and artifact endpoints, including push.

**Governance:** G01–G03 COMPLETE; G04–G09 UNDERWAY; G10–G12 TECHNICALLY PENDING (**3/6/3**). 439 RAW research entries not approved inserts, eligible denominator unknown, pilot 1207–1209 0/3 implemented. No protected `335` change, production patch, private server/loot/IP/SavedVariables disclosure, merge, installation, package, tag or release.
