# N-Questie Gate10 — Part53 deterministic source-preprovision review contract

**31 October 2026 | PUBLIC-SAFE | DESIGN/TEST ONLY. Not a release, production runtime patch, native acceptance, or permission to publish private records.**

## Decisions and current ownership

CosmicCuddle directly confirmed sending the [owner-private review package](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6545302977). CS02 subsequently [confirmed 5/5 verified file hashes and passing private validators](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6545317651). CS02 separately [reported the owner's privacy/source decisions](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6545339454): only independently verified player-visible fields may ship in public addon files, and the item whose source remains unproven **must not** receive a placeholder, guessed source or marker. The original private audit and any sensitive source data remain private. **CS02 retains the 1207–1209 implementation claim**. There is no separate owner approval yet for a live addon/source patch, public release, native test or world SQL edit.

## Protected 335 source-backed execution order and remaining proof limits

Protected base `335` at `26053bd28b0df3a01e5859f779d5f3cb4f57b221`:

- `Modules/QuestieInit.lua` invokes `QuestieInit:LoadBaseDB()`, then `QuestieCorrections:Initialize()`, then `QuestieDBCompiler:Compile()` upon a custom revision mismatch.
- `Database/Corrections/QuestieCorrections.lua` applies inherited Classic, TBC and WotLK corrections, including `QuestieWotlkNpcFixes:LoadAutomatics()`, `QuestieWotlkItemFixes:Load()` (which calls `InsertMissingItemIds()`) and automatic item starters **before** it calls `QuestieCompat.LoadCorrections()`. Then it also runs quest-race auto-patching: unresolved/guessed NPC faction friendliness can affect UI eligibility for quests whose required race mask is zero.
- `Compat/Compat.lua` iterates correction groups with `pairs(correctionsRegistry)`, so group callback order is nondeterministic. Within one group, callback registration is ordered via `ipairs`.
- `Compat/NQuestieCustomQuestLoader.lua` memoizes `approvedQuests()` at the first invocation and requires NPC, object **and item** rows to exist at that point. Reverse-index `relationUpdates` only patches already-existing records. Existing `parseQuest` refuses mixed objective categories pending native ordering proof.

**Feasible design seam, not yet code approval:** after `if approved then return approved end`, a single non-yielding `provisionSources()` preflight can examine source records against the effective post-inherited QuestieDB, and only then construct approval results. Calling it unconditionally before the memo guard would re-run it per group and create a self-collision.

## Full-batch acceptance: source validation by itself is insufficient

1. Treat the proposed three-quest set and every required source/reverse index as **one candidate batch**. Validate Questie codec allow-list and packed lengths, no anonymous server-only keys, proper zone-keyed map spawn format, authentic player-visible source provenance, current owner policies and *effective* ID collision checks.
2. Validate all three proposed quest rows, prerequisites, objective class, faction/IP/phase/character restrictions and dependency closure **before any direct write**. Reject the entire Gate10 candidate set on any unknown or failed mandatory source. In particular, do not insert ten source rows while all three new quests are rejected by a later `parseQuest` or prerequisite-cycle pass.
3. Prepare a detached complete write set. Only after successful validation should a bounded no-yield candidate source commit be considered. Any validator failure or exception leaves the original tables unchanged, with original curated quest 2001 and all inherited fixes intact. Proven source-writer ownership and whole-cache publication remain separate **Gate08 MAJOR RED** barriers; a merely no-yield ordinary Lua loop does not solve re-entrant/other-addon mutation.
4. No guessed loot-template-to-NPC conversion, source-less item marker, unverified world→zone transform, random/alternative spawn, global hiding bypass or server SQL patch.
5. Test every callback-group ordering and all ten independent source removals/collisions; confirm full rejection/no source writes on failure and positive admission only when all mandatory evidence is present. Confirm reverse links, public 2001 fingerprint even with raw-ID collision and missing 437, revision-triggered recompile, effective post-correction readback, cancellation/crash/relog, and native 3.3.5a/IP eligibility **in the correct separately authorised test stages**.

## Synthetic fixture reuse

- Historical first protected-335 witness: [12 checks](https://github.com/CosmicCuddle/N-Questie/blob/test/part53-preprovision-335-source-proof-20261031-cs01/tests/compat/nq_part53_source_preprovision_boundary.lua), independently 12/12 Lua5.1/5.4.
- [15-assertion child](https://github.com/CosmicCuddle/N-Questie/blob/8f0a51a8586c340362d249423898762cba8e267b/tests/compat/nq_part53_source_preprovision_boundary.lua): **CS02 independently verified 15/15** on both Lua interpreters and killed the 437 exception mutants.
- [18-assertion child](https://github.com/CosmicCuddle/N-Questie/blob/a2c3ad9d4243e69428212b3c00649c4f54017c49/tests/compat/nq_part53_source_preprovision_boundary.lua): adds occupied raw-2001 exception, not yet executed.
- **This branch** `test/part53-source-preapproval-injection-hook-20261031-cs01`: adds optional **`scenario(..., beforeFirstApproval)`** hook called **after original loader callback registration and before the first callback**; four new invented-ID-only checks (total **22**) show the pure source-injection ordering condition with object callback first and 2001 preserved. This is a mock-harness seam **not** a real `provisionSources()` production call. **22-check run unverified**; request independent Lua5.1/5.4 and mutant review before any PASS claim.

## Merge, release, privacy and future task limits

No real private audit rows or coordinates in public GitHub and no source/core/SQL/client install. No PR opened because existing PR workflows may upload public addon ZIP artifacts. Protected `335` remains untouched. Only test harness and this review note are added on an isolated child. The separate owner-requested [NQ-MAP-ACCURACY-001](../NQ-LIVING-PROJECT-MASTER-CHECKLIST.md) is queued **after** the missing-quest correction effort, not before.
