# N-Questie Validation M2.2: Effective Questie Export (Design Only)

Status: Proposed, not implemented
Date: 2026-10-14
Depends on: M2.1 input schema; M0 harness on the 28-quest integration baseline (PR #20)

## 1. Goal

Export the **effective** post-correction objective records from the compiled 3.3.5a N-Questie database, in a form that M2.3 can compare with M2.1 server input. Report-only. No quest data is changed.

## 2. Why "effective"

Stock `wotlkQuestDB.lua` is not what the client uses after N-Questie corrections. Corrections are applied through `QuestieCompat.LoadCorrections` during init. M2.2 must run the same path the M0 harness already uses (`cli/validate-335.lua`): load, compile, apply corrections, then read objectives. Using the raw DB file would mis-classify every corrected quest (including 1203).

## 3. Architecture

```
cli/validate-335.lua  (existing M0 harness)
        |
        |-- preservation check: 82,431 fields, 28-quest allow-list
        |-- level-correction count guard
        |-- M1 check on quest 1203 (stock vs effective)
        |
        v  [new flag, M2.2]
--export-effective PATH
        |
        v
write effective objective snapshot (Lua data literal, same shape as M2.1 quest rows
without server-only KillCredit / flags / provenance)
```

| Step | Behaviour |
|---|---|
| 1 | Run the existing M0 pipeline unchanged. If any M0 assertion fails, do not export. |
| 2 | After corrections are applied and the preservation check has passed, walk every quest id that appears in the M2.1 input (or a caller-supplied id list). |
| 3 | For each id, read `QuestieDB.QueryQuest` / the compiled table: objectives (creatures, objects, items, killCredit slot, spells), `sourceItemId`, `requiredSourceItems`, name. |
| 4 | Write a Lua data literal to PATH. PATH must be absolute and outside the public checkout (same path rules as M2.1), or under `private/`. Never write under tracked paths. |
| 5 | Refuse to overwrite an existing file unless an explicit `--force` flag is passed (default: refuse). |

## 4. Output format (proposed)

Match what M2.3 needs for `ObjectiveRules.Compare(server, questie)`:

```lua
return {
    schema = "nq-m2-effective",
    schemaVersion = 1,
    provenance = {
        exporter = "validate-335",
        exporterVersion = "…",
        sourceLabel = "nquestie-compiled",
        compiledRevision = <nQuestieDataRevision or equivalent>,
        exportedAt = "2026-10-14T12:00:00Z",
        questCount = N,
        m0Checks = <number of M0 assertions that passed>,
    },
    quests = {
        {
            ID = 1203,
            -- Questie-shaped objectives only (questKeys index 10), plus:
            sourceItemId = …,          -- questKeys 11
            requiredSourceItems = { … }, -- questKeys 21
            name = "…",                -- for private reports; strip for any public aggregate
            objectives = {
                creatures = { { id = … }, … },
                objects   = { { id = … }, … },
                items     = { { id = … }, … },
                killCredit = { … },    -- Questie slot 5, if present
            },
        },
        …
    },
}
```

M2.3 will turn each server M2.1 row through `ObjectiveRules.FromQuestTemplateRow` and each effective row into the questie table shape `Compare` already expects. Keeping objectives in an explicit structure avoids re-parsing compiled DB blobs in the batch runner.

## 5. Reuse of the M0 harness

| Existing guarantee | Keep in M2.2 |
|---|---|
| 28 reviewed level corrections active | Yes; do not weaken the allow-list or the expected count |
| 82,431-field preservation check | Yes; export is skipped if it fails |
| 5 negative fixture rejections | Untouched |
| Quest 1203 stock = CONFIRMED, effective = EXPECTED | Untouched; optionally assert the exported 1203 item objective is 3853 |
| Lua 5.1, report-only | Yes |

No edits to the runtime revision system. No TOC changes. No correction-file changes.

## 6. Proposed implementation sketch (not in this PR)

1. Factor a small `tools/validation/EffectiveExport.lua` that, given a loaded QuestieDB and a list of ids, returns the snapshot table.
2. Add `--export-effective PATH` to `cli/validate-335.lua`, gated so it runs only after all existing checks pass.
3. Synthetic test: load a minimal fake QuestieDB table, export, parse with a sister schema validator (`nq-m2-effective` v1), confirm quest 1203's item id is 3853 when the N-Questie correction is present.
4. CI uses only synthetic data. Real exports stay on the lead developer's machine.

## 7. Safety

- Same path gate as M2.1.
- No private server data in the export (this side is Questie-only).
- Name fields may be useful privately; any public aggregate must drop them.
- Failure of M0 ⇒ no file written (fail closed).
- CONFIRMED findings from a later M2.3 run are still not actionable without human review.

## 8. Acceptance criteria (when M2.2 is built)

| Criterion | Evidence |
|---|---|
| Export refused when M0 fails | Negative test |
| Export of synthetic 1203 has item 3853 after corrections, 33110 before | Fixture test |
| Path gate identical to M2.1 | Shared helper test |
| Full M0 + M1 + M2.1 suites still pass | CI |
| No `.github` workflow edits without a proposed-workflows entry | Review |

## 9. Out of scope for this design doc

Implementing the export, the batch runner (M2.3), changing PR #19/#20, automatic corrections.
