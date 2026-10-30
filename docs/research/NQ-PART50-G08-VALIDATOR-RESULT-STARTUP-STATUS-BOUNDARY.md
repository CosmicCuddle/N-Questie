# Part 50 Gate08 — debug validator result propagation and startup status

**30 October 2026 UTC | PUBLIC-SAFE | SOURCE REVIEW / DESIGN-ONLY | NO IMPLEMENTATION OR NATIVE QA**

> This is a narrow control-flow finding in the **immutable historical original addon source** at commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, **not** an in-game reproduced bug, owner-approved fix, failed client test or authorisation to change production. Default protected `335` was last verified at `26053bd28b0df3a01e5859f779d5f3cb4f57b221` (README-only N-Questie changes). No raw private DB or player data used.

## Source-backed findings

### 1. Individual validator results do not supply success/failure status

[Original `Database/compiler.lua:1063–1370`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/compiler.lua#L1063-L1370), pinned Git blob `abba0249f44d14711dbdd46bbde969ccffbc2963`, defines `ValidateNPCs`, `ValidateObjects`, `ValidateItems`, and `ValidateQuests`.

- An identified numeric/string/table mismatch calls `Questie:Warning(...)` and performs a **bare `return`**, with no explicit `false` / `ERROR` status. `ValidateItems` additionally calls `Questie:Error(...)` then a bare `return` for a missing referenced NPC or object in an item-drop relation.
- On the ordinary successful path, all four methods reach their final `stream:finished()` calls and log a debug success message, but **also have no explicit return status**.
- Therefore a caller cannot distinguish normal success and one of these handled early exits merely by inspecting the Lua return value: both return `nil`. This concerns **handled warnings/errors that return normally**. A thrown Lua exception is a different control-flow path and is **not** described as silently successful.
- Earlier [Part49 #430](https://github.com/CosmicCuddle/N-Questie/pull/430) identified the early-return reader-lease cleanup issue; [TEST-only #431](https://github.com/CosmicCuddle/N-Questie/pull/431) executed original individual validator methods under invented data and fake reader handles. **This memo's distinct addition is the enclosing Stage1 result/diagnostic boundary**, not an extra claim that reader leaks occur in-game.

### 2. Original `runValidator()` continues after a handled mismatch

[Original `Modules/QuestieInit.lua:117–145`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Modules/QuestieInit.lua#L117-L145), pinned Git blob `22fffa1b1bbeb81ba067f34151949c0938a316c1`, invokes the four validation methods **sequentially** and does **not** inspect their return values or maintain an aggregate `PASS/FAIL` variable. It yields between validation calls.

- If `ValidateNPCs` emits a non-throwing mismatch warning and returns, `runValidator()` proceeds to the object, item, and quest validators (unless a later call throws or the stage/coroutine is interrupted).
- If a raw source kind is unexpectedly still a `string`, `runValidator()` calls `Questie:Error("Cannot run the validator on string data, load database first")` and returns without checking those four kinds. The caller does not inspect this result either.
- This is **not** evidence that non-debug startup is supposed to fail on every data difference. Validation is gated by the original debug mode and recompile path; changing its semantics requires separate review.

### 3. Stage1 prints an unconditional completion message, then cleans raw tables

[Original `Modules/QuestieInit.lua:239–258`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Modules/QuestieInit.lua#L239-L258) calls `runValidator()` only under `Questie.db.profile.debugEnabled and dbCompiled and skipValidation ~= true`, then immediately prints `Load and Validation complete.` without examining validation results. On the normal return path, the stage invokes `QuestieCleanup:Run()`.

- The **success-sounding message establishes that execution passed the call site**, not that all four validators made it to successful terminal checks.
- [Original `Modules/QuestieCleanup.lua:7–20`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Modules/QuestieCleanup.lua#L7-L20) removes the four raw DB source table fields and several language lookup fields, then calls `collectgarbage()`. It does **not** explicitly finish abandoned validator streams. Because an unreturned original stream does not enter the stream pool solely by GC, **pool checkout, memory retention, and any later impact require separate measurement**; do not call this measured or permanent leakage.
- Since the debug validator runs **after** compiler publication, a future transactional compile cannot rely on the current debug `runValidator()` or message as a mandatory **prepublication** proof. This is a separation of acceptance stages; it does **not** establish an actual changed client record or runtime corruption.

## Specific validation boundary that must be designed before any repair

| Case | Original source response | What the future Gate08 *contract* must distinguish |
| --- | --- | --- |
| V01: all four debug validators finish normally | Four final `finished()` calls (item validator finishes three readers), message printed | Explicit `PASS` with all acquired leases accounted for |
| V02: NPC/object/item/quest comparison mismatch | Warning, bare return from that method, subsequent validators can run, message still possible | Explicit `FAIL`/diagnostic, safe lease ownership; **never infer success from the print** |
| V03: missing item-drop NPC/object | Error log, bare return; item validator's three readers can remain unfinished | Distinguish handled validation failure from thrown exception, account for all three reader leases |
| V04: raw DB table unexpectedly string | `runValidator()` emits error and returns; Stage1 message can still print | Explicit `NOT_RUN/INVALID_INPUT`, not `PASS` |
| V05: exception or externally aborted coroutine | Different path; success message/cleanup may not execute | Driver-owned error/abort/quarantine semantics; never force `finished()` on an active or possibly contaminated stream |
| V06: `debugEnabled=false`, `skipValidation=true`, or no recompile | Validation skipped by documented gate | `NOT_RUN` distinct from `PASS`; do not silently redefine legacy debug mode |

**All V01–V06 are proposed *future design/acceptance cases*, not newly passing tests or a mandate to make historical debug mode fatal.** In a future transaction implementation, the compile driver must have a separately defined **prepublication** result/receipt and account for source ownership, all four typed compiled Bin/Ptrs pairs, revision metadata, failure handling and crash/relog. Do not take the four legacy debug validators' `nil` returns as a transactional success receipt.

## Evidence and duplication safeguards

- Existing [#297](https://github.com/CosmicCuddle/N-Questie/pull/297) and [#302](https://github.com/CosmicCuddle/N-Questie/pull/302) already execute authentic original Stage1 and `runValidator` under *fabricated* host APIs for cache/recompile and outer compiler branches. They do **not** by themselves establish native validation-mismatch behavior.
- Existing [#431](https://github.com/CosmicCuddle/N-Questie/pull/431) covers source method bodies and return-before-`finished()` under invented comparisons. No repetitive assertion-only fixture is warranted just to confirm a straightforward return-value gap.
- [Part41/42/44](https://github.com/CosmicCuddle/N-Questie/pull/431) also include synthetic experiments on the *real* `QuestieStream` pool and `GetDBHandle` with fabricated bytes; they do **not** show normal client releases a stream twice or that any particular in-game bug occurred.
- **Next material engineering evidence** should target the separately unresolved Gate08 owned-source generation, safe driver-owned reader leases, eight-field-plus-metadata coherent publication, and WoW 3.3.5a/IP crash/relog/GC/frame tests **only after fresh owner approval** for native staging and backups.

## Safety and disposition

**Confirmed source:** debug validation has no aggregate status; handled mismatches do not stop the enclosing `runValidator()`; a completion message may appear after a handled warning; raw cleanup follows a normal Stage1 return.

**Unverified:** any real quest mismatch, user-visible false success, actual stream/memory leak, client crash, and server interaction. **Proposed:** V01–V06 as a future driver diagnostic/lease acceptance boundary.

**No original addon Lua/TOC/SQL/DB change, no native client, no player files, no archive/ZIP, build, merge, install or release.** The independent [#430](https://github.com/CosmicCuddle/N-Questie/pull/430) writer/reader finding and [#431](https://github.com/CosmicCuddle/N-Questie/pull/431) test remain immutable. Gate08 remains **MAJOR RED**; 439 RAW candidates unapproved; missing-quest pilot 1207–1209 still 0/3 implemented. The protected `335` branch stays untouched.
