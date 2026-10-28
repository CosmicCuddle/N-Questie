# Part42 Gate08 — source-backed real compiler, global pool and A→B→A witness

**28 October 2026. PUBLIC-SAFE TEST-ONLY.** This isolated draft does not edit protected `335`, install a client, modify production Lua, use private world SQL/NPC/GO/item/loot/IP data, read SavedVariables, package, tag or release.

## What is genuinely executed

The GitHub workflow fetches protected public commit [`8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`](https://github.com/CosmicCuddle/N-Questie/commit/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070), checks its **exact tree Git blobs** and rechecks all staged file bytes:

- [`Database/compiler.lua`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/compiler.lua) blob `abba0249f44d14711dbdd46bbde969ccffbc2963`. Executes the **unmodified complete actual** `CompileTableCoroutine`, `EncodePointerMap`, `DecodePointerMap` and `GetDBHandle` function bodies. This is **not** the outer four-kind `Compile` or full Stage1; do not attribute global atomicity checks to this fixture.
- [`Modules/QuestieStream.lua`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Modules/QuestieStream.lua) blob `1819aeea11148eae0742810dbd2338410edda238`. Loads the **entire unmodified actual module**, including its closed-over module-local `StreamPool`, `GetStream`, reset, `finished`, raw writer, raw decoder and `Load` methods.

The minimal test-only environment supplies `tremove=table.remove`, a pure-Lua `bit` shim and a one-field fictional u8 codec writer that actually uses the real stream `WriteByte` method. It stages a static compiler import via the module's actual `GetStream("raw")`; no global `GetStream` monkey-patching. There are **no real quest IDs, server NPCs or private eligibility records**: the invented source table uses only numeric indexes 1 and 2 and values 11, 22, and 33.

## Strict 17-control dual-Lua contract

1. Healthy: real per-kind compilation yields before writing and between synthetic rows, retaining an old published blob during the unfinished writer.
2. Real source-backed binary and pointer-map publication finishes. The actual global stream pool recycles the finished real writer stream into the actual `GetDBHandle` reader; `QuerySingle`, `Query` and `QueryValidator` recover exact invented 11/22 data, while another live stream remains distinct.
3. **KNOWN UNSAFE intentional A→B→A source-writer schedule:** while `CompileTableCoroutine` is suspended, invented row 1 changes from 11 to 33; the real compiler then serializes **33**, after which a fictional source writer restores 11 before the final publish. The final source equals the original 11, but the actual compiled `Bin` retains 33, and actual `GetDBHandle` returns 33. Hence testing only source values before/after cannot exclude transient writer changes. This does not prove a native runtime writer makes that mutation.
4. A deliberately injected fictional codec exception on the second row triggers the actual `pcall`/error branch, leaves an unreturned real borrowed stream and does not publish new binary/pointers.
5. An intentionally invalid fictional u8 string enters the real compiler's early-return branch without calling `finished()`; a primed real pooled stream is no longer available to a second borrower.

These diagnostics are not safety fixes. Mutation/recovery tests must distinguish good fixes which break expected unsafe witnesses from harmful changes. In particular, a correct epoch lease, copied immutable snapshot or safe writer exclusion could intentionally invalidate the A→B→A witness. The passed test **does not prove normal addon gameplay can perform these schedules**.

## Blocking safety obligations

- Source-write epoch must be proven for **every** E01–E08/correction/phase overlay writer including true A→B→A, not only a fictional mutated Lua table.
- Shared `QuestieStream` pool must have real owner-aware exact-once lease/quarantine on aborted and suspended reader/writer paths. This fixture demonstrates no client-controlled recovery.
- Outer compiler needs checked `SUCCESS/BUSY/RETRY/ERROR`; stage all **eight** NPC/object/quest/item Bin+Ptrs fields and expansion/locale/revision/version/count/source epoch in one private generation; validate/read back and atomically publish in one no-yield section.
- WoW 3.3.5a SavedVariables real on-disk flush/crash/torn-write/relog recovery remains wholly **unverified**, as do Individual Progression native client and owner-private quest eligibility.

**No gate promotion:** 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; Gate08 MAJOR RED. 439 RAW candidates are research-only, eligible/approved denominator UNKNOWN, pilots 1207–1209 remain 0/3 implemented. No protected-335 modification, owner-private disclosure, merge/install/package/tag/release.

CI on real Lua 5.1.5 and 5.4.6 must check all 17 labels and three exact output lines. Any failed original head, diagnostics, step logs and artifact endpoint findings must be preserved; correction on a **new isolated child** only.
