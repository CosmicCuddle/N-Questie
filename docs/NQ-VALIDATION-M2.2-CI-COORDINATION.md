# N-Questie M2.2 CI coordination: PR #30, PR #31 and the full M2 suite

Status: review notes for the lead developer. CI-only changes are yours to make; this branch contains no workflow edits.
Date: 14 October 2026 (Europe/London)

## 1. Summary

| Question | Answer |
|---|---|
| Does #30 run the full proposed `nquestie-m2-effective-export.yml` suites? | **No.** |
| Does #31 run them? | **No.** |
| Why | Both PRs sit on bases that predate the M2.2 export code (#30 on #24, #31 on the #23/#25 guard line). The export, writer, provenance and integration tests (#27, #28, #29) do not exist on those branches, so no workflow there can run them. |
| Of the 129 M2.2 export/writer/provenance/integration checks, how many ran in GitHub? | **0.** |
| Where do the new tests currently "run" in GitHub? | Only as busted wrappers inside the inherited `ci.yml` container, where they are reported as **pending** (no lua5.1, GNU realpath, git or sha256sum). Pending is not passing. |

What #30 and #31 do execute (both green, five workflows each):

| Step in `nquestie-objective-rules.yml` | #30 | #31 |
|---|---|---|
| Private-file guard and malicious-index self-test | inherited | yes |
| GNU realpath check (`realpath --version` is GNU, `realpath -e -- /` = `/`) | yes | yes |
| `luac5.1 -p` on M1 files, InputSchema, EffectiveSchema, M2.1/M2.2 standalone tests, specs, fixtures | yes | yes |
| M1 standalone + busted (M1 and M2.1/M2.2 Step 1 specs) | yes | yes |
| M2.1 schema and path tests | yes | yes |
| M2.2 Step 1 effective-schema standalone tests | yes | yes |
| M2.2 snapshot (46), safe writer (36), provenance (22), real-DB export integration (25) | **no** | **no** |
| M2.2 coverage synthetic (71) and real-DB coverage integration (20) (new, this PR) | **no** | **no** |
| M0 negatives (`tests/test_validate_335_fixtures.sh`) inside the M2 workflow | no (runs in `validate-335`) | no |

Run evidence (all success):

- #30 (head d7b5515b2): objective-rules https://github.com/CosmicCuddle/N-Questie/actions/runs/38599326301 ; validate-335 https://github.com/CosmicCuddle/N-Questie/actions/runs/38599325968 ; unit/lint https://github.com/CosmicCuddle/N-Questie/actions/runs/38599325965
- #31 (head af9b2b9f4): objective-rules https://github.com/CosmicCuddle/N-Questie/actions/runs/38599902099 ; validate-335 https://github.com/CosmicCuddle/N-Questie/actions/runs/38599902111 ; unit/lint https://github.com/CosmicCuddle/N-Questie/actions/runs/38599902181

Both closed the two #22 gaps (luac coverage and GNU realpath) for the files that exist on their bases. Neither duplicates nor conflicts with the work here.

## 2. Proposed action (CI-only, for the lead developer)

Open one CI-only draft PR whose **base is the top of the M2.2 stack** (currently `feat/nq-validation-m2.2-pilot-v2-design-2026-10-14`; the file also runs the coverage, v2-draft and pilot-syntax steps, which exist only from that branch up), adding one new file:

`.github/workflows/nquestie-m2-effective-export.yml` = byte-for-byte copy of `docs/proposed-workflows/nquestie-m2-effective-export.yml` from that branch.

The exact patch is `docs/proposed-workflows/nquestie-m2-effective-export.activation.diff` (a new-file diff; apply with `git apply`). It changes nothing in `nquestie-objective-rules.yml`, so it does not overlap with #30 or #31.

Requirements the workflow relies on (all in the file):

1. `fetch-depth: 0` (provenance reads commit and tree).
2. lua5.1, luarocks, busted, bit32; GNU coreutils (ubuntu-24.04 default).
3. Clean checkout; the last step asserts the tests left it clean.
4. No secrets, `permissions: contents: read`, writes to runner temp only.

After activation, confirm in the job log that these lines appear (proof that the checks ran rather than skipped):

| Log line | Checks |
|---|---|
| `PASS: M2.2 effective export (46 checks)` | 46 |
| `PASS: M2.2 safe writer (36 checks)` | 36 |
| `PASS: M2.2 provenance (22 checks)` (21 + NOTE means the tree was dirty) | 22 |
| `PASS: M2.2 export integration (25 checks)` | 25 |
| `PASS: M2.2 coverage (71 checks)` | 71 |
| `coverage integration: 20 passed, 0 failed` | 20 |
| `PASS: M2 v2 DRAFT prototype (33 checks)` | 33 |

Optional, later: once this workflow is active, the M2.2 busted wrappers in `ci.yml` can stay pending there; no change to `ci.yml` is needed.

## 3. Merge order note

#30 and #31 can merge independently of this activation. If #31 is merged into the M2 line first, the activation PR still applies cleanly (different file).
