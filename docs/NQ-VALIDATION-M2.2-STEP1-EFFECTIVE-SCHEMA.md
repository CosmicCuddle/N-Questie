# N-Questie Validation M2.2 Step 1: Effective Record Schema

Status: Draft, report-only, schema and validator only (no export logic)
Date: 2026-10-14
Branch: feat/nq-validation-m2.2-step1-effective-schema-2026-10-14 (based on PR #22)
Schema: `nq-m2-effective` version 1
Depends on: `nq-m2-input` v1 (frozen), reused unchanged

## 1. Purpose

Define and validate the file a later M2.2 export will write: the **effective** objective data of each selected quest after the normal 3.3.5a compile and the N-Questie correction pipeline. M2.3 compares these records with `nq-m2-input` server rows through the M1 rules.

The validator is `tools/validation/EffectiveSchema.lua`. It contains no export code and the M0 harness is not changed.

## 2. Reuse of M2.1

| Part | Source | Changed? |
|---|---|---|
| Data-only parser (no code, no duplicate keys, 16 MB cap) | `InputSchema.ParseString` | No |
| Fail-closed path rules (`realpath -e`, resolved target governs) | `InputSchema.CheckInputPath` | No |
| File loading | `EffectiveSchema.LoadFile` (same steps as M2.1) | New, M2.1 untouched |

`InputSchema.lua` is not modified. All M2.1 tests run unchanged.

Effective fixtures live in `tests/fixtures/m2_effective/`. The frozen M2.1 path rules only allow `tests/fixtures/m2_input/` inside the checkout, so `LoadFile` tests copy the fixture to a temporary folder first. This is intended: real exports must be outside the checkout.

## 3. Document

```lua
return {
    schema = "nq-m2-effective",
    schemaVersion = 1,
    provenance = { ... },
    quests = { { ... }, ... },   -- list
}
```

Unknown fields at any level are rejected. Unsupported versions are rejected.

## 4. Provenance

| Field | Effective | Stock |
|---|---|---|
| harness | name, e.g. `validate-335` | same |
| harnessVersion | semver | same |
| dataKind | `"effective"` | `"stock"` |
| sourceCommit | 40 lowercase hex (git commit of the compiled checkout) | same |
| sourceTree | 40 lowercase hex (git tree of that commit) | same |
| sourceDirty | must be `false` | must be `false` |
| tocInterface | `30300` | `30300` |
| flavour | `"wotlk-335"` | same |
| nQuestieDataRevision | integer ≥ 1 | `0` |
| correctionCount | integer ≥ 1 (28 today) | `0` |
| correctionFingerprint | `sha256:` + 64 hex over the correction modules | `"none"` |
| correctionModules | non-empty list of plain `.lua` file names, no duplicates, no paths | `{}` |
| m0Checks | integer ≥ 1 (passed M0 assertions) | `0` |
| exportedAt | `YYYY-MM-DDThh:mm:ssZ` | same |
| questCount | equals `#quests` | same |

`Validate(doc, { expectKind = "effective", expectCorrectionCount = 28 })` lets M2.3 refuse a stock file, or one built from a different correction set.

## 5. Quest record (all fields required)

| Field | Type | M1 / Questie mapping |
|---|---|---|
| ID | integer ≥ 1 | quest id |
| requiredLevel | integer 0–255 | questKeys 4 |
| questLevel | integer −1–255 (−1 = scales) | questKeys 5 |
| sourceItemId | integer ≥ 0 (0 = none) | questKeys 11 |
| requiredSourceItems | list of positive ids | questKeys 21 |
| objectives.creatures | list of positive ids, in Questie order | objectives[1] |
| objectives.objects | list of positive ids (Questie stores gameobjects positive) | objectives[2] |
| objectives.items | list of positive ids | objectives[3] |
| objectives.killCredit | list of `{ ids = {…non-empty}, rootId = n }` | objectives[5] |
| objectives.spells | list of positive ids | objectives[6] |
| hasTriggerEnd | boolean | questKeys 9 present |
| hasExtraObjectives | boolean | questKeys 27 present |
| extraObjectiveItems | list of item ids referenced by extraObjectives (empty when the flag is false) | questKeys 27 item refs |

Ids within one list must be unique. Order is kept because M1 reports ordering notes. Reputation objectives (slot 4), objective text and counts are not in v1: M1 does not use them, and Questie does not store counts.

## 6. M2.3 compatibility

`EffectiveSchema.ToQuestieRecord(record)` returns a new questKeys-indexed table in the shape `ObjectiveRules.Compare` already accepts. It does not modify the record. Tests show:

- Stock 1203 (item 33110) against server item 3853 → CONFIRMED_MISMATCH.
- Effective 1203 (item 3853) → no confirmed mismatch.
- killCredit objectives reach M1 as E-KILLCREDIT.

## 7. Error messages (examples)

| Situation | Message (substring) |
|---|---|
| Stock file where effective is required | `provenance.dataKind: expected "effective"` |
| Wrong correction set size | `provenance.correctionCount: expected 28` |
| Dirty source tree | `provenance.sourceDirty: must be false` |
| Wrong client build | `provenance.tocInterface: must be 30300` |
| AzerothCore-signed gameobject | `objectives.objects[1]: must be a positive integer id` |
| Duplicate quest | `duplicate quest ID 1203` |
| Empty killCredit ids | `killCredit[1].ids: must not be empty` |

## 8. Tests

| Suite | Coverage |
|---|---|
| `tests/test_nquestie_m2_effective_schema.lua` | 71 checks: valid effective and stock fixtures, kind/count expectations, 5 stock-provenance rules, 48 rejection cases, non-mutation, M1 compatibility, shared parser, path rules via temp files |
| `tools/validation/EffectiveSchema.test.lua` | Busted; runs in the existing M1 workflow |

## 9. Representability in real data (found in Step 2)

> Historical snapshot (before the #36 kill-credit order check). Current measured figures: 8,401 representable, 758 unsupported of 9,159 (`NQ-VALIDATION-M2.2-COVERAGE.md` §3).

A scan of all 9,159 compiled 3.3.5a quests found 752 that v1 cannot represent: reputation objectives (181 quests), extraObjectives references to monsters (466) or objects (335), and the same id twice in one objective list (10). The exporter refuses them; v1 is unchanged. See `docs/NQ-VALIDATION-M2.2-HANDOVER.md` §4 for the options.

## 10. Out of scope

The export itself, changes to the M0 harness, M2.3 batch runner, any real data.
