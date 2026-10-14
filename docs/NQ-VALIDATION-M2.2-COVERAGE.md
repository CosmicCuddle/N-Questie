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
| `DUPLICATE_ITEM`, `DUPLICATE_SPELL`, `DUPLICATE_KILLCREDIT_ID`, `DUPLICATE_SOURCE_ITEM`, `DUPLICATE_EXTRA_ITEM`, `EXTRA_OTHER_REF`, `LEVEL_INVALID`, `SOURCE_ITEM_INVALID`, `QUERY_FAILED`, `SHAPE_UNUSUAL` | other identified | further v1 refusals (none occur in the real DB today) |
| `UNCLASSIFIED`, `UNEXPECTED_ERROR` | unclassified | tool gap or crash; must be 0 |

## 3. Real-DB result (public compiled 3.3.5a Questie, this branch)

M0 first: 232 checks passed, 28 level corrections, 82,431 compiled fields with 0 mismatches.

| Measure | Quests |
|---|---|
| Total | 9,159 |
| v1 representable | 8,407 (91.8%) |
| v1 unsupported (unique quests) | 752 (8.2%) |
| Unclassified | 0 |

Per reason (a quest with several reasons counts once under each):

| Reason | Quests | Occurrences |
|---|---|---|
| `EXTRA_CREATURE_REF` | 359 | 466 |
| `EXTRA_OBJECT_REF` | 243 | 335 |
| `REPUTATION_OBJECTIVE` | 181 | 181 |
| `DUPLICATE_CREATURE` | 7 | 9 |
| `DUPLICATE_OBJECT` | 1 | 1 |
| Other identified | 0 | 0 |

Overlap combinations (each unsupported quest exactly once):

| Combination | Quests |
|---|---|
| `EXTRA_CREATURE_REF` only | 324 |
| `EXTRA_OBJECT_REF` only | 208 |
| `REPUTATION_OBJECTIVE` only | 175 |
| `EXTRA_CREATURE_REF` + `EXTRA_OBJECT_REF` | 31 |
| `DUPLICATE_CREATURE` only | 6 |
| `EXTRA_OBJECT_REF` + `REPUTATION_OBJECTIVE` | 4 |
| `EXTRA_CREATURE_REF` + `REPUTATION_OBJECTIVE` | 2 |
| `DUPLICATE_CREATURE` + `EXTRA_CREATURE_REF` | 1 |
| `DUPLICATE_OBJECT` + `EXTRA_CREATURE_REF` | 1 |
| **Total** | **752** |

Reconciliation: 8,407 + 752 = 9,159; combinations sum to 752. The earlier "466 monster / 335 object" figures were occurrences; the quest counts are 359 and 243.

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
