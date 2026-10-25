# N-Questie Part 34 — Effective owner closure and compiler transaction acceptance

> **Status: public-safe engineering design and test acceptance, NOT implemented.**
> Scope: AzerothCore / World of Warcraft 3.3.5a, Questie compatibility only. All sample identifiers in the isolated research suites are fictional. This document MUST NOT be used to publish private server SQL, real quest↔NPC/GO/item/loot links or Individual Progression source mappings.

## 1. Immutable comparison and implementation boundary

- Protected upstream baseline: `335` at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. Implement on a separately reviewed draft; never overwrite the protected branch.
- Existing loader research: [PR #168](https://github.com/CosmicCuddle/N-Questie/pull/168) current `17a442520901a22644f49acef8a213cc4802eba3`. **6/6** PR workflows passed; actual GitHub Lua 5.1 and Lua 5.4 **101/101 each**, actual pinned Questie item-starter codec **12/12**. Five `KNOWN GAP` assertions deliberately show that the *item-only* postflight does **not** refuse invented NPC/GO inconsistencies. Do not invert them while the current fixture applies only a subset of approved fictional corrections.
- NPC/GO closure research: [PR #171](https://github.com/CosmicCuddle/N-Questie/pull/171) current `bd623b11e4167f4f3bcb53d05dadcbc375e7b968`. **7/7** PR workflows passed; actual Lua 5.1 **42/42** and Lua 5.4 **42/42** on [run 40243902146](https://github.com/CosmicCuddle/N-Questie/actions/runs/40243902146); **0 artifacts across all seven runs**. It is a standalone proof, **not invoked from Questie init or compiler**. Independent CS02 review of whether newest synthetic probes kill previously surviving M6r/M16 mutants remains pending.
- Four-category pinned-source research: [PR #167](https://github.com/CosmicCuddle/N-Questie/pull/167), `1ab7006d369d78fc74162e589119ee5d5a3f505d`, **7/7** PR workflows with **105/105** source-backed Lua5.1 checks. The **production** `Database/compiler.lua` is still not repaired.
- Completion cache: [PR #169](https://github.com/CosmicCuddle/N-Questie/pull/169) is research/CI only, not proof of the real 3.3.5a client CLEAR-vs-ADD-ONLY semantics; duplicate comparison #170 must not be integrated as a second copy.

**No merge/release condition is satisfied by these test-only passes.** No real quest sources for 1207–1209 may be inserted without privately completed Gate09 provenance; current implementation remains **0/3**.

## 2. Source-backed runtime order and effective data view

The following statements are properties of the pinned Questie source, not promises of the proposed solution:

1. `Modules/QuestieInit.lua` Stage1 loads the base DB, runs `QuestieCorrections:Initialize()`, yields for other initialization, runs `QuestieCorrections:PreCompile()` (which itself yields), checks `QuestieCompat.VerifyNQuestieCustomItemSources()` for custom records, then invokes `QuestieDBCompiler:Compile()` and subsequently updates `nQuestieDataRevision`. The existing compiler has no sufficient success status for Stage1 to trust.
2. `Database/Corrections/QuestieCorrections.lua` calls `QuestieCompat.LoadCorrections()`, then `QuestieCorrections:MinimalInit()`. The latter merges faction overrides into `questDataOverrides`, `npcDataOverrides`, `objectDataOverrides` and `itemDataOverrides`. The compatibility correction registry in `Compat/Compat.lua` iterates categories with `pairs` (no guaranteed order); callbacks within a category use `ipairs`.
3. `Database/compiler.lua::GetDBHandle` supplies a `QuerySingle` function that returns the **whole overridden field** when present, before reading the pointer-backed binary field. Overrides can therefore produce effective fields for IDs missing a raw compiled pointer; checking only raw `npcData` or `objectData` is not an effective-view proof.
4. `Database/compiler.lua::CompileTableCoroutine` periodically yields, acquires a pooled writer stream, and publishes each category's binary/pointer pair before the next category has been verified. Its invalid datatype bare `return` and throwing writer path can bypass the normal `stream:finished()` release.
5. `Database/compiler.lua::Compile` sets `_isCompiling` to true, but the pinned code never resets it to false; BUSY and successful completion cannot be reliably distinguished by Stage1. `GetDBHandle` acquires a reader stream **before** yields to decode its pointer map; malformed decode can fail before the returned handle exists. Wrapping yielding work inside ordinary `pcall` is not Lua 5.1 coroutine-safe.

## 3. Planned effective-view owner contract (not production code)

Build an explicit approved plan `Q` from the reviewed custom records only. Then, **after all applicable registered corrections and `MinimalInit()`**, define each faction-specific/effective `quest.startedBy`, `quest.finishedBy`, NPC `questStarts`/`questEnds`, GO `questStarts`/`questEnds`, and item `startQuest` using their exact Questie numeric keys.

- Define forward tuples `F = (kind, ownerId, customQuestId, start|finish)` from **approved custom quest** NPC/GO startedBy and finishedBy list slots. For each approved quest compare each full effective forward slot to the approved plan as an **unordered set**; reject both extra and missing owners. Preserve empty slot distinctions, numeric ID bounds, dense arrays and duplicate refusal for fields referencing protected custom quests.
- Define reverse tuples `R` by **one full pass over the union** of raw NPC/GO owner IDs and any override-only owner IDs. For each owner, read the **effective whole field**, and collect references to quests in `Q`. Require `F == R` in **both directions**; reject an unplanned foreign owner, missing reverse owner, and start/finish role swaps.
- Do not globally reject valid legacy records merely for sparse/duplicate **unrelated-only** reverse lists. If an effective relation contains *any* approved custom quest ID, validate the entire relation densely and reject duplicates, bad types and over-bounds. Malformed non-table reverse fields and malformed override categories/entries must return an explicit typed refusal rather than silently allowing an unreviewed owner.
- Retain the **separate** scalar `item.startQuest` ↔ `quest.startedBy[3]` check from #168, scanning the whole effective item owner universe for unplanned backlinks. Validate any item query-time override paths independently. Never interpret item objectives or loot as an approved item starter.
- Quest objective NPC/GO IDs are **not** evidence that those objects offer or finish the quest. Keep the approved direct starter/finisher plan independent from kill, object and item objectives.
- If faction corrections can supply an approved quest/owner relation, either prove F==R **separately for each applicable effective faction view** with source-backed tests, or **fail closed** on such an override. Do not assume a raw-view pass proves Horde and Alliance query behavior.

### Correct synthetic fixture prerequisite

The current #168 item-only test deliberately simulates applying quest corrections for only **two** fictional quests. That is sufficient for its item-focused regression but **not** for a verifier over all approved fictional quests: a full forward checker falsely trips on other un-applied fixture records. Before changing #168's `KNOWN GAP` oracles into required refusals:

1. Create a **separate complete effective-view fixture** (do not weaken or overwrite the existing partial-item fixture).
2. Apply **every** approved fictional quest correction and its planned NPC/GO/item reverse corrections, plus the expected faction override layers. Instantiate callback-order permutations where order is intentionally unspecified.
3. Assert F==R on the legitimate complete fixture; add a foreign reverse owner **outside F**, a missing reverse link, both forward superset and subset, role swap, an override-only owner, mixed custom/unrelated malformed relation, and legitimate unrelated legacy duplicates/sparse arrays.
4. Only then invert the five #168 gap characterizations into fail-closed required refusals; the already reviewed public 2001 fingerprint and item-only quest/startQuest cases must continue to pass unchanged.

## 4. Compiler-yield ownership boundary

A synchronous one-time owner scan immediately before `Compile()` is **necessary but insufficient**: category encoding subsequently yields. Likewise a final checksum is insufficient against a transient ABA writer (`expected → foreign → expected`) during yields.

A safe integration must choose and test **one explicit boundary** before production editing:

**Option A — source-epoch write ownership:** all owned source writers are routed through a controlled epoch gate. While staged compilation is active, mutations to any covered nested quest/owner list and effective override are rejected or cause an observable transaction abort. No uninstrumented writer path is permitted. Lua 5.1 `__newindex` alone cannot intercept changes to existing nested keys; do not treat a metatable wrapper as comprehensive write tracking.

**Option B — immutable owned snapshot:** capture the exact corrected effective source graph used for the compile transaction, with no mutable nested references to live tables. Build and encode from the same snapshot. Memory/heap impact is unknown and must be measured on the actual 3.3.5a client before use.

Until one option is peer-reviewed, exercised across every compiler yield, and shown to refuse a transient ABA writer, **Gate05 remains UNDERWAY**.

## 5. Four-category transaction and failure state machine

The eventual Gate08 implementation must return one explicit status from `SUCCESS`, `BUSY`, `RETRY`, or `ERROR`, and must preserve old published cache + revision when any category fails.

| Condition | Required behavior |
|---|---|
| Existing compile already owns the epoch | `BUSY`; no new publication or metadata increment |
| Recoverable source epoch mismatch or change during a yield | `RETRY`; discard staged products, old cache unchanged |
| Invalid datatype, malformed pointer map, writer/readback failure | `ERROR`; release owned leases, old cache unchanged |
| Four distinct category Bin/Ptrs pairs encoded and verified against frozen effective source | `SUCCESS`; publish all **eight** fields and dependent version/language/expansion/count/revision metadata in a no-yield commit section |

Reader/writer stream leases must be tracked by the coroutine **driver/transaction owner**, including a failure before a handle is returned. On Lua 5.1 do **not** wrap yielding routines in an ordinary `pcall`; use a driver that observes `coroutine.resume` failure and always performs finalization after that failure, with regression cases for failed lease acquire, malformed pointer decoding and writer exception. Cleanup must not release a stream twice or return a still-live stream to the pool.

`Modules/QuestieInit.lua` may set `dbCompiled=true` and `nQuestieDataRevision` **only after explicit compiler SUCCESS**. Validate genuine BUSY (no-op), failure → repaired input → retry SUCCESS, stale source across yield, and all four category readbacks before any metadata advance.

An in-memory no-yield commit is **not** a proven SavedVariables/power-loss atomic transaction. Crash/persistence durability requires a separate rollback and actual client QA gate; do not claim it from synthetic Lua.

## 6. Required independent acceptance and rollback

1. **Lua 5.1 first:** actual pinned codec/source testing and exact interpreter verification. Re-run Lua 5.4 as a cross-check, not a substitute.
2. **Mutation proof:** independently kill one-directional `same()` mutants in *both* directions (M6 and M6r), missing non-table refusal (M16), omission of raw∪override owner-union keys and mistreatment of unrelated-only lists. Positive 42/42 alone does not establish mutant kills.
3. **Failure injection:** unexpected writer, override drift, forward/reverse orphan, compile lease leak, invalid codec datatype, malformed pre-handle pointers, source epoch ABA during yield, and failure → retry should all fail closed **without** publishing any category or revision.
4. **Actual 3.3.5a gameplay QA:** backup/rollback plan first, measure startup frame time, GC/heap, both faction effective views, real client completion-cache CLEAR/ADD-ONLY hypothesis, relog/reload and map marker display. Then, and only then, verify private Individual Progression eligibility outside public GitHub.
5. **Final integration gates:** fresh source review, all exact-head CI checks, independent CS02 review, zero unexpected artifacts, privacy audit, owner-facing testing evidence and explicit release authorization.

## 7. Current non-goals

No production patch, no actual quest 1207–1209 insertion (still **0/3**), no public private source mappings, no client/server/SavedVariables changes, no automatic packages or deployment, and no merge or release decision are authorized by this document. The user-approved Gates 10–12 allow development but remain **technically pending**.
