# Stage A2: opt-in nq-m2-effective v2 export, results

Status: implemented on `dev/stage-a2-v2-exporter` (draft PR against
`dev/stage-a1-v2-roundtrip`). Approved as decision t55u. Not merged or
released.
* Harness 1.3.0 on this branch only; A1 stays 1.2.0.
* v1 (nq-m2-input v1, nq-m2-effective v1) is frozen. Its sources are
  byte-identical to 780e89cbe (sha256 pins), and its output is unchanged.
* No M2.3 engine, markers or automatic corrections. Public compiled 3.3.5a
  data only.

## Use

    NQ_EXPORT_SCHEMA_VERSION=2 NQ_EXPORT_V2_OUT=/abs/private/dir/v2.lua \
    NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 lua5.1 cli/validate-335.lua

The output directory must already exist, be owned by you, be mode 0700 (no
group or other access) and lie outside the git checkout. The file must not
exist yet.

Read-only check of a written file against this checkout:

    NQ_V2_VERIFY_IN=/abs/private/dir/v2.lua NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 lua5.1 cli/validate-335.lua

## Mode contract (refused before compile and M0, nothing written)

* Either variable alone, or a schema version other than 2.
* Any other mode's variable: `NQ_EXPORT_EFFECTIVE_OUT`, `NQ_EXPORT_QUESTS`,
  `NQ_EXPORT_SELECTION`, `NQ_EXPORT_FORCE`, `NQ_COVERAGE_MANIFEST_OUT`,
  `NQ_COVERAGE_AGGREGATE_OUT`, `NQ_V2_ROUNDTRIP`, `NQ_V2_VERIFY_IN`,
  `NQ_VALIDATE_FIXTURE`.
* `NQ_VALIDATE_SKIP_COMPILE=1`, or a missing `NQ_VALIDATE_EXPECT_LEVEL_COUNT`.
* A path that is relative, contains `.` or `..`, has a non-plain file name, or
  whose directory is missing, not owned by you or accessible to group/other.
* A directory path containing a symlink (directory or parent).
* A directory inside the checkout (`private/` included).
* An existing destination, or a symlink there (dangling or not).

After M0, a dirty checkout makes provenance collection fail: no file is
written. There is no development flag.

## Pipeline (`tools/validation/ExportV2.lua`, `Export`)

1. Build all 9,159 records with the A1 builder (fails closed).
2. Build the document and validate it with `EffectiveSchemaV2.Validate`.
3. Serialise deterministically (`EffectiveExportV2.Serialise`):
   * a fixed key order per table kind;
   * integers only;
   * printable ASCII strings;
   * `\n` endings and one quest per line;
   * an unknown field fails closed.
4. Parse the text back with the safe literal parser, validate it, and
   require it to be canonically equal to the document.
5. Round trip on the parsed records: rebuild, recompute positions and
   compare with a fresh read of the compiled data. This also checks v1
   equivalence for the 8,401 and M1 parity. Any difference fails.
6. The compiled data fingerprint must be unchanged (`preWrite`).
7. Write through `SafeWrite.WriteFile`, never with `force`. That means a
   private temp file, read back, then a no-clobber hard link; the result is
   0600 in a 0700 directory.
8. Re-read the file, require byte equality, then parse and validate it again.

A failure in steps 1 to 7 leaves no output file, and SafeWrite removes its
temp file. A failure in step 8 means the installed file changed after
SafeWrite's own check. It is reported and left in place for inspection,
not deleted, because it is no longer known to be ours.

No fsync is performed: there is no power-loss durability claim. The
guarantees are no-clobber install and atomic visibility of a complete file.

## Modules and functions

| File | Change |
|---|---|
| `tools/validation/EffectiveSchemaV2.lua` | new: production v2 validator, promoted from the draft (no draft guard) |
| `tools/validation/draft/EffectiveSchemaV2Draft.lua` | now a guarded wrapper around the production module (design tests unchanged) |
| `tools/validation/EffectiveExportV2.lua` | adds `BuildDocument`, `Serialise` and the fixed orders (`PROVENANCE_ORDER`, `QUEST_ORDER`, `OBJECTIVE_ORDER`, `EXTRA_ORDER`, `REF_ORDER`, `DOC_ORDER`) |
| `tools/validation/ExportV2.lua` | new: `ParseAndValidate`, `CheckParsed`, `Export` |
| `tools/validation/RoundTripV2.lua` | uses the production validator; `FormatAggregate` takes an optional title |
| `cli/validate-335.lua` | `HARNESS_VERSION` 1.3.0; `v2ExportOptions`, `runExportV2`, `v2VerifyOptions`, `runVerifyV2`; v1 `runExport`, `exportOptions` and `coverageOptions` unchanged |

Deviations from the proposal's file list:
* The mode-guard cases live in `tests/test_nquestie_m2_v2_export_integration.sh`
  instead of a separate `test_nquestie_m2_v2_mode_guards.sh`.
* The read-only verify mode was added so that F1-F5 run on the written file
  itself.
* The pipeline is a module of its own, so the builder stays free of I/O.

## F1-F8 on the public database (measured 2026-10-15)

| ID | Result |
|---|---|
| F1 | 9,159 records; the sorted ID list sha256 equals the pin `e7dfb2a9...b6a3`; IDs sorted; `questCount` 9,159 |
| F2 | 8,401 SUPPORTED / 758 UNSUPPORTED_BY_RULES. Per-quest status and reasons equal the coverage manifest of the same commit (9,159 compared, 0 differing). Reason quest counts: EXTRA_CREATURE_REF 359, EXTRA_OBJECT_REF 243, REPUTATION_OBJECTIVE 181, KILLCREDIT_FIRST_REORDER 16, DUPLICATE_CREATURE 7, DUPLICATE_OBJECT 1 |
| F3 | Verify mode on the written file: 9,159 re-read, rebuilt and compared, 0 quests differing, 0 differences; positions checked for all 9,159 |
| F4 | No loss for the 758: 801 refs (monster 466, object 335), 181 reputation pairs (22 zero), 16 kill-credit-first quests, 10 duplicate occurrences; 730 extra entries, 78 spawn-only, 696 objectiveIndex 0, 5 one past the objectives |
| F5 | v1 equivalence: 8,401 compared, 0 differing |
| F6 | Two exports to different temp directories are equal after `Canonical(doc, {"exportedAt"})`, and byte-identical apart from the exportedAt value. Only `provenance.exportedAt` may differ. The real UTC timestamp is kept |
| F7 | All 232 M0 checks pass with 82,431 fields and 0 mismatches. M1 and v1 suites pass. The v1 sources are byte-identical to the base (sha256 pins). The v1 golden test passes. Default CLI output is byte-identical to the A1 head (golden, timings normalised). A v1 export of all 8,401 SUPPORTED quests on the A1 head and on this branch gives 8,401 canonically equal records; provenance differs only in exportedAt, sourceCommit, sourceTree and the intended harnessVersion 1.2.0 to 1.3.0 |
| F8 | Fail closed. Full DB: an unwritable directory fails with no file; a dirty checkout fails after M0 with no file; `private/` and all the mode-guard cases are refused before M0. Synthetic, through the real pipeline: malformed records, false SUPPORTED, a dropped quest, display text, a missing kill-credit set, a build error, a changed text, preWrite failure, SafeWrite failures at three points, existing file, symlinks, bad directory modes, read-only directory. In every case no file and no temp file is left |

Spec section 11 now states that a SUPPORTED quest may have
`killCreditFirst = true` (one KillCredit and nothing reordered); there are 0
such quests at baseline.

## Determinism and provenance

The provenance fields come from `ExportProvenance.Collect` (reused
unchanged), in a fixed order:
* harness, harnessVersion, dataKind, flavour, tocInterface;
* sourceCommit, sourceTree, sourceDirty;
* nQuestieDataRevision, correctionCount, correctionModules,
  correctionFingerprint;
* m0Checks, questCount, exportedAt.

Only `exportedAt` is run-specific within one commit. Across commits,
sourceCommit and sourceTree also differ. These are the fields
`Canonical` may exclude (`RUN_FIELDS`).

## Performance

These figures come from `/usr/bin/time -v` on the box:
* Whole run (compile, M0, export, check, write, re-read): about 19 s wall.
* Export part: about 3.9 s CPU, with 189 MiB of Lua heap growth.
* Peak RSS: 623 MiB, about the same as a default run.
* Output: 2,366,003 bytes, under the reader limit of 16 MiB.

## Tests

| Test | Checks |
|---|---|
| `tests/test_nquestie_m2_v2_export.lua` | 111: serialiser order, determinism, refusals, parse back; pipeline success; refusals with no file left |
| `tests/test_nquestie_m2_v2_export_integration.sh` | 104: mode guards, two full exports, F1-F8, verify mode, tamper detection, dirty clone, `private/`, unwritable directory, default golden |
| `tests/check_m2_v2_export_file.lua` | read-only helper for the integration test |
| `tests/test_nquestie_m2_v2_mutation.sh` | 60 mutants (21 new for the serialiser, pipeline and schema gates), all killed. Two equivalent mutants are documented in the script |
| `tests/test_nquestie_m2_v1_frozen.lua` | adds sha256 pins of six v1-era sources |
| `tests/test_nquestie_harness_version.lua` | pins 1.3.0 and checks that three provenance sites use it |

All of these run from `tests/run_m2_suite.sh` and from busted
(`tools/validation/M2V2RoundTrip.test.lua`). No workflow file is changed.

## Limitations and risks

* SafeWrite's remaining path races are documented in
  `docs/NQ-VALIDATION-M2.2-SAFE-WRITER.md`. There is no fsync, so no
  power-loss durability.
* A file changed after install is left in place for inspection rather than
  deleted.
* The killCreditFirst set and the compiled data come from the headless
  harness load. The game client is not involved. In-game verification of
  the 5 one-past objectiveIndex quests is still pending.
* The output path is printed on success, as v1 does. The file holds public
  data only, but is kept private by rule.
* Busted runs the full-DB tests only where lua5.1 and bit32 are installed.
  Elsewhere they are reported as pending, not as passed.
