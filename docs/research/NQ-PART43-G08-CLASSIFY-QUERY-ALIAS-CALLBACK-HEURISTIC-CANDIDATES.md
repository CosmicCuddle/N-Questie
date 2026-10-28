# Part43 Gate08 — first-party reader alias and callback candidate reclassification

**28 October 2026 · public-safe test-only design audit · NO runtime edit, native build, installation, merge, tag or release**

## Provenance

Frozen source inventory [test-only #313](https://github.com/CosmicCuddle/N-Questie/pull/313), original exact `07eaa43d1d19b82917ad0c0de9621fa68a875a46`, independently passed **25/25** checks in dedicated [run 40724504297](https://github.com/CosmicCuddle/N-Questie/actions/runs/40724504297), zero artifacts. It read **110** first-party Lua files from protected `335` `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, identified 197 raw `QuestieDB.Query*/_Query*/*Pointers` matches in 25 files, and 36 **conservative assignment** plus 14 **conservative callback** candidates. Crucially, neither candidate total is a verified count of long-lived aliases or retained callbacks.

## New narrower test-only classification

An isolated Python3 classifier on the same public protected original commit independently authenticates original five Git blobs and recomputes the exact 110/197/25 and 36/14 baseline using the original patterns, then categorizes references as:
- **DIRECT_CALL** — `QuestieDB.Query*Single(...)` invokes immediately. A comma directly preceding the call is NOT evidence that the function itself was passed as a callback.
- **EXPORT_ASSIGNMENT_LHS** — e.g. `QuestieDB.QueryNPC = ...`, an exported API publisher. Counting this as a retained consumer alias is misleading.
- **QUERY_VALUE_ASSIGNED_RHS** — an actual query-function value is assigned, e.g. `local databaseQueryHandle = QuestieDB.QueryNPCSingle` or `query = QuestieDB.QueryNPCSingle`. These warrant lifetime review, but a local alias does not automatically persist across an event or generation.
- **QUERY_VALUE_PASSED_ARGUMENT** — a query-function value is passed without invoking it, e.g. `AddLinkedParagraph(..., QuestieDB.QueryNPCSingle)`. The callee's possible retention duration still requires review.
- **COMMENT** — detected ordinary Lua single-line comments (comments and original exploratory diagnostics can inflate a textual audit).
- **OTHER_NONCALL_REFERENCE** — compound reader accesses, map pointers and other references requiring manual inspection.

The classifier preserves original candidate membership with exact path, line, field, source excerpt and newly assigned category, reporting precise counts in CI logs. Its intent is to **remove false positives and prioritize real query/pointer generation contracts**, not to supply a new authoritative alias graph. New dedicated CI must independently show **25/25** source-backed invariants and the real computed category split before this work can be called passing; no numeric split has been pre-approved or assumed. The selection still excludes vendor libs, private files, huge database rows and unknown third-party consumers. It is not a full Lua tokenizer; long bracket comments/strings, dynamic indexing, indirect exports and runtime lifetime remain limitations.

## Engineering implications and hard boundaries

The source-backed [#311](https://github.com/CosmicCuddle/N-Questie/pull/311) QuestieSearch test (52/52 per Lua VM) already exposed a synthetic stale direct `:Search` result cache after OLD→NEW matching source replacement, along with deliberately mismatched query/pointer false negatives. The real original `QuestieDB:Initialize()` directly builds and exposes individual query closures and pointer maps. Therefore future production readiness would require explicit **one-generation query+pointer selection** and staged cache invalidation for QuestieSearch/QuestieSearchResults, quests, communications, tracker and derived query handles. No actual adapter is authorized or implemented in this child. A positive static classifier does NOT prove runtime coherence, saved variable or native game safety.

Gate08 remains **MAJOR RED**, overall **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**, 439 RAW quest investigations not approved, eligible denominator unknown, pilots 1207–1209 **0/3** implemented. Required but unproved: E01–E08 and unknown writer ownership; global QuestieStream leases, A→B→A and abort quarantine; coherent four-kind (eight Bin+Ptrs) and metadata publication; existing third-party consumers; old-format SavedVariables migration, relog/crash disk recovery and native WoW 3.3.5a + Individual Progression. No protected 335 modification, production edits, build scripts, ZIP/package, client installation, merge, tag or release. Any future authorized native test requires backup of `Interface/AddOns/Questie-335` and account/character SavedVariables plus documented rollback.
