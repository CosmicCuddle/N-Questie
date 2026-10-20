# N-Questie 3.3.5a — source-to-private-stage provenance

**Status: DRAFT for CS01 review.** CS02 Workstream 2, 20 October 2026. This is a human-readable acceptance contract for a future private check of an off-game `Questie-335` folder. It installs nothing, copies nothing, and does not test the game.

Labels used below: **VERIFIED** (checked here against Git objects or the named source), **VERIFIED-on-Linux** (observed with Git 2.43.0 on Linux; the Windows client was not used), **POTENTIAL ISSUE**, **UNKNOWN**, **NOT TESTED**, **PROPOSAL** (CS02 design, not yet accepted).

## 1. Scope

**VERIFIED:** pinned source is commit `891a627318ac403d4da28655318286507f96c1aa`. The intended stage is the 557 runtime files defined below, in a separate folder named `Questie-335`. Placeholder for that folder: `<STAGE>`. No owner-private path is written here.

**This procedure is not a game test, not Windows/NTFS approval, and not rights clearance. Nothing is installed by it.** Backup and rollback stay on CS01's owner worksheet (v5, private). If that backup is unverified, STOP.

CS01's separate Python prototypes (`nq_private_stage_provenance_DRAFT.py` and v3) are not on GitHub. **NOT TESTED:** CS02 has not read their source. CS01 reports that v1 can return a false PASS after a directory swap, and that v3 fails closed without POSIX `O_NOFOLLOW` and directory-fd support, so v3 is not a Windows path. Do not ask the owner to run either script.

## 2. Pinned 557 files

**VERIFIED** with `git ls-tree -r --full-tree 891a627318ac403d4da28655318286507f96c1aa`. The runtime set is three root blobs plus every blob under six directories:

| Location | Files |
| --- | ---: |
| Root: `embeds.xml`, `Questie-335.toc`, `Questie.lua` | 3 |
| `Compat/` | 64 |
| `Database/` | 57 |
| `Icons/` | 53 |
| `Libs/` | 102 |
| `Localization/` | 168 |
| `Modules/` | 110 |
| **Total** | **557** |

**VERIFIED:** the same 557 paths, modes, and blob IDs are at `#149` head `6922180c3a5a0a5559098766360226cbabc3d583` (GitHub tree, `truncated=false`) and at `335` head `2be0f6f3001a20242c2fe81cb1915ff18602a4c8`. Blob-byte sum is 134,356,446. Longest relative path is 67 characters (`Compat/Libs/AceGUI-3.0/widgets/AceGUIContainer-BlizOptionsGroup.lua`). All 557 paths are ASCII, NFC, and free of case-fold collisions and Windows-reserved names (`CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9`, `LPT1`–`LPT9`, trailing dot or space, `<>:"\|?*`). That says nothing about the owner's absolute prefix.

**VERIFIED:** the four required notice files are inside the 557:

- `Icons/LICENSE.md` blob `d4dcaef9a5235e275f3511b214017fd892d08de7`
- `Icons/MIT.txt` blob `814bef05214ea042df6fbf0cf6e7358a216967fc`
- `Libs/LICENSE.txt` blob `866fc34ea592d49b1dc0b1b3827c24e7be138858`
- `Libs/Krowi_WorldMapButtons/LICENSE.md` blob `3a204362419bf105b75bd7ea9841cf5706fb7710`

`ExternalScripts(DONOTINCLUDEINRELEASE)/slpp/LICENSE` is outside the 557 and must stay out. Presence of these four notices is not rights clearance.

**VERIFIED:** among the 557, modes are 414 `100644` and 143 `100755`, all type `blob`. Count of mode `120000` (symlink) is 0. Count of mode `160000` (gitlink) is 0. The full commit has two gitlinks, both outside the stage: `.types/.SubModules/BlizzardInterfaceCode` and `.types/.SubModules/vscode-wow-api`. A `100755` entry is a normal file with the executable bit, not a symlink. Whether a Windows copy keeps that bit is **NOT TESTED**. Compare path and bytes.

**VERIFIED:** other root TOCs exist and must not be in the stage: `Questie-335-Classic.toc`, `Questie-335-TBC.toc`, `Questie-BCC.toc`, `Questie-Classic.toc`, `Questie-WOTLKC.toc`, `Questie.toc`. The only root TOC in the stage is `Questie-335.toc`. Eleven nested library TOCs are expected and must remain: `Libs/Ace3.toc`, `Libs/Ace3_TBC.toc`, `Libs/Ace3_Vanilla.toc`, `Libs/Ace3_Wrath.toc`, `Libs/HereBeDragons/HereBeDragons.toc`, `Libs/HereBeDragons/LibStub/LibStub.toc`, `Libs/Krowi_WorldMapButtons/Krowi_WorldMapButtons.toc`, `Libs/Krowi_WorldMapButtons/Krowi_WorldMapButtons_TBC.toc`, `Libs/Krowi_WorldMapButtons/Krowi_WorldMapButtons_Vanilla.toc`, `Libs/Krowi_WorldMapButtons/Krowi_WorldMapButtons_Wrath.toc`, `Libs/LibStub/LibStub.toc`.

**VERIFIED** from the `Questie-335.toc` blob (`f59dc1c2b1987697e133297831224e6f0957bae8`, 6,590 bytes): `## Interface: 30300`, `## SavedVariables: QuestieConfig`, `## SavedVariablesPerCharacter: QuestieConfigCharacter`, and a load line `Compat\embeds.xml`. Those SavedVariables names must stay unchanged. Root `embeds.xml` is one of the three root files, so it is present, but the TOC does not load it. `git grep` of the 557 paths finds `embeds.xml` only on that one TOC line.

## 3. Byte comparison

**VERIFIED** for all 557 blobs: a Git blob ID is SHA-1 over the ASCII header `blob <decimal-length>\0` plus the raw bytes. Plain SHA-256 of those bytes is a different value. Example: `Questie.lua` blob `6161f46f7d1c5e617a34f8a2b83d959de0b5d25d`, SHA-256 `9645d91e7e965dfd6f154d3c796ad63b471f95eb166c57e21926e5dd9c7f0256`.

**VERIFIED** by reading `tools/check_nq_335_local_stage.py` at `6922180c` (that file is not in `891a6273`): a structural G04 PASS checks layout, notice presence, the TOC/XML graph, and static texture paths. It does not hash the 557 files against Git blobs. The checker says it is not a source-commit attestation. Re-running it was **NOT TESTED** here. A G04 PASS does not prove byte equality.

**UNKNOWN:** how that checker treats a Windows drive-relative path such as `C:..\Questie-335` or `C:Questie-335`. This procedure refuses those spellings on its own.

## 4. Line-ending hazard

**VERIFIED** from `.gitattributes` blob `92799b3e9eb4435dd28a2752544b00fb3eba1132` at the pin:

```
* text=lf
*.lua  text
*.toc  text
*.xml  text
*.py   text
*.json text
*.png binary
*.jpg binary
*.exe binary
*.tga binary
*.blp binary
```

**VERIFIED** with `git check-attr` on the 557 paths: `eol` is unspecified for every path. `text` is `set` for 490 files (428 `.lua`, 12 `.toc`, 50 `.xml`). `text` is `unset` and `binary` is `set` for 57 files (35 `.blp`, 22 `.tga`). `text` is the string `lf` for these 10 files: `Compat/ExtractMapData/UiMap.csv`, `Compat/ExtractMapData/UiMapAssignment.csv`, `Icons/LICENSE.md`, `Icons/MIT.txt`, `Libs/CHANGES.txt`, `Libs/HereBeDragons/CHANGELOG.md`, `Libs/Krowi_WorldMapButtons/LICENSE.md`, `Libs/LICENSE.txt`, `Libs/LibDataBroker-1.1/README.textile`, `Libs/changelog.txt`.

`text=lf` is not a documented value of the `text` attribute in the wording CS02 could retrieve (the local Git manual pages are not installed, so the manual sentence is **UNKNOWN**). **VERIFIED-on-Linux** with Git 2.43.0 in a scratch repo:

- `git check-attr` prints `text: lf` when only `* text=lf` matches, and `text: set` when a later `*.lua text` line matches. `eol` stays unspecified.
- `text=lf` alone does not strip CR on `git add`. `git hash-object` and `git hash-object --no-filters` then return the same id, CR bytes included.
- `*.lua text` does enable the clean filter. For CRLF bytes in a `.lua` file, `git hash-object` without `--no-filters` returns the LF blob id and hides the difference. `--no-filters` returns a different id.
- Checkout with `core.autocrlf=true` wrote CRLF for both a `text: set` file and a `text: lf` file. `core.autocrlf=false` plus `core.eol=crlf` wrote CRLF for the `text: set` file and left the `text: lf` file as LF. `core.eol=lf` wrote LF for the `text: set` file. A `binary` file was left unchanged under `core.autocrlf=true`.

**POTENTIAL ISSUE:** a Windows checkout with `core.autocrlf=true` or `core.eol=crlf` can write CRLF into Lua, TOC, and XML. `core.autocrlf=true` may also rewrite the 10 `text: lf` files, including the four notices. A stage copied from that working tree will not match blob bytes. The hash compare then FAILs. That FAIL is correct. Do not convert line endings and continue.

**Required handling:** take expected bytes from `git cat-file blob` (the object database), not from a working tree. Do not build `<STAGE>` from a Windows checkout. On Windows, compare file bytes to the manifest SHA-256. Do not use `git hash-object` unless it is `git hash-object --no-filters`, and even then a CRLF mismatch is STOP. Windows checkout behaviour itself is **NOT TESTED**.

## 5. Proposal for CS01 review

**PROPOSAL:** on a trusted Linux side, generate a manifest from Git objects. The file `docs/NQ-335-STAGE-EXPECTED-MANIFEST-891a6273.tsv` is that manifest for this pin. It has a header line `path	bytes	git_blob	sha256`, then 557 rows in `git ls-tree -r` order, LF endings, no CR. **VERIFIED:** file SHA-256 `73eccd4498a3a47db4c5d3fca60a83f7c35052174afcbafe350839b34fcb6b52` (84,728 bytes). The `bytes` column sums to 134,356,446. Each SHA-256 matches `git cat-file blob <id> | sha256sum`. The manifest is valid only for commit `891a627318ac403d4da28655318286507f96c1aa`.

Exact command, run from the repository root (writes only that TSV):

```bash
python3 - << 'PY'
import hashlib, subprocess
pin = "891a627318ac403d4da28655318286507f96c1aa"
roots = {"Questie.lua", "Questie-335.toc", "embeds.xml"}
prefixes = ("Compat/", "Database/", "Icons/", "Libs/", "Localization/", "Modules/")
ls = subprocess.check_output(["git", "ls-tree", "-r", "--full-tree", pin])
rows = []
for line in ls.splitlines():
    meta, path_b = line.split(b"\t", 1)
    mode, typ, oid = meta.split(b" ")
    path = path_b.decode("ascii")
    selected = path in roots or path.startswith(prefixes)
    if typ != b"blob":
        if selected:
            raise SystemExit("runtime path is not a blob: " + path)
        continue
    if selected:
        rows.append((path, oid.decode("ascii")))
if len(rows) != 557:
    raise SystemExit("expected 557 paths, got %d" % len(rows))
batch = subprocess.Popen(["git", "cat-file", "--batch"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
lines = ["path\tbytes\tgit_blob\tsha256"]
total = 0
for path, oid in rows:
    batch.stdin.write((oid + "\n").encode("ascii"))
batch.stdin.close()
for path, oid in rows:
    header = batch.stdout.readline().decode("ascii").rstrip("\n")
    got, typ, size_s = header.split(" ")
    if got != oid or typ != "blob":
        raise SystemExit("bad header " + header)
    size = int(size_s)
    data = batch.stdout.read(size)
    if batch.stdout.read(1) != b"\n":
        raise SystemExit("missing newline after " + path)
    digest = hashlib.sha256(data).hexdigest()
    formed = hashlib.sha1(b"blob %d\0" % size + data).hexdigest()
    if formed != oid:
        raise SystemExit("blob id mismatch " + path)
    total += size
    lines.append("%s\t%d\t%s\t%s" % (path, size, oid, digest))
if batch.wait() != 0:
    raise SystemExit("git cat-file failed")
if total != 134356446:
    raise SystemExit("byte sum %d" % total)
text = ("\n".join(lines) + "\n").encode("ascii")
dest = "docs/NQ-335-STAGE-EXPECTED-MANIFEST-891a6273.tsv"
with open(dest, "wb") as fh:
    fh.write(text)
print(hashlib.sha256(text).hexdigest())
PY
```

**PROPOSAL, every command NOT TESTED:** the owner compares `<STAGE>` with read-only PowerShell. Git is not required on Windows. Normalize `\` to `/`, then require exact case-sensitive equality of the relative-path set with the manifest. `Get-FileHash -LiteralPath -Algorithm SHA256` must match the `sha256` column. Run the hash pass twice. Any difference is concurrent modification and is STOP.

Before any `-Recurse`: reject the path string, then walk `<STAGE>` and each ancestor with `Get-Item -LiteralPath -Force` (not `-Recurse`) and STOP if `Attributes` contains `ReparsePoint`. **UNKNOWN:** whether Windows PowerShell 5.1 `Get-ChildItem -Recurse` follows junctions or directory symlinks. Do not use `-Recurse` until the non-recursive check has passed. Hard links are not reparse points. **UNKNOWN / NOT TESTED:** a PowerShell 5.1 primitive that lists extra hard-link names. If that proof is unavailable, STOP. No link-following fallback.

## 6. STOP before reading file contents

Reject `<STAGE>` before any content read when any of these is true:

- The path is not absolute, or it is not plain: a raw `..` segment, or a drive-relative form such as `C:..\Questie-335` or `C:Questie-335`.
- The final folder name is not exactly `Questie-335`.
- `<STAGE>` is inside the WoW `Interface\AddOns` tree, or inside OneDrive, Dropbox, or any other cloud-synced folder. Treat OneDrive Files On-Demand placeholders as reparse points, and treat a sync client as able to change a file during the check. Owner machine **NOT TESTED**.
- Any symlink, junction, reparse point, or hard-link alias exists in `<STAGE>` or in an ancestor.
- The relative path set differs from the manifest: missing, extra, or case-misnamed file, an extra root `.toc`, an empty unexpected directory, or a directory Git does not track.
- The tree contains `.git`, `WTF`, SQL, `.bak`, account data, private data, or a second Questie copy.

## 7. Acceptance STOP matrix

STOP, and leave the game untouched, if any of these is true:

| Gate | Result required |
| --- | --- |
| Path or byte vs manifest | Exact 557 paths and SHA-256 values. Any mismatch or unknown file is STOP. |
| `Questie-335.toc` | SHA-256 `0783a6f38a530a2d646569d047dc91b6ca2f9ab408adb844b9af324f1424eee9`. That preserves Interface `30300` and the two SavedVariables names. |
| Second Questie addon | Owner confirms no other enabled Questie. **NOT TESTED.** Do not scan the live AddOns folder with this note. |
| WoW process | Owner confirms WoW is not running. **NOT TESTED.** |
| Concurrent change | A second read-only pass matches the first. Any change is STOP. |
| Backup / rollback | CS01 worksheet verified by the owner. Otherwise STOP. |
| Copying and graphics rights | Still uncleared until a separate decision. STOP before any distribution. See `docs/NQ-335-DISTRIBUTION-RIGHTS-AND-PACKAGE-PREFLIGHT.md`. |
| Source | Trusted checkout of `891a627318ac403d4da28655318286507f96c1aa` only. |

If a safe no-follow primitive is missing, STOP. Do not fall back to a call that follows links.

## 8. What the owner may record

Record only PASS or FAIL, plus counts (files compared, mismatches, missing, extra). Do not post absolute private paths, account names, or file copies to GitHub.

A PASS here means the off-game folder matched this manifest. It does not mean the addon was installed, that Windows or NTFS was approved, that rights were cleared, or that an in-game test passed. Those remain **NOT TESTED**.
