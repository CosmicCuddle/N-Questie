# N-Questie Validation M2.1: Input Schema

Status: Draft, report-only
Date: 2026-10-14
Branch: feat/nq-validation-m2.1-input-schema-2026-10-14 (based on PR #20)
Schema: `nq-m2-input` version 1
Owner: validation workstream (framework). Private export: lead developer (local only).

## 1. Purpose

Accept a file of selected AzerothCore quest objective records (exported privately) and either accept the whole document or reject it with a full list of errors. Nothing is repaired, nothing is written, and no corrections are generated.

The validator is `tools/validation/InputSchema.lua`. The CLI is `cli/validate-m2-input.lua`.

## 2. Format choice: Lua 5.1 data literal

| Option | Verdict |
|---|---|
| Lua table file (`return { ... }`) | Chosen. The private exporter already emits a Lua 5.1-shaped table. No new Python dependencies. Native to the addon toolchain. |
| JSON + bundled parser | Rejected for v1. Would need a second parser and a second exporter path. Can be added later as an alternate reader if needed. |

The file is **not** executed. A small data-only parser accepts tables, numbers, booleans, nil and quoted strings, and rejects function calls, string methods, globals, loops, bytecode and duplicate keys (a normal `load` would silently overwrite duplicates).

## 3. Top-level document

```lua
return {
    schema = "nq-m2-input",
    schemaVersion = 1,
    provenance = { ... },
    quests = { { ... }, { ... } },  -- list, not a map keyed by ID
}
```

Unknown top-level fields are rejected. `schema` must be exactly `nq-m2-input`. `schemaVersion` must be `1` (unsupported versions are rejected, not upgraded).

## 4. Provenance (required, no private contents)

| Field | Type | Rule |
|---|---|---|
| exporter | string | Short name: letters, digits, `.`, `_`, `-` (max 64). No paths. |
| exporterVersion | string | Semver, e.g. `1.0.0` |
| sourceLabel | string | Non-identifying label, e.g. `acore_world-offline`. No absolute paths, no account names. |
| sourceFingerprint | string | `sha256:` + 64 lowercase hex (hash of the offline archive the exporter read) |
| exportedAt | string | UTC ISO 8601: `YYYY-MM-DDThh:mm:ssZ` |
| selection | string | Must be `"explicit"` (quest IDs chosen by a reviewer) |
| questCount | integer | Must equal `#quests` |

Unknown provenance fields (for example a path) are rejected. Absolute paths and credentials must never appear here.

## 5. Quest record (every field required)

### 5.1 Integer columns (export `0` for an empty slot)

`ID`, `StartItem`, `ItemDrop1`–`ItemDrop4`, `RequiredNpcOrGo1`–`4`, `RequiredNpcOrGoCount1`–`4`, `RequiredItemId1`–`6`, `RequiredItemCount1`–`6`.

| Field | Rule |
|---|---|
| ID | Integer ≥ 1 |
| RequiredNpcOrGoN | Integer; **negative = gameobject**, positive = creature, 0 = empty |
| RequiredNpcOrGoCountN | Integer ≥ 0; must be > 0 when the id is set, 0 when the id is 0 |
| RequiredItemIdN / CountN | Same pairing rule; ids are never negative |
| StartItem, ItemDropN | Integer ≥ 0 |

### 5.2 Flags (must be present; absent = reject)

| Field | Allowed values |
|---|---|
| hasConditions | `true`, `false`, `"unknown"` |
| ipGated | `true`, `false`, `"unknown"` |
| scriptedCredit | `true`, `false`, `"unknown"` |
| killCreditComplete | boolean only (`true` / `false`) |

There is no default. Omitting a flag rejects the whole input.

### 5.3 KillCredit

```lua
KillCredit = {
    [creatureId] = { credit1, credit2 },  -- integers ≥ 0; {0, 0} = verified none
}
```

- Keys must be positive creature ids. Gameobject (negative) keys are rejected.
- Each value must be exactly `{credit1, credit2}`.
- Use `{}` when no rows were exported.
- If `killCreditComplete = true`, every **positive** `RequiredNpcOrGoN` must have a row. Negative (gameobject) targets are not looked up. Claiming complete with a missing creature row rejects the whole input.

## 6. Whole-input rejection

Any error rejects the document. The CLI prints every error and exits 1. No partial report is written. The input file is never modified.

## 7. Input paths

The path is given as the CLI argument or `NQ_M2_INPUT`. It is checked in this order, and the first failure rejects the input:

| Step | Rule |
|---|---|
| 1 | Must be non-empty and absolute |
| 2 | Must not contain `.` or `..` segments, or control characters |
| 3 | The resolver must work (`realpath -e -- /` returns `/`). Otherwise reject. |
| 4 | The repository root must resolve |
| 5 | The input must resolve fully with GNU `realpath -e`: every component, every parent symlink and the file itself. A missing file, broken link, loop or permission error rejects. |
| 6 | The **resolved** path must be outside the resolved checkout, or under `<checkout>/private/` or `<checkout>/tests/fixtures/m2_input/` |

The resolved target always governs:

| Case | Result |
|---|---|
| Symlink outside the checkout pointing to a public file | Reject |
| Symlink outside pointing into `tests/fixtures/m2_input/` or `private/` | Accept |
| Directory symlink outside pointing at the checkout root | Reject, unless the full path resolves under an allowed area |
| Symlink in `private/` pointing to a public file or to the checkout root | Reject |
| Symlink in `private/` pointing outside the checkout | Accept (resolved target is outside) |
| Broken symlink, loop, missing file, unreadable parent | Reject |
| Relative path, `.` or `..` segments | Reject |
| Resolver missing, failing or giving a non-absolute answer | Reject |

The file is then opened by its resolved path. The validator never writes.

Platform notes:

- Linux (Ubuntu CI, the box): supported. Uses GNU coreutils `realpath -e`.
- macOS: the default `realpath` does not support `-e`, so every path is rejected unless GNU coreutils `realpath` is first on `PATH`. This is intentional fail-closed behaviour.
- Windows: not supported. Lua 5.1 has no path API, `io.popen` goes through `cmd.exe`, and `realpath` is not available, so every path is rejected. Run under WSL or Git Bash with GNU coreutils if needed. This has not been tested.
- LuaFileSystem is not used. It has no realpath function and would add a dependency.

## 8. Mapping from the private exporter (PR #19 handover)

What the local exporter emits today (from `docs/M2-PRIVATE-OBJECTIVE-INTAKE-HANDOVER.md`) and what this schema requires:

| Topic | Exporter today | M2.1 requirement | Gap |
|---|---|---|---|
| Shape | Quest-ID-keyed table or JSON | Top-level `{ schema, schemaVersion, provenance, quests = { list } }` | Wrap records in the document; emit a **list**, not a map keyed by ID |
| Objective columns | Present | All integer fields required (export 0 for empty) | Confirm every field is always written |
| Flags | All tagged `killCreditComplete=false`, others `"unknown"` | Explicit values required (already the case) | Keep never converting `"unknown"` to `false` |
| KillCredit | Optional manifest of creature ids; incomplete by default | Table required (`{}` ok); `killCreditComplete=true` only when every server creature has a row | Do not set complete just because a row was selected |
| Provenance | Fingerprint + UTC date privately | All seven provenance fields, no paths | Add exporter name/version, sourceLabel, selection=`"explicit"`, questCount |
| Output location | Outside the public checkout, mode 0600 | Absolute path outside checkout (or under private/) | No change needed for the stronger default |
| Format | Lua or JSON | Lua data literal for v1 | Prefer the Lua path; keep JSON private if useful, but the public validator reads Lua only |
| Lua parse check | Not yet run through Lua 5.1 | Must parse with this data-only parser | Run the exporter output through `cli/validate-m2-input.lua` locally before any M2.4 pilot |

The private exporter is not in this repository and is not modified by this PR. The lead developer updates the local adapter only.

## 9. Examples

Positive fixture: `tests/fixtures/m2_input/valid_selected_quests.lua` (quests 1203, 900101, 900102, 900103).

```bash
lua5.1 cli/validate-m2-input.lua "$(pwd)/tests/fixtures/m2_input/valid_selected_quests.lua"
# OK: 4 quest record(s), schema nq-m2-input v1, ...
```

Error message examples:

| Situation | Message (substring) |
|---|---|
| Flag omitted | `hasConditions: missing (must be true, false or "unknown")` |
| Complete claimed, row missing | `killCreditComplete: true but KillCredit has no row for creature 900141` |
| Duplicate quest ID | `duplicate quest ID 1203` |
| Path inside checkout | `input path is inside the public checkout` |
| Code in the file | `only data literals are allowed` |
| Wrong schema version | `schemaVersion: unsupported` |

## 10. Tests

| Suite | Coverage |
|---|---|
| `tests/test_nquestie_m2_input_schema.lua` | Standalone: valid fixture, 43 validation rejections, 16 parse rejections, path gate, CLI |
| `tests/test_nquestie_m2_input_paths.lua` | Path and symlink safety: 29 cases using temporary files created at run time |
| `tools/validation/InputSchema.test.lua` | Busted; picked up by the existing M1 workflow (`busted -p ".test.lua" tools/validation`) |
| Proposed workflow steps | `docs/proposed-workflows/nquestie-m2-input-schema.yml` (not activated) |

## 11. Final statement: schema v1

`nq-m2-input` version 1 is frozen as described in §3–§6. Any change to fields, types or rules needs a new `schemaVersion`. The validator rejects every version it does not know. It does not upgrade or downgrade documents.

## 12. Exporter compatibility requirements

The private exporter is compatible with v1 when it does all five of these:

1. Writes the top-level document `{ schema = "nq-m2-input", schemaVersion = 1, provenance = {...}, quests = { ... } }`, with `quests` as a **list**, not a table keyed by quest ID.
2. Writes every integer objective field for every record, using `0` for empty slots.
3. Writes all seven provenance fields, with no paths, account names or credentials.
4. Writes `hasConditions`, `ipGated` and `scriptedCredit` explicitly as `true`, `false` or `"unknown"`. It never turns `"unknown"` into `false`. It sets `killCreditComplete = true` only when a KillCredit row was actually read for every positive `RequiredNpcOrGo` creature.
5. Writes a Lua data literal (no function calls, no long strings, no hex, no duplicate keys) to an absolute path outside the checkout, or under `private/`. It passes `lua5.1 cli/validate-m2-input.lua <path>` locally before any M2.4 pilot.

## 13. Out of scope

Effective Questie export (M2.2), batch comparison (M2.3), private exporter code, automatic corrections, live server access, workflow files under `.github/`.
