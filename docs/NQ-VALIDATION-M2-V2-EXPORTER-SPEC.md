# N-Questie M2 production v2 exporter: implementation specification

Status: **specification only**. No production v2 exporter exists and none is authorised by this document. Implementation needs a separate maintainer decision. Stacked on PR #39 (v2 design, final draft).

Date: 14 October 2026. Baseline measured on the 3.3.5a effective database: 9,159 compiled quests, 8,401 v1-representable, 758 unsupported by v1, 0 unclassified; 232 M0 checks; 82,431 fields.

## 1. Purpose and scope

The v2 exporter writes `nq-m2-effective` schema version 2: a structural, ordered copy of every compiled quest's objective data, as Questie builds it at runtime. It replaces nothing. v1 (`nq-m2-input` v1 and `nq-m2-effective` v1) stays frozen and the v1 exporter keeps working unchanged.

In scope: objectives, their order and repeats, kill credit, reputation, extra objectives (references and objective index, not text or coordinates), source items, levels, trigger-end presence, per-quest M1 support status, provenance.

Out of scope: display text, spawn coordinates, markers (see the separate nq-m2-markers design), any comparison with server data (M2.3), any correction.

## 2. Inputs and how to read them

| Input | Source | Rule |
|---|---|---|
| Quest ID set | compiled `QuestieDB.QuestPointers` after all corrections | 9,159 IDs; must equal the compiler input set (pinned sha256 `e7dfb2a9...b6a3`) |
| Quest records | `QuestieDB.QueryQuestSingle` per field, after corrections | raw compiled values, never the M0 `normalize` helper (it turns 0 into nil) |
| Kill-credit-first set | `QuestieCorrections.killCreditObjectiveFirst` | must be present and non-empty, or the run fails (as in `exportContext()` today); 16 quests at baseline |
| M1 reason codes | `EffectiveExport.Record` classification and `Coverage.Classify` | the same codes as the coverage manifest; recomputed, never copied from a file |
| Provenance | git (commit, tree, dirty), TOC, revision, correction fingerprint and modules, M0 count | read once at start; dirty tree refuses unless an explicit development flag is set, and then `sourceDirty = true` is recorded |

## 3. Record content per quest

Every compiled quest gets exactly one record. Field definitions are those in the v2 design §5; the exporter must fill them as follows.

| Field | Rule |
|---|---|
| `ID` | integer > 0 |
| `requiredLevel`, `questLevel` | raw integers (questLevel may be -1, meaning scaling) |
| `sourceItemId` | raw value, 0 when absent |
| `requiredSourceItems` | list in compiled order, kept even when an ID is also an item objective (Questie only skips the special objective at runtime, `QuestieDB.GetQuest`) |
| `objectives` | ordered list (section 4) |
| `killCreditFirst` | true only if the quest is in the kill-credit-first set **and** has at least one killCredit objective |
| `hasTriggerEnd` | boolean presence of `triggerEnd` (contents not exported) |
| `extraObjectives` | every entry in compiled order (section 5) |
| `m1Status`, `m1Reasons` | `SUPPORTED` with empty reasons, or `UNSUPPORTED_BY_RULES` with the sorted unique reason codes; must equal `ExpectedM1` in the draft validator |

## 4. Objective ordering, repeats and kill credit

The exporter reproduces `QuestieDB.GetQuest` exactly, because quest-log line N maps to `ObjectiveData[N]` (`QuestieQuest:PopulateQuestLogInfo`).

1. Walk slots in kind order: creatures [1], objects [2], items [3], reputation [4], killCredit [5], spells [6].
2. Within a slot keep compiled order. `slotIndex` is the 1-based index inside the slot.
3. Repeated IDs within a slot are kept, each with `occurrence` = 1, 2, 3... in compiled order (25199 has four; 11142 two; 12683 two). Never deduplicated, never merged.
4. If `killCreditFirst` is true, each killCredit entry is inserted at position 1 in slot order, so killCredit entries come first and **reversed** (slot 3, 2, 1). 11652 is the real two-entry case; 900003 in the acceptance fixture is the synthetic three-entry case.
5. `position` is the final 1-based list position.
6. Reputation keeps `factionId` and `requiredValue` exactly, including 0 (22 quests at baseline). Missing value is a malformed record, not 0.
7. killCredit keeps every ID in `ids` in compiled order and `rootId`.
8. Spells keep `id` and the optional `itemSourceId`.

## 5. Extra objectives

Each entry `{spawns, icon, text, objectiveIndex, refs}` becomes `{position, icon, hasText, spawnZones, objectiveIndex, refs}`.

- `spawnZones`: sorted list of zone IDs that have spawns; coordinates are not exported.
- `objectiveIndex`: always exported, including 0 (696 of 730 entries). Must be ≤ number of objectives, with one exception found by the Stage A1 measurement: it may be number of objectives + 1 when the quest has a triggerEnd (that line is the event objective) or has no DB objectives at all (a client-only quest-log line). 5 real quests use this: 10985 and 13429 (triggerEnd), 12124, 13418 and 13419 (no objectives). Anything larger is rejected.
- `refs`: every `{type, id}` with `refIndex`, in compiled order. Note: at runtime Questie takes `Type`/`Id` from the first reference only but merges the spawns of **all** references (`QuestieDB.GetQuest`, extraObjectives loop); the export keeps all of them so neither behaviour is lost.
- Baseline: 632 quests, 730 entries, 801 refs (monster 466, object 335, item 0), 78 spawn-only entries.

## 6. The 758 unsupported quests

The 758 are exported in full like every other quest. They differ only in `m1Status = UNSUPPORTED_BY_RULES` and their reason codes. The exporter does not trim reputation, drop extras, reorder kill credit to make a quest "fit", or skip it. Per-reason baseline (quests/occurrences): EXTRA_CREATURE_REF 359/466, EXTRA_OBJECT_REF 243/335, REPUTATION_OBJECTIVE 181/181, KILLCREDIT_FIRST_REORDER 16/16, DUPLICATE_CREATURE 7/9, DUPLICATE_OBJECT 1/1.

## 7. Versioning

| Item | Rule |
|---|---|
| `schemaVersion` | 2; unknown versions are rejected by every reader |
| v1 | unchanged, still produced by the existing exporter |
| v1 → v2 migration | "v1-held-fields-only"; refused for any quest with extraObjectives or killCredit (v2 design §8) |
| v2 → v1 | refused (no downgrade) |
| Harness version | 1.2.0 for the order protection (separate PR); the production v2 exporter bumps it again |

## 8. Failure handling, paths, determinism, performance

- **Fail closed, whole file.** Any malformed record, unclassified quest, missing kill-credit-first set, ID-set mismatch, provenance error or validator failure: no file is written. Errors go to stderr with the quest ID and field.
- **Self-validation.** The document is validated with the v2 validator before writing; the written bytes are re-read and validated again.
- **Safe paths.** Writes only through `SafeWrite` (no overwrite of existing files, no symlinks, no repository paths, owner-only permissions), the same rules as the private coverage manifest.
- **Deterministic serialisation.** Quests sorted by ID; keys in a fixed order per table; integers only (no floats); `\n` line endings; no timestamps except `provenance.exportedAt`. Reproducibility is tested, not forced: the test harness compares `Canonical(doc, exclude)` (draft function, tested), where `exclude` may only name per-run provenance fields (`exportedAt`, and `sourceCommit`/`sourceTree` across commits). The real file keeps its real timestamp; production provenance is never weakened to make hashes stable.
- **Inputs untouched.** Deep compare of the compiled database before and after the run.
- **Performance target.** All 9,159 quests within the existing M0 run budget; no measured figure yet (no exporter). The acceptance run records wall time and peak memory.
- **Privacy.** The export holds only public Questie data, but it goes to a private path by default, as v1 does, to keep one handling rule for all M2 files.

## 9. Acceptance test plan

Synthetic tests (run in CI, no private data):

| ID | Check | Where today |
|---|---|---|
| A1 | category fixture (10 real-shape quests) valid | `tests/test_nquestie_m2_effective_v2_draft.lua` |
| A2 | acceptance fixture (6 synthetic quests, IDs 900001-900006) valid; covers no-objective quest, all six kinds, multi-ID kill credit, three reversed kill-credit entries, required source items, spell item source, trigger end, objectiveIndex 0 and maximum, spawn-only extra | `tests/test_nquestie_m2_v2_acceptance.lua` |
| A3 | negative: kill credit not reversed, reputation 0 dropped, objectiveIndex too large (n+2, or n+1 without triggerEnd), quest dropped, display text present, unknown version | same |
| A4 | migration refusals and downgrade refusal | v2 draft test |
| A5 | reproducible comparison: exportedAt excluded explicitly, record and non-run provenance differences still detected, non-run exclusion refused, v1 golden fixture | acceptance test |

Full-database tests (to run once an exporter is authorised):

| ID | Check | Pass condition |
|---|---|---|
| F1 | quest set | 9,159 records; ID-list sha256 equals the pin |
| F2 | coverage | 8,401 SUPPORTED, 758 UNSUPPORTED_BY_RULES; per-reason counts equal the coverage manifest of the same commit |
| F3 | round trip (section 10) | 0 differences over 9,159 |
| F4 | no-loss for the 758 (section 10) | 0 differences; 801 refs, 181 reputation values, 16 kill-credit-first quests accounted for |
| F5 | v1 equivalence (section 11) | 0 differences over 8,401 |
| F6 | determinism | two runs on the same clean tree are byte-identical after `Canonical(doc, {"exportedAt"})`; production provenance keeps its real timestamp |
| F7 | M0, M1, v1 unchanged | 232 M0 checks pass with strict field-level pins; M1 and v1 suites pass; v1 writer source unchanged (diff empty); v1 export equivalent before and after by `Canonical(doc, {"exportedAt"})` (and `sourceCommit`/`sourceTree` only when comparing across commits), plus the synthetic v1 golden fixture test |
| F8 | fail-closed | injected malformed record, missing kill-credit set, unwritable path: no file |

## 10. Round-trip proof design

Goal: show v2 holds every structural fact of every compiled quest.

1. **Rebuild.** From each v2 record rebuild the compiled objective table: put objectives back into slots by `kind` and `slotIndex` (ignoring `position`), rebuild reputation pairs, killCredit `{{ids}, rootId}`, spells, `requiredSourceItems`, `sourceItemId`, levels.
2. **Order check.** Independently recompute `position` from the rebuilt slots with the Questie rules (section 4) and compare with the exported `position`.
3. **Compare.** Deep-compare the rebuilt structure with the raw compiled record for all 9,159 quests, excluding only the documented exclusions (text, coordinates, trigger-end contents). Report counts only: quests compared, quests differing, differences per field. Any difference fails.
4. **No-loss for the 758.** For the unsupported quests, additionally count, per reason, the facts that v1 cannot hold and check every one is present in v2: extra refs (801, by type), reputation pairs (181, including 22 zeros), kill-credit-first quests (16, with reversed order checked), duplicate occurrences (10). Totals must equal the coverage manifest.

A measured prototype of this round trip was considered (optional in the brief) and **not built** in this PR: it would need a v2 record builder over the live database, which is close to the exporter itself. It is listed as the first step of the implementation sequence instead.

## 11. v1 vs v2 equivalence contract (the 8,401)

For each SUPPORTED quest, the v1 record and the v2 record are equivalent when all of the following hold. Nothing else is claimed.

| Fact | v1 | v2 | Rule |
|---|---|---|---|
| levels, sourceItemId, requiredSourceItems, hasTriggerEnd | held | held | equal |
| creature, object, item, spell IDs per slot, in order | held | held | equal per slot |
| killCredit ids and rootId | held | held | equal |
| reputation | v1 cannot hold it | held | none (SUPPORTED quests have no reputation) |
| extraObjectives | v1 holds only a presence flag and item list | full | v1 flag equals `#extraObjectives > 0`; nothing more compared |
| cross-kind order (`position`) | not held | held | **no claim**; v1 never stored it |
| killCreditFirst | not held | held | **no claim** (SUPPORTED quests have it false, but v1 cannot confirm) |
| occurrence | implied by list order | explicit | v1 list order equals v2 occurrence order |

## 12. Remaining open points

- Exporter entry point: **decided** (maintainer, 14 October 2026): an explicit opt-in v2 mode in `cli/validate-335.lua`. See `docs/NQ-VALIDATION-M2-V2-EXPORTER-PROPOSAL.md` for the trade-off and the mode contract.
- Performance figures (none measured).
- HARNESS_VERSION: **decided**, 1.1.0 → 1.2.0 with the kill-credit ordering protection, in a separate draft PR on the #38 line (not in this design stack). The production v2 exporter bumps it again (proposed 1.3.0).
