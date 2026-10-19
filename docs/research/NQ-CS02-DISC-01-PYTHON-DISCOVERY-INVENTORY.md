# NQ-CS02-DISC-01 Python discovery-readiness inventory

Status of this note: research only. It records what was read at commit `3b5e3a90c2194b7d6b214e7d280b0a8248d0d5aa` and what was executed on 2026-10-19. It does not change a workflow, a test, or addon code.

Claim labels used below:

- **VERIFIED** — a command in this session produced the result.
- **SOURCE ONLY** — read from the tree at `3b5e3a90`; not a separate execution.
- **UNKNOWN** — not established.
- **NOT TESTED** — not run.

## 1. Baseline

| Item | Value | Label |
| --- | --- | --- |
| Commit | `3b5e3a90c2194b7d6b214e7d280b0a8248d0d5aa` | VERIFIED (`git rev-parse HEAD` before and after the suite) |
| Remote branch at the same SHA | `origin/integration/nq-reviewed-tests-no-upload-candidate-2026-10-19` | VERIFIED (`git fetch origin integration/nq-reviewed-tests-no-upload-candidate-2026-10-19` then `git rev-parse`) |
| Python | Python 3.12.3 | VERIFIED (`python3 --version`) |
| Lua | Lua 5.1.5, `/usr/bin/lua5.1` and `/usr/bin/luac5.1` | VERIFIED. `lua5.1` was absent at session start. Installed with `sudo apt-get install -y lua5.1` (package `lua5.1 5.1.5-9build2`). `lua5.1 -v` then printed `Lua 5.1.5`. |
| Working tree before the suite | `git status --porcelain` empty | VERIFIED |

`tools/test_world_quest_sql_quoting.py` is absent from this commit. VERIFIED: the path is not in the worktree, and `git rev-parse HEAD:tools/test_world_quest_sql_quoting.py` exited with `fatal: Needed a single revision`. Open PR #136 (`gh pr view 136 --repo CosmicCuddle/N-Questie`) lists that path as its only file, on head `239c7ea0f54821e9afb4e2c73fc90c44abdbab8a` (`cs02/DEV-065-sql-quoting-delimiters-guarded`), base `test/nq-invalid-custom-quest-id-keys-2026-10-19`. That file was not checked out and was **NOT TESTED**.

The repo contains exactly ten `test_*.py` files, all under `tools/`. VERIFIED by listing `tools/test_*.py` and by a repo-wide search.

## 2. Commands run

All suite commands ran on 2026-10-19 from 19:05:57Z to 19:06:29Z. Every process exit code was 0. VERIFIED.

Standalone, cwd `/workspace`, in filename order from `find tools -maxdepth 1 -name 'test_*.py' | sort` under `LC_ALL=en_US.UTF-8`:

```bash
python3 tools/test_audit_world_quest_levels_columns.py
python3 tools/test_audit_world_quest_levels_counts.py
python3 tools/test_audit_world_quest_levels.py
python3 tools/test_export_world_quests.py
python3 tools/test_generate_custom_quests_json_roots.py
python3 tools/test_generate_custom_quests_numeric_types.py
python3 tools/test_generate_custom_quests.py
python3 tools/test_nquestie_335_manifest_preflight.py
python3 tools/test_reviewed_classic_chain_sources.py
python3 tools/test_reviewed_early_quest_sources.py
```

Discovery, twice:

```bash
# cwd /workspace
python3 -m unittest discover -s tools -p 'test_*.py' -v

# cwd /tmp ; absolute start directory
python3 -m unittest discover -s /workspace/tools -p 'test_*.py' -v
```

After the suite, each of the ten modules was imported once with `builtins.open` wrapped, `sys.path` starting with `/workspace/tools`. That import pass opened no paths. VERIFIED. Bytecode under `tools/__pycache__/` already existed from the suite, so this pass did not re-read `.py` sources. It shows import did not open data files.

`git status --porcelain` and the tracked-file digest in section 7 were taken immediately before the first standalone command and immediately after the second discovery, before this document existed.

## 3. Summary

| Mode | Tests | Result | Label |
| --- | --- | --- | --- |
| Ten standalone files, summed | 108 | each file exit 0; one skip in the counts file | VERIFIED |
| Discovery, cwd `/workspace` | 108 in 10.315s | `OK (skipped=1)`, exit 0 | VERIFIED |
| Discovery, cwd `/tmp` | 108 in 10.562s | `OK (skipped=1)`, exit 0 | VERIFIED |

The single skip is `test_audit_world_quest_levels_counts.AuditCountAndOrderTests.test_repeated_correction_id_policy_is_not_stated`. Both discovery logs printed:

```text
skipped 'UNKNOWN policy: repeated correction quest IDs are not rejected; last literal assignment is what the code does today, but that policy is not stated (DEV-063 overlap)'
```

SOURCE ONLY for the call site: `tools/test_audit_world_quest_levels_counts.py` lines 297–308. The method calls `self.skipTest(...)` with that string. There is no `skipUnless` around it. Reaching the method is enough to skip.

`tools/test_generate_custom_quests.py` lines 105–106 decorate `test_generated_lua_loads_through_real_335_overlay` with `@unittest.skipUnless(shutil.which("lua5.1"), "requires installed Lua 5.1")`. With `/usr/bin/lua5.1` on `PATH`, that test ran and passed in standalone and in both discovery runs (verbose line ends in `ok`). VERIFIED. A host without `lua5.1` would add a second skip. NOT TESTED on a machine where `lua5.1` is missing.

## 4. Per-file inventory

Blob SHAs are `git rev-parse HEAD:<path>` at `3b5e3a90`. VERIFIED.

| File | Git blob | Standalone | Discovery | Overlay step |
| --- | --- | --- | --- | --- |
| `tools/test_audit_world_quest_levels.py` | `cf743a0979b32314fb9594c805919cde929cbb84` | 16 in 0.172s, `OK` | 16 | yes, lines 47–50 |
| `tools/test_audit_world_quest_levels_columns.py` | `8edf450b442f4d2b636b86b72c0b1a302571ed54` | 16 in 0.015s, `OK` | 16 | no |
| `tools/test_audit_world_quest_levels_counts.py` | `aed7bb3717ab619c8e26f9797072014ea57c9a1e` | 6 in 0.008s, `OK (skipped=1)` | 6 | no |
| `tools/test_export_world_quests.py` | `d779a166d490507485682fb46f1eb966cd73fdb2` | 14 in 0.012s, `OK` | 14 | yes, lines 39–40 |
| `tools/test_generate_custom_quests.py` | `8e7c816c54ef45a8a5b48d1610fc1fbc3f14eadf` | 13 in 0.015s, `OK` | 13 | yes, lines 41–46 |
| `tools/test_generate_custom_quests_json_roots.py` | `3aec8a5c7887376b0b05acde5049488d36546fd5` | 4 in 1.377s, `OK` | 4 | no |
| `tools/test_generate_custom_quests_numeric_types.py` | `dbd4f571a614a007c7f912e6c1c4de1226c2f420` | 9 in 8.358s, `OK` | 9 | no |
| `tools/test_nquestie_335_manifest_preflight.py` | `50daa446847e6b5693e19936de08272f19bc4d0e` | 24 in 0.117s, `OK` | 24 | yes, lines 55–56 |
| `tools/test_reviewed_classic_chain_sources.py` | `7bca03d521d868b347ead8a2b5c632b13965e0a5` | 3 in 0.167s, `OK` | 3 | yes, lines 53–54 |
| `tools/test_reviewed_early_quest_sources.py` | `2df2d07f76ec3c0136b76858efbfcc2b9fcd7c4a` | 3 in 0.166s, `OK` | 3 | yes, lines 51–52 |

Standalone counts and discovery counts match for every file. VERIFIED. `Ran N tests` counts `TestCase` methods. Methods that use `subTest` still count as one test. SOURCE ONLY that several methods call `subTest`; the pin in section 6 is the 108 method ids, matching `Ran 108`.

### 4.1 `tools/test_audit_world_quest_levels.py`

- Imports, stdlib (lines 3–7): `json`, `tempfile`, `unittest`, `zipfile`, `pathlib.Path`.
- Imports, local (line 9): `audit_world_quest_levels` as `audit`. That module imports `export_world_quests` (`tools/audit_world_quest_levels.py` line 20). SOURCE ONLY.
- Import-time work: string constants `RAW` and `CORRECTION` (lines 12–36), then functions and `QuestLevelAuditTests`. No file, subprocess, or network call at import. SOURCE ONLY. The import probe opened nothing. VERIFIED.
- `if __name__ == "__main__"` (lines 284–285) calls `unittest.main()` only. SOURCE ONLY.
- Subprocess: none. SOURCE ONLY.
- Network: none. SOURCE ONLY (no network API in this file or in `audit_world_quest_levels.py` / `export_world_quests.py`).
- Environment variables: none read. SOURCE ONLY (no `os.environ` or `getenv` in the ten tests or the three local modules).
- Paths: `test_real_repository_jarl_record_and_literal_layers` (lines 51–68) reads public repo files through `Path(__file__).resolve().parents[1] / audit.QUESTIE_RAW` and each `audit.LEVEL_FIXES` entry. Those constants are relative (`tools/audit_world_quest_levels.py` lines 22–27): `Database/Wotlk/wotlkQuestDB.lua` and the three `Database/Corrections/*QuestFixes.lua` files. Writes in other methods use `tempfile.TemporaryDirectory` (lines 93, 139, 155, 199, 226, 258).
- Skip: none.

### 4.2 `tools/test_audit_world_quest_levels_columns.py`

- Imports, stdlib (lines 9–13): `json`, `tempfile`, `unittest`, `zipfile`, `pathlib.Path`.
- Imports, local: `audit_world_quest_levels` (line 15), `parse_row` from `export_world_quests` (line 16).
- Import-time work: constants and helpers only. SOURCE ONLY. Import probe: no opens. VERIFIED.
- `if __name__ == "__main__"` (lines 348–349) calls `unittest.main()` only. SOURCE ONLY.
- Subprocess: none. Network: none. Environment variables: none. SOURCE ONLY.
- Writes: `write_sql` (lines 53–56) and the CLI test (lines 321–345) write only under `tempfile.TemporaryDirectory`.
- Skip: none.
- The module docstring does not mention CI. Absence from the overlay workflow is recorded in section 5. SOURCE ONLY.

### 4.3 `tools/test_audit_world_quest_levels_counts.py`

- Imports, stdlib (lines 11–16): `io`, `json`, `tempfile`, `unittest`, `contextlib.redirect_stdout`, `pathlib.Path`.
- Imports, local (line 18): `audit_world_quest_levels`.
- Import-time work: constants and helpers only. SOURCE ONLY. Import probe: no opens. VERIFIED.
- `if __name__ == "__main__"` (lines 311–312) calls `unittest.main()` only. SOURCE ONLY.
- Subprocess: none. Network: none. Environment variables: none. SOURCE ONLY.
- Writes: SQL and JSON under `tempfile.TemporaryDirectory`. `setUp` (lines 136–137) and `test_cli_json_bytes_identical_and_outside_repo` (lines 235–253) assert those paths are outside the repo via `audit.inside`.
- Skip: one, unconditional, lines 297–308, reason quoted in section 3. VERIFIED it was the only skip in the full discovery output.
- Docstring lines 7–9 say this file is not run in CI and that the overlay workflow executes `tools/test_audit_world_quest_levels.py` only. SOURCE ONLY, consistent with section 5.

### 4.4 `tools/test_export_world_quests.py`

- Imports, stdlib (lines 2–5): `tempfile`, `unittest`, `zipfile`, `pathlib.Path`.
- Imports, local (line 7): `export_world_quests` as `exporter`.
- Import-time work: helpers and column tuples only. SOURCE ONLY. Import probe: no opens. VERIFIED.
- `if __name__ == "__main__"` (lines 338–339) calls `unittest.main()` only. SOURCE ONLY.
- Subprocess: none. Network: none. Environment variables: none. SOURCE ONLY.
- Writes: `setUp` (lines 93–97) creates `tempfile.TemporaryDirectory` and writes `world.sql` there. Other writes use that same directory.
- Skip: none. `test_negative_quest_id_is_skipped_and_missing_id_is_refused` and `test_space_or_tab_after_opening_paren_skips_quest_row` describe parser behaviour. Both ran (`... ok`). VERIFIED. They are not `unittest` skips.

### 4.5 `tools/test_generate_custom_quests.py`

- Imports, stdlib (lines 2–9): `copy`, `json`, `shutil`, `subprocess`, `tempfile`, `unittest`, `pathlib.Path`.
- Imports, local (line 11): `generate_custom_quests` as `generator`.
- Import-time work: imports and helpers only. `subprocess` is imported; `subprocess.run` is not called at import. SOURCE ONLY. Import probe: no opens. VERIFIED.
- `if __name__ == "__main__"` (lines 403–404) calls `unittest.main()` only. SOURCE ONLY.
- Subprocess: `test_generated_lua_loads_through_real_335_overlay` (lines 212–217) runs `[shutil.which("lua5.1"), harness, generated, Compat/NQuestieCustomQuestLoader.lua]` with `cwd` set to the repo root from `Path(__file__).resolve().parents[1]`, `timeout=15`. VERIFIED the test passed while `lua5.1` was `/usr/bin/lua5.1`.
- Network: none. Environment variables: none read. The child inherits the parent environment because `subprocess.run` is called without `env=`. SOURCE ONLY.
- Writes: Lua harness files and CLI outputs under `tempfile.TemporaryDirectory` (lines 205, 223, 258, 315, 339, 375).
- Skip: the Lua test is conditional (lines 105–106) and did not skip in this session. VERIFIED.

### 4.6 `tools/test_generate_custom_quests_json_roots.py`

- Imports, stdlib (lines 11–16): `json`, `subprocess`, `sys`, `tempfile`, `unittest`, `pathlib.Path`.
- Imports, local (line 18): `generate_custom_quests`.
- Import-time work: path constants `GENERATOR` and `REPO_ROOT` (lines 28–29) and helpers. `invalid_payloads()` is not called at import. SOURCE ONLY. Import probe: no opens. VERIFIED.
- `if __name__ == "__main__"` (lines 238–239) calls `unittest.main()` only. SOURCE ONLY.
- Subprocess, test time:
  - `repository_status` (lines 81–92) runs `git status --porcelain` with `cwd` = repo root, `timeout=30`.
  - `run_generator` (lines 95–114) runs `sys.executable` on `tools/generate_custom_quests.py` with `cwd` = the temp review directory, `timeout=30`.
- Network: none. Environment variables: none read. SOURCE ONLY.
- Writes: review JSON and `curated.lua` under `tempfile.TemporaryDirectory` only.
- Skip: none.
- `setUp` / `tearDown` (lines 123–127) require `git status --porcelain` to be unchanged across each test. The four tests passed, so that check held. VERIFIED.

### 4.7 `tools/test_generate_custom_quests_numeric_types.py`

- Imports, stdlib (lines 12–17): `json`, `subprocess`, `sys`, `tempfile`, `unittest`, `pathlib.Path`.
- Imports, local (line 19): `generate_custom_quests`.
- Import-time work: path constant `SCRIPT` (line 22) and case tables. SOURCE ONLY. Import probe: no opens. VERIFIED.
- `if __name__ == "__main__"` (lines 468–469) calls `unittest.main()` only. SOURCE ONLY.
- Subprocess: `run_cli` (lines 140–147) runs `sys.executable` on `tools/generate_custom_quests.py` with `cwd` = the temp directory, `timeout=15`.
- Network: none. Environment variables: none read. SOURCE ONLY.
- Writes: review JSON and Lua under `tempfile.TemporaryDirectory`. `run_cli` (lines 138–139) asserts both paths stay inside that directory.
- Skip: none.
- Docstring lines 3–4 say the file is not run in CI. SOURCE ONLY, consistent with section 5.

### 4.8 `tools/test_nquestie_335_manifest_preflight.py`

- Imports, stdlib (lines 6–12): `os`, `re`, `tempfile`, `unittest`, `pathlib.Path`, `unittest.mock`.
- Local `tools/*.py` modules: none. The checks live in this file (`_checked_path`, `check_manifest`).
- Import-time work: regex compilation (lines 15–28) and function definitions. SOURCE ONLY. Import probe: no opens. VERIFIED.
- `if __name__ == "__main__"` (lines 582–583) calls `unittest.main()` only. SOURCE ONLY.
- Subprocess: none. Network: none. Environment variables: none read. `os` is used for `os.symlink` inside tests. SOURCE ONLY.
- Writes: `synthetic_package` (lines 165–186) and later tests write under `tempfile.TemporaryDirectory`. Symlinks (lines 346–364) point at files in that same temp directory.
- Reads of the real tree: `test_real_public_335_source_references_without_writes` (lines 567–579) calls `check_manifest` on `Path(__file__).resolve().parents[1]` with `require_staged_name=False`, then compares `Questie-335.toc` bytes. The test passed. VERIFIED. Expected counts in source are `toc_paths` 143, `xml_paths` 149, `total_references` 292, `xml_documents` 21 (lines 573–578). SOURCE ONLY for those literals; the assertion passed, so the live tree matched them. VERIFIED.
- String fixtures that name absolute or foreign paths, and that the code refuses before opening them (SOURCE ONLY for the refusal path in `_checked_path`, lines 31–34; VERIFIED the tests passed):
  - line 282: `"/etc/passwd"`
  - line 554: `file:///etc/passwd` inside an XML entity string
  - lines 314–315: `C:\untrusted\module.lua` and `\\server\share\module.lua`
- Skip: none.

### 4.9 `tools/test_reviewed_classic_chain_sources.py`

- Imports, stdlib (lines 4–5): `unittest`, `pathlib.Path`.
- Imports, local (lines 6–11): `QUESTIE_RAW`, `LEVEL_FIXES`, `parse_questie_raw`, `parse_static_level_fixes` from `audit_world_quest_levels`.
- Import-time work: `ROOT = Path(__file__).resolve().parents[1]` (line 13) and ID sets. The public Lua files are read in `setUpClass` (lines 20–25), not at import. SOURCE ONLY. Import probe: no opens. VERIFIED.
- `if __name__ == "__main__"` (lines 61–62) calls `unittest.main()` only. SOURCE ONLY.
- Subprocess: none. Network: none. Environment variables: none. Writes: none. Skip: none. SOURCE ONLY.
- `setUpClass` raises `AssertionError` if `parse_questie_raw` reports unparsed rows. The tests passed, so that branch was not taken. VERIFIED.

### 4.10 `tools/test_reviewed_early_quest_sources.py`

- Imports, stdlib (lines 4–5): `unittest`, `pathlib.Path`.
- Imports, local (lines 7–13): the same four names from `audit_world_quest_levels`.
- Import-time work: `ROOT` (line 15) and `BASELINE` (lines 19–24). File reads are in `setUpClass` (lines 28–32). SOURCE ONLY. Import probe: no opens. VERIFIED.
- `if __name__ == "__main__"` (lines 59–60) calls `unittest.main()` only. SOURCE ONLY.
- Subprocess: none. Network: none. Environment variables: none. Writes: none. Skip: none. SOURCE ONLY.
- Same unparsed-row `AssertionError` guard (lines 32–33). Tests passed. VERIFIED.

### 4.11 Local modules loaded because tests import them

Discovery does not treat these as tests. They load because the test modules import them. Each guards `main()` with `if __name__ == "__main__"`:

- `tools/export_world_quests.py` lines 151–156
- `tools/generate_custom_quests.py` lines 186–191
- `tools/audit_world_quest_levels.py` lines 267–272

Import of those modules compiles regexes and sets path constants. It does not parse a database or write a report. SOURCE ONLY. Docstrings mention example paths such as `/private/acore_world.zip` (`tools/audit_world_quest_levels.py` lines 9–10, `tools/export_world_quests.py` line 3). Those strings are not opened on import. SOURCE ONLY.

## 5. What `nquestie-overlay.yml` runs

File: `.github/workflows/nquestie-overlay.yml` at `3b5e3a90`. Job `verify-custom-quest-overlay`. SOURCE ONLY. This inventory did not execute GitHub Actions.

Explicit `python3 tools/test_*.py` steps:

| Step name | Lines | Command |
| --- | --- | --- |
| Test selected quest SQL export parser | 39–40 | `python3 tools/test_export_world_quests.py` |
| Test reviewed JSON to Lua generation (offline, fail closed) | 41–46 | `command -v lua5.1` then `python3 tools/test_generate_custom_quests.py` |
| Test private existing-quest level audit (synthetic data only) | 47–50 | `python3 -m py_compile tools/audit_world_quest_levels.py` then `python3 tools/test_audit_world_quest_levels.py` |
| Guard approved early quest IDs against changed public Questie source | 51–52 | `python3 tools/test_reviewed_early_quest_sources.py` |
| Verify real public Questie baselines for the two Classic chains | 53–54 | `python3 tools/test_reviewed_classic_chain_sources.py` |
| Test 3.3.5a manifest preflight (synthetic, no package or upload) | 55–56 | `python3 tools/test_nquestie_335_manifest_preflight.py` |

Lua 5.1 is installed earlier in the same job (step `Install Lua 5.1`, lines 16–19).

These four `tools/test_*.py` files are not named by that workflow:

- `tools/test_audit_world_quest_levels_columns.py`
- `tools/test_audit_world_quest_levels_counts.py`
- `tools/test_generate_custom_quests_json_roots.py`
- `tools/test_generate_custom_quests_numeric_types.py`

A search of every file under `.github/workflows/` (`ci.yml`, `nquestie-m2-effective-export.yml`, `nquestie-objective-rules.yml`, `nquestie-overlay.yml`, `nquestie-revision-guard.yml`, `nquestie-validate-335.yml`) found `python3 tools/test_` only in `nquestie-overlay.yml`. SOURCE ONLY. No claim is made about CI systems outside this repo.

`Assemble PR-only WoW 3.3.5a addon package` (lines 67–90) has `if: ${{ false }}` at line 71. `Upload temporary N-Questie PR test build` (lines 91–101) has `if: ${{ false }}` at line 95. SOURCE ONLY.

## 6. Pinned discovery inventory

Future CI should compare discovered test ids to this list. A bare `>= 108` floor is the wrong check: it would still pass if a test were renamed, dropped, or replaced.

Both discovery runs produced the same 108 ids, in this order. VERIFIED. Python 3.12 verbose form is `test_method (module.Class.test_method)`. The id below is the `module.Class.test_method` portion. Order follows discovery from `-s tools`: filenames in code-point order (`test_audit_world_quest_levels.py` before `test_audit_world_quest_levels_columns.py`), then method names sorted within each class.

The only raw-log differences between the two runs were `Ran 108 tests in 10.315s` versus `10.562s`, and the tempfile path printed by `audit.main` (`/tmp/tmp_rkn9vjj/private/level-review.json` versus `/tmp/tmpk6n41g3e/private/level-review.json`). VERIFIED (`diff` of the two verbose logs).

1. `test_audit_world_quest_levels.QuestLevelAuditTests.test_cli_incomplete_questie_source_preserves_private_report`
2. `test_audit_world_quest_levels.QuestLevelAuditTests.test_cli_nonnumeric_questie_level_fails_closed_before_output`
3. `test_audit_world_quest_levels.QuestLevelAuditTests.test_commas_and_escapes_in_lua`
4. `test_audit_world_quest_levels.QuestLevelAuditTests.test_duplicate_world_quest_rejected_for_sql_and_zip`
5. `test_audit_world_quest_levels.QuestLevelAuditTests.test_dynamic_fix_and_missing_questie_are_distinct`
6. `test_audit_world_quest_levels.QuestLevelAuditTests.test_full_cli_synthetic_audit`
7. `test_audit_world_quest_levels.QuestLevelAuditTests.test_mismatch_detection_with_literal_layer`
8. `test_audit_world_quest_levels.QuestLevelAuditTests.test_missing_fix_table_rejected`
9. `test_audit_world_quest_levels.QuestLevelAuditTests.test_missing_quest_rejected`
10. `test_audit_world_quest_levels.QuestLevelAuditTests.test_negative_dynamic_quest_requires_review`
11. `test_audit_world_quest_levels.QuestLevelAuditTests.test_parse_generated_lua_nested_quests`
12. `test_audit_world_quest_levels.QuestLevelAuditTests.test_parse_static_layer_and_dynamic_guard`
13. `test_audit_world_quest_levels.QuestLevelAuditTests.test_private_server_sql_and_zip`
14. `test_audit_world_quest_levels.QuestLevelAuditTests.test_real_repository_jarl_record_and_literal_layers`
15. `test_audit_world_quest_levels.QuestLevelAuditTests.test_refuse_private_output_inside_repo`
16. `test_audit_world_quest_levels.QuestLevelAuditTests.test_requested_match_is_included`
17. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_cli_column_refusal_does_not_write_a_report`
18. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_duplicate_minlevel_header_keeps_the_later_value`
19. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_explicit_zero_levels_are_kept`
20. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_extra_header_without_matching_value_is_refused`
21. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_extra_unknown_column_is_ignored`
22. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_later_missing_column_does_not_return_earlier_rows`
23. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_later_unrecognized_insert_is_not_merged`
24. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_missing_or_misspelled_level_columns_are_refused`
25. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_named_columns_parse_in_any_order`
26. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_non_numeric_levels_are_not_coerced`
27. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_parse_row_maps_by_header_name_and_rejects_width`
28. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_scrambled_header_with_extra_column_keeps_named_levels`
29. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_tuple_width_must_match_header`
30. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_unrecognized_insert_header_is_refused`
31. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_whitespace_around_header_names_still_matches`
32. `test_audit_world_quest_levels_columns.QuestLevelColumnTests.test_zip_follows_the_same_column_rules`
33. `test_audit_world_quest_levels_counts.AuditCountAndOrderTests.test_cli_json_bytes_identical_and_outside_repo`
34. `test_audit_world_quest_levels_counts.AuditCountAndOrderTests.test_duplicate_questie_id_rejected`
35. `test_audit_world_quest_levels_counts.AuditCountAndOrderTests.test_duplicate_world_quest_id_rejected`
36. `test_audit_world_quest_levels_counts.AuditCountAndOrderTests.test_known_dataset_counts_and_exact_order`
37. `test_audit_world_quest_levels_counts.AuditCountAndOrderTests.test_order_stable_across_runs_and_input_permutations`
38. `test_audit_world_quest_levels_counts.AuditCountAndOrderTests.test_repeated_correction_id_policy_is_not_stated`
39. `test_export_world_quests.ExportTests.test_empty_integer_fields_are_refused`
40. `test_export_world_quests.ExportTests.test_incorrect_sql_tuple_width`
41. `test_export_world_quests.ExportTests.test_leading_whitespace_and_tabs_are_accepted`
42. `test_export_world_quests.ExportTests.test_missing_integer_column_defaults_to_zero`
43. `test_export_world_quests.ExportTests.test_missing_quest_fails_closed`
44. `test_export_world_quests.ExportTests.test_negative_prev_quest_id_is_refused`
45. `test_export_world_quests.ExportTests.test_negative_quest_id_is_skipped_and_missing_id_is_refused`
46. `test_export_world_quests.ExportTests.test_row_must_end_as_heidi_tuple`
47. `test_export_world_quests.ExportTests.test_signed_npc_ids_on_creature_links`
48. `test_export_world_quests.ExportTests.test_single_realistic_quest`
49. `test_export_world_quests.ExportTests.test_space_or_tab_after_opening_paren_skips_quest_row`
50. `test_export_world_quests.ExportTests.test_unsafe_integer_coercion`
51. `test_export_world_quests.ExportTests.test_unsupported_gameobject_fails_closed`
52. `test_export_world_quests.ExportTests.test_zip_equals_sql`
53. `test_generate_custom_quests.GeneratorTests.test_bad_ids_counts_and_duplicates_refused`
54. `test_generate_custom_quests.GeneratorTests.test_cli_failed_review_never_replaces_existing_generated_lua`
55. `test_generate_custom_quests.GeneratorTests.test_cli_higher_revision_still_requires_overwrite`
56. `test_generate_custom_quests.GeneratorTests.test_cli_invalid_new_review_creates_no_lua_file`
57. `test_generate_custom_quests.GeneratorTests.test_cli_never_overwrites_existing_file_by_default`
58. `test_generate_custom_quests.GeneratorTests.test_cli_requires_explicit_removal_approval`
59. `test_generate_custom_quests.GeneratorTests.test_explicit_quest_approval`
60. `test_generate_custom_quests.GeneratorTests.test_explicit_verified_npcs`
61. `test_generate_custom_quests.GeneratorTests.test_generated_lua_loads_through_real_335_overlay`
62. `test_generate_custom_quests.GeneratorTests.test_known_quest_lua_structure`
63. `test_generate_custom_quests.GeneratorTests.test_sort_order_and_stable_output`
64. `test_generate_custom_quests.GeneratorTests.test_title_escaping_no_lua_injection`
65. `test_generate_custom_quests.GeneratorTests.test_unknown_format_and_fields_refused`
66. `test_generate_custom_quests_json_roots.InvalidJsonRootTests.test_existing_output_unchanged_with_overwrite`
67. `test_generate_custom_quests_json_roots.InvalidJsonRootTests.test_existing_output_unchanged_without_overwrite`
68. `test_generate_custom_quests_json_roots.InvalidJsonRootTests.test_invalid_roots_do_not_create_output`
69. `test_generate_custom_quests_json_roots.InvalidJsonRootTests.test_valid_minimal_document_generates_lua`
70. `test_generate_custom_quests_numeric_types.NumericJsonTypeTests.test_cli_approved_and_verified_tokens`
71. `test_generate_custom_quests_numeric_types.NumericJsonTypeTests.test_cli_numeric_string_revision_token_is_currently_accepted`
72. `test_generate_custom_quests_numeric_types.NumericJsonTypeTests.test_cli_revision_tokens_follow_argparse_then_whole`
73. `test_generate_custom_quests_numeric_types.NumericJsonTypeTests.test_generate_refuses_non_ints_that_argparse_would_coerce`
74. `test_generate_custom_quests_numeric_types.NumericJsonTypeTests.test_json_numeric_fields_are_refused_without_writing`
75. `test_generate_custom_quests_numeric_types.NumericJsonTypeTests.test_positive_control_minimal_review_generates_lua`
76. `test_generate_custom_quests_numeric_types.NumericJsonTypeTests.test_quests_value_must_be_a_list`
77. `test_generate_custom_quests_numeric_types.NumericJsonTypeTests.test_zero_on_minimum_zero_fields_is_currently_accepted`
78. `test_generate_custom_quests_numeric_types.NumericJsonTypeTests.test_zone_or_sort_currently_accepts_negative_and_zero`
79. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_adjacent_xml_attributes_without_whitespace_refused`
80. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_exact_case_refusal_when_is_file_claims_wrong_case_exists`
81. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_external_toc_symlink_cannot_supply_managed_manifest`
82. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_missing_compat_after_legacy_style_copy_is_refused`
83. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_missing_nested_script_and_exact_case_guard`
84. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_path_traversal_and_absolute_path_refused`
85. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_prefixed_xml_loader_tags_fail_closed`
86. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_quoted_attribute_contents_do_not_create_false_dependencies`
87. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_real_public_335_source_references_without_writes`
88. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_recursive_xml_include_cycle_refused`
89. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_retail_wotlk_toc_is_not_a_335_toc`
90. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_spoofed_xml_file_attribute_is_not_a_file_reference`
91. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_symlink_outside_staging_root_refused`
92. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_synthetic_valid_nested_xml_and_commented_script`
93. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_toc_name_case_refused_when_is_file_is_case_insensitive`
94. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_unterminated_quoted_xml_load_attribute_is_refused`
95. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_unterminated_xml_comment_cannot_hide_references`
96. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_unusual_prefixed_loader_spellings_are_refused`
97. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_windows_drive_and_unc_paths_refused_in_toc_and_xml`
98. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_wrong_case_intermediate_dir_refused_with_case_insensitive_listing`
99. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_wrong_interface_and_wrong_package_folder_refused`
100. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_xml_dtd_and_entity_declarations_refused`
101. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_xml_missing_or_duplicate_file_attribute_refused`
102. `test_nquestie_335_manifest_preflight.ManifestPreflightTests.test_xml_s_whitespace_only_in_loader_attributes`
103. `test_reviewed_classic_chain_sources.ClassicQuestChainSourceTests.test_all_nine_inherited_level_pairs`
104. `test_reviewed_classic_chain_sources.ClassicQuestChainSourceTests.test_prior_level_batches_and_jarl_do_not_overlap`
105. `test_reviewed_classic_chain_sources.ClassicQuestChainSourceTests.test_static_numeric_fix_layers_are_accounted_for`
106. `test_reviewed_early_quest_sources.EarlyQuestSourceTests.test_all_eleven_source_values_still_match`
107. `test_reviewed_early_quest_sources.EarlyQuestSourceTests.test_no_original_static_numeric_corrections_for_these_ids`
108. `test_reviewed_early_quest_sources.EarlyQuestSourceTests.test_quest_1203_and_custom_2001_not_in_the_batch`

Result to pin with that list: `Ran 108 tests`, `OK (skipped=1)`, and the skip id in section 3. The Lua overlay test is expected to **run**, which requires `lua5.1` on `PATH` before discovery.

## 7. Tracked-tree cleanliness

`git status --porcelain` was empty before the suite and empty after both discovery runs. VERIFIED. `__pycache__` is ignored by `.gitignore` line 29 (`*__pycache__/`). SOURCE ONLY for the ignore rule. After the suite, `tools/__pycache__/` contained `cpython-312.pyc` for the three local modules and the ten test modules. VERIFIED (`find`). Those files do not appear in porcelain.

Tracked files under `tools/` (55 paths from `git ls-files -- tools`): sha256 listing before and after was byte-identical. VERIFIED (`cmp`). Command, with `LC_ALL=en_US.UTF-8`:

```bash
git ls-files -z -- tools | sort -z | xargs -0 sha256sum
```

sha256 of that 55-line listing, before and after: `96b760f2a70cf846c551ecdd6d11f659922ecc293ed8aadd7a36fef4d57fa870`. VERIFIED.

Per-file digests (same before and after):

```text
89edd9d0c66e659dd2ab7f117e2d379f64d338093b8cf824559a749244bc43a7  tools/audit_world_quest_levels.py
2cc77f8e537f39d416104814835eb345cc21df45f0ed9bcac44c72dbe62367fa  tools/export_world_quests.py
613e11618368d8317917561a4151317e0ea4906077622f27dab6a0e48e804f84  tools/generate_custom_quests.py
2745c778a0f57184030c6a9be558d95d0121479c4387961311344334ff845ad8  tools/test_audit_world_quest_levels_columns.py
6117d43aa15a99ef442fe032702b313c9a3b5ca299c043d94198afcb6014b8cc  tools/test_audit_world_quest_levels_counts.py
3e07ddaf0ed189bbe9d8f2c5c361540827485156fa0c7cec210f20339350d7c1  tools/test_audit_world_quest_levels.py
4e182ec8b11ebceb93b189f8e95ff91903c3ed758dc1d81580c8d5e757d5d5fe  tools/test_export_world_quests.py
c9348755943c9a7b80699524ae2339d2f4af29c364f7a86d1cb9fed5d5c7dde9  tools/test_generate_custom_quests_json_roots.py
3410b331f71321ce0ea1febeea47fee58537f2eea50771aa4c27906ac65e9971  tools/test_generate_custom_quests_numeric_types.py
849f36168b3baf7b757c18a840ba01d9f4fa12b250816fbe9eaf4873c0797afd  tools/test_generate_custom_quests.py
76e035b16d3c6519fcf193ae6aad524d9581550666c53ebc836332105adfedaf  tools/test_nquestie_335_manifest_preflight.py
81e051df8c8aa9667bc865ecc989999eae21717a4cd5c0e76374c44a67dfc194  tools/test_reviewed_classic_chain_sources.py
a6de91a09df3d78aa0dc40eda9ccd12d24cca60cf5350a083a45c17ad36d3eaa  tools/test_reviewed_early_quest_sources.py
3a7340677fbef783e573114127925fc4be0a27eb56dd22a32c886d9320652bcd  tools/validation/CheckoutState.lua
6010f6b37c9f74b97ee19c08144feab1cb99b3dae3d1d7091ca9673de2c6d7c3  tools/validation/Coverage.lua
5e5e1ddefb7fda88d9f982271386e2eb8ea4e6ef64760a80a7ee00c07774daf1  tools/validation/draft/CorrectionQaDraft.lua
0f111cd70a911ea9e6d1cb1e89daf19b2a8379b0b33847a2d9d2cf0cbfafe810  tools/validation/draft/EffectiveSchemaV2Draft.lua
7a790d8ba5cfa06201532e2f486e23dbae47e63cd19cc86df9e7768e6e265564  tools/validation/draft/M23ReportDraft.lua
a2f67698e606be025de76558be0772c26c85fd5d4c17a1641599b37ec558d157  tools/validation/draft/MarkersDraft.lua
849ddb20648d545990f404fb2c6caa61c06274b9d66c804eb2008413ac01c489  tools/validation/EffectiveExport.lua
a88ae7de4d2cb868b6d3c73aff3f15ef6d1e54485102f7c2bf52a8e423982034  tools/validation/EffectiveExportV2.lua
bcac0e53d9b0286dfe89714b67bf186143333dac3c7235a28dab5717ccb06696  tools/validation/EffectiveSchema.lua
0d37eec4a145760512060dd01a7c710e785b0177dcab2045867a5473a2c72092  tools/validation/EffectiveSchema.test.lua
6073fe73a1b1dcce96e88e9c8cd082013b626ded785dbfab6cc73deab50705ee  tools/validation/EffectiveSchemaV2.lua
3ae8848436df5e60922bfb9f9a46bb61ac5322d5d598a4e46404b78377641a3d  tools/validation/ExportProvenance.lua
ebeff0957b53d2841152ec228c7138a2d8d56be4233c863058e88bc8f927dd0a  tools/validation/ExportV2.lua
bc4483990b164c98c30cb0f5f0b62773bd95ade9ef22811d899c23c8b4a6f124  tools/validation/fixtures/compiled_shapes.lua
65ffe3eda1c3be7f149b32c125873a9f48b827e60f26395d6479c6d7bfd0b1b0  tools/validation/fixtures/effective_cases.lua
82c23d3ca0657fa71958ef4fdd3f679d4767f25e64cc5bbea00761a1c6c43f34  tools/validation/fixtures/input_cases.lua
4298e6caec4e7589dc56b83f1918afb4727029a44853a6e43210e02f32e6d73b  tools/validation/fixtures/input_parse_cases.lua
9c71e8c1504f9a2c83867b30f65bcafbe91db0927dd2b35fd1c8f37cdab48318  tools/validation/fixtures/objective_cases.lua
b5a084913924f3944ef0a863684aaf75ec66de2fab164a057eff34f12f4db6fb  tools/validation/InputSchema.lua
f13d7f72ffb1faef1ad6dc8c6b35160991ce98caa3bd8a908f4f79d8a63d02e5  tools/validation/InputSchema.test.lua
ebe5aeb39fb8e70630a73a72b16aec31df4b8ec0469c97415fa7cd1048759785  tools/validation/integration/assertion_counts.sh
57ee56bbc93f978375d83f28cae0319ba8ec0eef1f0b4b3bdd4043d98745361c  tools/validation/integration/test_inventory.sh
37b2904ac2c4073c034f7b8d5e67416cd4a03df76065e4891b5b0a9d5c4baf03  tools/validation/M21Private1203Gate.test.lua
00243551d38b8367bf39bf508c97d11875076febdbdd3f5fcc8209b8a93d1b36  tools/validation/M22Export.test.lua
da6be278c1378d0525eafb07f8d5d7e13a752b5e53f90678cdea1b51e9b46bb6  tools/validation/M22Libraries.test.lua
c64d99927bb9b60cd656c60e004257e1f733b98e0a18df3efc538afffdbf746e  tools/validation/M22PilotPreflight.test.lua
0abe0fa77fad3e914109b9c41d58e12c38dd39e5660ca2f5fe5a983361b41329  tools/validation/M23ApprovedExports.lua
1f273ec7507f006fe56f1d4abfd2acdf986cbb170193a978497fc37799908957  tools/validation/M23ApprovedExportsParser.lua
443eec7ff2963ed6915bb965a10e15d647177670c1d4027e6b14d70a89dab188  tools/validation/M23Batch.lua
0861b30d553e72923133b27a3c3ed6087ce133f5f11441c1322ed9936844e552  tools/validation/M23Batch.test.lua
c70528f5a387b9d7d717de31a66db2dfd0cc90b08ba91a4b16d6c39f7b0bca8b  tools/validation/M23Foundation.test.lua
37b522073be8dcf526c6148db15ccfac9711dcf295823a2cc07b4ec600e23a01  tools/validation/M23Membership.lua
6d00d54f478938968f76e9f1ef457e7140a2c164417d645cba01daba53db3aaf  tools/validation/M23QuestieAdapter.lua
bf394847e049caa95bbc7e98fa39eb5c703e9c072eda0be46a156dae61f06982  tools/validation/M2V2RoundTrip.test.lua
dd095356a906195bee2a7867bfd070140a168fcae27d9a159213a77ac4810a54  tools/validation/NoWriteGuard.lua
3b974f9436aa975b3ee5122199b24e25b030c2e8e6dcb3e462ed676f6af96011  tools/validation/ObjectiveRules.lua
a515ab3a6c00a61a209dba8acd38778101708fb9f08674ef8918d68277f5bfc2  tools/validation/ObjectiveRules.test.lua
ebb123d56947bf294641472daa5d31fab807b867aa92699ef13d45f061208224  tools/validation/RoundTripV2.lua
ac2e830c8275f5ebc4510244dde175f6a50ed55cc04658ce74747dc1ee7815ae  tools/validation/run_cases.lua
4ee1e2e62c49cccd8568a3866aa86e03def552a3f08521b5d92e66f5a02b22cd  tools/validation/run-m2-pilot.sh
513e596f07b1fc1162a9efc1cad8b26cd92591b8063804e75403c53042cc87f2  tools/validation/SafeWrite.lua
d6460e4befe60faeea70f303ccbfdf2b005d8928fa4debdfc788d844ac4ee9cc  tools/validation/StatusCapture.lua
```

## 8. Discovery risks

1. **`argparse` program name changes under discovery. VERIFIED, and the current assertions still passed.** Standalone, `parser.error` usage text starts with `test_audit_world_quest_levels.py` and `test_generate_custom_quests.py`. Under `python3 -m unittest discover`, the same calls print `usage: python3 -m unittest`. Cause: `main()` uses `argparse`, whose prog defaults to `sys.argv[0]`, and discovery's `sys.argv[0]` is the unittest module. SOURCE ONLY for that mechanism (`tools/audit_world_quest_levels.py` lines 227–235, `tools/generate_custom_quests.py` lines 137–149). The tests assert `SystemExit` or the exception type, not the usage banner, so both modes exited 0. A future assertion on the prog string would fail under discovery and pass standalone.

2. **`if __name__ == "__main__"` is not executed by discovery.** In all ten files the block only calls `unittest.main()`. SOURCE ONLY. Discovery still collected every `TestCase` method: standalone and discovery counts match. VERIFIED. Logic placed only inside that block would not run under discovery.

3. **No `sys.path` edits.** SOURCE ONLY (search of the ten tests and three local modules found no `sys.path` assignment). Standalone works because Python puts the script directory (`tools/`) on `sys.path`. Discovery inserts the start directory (`tools/`) the same way. VERIFIED by both discovery runs, including cwd `/tmp` with `-s /workspace/tools`.

4. **Repo root is `Path(__file__).resolve().parents[1]`, not the process cwd.** SOURCE ONLY. Relative audit paths are joined to that root (`root / audit.QUESTIE_RAW`). Discovery from `/tmp` produced the same ids and the same pass result. VERIFIED.

5. **`tools/` has no `__init__.py`.** VERIFIED (`ls tools/__init__.py` failed). Discovered modules are top-level names (`test_export_world_quests`), which is what the pin uses. The proposed command is `-s tools`. Starting discovery at the repo root is a different command and is **NOT TESTED**.

6. **No module-name collision among the ten files.** VERIFIED: 108 unique ids, ten distinct module prefixes. No `test_*.py` outside `tools/` exists to be pulled in by `-s tools`. VERIFIED.

7. **One process imports every module.** Discovery passed twice. VERIFIED. This session did not separately prove that tests avoid mutating globals of `audit_world_quest_levels`, `export_world_quests`, or `generate_custom_quests`. A future test that depended on import-time state left by another file could pass standalone and fail under discovery, or the reverse. UNKNOWN for a mutation that these 108 tests do not hit.

8. **`lua5.1` must already be on `PATH` or the pin's single skip becomes two.** SOURCE ONLY for `skipUnless` at `tools/test_generate_custom_quests.py` lines 105–106. The overlay job installs Lua at lines 16–19, before the Python steps. An additive discovery step later in that same job sees `lua5.1`. A discovery step in a job that has not installed Lua would skip `test_generated_lua_loads_through_real_335_overlay`. NOT TESTED without Lua.

9. **`test_generate_custom_quests_json_roots.py` fails if `git status --porcelain` changes during a test** (lines 123–127). SOURCE ONLY. The suite left porcelain empty. VERIFIED. A discovery step that writes a tracked file mid-run would fail this module.

10. **Stdout from `audit.main` and `generator.main` is noisy under discovery, and assertions still passed.** VERIFIED in the verbose logs: `PRIVATE audit: ...` and `Generated curated Lua records ...` appear, and argparse errors are expected refusals. With stdout redirected, those prints showed up after the `OK (skipped=1)` line because unittest progress is on stderr and non-TTY stdout is block-buffered. That is a capture-order effect. The exit code was still 0.

11. **Temp paths in that stdout differ every run.** VERIFIED (two different `/tmp/tmp…` directories). They are not part of the pin.

12. **Every current `test_*.py` is a real `unittest` module.** VERIFIED by discovery loading all ten and by the counts above. A future non-test file matching `test_*.py` would be imported by the same command.

13. **Landing PR #136's `tools/test_world_quest_sql_quoting.py` would change this inventory.** The file is absent here. VERIFIED. Its behaviour is NOT TESTED.

## 9. Recommendation

This is a **proposal**. It needs the maintainer's explicit approval. No workflow file was edited for this note.

Agreed shape, if that approval is given later:

- Add one step to `.github/workflows/nquestie-overlay.yml`, in job `verify-custom-quest-overlay`, after the existing Python commands (the last of those is `Test 3.3.5a manifest preflight`, lines 55–56) and before `Assemble PR-only WoW 3.3.5a addon package`.
- Command: `python3 -m unittest discover -s tools -p 'test_*.py' -v`.
- Keep every existing step, including the six explicit `python3 tools/test_*.py` commands.
- Keep `if: ${{ false }}` on `Assemble PR-only WoW 3.3.5a addon package` (line 71) and on `Upload temporary N-Questie PR test build` (line 95).
- Pin the check to the 108 ids in section 6 and to exactly one skip (`test_repeated_correction_id_policy_is_not_stated`, reason in section 3). Do not use a bare `>= 108` floor.
- Run that step in the same job after `Install Lua 5.1` (lines 16–19), so `test_generated_lua_loads_through_real_335_overlay` executes instead of skipping.

On this commit, with Python 3.12.3 and Lua 5.1.5, that discovery command is ready to add: 108 tests, one intentional skip, identical ids from two working directories, and no tracked-file changes under `tools/`. VERIFIED for this host. It is not a workflow change.
