# Proposal B: private report-only M2.3 batch engine

Status: **proposal for maintainer approval**. Not implemented. Approving this document is not approval to merge or release. Design: `docs/NQ-VALIDATION-M2.3-DESIGN.md`. Date: 14 October 2026.

## 1. Scope

In: one server file (`nq-m2-input` v1), one effective export (v1 or v2), one paired coverage manifest; selection protocol; two-axis statuses; M1 called unchanged; private report; counts-only aggregate; optional private rejection diagnostic.

Out: corrections of any kind, markers, text, network access, writing into the repository, any public output of real data.

## 2. What real M2.1 input can and cannot establish

The frozen M2.1 server record carries `hasConditions`, `ipGated`, `scriptedCredit` and KillCredit completeness as recorded by the private exporter, where `unknown` and `false` are different. The engine:

- maps a recorded `false` with a stated source to `complete` for that evidence item only if the private exporter documents how it was determined;
- maps `unknown`, absent or undocumented values to `unknown`;
- therefore returns `NEEDS_MANUAL_REVIEW` for most real quests until the server export carries that evidence. No completeness is invented.

## 3. Files

| File | Purpose |
|---|---|
| `tools/validation/M23Batch.lua` | pure engine: `Run(serverDoc, effectiveDoc, manifestDoc) -> report, aggregate` or `nil, rejection` |
| `tools/validation/M23Report.lua` | promoted from `draft/M23ReportDraft.lua` (validators, selection protocol) |
| `cli/compare-m2.lua` | reads three private files through the restricted parser, writes through SafeWrite |
| `tests/test_nquestie_m2_3_engine.lua` | synthetic engine tests |
| `tests/test_nquestie_m2_3_cli.sh` | CLI tests with synthetic files in a temporary private directory |

No workflow file edits; tests are wired through `run_m2_suite.sh` and the busted wrapper.

## 4. Steps

1. Promote the draft validators and selection protocol (no behaviour change; existing 110 checks kept).
2. Engine core: validation order (§2 of the design), pairing, preflight split, membership, per-quest M1 call, outcome assignment with `OutcomeAllowed` as an internal assertion.
3. Output: deep-compare inputs before and after; build report and aggregate; validate both; write both or nothing.
4. CLI and its tests.
5. First private pilot (lead only): quest 1203 alone, after the lead's genuine Lua 5.1 validation of the real file. Only a pass/fail line and counts are shared.

## 5. Tests and acceptance

| Test | Pass |
|---|---|
| Executed matrix S01-S17, P01 | engine gives the same statuses / rejection codes as the draft protocol |
| Design assertions D01-D03 become executable | input changed → `REJECTED_INPUT_CHANGED`; unsafe or existing output → `REJECTED_UNSAFE_OUTPUT`; M1 results equal direct calls |
| Rejection | every rejection leaves the output directory without report or aggregate |
| Report/aggregate | outputs pass `ValidateReport` and `ValidateAggregate`; aggregate contains only vocabulary keys |
| 1203 synthetic | v1 effective vs synthetic server 1203 → EXPORTED / EXPECTED_REPRESENTATION_DIFF, never CONFIRMED |
| Unknown evidence | any unknown item → never CONFIRMED_* |
| Full-ID coverage | synthetic server file listing all 9,159 IDs with public-derived values against a v2 test export → exactly one row each; 758 rows `m1Supported = false` |
| CI | all six workflows green on the exact head SHA; real data never in CI |

## 6. Stopped / no-go list

- No automatic correction, no edits to Questie data, no network, no upload.
- No real server data in fixtures, logs, PR text or CI.
- Stop if any outcome would require weakening M1, v1, the reason vocabulary or the evidence rules.

## 7. Approval gates

1. Maintainer approves this proposal.
2. Draft PR reviewed on its exact head with six green workflows.
3. Separate approval for the first private 1203 run (lead's machine only).
4. Separate approval before any aggregate is shared.
