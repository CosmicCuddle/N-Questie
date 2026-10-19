# DEV-087 — M0 / M1 / M2 write-side effect audit

Audit only. No validation code, tests, fixtures, workflows, TOC, Compat, or SavedVariables were changed. This note records a source review of file writes on commit `4111b097df44daa02751f4b7a2792689b1df89e6` and the cleanliness of that tree after the M0, M1, and M2 workflow commands were run locally.

Labels used below:

- **VERIFIED** — observed on a run in this audit.
- **SOURCE ONLY** — read in source; not separately instrumented.
- **NOT TESTED** — not executed.
- **POTENTIAL ISSUE** — a write or a blind spot that the current gates do not fully cover.

## Scope and base

| Item | Value |
| --- | --- |
| Repository | N-Questie (`CosmicCuddle/N-Questie`) |
| Base commit | `4111b097df44daa02751f4b7a2792689b1df89e6` |
| Base branch (not modified) | `test/nq-invalid-custom-quest-id-keys-2026-10-19` |
| Remote tip of that branch at audit time | same SHA |
| Overlay Assemble / Upload | `.github/workflows/nquestie-overlay.yml` lines 71 and 95, `if: ${{ false }}` |

`335` was not checked out, committed to, or used as a PR base.

Cleanliness method, run before and after each suite from `/workspace`:

```bash
git status --porcelain --ignored
git status --porcelain --untracked-files=all
git ls-files -z | while IFS= read -r -d '' f; do
  if [ -d "$f" ] && [ ! -L "$f" ]; then printf 'DIR %s\n' "$f"
  else sha256sum -- "$f"; fi
done
```

`sha256sum` cannot hash a gitlink directory. The two tracked submodule paths were recorded as `DIR` instead of a digest:

- `.types/.SubModules/BlizzardInterfaceCode`
- `.types/.SubModules/vscode-wow-api`

That is 912 tracked paths (910 file digests + 2 directory markers). A digest mismatch would still show up as a diff of that list. `git status --porcelain --ignored` was empty before every suite.

## Toolchain

M1 and M2 install Lua from apt and Busted from an unpinned `luarocks --lua-version=5.1 install busted`. This host matched that shape:

| Tool | This run | Workflow |
| --- | --- | --- |
| Lua | 5.1.5 (`lua5.1` 5.1.5-9build2). `lua` and `luac` are alternatives to `lua5.1` / `luac5.1` | M1/M2: `apt-get install lua5.1`. M0: `leafo/gh-actions-lua@v10` with `luaVersion: "5.1"` (the Action installer itself was **NOT TESTED**) |
| LuaRocks | 3.8.0 (apt) | M1/M2: apt `luarocks`. M0: `leafo/gh-actions-luarocks@v4` (**NOT TESTED**) |
| Busted | 2.3.0, installed by the same unpinned luarocks command the workflows use | M1/M2 do not pin a version. Inherited `ci.yml` pins `lunarmodules/busted@v2.2.0`; that workflow was **NOT TESTED** |
| bit32 | 5.3.5.1-1 | Installed only for M0 and M2, matching those workflows. Absent during M1 |
| realpath | GNU coreutils 9.4 | Required by the M2 workflow |
| python3 | 3.12.3 present, unused | No Python step in the three suites |

## Entry points

| Suite | Workflow | What was executed |
| --- | --- | --- |
| M0 | `.github/workflows/nquestie-validate-335.yml` job `validate-335` | `luac -p cli/validate-335.lua tests/fixtures/validate335/*.lua`; `NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 lua cli/validate-335.lua`; `LUA=lua bash tests/test_validate_335_fixtures.sh` |
| M1 | `.github/workflows/nquestie-objective-rules.yml` job `objective-rules` | private-file guard and its self-test; `luac5.1 -p` of `tools/validation/*.lua`, fixtures, and `cli/validate-objectives.lua`; `lua5.1 tests/test_nquestie_objective_rules.lua`; `busted -p ".test.lua" tools/validation`; M2.1 schema/path steps; `lua5.1 cli/validate-m2-input.lua` on the synthetic adapter fixture; `lua5.1 cli/validate-objectives.lua` |
| M2 | `.github/workflows/nquestie-m2-effective-export.yml` job `m2-framework` | the workflow's Lua 5.1 syntax list, both private-file scripts, the standalone M1/M2.1/M2.2 Lua tests, `bash -n tools/validation/run-m2-pilot.sh`, the same Busted pattern, M0 negatives, `tests/test_nquestie_m2_export_integration.sh`, `tests/test_nquestie_m2_coverage_integration.sh`, then `test -z "$(git status --porcelain --untracked-files=all)"` |

`tests/run_m2_suite.sh` is a local aggregator. The M2 workflow does not call it. It was **NOT TESTED** as an entry point. Its steps overlap the workflow.

Read at the same commit and **NOT TESTED**: `.github/workflows/ci.yml` (Luacheck, inherited Busted, Era/SoD/WotLK validators, tag publish), `.github/workflows/nquestie-revision-guard.yml`, and the test steps in `.github/workflows/nquestie-overlay.yml` (overlay Lua/Python checks). Overlay Assemble and Upload are hard-disabled (`if: ${{ false }}`) and were not run.

## Source review of writes

Read-only `io.open` (`"r"` / `"rb"` / default mode), `io.lines`, `loadfile`, and `io.popen` of `pwd`, `git status`, `realpath`, `sha256sum`, or `id` are not writes. They are omitted except where a command can create or replace a file.

### M0 — `cli/validate-335.lua` and the fixture script

Default M0 mode does not open a file for write. `exportOptions`, `coverageOptions`, `v2ExportOptions`, and `roundTripOptions` return before any writer when their environment variables are unset (`cli/validate-335.lua` around 434–441, 496–500, 578–580, 679–682). The workflow sets only `NQ_VALIDATE_EXPECT_LEVEL_COUNT`.

Writes that exist in this file and run only when an export or coverage mode is turned on:

| Location | What is written | Where |
| --- | --- | --- |
| `cli/validate-335.lua:566` | coverage manifest via `SafeWrite.WriteFile` | path in `NQ_COVERAGE_MANIFEST_OUT` |
| `cli/validate-335.lua:569` | coverage aggregate text via `SafeWrite.WriteFile` | path in `NQ_COVERAGE_AGGREGATE_OUT` |
| `cli/validate-335.lua:917` | v1 effective export via `SafeWrite.WriteFile` | path in `NQ_EXPORT_EFFECTIVE_OUT` |
| `tools/validation/ExportV2.lua:141` | v2 export, called from `runExportV2` | path in `NQ_EXPORT_V2_OUT` |

`tools/validation/SafeWrite.lua:134–148` creates the bytes. `mktemp -p <dest-dir> .nq-write.XXXXXXXXXX` then `io.open(temp, "wb")`. Install is `ln -T` (no clobber) or `mv -fT` when `force` is set (`SafeWrite.lua:167–178`). `CheckDestination` (`SafeWrite.lua:84–112`) refuses a destination that resolves inside the checkout unless it is under `<checkout>/private/`. v2 export adds a second refusal that also rejects `private/` (`cli/validate-335.lua:726–727`).

`SafeWrite.lua:178–180`: if the hard link is published and `rm` of the temp name fails, the function returns failure but leaves the published file and possibly a second link (`.nq-write.*`) in the destination directory. That directory is the caller-chosen output directory, not a fixed path in the repo. **SOURCE ONLY** for the failure branch; the successful runs below left no `.nq-write.*` under the checkout (**VERIFIED**).

`tests/test_validate_335_fixtures.sh` only runs the harness with `NQ_VALIDATE_SKIP_COMPILE=1` and `NQ_VALIDATE_FIXTURE` set to each synthetic fixture, then greps stdout. No `io.open` write, redirect, or `rm` of a repo path. **SOURCE ONLY**, and the script was run (**VERIFIED** exit 0, no hash change).

`cli/profiler.lua:239` (`io.open(filename, "w+")`) is not on the M0/M1/M2 entry path. **NOT TESTED**.

### M1 — objective rules, Busted, and the M2.1 steps the M1 workflow also runs

| Location | What is written | Where |
| --- | --- | --- |
| `tests/test_check_no_tracked_private.sh:9–12` | throwaway `git init` repos (`echo`, `git add`, `git commit`) | `mktemp -d`, then `rm -rf` |
| `tests/test_nquestie_objective_rules.lua` | none. Header says no file writes; no `io.open` | — |
| `cli/validate-objectives.lua` | none. Prints a report. `loadfile` of the fixture only | — |
| `cli/validate-m2-input.lua:15` | `io.popen` of `pwd` only. Header says it never writes | — |
| `tests/test_nquestie_m2_input_paths.lua:28–32` and `:131`, `:142` | `mkdir -p` plus copies, symlinks, and `io.open(..., "wb")` of a fake `realpath` and a probe script | child dir `<repo>/private/m2-path-test-<time>-<rand>` **and** a `mktemp -d` outside the repo. `cleanup()` at line 171 removes those two paths, not a parent `private/` the test itself created |
| `tools/validation/M22Libraries.test.lua:12–22` | `os.execute("lua5.1 <script>")` for library tests, including safe-write | see M2 rows; Busted on M1 does run these |
| `tools/validation/M2V2RoundTrip.test.lua:11–21` | `os.execute` of the Stage A1/A2 scripts | temp dirs (below). Real-DB rows run only when `require("bit32")` works |

`tests/test_nquestie_m2_input_schema.lua:109–115` uses `io.popen` to run the read-only CLI. No write mode.

Busted's own runner was not configured with coverage or a file output. No Busted output file appeared in the tree (**VERIFIED**).

### M2 — writers reached by the framework workflow

Direct steps plus everything Busted reaches (`*.test.lua` under `tools/validation/`).

| Location | What is written | Classification |
| --- | --- | --- |
| `tests/test_nquestie_m2_safe_write.lua:17–21`, `:48`, `:111–195` | `SafeWrite` output, hook files, and fake `mktemp`/`stat`/`rm` binaries | `<repo>/private/m2-write-test-<time>-<rand>` (mode 0700 child) and `mktemp -d` outside the repo. Line 231 deletes the child and the outside temp, not the parent `private/` |
| `tests/test_nquestie_m2_effective_schema.lua:100–111` | `cp` and `ln -s` via `os.execute` | `mktemp -d` outside the repo. `rm -rf` is the next sequential call, not a shell `trap`. A crash between line 100 and 111 would leak that temp dir. **SOURCE ONLY** for the crash path. After the successful run, no `/tmp/tmp.*` remained (**VERIFIED**) |
| `tests/test_nquestie_m2_export_integration.sh:11–12`, `:46`, `:65`, `:76–77` | selection file `io.open(NQ_SEL_OUT, "w")`; harness exports; `git clone` plus one untracked file in the clone | `$T` from `mktemp -d` (mode 0700) and a second temp clone. Line 65 asks for `$PWD/docs/x.lua` and expects refusal. The script does not delete `docs/x.lua` if the refusal were wrong |
| `tests/test_nquestie_m2_coverage_integration.sh:11–12`, `:22–23`, `:33` | real manifest and aggregate; one refusal aimed at `$PWD/coverage-manifest.lua` | success path is under `$T/priv`. Line 23 runs `rm -f coverage-manifest.lua` if that checkout path exists, so a bad write would be removed by the test itself before a later status check |
| `tests/test_nquestie_m2_v2_export.lua` | `io.open(..., "wb")` of synthetic v2 files | `mktemp -d` directories, removed at the end of the file |
| `tests/test_nquestie_m2_v2_mutation.sh:13–30`, `:49–54` | copies of sources, then `io.open(path, "w")` of a mutant | only under `$T/w` from `mktemp -d` |
| `tests/test_nquestie_m2_v2_verify_clean.lua:59–77` | temp git repo (`printf`, `git add`, corrupt-index probe) | `mktemp -d`, then `rm -rf` |
| `tests/test_nquestie_m2_v2_export_integration.sh:14–15` and `tests/check_m2_v2_export_file.lua:90` | v2 export file, coverage manifest, tampered copy (`io.open(arg[3], "wb")`) | `$T` from `mktemp -d`. Tamper target is `$T/tam/v2.lua` (integration script line 165). `trap` removes `$T` |
| `tests/test_nquestie_m2_v2_roundtrip_integration.sh` | harness stdout/stderr logs | `mktemp -d`. Round-trip mode is wrapped in `NoWriteGuard` inside the harness (`cli/validate-335.lua:631–632`) |
| `tests/test_nquestie_m2_pilot_preflight.sh:8–10`, `:37–53` | preflight fixtures (`printf >` logs, checksum, export placeholder) | `mktemp -d`. The script also asserts `$ROOT/negatives-1203.log` was not created |
| `tests/test_nquestie_private_1203_gate.sh:5–7`, `:66` | synthetic inputs; one fixture appends `os.execute("touch .../should-not-exist")` | `mktemp -d`. The touch string is data inside the fixture; the gate must not execute it |
| `tools/validation/run-m2-pilot.sh:46–47`, `:66–73`, `:113` | `mkdir -p` of `OUT_DIR`, then logs, the v1 export, and `SHA256SUMS-*` | caller-supplied absolute directory (outside the checkout, or under `private/`). The M2 workflow runs `bash -n` only, so this script's writes are **not** executed by that step. Busted does execute `tests/test_nquestie_m2_pilot_preflight.sh`, which invokes the script in reject paths and one temp-dir path |

`tests/test_nquestie_m2_no_write_guard.lua:13–23` calls write APIs only after `NoWriteGuard.Install`. Targets are `/nonexistent-dir/...`. `os.tmpname` and `io.tmpfile` are blocked before the real C function (`tools/validation/NoWriteGuard.lua:28–42`). Line 36 calls `SafeWrite.WriteFile` on `/tmp/nq-guard-test-should-not-exist` while the guard is installed. That path was absent after the suites (**VERIFIED**).

`NoWriteGuard` does not wrap an already-open file handle's `:write`, `os.execute` replacements installed by the caller before `Install`, or LuaFileSystem. **SOURCE ONLY**. The guarded modes used by the harness are the v2 round trip and v2 verify paths, not default M0.

No Python `open(..., "w")`, `shutil`, or `subprocess` call is on the M0, M1, or M2 workflow steps. Overlay's `tools/test_*.py` helpers use `tempfile.TemporaryDirectory`. Those tests were **NOT TESTED**.

## Runs

Host clock is UTC. Every suite exited 0. After each suite, all 912 tracked-path records matched the pre-run list (no digest change). `git status --porcelain --ignored` and `--untracked-files=all` were empty both before and after. No `.nq-write.*`, `coverage-manifest.lua`, or `docs/x.lua` was left in the tree. `/tmp/tmp.*` count was 0 after each suite.

### M0 — VERIFIED

Window: 2026-10-19T19:09:53Z to 19:10:59Z. `bit32` was installed. `private/` did not exist before or after.

`NQ_VALIDATE_EXPECT_LEVEL_COUNT=28 lua cli/validate-335.lua` printed (ANSI color stripped):

```text
[validate-335] level corrections asserted: 28
[validate-335] compiled round trip: 82431 quest fields compared, 0 mismatches
[validate-335] PASS: 232 checks
```

`luac -p` exited 0. `tests/test_validate_335_fixtures.sh` rejected all five fixtures and exited 0. No export line was printed, which matches the harness staying out of `WriteFile` when export variables are unset.

Tracked databases and fixtures were not modified. **VERIFIED**.

### M1 — VERIFIED

Window: 2026-10-19T19:08:01Z to 19:08:59Z. This run was done **before** `bit32` was installed, because the M1 workflow does not install it.

Every workflow step exited 0, including:

- `PASS: 29 objective-rule fixtures, all rules exercised, inputs unchanged`
- `busted`: `168 successes / 0 failures / 0 errors / 3 pending` in 55.0s
- `PASS: M2.1 input schema (43 validation cases, 16 parse cases)`
- `PASS: M2.1 path safety (32 cases)`
- `cli/validate-m2-input.lua` on the synthetic adapter: `OK: 2 quest record(s)...`
- `cli/validate-objectives.lua` finished with the report-only summary

The three pending Busted examples are the `bit32` gates in `tools/validation/M2V2RoundTrip.test.lua` (CLI verify clone, real-DB round trip, real-DB v2 export). They were pending because `require("bit32")` failed, which is what that spec does when bit32 is absent. They are not silent passes. The same three examples ran under M2 after bit32 was installed.

Busted on this workflow still executes the non-DB library tests, the mutation copy, safe-write, and path tests. The path log accepted `/workspace/private/m2-path-test-1792436936-840188/input.lua` and then cleanup removed that child.

**Leftover, VERIFIED:** after M1, `/workspace/private` existed, empty, mode `0755`. It was not listed by `git status --porcelain --ignored` (git does not list an empty directory). It was removed by the auditor before the M0 snapshot so M0 and M2 started from a tree with no `private/`. That removal was not a tracked change.

### M2 — VERIFIED

Window: 2026-10-19T19:11:56Z to 19:19:20Z. `bit32` was installed. Direct steps all exited 0, including:

- safe writer `PASS: M2.2 safe writer (40 checks)`
- `busted`: `171 successes / 0 failures / 0 errors / 0 pending` in 247.9s (the three M1-pending real-DB examples ran)
- M0 negatives, five fixtures rejected
- `PASS: M2.2 export integration (25 checks)`, including `PASS: no export option: 232 checks, no export`, `PASS: baseline wrote nothing`, `PASS: output inside the checkout`, and `PASS: no output file after any refusal`
- `coverage integration: 26 passed, 0 failed`, including `PASS: all 232 M0 checks passed first`, `PASS: 82,431 compiled fields, 0 mismatches`, and `PASS: nothing written in checkout`
- the workflow's own cleanliness command exited 0

**Leftover, VERIFIED:** after M2, `/workspace/private` again existed, empty, mode `0755`, mtime in the same minute the suite started. Status and digests were still identical, and the workflow gate still exited 0. No file remained inside `private/`.

## Findings

1. **Tracked Questie databases, compiled sources, and fixtures were not modified by these three suites. VERIFIED.** Digests of all 910 tracked files matched before and after M0, M1, and M2. No untracked non-ignored file appeared.

2. **Default M0 does not write. VERIFIED.** With only `NQ_VALIDATE_EXPECT_LEVEL_COUNT=28` it printed `PASS: 232 checks` and left no output file. Export and coverage writers in `cli/validate-335.lua` are opt-in and were not armed by the M0 workflow.

3. **Two tests write inside the checkout, under gitignored `private/`. VERIFIED that the children are removed; VERIFIED that the parent directory remains. POTENTIAL ISSUE.**
   - `tests/test_nquestie_m2_input_paths.lua:28` creates `<repo>/private/m2-path-test-*`.
   - `tests/test_nquestie_m2_safe_write.lua:20` creates `<repo>/private/m2-write-test-*`.
   - Both delete the child directory. `mkdir -p` creates `private/` when it is absent, and neither cleanup removes that parent. Mode `0755` matches `mkdir` under umask `022` (GNU `mkdir -m` applies to the final component).
   - M0, which does not run those tests, did not create `private/`. M1 and M2, which do, each left an empty `private/`.

4. **The existing cleanliness gate cannot see that leftover, or a failed cleanup under `private/`. VERIFIED. POTENTIAL ISSUE.**
   - M2's last step is `git status --porcelain --untracked-files=all` (`.github/workflows/nquestie-m2-effective-export.yml:97`). It exited 0 while empty `private/` existed.
   - After the M2 snapshot, a probe file `private/dev087-probe.txt` was created and then deleted. With the file present, `git status --porcelain --untracked-files=all` was still empty, and `git status --porcelain --ignored` showed `!! private/`. `git check-ignore` attributed that to `.gitignore:35` (`private/`).
   - An empty `private/` is invisible to both status forms. A leftover file under `private/` is invisible to the workflow gate and visible only with `--ignored`.
   - `tests/test_nquestie_m2_pilot_preflight.sh:14` uses the same porcelain command and passed during M2 Busted, which is consistent with this blind spot. The pilot preflight was not given a dirty `private/` on purpose; the directory was already there from earlier steps.

5. **Configured export paths used by the integration scripts stayed in temp directories. VERIFIED for the successful runs.** Export, coverage, v2 export, mutation, and the dirty-checkout clone all target `mktemp -d` (or a clone under it). Refusals of `$PWD/docs/x.lua` and `$PWD/coverage-manifest.lua` passed, and those paths did not exist afterwards. **SOURCE ONLY:** `tests/test_nquestie_m2_coverage_integration.sh:23` deletes `coverage-manifest.lua` if the refusal fails, which would hide that one path from a following status check. `tests/test_nquestie_m2_export_integration.sh` does not delete `docs/x.lua` on a failed refusal. Neither failure happened on this run.

6. **No fixed write path outside a temp dir or `private/` is on the default M0/M1/M2 command lines. SOURCE ONLY for the negative, VERIFIED for this checkout.** `SafeWrite` will write to any absolute directory that passes its checks, including `<checkout>/private/` for v1 and coverage. The workflows do not set `NQ_EXPORT_*` or `NQ_COVERAGE_*`. The pilot script can `mkdir` its `OUT_DIR` argument; the workflow does not invoke it except through the preflight test, which uses a temp directory.

7. **Temp-dir cleanup is trap-based in the shell integration scripts and sequential in two Lua files. SOURCE ONLY residual.** `tests/test_nquestie_m2_effective_schema.lua:111` is not a `trap`. No leaked `/tmp/tmp.*` was present after the successful runs (**VERIFIED**). `SafeWrite`'s post-publish `rm` failure can leave `.nq-write.*` beside a published file (**SOURCE ONLY**); not observed here.

8. **M1 Busted does not execute the three real-DB write tests unless bit32 is installed. VERIFIED.** Pending on M1 (no bit32). Executed on M2 (bit32 installed), 171/0/0, and the checkout digests still matched.

## Recommendations (proposal only)

Do not implement these in the M0 harness, M1 rules, frozen v1 exporter, or this change. They are test-only or workflow-only assertions. Editing `cli/validate-335.lua`, `tools/validation/ObjectiveRules.lua`, or other frozen modules needs a separate approval.

The gap is real enough to warrant an assertion: the suites can create a directory inside the repo, the current M2 gate does not see it, and a file left under `private/` would also pass that gate.

Proposed checks, in a new test or an extra CI step, not inside the frozen harness:

1. Snapshot `git status --porcelain --ignored` and the tracked-file digest list before the suite and require an empty diff after it. Keep the existing `git status --porcelain --untracked-files=all` check; do not treat it as sufficient.
2. If `private/` was absent before the suite, require it to be absent afterwards (`test ! -e private`). If a future fixture needs a pre-existing `private/`, require `find private -mindepth 1` to be empty instead. That catches both the empty directory observed here and a file the ignore rule would hide.
3. Run the path and safe-write tests with a dedicated temp parent, or `rmdir` the `private/` directory when the test created it and it is empty. That is a test change (`tests/test_nquestie_m2_input_paths.lua`, `tests/test_nquestie_m2_safe_write.lua`), still outside frozen M0/M1 code, and still not part of this task.
4. Optionally set `TMPDIR` to a suite-local directory and assert it is empty at the end, so a missing `trap` in `tests/test_nquestie_m2_effective_schema.lua` fails the suite instead of leaking outside the repo.
5. Do not add a write assertion by changing `SafeWrite` or `validate-335.lua`. Those already refuse public checkout paths. The hole is the cleanliness check and the `private/` parent directory, not a tracked-database write on the workflow commands that were run.

## Not claimed

- The leafo Lua/LuaRocks GitHub Actions were not executed. Lua 5.1.5 and an unpinned Busted 2.3.0 were used instead.
- `ci.yml`, the revision-bump workflow, and the overlay workflow's Lua/Python tests were not run.
- No in-game client, SavedVariables, addon zip, or upload was produced.
- A crash mid-test was not injected, so trap-versus-sequential cleanup is **SOURCE ONLY** beyond the successful-run observation that nothing under `/tmp/tmp.*` or `.nq-write.*` remained.
