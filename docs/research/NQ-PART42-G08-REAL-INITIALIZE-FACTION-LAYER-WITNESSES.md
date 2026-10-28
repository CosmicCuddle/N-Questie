# N-Questie Part42 G08 — actual original correction initialization and faction-source layering

**28 October 2026 — PUBLIC-SAFE TEST-ONLY.** Protected `335` and all previously frozen/independently reviewed draft heads remain untouched. This research covers genuine unmodified Lua function bodies but **not** the WoW 3.3.5a client, actual Individual Progression owner rules, real server data or production publication.

## Why this matters

The previous [#284](https://github.com/CosmicCuddle/N-Questie/pull/284) source-backed test executed the real unmodified local `_LoadCorrections`, local `addOverride` and yielding `PreCompile`, but only **statically anchored** `Initialize`, its direct `quest[requiredRaces]` derived write, `QuestieCompat.LoadCorrections`, and the `MinimalInit` call order. This new independent test **executes the real complete function bodies** of both `QuestieCorrections:Initialize` and `QuestieCorrections:MinimalInit` in a synthetic host with all imported modules explicitly replaced by tiny invented loading stubs. Nothing is copied from private server SQL or owner mappings.

The exact protected [`Database/Corrections/QuestieCorrections.lua`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/Corrections/QuestieCorrections.lua) is fetched and checked against original protected commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, Git tree blob **`0584d2d6c0ff8c6e04c0fd0152d9c524bbf0345d`** and separately staged source bytes. The fixture extracts the **unchanged complete** original function definitions for flag constants, `filterExpansion`, local `addOverride`, `MinimalInit`, local `_LoadCorrections` and `Initialize`. No source-function mutation, no monkey-patching or instrumentation of real protected code. The module imports, correction loader returns, compat callback, faction choice, event/timer and blacklists are **fictional host stand-ins**, so native call-graph reachability is still unproven.

## Strict 31 controls, run on original PUC Lua 5.1 and 5.4

- Real WotLK/3.3.5a modeled initialization calls ordered Classic, TBC, WotLK (including `LoadAutomatics`), then `QuestieCompat.LoadCorrections` source writers before derived `requiredRaces`, and finally calls actual `MinimalInit`. Fake compatibility correction overrides fake WotLK NPC faction.
- Real derived `requiredRaces` writes directly to an already-existing quest record based on a fictional NPC faction owner. The WotLK compatibility-selected `H` produces fictional race flag 88; a compatibility-selected `A` produces fictional flag 77; neutral `AH`, no quest starter and preexisting nonzero restriction are preserved.
- Real `_LoadCorrections` handles `QuestieItemStartFixes:LoadAutomaticQuestStarts()` with `noOverwrites` and `noNewEntries` for fictional items.
- Actual `MinimalInit` merges Classic→TBC→WotLK faction override payloads; an existing override record is updated in-place, override-only records are created, and invented base data is separate.
- Actual `filterExpansion`, WotLK automatic blacklist and `QuestieCompat.LoadBlacklists` paths execute; explicit `false` blacklist value remains authoritative, with expansion-specific flags selected by real source code.
- Separate invented Alliance/Horde effective payloads prove the tested function can produce different override tables when its external stub returns different data. This is **NOT** an actual `UnitFactionGroup`/owner/playerbot/IP client test and proves no real faction route.
- Classic with `Is335=false` avoids TBC/WotLK and compat correction branches, and real `MinimalInit` only adds Classic overrides. Real delayed Questie event registration is executed with a fictional timer, then the registered callback is invoked by test code.
- Source-text anchor confirms the original correction module has **no actual private authenticated Gate08 writer exclusion protocol**; this cannot prove absence of all protection in other modules.

## Unresolved engineering dependencies

This is still **not** actual client integration or exhaustive writer ownership. The fixture does not execute the actual imported `Load()`, `LoadFactionFixes()`, `LoadMissingQuests()`, `LoadAutomatics()` implementations, actual compatibility module internals, client `QuestieCompat.Is335` selection, faction APIs, RDP geometry or unknown third-party addon writes. All 31 passing controls would only validate **source-body semantics under an explicitly invented host environment**. An uninstrumented writer may still change an existing/nested Lua key, including an A→B→A race, during actual compiler yields; real all-writer E01–E08 and unknown-addon isolation remain RED.

Beyond writer provenance, Gate08 needs a coherent privately owned four-kind generation, compiler status outcomes and atomic publication of **all eight NPC/object/quest/item Bin+Ptrs fields AND matching metadata**, real stream exact-once ownership/quarantine, native 3.3.5a SavedVariables disk/crash/relog recovery and Individual Progression QA. Source-epoch increments made manually by a fixture are **not** a production proof. Full client heap/frame measurements would be required if snapshot design chosen.

The 12 project gates remain **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**, G08 MAJOR RED. 439 RAW are public research candidates, not approved quests; eligible denominator UNKNOWN, pilots 1207–1209 remain 0/3 implemented. No protected branch edits, SQL/NPC/GO/item/loot/IP/private SavedVariables, merge, installation, ZIP/package, tag or release.
