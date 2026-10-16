# N-Questie M2.3 Part 3 — one-pass private-findings execution boundary

**Status: DESIGN PROPOSAL ONLY; NOT IMPLEMENTED.** Prepared for independent review on the merged public/synthetic foundation. This document grants no permission to process real server inputs, trust an export, publish a bundle, merge a PR, release an addon or install files. Frozen v1/v2/M0/M1 and the historical report/aggregate/bundle-v1 contracts remain untouched.

**Pinned foundation:** protected `335` commit `2be0f6f3001a20242c2fe81cb1915ff18602a4c8` (merged PRs #68, #69, #70). Re-check the live branch before implementation. Governing design: [Part 3 private findings/K64 proposal (#71)](https://github.com/CosmicCuddle/N-Questie/pull/71), [K64/65 synthetic research (#72)](https://github.com/CosmicCuddle/N-Questie/pull/72), [conservative B6 evidence proposal (#74)](https://github.com/CosmicCuddle/N-Questie/pull/74), and the [maintainer's D1–D4/K64 decision](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6214484105).

## 1. Existing behaviour and exact gap

- `tools/validation/M23Batch.lua` is a **pure, unauthenticated, report-only** foundation. `Run(server, effective, manifest, pins)` checks frozen v1 input and M2.2 membership, projects each supported v2 quest, and calls frozen `M1.Compare` once for each M1-supported selected quest (inside `pcall`).
- It consumes each M1 finding to populate only `row.m1Classes`, `row.representationDiff` and a conservative outcome. The complete returned finding array is not included in the result. Unsupported quests do not invoke M1.
- Re-running `M1.Compare` after `M23Batch.Run` to obtain private `kind`, ordered `rules`, optional `server/questie`, and verbatim `explanation` would perform a **second comparison**, with a possible order/source divergence. This is not the recommended design.
- Historical `tools/validation/draft/M23ReportDraft.lua` defines a closed report-v1 contract; it must **not** be widened to carry private finding text.

## 2. Proposed isolated boundary — approval requested

**Preferred for initial implementation review: a NEW pure, private-only comparison worker, not a mutation of `M23Batch.Run`.** Share existing immutable validation/projection libraries (`InputSchema`, `M23Membership`, `M23QuestieAdapter` and frozen `ObjectiveRules`); do not call `M23Batch.Run` as a preparatory pass, and do not duplicate its M1 invocation.

The private worker would produce an **unpublishable in-memory candidate** with three separately versioned views: report-v1 summary, private findings-v1, and aggregate-v1 derived solely from validated report rows. Later bundle-v2 construction/authentication is a different review gate. This boundary is a proposal, not an existing API. A shared internal walker extracted from `M23Batch.Run` could reduce drift, but would edit reviewed Part 2 code; compare its regression cost with the isolated approach before approving.

**Intended evaluation order:**
1. **Outside the worker, future trusted boundary:** verify a pinned effective-v2 checkout/export, full M2.2 manifest membership and ID-set authenticity, clean checkout, and a separately approved allowlist entry. No such trusted boundary or entry currently exists. The pure worker itself **must return `authenticated=false, publishable=false`** or an equivalent clearly untrusted status, never self-attest by accepting supplied pins.
2. Reject duplicate/malformed server selected IDs with the existing fixed-code precedence (including `REJECTED_DUPLICATE_ID`), then validate frozen `nq-m2-input` v1 and effective-v2 membership, pairing and selection. Do not copy or echo validator error text; all failures use fixed codes.
3. On every M1-supported selected quest, **before M1**, count ordinary creature/object/item objectives separately (64 maximum each), other ordinary objectives (2,048 combined) and the approved nested extra/refs/kill-credit/required-source-item counter (4,096 combined). If any counter exceeds its defined policy, reject the **whole batch before M1**. Define every category's counting source in reviewed tests; keep frozen v2 accepting its historical 65+ examples.
4. Project the validated supported v2 record with `M23QuestieAdapter.ToQuestieRecordV2`, and call frozen `M1.Compare(M1.FromQuestTemplateRow(source), questie)` **exactly once** within a narrow protected call. Unsupported quests get zero calls and a private-only, export-matched `m1Reasons` list.
5. Inspect **that one returned findings array** before constructing any private finding member. A surviving `R-MALFORMED` rule or M1 exception rejects the whole batch as `REJECTED_MALFORMED_INPUT` without storing or printing the potentially input-derived explanation.
6. Check dense ordered findings, valid class/rule/type/ordinal vocabulary, ≤192 findings, verbatim printable-ASCII explanations ≤1,024 bytes, original canonical string references ≤1,024 bytes, numeric references including signed negative gameobject `server` IDs; reject unknown fields, coercion, omission, sanitisation and truncation.
7. Derive report-v1 `m1Classes` **from the same checked array in the same order**, and construct private findings-v1 by copying exactly the approved fields into separate owned tables (not shared mutable aliases). Supported findings have no `unsupportedReasons`; M1-unsupported rows place the strictly validated v2 reason list in private findings only. In the report, unsupported v2 selected quests stay `EXPORTED` with `M1_UNSUPPORTED_BY_RULES` and no public `reasons`.
8. Apply conservative frozen-v1 evidence: all five axes remain `unknown`; no `CONFIRMED_MATCH` or `CONFIRMED_MISMATCH`. Use only the existing expected-difference/manual-review/unsupported outcomes. Derive aggregate-v1 *only* from validated report-v1, with v2-only unsupported-reason occurrence counts remaining zero.
9. Validate closed members, sorted unique selected IDs and one-to-one selected set/class sequences, then count **complete encoded private bytes** incrementally: ≤256 KiB per quest and ≤64 MiB full private bundle output budget. Exceeding any output budget yields fixed `REJECTED_UNSAFE_OUTPUT` for the entire batch. A later publishing stage must additionally validate provenance, integrity, no-clobber writes and read-back; none exists here.
10. The worker returns only a local candidate or a fixed rejection code; **no filesystem, subprocess, network, WoW API, stdout, stderr or publication**. A future, separately approved CLI would own authentication and safe output handling.

## 3. Synthetic acceptance gates before code integration

- **OP01 single-pass spy:** on a supported selected quest, count exactly one M1 call; unsupported v2 quest exactly zero. A candidate using `M23Batch.Run` and then M1 must fail this test.
- **OP02 shared result/order:** two same-class findings with distinct explanations remain separate and ordered. `report.m1Classes[i] == private.m1Findings[i].class` for every i; mutate the class, ordinal or order and fail.
- **OP03 types/sign:** retain negative GO `server=-60001`, positive `questie=60001`; preserve `"13154"` STRING vs `13154` NUMBER; optional nil remains absent.
- **OP04 privacy breach:** a synthetic `R-MALFORMED` with distinctive input-derived secret text must return only fixed `REJECTED_MALFORMED_INPUT`, without candidate text, stdout, stderr or partial records.
- **OP05 K=64/65 per-kind:** frozen v2 accepts both shapes; initial reporter accepts 64 and refuses 65 *before* the M1 spy increments, for creature/object/item independently. Bound the 2,048/2,049 other and 4,096/4,097 nested counters likewise.
- **OP06 output budgets:** 192/193 findings, text/reference 1,024/1,025, full 256-KiB quest/64-MiB bundle encoded limits; fail closed, never truncate and never mark a partial publishable result.
- **OP07 unsupported reasons:** v2-only M1 unsupported selected quest is EXPORTED in report-v1 and carries exact sorted unique `unsupportedReasons` only in private findings-v1; aggregate-v1 reason occurrences remain zero.
- **OP08 conservatism:** every axis `unknown`, zero confirmed report outcomes. A malformed evidence injection or attempt to upgrade based solely on structural v1 validity must fail.
- **OP09 no I/O and aliasing:** snapshot input and returned findings unchanged; mutation of private candidate must not mutate source/server/v2/M1 results. No unapproved open/write/shell calls.
- **OP10 old engine regression:** the existing Part 1/Part 2 suite and `M23Batch.Run` published signature, class/order/outcome semantics stay unchanged; full suite PASS on the same integrated code.
- **OP11 error precedence:** duplicate-ID refusal remains distinct from other malformed shapes; invalid manifest/selection and over-limit preflight never leak IDs, paths or explanations through diagnostics.
- **OP12 provenance honesty:** no candidate may set `authenticated` or `publishable` true merely because supplied pins match. Future external verified evidence is required.

These are **planned tests, NOT currently implemented or passed**. Existing PR #72 validates frozen M1/v2 shape *research* only; OP05 must exercise the future reporter's stricter pre-M1 refusal directly.

## 4. Independent design decisions requested

1. Is the isolated pure private worker the safest initial implementation surface, or is a new shared internal walker justified by anti-drift benefits? **No existing Part 2 refactor is authorised by this proposal.**
2. How should tests construct a controlled M1 call counter without a production-facing dependency-injection escape hatch? The production code must always use frozen M1.
3. Precisely which validated v2 arrays contribute to the “2,048 other ordinary” and “4,096 nested” counters? Confirm that the approved maxima cannot cause an unexpectedly large M1 allocation.
4. Which closed error-code priority and full-record encoded-size measurement should be fixed in the next design revision before red tests?

**Merge and privacy gate:** new tests / new code / publication each require their own exact-head CI, independent review and explicit maintainer integration authority. This document by itself authorises none of them.
