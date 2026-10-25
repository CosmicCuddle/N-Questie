# N-Questie Part 32 — production compiler integration contract

> **PUBLIC-SAFE ENGINEERING PROPOSAL — NOT IMPLEMENTED.**
> Pinned World of Warcraft 3.3.5a/AzerothCore source review. No private SQL, NPC, game-object, item, loot, client source mapping, or live character information belongs here. Do not merge or package on the strength of this document or any synthetic fixture.

## Exact evidence boundary

- Protected `335` baseline `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`; unchanged.
- Actual `Database/compiler.lua` blob `abba0249f44d14711dbdd46bbde969ccffbc2963`, `Modules/QuestieStream.lua` blob `1819aeea11148eae0742810dbd2338410edda238`.
- The compiler schema spans four kinds: npc (15 roots), object (6), quest (30), item (16) = **67 root fields** referencing **20 codecs**.
- Draft [#167](https://github.com/CosmicCuddle/N-Questie/pull/167) exercises *real pinned writer and unmasked decoder code* in standalone Lua 5.1, but its staged transaction is **test-only**, not in the protected production loader.
- Complete-field synthetic values, rare nested records, real full-source shapes, crash persistence, and game-frame memory budgets are different acceptance gates.

## Confirmed, unsafe existing production behavior

1. `CompileTableCoroutine` returns normally after invalid datatype logging, even though that category remains unpublished. Other kinds may already be replaced and `Compile()` can advance success metadata.
2. `Compile()` returns without an explicit result when `_isCompiling` is true; the caller cannot distinguish BUSY from a successful completion. The guard is not an explicit retry protocol.
3. `QuestieInit.Stages[1]` calls `loadFullDatabase()` (base, corrections, townfolk, locale, gathering, yielding `PreCompile()`) and then calls `QuestieDBCompiler:Compile()`; immediately afterward it sets `nQuestieDataRevision` and `dbCompiled=true`, without a checked compiler SUCCESS result.
4. The original compiler emits the four binary/pointer pairs *per kind*, rather than atomically staging all four in local values before publishing. It constructs `for id=0,max_id` even for sparse IDs, before its first yield.
5. `GetDBHandle` yields during pointer decode. Consequently **no Lua 5.1 `pcall` wrapping the yielding section**, and no temporary global binary/handle replacement while a coroutine is suspended. After a handle is constructed, non-yielding field readback can be protected with cleanup.

## Proposed **separate reviewed production patch** — sequencing contract

1. **Source owner**: identify every producer/writer through base loading, correction dispatch, source registration, race inference, townfolk and `PreCompile()`. Implement one explicit freeze/ownership barrier. Invariant: no untracked writer may mutate a source record between creating the witness and publication. A final live digest alone misses transient G0→G1→G0 (ABA).
2. **Snapshot/witness**: produce an independently checked, coherent source plan after all applicable corrections. Prefer bounded, per-field or generation-protected witness designs over unbounded full database deep-copy. Observe legitimate shared references and metatables; rejecting them in a tiny scratch prototype is **not evidence** they are absent in production.
3. **Stage**: use sorted explicit IDs rather than scanning 0 to maximum ID; require 1..16777215 integral IDs, at most 65535 IDs in one kind's pointer map, pointer offsets/encoded binary within 24-bit bounds. Stage all four Bin/Ptrs pairs without modifying the global published fields.
4. **Verify**: preflight raw pointer header length/count, duplicate ID, range, planned ID/offset and unexpected extra bytes **before** a yielding decoder acquires a stream. Decode using real `GetDBHandle(bin,ptrs,skipmap,keymap,nil)`; compare to the frozen witness by codec semantics, not generic loose numeric tolerances. Clean up reader streams after all *catchable post-acquisition* assertion failures. Validate category/source relation closure.
5. **Status**: define disjoint results `SUCCESS`, `BUSY`, `RETRY`, `ERROR`. Invalid writer types, pointer corruption, source mismatch, staged readback mismatch or abort must never silently flow to success. Only SUCCESS can advance the custom data revision and compiled cache metadata. BUSY must not set `dbCompiled=true` at Stage1.
6. **Publish**: after all four categories and source postflight succeed, publish eight category fields plus compiler version/language/expansion/count and N-Questie revision in a final **no-yield** segment, preserving old values on all *catchable* aborts. No-yield *does not* imply a durable disk or SavedVariables crash-atomic transaction.
7. **Restart/retry**: specify bounded RETRY scheduling, a BUSY caller path, idempotent attempts, an explicit compile-owner release on terminal paths, and a safe fallback if the old compiled representation has an incompatible data revision. Do not allow downstream QuestieDB initialization to assume success on a failed compile.

## Synthetic regression and independent QA acceptance

| Test axis | Required before production merge |
|---|---|
| Four-category semantics | All 67 root schema fields, nested objective/spawn/waypoint/trigger/sentinel cases and precise codec-specific canonical normalization |
| Negative codec edges | Out-of-range lengths and IDs, invalid nested tables, malformed binary/pointers, duplicate IDs and pointer-geometry corruption |
| Failure/success transitions | Each of four category aborts, decode failure, late writer mutation/ABA, busy lock, fail→retry→success, source generation |
| Source closure | Effective custom quest/NPC/GO/item manifest, starter/finisher/objective/reverse indexes; distinguish item-started quests from item objectives |
| Scheduler | Real QuestieInit/ThreadLib Lua 5.1 coroutine path; yield ownership, callback ordering, late-writer safeguards; no phantom compiled-success |
| Client safety | Actual WoW 3.3.5a frame-time stalls, peak Lua heap/GC, SavedVariables recovery and rollback; large/sparse IDs |
| User acceptance | Actual client and Individual Progression eligibility/markers/loot, then reviewed packaging/CI and release gate |

**Excluded quests:** 30000–30004. Missing-quest implementation 1207–1209 remains **0/3**, already owner-approved but technically dependent on private source/loot/IP proof. Keep the 439 raw inventory reconciled as 21 conventionally linked (12 review + 9 deferred) and 418 exploratory.

**Team:** Grok's draft #166 is untouched during his owner-reported break. Only resume peer-review requests after the owner announces his return. The master 12-gate checklist lives on draft #96; its Gate 08 remains UNDERWAY until actual production integration and separate QA.
