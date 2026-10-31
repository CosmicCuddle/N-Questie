# N-Questie Part 51 — missing quest display: source-backed triage

**31 October 2026 · PUBLIC SAFE · research only.** No private quest rows, SQL, player identifiers, detailed account state, install steps or functional addon code changes. Read this alongside [missing quest audit #164](https://github.com/CosmicCuddle/N-Questie/pull/164), not as an automatic import mandate.

## Problem statement and evidence boundary

CosmicCuddle reported that the previously installed Part 50 test addon passed supplied smoke checks yet **some quests remain missing**. The exact installed source SHA and specific missing quest examples are **not pinned here**. There are at least two fundamentally different conditions:

1. The **server really offers** a quest, but N-Questie has no entry/incorrect entry, or suppresses its map icon.
2. The quest exists in a database/export or static starter relation, but it is **not presently obtainable** on the owner’s Vanilla Individual Progression character. Adding a Questie marker would then be a misleading false positive.

The original protected `335` tree at `26053bd28b0df3a01e5859f779d5f3cb4f57b221` is a **complete addon**. Existing compiled M0 evidence is a bounded subset (28 reviewed quest-level corrections, curated quest 2001, quest 1203 objective correction), *not* coverage of all server-only quests.

## Verified original source: missing map icon does not imply missing record

- [`Modules/Quest/AvailableQuests.lua` L89–L170](https://github.com/CosmicCuddle/N-Questie/blob/26053bd28b0df3a01e5859f779d5f3cb4f57b221/Modules/Quest/AvailableQuests.lua#L89-L170) calculates player-level ranges and filters completed, hidden, auto-blacklisted, repeatable/PvP/dungeon/raid/AQ War Effort/SoD and other categories **before** `IsLevelRequirementsFulfilled` and `IsDoable` accept a visible quest. No map icon therefore does **not** by itself prove the compiled database lacks that ID.
- [`Modules/Options/QuestieOptionsDefaults.lua` L110–L134](https://github.com/CosmicCuddle/N-Questie/blob/26053bd28b0df3a01e5859f779d5f3cb4f57b221/Modules/Options/QuestieOptionsDefaults.lua#L110-L134) defines level-filter defaults and `showAQWarEffortQuests = false`. This is a *source-default*, not proof the owner's current profile retains it; do not silently change options globally.
- [`Database/QuestieDB.lua` L503–L548](https://github.com/CosmicCuddle/N-Questie/blob/26053bd28b0df3a01e5859f779d5f3cb4f57b221/Database/QuestieDB.lua#L503-L548) independently enforces quest/required-level and max-level policy. Filtering has multiple layers.
- [`Database/QuestieDB.lua` L609–L778](https://github.com/CosmicCuddle/N-Questie/blob/26053bd28b0df3a01e5859f779d5f3cb4f57b221/Database/QuestieDB.lua#L609-L778) `IsDoable` examines hidden state, active quest, race, class, prerequisite chains, reputation, profession/specialization, daily availability, learned spells, exclusivity and achievement requirements; [`IsDoableVerbose`](https://github.com/CosmicCuddle/N-Questie/blob/26053bd28b0df3a01e5859f779d5f3cb4f57b221/Database/QuestieDB.lua#L781-L810) has explanatory logic, but is **not yet a validated in-game diagnostic command**.
- [`Modules/Quest/QuestieQuest.lua` L388–L400](https://github.com/CosmicCuddle/N-Questie/blob/26053bd28b0df3a01e5859f779d5f3cb4f57b221/Modules/Quest/QuestieQuest.lua#L388-L400) contains a separate option to hide untracked quest objective notes.
- [`Modules/QuestieInit.lua` L211–L220](https://github.com/CosmicCuddle/N-Questie/blob/26053bd28b0df3a01e5859f779d5f3cb4f57b221/Modules/QuestieInit.lua#L211-L220) recompiles on missing/stale cache, addon-version/locale/expansion mismatch or `nQuestieDataRevision` change. Failed/mismatched compilation is a **separate possible hypothesis**, not a finding from the owner's test.

## Read-only decision sequence for each reported quest

| Evidence bucket | Test question | Meaning / safe action |
|---|---|---|
| A — server availability | On the intended character, does a reachable, phase-eligible NPC/item/object **actually offer the quest now**? | If no, **do not import or force a marker**. Check prerequisites and IP; a static SQL row is not proof. |
| B — effective client data | Does the exact installed N-Questie effective compiled quest DB contain that quest ID and correct name/start/objective fields? | If not, consider a **private evidence-backed** missing-data proposal; do not infer all 439 need adding. |
| C — eligibility/suppression | If present, do category/level filters, completed/manual/auto hide, prequest/race/class/reputation/exclusivity rules prevent display? | Diagnose the **specific** reason. A legitimate restriction is not a missing-quest bug. |
| D — mapping | If eligible, are NPC/GO/item starter relations, coordinates, object/item objectives and quest endpoints present and correct? | Correct the **smallest** verified bad map link; avoid broad imports. |
| E — rendering/cache | If data and eligibility are correct, does icon generation or stale compile/cache block current display? | Reproduce on backed-up disposable staging and exact source; no unilateral SavedVariables deletions. |

Record for owner-private triage: quest ID or exact name, character faction/class/level and progression phase (only if owner comfortable), observed questgiver or objective, whether NPC actually offers it, and whether it is absent from map, tracker, or both. Keep player identities, private server paths, world SQL exports and full traces out of public GitHub. **One confirmed example is more useful than another general icon-count test.**

## Existing decision guards

- [Missing-quest inventory #164](https://github.com/CosmicCuddle/N-Questie/pull/164) is **9,525** server quest definitions, **9,086** original Questie IDs and **439 raw server-only** candidates. Only **12** first-pass public-safe review slots remain after linked-case and owner deferral review, none approved. This is a snapshot, not current player availability.
- Owner specifically deferred IDs **30000–30004** because they were not genuinely linked/doable. Do **not** re-add them without a new owner decision.
- Pilot IDs **1207–1209** are documented as **0/3 implemented**; do not mistake planning for deployed coverage.
- Gate08 **MAJOR RED** concerns safe compiler publication, stream ownership and relog recovery; Gate10 is missing-quest evidence and approvals. Neither blocker automatically resolves the other.
- No production changes, unreviewed quest additions, phase bypass, blanket filter disablement, new playable ZIP or public release from this document.
