# N-Questie M2 design stack audit (#39 to #44)

Date: 14 October 2026. Scope: draft PRs #39 → #41 → #42 → #43 → #44 and the separate harness 1.2.0 PR. #40 (lead QA planning) is a parallel sibling on the #38 line, read for alignment and not edited. Heads and CI are listed in the handover §13.

## 1. Ancestry

| PR | Base | Contains |
|---|---|---|
| #39 | #38 branch | v2 design final draft |
| #41 | #39 branch | #39 merged in (no rebase) + exporter spec, Proposal A |
| #42 | #41 branch | #41 merged in + M2.3 design, Proposal B |
| #43 | #42 branch | #42 merged in + markers design |
| #44 | #43 branch | #43 merged in + correction workflow, roadmap, this audit |
| harness 1.2.0 | #38 branch | HARNESS_VERSION bump and pins only |

Changes made low in the stack (#39 CI evidence, status model, historical-figure notes; #41 reproducibility) were merged upward, never rebased. Legacy #4, #18 and #32 are diverged from #38 (see #40's consolidation plan) and are not touched.

## 2. Checks

| Item | Finding | Result |
|---|---|---|
| Counts 9,159 / 8,401 / 758 / 0 unclassified | consistent in v2 design, spec, proposals, M2.3 design, roadmap, coverage doc. Older 8,407 / 752 in the Step 1 doc, handover §4 and roadmap open-item section were presented as live | fixed: marked as historical snapshots (pre-#36); live summary lines updated |
| Export statuses | #39 design §10 and roadmap §4 listed `REJECTED_MALFORMED_INPUT` as a per-quest status | fixed: three report statuses everywhere; malformed is batch-level only; selection mismatch rejects |
| Outcomes | five outcomes, same names in #39, #42, roadmap, workflow | pass |
| CONFIRMED rules | `CONFIRMED_MISMATCH` lacked a findings requirement | fixed in #42 (`OutcomeAllowed`, tests) |
| Reason vocabulary | aggregate allowed any key | fixed: closed vocabulary v1 = 17 `EffectiveExport.REASONS` codes, equality tested |
| Provenance | server: full M2.1 validation, no git; effective/manifest: pairing on 10 fields + modules; aggregate: no fingerprints | pass, consistent in #39 §9, #42 §2-3, Proposal B |
| Version numbers | nq-m2-input v1, nq-m2-effective v1 (frozen) and v2 (draft), nq-m2-3-report v1, nq-m2-3-aggregate v1, nq-m2-3-rejection v1, nq-m2-markers v1 (draft), reason vocabulary v1 | pass |
| Harness version | 1.2.0 only in the separate PR; design fixtures keep `1.1.0` as synthetic values; Proposal A plans 1.3.0 | pass (documented) |
| v1 byte identity | spec F7 and roadmap demanded byte identity despite run timestamps | fixed: `Canonical` with explicit exclusion of per-run fields, tested; production provenance unchanged |
| Marker traceability | roadmap M2.4 only allowed npcDB/objectDB points; markers stored zone-only custom spawns | fixed: three origins incl. raw custom pins, tested |
| Correction regression | forced CONFIRMED against unknown evidence | fixed: two tiers, documented manual review allowed |
| Text/tooltip | not covered | added: separate lane, aligned with #40 vocabulary |
| Superseded helper names | `CheckServerProvenance` only mentioned as replaced | pass |
| Check counts quoted in docs | v2 draft 63, acceptance 38, M2.3 contract 110, markers 39, QA 25, harness pin 5 | pass (executed, see handover §13) |

## 3. Open items

- Design assertions D01-D03 (input changed, unsafe output, M1 equality) are not executable without the engine and are not counted as tests.
- Map bounds and tolerance are decided in principle but no bounds table exists.
- Real private 1203 validation is the lead's task and is not represented by any CI result here.
