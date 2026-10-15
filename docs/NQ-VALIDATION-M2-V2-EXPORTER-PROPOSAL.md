# Proposal A: production v2 structural exporter (opt-in mode in validate-335)

Status: approved and implemented on draft branches (Stage A1 `dev/stage-a1-v2-roundtrip`, Stage A2 `dev/stage-a2-v2-exporter`). Not merged or released. Approving this document is not approval to merge or release. Stage A2 deviations from the file list below are recorded in `docs/NQ-VALIDATION-M2-STAGE-A2-RESULTS.md`. Spec: `docs/NQ-VALIDATION-M2-V2-EXPORTER-SPEC.md`. Date: 14 October 2026.

## 1. Decision and trade-off

Maintainer decision: the v2 exporter is a **separate explicit opt-in mode** of `cli/validate-335.lua`.

| Option | For | Against |
|---|---|---|
| Mode in validate-335 (chosen) | reuses the one compile + M0 path, so the v2 file is always produced from a database that just passed all 232 checks; one provenance collector; one SafeWrite path | a bug in mode selection could affect the v1 path; mitigated by the guards below |
| Separate CLI | physically separate entry point | would duplicate or re-import compile and M0, risking a v2 file from an unchecked compile; two provenance paths to keep identical |

No technical reason was found that makes a separate CLI safer, provided the mode guards below hold.

## 2. Mode contract

- Triggered only when **both** `NQ_EXPORT_SCHEMA_VERSION=2` and `NQ_EXPORT_V2_OUT=<absolute private path>` are set. Either alone is an error, nothing written. No default, no CLI flag shortcut, no config file.
- v1 variables (`NQ_EXPORT_EFFECTIVE_OUT`, `NQ_EXPORT_QUESTS`, `NQ_EXPORT_SELECTION`) together with v2 variables: error (one export per run). `NQ_EXPORT_FORCE` (v1 replace-existing) is refused in v2 mode: v2 never replaces a file.
- `NQ_VALIDATE_SKIP_COMPILE=1` with v2: error, as for v1.
- v2 always exports **all 9,159** compiled quests (no selection); a selection variable with v2 is an error. Subsets are made by readers, which keeps the manifest pairing simple.
- Runs only after compile and the full M0 run pass, exactly like v1.
- Same SafeWrite rules, same provenance collector (adds `schemaVersion = 2`, `displayScope`), self-validation before and after writing.
- v1 code path untouched: v1 writer functions are not edited; a test diffs them against the base.

## 3. Files

| File | Change |
|---|---|
| `tools/validation/EffectiveSchemaV2.lua` | promoted from `draft/EffectiveSchemaV2Draft.lua`; draft guard removed; draft file kept for history or deleted in the same PR |
| `tools/validation/EffectiveExportV2.lua` | new: v2 record builder (`BuildRecord(query, id, ctx)`), ordering per spec §4 |
| `cli/validate-335.lua` | A1: read-only round-trip mode; A2: export mode selection and call, HARNESS_VERSION 1.2.0 → 1.3.0 |
| `tests/test_nquestie_m2_v2_builder.lua` | synthetic builder tests |
| `tests/test_nquestie_m2_v2_export_integration.sh` | full-DB tests F1-F8 |
| `tests/run_m2_suite.sh`, `tools/validation/M22Libraries.test.lua` | wiring (no workflow file edits) |

## 4. First implementation PR, split into two stages

Each stage is its own draft PR with its own approval. Stage A2 starts only after A1's measured numbers are reviewed.

### Stage A1: record builder and measured in-memory round trip (no file writes)

| Item | Detail |
|---|---|
| Files | new `tools/validation/EffectiveExportV2.lua`; new `tools/validation/RoundTripV2.lua`; `tools/validation/EffectiveSchemaV2.lua` promoted from the draft (draft file deleted in the same PR, history in git); `cli/validate-335.lua`: one new read-only mode `NQ_V2_ROUNDTRIP=1` that prints counts only; tests below; suite and busted wiring |
| Functions | `EffectiveExportV2.BuildRecord(query, id, ctx) -> record \| nil, errs` (spec §3-5, uses the same `exportContext()` kill-credit-first set); `EffectiveExportV2.BuildAll(query, ids, ctx) -> records \| nil, errs`; `RoundTripV2.Rebuild(record) -> compiledShape`; `RoundTripV2.RecomputePositions(compiledShape, killCreditFirst) -> positions`; `RoundTripV2.Compare(rebuilt, raw) -> diffs`; `RoundTripV2.Aggregate(results) -> counts` |
| Output | stdout only: quests compared, quests differing, differences per field, per-reason no-loss totals (801 refs by type, 181 reputation pairs incl. 22 zero, 16 kill-credit-first, 10 duplicate occurrences), 8,401 v1-equivalence count. No quest IDs in the output except in a fixed failure line naming the first differing field kind. No file is opened for writing; a test asserts `io.open` is never called with a write mode during the mode |
| Harness | HARNESS_VERSION unchanged (1.2.0): no exported artefact changes |
| Tests | synthetic builder tests on both v2 fixtures' compiled-shaped inputs (all kinds, repeats, kill-credit reversed, rep 0, objectiveIndex 0 and max, spawn-only extras, required source items); negative builder tests (unclassified shape, missing kill-credit set, query failure); full-DB integration test running the mode |
| F-mapping | F1 (9,159 IDs, sha256 pin), F2 (8,401 / 758, per-reason counts equal the coverage manifest), F3 (round trip 0 differences), F4 (no-loss totals), F5 (v1 equivalence 0 differences over 8,401), F7 (M0 232, M1, v1 suites unchanged; v1 writer diff empty) |
| Acceptance | all of the above on CI with six green workflows on the exact head; measured counts recorded in the handover; any difference stops the stage (no adjusting the comparison) |
| Approval gate | maintainer approves Stage A1; review of the measured counts before A2 |

### Stage A2: opt-in export mode, SafeWrite, harness 1.3.0

| Item | Detail |
|---|---|
| Files | `cli/validate-335.lua` (v2 mode per §2, after compile + M0), `tools/validation/EffectiveExportV2.lua` (serialiser in fixed key order), `tests/test_nquestie_m2_v2_export_integration.sh`, `tests/test_nquestie_m2_v2_mode_guards.sh`, harness version pin test updated |
| Functions | `EffectiveExportV2.Serialise(doc) -> string` (deterministic, integers only); `runExportV2(opts, QuestieDB, Q, levelCount)` in the CLI, mirroring `runExport`; reuse of `ExportProvenance.Collect`, `SafeWrite.WriteFile` (no `force`), self-validation before writing and after re-reading |
| Harness | HARNESS_VERSION 1.2.0 → 1.3.0; pinned in the static test, export provenance and manifest provenance |
| Tests | mode guards (each wrong variable combination: nothing written, non-zero exit, including `NQ_EXPORT_FORCE`, `NQ_VALIDATE_SKIP_COMPILE`, selection with v2, v1 + v2 together); full export of 9,159; determinism (two runs equal after `Canonical(doc, {"exportedAt"})`); fail-closed injections (malformed record, missing kill-credit set, existing output, unsafe path) |
| F-mapping | F1-F5 re-run on the written file; F6 determinism; F7 v1 export equivalence before/after by `Canonical`; F8 fail-closed |
| Acceptance | all F-tests on the written file; v1 output equivalent and v1 writer diff empty; six green workflows on the exact head |
| Approval gate | separate maintainer approval of A2 after A1 is merged or accepted |

## 5. Will not be exported

Display text, spawn or marker coordinates, trigger-end contents, live availability (phase, conditions, IP), server data of any kind.

## 6. Stopped / no-go list

- No M2.3 comparison, no corrections, no change to v1 schema or v1 output, no workflow file edits, no private data in tests or CI.
- Stop and report if F3, F4 or F5 shows any difference; do not adjust the round trip to pass.

## 7. Approval gates

1. Maintainer approves this proposal.
2. Stage A1 draft PR, reviewed on its exact head with six green workflows; measured counts reviewed.
3. Separate approval for Stage A2; its draft PR reviewed the same way.
4. Each merge is a further decision.
