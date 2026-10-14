# N-Questie M2: nq-m2-effective v2 design (DRAFT, design only)

Status: design for review. **No v2 exporter exists or is proposed in this PR.** v1 stays FROZEN and valid.
Decision in force (Michael, 14 October 2026): Option A. v1-unsupported quests are out of scope for the initial pilot (temporary); v2 is designed next. The exporter stays fail-closed.
Date: 14 October 2026 (Europe/London)
Evidence: public compiled 3.3.5a Questie database read through `cli/validate-335.lua` after the 232 M0 checks (this branch). No private data.

## 1. Why v2

The coverage report (`docs/NQ-VALIDATION-M2.2-COVERAGE.md`) shows 752 of 9,159 compiled quests that v1 cannot represent, with 0 unclassified:

| Reason | Quests | Occurrences |
|---|---|---|
| extraObjectives `monster` references | 359 | 466 |
| extraObjectives `object` references | 243 | 335 |
| Reputation objective | 181 | 181 |
| Duplicate creature | 7 | 9 |
| Duplicate object | 1 | 1 |

## 2. Investigation: real compiled representations

### 2.1 How Questie reads these fields (public source)

| Field | Source | Questie use |
|---|---|---|
| `extraObjectives` (questKey 27) | `Database/questDB.lua`: `{{spawnlist, iconFile, text, objectiveIndex (optional), {{dbReferenceType, id}, ...} (optional)}, ...}` | `QuestieDB.GetQuest` builds `SpecialObjectives[index]` with `Icon = o[2]`, `Description = o[3]`, `RealObjectiveIndex = o[4]`; `o[1]` gives custom spawns; `o[5]` gives DB references. `Type`/`Id` are taken from the **first** reference only; every reference contributes spawns. |
| `objectives[4]` reputation | `{factionId, value}` | One `ObjectiveData` entry `{Type="reputation", Id=factionId, RequiredRepValue=value}`. A single pair, not a list. |
| Ordinary objectives | slots 1-6 | `ObjectiveData` order: all creatures, all objects, all items, reputation, killCredit (moved to the front when `QuestieCorrections.killCreditObjectiveFirst[questId]`), spells (third field `ItemSourceId`), then `triggerEnd` as an event. Each entry is one quest-log line, matched by position. |
| Icon | `Questie.ICON_TYPE_*` in `Questie.lua` | 1 slay, 2 loot, 3 event, 4 object, 5 talk (6-16 are quest-state icons) |

### 2.2 extraObjectives in the 752 quests

| Measure | Value |
|---|---|
| extraObjectives entries | 666 |
| With icon `[2]` | 666 (icon 1: 57, 2: 13, 3: 280, 4: 138, 5: 178) |
| With text `[3]` | 666 |
| With custom spawns `[1]` | 15 |
| With objective index `[4]` | 31 (values 1: 19, 2: 7, 3: 2, 4: 3) |
| With DB references `[5]` | 652 (14 entries are spawn-only) |
| References | 801: `monster` 466, `object` 335, `item` 0 |
| Max references in one entry | 14 |
| Entries mixing `monster` and `object` | 4 (e.g. 3628, 10556, 13007) |
| Same reference twice within an entry | 0 |

Representative records (public data; display text omitted):

| Quest | Shape |
|---|---|
| 735 | items 4646, 4641, 4644; extra: icon 3, objectiveIndex 2, ref `object` 2871 (linked to the second objective) |
| 1136 | item 5811; extra: icon 4, ref `object` 1770 |
| 1367 | reputation {93, 3000}; extra: icon 1, nine `monster` refs (4653 ... 4652) |
| 11142 | objects {500007}, {500007}; extra 1: custom spawn in zone 15, icon 3, no refs; extra 2: icon 5, ref `monster` 23704 |

Conclusion: position, icon, the objective-index link, the reference type and the reference order all carry meaning. v1 keeps none of these for non-item references, so trimming would change meaning. Refusing was correct.

### 2.3 Reputation objectives (181 quests)

| Measure | Value |
|---|---|
| `{factionId, value}` | 159 (values: 3000 = 50, 9000 = 40, 21000 = 37, 42000 = 32) |
| `{factionId}` only, no value | 22 (8470, 8471, 9871, 9872 and 18 quests with faction 910, e.g. 8544) |
| Distinct factions | 21 |
| Combined with other objectives | 146 (e.g. 1369: item 6083 + {93, 3000}) |

The 22 faction-only entries are a data shape Questie accepts (`RequiredRepValue` = nil). v2 must keep "no value" distinct from any number and must never default it.

### 2.4 The duplicate cases (8 quests, 10 duplicate occurrences)

| Quest | Name (public) | Compiled entries | Assessment |
|---|---|---|---|
| 11706 | The Collapse | creature 25768 (no text), 25768 "Nerubian tunnels collapsed" | Distinct log lines (kill + event credit to one NPC) |
| 12252 | Torture the Torturer | 27209 "fully questioned", 27209 (no text) | Distinct log lines (question, then kill) |
| 12481 | Adding Injury to Insult | 24238 "insulted", 24238 "defeated" | Distinct log lines |
| 13042 | Deep in the Bowels of The Underhalls | 30409 "Information beaten out ...", 30409 (no text) | Distinct log lines (beat, then slay) |
| 25199 | Basic Orders | 39368 x4: salute, roar, cheer, dance | Four distinct log lines (3 duplicate occurrences) |
| 64128 | Eastern Plaguelands | 9564 "Speak to Tal...", 9564 "Visit Zeppelin Master Frezza" | Distinct lines naming two different NPCs on one ID: likely a placeholder credit. **Data anomaly candidate** |
| 12683 | Burning to Help | 28003, 28003 (no text either) | Quest text asks for samples and kills; two identical entries. **Data anomaly candidate** (one may belong to another slot) |
| 11142 | Survey Alcaz Island | object 500007, 500007 (no text) | 500007 is in Questie's custom-object range; two identical entries. **Data anomaly candidate** |

Findings:

1. Duplicates are not accidental repeats in most cases: 5 quests (11706, 12252, 12481, 13042, 25199) use the same target for several separate log lines. Deduplicating would delete real objectives.
2. They are not alternatives (an "either" choice). Questie shows each as its own line by position.
3. Three (64128, 12683, 11142) look like data anomalies. That is a review question for the data owner, not something the exporter may decide.

## 3. v2 design

### 3.1 Record shape

```lua
{
  ID = 11142, requiredLevel = 32, questLevel = 37,
  sourceItemId = 0, requiredSourceItems = {},
  objectives = {                       -- one entry per ObjectiveData line, in Questie order
    { position = 1, kind = "object", slotIndex = 1, id = 500007, occurrence = 1 },
    { position = 2, kind = "object", slotIndex = 2, id = 500007, occurrence = 2 },
  },
  killCreditFirst = false,             -- QuestieCorrections.killCreditObjectiveFirst
  hasTriggerEnd = true,
  extraObjectives = {                  -- separate from ordinary objectives
    { position = 1, icon = 3, hasText = true, spawnZones = { 15 }, refs = {} },
    { position = 2, icon = 5, hasText = true, spawnZones = {},
      refs = { { type = "monster", id = 23704, refIndex = 1 } } },
  },
  m1Status = "UNSUPPORTED", m1Reasons = { "DUPLICATE_OBJECT", "EXTRA_CREATURE_REF" },
}
```

| Kind | Fields |
|---|---|
| `creature`, `object`, `item` | `id`, `occurrence` |
| `spell` | `id`, `occurrence`, optional `itemSourceId` |
| `killCredit` | `ids` (non-empty list, order kept), `rootId` |
| `reputation` | `factionId`, optional `requiredValue` (absent = no value in Questie data) |

### 3.2 How each requirement is met

| # | Requirement | Design |
|---|---|---|
| R1 | Preserve type | `kind` (ordinary) and `refs[].type` (extra), closed enumerations |
| R2 | Preserve target ID | `id` / `ids` / `rootId` / `factionId` exactly as compiled |
| R3 | Preserve relationship | extra `objectiveIndex` (Questie `RealObjectiveIndex`); killCredit `ids` with `rootId` |
| R4 | Preserve order | `objectives` in Questie `ObjectiveData` order; `killCreditFirst` recorded |
| R5 | Preserve position | `position` = list index (contiguous); `slotIndex` within each kind; `refIndex` within an extra |
| R6 | Ordinary vs extra | separate lists; extras carry `icon`, `hasText`, `spawnZones`, `refs`, and need refs or spawns |
| R7 | Duplicates with occurrence | every entry kept; `occurrence` numbers repeats of the same (kind, id) |
| R8 | Reputation explicit | its own kind; at most one per quest; missing value stays missing |
| R9 | M1 cannot interpret: preserve but classify | `m1Status`/`m1Reasons`: UNSUPPORTED when any reputation, extra creature/object reference or duplicate is present; validator rejects a SUPPORTED claim for such a record (no false SUPPORTED, so no false CONFIRMED downstream) |
| R10 | Versioning | see §4 |

Display text and spawn coordinates stay out (as in v1): `hasText` and `spawnZones` record their presence only.

### 3.3 What M1 would do with v2

M1 rules are unchanged. A v2 record with `m1Status = "SUPPORTED"` converts to the same Questie record v1 produces today. An UNSUPPORTED record is never passed to M1 for a CONFIRMED result. M2.3 reports it as "present but unsupported" (§5). New M1 rules for reputation, extra references and duplicate lines are a separate, later decision.

## 4. Versioning, migration and compatibility

| Rule | Detail |
|---|---|
| v1 unchanged | `EffectiveSchema.lua` and its tests are not touched. v1 files stay valid forever. |
| Unknown versions | Rejected (a missing version too). The frozen v1 validator already rejects v2 documents. |
| Dispatch | A future loader dispatches on `schemaVersion`: 1 to the v1 validator, 2 to the v2 validator, anything else rejected. |
| v1 to v2 | Feasible and lossless for what v1 holds. Facts v1 never recorded are not guessed: a v1 record with extraObjectives (no icon/index in v1), or with killCredit next to other objectives (relative order unknown in v1), is refused for migration and must be re-exported as v2. |
| v2 to v1 | Never by discarding. The draft refuses every downgrade; a later version may allow it only when the v2 record holds nothing v1 cannot express. |
| Provenance | Same fields and rules as v1 (reused). |

## 5. M2.3 status model (update)

Each quest in a batch gets exactly one status. No silent filtering: every server-selected quest appears in the report.

| Status | When |
|---|---|
| `ABSENT_FROM_EFFECTIVE_DB` | The quest is not in the compiled Questie DB |
| `UNSUPPORTED_BY_SCHEMA_VERSION` | Present, but the effective file's schema version cannot represent it (v1 today: the 752; reason codes from the coverage manifest) |
| `EXPORTED` | Supported and exported; M1 classifications follow |
| `REJECTED_MALFORMED_INPUT` | The server input record (or the effective file) failed validation; the whole batch stops if the file is malformed |
| `NEEDS_MANUAL_REVIEW` | Exported but M1 cannot decide (including v2 `m1Status = UNSUPPORTED` content) |

Other M2.3 rules:

- The preflight (coverage) manifest is a separate private input, never merged into the effective export.
- Reports keep both provenance records in full (server input and effective), plus the coverage manifest's commit; all three commits must match or the batch stops.
- The summary file (shareable) holds counts per status and reason only.

## 6. Test plan for v2 (for the future exporter)

| # | Test | Real quests (public) |
|---|---|---|
| R1 | Each kind and each reference type round-trips | 1203 item, 2001 creatures, 498 objects, 2784 killCredit, 1367 monster refs, 735 object refs |
| R2 | IDs equal compiled values | as above |
| R3 | objectiveIndex kept; killCredit ids/root kept | 735 (index 2), 9666 |
| R4 | ObjectiveData order, incl. item-before-reputation and killCreditFirst | 1369; 10503 (the only `killCreditObjectiveFirst` quest) |
| R5 | Positions contiguous; ref order kept | 1367 (nine refs), 3628 (mixed refs) |
| R6 | Spawn-only extra vs reference extra | 11142 (both in one quest) |
| R7 | All occurrences kept and numbered | 25199 (x4), 11706, 12252, 12481, 13042, 64128, 12683, 11142 |
| R8 | Reputation with and without value | 1036, 8470 (faction only) |
| R9 | No false SUPPORTED | every UNSUPPORTED category and overlap: 3628, 1920, 735, 1367, 1380, 11142, 11706, 1036, 12252 |
| R10 | v1 still valid; unknown version rejected; v1 to v2 migration; downgrade refused | v1 fixtures; 1203 |

Plus, for the future exporter: a full-DB run must export all 9,159 quests (0 refused, 0 unclassified), and a v2 export of the 8,407 v1-representable quests must convert back to exactly the v1 records.

### Prototype evidence (this PR, DRAFT)

`tools/validation/draft/EffectiveSchemaV2Draft.lua` is a **draft** validator that refuses to run without `allowDraft = true` and is used by no harness. `tests/fixtures/m2_effective_v2_draft/v2_categories.lua` holds 8 hand-written records that mirror the public compiled shapes of 1203, 1367, 735, 25199, 11142, 8470, 9666 and 1369. `tests/test_nquestie_m2_effective_v2_draft.lua`: 33 checks covering R1-R10 (positive and negative cases), the draft guard, migration and downgrade refusal. The fixture also parses with the frozen data-only parser.

## 7. Coverage projection (before / after)

| | v1 (today) | v2 (projected) |
|---|---|---|
| Representable in the schema | 8,407 of 9,159 (91.8%) | 9,159 of 9,159 (100%) |
| Of the 752 | 0 | 752 |
| M1 SUPPORTED (usable for CONFIRMED) | 8,407 | 8,407 (unchanged) |
| Present but M1 UNSUPPORTED | n/a (refused) | 752 (quests with each reason, overlapping: extra refs 571, reputation 181, duplicates 8) |

Basis: every refusal in the real DB has one of the five reason codes handled by §3 and there are 0 unclassified or "other" refusals. This is a projection from the coverage data and the draft fixtures, not a measured v2 export. It must be confirmed by the v2 exporter's full-DB test.

Gains for M1 would need new rules, each a separate decision: duplicate-line semantics (6 duplicate-only quests), reputation comparison (175 reputation-only quests), extra-reference comparison (the rest).

## 8. Decisions needed

1. Approve the v2 shape (§3), the M1 rule for UNSUPPORTED (R9) and the versioning rules (§4).
2. Data anomaly review for 64128, 12683 and 11142 (data owner).
3. Whether `spawnZones` (zone IDs only) is wanted, or presence only.
4. Approve the M2.3 status model (§5) before M2.3 code.
