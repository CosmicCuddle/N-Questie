# Proposal A: production v2 structural exporter (opt-in mode in validate-335)

Status: **proposal for maintainer approval**. Not implemented. Approving this document is not approval to merge or release. Spec: `docs/NQ-VALIDATION-M2-V2-EXPORTER-SPEC.md`. Date: 14 October 2026.

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
| `cli/validate-335.lua` | mode selection and call; HARNESS_VERSION 1.2.0 → 1.3.0 |
| `tests/test_nquestie_m2_v2_builder.lua` | synthetic builder tests |
| `tests/test_nquestie_m2_v2_export_integration.sh` | full-DB tests F1-F8 |
| `tests/run_m2_suite.sh`, `tools/validation/M22Libraries.test.lua` | wiring (no workflow file edits) |

## 4. Steps

1. Builder only, plus the **measured round trip** (spec §10) that prints counts only. Review the numbers.
2. Promote the validator; add the mode guards and SafeWrite path.
3. Full-DB integration tests F1-F8; determinism via `Canonical`.
4. Docs, handover, harness bump.

## 5. Tests and acceptance

| Test | Pass |
|---|---|
| A1-A5 synthetic | as today, without the draft guard |
| Builder unit tests | every shape in both v2 fixtures rebuilt from compiled-shaped input |
| Mode guards | each wrong variable combination writes nothing and exits non-zero |
| F1 quest set | 9,159; ID-list sha256 pin |
| F2 coverage | 8,401 SUPPORTED / 758 UNSUPPORTED_BY_RULES; per-reason counts equal the manifest |
| F3 round trip | 0 differences over 9,159 |
| F4 no-loss for the 758 | 801 refs, 181 reputation pairs (22 zero), 16 kill-credit-first, 10 duplicate occurrences |
| F5 v1 equivalence | 0 differences over 8,401 (spec §11) |
| F6/F7 | reproducible by `Canonical`; v1 writer diff empty; M0 232, M1 and v1 suites pass |
| F8 fail-closed | injected failures write nothing |
| CI | all six workflows green on the exact head SHA |

## 6. Will not be exported

Display text, spawn or marker coordinates, trigger-end contents, live availability (phase, conditions, IP), server data of any kind.

## 7. Stopped / no-go list

- No M2.3 comparison, no corrections, no change to v1 schema or v1 output, no workflow file edits, no private data in tests or CI.
- Stop and report if F3, F4 or F5 shows any difference; do not adjust the round trip to pass.

## 8. Approval gate

Separate maintainer approval of this proposal; then one draft PR, reviewed on its exact head with six green workflows. Merge is a further decision.
