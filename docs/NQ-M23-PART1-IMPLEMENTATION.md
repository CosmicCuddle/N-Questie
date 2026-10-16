# N-Questie M2.3 Part 1: safety foundation (draft PR only)

Source baseline: merged `335` commit `41aa84b56f38adbea09a89c32af1e9ab4c4b9d09`.
Scope: **public/synthetic-only groundwork**. No comparison engine or private run.

## What is implemented

- `tools/validation/StatusCapture.lua`: Lua 5.1 bounded command stdout capture with checked exit-code marker. Any non-zero status, missing status marker, injected duplicate marker, oversized or malformed output returns no stdout. This helper accepts only trusted, locally constructed shell commands; callers must quote every variable argument. It never logs captured stdout.
- `tools/validation/M23ApprovedExports.lua`: initially empty data-only trust allowlist. **No export commit is approved**, including the Stage A2 reviewed source or the `335` merge. No auto-trust from ancestry, identical trees or green CI.
- `tools/validation/M23ApprovedExportsParser.lua`: pure strict validator for the N1 allowlist schema; accepts bytes only, reuses `InputSchema.ParseString` (never executes the candidate allowlist), enforces closed keys, types, dense lists, unique commits and ordered non-duplicate correction modules. Invalid input gets only `REJECTED_ENGINE_CHECKOUT`. Parsing does **not** prove file provenance, checked-out cleanliness or authorisation: the future CLI must enforce those before using these bytes.
- A synthetic Lua test and a Busted wrapper wired into the existing M2 test runner (no workflow file changes).

## Explicitly NOT implemented

`M23Batch.lua`, `M23Report.lua`, `cli/compare-m2.lua`, actual server input, data checkout, pinned full-DB status cross-check, run-time allowlist/trust decision, bundle publisher, or private-output extraction. No side effects on WoW, AzerothCore, the installed addon or GitHub outside this draft PR.

## Governing later-stage contracts

Final decisions:
- https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6192683832
- https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6192888329
- https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6193810632

Initial engine is **v2 effective-export only** with frozen `nq-m2-input` v1; 14 fixed codes (never the old draft's dropped v1-specific code); 50 agreed test IDs and 28 mutants still pending. Never change the 185-check historical draft. Publication uses a single private no-clobber bundle. `leftoverTempCount` stays in that private bundle only; no automatic deletion and no power-loss durability claim. Any actual approved entry must be added through a separate reviewed GitHub PR.

## Test command (on a trusted throwaway development checkout)

```bash
lua5.1 tests/test_nquestie_m2_3_foundation.lua
```

These tests invoke only synthetic shell commands and invented in-memory SHA strings. They do not access server exports or start the comparison pipeline.

This PR **MUST stay draft and unmerged** until independently reviewed on its exact head and separately approved for merge.
