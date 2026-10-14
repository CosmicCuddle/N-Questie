# N-Questie M2.2: compiled quest ID set (9,158 vs 9,159)

Status: explained and pinned by a regression test. No data was changed.
Date: 14 October 2026 (Europe/London)
Evidence: public 3.3.5a Questie data loaded by `cli/validate-335.lua` (actual ID sets compared, not counts).

## 1. Answer

The M0 log's `questData records=9158` is the set **before the N-Questie callbacks run**. The compiled DB (`QuestieDB.QuestPointers`, which the exporter and coverage tool read) has 9,159. The single difference is **quest 2001 (Ravenclaw Cleanup)**, added by the N-Questie custom quest overlay `Compat/NQuestieCustomQuestData.lua`. No ID is removed or replaced by N-Questie.

## 2. ID sets compared

| Stage | IDs | Difference from the previous stage |
|---|---|---|
| Raw `Database/Wotlk/wotlkQuestDB.lua` | 9,086 | |
| After inherited Questie corrections, before N-Questie (`before`) | 9,158 | +72 new IDs, 0 removed (inherited) |
| After N-Questie callbacks (`after`) | 9,159 | +2001, 0 removed |
| Source table handed to the compiler | 9,159 | identical set |
| Compiled `QuestPointers` (exporter and coverage input) | 9,159 | identical set |

All keys are numbers and every compiled ID is unique. All 9,159 compiled quests have a name and a numeric quest level.

### Inherited additions (+72, before N-Questie)

| Source (public Questie) | New IDs |
|---|---|
| `tbcQuestFixes.lua` `InsertMissingQuestIds` | 28 (e.g. 63866 ... 64845; includes 64128) |
| `wotlkQuestFixes.lua` `InsertMissingQuestIds` | 37 (70395 ... 78753) |
| `classicQuestFixes.lua` `LoadMissingQuests` | 7 (65593 ... 65610) |

### Inherited replacements (same ID kept)

The same functions also set **90 IDs that already exist in the raw file** to `{}` before the correction tables fill them: 85 in `tbcQuestFixes.lua` (12133 ... 12421) and 5 in `classicQuestFixes.lua` (5640, 5678, 7668, 7669, 7670). The IDs stay the same, and every one has a name and level after corrections. This is inherited Questie behaviour, outside N-Questie, and is covered by M0's 82,431-field compiled round trip, which compares against the post-correction table.

## 3. Is 2001 involved?

Yes, and it is the only quest involved. The harness now prints `questData IDs added by N-Questie: 2001; removed: none` (an informational line, not an extra check, so the M0 count stays 232). The existing M0 allow-list already fails if N-Questie adds any record not allow-listed.

## 4. Coverage examines the final effective DB

The coverage tool and the exporter both iterate `QuestieDB.QuestPointers` after compilation, which equals the post-correction source set. 2001 is included (REPRESENTABLE).

## 5. Regression test

`tests/test_nquestie_m2_coverage_integration.sh` checks:

| Check | Pinned value |
|---|---|
| Pre-N-Questie quest count | 9,158 |
| N-Questie ID changes | added 2001, removed none |
| Compiled ID count | 9,159 |
| sha256 of the sorted compiled ID list (one decimal ID per line, newline-terminated) | `e7dfb2a99642544b66359b6721887083a3bdab783986d75de32296c783edb6a3` |
| Unique IDs, 2001 present | yes |

### Update procedure

If upstream Questie or an N-Questie correction legitimately adds or removes quests:

1. Run the coverage command (coverage doc §4) and list the changed IDs: `lua5.1 -e` over the private manifest, or compare the old and new sorted lists.
2. Explain every added or removed ID by its source (upstream file, inherited correction or N-Questie overlay). Never edit data to match the pin.
3. Update `PIN_COUNT`, `PIN_SHA` and, if the N-Questie overlay changed, the "added by N-Questie" line in the test, plus this document and the coverage pins, in one commit with a development-log entry.
