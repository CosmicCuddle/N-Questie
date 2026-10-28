# Part43 G08 — unchanged original 335 DB reader plus Journey Search generation transition

**28 October 2026 · PUBLIC-SAFE TEST ONLY · draft, no production edits, ZIP/install, merge, tag or release**

## Provenance and why this test

Preceding separate public-safe diagnostics: real 335 `QuestieDB:Initialize()` under invented decoder (#306), private shadow generation adapter (#308), **entire genuine `QuestieSearch.lua`** under invented query and pointer records (#311), and the first-party alias classifier (#315). #315 original `fe3680e7f49e5710a4c36313c8dfa2e942b1225c` independently passed 25/25 dedicated assertions: 36 naive assignments comprise 12 exported LHS writes, 23 RHS query/handle values and 1 guard; 14 naive callback candidates are seven actual function-value arguments, seven ordinary calls. Actual original SearchResults helper functions use callback query arguments *synchronously*. Still no accepted production reader/writer synchronization.

This new isolated **test-only** child of frozen #315 executes the original, unmodified **`Database/QuestieDB.lua` `QuestieDB:Initialize()`** (full original function) **and the full unmodified `Modules/Journey/QuestieSearch.lua`** together in the same fictional host. CI pins protected public `335` commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` and authenticates original Git blobs:
- `Database/QuestieDB.lua` `5784cb65160175e1dce30fe20e8baada0af7e480`;
- `Modules/Journey/QuestieSearch.lua` `999efb373c5cc61f258115cf89e5e587cc087855`;
- `Modules/Journey/QuestieSearchResults.lua` `00b1b0382d301d2839f0cd7c30fe8ff7ac143353` (source anchor only);
- `Modules/Quest/AvailableQuests.lua` `2664f09fdf1f5df4d94581414e9d5ea88e9af4e7` (source anchor only).

## Test-only proposed transition contract

- **OLD** reader is created by real original DB Initialize using synthetic old Bin strings, two old records/pointers for *each* NPC/Quest/Object/Item. Full real original Search runs on the matching four query/pointer pairs, populates old `LastResult`.
- **Staging** prepares invented NEW Bin/Ptrs and metadata off to the side, yielding after each kind. A second request returns BUSY; current reader set, old Search results and old database remain unchanged.
- **Validation** requires matching source owner, monotonic epoch (including A→B→A), revision and available state. Invalid pointer maps, final item writer failure, or error in fourth fictional `GetDBHandle` leave OLD selected with no success signal.
- **Prepare reader** privately executes real DB Initialize and real Search in a fresh synthetic environment. The actual Search `:ByName("token")` is run on all four NEW kinds *before* the model pointer selection; its `LastResult` therefore contains only new IDs.
- **Commit** is exactly one no-yield selection of an invented `host.current` reader+search group, which is **not** an original production API. Old reader closures and old search cache remain pinned and independently queryable.
- **KNOWN UNSAFE comparator:** a separate fictional host reassigns the genuine old module's exported `Query*Single` and `*Pointers` fields to valid NEW fields without invalidating the original Search `LastResult`. The genuine `:Search` carries OLD IDs forward while adding NEW IDs; the genuine `:ByName` resets. Merely pairing query and pointer exports is insufficient for cache correctness.

The fixture proposes **54 assertions on each real Lua 5.1.5 and Lua 5.4.6**; passing must be independently proven from the exact-head dedicated CI logs, not claimed at creation. The original `GetDBHandle` binary decoder is **fictional**, and `NEW`/ `OLD` query records are fabricated. The test confirms only the unmodified source functions' behaviour against a model interface; it does **not** implement a new actual QuestieDB Query* dispatcher, SavedVariables schema, client event hooks or live addon loader.

## Remaining red gates

A real solution must safely integrate all original Query*/_Query* APIs, four pointer maps, derived caches, Journey Search/Results, AvailableQuests, Quest/Comms/Tracker plus external readers with a source-aware writer fence and immutable reader generation lifetime. Original E01–E08 and untracked source aliases, global pooled QuestieStream leases/quarantine, coherent 8 Bin/Ptrs plus metadata publication, persistent 335 SavedVariables migration, crash/relog rollback, native WoW 3.3.5a + Individual Progression remain unproven. Thread scheduling in a native client is not reproduced. Gate08 **MAJOR RED**, overall **3 COMPLETE/6 UNDERWAY/3 TECHNICALLY PENDING**; 439 RAW quests unapproved, denominator unknown, pilot 1207–1209 0/3. Protected `335` unchanged. No real realm/account data, production Lua/SQL edits, ZIP/build/install/merge/tag/release; owner must approve any future private playable package and client installation separately, preceded by backups of `Interface/AddOns/Questie-335` and both account/character SavedVariables sets, with rollback.
