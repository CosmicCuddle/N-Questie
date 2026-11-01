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
| Part55 5-objective Gate10 / strict-latch M2 test | **VERIFIED PASS** — real Lua5.1 exact-head source test at `68c10f61`: 9,162 total / 8,404 supported / 758 unsupported, three proposed quests, five ordered item objective IDs, six unchanged unsupported reason aggregates, zero manifest/round-trip differences. GitHub run [41231357608](https://github.com/CosmicCuddle/N-Questie/actions/runs/41231357608), job `124626066356` successful. |
| Optional full old-record comparison | **VERIFIED PASS** — same exact-head CI job ran `NQ_GATE10_COMPARE_335=1` and logged "all 9159 inherited v2 structural quest records unchanged" against protected `335@26053bd2`; exactly 1207–1209 added. This does **not** compare native map/quest descriptions, server SQL or IP conditions. |
| Native WoW 3.3.5a/IP marker/loot/phase | **UNKNOWN:** no authorization or evidence here. |
| Gate08 atomic compiled cache / saved-variable recovery / RAM-GC | **MAJOR RED.** |

## Safe, decisive run scope

GitHub push-only workflow `nquestie-part55-gate10-m2-latch-proof.yml` executes these two commands in the **isolated branch only** using real Lua **5.1** + bit32 (not Lua 5.4; inherited `cli/dump.lua` calls `getfenv`):

```sh
bash tests/test_nquestie_m2_gate10_delta.sh
NQ_GATE10_COMPARE_335=1 bash tests/test_nquestie_m2_gate10_delta.sh
```

The PR-triggered-commit-run connector query does **not** list push-only Actions runs, but the dedicated push run ID was provided by CS02 and **independently verified through GitHub Actions job steps and logs**: run [41231357608](https://github.com/CosmicCuddle/N-Questie/actions/runs/41231357608), job `124626066356`, source `68c10f61`, every step SUCCESS including both Lua5.1 proof commands. The full-record parity PASS lines were visible directly in the returned log. No package, artifact upload, native game test, server write or release step was added.

**Decision rule applied:** The dedicated public M2 *structural* data delta is **verified isolated**. This still does **not** clear the original two RED frozen 335 Busted acceptance tests; a separately reviewed Gate10-specific variant is required. Never globally re-pin the historical test file `tests/test_nquestie_m2_v2_export_integration.sh` or `tools/validation/M2V2RoundTrip.test.lua`.

## Missing Vanilla quests — diagnosis not blanket approval

- The previously identified **439 RAW** candidates included existing custom quest 2001; private Part54 reconciliation recorded **438 effective server-only candidates**, not 438 confirmed eligible Vanilla quests. Eligibility depends on current progression, faction, conditions, player level and possibly dynamic/IP gates.
- Gate10's proposed 1207, 1208, 1209 are a **three-quest candidate pilot**, not a release-ready correction. The private snapshot found the quest-1207 description **22** versus recorded required count **20**, and quest-1209 wording/item-label correspondence problematic for **all three slots**. Preserve those decisions for CosmicCuddle; do not change SQL, objective ordering, drops or prose without owner approval.
- Differentiate **(A)** server quest availability, **(B)** effective compiled quest indexing, **(C)** current-character/AQ/hidden/doability filtering and **(D)** object/NPC location mapping. [PR #456](https://github.com/CosmicCuddle/N-Questie/pull/456) covers invented source-executed filter fixtures; it is not proof of a real missing quest.
- Keep explicitly owner-deferred quest IDs **30000–30004** excluded. Preserve quest **2001** and its previously tested marker lifecycle.
- Never upload the private `acore_world.zip`, extracted SQL, per-character data or complete source crosswalk.

## Wrong or misleading map pins — task NQ-MAP-ACCURACY-001

Queued **after** the missing-quest proof: evaluate each quest target's *actual active* world spawns, not every historical/shared template spawn. Compare server map/phase/conditions to Questie zone-local coordinate transforms, then spot-check both minimap and world-map markers in an owner-approved disposable native 3.3.5a test. Do not fabricate exact spawns or remove unrelated legitimate pins simply to reduce clutter.

## 1 November 2026 — owner-private 438-ID source triage (public-safe aggregate)

A reproducible **owner-private**, read-only review of the frozen source inventory verified that only **23/438 candidates** have at least one ordinary NPC/GO starter or ender relationship (**20 both sides, 3 one side**). **All 23** were already allocated to dedicated Gate10, AQ/IP, owner-deferred, internal-placeholder or PvP workstreams; **none** is a newly evidenced ordinary Vanilla quest ready for blanket import.

The separate **37-ID title/minimum-level first-pass sample** contains **zero ordinary NPC/GO starter/ender relationships**. Manual historical cross-checks classify **19** as the Cataclysm pre-launch Elemental Unrest storyline; **5** TBC-era/beta, **1** WotLK beta, **2** AQ test-realm concepts, **2** Darkmoon placeholders, **3** owner-custom dependent quests, and **5** individually ambiguous historical candidates. These are research **priorities**, not confirmed live enable/disable decisions. In particular do not treat low `MinLevel`, high/low IDs, `VerifiedBuild`, source item, or a NextQuest relationship as proof of playable *Vanilla* quest-giver or map coordinates. The entire 438-ID backlog remains preserved.

The full private ID/title crosswalk, external references and repeatable checker are stored only in CosmicCuddle's **Server-Side-Information / Private N-Questie Quest Audits** Library. No private SQL, candidate-specific unpublished source fields or map coordinates are included here. Gate10 data proof, original frozen M2 Busted RED, Gate08 and character-specific IP/native acceptance remain separate.

## 1 November — typed archived SQL acquisition and POI cross-check

Read-only source scan (original owner snapshot, source-typed fields, private archived report) now differentiates **21** candidate IDs with static NPC/GO *starter* relations, **3** with item-template quest-start links, and **414/438** with neither (the prior **23** count included two NPC/GO *ender-only* records). This is **not** an assertion that 414 are unavailable: C++ scripts, custom modules, database changes and runtime mechanisms remain untested. In **56,660** archived SmartAI rows, **zero candidate IDs** appeared in typed OFFER_QUEST, fail/credit or accept/reward event fields; the same candidates had zero matching `spell_area` quest fields, areatrigger quest-turnin relations, quest-pool entries or event-specific NPC/GO quest additions. **16** have seasonal-event relationships (association only, not proof of availability).

The archived `quest_poi` table contains **272 POI entries across 182** of the 438 candidate IDs; **180** of these IDs lack ordinary NPC/GO starter *and* ender links. Client POI metadata is **not** a quest-giver link, active creature/object spawn, IP eligibility, or proof the player's addon currently displays a wrong icon. Do **not** auto-import POIs into N-Questie or claim these dormant candidate POIs explain existing marker errors. This aggregate is a *preventive test design input* for `NQ-MAP-ACCURACY-001`, not a reviewed marker patch.

Exact item identities, quest titles/IDs, source row crosswalk, POI ObjectiveIndex/MapID and repeatable scripts remain in the owner's **Private N-Questie Quest Audits** Library; none are published to GitHub.

## 1 November — Gate10 loot-route and narrative integrity (owner-private corroboration)

A new **read-only owner-private** checker independently joined the original archived quest, item, NPC, GO and **actual loot-template ID** fields for the three Gate10 pilot quests. All **five** expected objective items have matching direct archived loot entries; all relevant NPC/GO spawn **counts** also agree with the proposed additive source projection. This **does not** prove individual map-coordinate conversion, phase/IP eligibility, client visibility or real in-game drops.

Source-confirmed **review-only** discrepancies remain: 1207's player-facing objective label versus authoritative server-required item count; 1209's quest-objective label order versus actual item slots; and 1209's prose implying an additional unnamed ally. **Keep server quantities, source item IDs and objective order unchanged** until CosmicCuddle reviews a native-client test and chooses any text-only or gameplay correction. Also check GO loot interaction against quest acceptance: archival quest-required flags differ by source type, which is a test prompt and not permission to change SQL. Full exact source joins, archive fingerprints and repeatable checker are stored **only in the owner's Private N-Questie Quest Audits Library**, not in this repository.

## 1 November — source-to-proposed-marker spatial consistency and future native test sheet

A **read-only owner-private** spatial reconciliation (archived world source vs exact reviewed public pilot marker data blob `74a57ecc`) matched **51/51 proposed NPC/GO marker positions** to archived spawns. Three NPC positions fitted the local two-axis affine world-to-Barrens projection; the other **48/48** held-out points matched with largest coordinate distance **0.00990 map percentage points** (tolerance **0.015**); a deliberately displaced synthetic marker was detected. The original snapshot and source counts were independently validated, and existing NPC 3393 remains inherited rather than newly provisioned.

**Scope:** This is stronger than the prior spawn-*count* proof, but fitted affine coordinates do **not independently validate installed client `WorldMapArea.dbc` bounds** or in-game Questie rendering, live active spawns, IP phase, creature loot or user-visible text. Raw coordinates and exact private SQL joins remain in CosmicCuddle's **Private N-Questie Quest Audits** Library.

A separate **[Gate10 native acceptance matrix](2026-11-01_PART55_GATE10_NATIVE_ACCEPTANCE_MATRIX.md)** now records conditional 3.3.5a/IP player tests for quest availability, five item objectives, 1207 20/22 wording, 1209 name/slot discrepancies, completion placeholders, map pins and old-quest regressions. All are **NOT RUN**; this documentation is **not** test-package, installation, merge or Gate08 approval.

## 1 November — archived spawn availability and patrol-path caution

Further **owner-private typed SQL** checks inspected the 51 proposed Gate10 marker spawn rows plus one *inherited* existing target (52 total). All 52 have archived `map=1`, `spawnMask=1`, `phaseMask=1`, and none has an archived direct game-event, creature/object pool, custom spawn-group, formation or linked-respawn membership. These are **archival source properties**, not confirmation of present-day live spawns or IP behavior.

The proposed item-source creature population includes **24 mages**: **13 stationary**, **5 random-moving** and **6 with linked waypoint paths**. All six waypoint paths were found in archived `waypoint_data`; some extend materially beyond the base spawn position. Static coordinates show where a spawn *starts*, not every location along a patrol. This directly informs `NQ-MAP-ACCURACY-001`: do not equate every off-pin patroller with a bad marker or mass-import patrol points without live observations.

**Significant conditional gameplay risk:** the archived three unique NPC sources required for quest **1209** have unusually long configured respawn delays. Their present-day live respawn behavior, force-respawn scripts and persisted `creature_respawn` state have not been checked. Request a source-version-aware **read-only** review by Maintenance prior to native acceptance; **no respawn/SQL changes, forced respawns, release or client install authorised**. Exact spawn GUIDs, respawn intervals, paths and source evidence stay in CosmicCuddle's Private N-Questie Quest Audits Library.

## 1 November — independent historical 3.3.5a Barrens map-scale cross-check

An **owner-private read-only** independent-scale comparison now uses **fixed Barrens dimensions** published in the historical [3.3.5a Gatherer/Astrolabe map data](https://github.com/locus313/WoW-3.3.5a-Addons/blob/main/Gatherer/Astrolabe/Astrolabe.lua): map-horizontal **10133.4423** and map-vertical **6756.2019** world units. Unlike the earlier three-anchor affine test, this check **does not infer zone scale from the proposed Questie points**. It pairs all **51** reviewed marker positions one-to-one with owner-archived source spawns and fits **only the two map-origin offsets**.

**Result:** 51/51 within 0.015 map percentage points, maximum **0.00732**; a 0.6 percentage-point synthetic marker displacement is detected. This supplies independent **scale** corroboration. **Important qualification:** the map *origin* remains derived from the proposal; we have **not decoded the owner's installed 3.3.5a `WorldMapArea.dbc` bounding rectangle** and cannot claim complete independently verified map positions or native marker correctness. Do not deploy a coordinate correction from these results. Full source-pinned script and private audit reside only in the owner's Private N-Questie Quest Audits Library.

## 1 November — independently decoded WDBC Barrens **absolute** map bounds

**New, stronger independent source:** an actual 3.3.5a-build-12340 [`WorldMapArea.dbc` binary](https://github.com/Elwynsiaa/data/blob/main/dbc/WorldMapArea.dbc), Git blob **`32019ed2a62153b2e21b18d49f38b2eb4af1c2cd`**, was fetched in **base64** using the connected GitHub file reader and decoded as a real `WDBC` table (**108 records × 11 fields**). The **Barrens** row was located by its **ID 11, map 1, area 17 and string-table name**. Its four native float32 `LocLeft/Right/Top/Bottom` fields independently specify the map **origin and scale**, rather than fitting either to the proposed N-Questie markers. The field schema agrees with the TrinityCore 3.3.5a `WorldMapArea.dbc` reference.

A new owner-private checker combines these **fixed** bounds with the **original archived owner-world NPC/GO positions** and the **unchanged proposed public Gate10 source projection** (blob `74a57ecc`). One-to-one matching yields **51/51 within the same 0.015% zone-map tolerance**, maximum discrepancy **0.008550 percentage points**, and rejects a deliberately displaced synthetic marker. **Zero fitted calibration parameters** were used. This is stronger than the previous Astrolabe **fixed-scale / fitted-origin** and 3-anchor affine comparisons; those earlier checks remain historical context, not the best available proof. Full exact audit and executable verification script are retained only in CosmicCuddle's **Private N-Questie Quest Audits** Library.

**Still NOT verified:** the owner's **installed** client may have custom DBC overrides; this independently published 3.3.5a file is not proven byte-identical to it. The archived SQL is not a current live-world spawn snapshot. IP phase, patrol timing, native Questie rendering/loot/quest text, Gate08 and original M2 candidate acceptance remain separate, and no install or merge is authorised.

## 1 November — candidate A2 exact-field regression repaired, stricter than first draft

A read-only source comparison of the candidate-specific A2 suite exposed a **contradictory inherited M0 assertion**: despite correctly expecting **9,162** Gate10 quests, the initial candidate A2 script still required **82,431** compiled quest-field comparisons (the exact **9,159**-quest protected-335 value). This would falsely fail any successful three-quest addition, even though its F7 comparator required the field total to increase.

The actual `cli/validate-335.lua` source has **9** `COMPILED_KEYS` and compares each key for every compiled quest, establishing **9,162 × 9 = 82,458** as the **exact** Gate10 field total. On isolated test branch `7d2d6d4d`, both the candidate A2 M0 check and the new F7 comparator now **require exactly 82,458 and zero mismatches**; the F7 fixture's valid synthetic output uses 82,458 and its invalid 82,431 mutant remains negative. A fresh independent local run of the updated F7 Python fixture **PASSED** all 4 positive/negative cases; exact two source-file Git blobs were checked against GitHub. The original protected-335 A2 still correctly expects 82,431, untouched.

**Proof boundary:** this fixes a guaranteed false-negative in the new **test-only** A2 suite; it is **NOT** a recorded PASS for the full real Lua5.1 F1–F8 suite, which still requires a concrete new-head run/job log and CS02 review. Existing Gate08, IP/live-state, owner text and release gates are separate.

## 1 November — independent push-only Actions run IDs recovered; candidate A2 114/115

The connected GitHub repository GET endpoint for **branch-filtered Actions workflow runs** supplies the missing evidence that was unavailable from the PR-trigger-only commit-runs reader. Independently checked **real workflow job steps**, not merely overall CI badges:

- **PASS at the corrected stderr fix:** [run `41291777383`](https://github.com/CosmicCuddle/N-Questie/actions/runs/41291777383), candidate test commit `a69573b7`, job `124804329113`: Gate10 export/exact admitted IDs, full inherited-9159 comparison, candidate real Lua5.1 A1 (9,162 quests) and **original frozen 335 A1/A2** were all **green**. The prior uncertainty about whether the corrected test had run is resolved.
- **FAIL only candidate A2:** [run `41303630380`](https://github.com/CosmicCuddle/N-Questie/actions/runs/41303630380), head `d97f5287`, job `124839491687`. All earlier four Gate10/335 checks and the F7 synthetic mutation self-test **passed**; candidate-specific A2 F1–F8 reported **114 PASS / 1 FAIL**. The only failure was **F7's strict default CLI golden comparator**, specifically the **`npcData` source-summary line** (line 16). F1–F6, F8, full public data coverage, 9,162/8,404, exact 82,458 compiled fields, clean checkout/symlink protections, tamper detection and zero v1/v2 mismatches passed.
- **Safeguard:** F7 is **not** loosened to automatically permit unrelated NPC changes. A strict, public-summary-only error diagnostic and a separate quick read-only Actions job were added on the isolated branch at `cf16b29f` to expose only verified source-summary counts/digests, without private SQL or artifacts. This is **diagnostic work awaiting an exact new-head result**, not candidate A2 clearance.

**Original 335 A2/Busted goldens remain unchanged**, and the 169/171 two old-count assertions in the main candidate are still RED. Native client, IP/phase/respawns, Gate08 and owner decisions are independent.

## Next Gate10 actions

1. **Completed:** genuine Lua5.1 source proof and full 9,159-record parity at exact test head `68c10f61`; independent successful GitHub Actions step/log verification.
2. **Isolated candidate A2 now authored, NOT RUN / NOT VERIFIED:** `tests/test_nquestie_m2_gate10_a2_export_integration.sh` retains the full F1–F8 real-DB safety cases, pins the inherited 9,159 ID digest, requires 1207–1209 exactly once and expects 9,162/8,404. A separate `tests/check_nquestie_m2_gate10_f7.py` compares unchanged original 335 CLI golden by its Git blob SHA with only six specifically allowed Gate10 source/field changes. The push-only test workflow now includes candidate A2 **after** the frozen-335 controls; **F7 Python self-test independently executed locally: PASS**, with all three files byte-verified against their pinned GitHub blobs (`2e304cd5` comparator, `52f1a75f` fixture, `214925d9` unmodified frozen golden); one expected-positive and three mutation-negative cases were checked. GitHub source-to-source LCS review of standalone A2 versus the original frozen A2 confirms **221 unchanged lines** and exactly 9 expected change hunks (only candidate counts, inherited-ID SHA guard, exact quest admission, F7 adapter, test title). **Full A2 real Lua5.1/Actions execution has now been independently verified as 114 PASS / 1 F7 FAIL at `d97f5287`**; later diagnostics are pending, so full F1–F8 acceptance is **NOT GREEN**. CS02 review still required. The original candidate two Busted specs remain 169/171 RED by old-count assumptions; neither old test nor golden was repinned or modified.
3. **Outstanding (owner/native):** verify 1207 count-vs-prose and 1209 objective labels without unsanctioned SQL changes; native quest availability/IP, map/loot and Gate08 require separate acceptance. No merge/packaging/native trial without owner approval.

All feedback belongs in the **existing PR #457** discussion; do not create a duplicate cross-project Issue.
