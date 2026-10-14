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
exactly. Positive and negative tests cover it.

## Known synthetic conflicts (0 in real data)

* A killCreditFirst quest with a single kill-credit entry: v1 says
  SUPPORTED, while the v2 ExpectedM1 rule says UNSUPPORTED.
* Repeated requiredSourceItems: v1 says DUPLICATE_SOURCE_ITEM, while
  ExpectedM1 says SUPPORTED.

Both fail closed in the round trip (fixture quests 910013 and 910015). This
needs a decision before Stage A2.

## Tests

| Test | Checks |
|---|---|
| `tests/test_nquestie_m2_v2_builder.lua` | 145: exact records, round trip, determinism, aliasing, about 60 negative inputs, 27 tamper cases, conflicts fail closed |
| `tests/test_nquestie_m2_no_write_guard.lua` | 20 |
| `tests/test_nquestie_m2_v1_frozen.lua` | v1 output byte-identical to a golden file made with the base commit's exporter (accepted and refused quests) |
| `tests/test_nquestie_m2_v2_mutation.sh` | 27 mutants, all killed; the unmutated copy passes |
| `tests/test_nquestie_m2_v2_roundtrip_integration.sh` | 68: refusals, unchanged checkout and empty HOME/TMPDIR, every baseline, determinism across processes, default run unchanged |
| `tests/test_nquestie_m2_v2_acceptance.lua` | 41 (objectiveIndex rule) |

All of these run from `tests/run_m2_suite.sh` and from busted
(`tools/validation/M2V2RoundTrip.test.lua`). No workflow file is changed.
Public CI is framework evidence only.
