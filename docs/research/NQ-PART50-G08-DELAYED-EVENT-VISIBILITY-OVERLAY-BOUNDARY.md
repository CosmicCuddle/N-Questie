# Part 50 — Gate08 compile source versus delayed world-event visibility

**30 Oct 2026 UTC · CONFIRMED historic first-party source / PROPOSED design · DRAFT, no implementation or client acceptance**

Original code source commit: `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`; protected default `335` last separately checked at `26053bd28b0df3a01e5859f779d5f3cb4f57b221`, protected=true. The historic code is a **reference baseline**, not the current default branch. Tests are public-only with fictional IDs and event dates; no private Naxxramas source/SQL or IP mappings.

## Finding: there are THREE different classes of mutable source/effective state

| Surface | Authentic original source | What the future Gate08 rule must do |
| --- | --- | --- |
| **1. Precompile raw source writers** | `QuestieQuestFixes:LoadMissingQuests` replaces twelve `questData` row objects; `QuestieDB.private:DeleteGatheringNodes` clears twenty-four `objectData` spawn fields; `QuestieCorrections:PreCompile` updates NPC waypoints while yielding; `_LoadCorrections` and faction-derived quest requirements write raw fields | Capture a **coherent completed precompile source generation** or fully protect every writer through compile yields; neither root-table identity nor after-the-fact equality proves no mutation |
| **2. Runtime effective overrides** | `QuestieCorrections:MinimalInit` merges `npcDataOverrides`, `objectDataOverrides`, `questDataOverrides`, `itemDataOverrides`; [`QuestieEvent.lua`](../../Database/Corrections/QuestieEvent.lua) `_LoadDarkmoonFaire` can assign `QuestieDB.npcDataOverrides[id]=data` in its **`Questie.IsClassic`-gated** path | Define which fields belong to compiled-binary ownership versus separately updated **reader-time overlay** views. Maintain coherent source/override precedence across readers. Do not assume Classic Darkmoon code executes in the actual 3.3.5a/IP client; test client mode and event timing |
| **3. Runtime quest eligibility / event visibility** | `QuestieCorrections:MinimalInit` optionally schedules `C_Timer.After(1, function() QuestieEvent:Load() end)` when `showEventQuests`; `QuestieEvent:Load` may remove active event quest IDs from `QuestieCorrections.hiddenQuests` by assigning `nil` | **Permit legitimate visibility changes** without treating them as an invalid compiler source generation. Prevent stale reader table aliases if a root is later replaced. A timestamped callback is not an atomic source freeze |

## Original code anchors and exact semantics

- [`QuestieCorrections.lua:148–235`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/Corrections/QuestieCorrections.lua#L148-L235) defines `addOverride`, calls it for the four data kinds, **replaces** `QuestieCorrections.hiddenQuests` with the expansion-filtered blacklist at `MinimalInit`, then conditionally schedules the one-second event callback. This is an *API scheduling request*, not proof the callback will always fire after DB initialization.
- [`QuestieEvent.lua:84–153`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/Corrections/QuestieEvent.lua#L84-L153) describes the original `Load` path: it parses event windows, stores event quest names, may set `hiddenQuests[questId]=nil` and `activeQuests[questId]=true`, calls `_LoadDarkmoonFaire()` only in a `Questie.IsClassic` branch, and finally clears `QuestieEvent.eventQuests=nil` to save memory. 
- [`QuestieEvent.lua:248–279`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/Corrections/QuestieEvent.lua#L248-L279) has a Classic-specific Darkmoon writer into the effective NPC override table. This is an override mutation, not direct rewriting of the four compiled binary fields.
- [`QuestieDB.lua:220–311`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/QuestieDB.lua#L220-L311) original `QuestieDB:Initialize()` gets four compiled reader handles and **caches the table reference** `QuestieCorrectionshiddenQuests = QuestieCorrections.hiddenQuests`.
- [`QuestieDB.lua:627–634`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/QuestieDB.lua#L627-L634) original `IsDoable` checks that cached table. Lua in-place mutation of that same table is observable by the cached reference; a later replacement of the table root leaves the old reader reference stale until rebind/reinitialization.

**Correction to avoid overclaiming:** The delayed event callback is *conditional* on `showEventQuests`; actual firing time, active-event state, `Questie.IsClassic` / `IsWotlk` selection, event list lifetime and special private client behaviour are **not** measured in-game. Source order does not prove an actual race, stale UI or player-visible bug.

## Narrow source test and limits

- Previous source writer [#434](https://github.com/CosmicCuddle/N-Questie/pull/434) original first head failed because its own test searched a whole file for a method invocation. Corrected immutable child [#435](https://github.com/CosmicCuddle/N-Questie/pull/435) executed **17/17 real Lua5.1 and 17/17 real Lua5.4** in its dedicated job on artificial raw rows. Full matrix CI must be checked independently.
- New **TEST-only draft [#437](https://github.com/CosmicCuddle/N-Questie/pull/437)** head `77721e098f5b59359cabfedea2c41a9535cf9d8b`, child of frozen [#435](https://github.com/CosmicCuddle/N-Questie/pull/435). Executes the **unchanged** original `QuestieEvent:Load()` and `QuestieDB:Initialize()` source against fake WotLK-shaped flags and invented dates/IDs and **fake** compiled DB reader handles.
- Expected controls **26/26 per real Lua5.1 and Lua5.4**, but **NOT VERIFIED at this note's creation**. It tests an in-place active-event unhide reaching original initialized table alias; fake WotLK-mode Classic-only exclusion; inactive event retained; one-shot event list; deliberately repeated load; and hypothetical root replacement after initialization. An artificially repeated event load or a second `MinimalInit` after DB initialization is a **counterfactual**, not established live scheduling.
- It **does not** execute original Classic Darkmoon writer, actual C_Timer scheduler, 3.3.5a game APIs, real DB stream pool, Individual Progression, SavedVariables or client performance. **Passing a synthetic runner does not establish absence or presence of an actual user bug.** The exact-head workflow/logs/artifact counts must be checked separately.

## Concrete future acceptance requirements (PROPOSED, NOT GREEN)

- **EV01 — compile/raw ownership:** no compile may use unverified partially-transformed precompile tables. Demonstrate ordered, complete ownership of quest replacement, prune, corrections, faction-derived fields and waypoint processing.
- **EV02 — active event visibility:** authorized runtime `hiddenQuests` in-place updates must remain observable to `IsDoable` without rebuilding compiled binaries.
- **EV03 — root replacement:** if runtime code replaces the `hiddenQuests` table after `QuestieDB:Initialize`, affected cached readers must either be explicitly rebound or the replacement forbidden while readers exist; mere source epoch does not update an already-captured Lua alias.
- **EV04 — event callback lifetime:** repeated/delayed event callbacks and `eventQuests=nil` one-shot state must be accounted for; do not claim the game schedules duplicates without client evidence.
- **EV05 — mode-specific overlays:** verify original `Questie.IsClassic` branch versus actual 3.3.5a/IP flags and Classic Darkmoon NPC override behaviour before choosing any overlay ownership policy.
- **EV06 — independent safety:** none of EV01–EV05 resolves shared `QuestieStream` pool ABA/quarantine, driver-owned DEAD/SUSPENDED leases, coherent eight `Bin/Ptrs` fields and compiled metadata, crash/relog SavedVariables recovery or native memory/GC/frame caps.

## Disposition

**CONFIRMED:** direct source code has conditional delayed event visibility writer, cached `hiddenQuests` table ref, Classic-only Darkmoon effective NPC override writer and one-shot event quest list clearing.

**UNVERIFIED:** actual callback timing relative to initialization, double event invocations, stale in-game UI, private event availability, 3.3.5a client flags and any impact on real gameplay. **PROPOSED:** EV01–EV06 future boundaries, not a new implementation approval.

**NO MERGE / NATIVE INSTALL / LIVE SQL / CLIENT OR SERVER / ZIP OR RELEASE**. Gate08 remains **MAJOR RED**; Gate10 439 RAW unapproved, pilots 1207–1209 0/3. Coordinate with Maintenance only on a verified cross-project dependency.
