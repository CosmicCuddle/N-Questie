# N-Questie Part53 — Questie 3.3.5a pilot source-row schema boundary

**31 October 2026 | PUBLIC-SAFE | DOCS ONLY.** No owner-private quest records, names, NPC/GO/item identities, SQL, spawn coordinates or loot links here. This file does not author an addon patch.

## 1. Original protected source and exact codec facts

Checked against `CosmicCuddle/N-Questie` protected `335` at `26053bd28b0df3a01e5859f779d5f3cb4f57b221`:

| Original file and blob | Existing authoritative client field | Codec / consequence |
| --- | --- | --- |
| `Database/npcDB.lua`, `ace50953a6bb0bc3ebdd349576681f10e8f44443` | `name` | `u8string`, maximum 255 **UTF-8 bytes**; `nil` is a special sentinel |
| same | `minLevel`, `maxLevel`, `rank` | `u8`, 0–255 (subject to valid range and server-backed meaning) |
| same | `factionID`, `npcFlags` | `u16`, `u32` respectively |
| same | `questStarts`, `questEnds` | `u8u24array`: at most 255 unique u24 quest IDs; preserve inherited links |
| same | `spawns` | `spawnlist`: **zone-ID-keyed** coordinate lists; a flat server world-position or plain list of map-percent coordinates is NOT the client field shape |
| `Database/objectDB.lua`, `70cd760ec046d3c9fcea1bb6d0a22595811261d0` | `name`, `questStarts`, `questEnds`, `spawns` | `u8string`, u8-capacity reverse quest links, zone-keyed `spawnlist` |
| `Database/itemDB.lua`, `a714c1a11ce0513276de3f9ce9015d7db22efa80` | `name`, `class`, `subClass` | `u8string`, `u8`, `u8` |
| same | `npcDrops` | **`u16u24array`**: up to 65,535 references, NOT u8-length; distinguish this from item object drops |
| same | `objectDrops`, `relatedQuests` | `u8u24array`, 255 maximum references |
| `Database/questDB.lua`, `9503b16031e739d9c0f046939058229b1a18d9b1` | `startedBy`, `finishedBy`, `objectives` | nested Questie-owned object structures; direct 3.3.5a client item objectives occupy objectives slot 3; source item-drop IDs are not the quest's direct creature targets |

All source value ranges are **encoding limits, not proof of server correctness**; an unverified source, phase, spawn or quest may be in range but wrong.

## 2. Owner-private v4 pilot: what can be preserved and what must not be directly emitted

The existing owner-private `v4_SOURCE_CLOSURE` audit proposes **3 new quest records**, with **4 NPC, 1 gameobject and 5 item** candidate source rows absent from the pinned **raw** client files. It combines **server provenance metadata** with potential client fields. That is fine for a private audit but **the audit rows must not be copied directly into `QuestieDB.npcData/objectData/itemData`**.

Examples of **server-only or audit-only field names** that must not be passed as client source keys include `kind`, `id` (dictionary key, not a source field), `missing_from_raw_Questie`, `lootid`, `phaseMask`, `spawn_world_map`, `gameObjectType`, `lootEntry`, `questRequiredData8` and `sourceReview`. Do not guess values for `minLevelHealth`, `maxLevelHealth` or `friendlyToFaction`; these are **real Questie keys**, but the private source audit explicitly does not certify those values.

**Location gating:** Private projection of WorldMapArea/world positions into percentage coordinates remains a candidate calculation, not validated native 3.3.5a `spawnlist` proof. A deterministic source adapter must resolve verified zone IDs, the real map-coordinate transform, and IP/phase/event visibility before committing a source row. Unknown stays `NEEDS_MANUAL_REVIEW`. A single incorrect pin can pollute many visible quest markers.

**Collision gating:** Missing from raw `npcDB.lua/objectDB.lua/itemDB.lua` is not proof the effective tables remain empty after inherited Classic/TBC/WotLK corrections. Reject any proposed source ID that conflicts with an effective existing row or a reviewed other correction; do not overwrite. Raw quest 2001 and the owner-deferred 30000–30004 exclusions remain protected.

## 3. Independently run owner-private, read-only schema tests

The separately stored owner-private Library files `PRIVATE_Part53_v4_Client_Schema_Checker.py` and `PRIVATE_Part53_v4_Client_Schema_Report.json` test a **detached, non-installable** field projection from v4. The checker pins both the audit archive and server-snapshot identities, also invokes the earlier private structural closure validator, rejects **15/15 deliberate negative cases**, and asserts a **positive synthetic item `npcDrops` list of 256** is allowed by u16 length while a relatedQuests list of 256 is rejected by u8. It emits no quest ID, item/NPC name, spawn or loot identity; the report remains **private**.

**Verified by local Python execution:** original private structural closure PASS; 15/15 independent schema negative controls rejected; synthetic item 256 positive PASS; original addon and server unchanged. **NOT VERIFIED:** real effective correction/collision matrix, client zone/map source coordinates, full Questie Lua 5.1 compiler encoding and reader round-trip, deterministic source provision into original `QuestieCorrections:Initialize`, per-character/IP unlock, native quest text agreement, Gate08 atomic persistence or live gameplay. These are release blockers; do not misstate synthetic schema passing as a playable quest.

## 4. Proposed implementation handoff and ownership

1. **CS02 retains 1207–1209 Gate10 implementation claim.** Use the private v4 source audit and the new private schema report only through an authorized private Library connection; never copy their full contents to public GitHub.
2. Implement a **separately reviewed source adapter and complete-batch preflight** concept: source row field allow-list, exact codec type/length, source/no-collision checks **after inherited corrections**, and deterministic preprovision of all source categories **before any memoized `approvedQuests()` call**. This is a *design requirement*, **not authorization to modify original addon Lua**.
3. Unresolved quest text/item-count contradictions require a separate owner decision before any server-SQL change. Verify legitimate drop sources and native-client coordinate conversions rather than guessing.
4. Test source and quest reverse links plus the original public quest 2001, approved exclusions, compiler/reload, and Gate08 independently; preserve rollback and separate native authorization. No PR is opened solely to add this documentation because existing PR triggers can package the addon.

Read alongside [Part53 protected-335 source-order test](NQ-PART53-PROTECTED335-SOURCE-ORDER-PROOF.md), [current living handover](../HANDOVERS/CURRENT.md), and [cross-developer discussion](https://github.com/CosmicCuddle/N-Questie/pull/42).
