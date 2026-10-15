# N-Questie — Combined M1 + 28-Quest Validation Handover

**Date:** 14 October 2026  
**Integration draft:** [PR #20](https://github.com/CosmicCuddle/N-Questie/pull/20)  
**Parent:** [PR #19](https://github.com/CosmicCuddle/N-Questie/pull/19), documentation-only private intake atop the all-green 28-level integration PR #16.  
**Status:** Test-only integration, unmerged, no release and no in-game rollout.

## Workstream ownership and source

Grok owns the report-only Lua 5.1 objective validation architecture and safety work in [PR #18](https://github.com/CosmicCuddle/N-Questie/pull/18). The lead workstream owns source-reviewed AzerothCore quest corrections (28 levels plus quest 1203 item objective), private export and integration QA.

PR #20 **copies only reviewed public M1 source, fixtures, reporter, docs and CI** from Grok's PR #18 into a fresh branch based on PR #19. It does not rewrite #18, #15, #17, #16, #19 or any other PR head. The inherited test repair from PR #4, M0 validator, revision guard and strict 28-ID allow-list were already part of PR #19's parent.

### Review-only combined implementation

- `tools/validation/ObjectiveRules.lua`: Grok's **25 report-only objective validation rules**, including kill-credit completeness requiring verified records for both creatures, `scriptedCredit=false` and one-to-one unmatched targets before `M-NPC-TARGET`.
- **Ambiguous multi-target sets** return manual review; no fabricated positional replacement pairs. Reordering alone produces an ordering note.
- Conditions/IP/script flags support `true`, `false` and `"unknown"`. No character quest availability is asserted.
- Synthetic fixtures, `tests/test_nquestie_objective_rules.lua`, Busted spec, shared runner, diagnostic CLI and the active M1 workflow run **without private data**.
- The only modification to the existing 28-quest `cli/validate-335.lua` is the M1 block checking *real Questie records for quest 1203*: stock item objective 33110 yields `CONFIRMED_MISMATCH` versus server-shaped reviewed item 3853; corrected effective N-Questie objective yields `EXPECTED_REPRESENTATION_DIFF`.
- **No level correction code, TOC, cache revision, user-facing runtime addon behavior, quest-NPC links, item records or private SQL is modified by this draft.**

## Verification and gates

Dedicated M1 GitHub [run 38580760515](https://github.com/CosmicCuddle/N-Questie/actions/runs/38580760515) **PASS** on initial integrated source: 29 synthetic scenarios exercising 25 rules, unchanged inputs, 31 Busted tests with 0 failures/errors, and Lua 5.1 parser/CLI checks.

Dedicated overlay [run 38580760610](https://github.com/CosmicCuddle/N-Questie/actions/runs/38580760610) and revision guard [run 38580760706](https://github.com/CosmicCuddle/N-Questie/actions/runs/38580760706) **PASS** on initial source commit.

**Full combined acceptance: achieved on source + handover commit `4470f3657483dfcdee08a080f22f258f6c1a51bd`.** All five GitHub workflows PASSED on that exact head: [M1 38581451391](https://github.com/CosmicCuddle/N-Questie/actions/runs/38581451391), [M0 38581451396](https://github.com/CosmicCuddle/N-Questie/actions/runs/38581451396), [overlay 38581451217](https://github.com/CosmicCuddle/N-Questie/actions/runs/38581451217), [revision guard 38581451165](https://github.com/CosmicCuddle/N-Questie/actions/runs/38581451165), [inherited full CI 38581451178](https://github.com/CosmicCuddle/N-Questie/actions/runs/38581451178). The inherited run passed LuaCheck, Busted with PR #4 shim, WotLK/Era/SoD database validators, and appropriately skipped tag-only publishing.

Detailed [first integrated M0 run 38580760502](https://github.com/CosmicCuddle/N-Questie/actions/runs/38580760502) reports **232 assertions**, **28** reviewed level corrections, **82,431** quest fields checked (zero mismatches), five expected synthetic rejections and quest 1203 stock/effective M1 classifications. **Later documentation commits start new CI; check PR #20's newest head rather than assuming a previous green SHA validates future changes.** None of these automated results constitutes in-game QA or release permission.

## M2 interface handoff

- [Grok M2 plan](NQ-VALIDATION-M2-PLAN.md) is **proposed, not implemented**. Grok owns strict M2.1 input contract/validator, effective-record export and report-only batch engine.
- [Lead private M2 intake](M2-PRIVATE-OBJECTIVE-INTAKE-HANDOVER.md) describes a **standalone local-only exporter** for 1–50 explicitly selected offline SQL quest records, which passed 12 synthetic tests and correctly read quest 1203 item 3853×1 and quest 2001 creatures 1868×8 / 1869×8 privately.
- The private adapter emits `killCreditComplete=false`, `hasConditions="unknown"`, `ipGated="unknown"` and `scriptedCredit="unknown"`. It does not invent evidence of complete creature KillCredit coverage, IP eligibility or scripted objective behavior.
- A later **private-only** M2 pilot should pair quest 1203's server row against the compiled 28-quest N-Questie objective after M2.1/2.2 validation. Only aggregate classification statistics, separately reviewed, may be published.
- **A green M1 suite does not approve the 24 remaining item or 151 NPC objective candidates for correction.** Confirmed findings still require explicit human review and a separate draft correction PR.

## Remaining blockers and safety

1. **PR #2 / #3 diverged documentation ancestry** (nine extra PR #2 commits). The integration docs reflect observed quest 2001 in-game marker lifecycle, but original ancestry remains unresolved; see [reconciliation plan](PR2-PR3-ANCESTRY-RECONCILIATION-PLAN.md).
2. **No approved in-game QA of existing quest corrections**. Back up installed `Interface/AddOns/Questie-335` and `QuestieConfig` / `QuestieConfigCharacter` SavedVariables before any separately authorised test build.
3. **M2 not implemented**. Nothing here runs live SQL, changes realm/account/character databases, modifies IP/playerbots or SavedVariables, releases addons, merges any PR or publishes the private `acore_world.zip`.
4. **No automatic merges/tags/releases/N-Addon-Collection updates**. All deployment and release gates remain with the maintainer.

**Source-of-truth:** This handover, [Project handover](PROJECT-HANDOVER.md), [Roadmap](ROADMAP.md), [M1 review details §10](NQ-VALIDATION-M1.md), and [M2 plan](NQ-VALIDATION-M2-PLAN.md).
