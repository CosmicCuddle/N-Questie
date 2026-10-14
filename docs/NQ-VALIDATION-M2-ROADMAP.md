# N-Questie Validation M2: Technical Roadmap

Status: M2.1 done (PR #21/#22). M2.2 Steps 1–6 in draft (PRs #24, #26–#29). M2.3 onwards not started
Date: 2026-10-14
Framework owner (code, tests, reporting tools, docs): validation workstream
Data owner (private exports, real comparisons, corrections): lead developer
Approval: every phase and step below needs Michael's approval before it starts

## 1. Ownership

| Area | Owner |
|---|---|
| Schemas, validators, parser, path rules | Validation workstream |
| Effective export (M2.2) and batch engine (M2.3) | Validation workstream |
| Synthetic fixtures, CI proposals, docs and handover | Validation workstream |
| Private acore_world exporter and its output | Lead developer |
| Real M2 runs, triage of real findings | Lead developer, with Michael |
| Correction modules, allow-list updates, revision bumps | Lead developer, through reviewed PRs |
| Merges, releases, in-game QA sign-off | Michael |

## 2. Fixed guarantees (must hold in every phase)

- M0: 28 reviewed corrections active, 232 checks, the 82,431-field round-trip with 0 mismatches, all 5 negative fixtures rejected.
- M1: the 25 rules unchanged in strength. Quest 1203 stays CONFIRMED_MISMATCH against stock Questie and EXPECTED_REPRESENTATION_DIFF against N-Questie.
- `nq-m2-input` v1 is frozen; `nq-m2-effective` v1 once accepted.
- Report-only: no tool changes Questie data, corrections, TOC, the revision system, SQL or SavedVariables.
- Private data stays outside the public checkout or under the gitignored `private/`. CI uses synthetic data only.
- Fail closed: any doubt means reject or NEEDS_MANUAL_REVIEW, never a confirmed result.

## 3. M2.2 Effective export

Goal: write `nq-m2-effective` v1 records for explicitly selected quest IDs, taken from the compiled 3.3.5a database after corrections. The export only runs after every M0 check has passed.

### Steps

- [x] **Step 1: Schema and validator** (PR #24, draft). `EffectiveSchema.lua`, 71 standalone checks, busted spec.
- [x] **Step 2: Pure snapshot function** (PR #27) (`tools/validation/EffectiveExport.lua`)
  - Input: a loaded QuestieDB and a list of quest IDs. Output: a snapshot table. No I/O.
  - Reads compiled records (questKeys 4, 5, 9, 10, 11, 21, 27) into the v1 record shape. It does not read the raw DB file.
  - A requested ID with no compiled record rejects the whole export.
- [x] **Step 3: Harness hook** (PR #28; options are environment variables because `arg[1]` is the faction) (`cli/validate-335.lua --export-effective PATH --quests FILE`)
  - Runs after all existing checks and only if they all pass. It must not change the existing check count (232).
  - Quest IDs come only from an explicit list (a file or the IDs in an `nq-m2-input` document). There is no "export everything" default.
  - Provenance comes from git (`rev-parse HEAD`, `HEAD^{tree}`, `status --porcelain` must be empty), the TOC (30300), `nQuestieDataRevision`, the correction module list and a sha256 over those files, and the M0 check count.
- [x] **Step 4: Safe writing** (PR #27; no-clobber via link(2)) (option C + D from the M2.2 design §6b)
  - The output folder resolves (via `realpath -e`) outside the checkout or under `private/`, is owned by the current user and has mode 0700 or stricter.
  - Write to a `mktemp` file in that folder, re-verify after writing, then rename atomically.
  - No overwrite without `--force`. File mode 0600.
  - Validate the written file with `EffectiveSchema.LoadFile` before reporting success; on failure, delete the temp file and exit non-zero.
- [x] **Step 5: Round-trip and negative tests** (PRs #27–#29)
  - A synthetic fake DB: 1203 exports 33110 without corrections and 3853 with them.
  - An M0 failure writes no file. A missing ID rejects. A dirty tree rejects.
  - The export passes `EffectiveSchema` and M1 `Compare` with expected classes.
  - The real harness on CI exports 1203 to a temp folder (public Questie data only) and asserts item 3853.
- [x] **Step 6: CI and docs** (PR #29; workflow proposed, not active)
  - Proposed workflow step under `docs/proposed-workflows/` (no `.github` edit without workflow scope).
  - Update the handover, ROADMAP and the M2.2 design doc.

### Acceptance criteria

| Criterion | Evidence |
|---|---|
| M0 still 232 checks, 82,431 fields, 0 mismatches | CI log |
| Export refused if any M0 check fails | Negative test |
| Only selected IDs exported | Test with 3 IDs from a list |
| 1203 effective = 3853, stock = 33110 | Fixture and real-harness test |
| No overwrite; temp + rename; 0600; folder checks | Write-safety tests incl. symlink cases |
| Output validates as `nq-m2-effective` v1 | Round-trip test |

### Open item from Steps 2–6: decided (Option A)

> Historical snapshot (before the #36 kill-credit order check). Current measured figures: 8,401 representable, 758 unsupported of 9,159 (`NQ-VALIDATION-M2.2-COVERAGE.md` §3).

v1 cannot represent 752 of 9,159 quests. **Decision (Michael, 14 October 2026): Option A.** v1 stays frozen; those quests are out of scope for the initial pilot (temporary); v2 is designed next. The exporter stays fail-closed: an unsupported requested ID fails the export, writes nothing and prints every reason. Never trim, dedupe, drop reputation or reinterpret extras; no false CONFIRMED.

### M2.2 follow-up (Option A)

- [x] Read-only coverage/preflight over all compiled quests, sharing the exporter's reason codes (`docs/NQ-VALIDATION-M2.2-COVERAGE.md`)
- [x] Export refusals carry reason codes per quest
- [x] CI review of #30/#31 and an exact activation diff (`docs/NQ-VALIDATION-M2.2-CI-COORDINATION.md`)
- [x] Reproducible 1203 pilot and a 16-quest v1 pilot list (`docs/NQ-VALIDATION-M2.2-PILOT.md`)
- [x] v2 design, duplicate investigation, draft validator and fixtures (`docs/NQ-VALIDATION-M2-EFFECTIVE-V2-DESIGN.md`)
- [x] Activate the M2 workflow (lead's #35; integrated in #38)
- [x] killCreditObjectiveFirst order refusal; measured coverage 8,401 / 758 (#36)
- [x] 9,158 vs 9,159 explained and the compiled ID set pinned (#37)
- [x] Final v2 design: display scope, provenance pairing, split M1 statuses, duplicate assessment
- [ ] Approve v2 design; then a v2 exporter (separate approval)

## 4. M2.3 Report-only batch comparison engine (DESIGN ONLY)

Status: design only. Nothing in this section is implemented; examples and module names are proposals. Implementation needs separate maintainer authorisation. Final model: `docs/NQ-VALIDATION-M2-EFFECTIVE-V2-DESIGN.md` §9-§10.

Goal: compare one private server file (`nq-m2-input` v1) with one effective Questie export (`nq-m2-effective` v1 or v2) and its paired coverage manifest, quest by quest, using the M1 rules unchanged, and write a private report plus a separately reviewed aggregate.

### Inputs (three, all required)

| Input | Validation | Provenance |
|---|---|---|
| Server file | full `InputSchema.Validate` (every provenance field and record) | own: exporter, version, label, `sourceFingerprint` (sha256), time, selection, questCount. No git commit; never compared with one. |
| Effective export | version dispatch: v1 → frozen v1 validator, v2 → v2 validator, other → rejected | git commit, tree, revision, correction fingerprint and modules, M0 count |
| Coverage manifest | its own schema checks; reconciled aggregate | must pair with the effective export: same commit, tree, revision, correction count, fingerprint, modules, TOC, flavour, harness and version; both clean |

### Flow

1. Validate the three inputs independently. Any failure rejects the **whole batch**: no report and no partial output.
2. Check pairing between the effective export and the manifest. Any difference rejects the batch.
3. Membership consistency: every effective-export quest is REPRESENTABLE in the manifest, and no quest is both exported and UNSUPPORTED. Any contradiction rejects the batch.
4. For each server-selected quest, assign exactly **one export status**: `ABSENT_FROM_EFFECTIVE_DB` (not in the full manifest), `UNSUPPORTED_BY_SCHEMA_VERSION` or `EXPORTED`. A manifest-REPRESENTABLE quest missing from the selected export rejects the batch (selection mismatch). `REJECTED_MALFORMED_INPUT` exists only as a fixed stderr code, never in a report or file.
5. For `EXPORTED` quests only, assign **at most one comparison outcome**: `M1_UNSUPPORTED_BY_RULES`, `NEEDS_MANUAL_REVIEW`, `EXPECTED_REPRESENTATION_DIFF`, `CONFIRMED_MATCH` or `CONFIRMED_MISMATCH`. Records with v2 `m1Status = UNSUPPORTED_BY_RULES` get `M1_UNSUPPORTED_BY_RULES` and are never passed to M1 for confirmation. Unknown IP, conditions, KillCredit completeness or scripts never confirm.
6. Inputs are deep-compared before and after; any change aborts with no report.
7. Write the private report and aggregate only through SafeWrite to private paths. If anything fails, nothing is written.

### Reporting

Every selected ID appears exactly once in the private report, with its export status, its reason codes (from the manifest) when unsupported, and its comparison outcome when exported. Nothing disappears silently. The aggregate holds counts per status, outcome and reason only.

### Acceptance (when implemented)

| Criterion | Evidence |
|---|---|
| Any malformed or inconsistent input: no files at all | negative matrix, output folder stays empty |
| One export status per selected ID; at most one outcome | property test over fixtures |
| M1 results identical to calling M1 directly | comparison test |
| 1203 effective gives EXPECTED_REPRESENTATION_DIFF, never CONFIRMED | test |
| Aggregate contains no IDs, names or fingerprints | grep test |

## 5. M2.4 / M2.5 Real-data review process

### Who does what

| Step | Owner | Output |
|---|---|---|
| 1. Export selected server rows (1203 first, then a small edge-case group) | Lead developer | Private `nq-m2-input` file |
| 2. Effective export from a clean checkout | Lead developer (runs our tool) | Private `nq-m2-effective` file |
| 3. Batch run | Lead developer | Private report + summary |
| 4. Share the aggregate summary only | Lead developer → PR comment, after review | Counts per class/rule |
| 5. Triage | Lead developer + Michael; validation workstream answers rule questions | Triage list (private) |
| 6. Corrections | Lead developer | Correction-module draft PR |
| 7. Framework fixes for false positives/negatives | Validation workstream | Rule or test PR with a synthetic fixture |

### Triage order

1. CONFIRMED_MISMATCH: check the evidence by hand (server row, Questie record, in-game behaviour if possible). CONFIRMED is **not** directly actionable.
2. NEEDS_MANUAL_REVIEW sets (R-ITEM-SET, R-NPC-SET, R-NPC-NOCREDIT): collect the missing evidence (KillCredit rows, scripts, conditions) and re-run.
3. UNSUPPORTED (C-COND, C-IP, C-SCRIPT, C-UNKNOWN): out of offline scope; note them and leave as-is unless there's in-game evidence.
4. EXPECTED_REPRESENTATION_DIFF: no action.

### Evidence needed before a correction

- Server row values (privately), the effective Questie record, and the rule ids.
- For creatures: KillCredit rows for both sides, and a statement on scripts.
- For items: StartItem/ItemDrop relation checked.
- Where possible, an in-game check on the test realm.

### From finding to release

1. The lead developer opens a draft correction-module PR (one quest group per PR).
2. The M0 allow-list and expected count are updated in the same PR, with a negative fixture for the new correction.
3. `nQuestieDataRevision` is bumped (the revision guard enforces it).
4. All CI passes (M0, M1, M2 suites).
5. In-game verification on the test realm, with the addon and SavedVariables backed up first.
6. Michael approves the merge and release.

### What may be published

| Allowed in public GitHub | Not allowed |
|---|---|
| Aggregate counts per class and rule | Per-quest server rows, IDs from private findings |
| Synthetic fixtures | Exporter output, SQL, archive hashes tied to private files |
| Correction PRs for reviewed quests (public Questie data plus a reviewed value) | Full private reports |

## 6. Risks

| Risk | Mitigation |
|---|---|
| Real data has shapes the schemas reject (e.g. duplicate objective IDs) | Report it, and change the schema only through a new version with Michael's approval |
| A write race in M2.2/M2.3 output | Temp + rename in a user-owned 0700 folder; residual window documented |
| Over-trusting CONFIRMED | Process rule: human evidence review before any correction |
| CI drift (proposed workflow steps not activated) | Busted covers specs today; the proposed diffs are listed in the handover |
| Linux-only path resolver | Accepted; documented |
| Pilot scope hides 8.2% of quests | Option A is temporary; coverage report lists every excluded quest with reasons |
| v1 has no cross-kind position (quest 10503 shows killCredit first) | Recorded in v2 (`killCreditFirst`); review item for M2.3 |
| Lead developer's real M2.1 input not yet validated under genuine Lua 5.1 | Run `cli/validate-m2-input.lua` in a trusted Linux environment before M2.3 |
| The M0 harness takes about 90 s; export adds time | Export only selected IDs |

## 7. Open questions

1. Who applies the proposed workflow diffs (token scope)?
2. Should "in effective but not in the server selection" be reported at all, or ignored?
3. Reputation objectives (slot 4): designed for v2 (explicit kind; value may be absent), pending approval.
4. Where do private reports live by default: a fixed folder outside the checkout, or `private/`?
5. How long are private reports kept, and are they ever shared outside the lead developer's machine?
6. What is the size of the first real batch after 1203 (suggested: 10–20 edge cases)?
