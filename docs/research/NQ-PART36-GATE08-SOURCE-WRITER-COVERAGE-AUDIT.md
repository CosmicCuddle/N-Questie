# Gate08 — Source writer and A→B→A coverage audit (Part 36)

**Date:** 2026-10-26. **Status:** PUBLIC-SAFE design/verification, **NOT IMPLEMENTED**, **NOT integration approval**. Protected `335` remains `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. Based on actual public Questie source at draft [#183](https://github.com/CosmicCuddle/N-Questie/pull/183) (`22686e486d15f7f3350f5e3fe7d55fc677a34f81`). Compare this with the [Part35 Gate08 blueprint](NQ-PART35-GATE08-TRANSACTIONAL-COMPILER-INTEGRATION-BLUEPRINT.md).

## Decision: NO epoch completeness claim yet

A monotonically incremented number only proves source consistency when **every relevant mutation** increments it, including a transient A→B→A. The current Questie implementation exports normal writable Lua tables; neither an `__newindex` metatable on the root nor a pre/post deep equality check can capture all in-place and nested writes. **Do not add a cosmetic epoch and switch Stage1 to a transaction.**

### Verified public-source mutation boundaries

| Surface | Verified code location / mutation | Required instrumentation |
|---|---|---|
| Quest, NPC, object and item **base records** | `Database/Corrections/QuestieCorrections.lua::_LoadCorrections` creates missing `QuestieDB[databaseTableName][id]={}`, then sets `[id][key]=value` for each correction; `Initialize()` calls it for Classic, TBC, WotLK and SoD, plus `QuestieCompat.LoadCorrections` | Monotonic mutation counter **before every insertion, replacement, deletion and nested relation edit** or owned read-only input snapshot |
| Quest **nested base fields** | `QuestieCorrections:Initialize` directly sets `quest[requiredRaces]` after derived faction checks | Treat direct field mutation as a writer; require in-scope epoch |
| NPC **nested waypoints** | `QuestieCorrections:PreCompile` writes `npcData[id][waypointKey]` and **yields** during processing | Epoch must account for changes and scheduling; a one-time preflight cannot cover this |
| Faction-specific effective overrides | `QuestieCorrections:MinimalInit` merges correction tables via private `addOverride`: `override_table[id]=data` and `override_table[id][key]=value` on item/NPC/GO/quest overrides | Per-faction views must remain coherent with what was compiled; include both character-faction variants where needed |
| Other base/source transformations | `QuestieQuestFixes:LoadMissingQuests()`, `QuestieDB.private:DeleteGatheringNodes()` and correction hooks in `Compat/` | Audit individual method effects and registration order; no blanket coverage claim yet |
| Addon/late writers | Public `QuestieDB` record and override tables remain mutable by arbitrary Lua modules or third-party addons between coroutine yields | Require a demonstrable exclusive writer contract, or prove *all* reads use an immutable owned generation. Unknown writers are a **hard stop**. |

**Important distinction:** The current [#178](https://github.com/CosmicCuddle/N-Questie/pull/178) effective owner preflight is read-only and checks one effective faction view at a time. [#180–#184](https://github.com/CosmicCuddle/N-Questie/pull/184) only stage/lease/error-handle source **optionally** and do **not** yet enforce epoch ownership across yields. None constitutes a lock on all of the above writers.

### Two acceptable future solutions

**A. Complete guarded-writer epoch:** privatize or instrument *every* relevant source writer including writes through nested references, capture a start epoch and recheck at every compile yield and prepublication. Include a policy for unexpected third-party or out-of-band writes. An uninstrumented writer invalidates proof and requires a hard-stop, not a best-effort warning.

**B. Owned immutable compiler-generation snapshot:** take a version-specific, fully proven immutable input generation covering all four kinds and their effective overrides, then ensure **all** writer/reader paths consume only that copy until verification and publication. Must explicitly benchmark 3.3.5a client RAM/GC; copying every raw row may exceed viable client memory. Do not assume table copy is cheap.

**Current engineering recommendation:** build falsifiable **test-only epoch/ABA contracts** and enumerate the remaining writer paths before choosing A or B. Keep the production Stage1 route unchanged. A writer epoch covering only `_LoadCorrections` would be insufficient.

## Acceptance probes to add on an isolated branch

- **E01 — one persistent change:** mutate a relevant NPC forward owner during a compiler yield; driver refuses publication.
- **E02 — transient A→B→A:** change an approved quest relation from A to B, then restore A during consecutive yields. A final-value equality comparison would pass; complete epoch must require **RETRY**.
- **E03 — nested value:** modify an already-present nested `quest.startedBy[1][1]` or NPC/GO `questStarts` array element; epoch must detect it. A root-only `__newindex` hook is not enough.
- **E04 — override-only owner:** add an item/NPC/GO override record with no base row during a yield; detect even when base table identity is unchanged.
- **E05 — cross-faction:** change one faction-specific approved quest owner override after current-faction preflight, but before publication. Opposite-faction cached login must not accept an unchecked generation.
- **E06 — unrelated writer:** either certify non-interference or conservatively invalidate the whole generation, according to an explicit coverage rule.
- **E07 — unknown third-party writer:** fail closed when writer provenance/ownership cannot be established; no claim of protection from an uninstrumented native Lua write.
- **E08 — unaffected legacy path:** with no transaction owner, original Questie startup and compilation remain byte/semantics compatible; do not change protected `335`.

Tests E01–E08 are **planned**, not implemented or green. Use wholly invented fixture records. Never include owner-private SQL, real source NPC/GO/item/loot relations, or Individual Progression mappings in public GitHub.

## Separate atomicity and recovery gates

Even a perfect epoch does not solve ambiguous `finished()` stream-pool corruption, suspended Lua 5.1 coroutine ownership, commit of all eight binary/pointer fields with matching version/language/count/custom revision, or multi-field disk writes after crash/relog. These remain separately REQUIRED Gate08 tests TX01–TX18.

### Next engineering dependencies

1. **Finish [draft #184](https://github.com/CosmicCuddle/N-Questie/pull/184) strict staged datatype-error review**; verify full exact-head CI and Grok adversarial review. Non-throwing Questie errors must never count as a successful staged category.
2. Add a **driver-controlled current-generation eight-field completeness receipt** so stale previously staged bytes cannot pass. This is not publication.
3. Implement source-writer proof only when all mutation surfaces above are accounted for; request actual 3.3.5a RAM/frame measurements for any snapshot alternative.
4. Continue the full Gate10 **439-record investigation**, with the separately gated initial 1207–1209 pilot 0/3. Neither automatic 439-item inclusion nor merging/release is authorised.
