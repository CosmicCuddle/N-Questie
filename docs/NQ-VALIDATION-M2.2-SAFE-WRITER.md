# N-Questie Validation M2.2 Step 4: Safe Writer

Status: Draft, report-only tooling
Date: 2026-10-14
Module: `tools/validation/SafeWrite.lua` (shared with M2.3 later)
Platform: Linux with GNU coreutils (`realpath`, `mktemp`, `stat`, `ln`, `mv`, `id`)

## 1. What it guarantees

| Rule | How |
|---|---|
| Approved locations only | The destination directory must resolve (`realpath -e`) outside the checkout or under `<checkout>/private/`. `tests/fixtures/` is read-only for this purpose. |
| Fail closed on paths | Absolute paths only, no `.`/`..`, no control characters, plain file name. A resolver failure or missing directory rejects. |
| Private directory | Owned by the current user, a real directory, no group/other bits (0700 or stricter) |
| Private file | Temp file from `mktemp` (exclusive create) in the same directory, `chmod 600`, read back and compared |
| No partial final file | The final name only appears through `ln` (link) or `mv -fT` (rename), both of which install a complete file |
| Real no-clobber | Without `--force`: `ln -T temp final` uses link(2), which fails if `final` exists at that moment, even if it appeared after the earlier check. The temp name is then removed. |
| `--force` | `mv -fT temp final` is rename(2): atomic, so readers see the old or the new file |
| Symlinks | An existing final path that is a symlink is refused, with or without `--force`. A directory symlink that redirects into the checkout is caught by resolving the directory. |
| Failure keeps existing data | Any failure before install removes the temp file and leaves the existing final file untouched |
| Post-install check | Final path resolves to itself, is a regular file, owned by the user, mode 0600, content equals what was written |

Why not plain temp + rename for the default: rename(2) silently replaces an existing file, so it is not no-clobber. `mv -n` reports success even when it skips, and needs a second check that is itself racy. link(2) is the standard atomic create-if-absent.

## 2. Remaining races (not eliminated)

1. **Directory swap after the re-check.** The directory is resolved, then re-resolved just before install. A process running as the same user could replace a parent directory between that re-check and `ln`/`mv`. The 0700 requirement prevents other users from doing this; it does not stop the same user.
2. **`--force` over a file that becomes a symlink.** The final path is checked for being a symlink right before `mv`. rename(2) replaces the symlink itself, not its target, so the target is not written. The window still exists, but it cannot redirect the write.
3. **Post-install check failure with `--force`.** If the post-install check fails, the old file has already been replaced. The tool reports the error and leaves the new file for inspection.
4. **Filesystems without hard links.** `ln` fails and the write is refused (fail closed).

These are acceptable for a single-user, local-only tool. They are not claimed to be eliminated.

## 3. Tests (`tests/test_nquestie_m2_safe_write.lua`, 36 checks)

- New file outside the checkout and under `private/`. Mode 0600. No temp files left.
- An existing file is refused without `--force` and left unchanged. `--force` replaces it atomically.
- A racing file is created just before install: the no-clobber install refuses and keeps the racing file intact.
- Refused locations: inside the checkout, `tests/fixtures`, a directory symlink into the checkout, a symlink final path (with and without `--force`), a missing directory, a relative path, a `..` segment, a bad name, a group/other-accessible directory, a final path that is a directory, a read-only directory.
- Simulated failures (`afterTempCreate`, `afterWrite`, `beforeInstall`), each as a false return and as a crash. No final file is created, an existing file stays intact, and no temp files are left.
- Resolver unavailable.
