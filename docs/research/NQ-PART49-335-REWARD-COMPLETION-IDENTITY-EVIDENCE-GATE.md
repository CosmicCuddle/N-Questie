# N-Questie Part 49 — WoW 3.3.5a Quest Reward Identity and Completion Observability Gate

**30 October 2026 UTC. RESEARCH / DOCS-ONLY / FUTURE OBSERVATION PROPOSAL. NOT AUTHORIZED FOR CLIENT TESTING OR ADDON SOURCE EDITS.**

## 1. What this gate is—and is not

The historical first-party 3.3.5 compatibility layer tracks the ID of a rewarded quest by its **title**, rather than receiving a quest ID directly from the Lua `GetQuestReward` post-hook. Earlier Part48 analysis identified a first-match title lookup and ambiguous static quest titles; Part49 additionally found the local title cache has **no independent expiry**.

This document specifies **which evidence would distinguish** correct, absent, ambiguous and stale mappings. It does not establish that these scenarios occur on CosmicCuddle's actual 3.3.5a client, or authorize native instrumentation, test accounts, production edits, fixes, release, builds, installation or merges.

**Immutable historical addon source commit:** `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`; authentic `Compat/Compat.lua` Git blob `b3e273e82cabbd5b7b351ae5aa3d94d4675387be`. This is **not** protected live `335` (last independently checked `26053bd28b0df3a01e5859f779d5f3cb4f57b221`, protected=true).

## 2. Confirmed SOURCE behaviour (not native WoW behaviour)

| Original source | What it does |
| --- | --- |
| [`Compat/Compat.lua:682–692`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Compat/Compat.lua#L682-L692) | `QuestieCompat.GetQuestIDFromName(questTitle)` walks `GetQuestLogTitle(1..MAX_QUEST_LOG_INDEX)`, returns first same-title non-header quest ID. No duplicate-title or quest-ender guard; no match returns nil. |
| [`Compat/Compat.lua:1405–1411`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Compat/Compat.lua#L1405-L1411) | A `GetQuestReward(itemChoice)` post-hook obtains `GetTitleText()` and, ONLY when lookup produces positive ID, writes `completeQuestCache[questTitle] = questId`. Missing lookup does **not** remove an older same-title entry. |
| [`Compat/Compat.lua:1359–1374`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Compat/Compat.lua#L1359-L1374) | `CHAT_MSG_SYSTEM` matches localized quest-complete message pattern, retrieves cached ID by matched title, calls `QuestTurnedIn(id)`, then `QuestRemoved(id)`, and clears that title key **only on cache hit**. |
| Same complete `Compat.lua` file | A full-file search found just FOUR references to `completeQuestCache`, around original lines **1361, 1367, 1371, 1409**. There is no timer expiry, cache age, per-turn-in token, alternative clear on no match, or clearing on unrelated client events in this module. Persistence is in-memory until matching message, overwrite, or reload; this fact alone does not show harmful native reuse. |
| [`QuestEventHandler.lua:275–330`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Modules/Quest/QuestEventHandler.lua#L275-L330) | Given an ID, original `QuestTurnedIn` changes quest state/cache and invokes `QuestieQuest:CompleteQuest`, `QuestieJourney:CompleteQuest`, `QuestieAnnounce:CompletedQuest`; a wrong ID can therefore reach the WRONG **addon** state if the native preconditions actually occur. |
| [`QuestieQuest.lua:493–532`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Modules/Quest/QuestieQuest.lua#L493-L532) | Original `CompleteQuest(id)` can clear `currentQuestlog[id]`, set completion flags via 335 compat, and update frames/tooltips/tracker. **Do not assert a given side effect executed without a real trace.** |
| [`QuestieJourney.lua:193–215`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Modules/Journey/QuestieJourney.lua#L193-L215) | Original `CompleteQuest(id)` appends an ID-keyed timestamped completion entry. Never backfill or replay it speculatively. |

**Important distinction:** `QuestieCompat.GetQuestID(false, title)` is a separate quest-giver-aware helper, using [`QuestieDB.GetQuestIDFromName`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/QuestieDB.lua#L1683-L1733). It is **not** a proven safe replacement: its `pairs` loop can overwrite a result among multiple qualifying entries; its `IsDoable` and current-log restrictions may reject valid hidden/other quests; NPC/GUID context may be absent. **Native** `GetQuestID()` was not part of stock 3.3.5a; do not substitute the post-4.0.1 API.

Original Classic static quest data includes repeated titles (Part48 research: 4,244 entries, 463 repeated titles, 293 conservative same-title/same-ender groups). This is **NOT** proof of simultaneous active quest-log duplicates or the owner's current DB. Do not take sequential quests such as *The People's Militia* 12/13/14 as simultaneous examples.

## 3. Archived Blizzard UI entry paths—not native event timing

Archived 3.3.5 interface [`QuestFrame.lua`](https://github.com/wowgaming/3.3.5-interface-files/blob/d0339b17b0221db76e6acd2dc2915d224a5b62ca/QuestFrame.lua) calls `GetQuestReward(QuestInfoFrame.itemChoice)` directly for ordinary reward confirmation, but routes a quest with monetary expense to `CONFIRM_COMPLETE_EXPENSIVE_QUEST` popup.

Archived [`StaticPopup.lua`](https://github.com/wowgaming/3.3.5-interface-files/blob/d0339b17b0221db76e6acd2dc2915d224a5b62ca/StaticPopup.lua) invokes `GetQuestReward(QuestInfoFrame.itemChoice)` in that popup's `OnAccept`.

**Both normally reach the same Lua hook**, but the dialog/frame state, quest-log state, server reply timing, exact quest ID available to Lua, and completion-chat order at the *post-hook* remain **UNKNOWN**. A server opcode carrying exact quest ID is not evidence that this Lua post-hook exposes that ID.

## 4. Conditional outcome matrix — all require actual observation before diagnosis

| Case | Preconditions to establish | Source-level conditional consequence | Native status |
| --- | --- | --- | --- |
| R1 — unique present | Reward title T; exactly one live log quest title T, ID X, when the hook reads; matching completion system message | Hook caches T→X; matching chat consumes X and clears key | **UNVERIFIED**, sensible reference baseline |
| R2 — no live match | Hook reads title T but no `GetQuestLogTitle` entry matches | Hook creates no new ID; subsequent chat only processes if an older T key already exists | **UNVERIFIED**; could arise from removal/order, title mismatch, not necessarily bug |
| R3 — simultaneous same title | Two or more ACTUALLY active client log entries share exact T; rewarded ID Y is not first title match X | Hook chooses X; matching chat acts on X, potentially not Y | **UNVERIFIED**; static DB duplicates are inadequate proof |
| R4 — unmatched stale mapping | Earlier hook cached T→X; matching completion chat DID NOT consume it; later same-title completion message appears and no later successful hook overwrote it | Matching chat may consume old X and call original turn-in/removal for X | **UNVERIFIED**; no demonstrated natural event sequence |
| R5 — post-hook overwrite | Earlier T→X exists, later hook with same T successfully identifies Y | Cache overwritten to T→Y; matching chat uses Y | **UNVERIFIED**; depends on actual hook/order |
| R6 — expensive reward confirmation | Player enters archived monetary confirmation route and accepts | That route calls same `GetQuestReward` function, but hook title/log observability may differ by UI timing | **UNVERIFIED**; no owner-approved native comparison |

**No source-only matrix row proves a live failure.** An API simulation can check deterministic first-match / cache logic, not timing, reentrancy, server success, user data or game UI outcomes.

## 5. Minimum future observation plan, requiring NEW explicit CosmicCuddle approval

If and only if separately approved on a disposable client/server/character and reversible staged data:

1. **Baseline identity:** exact client build/addon source hashes, test quest ID selected by server only when legitimately observable, quest title, quest-ender, current quest-log indices/IDs and existing quest acceptance/completion state. Prefer one ordinary **approved** unique-title quest.
2. **Before reward action:** whether ordinary button or monetary popup; `GetTitleText()` and `GetQuestLogTitle` snapshot, including *every* exact same-title non-header match. Do not assume NPC token or modern native `GetQuestID()` exists.
3. **Hook and system-message ordering:** ordered monotonic sequence of the real `GetQuestReward` invocation/post-hook, resulting lookup ID (or nil), actual subsequent localized `CHAT_MSG_SYSTEM` text/pattern match, and completion state; do NOT forge a completion event or cause duplicate rewards. If private-local `completeQuestCache` must be observed directly, **new hook/instrumentation requires separate owner approval**.
4. **After-state:** exact ID(s) affected in `QuestiePlayer.currentQuestlog`, `Questie.db.char.complete`, Journey completion entries and tracker/notes compared with the actual server-rewarded quest ID where it is safely/legitimately visible. Separate an incorrect ID from a missing callback or delayed refresh.
5. **Controls and interpretation:** a normal unique-title completion first; an expensive-confirmation flow only if naturally available in allowed test data. Do **not** manufacture simultaneous same-title active quests, skip hook order, replay historical completion messages, or force stale-cache races merely to show R3/R4. Seeing none in one session is inconclusive.
6. **Safety gate:** beforehand record explicit approval, client/server/addon test scope and test quests, privacy protections, full addon and account/character WTF/SavedVariables backups, relevant staging DBC/DB snapshots, hashes, **verified restoration on disposable copies**, no-production-write and stop conditions. Do not post account IDs, SavedVariables, logs with private data, secrets or live DB exports on GitHub.

## 6. What would support a change—and what would not

A genuine native trace showing **(a)** actual rewarded quest ID Y, **(b)** original Lua resolver output X distinct from Y, and **(c)** original completion handler/Journey/quest flags operating on X, would support a specific ID-mismatch investigation. A complete missing-hook case with persistently missing effects and no alternative recovery would support a separate missed-completion investigation.

Do **not** infer such results from a static repeated-title dataset, historical source alone, a fabricated game host, a missing modern API, a single no-B-event observation or server packet details invisible to the client addon.

No implementation or algorithm selected. Especially **do not silently replace first-match lookup with the also-nonunique giver-aware helper, guess a quest ID, replay completion chat or backfill Journey**. Ask owner to approve a narrowly justified change only after evidence and rollback planning.

**Gate08 remains MAJOR RED; 439 RAW candidate quests UNAPPROVED; pilot 1207–1209 0/3.** This document does not change release gate status, frozen original PRs, or protected live `335`.
