# Part42 Gate08 — actual protected-335 correction writer and compiler A→B→A witness

**Public-safe TEST-ONLY research (28 October 2026).** No production code, private world data, client SavedVariables, or release operations.

## Source-authenticated execution boundary

Three unmodified source files from protected `335` commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` are fetched, tree-blob verified, staged and hash-verified byte for byte:

1. [`Database/compiler.lua`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/compiler.lua) Git blob `abba0249f44d14711dbdd46bbde969ccffbc2963`: actual complete `CompileTableCoroutine`, pointer encoder/decoder and `GetDBHandle` functions.
2. [`Modules/QuestieStream.lua`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Modules/QuestieStream.lua) Git blob `1819aeea11148eae0742810dbd2338410edda238`: the complete actual module with module-local stream pool.
3. [`Database/Corrections/QuestieCorrections.lua`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/Corrections/QuestieCorrections.lua) Git blob `0584d2d6c0ff8c6e04c0fd0152d9c524bbf0345d`: extracts and executes the **actual unchanged function bodies** of local `_LoadCorrections`, local `addOverride`, and `QuestieCorrections:PreCompile`, using a tiny synthetic host instead of invoking the complete `Initialize` or `MinimalInit` client lifecycle. Static pins also verify the derived `requiredRaces` assignment and `QuestieCompat.LoadCorrections` call sites; **these two are not executed**.

All source mutations are of fictional rows 1–8 or fictional 504 NPC waypoint placeholder records. No real quest/NPC/GO/item/loot IDs, no private SQL, phase policy or IP mapping.

## Main new falsification

The parent [#282](https://github.com/CosmicCuddle/N-Questie/pull/282) showed fictional direct source A→B→A. This child executes an **actual production-source correction writer** within that schedule:

- Actual protected `CompileTableCoroutine` is suspended before row 1.
- Real unmodified `_LoadCorrections("npcData", ...)` changes fictional source row 1 from `11` to `33`.
- Actual real compiler writes `33` into its real shared QuestieStream, then yields.
- Real `_LoadCorrections` restores row 1 to `11`, and the compiler publishes its old transient `33` result.
- The real `GetDBHandle` and pointer decoder then read back **33**, even though the latest source is **11**.

This is a **known-unsafe intentionally orchestrated schedule**: it proves the source function has the relevant write capability and the compiled reader sees the transient mutation. It does **not** establish that normal game startup schedules that writer in between these yields, nor that it is an unowned writer under actual runtime policy.

## Additional coverage (new controls W34–W51)

- Real `_LoadCorrections` creates missing base rows, obeys `noNewEntries` and `noOverwrites`, and can write invented entries into each of the four base kind tables.
- Real `addOverride` creates override-only rows and merges existing override keys in-place. A fictional two-faction map exercise demonstrates disjoint views, **not the actual WoW faction-selection logic**.
- Real `PreCompile` edits invented waypoint fields, yields after 502 optimizations, and resumes to finish; this demonstrates **partial source mutation across an actual yielding function**, not actual RDP geometry (the `OptimizeWaypoints` dependency is a synthetic stub).
- A **fixture-only** monotonic epoch explicitly incremented before each real correction writer call refuses publishing the A→B→A stage. This is **not** instrumentation added to the actual `_LoadCorrections` function and cannot detect unknown third-party writers.
- Previous 33 source-backed compiler / synthetic guard controls are retained; **51 strict controls** required in each PUC Lua 5.1/5.4 VM.

## Remaining hard Gate08 blockers

None of E01–E08 is accepted as a fully authenticated client writer proof. Additional actual writers include derived `requiredRaces`, `MinimalInit` faction overrides including both native views, compatibility callbacks, late database transforms and unknown third-party addon aliases. Real excluded writers/provenance, owned immutable-generation capture without inter-copy race, real exact-once stream pool ownership/quarantine, full checked four-kind binary/pointer+metadata transaction and actual 3.3.5a client SavedVariables disk/relog/crash tests are all RED.

This is a **test-only draft**. Original protected `335` and all peer-reviewed draft heads remain immutable. No merge, install, package, ZIP, tag or release. Gate totals **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**; 439 RAW records are research-only, eligible denominator UNKNOWN, pilot 1207–1209 remains 0/3 implemented.
