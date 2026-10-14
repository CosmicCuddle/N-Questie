# N-Questie — Collaboration and Integration Status

**Snapshot:** 14 October 2026  
**Purpose:** A single current entry point for the lead quest-data workstream and the external validation workstream.  
**Important:** All referenced changes are in **draft, unmerged** pull requests unless specifically stated otherwise.

## Latest checkpoint: revision CI activation and Hillsbrad review (14 October 2026)

- **Grok PR #12:** Independently implemented a CI-only `NQuestieCustomQuestData.revision` bump guard with seven synthetic cases. The runtime cache mechanism is not changed.
- **Lead PR #14:** Independently activated the guard's proposed GitHub workflow on a separate draft branch stacked on #12, without changing Grok's source branch. GitHub [run 38569424455](https://github.com/CosmicCuddle/N-Questie/actions/runs/38569424455) **PASSED**; this is an isolated workflow result, *not* combined 28-quest CI.
- **Hillsbrad source candidates:** Quest 566 has inherited min 17/server min 35, quest 567 has 17/19. Actual quest-levels (40/28), gameobject starters (1763/2008), quest-ender NPC 2215 and objective target IDs agree. Explicit `conditions` quest-ID references were not found in 17,701 exported rows; IP and indirect conditions remain unverified. **Neither quest has been added to a correction PR.** See [HILLSBRAD-WANTED-QUESTS-REVIEW.md](HILLSBRAD-WANTED-QUESTS-REVIEW.md).
- **Next combined integration gate:** Both the cache guard and Grok's 3.3.5a M0 validator need to run against the **same future review branch** containing 28 source-approved quest level corrections, then inherited PR #4 Busted repairs, before any merge consideration.

## 1. Development ownership

| Workstream | Maintainer/contact | Area | GitHub PRs |
|---|---|---|---|
| Quest data and safe per-quest corrections | Lead quest-data workstream | Private source audit, curated quest levels, custom importer, in-game QA planning | #2, #3, #5, #6, #7, #8, #13 |
| Validator and reliability review | Grok | Real 3.3.5a correction/compile harness, negative tests, validation rule design, revision bump safeguard | #9, #11, #12 |
| Workflow enablement (with contributor's read-only source preserved) | Lead quest-data workstream | Enable independently reviewed M0 workflow without touching Grok's branch | #10 |
| Inherited CI repair | Separate unmerged fixture branch | Busted `QuestieCompat` test initialization and LuaCheck globals | #4 |
| Project foundation | Main docs branch | Handover, initial plan and safeguards | #1 |

Review and comments are collaborative; **never rewrite another contributor's branch without coordination and maintainer authorization**.

## 2. Branch relationships and independent work

Original correction stack:

```text
335
  └─ #1 Foundation docs
       └─ #2 Custom quest overlay (quest 2001)
            └─ #3 Curated offline generator
                 └─ #5 Read-only quest-level audit
                      └─ #6 Jarl Needs a Blade item correction (1203)
                           └─ #7 Eight Dustwallow quest levels
                                └─ #8 Eleven early-zone quest levels
                                     └─ #13 Nine Classic chain quest levels
```

Validation branches are independently based on **#7**:

```text
#7 ├─ #9 M0 validation harness
   │    └─ #10 GitHub Actions workflow activation
   ├─ #8 Eleven early-zone fixes
   └─ #12 CI-only cache revision-bump guard

#11 is a *separate integration test PR* combining #10 and #8,
     with explicit support for 19 existing-quest level changes.
#13 is stacked on #8 and has NOT yet been integrated into #11.
#4 is independent on 335 and repairs the pre-existing full CI failure.
```

**Ancestry caution:** Grok's review previously found a documentation-commit gap between PR #2 and PR #3 that can cause merge conflicts. Resolve that as a coordinated review task before merging the stack, preserving in-game quest 2001 QA notes.

## 3. Curated corrections ready for future QA

| Scope | Draft | IDs / coverage | Verification |
|---|---|---|---|
| New custom quest | #2 | 2001 Ravenclaw Cleanup | Observed in-game marker lifecycle passed on an earlier approved QA test; specific new patches not thereby validated |
| Existing item objective | #6 | 1203 Jarl Needs a Blade — one Moonsteel Broadsword (3853), not WotLK item 33110 | Private world source confirmed; real 3.3.5a M0 harness passed for this record; no new in-game QA yet |
| Dustwallow level differences | #7 | 8 IDs: 1166, 1168, 1169, 1170, 1171, 1172, 1205, 1252 | Dedicated Lua 5.1 and Grok real-335 M0 checks passed; in-game QA pending |
| Early-zone level differences | #8 | 11 IDs: 98, 126, 169, 180, 249, 256, 304, 398, 442, 895, 6284 | Dedicated Lua 5.1/source checks passed; included in Grok's separate combined M0 draft #11 |
| Classic chain levels | #13 | 9 IDs: 225, 227, 228, 229, 231, 473, 464, 465, 474 | Dedicated Lua 5.1/public baseline tests passed on [workflow 38567305494](https://github.com/CosmicCuddle/N-Questie/actions/runs/38567305494); **not yet integrated with M0** |

**Total existing-quest level IDs currently staged:** **28** (8 + 11 + 9). All use guarded `questLevel` and/or `requiredLevel` corrections only. They do not force difficulty colours. None is an approved game release or evidence of actual character/IP availability.

The separate `NQuestieCustomQuestData.revision` marker increased with correction stacks #6/#7/#8/#13; current proposed value on #13 is **5**. Grok's PR #12 would enforce revision-bump discipline through CI only, without changing runtime cache behaviour.

## 4. Automated test truth

- **PR #13 dedicated overlay checks: PASSED** on [run 38567305494](https://github.com/CosmicCuddle/N-Questie/actions/runs/38567305494). Covers the nine-quest Lua correction regression, public WotLK source baselines and special quest 225 TBC correction.
- **PR #13 inherited `CI`: FAILED** at `unit-tests` on [run 38567305560](https://github.com/CosmicCuddle/N-Questie/actions/runs/38567305560). This PR lacks independent fixture fix #4; the separate `lua-check` job passed.
- **PR #10 M0 live GitHub workflow: PASSED** [run 38565400913](https://github.com/CosmicCuddle/N-Questie/actions/runs/38565400913) for original eight Dustwallow corrections, quest 1203 and quest 2001 plus synthetic failures. This is an off-client real-database compilation test, **not an in-game client login test**.
- **Grok PR #11:** The contributor reports local M0 real-database validation of the combined 19 level corrections and compiled-roundtrip checks; consult its individual branch CI and acceptance before asserting full integration success.
- **PR #4:** Independent inherited Busted fixture tests passed in isolation; it has **not been integrated** with the current stack.

**Combined all-PR green CI has not yet been achieved.**

## 5. Data/privacy and approval boundaries

The private `acore_world.zip`, the installed quest database supplied directly in chat, the seven-tab private audit and the per-quest full mismatch list stay **off public GitHub**. GitHub documents only narrow, necessary per-quest corrections and aggregate review findings.

- No live AzerothCore queries/writes, module config edits, character quest/progression changes or player data transfers.
- Never replace the installed WoW `Interface/AddOns/Questie-335` or clear `QuestieConfig` / `QuestieConfigCharacter` SavedVariables without a maintainer-approved QA backup/rollback plan.
- No merges into `335`, GitHub tags/releases, addon collection updates or automated public deployments without explicit maintainer authorization.

## 6. Next action owners

**Quest-data workstream:** Finish source/data review of the next candidate quests, especially Hillsbrad 566's unusual minimum-level difference. Avoid further bulk additions while integration M0 and revision safeguards are being coordinated. Document source verification and selectively stage patches only when validated.

**Grok's validation workstream:** Keep the M0 source PRs separate; coordinate a future combined 28-quest harness with exact allow-list and before/after/compiled assertions for the nine IDs from PR #13. PR #11 currently covers 19. Maintain independent CI-only cache guard PR #12. Continue objective-validation M1 after M0 acceptance.

**Integration review:** Compare CI workflow additions (#10), cache guard (#12), test fixture fix (#4), and the correction stack. Resolve documentation ancestry (#2 → #3) with an explicit plan and test on a temporary staging branch. Seek maintainer approval before any merge.

**In-game QA:** Only after the integrated branch is verified and backup instructions agreed. Check gameobject quest starts/ends for IDs 225/231 and 465/474 specifically.
