# N-Questie Part47 — Original QuestEventHandler Removal Lifecycle / Cache Evidence (TEST-ONLY DRAFT)

**29 October 2026 — isolated research contract. This is not a native-client finding, release acceptance, or approval to edit protected production.**

## Immutable source and test scopes

Historical pre-README original 335 commit: `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, **NOT** the current live production commit.
- `Modules/Quest/QuestEventHandler.lua` original Git blob `fa3950ad5078ed299226fe384ea20eba2674b853`: test extracts and executes unchanged full `QuestTurnedIn`, `QuestRemoved`, and `MarkQuestAsAbandoned` **function bodies**.
- `Modules/Quest/QuestLogCache.lua` original Git blob `09e9989922731f899994e6eb09af24465ae196ce`: test executes whole unchanged original module.
- Five other authentic historical blobs are authenticated by unchanged dedicated CI; their full modules are **not** exercised in the new fixture.
- Existing #380 test executes original `UpdateAllQuests` function body and whole cache together in a separate host; new fixture does **not** combine `UpdateAllQuests`, `SmoothReset`, `UpdateQuest`, actual event registration, full original event-handler initialization or all addon modules in one process.

All event scheduling, accepted/removed/turned-in states, questlog objective data, WoW compat APIs, C_Timer.NewTicker callback and Cancel behavior, QuestieDB parent query, reward info, other addon callbacks, and order of event invocation are deliberately **FABRICATED by this test host**. Real 3.3.5a game data, events and frame scheduler are not executed.

## Source-backed question and bounded synthetic sequences

Original first-party source `QuestEventHandler.lua:310` removes the cached quest immediately during `QuestTurnedIn`. `QuestEventHandler.lua:332-345` distinguishes already-turned-in removal from a potential abandonment requiring ticker callback. `QuestEventHandler.lua:353-363` invokes original `QuestLogCache.RemoveQuest` only when the tracked state is `QUEST_REMOVED`. The original cache's `RemoveQuest` deletes one cached record; the count transition 1→0 by itself can retain the prior objective in a fake game-log host. These are source-level statements, not native-event proof.

The new separate fixture exercises three invented orders:
1. Original cache initially contains one synthetic objective. Fake client transitions 1→0 without a change notice; original **turn-in then removed** clears the old cached entry and the later removed handler skips the fake abandonment timer.
2. Rebuilt fake accepted cache: **removed then turn-in**, original removed method schedules a fake timer without clearing cache, but original turn-in cancels the timer and clears cache. Fake scheduler suppresses the cancelled callback.
3. Rebuilt accepted cache: **removed then explicit fake timer firing without turn-in** invokes original `MarkQuestAsAbandoned`, which clears cache, notifies mock abandon sinks and removes tracking.

The fixture is NOT proof these three orders occur in native WoW, nor evidence that original `UpdateAllQuests` or `SmoothReset` has an observable game defect. Distinguish original source call-graph from synthetic input reachability.

## CI and release evidence

Branch is a direct child of frozen successful test-only #380 exact `9d44e8c8229ead538c45165aed73927d06ec858a`. New file and CI step are TEST ONLY. **30 new assertions per Lua5.1.5 and Lua5.4.x PROPOSED; NOT credited until exact-head GitHub Actions succeeds.** Inherited #380 464 per interpreter remains historic verified evidence on its own frozen SHA; do not claim a combined 494 until the new branch's dedicated dual-Lua run, source hashes, clean checkout and artifact census are independently checked.

Do not mutate frozen red test heads (#361/#362/#373/#374/#377) or any older green PR. Do not merge, edit addon Lua/SQL/TOC or protected `335`, test a real client, access SavedVariables/character data, package, tag, install or release. **Gate08 MAJOR RED; 439 RAW candidates unapproved; pilot quests 1207–1209 remain 0/3.** Actual native quest objective 1→0 event reachability and AnimationGroup/ThreadLib order remain UNKNOWN.
