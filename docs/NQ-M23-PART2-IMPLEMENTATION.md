# M2.3 Part 2: pure comparison foundation (DRAFT / DO NOT MERGE)

Base: merged `335` `41aa84b56f38adbea09a89c32af1e9ab4c4b9d09`.
Independent of Part 1 draft PR #68; it does not modify or merge #68.

## Deliberate scope

- `M23QuestieAdapter.ToQuestieRecordV2`: converts M1-SUPPORTED v2 structural records into frozen M1's questKeys-indexed form, retaining all eligible targets, KillCredit ids/root, slot positions, source items and extra items. Unsupported v2 records are never projected.
- `M23Membership.Check`: checks production coverage-manifest shape and pairing against v2; every ID, supported/unsupported status and strictly sorted/unique reason list must agree. Checks the supplied count pins and coverage aggregate. It does **not** authenticate the export or trust a caller-supplied pin.
- `M23Membership.IdBytes`: constructs the M2.2 canonical sorted decimal ID list with LF following every ID. A future trusted CLI must compute SHA-256 and compare the result to the allowlisted ID-set pin. `IdBytes` does not claim to perform hashing.
- `M23Batch.Run`: compares a structurally valid frozen `nq-m2-input` v1 document against a structurally valid effective v2 export using frozen `ObjectiveRules`. Produces only an **in-memory, NOT-authenticated, NOT-publishable** summary. It cannot touch the filesystem or server.

## Crucial B6 limitation

Frozen v1's field validations alone do not prove that all required private evidence was collected. The frozen M2.1 validator requires all tri-state fields: a missing field rejects the whole batch, whereas an explicit `"unknown"` stays uncertain. Every evidence axis, including `objectiveData`, remains **unknown** in this initial engine. Thus it must NEVER emit `CONFIRMED_MATCH` or `CONFIRMED_MISMATCH`; possible target discrepancies remain `NEEDS_MANUAL_REVIEW`. M1's expected representation differences may still be explained. This is a safety rule, not evidence that two quests agree.

## Not implemented here

Trusted export-commit allowlist checks; A2 `NQ_V2_VERIFY_IN` authenticity; private checkout gates; read/re-hash of input files; cryptographic SHA-256 validation; 14-code stdout/stderr CLI contract; private report/aggregate schemas; secure atomic publication; 50-test/28-mutant milestone; real private quest-data comparison; user client installation.

**No merge, tag, release, private data, automatic corrections, runtime addon modifications or AzerothCore changes.** No production claims or decisions about M2.4.

Run synthetic tests: `lua5.1 tests/test_nquestie_m2_3_batch.lua`.

Governing decisions: https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6199960658

## Review follow-up (PR #69)

The independent review identified three targeted improvements, now implemented:
- The KillCredit anti-aliasing test mutates the **same source record** used by the projection.
- Paired manifest tests reject a missing second reason and an aggregate with an omitted reason; both checks are deliberately mutation-sensitive.
- Duplicate server IDs are classified as `REJECTED_DUPLICATE_ID` before the frozen input validator, while other malformed shapes still reach `REJECTED_MALFORMED_INPUT`.

Additionally, the production coverage manifest has a closed top-level key set. The larger 8,401-quest public parity script and test runner integration remain separate future test-hardening work, not acceptance claims. No change grants trusted exports or confirms a quest based on frozen v1.
