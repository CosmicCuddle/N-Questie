# Stage A1: in-memory v2 round trip, results

Status: implemented on `dev/stage-a1-v2-roundtrip` (draft PR against
`integration/r5-335`). Read-only. Harness stays 1.2.0. nq-m2-input v1 and
nq-m2-effective v1 are frozen and unchanged. No Stage A2, no M2.3 engine, no
marker export, no automatic corrections. Public compiled 3.3.5a data only.

## What it does

`NQ_V2_ROUNDTRIP=1 NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 lua5.1 cli/validate-335.lua`

1. Runs all M0 checks first (232). The mode starts only after M0 passes.
2. Builds a v2 record for every compiled quest from post-correction data
   (`EffectiveExportV2.BuildAll`), deep copied.
3. Validates each record against the v2 draft schema (`ValidateQuest`) and
   against its own `ExpectedM1` rule.
4. Rebuilds the runtime objective shape from the record
   (`RoundTripV2.Rebuild`), recomputes positions independently
   (`RecomputePositions`) and compares with a projection of the raw compiled
   data made without the builder (`Project`, `Compare`).
5. For SUPPORTED quests, compares with the frozen v1 record
   (`V1Equivalent`). For UNSUPPORTED quests, counts that every extra ref,
   reputation pair (including 0), kill-credit-first order and duplicate is
   still present.
6. Does all of this twice and requires identical aggregates, and requires the
   source fingerprint (never printed) to be unchanged.
7. Prints aggregate counts only. No quest IDs, no files.

The mode refuses to start, before M0, with any value other than `1`, with
any v1 export, coverage, v2 export or fixture variable, with skip-compile, or
without the level-count assertion.

## Modules

| File | Functions |
|---|---|
| `tools/validation/EffectiveExportV2.lua` | `CheckContext`, `MaxObjectiveIndex`, `BuildRecord`, `BuildAll` |
| `tools/validation/RoundTripV2.lua` | `Project`, `Rebuild`, `RecomputePositions`, `Compare`, `V1Equivalent`, `ReadRaw`, `CheckRecord`, `Check`, `Aggregate`, `FormatAggregate`, `Run` |
| `tools/validation/NoWriteGuard.lua` | `Install`, `Remove` (blocks write-mode `io.open`, `io.output(name)`, `io.popen`, `os.execute`, `os.rename`, `os.remove`, `os.tmpname`, and counts attempts) |
| `tools/validation/draft/EffectiveSchemaV2Draft.lua` | adds `ValidateQuest`; objectiveIndex rule corrected (see spec) |

## Measured on the public database (2026-10-15)

| Measure | Result |
|---|---|
| quests processed / built | 9,159 / 9,159 |
| build errors / validation errors / unclassified | 0 / 0 / 0 |
| SUPPORTED (v1 representable) | 8,401 |
| UNSUPPORTED_BY_RULES | 758 |
| ExpectedM1 disagreements | 0 |
| round-trip quests differing / differences | 0 / 0 |
| v1 equivalence | 8,401 compared, 0 differing |
| extra refs (occurrences) | 801 (monster 466, object 335, item 0) |
| extra entries | 730 in 632 quests; 78 spawn-only; 696 with objectiveIndex 0; 5 one past the DB objectives |
| reputation pairs | 181 (22 with value 0) |
| kill-credit-first quests | 16 |
| duplicate occurrences | 10 (creature 9, object 1) |
| source unchanged / repeat identical / blocked write attempts | yes / yes / 0 |

Quest counts versus occurrence counts: 801 extra refs are occurrences. The
per-reason figures are quests: EXTRA_CREATURE_REF 359 quests (466 monster
refs), EXTRA_OBJECT_REF 243 quests (335 object refs), REPUTATION_OBJECTIVE
181, KILLCREDIT_FIRST_REORDER 16, DUPLICATE_CREATURE 7 quests (9
occurrences), DUPLICATE_OBJECT 1. A quest can carry several reasons, so the
reasons sum to more than 758. The 758 are represented with the M1 classes
unchanged.

Documented exclusions (counted, not silently dropped): objective text 1,455,
extra text 730, spawn coordinates 105 entries, triggerEnd contents 354.
Normalisation: 3,599 quests with no objectives table compare equal to an
empty list.

Performance (box, `/usr/bin/time -v`, measured while another suite ran):
the round-trip mode takes about 21 s wall against 17 s for a default run.
Peak RSS is about 622 MiB in both (the compile dominates). The round trip
uses about 1.3 to 2.0 s of CPU per pass, with about 159 MiB of Lua heap
growth.

## Spec correction found by measurement

`objectiveIndex` may be number of objectives + 1 only with a triggerEnd or
with no DB objectives (5 real quests). The first run produced 5 build errors.
They were investigated, not forced, and the rule now matches the data
exactly. Positive and negative tests cover it. In-game verification of the 5 quests (10985, 13429, 12124, 13418, 13419) is still pending.

## M1 parity with frozen v1 (hardening, decision t54u)

`EffectiveSchemaV2Draft.ExpectedM1` now emits the established v1
`EffectiveExport.Record` codes. The two former synthetic conflicts are
resolved:

* killCreditFirst with exactly one killCredit and no other ordinary
  objective reorders nothing, so it is SUPPORTED (as v1). The v2 flag and
  order are kept. It is a reorder (`KILLCREDIT_FIRST_REORDER`) only when a
  killCredit moves before another kind or several killCredit entries are
  reversed.
* Repeated requiredSourceItems: v2 keeps every occurrence and the
  classification keeps v1's `DUPLICATE_SOURCE_ITEM`.

| v1 reason (EffectiveExport.Record) | v2 ExpectedM1 before | v2 ExpectedM1 after |
|---|---|---|
| DUPLICATE_SOURCE_ITEM | none (SUPPORTED) | DUPLICATE_SOURCE_ITEM |
| DUPLICATE_CREATURE | DUPLICATE_CREATURE | same |
| DUPLICATE_OBJECT | DUPLICATE_OBJECT | same |
| DUPLICATE_ITEM | DUPLICATE_OTHER | DUPLICATE_ITEM |
| DUPLICATE_SPELL | DUPLICATE_OTHER | DUPLICATE_SPELL |
| DUPLICATE_KILLCREDIT_ID | none | DUPLICATE_KILLCREDIT_ID |
| REPUTATION_OBJECTIVE | REPUTATION_OBJECTIVE | same |
| SHAPE_UNUSUAL (spell itemSourceId) | none | SHAPE_UNUSUAL |
| EXTRA_CREATURE_REF / EXTRA_OBJECT_REF | same codes | same |
| DUPLICATE_EXTRA_ITEM | none | DUPLICATE_EXTRA_ITEM |
| KILLCREDIT_FIRST_REORDER | whenever flagged | only on a real reorder (v1 rule) |
| EXTRA_OTHER_REF, LEVEL_INVALID, SOURCE_ITEM_INVALID, QUERY_FAILED, other SHAPE_UNUSUAL, UNCLASSIFIED | not reachable | not reachable (the builder refuses those inputs first) |

No new code was introduced. The acceptance fixture's quest 900001 (spell
with itemSourceId) now carries the SHAPE_UNUSUAL that v1 gives it.

Synthetic parity matrix: 3,281 cases (each reason alone, killCreditFirst
edge cases, all 350 compatible pairs and 2,900 compatible triples of 27
features, all features together), 364 SUPPORTED and 2,917 UNSUPPORTED, 0
disagreements in status or reason set. Run against the previous ExpectedM1,
the same matrix fails 5,844 checks. Real database: all 9,159 quests agree
(`m1 status disagreeing with v2 ExpectedM1 0`, and 0 killCreditFirst quests
flagged without a reorder). The baseline is unchanged.

## Tests

| Test | Checks |
|---|---|
| `tests/test_nquestie_m2_v2_builder.lua` | 150: exact records, round trip, determinism, aliasing, about 60 negative inputs, 27 tamper cases, former conflicts now agree, m1 mismatch fails closed |
| `tests/test_nquestie_m2_v2_m1_parity.lua` | 9,907 checks over 3,281 cases: ExpectedM1 against frozen V1.Record, status and reasons |
| `tests/test_nquestie_m2_no_write_guard.lua` | 20 |
| `tests/test_nquestie_m2_v1_frozen.lua` | v1 output byte-identical to a golden file made with the base commit's exporter (accepted and refused quests) |
| `tests/test_nquestie_m2_v2_mutation.sh` | 40 mutants (13 on the parity logic), all killed; the unmutated copy passes |
| `tests/test_nquestie_m2_v2_roundtrip_integration.sh` | 69: refusals, unchanged checkout and empty HOME/TMPDIR, every baseline, determinism across processes, default run unchanged |
| `tests/test_nquestie_m2_v2_acceptance.lua` | 41 (objectiveIndex rule) |

All of these run from `tests/run_m2_suite.sh` and from busted
(`tools/validation/M2V2RoundTrip.test.lua`). No workflow file is changed.
Public CI is framework evidence only.
