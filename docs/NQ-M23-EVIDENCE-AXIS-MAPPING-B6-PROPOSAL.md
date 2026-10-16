# M2.3 B6: evidence-axis mapping proposal (DRAFT — DESIGN ONLY)

**Status:** a new design-only PR requested by the maintainer, for review by CosmicScript01 and CosmicScript02. **No source code, schema or workflow changes and no confirmation enabled.**

**Stable reference:** protected-by-policy `335`, `41aa84b56f38adbea09a89c32af1e9ab4c4b9d09`; frozen `InputSchema.lua`, frozen `ObjectiveRules.lua`, frozen draft `tools/validation/draft/M23ReportDraft.lua`, and separately reviewed Part 2 `M23Batch.lua` on draft #69 at `5f444388814834b2a6ec101258d211dcd1c312b1`.

**Approval to research:** [Maintainer decision, 2026-10-16](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6214484105), item 6. This authorises *draft design* only. No confirmation outcome, new trusted exporter, merge, private quest run, release or publication is authorised by this document.

## 1. Purpose and the immutable boundary

Frozen report-v1 recognises five `evidence` keys: `killCredit`, `conditions`, `scripts`, `ip`, and `objectiveData`. Its **draft classification model** permits `CONFIRMED_MATCH` only with all five literally `"complete"`, **zero M1 findings**, and no representation difference. It permits `CONFIRMED_MISMATCH` only with all evidence complete, at least one M1 `CONFIRMED_MISMATCH` finding, and **no** `NEEDS_MANUAL_REVIEW` or `UNSUPPORTED` finding. These conditions are **necessary but not proof of data authenticity or data completeness**. M1's finding class is not itself an M2.3 final outcome.

Frozen `nq-m2-input` v1 contains `killCreditComplete`, `hasConditions`, `ipGated` and `scriptedCredit`, plus server quest objective fields. **It contains no `objectiveData` attestation**, nor does ordinary structural validation prove completeness of conditions, scripts, IP stages or external objective sources. Absent required tri-states already fail `InputSchema.Validate`; explicit `"unknown"` remains unknown, never false.

**Safe existing behaviour:** draft #69's `M23Batch.Run` deliberately sets **all five evidence axes to `"unknown"`** on every selected quest. It emits only `NEEDS_MANUAL_REVIEW`, `EXPECTED_REPRESENTATION_DIFF`, or `M1_UNSUPPORTED_BY_RULES`, never either `CONFIRMED_*` outcome. Preserve this behaviour until new evidence proofs are separately designed, accepted and tested. Do **not** change the frozen v1 input schema to smuggle in flags.

## 2. Candidate mapping — separate the hint from the proof

CosmicScript02's initial candidate, recorded in [Checkpoint B6](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6199892867), maps a `true` `killCreditComplete` hint to complete, maps literal `false` conditions/script/IP flags to complete, and maps `objectiveData` to complete after input validation. **This is a valuable test hypothesis, not adequate production confirmation evidence.** A false flag may represent absent data *in a particular export*, but without an independently verified coverage/completeness proof, absence cannot be treated as proven. `InputSchema.Validate` guarantees shape, not semantic completeness.

Recommended **two-tier mapping** for a future explicitly versioned, separately authenticated evidence source:

| Evidence axis | Frozen v1 signal (hint only) | Allowed future `complete` proof; otherwise `unknown` |
|---|---|---|
| `killCredit` | `killCreditComplete == true` | An independently authenticated *per-quest* coverage assertion that all relevant creature/kill-credit source rows for that quest were queried, joined and verified against the pinned server snapshot **AND** the existing M1 per-creature KillCredit safeguards still hold. `false` or absent proof → unknown |
| `conditions` | `hasConditions == false` | An authenticated per-quest **complete conditions query/absence attestation** for the same snapshot, with no unknown/incomplete source rows and the flag literally false; `true` or unknown → never a completeness shortcut |
| `scripts` | `scriptedCredit == false` | An authenticated, versioned coverage attestation for the defined script/credit sources for that quest, demonstrating absence or reviewed completeness for the precise source scope. A false flag without source coverage is not enough |
| `ip` | `ipGated == false` | A pinned, stage-aware per-quest Individual Progression eligibility/availability scope proof; must cover the chosen realm/progression policy and the exact source snapshot. A false flag by itself is not a completeness proof |
| `objectiveData` | Parsed and structurally valid v1 objective row | An authenticated semantic completeness proof for all objective fields, joins, counts and supported representations required for M1 parity, with documented source coverage and no unclassified objectives. **Validation alone must never assert complete** |

These are **requirements for a future versioned evidence profile**, not an implementation of those checks. A source can be unavailable or not applicable, but it must not default to `"complete"` merely because the row is missing. Where the current project cannot prove all required evidence for a quest, it must remain `"unknown"` and **never become a confirmed M2.3 outcome**.

## 3. Proposed provenance and consistency gates

A future evidence document or separately authenticated attestation (its exact name/schema are **NOT yet approved**) should have the following properties before use:

1. **Versioned and closed schema** with exact five-axis vocabulary; no free-form proof claims that an engine merely trusts. `complete` requires a matching proof type, not a user-supplied magic string.
2. **Per-quest join** to the selected ID and pinned effective v2 export/coverage manifest, while confirming the complete 9,159-ID external membership/status reconciliation first; do not infer unselected quests from a selected subset.
3. **Snapshot binding:** source fingerprint, exporter version, approved source commit and per-axis coverage scope must bind to the same immutable authenticated source snapshot as the `nq-m2-input` v1 export. A self-contained digest only checks tampering, not historical authenticity.
4. **Known-unknown propagation:** missing `objectiveData` proof, script-coverage uncertainty, unverified IP stage, any `"unknown"` flag, partial query, duplicated or mismatched source record, or trust failure must never yield an evidence axis `complete`.
5. **No partial promotion:** preserving a stronger `M1` `CONFIRMED_MISMATCH` *finding class* is permitted in a **private** finding, but the **final** batch outcome is bounded by all five evidence axes and the unchanged decision rules. Do not promote a single good axis into confirmation.
6. **Privacy:** only fixed rejection codes on stderr; no quest IDs, private paths, source fingerprints, explanation text or detailed proof records in public CI/artifacts/aggregate-v1. Any new evidence member stays private and covered by independently reviewed bundle integrity.
7. **Atomic safety:** the completed evidence proof and the private output must be mutually consistent, checked before a private no-clobber bundle is published. Fail closed on any disagreement; no partial per-quest success or auto-correction.

## 4. Decision alternatives

**A — keep all five evidence axes unknown (recommended until a real per-axis completeness source exists).** Safe today, permits manual/expected-difference triage but no `CONFIRMED_*`. No change to frozen v1 or existing Part 2.

**B — promote axes based solely on existing four v1 flag values and shape validation.** Simpler and originally suggested for discussion; **not recommended** because false/true assertions and structural validation cannot attest the absence or completeness of external quest data and `objectiveData` has no trustworthy completeness source in v1. Must not be silently implemented.

**C — introduce a separately reviewed versioned evidence source with the proofs in §2–3.** This could eventually allow confirmations after a **new, explicit maintainer approval** of the evidence schema, trust model, complete/unknown transitions, handling of untrusted sources, and mutation-sensitive tests. It is **not** part of current Part 3 reporting D1–D4 approval.

Recommended staged decision: **approve A now as the default; research C as a distinct future design and do not approve B.**

## 5. Proposed synthetic acceptance matrix (no production tests added in this PR)

| ID | Synthetic condition | Required final outcome / gate |
|---|---|---|
| EV01 | Well-formed v1, matching M1 targets, all four v1 hints plausible, no independent objectiveData proof | Evidence all unknown, `NEEDS_MANUAL_REVIEW`; never `CONFIRMED_MATCH` |
| EV02 | M1 target difference with `CONFIRMED_MISMATCH` finding class, but no external source-completeness attestation | Private M1 class retained; final `NEEDS_MANUAL_REVIEW`, never `CONFIRMED_MISMATCH` |
| EV03 | `killCreditComplete=true` but missing coverage-source proof | `killCredit=unknown`, never confirmed |
| EV04 | `hasConditions=false`, `scriptedCredit=false`, `ipGated=false` but no relevant source-scope proof | Three axes unknown; no confirmed outcome |
| EV05 | Explicit `"unknown"` for any tri-state | Unknown, no confirmed outcome |
| EV06 | Missing required tri-state in frozen v1 | Existing `REJECTED_MALFORMED_INPUT`; no bundle |
| EV07 | Malformed/dropped extra objective or unsupported v2 representation | Remains `M1_UNSUPPORTED_BY_RULES`; never silently coerced |
| EV08 | Valid shape plus deliberately incomplete objective-data source coverage | `objectiveData=unknown`, no confirmation |
| EV09 | Well-formed candidate external proof but unknown/untrusted commit or mismatched snapshot fingerprint | No promotion; fixed-code full-batch refusal where trust cannot be established |
| EV10 | Valid future proof for only 4/5 axes | Fifth axis unknown; no confirmed outcome |
| EV11 | Two proofs with duplicate/inconsistent quest ID or missing selected member | Whole-batch rejection; no partially confirmed quests |
| EV12 | Unexpected flag/extra schema key or falsified `"complete"` without its proof | Reject; do not default to complete |
| EV13 | Evidence proof with private quest/path in error message | Fixed-code-only stderr; zero private text leakage |
| EV14 | Reorder/remove one private finding from a provisional confirmed mismatch case | Existing report/private finding order correspondence fails independently of evidence |
| EV15 | Evidence/v2 exported quest source hashes from different snapshots | No per-axis completion or confirmed outcome; source mismatch rejected |
| EV16 | Invalid proof changes a potentially confirmed scenario to unknown | Final classification cannot become more confident |

**Review criteria:** CosmicScript02 should identify any valid, *machine-verifiable* concrete proof of `objectiveData` completeness from already-reviewed frozen v1 data, propose a safe proof schema if one exists, or endorse A as the necessary default. Keep `OutcomeAllowed` as a frozen design reference, not an imported implementation. No `CONFIRMED_*` until test coverage verifies every axis against authenticated sources.

## 6. Out of scope and future gate

This document **does not** enable confirmation, alter frozen M0/M1/v1, add or alter the M2.3 Part 3 private schema/engine, modify `335`, change branch protection, approve a trusted exporter commit, expose private data, publish a bundle, run on a server, merge any PR, alter the addon, or release anything.

**Links:** [CosmicScript02's B6 candidate](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6199892867) · [CosmicScript01 safety reservation](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6199960658) · [current #69 Part 2](https://github.com/CosmicCuddle/N-Questie/pull/69) · [maintainer design-only approval](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6214484105).
