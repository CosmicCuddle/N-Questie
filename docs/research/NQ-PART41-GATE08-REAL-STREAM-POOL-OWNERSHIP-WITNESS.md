# Part41 Gate08 — actual global QuestieStream pool: public owner-lifetime evidence

**28 October 2026 — PUBLIC-SAFE TEST-ONLY; known-unsafe misuse witnesses, not an API repair and not gameplay acceptance.**

## Exact public source scope

The dedicated workflow stages complete, unmodified protected-`335` `Modules/QuestieStream.lua` and `Database/compiler.lua` from immutable `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, verifying both their Git tree identities and staged file hashes:
- Stream: `1819aeea11148eae0742810dbd2338410edda238`.
- Compiler: `abba0249f44d14711dbdd46bbde969ccffbc2963`.

The test executes the **ENTIRE real stream module** unmodified with only synthetic `QuestieLoader`/logger and a tiny pure-Lua `bit` stand-in appropriate for the tested raw-byte path. The shared `local StreamPool={}`, real `GetStream`, `finished`, `reset`, `Save`, `Load` and raw byte methods actually run. The separately pinned compiler is **static evidence only** for `GetDBHandle` acquiring a raw stream and yielding **before** an owned handle is returned. Neither full compiler integration nor WoW's live thread scheduler runs. No real private NPC/GO/loot/IP/SQL or client SavedVariables are accessed.

## Reproducible observations in fictional schedules

14 checks (await independent actual Lua 5.1/5.4 CI evidence) cover default stream state, byte round-trip, missing mode rejection, reset on return, same-mode pool reuse, distinct simultaneous unreturned loans, raw decoder reloading and mode mismatch.

They deliberately reproduce three known-unsafe **caller-misuse** schedules:

1. **Use-after-return:** A previously returned stream object remains a live Lua reference. After another borrower receives the same object, a write through the stale reference changes the new owner's bytes. No stale-reference invalidation or generation token exists in this implementation.
2. **Double `finished()`:** The real `_StreamFinished` unconditionally inserts its stream into `StreamPool` each time, with no checked owner identity, lease generation or released-state guard. Two returns add the **same object twice**; two later simultaneous `GetStream("raw")` calls each receive that same object, and their writes are shared. This is not evidence production calls `finished` twice; it is a concrete hazard **if** the caller violates exactly-once return.
3. **Premature return of suspended coroutine's stream:** The controlled test externally calls `finished` on a stream while its owning coroutine is paused and still intends to write. A second borrower receives and modifies that same object, and the original coroutine resumes against the new state. The healthy control confirms that the stream remains distinct if it is **not** returned while suspended. This is a forbidden ownership schedule, **not proof a normal Questie workflow performs it**.

A related design issue is **shared pool scope**: the exact `StreamPool` is module-local and common to unrelated users of the same imported module. Changing `GetStream` globally to intercept compiler leases would risk corrupting those users. A safe integration must own and quarantine leases without global monkey-patches.

## Gate08 exit criteria remain RED

- Complete real caller inventory, source E01–E08 and A→B→A monotonic ownership/epoch coverage, or proven immutable input snapshot; source equality alone cannot certify writer exclusion.
- Full actual `GetDBHandle` allocation/reader decode/yield and four-kind compiler build lifecycle, including unexpected errors. Never `finished()` a suspended/poisoned/unowned stream, never reuse until owner dead and return proven exactly once. Global pool requires explicit unknown-state recovery.
- Four-kind compiled `npc/obj/quest/item` binary+pointer **eight fields** and revision/version/count metadata must stage privately and publish together in no-yield coherent memory operation after source verification and codec-readback checks; checked `SUCCESS/BUSY/RETRY/ERROR` required. An in-memory no-yield transaction still does **NOT** make disk SavedVariables crash/relog atomic.
- Actual native 3.3.5a and owner-approved IP gameplay, memory/GC/frame and genuine power loss/relog recovery are independently RED.

**Mutation review request to CS02**, only after older #267, #270 and #272: independently alter `_StreamFinished` to detect already-returned leases; add a stale-reference invalidation, and prevent release during coroutine suspension; make sure named known-unsafe controls now **fail appropriately** (a real fix must change the expected negative assertion), and harmful weakened test assertions are identified; test pristine actual Lua5.1/Lua5.4, revert all local mutations, comment-only, no pushes.

**Governance:** G01–G03 COMPLETE; G04–G09 UNDERWAY; G10–G12 TECHNICALLY PENDING (3/6/3). 439 RAW exploratory, approved eligible denominator UNKNOWN, pilot 1207–1209 0/3 implemented. Never merge/install/package/tag/release, change protected `335`, or publish owner-private world SQL/NPC/GO/item/loot/IP relations or user SavedVariables.
