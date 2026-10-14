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
| 1 | Server file `nq-m2-input` v1 | frozen `InputSchema.Validate` (full: every provenance field and record), via `CheckServerDocument` | any error; duplicate quest ID; git commit in provenance |
| 2 | Effective export | dispatch on `schemaVersion`: 1 → frozen v1 validator, 2 → v2 validator, other → reject | any error; `sourceDirty = true` |
| 3 | Coverage manifest | manifest schema + `Coverage.Aggregate` reconciliation | any error; counts do not reconcile |

The server `sourceFingerprint` is a sha256 of the server data. It is independent of git and is never compared with a Questie commit or tree.

## 3. Pairing, membership and selection (whole batch)

**Pairing** between the effective export and the manifest: identical `sourceCommit`, `sourceTree`, `nQuestieDataRevision`, `correctionCount`, `correctionFingerprint`, `correctionModules` (order-sensitive), `tocInterface`, `flavour`, `harness`, `harnessVersion`; both `sourceDirty = false`. Draft: `CheckPairing` (tested).

**Manifest completeness.** The coverage manifest lists every compiled quest (9,159 at baseline). It proves full-DB membership only when its entry count equals the pinned count and the ID-list sha256 equals the pin; otherwise the batch is rejected (`REJECTED_MANIFEST_INCOMPLETE`), because absence could not be proven.

**Selection protocol (exact ID sets).**

1. The server selection must be a dense list of unique positive integers (`REJECTED_DUPLICATE_ID` otherwise).
2. **Preflight split** (`PreflightSplit`, before any export) divides the server selection by the full manifest into `v1Request` (REPRESENTABLE), `unsupported` (UNSUPPORTED) and `absent` (not in the manifest).
3. **v1 export:** the frozen all-or-nothing v1 exporter is asked only for `v1Request`. v1 is not changed and still refuses any request containing an unsupported ID. The effective export's ID set must equal `v1Request` exactly. A REPRESENTABLE quest missing from the export, or an extra exported quest, is `REJECTED_SELECTION_MISMATCH`, never ABSENT. An exported quest marked UNSUPPORTED, or not in the manifest, is `REJECTED_MEMBERSHIP`.
4. **v2 export:** always all manifest quests (Proposal A); anything less is `REJECTED_SELECTION_MISMATCH`.
5. Rows: `absent` → `ABSENT_FROM_EFFECTIVE_DB`; `unsupported` with v1 → `UNSUPPORTED_BY_SCHEMA_VERSION` with the manifest reason codes; everything else → `EXPORTED` (with v2, unsupported quests are EXPORTED with `m1Supported = false`).

Draft: `PlanSelection` implements exactly these rules for synthetic ID sets (no files, no M1) so the matrix in §9 is executed, not described.

**Whole-batch rejection** means: exit non-zero; write **no** file of any kind (no report, no aggregate, no temporary or partial file, **no rejection file**); print only fixed lines `nq-m2-3: <CODE>` to stderr, one per failed gate, with CODE from the closed list: `REJECTED_MALFORMED_INPUT`, `REJECTED_DUPLICATE_ID`, `REJECTED_PAIRING`, `REJECTED_MEMBERSHIP`, `REJECTED_SELECTION_MISMATCH`, `REJECTED_MANIFEST_INCOMPLETE`, `REJECTED_V1_SELECTION_EMPTY_AFTER_PREFLIGHT`, `REJECTED_INPUT_CHANGED`, `REJECTED_UNSAFE_OUTPUT`. No paths, quest IDs, records, labels or fingerprints appear. Draft `CheckStderr` enforces this (exact lines, no digits outside the code set, no `/`, no 8-character hex run).

**Unsupported-only or absent-only v1 selection.** If the preflight `v1Request` is empty, a v1 batch is impossible: frozen v1 cannot write zero records (`questCount > 0`). The batch is rejected with `REJECTED_V1_SELECTION_EMPTY_AFTER_PREFLIGHT`; the same selection can be compared later against a full v2 export, which holds every quest. v1 is unchanged.

## 4. Per-quest export status (axis 1, exactly one, successful reports only)

| Status | When |
|---|---|
| `ABSENT_FROM_EFFECTIVE_DB` | not in the complete manifest (full-DB membership proven, §3) |
| `UNSUPPORTED_BY_SCHEMA_VERSION` | manifest UNSUPPORTED and the export is v1; row carries the manifest reason codes |
| `EXPORTED` | in the export |

`REJECTED_MALFORMED_INPUT` is **batch-level only** (one consistent model): it never appears as a report row, because a malformed input never produces a report. The draft report validator rejects any row that carries a rejection code. Every selected ID gets exactly one row; nothing disappears silently.

## 5. Comparison outcome (axis 2, only for EXPORTED, exactly one)

Each EXPORTED row lists `m1Classes`, the M1 class of every finding (`ObjectiveRules.CLASS`, unchanged): `CONFIRMED_MISMATCH`, `EXPECTED_REPRESENTATION_DIFF`, `NEEDS_MANUAL_REVIEW`, `UNSUPPORTED`. An empty list means M1 returned no findings.

| Outcome | Allowed only when |
|---|---|
| `M1_UNSUPPORTED_BY_RULES` | `m1Supported == false` exactly (v2 `m1Status = UNSUPPORTED_BY_RULES`); the row carries no M1 findings; no other outcome is allowed |
| `NEEDS_MANUAL_REVIEW` | always permitted when `m1Supported == true` (the conservative default whenever evidence is unknown) |
| `EXPECTED_REPRESENTATION_DIFF` | at least one finding and **all** findings are EXPECTED_REPRESENTATION_DIFF |
| `CONFIRMED_MISMATCH` | at least one CONFIRMED_MISMATCH-class finding, no NEEDS_MANUAL_REVIEW or UNSUPPORTED finding, and all evidence complete |
| `CONFIRMED_MATCH` | §6 |

Every EXPORTED row must carry `m1Supported` as an explicit boolean. Only `true` can receive NEEDS_MANUAL_REVIEW, EXPECTED_REPRESENTATION_DIFF or a CONFIRMED outcome; `nil`, `"unknown"`, strings, numbers or tables never confirm and make the row invalid.

## 6. CONFIRMED_MATCH mapping (M1 has no such class)

Only when **all** hold: `m1Supported == true` exactly; `m1Classes` is empty (zero findings of any class); every evidence item (`killCredit`, `conditions`, `scripts`, `ip`, `objectiveData`) is `complete`; no representation difference applies. A missing evidence table is not positive evidence. M1 is not changed. Draft: `OutcomeAllowed` (tested).

## 7. Private report format (`nq-m2-3-report` v1)

```
{ schema = "nq-m2-3-report", schemaVersion = 1, private = true,
  selected = { <unique positive quest IDs, dense list> },
  rows = { { questId, exportStatus, reasons? (UNSUPPORTED only, closed vocabulary),
             m1Supported?, m1Classes?, representationDiff?,
             evidence? = { killCredit, conditions, scripts, ip, objectiveData }, outcome? (EXPORTED only) } } }
```

Written only inside the bundle (§7a), after the whole batch has passed. Never committed, uploaded or attached anywhere.

## 7a. Atomic publication of report and aggregate

Two successive SafeWrite calls are not a transaction: a failure or crash after the first leaves one published file. Options compared:

| | (i) One bundle file | (ii) Staged 0700 directory renamed into place |
|---|---|---|
| Atomic unit | one file, installed by SafeWrite's temp + fsync + `link(2)` (fails if the name exists: true no-clobber) | one directory, installed by `rename(2)` |
| No-clobber | yes, by `link(2)` | **no**: Linux `rename(2)` silently replaces an *empty* target directory; `renameat2(RENAME_NOREPLACE)` is not portably reachable from Lua 5.1 or POSIX shell |
| Workarounds needed | none | mkdir-based lock plus re-check, which still has a window between check and rename |
| Crash after staging | stray temp file, no final file | stray staged directory, possibly a replaced empty target |
| Crash after install | complete final file plus a stray temp (removed on the next run by an explicit, name-pattern-limited cleanup) | complete directory |
| Sharing the aggregate | extracted from the bundle by a separate, reviewed command | copy one file out |

**Recommendation: (i) a single bundle file** `nq-m2-3-bundle` v1 = `{ schema, schemaVersion, private = true, report, aggregate }`, built only from a report and aggregate that both validated and reconcile (`BuildBundle`), and published once (`PublishBundle`). It reuses SafeWrite's existing, tested no-clobber install, needs no directory tricks, and gives "both or nothing" by construction. The aggregate leaves the bundle only through a separate reviewed extraction step, which matches the rule that every shared aggregate is reviewed.

Limitations stated plainly: a power loss between `link(2)` and removing the temp leaves a stray temp beside a complete bundle; durability of the directory entry depends on the filesystem; output is private (0600 file in a 0700 directory) and never overwritten.

Draft tests (simulated filesystem): failure at temp write, partial temp, fsync, link, crash before link → no published file; success → one complete file, temp removed; existing bundle → refused and untouched; crash after link → complete file plus stray temp; invalid report or non-reconciling aggregate → no bundle.

## 8. Aggregate format (`nq-m2-3-aggregate` v1)

Fields allowed: `schema`, `schemaVersion`, `reasonVocabVersion` (= 1), `selectedCount`, `exportStatus`, `outcome`, `reasons`. Every key in the three count tables must belong to a **closed vocabulary**: the three report statuses, the five outcomes, and reason vocabulary v1 (exactly the 17 `EffectiveExport.REASONS` codes; the test checks equality). Unknown, numeric or label-like keys are rejected, so no quest ID, name, label or fingerprint can leak. Counts must reconcile exactly with the private report: per status, per outcome, and per reason **occurrence** (a reason on two quests counts 2). The aggregate is never validated without its report. Sharing needs a separate human review each time.

## 9. Synthetic fixtures and executable matrix

| File | Content |
|---|---|
| `tests/fixtures/m2_3_draft/report_synthetic.lua` | 8 rows reaching all 3 statuses and all 5 outcomes, with M1 class lists; values invented |
| `tests/fixtures/m2_3_draft/batch_matrix.lua` | synthetic 6-quest complete manifest; 20 selection cases and 1 preflight case **executed** through `PlanSelection`/`PreflightSplit`; 3 engine-only design assertions (input changed, real-filesystem unsafe output, M1 equality) clearly marked and not counted as tests |
| `tests/test_nquestie_m2_3_report_draft.lua` | 165 checks: report rules, explicit `m1Supported` for every non-true value, CONFIRMED rules, selection uniqueness, batch-only malformed status, stderr code contract, atomic bundle with simulated failures and crashes, aggregate vocabulary and reconciliation, executed matrix, server-provenance and pairing gates |

Key executed cases: 1203 selected but export holds only 2001 → `REJECTED_SELECTION_MISMATCH` (not ABSENT); quest absent from a complete manifest → ABSENT; incomplete manifest → `REJECTED_MANIFEST_INCOMPLETE`; mixed 1203 + 11142 → split, 1203 EXPORTED, 11142 UNSUPPORTED with reasons; v1 export claiming 11142 → `REJECTED_MEMBERSHIP`.

## 10. Acceptance for a future engine

See `docs/NQ-VALIDATION-M2.3-ENGINE-PROPOSAL.md` (Proposal B).

## 11. Limitations

- Evidence completeness depends on server-side data (KillCredit tables, conditions, SmartAI) that M2.1 does not yet carry; until it does, real runs will mostly produce NEEDS_MANUAL_REVIEW. That is the intended conservative behaviour.
- The draft validator checks format and rules, not whether the engine computed them correctly.
