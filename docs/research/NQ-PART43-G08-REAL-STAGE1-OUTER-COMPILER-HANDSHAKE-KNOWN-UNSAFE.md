# Part 43 Gate08 / Alpha0 — original Stage1 ↔ outer four-kind compiler handshake witness

**2026-10-28 · PUBLIC-SAFE TEST ONLY · isolated DRAFT · NO ZIP / build / install / release**

## The specific integration question

Earlier frozen [#300](https://github.com/CosmicCuddle/N-Questie/pull/300) passed **35/35** real-source Stage1 cold/warm Lua5.1 and 5.4 tests in invented hosts, but it stubbed the entire `QuestieDBCompiler:Compile()`. We now connect **both unmodified original function bodies** to investigate concrete return/status, partial-publication and re-entry hazards at the exact boundary used by normal 3.3.5a startup. This is targeted further engineering, NOT an approval to generate a playable Alpha0 build.

**Immutable public protected `335` source:** `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.
- `Modules/QuestieInit.lua`, blob `22fffa1b1bbeb81ba067f34151949c0938a316c1`: unmodified `loadFullDatabase`, `runValidator`, complete Stage1.
- `Database/compiler.lua`, blob `abba0249f44d14711dbdd46bbde969ccffbc2963`: **unmodified complete actual outer** `QuestieDBCompiler:Compile()` source, ending before `ValidateNPCs`.

The new dedicated CI verifies both original Git blob hashes, stages source only to runner temporary storage, and executes extracted functions under PUC Lua 5.1.5 and 5.4.6. **Per-kind `CompileNPCs`, `CompileObjects`, `CompileQuests`, `CompileItems` are intentionally synthetic writer stubs** to make partial state observable with tiny invented strings. The game client, AceDB, QuestieStream and all real serializer and correction implementations are NOT executed or claimed verified by this test. No real character, account, SQL, NPC/GO/item/loot/IP mapping or SavedVariables are imported.

## Source-grounded hazard and test claims

Original outer `Compile()`:
1. If `_isCompiling` is already true, simply `return` (no BUSY vs SUCCESS marker to caller).
2. Sets `_isCompiling = true`, then calls four per-kind compilers **in order**, and only afterwards writes expansion and version/locale/`dbIsCompiled`/count metadata. The actual per-kind source in the same original compiler file directly writes each kind's Bin then Ptrs; no common one-step all-eight publication is visible in this source.
3. Does not reset `_isCompiling` on success or on a throwing per-kind failure.
4. Real Stage1 unconditionally writes `nQuestieDataRevision` and proceeds to DB initialization once `:Compile()` returns without throwing. A BUSY no-op is indistinguishable from completed compilation to that caller.

Fictional tests preserve the previous 35 Stage1 controls and add 20 source-backed outer-handshake controls (55 total): clean real outer success and expected four-kind order, eight synthetic Bin/Ptrs writes and trailing metadata, one-shot compiling flag, silent duplicate call, failures at object and item stages that expose partial synthetic Bin/Ptrs updates while old metadata persists, subsequent failed retry due to retained flag, and most importantly a **pre-busy+stale custom revision** with preexisting old compiled metadata: original Stage1 completes and writes the *new* `nQuestieDataRevision` without executing any of the four per-kind writers. A fresh matching-cache simulation then follows the warm route. These are **deliberately constructed scheduling and data fixtures**, not evidence ordinary native login has actually exhibited this scenario.

The outcome is expected to be **KNOWN UNSAFE** for these deliberately created conditions. A passing test means the unsafe behavior was successfully witnessed, **not that the compiler was fixed**. Do NOT weaken Gate08 to green on this basis. A real fix must coordinate all E01–E08 + unknown writer source capture, exact-once global QuestieStream ownership/abort quarantine, coherent eight Bin+Ptrs and metadata no-yield atomic publication, distinguish BUSY/RETRY/ERROR/SUCCESS to the caller, persist/recover SavedVariables safely, and pass native 3.3.5a plus Individual Progression QA.

## Run and approval boundaries

CI must be checked on exact original draft HEAD for real Lua 5.1 and 5.4 logs and zero artifacts before a passing claim. Earlier frozen #297–#299 harness failures remain historical; frozen corrected #300 original source test remains untouched. Every changed path in this child is test-only script, dedicated CI and this note. The original `build.py` still chooses the wrong folder/TOC and omits Compat; `release.py` can tag/commit. Neither is run. This does not create an addon directory, ZIP, install, SavedVariables or release, nor permit any of these without owner's separate explicit approval.

Project remains **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**, Gate08 **MAJOR RED**. 439 RAW quest research records are not approved, eligible denominator unknown, pilots 1207–1209 still 0/3.
