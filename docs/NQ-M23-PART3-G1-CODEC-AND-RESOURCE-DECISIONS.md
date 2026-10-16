# N-Questie M2.3 Part 3 — G1 canonical codec and resource decision record

**Status: REVIEW PROPOSAL ONLY / NOT APPROVED / NOT IMPLEMENTED.**
This document specifies **candidate decisions** for independent CosmicScript02 review and separate maintainer selection. It adds no Lua implementation, test, CLI, trusted-export entry, private comparison, publisher, release, merge, AzerothCore source change or addon installation. It is **not** a final standard, nor does it supersede the owner-approved D1–D4/K64 design in [#71](https://github.com/CosmicCuddle/N-Questie/pull/71).

**Verified foundation:** protected `335` = `2be0f6f3001a20242c2fe81cb1915ff18602a4c8` after #68 → #69 → #70. Companion proposals: [#76 isolated worker](https://github.com/CosmicCuddle/N-Questie/pull/76), [#77 synthetic G2 blueprint](https://github.com/CosmicCuddle/N-Questie/pull/77), [#78 nested data research](https://github.com/CosmicCuddle/N-Questie/pull/78), [#79 test-loader spy](https://github.com/CosmicCuddle/N-Questie/pull/79), [#80 signed GO bounds](https://github.com/CosmicCuddle/N-Questie/pull/80), [#81 non-finite numeric research](https://github.com/CosmicCuddle/N-Questie/pull/81). The shared developer disagreement/compromise proposal is in [#42](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6222404924).

## 1. Previously approved invariants (not newly approved by this PR)

- Bundle **v2** will carry distinct private **report-v1**, **findings-v1**, **aggregate-v1**, engine provenance and `leftoverTempCount`. Keep the historical bundle-v1, report-v1 and aggregate-v1 validators unchanged.
- Per selected v2 quest, creature, object and item ordinary counts each ≤ **64**; all other ordinary types together ≤ **2,048**; combined nested resources ≤ **4,096**. **Which nested sub-arrays count is not yet agreed.**
- After the same single frozen M1 call: at most **192 findings**, **1,024 original ASCII bytes per explanation**, **1,024 bytes per canonical ID-set string**, **256 KiB** complete encoded findings record per quest, **64 MiB** complete encoded bundle output. Frozen input remains **16 MiB**.
- All five evidence axes remain `unknown` under frozen v1. No `CONFIRMED_*` report outcome from structural v1 evidence. `R-MALFORMED` must never be copied or disclosed.
- Existing `M23Batch.Run` stays byte-identical and report-only. A proposed new pure I/O-free worker returns an **untrusted, nonpublishable in-memory** candidate, never a trusted export or an authenticated result.
- The resource-counting **A/B/C**, JSON codec, exact provenance keys, and precise temp-counter measurement method below remain unapproved options requiring review. Existing maintainer decisions on CLI rejection codes, preserving published failures and including a private `leftoverTempCount` field **are already approved**; this proposal may not silently supersede them. Nothing authorises real/private input, publication, integration or a release.

**Approved Part 3 CLI error contract (already decided, not an open A/B choice):** the 14 fixed codes in [maintainer reconciliation](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6192683832) and [final confirmation](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6193810632), including `REJECTED_M1_STATUS_MISMATCH` and `POST_PUBLICATION_FAILED`. A new, separately validated CLI stderr checker must enforce this **approved 14-code set**. The nine-code `tools/validation/draft/M23ReportDraft.lua` `M.REJECTION`/`CheckStderr` belong to the **historical draft**, not the real Part 3 CLI; its digit filter also rejects `M1` and must **not** be reused. Do not map M1 status disagreements to `REJECTED_MEMBERSHIP` or `REJECTED_MALFORMED_INPUT`, which would contradict the owner's existing mapping. The approved post-link error line is exactly `nq-m2-3: POST_PUBLICATION_FAILED`, with a non-zero exit and the already-published bundle kept private for human inspection ([N2 owner decision](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6192888329)).

## 2. A precise *proposal* for pre-M1 resource counts

Count on **every selected quest**, including records whose `m1Status` is unsupported. Count after frozen v2 structural validation, membership/pairing and selection checks, and before adapter/M1, with a fixed whole-batch `REJECTED_MALFORMED_INPUT` on overrun.

```text
creature = #ordinary objectives where kind == creature     <= 64
object   = #ordinary objectives where kind == object       <= 64
item     = #ordinary objectives where kind == item         <= 64
other    = #ordinary objectives where kind in
             {reputation, killCredit, spell}                <= 2048

m1Nested = #requiredSourceItems
         + #extraObjectives
         + SUM(each extra objective e: #e.refs)
         + SUM(each killCredit objective o: #o.ids)        <= 4096

zoneEntries = SUM(each extra objective e: #e.spawnZones)
```

**Grounding:** `M23QuestieAdapter.lua` forwards required-source arrays, extra entries and refs, kill-credit IDs plus the scalar `rootId`; it **does not** forward `spawnZones` to M1. `rootId` is already bounded one-per-killCredit by `other`; `m1Reasons` is deduplicated from a closed vocabulary; neither adds a separate nested-array count. In contrast, `spawnZones` still consumes validator/parsing memory under the frozen 16-MiB byte cap.

**Unresolved maintainer choice — select exactly one:**

| Option | Count/guard | Advantage / cost |
| --- | --- | --- |
| **A: M1-only** (CosmicScript02 proposal) | `m1Nested <= 4096` only; no additional zone limit | Directly bounds what M1 receives; huge zone arrays still bounded only by frozen 16 MiB input |
| **B: combined inclusive** (earlier CosmicScript01 preference) | `m1Nested + zoneEntries <= 4096` | Single conservative nested ceiling; also refuses a v2-valid 2,049-extra-entries × 1-zone record |
| **C: dual caps** (new compromise, **not approved**) | `m1Nested <= 4096` **and separately** `zoneEntries <= 4096` | Limits zone count in selected records **after full v2 validation**, not parsing/validation resource pressure; adds a *new* policy threshold requiring explicit authorisation |

**Examples for decision, not test results:**
- One extra with 4,096 zones and no refs: `m1Nested=1`, `zoneEntries=4096`. Option A accepts the *count gate*; B refuses (sum 4097); C accepts equality.
- 2,049 extras with one zone each: `m1Nested=2049`, `zoneEntries=2049`. A and C accept their count gate; B refuses (4098).
- 4,096 required-source entries plus one extra: `m1Nested=4097`, so all options refuse.
- A killCredit objective with 4,096 IDs has `m1Nested=4096` (assuming no other nested entries); its `rootId` does **not** add another nested entry.

Every equality is **only resource-gate acceptance**. Other v2 or output gates may still reject. No option is silently selected by these examples or by test CI. **Resource timing:** the proposed worker count happens **after** `M23Membership.Check`, which already parses/validates the full v2 export and visits every `spawnZones` element. Consequently B/C do not save v2 parsing or validation memory/time under the existing 16-MiB input bound; their additional refusals are policy limits on selected records. Option A alone bounds the nested data forwarded to frozen M1.

## 3. Proposed safe numeric preflight (independent of §2)

Before forwarding any selected v2 record to M1, traverse its closed validated numeric fields (including every nested `spawnZones` entry), refusing **all non-finite numeric values**. Require `sourceItemId` in `0..2147483647`. Ordinary/reference IDs already have their own frozen `posId` bounds; use those existing rules rather than relaxing them. No invented real-world zone range: finite negative zones remain frozen-v2-valid unless a later reviewed zone policy changes this.

This is a **new worker-only guard**, not a change to `EffectiveSchemaV2.ValidateQuest`. Its current `isInt` accepts `math.huge` for `sourceItemId`, `spawnZones`, and **reputation `requiredValue`** (even on M1-unsupported selections), and accepts `sourceItemId > 2147483647`, as independently researched in #78/#81. `InputSchema.ParseString` can produce infinite doubles from `1e999` in a data literal. No such input may reach a proposed canonical output encoder. Refuse with a *fixed* `REJECTED_MALFORMED_INPUT` without logging the offending value/path.

## 4. Candidate closed canonical bundle-v2 byte format — NEEDS REVIEW

**Encoding choice proposed, not approved:** a *single, unindented, ASCII-only RFC 8259 JSON object* ending with **exactly one LF byte (0x0A)**; no BOM, CRLF, trailing spaces, comments, extra newline or arbitrary key order. JSON is a proposal **for private bundle-v2 only**; it does not change or widen frozen Lua v1/v2 input or draft bundle-v1.

### 4.1 Primitive and collection rules

1. Only approved closed schema fields may appear; **no unknown fields, metatables, holes, sparse arrays, duplicate keys or nulls**. Optional `server`/`questie` and `unsupportedReasons` are **omitted**, never encoded as `null`. Booleans use lowercase `true`/`false`.
2. Numeric values must be **finite, mathematically integral and within the separately reviewed range for their specific field**. In Lua 5.1, ordinary integers are represented using floating-point numbers; **do not require a Lua integer subtype**. Check `type(v) == "number"`, finite (`v == v` and `v ~= math.huge` and `v ~= -math.huge`), and `v == math.floor(v)` **after** the finiteness check, then check the relevant field bounds. Reject fractions, NaN and infinities; require magnitudes ≤ `2147483647` for ordinary IDs/references, with signed **negative server gameobject** references ≥ `-2147483647` (not `-2147483648`). Nonnegative counts/version values need their own explicit approved upper limits. **The encoded JSON lexical form** is plain base-10 integer digits with optional leading `-`; no decimal point, exponent, plus sign, leading zero, locale dependence, or negative-zero spelling (canonical zero is `0`). A valid in-memory Lua 5.1 value `13154.0` therefore encodes as numeric JSON `13154`; the fractional `13154.5` is invalid. Do **not** reuse Lua 5.1 `string.format("%d", v)` or frozen `EffectiveSchemaV2.Canonical` without a separately reviewed, bounded integer-to-decimal implementation.
3. All string fields are limited to exact ASCII bytes 0x20–0x7E under their own closed schema limits. In JSON, escape `"` to `\"` and `\` to `\\` exactly; do not escape solidus, encode printable characters as `\uXXXX`, normalise case, trim or replace characters. Controls/non-ASCII **reject before encoding**, never silently repair. `explanation` is copied verbatim; the escape process changes transport representation but not decoded bytes.
4. Arrays retain required canonical order: report `selected` ascending, report rows by selected ID, findings quests by selected ID, individual findings and `rules` in **original M1 order**, `ordinal` equal to 1-based original position; `unsupportedReasons` strictly ascending, distinct. Keep `"13154"` as a JSON **string**, distinct from numeric `13154`.
5. JSON objects use the fixed field order in §4.2. Maps of closed aggregate enum/count keys use **lexicographically ascending** names, with a fixed rule to emit every vocabulary key including zero counts (alternatively the reviewer may choose sparse nonzero maps, but the final format MUST choose one). This proposal chooses **all keys with zero counts** for deterministic bytes.
6. Never interpolate private values into logs or error details. All schema/type/character failures are fixed-code `REJECTED_MALFORMED_INPUT`; validated but over-budget encoded output is fixed-code `REJECTED_UNSAFE_OUTPUT` and **nothing is published**.

**Tiny non-secret encoder oracle proposal:** source string containing `A`, a double quote, `B`, a backslash and `C` is five raw ASCII bytes. Its complete JSON string is `"A\"B\\C"` (nine encoded ASCII bytes). A count based on the raw five bytes would be invalid. This needs an independently written exact-byte oracle before approving an encoder.

### 4.2 Candidate member/key order

**Outer payload (before integrity):** fixed order `schema`, `schemaVersion`, `private`, `report`, `findings`, `aggregate`, `engineProvenance`, `leftoverTempCount`. Fixed outer values: `schema="nq-m2-3-bundle"`, `schemaVersion=2`, `private=true`. **Final bundle:** same fields and order, with `integrity` added as the final key.

- **report-v1:** `schema`, `schemaVersion`, `private`, `selected`, `rows`. Each **v2-only EXPORTED** row: `questId`, `exportStatus`, `m1Supported`, `m1Classes`, `representationDiff`, `evidence`, `outcome`. Evidence keys in order: `killCredit`, `conditions`, `scripts`, `ip`, `objectiveData`. Report-v1 `reasons` must be **absent** on EXPORTED rows; no private reasons are copied there.
- **findings-v1:** `schema`, `schemaVersion`, `private`, `quests`. Per quest: `questId`, `m1Findings`, optional `unsupportedReasons` (only v2 M1-unsupported; exact validated export list). Per M1 finding: `ordinal`, `kind`, `class`, `rules`, optional `server`, optional `questie`, `explanation`. Preserve original M1 types, sign and order; no aliasing to input tables.
- **aggregate-v1:** `schema`, `schemaVersion`, `reasonVocabVersion`, `selectedCount`, `exportStatus`, `outcome`, `reasons`; each closed vocabulary map sorted as above and reconciled from **report-v1 only**. The v2 unsupported private reasons do not appear in public report or aggregate reason occurrences.
- **engineProvenance:** proposed **private-only** fixed fields `engineName`, `engineVersion`, `effectiveSourceCommit`, `effectiveSourceTree`, `effectiveCorrectionFingerprint`, `serverSourceFingerprint`, `fullManifestIdsSha256`, `selectedIdsSha256`, in that order. These are **candidate keys, pending separate schema/authenticator review**. Hex and `sha256:` representations must be closed and verified by an external trusted boundary, never taken as proof from unverified input. No paths, arbitrary labels or free text.
- **leftoverTempCount:** an **owner-approved required private-bundle field** ([N3 decision](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6193810632)), represented by a validated bounded nonnegative integer set **before bundle encoding/hashing and publication** by a future reviewed publisher, never invented by the pure comparison worker. The exact scan/measurement semantics are **not** implemented or newly approved by this proposal. A post-install result cannot be retroactively inserted in immutable precomputed bytes; see §5.1. Before the trusted stage, a candidate must not claim publication or authentication.
- **integrity:** proposed object `{"algorithm":"sha256","payloadHash":"<64 lowercase hex>"}`. The value is calculated from the domain-separated payload as §4.3 describes and is **integrity only, NOT authentication**, even if internally self-consistent.

**Still needs maintainer/reviewer approval:** proposed provenance keys/trust bindings; the **measurement method** for the already-required private `leftoverTempCount` and pre-hash insertion; whether full vocabulary zero counts are mandatory; and all JSON/framing/integrity choices. Its presence and the 14-code stderr/N2 post-publication protocol are **not** being reopened here. An exact-byte test MUST be deferred until outstanding format choices are decided.

### 4.3 Proposed deterministic integrity scope without a self-hash cycle

1. Canonically encode an **outer payload object** holding the first eight fields of §4.2 with no integrity key and **no final LF**. Call these raw bytes `payloadBytes`.
2. Compute lowercase hexadecimal SHA-256 of ASCII domain prefix `nq-m2-3-bundle/v2\n` concatenated with the full `payloadBytes`. The prefix is included to separate this digest from unrelated historical formats. Do not confuse this digest with a trusted export SHA or signer attestation.
3. Canonically encode the **final outer bundle object**, adding `integrity` as the ninth, final key containing the digest. Append **one final LF**. Verify that re-encoding the object **without** its `integrity` key reproduces the same payload bytes and digest; verify exact stored bytes and length on read-back.
4. A standalone read-back detects **accidental changes relative to its stored checksum** and proves only internal byte consistency. **An attacker with write access can replace the bundle and recompute this unkeyed SHA-256**, so this does NOT detect deliberate adversarial rewriting, authenticate the server/effective export, attest who ran M1, or prove publication. A separately verified trusted source pin or authenticated external digest/signature would be needed for those claims; the future separately reviewed CLI must establish external trust independently.

A malformed provenance, unsupported codec field, failed hash operation, noncanonical JSON, different read-back bytes, or output over budget rejects with a fixed closed code; publication remains a separate future gate. No hash-writing or filesystem calls belong in the pure worker.

## 5. Exact proposed byte-count semantics and precedence

- One **per-quest findings record** is the complete canonical encoded JSON *object* for that element of `findings.quests`, starting at `{` and ending at `}`. Include `questId`, all member keys, arrays, punctuation and every escaped string byte. Count **≤ 262,144 bytes**. The comma **between** adjacent quest entries belongs to bundle framing, not the single object, and **is** counted at the whole-bundle level.
- The **whole private bundle** is the complete final encoded JSON object **including** engine provenance, integrity hash, `leftoverTempCount`, all strings, object/array delimiters and **final LF**, counted as exact bytes **≤ 67,108,864**. Count at the final format, never merely the payload bytes, decoded explanations or Lua table memory. The separate **16-MiB** frozen input bound remains unchanged.
- Reject the complete selected batch if any individual or whole-bundle budget is exceeded. A bounded incremental encoder/count sink may calculate bytes without creating an unbounded giant string, but must produce **exactly the same bytes** as the separately tested reference codec; at least one small end-to-end encoded/read-back oracle is necessary.
- **Order after the one M1 call:** detect `R-MALFORMED` first, without retaining its explanation, → `REJECTED_MALFORMED_INPUT`; next invalid field/array/type/printable character/canonical token or unknown key → `REJECTED_MALFORMED_INPUT`; last well-formed but over-limit count or complete encoded size → `REJECTED_UNSAFE_OUTPUT`. At all failure points: `nil, fixedCode`; no private value or partial candidate escaped.
- **Order before M1:** preserve Part 2 duplicate-ID → frozen server validation → v2/coverage membership/pairing → selection precedence, followed by the future reviewed resource/numeric preflight before adapter. No fixed rejection code may echo selected IDs or paths. A private worker cannot self-authenticate pins.

### 5.1 Publisher lifecycle and `leftoverTempCount` — UNRESOLVED

**This is a design review checklist, not an implementation or approval.** The pure comparison worker must not write files. Before any future publisher is built, reconcile the proposed ninth-field SHA-256 bundle framing with the **actual** no-clobber `SafeWrite.WriteFile` lifecycle in protected `335` (`tools/validation/SafeWrite.lua:117–200`). That code writes a private staging file, reads it back, hard-links the final name, then unlinks the staging name; post-link cleanup and read-back can fail **after the final file is visible**. A failure status alone therefore does not prove non-publication.

| Phase / synthetic future oracle | Verified SafeWrite property | Future private publisher requirement (proposed; NOT APPROVED) |
| --- | --- | --- |
| Schema, trust, preflight, encoding or size failure **before staging** | No SafeWrite call needed | Reject with closed code and create no new file; never print private content |
| Staging/write/read-back failure **before final link** | Existing temp cleanup is attempted; an existing final name, if any, must not be overwritten | Distinguish failed cleanup from success; no newly installed final bundle; never claim unrelated existing files are absent |
| No-clobber final link fails, including pre-existing target | Without `force`, `ln -T` does not overwrite the target | Refuse this invocation; preserve the existing final; no automatic `--force` retry |
| Link succeeds and temp removal succeeds, followed by successful post-install verification | Final was already published at link time | Only the subsequently verified operation may report **success**; bundle presence or digest consistency alone cannot attest command success |
| **Link succeeds** but temp unlink **fails** | `WriteFile` returns `false, diagnostic, { published = true, final = ... }`; private temp hard link may remain | **Approved N2:** non-zero exit, fixed `nq-m2-3: POST_PUBLICATION_FAILED` stderr, preserve bundle for human inspection; do not leak diagnostic path |
| Link succeeds but final read-back/metadata verification fails | `WriteFile` likewise returns `false` with `published = true` and leaves final evidence in place | **Approved N2:** `POST_PUBLICATION_FAILED`; no silent deletion, overwriting or success claim. Use a new unused filename after correcting the cause |
| Power loss after close/link | The existing helper uses no file/directory `fsync(2)` | Visibility/no-clobber ≠ power-loss durability; additional durability guarantees require a separate publisher design and tests |

**Counter measurement options — do not confuse with the already-approved requirement to include the field:** (A) a bounded **pre-install snapshot** of pre-existing approved-pattern leftovers, excluding this run's staging name, fits the current pre-encoding owner decision, but its scan scope, counting rule, and race limits still require review; it **does not** claim post-run cleanup success. (B) a genuine **post-install count** requires a separately designed publication protocol/attestation outside the precomputed immutable bundle, and **requires a change to the current owner-approved contract**. (C) **omitting** `leftoverTempCount` requires an explicit owner-approved contract revision; silently omitting it or encoding fictitious zero is prohibited. No option here grants approval to introduce a sidecar or output file.

**Integrity and privacy boundary:** a returned `{ published = true }` flag is a lifecycle signal, **not** a trust attestation. Never forward SafeWrite's path-bearing diagnostics, private bytes, hashes, IDs or traces to stderr. The **approved N2 external protocol** for any post-link failure is fixed `nq-m2-3: POST_PUBLICATION_FAILED` with non-zero exit, preservation of the bundle for human inspection, and no automatic consumer trust; subsequent recovery uses a **new unused filename**. Do not mutate an already linked, hash-pinned bundle or mislabel a post-link error as an ordinary pre-link rejection. No extra sidecar/quarantine file is authorised.

**Additional future synthetic oracles:** simulate pre-link failure, final-name collision, temp-unlink failure after a successful link, post-install check failure, and an unavailable `fsync` guarantee; verify preserved final bytes and no-clobber, correct fixed `POST_PUBLICATION_FAILED` for post-link failures, no private stderr leakage, and the reviewed pre-hash counter measurement. Tests must not use or publish real exported server data.

## 6. Future synthetic tests (NOT IMPLEMENTED OR PASSED HERE)

- Two independent encoders/reference oracles for all permitted ASCII chars, quote/backslash escaping, exact integer decimal rendering, optional-field omission, sorted enum map keys, empty lists, field order and single-LF rule. Mutants (extra escaped slash, Unicode escape instead of literal printable, CRLF, duplicate keys, object-key reorder, null substitution) must fail canonical read-back.
- Record byte count at `262143 / 262144 / 262145` and final bundle byte count at `67108863 / 67108864 / 67108865`; use stubbed synthetic M1 finding arrays and **real final codec output**, not fabricated `#explanation`. Do not claim 64-MiB allocation in every CI run is safe; incremental overflow/count tests plus a bounded end-to-end oracle are intended.
- Negative signed gameobject reference `-2147483647`, missing sides, numeric `13154` distinct from string `"13154"`, duplicated same-class M1 findings and strictly ordered `rules`. Reject `-2147483648`, zero ref, noninteger, NaN/Inf and >2^53 numeric values without formatting or leaking.
- Combined synthetic sentinel: `R-MALFORMED` plus oversized explanation or 193 findings returns **malformed**, never unsafe output. Unknown-key + oversize case also returns malformed before size. Non-finite v2 scalar/zone data must reject before any M1 call.
- Each approved resource option §2 requires **distinct** K64/65, 2048/2049, 4096/4097 and zone 4096/4097 tests. Mark a v2-valid fixture test differently from an actual new-worker refusal. Keep frozen v2 and historical Part 2 byte-identical.

## 7. Required independent decisions before G2 code

1. **Maintainer:** choose resource option A, B or C (including whether a new zone cap is authorised); confirm per-selected-quest counting on unsupported as well as supported selections.
2. **CosmicScript02 + maintainer:** approve or amend the proposed ASCII JSON codec, fixed field order, zero-count map representation, numeric rendering, string escaping, final LF, digest domain prefix and full-envelope byte scope.
3. **Maintainer and future trusted-boundary design:** approve a strict `engineProvenance` key set and exact pre-write measurement/audit semantics for the **already owner-required** private `leftoverTempCount`; decide how provenance is verified rather than merely reproduced. Do not silently revise N2 post-publication status or the 14-code stderr contract.
4. **Reviewer:** verify the fixed-code precedence, input vs output classifications, per-record comma handling and genuine boundary test feasibility before any G2 red test becomes a required CI gate.

**Do not implement, trust, merge, tag, release, publish, run a private pilot or modify server/addon files based only on this candidate document.**
