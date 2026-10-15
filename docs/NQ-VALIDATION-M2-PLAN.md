# N-Questie Validation M2: Plan

Status: Proposed, not implemented
Date: 2026-10-14
Owner (framework, safety, tests): validation workstream
Owner (private data processing): lead developer, run locally only
Depends on: M1 with review fixes (docs/NQ-VALIDATION-M1.md §10)

## 1. Goal

Run the M1 objective rules over the full set of server quests, compared with the effective N-Questie records. Produce a private report for each quest and a public aggregate summary. M2 does not change any quest data.

## 2. Split of responsibilities

| Part | Owner | Where it runs | In the repo |
|---|---|---|---|
| Export of acore_world rows (quest_template, creature_template KillCredit, conditions, IP gating, scripts) | Lead developer | Local machine only | No |
| Private adapter: export → input schema (§4) | Lead developer | Local machine only | No (only the schema and a synthetic sample) |
| Input schema and validator for it | Validation workstream | Repo + CI | Yes |
| Effective-record export from the 3.3.5a harness | Validation workstream | Repo + CI | Yes |
| Batch runner, report writer, aggregate summary | Validation workstream | Repo + CI | Yes |
| Synthetic fixtures and tests | Validation workstream | Repo + CI | Yes |
| Review of findings and any correction PRs | Lead developer + Michael | — | Separate, approved PRs only |

## 3. Architecture

1. **Private export** (lead developer, local) writes one row per quest in the schema in §4, to `private/` (gitignored).
2. **Schema check** (`tools/validation/InputSchema.lua`) rejects the whole input if any row is malformed. Rows are never silently repaired.
3. **Effective records**: `cli/validate-335.lua --export-effective <file>` writes the post-correction objectives, start items and source items for every quest, after the 82,431-field preservation check passes. If the check fails, nothing is exported.
4. **Batch runner** (`cli/validate-objectives-batch.lua`) runs `ObjectiveRules.Compare` per quest and writes:
   - `private/m2-report.tsv`: a row per finding, kept local
   - `private/m2-summary.md`: counts by class and rule only, with no ids, names or text from private rows
5. **Publication**: only the aggregate summary may be pasted into a PR or issue, and only after the lead developer has reviewed it.

## 4. Input schema (per quest)

| Field | Type | Rule |
|---|---|---|
| ID | integer > 0 | Required |
| RequiredNpcOrGo1-4, RequiredNpcOrGoCount1-4 | integer | AzerothCore meaning; a negative id is a gameobject |
| RequiredItemId1-6, RequiredItemCount1-6 | integer >= 0 | |
| ItemDrop1-4, StartItem | integer >= 0 | |
| KillCredit | map creatureId → {credit1, credit2} | Must cover every creature in RequiredNpcOrGo and every Questie creature for that quest; `{0, 0}` = verified none |
| killCreditComplete | boolean | Only set true when the adapter has written a row for every relevant creature |
| hasConditions, ipGated, scriptedCredit | true / false / "unknown" | Never omitted in M2 input; "unknown" when the source does not establish it |
| provenance | string | Export date and the DB build or commit it came from; recorded in the report header, never published |

KillCredit provenance: the adapter takes the values straight from `creature_template.KillCredit1/2`. It does not infer them, and it writes `{0, 0}` only for rows it actually read. A creature with no row is left out, so M1 fails closed (R-NPC-NOCREDIT).

## 5. Safety requirements

- Private inputs and outputs live only under `private/`. This is already gitignored; a CI check must fail if any file under `private/` is tracked.
- CI uses synthetic fixtures only. No test may need private data to pass.
- Fail closed: a schema error, harness preservation failure, or missing effective record stops the run with a non-zero exit code. It never produces a partial report that looks complete.
- Report-only. No code path writes quest data, corrections, SQL, the addon install or SavedVariables.
- The runtime revision system is not touched.
- **CONFIRMED_MISMATCH is not directly actionable.** Each confirmed row needs human review and a separately approved correction PR, as the lead developer asked.
- Individual Progression availability is never claimed. `ipGated` only lowers confidence.

## 6. Milestones and acceptance criteria

| Step | Deliverable | Acceptance |
|---|---|---|
| M2.1 | Input schema + validator + synthetic sample | Rejects every malformed fixture; accepts the sample; tested in CI |
| M2.2 | Effective-record export from the harness | Export matches the compiled DB for all quests; runs only after the preservation check passes; quest 1203 export gives EXPECTED against server data |
| M2.3 | Batch runner + private report + aggregate summary | Synthetic batch of at least 50 quests gives the expected counts; summary contains no ids or text; private-path guard tested |
| M2.4 | Lead-developer local run | Lead developer runs it on the private export and shares the aggregate counts only |
| M2.5 | Triage | Confirmed rows reviewed by hand; any fixes go in separate, approved PRs |

## 7. Integration (after M1 fixes are accepted)

A separate integration branch will combine the improved M1, PR #16's strict 28-quest M0 harness, the revision guard (#12/#14) and the #4 fix. The 82,431-field preservation check stays as strict as it is now. That work is not part of M2 and needs its own approval.

## 8. Out of scope

Live server queries, automatic corrections, evaluating conditions or scripts, IP phase simulation, publishing per-quest private data.
