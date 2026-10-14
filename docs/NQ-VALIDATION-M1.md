# N-Questie — Validation M1: Quest Objective Validation Rules

**Date:** 14 October 2026
**Status:** Draft branch `feat/nq-validation-m1-objectives-2026-10-14`. Report only. Not merged.
**Owner:** Grok Bot (validation workstream)
**Base:** PR #11 head `f2ab43fd` (M0 harness + PR #8 + active M0 workflow)
**Data used:** public Questie source and synthetic fixtures only. No private acore_world data is read or required.

## 1. Why this base

PR #11 already contains the M0 harness, the active `nquestie-validate-335.yml` workflow (from #10) and PR #8. The M1 check on real Questie data for quest 1203 is added to that harness, so it runs in GitHub CI on this draft PR without any workflow edit. Basing M1 on #9 or #10 alone would lose PR #8 coverage. Basing it on #7 would lose the harness. This branch does **not** extend validation to PR #13's nine Classic chain corrections; that is coordinated separately.

## 2. What M1 delivers

| File | Purpose |
|---|---|
| `tools/validation/ObjectiveRules.lua` | Pure Lua 5.1 rule engine. `FromQuestTemplateRow(row)` turns a quest_template-shaped row into a normalised record; `Compare(server, questie)` returns findings; `Worst()` and `Format()` produce summaries. No WoW API, no globals, no I/O, no writes. |
| `tools/validation/fixtures/objective_cases.lua` | 20 synthetic cases, SQL-shaped (AzerothCore column names), including quest 1203 |
| `tools/validation/run_cases.lua` | Shared checker used by both test runners |
| `tests/test_nquestie_objective_rules.lua` | Standalone Lua 5.1 test; also requires every catalogued rule to be exercised and inputs to stay unmodified |
| `tools/validation/ObjectiveRules.test.lua` | busted spec (22 tests) |
| `cli/validate-objectives.lua` | Prints a report for a cases file (default: synthetic fixtures). Private inputs belong under `private/` (gitignored). |
| `cli/validate-335.lua` (extended) | Runs the M1 rules on the **real** quest 1203 records: stock objectives → `CONFIRMED_MISMATCH`, effective N-Questie record → only `EXPECTED_REPRESENTATION_DIFF` |
| `docs/proposed-workflows/nquestie-objective-rules.yml` | Proposed CI job for the M1 tests (not active; token lacks workflow scope) |

## 3. Technical design

### 3.1 Inputs

- **Server side:** a row keyed by quest_template column names:
  - `ID`
  - `RequiredNpcOrGo1–4` and `RequiredNpcOrGoCount1–4` (negative = gameobject)
  - `RequiredItemId1–6` and `RequiredItemCount1–6`
  - `ItemDrop1–4`
  - `StartItem`

  Four optional reviewer-supplied keys are not quest_template columns:
  - `KillCredit = {[creature] = {KillCredit1, KillCredit2}}` from creature_template
  - `killCreditComplete`
  - `hasConditions`
  - `ipGated` / `scriptedCredit`

  Malformed values (non-integers, negative counts, a count without an id, negative item ids) stop classification with `R-MALFORMED`.
- **Questie side:** the effective record by `QuestieDB.questKeys` index:
  - `objectives` (10): `[1]` creatures, `[2]` objects, `[3]` items, `[5]` kill credit `{{ids}, rootId, text}`, `[6]` spells
  - `sourceItemId` (11), `requiredSourceItems` (21), `extraObjectives` (27), `triggerEnd` (9)

### 3.2 What Questie stores and what the client supplies

| Data | Questie DB | Supplied at runtime by the 3.3.5a client |
|---|---|---|
| Objective target ids | yes (`objectives`) | — |
| Objective counts (required and current) | **no** | quest log (`GetQuestLogLeaderBoard` text and counts) |
| Objective order | implied by type grouping: creatures, objects, items, reputation, kill credit, spells (`QuestieDB.lua`) | quest-log index; Questie maps log objective N to `ObjectiveData[N]` (`QuestieQuest.lua:1101, 1469`) |
| Objective text | optional custom text per objective | quest log text |
| Source and start items | `sourceItemId`, `requiredSourceItems`, `extraObjectives` | bag contents |

Counts are therefore never compared (`E-QTY`). Order is reviewed only where it can misplace pins.

### 3.3 Classification order

1. Malformed input → `NEEDS_MANUAL_REVIEW` (`R-MALFORMED`). Stop.
2. Quest missing from Questie → `NEEDS_MANUAL_REVIEW` (`R-QUEST-MISSING`). Stop.
3. `conditions` / IP gate → `UNSUPPORTED` (`C-COND`, `C-IP`). Comparison continues for static fields, but no availability claim is made.
4. Creatures and gameobjects, per server slot:
   - Negative id → object: an `objectives[2]` match gives `E-GO-SIGN`. The same id as a creature gives `R-GO-AS-NPC`. A missing object gives `R-GO-UNPAIRED`, or `C-SCRIPT` if credit is scripted.
   - Positive id: a direct `objectives[1]` match is consistent. If it is in kill credit, `E-KILLCREDIT`. If creature_template KillCredit links a Questie creature, `E-KC-TEMPLATE`.
   - Remaining pairs: `C-SCRIPT` if scripted; `CONFIRMED_MISMATCH` (`M-NPC-TARGET`) only when complete KillCredit data was supplied; otherwise `R-NPC-NOCREDIT`. Single-sided targets give `R-NPC-UNPAIRED`.
5. Items:
   - A direct `objectives[3]` match is consistent. `StartItem` held as a Questie source item gives `E-STARTITEM`.
   - `ItemDrop` items not required give `E-SRCITEM`, or `R-SRC-AS-OBJECTIVE` if Questie tracks them as an objective.
   - Remaining unmatched items that pair one-to-one with Questie extras give `CONFIRMED_MISMATCH` (`M-ITEM-TARGET`). Anything else gives `R-ITEM-UNPAIRED`.
6. Order: same-type order differences give `R-ORDER-WITHIN-TYPE`. A gameobject slot before a creature slot gives `R-ORDER-MIXED`. Otherwise, if both creature/object and item slots exist, `E-ORDER-TYPE`.

Every finding carries a class, at least one rule id, a plain-English explanation, and the server and Questie values. A quest's summary class is the worst of its findings: CONFIRMED > REVIEW > UNSUPPORTED > EXPECTED.

### 3.4 Guarantees

- Report only. `Compare` never mutates its inputs (tested). Nothing generates or applies corrections.
- No availability claims. `C-IP` and `C-COND` explanations state that eligibility is not assessed.
- `CONFIRMED_MISMATCH` still means "needs human approval before any correction", as in the design document.

## 4. Rule table

| Rule | Class | Meaning |
|---|---|---|
| `C-COND` | UNSUPPORTED | conditions rows affect this quest. Questie has no equivalent, so availability and objective visibility cannot be validated offline. |
| `C-IP` | UNSUPPORTED | Individual Progression decides when this quest is available. Static data can only show consistency, not eligibility for a character. |
| `C-SCRIPT` | UNSUPPORTED | Objective credit is granted by a server script (SmartAI or C++). The credited creature or object is not visible in quest_template. |
| `E-GO-SIGN` | EXPECTED | AzerothCore stores gameobject targets as negative RequiredNpcOrGo values. Questie stores the positive id in objectives[2] (object objectives). |
| `E-KC-TEMPLATE` | EXPECTED | Questie lists the creature the player actually kills. Its creature_template KillCredit1/KillCredit2 points at the server's RequiredNpcOrGo target. |
| `E-KILLCREDIT` | EXPECTED | The server target creature is listed in a Questie killCreditObjective (objectives[5]) as an alternative or root creature. |
| `E-ORDER-TYPE` | EXPECTED | Questie groups objectives by type (creature, object, item). The server's slot order differs only across types, which Questie's own ordering accounts for. |
| `E-QTY` | EXPECTED | Questie does not store objective counts. The client quest log supplies required and current counts at runtime, so count values are not compared. |
| `E-SRCITEM` | EXPECTED | ItemDrop items are source items, not counted objectives. Questie may list them in requiredSourceItems/extraObjectives or omit them. |
| `E-STARTITEM` | EXPECTED | The required item is the quest's StartItem (given on accept). Questie keeps it as sourceItemId or requiredSourceItems instead of an item objective. |
| `M-ITEM-TARGET` | CONFIRMED | Same item objective slot, different item id on each side, and no representation rule applies. Treat as a genuine data difference until reviewed. |
| `M-NPC-TARGET` | CONFIRMED | Same creature slot, different creature id, and the supplied KillCredit data does not link them. Treat as a genuine data difference until reviewed. |
| `R-GO-AS-NPC` | NEEDS_MANUAL_REVIEW | The server marks the target as a gameobject (negative id) but Questie lists the same id as a creature objective. |
| `R-GO-UNPAIRED` | NEEDS_MANUAL_REVIEW | A gameobject target appears on only one side. Questie sometimes models object use as a spell, event or extra objective. |
| `R-ITEM-UNPAIRED` | NEEDS_MANUAL_REVIEW | An item appears on only one side. It may be a missing objective, an extra Questie objective, or a source item. A person must check the quest text. |
| `R-MALFORMED` | NEEDS_MANUAL_REVIEW | The server-shaped input is malformed (non-integer id, negative count, count without id). The record was not classified further. |
| `R-NPC-NOCREDIT` | NEEDS_MANUAL_REVIEW | Creature targets differ and creature_template KillCredit data was not supplied, so a kill-credit relationship cannot be ruled out. |
| `R-NPC-UNPAIRED` | NEEDS_MANUAL_REVIEW | A creature target appears on only one side. |
| `R-ORDER-MIXED` | NEEDS_MANUAL_REVIEW | The server places a gameobject slot before a creature slot. Questie lists creatures first, so quest-log indexes may not line up with Questie's objective list. |
| `R-ORDER-WITHIN-TYPE` | NEEDS_MANUAL_REVIEW | Two targets of the same type are in a different order. Questie maps quest-log objective N to its N-th objective, so pins may attach to the wrong line. |
| `R-QUEST-MISSING` | NEEDS_MANUAL_REVIEW | The quest exists in the server data but not in Questie. Handled by the reviewed import workflow, not by objective rules. |
| `R-SRC-AS-OBJECTIVE` | NEEDS_MANUAL_REVIEW | Questie lists an ItemDrop source item as an item objective, but the server does not require it. The tracker may show an extra objective. |

## 5. Quest 1203 example

Public facts (`docs/REVIEW-2026-10-14.md`): the server requires one Moonsteel Broadsword (3853); stock WotLK Questie has Razorspine's Sword (33110) as its item objective.

| Input | Classification |
|---|---|
| Synthetic row `{ID=1203, RequiredItemId1=3853, RequiredItemCount1=1}` vs stock `{nil,nil,{{33110}}}` | `CONFIRMED_MISMATCH` (`M-ITEM-TARGET`): "Server requires item 3853 (RequiredItemId1); Questie's item objective is 33110. No representation rule explains the difference." |
| Same row vs the N-Questie corrected record | `E-QTY` only (consistent apart from counts) |
| Same row vs the **real** stock and effective records in `cli/validate-335.lua` | stock → `CONFIRMED_MISMATCH`; effective → `EXPECTED_REPRESENTATION_DIFF` |

## 6. Test results (local, 14 Oct 2026, ~14:10–14:40 BST, Lua 5.1.5)

| Check | Result |
|---|---|
| `lua5.1 tests/test_nquestie_objective_rules.lua` | PASS: 20 fixtures, all 22 rules exercised, inputs unchanged |
| `busted -p ".test.lua" tools/validation` | 22 successes / 0 failures / 0 errors |
| `NQ_VALIDATE_EXPECT_LEVEL_COUNT=19 lua5.1 cli/validate-335.lua` | PASS, 183 checks (adds the 2 M1 checks on real 1203 data); 0 unexpected changes; compiled round trip 0 mismatches |
| `tests/test_validate_335_fixtures.sh` | 4/4 negative fixtures rejected with the expected message |
| Other `tests/test_nquestie_*.lua` | 4/4 PASS |
| `tools/test_*.py` | 4/4 pass |
| Full busted on this branch | 22 / 0 / 9 errors (the 9 are the inherited `QuestieCompat` failure; needs PR #4) |
| Full busted on a throwaway merge with PR #4 (not pushed) | 40 successes / 0 failures / 0 errors |
| `luacheck` (M1 files, harness, CI scope with CI globals) | 0 warnings / 0 errors |
| `luac5.1 -p` on all `cli/`, `tests/` and `tools/validation/` Lua | OK |

GitHub CI results are recorded in the PR.

## 7. Limitations

- **Synthetic only.** Real classification of the 24 item and 151 NPC candidates needs the maintainer's private export, converted locally into the row format (M2). Nothing here uses or requires it.
- **Kill credit.** `CONFIRMED_MISMATCH` for creatures needs complete creature_template KillCredit data. Without it, results stay `NEEDS_MANUAL_REVIEW`. SmartAI or C++ credit is invisible and must be flagged by a reviewer (`scriptedCredit`).
- **Conditions and Individual Progression.** These are flagged `UNSUPPORTED` from reviewer-supplied flags. The tool does not read the `conditions` table or IP module code, and it never states availability.
- **Gameobject alternatives.** Questie sometimes models object use as spell, event or extra objectives. These stay `NEEDS_MANUAL_REVIEW`.
- **Pairing.** Unmatched items and creatures are paired in slot order. With several unmatched targets on both sides the pairing may be wrong, so the explanation lists both values.
- **Client behaviour.** Quest-log order, counts and objective text come from the 3.3.5a client. Order findings are risks, not proof; they need in-game checks.
- **Not wired into CI.** The standalone M1 tests run in CI only through the inherited busted job (blocked by #4) and the 1203 checks inside the active M0 workflow. The dedicated job is proposed.

## 8. Next (M2, not started)

A local converter from the private export to the row format under `private/`, an effective-record export from the M0 harness, then the first private classification run. Only aggregate counts will be published.

## 10. Review fixes (2026-10-14)

Status: Draft, report-only
Branch: feat/nq-validation-m1-review-fixes-2026-10-14 (based on PR #17 head 460dbf304)
Trigger: lead-developer technical review on PR #15

### 10.1 Kill credit (review point 1)

`killCreditComplete = true` is now only an assertion. On its own it no longer produces CONFIRMED_MISMATCH.

M-NPC-TARGET is reported only when all of the following hold:

| Condition | Required evidence |
|---|---|
| Unmatched creatures | Exactly one on the server side and one on the Questie side |
| KillCredit rows | A well-formed `{credit1, credit2}` entry (integers >= 0, `{0, 0}` allowed) for both creatures |
| Coverage | `killCreditComplete = true` |
| Scripted credit | `scriptedCredit = false` (explicitly) |

If any condition fails, the finding is R-NPC-NOCREDIT (NEEDS_MANUAL_REVIEW). The explanation names the missing creature rows and any other failed condition. A malformed KillCredit entry is reported as R-MALFORMED.

### 10.2 Multiple unmatched targets (review point 2)

Slot-position pairing has been removed. The only evidence accepted for a one-to-one correspondence is:

1. Equal ids (match by id, not by slot).
2. A representation rule: E-KC-TEMPLATE (creature_template KillCredit link), E-STARTITEM, E-SRCITEM, E-GO-SIGN.
3. Elimination: after 1 and 2, exactly one target remains unmatched on each side of the same type (with the kill-credit conditions in 10.1 for creatures).

When more than one target of a type is unmatched on either side and the other side is not empty, one set-level finding is reported. It lists both sets and does not pair them.

| New rule | Class | Meaning |
|---|---|---|
| R-ITEM-SET | NEEDS_MANUAL_REVIEW | Item sets differ, no pairing claimed |
| R-NPC-SET | NEEDS_MANUAL_REVIEW | Creature sets differ, no pairing claimed |
| C-UNKNOWN | UNSUPPORTED | Converter marked a flag as `"unknown"` |

Reordering alone is never a mismatch. Same ids in another order give only R-ORDER-WITHIN-TYPE, so item and NPC reorder fixtures both return no CONFIRMED finding.

### 10.3 Tri-state flags (coordination point)

`hasConditions`, `ipGated` and `scriptedCredit` accept `true`, `false` or `"unknown"`. If a flag is omitted, it is treated as not established. If a flag has any other value, it is reported as R-MALFORMED. A `"unknown"` value adds a C-UNKNOWN finding.

### 10.4 New regression fixtures

| Quest | Case | Result |
|---|---|---|
| 900999 | Reviewer repro: completeness flag, no KillCredit rows | R-NPC-NOCREDIT |
| 900020 | KillCredit row missing for the server target | R-NPC-NOCREDIT |
| 900021 | Rows complete, completeness not asserted | R-NPC-NOCREDIT |
| 900022 | Rows complete, scriptedCredit "unknown" | R-NPC-NOCREDIT + C-UNKNOWN |
| 900008 | Genuinely complete data (updated) | M-NPC-TARGET |
| 900023 | Two items replaced by two items | R-ITEM-SET |
| 900024 | Two items vs one item | R-ITEM-SET |
| 900025 | Two creatures replaced, complete KillCredit | R-NPC-SET |
| 900026 | Items reordered | R-ORDER-WITHIN-TYPE only |
| 900013 | Creatures reordered (existing) | R-ORDER-WITHIN-TYPE only |
| 900027 | Invalid flag and KillCredit row | R-MALFORMED |

Quest 1203 against stock Questie is still CONFIRMED_MISMATCH (single unmatched item on each side). The effective N-Questie record is still EXPECTED_REPRESENTATION_DIFF.

### 10.5 Results

| Check | Result |
|---|---|
| tests/test_nquestie_objective_rules.lua | PASS, 29 fixtures, 25 rules all exercised |
| busted tools/validation | 31 successes, 0 failures |
| cli/validate-335.lua (NQ_VALIDATE_EXPECT_LEVEL_COUNT=19) | PASS, 183 checks |
| tests/test_validate_335_fixtures.sh | PASS, 4 negative fixtures |
| Other tests/test_nquestie_*.lua | PASS |
| luacheck | 0 warnings / 0 errors |

### 10.6 Additional verified checks (2026-10-14, branch head 3c742eae7)

| Check | Result |
|---|---|
| tests/test_validate_335_fixtures.sh | All 4 negative fixtures ran and were rejected as intended (see below) |
| Full busted (`busted -p ".test.lua" .`) on 3c742eae7 alone | 31 successes, 0 failures, 9 errors (QuestieCompat nil, needs PR #4) |
| Full busted with PR #4 (c2bc4a76) merged, local throwaway branch, deleted, not pushed | 49 successes, 0 failures, 0 errors |
| tests/test_nquestie_*.lua (5 files), with PR #4 merged | All PASS |
| tests/test_nquestie_objective_rules.lua, with PR #4 merged | PASS, 29 fixtures, all rules exercised |
| busted tools/validation, with PR #4 merged | 31 successes, 0 failures |
| tools/test_audit_world_quest_levels.py | 12 tests, OK |
| tools/test_export_world_quests.py | 4 tests, OK |
| tools/test_generate_custom_quests.py | 9 tests, OK |
| tools/test_reviewed_early_quest_sources.py | 3 tests, OK |

Negative fixtures:

| Fixture | Rejection message |
|---|---|
| corrupted_correction.lua | 1203 item objective is 3853 |
| early_level_wrong_value.lua | PR #8 quest 169 requiredLevel 15 |
| missing_quest.lua | quest 2001 missing after corrections |
| unexpected_field_change.lua | not allow-listed |
