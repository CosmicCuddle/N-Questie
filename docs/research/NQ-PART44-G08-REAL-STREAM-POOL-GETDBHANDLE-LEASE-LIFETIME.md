# Part44 Gate08 — actual original QuestieStream pool and GetDBHandle lease lifecycle

**28 October 2026 · PUBLIC-SAFE TEST-ONLY RESEARCH DRAFT · NO PROTECTED RUNTIME MODIFICATION, REAL CLIENT, BUILD, ZIP, INSTALL, MERGE OR RELEASE**

## Complete original code being executed

Pinned protected public `335` `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. Exact unchanged `Modules/QuestieStream.lua` Git blob `1819aeea11148eae0742810dbd2338410edda238`, **entire 484-line module executed**. Exact `Database/compiler.lua` Git blob `abba0249f44d14711dbdd46bbde969ccffbc2963`, **whole unchanged `QuestieDBCompiler:GetDBHandle` function** from 1372 through end 1619 executed, not the complete original compiler module.

The original `QuestieStreamLib:GetStream` removes a stream from module-local `StreamPool` via `tremove` (51–70), returns existing same-mode object or makes a new stream, and dynamically assigns raw reader functions. Original `stream:finished()` calls `reset()` and `tinsert(StreamPool,self)` (40–49). No owner/epoch, reference-count or idempotent-finish guard is visible in these functions.

Original `QuestieDBCompiler:GetDBHandle` starts with `QuestieStream:GetStream("raw")` and actually calls `coroutine.yield()` THREE TIMES around pointer loading/decoding and data loading (1372–1384). It creates `QuerySingle` / `Query` closures capturing both the decoded pointer table and that stream, then returns handle with `handle.stream = stream` and `handle.pointers = pointers`. Its own source function has no generation/epoch guard. This is source-level lifecycle evidence, not proof the current addon ever invokes invalid stream release while a handle remains in use.

## New isolated dual-Lua behaviour test

Dedicated read-only workflow verifies both original Git blobs, runs actual Lua5.1.5 and Lua5.4.6, compiles entire actual QuestieStream module and unchanged complete original GetDBHandle body with minimal fictional root-index, reader-map/skipmap and mock `DecodePointerMap`.

**33 assertions per interpreter proposed until exact-head GitHub Actions logs are independently inspected**:

- Original A GetDBHandle actually suspends on each of its three yields, loads fabricated `PTR_A` and raw byte `A`, returns actual original `QuerySingle(55,"value")` = 65.
- Original B handle acquired while A is not finished has its own actual stream object; both fabricated readers return their own bytes.
- **Deliberately INVALID use:** test calls genuine original `handleA.stream:finished()` while A's QuerySingle closure still exists, then obtains C handle. The genuine original stream pool returns that same A stream object for C. A's retained original QuerySingle now observes C's fictitious binary byte 67, even though its captured pointer map remains A. This is not a claim normal code releases readers early.
- **Deliberate duplicate invalid finish:** original `finished()` called twice on the same pool object; two later actual original handles can share that same stream and thus read the latest invented data. This is a controlled lease-misuse negative test, **not evidence such double finishing happens in real runtime**.
- Confirms no actual packets, private SavedVariables, native client, original binary pointer decoder or production writer. A minimally mocked `bit` shim is only for module load; raw byte read path remains original.

## Gate08 implication, not implementation permission

Any future approved generation publisher/consumer needs an explicit source-scoped stream lease: never return a stream to the global pool while any reader/query closure, validator or deferred consumer still references it. `finished()` should be owned exactly once and quarantined after aborted writers until safety is proven. Pool reuse and epoch identity must both be tracked; checking pointer ID membership alone cannot certify retained closure source coherence. Need further original call-site census for who calls `finished()`, how original GetDBHandle proceeds under coroutine interleaving, and all source writers E01–E08 or third-party changes. No production adaptation is made by this test.

**Hard boundaries:** Gate08 MAJOR RED; 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING, 439 RAW unapproved, denominator unknown, pilot 1207–1209 0/3. Real four-kind eight Bin+Ptrs and metadata atomic commit, original compiler full integration, stream handler ownership under native frame scheduling, disk/SavedVariables crash/relog and WoW 3.3.5a Individual Progression still not accepted. No protected source changes, merge, build/ZIP, install, tag or release. Future native validation requires explicit owner approval, complete Questie-335 and both account/character SavedVariables backups and verified rollback.
