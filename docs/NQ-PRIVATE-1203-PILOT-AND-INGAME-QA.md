# N-Questie — Private 1203 Pilot and In-Game QA Runbook

**Status:** DRAFT planning and operator checklist only; no private data included, no live run performed by this document.  
**Scope:** Maintainer / lead-developer side of M2.1, M2.2, future M2.3, and controlled in-game QA.  
**Baseline:** PR #38 (`d58a4b89d247b2c2b43a85fa7cafc3600e23f823`); separate from Grok's v2 design PR #39.  
**Date:** 14 October 2026.

## 1. Purpose and evidence boundaries

This runbook connects three **different** kinds of evidence, without treating one as proof of another:

| Evidence | Established | Still unverified |
| --- | --- | --- |
| Public compiled N-Questie | M0 232 positive checks; 28 reviewed level corrections; 82,431 compiled fields, zero mismatches. Effective quest 1203 includes item 3853; stock WotLK Questie has 33110. | Equivalence to a running private server, current in-game eligibility, all exact spawn positions. |
| M2.2 public pilot | A Linux/Lua 5.1 pilot for quest 1203 and the 16-quest v1 pilot list has passed as documented in `NQ-VALIDATION-M2.2-PILOT.md`. v1 coverage: 8,401 representable / 758 unsupported out of 9,159, none unclassified. | No private server comparison; the private server-input validator has not been run on the lead's real selected-quest file with Lua 5.1. |
| Quest 2001 in-game smoke test | Maintainer verified starter, objective markers, completed turn-in marker and post-hand-in disappearance; see `QUEST-2001-SMOKE-TEST.md`. | Full independent live-spawn/phase reconciliation, all interim counter transitions and other quests' markers. |

Do **not** mark a server discrepancy as confirmed merely because a private SQL row differs from stock Questie, or because a public synthetic CI test passes. Reports are evidence for human review, not an automatic correction queue.

## 2. Safety preflight (before any local command)

1. Use a **trusted development Linux checkout**, not the running AzerothCore worldserver directory or the installed WoW addon folder. On MobaXterm, these commands execute on whichever Linux host the SSH session actually connects to; confirm the host and working directory yourself.
2. Do not copy `acore_world.zip`, a real quest-input Lua file, private provenance fingerprint, individual private discrepancy report, credentials, or SavedVariables into a public Git working tree, issue or PR. The server-side archive remains offline and read-only.
3. Use a private directory with mode `0700` and files with mode `0600`, outside the checkout if practical. Do not use root or sudo solely for these read-only checks. Git ignores `private/`, but an outside directory is easier to keep separate.
4. Confirm the chosen checkout is on the **intended review commit** and clean. A green PR workflow on some other head is not a substitute for matching the local commit. Never run `git pull` against a live installation to conduct this pilot.
5. For this *offline, read-only* validation no installed-addon backup is needed because nothing is installed or altered. **Before any future in-game QA installation**, close WoW and back up the existing addon directory plus the relevant account/character `QuestieConfig` and `QuestieConfigCharacter` SavedVariables; verify rollback works. Only install a QA package after specific maintainer approval.

Example non-destructive preflight commands, run inside the development checkout:

```bash
pwd -P
git status --porcelain --untracked-files=all
git rev-parse HEAD
command -v lua5.1
command -v realpath
```

Stop if the Git status is not empty, the checkout is not the expected source, Lua 5.1 is missing, or the local file cannot be kept private. Do not publish raw terminal logs without inspecting them first.

## 3. Gate A — validate the real private M2.1 file (not yet completed)

The private Python exporter was synthetically tested, but its **actual private quest-1203 output** has not been validated by the real Lua 5.1 M2.1 parser.

From a trusted development checkout containing `cli/validate-m2-input.lua`:

```bash
lua5.1 cli/validate-m2-input.lua "/absolute/private/path/quest-1203.lua"
```

Replace the placeholder with the real absolute file path **locally**, never in public discussion. The CLI is read-only; it loads a Lua 5.1 **data literal via a restricted parser**, not ordinary executable Lua, and rejects malformed input and unsafe resolved paths.

**PASS requires all of the following:**

- Process exits 0 and prints `OK:` with the expected selected-record count and schema `nq-m2-input v1`.
- Independently confirm **privately** that the selected document is exactly the intended current server snapshot and includes quest 1203. Parser success establishes validity of the format and fields, **not** that the private exporter picked the correct quest.
- Compare the selected offline source row against the exported quest 1203 record: required item **3853 x1**, with the relevant other objective slots preserved, not silently defaulted.
- Preserve flags such as `hasConditions`, `ipGated`, `scriptedCredit` and KillCredit completeness as recorded; `unknown` and `false` are not interchangeable.
- Save the command's result in the private audit directory, without exposing full provenance or source label publicly.

If it says `REJECT:`, **stop** and investigate the local data/format mismatch. Do not hand-edit a real export until a source-checked, reproducible correction is identified. Do not relax the validator to make an input pass.

**Permitted public status:** e.g. `Real 1203 M2.1 file: PASS/FAIL; validated quest count: 1`. No source fingerprints, file paths, individual private server row dumps or file attachments.

## 4. Gate B — reproduce the *public* compiled 1203 pilot

This is a separate test and **does not load private server data**. Use a clean checkout of the reviewed M2.2 integration stack with GNU coreutils, Git, sha256sum and Lua 5.1.

```bash
mkdir -p "$HOME/nq-private/m2-pilot-1203"
chmod 700 "$HOME/nq-private/m2-pilot-1203"
tools/validation/run-m2-pilot.sh "$HOME/nq-private/m2-pilot-1203" 1203
```

To test the already-curated 16-quest selection use **a distinct output folder**, because the script writes new files and must not overwrite existing evidence:

```bash
mkdir -p "$HOME/nq-private/m2-pilot-list"
chmod 700 "$HOME/nq-private/m2-pilot-list"
tools/validation/run-m2-pilot.sh "$HOME/nq-private/m2-pilot-list" pilot
```

The wrapper requires a clean Git checkout, rejects five M0 negative cases before exporting, verifies all 232 checks / 28 reviewed level corrections / 82,431 fields, verifies known 1203 stock-versus-effective objective IDs, validates output provenance, and keeps files under the private directory. Re-running into the **same filenames** is deliberately refused; use a new private folder rather than forcing or deleting prior evidence.

**PASS:** script explicitly prints `PILOT PASS` for the requested mode. A wrapper success is not a successful private server comparison. If it fails, keep logs private and classify whether it is an environment, source revision, validation, coverage or output-path failure; do not bypass the guard.

The v1 pilot selection is: `1203, 2001, 498, 553, 786, 2784, 3377, 9666, 4022, 532, 10392, 1045, 611, 717, 30, 25`. These IDs are **representable**; this does not prove their server objective counts or locations.

## 5. Gate C — future private M2.3 report-only comparison (BLOCKED)

**Not executable now:** the production M2.3 batch engine is not implemented or approved. Do not invent a command or substitute an ad hoc comparison that reports `CONFIRMED_MISMATCH`.

When separately approved and implemented, the first real run must:

1. Validate the entire M2.1 server selection before touching output files.
2. Validate the effective export and **its paired coverage manifest** together, including version, quest membership and matched commit/tree/revision/correction fingerprint.
3. Verify that the server's SHA-256 archive fingerprint is validated independently and **never compared** with a Git SHA or a public correction fingerprint.
4. Produce one export status per selected quest; an M1 outcome only where comparison is supported. Clearly distinguish `M1_UNSUPPORTED_BY_RULES` and `NEEDS_MANUAL_REVIEW`.
5. Keep incomplete KillCredit, conditions, scripted behaviour, current IP eligibility, ambiguous target mapping and structural-only display scope from becoming false confirmations.
6. Use a no-clobber, fail-closed private report writer; malformed input or inconsistent provenance rejects the whole batch with no misleading partial report.
7. Examine quest **1203 first**. Only after reviewer sign-off should a small mixed item/NPC/GO batch be considered. The older 24-item / 151-NPC candidate groups are **candidates**, not approved corrections.

Any discrepancy should retain a reason code, the relevant source-evidence category and whether it is actionable or needs in-game confirmation. No automatic Lua correction generation or publishing private reports.

## 6. Gate D — optional in-game QA (requires separate approval and backup)

These checks describe **how to test later**, not permission to install a draft now.

Before changing the installed addon: close WoW; back up the currently working addon folder and the existing `QuestieConfig` / `QuestieConfigCharacter` SavedVariables in their account/character locations; confirm the backups are readable and restoration steps are known. Install **one** explicitly approved QA build only; preserve normal user preferences.

For each reviewed quest, record privately:

- Quest ID, UI quest title, character level/faction/class and confirmed effective IP stage, where independently known.
- Whether the quest is offered, in log, incomplete, completed or previously turned in; note prereqs and phase/condition evidence rather than guessing it.
- Quest-log objective **line count, order, target label, required count, current count** (screenshots may help).
- World-map and minimap marker presence; starter, objective and ender icon type; visible location versus actual currently active target.
- Marker behaviour on accept, an incremental objective update, completion, hand-in and a fresh login when feasible.
- Whether a candidate is hidden or scripted. Never bypass requirements just to force it to appear.

**Specific cases to queue:**

| Quest | In-game question | Current disposition |
| --- | --- | --- |
| **1203 — Jarl Needs a Blade** | Does the quest log ask for one Moonsteel Broadsword (3853)? Does N-Questie show the correct objective/turn-in markers under applicable player conditions? | Public effective item is verified; real private file still needs Lua 5.1 validation; no complete new in-game QA claim. |
| **2001 — Ravenclaw Cleanup** | Regression-check starter, servant/champion objective markers (1868/1869, 8 each), completed hand-in, marker removal; optionally observe interim counters and actual active spawn positions. | Initial in-game lifecycle PASS already recorded; additional checks outstanding. |
| **11142 — Survey Alcaz Island** | Count the actual quest-log lines and inspect whether the two apparent 500007 placeholders represent two distinct lines. | Hypothesis from public corrections only; do not deduplicate. |
| **12683 — Burning to Help** | Check two separate objective lines and marker intent; do not assume 28003 is a kill-credit assertion for line 1. | Public mapping is a location hint; do not collapse the lines. |
| **64128 — boosted Tauren Druid variant** | Only if the quest is genuinely visible/available: check the 'Speak to Tal' line versus the target currently associated with Frezza. | Hidden/blacklisted public-source anomaly candidate; no forced visibility or priority. |

A quest may require different expectations across progression stages. Document the actual stage and conditions rather than making a universal pass/fail claim.

## 7. Review classification and correction boundary

| Observation | Safe next action | Do not do |
| --- | --- | --- |
| Invalid private input | Fix exporter/selection **offline** after source verification; rerun Gate A | Skip validator or upload data to GitHub |
| v1 unsupported objective | Record coverage reason; defer to reviewed v2 schema | Drop fields, reorder, or deduplicate targets |
| Different quest-level numbers | Check correction overlays, level semantics and server source first | Automatically modify quest levels or availability |
| NPC/object mismatch | Determine whether it is a kill objective, map hint, KillCredit alias, phase/spawn issue or actual data defect | Treat each differing numeric ID as a confirmed bug |
| Marker at wrong location | Verify source spawn, map/zone conversion, phase/condition and Questie cache state | Invent world-to-map coordinates or directly alter live DB |
| Apparent missing quest | Verify compiled quest membership, player prerequisites, faction/IP visibility, cache, and quest-completion state | Force hidden/unsupported quests onto the map |
| Genuine reviewed defect | Open a **separate, field-scoped draft correction** with regression tests and maintainer approval | Bulk import private server tables |

## 8. Completion and handover checklist

- [ ] Gate A real selected 1203 file accepted by genuine Lua 5.1 (not yet evidenced).
- [x] Public Gate B 1203 and 16-quest wrapper pilots previously passed on their recorded commit; repeat on any future approved integration candidate where required.
- [ ] Gate A and B evidence paired to the correct recorded versions; no mixing unpaired inputs.
- [ ] Future M2.3 receives **separate** implementation approval and passes synthetic/negative suites.
- [ ] First **private** report-only 1203 comparison completed, with no unsupported inference.
- [ ] Review findings individually and decide whether any narrow correction proposal is justified.
- [ ] Before any future in-game QA, backed-up existing addon and SavedVariables verified; install separately approved.
- [ ] Quest 11142 log-line count verified when practicable; 64128 only if organically accessible.
- [ ] Only aggregate PASS/FAIL, counts and non-sensitive development facts shared publicly.

### Ownership

- **Grok:** v2 structure, exporter acceptance planning, M2.3 architecture, synthetic/CI tests and proposed marker-check architecture.
- **Lead / ChatGPT:** private-source evidence boundaries, pilot decisions, reviewed candidate triage and preparation of read-only operator procedures.
- **Maintainer:** approval of production implementation, any QA install, in-game observations, merger and release.

**This is a documentation-only safety and test plan.** It authorizes no production v2 exporter, M2.3 engine, client changes, corrections, merge, tag or release.

## 9. Archive fingerprint and snapshot freshness gate (before a future *real* comparison)

A valid `nq-m2-input` file is **not yet authenticated against the private archive it purports to represent**. `InputSchema.Validate` enforces the `sourceFingerprint` format, record types, exporter fields and internal count, but it does **not** open and hash the private SQL archive. A successful `OK:` therefore does **not** prove that the archive hash in the document is truthful, that the exporter read the intended archive, or that the snapshot describes the server's current running data.

Perform these additional checks locally and **never post hashes or paths to GitHub**:

1. Identify the exact private archive file and the offline exporter run that produced the selected quest-1203 Lua document. Keep their paths, archive name, exporter invocation and timestamps private.
2. On the trusted host, recompute SHA-256 over the **identical archive bytes the exporter read** (not a re-zipped or extracted substitute). Compare it privately with the `sha256:<64 lowercase hex>` value stored in the input's provenance. Record only `MATCH / MISMATCH / NOT VERIFIED` in the public status. A hash match proves byte identity to that archived file, **not** that the running server has not changed since the snapshot.
3. Separately verify that the archive's selected `quest_template` row and required objective/source/credit/conditions evidence represent **the intended snapshot**. Do not infer `killCreditComplete`, `ipGated`, `hasConditions` or `scriptedCredit` from missing SQL tables; incomplete evidence stays explicitly unknown.
4. Record the archive snapshot time and the export time **privately**. If the world DB may have changed since that snapshot, report the result as **historical-snapshot comparison** until a newer authorised read-only archive can be verified. Never claim current-world correctness from an older offline archive.
5. Any mismatch, missing original archive, unverifiable exporter version or uncertainty about exact hash source **blocks a confirmed real-data comparison**; stop rather than rewriting provenance or silently regenerating hashes.

The public status should say only, for example: `private 1203 format PASS; snapshot fingerprint MATCH; current-world freshness NOT VERIFIED`. If evidence is insufficient, say `NOT VERIFIED` rather than `PASS`.

This gate does not require connecting to the live DB. It does not authorise fresh backups, exporting new server data, installing the addon, or running production M2.3. It strengthens evidence hygiene before those steps are separately approved.
