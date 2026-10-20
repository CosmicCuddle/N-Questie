# N-Questie 3.3.5a — Windows PowerShell 5.1 / NTFS read-only stage verifier (design)

**Status: DESIGN ONLY. Windows verification is STOP / NOT TESTED.** No owner action. This note is not an installer, not a script, and not a live WoW, AddOns, WTF, SQL, or server procedure. It builds no ZIP and creates no release. Nothing here is a Windows PASS.

CS02 Workstream 3, 20 October 2026. Parent commit `891a627318ac403d4da28655318286507f96c1aa` (frozen draft #148). This PR adds this file only. It does not modify #148, #149, or #150. CS01 reviewed `0253916d3b5d429cb70f26ad510665fcf57d7674` and requested two docs clarifications (comment `6302293994`). This revision records those two points and the nine section 10 answers. Windows PS 5.1 / NTFS remains **STOP / NOT TESTED**.

Labels: **VERIFIED** (re-derived here, or read from a named Git object or a page fetched for this note), **POTENTIAL ISSUE**, **UNKNOWN**, **NOT TESTED**. Where this note says **UNVERIFIED**, it means the Microsoft page exists and the Windows PowerShell 5.1 behaviour is still **UNKNOWN**. Documentation text is not Windows execution.

## 1. What was re-derived

**VERIFIED** (Linux, off-game, this note): the bytes of `docs/NQ-335-STAGE-EXPECTED-MANIFEST-891a6273.tsv` were fetched from draft #150 head `610a76765bca957223004f3a95221de456f13bd3`. SHA-256 `73eccd4498a3a47db4c5d3fca60a83f7c35052174afcbafe350839b34fcb6b52`, 84,728 bytes, Git blob `474c3efbfb61da7c5e4e011726686edac53f700f`. Header `path	bytes	git_blob	sha256`, then 557 data rows, LF, no CR. Those bytes are not copied into this branch. Do not regenerate the TSV to add directory rows.

**VERIFIED** from those 557 `path` values. The directory set is every proper prefix: for `Modules/Quest/QuestEventHandler.lua` the prefixes are `Modules` and `Modules/Quest`. Counted that way, the TSV implies exactly 109 directories (89 leaf, 20 non-leaf), maximum depth 4, and 13 directories with exactly one descendant file. A leaf directory has no other directory name under it. Case-folding the 557 file paths and the 109 directory paths, with a second check of each final component against its parent, finds 0 file collisions and 0 directory collisions. Top-level split: 3 root files (`embeds.xml`, `Questie-335.toc`, `Questie.lua`) / Compat 64 / Database 57 / Icons 53 / Libs 102 / Localization 168 / Modules 110. Longest relative file path is 67 characters (`Compat/Libs/AceGUI-3.0/widgets/AceGUIContainer-BlizOptionsGroup.lua`). Longest relative directory is 42 characters (`Localization/lookups/Classic/lookupObjects`). The same bytes contain no non-ASCII, no control bytes other than TAB and LF, no `<>:"\|?*`, no reserved DOS device basenames (`CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9`, `LPT1`–`LPT9`, including an extension), no empty / `.` / `..` components, and no trailing dot or space. That agrees with CS01 Part 79 (`6299431420`) and is source-name syntax only. Owner path length, long-path policy, and case retention are **NOT TESTED**. On a legacy ~260-character absolute limit, a long stage root can still fail. An OS path-length error is STOP `api-failed`. Do not turn on a long-path prefix to force a PASS.

The four notice paths named in #150's guide are rows in that TSV, and this note re-checked that they are present: `Icons/LICENSE.md`, `Icons/MIT.txt`, `Libs/LICENSE.txt`, `Libs/Krowi_WorldMapButtons/LICENSE.md`.

## 2. Neighbour work this design does not change

**VERIFIED** by reading #149 head `6922180c3a5a0a5559098766360226cbabc3d583`: `tools/check_nq_335_local_stage.py` is a read-only structural checker. It rejects a raw `..` component before `os.path.abspath`, walks the lexical ancestor chain, inventories with `os.scandir` and `follow_symlinks=False`, and skips TOC, XML, Lua, and texture reads after a layout failure. Notice handling there is presence of three paths, plus the Krowi notice when that directory is present. It does not hash the 557 files against the TSV and it does not read NTFS link counts. Its `FILE_ATTRIBUTE_REPARSE_POINT` check is a no-op off Windows. Real Windows junctions are **NOT TESTED** there. A G04 PASS is not a byte attestation and is not a Windows PASS.

#150's guide already refuses drive-relative forms, `Get-ChildItem -Recurse`, and any claim that two hash passes are an atomic snapshot. Part 76's `git cat-file --batch` pipe-deadlock note stays a deferred docs patch on that guide. CS01 confirmed that deferral until this design review closes (section 10). This PR does not edit #150, the accepted TSV, or older drafts.

## 3. Threat model

The verifier exists to STOP a private off-game `Questie-335` copy when any of these are true: a file is missing, extra, renamed, or case-only renamed; a directory is missing or an unexpected directory is present, including an empty one; a file's byte count or unfiltered SHA-256 differs from the pinned TSV, including a CRLF conversion; an ancestor or a descendant is a symlink, junction, or other reparse point; a regular file has an NTFS hardlink alias, including one whose other name is outside the stage; the stage path is relative, drive-relative, rooted at the volume root, or contains raw `..`; the manifest is malformed or is not the pinned bytes; the folder is cloud-synced or changes during the scan; an OS call fails or a required proof is unavailable.

**Explicit non-guarantees.** There is no atomic snapshot. Two identical hash passes show only that those two reads matched. They do not protect against a hostile concurrent swapper who restores the old bytes between the reads, or who changes the tree after the process exits. `NtQueryDirectoryFile` documentation says a parallel directory change may or may not be visible during enumeration (**VERIFIED** as page text, **NOT TESTED** on Windows). A PASS, once this procedure has real evidence, would mean only that the named stage matched the pinned manifest under the stated reads.

Out of scope, all **NOT TESTED**: gameplay, SavedVariables, TOC load, rights clearance, backup and restore, the owner's PC, and any live `Interface\AddOns` or WTF tree. The procedure must not open those trees to decide that they are out of scope.

## 4. Acceptance contract (CS01 Part 75, items 1–6)

Pinned inputs stay `891a627318ac403d4da28655318286507f96c1aa` and TSV SHA-256 `73eccd4498a3a47db4c5d3fca60a83f7c35052174afcbafe350839b34fcb6b52`. The later implementation takes a manifest path and a required SHA-256. If the file bytes do not match the required pin, reason `manifest-pin`, and the stage is not opened. For an owner-stage run the required pin is the hash above. CI fixtures use their own invented pins so the job does not download addon bytes (section 8).

### Item 1 — two ordinal sets, then bytes

Compare two sets with `[System.StringComparer]::Ordinal`: the 557 relative file paths, and the 109 directories derived from their parent prefixes. Reject an unexpected empty directory in that same directory-set compare. Do both compares before any ordinary file's bytes are read. The four notice paths are ordinary members of the 557. Each must later match its TSV `bytes` and `sha256`. Presence-only is not acceptance. Expected hashes are the raw Git blob bytes. The implementation must not normalise CRLF and must not call `git hash-object` with or without filters. A CRLF Lua file is a hash mismatch and a correct STOP.

### Item 2 — ambiguous paths and reparse, before enter or read

Refuse, with no path normalisation and no open, a relative path, a drive-relative path (`C:..\x`, `C:Questie-335`), a raw `..` component, or a volume or UNC root used as the stage. The final component must be exactly `Questie-335`. Then open ancestors handle-by-handle (section 5). Leaving `OBJ_CASE_INSENSITIVE` unset does not prove the on-disk spelling of the stage root or of any ancestor. Each requested ancestor and the final `Questie-335` component need a reviewed handle-based actual-name check, or an independently tested equivalent, covering case, 8.3 short-name aliases, and a trailing dot or space. If that spelling cannot be proven, STOP `path-ambiguous` or `interop-unproven`. Descendant file and directory sets stay ordinal compares (item 1). File bodies are not re-opened by pathname. A reparse ancestor STOPs before the stage is entered. A reparse descendant STOPs before that child is entered or read. `Get-ChildItem -Recurse` is forbidden. A leaf-only no-follow flag on a full path is forbidden: `CreateFileW` `FILE_FLAG_OPEN_REPARSE_POINT` documents that it changes the final component only (**VERIFIED** as page text).

### Item 3 — hardlink aliases are a separate proof

A reparse check does not see a hardlink. On a volume already proven to be NTFS, a regular file whose `BY_HANDLE_FILE_INFORMATION.nNumberOfLinks` is not exactly 1 is STOP, before that file's bytes are read, and without opening the other name. The Microsoft structure page says FAT reports `nNumberOfLinks` as always 1, while NTFS can report more than 1 (**VERIFIED** as page text). A link-count of 1 on a non-NTFS volume is therefore not proof. `fsutil hardlink list` is a documentation pointer only (section 5). If the link-count proof cannot be made, reason `hardlink-unproven`, which is STOP, not PASS.

### Item 4 — quiescent, unsynced, off-game

There is no unproven automatic sync detector. A path containing the string `OneDrive`, or a path without that string, is not proof of sync and is not proof of its absence. Reparse, cloud-recall, and offline indicators STOP when those queries are supported (**NOT TESTED**). A future off-game location still needs an external unsynced and quiescent precondition. Unknown sync detection keeps any owner Windows GO at STOP. A sharing denial during the scan is STOP `access-denied` or `api-failed`. `drift` applies only when a byte change actually occurs and is observed (sections 5 and 7). Do not open a live WoW, AddOns, WTF, or SQL path. Two matching reads are diagnostic only (section 3). They are not an atomic snapshot.

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

- [`OBJECT_ATTRIBUTES`](https://learn.microsoft.com/en-us/windows/win32/api/ntdef/ns-ntdef-_object_attributes): `RootDirectory` makes `ObjectName` relative to an open directory handle. `OBJ_DONT_REPARSE` fails the parse with `STATUS_REPARSE_POINT_ENCOUNTERED` if a reparse point is encountered. `OBJ_CASE_INSENSITIVE` would request a case-insensitive match and must not be set. Leaving it unset does not prove the on-disk spelling of an opened ancestor or of the stage root.
- [`NtCreateFile`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntifs/nf-ntifs-ntcreatefile): open by full name, or by a name relative to `RootDirectory`. `FILE_OPEN_REPARSE_POINT` (0x00200000) opens a reparse point itself and skips normal reparse processing for that open. Without it, normal reparse processing runs. Disposition is open-existing only. No write, delete, overwrite, or supersede access.
- [`NtQueryDirectoryFile`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntifs/nf-ntifs-ntquerydirectoryfile): lists the directory represented by an existing handle. The page says parallel changes may or may not be visible. Wildcards are not used. The user-mode name is `NtQueryDirectoryFile`.
- [`GetFileInformationByHandle`](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getfileinformationbyhandle) fills [`BY_HANDLE_FILE_INFORMATION`](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/ns-fileapi-by_handle_file_information), including `nNumberOfLinks`. Failure, or a partial network result, is STOP. The stage must not be a network path anyway.
- [`CreateFileW`](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilew): `FILE_FLAG_OPEN_REPARSE_POINT` applies to the final component. That is why a single full-path `CreateFileW` is not the design.

**Walk.** Lexical checks from section 4 run first, with no open. Then, starting at the volume root, open one component at a time with `RootDirectory` set to the retained parent handle, `OBJ_DONT_REPARSE` set, and `OBJ_CASE_INSENSITIVE` clear. Retain each ordinary directory handle. After each ancestor open, and for the final `Questie-335` component, read that component's actual name from the retained handle or from the parent handle's directory entry (step 3). Enumerate only a retained handle. For each immediate child, open that single component the same way, with `FILE_OPEN_REPARSE_POINT` as well, so a reparse child is not followed. Inspect type and reparse attribute before descent. An ordinary directory is retained and descended later. A regular file is link-checked on that same handle. Bytes are read from that retained handle only after both path sets match. A second read uses the retained handle again. The process never re-opens a file body by pathname. Descendant path sets stay `[System.StringComparer]::Ordinal`.

**Order of one run.** Setup of fixtures is a different program. The verifier itself never creates, writes, deletes, or renames.

1. Read the manifest. Require the pinned SHA-256, the header, 557 rows when the owner pin is in force, LF only, and a parse of every `bytes` and `sha256` field. Derive the 109 directories in memory. Do not write them back. Any failure STOPs here, before the stage path is opened.
2. Refuse the stage string if it is relative, drive-relative, contains `..` or a trailing dot or space, uses a `:` stream (`name:stream`), or is a volume root. Require the final component `Questie-335` by ordinal compare. This step calls no filesystem API. It does not prove the on-disk spelling of any ancestor or of the stage root.
3. Open each ancestor, one component, retained handle, `OBJ_DONT_REPARSE`, `OBJ_CASE_INSENSITIVE` clear. After each open, require a reviewed handle-based actual-name check of that component, or an independently tested equivalent. Apply the same check to the final `Questie-335` component. Ordinal-compare the actual name with the requested component. A case-only difference, an 8.3 short-name alias, or a trailing dot or space is STOP `path-ambiguous`. If the actual name cannot be read, STOP `interop-unproven` and do not open the next component. Do not re-open the object by pathname to learn the spelling. The query itself is **UNVERIFIED** and **NOT TESTED**. A reparse result STOPs with `ancestor-reparse` and does not open the next component. Close every handle already held. The last component must be an ordinary directory whose actual name is exactly `Questie-335`. A file, or a reparse point, at that name is STOP. A path-based volume query is forbidden in this step: it can follow a junction before the chain is known.
4. From the retained stage-root handle, read the filesystem name. Anything other than the ordinal string `NTFS` is STOP `filesystem-not-ntfs`. The exact query API is **UNVERIFIED**. FAT must not reach the link-count rule, because that filesystem's documented `nNumberOfLinks` is always 1. If this query cannot be made, STOP `interop-unproven`.
5. Enumerate the retained stage directory. Ignore the `.` and `..` entries. They are not members of the 109. Any other name that contains `\`, `/`, `:`, or NUL is STOP `path-ambiguous`. Build the relative path with `/` from the components actually descended.
6. Open that child. If it is a reparse point, STOP `child-reparse` and do not descend, do not read bytes, and do not open the target. If the type cannot be classified as an ordinary directory or an ordinary file, STOP `api-failed`.
7. For an ordinary directory, retain the handle and repeat from step 5. For an ordinary file, call `GetFileInformationByHandle` on that handle. `nNumberOfLinks` must be exactly 1. The rule is for regular files only (section 10). Any other value is STOP `hardlink` with no byte read. A failed query is STOP `hardlink-unproven`. Validate the count on an actual NTFS synthetic fixture before any platform claim. That validation is **NOT TESTED**.
8. After the walk, compare the two sets with `Ordinal`. A mismatch, including an empty extra directory or a case-only rename, is STOP `set-mismatch` with `content_reads` still 0. Close file handles without reading them.
9. Only if both sets match, read each retained file handle. Compare `nFileSizeHigh`/`nFileSizeLow` with the TSV size first (`size-mismatch`). Then read that many bytes and hash them. A short read or a digest mismatch is STOP. `content_reads` counts staged files only.
10. Rewind each retained handle and read again. This second full-content read is diagnostic only. It does not establish an atomic snapshot (section 3) and it does not override a share conflict. `drift` is used only when a byte change actually occurs and is observed. A sharing denial is not `drift`. There is no promise to detect an arbitrarily timed swap. If the rewind fails, STOP `api-failed`.
11. On every exit, close every retained handle. A close error after a successful compare is STOP `api-failed`, not a quiet PASS.

Access requested for an open is read and list only: directory listing, read attributes, and, for a file that has reached step 9, read data. Share mode is `FILE_SHARE_READ` only. `FILE_SHARE_WRITE` is not requested. No write, delete, overwrite, or `FILE_DELETE_ON_CLOSE`. A concurrent writer may be denied, or the verifier's open may fail with a sharing violation. Either outcome is fail-closed STOP `access-denied` or `api-failed`. Do not add `FILE_SHARE_WRITE` so a synthetic test can pass. A test that alters sharing only inside a fake implementation is logical-only and never counts as proof of this production handle policy. **UNVERIFIED** from PS 5.1 whether those access masks are accepted on the runner. Denial is STOP `access-denied`. If a concurrent-mutation fixture cannot be created under this share policy, that row is `NOT TESTED` (section 7).

**UNVERIFIED**, each one a STOP (`interop-unproven` or `api-failed`) if it fails: calling `ntdll` `NtCreateFile` / `NtQueryDirectoryFile` / `NtReadFile` via PS 5.1 `Add-Type`; structure layout and alignment for the process bitness; the handle-based actual-name query in step 3; permissions; localised system text; behaviour on any filesystem other than NTFS; `FILE_OPEN_NO_RECALL` as an extra "do not hydrate a placeholder" flag. For the one-component child candidate, CS01 prefers `OBJ_DONT_REPARSE` together with `FILE_OPEN_REPARSE_POINT` (section 10). Either `STATUS_REPARSE_POINT_ENCOUNTERED` or an opened reparse-point-itself handle is a STOP, and only if a synthetic run proves the target was not entered or read. If that combination is unsupported, STOP and revisit the design with evidence. Do not drop either flag to obtain a pass. Which of the two STOP results Windows returns is **NOT TESTED**. A directory's link count is not required to be 1. NTFS directories commonly report a count above 1 because of `.` and `..` links. That statement is **NOT TESTED** here. Applying `== 1` to directories would reject a normal tree, so the rule is specified for regular files only.

**Alternative hardlink proof.** `GetFileInformationByHandle` on the retained handle is the alternative to parsing `fsutil`. It is still **NOT TESTED** from PS 5.1. [`fsutil hardlink`](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-hardlink) documents `fsutil hardlink list` as a read-only enumeration. That is a pointer only. Its output is localised, so a parse is not proof. The create form is forbidden. If `fsutil` is ever run on a synthetic fixture, a non-zero exit or an unexpected line is STOP.

**Forbidden.** `Get-ChildItem -Recurse`. `Get-ChildItem` without `-Recurse` as the walker. `-FollowSymlink` (the #150 guide notes it arrived in PowerShell 6). `Resolve-Path`, `GetFullPath`, and any other normaliser before the lexical refuse. `Get-FileHash`, because it takes a path and would re-open; whether it follows reparse points is **UNVERIFIED** and does not matter, because it is not the hash step. The hash is SHA-256 over the bytes read from the retained handle (`System.Security.Cryptography.SHA256` is the candidate API, **NOT TESTED**).

## 6. PowerShell 5.1 pitfalls

**VERIFIED** as text on the [PS 5.1 comparison page](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comparison_operators?view=powershell-5.1): `-eq`, `-contains`, and `-in` are case-insensitive unless the `c` form is used. `-ceq` is case-sensitive and uses InvariantCulture, which is not the same statement as ordinal code-unit equality. Path sets therefore use `[System.StringComparer]::Ordinal`. A `Modules` versus `modules` difference must STOP. Do not store those paths in a PowerShell hashtable or a `HashSet` unless the constructor is given `[System.StringComparer]::Ordinal`. A default comparer is not accepted as proof. Whether a particular `HashSet` constructor is ordinal on PS 5.1 is **NOT TESTED**.

**Path strings.** Win32 often strips a trailing dot or space and expands an 8.3 short name. The manifest has neither (**VERIFIED**, section 1). The walker uses the name bytes returned by the directory query for descendants. The same actual-name proof is required for every requested ancestor and for the final stage-root component `Questie-335` (section 5, step 3). An unset `OBJ_CASE_INSENSITIVE` flag is not that proof. A mis-cased stage root (`questie-335` where `Questie-335` is required), an 8.3 alias of the stage root or of an ancestor, or a name that differs by a trailing dot or space, is STOP `path-ambiguous`. If the actual name cannot be read, STOP `interop-unproven`. Creating those names from PS 5.1 is **NOT TESTED**. If the fixture volume cannot create them, that case is `NOT TESTED` / STOP, not a skip into PASS. Case-sensitive ordinal sets stay in force. File bodies are not re-opened by pathname.

**Alternate data streams.** The TSV hash covers the unnamed data stream only. A named stream is invisible to that hash. Extra named streams are STOP. Named streams on regular files are in scope. Named streams on directories are in scope as well: a directory stream reported by the same check is STOP. The candidate is a retained-handle call, `GetFileInformationByHandleEx` with `FileStreamInfo`, named by CS01 and **NOT TESTED** on files and on directories. If that call cannot be validated, including if it cannot be shown to enumerate directory streams, the report says `ADS: NOT TESTED` and `windows_ps51_ntfs` stays `NOT TESTED`. That gap must be printed. A default-stream match is not a clean PASS. A call that returns no stream is not proof that directory streams are absent until the call has been executed on NTFS.

## 7. Synthetic fixture inventory

Build every fixture on a disposable tree of invented files. The later CI job uses a unique `RUNNER_TEMP` child (section 8). No row is built under WoW, AddOns, WTF, or a real owner profile. This PR does not build them. Every expected result below is **NOT TESTED** until a Windows PS 5.1 + NTFS run exists. "Outside" means bytes that are not the invented staged file being hashed.

The rows cover Part 74 item 3 and Part 75 item 5: the safe stage; relative, drive-relative, and raw `..`; linked ancestor; nested junction; directory symlink; file symlink; other linked file; external hardlink; unsupported or denied hardlink proof; empty extra directory; extra, missing, renamed, and case-only file; case-only directory; mis-cased stage root; 8.3 alias; altered byte; CRLF Lua; unknown notice; named streams; share conflict during the scan; sync location; malformed manifest; inaccessible file and failed API. Volume root is included because Part 75 item 2 refuses it. Under production sharing (`FILE_SHARE_READ` only, no `FILE_SHARE_WRITE`), a concurrent writer may be denied or the verifier open may fail. That row records `drift` only for a byte change that is actually observed.

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
| Mis-cased stage root | On-disk final directory is `questie-335`; required spelling is `Questie-335`. `OBJ_CASE_INSENSITIVE` stays clear. The input string may already be the required spelling | STOP `path-ambiguous`. If the actual-name check cannot be made, STOP `interop-unproven` | No file-body re-open by pathname |
| 8.3 alias | An ancestor or the stage root is addressed by an 8.3 short-name alias, or the actual name is a short name. Trailing dot or space is the same class of failure | STOP `path-ambiguous`. If the alias cannot be created, or the actual-name check cannot be made, `NOT TESTED` / STOP `interop-unproven` | No file-body re-open by pathname |
| Altered byte | One staged byte flipped; sets still match | STOP `hash-mismatch` | That staged file only |
| CRLF-converted Lua | LF bytes stored with CRLF; no conversion step exists | STOP `hash-mismatch` | That staged file only |
| Unknown notice | Extra `LICENSE` or `NOTICE` path that is not one of the four | STOP `set-mismatch`. No new reason token | No file bytes |
| Named stream | Extra named stream on a regular file or on a directory, and a planted stream the check does not report | Extra stream: STOP. Unobserved planted stream, or enumeration not validated, including directory streams: `ADS: NOT TESTED`, and `windows_ps51_ntfs` stays `NOT TESTED` | Default-stream bytes are not a clean PASS |
| Share conflict during the scan | Production opens use `FILE_SHARE_READ` only, with no `FILE_SHARE_WRITE`. A concurrent writer may be denied, or the verifier open may fail with a sharing violation | Denied writer or denied open: STOP `access-denied` or `api-failed`. Observed byte change on the retained handle: STOP `drift`. If a concurrent mutation cannot be created under this share policy: `NOT TESTED`. A fake implementation that widens sharing is logical-only and is not proof of the production handle policy. No promise to detect an arbitrarily timed swap | Staged bytes only; not an atomicity claim |
| OneDrive or other sync location | Supported reparse, cloud-recall, or offline indicator, using a disposable stand-in. A path string containing `OneDrive` is not the test and is not proof. A real OneDrive folder is not used | STOP `ancestor-reparse` or `sync-location` when the indicator query is supported. No unproven automatic detector. Unknown detection keeps the owner Windows GO at STOP | No placeholder hydrate, no outside read |
| Malformed manifest | Wrong pin, column count, row count, duplicate, CR, `\`, `..`, or non-hex digest | STOP `manifest-pin` or `manifest-malformed` | Stage not opened |
| Inaccessible file or failed OS API | ACL denies a child, or the native call returns an error | STOP `access-denied` or `api-failed` | No outside read; do not continue into PASS |

If the runner cannot create a junction, symlink, hardlink, 8.3 alias, trailing-dot name, or a concurrent mutation under `FILE_SHARE_READ` without `FILE_SHARE_WRITE`, that row is reported `NOT TESTED` / STOP. It is not skipped, and sharing is not widened to make it pass. A small invented manifest (2 files and 1 directory, plus these mutations) runs before a second invented fixture with 557 files and 109 directories. Both include missing and extra named streams, a case-only stage root, an 8.3 alias, and share-conflict outcomes. The large fixture uses invented bytes and invented hashes. It exercises count and set logic. It is not a copy of the addon, not a copy of the real TSV, and not an owner-stage PASS.

## 8. Evidence plan

Categories stay separate. None of the later ones is implied by an earlier one.

| Category | What can move it | This PR |
| --- | --- | --- |
| Linux synthetic | Set math, TSV shape, #149 G04 on Linux, CS01's 20/20 in-memory probes in Part 77 | TSV re-derivation in section 1 is **VERIFIED**. No new Linux fixture was executed for this note |
| PowerShell version | A job prints `$PSVersionTable.PSEdition` and `PSVersion` | **NOT TESTED** |
| Windows PS 5.1 + NTFS | That same job is `Desktop` 5.1, on NTFS, and runs section 7 | **NOT TESTED**. Linux `pwsh` 7, this document, and Git tests cannot change this cell |
| Peer review | CS01 reviews the exact head | CS01 reviewed `0253916d3b5d429cb70f26ad510665fcf57d7674` and requested changes (comment `6302293994`). This revision is pending re-review. Not a Windows PASS |
| Gameplay | A later owner decision, outside this design | **NOT TESTED** |

CS01 comment `6299053766` approves the principle of a later, separate, guarded DRAFT workflow PR. That approval is not an approval of code, not a merge, and not this PR. This PR does not add a workflow. The fixture PR is written only after CS01 reviews this note. Its seven hard requirements, mapped one to one:

1. Base frozen #148 `891a627318ac403d4da28655318286507f96c1aa`, never `335`. Leave #148, #149, and #150 unchanged. No merge, tag, release, installer, or ZIP.
2. Print generic host facts and STOP before any claim unless `$PSVersionTable.PSEdition` is `Desktop`, the version is 5.1, and the fixture drive's filesystem is NTFS. Run `shell: powershell` and `powershell.exe`, not `pwsh`. The runner label is the explicit `windows-2025` label, not floating `windows-latest`.
3. `permissions: contents: read`. Trigger: `pull_request` only. No tag push, `workflow_dispatch`, `pull_request_target`, or `workflow_run`. No secrets, network downloads, caches, artifacts, or uploads.
4. Invented names only, under a unique `RUNNER_TEMP` child. Real junction, hardlink, and symlink rows that the runner cannot create are `NOT TESTED` / STOP, never a silent skip.
5. The verifier is read-only. Fixture setup is the only write phase. Small invented fixture first (2 files, 1 directory), then a 557-file / 109-directory invented fixture, including named streams, a case-only stage root, an 8.3 alias, and share-conflict outcomes. The CI manifest is invented, plus a required-pin parameter only. Do not vendor or copy the real TSV, and do not fetch addon bytes or network artifacts. The owner pin in section 4 stays unchanged for a future separately approved private run. Outside-scratch canaries must stay unread. Production opens keep `FILE_SHARE_READ` only.
6. If `OBJ_DONT_REPARSE` or `NtCreateFile` interop fails, STOP. Do not fall back to path-based `Get-ChildItem -Recurse`. Repeated hashes are not atomic proof.
7. CS01 reviews the exact SHA, the full diff, step conclusions, pass/fail/`NOT TESTED` counts, the host facts, and zero artifacts per run. A green hosted runner does not validate the owner's PC, backups, WoW load, rights, or real staging.

**Part 80 (`6299839567`), checked again at this parent.** **VERIFIED** at `891a6273`: `.github/workflows/ci.yml` blob `6c4393fdb18c101e377ff4c41c128551ee617685` has `push: tags: "*"` and a `publish` job with `if: startsWith(github.ref, 'refs/tags/v')`, which runs `python build.py -r`, `gh release create`, and CurseForge/WAGO uploads. Overlay Assemble and Upload are `if: ${{ false }}` in `nquestie-overlay.yml` and do not gate that publish job. Part 80 reports the same `ci.yml` blob at `335`, #149, and #150; those three refs were not re-fetched for this sentence. This design PR must not create or push any tag, `v*` especially, must not edit `ci.yml` or its publish gate, and must be re-checked so the diff contains no `build.py -r`, `gh release`, `upload-*`, or a new trigger. The only intended path is this file.

**Part 79** is source-name syntax evidence only (section 1). It is not NTFS evidence.

## 9. What would still be true after a green fixture run

A future CI job can move only the `powershell_version` and `windows_ps51_ntfs` cells, and only for the invented fixtures it actually ran. It does not move `gameplay`. It does not clear rights, backups, or the owner PC. It does not authorise copying the stage into `Interface\AddOns`. Linux synthetic evidence stays in its own cell even if the same set math passed on Windows. Peer review stays in its own cell until CS01 says the exact head was reviewed. Part 74's rule stands: if the platform execution is missing, Windows remains STOP, and the owner is not handed a script to try.

The diff of this PR is this file alone. Before push, the author re-checks that the commit does not touch `.github/workflows/`, does not add a script, and does not contain a tag. Reviewers repeat that check. `ci.yml`'s publish job remains the pre-existing tag gate described in section 8.

## 10. CS01 answers (comment `6302293994`)

Recorded from CS01's review of `0253916d3b5d429cb70f26ad510665fcf57d7674`. These are design directions. They are not a Windows execution. `windows_ps51_ntfs` stays **NOT TESTED**. The Windows gate stays **STOP**.

1. **YES.** `nNumberOfLinks == 1` applies to regular files only, not to directories. Validate it on an actual NTFS synthetic fixture. That run is **NOT TESTED**.
2. Prefer `OBJ_DONT_REPARSE` plus `FILE_OPEN_REPARSE_POINT` for the one-component child candidate. Accept either `STATUS_REPARSE_POINT_ENCOUNTERED` or an opened reparse-point-itself handle, then STOP, only when a synthetic run proves the target was not entered or read. If the combination is unsupported, STOP and revisit the design with evidence. Do not silently weaken it. Which result Windows returns is **NOT TESTED**.
3. **YES.** ADS stays fail-closed. `windows_ps51_ntfs` stays **NOT TESTED** while stream enumeration is unverified. The candidate retained-handle method is `GetFileInformationByHandleEx` with `FileStreamInfo`. It is **NOT TESTED** on files and on directories. Extra named streams are STOP. Directory streams are in scope (section 6): a reported directory stream is STOP, and an unproven directory-stream enumeration keeps `ADS: NOT TESTED`.
4. No unproven automatic sync detector. Reparse, cloud-recall, and offline indicators STOP when those queries are supported. A future off-game location needs an external unsynced and quiescent precondition. A path containing `OneDrive`, or a path without that string, is not proof. Unknown sync detection keeps the owner Windows GO at STOP.
5. **YES.** Keep the second full-content read on every run. It is diagnostic only. It does not establish an atomic snapshot and it cannot override a share conflict.
6. **YES.** Two files and one directory, then a full 557-file / 109-directory invented fixture. Include missing and extra named streams, a case-only stage root, and share-conflict outcomes. The 8.3 alias row in section 7 is part of the same inventory.
7. Invented CI manifest plus a required-pin parameter only. Do not vendor or copy the real TSV. Do not request network artifacts or addon bytes. The real owner pin in section 4 stays documented and unchanged for a future separately approved private run.
8. An unknown notice uses the existing `set-mismatch` token. It is an unexpected path. No new reason token.
9. **Yes.** Defer the #150 optional `git cat-file --batch` streaming fix until this WS3 design review closes. Do not modify the accepted TSV or older drafts.
