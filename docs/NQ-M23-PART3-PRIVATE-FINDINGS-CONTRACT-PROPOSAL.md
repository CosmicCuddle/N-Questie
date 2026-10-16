# N-Questie M2.3 Part 3 — private findings contract (review proposal)

**Status: DESIGN ONLY — D1–D4 and K=64 APPROVED BY MAINTAINER; IMPLEMENTATION NOT PRESENT.** The [recorded 2026-10-16 decision](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6214484105) approves the private-report design and separate synthetic-only implementation preparation, subject to code review. It does **not** authorise a CLI/export allowlist entry, private pilot, publication, merge of this PR, release or installation.

**Foundation checkpoint (2026-10-16):** protected `335` reached `bec920309252f8953b5db94731d7860f6b4d1118` by merging [Part 1 PR #68](https://github.com/CosmicCuddle/N-Questie/pull/68); the exact old baseline `41aa84b56f38adbea09a89c32af1e9ab4c4b9d09` is preserved on `backup/nq-335-pre-m23-foundations-2026-10-16`. [Part 2 PR #69](https://github.com/CosmicCuddle/N-Questie/pull/69) has a separate new-baseline integration draft, `60a48aa41ca692bcefe7c4c9732099c968d93124`, awaiting its own integration-head review. Verify live branch SHAs before using this historical checkpoint. This document changes neither the frozen validators nor `335`.

## 1. Problem and design choice

The v2-only Part 2 pure comparison already calls frozen M1 but retains only a finding's `class`; it discards `kind`, `rules`, target references and `explanation`. The frozen `M23ReportDraft` report-v1 row is closed to those details. A summary alone cannot explain which quest objective merits investigation.

**Maintainer-approved option B (design contract only; no reporter implemented here):**
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
  - a **finite-size bounded** string of **one or more** canonical positive decimal ID tokens (each 1–2,147,483,647), separated by exactly comma + space, as emitted by M1's `idList` functions. **Even a single-token string (e.g. `"13154"`) stays a string**, distinct from the numeric `13154`; never coerce or invent target pairs/slots. Reject leading zeros, sign prefixes, empty tokens, controls and noncanonical separators. Validate with Lua 5.1-safe token parsing, not repeated-capture regex syntax. **Initial maximum is 1,024 string bytes under the approved K=64 M2.3 preflight policy in §3A.** The synthetic 128-objective M1 case in PR #72 remains structurally admissible v2 research, but must be **rejected by the future M2.3 reporter before calling M1**, because it exceeds 64 objectives. No string may be truncated.
  - Never change signs: `E-GO-SIGN` legitimately emits `server=-60001, questie=60001`. See `ObjectiveRules.lua` lines 259–280 on `335`.
- `explanation` is **required and private-only**, copied verbatim from the same M1 call as the classes. Require printable ASCII (0x20–0x7E), no controls or newline, and a finite reviewed byte limit. **Approved initial M2.3 cap is 1,024 explanation bytes** on supported selected quests that pass §3A's **K=64 preflight**. The 220-byte maximum observed over 8,401 current public supported quests with synthetic near-int32 server IDs ([independent research](https://github.com/CosmicCuddle/N-Questie/pull/71#issuecomment-6213232735)) is only a dataset snapshot, **not** the cap's proof. Synthetic 128/512-target tests in [PR #72](https://github.com/CosmicCuddle/N-Questie/pull/72) demonstrate longer frozen M1 text is possible but correspond to **future M2.3 pre-M1 resource refusals**, not truncation. §3A derives the 944/960/877-byte worst-case growing templates under K=64; reject any over-cap finding without logging private text.
- `unsupportedReasons` must be absent on supported quests; on M1-unsupported quests it is a dense, nonempty, strictly ascending, unique list of **known v2 reason codes**, identical to the authenticated export's `m1Reasons`. Unsupported quests have zero M1 findings because Part 2 never calls M1 for them. Any mismatch rejects the complete batch, never defaults silently.
- **Reject any `R-MALFORMED` finding before constructing private results.** Frozen M1 embeds `server.problems` (which can include raw input-derived values) in that rule's explanation. In the intended M2.3 path the full frozen `InputSchema.Validate` and v2 structural checks must already have rejected that input. Treat a surviving `R-MALFORMED` as an internal validation breach: whole-batch `REJECTED_MALFORMED_INPUT`, fixed-code-only stderr, no private content or partial bundle. Do not store or reformat its explanation.

## 3A. Maintainer-approved initial M2.3 resource policy — K=64 (DESIGN / NO ENGINE YET)

**Owner decision:** [2026-10-16 maintainer approval](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6214484105) chooses **K=64 per creature, object and item objective kind** (rather than the former K=512 proposal). The existing frozen v1/v2 validators and exporter are unchanged. A structurally valid v2 record over K=64 remains valid v2 data but is **not processable by this initial M2.3 private reporting profile**. Reject an over-budget *whole selected batch*; never skip a quest, silently truncate explanations or repurpose a report-v1 status. These exact limits are **approved design policy**; implementation is not present in this PR, and its code/tests need independent review.

| Initial private M2.3 profile | Approved initial threshold / behaviour |
|---|---|
| Full authenticated effective v2 input bytes | **Inherit frozen 16 MiB maximum** (`InputSchema.MAX_BYTES`, also respected by `ExportV2.lua`). No new export reader allowance; independently verify checksum/provenance |
| Ordinary objective entries of each kind: creature | **64** maximum |
| Ordinary objective entries of each kind: object | **64** maximum |
| Ordinary objective entries of each kind: item | **64** maximum |
| Other ordinary objective entries combined | **2,048** maximum (subject to frozen v2 structural validation; reputation at most one under its own validator) |
| Nested extras, refs, kill-credit IDs, required source-item entries | **4,096** combined maximum; count as bounded input before invoking M1 |
| Single original M1 numeric set-reference STRING | **1,024 bytes** maximum; must preserve comma-space spelling and string type even when a single ID |
| Single original M1 `explanation` | **1,024 bytes** maximum of verbatim printable ASCII; no sanitisation, rewriting or truncation |
| One selected quest's M1 finding entries | **192** maximum, checked after the single bounded M1 call, before creating any private member |
| All serialised private findings for one selected quest | **256 KiB** maximum of *complete encoded records*, including all field and delimiter overhead; incremental, whole-batch refusal on overflow |
| Complete serialised private bundle-v2 | **64 MiB** maximum, an **output-only** amplification/budget ceiling (4 × inherited 16-MiB v2 input). It is **not** a guarantee that every otherwise-valid selection can be published. Independently verify exact output bytes/read-back before publication |

**Source-derived text bounds under K=64:** Frozen `ObjectiveRules.lua` encodes each positive int32 target using at most 10 digits and exactly `, ` between targets, so the longest 64-target string has `12*64-2 = 766` ASCII bytes. With four near-max-int32 server creature slots, `R-NPC-SET` yields at most **944 bytes** (`176+12*64`); with six server item slots, `R-ITEM-SET` yields at most **960 bytes** (`192+12*64`). A scripted-creature `C-SCRIPT` with 64 Questie targets is at most **877 bytes** (frozen template: `109+12*64`). These are below the **1,024-byte** private explanation cap without truncation. The prior #72 synthetic 128/512-target cases prove that *larger v2 structures and M1 explanations are possible*; under **K=64** they are now explicit expected **pre-M1 profile refusals**, not acceptable private explanations.

**Source-derived count bound:** The unchanged M1 `ObjectiveRules.lua` has 29 finding call sites; only three explanation templates embed ID lists. With a max of 64 Questie creature + 64 item targets and frozen server slots, a conservative upper bound on its total emitted findings is **160**:
`3` availability, `1` quantity, `4` first-pass npc/gameobject, `4` later unmatched creature resolution, `64` Questie creature unmatched, `1` creature set, `6` first-pass required-item, `6` subsequent unmatched server item, `64` Questie item unmatched, `1` item set, `4` source item, `2` ordering. This deliberately overcounts mutually exclusive branches. The separate **192-finding refusal ceiling** has margin above 160. Max 64+64 Questie-only objectives yields **128** `R-*-UNPAIRED` findings; four scripted server creature slots can repeat a 877-byte explanation four times (**3,508** bytes). The **256-KiB complete encoded record budget remains independently enforced** rather than presumed from the number of text bytes; under worst-case future encoding overhead, a structurally valid selection might still be refused with a fixed code. Never silently discard fields.

**Evaluation order and codes:** Verify authenticity and all frozen v2 schema/status/selection checks first. **Preflight objective and nested resource counts before calling M1** so its output allocation is bounded. Call frozen `M1.Compare` **once** for a selected supported quest; only after that call can the reporter check the returned findings count, explanation/reference bytes and field types. Unexpected `R-MALFORMED` always rejects the whole batch before storing or printing text. Input/preflight failure returns existing **`REJECTED_MALFORMED_INPUT`**; oversized output/serialised private bundle returns **`REJECTED_UNSAFE_OUTPUT`**, with fixed-code-only stderr and no partial private publication. Incrementally encode/check a single quest, then the entire bundle, rather than accumulating unbounded output in memory. The 16-MiB authenticated input cap and 64-MiB final-output cap are different controls.

**Review boundary:** Owner approval selects K=64 and the initial bounded-private-output direction; **this document still needs exact-head review and corresponding synthetic threshold tests before implementation**. No code change to frozen validators, reporter schema/engine, addon runtime, exporter trust allowlist, private server, or report-v1/aggregate-v1 is authorised by this document alone.

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
| PF17 | K=64 supported quest with 64 unmatched v2 creatures/items; worst-case `R-NPC-SET`, `R-ITEM-SET`, scripted `C-SCRIPT` | Full original explanations ≤1,024 bytes, ref strings ≤1,024; type preserved; no truncation |
| PF18 | Exactly 64 versus 65 ordinary creatures, objects and items, plus 2,048/2,049 other ordinary entries and 4,096/4,097 nested entries | M2.3 K=64/combined counts accepted only when otherwise valid, and over-limit input refused **before** M1; frozen v2 validity is not changed |
| PF19 | Up to 128 individual `R-*-UNPAIRED` findings; four 877-byte `C-SCRIPT` explanations; synthetic findings 192/193; over-1,024 text/reference, quest >256-KiB encoded findings or bundle >64-MiB | Count all records and their complete encoding, never explanation bytes alone; output overrun fixed-code batch rejection without private leak or partial publication |
| PF20 | Frozen v2 structurally-valid 65, 128, 512 and 513 creature/objective shapes (as applicable), including previously researched long M1 text | New M2.3 profile rejects >64 before M1, while unchanged frozen v2 structural acceptance and previous research tests remain valid |

## 6. Approvals and unresolved boundaries

**Maintainer decisions recorded on 2026-10-16:** [D1, D2, D3 and initial D4/K=64 are APPROVED](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6214484105):
1. New private bundle-v2 contract containing the additional findings member, engine provenance and private-only `leftoverTempCount`.
2. Private-only original M1 `explanation` with approved initial 1,024-byte length/ASCII restriction, exact ref typing and no public/stderr leakage.
3. Frozen aggregate-v1 semantics: v2-only selected-subset unsupported reasons stay private and aggregate-v1 reason counts remain zero.
4. M2.3-only K=64 resource policy and fail-closed private report budgets in §3A. This is an approved **design choice**, not a passing implementation, merge, private run or release authorization.

**Independent review still requested:** validate signed negative gameobject references and other possible `server`/`questie` shapes; explanation bound; supported/unsupported correspondence; privacy and test feasibility.

**Never auto-approved:** merges, releases, private 1203 run, server or addon installation, first trusted export commit, shared aggregate, historical frozen-validator changes, or production publishing CLI.

**Review links:**
- [Part 3 contract question](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6212003813)
- [Initial CosmicScript01 proposal](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6212242374)
- [Two format gaps](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6212571008)
- [CosmicScript02 option B recommendation](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6212820170)
- [Signed gameobject correction](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6212872836)
