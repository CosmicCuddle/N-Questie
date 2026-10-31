# Part 55 — Gate10 strict-latch M2 proof and Vanilla quest display gates

**31 October 2026 | Research/test-only draft | NOT an installation, merge or release.**

This document is a public-safe operational handover for N-Questie Part 55, based on [Gate10 draft #457](https://github.com/CosmicCuddle/N-Questie/pull/457) and the private owner-only Part 54 history. The raw world archive and private analyses remain **outside GitHub**.

## Exact branch and ownership

- **Protected default `335`** remains separate and must not be changed by this research.
- **CS02 owns runtime candidate** `feat/part53-gate10-1207-1209-cs02`, reviewed head `d815548cbfef88d9f0c1f429ea7e6bf48214cddc`; PR #457 is DRAFT/UNMERGED.
- **CS01's isolated test-only branch** `test/part55-gate10-m2-latch-proof-20261031-cs01` begins at the **exact strict-latch head** and adds a copied, source-authenticated test (`tests/test_nquestie_m2_gate10_delta.sh`) and a **branch-only push workflow** (`.github/workflows/nquestie-part55-gate10-m2-latch-proof.yml`). The strict-latch loader, data, TOC and frozen M2 golden are untouched.
- Previous CS01 Part54 test-only branch `9e9ecdf0...` was based on an earlier, *pre-latch* implementation. Do not confuse results across branches.

## Evidence and truthful status

| Gate | Result / next proof |
| --- | --- |
| Gate10 Lua synthetic loader + failure-latch | **CS02-reported PASS:** 94/94 normal, both adversarial modes, 24/24 mutations, Lua 5.1 and 5.4, at `d815548c`. Not native client evidence. |
| Existing M2 Busted framework | **RED:** completed run [41227924456](https://github.com/CosmicCuddle/N-Questie/actions/runs/41227924456) reports 169 successes and 2 failures in frozen 9,159-count-dependent real-DB tests; no private stdout in wrapper. |
| Prior CS01 simplified opt-in M2 test `98b0aebb` | **CS02-reported Lua5.1 PASS** at its exact head; not proof of the later 5-objective or all-record checks. |
| Part55 5-objective Gate10 / strict-latch M2 test | **NOT YET VERIFIED:** genuine Lua 5.1 export must prove 9,162 total / 8,404 supported / 758 unsupported, five item objective IDs and order, unchanged six refusal aggregates, and zero internal round-trip differences. |
| Optional full old-record comparison | **NOT YET VERIFIED:** independently export protected `335@26053bd28b0df3a01e5859f779d5f3cb4f57b221` from a temporary checkout and compare all **9,159** complete *v2 structural* old quest records; exactly 1207–1209 may be added. |
| Native WoW 3.3.5a/IP marker/loot/phase | **UNKNOWN:** no authorization or evidence here. |
| Gate08 atomic compiled cache / saved-variable recovery / RAM-GC | **MAJOR RED.** |

## Safe, decisive run scope

GitHub push-only workflow `nquestie-part55-gate10-m2-latch-proof.yml` executes these two commands in the **isolated branch only** using real Lua **5.1** + bit32 (not Lua 5.4; inherited `cli/dump.lua` calls `getfenv`):

```sh
bash tests/test_nquestie_m2_gate10_delta.sh
NQ_GATE10_COMPARE_335=1 bash tests/test_nquestie_m2_gate10_delta.sh
```

GitHub's PR-triggered-commit-run connector query does **not** list push-only Actions runs. **Do not call this test PASS merely because the branch and workflow files exist.** Inspect an actual Actions run and job logs and record the precise test head and first failure, if any. No package, artifact upload, native game test, server write or release step was added.

**Decision rule:** If it passes, record that the public M2 *structural* data delta is isolated. That still does **not** clear the original two RED frozen 335 Busted acceptance tests; a separately reviewed Gate10-specific variant is required. Never globally re-pin the historical test file `tests/test_nquestie_m2_v2_export_integration.sh` or `tools/validation/M2V2RoundTrip.test.lua`.

## Missing Vanilla quests — diagnosis not blanket approval

- The previously identified **439 RAW** candidates included existing custom quest 2001; private Part54 reconciliation recorded **438 effective server-only candidates**, not 438 confirmed eligible Vanilla quests. Eligibility depends on current progression, faction, conditions, player level and possibly dynamic/IP gates.
- Gate10's proposed 1207, 1208, 1209 are a **three-quest candidate pilot**, not a release-ready correction. The private snapshot found the quest-1207 description **22** versus recorded required count **20**, and quest-1209 wording/item-label correspondence problematic for **all three slots**. Preserve those decisions for CosmicCuddle; do not change SQL, objective ordering, drops or prose without owner approval.
- Differentiate **(A)** server quest availability, **(B)** effective compiled quest indexing, **(C)** current-character/AQ/hidden/doability filtering and **(D)** object/NPC location mapping. [PR #456](https://github.com/CosmicCuddle/N-Questie/pull/456) covers invented source-executed filter fixtures; it is not proof of a real missing quest.
- Keep explicitly owner-deferred quest IDs **30000–30004** excluded. Preserve quest **2001** and its previously tested marker lifecycle.
- Never upload the private `acore_world.zip`, extracted SQL, per-character data or complete source crosswalk.

## Wrong or misleading map pins — task NQ-MAP-ACCURACY-001

Queued **after** the missing-quest proof: evaluate each quest target's *actual active* world spawns, not every historical/shared template spawn. Compare server map/phase/conditions to Questie zone-local coordinate transforms, then spot-check both minimap and world-map markers in an owner-approved disposable native 3.3.5a test. Do not fabricate exact spawns or remove unrelated legitimate pins simply to reduce clutter.

## Next evidence request to CS02

1. Inspect branch-specific Actions/logs for the **Part55 test branch** and report actual Lua5.1 PASS/FAIL for each command, including exact source SHA.
2. If RED, provide the *first failing assertion/log*, classify as script, dependency, baseline or real field-delta failure. Fix only on a new reviewable test branch.
3. Only after a confirmed complete data-delta run, propose a **separate Gate10-specific M2 variant** retaining the frozen original 335 baseline. No merge/packaging/native trial without owner approval.

All feedback belongs in the **existing PR #457** discussion; do not create a duplicate cross-project Issue.
