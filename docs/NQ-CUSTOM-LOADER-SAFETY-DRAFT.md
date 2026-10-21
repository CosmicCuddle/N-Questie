# Guarded custom quest loader — draft development contract

This branch is a **development draft**, not an addon package or approved server quest import.

## Scope

- Existing `Compat/NQuestieCustomQuestData.lua` still contains only the previously public custom quest 2001.
- The loader adds **new quest IDs only**, with a narrow fingerprint-checked compatibility exception for the already-released public quest **2001**. Other existing-quest field corrections remain separately owned by `Compat/NQuestieExistingQuestCorrections.lua`.
- No private server quest names, IDs, NPCs, items, coordinates, SQL, or database exports are included.
- The client, protected `335` branch, and SQL/server are untouched. **Do not merge or release without the owner's separate approval.**

## Public input schema

Required: `name`, `requiredLevel`, `questLevel`, `zoneOrSort`, `requiredRaces`, `questFlags`.

Optional source arrays (IDs only): `startedByNpcs`, `finishedByNpcs`, `startedByGameObjects`, `finishedByGameObjects`. At least one supported starter and finisher must resolve in the existing Questie NPC/object database.

Optional objective arrays (IDs only): `killNpcs`, `objectObjectives`, `itemObjectives`. They must resolve in the existing public NPC/object/item DB. Unknown drop sources **do not** create invented coordinates. An objective-less quest requires explicit `noDirectObjectives = true`.

Optional restrictions: `requiredClasses`, `preQuestSingle`, `preQuestGroup`, `exclusiveTo`, `parentQuest`, `nextQuestInChain`, `specialFlags`.

- **No server condition or IP-stage expression is supported.** Event/phase-gated data are explicitly out of scope.
- `specialFlags` accepts only 0 or 1 (the verified Questie repeatable bit), not a raw AzerothCore mask.
- Lists must be dense, unique, integer-indexed, max 255 elements, with IDs from 1 through 16,777,215. Numbers use their `questDB.lua` compiler field ranges.
- `questLevel = -1` is preserved as a supported scaling sentinel.
- Unknown fields, collisions, unresolved sources, impossible prerequisite cycles, and dangling references are rejected instead of silently omitted.
- Existing reverse NPC/GO quest relations are retained and checked for combined packed-array capacity before additions.

**Do not interpret chain relations as raw AzerothCore ExclusiveGroup or PrevQuestID automatically.** Any eventual custom quest needs deliberate conversion and review.

## Verification

Offline runner (where a Lua runtime is installed):

```bash
python3 tests/compat/run_nq_custom_loader_safety.py
```

The script checks a pinned Git blob revision of the draft loader and runs synthetic records, including the **already-public** 2001 baseline. It uses Lua 5.1 when locally available, otherwise 5.4 if present; a successful Lua 5.4 run is **not** a WoW 3.3.5a Lua 5.1 certification.

Local development evidence: **34/34** proposed behavioural guards passed using isolated Lua 5.4 mocks against the exact draft loader blob. Existing repository CI found a tuple-shape regression for quest 2001 on the first draft; a subsequent commit restored its exact NPC/kill-only nested arrays and added dedicated regression assertions. The committed extended test file has further synthetic cases; the separate game-client, Questie compiler round-trip, 2001 in-game, Quest 1203, individual progression, map precision and SavedVariables regression tests remain **NOT TESTED**.

**Review requests for CS02:** inspect callback ordering/collision handling, missing NPC/GO crash prevention, item-objective nil safety, mixed-type objective ordering, reverse-index capacity, negative prerequisite mapping policy, cache revision bump 5→6, and Lua 5.1 compatibility. Do not introduce real server records during this review.
