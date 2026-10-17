# N-Questie M2.3 Part 3 — G2 synthetic oracles and red-test blueprint

**Status: DESIGN / TEST PLAN ONLY; proposed G2 worker acceptance tests NOT IMPLEMENTED or RUN, NOT APPROVED FOR MERGE.** Prepared by CosmicScript01 for independent CosmicScript02 review. This document adds no executable tests or production files. It does not authorise private exports, comparison pilots, trusted allowlist entries, engine/CLI/publisher implementation, confirmed outcomes, merges, tags, releases, server or addon changes.

**Pinned public/synthetic baseline:** protected `335` = `2be0f6f3001a20242c2fe81cb1915ff18602a4c8` after reviewed #68→#69→#70. Recheck the live ref before implementation. Companion review material: [#71 private contract](https://github.com/CosmicCuddle/N-Questie/pull/71), [#72 shape research](https://github.com/CosmicCuddle/N-Questie/pull/72), [#74 conservative evidence](https://github.com/CosmicCuddle/N-Questie/pull/74), [#76 one-pass architecture](https://github.com/CosmicCuddle/N-Questie/pull/76), [developer boundary discussion](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6219631109). This is a TEST-BLUEPRINT companion, not a replacement contract.

## 1. Why the next tests must be distinct from #72

- #72 tests **frozen v2 and M1 shape facts**, including K=65 structurally acceptable data and exact 766/944/960/877-byte examples. It does *not* impose an M2.3 reporter limit.
- #76 proposes a new **I/O-free private comparison worker**; `M23Batch.Run` already calls M1 once but drops findings. Merely wrapping it and calling M1 again is disallowed.
- G2 tests must initially be **red against the missing new worker**, then move to green when a separately reviewed G3 implementation exists. Do not install red required CI tests on protected `335` as if they were passing tests.
- Keep frozen `InputSchema.lua`, `EffectiveSchemaV2.lua`, `ObjectiveRules.lua`, `draft/M23ReportDraft.lua` and current `M23Batch.lua` byte-identical. Do not modify #72's currently PASS-reviewed fixture in order to insert failing G2 tests.

## 2. Controlled test loader, without a production override

A future synthetic-only G2 spec may intercept `dofile` **only during the test's loading of the new worker**, matching the exact relative path `tools/validation/ObjectiveRules.lua`. The worker MUST load M1 at module load time with this exact path; a lazy/different-path import bypasses the spy and must make the one-call test fail. Use the original `dofile` for all other modules, wrap the returned M1 module in a *separate table*, intercept only `Compare`, and restore `_G.dofile` immediately even if the load fails. This narrow replacement is valid only in single-threaded, test-controlled module loading; do not call unrelated modules during it. Load unmodified `M23Batch.lua` for differential tests **after** restoration so its own M1 dependency is not counted.

Lua 5.1-compatible illustrative test harness (not committed as executable test):

```lua
local original = dofile
local calls = 0
_G.dofile = function(path)
    local module = original(path)
    if path ~= "tools/validation/ObjectiveRules.lua" then return module end
    local wrapper = {}
    for k, v in pairs(module) do wrapper[k] = v end
    wrapper.Compare = function(...)
        calls = calls + 1
        return module.Compare(...)
    end
    return wrapper
end
local ok, Worker = pcall(original, "tools/validation/M23PrivateFindings.lua")
_G.dofile = original  -- always restore, including on load failure
assert(_G.dofile == original, "test loader failed to restore global dofile")
assert(ok, "synthetic worker load failed")
-- Load baseline M23Batch only now, after restoration, for independent comparison.
-- Calls are asserted on synthetic inputs; Worker must not expose injection API.
```

For a deliberate malformed finding, use a **test-only replacement `Compare`** emitting a distinctive private sentinel in one `R-MALFORMED` finding. Never patch frozen M1, introduce a runtime injection flag, or print the sentinel. After the call, require only `nil, "REJECTED_MALFORMED_INPUT"`. To verify non-disclosure, capture any test-controlled output and assert the sentinel does not appear; never include actual private server material.

## 3. Fixture construction and comparison oracle

Use invented quest IDs, fabricated provenance with correctly matched manifest and pins, and the existing Part 2 synthetic fixture builders as reference. Validate each *nominally valid* v2/manifest fixture through frozen `EffectiveSchemaV2.Validate` and `M23Membership.Check` first. This prevents false "preflight PASS" claims when the fixture actually failed the older validator.

For ordinary synthetic supported cases:

1. Run the existing `M23Batch.Run(server, effective, manifest, pins)` and the proposed worker independently on **deep-cloned** inputs.
2. Assert equal fixed rejection codes for inputs where Part 2 and Part 3 contracts overlap, or exact ordered **comparable field** equality on success (`questId`, `m1Supported`, `m1Classes`, `representationDiff`, outcome before report-v1 normalisation, all five evidence axes). Compare canonical selected ID bytes and total/supported/unsupported counts as applicable. **Reasons require an explicit version mapping:** Part 2 returns `reasons={}` for supported and `reasons=q.m1Reasons` for unsupported; report-v1 `EXPORTED` rows must omit `reasons` entirely under frozen `M23ReportDraft.ValidateReport`. The supported private member must omit `unsupportedReasons`; the unsupported private member preserves the exact sorted `m1Reasons`. Compare those cross-view values, not literal row-table equality. Never weaken report-v1 to carry private unsupported reasons.
3. **Do not pretend** the known `R-MALFORMED` case is equivalent: Part 2 currently reduces it to manual review, while proposed Part 3 must reject the complete batch. Isolate that case and explicitly assert the intended difference.
4. Re-check private findings **against the same call**: per supported quest `#report.m1Classes == #private.m1Findings`; every class and ordinal matches at the same index; duplicate same-class explanations stay separate.
5. Prove no source mutation, no shared-table aliasing, no filesystem/process writes, and no new ability to mark `authenticated` or `publishable` true.

A differential test that merely checks counts or sorted sets is insufficient: order, types, reasons, fixed codes and absence of unapproved fields all matter.

## 4. Planned synthetic acceptance families (all NOT IMPLEMENTED)

| Gate | Fixture and mutation | Required future oracle |
| --- | --- | --- |
| G2-01 | One supported selected quest; one unsupported v2 quest; K=65 rejected supported quest | Count M1 calls **1 / 0 / 0** respectively, without production dependency injection |
| G2-02 | Two identical-class `C-UNKNOWN` findings with distinct explanations | Both retained verbatim in order; classes and ordinals correspond exactly, no dedupe |
| G2-03 | `-60001` and signed **`-2147483647`** server GO references for `E-GO-SIGN`, `R-GO-AS-NPC`, object `C-SCRIPT`, `R-GO-UNPAIRED`; numeric `13154` vs string `"13154"`; absent side; invalid `-2147483648` input | Preserve exact signs, strings and nils; invalid server slot refused before M1 by unchanged `InputSchema` |
| G2-04 | Stubbed `R-MALFORMED` carrying `SYNTHETIC_SECRET_SENTINEL`, **together with** a 1,025-byte explanation or a 193-finding list | `REJECTED_MALFORMED_INPUT` takes precedence over any size/count violation; no private sentinel, partial record or `REJECTED_UNSAFE_OUTPUT` |
| G2-05 | Creature, object, item each 64 / 65, with otherwise valid v2 records | **PROPOSED pending explicit step-10 revision:** 64 passes the resource gate (later checks still apply); 65 refuses before M1, frozen v2 still accepts. The exact fixed code for an otherwise valid K65 is **UNDECIDED**, not automatically `REJECTED_MALFORMED_INPUT` or `REJECTED_UNSAFE_OUTPUT` |
| G2-06 | Combined other ordinary 2048 / 2049; nested 4096 / 4097, with otherwise valid v2 membership | Proposed exact pre-M1 boundary **only after B1's numerical ceilings**, the counter formula, `spawnZones` A/B/C treatment and the **fixed over-limit refusal code** are independently reviewed and approved; no production green/red oracle can assume those choices |
| G2-07 | 192 / 193 synthetic complete findings; 1024 / 1025 explanation and string-ref bytes | Exact threshold handling, no truncation; classify malformed type/content separately from oversized output |
| G2-08 | Printable ASCII containing quote and backslash, plus safe-looking input that encodes larger than raw length | Byte budget counts actual **canonical encoded bytes including escapes**, not Lua `#text` alone |
| G2-09 | 256 KiB −1 / = / +1 complete encoded quest findings record, individually valid fields | Boundary accept/accept/refuse (assuming all other checks pass), not a raw explanation budget |
| G2-10 | 64 MiB −1 / = / +1 complete encoded private bundle | Boundary accept/accept/refuse for the *entire* future bundle-v2, including framing/provenance/integrity; use bounded counting sink where possible |
| G2-11 | v2-only M1-unsupported record with sorted reasons, malformed/duplicate/mismatched reason variants | Report-v1 stays EXPORTED, no public reasons, private reasons exact-match export; aggregate-v1 reason occurrence counts remain zero |
| G2-12 | Explicit duplicate server ID, bad server v1, invalid v2, paired manifest mismatch, absent **FIRST** versus **LAST** selected quest ID | Preserve fixed rejection codes without identifiers/path/explanation. **PROPOSED NEW-WORKER preflight oracle, pending approval:** either nonmember position must refuse the entire batch with `REJECTED_SELECTION_MISMATCH` **before any M1 call**, proven with the positive-controlled M1 loader spy. Do not treat frozen Part 2's late-selection behaviour as a new-worker pass |
| G2-13 | Mutated class/order/ordinal, unknown key, float/zero ref, noncanonical set token, nil/array holes | Reject all unsound private records with fixed code; never "repair" output by guessing |
| G2-14 | Valid structural v1 flags asserting evidence completeness without authenticated per-axis proof | All five evidence axes remain unknown, no CONFIRMED_* report outcome |
| G2-15 | 8,401-style public synthetic coverage and 9,159-ID in-memory fixture (where practical) | Part 2/public output differential **using the explicit reason mapping in §3**, bounded deterministic execution, no real server exports |
| G2-16 | v2 accepts `sourceItemId=2147483648`, mathematically integral doubles above 2^53, and non-finite `sourceItemId`, `spawnZones`, or **M1-unsupported reputation `requiredValue`**; frozen v2 retained | Future Part 3 preflight inspects **all selected records, including M1-unsupported**, refusing non-finite numeric values and out-of-range `sourceItemId` **before M1** with a fixed approved code. Finite, mathematically integral Lua 5.1 numbers in the reviewed range (e.g. `13154.0`) must not be mistaken for forbidden JSON decimal tokens. A proposed encoder must never format `inf` or imprecise >2^53 integers as valid IDs |

| G2-17 | Invented v2-valid **single-reason** cohort fixtures: extra creature reference, extra object reference, reputation, duplicate creature and killCredit-first reordering (five reason types; not 709 private fixtures) | For each: `V2.Validate`, coverage reason/status/pins and `M23Membership.Check` accept the nominal fixture; frozen Part 2 returns `M1_UNSUPPORTED_BY_RULES` and performs **zero** M1 calls for an unsupported selection. Future G3 may preserve private `unsupportedReasons` exactly and omit public report-v1 reasons; no new v1 support or automatic quest correction implied |
| G2-18 | Invented v2-valid **multi-reason** cohort fixtures for all seven public overlap combinations; use genuinely valid frozen-v2 shapes, not manually assigned inconsistent `m1Reasons` | Every synthetic quest is counted **once** as unsupported, while **each** validated reason is retained in the private reason list and counted correctly in the coverage reason-occurrence map; preserve sorted/distinct reasons and exact manifest/pins. Reject missing, duplicated, reordered or injected reasons; compare ordinary Part 2 behavior separately from unimplemented G3 private output |
| G2-19 | Deterministic **aggregate-only** fixture of 12 disjoint cohort counts with a mutation of one combination or one reason occurrence; never import private quest IDs | Reconcile `709 single + 49 multiple = 758 unsupported`, `8401 + 758 = 9159`, and `0 unclassified`; all 12 disjoint buckets sum to 758 and per-reason occurrences reflect overlaps. A one-count mutation must fail. This is a **source aggregate consistency** oracle, not 9,159 individual quest confirmations |

A test that cannot construct a *v2-valid* 2,049/4,097 objective arrangement must use a test-only boundary component/stub, clearly labelled; do not report a frozen-v2 rejection as proof that the **new** M2.3 resource check ran. **Do not implement G2-06's exact nested boundary until the counting formula receives explicit maintainer approval.** Cases impossible or unproved with real frozen M1 under K64 must be labelled **STUBBED**, not represented as observed source behaviour: 193 findings (source-derived estimate ≤160), 1,025-byte per-field explanation/reference (observed theoretical maximum 960/766), 256-KiB findings record, and surviving `R-MALFORMED` after v1 validation (15 tested mutations rejected; not an exhaustive proof). The 64-MiB whole-bundle threshold cannot be asserted until the actual encoder is defined.

## 4a. Public M2.2 coverage cohorts — proposed G2 test order, NO NEW COVERAGE CLAIM

**Source:** protected `335`, `docs/NQ-VALIDATION-M2.2-COVERAGE.md`, compiled **9,159 total = 8,401 v1 representable + 758 v1 unsupported**, with **0 unclassified**. This is an immutable **v1 shape classification at this baseline**, not a count of broken quests, pending quest corrections, or the number of quests actually checked against private server objectives. The M2.3 comparison worker **must not change the frozen v1 coverage counters** just because v2 preserves richer unsupported metadata.

**The twelve disjoint combinations** (the report counts a quest with multiple reasons **once** in the 758, but counts its reason occurrence in every applicable category):

| Public baseline combination | Distinct quests | Fixture lane |
| --- | ---: | --- |
| `EXTRA_CREATURE_REF` only | 317 | Single reason |
| `EXTRA_OBJECT_REF` only | 205 | Single reason |
| `REPUTATION_OBJECTIVE` only | 175 | Single reason |
| `DUPLICATE_CREATURE` only | 6 | Single reason |
| `KILLCREDIT_FIRST_REORDER` only | 6 | Single reason |
| **Single-reason subtotal** | **709** | Five synthetic shape families |
| `EXTRA_CREATURE_REF` + `EXTRA_OBJECT_REF` | 31 | Multiple reasons |
| `EXTRA_CREATURE_REF` + `KILLCREDIT_FIRST_REORDER` | 7 | Multiple reasons |
| `EXTRA_OBJECT_REF` + `REPUTATION_OBJECTIVE` | 4 | Multiple reasons |
| `EXTRA_OBJECT_REF` + `KILLCREDIT_FIRST_REORDER` | 3 | Multiple reasons |
| `EXTRA_CREATURE_REF` + `REPUTATION_OBJECTIVE` | 2 | Multiple reasons |
| `DUPLICATE_CREATURE` + `EXTRA_CREATURE_REF` | 1 | Multiple reasons |
| `DUPLICATE_OBJECT` + `EXTRA_CREATURE_REF` | 1 | Multiple reasons |
| **Multiple-reason subtotal** | **49** | Seven synthetic shape families |
| **Unsupported total** | **758** | **709 + 49** |

**Acceptance sequence proposed for G2-17 through G2-19:**

1. Construct **one or more invented, structurally valid examples per one of the five single and seven multiple reason-combination shapes**; do not copy private IDs or simulate a 709/49 sample of actual quests. Confirm `V2.Validate`, `V2.ExpectedM1`, `M23Membership.Check`, closed reason ordering, manifest aggregate and full-dataset pin consistency *independently before* a new-worker assertion. A fixture rejected by the frozen v2 validator is **not evidence** that a new Part 3 gate worked.
2. For v2-only M1-unsupported selections, test the existing Part 2 skip path and zero `M1.Compare` calls with the temporary, restored test-loader spy. Its current internal `reasons` match the validated v2 `m1Reasons`; **report-v1 EXPORTED rows must omit `reasons`**, while a future *separately authorised* private findings format may retain `unsupportedReasons`. Do not move private reasons into counts-only public aggregate-v1.
3. Check that `EXTRA_CREATURE_REF + EXTRA_OBJECT_REF` does **not** become two quests. Preserve every reason exactly once, maintain closed sorted reason lists and separately count reason **occurrences**. Use mutations of a reason, status, total or aggregate entry to prove the test detects disagreement. Overlap cohorts must not force a v1 representability change.
4. Preserve five **unknown** evidence axes, no claim of `CONFIRMED_*` from frozen v1 or coverage alone, and no guessed correction/marker, real private export, world DB modification or installed addon change. Signed GO, malformed M1 findings and byte-level/private-output assertions remain distinct future G2/G3 gates.

**Order rationale:** prioritise the 697 quests represented by the three largest one-reason *public cohorts*, but do not mistake them for **all** single-reason quests: another 12 have duplicate-creature or killCredit ordering alone. The remaining 49 genuinely have overlapping reasons; the cohort-based **fixture sequence** may help reach proof of structural behavior but does **not** increase 8,401/9,159 v1 representability or resolve 758 possible in-game discrepancies. All of these test fixtures are **proposals, NOT IMPLEMENTED/TESTED here**.

## 4b. G2-12 paired preflight failures — public Part 2 oracle, proposed Part 3 test

**Existing behaviour VERIFIED on synthetic-only draft #83 commit `7cea553e1cb72ddcc2672f69d07cb72f6717828f` (6/6 exact-head CI). This is NOT a test of G3 and NOT an approved new error-order policy.** These are observed rejection priorities in the frozen `M23Batch.Run` / `M23Membership.Check` boundary. The separately approved 14-code future Part 3 CLI vocabulary remains authoritative for its own public stderr contract; historical nine-code draft stderr validation is not reusable.

For each row, make *three* independent calls with fresh invented, fully snapshotted inputs: fault A alone, fault B alone, then both. First assert that **each independent fault really reaches its distinct expected fixed code**, rather than producing a malformed-fixture false positive. Only then assert that both faults return the earlier existing Part 2 code. Assert `nil` output and no mutations to the server selection, effective v2, manifest, or pins on every refusal. No validator's diagnostic text, quest ID, input path or finding explanation may enter the public rejection.

| Independently verified fault A | Independently verified fault B | Existing Part 2 combined refusal |
| --- | --- | --- |
| Duplicate selected server ID | Malformed signed GO slot (`-2147483648`) | `REJECTED_DUPLICATE_ID` |
| Malformed signed GO slot | Unpaired manifest provenance | `REJECTED_MALFORMED_INPUT` |
| Invalid v2 `sourceItemId=-1` | Unpaired manifest provenance | `REJECTED_MALFORMED_INPUT` |
| Unpaired manifest provenance | Incorrect aggregate reason count | `REJECTED_PAIRING` |
| Incorrect aggregate reason count | Missing FIRST selected quest | `REJECTED_MANIFEST_INCOMPLETE` |

**Important scope: two pin gates, NOT a universal ranking of refusal-code names.** Each table case assumes otherwise-valid external count pins and unrelated shapes. Frozen `M23Membership.Check` checks `pins.questCount == pins.supportedCount + pins.unsupportedCount` **first**, before v2 validation and pairing. For example, `questCount=4`, `supportedCount=2`, `unsupportedCount=1` is **internally inconsistent**, so `REJECTED_MANIFEST_INCOMPLETE` wins even when v2 is malformed or provenance unpaired. In contrast, `questCount=4`, `supportedCount=2`, `unsupportedCount=2` is internally consistent but **wrong for a three-quest dataset**; that check occurs **after** v2 validation and pairing, so simultaneous malformed v2 returns `REJECTED_MALFORMED_INPUT` and simultaneous unpaired provenance returns `REJECTED_PAIRING`. The later rejection may arise at `M23Membership.Check`'s quest-count comparison (line 78), coverage-aggregate reconciliation (lines 83–85), or final supported/unsupported recount (line 132), **all after** frozen-v2 validation and provenance pairing. The outer `M23Batch.Run` duplicate-ID and server-v1 gates precede either pin gate. These are observed *conditional Part 2 gate-order facts*, not a global code hierarchy or an approved new G3 policy. CosmicScript02 independently demonstrated the late-gate distinction when reviewing #83 `27bd48b`; the extended synthetic oracle is proposed/tested separately on that draft. Any future contract must specify exact gates and prerequisites before approving new worker behaviour.

**Separate positional oracle, not proved by the table above:** the frozen Part 2 comparator checks selected quest membership inside its loop. With a **positive-tested** M1 loader spy, invented selection `{4,2,1}` (missing first) refuses with **0** M1 calls, while `{3,2,4}` (missing last) refuses with **1 earlier** M1 call. Both return `REJECTED_SELECTION_MISMATCH`. A future proposed G3 **batch-global selection preflight** would require zero M1 calls in BOTH positions; this stricter timing requirement and any change in precedence are **pending G1 maintainer approval**, not claims of a currently implemented worker. Tests should distinguish externally visible code/result equivalence from internal M1 call-order equivalence.

**G2 red-test acceptance proposal:** after G1 fixes the future pure worker's exact error precedence, independently replay approved paired-fault fixtures with the positive-controlled spy and check that no M1 is called on complete-batch preflight refusals. Do **not** simply copy the Part 2 ordering above into the new worker or reopen the already approved CLI stderr vocabulary. If G1 specifies a different precedence, document the deliberate mapping and test that mapping exactly. Keep all fixtures fabricated and all working branches DRAFT.

## 5. Proposed resource-counter interpretation — REVIEW OPEN, NOT AUTHORISED

The maintainer approved **K=64 each** for ordinary `creature`, `object`, `item` and retained the frozen **16-MiB input** cap. The **2,048 combined other ordinary** and **4,096 nested** ceilings were **PROPOSED recalculations, not verified owner approvals**; see [D4's required reviewed revision](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6214484105), [#71's proposed values](https://github.com/CosmicCuddle/N-Questie/pull/71#issuecomment-6214588261) and the separate **B1 decision in #87**. The exact nested formula is likewise unapproved.

Candidate interpretation to submit for review:
- Count each `q.objectives` entry once according to its `kind`. `reputation + killCredit + spell` contribute to **other ordinary**, not creature/object/item. Under frozen v2, reputation has a separate one-entry maximum.
- Nested total candidate, counting structures that reach M1: `#q.requiredSourceItems + #q.extraObjectives + SUM(#e.refs) + SUM(#killCredit.ids)`. This follows CosmicScript02's verified adapter review: `rootId` is a scalar already bounded by the other-ordinary killCredit count; counting it again could double-charge it. `m1Reasons` is a closed, deduplicated status-code set. `sourceItemId` and spell `itemSourceId` are separately bounded scalar attributes rather than nested arrays. **This is still a proposal, not the approved rule.**
- **Maintainer choice still open — `spawnZones`:** frozen `EffectiveSchemaV2.lua` checks a dense integer list but has no small list limit. The adapter does **not** forward `spawnZones` to M1, so excluding zones best matches the immediate M1-allocation objective; including `+ SUM(#e.spawnZones)` imposes an additional **selected-quest policy limit**, but cannot lower parse/validate memory cost because `M23Membership.Check` has already validated the **entire** v2 export under the frozen 16-MiB input ceiling. One extra objective with 4,096 zones counts as **1** under the M1-reaching formula, versus **4,097** under the inclusive formula. Do not silently choose either rule in G2 code. Count limits apply **per selected quest**, including M1-unsupported quests for consistent refusal semantics, after validated v2 membership and before M1.
- After v2/membership checks, the **proposed (not approved)** whole-batch pre-M1 gate would refuse a selected quest over any resource limit; equality passes the count gate only. **D5:** this execution order still requires an express maintainer amendment to #42 step 10. **D6:** the fixed refusal code for otherwise valid over-limit K65/2,049-other/4,097-nested records remains **UNDECIDED** between existing `REJECTED_MALFORMED_INPUT` and `REJECTED_UNSAFE_OUTPUT`; do not hardcode either before maintainer approval. Separately propose refusing `sourceItemId` outside **0..2147483647**, and selected non-finite numeric values, without altering frozen v2. Unknown/unsafe numeric content must never reach a future output encoder. This adds no authorisation.

## 6. Exact private encoded-budget oracle — REVIEW OPEN

Budget equations must be applied to the **final canonical output format**, not an imagined JSON or Lua `%q` encoding. The future codec/schema review must fix and test: UTF-8/ASCII rules, escaping, field order or canonical order, delimiters, newline policy, numbers, null/omitted fields, integer representation, version framing, integrity representation, and the scope of each record.

- **Per quest:** size of its entire encoded private findings entry, including quest-ID/key/framing bytes; ceiling **256 × 1024 = 262144 bytes**.
- **Whole bundle:** size of its actual complete bundle-v2 encoding (report-v1, aggregate-v1, private findings, provenance, `leftoverTempCount`, version and integrity/framing); ceiling **64 × 1024 × 1024 = 67108864 bytes**.
- **Input:** the separate frozen **16-MiB** bound remains unchanged.
- **Fail closed with specified precedence:** after M1, detect `R-MALFORMED` first (`REJECTED_MALFORMED_INPUT`), then malformed field/type/closed-schema failures (also malformed), **then** purely over-budget valid records (`REJECTED_UNSAFE_OUTPUT`). An unknown key should not be classified as merely oversized. No partial bytes returned or published.
- A `192 × (1024 + 2×1024)` approximation is about 576 KiB before other fields, so 192 findings alone do **not** guarantee the 256-KiB quest budget.
- To avoid allocating a 64-MiB test string for every CI case, test a deterministic incremental counter/sink against **known canonical encoder output** using small exact byte fixtures plus a bounded overflow test. This cannot replace at least one end-to-end encoding contract test. The existing frozen `EffectiveSchemaV2.Canonical` is **NOT** an approved Part 3 codec: Lua 5.1 `string.format("%d", math.huge)` may silently render an invalid huge negative integer. Future encoder must reject non-finite, imprecise or out-of-profile numbers *before* formatting and must prove the exact encoded byte counts.

## 7. Future gates and acceptance discipline

**G1 (contract):** first approve/amend B1 numerical thresholds, then closed schemas/encoding, error precedence and counter formula after CosmicScript02 exact-head review and explicit maintainer decision. **D5/D6 are explicit outstanding decisions:** #42 [6192683832 step 10](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6192683832) currently approves unchanged `M23Batch.Run` selection/M1 ordering, so a new zero-M1 global preflight requires the maintainer to **expressly supersede/amend** that step before G3/CLI implementation. For a structurally valid K65/2,049-other/4,097-nested record, this blueprint must not decide whether `REJECTED_MALFORMED_INPUT` or `REJECTED_UNSAFE_OUTPUT` is returned; both existing-code alternatives must be resolved in the approved contract, without adding a fifteenth code. Do not silently choose policy in Lua.

**G2 (synthetic red tests):** separate draft, invented data only. The first regression checks must demonstrate the single-call spy, Part 2 differential including fixed rejection codes, K65 pre-M1 refusal (**fixed code remains D6-UNDECIDED; whole-batch step order requires D5 amendment**), private secret refusal and encoded-byte budget boundaries. Red-test evidence is not green CI; do not merge failing mandatory jobs.

**G3 (new pure worker):** only after G1/G2 review, implement a separately scoped pure candidate worker, no I/O, preserved original findings, no mutation of Part 2/frozen files. Complete independent exact-head review, mutations and full synthetic suite.

**Always-on evidence invariant:** the five axes remain UNKNOWN at every G2/G3/G4 stage unless a *separately authenticated and reviewed* per-axis source is approved. No automatic CONFIRMED_*.

**Separate later gate:** any trusted CLI, private pilot, integrity publisher, real export, allowlist pin, release, protected integration or addon/server installation requires separate maintainer authorisation and review. Neither passing synthetic tests nor this document confers it.

## 8. Questions specifically for CosmicScript02

1. Is the isolated worker + test-loader spy feasible under the current Lua 5.1 loading pattern without touching production dependencies?
2. What should the exact **2,048 other / 4,096 nested** formula count? Include/exclude `spawnZones`, `rootId`, and clarify if a boundary example is actually v2-valid and M1-supported.
3. **Reviewed recommendation:** `R-MALFORMED` → malformed type/shape → `REJECTED_UNSAFE_OUTPUT`. Does the maintainer approve making this precedence normative before G2 code?
4. Which future encoder format should determine the exact 256-KiB and 64-MiB encoded-byte oracles? Do not approve threshold arithmetic as format correctness.
5. Which candidate G2 cases would be logically impossible with real frozen M1 and must be explicitly labelled **stubbed**?

**Review verdict requested: PASS / CHANGES REQUESTED / NOT TESTED on the exact PR head. This is design-only and must remain DRAFT/unmerged.**
