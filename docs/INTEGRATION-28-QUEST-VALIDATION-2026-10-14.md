# N-Questie — Combined 28-Quest Validation Checkpoint

**Date:** 14 October 2026  
**Branch:** `integration/nquestie-28quest-full-ci-2026-10-14`  
**Review:** [Draft PR #16](https://github.com/CosmicCuddle/N-Questie/pull/16)  
**Status:** **Testing-only integration**, no merge/release authorization and no installed-addon changes.

## Why this branch exists

The lead quest-data workstream has staged 28 individually source-verified existing-quest level corrections in:
- [#7](https://github.com/CosmicCuddle/N-Questie/pull/7): eight Dustwallow Marsh IDs;
- [#8](https://github.com/CosmicCuddle/N-Questie/pull/8): eleven early-zone IDs;
- [#13](https://github.com/CosmicCuddle/N-Questie/pull/13): nine Duskwood Mor'Ladim and Wetlands Nek'rosh chain IDs.

Grok's independent [M0 validator PR #11](https://github.com/CosmicCuddle/N-Questie/pull/11) previously covered 19 corrections and performed compiled database read-back. His [PR #12](https://github.com/CosmicCuddle/N-Questie/pull/12) provides a revision-bump safeguard. Separately, [PR #4](https://github.com/CosmicCuddle/N-Questie/pull/4) repairs inherited Busted test initialization. All remain **draft and unmerged**.

The lead workstream created this NEW integration branch **from PR #13**, copying the reviewed **public** M0 harness, synthetic fixtures, workflow, revision-guard script/tests, and PR #4's standalone test-harness fix into this branch only. **No existing PR head was edited or merged.**

## 28 reviewed levels checked explicitly

| Batch | IDs | Source and file |
|---|---|---|
| PR #7 — Dustwallow | 1166, 1168, 1169, 1170, 1171, 1172, 1205, 1252 | `Compat/NQuestieReviewedQuestLevelCorrections.lua` |
| PR #8 — early zones | 98, 126, 169, 180, 249, 256, 304, 398, 442, 895, 6284 | `Compat/NQuestieReviewedEarlyQuestLevels.lua` |
| PR #13 — Classic chains | 225, 227, 228, 229, 231, 473, 464, 465, 474 | `Compat/NQuestieReviewedClassicChainLevels.lua` |

The M0 harness verifies before/after `requiredLevel` and `questLevel` for **each ID**, including unchanged fields. A strict per-ID/per-field allow-list prevents replacing unrelated objectives, quest starters/enders, NPC/gameobject/item data or prerequisites. It asserts that 28 level correction IDs are represented, verifies their final values after compilation, and checks for inherited runtime overrides targeting corrected IDs.

This integration branch **does not add any further production quest correction**. It does not change the runtime cache revision value (`revision = 5` on PR #13).

## Combined validation evidence

**Positive M0 integration:** [GitHub run 38571850030](https://github.com/CosmicCuddle/N-Questie/actions/runs/38571850030) **PASSED**:
- 28 level corrections asserted;
- **230 positive checks** passed;
- **82,431** compiled quest fields compared with **zero mismatches**;
- 22 inherited runtime quest overrides examined; none shadow corrected N-Questie quests;
- no unapproved quest, NPC, object or item changes.

**Negative M0 integration:** Five synthetic faults were rejected with the expected messages, including a new deliberate quest **225** `requiredLevel = 29` instead of the reviewed **28**. Existing negative tests remain intact.

**Revision guard:** The initially copied guard script lacked an executable file-mode bit because of the GitHub content-copy method; the test runner invoked it as an executable and failed with status 126. The integration-only synthetic test runner now uses `bash "$SCRIPT" base` so results do not depend on that file-mode bit. After that correction, the [GitHub revision guard run 38571850279](https://github.com/CosmicCuddle/N-Questie/actions/runs/38571850279) **PASSED** all seven synthetic tests and the PR baseline check. The original Grok PR #12 remains untouched.

**Full combined CI on PR #16:** After integrating the source, revising the guard test invocation and reconciling quest 2001 evidence, the latest tested [inherited CI run 38573190617](https://github.com/CosmicCuddle/N-Questie/actions/runs/38573190617) **PASSED** LuaCheck, Busted unit-tests and Era/SoD/WotLK DB validators. The tag-only publish step did not run. On that same commit, [M0 38573190612](https://github.com/CosmicCuddle/N-Questie/actions/runs/38573190612), [revision guard 38573190572](https://github.com/CosmicCuddle/N-Questie/actions/runs/38573190572) and [overlay checks 38573190614](https://github.com/CosmicCuddle/N-Questie/actions/runs/38573190614) all **PASSED**. **This is an integrated automated testing result, not in-game QA or merge approval.**

**Dedicated overlay checks:** [Run 38571850685](https://github.com/CosmicCuddle/N-Questie/actions/runs/38571850685) passed.

Be precise about which commit each workflow tested: GitHub automatically re-runs jobs after subsequent documentation commits, and historical green results do not alone prove the newest head.

## Remaining high-priority blockers

1. **Unresolved #2/#3 documentation ancestry:** GitHub compare independently confirms PR #2 has **nine commits** missing from PR #3's ancestry, affecting four documents. The most misleading conflict was the stale `NOT YET RUN` quest 2001 smoke-test text, which **has now been corrected in this integration branch** from PR #2's genuine in-game QA evidence. **This does not resolve the underlying Git history divergence.** See [PR2-PR3-ANCESTRY-RECONCILIATION-PLAN.md](PR2-PR3-ANCESTRY-RECONCILIATION-PLAN.md) for the proposed future approval-controlled reconciliation.
2. **User-authorized in-game QA:** The headless M0 harness does not prove marker colour/visibility, UI text (including non-enUS localisation), locale, login cache persistence, IP stage eligibility, quest-chain gameplay or frame-split loading. Back up `Interface/AddOns/Questie-335` and `QuestieConfig`/`QuestieConfigCharacter` SavedVariables before any separately authorized QA build.
3. **Grok's M1 objective validation:** Independent workstream continues; do not edit their M1 development branch or infer individual objective bugs from raw SQL ID differences.
4. **Release approval:** Never merge any PR, move `335`, create tags/releases, change N-Addon-Collection or modify live AzerothCore/installed WoW files without the maintainer's explicit approval.

## Validation commands (development checkout only)

```bash
lua5.1 cli/validate-335.lua
NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 lua5.1 cli/validate-335.lua
bash tests/test_validate_335_fixtures.sh
bash tests/test_check_revision_bump.sh
bash cli/check-revision-bump.sh origin/feat/nquestie-reviewed-classic-chain-levels-2026-10-14
```

Requires Lua 5.1 and the same `bit32` environment as Grok's M0 harness. On GitHub, the approved M0 workflow itself sets `NQ_VALIDATE_EXPECT_LEVEL_COUNT=28` for its positive test. The revision-guard workflow uses the PR's actual base ref. CI uses only public Questie records and synthetic fixtures, never the private `acore_world.zip` or private seven-tab audit report.

**Collaboration source references:** [Grok's M0 details](NQ-VALIDATION-M0.md), [independent code review](REVIEW-2026-10-14.md), [revision safeguard](NQ-REVISION-GUARD.md), [28-quest scope](CLASSIC-CHAIN-LEVEL-AUDIT.md), [project handover](PROJECT-HANDOVER.md).
