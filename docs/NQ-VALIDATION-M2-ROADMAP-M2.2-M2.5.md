# N-Questie validation roadmap: M2.2 to M2.5 and in-game QA

Status: planning. Every stage needs its own maintainer approval before implementation. Date: 14 October 2026.

PR stack for the planning work (each a draft, merge order bottom to top): #39 v2 design final → #41 v2 exporter spec and Proposal A → #42 M2.3 design and Proposal B → #43 markers design → this PR (#44, correction workflow and roadmap). Separate: harness 1.2.0 PR on the #38 line; #40 (lead QA planning) is a parallel sibling, not part of this stack.

Standing safeguards for every stage: synthetic or public data only in the repository and CI; private files only through SafeWrite to private paths; whole-batch fail-closed; v1 frozen; M0/M1 unchanged; no automatic corrections; no runtime addon, server or SavedVariables changes from validation code.

## M2.2 completion: production v2 exporter

| Item | Detail |
|---|---|
| Depends on | #39 (validator, design), #41 (spec) |
| Files | new exporter mode or CLI (decision open), `tools/validation/EffectiveSchemaV2.lua` promoted from draft, `EffectiveExport.lua` v2 record builder |
| Synthetic tests | A1-A4 (existing draft tests become production tests) |
| Full-DB tests | F1-F8 in the spec: 9,159 records, 8,401/758, round trip 0 differences, no-loss for the 758, v1 equivalence for 8,401, determinism, M0/M1/v1 unchanged, fail-closed |
| Privacy | export written privately; CI runs on public data only |
| Deliverables | exporter, tests, measured round-trip report (counts only) |
| Acceptance | all F-tests pass in CI on the final head; v1 writer unchanged and v1 output equivalent by `Canonical(doc, {"exportedAt"})` (production timestamps kept); golden v1 fixture test |
| Limitations | structural only; no text, coordinates or triggers |
| Approval gate | maintainer authorises the production exporter; HARNESS_VERSION bump decided |

## M2.3: report-only batch comparison

| Item | Detail |
|---|---|
| Depends on | M2.2 completion (v2) for the 758; v1 alone covers the 8,401 |
| Files | `tools/validation/BatchCompare.lua`, CLI `cli/compare-m2.lua`, `M23Report.lua` promoted from draft |
| Synthetic tests | contract draft tests (185 checks) become production; matrix S01-S20 and P01 already executed against the draft protocol; D01-D03 become executable with the engine |
| Full-DB tests | run against a synthetic server file covering all 9,159 IDs (public-derived values) to prove every quest gets one row |
| Privacy | real server comparisons only on the lead's trusted machine; aggregate reviewed before sharing |
| Deliverables | engine, private report, aggregate |
| Acceptance | matrix passes; M1 results identical to direct calls; inputs unchanged; 1203 never CONFIRMED |
| Limitations | mostly NEEDS_MANUAL_REVIEW until server evidence (KillCredit, conditions, scripts, IP) is exported |
| Approval gate | maintainer authorises the engine; first real run reviewed by the lead |

## M2.4: markers

| Item | Detail |
|---|---|
| Depends on | M2.3 (status vocabulary), verified map-bounds table, private spawn export |
| Files | marker exporter, marker schema, location comparison |
| Synthetic tests | marker fixtures with invented zones and coordinates clearly labelled synthetic; tolerance tests; phase/condition unknown never confirms |
| Full-DB tests | marker export for 9,159 quests; every objective target accounted for (direct, killCredit, itemSource, extraRef) |
| Privacy | server spawn data private; only aggregates shared |
| Deliverables | marker export, location report |
| Acceptance | no invented, rounded or deduplicated coordinates: every point traceable, by origin tag, to a specific Questie NPC spawn (`db_npc`), object spawn (`db_object`) or raw custom extraObjective pin (`custom_extra`); waypoints separate; item source categories kept; structural, location and behaviour results reported separately; no confirmed location result |
| Limitations | phases and IP mostly manual; map bounds from verified 3.3.5a client data and Questie coordinates, cross-checked; 1.0 zone-percent tolerance provisional |
| Approval gate | separate approvals for exporter, server spawn export and comparison |

## M2.5: correction rounds and in-game QA

| Item | Detail |
|---|---|
| Depends on | M2.3 (candidates), correction workflow (this PR) |
| Files | `Compat/NQuestie*` modules (reviewed changes only), M0 pins |
| Synthetic tests | compare-and-swap guard tests; revision guard |
| Full-DB tests | tier A: M0 pins for each corrected field, inherited guards, no unrelated differences; tier B: M2.3 outcome recorded, documented NEEDS_MANUAL_REVIEW allowed |
| Text / tooltip QA (separate column) | quest-log line/count/order, tracker, starter/finisher/objective/item-source tooltips, extra objective text; PASS / DIFFERENCE_TO_REVIEW / UNKNOWN with stage and client locale; unknown availability = UNKNOWN; no automatic rewrite (workflow §7, #40 checklist) |
| In-game QA | per correction: quest visible at the right level; starter and finisher markers present; objective markers appear, update on progress and disappear on completion; finisher appears on completion; minimap and world map agree; tested on a fresh character where IP matters |
| Privacy | QA notes private; repository holds only the correction and its public description |
| Deliverables | small reviewed correction PRs in queue order |
| Acceptance | M0, M1, M2 green; QA checklist completed by a person |
| Approval gate | each correction PR reviewed and merged by the maintainer |

## Recommended implementation sequence

1. Review and merge the harness 1.2.0 PR (#38 line), then the planning stack in order (#39 → #41 → #42 → #43 → #44).
2. First production PR: Proposal A step 1, the v2 record builder plus the measured round trip (counts-only output), then the exporter mode around it.
3. M2.3 (Proposal B) on v1 for the 8,401, then extend to v2; first private run 1203 only, after the lead's Lua 5.1 validation.
4. Corrections in queue order, levels first.
5. Markers last; they need verified map bounds and a private spawn export.
