# N-Questie — Development Handover

**Project:** N-Questie  
**Maintainer:** CosmicCuddle  
**Established:** 13 October 2026  
**Repository:** https://github.com/CosmicCuddle/N-Questie  
**Default/source branch:** `335`  
**Fork parent:** https://github.com/divial28/Questie-335  
**Client:** World of Warcraft 3.3.5a (`## Interface: 30300`)  
**Inherited addon identity:** `Questie-335.toc`, display title `Questie-335`, upstream version `9.5.1`  

## Current verified intake — 14 October 2026 (installed quest file + full server audit)

**Installed file verified:** Maintainer uploaded the working addon's `Database/Wotlk/wotlkQuestDB.lua`. Its git blob is `abbf2831b6d6b54b5d9383ba2c3e5cce5147379d`, identical to the N-Questie repository's original WotLK quest source. No installed version discrepancy.

**Private all-server audit completed:** 9,525 server quest templates versus 9,086 original Questie entries; 439 server-only IDs, most unlinked/unused/NYI, with only 18 *plausibly linked* non-placeholder quests needing eligibility review. Initial raw level mismatches: 139 nominal, 150 minimum across 259 unique quests. After literal inherited correction-layer approximation: **270** unique level candidate IDs (148 nominal, 154 minimum, overlapping). Of 1,484 raw item differences, **1,460** match Questie's separate `sourceItemId` representation; **24** require follow-up. Additional NPC/GO and chain mismatches are candidates, not accepted fixes.

**PRIVATE handover artifact:** A seven-tab Excel workbook of candidate mismatches was generated for the maintainer inside the conversation. Do not push that file, the private original SQL ZIP, full data JSON or per-record full audit into public GitHub. Aggregate methodology and caveats are documented in `docs/FULL-SERVER-QUEST-AUDIT-CHECKPOINT.md`.

**Next:** Review the 24 unresolved item cases and 18 linked missing quests; triage high-impact early-zone level candidates; test server IP/condition gate behavior separately. Keep PR #6 and PR #7 draft, unmerged, not released. Maintain backups before future client QA.

## Latest handover — 14 October 2026 (private database re-upload analyzed)

**Private source is now available in this conversation:** The maintainer uploaded acore_world.zip, an offline HeidiSQL export. It was inspected read-only locally; 9,525 unique quest templates. Keep the original SQL/ZIP private and OFF GitHub.

**Confirmed quest 1203 issue:** Existing WotLK Questie levels match server (required 30, nominal 35), but inherited Questie has Razorspine's Sword (33110) while server requires one Moonsteel Broadsword (3853) and the corresponding item objective text. [Draft PR #6](https://github.com/CosmicCuddle/N-Questie/pull/6) stages an item/text-only guarded correction without changing levels, questgivers or prerequisite.

**Dustwallow pass:** 134 server quests under QuestSortID 15, 126 present in stock WotLK Questie; 8 missing require classification. Eight existing level mismatches were source-verified and stage through [draft PR #7](https://github.com/CosmicCuddle/N-Questie/pull/7). Thirty-two item-ID candidates include quest 1203; 31 require closer source semantics review. See [Dustwallow audit](docs/DUSTWALLOW-QUEST-AUDIT.md). Scoped PR #6 Lua 5.1 checks passed; PR #7 dedicated CI still requires checking when run concludes.

**Next:** Expand to all-zone comparisons, never patch candidate item objectives blindly; check IP stage/conditions and verify in-game on an eligible character after backups. Source-guarded corrections must preserve Questie objective metadata outside the approved fields. All PRs #1–#7 remain unmerged; #2–#7 draft (PR #1 is foundation open). No release or collection update authorized.

## Historical checkpoint: original PR #5 audit

## Existing-quest mismatch audit — draft PR #5 (14 October 2026)

**First reported correction:** Quest 1203 **Jarl Needs a Blade**. Public Questie WotLK generated record: required level 30, nominal quest level 35. No direct literal numeric `requiredLevel` or `questLevel` correction for ID 1203 was found in the checked Classic/TBC/WotLK quest fix modules. This is **not** proof of the user's server values: the original private world ZIP from the earlier conversation is not currently accessible here.

**New workflow:** [Draft PR #5](https://github.com/CosmicCuddle/N-Questie/pull/5), stacked on PR #3, adds `tools/audit_world_quest_levels.py` and `docs/EXISTING-QUEST-LEVEL-AUDIT.md` for a streaming, read-only comparison between selected/all world quest-level fields and static Questie WotLK level records plus literal correction layers. It refuses publishing its private report into the GitHub checkout and never connects to the world server. Synthetic tests initially passed [scoped run 38551948617](https://github.com/CosmicCuddle/N-Questie/actions/runs/38551948617); a newer source-baseline test still needs CI confirmation.

**Next user action:** Request re-upload of the **private acore_world.zip** in chat (not GitHub). Analyze quest 1203 and all mismatches offline; do not invent level replacements. Flag changes arising from IP/module conditions separately from numeric database differences. Only create explicit field-level corrections after review. All PRs remain unmerged; installed addon/SavedVariables/character state remain untouched.

## Existing-quest correction scope — 14 October 2026

The maintainer confirmed that **incorrect inherited WotLK quest information must be repaired too**, especially outdated quest levels and red/green difficulty colours on the Naxxramas AzerothCore server with Individual Progression. This is now explicitly tracked in `docs/ROADMAP.md` as **Phase 2A — Corrections for existing WotLK quests**.

Technical finding: `Modules/Libs/QuestieLib.lua` colours quests by the effective `questLevel` compared with `QuestiePlayer.GetPlayerLevel()` via `PrintDifficultyColor` and `GetTbcLevel`; `MinLevel` / `requiredLevel` is a separate eligibility gate. IP era availability may need module-specific interpretation beyond static quest data.

Implementation must start with a **private read-only Questie-vs-server discrepancy report** (server source plus effective Questie corrections), then an **approved field-level** correction overlay that preserves other fields. Do not replace full existing quest records merely to fix a level, infer a green colour from the IP era, access server progression, publish the raw SQL export, or change installed addons. Add regression tests and staged in-game QA; PR review/merge/release gates remain unchanged.

## Most recent verified state — 14 October 2026 (supersedes historical checkpoints below)

- **In-game quest 2001 visual marker lifecycle: PASS.** Available starter, Ravenclaw Servant/Champion objective pin tooltips, completed turn-in indicator and post-hand-in marker disappearance confirmed by maintainer. Existing Questie installation/regression tests also passed 5/5. Individual kill-counter transitions and exact active NPC spawn-coordinate alignment not independently tested.
- **PR #3 (this branch):** Offline reviewed JSON → Lua generator now protects existing generated quests against accidental removal, requiring explicit `--approve-removal-quest` approval and a revision increase for replacements. Test file includes synthetic partial-import regression. The latest commits need fresh dedicated CI results. Earlier [run 38547219011](https://github.com/CosmicCuddle/N-Questie/actions/runs/38547219011) passed before the newest removal safeguard.
- **PR #4 (independent `335` CI fixture):** [run 38549456997](https://github.com/CosmicCuddle/N-Questie/actions/runs/38549456997) **all inherited checks PASS**: LuaCheck, Busted, WotLK/Era/SoD validators. This has **not** been integrated with PR #2/#3; combined CI still requires testing.
- All PRs remain **unmerged** (PR #2/#3/#4 are draft). Neither the full private world export nor raw review JSON has been published. Installed addon and SavedVariables are unchanged by this development. No live DB changes, release or N-Addon-Collection update authorized.
- **Next:** Obtain clean CI for the latest PR #3 changes, then plan an additional source-verified quest (especially missing NPC/gameobject spawn mapping) without guessing coordinates; integrate test-only CI improvements only after separate review.

## Earlier new-chat entry point — historical context

## Latest verified state — 14 October 2026 (new-chat entry point)

**Maintainer in-game QA STEP 1: PASS — five out of five.** User installed the PR-only N-Questie test addon and explicitly confirmed:
1. **PASS:** N-Questie appears in the character-selection AddOns list.
2. **PASS:** The addon loads with no Lua errors.
3. **PASS:** Normal Questie quest icons remain visible on the world map.
4. **PASS:** Normal quest objective icons remain visible on the minimap.
5. **PASS:** Questie settings and existing preferences are retained.

**Meaning:** Preliminary addon compatibility and regression smoke checks passed **in game**. **Not tested yet:** actual custom quest 2001 starter, kill-objective and ender markers. The user has **not** stated a qualifying Horde character or completion of prerequisite 437. Do not call that test passed and do not infer backup completion unless confirmed.

**Development PRs:** [#1 foundation](https://github.com/CosmicCuddle/N-Questie/pull/1) open/unmerged against `335`; [#2 quest overlay](https://github.com/CosmicCuddle/N-Questie/pull/2) **draft**, stacked on the #1 branch, unmerged. The baseline branch `335` still has original Questie-335. The last feature revision *before this documentation-only QA note* was `0976bce5c3ec96bb3a4b5114b2ad71e5bfdcabba`. A code/PR recheck is required before any merge/release.

**Automated checks:** [dedicated N-Questie run 38461711184](https://github.com/CosmicCuddle/N-Questie/actions/runs/38461711184) passed Lua 5.1 parsing, mocked quest/NPC correction, scoped Python exporter fixture tests, TOC checks and QA package assembly. **Inherited upstream CI run 38461710869 failed**, with Busted upstream tests starting without `QuestieCompat` (verify current logs before claiming the failure is exclusively upstream). Both results must remain visible; not all CI passed. Temporary QA artifact `N-Questie-335-PR-TestBuild`, ID `11846520352`, from that successful run (expiry 27 October 2026).

**Next user-facing step:**
- Thank the maintainer for five passes; continue to **Step 2 — one custom quest**. Ask whether a genuinely eligible Horde test character (quest 437 done) can reach **quest 2001 Ravenclaw Cleanup** in Silverpine Forest.
- If yes: check starter at Shadow Priest Allister NPC 2121, kill-target map/minimap positions for Ravenclaw Servants (1868) and Champions (1869), then turn-in at NPC 2121. Keep normal quest icons as a comparison. Test only through ordinary in-game gameplay.
- If not: use the private acore_world-derived audit to choose a safer, accessible custom quest; **do not change player progress, database or GM state just to test**.
- After the first verified custom quest, review and fix the remaining inherited CI issue and implement scalable read-only import for more quests, including NPC/object coordinates and special quest conditions.

**Permissions and safety:** Maintainer permits publication of *curated* quest IDs, names, NPCs, objectives and map coordinates. Full `acore_world.zip`, server metadata and connection information stay private, **never on public GitHub**. The private export may need to be reattached in a new chat; do not assume its bytes are automatically in the repo. Back up the existing `Questie-335` addon folder plus account/character Questie SavedVariables before any future installed test build. Preserve upstream authorship/licence, folder and TOC names, existing settings and rollback. Do not merge, tag, publish a release or update N-Addon-Collection without explicit maintainer approval.

## Purpose

Maintain a Naxxramas-server-specific Questie fork and make it straightforward to add or correct map and minimap markers for custom AzerothCore quests. The first milestone is reliable quest starter and ender markers; objective markers follow only when their world locations and underlying Questie record types are known.

**Priority:** Keep existing Questie working while building a *small, reviewable custom data overlay*. Never hand-edit thousands of generated WotLK records for each server change.

## Verified starting point

- `CosmicCuddle/N-Questie` was created on 13 October 2026 as a fork of `divial28/Questie-335`; the copied/default branch is `335`.
- Initial `335` head: `13c958005c0e3b27e3ef0ea3472998fa522a11a5`.
- The original `Questie-335.toc` registers `QuestieConfig` and `QuestieConfigCharacter` as SavedVariables, targets `30300`, loads the WotLK quest/NPC/object/item databases, then the correction modules.
- `Database/questDB.lua`, `npcDB.lua`, and `objectDB.lua` define symbolic field keys. `Database/Corrections/QuestieCorrections.lua` merges existing Classic/TBC/WotLK corrections during database initialization.
- The quest and spawn data are related but distinct: quest start/turn-in references use NPC/object IDs; spawn coordinates belong to the corresponding NPC/object records. **A quest ID alone does not establish an icon location.**
- Compiled/cached Questie database state may require a supported recompile/refresh after adding overlay entries; determine exact invalidation behavior in code before implementing a loader.
- The inherited GitHub Actions workflow includes Lua 5.1 and database validation stages, but it has **not been accepted as a passing N-Questie run**. CI and in-game testing must be recorded separately.
- The original README currently refers to the previous upstream fork and the installed addon folder `Questie-335`. Preserve compatible installed folder/TOC names initially, even though the GitHub repository is called **N-Questie**.

## Working rules

1. **Back up first:** Before any test installation, close WoW and back up the current working `Interface/AddOns/Questie-335/` directory (or the exact installed Questie folder) and the Questie SavedVariables for the account/character. Keep the baseline ZIP for rollback.
2. **Scope controls:** Make addon changes only in this repository/feature branch. Do not change live AzerothCore world/characters/auth databases, custom quests, quest flags or NPC placements without separate explicit approval.
3. **Read-only server data:** Use a narrowly scoped, read-only export from the AzerothCore `world` DB to author custom quest records. Do not request credentials or whole database dumps. Confirm actual table names and schema before drafting SQL queries.
4. **Quest IDs and positions:** Never invent quest IDs, NPC IDs, gameobject IDs, coordinates, availability, phases or map conversions. Validate map-specific coordinates before showing markers.
5. **Client compatibility:** Lua 5.1 / WoW 3.3.5a only. Respect `QuestieLoader`, correction application order, existing database compilation and marker filtering. Do not quietly change existing quest records or progression gating.
6. **Fork attribution:** Preserve upstream history, credits, and all inherited licence/third-party notices. Complete a licence and redistribution review before any public download or release; no custom origin claims.
7. **Repository practices:** One focused topic per PR, source/QA distinctions explicit, with development log, test evidence and rollback. Do not merge, tag or update N-Addon-Collection until maintainer authorizes it.
8. **Accessibility:** Short, clear walkthroughs, readable map markers/tooltips and a simple repeatable import workflow.

## Roadmap and working files

- [ROADMAP.md](ROADMAP.md): phased milestones and acceptance gates.
- [CUSTOM-QUEST-DATA-DESIGN.md](CUSTOM-QUEST-DATA-DESIGN.md): proposed overlay, source fields, map-coordinate requirements.
- [TESTING.md](TESTING.md): safe read-only test sequence and expected observations.
- [DEVELOPMENT-LOG.md](DEVELOPMENT-LOG.md): decisions and evidence.

## First deliverable

1. Receive **one real quest ID** for a quest that currently has missing or wrong icons; optionally NPC/gameobject ID and spawn evidence.
2. Query/inspect `quest_template`, quest starter/ender relationships, NPC/gameobject templates and spawn records **read-only**; reconcile with this server's actual schema and phasing.
3. Prove one quest starter and ender icon, using the existing correction architecture with the smallest possible code change and minimal regression tests.
4. Extend to objectives and batch import only after the first quest passes in-game.

The first documentation PR is **foundation only**. It does not implement or install a new custom quest overlay.

## Continue development in a new chat

> Continue N-Questie on https://github.com/CosmicCuddle/N-Questie (branch `335`). Read docs/PROJECT-HANDOVER.md, ROADMAP.md, CUSTOM-QUEST-DATA-DESIGN.md, TESTING.md and DEVELOPMENT-LOG.md; check current PRs and state. Prioritize a small, non-destructive server-specific quest overlay and a reproducible read-only quest import. Request the example quest ID and only the necessary world-DB records. Preserve WoW 3.3.5a, the installed Questie addon identity, upstream credits, backups and PR-based testing. Update the handover after each milestone.

## Current development state — 13 October 2026 (supersedes foundation-only status)

**Open PRs:**
- [PR #1](https://github.com/CosmicCuddle/N-Questie/pull/1), base `335`: documentation/handover only.
- **Draft** [PR #2](https://github.com/CosmicCuddle/N-Questie/pull/2), base PR #1 branch: isolated first custom quest overlay, selected-quest read-only exporter, regression tests and PR-only QA package.

**Curated quest 2001:** `Ravenclaw Cleanup` (Silverpine Forest). The private `world` export supplies NPC 2121 as giver/ender, prerequisite quest 437, and kill targets 1868 and 1869 (eight kills each). Those NPCs already have zone 130 coordinates in Questie's WotLK NPC records, so the overlay only adds quest data and missing reverse NPC links without making up spawn positions.

**Implementation in draft PR #2:** `Compat/NQuestieCustomQuestData.lua` and `Compat/NQuestieCustomQuestLoader.lua` are loaded through the existing `Questie-335.toc`. `Modules/QuestieInit.lua` uses a custom data revision to force a normal compiled-DB refresh on changed records. The README preserves upstream attribution; the addon folder/TOC name and original Questie SavedVariables remain intact. A test-only in-game title/version distinguishes the fork.

**Automated QA:** [GitHub Actions run 38461484026](https://github.com/CosmicCuddle/N-Questie/actions/runs/38461484026) **passed** the dedicated Lua 5.1 parser, mock Questie corrections, SQL/ZIP Python test fixtures, TOC paths and temporary single-addon package. The artifact is `N-Questie-335-PR-TestBuild`; expires 27 October 2026. This **does not establish in-game pin functionality** or comprehensive upstream CI compatibility. The inherited workflow has separate lint/validator jobs; record those outcomes separately.

**Privacy:** Maintainer approved publicly including *curated* server quest IDs, NPCs, objectives and coordinates. Do **not** upload the entire `acore_world.zip`, server connection details, or uncontrolled exports. The full SQL was only read locally.

**Next action:** Back up the existing Questie folder and both Questie SavedVariables. Then, when the maintainer is ready, install the reviewed **PR-only** test build and verify quest 2001's starter, kill objective and turn-in markers in Silverpine on an eligible Horde character with prerequisite quest 437. Do not mutate server/character progression for testing. Use [QUEST-2001-SMOKE-TEST.md](QUEST-2001-SMOKE-TEST.md). After that, implement reviewed-JSON to Lua generation, added/new NPC spawn mapping and progressively expand to further server-specific quests. Neither PR has been merged; no release has been published.


## 14 October 2026 — New stacked draft generator PR (next continuation)

- [Draft PR #3 — Reviewed JSON-to-Lua generator](https://github.com/CosmicCuddle/N-Questie/pull/3) is stacked on draft PR #2, **not merged**. It adds a local-only conversion program, synthetic tests, CI coverage and an importer guide. The complete private SQL ZIP and review JSON remain off public GitHub.
- Source reviewed quest IDs and verified-existing NPC ID sets must be supplied explicitly; do not assume generated Lua implies live quest availability, map-coordinate correctness or Individual Progression unlocks.
- **Step 1 remains PASS 5/5. Step 2 remains NOT TESTED.** Continue actual quest 2001 (Ravenclaw Cleanup) starter / NPC kills / turn-in in-game only when a legitimately eligible character exists. No progression changes just for testing.
- PR #3 automation results must be checked separately from PR #2's last passing scoped run and inherited CI failures. No PR merge, release, live database changes or addon collection change without maintainer approval.

