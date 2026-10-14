# N-Questie — Quest Objective Validation System (Design Proposal)

**Date:** 14 October 2026
**Status:** Design. M0 approved and implemented on `feat/nq-validation-m0-2026-10-14` (see `docs/NQ-VALIDATION-M0.md`). M1–M5 not started.
**Owner:** Grok Bot (validation system). Corrections, imports and private comparisons stay with the lead developer.
**Inputs:** private local `acore_world` SQL export (never committed) and the Questie WotLK DB at the effective, post-correction stage
**Candidate pool:** 270 level, 24 item-objective, 151 NPC kill-objective, 18 possibly usable missing quests. These are candidates, not bugs.
**Verified anchor case:** quest 1203. The server requires item 3853 (Moonsteel Broadsword); Questie has 33110 (Razorspine's Sword).

## 1. Why a dedicated validator

The current tooling compares raw numbers. `tools/audit_world_quest_levels.py` (PR #5) covers levels and literal correction layers. The handover also records that 1,460 "item mismatches" turned out to be representation noise. The two databases encode the same quest differently, and a field-by-field diff cannot tell an encoding difference from a wrong target. The validator therefore needs a rule catalogue that explains each expected difference with a rule ID. Only differences that no rule explains reach a human.

I also want to be critical of the current design. Comparisons run against the *raw* `wotlkQuestDB.lua` plus a "literal approximation" of correction layers. Some corrections are code (for example `QuestieCompat.RegisterCorrection` callbacks, `LoadMissingQuests`, `Automatic/*`), so a literal parse will miss or misread them. The validator must compare against the **effective** DB produced by running the real `QuestieCorrections:Initialize()`, the same path the 335 harness in the review uses.

## 2. How Questie represents the data (quoted from the code)

### 2.1 Quest record keys (`Database/questDB.lua`)

```lua
['startedBy'] = 2,      -- {creatureStart, objectStart, itemStart}
['finishedBy'] = 3,     -- {creatureEnd, objectEnd}
['requiredLevel'] = 4, ['questLevel'] = 5,
['requiredRaces'] = 6, ['requiredClasses'] = 7,
['objectivesText'] = 8, -- Auto-complete if nil
['triggerEnd'] = 9,     -- {text, {[zoneID] = {coordPair,...}}}
['objectives'] = 10,
    --['creatureObjective'] = 1, -- {{creature(int), text(string)},...}
    --['objectObjective'] = 2,   -- {{object(int), text(string)},...}
    --['itemObjective'] = 3,     -- {{item(int), text(string)},...}
    --['reputationObjective'] = 4,
    --['killCreditObjective'] = 5, -- {{creature(int), ...}, baseCreatureID, baseCreatureText}
    --['spellObjective'] = 6,
['sourceItemId'] = 11,  -- int, item provided by quest starter
['preQuestGroup'] = 12, ['preQuestSingle'] = 13, ['childQuests'] = 14,
['inGroupWith'] = 15, ['exclusiveTo'] = 16, ['zoneOrSort'] = 17,
['requiredSourceItems'] = 21, -- Items that are not an objective but still needed
['nextQuestInChain'] = 22, ['questFlags'] = 23, ['specialFlags'] = 24,
['parentQuest'] = 25,
['extraObjectives'] = 27, -- {{spawnlist, iconFile, text, objectiveIndex, {{dbReferenceType, id}}}}
['requiredMaxLevel'] = 30,
```

There is no breadcrumb key. Breadcrumbs are modelled with `exclusiveTo`, for example `classicQuestFixes.lua:111` `[questKeys.exclusiveTo] = {5}, -- Raven Hill breadcrumb`.

### 2.2 Related keys

- `npcKeys`: `questStarts = 10`, `questEnds = 11`. These are reverse links that must stay consistent with `startedBy` and `finishedBy`.
- `objectKeys`: `name = 1, questStarts = 2, questEnds = 3, spawns = 4, zoneID = 5, factionID = 6`.
- `itemKeys`: `npcDrops = 2, objectDrops = 3, itemDrops = 4, startQuest = 5, vendors = 14, relatedQuests = 15`. Item objective pins come from these drop and vendor sources, not from the quest.

### 2.3 How objectives are built and matched (`Database/QuestieDB.lua`, `Modules/Quest/QuestieQuest.lua`)

- `ObjectiveData` is filled in a **fixed type order**: `objectives[1]` creatures, then `[2]` objects, then `[3]` items, then `[4]` reputation, then `[5]` kill credit (or first if `QuestieCorrections.killCreditObjectiveFirst[questId]`), then `[6]` spells, then `triggerEnd` (`QuestieDB.lua` ~1205–1300).
- The quest-log objective at position *n* uses `quest.ObjectiveData[objective.Index]` (`QuestieQuest.lua:1101`, `1469`). **Order is meaningful.**
- **Quantities are not stored.** `ObjectiveData` entries hold `Type`, `Id` and `Text` only. Counts come from the client quest log at runtime.
- Kill credit: `{IdList = creditObjective[1], RootId = creditObjective[2], Text = creditObjective[3]}`. This is one objective satisfied by several creatures.
- `requiredSourceItems` become `SpecialObjectives` only "if not itemObjPresent" (no duplicate with `objectives[3]`).
- `sourceItemId` is used by the tracker for the usable-item button (`QuestieTracker.lua:805–821`).
- Availability: `IsPreQuestGroupFulfilled` (all required, unless an `exclusiveTo` sibling is done), `IsPreQuestSingleFulfilled` (any one), `nextQuestInChain` and `exclusiveTo` hide a quest once the follow-up or a sibling is done or in the log (`QuestieDB.lua` ~560–745).

## 3. Mapping to AzerothCore

Column names follow the AzerothCore 3.3.5 schema. Confirm each one against the actual export header before implementing (rule M-0).

| AzerothCore | Questie | Notes / rule |
|---|---|---|
| `RequiredNpcOrGo1–4` > 0 | `objectives[1]` creature | |
| `RequiredNpcOrGo1–4` < 0 | `objectives[2]` object (abs value) | E-GO-SIGN |
| `RequiredNpcOrGoCount1–4` | none (runtime) | E-QTY |
| Several creatures giving credit (`creature_template.KillCredit1/2`, SmartAI credit) | `objectives[5]` `{{ids}, rootId, text}` | E-KC |
| `RequiredItemId1–6` | `objectives[3]` | |
| `RequiredItemCount1–6` | none | E-QTY |
| `ItemDrop1–4` / `ItemDropQuantity` | `requiredSourceItems` or `extraObjectives`, often absent | E-SRC |
| `StartItem` (provided on accept) | `sourceItemId`; often also appears in `RequiredItemId` | E-STARTITEM (the 1,460 false positives) |
| `MinLevel` / `QuestLevel` (−1 = scaled) | `requiredLevel` / `questLevel` (−1 handled in `PrintDifficultyColor`) | E-LVL-DYN |
| `AllowableRaces` | `requiredRaces` (0 = any; Questie also infers faction from the starter NPC in `QuestieCorrections:Initialize`) | E-RACE-INFER |
| `quest_template_addon.PrevQuestID` > 0 | `preQuestSingle` or `preQuestGroup` | |
| `PrevQuestID` < 0 (must be *active*) | `parentQuest` / `childQuests` | E-PREV-NEG |
| `NextQuestID` | `nextQuestInChain` (opposite direction semantics, needs care) | NEEDS_MANUAL_REVIEW by default |
| `ExclusiveGroup` > 0 (one of) / < 0 (all) | `exclusiveTo` / `preQuestGroup` | E-EXCL |
| `BreadcrumbForQuestId` (if present in export) | `exclusiveTo` on the breadcrumb | E-BREADCRUMB |
| `SpecialFlags` (repeatable etc.) | `specialFlags` (bit 1 repeatable) | |
| `creature_queststarter` / `_questender`, `gameobject_queststarter` / `_questender` | `startedBy[1/2]`, `finishedBy[1/2]` and NPC/object `questStarts/Ends` | Check both directions |
| `conditions` (SourceType 19/20 quest availability/show mark, 9 gossip, etc.) | no equivalent | UNSUPPORTED (C-COND) |
| Individual Progression stage gates (module C++ scripts) | no equivalent | UNSUPPORTED (C-IP) |

Individual Progression decides availability through server scripts and character state, not through `quest_template`. Offline validation can therefore only say "statically consistent". It cannot say "available to this character". Every finding touching IP-gated content carries the `C-IP` caveat.

## 4. Validator design

**Language:** Python 3 for parsing SQL and reporting, building on PR #5's streaming reader. Lua 5.1 produces the effective Questie DB by running `cli/validate-335.lua`-style loading and writing the effective quest, NPC, object and item records to local JSON. This avoids reimplementing Questie's correction logic in Python, which is the weakness of the current approach.

```
tools/validate/
  export_effective_questie.lua   -- Lua 5.1: load Questie-335.toc path, run Initialize(), dump JSON (local)
  validate_objectives.py         -- read SQL export + effective JSON, apply rules, classify
  rules.py                       -- rule catalogue (code + docstrings)
  report.py                      -- CSV/Markdown/JSON writer (local only)
  fixtures/                      -- synthetic SQL + synthetic Questie records (public)
  test_validate_objectives.py
docs/VALIDATION-RULES.md         -- human-readable rule catalogue
```

**Classifications:**

| Class | Meaning |
|---|---|
| `CONFIRMED_MISMATCH` | Same semantic slot, different target ID or level, no rule applies, inputs well formed. Still needs human approval before any correction. |
| `EXPECTED_REPRESENTATION_DIFF` | Explained by one or more rule IDs, listed in the output |
| `NEEDS_MANUAL_REVIEW` | Ambiguous (multiple plausible mappings, scripted credit, `NextQuestID`, order differences) |
| `UNSUPPORTED` | Conditions, IP scripts, SmartAI, phasing. Out of offline scope. |

Each finding records: quest ID, field, server value, Questie effective value, the correction layer that last set the field, rule IDs, class and confidence.

**Rule catalogue (initial):**

| ID | Rule |
|---|---|
| E-QTY | Counts are not represented in Questie. Never a mismatch. |
| E-GO-SIGN | A negative `RequiredNpcOrGo` maps to `objectives[2]` |
| E-KC | A server creature in a Questie kill-credit `IdList` or `RootId` counts as a match |
| E-STARTITEM | `StartItem` equal to a `RequiredItemId` may appear as `sourceItemId` and not in `objectives[3]` |
| E-SRC | `ItemDrop` and source items may be missing or appear in `requiredSourceItems` / `extraObjectives` |
| E-ORDER | Questie orders creature → object → item. Order differences across types are expected; order differences *within* a type → NEEDS_MANUAL_REVIEW (pins attach by index). |
| E-SPELL | Spell-cast objectives (`objectives[6]`) vs server credit via script |
| E-EVENT | `triggerEnd` exploration vs server area trigger |
| E-LVL-DYN | Questie −1 vs server −1 or scaled |
| E-RACE-INFER | Questie `requiredRaces` 0 combined with faction inferred from the starter |
| E-PREV-NEG, E-EXCL, E-BREADCRUMB | Chain encodings as mapped in §3 |
| C-COND, C-IP | Always UNSUPPORTED, with a caveat |

Quest 1203 must come out as `CONFIRMED_MISMATCH` (item slot 1: 33110 vs 3853, no rule applies). This is the acceptance anchor.

**Privacy:** output goes to `private/validation/` and is added to `.gitignore` together with `*.sql`, `*.zip` (already ignored), `private/` and `*.validation.json`. CI runs only on `fixtures/`. The tool refuses to write inside the repo except under `private/`.

**Corrections from findings:** a separate, explicit approval file (`private/approved.json`: quest ID, field, expected old value, new value, reviewer, source). A generator emits narrowly scoped, source-guarded `RegisterCorrection` callbacks in the PR #6/#7 style into `Compat/NQuestie*Corrections.lua` and bumps the shared revision. Generated `Database/Wotlk/*DB.lua` files are never edited. The generator belongs with the lead developer's PR #3 tooling. The validator only *proposes*.

**Optional in-addon command (Lua 5.1, later):** `/questie nqvalidate <questId>` prints the effective record (levels, objectives by index, starters and enders, prerequisites) and, for an accepted quest, compares `GetQuestLogLeaderBoard` objective types and order with `ObjectiveData`. Read only, no SavedVariables writes, debug-gated. This is the only way to catch E-ORDER problems against the real client.

**Synthetic fixtures:**

| Fixture | Expectation |
|---|---|
| Normal kill + item quest | All match |
| Modified item (1203-like, fake IDs) | CONFIRMED_MISMATCH |
| Gameobject objective (negative ID) | E-GO-SIGN |
| Kill credit with 3 creatures | E-KC |
| StartItem in RequiredItem | E-STARTITEM |
| Mixed NPC/GO order | E-ORDER or manual review |
| Quest with `conditions` row | UNSUPPORTED |
| Missing in Questie | reported in a separate "missing" bucket |
| Malformed SQL row or truncated INSERT | fail closed with an error, no partial report |
| Unknown column set | fail closed (M-0 schema check) |

**Limitations:** offline validation cannot see SmartAI or C++ credit scripts, conditions, phasing, IP stage, dynamic levels, spawn accuracy, client-side quest-log text or objective order. It also cannot see locale overrides (`l10n:Initialize` replaces `objectivesText` on non-enUS clients). A clean result means "statically consistent", nothing more.

## 5. Milestones

| M | Deliverable | Acceptance |
|---|---|---|
| M0 **(implemented, see NQ-VALIDATION-M0.md)** | Effective-DB validation harness `cli/validate-335.lua` with allow-list preservation check; JSON export deferred to M1. Original scope: effective-DB exporter (Lua 5.1), built on the 335 harness, plus a schema check of the export header | Dumps effective records for 1203 and the 8 Dustwallow IDs equal to the review's harness output. Fails on an unknown schema. |
| M1 | Rule catalogue doc and Python core for item and NPC objectives with synthetic fixtures | All fixtures pass in CI. Synthetic 1203 → CONFIRMED_MISMATCH. Synthetic StartItem → E-STARTITEM. |
| M2 | Private run on the 24 item and 151 NPC candidates (maintainer runs it locally) | Every candidate classified. Count of CONFIRMED vs EXPECTED reported in aggregate only. 1203 is reproduced. |
| M3 | Gameobject, kill-credit and order rules, plus chain and prerequisite rules | Fixtures for each rule. The 18 missing quests are classified for chain consistency. |
| M4 | Approval file → hand-off format for the lead developer's correction generator | Round trip: an approved finding becomes a guarded callback, and the 335 harness shows the field changed with no others touched. |
| M5 | Optional `/questie nqvalidate` command | Read only. Shown on 1203 in game. No taint or Lua errors. |

## 6. Files and dependencies

- **New:** `tools/validate/*`, `docs/VALIDATION-RULES.md`, `cli/validate-335.lua` (shared with the review recommendation), `.gitignore` entries.
- **Later modification:** `.github/workflows/nquestie-overlay.yml` (fixture job). For M5 only, a new `Compat/NQuestieValidateCommand.lua` plus one TOC line.
- **Dependencies:** PR #4 merged (green Busted). PR #3/#2 ancestry fixed. PR #5's SQL reader reused rather than duplicated (coordinate file ownership with the lead developer). PR #6/#7 correction style is the target output format. No edits to the lead developer's branches; the validator goes in its own draft PR once approved.

## 7. Recommended first milestone

**M0.** It is small. It reuses the harness already proven in the review. It fixes the main weakness of the existing audit (literal approximation of correction layers). It also gives CI a real 3.3.5a integration test at the same time.
