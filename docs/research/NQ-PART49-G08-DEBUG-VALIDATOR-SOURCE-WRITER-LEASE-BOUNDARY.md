# Part49 Gate08 — debug validator source mutation and reader-lease exit audit

**30 October 2026 UTC | PUBLIC-SAFE | SOURCE INSPECTION / DOCS-ONLY / PROPOSED REVIEW GATE.**

This is a **new specific source-writer and reader-lifetime audit**. It does not modify original N-Questie Lua/TOC/DB, prove an in-game issue, select a production fix, authorize a client test, pass Gate08, or approve a merge/install/package/release. Every code reference below is to the **immutable historical original 335 addon code** `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, NOT the protected live README-only `335` Git HEAD `26053bd28b0df3a01e5859f779d5f3cb4f57b221` (last verified protected=true).

## 1. New source-writer class: the debug validator itself

**Confirmed source fact:** [original `Database/compiler.lua:1327–1357`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/compiler.lua#L1327-L1357), immutable Git blob `abba0249f44d14711dbdd46bbde969ccffbc2963`, contains the following within `QuestieDBCompiler:ValidateQuests()`:

```lua
local b = nonCompiledData[QuestieDB.questKeys[key]]
-- inside the type(a) == "table" branch:
if key == "extraObjectives" then
    for i = 1, #b do
        if not b[i][4] and a[i][4] == 0 then
            b[i][4] = 0
        end
    end
end
```

Here `nonCompiledData` is iterated directly from `QuestieDB.questData`; `b` is the **original nested record value**, not a deep copy. The assignment writes `0` into the fourth field of the underlying `extraObjectives[i]` source row **if** the decoded compiled comparison element has fourth field `0` and the original row fourth field is nil/false. This appears intended to normalize comparison against the codec's 24-bit zero representation, but it is **an actual in-place source-table mutation on the stated conditional path**. No actual qualifying quest row or owner-client event has been demonstrated by this audit.

**Execution gate:** [original `Modules/QuestieInit.lua:210–249`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Modules/QuestieInit.lua#L210-L249) compiles a stale database, initializes its DB handles, and later calls `runValidator()` ONLY when `Questie.db.profile.debugEnabled` AND `dbCompiled` AND `skipValidation ~= true`. [`runValidator` at lines 117–145](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Modules/QuestieInit.lua#L117-L145) calls NPC, object, item and quest validation. This source write is therefore **post-compilation** on that debug-enabled validation branch; it is NOT proof of a concurrent mutation during the earlier compiler yields.

**Gate08 consequence:** the earlier [Part36 writer audit](NQ-PART36-GATE08-SOURCE-WRITER-COVERAGE-AUDIT.md) explicitly covers corrections, derived faction values, waypoints, overrides and unknown addons, but does not enumerate this validator's post-compile nested source write. Any future *complete writer census* and source-generation/recompile policy must include it. A generation read-only/freeze contract cannot simply declare all validators to be non-mutating without either demonstrating a copy or enforcing a no-writer boundary. Do NOT silently patch a source-field normalization or change SavedVariables semantics.

## 2. Conditional reader-lease cleanup on early validation exits

Original [`Database/compiler.lua:1063–1370`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/compiler.lua#L1063-L1370) has these source-level paths:

| Validator method | `GetDBHandle` calls before validation | Ordinary successful cleanup | Early mismatch/error exits before cleanup |
| --- | --- | --- | --- |
| `ValidateNPCs` | 1 NPC reader | `validator.stream:finished()` | number/string/table mismatch returns early |
| `ValidateObjects` | 1 object reader | `validator.stream:finished()` | number/string/table mismatch returns early |
| `ValidateItems` | **3 readers:** item `validator`, object `obj`, NPC `npc` | ALL THREE `stream:finished()` at end | missing object/NPC drop relation or number/string/table mismatch returns early |
| `ValidateQuests` | 1 quest reader | `validator.stream:finished()` | number/string/table mismatch returns early |

**Important positive qualification:** `ValidateItems` **does** release all three handles on its successful path; do **not** claim they are always leaked. The risk is specifically **an early return after acquisition without reaching the ending `finished()` calls**, or a failure in the reader setup/handling before a safe cleanup boundary.

Original [`GetDBHandle:1372–1390`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/compiler.lua#L1372-L1390) acquires `QuestieStream:GetStream("raw")` **before three coroutine yields and pointer-map load/decode**; `handle.stream` is assigned only AFTER the final data load. A failure in this interval is separately a **pre-handle reader ownership** issue already recognized in Part35. The newly confirmed contribution of this memo is the **normal early-return/mismatch paths after successful acquisition**, particularly the three-reader `ValidateItems` case.

**Do not infer:** actual leaked-stream count per real client session, permanent pool contamination, native user-visible defect, completion of a clean `finished()` call, or a proven safe double-release fix from static reading. The original stream pool may retain other references; effect on runtime memory/pool health requires a distinct, reviewed experiment. No real runtime failure was observed.

## 3. Required falsifiable checks BEFORE claiming safe integration

These are **unimplemented acceptance proposals**, not green tests or permission to modify code:

1. **W01 — validator must not mutate owned source:** record immutable input nested row before/after each validator with an invented `extraObjectives[i][4]=nil` and a decoded `0`. Either restore exact bytes/table structure or justify a *registered* intentional source-writer epoch under a separately accepted policy. Do not merely compare scalar equality where `nil` and `0` differ.
2. **W02 — no silent writer bypass:** if design uses a complete writer epoch or immutable generation snapshot, all post-compile validator branches and any subsequent source reuse must be governed by the same documented generation contract, including debug enabled/disabled and `skipValidation` gates. Confirm legacy and 3.3.5 custom-quest revision semantics first.
3. **L01 — all successful exits:** individually instrument the **unchanged original** NPC, object, item (three leases), and quest reader handles under a fabricated host. Each successfully acquired stream must receive exactly one safe terminal `finished()` on the ordinary success path; reproduce original behaviour separately from proposed cleanup.
4. **L02 — all early exits:** inject a controlled invented mismatched numeric/string/table row and a missing item-drop NPC/object relationship. Establish which **already acquired** reader streams would remain unreleased under unchanged source. Do not infer a runtime memory leak beyond this test.
5. **L03 — failure before the returned handle exists:** stage pointer-load/decode/reader failure at the existing original `GetDBHandle` yield boundary; require driver-owned cleanup/quarantine of any acquired stream without guessing `handle.stream` exists.
6. **L04 — safe re-entry:** only after a separately approved driver contract, verify that repeated validation/compile attempt cannot reuse a busy, poisoned, suspended, double-returned or unknown-condition pool stream; compare success/error/abort outcomes. `pcall` is not a general substitute for coroutine-owner release across yields.
7. **NATIVE STILL REQUIRED:** after explicit CosmicCuddle approval and verified disposable staging backups and rollback, benchmark real WoW 3.3.5a performance, `SavedVariables` disk persistence/relog, client startup and IP markers. No synthetic fixture alone passes Gate08.

## 4. Distinctions from prior work and decisions

- The **Part35 Gate08 blueprint** already rejects early publication of the eight SavedVariables Bin/Ptrs fields, unchecked status propagation and ownership gaps in `GetDBHandle`; this memo does not claim those earlier risks are new.
- The **Part36 writer audit** already rejects a cosmetic source epoch and unknown writes; **new concrete addition** is the debug quest validator's own nested `extraObjectives` source assignment.
- The **Part43 DB consumer audit** already shows consumers retain direct eight-field handles, making one-pointer shadow publication non-drop-in. The validator's early-exit lease obligations must be accounted for within any such architecture.
- The earlier reward-title-only [Part49 DOCS #428](https://github.com/CosmicCuddle/N-Questie/pull/428) and [source TEST #429](https://github.com/CosmicCuddle/N-Questie/pull/429) are **separate subjects**; no source fix or additional quest-completion test is proposed here.
- **No Maintenance routing now:** these are original N-Questie addon internal findings. Search central existing Issues before any future issue; only a concrete installed-server or inter-project dependency justifies a new cross-project request.

**Gate08 remains MAJOR RED.** Gate10 has **439 RAW unapproved** research candidates, and missing quest pilots **1207–1209 remain 0/3 implemented**; these are separate from the older 16-quest public-data M2.2 representability pilot. Protected live branch, source and pending approval gates remain untouched.
