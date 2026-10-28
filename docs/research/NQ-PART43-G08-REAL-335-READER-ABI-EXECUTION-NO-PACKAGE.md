# Part43 Gate08 — executing the unchanged original 335 DB reader ABI (TEST ONLY)

**28 October 2026 · public safe · isolated source-backed draft · NO package/ZIP/client/install/merge**

## Why this experiment

[Draft #304](https://github.com/CosmicCuddle/N-Questie/pull/304) demonstrated a shadow fail-closed compiler generation with `SUCCESS/BUSY/RETRY/ERROR`, private staging and a single **model-only** generation pointer. However, N-Questie’s original `QuestieDB:Initialize()` does **not** read that model pointer; it uses eight direct legacy global (or SoD) fields. We need to test the actual reader code before proposing a production adapter.

The dedicated job authentically pins `Database/QuestieDB.lua` from protected 335 commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, original Git blob `5784cb65160175e1dce30fe20e8baada0af7e480`. Lua extracts and **executes the entire unchanged original `QuestieDB:Initialize()` body** from line 220 to immediately before `GetObject()` (original line 313), including popup/error control, four handle assembly calls, exported pointers and functions, memoization, and cache resets. It runs in entirely fictional independent Lua5.1/5.4 hosts with invented `OLD_BIN_...`, `NEW_BIN_...`, `SOD_BIN_...` values. Crucially, **`QuestieDBCompiler:GetDBHandle()` is a fictional recording stub, not the authentic decoder or QuestieStream**. No player/realm/account/SavedVariables data or actual addon client.

## Tests and expected evidence

A passing dedicated run must independently confirm **32/32 assertions in each Lua version**, including:
- Original 335 non-SoD branch grabs exactly four Bin+Ptrs pairs from `Questie.db.global`, regardless of a separately populated `global.published` generation;
- Original consumer constructs four query handles with those direct values, pins query and pointer functions, clears five related caches and configures two memoized helpers;
- Replacing the unused shadow generation pointer does **not** change new or already-existing original handles, nor does invoking original `QuestieDB:Initialize()` again while legacy fields remain old;
- Invented mismatched `npcBin` and `npcPtrs` are passed as such to the recording `GetDBHandle`; this **does not prove the real factory accepts them without error**, only that the original caller has no precheck;
- Writing all eight direct legacy fields as a complete new generation allows the original reader to observe them on a later reinit, while already-pinned query closure continues holding its earlier bytes;
- The original reader does not validate the compiled version or custom data revision before making those query handles (those checks happen elsewhere);
- Separate original `Questie.IsSoD` selection reads `global.sod` fields independently, not the proposed shadow pointer;
- A conceptual one-reference *future* reader snapshot retains a coherent old generation while a separate new pointer is substituted. The conceptual adapter is **NOT** any source function currently used by the addon.

## Required design work, NOT permission to change production

A future practical solution must coordinate the fail-closed writer with a matching reader-side generation binding; explicit old-format SavedVariables migration and rollback; SoD and ordinary 335 selection; query handle lifecycle and cache coherence; E01–E08 actual source writer captures and external aliases; QuestieStream global pool leases/quarantine; atomic in-memory and recovery semantics on real SavedVariables disk; and native 3.3.5a plus Individual Progression tests. Any original 335 direct field-API rewrite is a **separate, unapproved production change**. Gate08 remains MAJOR RED even when these diagnostic tests pass. Protected source unchanged, no building, packaging, installation, client actions, merge, tag or release. Whole-project gates 3 COMPLETE/6 UNDERWAY/3 TECHNICALLY PENDING; 439 RAW unapproved, eligible denominator UNKNOWN, pilots 1207–1209 0/3.
