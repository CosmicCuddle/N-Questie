# N-Questie M2.3 Part 3 — G2 synthetic oracles and red-test blueprint

**Status: DESIGN / TEST PLAN ONLY; NOT IMPLEMENTED, NOT RUN, NOT APPROVED FOR MERGE.** Prepared by CosmicScript01 for independent CosmicScript02 review. This document adds no executable tests or production files. It does not authorise private exports, comparison pilots, trusted allowlist entries, engine/CLI/publisher implementation, confirmed outcomes, merges, tags, releases, server or addon changes.

**Pinned public/synthetic baseline:** protected `335` = `2be0f6f3001a20242c2fe81cb1915ff18602a4c8` after reviewed #68→#69→#70. Recheck the live ref before implementation. Companion review material: [#71 private contract](https://github.com/CosmicCuddle/N-Questie/pull/71), [#72 shape research](https://github.com/CosmicCuddle/N-Questie/pull/72), [#74 conservative evidence](https://github.com/CosmicCuddle/N-Questie/pull/74), [#76 one-pass architecture](https://github.com/CosmicCuddle/N-Questie/pull/76), [developer boundary discussion](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6219631109). This is a TEST-BLUEPRINT companion, not a replacement contract.

## 1. Why the next tests must be distinct from #72

- #72 tests **frozen v2 and M1 shape facts**, including K=65 structurally acceptable data and exact 766/944/960/877-byte examples. It does *not* impose an M2.3 reporter limit.
- #76 proposes a new **I/O-free private comparison worker**; `M23Batch.Run` already calls M1 once but drops findings. Merely wrapping it and calling M1 again is disallowed.
- G2 tests must initially be **red against the missing new worker**, then move to green when a separately reviewed G3 implementation exists. Do not install red required CI tests on protected `335` as if they were passing tests.
- Keep frozen `InputSchema.lua`, `EffectiveSchemaV2.lua`, `ObjectiveRules.lua`, `draft/M23ReportDraft.lua` and current `M23Batch.lua` byte-identical. Do not modify #72's currently PASS-reviewed fixture in order to insert failing G2 tests.

## 2. Controlled test loader, without a production override

A future synthetic-only G2 spec may intercept `dofile` **only during the test's loading of the new worker**, matching the exact relative path `tools/validation/ObjectiveRules.lua`. Use the original `dofile` for all other modules, wrap the returned M1 module in a *separate table*, intercept only `Compare`, and restore `_G.dofile` immediately even if the load fails.

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
assert(ok, "synthetic worker load failed")
-- Calls are asserted on synthetic inputs; Worker must not expose injection API.
```

For a deliberate malformed finding, use a **test-only replacement `Compare`** emitting a distinctive private sentinel in one `R-MALFORMED` finding. Never patch frozen M1, introduce a runtime injection flag, or print the sentinel. After the call, require only `nil, "REJECTED_MALFORMED_INPUT"`. To verify non-disclosure, capture any test-controlled output and assert the sentinel does not appear; never include actual private server material.

## 3. Fixture construction and comparison oracle

Use invented quest IDs, fabricated provenance with correctly matched manifest and pins, and the existing Part 2 synthetic fixture builders as reference. Validate each *nominally valid* v2/manifest fixture through frozen `EffectiveSchemaV2.Validate` and `M23Membership.Check` first. This prevents false "preflight PASS" claims when the fixture actually failed the older validator.

For ordinary synthetic supported cases:

1. Run the existing `M23Batch.Run(server, effective, manifest, pins)` and the proposed worker independently on **deep-cloned** inputs.
2. Assert equal fixed rejection codes for inputs where Part 2 and Part 3 contracts overlap, or exact ordered public row field equality on success (`questId`, `m1Supported`, `m1Classes`, `representationDiff`, outcome before report-v1 normalisation, all five evidence axes, and reason handling). Compare canonical selected ID bytes and total/supported/unsupported counts as applicable.
3. **Do not pretend** the known `R-MALFORMED` case is equivalent: Part 2 currently reduces it to manual review, while proposed Part 3 must reject the complete batch. Isolate that case and explicitly assert the intended difference.
4. Re-check private findings **against the same call**: per supported quest `#report.m1Classes == #private.m1Findings`; every class and ordinal matches at the same index; duplicate same-class explanations stay separate.
5. Prove no source mutation, no shared-table aliasing, no filesystem/process writes, and no new ability to mark `authenticated` or `publishable` true.

A differential test that merely checks counts or sorted sets is insufficient: order, types, reasons, fixed codes and absence of unapproved fields all matter.

## 4. Planned synthetic acceptance families (all NOT IMPLEMENTED)

| Gate | Fixture and mutation | Required future oracle |
| --- | --- | --- |
| G2-01 | One supported selected quest; one unsupported v2 quest; K=65 rejected supported quest | Count M1 calls **1 / 0 / 0** respectively, without production dependency injection |
| G2-02 | Two identical-class `C-UNKNOWN` findings with distinct explanations | Both retained verbatim in order; classes and ordinals correspond exactly, no dedupe |
| G2-03 | `server=-60001`, `questie=60001`; numeric `13154` versus string `"13154"`; absent side | Preserve negative GO sign, type of single-token strings and missing optional side |
| G2-04 | Fake `R-MALFORMED` whose explanation contains `SYNTHETIC_SECRET_SENTINEL` | Entire batch returns only fixed malformed code; no record, partial return or output containing sentinel |
| G2-05 | Creature, object, item each 64 / 65, with otherwise valid v2 records | 64 passes *resource gate* (not automatic report success); 65 refuses before M1, frozen v2 still accepts |
| G2-06 | Combined other ordinary 2048 / 2049; nested 4096 / 4097, with otherwise valid v2 membership | Exact pre-M1 boundary after counter formula is independently reviewed and approved |
| G2-07 | 192 / 193 synthetic complete findings; 1024 / 1025 explanation and string-ref bytes | Exact threshold handling, no truncation; classify malformed type/content separately from oversized output |
| G2-08 | Printable ASCII containing quote and backslash, plus safe-looking input that encodes larger than raw length | Byte budget counts actual **canonical encoded bytes including escapes**, not Lua `#text` alone |
| G2-09 | 256 KiB −1 / = / +1 complete encoded quest findings record, individually valid fields | Boundary accept/accept/refuse (assuming all other checks pass), not a raw explanation budget |
| G2-10 | 64 MiB −1 / = / +1 complete encoded private bundle | Boundary accept/accept/refuse for the *entire* future bundle-v2, including framing/provenance/integrity; use bounded counting sink where possible |
| G2-11 | v2-only M1-unsupported record with sorted reasons, malformed/duplicate/mismatched reason variants | Report-v1 stays EXPORTED, no public reasons, private reasons exact-match export; aggregate-v1 reason occurrence counts remain zero |
| G2-12 | Explicit duplicate server ID, bad server v1, invalid v2, paired manifest mismatch, absent selection | Preserve appropriate existing fixed-code precedence; no identifiers/path/explanation in error output |
| G2-13 | Mutated class/order/ordinal, unknown key, float/zero ref, noncanonical set token, nil/array holes | Reject all unsound private records with fixed code; never "repair" output by guessing |
| G2-14 | Valid structural v1 flags asserting evidence completeness without authenticated per-axis proof | All five evidence axes remain unknown, no CONFIRMED_* report outcome |
| G2-15 | 8,401-style public synthetic coverage and 9,159-ID in-memory fixture (where practical) | Part 2/public output differential, bounded deterministic execution, no real server exports |

A test that cannot construct a *v2-valid* 2,049/4,097 objective arrangement must use a test-only boundary component/stub, clearly labelled; do not report a frozen-v2 rejection as proof that the **new** M2.3 resource check ran. Likewise, synthetic 193 findings and a 256-KiB record may require a test-only M1 stub because frozen M1 has an estimated 160-finding bound under K64.

## 5. Proposed resource-counter interpretation — REVIEW OPEN, NOT AUTHORISED

The approved initial ceiling is **64 each** for `creature`, `object`, `item`; **2,048 combined other ordinary entries**; **4,096 combined nested entries**. The *exact counting formula* was not approved.

Candidate interpretation to submit for review:
- Count each `q.objectives` entry once according to its `kind`. `reputation + killCredit + spell` contribute to **other ordinary**, not creature/object/item. Under frozen v2, reputation has a separate one-entry maximum.
- Nested total candidate: `#q.requiredSourceItems + #q.extraObjectives + SUM(#e.refs + #e.spawnZones) + SUM(#killCredit.ids)`. Consider whether each `killCredit.rootId` should also add one; `sourceItemId` and `spell.itemSourceId` are scalars with one-per-objective multiplicity and may not require independent nested increments.
- **Why `spawnZones` matters:** `EffectiveSchemaV2.lua` checks it is a dense list but the cited current validator section does not impose a small per-record bound. Excluding it from preflight without justification could leave an unexpected nested input amplification surface.
- Resolve exact count domain (one v2 selected quest or whole batch), threshold equality, reject code and evaluation precedence in a reviewed contract before tests or implementation. The suggestion above is **not** an expansion of maintainer authorisation.

## 6. Exact private encoded-budget oracle — REVIEW OPEN

Budget equations must be applied to the **final canonical output format**, not an imagined JSON or Lua `%q` encoding. The future codec/schema review must fix and test: UTF-8/ASCII rules, escaping, field order or canonical order, delimiters, newline policy, numbers, null/omitted fields, integer representation, version framing, integrity representation, and the scope of each record.

- **Per quest:** size of its entire encoded private findings entry, including quest-ID/key/framing bytes; ceiling **256 × 1024 = 262144 bytes**.
- **Whole bundle:** size of its actual complete bundle-v2 encoding (report-v1, aggregate-v1, private findings, provenance, `leftoverTempCount`, version and integrity/framing); ceiling **64 × 1024 × 1024 = 67108864 bytes**.
- **Input:** the separate frozen **16-MiB** bound remains unchanged.
- **Fail closed:** no partial bytes returned or published as a successful result after overrun; `REJECTED_UNSAFE_OUTPUT` once a validated encoded size is too large.
- A `192 × (1024 + 2×1024)` approximation is about 576 KiB before other fields, so 192 findings alone do **not** guarantee the 256-KiB quest budget.
- To avoid allocating a 64-MiB test string for every CI case, test a deterministic incremental counter/sink against **known canonical encoder output** using small exact byte fixtures plus a bounded overflow test. This cannot replace at least one end-to-end encoding contract test.

## 7. Future gates and acceptance discipline

**G1 (contract):** approve closed schemas/encoding, error precedence and counter formula after CosmicScript02 exact-head review and maintainer decision. Do not silently choose policy in Lua.

**G2 (synthetic red tests):** separate draft, invented data only. The first regression checks must demonstrate the single-call spy, Part 2 differential including fixed rejection codes, K64 pre-M1 refusal, private secret refusal and encoded-byte budget boundaries. Red-test evidence is not green CI; do not merge failing mandatory jobs.

**G3 (new pure worker):** only after G1/G2 review, implement a separately scoped pure candidate worker, no I/O, preserved original findings, no mutation of Part 2/frozen files. Complete independent exact-head review, mutations and full synthetic suite.

**Always-on evidence invariant:** the five axes remain UNKNOWN at every G2/G3/G4 stage unless a *separately authenticated and reviewed* per-axis source is approved. No automatic CONFIRMED_*.

**Separate later gate:** any trusted CLI, private pilot, integrity publisher, real export, allowlist pin, release, protected integration or addon/server installation requires separate maintainer authorisation and review. Neither passing synthetic tests nor this document confers it.

## 8. Questions specifically for CosmicScript02

1. Is the isolated worker + test-loader spy feasible under the current Lua 5.1 loading pattern without touching production dependencies?
2. What should the exact **2,048 other / 4,096 nested** formula count? Include/exclude `spawnZones`, `rootId`, and clarify if a boundary example is actually v2-valid and M1-supported.
3. Should malformed **type/shape** rejection precede `REJECTED_UNSAFE_OUTPUT` when one synthetic finding violates both, after `R-MALFORMED` takes priority?
4. Which future encoder format should determine the exact 256-KiB and 64-MiB encoded-byte oracles? Do not approve threshold arithmetic as format correctness.
5. Which candidate G2 cases would be logically impossible with real frozen M1 and must be explicitly labelled **stubbed**?

**Review verdict requested: PASS / CHANGES REQUESTED / NOT TESTED on the exact PR head. This is design-only and must remain DRAFT/unmerged.**
