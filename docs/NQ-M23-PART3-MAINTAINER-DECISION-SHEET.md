# N-Questie M2.3 Part 3 — maintainer decision sheet

**STATUS: ALL OPTIONS UNSELECTED. Review proposal, NOT approved or implemented.** This is an approval-ready summary of existing design documents; it neither supersedes the approved contracts nor authorises work on private inputs, the trusted CLI, publisher, addon, server, release or protected `335`.

**Sources:** [G1 resource/codec proposal #82](https://github.com/CosmicCuddle/N-Questie/pull/82), [G2 test blueprint #77](https://github.com/CosmicCuddle/N-Questie/pull/77), [G3 worker architecture #76](https://github.com/CosmicCuddle/N-Questie/pull/76), [owner-approved #42 step 10](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6192683832), [owner N2/N3 confirmation](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6193810632). Frozen `335` is `2be0f6f3001a20242c2fe81cb1915ff18602a4c8`. Follow the detailed source whenever this summary omits detail.

## Already approved — not reopened here

- Byte-identical frozen `M23Batch.Run` and historical v1/v2 schemas/report validators. Any separately authorised Part 3 worker must be pure, I/O-free, in memory and **untrusted/nonpublishable**.
- Candidate quest resource ceilings already approved numerically: creature/object/item ordinary objectives **64 each**, other ordinary (reputation/killCredit/spell) **2,048**, combined nested **4,096**. **Exact nested formula, spawn-zone policy, selected unsupported scope and new worker execution order are NOT approved.**
- After one frozen M1 call: maximum **192** findings, **1,024** original ASCII bytes per explanation and canonical ID-set string, **262,144** complete canonical bytes per quest findings record, **67,108,864** complete final-bundle bytes. Frozen input remains **16 MiB**.
- The existing approved **14 Part 3 CLI error codes** include `REJECTED_M1_STATUS_MISMATCH` and `POST_PUBLICATION_FAILED`. The historical nine-code draft stderr checker is *not* the future CLI contract. Post-publication failure keeps the published private bundle for human inspection; do not silently revise N2.
- The required private `leftoverTempCount` **field** is already approved; its **measurement source, audit semantics and pre-hash placement** remain unresolved. Five evidence axes remain `unknown` absent separately authenticated evidence; hashes are not authentication. Never disclose `R-MALFORMED` explanations.

## D5. Should owner-approved #42 step 10 be explicitly amended?

Current approved step 10 invokes unchanged `M23Batch.Run`, retaining present selection/membership/per-quest M1 behavior. The proposed **new** worker's whole-selected-batch pre-M1 selection and resource gate is a genuine change, not an implementation of unchanged step 10.

- **A — approve explicit amendment:** permit a new distinct worker to perform complete selected-ID, membership and resource preflight before ANY M1 call; its batch refusal calls M1 zero times. Existing `M23Batch.Run` itself stays byte-identical.
- **B — keep approved step 10:** global zero-M1 G3 worker preflight is NOT authorised; revise #76/#77 accordingly.
- **C — another explicit sequence:** owner supplies ordered gates and precise permitted M1-call behavior.

**UNDECIDED.** Required recorded answer: `D5 = A/B/C`, exact replacement step text and scope.

## D6. Which APPROVED fixed code applies to an otherwise valid pre-M1 over-limit record?

Concrete examples (all frozen-v2-valid): supported creature K65, combined-other 2,049, or selected nested 4,097. This is not a malformed-schema/nonfinite-number error, nor post-M1 oversized canonical output.

- **A:** `REJECTED_MALFORMED_INPUT`.
- **B:** `REJECTED_UNSAFE_OUTPUT`.
- **C:** propose an *already approved* fixed code with full rationale; no fifteenth code.

**UNDECIDED.** Record `D6 = A/B/C` plus whether the chosen existing code covers all the agreed pre-M1 ceilings. Separately proposed invalid/nonfinite scalar inputs map to MALFORMED_INPUT; post-M1 encoded-output excess maps to UNSAFE_OUTPUT. Neither decides this well-formed pre-M1 case.

## R1. Exact nested counting formula

G1 #82 `2 **proposes**, but does not approve, per-selected-v2-quest arithmetic:

~~~text
m1Nested = #requiredSourceItems
         + #extraObjectives
         + SUM(each extra e: #e.refs)
         + SUM(each killCredit o: #o.ids)

zoneEntries = SUM(each extra e: #e.spawnZones)
~~~

Scalar `rootId` is not a second nested array entry. The frozen adapter forwards all the listed M1 nested arrays but drops `spawnZones` (which are still parsed by the frozen v2 validator).

- **A:** approve those exact summations, inclusive `<= 4096` where applicable.
- **B:** supply replacement fields and exact per-array counting rules.

**UNDECIDED.** Record `R1 = A/B` and any exact replacement.

## R2. Spawn-zone policy — choose precisely one (or provide a full alternative)

| Candidate | Count gate | Benefit / cost |
| --- | --- | --- |
| **A — M1-only** | `m1Nested <= 4096`; no extra zone cap | Directly bounds M1-forwarded arrays; **zone arrays still limited only by frozen 16-MiB input** |
| **B — combined** | `m1Nested + zoneEntries <= 4096` | One conservative inclusive ceiling; rejects records whose *separate* components each fit |
| **C — dual** | `m1Nested <= 4096` and `zoneEntries <= 4096` separately | New selected-record zone ceiling, but **does not reduce prior full v2 parsing/validation memory** |

Nonnegative counts imply **B-pass => C-pass => A-pass**, so raw PASS counts are not a quality ranking. An invented case `m1Nested=1, zones=4096` passes A/C but fails B; `m1Nested=2049, zones=2049` passes A/C but fails B; `m1Nested=4097` fails all. These are **hypothetical count gates**, not Part 2 or G3 refusals. [#85](https://github.com/CosmicCuddle/N-Questie/pull/85) tests such arithmetic without choosing a policy.

**UNDECIDED.** Record `R2 = A/B/C` or a fully specified replacement.

## R3. Scope: do frozen-v2-valid M1-UNSUPPORTED selected records count?

- **A — all selected quests:** count even `UNSUPPORTED_BY_RULES` quests, including an unsupported LAST record; a resource failure may refuse the whole batch with zero M1 calls **only if D5 approves that order**.
- **B — supported-only:** provide explicit handling of unsupported resource pressure and comparison order.
- **C — different precise rule:** include/exclude criteria and step order supplied by maintainer.

**UNDECIDED.** Record `R3 = A/B/C`. G1 #82 `7.1 explicitly leaves this open; #85's unsupported fixtures only compute options.

## C1. Approve/amend complete canonical private bundle-v2 format

G1 #82 ``3–5 **proposes** a closed, unindented **ASCII-only RFC 8259 JSON** encoding with one terminal LF; finite bounded integer decimal tokens (Lua 5.1 safe; no `%d` assumption); quote/backslash escaping; fixed key and array order; optional-field omission rather than `null`; full zero-inclusive enum/count maps; exact final encoded-byte budgets; a SHA-256 payload digest over an explicit domain prefix with `integrity` excluded from its own hash input. This **unkeyed hash is NOT authentication**.

Before selecting, resolve **all** of these together: key/field order for outer report/findings/aggregate/provenance/integrity, signed GO bounds, numeric ranges/lexical form, zero vs sparse enum maps, ASCII escape rules, final LF, canonical round-trip, payload hash domain and scope, full envelope count including integrity and LF, and proposed nonfinite numeric preflight. Preserve ordered M1 findings, duplicates, rule ordering and numeric-versus-string distinctions.

- **A:** approve all specified #82 ``3–5 subchoices **exactly**, subject to fresh reviewer verification.
- **B:** provide a written list of changes and request a consolidated reviewed final contract.
- **C:** reject that candidate and provide a fully specified alternative codec.

**UNDECIDED.** Record `C1 = A/B/C` and all subchoices/amendments. No codec green test or private worker output should be claimed until the byte contract is complete.

## P1. Provenance keys / external verification / already-required temp counter

G1 #82 `4.2 proposes a closed `engineProvenance` key set, private trusted-boundary pins and a mandatory `leftoverTempCount` inserted **before** immutable bundle encoding/hashing. The pure worker may not invent or authenticate either field.

- **A:** approve exact `engineProvenance` fields and specify which **external trusted authority/pins** verify the values.
- **B:** specify an amended closed key/type set and trustworthy verification binding.

Regardless of A/B, the maintainer must **define the temp-count measurement**: scope/root, entries counted (files, dirs, symlinks), scan start/end, errors/races/symlink handling, final measurement time relative to publication/cleanup, and audit evidence. Do not default to invented zero or retrospectively rewrite pre-hashed bytes.

**UNDECIDED.** Record `P1 = A/B` plus exact counter measurement and trusted data source.

## Evidence already available — not policy decisions

- [#77](https://github.com/CosmicCuddle/N-Questie/pull/77) `94925ced` — G2 plan and D5/D6 design; 6/6 GitHub CI, exact-head developer PASS.
- [#83](https://github.com/CosmicCuddle/N-Questie/pull/83) `3ddfc389` — synthetic Part 2 precedence, **all twelve synthetic public-reason cohort patterns**, no-M1 unsupported oracles; 6/6 CI, exact-head developer PASS. Public `9,159 = 8,401 + 758` reflects **v1 shape representability**, not quests repaired.
- [#84](https://github.com/CosmicCuddle/N-Questie/pull/84) `aa2f3cf` — supported/unsupported K64/K65 object/item, identity and real M1 spy controls; 6/6 CI, exact-head developer PASS.
- [#85](https://github.com/CosmicCuddle/N-Questie/pull/85) `c49d703` — **21 synthetic** candidate nested/zone cases, pure adapter checks; **6/6 CI; new-head peer review pending**.
- [#86](https://github.com/CosmicCuddle/N-Questie/pull/86) `da1d4e4` — **10 synthetic** other-ordinary cases, pure adapter checks; **6/6 CI; new-head peer review pending**; does NOT call M1.
- Peer/CI success never substitutes for maintainer approval of D5/D6/R1/R2/R3/C1/P1.

## Gate to any actual G3 implementation

1. Maintainer records all **seven** selections/amendments, and reviewer checks the amended contract for internal consistency (especially step order, fixed-code precedent, signed numeric bounds and authenticating source).
2. Only then open a **distinct isolated G2/G3 implementation draft** with red/green synthetic oracles, preserving the frozen Part 2 and protected `335` byte-identically.
3. Require fresh exact-head CI, CosmicScript02 independent review, and separate maintainer permission for trusted CLI, private input, publishing, merge and release. No unapproved production/test gates on `335`.

**Optional response format — NOTHING preselected:**

~~~text
D5 = [A / B / C]  exact step-10 amendment:
D6 = [A / B / C]  existing code / scope:
R1 = [A / B]      exact nested formula:
R2 = [A / B / C]  zone guard:
R3 = [A / B / C]  unsupported scope:
C1 = [A / B / C]  complete byte-format decisions:
P1 = [A / B]      trusted provenance + temp scan semantics:
~~~

If any field remains unanswered, **that gate remains open**. This document approves no choice and changes no worker, parser, trusted CLI, exporter, release or server files.
