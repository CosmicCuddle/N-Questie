# N-Questie M2: nq-m2-effective v2 design (final draft for approval)

Status: design final for review. Docs, synthetic tests and a DRAFT validator only. **No v2 exporter and no M2.3 engine exist.** v1 stays FROZEN and valid.
Decisions in force: Option A (v1 frozen, unsupported quests out of scope for the initial pilot, exporter fail-closed). Lead review on PR #34 incorporated (§10).
Date: 14 October 2026 (Europe/London)
Evidence: public compiled 3.3.5a Questie data read through `cli/validate-335.lua` after the 232 M0 checks; public Questie source and git history. No private data.

## 1. Scope in one paragraph

v2 is a **structural objective schema**: it records, for each quest, every objective's kind, target IDs, relationships, order, quest-log position and duplicates, plus extra-objective references and reputation pairs, exactly as the compiled Questie database holds them. It is **not** a full-fidelity export of Questie's display or marker data. Display text and exact custom spawn coordinates are deliberately left out and the document says so (`displayScope = "structural-only"`). A separate future marker audit is designed in §7.

## 2. Coverage today (v1, measured)

| Measure | Quests |
|---|---|
| Compiled quests | 9,159 |
| v1 representable | 8,401 |
| v1 unsupported | 758 (0 unclassified) |

| Reason | Quests | Occurrences |
|---|---|---|
| extraObjectives `monster` references | 359 | 466 |
| extraObjectives `object` references | 243 | 335 |
| Reputation objective | 181 | 181 |
| killCreditObjectiveFirst reorder | 16 | 16 |
| Duplicate creature | 7 | 9 |
| Duplicate object | 1 | 1 |

Overlaps and the update procedure: `docs/NQ-VALIDATION-M2.2-COVERAGE.md`.

## 3. Real compiled representations (investigation)

### 3.1 How Questie uses these fields

| Field | Questie behaviour (public source) |
|---|---|
| Ordinary objectives | `QuestieDB.GetQuest` builds `ObjectiveData`: creatures, objects, items, reputation, killCredit, spells, then `triggerEnd` as an event. `QuestieQuest:PopulateQuestLogInfo` maps quest-log objective N to `ObjectiveData[N]` ("trusts the database order"). |
| `killCreditObjectiveFirst` | Each killCredit entry is inserted at position 1, so killCredit lines come first and several entries end up in reverse order. 16 quests at runtime (10503 from `tbcQuestFixes.lua`, 15 from `wotlkQuestFixes.lua`). |
| `objectives[4]` reputation | One pair `{factionId, value}` → `{Type="reputation", Id, RequiredRepValue}` |
| `extraObjectives` | `{spawns, icon, text, objectiveIndex, {{type, id}, ...}}` → `SpecialObjectives[index]` with `Icon`, `Description`, `RealObjectiveIndex`; `Type`/`Id` from the **first** reference; every reference contributes spawns |
| Icons | `Questie.ICON_TYPE_*`: 1 slay, 2 loot, 3 event, 4 object, 5 talk |

### 3.2 Measured shapes (all compiled quests, raw values)

| Measure | Value |
|---|---|
| Quests with extraObjectives | 632 (entries 730) |
| Entries with custom spawns `[1]` | 79 (78 spawn-only, no references) |
| `objectiveIndex [4]` | always present: 0 (not linked) 696; 1: 20; 2: 8; 3: 3; 4: 3 |
| References | 801: `monster` 466, `object` 335, `item` 0; max 14 per entry; 4 entries mix types; no repeated reference within an entry |
| Reputation pairs | 181, all `{factionId, value}`: 0 = 22, 3000 = 50, 9000 = 40, 21000 = 37, 42000 = 32; 21 factions; 146 combined with other objectives |

**Correction to the earlier draft.** The earlier draft reported 22 "faction-only" reputation objectives and only 31 entries with an objective index. Both were artifacts of the M0 harness's comparison normaliser, which treats 0 as absent. The raw compiled values are `{faction, 0}` and `objectiveIndex = 0`. The v2 design now requires both values and keeps 0 as 0. The draft validator and fixtures were changed to match.

## 4. Duplicate cases: evidence-based assessment

Sources: compiled data, inherited corrections, `git log`/`git blame` of the Questie corrections. No dedupe and no correction made.

| Quest | Compiled entries | Origin (git evidence) | Assessment |
|---|---|---|---|
| 11142 Survey Alcaz Island | objects {500007}, {500007}; extra: spawn-only event (zone 15), talk with `monster` 23704 | Raw DB has **no** objectives. `tbcQuestFixes.lua` added them in 4c36a5d88 (2022-10-27, "Fix missing objectives for 'Survey Alcaz Island'"). 500007 is a Questie-made object "Alcaz Survey Credit" (`tbcObjectFixes.lua`) | **Deliberate upstream mapping** of two quest-log lines to one placeholder credit object. Two lines appear intended; the in-game line count and texts **need an in-game check** before any M1 interpretation. Not a data error to remove. |
| 12683 Burning to Help | creatures {28003}, {28003} | Raw DB: {28771 "Sputum Samples Collected"}, {28003}. `wotlkQuestFixes.lua` changed line 1 to 28003 in 9f5ee0d67 (2022-10-05, "Fix objective locations for 'Burning to Help'") | **Legitimate two-line quest** (samples, then kills). Line 1 deliberately points at the hydra (28003) **for map locations**: samples come from the hydras. The ID is a location hint, not the server's credit ID. M1 must not read it as a kill-credit claim. Needs review in M2.3, not a correction. |
| 64128 Eastern Plaguelands (boosted Tauren Druid) | creatures {9564 "Speak to Tal, the Wind Rider Master"}, {9564 "Visit Zeppelin Master Frezza"} | Added by `tbcQuestFixes.lua` a192ef70d (2021-05-24, boosted-character version). 9564 is Frezza; Tal is NPC 2995. Quest is in `QuestieQuestBlacklist.lua` ("Boosted character quest"), so hidden in game | **Upstream data anomaly candidate**: line 1 names Tal but targets Frezza's ID (likely a copy). Low impact because the quest is blacklisted. **Needs an in-game check** only if it is ever unhidden. |
| 11706, 12252, 12481, 13042, 25199 | same creature, distinct texts | upstream DB | **Legitimate multi-line**: separate quest-log lines on one target (e.g. 25199 salute, roar, cheer, dance) |

Conclusion: duplicates are meaningful (positions in the quest log). v2 keeps every entry with an occurrence number. None is an "either/or" alternative.

## 5. v2 record design

```lua
{ schema = "nq-m2-effective", schemaVersion = 2, displayScope = "structural-only",
  provenance = { ... same fields and rules as v1 ... },
  quests = {
    { ID = 11652, requiredLevel = 68, questLevel = 71, sourceItemId = 0, requiredSourceItems = {},
      objectives = {                                   -- exactly Questie's ObjectiveData order
        { position = 1, kind = "killCredit", slotIndex = 2, ids = { 25332, 25333, 25469 }, rootId = 25333 },
        { position = 2, kind = "killCredit", slotIndex = 1, ids = { 27106, 27107, 27108, 27110 }, rootId = 27106 },
        { position = 3, kind = "creature",   slotIndex = 1, id = 25465, occurrence = 1 },
      },
      killCreditFirst = true, hasTriggerEnd = true,
      extraObjectives = {
        { position = 1, icon = 3, hasText = true, spawnZones = {}, objectiveIndex = 0,
          refs = { { type = "monster", id = 25334, refIndex = 1 } } },  -- "Drive a tank"
      },
      m1Status = "UNSUPPORTED_BY_RULES", m1Reasons = { "EXTRA_CREATURE_REF", "KILLCREDIT_FIRST_REORDER" } },
  } }
```

| Kind | Fields |
|---|---|
| `creature`, `object`, `item` | `id`, `occurrence` |
| `spell` | `id`, `occurrence`, optional `itemSourceId` |
| `killCredit` | `ids` (order kept), `rootId` |
| `reputation` | `factionId`, `requiredValue` (required integer; 0 is real) |
| all | `position` (list index), `slotIndex` (index in the compiled slot) |

## 6. Requirements matrix (objective preservation)

| # | Requirement | v2 mechanism | Draft test evidence |
|---|---|---|---|
| R1 | type | `kind`, `refs[].type` closed sets | unknown kind / ref type rejected |
| R2 | target ID | `id`, `ids`, `rootId`, `factionId` | invalid id rejected |
| R3 | relationship | `objectiveIndex` (0 = not linked, n ≤ #objectives), killCredit `ids`+`rootId` | missing/out-of-range index rejected; 0 kept |
| R4 | order | `objectives` in ObjectiveData order; `killCreditFirst`; reverse slot order for killCredit when first | 10503 and 11652 shapes accepted; slot order or default order rejected when the flag is set; flag must agree with order |
| R5 | position | `position` contiguous; `slotIndex` a permutation per kind; `refIndex` | gaps and bad indexes rejected |
| R6 | ordinary vs extra | separate lists; extras need refs or spawns | extra fields on ordinary objectives rejected |
| R7 | duplicates | every entry kept, `occurrence` numbered | 25199 x4 kept; wrong occurrence or a dropped duplicate rejected |
| R8 | reputation explicit | own kind, single pair, value required | value 0 kept; missing value rejected; two pairs rejected |
| R9 | M1 cannot interpret → kept but classified | `m1Status` SUPPORTED / UNSUPPORTED_BY_RULES with all reasons | false SUPPORTED rejected; `NEEDS_MANUAL_REVIEW` and old `UNSUPPORTED` rejected as record statuses |
| R10 | versioning | §8 | v1 valid; unknown/missing version rejected; migration and downgrade rules |
| D1 | display scope explicit | `displayScope = "structural-only"`; `hasText`, `spawnZones` presence | marker required; `text` and coordinate fields rejected; presence recorded |
| P1 | provenance pairing | §9 | pairing and server-provenance tests |

Draft evidence: `tests/test_nquestie_m2_effective_v2_draft.lua`, 57 checks over 10 hand-written records mirroring public shapes (1203, 1367, 735, 25199, 11142, 8470, 9666, 1369, 10503, 11652).

**Required before any production v2 exporter (lead review point 6):** a compiled-record round trip over all 9,159 quests, and specifically the 758 v1-unsupported IDs, proving that no objective kind, duplicate occurrence, reference order, reputation value or killCredit position is discarded; plus v2 → v1 equality for the 8,401 v1-representable quests. The projection below is not a measurement.

## 7. Display text and markers: explicit limitation and future extension

**v2 does not preserve:** extra-objective display text, objective text, `triggerEnd` text and coordinates, or exact custom spawn coordinates. It records only that text exists (`hasText`) and which zones custom spawns are in (`spawnZones`). Omission never means "no marker data": the document-level `displayScope` says the data was not exported, and the validator rejects attempts to smuggle text or coordinates into v2.

**Future extension (design only): `nq-m2-markers` v0**, a separate schema and export for a marker/coordinate audit:

| Element | Design |
|---|---|
| Records | per quest: `triggerEnd` coordinates; per extra objective `{position, zone, x, y}` lists; optional per-objective spawn sources (NPC/object IDs only, not Questie's derived spawn lists) |
| Precision | coordinates kept as compiled (no rounding); zone IDs validated against Questie's zone table |
| Pairing | same provenance pairing rules as v2 (§9); one markers file pairs with one effective export |
| Validation | bounds 0–100, known zones, no duplicate points within an entry, positions agree with v2 `extraObjectives` |
| Comparison | against server spawn data only when the server export carries it; otherwise reported "not comparable", never "match" |
| Privacy | public-data derived; private server comparisons stay private |

## 8. Versioning, migration, compatibility

| Rule | Detail |
|---|---|
| v1 unchanged | `EffectiveSchema.lua` untouched; v1 files valid forever |
| Unknown versions | rejected (missing version too); the frozen v1 validator rejects v2 documents |
| Dispatch | `schemaVersion` 1 → v1 validator, 2 → v2 validator, anything else rejected |
| v1 → v2 | lossless for what v1 holds; refused where v1 lacks facts (extraObjectives without icon/index; killCredit beside other objectives, whose position v1 cannot state) |
| v2 → v1 | never by discarding; refused |

## 9. Provenance compatibility rules

| Pair | Rule |
|---|---|
| Effective export ↔ its coverage manifest | must share `sourceCommit`, `sourceTree`, `nQuestieDataRevision`, `correctionCount`, `correctionFingerprint`, `correctionModules`, `tocInterface`, `flavour`, `harness`, `harnessVersion`; both clean (`sourceDirty = false`); effective `dataKind = "effective"`. Any difference: the batch stops. |
| Server input (`nq-m2-input`) | validated separately: exporter, version, `sourceLabel`, `sourceFingerprint` (sha256), `exportedAt`, `selection = "explicit"`, `questCount`. It has **no git commit** and is never compared with a Questie commit. |
| Reports | keep all records in full: server provenance, effective provenance, coverage-manifest provenance |
| Mixing | a batch takes exactly one server file, one effective file and one coverage manifest; files from different checkouts are rejected, never merged |

Draft functions: `CheckPairing` and `CheckServerProvenance` in the draft validator (tested).

## 10. M2.3 status model (final proposal)

Two separate axes per server-selected quest. Nothing is filtered silently: every requested quest appears in the private report with one export status and, where applicable, one M1 outcome.

**Export status**

| Status | Meaning |
|---|---|
| `ABSENT_FROM_EFFECTIVE_DB` | not in the compiled Questie DB (ID set pinned, see the quest ID set doc) |
| `UNSUPPORTED_BY_SCHEMA_VERSION` | in the DB, but the effective file's schema version cannot represent it; reason codes from the paired coverage manifest |
| `EXPORTED` | represented in the effective file |
| `REJECTED_MALFORMED_INPUT` | the server record failed validation (a malformed file stops the whole batch) |

**M1 outcome** (only for `EXPORTED`)

| Outcome | Meaning | May confirm? |
|---|---|---|
| `M1_UNSUPPORTED_BY_RULES` | M1 has no rule for this content (`m1Status = UNSUPPORTED_BY_RULES`) | **No.** Not a mismatch and not an evidence task |
| `NEEDS_MANUAL_REVIEW` | rules ran, evidence incomplete or ambiguous (e.g. incomplete KillCredit, unknown script/IP flags) | **No**, until a human supplies evidence |
| `EXPECTED_REPRESENTATION_DIFF` | known representation difference (e.g. 1203 effective) | no change needed |
| `CONFIRMED_MATCH` / `CONFIRMED_MISMATCH` | rules ran with complete evidence | yes, then the normal evidence review before any correction |

**Unsupported quests in private reports.** Each appears as a row with its export status, reason codes from the coverage manifest, and no M1 outcome. The summary counts them per status and reason. No quest is dropped from the report because it could not be exported.

**Pairing coverage manifest ↔ effective export.** The manifest is a separate private input. M2.3 checks pairing (§9), checks that every requested ID is in exactly one of {manifest REPRESENTABLE ∧ effective file, manifest UNSUPPORTED, absent}, and stops on any contradiction (e.g. a quest exported but listed UNSUPPORTED).

## 11. Coverage projection

| | v1 (measured) | v2 (projected) |
|---|---|---|
| Structural objective fields representable | 8,401 of 9,159 | 9,159 of 9,159 |
| Of the 758 | 0 | 758 |
| M1 SUPPORTED | 8,401 | 8,401 (unchanged) |
| Kept but `UNSUPPORTED_BY_RULES` | n/a (refused) | 758 |

This means "projected 100% representability of the structural objective fields", not a full-fidelity quest export (§7). It is projected from the coverage reasons (all are handled by §5 and none are unclassified) and the draft fixtures. It is not a measured v2 export.

## 12. Next integration and acceptance checklist

| Gate | Owner | State |
|---|---|---|
| #38 integration: all six workflows green on one commit | framework | see handover |
| Lead: real private 1203 input validated under genuine Lua 5.1 | lead | open |
| Approve this design (§5–§10) | Michael / lead | open |
| In-game checks: 11142 line count; 64128 only if unhidden | lead | open |
| v2 exporter (separate approval) with the full round-trip tests in §6 | framework | not started |
| M2.3 engine (separate approval) with the status model in §10 | framework | not started |
