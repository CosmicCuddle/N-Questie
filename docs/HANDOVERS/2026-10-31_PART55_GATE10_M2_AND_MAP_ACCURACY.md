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

## Next Gate10 actions

1. **Completed:** genuine Lua5.1 source proof and full 9,159-record parity at exact test head `68c10f61`; independent successful GitHub Actions step/log verification.
2. **Outstanding (Maintenance/CS02 implementation review):** propose a **separate Gate10-specific M2 acceptance variant** for 9,162/8,404 while retaining the frozen original 335 tests. The original two Busted RED tests are still RED on the candidate.
3. **Outstanding (owner/native):** verify 1207 count-vs-prose and 1209 objective labels without unsanctioned SQL changes; native quest availability/IP, map/loot and Gate08 require separate acceptance. No merge/packaging/native trial without owner approval.

All feedback belongs in the **existing PR #457** discussion; do not create a duplicate cross-project Issue.
