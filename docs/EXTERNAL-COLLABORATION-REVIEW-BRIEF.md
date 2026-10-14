# N-Questie — External Collaboration and Integration Review Brief

**Date:** 14 October 2026
**Status:** Review assignment, not authority to deploy or merge
**Project:** [CosmicCuddle/N-Questie](https://github.com/CosmicCuddle/N-Questie)
**Supported client:** World of Warcraft 3.3.5a (Interface 30300)
**Maintainer approval required for all merges, releases, installs and live-server actions**

## 1. Collaboration model

The maintainer may invite a second reviewer/developer (Grok) to assist with N-Questie.

**Lead implementation and source-of-truth work:** Maintain the curated offline server-data comparison, verified field-level quest corrections, review manifests, developer testing, project roadmap and handover. Quest data and eligibility claims must be grounded in the maintainer's actual AzerothCore world export and runtime module behaviour, not generic stock-WotLK assumptions.

**External review assignment:** Independently inspect the public N-Questie **correction-integration and test architecture**. Report weaknesses and propose narrow fixes, without duplicating private data audits or silently rewriting current development branches.

**Ownership rule:** Do not have two developers edit the same GitHub branch/file simultaneously. Review and discuss in PR comments; if an implementation is approved, open a **separate named branch and draft PR**, documenting its exact base and the files owned. Do not change PR #2–#7's heads without the maintainer's explicit coordination.

## 2. Primary assigned task — correction integration audit (Grok)

Inspect the public N-Questie repository and draft PRs below, **read only at first**:

- [PR #2 — Curated custom quest overlay](https://github.com/CosmicCuddle/N-Questie/pull/2)
- [PR #3 — Reviewed JSON-to-Lua quest generator](https://github.com/CosmicCuddle/N-Questie/pull/3)
- [PR #4 — Isolated inherited CI/Busted fixture repair](https://github.com/CosmicCuddle/N-Questie/pull/4)
- [PR #5 — Read-only existing quest-level audit](https://github.com/CosmicCuddle/N-Questie/pull/5)
- [PR #6 — Jarl Needs a Blade item objective correction](https://github.com/CosmicCuddle/N-Questie/pull/6)
- [PR #7 — Eight Dustwallow quest-level corrections](https://github.com/CosmicCuddle/N-Questie/pull/7)

### Key code files to inspect

- `Questie-335.toc` and `Modules/QuestieInit.lua` — 3.3.5a load order and compiled quest database revision/cache invalidation.
- `Modules/QuestieCompat.lua`, `Compat/Corrections.lua` and `Database/Corrections/*QuestFixes.lua` — registration and application order, actual shape/timing of `QuestieDB.questData`, and whether several `RegisterCorrection("questData", callback)` registrations compose safely.
- `Compat/NQuestieCustomQuestLoader.lua`, `Compat/NQuestieExistingQuestCorrections.lua`, `Compat/NQuestieReviewedQuestLevelCorrections.lua` — how corrections operate on existing and missing IDs; guards for 3.3.5a, later upstream modifications and malformed data.
- `Compat/NQuestieCustomQuestData.lua` — proposed revision increases and compatibility with old SavedVariables/cache.
- `tests/test_nquestie_overlay.lua`, `tests/test_nquestie_existing_quest_1203.lua`, `tests/test_nquestie_reviewed_dustwallow_levels.lua`, `setupTests.lua` and `.github/workflows/nquestie-overlay.yml` — whether mocks reflect real integration and detect regressions.

### Questions to answer

1. **Correct registration and execution timing:** Are additional correction callbacks installed before Questie finalizes its quest database? Does QuestieDB.questData contain decoded Lua tables when guarded callbacks inspect it, or can it still be serialized as a string?
2. **Cache invalidation:** Does `nQuestieDataRevision` reliably trigger a rebuild when an existing-quest correction changes, and do SavedVariables survive unchanged?
3. **Correction composition:** Can quest 2001 overlays, quest 1203 item objective changes and the eight Dustwallow level changes all survive the combined correction pipeline and the inherited Classic/TBC/WotLK correction layers?
4. **Safety:** Are source-value guards overly strict, ineffective, dependent on application order, or capable of dropping unrelated objective/item text, kill credit, NPC or quest-chain fields?
5. **CI realism:** Does PR #4's test harness repair integrate safely with PR #7's stacked branch, and are any important real-world load-order cases untested? Do not claim the green PR #4 run proves PR #7's combined CI passes.
6. **3.3.5a compatibility:** Confirm Lua 5.1 syntax and that other-version Questie behaviours remain excluded.

**Priority:** A code-backed integration issue that would prevent PR #6/#7 from working in-game takes precedence over style, refactoring or mass quest-data additions.

## 3. Secondary optional assignment (only after the integration review)

Review how Questie's `sourceItemId`, `objectives[3]` and `requiredSourceItems` map to objective markers and item quantities. Develop **synthetic public test fixtures only** to help distinguish harmless encoding differences from actual wrong item targets. The lead implementation team can then apply those semantics to its existing private comparison of 24 item-objective candidates.

No need for direct access to the full private `acore_world.zip`, the private seven-tab Excel audit, game credentials or player information to accomplish the primary task. If access to a narrow private record is later necessary, ask the maintainer for permission and use a redacted extract with only the relevant quest/objective fields.

## 4. Deliverable expected from Grok

Submit one **read-only review report** containing:

| Field | Required content |
|---|---|
| Finding | Clear description, severity (blocker / important / improvement) |
| Code evidence | Exact GitHub path, branch or commit SHA, function and line numbers |
| Reproduction | Commands, minimal synthetic Lua test or code path to reproduce; distinguish observed from suspected behaviour |
| Impact | Which quests or screens are affected (quest 2001, quest 1203, eight Dustwallow levels, existing vanilla quests) |
| Recommended fix | Narrowest change possible and exact files that would change |
| Confidence / uncertainty | Any runtime behaviour that still needs in-game verification |

Use GitHub PR review comments or provide a Markdown report to the maintainer. **Do not silently commit changes** to another contributor's branch. If an approved implementation task emerges, open a separately named draft PR with unit/integration tests, test logs and rollback notes.

## 5. Safety and release boundaries

- **Never upload** the raw `acore_world.zip`, database exports, private CSV/Excel/JSON comparisons, SQL credentials, server hostname or unrelated personal/player data into public GitHub or external review platforms.
- Do not modify the live AzerothCore database, Individual Progression, mod-playerbots or client data files as part of this review.
- Do not replace the installed working `Interface/AddOns/Questie-335`, delete SavedVariables, reset characters/quest states or require a second test server.
- Back up the installed addon, SavedVariables and any approved production files **before** any later maintainer-authorized in-game QA changes; provide clear rollback steps.
- Preserve upstream Questie licences and credits.
- No direct pushes to `335`, no PR merges, version tags, GitHub releases or N-Addon-Collection updates without explicit maintainer approval.
- This is a **review task**, not an instruction to publish final changes. Prioritise correctness and documentation over speed.

## 6. Current confirmed facts versus pending work

**Confirmed:** Quest 2001 completed its observed in-game icon lifecycle (available, objectives, complete, marker removal after hand-in). Private source checking confirmed quest 1203 requires one Moonsteel Broadsword (3853), while the original Questie WotLK objective uses Razorspine's Sword (33110); its levels already match. Eight Dustwallow numerical level candidates were source-verified and staged in PR #7. PR #4 passed full inherited CI **in isolation**, while the stacked branch's inherited tests remained failing without its fixture changes.

**Pending:** Combined PR #4 + stacked PR #2/#3/#5/#6/#7 integration CI, in-game QA of quest 1203 and the eight numeric changes, dynamic/character-specific Individual Progression visibility, remaining all-server discrepancy triage. The private audit workbook is a candidate list, not authoritative approval for mass patching.

**Primary coordination document:** `docs/PROJECT-HANDOVER.md` (latest checkpoint first); supporting materials in `docs/ROADMAP.md`, `docs/DEVELOPMENT-LOG.md`, `docs/FULL-SERVER-QUEST-AUDIT-CHECKPOINT.md`, `docs/DUSTWALLOW-QUEST-AUDIT.md`.
