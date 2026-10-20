# N-Questie 3.3.5a — Windows PowerShell 5.1 / NTFS read-only stage verifier (design)

**Status: DESIGN ONLY. Windows verification is STOP / NOT TESTED.** No owner action. This note is not an installer, not a script, and not a live WoW, AddOns, WTF, SQL, or server procedure. It builds no ZIP and creates no release. Nothing here is a Windows PASS.

CS02 Workstream 3, 20 October 2026. Parent commit `891a627318ac403d4da28655318286507f96c1aa` (frozen draft #148). This PR adds this file only. It does not modify #148, #149, or #150.

Labels: **VERIFIED** (re-derived here, or read from a named Git object or a page fetched for this note), **POTENTIAL ISSUE**, **UNKNOWN**, **NOT TESTED**. Where this note says **UNVERIFIED**, it means the Microsoft page exists and the Windows PowerShell 5.1 behaviour is still **UNKNOWN**. Documentation text is not Windows execution.

## 1. What was re-derived

**VERIFIED** (Linux, off-game, this note): the bytes of `docs/NQ-335-STAGE-EXPECTED-MANIFEST-891a6273.tsv` were fetched from draft #150 head `610a76765bca957223004f3a95221de456f13bd3`. SHA-256 `73eccd4498a3a47db4c5d3fca60a83f7c35052174afcbafe350839b34fcb6b52`, 84,728 bytes, Git blob `474c3efbfb61da7c5e4e011726686edac53f700f`. Header `path	bytes	git_blob	sha256`, then 557 data rows, LF, no CR. Those bytes are not copied into this branch. Do not regenerate the TSV to add directory rows.

**VERIFIED** from those 557 `path` values. The directory set is every proper prefix: for `Modules/Quest/QuestEventHandler.lua` the prefixes are `Modules` and `Modules/Quest`. Counted that way, the TSV implies exactly 109 directories (89 leaf, 20 non-leaf), maximum depth 4, and 13 directories with exactly one descendant file. A leaf directory has no other directory name under it. Case-folding the 557 file paths and the 109 directory paths, with a second check of each final component against its parent, finds 0 file collisions and 0 directory collisions. Top-level split: 3 root files (`embeds.xml`, `Questie-335.toc`, `Questie.lua`) / Compat 64 / Database 57 / Icons 53 / Libs 102 / Localization 168 / Modules 110. Longest relative file path is 67 characters (`Compat/Libs/AceGUI-3.0/widgets/AceGUIContainer-BlizOptionsGroup.lua`). Longest relative directory is 42 characters (`Localization/lookups/Classic/lookupObjects`). The same bytes contain no non-ASCII, no control bytes other than TAB and LF, no `<>:"\|?*`, no reserved DOS device basenames (`CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9`, `LPT1`–`LPT9`, including an extension), no empty / `.` / `..` components, and no trailing dot or space. That agrees with CS01 Part 79 (`6299431420`) and is source-name syntax only. Owner path length, long-path policy, and case retention are **NOT TESTED**. On a legacy ~260-character absolute limit, a long stage root can still fail. An OS path-length error is STOP `api-failed`. Do not turn on a long-path prefix to force a PASS.

The four notice paths named in #150's guide are rows in that TSV, and this note re-checked that they are present: `Icons/LICENSE.md`, `Icons/MIT.txt`, `Libs/LICENSE.txt`, `Libs/Krowi_WorldMapButtons/LICENSE.md`.

## 2. Neighbour work this design does not change

**VERIFIED** by reading #149 head `6922180c3a5a0a5559098766360226cbabc3d583`: `tools/check_nq_335_local_stage.py` is a read-only structural checker. It rejects a raw `..` component before `os.path.abspath`, walks the lexical ancestor chain, inventories with `os.scandir` and `follow_symlinks=False`, and skips TOC, XML, Lua, and texture reads after a layout failure. Notice handling there is presence of three paths, plus the Krowi notice when that directory is present. It does not hash the 557 files against the TSV and it does not read NTFS link counts. Its `FILE_ATTRIBUTE_REPARSE_POINT` check is a no-op off Windows. Real Windows junctions are **NOT TESTED** there. A G04 PASS is not a byte attestation and is not a Windows PASS.

#150's guide already refuses drive-relative forms, `Get-ChildItem -Recurse`, and any claim that two hash passes are an atomic snapshot. Part 76's `git cat-file --batch` pipe-deadlock note stays a deferred docs patch on that guide. This PR does not edit it.

## 3. Threat model

The verifier exists to STOP a private off-game `Questie-335` copy when any of these are true: a file is missing, extra, renamed, or case-only renamed; a directory is missing or an unexpected directory is present, including an empty one; a file's byte count or unfiltered SHA-256 differs from the pinned TSV, including a CRLF conversion; an ancestor or a descendant is a symlink, junction, or other reparse point; a regular file has an NTFS hardlink alias, including one whose other name is outside the stage; the stage path is relative, drive-relative, rooted at the volume root, or contains raw `..`; the manifest is malformed or is not the pinned bytes; the folder is cloud-synced or changes during the scan; an OS call fails or a required proof is unavailable.

**Explicit non-guarantees.** There is no atomic snapshot. Two identical hash passes show only that those two reads matched. They do not protect against a hostile concurrent swapper who restores the old bytes between the reads, or who changes the tree after the process exits. `NtQueryDirectoryFile` documentation says a parallel directory change may or may not be visible during enumeration (**VERIFIED** as page text, **NOT TESTED** on Windows). A PASS, once this procedure has real evidence, would mean only that the named stage matched the pinned manifest under the stated reads.

Out of scope, all **NOT TESTED**: gameplay, SavedVariables, TOC load, rights clearance, backup and restore, the owner's PC, and any live `Interface\AddOns` or WTF tree. The procedure must not open those trees to decide that they are out of scope.

## 4. Acceptance contract (CS01 Part 75, items 1–6)

Pinned inputs stay `891a627318ac403d4da28655318286507f96c1aa` and TSV SHA-256 `73eccd4498a3a47db4c5d3fca60a83f7c35052174afcbafe350839b34fcb6b52`. The later implementation takes a manifest path and a required SHA-256. If the file bytes do not match the required pin, reason `manifest-pin`, and the stage is not opened. For an owner-stage run the required pin is the hash above. CI fixtures use their own invented pins so the job does not download addon bytes (section 8).

### Item 1 — two ordinal sets, then bytes

Compare two sets with `[System.StringComparer]::Ordinal`: the 557 relative file paths, and the 109 directories derived from their parent prefixes. Reject an unexpected empty directory in that same directory-set compare. Do both compares before any ordinary file's bytes are read. The four notice paths are ordinary members of the 557. Each must later match its TSV `bytes` and `sha256`. Presence-only is not acceptance. Expected hashes are the raw Git blob bytes. The implementation must not normalise CRLF and must not call `git hash-object` with or without filters. A CRLF Lua file is a hash mismatch and a correct STOP.

### Item 2 — ambiguous paths and reparse, before enter or read

Refuse, with no path normalisation and no open, a relative path, a drive-relative path (`C:..\x`, `C:Questie-335`), a raw `..` component, or a volume or UNC root used as the stage. The final component must be exactly `Questie-335`. Then open ancestors handle-by-handle (section 5). A reparse ancestor STOPs before the stage is entered. A reparse descendant STOPs before that child is entered or read. `Get-ChildItem -Recurse` is forbidden. A leaf-only no-follow flag on a full path is forbidden: `CreateFileW` `FILE_FLAG_OPEN_REPARSE_POINT` documents that it changes the final component only (**VERIFIED** as page text).

### Item 3 — hardlink aliases are a separate proof

A reparse check does not see a hardlink. On a volume already proven to be NTFS, a regular file whose `BY_HANDLE_FILE_INFORMATION.nNumberOfLinks` is not exactly 1 is STOP, before that file's bytes are read, and without opening the other name. The Microsoft structure page says FAT reports `nNumberOfLinks` as always 1, while NTFS can report more than 1 (**VERIFIED** as page text). A link-count of 1 on a non-NTFS volume is therefore not proof. `fsutil hardlink list` is a documentation pointer only (section 5). If the link-count proof cannot be made, reason `hardlink-unproven`, which is STOP, not PASS.

### Item 4 — quiescent, unsynced, off-game

Refuse a cloud-sync or OneDrive location, and refuse a stage that changes between the two reads. Do not open a live WoW, AddOns, WTF, or SQL path. Two matching reads are drift detection only (section 3). Owner-machine sync detection beyond "any reparse ancestor" is **UNKNOWN** (section 10).

### Item 5 — synthetic negatives

Section 7 is the inventory. Each negative that could point outside the fixture must STOP with `outside_reads` still 0. This design does not claim protection from an adversarial swapper.

### Item 6 — report, and evidence kept apart

Print a minimal report: `RESULT`, `reason`, `files_expected`, `files_seen`, `dirs_expected`, `dirs_seen`, `byte_mismatches`, `hash_mismatches`, `content_reads`, `outside_reads`. No absolute owner path, account name, manifest path, or file body. Mismatch counts are enough; do not print each digest. `outside_reads` must be 0. Evidence lines are separate and must not be collapsed into one PASS: `linux_synthetic`, `powershell_version`, `windows_ps51_ntfs`, `peer_review`, `gameplay`. Until section 8's evidence exists, `windows_ps51_ntfs` is `NOT TESTED` and `gameplay` is `NOT TESTED`. A fixture match must still print `windows_gate: STOP` until CS01 accepts a real Windows run. This PR prints nothing, because it runs nothing.

Reason tokens, one primary token per STOP: `manifest-pin`, `manifest-malformed`, `path-relative`, `path-drive-relative`, `path-dotdot`, `path-root`, `path-ambiguous`, `ancestor-reparse`, `child-reparse`, `hardlink`, `hardlink-unproven`, `filesystem-not-ntfs`, `set-mismatch`, `size-mismatch`, `hash-mismatch`, `drift`, `sync-location`, `access-denied`, `api-failed`, `interop-unproven`. A sample of the only shape this design allows:

```
RESULT: STOP
reason: child-reparse
files_expected: 557
files_seen: 12
dirs_expected: 109
dirs_seen: 4
byte_mismatches: 0
hash_mismatches: 0
content_reads: 0
outside_reads: 0
linux_synthetic: separate
powershell_version: NOT TESTED
windows_ps51_ntfs: NOT TESTED
peer_review: pending
gameplay: NOT TESTED
windows_gate: STOP
```

A later invented-fixture match uses `RESULT: PASS` and `reason: none`, and it still prints `windows_gate: STOP` and `gameplay: NOT TESTED`. The numbers above are an illustration of fields, not an observed run.

## 5. Candidate traversal

Candidate, research only. **NOT TESTED** on Windows. PS 5.1 P/Invoke is **UNVERIFIED**. If any step below cannot be validated on Windows PowerShell 5.1 and NTFS, the result is STOP. There is no fallback to `Get-ChildItem -Recurse` or to a path-based open.

**Documented** (pages fetched for this note):

- [`OBJECT_ATTRIBUTES`](https://learn.microsoft.com/en-us/windows/win32/api/ntdef/ns-ntdef-_object_attributes): `RootDirectory` makes `ObjectName` relative to an open directory handle. `OBJ_DONT_REPARSE` fails the parse with `STATUS_REPARSE_POINT_ENCOUNTERED` if a reparse point is encountered. `OBJ_CASE_INSENSITIVE` would request a case-insensitive match and must not be set.
- [`NtCreateFile`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntifs/nf-ntifs-ntcreatefile): open by full name, or by a name relative to `RootDirectory`. `FILE_OPEN_REPARSE_POINT` (0x00200000) opens a reparse point itself and skips normal reparse processing for that open. Without it, normal reparse processing runs. Disposition is open-existing only. No write, delete, overwrite, or supersede access.
- [`NtQueryDirectoryFile`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntifs/nf-ntifs-ntquerydirectoryfile): lists the directory represented by an existing handle. The page says parallel changes may or may not be visible. Wildcards are not used. The user-mode name is `NtQueryDirectoryFile`.
- [`GetFileInformationByHandle`](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getfileinformationbyhandle) fills [`BY_HANDLE_FILE_INFORMATION`](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/ns-fileapi-by_handle_file_information), including `nNumberOfLinks`. Failure, or a partial network result, is STOP. The stage must not be a network path anyway.
- [`CreateFileW`](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilew): `FILE_FLAG_OPEN_REPARSE_POINT` applies to the final component. That is why a single full-path `CreateFileW` is not the design.

**Walk.** Lexical checks from section 4 run first, with no open. Then, starting at the volume root, open one component at a time with `RootDirectory` set to the retained parent handle, `OBJ_DONT_REPARSE` set, and `OBJ_CASE_INSENSITIVE` clear. Retain each ordinary directory handle. Enumerate only that handle. For each immediate child, open that single component the same way, with `FILE_OPEN_REPARSE_POINT` as well, so a reparse child is not followed. Inspect type and reparse attribute before descent. An ordinary directory is retained and descended later. A regular file is link-checked on that same handle. Bytes are read from that retained handle only after both path sets match. A second read uses the retained handle again. The process never re-opens by path string.

**Order of one run.** Setup of fixtures is a different program. The verifier itself never creates, writes, deletes, or renames.

1. Read the manifest. Require the pinned SHA-256, the header, 557 rows when the owner pin is in force, LF only, and a parse of every `bytes` and `sha256` field. Derive the 109 directories in memory. Do not write them back. Any failure STOPs here, before the stage path is opened.
2. Refuse the stage string if it is relative, drive-relative, contains `..` or a trailing dot or space, uses a `:` stream (`name:stream`), or is a volume root. Require the final component `Questie-335` by ordinal compare. This step calls no filesystem API.
3. Open each ancestor, one component, retained handle, `OBJ_DONT_REPARSE`. A reparse result STOPs with `ancestor-reparse` and does not open the next component. Close every handle already held. The last component must be an ordinary directory. A file, or a reparse point, at that name is STOP. A path-based volume query is forbidden in this step: it can follow a junction before the chain is known.
4. From the retained stage-root handle, read the filesystem name. Anything other than the ordinal string `NTFS` is STOP `filesystem-not-ntfs`. The exact query API is **UNVERIFIED**. FAT must not reach the link-count rule, because that filesystem's documented `nNumberOfLinks` is always 1. If this query cannot be made, STOP `interop-unproven`.
5. Enumerate the retained stage directory. Ignore the `.` and `..` entries. They are not members of the 109. Any other name that contains `\`, `/`, `:`, or NUL is STOP `path-ambiguous`. Build the relative path with `/` from the components actually descended.
6. Open that child. If it is a reparse point, STOP `child-reparse` and do not descend, do not read bytes, and do not open the target. If the type cannot be classified as an ordinary directory or an ordinary file, STOP `api-failed`.
7. For an ordinary directory, retain the handle and repeat from step 5. For an ordinary file, call `GetFileInformationByHandle` on that handle. `nNumberOfLinks` must be exactly 1. Any other value is STOP `hardlink` with no byte read. A failed query is STOP `hardlink-unproven`.
8. After the walk, compare the two sets with `Ordinal`. A mismatch, including an empty extra directory or a case-only rename, is STOP `set-mismatch` with `content_reads` still 0. Close file handles without reading them.
9. Only if both sets match, read each retained file handle. Compare `nFileSizeHigh`/`nFileSizeLow` with the TSV size first (`size-mismatch`). Then read that many bytes and hash them. A short read or a digest mismatch is STOP. `content_reads` counts staged files only.
10. Rewind each retained handle and read again. A difference is STOP `drift`. Equal reads are still not an atomic snapshot (section 3). If the rewind fails, STOP `api-failed`.
11. On every exit, close every retained handle. A close error after a successful compare is STOP `api-failed`, not a quiet PASS.

Access requested for an open is read and list only: directory listing, read attributes, and, for a file that has reached step 9, read data. Share mode is read. No write, delete, overwrite, or `FILE_DELETE_ON_CLOSE`. **UNVERIFIED** from PS 5.1 whether those access masks are accepted on the runner. Denial is STOP `access-denied`.

**UNVERIFIED**, each one a STOP (`interop-unproven` or `api-failed`) if it fails: calling `ntdll` `NtCreateFile` / `NtQueryDirectoryFile` / `NtReadFile` via PS 5.1 `Add-Type`; structure layout and alignment for the process bitness; whether `OBJ_DONT_REPARSE` and `FILE_OPEN_REPARSE_POINT` together return a handle or `STATUS_REPARSE_POINT_ENCOUNTERED` on a reparse child (either result STOPs; which one is an open question); permissions; localised system text; behaviour on any filesystem other than NTFS; `FILE_OPEN_NO_RECALL` as an extra "do not hydrate a placeholder" flag. A directory's link count is not required to be 1. NTFS directories commonly report a count above 1 because of `.` and `..` links. That statement is **NOT TESTED** here. Applying `== 1` to directories would reject a normal tree, so the rule is specified for regular files only.

**Alternative hardlink proof.** `GetFileInformationByHandle` on the retained handle is the alternative to parsing `fsutil`. It is still **NOT TESTED** from PS 5.1. [`fsutil hardlink`](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-hardlink) documents `fsutil hardlink list` as a read-only enumeration. That is a pointer only. Its output is localised, so a parse is not proof. The create form is forbidden. If `fsutil` is ever run on a synthetic fixture, a non-zero exit or an unexpected line is STOP.

**Forbidden.** `Get-ChildItem -Recurse`. `Get-ChildItem` without `-Recurse` as the walker. `-FollowSymlink` (the #150 guide notes it arrived in PowerShell 6). `Resolve-Path`, `GetFullPath`, and any other normaliser before the lexical refuse. `Get-FileHash`, because it takes a path and would re-open; whether it follows reparse points is **UNVERIFIED** and does not matter, because it is not the hash step. The hash is SHA-256 over the bytes read from the retained handle (`System.Security.Cryptography.SHA256` is the candidate API, **NOT TESTED**).

## 6. PowerShell 5.1 pitfalls

**VERIFIED** as text on the [PS 5.1 comparison page](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comparison_operators?view=powershell-5.1): `-eq`, `-contains`, and `-in` are case-insensitive unless the `c` form is used. `-ceq` is case-sensitive and uses InvariantCulture, which is not the same statement as ordinal code-unit equality. Path sets therefore use `[System.StringComparer]::Ordinal`. A `Modules` versus `modules` difference must STOP. Do not store those paths in a PowerShell hashtable or a `HashSet` unless the constructor is given `[System.StringComparer]::Ordinal`. A default comparer is not accepted as proof. Whether a particular `HashSet` constructor is ordinal on PS 5.1 is **NOT TESTED**.

**Path strings.** Win32 often strips a trailing dot or space and expands an 8.3 short name. The manifest has neither (**VERIFIED**, section 1). The walker still has to use the name bytes returned by the directory query. A supplied 8.3 component, or a name that differs by a trailing dot or space, is STOP. Creating those names from PS 5.1 is **NOT TESTED**. If the fixture volume cannot create them, that case is `NOT TESTED` / STOP, not a skip into PASS.

**Alternate data streams.** The TSV hash covers the unnamed data stream only. A named stream is invisible to that hash. Stream enumeration is an extra check: any named stream is STOP. If the enumeration API cannot be validated, the report says `ADS: NOT TESTED` and `windows_ps51_ntfs` stays `NOT TESTED`. That gap must be printed. It must not be omitted so a default-stream match can be quoted as a clean PASS.

## 7. Synthetic fixture inventory

Build every fixture on a disposable tree of invented files. The later CI job uses a unique `RUNNER_TEMP` child (section 8). No row is built under WoW, AddOns, WTF, or a real owner profile. This PR does not build them. Every expected result below is **NOT TESTED** until a Windows PS 5.1 + NTFS run exists. "Outside" means bytes that are not the invented staged file being hashed.

The rows cover Part 74 item 3 and Part 75 item 5: the safe stage; relative, drive-relative, and raw `..`; linked ancestor; nested junction; directory symlink; file symlink; other linked file; external hardlink; unsupported or denied hardlink proof; empty extra directory; extra, missing, renamed, and case-only file; case-only directory; altered byte; CRLF Lua; unknown notice; mutation during the scan; sync location; malformed manifest; inaccessible file and failed API. Volume root is included because Part 75 item 2 refuses it.

| Case | Disposable build | Expected | Outside content |
| --- | --- | --- | --- |
| Safe off-game stage | Ordinary NTFS directory, final name `Questie-335`, invented files matching an invented manifest, link count 1, no reparse, tree left unchanged | Fixture `PASS`, and `windows_gate` still `STOP` until CS01 accepts the run | Staged bytes only |
| Relative path | Pass `Questie-335` or `.\Questie-335` | STOP `path-relative` | No open |
| Drive-relative | Pass `C:..\x` and `C:Questie-335` | STOP `path-drive-relative` | No open |
| Raw `..` | A component is `..`, including a form that would lexically stay inside | STOP `path-dotdot` | No open |
| Volume root | Pass the drive root as the stage | STOP `path-root` | No stage listing |
| Linked ancestor | Parent of the stage is a junction or symlink; target holds a canary | STOP `ancestor-reparse` | Canary unread |
| Nested directory junction | Ordinary parent, child directory is a junction to an outside canary | STOP `child-reparse` before descent | Canary unread |
| Directory symlink | Child directory is a symlink | STOP `child-reparse` before descent | Target unread |
| File symlink | Child file is a symlink to an outside canary | STOP `child-reparse` | Canary unread |
| Linked file | Child file has a reparse attribute and is not a directory | STOP `child-reparse` | Target unread |
| External hardlink | Staged file's other NTFS name is outside; link count greater than 1 | STOP `hardlink` before hashing | Other name unopened |
| Unsupported or no-access hardlink check | Volume is not NTFS, or the link-count query fails or is denied | STOP `hardlink-unproven` or `filesystem-not-ntfs` | No byte read |
| Unexpected empty directory | Extra empty directory beside an otherwise matching tree | STOP `set-mismatch` | No file bytes |
| Extra file | One invented extra file | STOP `set-mismatch` | No file bytes |
| Missing file | One manifest path absent | STOP `set-mismatch` | No file bytes |
| Renamed file | One path replaced by a different spelling | STOP `set-mismatch` | No file bytes |
| Case-only renamed file | `Questie.lua` stored as `questie.lua` | STOP `set-mismatch` | No file bytes |
| Case-only renamed directory | `Modules` stored as `modules` | STOP `set-mismatch` | No file bytes |
| Altered byte | One staged byte flipped; sets still match | STOP `hash-mismatch` | That staged file only |
| CRLF-converted Lua | LF bytes stored with CRLF; no conversion step exists | STOP `hash-mismatch` | That staged file only |
| Unknown notice | Extra `LICENSE` or `NOTICE` path that is not one of the four | STOP `set-mismatch` | No file bytes |
| Stage changes during the scan | Writer flips a byte between the two retained-handle reads | STOP `drift` | Staged bytes only; not an atomicity claim |
| OneDrive or other sync location | Ancestor is a reparse stand-in for a cloud placeholder. A real OneDrive folder is not used | STOP `ancestor-reparse` or `sync-location` | No placeholder hydrate, no outside read |
| Malformed manifest | Wrong pin, column count, row count, duplicate, CR, `\`, `..`, or non-hex digest | STOP `manifest-pin` or `manifest-malformed` | Stage not opened |
| Inaccessible file or failed OS API | ACL denies a child, or the native call returns an error | STOP `access-denied` or `api-failed` | No outside read; do not continue into PASS |

If the runner cannot create a junction, symlink, or hardlink, that row is reported `NOT TESTED` / STOP. It is not skipped. A small invented manifest (proposal: 2 files and 1 directory, plus these mutations) runs before a second invented fixture with 557 files and 109 directories. The large fixture uses invented bytes and invented hashes. It exists to exercise count and set logic. It is not a copy of the addon and it is not an owner-stage PASS.

## 8. Evidence plan

Categories stay separate. None of the later ones is implied by an earlier one.

| Category | What can move it | This PR |
| --- | --- | --- |
| Linux synthetic | Set math, TSV shape, #149 G04 on Linux, CS01's 20/20 in-memory probes in Part 77 | TSV re-derivation in section 1 is **VERIFIED**. No new Linux fixture was executed for this note |
| PowerShell version | A job prints `$PSVersionTable.PSEdition` and `PSVersion` | **NOT TESTED** |
| Windows PS 5.1 + NTFS | That same job is `Desktop` 5.1, on NTFS, and runs section 7 | **NOT TESTED**. Linux `pwsh` 7, this document, and Git tests cannot change this cell |
| Peer review | CS01 reviews the exact head | Not started |
| Gameplay | A later owner decision, outside this design | **NOT TESTED** |

CS01 comment `6299053766` approves the principle of a later, separate, guarded DRAFT workflow PR. That approval is not an approval of code, not a merge, and not this PR. This PR does not add a workflow. The fixture PR is written only after CS01 reviews this note. Its seven hard requirements, mapped one to one:

1. Base frozen #148 `891a627318ac403d4da28655318286507f96c1aa`, never `335`. Leave #148, #149, and #150 unchanged. No merge, tag, release, installer, or ZIP.
2. Print generic host facts and STOP before any claim unless `$PSVersionTable.PSEdition` is `Desktop`, the version is 5.1, and the fixture drive's filesystem is NTFS. Run `shell: powershell` and `powershell.exe`, not `pwsh`. The runner label is the explicit `windows-2025` label, not floating `windows-latest`.
3. `permissions: contents: read`. Trigger: `pull_request` only. No tag push, `workflow_dispatch`, `pull_request_target`, or `workflow_run`. No secrets, network downloads, caches, artifacts, or uploads.
4. Invented names only, under a unique `RUNNER_TEMP` child. Real junction, hardlink, and symlink rows that the runner cannot create are `NOT TESTED` / STOP, never a silent skip.
5. The verifier is read-only. Fixture setup is the only write phase. Small invented fixture first, then a 557-file / 109-directory invented fixture. Outside-scratch canaries must stay unread.
6. If `OBJ_DONT_REPARSE` or `NtCreateFile` interop fails, STOP. Do not fall back to path-based `Get-ChildItem -Recurse`. Repeated hashes are not atomic proof.
7. CS01 reviews the exact SHA, the full diff, step conclusions, pass/fail/`NOT TESTED` counts, the host facts, and zero artifacts per run. A green hosted runner does not validate the owner's PC, backups, WoW load, rights, or real staging.

**Part 80 (`6299839567`), checked again at this parent.** **VERIFIED** at `891a6273`: `.github/workflows/ci.yml` blob `6c4393fdb18c101e377ff4c41c128551ee617685` has `push: tags: "*"` and a `publish` job with `if: startsWith(github.ref, 'refs/tags/v')`, which runs `python build.py -r`, `gh release create`, and CurseForge/WAGO uploads. Overlay Assemble and Upload are `if: ${{ false }}` in `nquestie-overlay.yml` and do not gate that publish job. Part 80 reports the same `ci.yml` blob at `335`, #149, and #150; those three refs were not re-fetched for this sentence. This design PR must not create or push any tag, `v*` especially, must not edit `ci.yml` or its publish gate, and must be re-checked so the diff contains no `build.py -r`, `gh release`, `upload-*`, or a new trigger. The only intended path is this file.

**Part 79** is source-name syntax evidence only (section 1). It is not NTFS evidence.

## 9. What would still be true after a green fixture run

A future CI job can move only the `powershell_version` and `windows_ps51_ntfs` cells, and only for the invented fixtures it actually ran. It does not move `gameplay`. It does not clear rights, backups, or the owner PC. It does not authorise copying the stage into `Interface\AddOns`. Linux synthetic evidence stays in its own cell even if the same set math passed on Windows. Peer review stays in its own cell until CS01 says the exact head was reviewed. Part 74's rule stands: if the platform execution is missing, Windows remains STOP, and the owner is not handed a script to try.

The diff of this PR is this file alone. Before push, the author re-checks that the commit does not touch `.github/workflows/`, does not add a script, and does not contain a tag. Reviewers repeat that check. `ci.yml`'s publish job remains the pre-existing tag gate described in section 8.

## 10. Open questions for CS01

1. Confirm `nNumberOfLinks == 1` applies only to regular files, so a normal NTFS directory link count does not STOP the tree.
2. On a single-component child open, do you want `OBJ_DONT_REPARSE` and `FILE_OPEN_REPARSE_POINT` together, accepting `STATUS_REPARSE_POINT_ENCOUNTERED` as the STOP, or `FILE_OPEN_REPARSE_POINT` alone so the tag can be read while `OBJ_DONT_REPARSE` stays on multi-component parses? Both fail closed.
3. Confirm an unvalidated ADS enumeration blocks `windows_ps51_ntfs` rather than being an accepted gap beside a default-stream match.
4. Which sync-root signals should STOP when the ancestor is not a reparse point, without putting owner paths in git?
5. Is the second full-content read mandatory on every run, given section 3's limit?
6. Is an invented 2-file / 1-directory fixture the right minimum before the 557 / 109 invented shape?
7. Should the later CI PR vendor a byte-for-byte copy of the pinned TSV, or only invented manifests plus a required-pin parameter? This note assumes the second, because a network fetch of the TSV is forbidden.
8. Should an unknown notice use a distinct reason code, or the `set-mismatch` code in section 7?
9. Part 76's streaming `git cat-file --batch` example is still deferred until this design is reviewed. Confirm that order.
