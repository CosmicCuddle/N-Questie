# Part43 Gate08 — authentic 335 Journey search query/pointer pairing and stale results

**28 October 2026 · PUBLIC-SAFE TEST ONLY · direct child frozen draft #308 · NO runtime edit, ZIP, install, merge, tag or release**

## Original source provenance and the concrete consumer boundary

This test fetches immutable protected original `335` commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` and authenticates Git blobs:
- `Modules/Journey/QuestieSearch.lua`, `999efb373c5cc61f258115cf89e5e587cc087855`.
- `Modules/Journey/QuestieSearchResults.lua`, `00b1b0382d301d2839f0cd7c30fe8ff7ac143353`.
- `Modules/Quest/AvailableQuests.lua`, `2664f09fdf1f5df4d94581414e9d5ea88e9af4e7`.

The **full, byte-for-byte original** `QuestieSearch.lua` is executed, not rewritten. The test supplies only invented, tiny and reversible NPC/object/item/quest query-function closures and corresponding per-kind pointer maps. No AzerothCore data, N-Questie quest mapping, player account, SavedVariables, actual binary compiler/decoder or WoW client is accessed. Two other actual source files are authenticated and their exact consumer anchors inspected but are **not executed**.

Actual original `QuestieSearch:Search()` line 72 onward, especially lines **78–89**, reads `QuestieDB.QueryNPCSingle` and `QuestieDB.NPCPointers`, with analogous separate pairs for objects, items and quests. Lines **113–157** iterate the selected pointers, invoke the selected query closure for name search, or match ID strings. The original `QuestieSearch.LastResult` can carry data across direct `:Search()` calls. `:ByName()` (lines 29–36) calls `_ResetResults()` first.

Other real consumers:
- `QuestieSearchResults.lua` passes query functions as callback values in quest-detail paragraphs around **lines 240–259** and assigns local aliases around **lines 278–282**, plus other uses.
- `AvailableQuests.lua` binds `local questData = QuestieDB.QuestPointers or QuestieDB.questData` at **line 93**, a pointer-table alias for its calculation.

## Proposed executable acceptance (NOT verified until CI completes)

The dedicated job pins all three Git blobs and runs authentic full `QuestieSearch.lua` on Lua 5.1.5 and 5.4.6 with **52 strict checks per interpreter**:
- Matching four-kind OLD query/pointer pairs produce correct ByName / exact-name / fuzzy-name / ByID results.
- A deliberately constructed pre-existing mixed OLD-query/NEW-pointers (or NEW-query/OLD-pointers) returns **zero matches silently**, rather than throwing, for each of four kinds. Restoring matching NEW pairs restores two matching rows. This is a **known-unsafe synthetic input state** accepted by the original consumer's call logic, NOT proof real vanilla client randomly interleaves these adjacent Lua reads.
- A source-closure callback changes the global facade mid-search; both original **local variables** remain paired for that synchronous invocation (a positive finding). The next call uses NEW values.
- A nil query or pointer map causes ordinary original search to fail rather than providing a success result.
- More subtly, a complete OLD→NEW transition between **direct** `:Search()` calls leaves OLD result IDs in `LastResult` while adding NEW IDs, because IDs absent from current `databaseKeys` are not cleared by direct `:Search()`. `:ByName()` explicitly clears the old entries. This is a constructed lifecycle/compatibility issue relevant to future generation switching and cache invalidation.
- The original consumer has no explicit generation lease or source revision binding API. A proposed producer/read-side generation design must pair query closure+pointer map per generation **and invalidate/reset Search/Journey caches on transition**.

**Technical boundary:** These tests do not run the actual `QuestieDBCompiler:GetDBHandle()`, real `QuestieDB.Query*()`, the 335 addon, external addon writes, thread yields across the two reads, QuestieStream or SavedVariables. A passing unsafe witness establishes source response to fictional mixed pairs and stale cache transitions, NOT a fix or evidence the constructed state occurs during ordinary native play. Dynamic aliasing through unscanned files is not ruled out by these three anchors; this is not a complete 500-file consumer census.

## Gate and release constraints

Gate08 remains **MAJOR RED**; E01–E08 and unknown external writers, A→B→A epoch ownership, exact-once stream pool lease and abort quarantine, coherent four-kind + metadata publication, all original `QuestieDB.Query*` cached aliases, old-format SavedVariables migration, relog/crash disk recovery and native 3.3.5a/Individual Progression all remain unverified. No production patch or package authorized; protected `335` is not modified. Project gates **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**. 439 RAW quest research entries are not approved, denominator unknown and pilots 1207–1209 **0/3**. Never invoke legacy `build.py` or `release.py` without explicit separately granted owner authority, plus backups and rollback.
