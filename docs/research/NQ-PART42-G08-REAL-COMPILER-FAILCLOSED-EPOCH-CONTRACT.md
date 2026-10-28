# Part42 Gate08 — fail-closed source epoch guard around real compiler (public-safe test model)

**Date:** 28 October 2026. **Authority:** test-only isolated draft, no protected `335` edits and no runtime integration.

## Engineering objective

Frozen [#280](https://github.com/CosmicCuddle/N-Questie/pull/280) executes the unmodified real **per-kind** compiler, pointer encoder/decoder, actual `GetDBHandle` and complete real global QuestieStream module. Its fictional source writer changes row 1 from 11→33→11 across real compiler yields, leaving a stale byte 33 even after the source returns to 11. This new child builds a **falsifiable guard-shell model**, not a production guard, that accepts a staged generation only if all writers were already certified and the *monotonic epoch* is unchanged.

The test stages the real compiler's output in a private invented `Questie.db.global`. A **different** fictional public holder exposes an older generation as **one reference**. The guarded model checks writer provenance, start-vs-final epoch, completion and pointer output, then performs a final check and one no-yield reference swap. Production Questie still publishes per-kind fields directly; no production use of this model is enabled.

## Authentic source boundaries

CI pins Git tree and temporary byte hashes at protected-335 commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`:
- [`Database/compiler.lua`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/compiler.lua) Git blob `abba0249f44d14711dbdd46bbde969ccffbc2963`, with unchanged `CompileTableCoroutine`, `EncodePointerMap`, `DecodePointerMap`, `GetDBHandle`.
- [`Modules/QuestieStream.lua`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Modules/QuestieStream.lua) Git blob `1819aeea11148eae0742810dbd2338410edda238`, entire unchanged shared module-local pool.

The test-only source remains two invented u8 rows, not real quests. The model's `state:write()` explicitly increments a private epoch **before** changing an existing nested field. An `unknownWrite()` **simulation** marks provenance uncertified. That flag is only provided by this fictional test driver; the existing client cannot automatically identify unknown addon writes. The `untrackedWrite()` control demonstrates how an unregistered alias can defeat a falsely claimed complete epoch.

## Strict 33-control dual-Lua scope

Existing exact-source checks C01–C17 are retained and followed by E18–E33:

- E18–E21: healthy, **certified** unmodified fictional source => real codec staged bytes/pointers, successful fixture-only reference publication with metadata and actual decoder readback. Prior generation stays intact.
- E22–E25: a **registered transient A→B→A** increments the epoch twice; the actual compiler still serializes B, but the *fixture* refuses publication as `RETRY` and leaves the previous generation intact.
- E26–E27: registered persistent and already-existing nested-index edits refuse publication. A root `__newindex` metatable is not assumed adequate.
- E28: an **explicitly certified** noninterfering unrelated write does not require retry. Real production classification still needs proof.
- E29: an **explicitly flagged unknown** writer leads to `ERROR` even when final source equals original and no epoch increment exists. This does not discover unknown writers on its own.
- E30: **EXPECTED KNOWN UNSAFE**: if an unregistered writer changes A→B→A while provenance is falsely claimed complete, the epoch remains unchanged and the model **incorrectly publishes B**. This is evidence that a cosmetic epoch is not a safety feature.
- E31: a registered mutation between the first final check and the last prepublication check must cause `RETRY`; the test-only final reference swap has no yield or callback.
- E32: injected codec exception from the **real compiler** cannot publish an incomplete stage through the fixture.
- E33: direct update to an **existing** nested Lua table key does **not** call `__newindex`, demonstrating the known Lua metatable bypass.

**Important:** These controls prove neither an authenticated writer registry nor full 4-kind publication. They operate on invented scheduling and an invented public holder, even though the compiler/pool functions are actual unmodified protected source. The model is **not** a production patch, no source epoch protocol has yet been accepted, and no proof covers actual E01–E08, third-party aliases or native WoW addon callbacks.

## Remaining release-blocking evidence

The existing [Part36 source-writer audit](https://github.com/CosmicCuddle/N-Questie/blob/3bd3ba5723b58606dee380d70336651945cca590/docs/research/NQ-PART36-GATE08-SOURCE-WRITER-COVERAGE-AUDIT.md) and [Part37 copy-race decision](https://github.com/CosmicCuddle/N-Questie/blob/3bd3ba5723b58606dee380d70336651945cca590/docs/research/NQ-PART37-GATE08-OWNED-SOURCE-GENERATION-DECISION.md) still govern. The actual full base/derived/override/faction writer inventory must either be completely fenced including unknown writers or a genuinely owned immutable capture must be established without an inter-copy race. A correct production solution also requires quarantine of real stream leases, checked `SUCCESS/BUSY/RETRY/ERROR`, private four-kind **eight Bin+Ptrs fields plus all metadata**, and atomic no-yield publication, followed by genuine 3.3.5a SavedVariables disk/crash/relog and native Individual Progression testing.

Project totals remain **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**, Gate08 MAJOR RED; 439 RAW public research records are not approved quest additions and the denominator is UNKNOWN; pilot 1207–1209 remain **0/3 implemented**.

No owner-private SQL/NPC/GO/item/loot/IP mappings or SavedVariables are in this draft. No owner approval has been given for production edits, merge, client install, package, tag or release. Keep all failed initial heads, CI logs, artifact inventories and peer findings. Run strict dual Lua 5.1.5/5.4.6 dedicated controls before declaring this isolated experiment successful.
