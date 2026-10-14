# N-Questie M2.3 report-only batch comparison: detailed design

Status: **design only**. No M2.3 engine exists and none is authorised by this document. The draft report validator (`tools/validation/draft/M23ReportDraft.lua`) checks the proposed output formats on synthetic fixtures only; it never reads server data, never runs M1 and never writes files. Stacked on the Stage 2 exporter specification (PR #41), which is stacked on #39.

Date: 14 October 2026.

## 1. Goal

For one explicit selection of quests, compare the private server record (M2.1 input) with the effective Questie record (M2.2 export) using the M1 rules unchanged, and produce:

- a **private report**, one row per selected quest;
- an **aggregate**, counts only, reviewed separately before it is shared anywhere.

M2.3 never corrects anything, never edits the database and never confirms what the evidence cannot support.

## 2. Inputs, validated independently

| # | Input | Validator | Rejects batch when |
|---|---|---|---|
| 1 | Server file `nq-m2-input` v1 | frozen `InputSchema.Validate` (full: every provenance field and record) | any error; duplicate quest ID; git commit in provenance |
| 2 | Effective export | dispatch on `schemaVersion`: 1 → frozen v1 validator, 2 → v2 validator, other → reject | any error; `sourceDirty = true` |
| 3 | Coverage manifest | manifest schema + `Coverage.Aggregate` reconciliation | any error; counts do not reconcile |

The server `sourceFingerprint` is a sha256 of the server data. It is independent of git and is never compared with a Questie commit or tree.

## 3. Pairing and membership (whole batch)

**Pairing** between the effective export and the manifest: identical `sourceCommit`, `sourceTree`, `nQuestieDataRevision`, `correctionCount`, `correctionFingerprint`, `correctionModules` (order-sensitive), `tocInterface`, `flavour`, `harness`, `harnessVersion`; both `sourceDirty = false`.

**Membership consistency:**

- v1 export: the exported quest set equals the manifest REPRESENTABLE set restricted to the selection; no exported quest is UNSUPPORTED in the manifest.
- v2 export: every manifest quest is exported; each record's `m1Status`/`m1Reasons` equals the manifest classification.
- Quest counts agree.

Any failure: whole-batch rejection, defined precisely as: exit non-zero, write **no** report, **no** aggregate, **no** temporary or partial file, and print only the failed check names (no quest data) to stderr.

## 4. Per-quest export status (axis 1, exactly one)

| Status | When |
|---|---|
| `ABSENT_FROM_EFFECTIVE_DB` | selected server quest ID not in the compiled database (not in the manifest at all) |
| `UNSUPPORTED_BY_SCHEMA_VERSION` | in the manifest as UNSUPPORTED and the export version cannot hold it (v1); row carries the manifest reason codes |
| `EXPORTED` | record present in the export |
| `REJECTED_MALFORMED_INPUT` | the quest's own data cannot be compared (reserved for per-quest problems that the batch validators deliberately allow, such as a server record that is valid but refers to a quest the export marks malformed); never used to hide a batch error |

Every selected ID gets exactly one row. Nothing disappears silently.

## 5. Comparison outcome (axis 2, only for EXPORTED, exactly one)

| Outcome | When |
|---|---|
| `M1_UNSUPPORTED_BY_RULES` | v2 record has `m1Status = UNSUPPORTED_BY_RULES`; M1 is not run for confirmation |
| `EXPECTED_REPRESENTATION_DIFF` | M1 findings are fully explained by a documented representation difference (for example 1203 effective vs server) |
| `NEEDS_MANUAL_REVIEW` | any evidence item unknown (KillCredit completeness, conditions, scripts, IP, objective data), any M1 NEEDS_MANUAL_REVIEW class, or kill-credit-first order cannot be matched to server order |
| `CONFIRMED_MISMATCH` | an M1 finding remains, M1 supports the record and every evidence item is complete |
| `CONFIRMED_MATCH` | section 6 |

## 6. CONFIRMED_MATCH mapping (M1 has no such class)

M1 reports findings; it has no "match" class. M2.3 derives `CONFIRMED_MATCH` only when **all** hold:

1. the record is M1-supported (v1, or v2 `SUPPORTED`);
2. M1 returned **zero** findings of any class, including NEEDS_MANUAL_REVIEW sets;
3. every evidence item (`killCredit`, `conditions`, `scripts`, `ip`, `objectiveData`) is `complete`;
4. no representation difference applies.

This does not change M1. Unknown IP, conditions, KillCredit or scripts never confirm. Implemented as `ConfirmedMatchAllowed` in the draft validator and tested.

## 7. Private report format (`nq-m2-3-report` v1)

```
{ schema = "nq-m2-3-report", schemaVersion = 1, private = true,
  selected = { <quest IDs> },
  rows = { { questId, exportStatus, reasons?, m1Supported?, m1Findings?, representationDiff?,
             evidence? = { killCredit, conditions, scripts, ip, objectiveData }, outcome? } } }
```

Written only through SafeWrite to a private path, after the whole batch has passed. Never committed, uploaded or attached anywhere.

## 8. Aggregate format (`nq-m2-3-aggregate` v1)

Fields allowed: `schema`, `schemaVersion`, `selectedCount`, `exportStatus` (counts by status), `outcome` (counts by outcome), `reasons` (counts by reason code). No quest IDs, names, labels or fingerprints; keys are names only; status counts sum to `selectedCount`; outcome counts sum to EXPORTED; must reconcile with the private report. Sharing an aggregate needs a separate human review each time.

## 9. Synthetic fixtures and negative matrix

| File | Content |
|---|---|
| `tests/fixtures/m2_3_draft/report_synthetic.lua` | 9 rows reaching all 4 statuses and all 5 outcomes; values invented |
| `tests/fixtures/m2_3_draft/batch_matrix.lua` | 15 whole-batch rejection cases (server, effective, pairing, membership, manifest, input-changed, output path) and 11 per-quest cases (1203, absent, duplicates 11142/25199, kill-credit-first 10503, malformed, unknown evidence, complete match/mismatch, kill-credit order) |
| `tests/test_nquestie_m2_3_report_draft.lua` | 104 checks: report rules, CONFIRMED rules, aggregate privacy and reconciliation, matrix completeness |

## 10. Acceptance for a future engine

All B-cases produce no files; all Q-cases produce exactly the stated status/outcome; output passes `ValidateReport` and `ValidateAggregate`; M1 results equal direct M1 calls; inputs unchanged after the run; 1203 never CONFIRMED.

## 11. Limitations

- Evidence completeness depends on server-side data (KillCredit tables, conditions, SmartAI) that M2.1 does not yet carry; until it does, real runs will mostly produce NEEDS_MANUAL_REVIEW. That is the intended conservative behaviour.
- The draft validator checks format and rules, not whether the engine computed them correctly.
