# N-Questie M2.2 pilot procedure: quest 1203, then the v1 pilot list

Status: procedure ready; run locally on public data (results below). Nothing was published.
Scope: Option A. Only v1-representable quests. The comparison with private server data is M2.3 and is not part of this procedure.
Date: 14 October 2026 (Europe/London)

## 1. What the pilot proves

| Gate | Requirement | How it is checked |
|---|---|---|
| M0 negatives | 5 fault-injection fixtures still rejected | `tests/test_validate_335_fixtures.sh` |
| M0 checks | 232 checks pass before anything is written | harness log `PASS: 232 checks`; the export runs only after PASS |
| Corrections | 28 level corrections | `NQ_VALIDATE_EXPECT_LEVEL_COUNT=28`, harness log, provenance `correctionCount` |
| Integrity | 82,431 compiled fields, 0 mismatches | harness log |
| M1 on 1203 | stock CONFIRMED_MISMATCH, effective EXPECTED_REPRESENTATION_DIFF | harness log |
| Stock 1203 | objective item 33110 | public source line in `Database/Wotlk/wotlkQuestDB.lua` |
| Effective 1203 | levels 30/35, objective item 3853 | written export, loaded with the v1 validator |
| Provenance | commit = HEAD, revision 5, 28 corrections, 232 M0 checks | written export |
| Safe output | 0700 directory, 0600 file, no clobber | SafeWrite; script checks modes |

## 2. Procedure

```bash
git status --porcelain --untracked-files=all     # must print nothing
tools/validation/run-m2-pilot.sh /abs/private/m2-pilot 1203
tools/validation/run-m2-pilot.sh /abs/private/m2-pilot pilot   # the 16-quest list (section 4)
```

Requirements: Linux, GNU coreutils (`realpath -e`), lua5.1, git, sha256sum, a clean checkout. The output directory must be absolute, outside the checkout (or under `private/`), and mode 0700; the script creates it if missing. Existing output files are never overwritten. Logs, the export and a SHA256 file stay in that directory.

## 3. Local results (box, 14 October 2026, commit 5a69d4be5)

| Check | 1203 run | Pilot-list run |
|---|---|---|
| 5 M0 negatives rejected | PASS | PASS |
| Harness exit 0, 232 M0 checks | PASS | PASS |
| 28 level corrections | PASS | PASS |
| 82,431 fields, 0 mismatches | PASS | PASS |
| M1 1203: stock CONFIRMED_MISMATCH, effective EXPECTED_REPRESENTATION_DIFF | PASS | PASS |
| Export written after PASS, mode 0600 | PASS | PASS |
| Stock 1203 item 33110 (public source) | PASS | PASS |
| Effective 1203: 30/35, item 3853 | PASS | PASS |
| Provenance: commit = HEAD, revision 5, 28 corrections, M0 232 | PASS | PASS |
| Records | 1 | 16, in requested order |

Output went to a temporary 0700 directory on the box and was not published. The export SHA256 depends on the commit and export time, so it is not a reference value.

## 4. Proposed v1 pilot list (16 quests, all v1-representable)

Every quest is REPRESENTABLE in the coverage manifest, and the pilot-list export succeeded (the exporter refuses the whole run if any requested quest is unsupported). Values are the effective compiled public data.

| Quest | Levels | Creatures | Objects | Items | KillCredit {ids}/root | Source item | Required source items | Covers |
|---|---|---|---|---|---|---|---|---|
| 1203 | 30/35 | | | 3853 | | | | item; the N-Questie correction |
| 2001 | 12/16 | 1868, 1869 | | | | | | creatures |
| 498 | 17/22 | | 1721, 1722 | | | | 3467, 3499 | gameobjects + required source items |
| 553 | 29/33 | | 1768, 1769, 1770 | | | 3710 | | gameobjects + source item |
| 786 | 5/8 | | 3189, 3190, 3192 | | | | | three gameobjects |
| 2784 | 45/50 | | | | {7572}/7572 | | | KillCredit |
| 3377 | 40/50 | | | | {8436}/8436 | | | KillCredit |
| 9666 | 10/13 | 17701 | | | {17701}/17701 | 24084 | | creature + KillCredit on the same NPC |
| 4022 | 52/54 | | | 10575 | {9459}/9459 | | | item + KillCredit |
| 532 | 19/26 | 2335, 2387 | 1761 | 3657 | | | | mixed: creatures, object, item |
| 10392 | 58/61 | 19298 | 182935 | 29795 | | | 29795 | mixed + required source item |
| 1045 | 18/30 | 3696, 3932 | | 5388 | | 5462 | | creatures + item + source item |
| 611 | 32/40 | | | 4034 | | 4027 | 4034, 4027 | item + source + required source items |
| 717 | 40/50 | | | 4615, 4645 | | 4640 | 4843, 4844, 4845 | two items, three required source items |
| 30 | 16/-1 | | | 15885 | | | 15883, 15882 | scaling level (-1); spawn-only extraObjective (v1-representable) |
| 25 | 23/25 | 3917 | | | | | | creature + triggerEnd |

Not in the list (out of scope under Option A): any quest with reputation, extraObjectives creature/object references or duplicate objectives (752 quests).

## 5. How the lead developer runs it privately

1. Check out the stack top on a trusted Linux machine (GNU coreutils, lua5.1). Make sure `git status` is clean.
2. Create a private directory outside the checkout: `mkdir -m 700 ~/nq-private/m2-pilot`.
3. Run `tools/validation/run-m2-pilot.sh ~/nq-private/m2-pilot 1203`, then `... pilot`.
4. Keep the effective exports private. They are public-data derived but are the input to the private M2.3 comparison, which uses the private server input (`nq-m2-input` v1) together with these files.
5. Optional preflight before choosing more quests: the coverage run in `docs/NQ-VALIDATION-M2.2-COVERAGE.md` §4; keep its per-quest manifest private.
6. Share only the PASS/FAIL lines and counts. Do not share server data, SQL/Excel exports, credentials or SavedVariables.

Outstanding before the private comparison: the lead developer's real M2.1 input file still needs genuine Lua 5.1 validation (`cli/validate-m2-input.lua`) in a trusted Linux environment.
