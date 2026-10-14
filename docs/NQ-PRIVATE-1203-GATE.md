# N-Questie — One-command private quest 1203 gate

**Status:** Draft offline QA helper, not a private test result or a production M2.3 engine.  
**Date:** 14 October 2026.  
**Related:** Lead [PR #40](https://github.com/CosmicCuddle/N-Questie/pull/40) private pilot runbook, M2.1 schema in `docs/NQ-VALIDATION-M2.1-INPUT-SCHEMA.md`.

## What this checks

The command `cli/check-private-1203.lua` is a deliberately narrow **read-only** tool. It uses the existing M2.1 **data-only parser** and schema validator, then requires:

- exactly **one selected quest**, ID **1203**;
- exactly **one required item objective**, **item 3853 ×1**, and every other required-item slot empty;
- no required creature/gameobject objective slots;
- all required schema/provenance fields and explicit tri-state evidence flags to be syntactically valid.

It does **not** execute the supplied Lua data, connect to MySQL/AzerothCore or write files. It never prints paths, source fingerprints, private row values or labels. Exit status 0 means this **limited input-format and objective-shape gate** passed; nonzero means stop and investigate privately.

**Not verified by PASS:** whether the source archive is authentic, the archive SHA-256 matches `sourceFingerprint`, the snapshot matches today's running world DB, KillCredit/conditions/script/IP evidence is complete, client quest text or in-game availability, or an M2.3 comparison. Never call this a `CONFIRMED_MATCH`.

## Safe usage from MobaXterm (connected to a trusted Linux development checkout)

1. Confirm that you are in the N-Questie **development checkout**, not the installed WoW addon folder or running worldserver directory. Do not run `git pull` on the live game/server for this check.
2. Keep the actual private `nq-m2-input` file **outside the public Git checkout**, with its **immediate parent directory owned by your current Linux user and mode `0700`**, and the **regular input file owned by that user and mode `0600`**. The read-only gate now **enforces** both requirements; an unsuitable file or folder exits with `FAIL` without reading the contents. Do not upload, attach or paste it into a public GitHub PR.
3. Run the following preflight; a blank `git status` is expected if this is the intended clean checkout:

```bash
pwd -P
git status --porcelain --untracked-files=all
git rev-parse HEAD
command -v lua5.1
command -v realpath
```

4. Run the *read-only* selected-quest check, replacing the placeholder **only locally**:

```bash
lua5.1 cli/check-private-1203.lua "/absolute/private/path/quest-1203.lua"
```

Expected result **only if the real private file really matches the schema and objective**:

```text
PASS: quest 1203 M2.1 schema, single-ID selection and public 3853 x1 item-only objective
NOT VERIFIED: private archive fingerprint, current-world freshness, IP/conditions/scripts and M2.3 match
```

If it instead prints `FAIL:`, **stop**. First verify privately that you selected the intended one-quest export and used a supported absolute path. Do not change the source archive or relax the parser to obtain a pass. The legacy `lua5.1 cli/validate-m2-input.lua "<private path>"` provides fuller private local diagnostics, but its output can contain detailed field information and must not be pasted to GitHub.

5. **Optional original-archive fingerprint check (still read-only):** once you have independently identified the **exact original archive bytes** used by the exporter, store that archive outside the checkout in a current-user-owned `0700` immediate parent folder, as a current-user-owned regular file with `0600` permissions. Run:

```bash
lua5.1 cli/check-private-1203.lua "/absolute/private/path/quest-1203.lua" --archive "/absolute/private/path/acore_world.zip"
```

The command calculates the archive file's SHA-256 directly from its bytes and compares it privately with `sourceFingerprint` in the selected Lua document. It prints **PASS: supplied offline archive SHA-256 matches the declared source fingerprint (byte comparison only)** only if the two match. On mismatch or unsafe source paths/permissions it prints a generic `FAIL`, with no path or hash disclosure. It never modifies the archive or selected export.

**Important:** a matching SHA-256 does **not** prove the private exporter truly used that archive. Verify the source/exporter run independently. It also does **not** prove that the live world database has not changed. Separately perform the freshness and source-selection checks in `docs/NQ-PRIVATE-1203-PILOT-AND-INGAME-QA.md` (§9 on PR #40). Keep archive hashes, source metadata and selected SQL rows private. Human approval is still required before running production M2.3.

No backup of a running installation is needed for **this read-only command**, because nothing is modified. Back up the addon and relevant SavedVariables **before any future approved in-game QA installation**.

## Public CI coverage

The test fixture `tests/fixtures/m2_input/quest1203_single_synthetic.lua` and the checksum test archive's bytes are **invented/public**, not server data or a real ZIP export. `tests/test_nquestie_private_1203_gate.sh` checks the synthetic positive case, wrong quest/item/count/extra-target cases, schema and provenance rejection, rejected executable Lua, safe absolute paths and privacy-minimised output. It is wired to `tests/run_m2_suite.sh` and `tools/validation/M21Private1203Gate.test.lua`.

The minimal inherited Busted container lacks Bash/GNU tools, so its wrapper reports `pending` there; the full Bash-capable M2 framework CI **must run and pass** the test. No CI result can validate the private server input.
