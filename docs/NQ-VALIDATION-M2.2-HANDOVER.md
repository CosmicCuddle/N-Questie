# N-Questie Validation M2.2: Handover (Steps 2–6)

Status: Draft PRs, report-only, unmerged
Date: 2026-10-14
Owner: validation workstream (framework). Real data, comparisons and corrections: lead developer.

## 1. PR stack and dependency order

| Order | PR | Branch | Content |
|---|---|---|---|
| 0 | #24 | feat/nq-validation-m2.2-step1-effective-schema-2026-10-14 | Step 1: `nq-m2-effective` v1 schema |
| 1 | #26 | feat/nq-validation-m2.2-integration-2026-10-14 | #24 plus a `--no-ff` merge of #25 (includes #23): `private/` guard in the stack |
| 2 | #27 | feat/nq-validation-m2.2-snapshot-writer-2026-10-14 | Step 2 snapshot, Step 4 safe writer |
| 3 | #28 | feat/nq-validation-m2.2-harness-export-2026-10-14 | Step 3 harness export and provenance |
| 4 | #29 | feat/nq-validation-m2.2-tests-ci-docs-2026-10-14 | Steps 5+6: suite runner, proposed CI, docs |

Review and merge bottom-up. No rebases, force-pushes or base changes were made. #24, #25, #23 and #22 are unchanged.

**Integration route.** #26 starts at #24's head (cf57a1d71) and merges #25's head (b2ddf2f15) with `git merge --no-ff`. The only conflicts were lines appended to `docs/ROADMAP.md` and `docs/PROJECT-HANDOVER.md`; both sides were kept. The stack therefore runs #25's private-guard CI steps.

**Why this split.** The suggested split was Step 2+3, then 4, then 5+6. The harness export (Step 3) must not write without the safe writer (Step 4), so the two libraries (Steps 2 and 4) come first and the harness hook second. Each PR still carries its own tests.

## 2. Per-step summary

| Step | What | Key files |
|---|---|---|
| 2 | Pure snapshot of the compiled DB (via `QuestieDB.QueryQuestSingle` after compilation, runtime overrides applied) into v1 records. Explicit IDs only; missing, duplicate or invalid IDs are rejected; objective order is kept; nothing is mutated (deep-compare checked). Records v1 cannot represent are refused (§4). | `tools/validation/EffectiveExport.lua` |
| 3 | Opt-in export in `cli/validate-335.lua`. Options are checked before M0. The export runs only after all checks pass (232) and doesn't change the check list. Provenance comes from git, the loaded files and the loaded data. Without the option, behaviour is unchanged. | `cli/validate-335.lua`, `tools/validation/ExportProvenance.lua` |
| 4 | Safe writer: resolved approved locations, user-owned 0700 directory, 0600 temp file in the destination, link(2) no-clobber install, rename(2) only with force, post-install check | `tools/validation/SafeWrite.lua`, `docs/NQ-VALIDATION-M2.2-SAFE-WRITER.md` |
| 5 | Tests per Michael's list (§5) and the M2 suite runner | `tests/test_nquestie_m2_*.lua`, `tests/test_nquestie_m2_export_integration.sh`, `tests/run_m2_suite.sh` |
| 6 | Proposed CI workflow (token has no workflow scope) | `docs/proposed-workflows/nquestie-m2-effective-export.yml` |

### Export usage

```bash
mkdir -m 700 /abs/private-out
NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 \
NQ_EXPORT_EFFECTIVE_OUT=/abs/private-out/effective.lua \
NQ_EXPORT_QUESTS="1203,2001" \
lua5.1 cli/validate-335.lua
# or NQ_EXPORT_SELECTION=/abs/private/input.lua (a validated nq-m2-input file)
# NQ_EXPORT_FORCE=1 replaces an existing output file atomically
```

Environment variables are used because the harness already uses `arg[1]` for the faction.

### Provenance sources

| Field | Source |
|---|---|
| sourceCommit / sourceTree | `git rev-parse HEAD` / `HEAD^{tree}`, after checking the harness root is the git top level |
| sourceDirty | `git status --porcelain --untracked-files=all` must be empty, otherwise refuse |
| correctionModules | `Compat/NQuestie*.lua` files that the TOC load actually loaded, in TOC order; each must be tracked |
| correctionFingerprint | sha256 over `name sha256(file)` lines in TOC order |
| nQuestieDataRevision | `NQuestieCustomQuestData.revision` from the loaded data (5 today) |
| correctionCount | Level corrections the harness asserted (28), which must equal `NQ_VALIDATE_EXPECT_LEVEL_COUNT`. The quest 1203 item correction and the quest 2001 overlay are checked by M0 but not counted here. |
| m0Checks | The harness's actual pass count (232) |
| tocInterface | `## Interface:` in `Questie-335.toc`, which must equal `GetBuildInfo` (30300) |
| stock export | Not implemented. Optional, and not needed for M2.3. The schema supports `dataKind = "stock"` for a future, clearly separate path. |

## 3. Real-DB evidence

The integration test exports 10 real quests from the compiled 3.3.5a database and checks exact values:

| Quest | Exported (req/quest level, objectives) | Covers |
|---|---|---|
| 1203 | 30/35, item 3853 | The known correction |
| 2001 | 12/16, creatures 1868, 1869 | N-Questie overlay quest, multiple creatures |
| 2784 | 45/50, killCredit {7572} root 7572 | Kill credit |
| 30 | 16/−1, item 15885, requiredSourceItems 15883, 15882, extraObjectives present | Source items, scaling level, extraObjectives without refs |
| 25 | 23/25, creature 3917, triggerEnd | triggerEnd |
| 28 | 16/−1, no objectives, requiredSourceItems 15877, triggerEnd | Empty lists |
| 498 | 17/22, objects 1721, 1722, requiredSourceItems 3467, 3499 | Gameobjects |
| 532 | 19/26, creatures 2335, 2387, object 1761, item 3657 | Mixed types |
| 553 | 29/33, objects 1768, 1769, 1770, sourceItemId 3710 | sourceItemId, 3 objects in order |
| 786 | 5/8, objects 3189, 3190, 3192 | Object order |

Provenance in the test run: m0Checks 232, correctionCount 28, revision 5, sourceCommit equals HEAD, TOC 30300. M1 on the exported 1203 record gives EXPECTED_REPRESENTATION_DIFF. The stock-shaped 1203 (33110) gives CONFIRMED_MISMATCH.

## 4. Finding for review: v1 cannot represent 752 of 9,159 quests

A full scan of the compiled database (all 9,159 quests, using `EffectiveExport.Record`):

| Reason | Count |
|---|---|
| Representable in v1 | 8,407 |
| Refused | 752 (8.2%) |
| — extraObjectives references to `monster` | 466 refs |
| — extraObjectives references to `object` | 335 refs |
| — reputation objectives (objectives[4]) | 181 quests |
| — the same creature id twice in objectives[1] | 9 |
| — the same object id twice in objectives[2] | 1 |

Real examples: 1036 and 1367 (reputation), 11142 (object 500007 twice), 11706 (creature 25768 twice, once with text), 1367 and 11706 (`monster` refs).

No real quest uses spells (objectives[6]) or extraObjectives item references. Those paths are tested synthetically only.

These quests are **refused, not trimmed or reinterpreted**: one such quest in a selection refuses the whole export. v1 is unchanged. Covering them needs a schema decision, which is **not made here**. Options for review:

1. `nq-m2-effective` v2 with `objectives.reputation`, `extraObjectiveRefs = { {type, id}, ... }` and duplicate entries allowed (or kept as `{id, count}`).
2. Keep v1 and treat refused quests as out of scope for M2.3 (listed as "not exportable" in reports).

`monster`/`object` extraObjectives refs may matter for the 151 NPC candidates, because they are often alternative kill or use targets. M1 currently only looks at whether extraObjectives exist. This should be decided before the M2.4 real runs.

## 5. Test map (Michael's list)

| Requirement | Test |
|---|---|
| 1203 stock 33110 vs effective 3853, distinguishable, M1 still confirms stock | effective_export, effective_schema, check_m2_export_values |
| Generated record contains 3853 | Integration (real harness) |
| Multiple creatures, gameobjects, source items, requiredSourceItems, killCredit, extraObjectives, ordering, empty lists | Integration (10 real quests) and compiled-shape unit tests |
| Spells, questLevel −1, unusual shapes | Snapshot unit tests (synthetic; no real spells exist) |
| Missing IDs, duplicate selection, invalid IDs, empty selection | Snapshot unit tests and integration |
| Invalid objective structures | 10 unusual-shape refusals and 5 real unrepresentable refusals |
| Wrong schema version, incomplete provenance | Effective schema tests (48 rejections) |
| Dirty checkout | Provenance (simulated) and integration (real temp clone) |
| Failed M0 | Integration: wrong level count means no file |
| Unsafe output paths, existing files, simulated write failures | Safe writer (36) and integration |
| Invalid or missing correction metadata | Provenance tests (revision, counts, modules, hashing, TOC) |
| Round trip | Serialise → parse → validate; `ToQuestieRecord` → `Record` gives an identical record |

Parsing and schema validity are not semantic correctness. The exact expected values in `tests/check_m2_export_values.lua` (taken from the compiled database) are what tie the export to real data.

## 6. Results (local, 2026-10-14)

| Suite | Result |
|---|---|
| M2.2 snapshot | 46 checks pass |
| M2.2 safe writer | 36 checks pass |
| M2.2 provenance | 22 checks pass |
| M2.2 export integration (real harness) | 25 checks pass |
| M2.2 effective schema | 71 checks pass |
| M2.1 schema / paths | 43+16 / 30 checks pass |
| M1 objective rules | 29 fixtures pass |
| M0 harness | 232 checks, 82,431 fields, 0 mismatches |
| M0 negatives | 5/5 rejected as intended |
| busted tools/validation | see §7 |
| luacheck, luac -p | clean |

## 7. CI

See the PR checks. Actions links are recorded in the PR #29 description and in the final report. The new M2.2 standalone and integration steps run in CI only once the proposed workflow is activated. Until then, the busted wrappers run the snapshot, writer, effective-schema and provenance tests inside the existing M1 workflow.

## 8. Known limitations

- 752 quests are not representable in v1 (§4).
- The export needs a clean checkout and Linux with GNU coreutils and git.
- Writer races are documented, not eliminated (safe-writer doc §2).
- A full M0 run takes 20–90 s; the integration test runs it about 7 times (around 2–3 minutes).
- No stock export path.
- `correctionCount` counts level corrections only.

## 9. Outstanding review requirements

1. Decide on §4 (v2 or out of scope) before M2.3 coverage work and M2.4 real runs.
2. Review and activate the proposed workflow (lead developer, CI-only PR).
3. Review the writer races against how private outputs will actually be stored.
4. Confirm environment-variable options are acceptable for the harness.

## 10. Follow-up after the Option A decision (14 October 2026)

Decision: Option A. v1 frozen; v1-unsupported quests out of scope for the initial pilot (temporary); v2 designed next; exporter fail-closed.

### 10.1 PR stack and dependency order

| Order | PR | Branch | Content |
|---|---|---|---|
| 0–4 | #24 → #26 → #27 → #28 → #29 | as §1 | M2.2 Steps 1–6 |
| 5 | #33 | feat/nq-validation-m2.2-coverage-preflight-2026-10-14 | Shared reason codes, coverage/preflight mode, coverage tests, CI coordination notes and activation diff |
| 6 | #34 | feat/nq-validation-m2.2-pilot-v2-design-2026-10-14 | Pilot script and results, v2 design and duplicate investigation, DRAFT v2 validator and fixtures, docs |

Each PR's base is the PR above it; no rebases, force-pushes or base changes. #30 and #31 (lead developer) were reviewed and not touched; this stack does not merge #31, because #31 changes `nquestie-objective-rules.yml` and the M2.2 code is not on its base. Merging both lines later is a plain merge with no expected conflicts beyond doc appends.

### 10.2 Per-stage handover (concise)

| Stage | Result | Where |
|---|---|---|
| CI review | #30/#31 run Step 1 schema, luac and GNU realpath checks only; 0 of the 129 export/writer/provenance/integration checks ran in GitHub | `NQ-VALIDATION-M2.2-CI-COORDINATION.md` |
| Coverage | 9,159 total; 8,407 representable; 752 unsupported; 0 unclassified; overlaps reconciled | `NQ-VALIDATION-M2.2-COVERAGE.md` |
| Pilot | 1203 and the 16-quest list pass all gates locally; nothing published | `NQ-VALIDATION-M2.2-PILOT.md` |
| v2 design | shape, R1–R10, versioning, M2.3 statuses, test plan, projection (752 of 752 representable; M1 SUPPORTED unchanged at 8,407) | `NQ-VALIDATION-M2-EFFECTIVE-V2-DESIGN.md` |

### 10.3 Tests added

| Test | Checks |
|---|---|
| `tests/test_nquestie_m2_coverage.lua` | 71 |
| `tests/test_nquestie_m2_coverage_integration.sh` (real DB) | 20 |
| `tests/test_nquestie_m2_effective_v2_draft.lua` (DRAFT) | 33 |

All existing M2 tests unchanged and passing (46 / 36 / 22 / 25); the exporter's refusal messages are unchanged, only reason codes were added.

### 10.4 CI evidence

All five existing workflows passed (push and pull_request) on both new PRs. They run M0, M1, overlay, revision guard and `ci.yml`; the new M2.2 checks are **not** executed in GitHub until the proposed workflow is activated (see the CI coordination doc).

| PR | Head | M0 validate-335 | M1 objective-rules | CI (lint, unit, DB) |
|---|---|---|---|---|
| #33 | 67188b641 | [38603007522](https://github.com/CosmicCuddle/N-Questie/actions/runs/38603007522) | [38603008052](https://github.com/CosmicCuddle/N-Questie/actions/runs/38603008052) | [38603007565](https://github.com/CosmicCuddle/N-Questie/actions/runs/38603007565) |
| #34 | 05645e9f0 | [38603941237](https://github.com/CosmicCuddle/N-Questie/actions/runs/38603941237) | [38603941295](https://github.com/CosmicCuddle/N-Questie/actions/runs/38603941295) | [38605235149](https://github.com/CosmicCuddle/N-Questie/actions/runs/38605235149) |

Local (box, head 05645e9f0): full M2 suite PASS (all standalone suites, busted, export integration 25, coverage integration 20); pilot 1203 and pilot list PASS.

### 10.5 Limitations

- Option A excludes 752 quests (8.2%) until v2.
- v1 records lists per kind, not cross-kind position; quest 10503 (`killCreditObjectiveFirst`) is v1-representable but its "killCredit shown first" fact is not in v1.
- The coverage tool counts compiled quests (9,159); the M0 log counts 9,158 `questData` records before compilation. The one-quest difference is unexplained (review item).
- The new GitHub checks only run once the proposed workflow is activated; until then busted wrappers report pending in `ci.yml`.
- The v2 validator is a draft prototype; the projection is not a measured v2 export.

### 10.6 Outstanding reviews and items

1. Activate the proposed workflow (CI-only PR from the activation diff) and confirm the six log lines.
2. Approve the v2 design and the M2.3 status model.
3. Data owner: review duplicate anomalies 64128, 12683, 11142.
4. **The lead developer's real M2.1 input still needs genuine Lua 5.1 validation (`cli/validate-m2-input.lua`) in a trusted Linux environment.**
5. Explain 9,158 vs 9,159.
6. Then, with approval: v2 exporter, then M2.3.

## 11. Second follow-up (14 October 2026): order, ID set, CI integration, final v2 design

### 11.1 PR stack and dependency order

| Order | PR | Branch | Content |
|---|---|---|---|
| … | #24 → #26 → #27 → #28 → #29 → #33 → #34 | as above | M2.2 Steps 1–6, coverage, pilot, v2 draft |
| 7 | #36 | feat/nq-validation-m2.2-order-killcredit-first-2026-10-14 | `KILLCREDIT_FIRST_REORDER` (exporter + coverage), order tests, measured coverage 8,401 / 758 |
| 8 | #37 | feat/nq-validation-m2.2-quest-id-set-2026-10-14 | 9,158 vs 9,159 explained (quest 2001), compiled ID set pinned |
| 9 | #38 | feat/nq-validation-m2.2-ci-integration-2026-10-14 | #37 + `--no-ff` merge of #35's head 811b2b796 (lead's active M2 workflow); proposed copy removed |
| 10 | this PR | feat/nq-validation-m2-v2-design-final-2026-10-14 | final v2 design, duplicate assessment, provenance pairing, split M1 statuses, draft validator (57 checks) |

#35 is the lead's PR and was not edited. Its workflow is canonical.

### 11.2 Per-stage handover

| Stage | Result | Where |
|---|---|---|
| Order (#36) | Questie maps quest-log line N to ObjectiveData[N]; 16 quests in `killCreditObjectiveFirst` all change order; v1 now refuses them. 6 newly unsupported: 10503, 12100, 12546, 12561, 13382, 13404. No other cross-type order loss. | coverage doc §6 |
| ID set (#37) | raw 9,086 → inherited corrections 9,158 (+72; 90 existing IDs reset and refilled, IDs kept) → N-Questie +2001 = 9,159 = compiled set. No removals. Pinned by count and sha256. | `NQ-VALIDATION-M2.2-QUEST-ID-SET.md` |
| CI (#38) | six workflows on one commit (see §11.3) | PR #38 |
| Design (this PR) | review points 1–6 addressed; normaliser artifact corrected (reputation value 0, objectiveIndex 0) | `NQ-VALIDATION-M2-EFFECTIVE-V2-DESIGN.md` |

### 11.3 CI evidence

CI_EVIDENCE_2

### 11.4 Outstanding

1. Lead: genuine Lua 5.1 validation of the real private M2.1 input (1203 first).
2. Approve the v2 design and the M2.3 two-axis status model.
3. In-game: 11142 line count; 64128 only if unhidden. 12683: M1 to treat line 1's ID as a location hint (review in M2.3).
4. Production v2 exporter and the M2.3 engine: separate approvals; not started.
