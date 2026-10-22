# Guarded custom quest loader — development contract (DRAFT)

This branch is a **review-only development draft**, not a ready-to-install addon, a release, or authorisation to import quests. Protected `335`, the owner's installed addon and the live server/SQL are not changed by this branch.

## Scope and safety

- `Compat/NQuestieCustomQuestData.lua` contains **only the already-public quest 2001**; its approved data fields and nested output remain unchanged.
- The loader adds **new quest IDs only**, with a tightly checked, exact approved-field exception for public quest 2001. Existing-quest corrections use a separate reviewed path.
- No owner-private server quest records, IDs, NPC/item keys, locations, conditions, databases or SQL have been committed.
- All new records fail closed on unsupported gameplay fields, known-source references that do not resolve, and unresolved or cyclic dependencies. No addon logic claims to infer a player's server progression stage or event/phase eligibility.
- Mixed objective **categories** are **rejected for now** because Questie associates static objective data with ordered client quest-log objectives by index. A single objective category (NPC kills, GameObjects or items) is supported as a guarded input shape, not an in-game QA PASS.
- Source NPC/GO reverse indexes retain existing links; proposed quest additions are rejected before emission if the combined packed `u8` relation index would exceed **255** IDs. Do not invent missing coordinates for craftable/trade items.
- The overlay's `NQuestieCustomQuestData.revision` is **8**; it was deliberately advanced after loader changes so installed compiled DBs will rebuild when a future release is separately authorised. No actual installation is approved.

## Reviewed synthetic input contract

Required scalar fields: `name`, `requiredLevel`, `questLevel`, `zoneOrSort`, `requiredRaces`, `questFlags`.

Optional source lists: `startedByNpcs`, `finishedByNpcs`, `startedByGameObjects`, `finishedByGameObjects`. At least one source and one finisher must resolve in the existing public Questie NPC/object DB.

Optional objective lists: `killNpcs`, `objectObjectives`, `itemObjectives`. Every specified ID must exist in the corresponding public DB. Item data without reliable acquisition coordinates can retain objective metadata; **no fake drop pins** are created. `noDirectObjectives = true` must explicitly mark a quest with no direct objective lists.

Optional supported restrictions: `requiredClasses`, `preQuestSingle`, `preQuestGroup`, `exclusiveTo`, `parentQuest`, `nextQuestInChain`, `specialFlags`. `specialFlags` accepts **0 or 1** only (Questie repeatable); never copy raw AzerothCore flag masks. Chain and exclusive-group meanings must be reviewed, not transferred mechanically.

Lists must be dense, unique, integer-indexed and contain at most 255 positive IDs no greater than 16,777,215. Scalars obey the compiler's signed/unsigned field limits. `questLevel=-1` is an allowed scaling sentinel; actual client display remains untested.

## Testing and peer review

Run the public, **synthetic-only** contract suite:

```bash
python3 tests/compat/run_nq_custom_loader_safety.py
```

The runner verifies the exact reviewed loader Git blob before invoking installed Lua interpreters. It prefers Lua 5.1 and can also run Lua 5.4. The existing `.github/workflows/nquestie-overlay.yml` now runs this suite under **Lua 5.1** on PRs, rather than relying on a local-only result.

The separate **synthetic compiler codec probe** runs with `lua5.1 tests/compat/nq_custom_compiler_codec.lua`. It loads the repository's **actual** `Database/compiler.lua` writer/reader functions, uses invented one-kind GO and item objectives emitted by the guarded loader, and checks serialization of objective slots, questgiver NPC/GO slots and `questLevel=-1`. It first verifies the codec against a small **test-only byte stream**, then repeats the checks with the actual `Modules/QuestieStream.lua` **raw_assert** stream. The initial 11-assertion adapter probe passed in overlay CI run 39769056348; an **additional eight real-stream checks** passed under Lua 5.1 in overlay run 39769577022. This is **a real compiler-codec + stream serialization round trip**, but **not** a complete in-game compiled-DB build, live-client proof, or independent peer review.

- Initial implementation caught and fixed a nested-array regression for quest 2001; the current test suite preserves its exact NPC-only and kill-only tuple structure and rejects attempted record mutations.
- Peer review found a missing saturation test for NPC reverse indexes. Both **255+1 rejection** and **254+1 acceptance** tests are now included.
- A later peer review found the same gap for GameObjects. Both **GO starter** and **GO finisher** reverse-index limits now have 255+1 rejection and 254+1 acceptance fixtures, plus preservation checks. These synthetic-only additions passed the six PR-triggered workflows at head `f5d6b120`, and CS02 independently ran **56/56** Lua 5.1/5.4 checks and killed the disabled GO-pruner mutation. This is not real-client verification.
- Unsupported mixed objective kinds are explicitly held back pending real client objective order verification.
- The GitHub Actions synthetic-loader test command now uses a **120-second CI timeout** (`timeout` / `--kill-after`) so a non-terminating test mutation fails CI rather than waiting for the default job timeout. No loader, quest record or revision change is implied.
- CI `Assemble PR-only` and `Upload temporary PR test build` steps are disabled with `if: ${{ false }}` in `.github/workflows/nquestie-overlay.yml`. This branch does not assemble or upload an addon package. Older PR-only workflow artifacts predate this restriction and were not installed or released.
- The Part 119 head `f5d6b120` passed **six PR-triggered workflows**, including the integrated Lua 5.1 suite. CS02's reciprocal review of that exact head is a **draft PASS**. Workflow success must be checked again whenever the branch head changes; the Part 119 result does not certify subsequent commits.
- Lua 5.1 synthetic loader and real-stream codec PASS is **not** a live WoW 3.3.5a client PASS, a complete whole-DB compiled-loader rebuild or proof that private candidate quests are safe to import.
- Part 122 adds `tests/compat/nq_custom_fulltable_compiler.lua`, a compiler-only reopen of ten invented quests through real `CompileTable` / `CompileTableCoroutine`, `BuildSkipMap` and `GetDBHandle`. What that run proves and what it does not prove is recorded in `docs/NQ-P122-SYNTHETIC-FULLTABLE-COMPILER-DRAFT.md`. It is not a client PASS. The literal quest name `"nil"` reopens as Lua nil; that collision is documented there and is not fixed on this branch. `zoneOrSort=-32768` is not part of the fixture.

## Unresolved before any merge or release

- Recheck latest-head CI after subsequent edits. The Part 122 synthetic whole-table harness is compiler-only; a real Questie database rebuild and any live client check remain open. Reviews of future functional loader changes remain necessary. The literal `"nil"` name collision and the separate `zoneOrSort=-32768` boundary are not fixed here.
- Exact in-game marker/level handling, especially for scaling quests and item-only objectives.
- Server-side condition/IP phase availability and real source locations. Event/phase-gated quests must remain excluded.
- Owner's **separate explicit approval** for any merge, client install, private quest-data addition, live server/SQL change or release.

This document describes current proposed code and guarded offline validation only; it is not a rollout instruction.
