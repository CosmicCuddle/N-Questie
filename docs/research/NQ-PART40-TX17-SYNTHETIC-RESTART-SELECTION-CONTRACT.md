# Part 40 — TX17 fictional SavedVariables restart-selection model

**Status: PUBLIC-SAFE TEST-ONLY RESEARCH. This does NOT accept Gate08, TX17, disk/relog QA, integration or any release.**

**Protected `335` baseline:** `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. This independent child begins at that SHA and is intentionally unrelated to the frozen reviewed #238/#243 and pending CS02 mutation-review children #246/#247.

## Narrow purpose

[Standalone test](../../tests/compat/nq_gate08_tx17_savedvariables_restart_model.lua) uses **entirely invented** eight output fields representing four binary/pointer pairs and fictional revision, locale, compiled count and source tag. The model checks whether a **reader-selection policy** can fail closed on incomplete, inconsistent and multi-field mixed states *after* a hypothetical SavedVariables reload. It never reads/updates the real addon database, SavedVariables files, QuestieStream or the WoW client.

The model assumes an active slot marker and two self-consistently sealed generation slots. The active marker represents a separately persisted commit intent. A newer complete but **uncommitted** alternate is not automatically selected. A corrupt active generation may fall back **only** if its generation number remains readable and the alternate is both fully checked and older. An unreadable marker or active generation requires an external rollback/recovery decision.

The sealed record covers eight fields: `npcBin/npcPtrs`, `objBin/objPtrs`, `questBin/questPtrs`, `itemBin/itemPtrs`; metadata `generation`, `schema`, `revision`, `compiledCount`, `locale`, `sourceStamp`. Every value contributes to a canonical, length-prefixed checksum input in a deterministic key order. The two modular hashes are ordinary corruption indicators, **not cryptographic integrity or writer authentication**. The return value copies permitted fields, avoiding an immediate alias to the simulated persisted object.

## Cases and expected outcomes

- Valid selected generation 1 or 2 is accepted. A valid but not-yet-selected staged generation is ignored even if its generation number is greater.
- Deletion and value corruption of **each of the eight fields** are individually refused for the selected generation. Under the narrow readable-newer-generation assumption the prior intact slot is returned; no combination of Bin/Ptrs from different generations is constructed.
- Mutated revision, compiled count, locale and source tag are refused. Damaged schema, invalid revision or empty locale do not create a success.
- Torn/missing marker, missing selected slot, unreadable/invalid active generation, and both slots corrupt are refused.
- A healthy selected slot tolerates an invalid inactive slot. Divergent individually sealed records with the **same generation** are ambiguous and refused; exact duplicate copies are accepted.
- A returned snapshot does not alias its stored source. A test deliberately changes and **reseals** a value: it passes, confirming the checksum's **KNOWN UNSAFE** security limit.

The regression expects **38 fictional controls** on actual Lua 5.1.5 and 5.4.6. All fixture identifiers and values are invented; CI logs print only totals and scope caveats. The dedicated workflow does **not** upload files, artifacts or package output.

## Why successful CI is NOT disk safety

1. WoW 3.3.5a's actual SavedVariables serialization, shutdown/crash ordering and flush guarantees are not simulated or proven. A two-slot table inside one file is **not automatically an atomic two-generation disk journal**.
2. The active marker and slot writes may themselves be reordered, lost, truncated or serialized as one large file. The model cannot recover an old on-disk generation which was never actually durably persisted.
3. Plain Lua mutable tables can be edited and resealed by other writers; these checks do **not** enforce source epoch, all-writer ownership, anti-ABA protection, or provenance.
4. No real source, compiled byte readers, client locale, faction/IP, memory/GC/frame, retry scheduler or native error paths are tested.
5. Signature collision, malicious edits with recomputed checksums, and unsupported future schema must **not** be treated as trustworthy success.
6. Real recovery needs an explicit UX/backup/rollback plan when both generations or active marker are invalid. Avoid silent deletion of prior SavedVariables.

## Next proof obligations

**Synthetic only:** independent mutation review to remove each field check, confuse active/alternate, pick the newest inactive uncommitted generation, turn fallback into mixed generation, ignore metadata, bypass same-generation ambiguity, return a mutable alias or incorrectly treat the forged checksum as an authenticated writer. Each mutation must be reported as killed, surviving or genuinely equivalent on **both real Lua interpreters**.

**Native and owner-approved later:** first back up the actual addon folder and SavedVariables privately; measure 3.3.5a shutdown/`/reload`/relog behaviour and storage ordering under non-destructive fault injection; verify full four-kind source-consistent transaction/stream lifetime and recoverable previous generation; examine actual memory/GC/frame cost and owner-approved rollback. No server SQL, owner IP relationships or real SavedVariables are allowed in public CI.

**Release status:** Gate08 remains RED. TX01–TX18 are unaccepted as a whole; this is a **TX17 modelling component only**. Other gates remain **3 complete / 6 underway / 3 technically pending**; the quest research set is **439 RAW** not approved additions, and pilot 1207–1209 is **0/3 implemented**. Protected `335` unchanged. No merge, install, package, tag, release or user action is authorised.
