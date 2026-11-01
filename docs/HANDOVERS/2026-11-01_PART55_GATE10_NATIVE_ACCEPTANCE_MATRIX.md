# N-Questie — Gate10 disposable native test matrix (3.3.5a / IP Vanilla)

**PREPARED ONLY. NOT RUN. NOT APPROVED FOR INSTALLATION, MERGE, PACKAGING OR RELEASE.** Source proposal: [draft PR #457](https://github.com/CosmicCuddle/N-Questie/pull/457). Protect original `335`, original M2 tests and server gameplay.

## Preconditions / gates

1. Independently verify an actual GitHub Actions run at the exact test-source head for four steps: exact custom source admission `1207,1208,1209,2001`, 9,159-record structural parity, candidate A1 in-memory v2 round-trip, and frozen original 335 A1/A2 controls. Local proof or a prior SHA is not the same as an exact-head Actions PASS.
2. Resolve/explicitly classify the original two candidate M2 Busted acceptance failures using **a separate Gate10-specific variant**. Never re-pin old 335 acceptance/golden files to make the candidate appear green.
3. **Gate08 MAJOR RED** (compiled cache, SavedVariables recovery, RAM/GC) requires independent review and clearance. This checklist does not authorise a test ZIP or bypass those safeguards.
4. Only after CosmicCuddle's approval, test on an isolated native 3.3.5a client with an eligible IP Vanilla Horde character. Back up the existing addon and SavedVariables first; record client build, exact addon SHA, effective IP stage/cap, race, level and Lua errors. Do not touch the raid/live addon installation.

## Per-quest acceptance — all NOT RUN

| Test | Evidence to verify | Result |
|---|---|---|
| Quest availability | Thugg (NPC 1209) offers 1207/1208/1209 to a qualifying character at level >=18 subject to server prerequisites. Other legitimate quests must remain. | NOT RUN |
| 1207 — Kirin Tor Aid | **20** Signets (item 166) from Theramore Mages (NPC 3677). Record the archived **22**-in-objective-label conflict; verify client quest-log count, pickup, group loot and completion. 75% archived chance is not a guaranteed live drop rate. | NOT RUN |
| 1208 — Northwatch Intel | **15** War Documents (item 167) from GO 2013. Verify interaction and quest credit, including when solo/grouped. Archived GO loot `QuestRequired=0` needs observation, not a silent SQL change. | NOT RUN |
| 1209 — Northwatch Guard | **One each** of items **160 / 161 / 162** from their named NPCs. Check observed quest-log label/item matching: server order Duncan → Cassia → Fairmount differs from archived text labels Fairmount → Duncan → Cassia. | NOT RUN |
| Dialogue and text | For all three, inspect accept, objective, completion and turn-in text. The archived completion log contains `QuestCompletionLog NOT WORKING`; do not assume players see it. Quest 1209 prose refers to three allies though only two are named. | NOT RUN |
| Map/minimap | Compare quest giver, mage, boss and War Documents icons to **active in-game** NPC/GO positions and IP phase. Record missing/duplicate/out-of-zone markers. Do not import all archived POIs. | NOT RUN |
| Quest 1209 target availability | Before attempting item drops, check **whether all three required named NPCs are actually present**; record any missing NPC and whether the live server's respawn policy differs from the archive. Private archival audit found unusually long configured respawn delays for these three unique NPC sources. **Do not force-spawn or edit their timers** as part of this test. | NOT RUN |
| Quest 1207 moving targets | Observe Theramore Mages in motion: archived movement classification is **13 stationary / 5 random-wander / 6 waypoint patrols** across 24 spawns. Test base pins versus actual patrol locations; describe any confusing search areas rather than assuming a stationary marker is incorrect. | NOT RUN |
| Regression | Verify frozen custom quest **2001**, unrelated inherited Vanilla quests, map UI, and absence of unexpected Lua errors. | NOT RUN |

## Offline evidence versus in-game evidence

The original owner-private archived source audit confirms all **five objective items** have corresponding direct loot-template entries; proposed NPC/GO marker counts match the archived sources. A newer **owner-private** independent spatial reconciliation compares all **51 proposed spawn coordinates** to archived SQL world positions. Three NPC positions establish an affine world-to-zone transform; the other **48** are hold-out checks. **51/51 pass** within **0.015 map percentage points** (largest deviation approximately **0.00990**); a deliberately displaced marker fails the synthetic comparison.

**Stronger follow-up (1 November):** A publicly preserved **3.3.5a build-12340** binary `WorldMapArea.dbc` was independently decoded (Git blob `32019ed2a62153b2e21b18d49f38b2eb4af1c2cd`; Barrens row 11, map 1, area 17). With **both scale and origin held fixed from that external DBC**, **51/51** original archived spawns match the proposed N-Questie positions (largest mismatch **0.008550 percentage points**, tolerance 0.015). Synthetic displaced pin fails. This supersedes the earlier *three-anchor affine* proof for absolute historical 3.3.5a map consistency.

**Still NOT proved:** this third-party DBC is byte-identical to CosmicCuddle's **installed client**, nor that live spawns/phase/IP, loot or the addon map actually behave as archived. Real client map/minimap checks above remain **NOT RUN**. Reused NPC 3393 was not provisioned as an additional source marker. Exact SQL rows and unreleased owner-only spatial evidence remain in CosmicCuddle's private Library, **not** in GitHub.

## Record failure without changing production

On a mismatch: stop the pilot; record quest ID, test SHA, character's effective IP era, actual UI text, screenshot, map region and Lua error. Return evidence in existing [PR #457](https://github.com/CosmicCuddle/N-Questie/pull/457). Do not change quest counts, item IDs, coordinates, SQL, DBCs or IP rules without explicit approval and Maintenance review.

Broad wrong/overbroad quest-pin task: `NQ-MAP-ACCURACY-001` stays queued until missing-quest and safety gates are addressed. No native test or installation is claimed here.
