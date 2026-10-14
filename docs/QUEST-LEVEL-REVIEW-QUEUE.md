# N-Questie — Next Existing-Quest Level Review Queue

**14 October 2026 · Planning and source comparison only · No corrections authorized in this file**

## Purpose

The full private AzerothCore vs installed Questie comparison identified **270 quest IDs** with at least one differing minimum/nominal quest level **after literal numeric Classic/TBC/WotLK correction-layer approximation**. They are **review candidates**, not automatically broken quests.

The first eight Dustwallow records are staged in draft PR #7. Eleven early-game quests are staged in draft PR #8, using narrow source-value guards and Lua 5.1 tests.

The following groups are the next useful *read-only review candidates* because they form recognizable Classic-zone quest chains or accessible ordinary quests. The numbers below come from a private offline server export; this document publishes **only these selected IDs and their specific level fields**, not the export or the complete candidate report.

## Candidate group A — Duskwood: Mor'Ladim chain

| ID | Quest | Questie min / level | Server min / level | Server predecessor |
|---|---|---|---|---:|
| 225 | The Weathered Grave | 25 / 30 | 28 / 35 | 0 |
| 227 | Morgan Ladimore | 25 / 30 | 28 / 35 | 225 |
| 228 | Mor'Ladim | 25 / 30 | 28 / 35 | 227 |
| 229 | The Daughter Who Lived | 25 / 30 | 28 / 35 | 228 |
| 231 | A Daughter's Love | 25 / 30 | 28 / 35 | 229 |

- Each quest has at least one starter and one ender linked in the private server export.
- Quest **225** has an inherited TBC `requiredLevel` correction; its **post-literal-correction** value shown above is 25. Check the real effective 3.3.5a data before approving anything.
- The five server predecessor IDs are included as context only. Do not replace Questie's quest chain or unlock state just because numeric levels differ.
- After Grok's M0 integration harness is available, verify all five levels and the previous quest chain are preserved in the effective DB.

## Candidate group B — Wetlands: Nek'rosh sequence

| ID | Quest | Questie min / level | Server min / level | Server predecessor |
|---|---|---|---|---:|
| 473 | Report to Captain Stoutfist | 23 / 26 | 23 / 28 | 0 |
| 464 | War Banners | 23 / 26 | 23 / 28 | 473 |
| 465 | Nek'rosh's Gambit | 23 / 26 | 23 / 31 | 464 |
| 474 | Defeat Nek'rosh | 23 / 26 | 23 / 32 | 465 |

- Each ID has starter and ender associations in the private export.
- These are **nominal quest-level** differences; their recorded minimum levels match.
- Higher quest-level values may change tooltip colours at particular player levels; no forced colour mapping is proposed.
- Keep NPC objectives, required counts, locations, prerequisites and quest completion status unchanged.

## Candidate group C — Hillsbrad wanted quests

| ID | Quest | Questie min / level | Server min / level |
|---|---|---|---|
| 566 | WANTED: Baron Vardus | 17 / 40 | 35 / 40 |
| 567 | Dangerous! | 17 / 28 | 19 / 28 |

- Quest 566 has an unusually large minimum-level change: **17 → 35**, with nominal level 40 already agreeing. Prioritize game/source verification before approving any client visibility correction.
- Quest 567 is a smaller minimum-level mismatch. Neither is a reason to replace NPC/item objectives.

## Explicit pause points and responsibilities

1. **Source validation:** Recheck the private world fields and existing Questie correction layers for each nominated ID.
2. **Effective DB integration:** Wait for the separately assigned Grok M0 validator to confirm real Lua 5.1 loading and post-correction values. The current raw-plus-literal audit is only an approximation.
3. **IP and conditions:** Character-specific Individual Progression stage, server-side conditions and scripted gating are not established by static SQL. Do not infer an eligible quest purely from nominal/minimum levels.
4. **Correction proposal:** Any further approved batch should use a separately named draft branch, narrow field-level changes, source guards, source-baseline test, and synthetic Lua regression. Do not modify Grok's validation files or another contributor's branch.
5. **Manual game QA:** Back up installed Questie and SavedVariables before any maintainer-authorized QA package test. Never merge, tag, release or change N-Addon-Collection without explicit approval.

**This is a development queue, not a user-visible quest correction release.**
