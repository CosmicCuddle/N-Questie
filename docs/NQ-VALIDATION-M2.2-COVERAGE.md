# N-Questie M2.2 coverage / preflight report (nq-m2-effective v1)

Status: tool complete, real-DB run complete. This is a **coverage report, not an export.**
Decision in force (Michael, 14 October 2026): Option A. v1 stays frozen; v1-unsupported quests are out of scope for the initial pilot (temporary) and v2 is designed next. The exporter stays fail-closed.
Date: 14 October 2026 (Europe/London)

## 1. What the tool does

| Item | Detail |
|---|---|
| Entry point | `cli/validate-335.lua` with `NQ_COVERAGE_MANIFEST_OUT` (and optional `NQ_COVERAGE_AGGREGATE_OUT`) |
| Runs when | Only after all 232 M0 checks pass, on the compiled DB (same gate as the export) |
| Scope | Every quest in `QuestieDB.QuestPointers` (9,159) |
| Classification | `Coverage.Classify` calls `EffectiveExport.Record`, the exporter's own code. Reasons and messages are identical by construction (tested). |
| Reasons per quest | All kept, with occurrence counts. Nothing is trimmed, deduplicated or reinterpreted. |
| Unexpected failures | An error inside `Record` becomes `UNEXPECTED_ERROR`; a refusal without a code becomes `UNCLASSIFIED`. Both count as unclassified, never as representable. |
| Reconciliation | `Aggregate` asserts representable + unsupported = total and that reason combinations sum to unsupported, or it raises. |
| Per-quest manifest | Written only through `SafeWrite` to a private path (outside the checkout or under `private/`), 0700 directory, 0600 file, no clobber. Contains IDs, status and reason codes plus provenance; no effective records. |
| Aggregate | Counts only; safe to publish. Printed to the log; optional SafeWrite copy. |
| Mutually exclusive with | the effective export, `NQ_VALIDATE_FIXTURE`, `NQ_VALIDATE_SKIP_COMPILE` |

The exporter uses the same reason codes. An export that requests an unsupported ID fails, writes nothing, and prints the exact messages plus one line per quest: `quest 11142: refused, reasons: DUPLICATE_OBJECT,EXTRA_CREATURE_REF`. A requested ID missing from the compiled DB is reported as `ABSENT_FROM_EFFECTIVE_DB`.

## 2. Reason codes

| Code | Category | Meaning |
|---|---|---|
| `EXTRA_CREATURE_REF` | creature extra objectives | extraObjectives reference of type `monster` |
| `EXTRA_OBJECT_REF` | object extra objectives | extraObjectives reference of type `object` |
| `REPUTATION_OBJECTIVE` | reputation | `objectives[4]` present |
| `DUPLICATE_CREATURE` | duplicate creature | same creature ID twice in `objectives[1]` |
| `DUPLICATE_OBJECT` | duplicate object | same object ID twice in `objectives[2]` |
| `KILLCREDIT_FIRST_REORDER` | order | quest is in `QuestieCorrections.killCreditObjectiveFirst` and has killCredit plus another objective (or several killCredit entries); its quest-log positions differ from the kind order v1 implies (§6) |
| `DUPLICATE_ITEM`, `DUPLICATE_SPELL`, `DUPLICATE_KILLCREDIT_ID`, `DUPLICATE_SOURCE_ITEM`, `DUPLICATE_EXTRA_ITEM`, `EXTRA_OTHER_REF`, `LEVEL_INVALID`, `SOURCE_ITEM_INVALID`, `QUERY_FAILED`, `SHAPE_UNUSUAL` | other identified | further v1 refusals (none occur in the real DB today) |
| `UNCLASSIFIED`, `UNEXPECTED_ERROR` | unclassified | tool gap or crash; must be 0 |

## 3. Real-DB result (public compiled 3.3.5a Questie, this branch)

M0 first: 232 checks passed, 28 level corrections, 82,431 compiled fields with 0 mismatches.

| Measure | Quests |
|---|---|
| Total | 9,159 |
| v1 representable | 8,401 (91.7%) |
| v1 unsupported (unique quests) | 758 (8.3%) |
| Unclassified | 0 |

Measured after adding `KILLCREDIT_FIRST_REORDER` (previous run without the order check: 8,407 / 752).

Per reason (a quest with several reasons counts once under each):

| Reason | Quests | Occurrences |
|---|---|---|
| `EXTRA_CREATURE_REF` | 359 | 466 |
| `EXTRA_OBJECT_REF` | 243 | 335 |
| `REPUTATION_OBJECTIVE` | 181 | 181 |
| `KILLCREDIT_FIRST_REORDER` | 16 | 16 |
| `DUPLICATE_CREATURE` | 7 | 9 |
| `DUPLICATE_OBJECT` | 1 | 1 |
| Other identified | 0 | 0 |

Overlap combinations (each unsupported quest exactly once):

| Combination | Quests |
|---|---|
| `EXTRA_CREATURE_REF` only | 317 |
| `EXTRA_OBJECT_REF` only | 205 |
| `REPUTATION_OBJECTIVE` only | 175 |
| `EXTRA_CREATURE_REF` + `EXTRA_OBJECT_REF` | 31 |
| `EXTRA_CREATURE_REF` + `KILLCREDIT_FIRST_REORDER` | 7 |
| `DUPLICATE_CREATURE` only | 6 |
| `KILLCREDIT_FIRST_REORDER` only | 6 |
| `EXTRA_OBJECT_REF` + `REPUTATION_OBJECTIVE` | 4 |
| `EXTRA_OBJECT_REF` + `KILLCREDIT_FIRST_REORDER` | 3 |
| `EXTRA_CREATURE_REF` + `REPUTATION_OBJECTIVE` | 2 |
| `DUPLICATE_CREATURE` + `EXTRA_CREATURE_REF` | 1 |
| `DUPLICATE_OBJECT` + `EXTRA_CREATURE_REF` | 1 |
| **Total** | **758** |

Reconciliation: 8,401 + 758 = 9,159; combinations sum to 758. The earlier "466 monster / 335 object" figures were occurrences; the quest counts are 359 and 243.

Note: the M0 log reports 9,158 `questData` records before compilation and the compiled pointer table holds 9,159 quests. Coverage uses the compiled table (what the exporter reads). Explaining the one-quest difference is an open review item.

## 4. How to run

```bash
mkdir -m 700 /tmp/nq-coverage
NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 \
NQ_COVERAGE_MANIFEST_OUT=/tmp/nq-coverage/manifest.lua \
NQ_COVERAGE_AGGREGATE_OUT=/tmp/nq-coverage/aggregate.txt \
lua5.1 cli/validate-335.lua
```

Needs a clean checkout, Linux, GNU realpath, lua5.1, git and sha256sum. About 20 seconds.

## 5. Tests

| Test | Checks | What |
|---|---|---|
| `tests/test_nquestie_m2_coverage.lua` | 71 | every category, all reasons kept, parity with the exporter's messages and codes, crash and missing-code handling, reconciliation, labelling, manifest has no records, no mutation |
| `tests/test_nquestie_m2_coverage_integration.sh` | 20 | refusals before M0 (non-private manifest, with export, skip-compile, no level count, same paths), real run after 232 checks, 9,159 total, 0 unclassified, 0600 files, manifest parses and reconciles, export refuses 11142 with both reasons and writes nothing |

## 6. Objective order: `KILLCREDIT_FIRST_REORDER`

**How Questie orders objectives.** `QuestieDB.GetQuest` builds `ObjectiveData` in a fixed kind order: creatures, objects, items, reputation, killCredit, spells, then the `triggerEnd` event. `QuestieQuest:PopulateQuestLogInfo` maps quest-log objective N to `ObjectiveData[N]` ("trusts the database order"). For ordinary quests, v1's per-kind lists plus that fixed order reproduce every position, so nothing is lost.

**The exception.** For quests in `QuestieCorrections.killCreditObjectiveFirst`, each killCredit entry is inserted at position 1 (`tinsert(QO.ObjectiveData, 1, ...)`). The killCredit line moves before the other objectives, and several killCredit entries end up reversed. v1 cannot express this, so the quest-log meaning would change silently.

**The set at runtime (3.3.5a load order):** 16 quests: 10503 (from `tbcQuestFixes.lua`) and 11652, 12100, 12546, 12561, 12762, 12919, 13086, 13373, 13376, 13380, 13382, 13404, 13406, 24498, 24507 (from `wotlkQuestFixes.lua`). All 16 exist in the compiled DB and all have killCredit plus at least one creature or item objective, so all 16 change order. 11652 also has two killCredit entries, which are reversed. Earlier design notes named only 10503; that was incomplete.

| Effect | Quests |
|---|---|
| Newly unsupported (order is the only reason) | 6: 10503, 12100, 12546, 12561, 13382, 13404 |
| Already unsupported for extraObjectives (reason added) | 10: 11652, 12762, 12919, 13086, 13373, 13376, 13380, 13406, 24498, 24507 |

**Why this code.** `KILLCREDIT_FIRST_REORDER` names the exact mechanism. A generic `ORDER_CROSS_TYPE` code was considered but rejected: a full scan found no other cross-type order loss. The kind order is fixed, the event is always last, there are no spell objectives, and no extraObjectives item references exist. A generic name would suggest a wider class than exists. A quest that is flagged but has only one killCredit entry and no other objective keeps the same position, so it is not refused (tested).

**Fail closed.** The harness passes the runtime set to the exporter and the coverage tool. If the set is missing or empty, export and coverage refuse to run.

**Tests.** `tests/test_nquestie_m2_order.lua` (23 checks: positive and negative shapes, all reasons kept, parity, nothing returned on refusal). The real-DB coverage integration pins 16 order quests and checks that exporting 10503 is refused with nothing written.

### Update procedure for pinned counts

The coverage integration test pins 9,159 total, 8,401 representable, 758 unsupported and 16 order quests. If an upstream Questie update or a new N-Questie correction changes these numbers:

1. Run the coverage command (§4) and review the new aggregate and the reasons for the changed quests in the private manifest.
2. Confirm that every change is explained (new or removed quests, changed objectives). Never edit data to match the pinned numbers.
3. Update the pins in `tests/test_nquestie_m2_coverage_integration.sh` and the tables above in the same commit, with the explanation in the development log.
