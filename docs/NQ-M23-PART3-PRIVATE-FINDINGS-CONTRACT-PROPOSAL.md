# N-Questie M2.3 Part 3 — private findings contract (review proposal)

**Status: DESIGN ONLY — NOT APPROVED FOR IMPLEMENTATION.** Prepared by CosmicScript01 for independent review by CosmicScript02 and a separate maintainer decision. This document does not authorise an engine, CLI, export allowlist entry, private pilot, publication, merge, release or installation.

**Safe foundation:** protected `335` at `41aa84b56f38adbea09a89c32af1e9ab4c4b9d09`. Part 1 draft PR #68 at `1c817a52b9953b9a2c00d963e25f5ee681e0187e`; Part 2 draft PR #69 at `5f444388814834b2a6ec101258d211dcd1c312b1`; neither is merged. This document deliberately changes neither.

## 1. Problem and design choice

The v2-only Part 2 pure comparison already calls frozen M1 but retains only a finding's `class`; it discards `kind`, `rules`, target references and `explanation`. The frozen `M23ReportDraft` report-v1 row is closed to those details. A summary alone cannot explain which quest objective merits investigation.

**Preferred option B, subject to maintainer approval:**
1. Preserve the historical **`nq-m2-3-report` schemaVersion 1** as the private per-quest summary/index. Do not edit `tools/validation/draft/M23ReportDraft.lua`, its 185 checks, M1, M0 or any frozen v1 validator.
2. Introduce **`nq-m2-3-private-findings` schemaVersion 1** as a second, private-only, strictly validated member.
3. Put report-v1, findings-v1, aggregate-v1, private engine provenance and `leftoverTempCount` inside a **new private `nq-m2-3-bundle` schemaVersion 2**. This is a new validator, not a widening of the historical bundle-v1 contract.
4. Keep the **`nq-m2-3-aggregate` schemaVersion 1** counts-only; it reconciles solely from report-v1 rows. Never put IDs, explanations, rules, source hashes, paths, `leftoverTempCount` or private M1 targets in a shareable aggregate or stderr.

This contract does not authorise *sharing* even a counts-only aggregate. Sharing requires a separate maintainer review/approval.

## 2. Report-v1 index: exact v2-only semantics

- In a successful v2-only run the authenticated full export must contain every selected quest. Selected IDs absent from v2 cause the previously agreed whole-batch rejection; they must not become a successful `ABSENT_FROM_EFFECTIVE_DB` report row.
- Every successful selected row has `exportStatus = "EXPORTED"`, **including** a quest whose v2 `m1Status = "UNSUPPORTED_BY_RULES"`.
- Supported rows have `m1Supported = true`, ordered `m1Classes` (possibly empty), one conservative outcome and five evidence axes. On frozen `nq-m2-input` v1, all evidence axes remain `"unknown"`; never emit `CONFIRMED_MATCH` or `CONFIRMED_MISMATCH`.
- Unsupported-by-M1 rows have `m1Supported = false`, `outcome = "M1_UNSUPPORTED_BY_RULES"`, no M1 findings and no report-v1 `reasons` field. Do **not** call this `UNSUPPORTED_BY_SCHEMA_VERSION`.
- Convert Part 2's `selected` count to a **sorted, unique positive quest-ID array**; require one report row per selected ID, sorted by quest ID for deterministic output.
- Report-v1 `reasons` are reserved for `UNSUPPORTED_BY_SCHEMA_VERSION` by its frozen validator. Since this status is not produced on the v2-only path, **aggregate-v1 reason occurrence counts remain zero**, rather than silently counting the selected v2 unsupported reasons.
- The v2 `m1Reasons` are **not lost**: they appear in the private findings member below. Any proposal to publish selected-subset reason counts or change aggregate semantics needs a separately versioned aggregate and explicit approval.

## 3. Proposed closed private findings member

**Proposed shape (illustrative synthetic data, NOT parser input or shipped fixture):**

```lua
{
  schema = "nq-m2-3-private-findings",
  schemaVersion = 1,
  private = true,
  quests = {
    {
      questId = 60000,
      m1Findings = {
        {
          ordinal = 1,
          kind = "object",
          class = "EXPECTED_REPRESENTATION_DIFF",
          rules = { "E-GO-SIGN" },
          server = -60001,
          questie = 60001,
          explanation = "Private M1 explanation copied verbatim"
        }
      }
      -- unsupportedReasons MUST be absent for supported quests.
    },
    {
      questId = 60002,
      m1Findings = {},
      unsupportedReasons = { "REPUTATION_OBJECTIVE" }
      -- This list only exists for v2 M1-unsupported quests.
    }
  }
}
```

**Closed validation rules (proposed, not implemented):**
- Member, quest entry and finding entry use exact known key sets; reject unknown keys, unsupported versions, metatables, improper arrays, holes, duplicate quest IDs or extra unselected quests. Require the quest-entry ID set to equal the sorted report selection exactly.
- `m1Findings` is a dense array in **original M1 order**. `ordinal` is the 1-based position, not an independently sortable label; no extra, missing or duplicated ordinal.
- `kind` is from M1's actual set `input, quest, availability, quantity, object, creature, item, order`. `class` is exactly one of M1's four class values. `rules` is a dense nonempty **ordered** list with IDs from frozen `ObjectiveRules.RULES`, no duplicates. Do not conflate M1 rule IDs with v2 unsupported reason codes.
- `server` and `questie` are **optional**, mirroring M1's nil; when supplied, preserve their exact native representation:
  - nonzero integral numeric reference with absolute value **at most 2,147,483,647** (matching frozen `InputSchema.MAX_ID` and v2 `EffectiveSchemaV2.MAX_ID`); preserve negative **server gameobject IDs** verbatim. Prohibit floats, zero, booleans and out-of-range values;
  - a **finite-size bounded** string of **one or more** canonical positive decimal ID tokens (each 1–2,147,483,647), separated by exactly comma + space, as emitted by M1's `idList` functions. **Even a single-token string (e.g. `"13154"`) stays a string**, distinct from the numeric `13154`; never coerce or invent target pairs/slots. Reject leading zeros, sign prefixes, empty tokens, controls and noncanonical separators. Validate with Lua 5.1-safe token parsing, not repeated-capture regex syntax. **Maximum string bytes remain under review:** the synthetic 128-objective M1 case in PR #72 challenges a 1,024-byte limit, and the record must satisfy v2 structural checks.
  - Never change signs: `E-GO-SIGN` legitimately emits `server=-60001, questie=60001`. See `ObjectiveRules.lua` lines 259–280 on `335`.
- `explanation` is **required and private-only**, copied verbatim from the same M1 call as the classes. Require printable ASCII (0x20–0x7E), no controls or newline, and a finite reviewed byte limit. **Cap is UNDECIDED**: CosmicScript02 measured a 220-byte maximum over 8,401 currently public M1-supported compiled quests with synthetic near-int32 server targets, and at most four creature or item objectives per quest in that snapshot ([review](https://github.com/CosmicCuddle/N-Questie/pull/71#issuecomment-6213232735)); that is a *dataset measurement*, **not** a universal bound. The synthetic 128-creature case in [PR #72](https://github.com/CosmicCuddle/N-Questie/pull/72) exercises a structurally admissible larger shape and challenges 1,024 bytes, subject to exact-head CI and review. A future cap must be justified by an explicit authenticated-export/input resource policy, without silently truncating or logging private text.
- `unsupportedReasons` must be absent on supported quests; on M1-unsupported quests it is a dense, nonempty, strictly ascending, unique list of **known v2 reason codes**, identical to the authenticated export's `m1Reasons`. Unsupported quests have zero M1 findings because Part 2 never calls M1 for them. Any mismatch rejects the complete batch, never defaults silently.
- **Reject any `R-MALFORMED` finding before constructing private results.** Frozen M1 embeds `server.problems` (which can include raw input-derived values) in that rule's explanation. In the intended M2.3 path the full frozen `InputSchema.Validate` and v2 structural checks must already have rejected that input. Treat a surviving `R-MALFORMED` as an internal validation breach: whole-batch `REJECTED_MALFORMED_INPUT`, fixed-code-only stderr, no private content or partial bundle. Do not store or reformat its explanation.

## 3A. Proposed resource contract — explicit M2.3 boundary, NOT an existing v2 limit

**Recommendation for independent review, not an implementation approval.** Existing frozen v1 and v2 validators/exporters are unchanged and their accepted data shapes are **not** retroactively narrowed. These would be *additional M2.3 private-report preflight and output limits* after authenticated input checking, independently of the general v2 structural schema. A valid v2 quest above the proposed ceiling remains valid v2 data but is **not reportable under this M2.3 profile** without a separately reviewed higher resource policy. Never silently skip the quest, trim objectives or truncate findings.

| Private M2.3 proposed ceiling | Value / check |
|---|---|
| Authenticated full v2 export bytes before parsing | 64 MiB maximum (the current Stage A2 baseline was ~2.37 MB); preserve checksum/provenance verification, and fail closed before creating private output |
| Selected supported quest: creature objectives | 512 entries maximum |
| Selected supported quest: item objectives | 512 entries maximum |
| Selected supported quest: other ordinary objectives together | 2,048 entries maximum; v2 reputation remains at most one under its own validator |
| Selected supported quest: nested refs, kill-credit IDs, source-item lists | A finite combined 4,096-entry budget, across extras/references/kill-credit target IDs/required source items; count before M1; no unbounded nested walk |
| Single original M1 set-reference string | 8 KiB maximum, retaining all delimiters and the string type |
| Single original M1 `explanation` | 16 KiB maximum, printable ASCII; fail closed on the full original bytes, never truncate |
| One quest's collected private findings, including references and explanations | 256 KiB maximum; enforce incrementally, before appending to a full report |
| Entire serialized single private bundle-v2 | 64 MiB maximum; enforce an incremental prepublication byte budget and independently check exact serialized bytes/read-back |

**Why these suggested numbers?** Frozen `ObjectiveRules.lua` creates decimal set tokens from positive IDs of at most 10 bytes and separators of exactly 2 bytes, so an `n`-token set string uses at most `12*n - 2` bytes. With 512 entries the largest creature/item Questie set string is **6,142 bytes**, under the proposed 8-KiB limit. M1's `R-NPC-SET` template has 132 fixed ASCII bytes and at most 46 server-side target bytes (four 10-digit IDs); the corresponding maximum at 512 unmatched Questie creatures is **6,320 bytes**. `R-ITEM-SET` has 124 fixed bytes plus at most 70 server target bytes (six 10-digit IDs), giving **6,336 bytes**. The `C-SCRIPT` creature explanation can also contain the whole unmatched Questie creature list; its static template and one 10-digit server target yield **6,253 bytes** at 512. Other unchanged M1 templates must be independently enumerated before the 16-KiB cap is accepted as covering all authorized findings; `R-MALFORMED` is **always refused**. These calculations are **source-derived limits under this proposed count policy**, not a statement about unlimited v2 inputs.

**Important caveats:** A 128-creature record passes `EffectiveSchemaV2.ValidateQuest` in PR #72, but this proves *structural* admissibility only, not that today's exporter/compiled data produce that record. The earlier measured 220-byte public-data maximum likewise proves nothing about future custom quests. A 64-MiB full-export or output limit is a **new M2.3 safety policy**; exceeding it must return an existing fixed failure code (proposed: `REJECTED_MALFORMED_INPUT` for the M2.3 resource profile) without IDs, private lengths, paths or explanations on stderr. All size/count checks must run before, or incrementally during, allocation/serialization rather than after assembling an unbounded bundle in memory. A file-byte ceiling alone is not a process-memory bound, so a later code review must also inspect worst-case memory use.

**Review question:** Is this 512-entry creature/item + 16-KiB verbatim explanation + bounded bundle profile preferable to a shape-dependent per-record limit derived from authenticated input sizes? Any approved alternative needs a versioned, testable resource policy, explicit ceiling cases and a strict fail-closed/no-leak requirement. This recommendation is **not yet frozen**, and introduces no changes to M1, the v2 exporter, report-v1 or the frozen acceptance suites.

## 4. Correspondence and integrity

**Production generation gate:**
1. Validate the whole input, v2 full coverage, status/reason pairing and trusted-export provenance using previously approved checks. Never accept a file only because its schema is valid.
2. Call unchanged `M1.Compare` **once per M1-supported selected quest**. Preserve both summary classes and private ordered findings from that *same* successful invocation. Never re-run M1 solely for report serialisation.
3. Produce report-v1, findings-v1 and aggregate-v1, with exactly matching selected ID sets. Per selected quest, `row.m1Classes[i]` must equal `findings[questId].m1Findings[i].class` in count and order. For unsupported quests both are empty.
4. Validate all members, external-export correspondence for `unsupportedReasons`, privacy boundaries, and bundle-v2 closed schema **before any write**. Include the full findings member, both other members, provenance and `leftoverTempCount` in the new versioned bundle's integrity mechanism; do **not** reuse the frozen bundle-v1 digest unchanged.
5. Publish at most **one private no-clobber bundle**, with the approved pre/post-publication error contract; no automatic deletion of legacy temp files and no unsupported durability claims.

**Validation limits:** a standalone read-back of a bundle can check internal schema and integrity. It cannot independently re-prove the bundled unsupported reasons came from an authentic external export unless that export is separately present and re-verified. A bundle digest alone is not proof of historical authenticity or successful publication. Document this distinction clearly.

## 5. Proposed additional public/synthetic acceptance cases

These are **candidate design tests** beyond the separately agreed production baseline of 50 tests and 28 mutants. They are **not counted as implemented or passed**.

| ID | Synthetic case | Required result |
|---|---|---|
| PF01 | M1-supported quest, no findings | Empty private list; `NEEDS_MANUAL_REVIEW`, never CONFIRMED (B6) |
| PF02 | Two `C-UNKNOWN` findings with identical kind/class/rules but different explanations | Preserve both and original order; no deduplication |
| PF03 | Unmatched creature set strings `"60001, 60002"` / `"60003, 60004"` | Exact round-trip; reject conversion to paired lists |
| PF04 | `E-GO-SIGN` with `server=-60001`, `questie=60001` | Accepted with negative server sign intact |
| PF05 | Supported quest with absent `server` or `questie` side | Preserve omission; never fabricate a target |
| PF06 | M1-unsupported v2 quest with one or more sorted reason codes | Report row EXPORTED, `m1Supported=false`, no report reasons, private `unsupportedReasons` matches v2 |
| PF07 | Unsupported reason mismatch, reorder, extra, duplicate or present on supported quest | Fail closed, no publication |
| PF08 | Missing, duplicate, unselected or out-of-order quest/finding entries | Fail closed, no publication |
| PF09 | Drop/reorder findings or alter one finding class without the summary | Class-sequence correspondence fails |
| PF10 | Unknown key, noninteger ref, structured ref, control character or over-bound explanation | Fail closed with fixed code; no private text logged |
| PF11 | Recompute/tamper a private findings payload, engine provenance or leftover count | New bundle integrity validation rejects accidental/tampered inconsistency; never claim a checksum alone authenticates source |
| PF12 | Error from private finding text containing quest IDs or rules | Stderr is fixed code only; aggregate remains counts-only; no private ID, rule, explanation or path leakage |
| PF13 | Selected IDs absent from full v2 export | Agreed whole-batch selection rejection; no fabricated successful absent row |
| PF14 | M1 findings include a class named CONFIRMED_MISMATCH | Preserve *M1 finding class* for triage but final *batch outcome* is not CONFIRMED_* (B6) |
| PF15 | Single-token M1 set reference `"13154"` versus numeric `13154` | Preserve the string representation verbatim; type substitution fails reconciliation |
| PF16 | Synthetic malformed tri-state yields M1 `R-MALFORMED` explanation with input-derived text | Refuse whole batch before any finding is stored or printed; fixed error code only, no bundle |
| PF17 | Selected supported quest with 128 unmatched v2 creatures and >1,024-byte `R-NPC-SET` explanation | Preserve all bytes under the proposed 512/16-KiB policy; no truncation |
| PF18 | Synthetic selected supported quest with 513 creature or item objectives, or an above-budget nested list | Proposed M2.3 resource-profile rejection before M1; original v2 structural validator remains unchanged |
| PF19 | One finding exceeds 16 KiB, quest findings exceed 256 KiB, or bundle/export bytes exceed 64 MiB | Fixed-code full-batch refusal, no private-data stderr/log leakage, no partial publication |

## 6. Approvals and unresolved boundaries

**Maintainer approval required before implementing Part 3's new schema:**
1. New private bundle-v2 contract containing the additional findings member, engine provenance and private-only `leftoverTempCount`.
2. Private-only verbatim M1 `explanation` with a reviewed finite length/character limit and no public/stderr leakage.
3. Existing aggregate-v1 semantics: v2-only selected-subset unsupported reasons stay private and aggregate-v1 reason counts remain zero.

**Independent review still requested:** validate signed negative gameobject references and other possible `server`/`questie` shapes; explanation bound; supported/unsupported correspondence; privacy and test feasibility.

**Never auto-approved:** merges, releases, private 1203 run, server or addon installation, first trusted export commit, shared aggregate, historical frozen-validator changes, or production publishing CLI.

**Review links:**
- [Part 3 contract question](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6212003813)
- [Initial CosmicScript01 proposal](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6212242374)
- [Two format gaps](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6212571008)
- [CosmicScript02 option B recommendation](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6212820170)
- [Signed gameobject correction](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6212872836)
