# N-Questie — Private M2 Objective Data Intake Handover

**14 October 2026 · Local-only preparation · Draft/read-only · No public quest-data import**

## Private exporter version 2 — historical safety evidence preserved from PR #19

This section preserves **locally reported** evidence from [draft PR #19](https://github.com/CosmicCuddle/N-Questie/pull/19), without copying private source, generated quest records or the offline archive to GitHub. The exporter itself is a separate local-only Python tool; the statements below come from its prior handover, **not from a fresh independent run in this public repository**.

- **Synthetic tests:** Version 2 reportedly passed **25 Python synthetic cases** (12 earlier tests plus 13 fail-closed cases). In particular, it rejects negative required item IDs/counts and invalid starting/source-item values, positive objective counts without target IDs, malformed/negative KillCredit pairs, unjustified completeness claims, missing or altered `"unknown"` condition/IP/script flags, invalid provenance, and duplicate or overlapping explicit creature candidate lists. **Signed negative NPC/GO IDs remain valid** to represent gameobject objectives; rejecting all negative targets would corrupt that distinction.
- **Private-output safeguards:** The local tool reportedly uses restrictive Unix `0600` output permissions, an atomic no-clobber link for a previously absent destination (unless explicitly approved to overwrite), and checks for destinations **inside any Git checkout**, including cases involving symlinks. These are *reported local-tool properties*, not a claim that the public GitHub code contains this private exporter.
- **Limits of atomicity:** A no-clobber link prevents silent replacement and provides atomic file visibility; it does **not** guarantee power-loss durability. No `fsync` protection is being claimed for the private exporter here.
- **Read-only archive pilot:** The prior report confirms only the public, minimal facts for quest **1203** (required item **3853 ×1**) and quest **2001** (creatures **1868 ×8** and **1869 ×8**) and the presence of selected creature KillCredit records in an offline archive. Selected rows, original ZIP contents, source hashes, exporter implementation and private reports remain outside GitHub. Its deliberately incomplete evidence flags stayed `killCreditComplete=false` and `hasConditions/ipGated/scriptedCredit="unknown"`.

### Lua 5.1 and source authenticity — two separate outstanding gates

The **historical private exporter output was parsed using Lua 5.4**, not Lua 5.1, as recorded in PR #19. Since then, **public synthetic Lua 5.1** M2.1 parsing and selected-1203 gate tests have passed on [draft integration PR #48](https://github.com/CosmicCuddle/N-Questie/pull/48) at `780e89cbe2957e8c65c33a95b4ebe61c50f33587` (all six public CI workflows green). This is **not** evidence that the actual locally generated private quest-1203 Lua document has been parsed under Lua 5.1.

The [read-only operator gate](NQ-PRIVATE-1203-GATE.md) may also compare the original offline archive's bytes against the private input's declared SHA-256, with paths and digests kept private. Even a matching digest **does not independently establish which archive the exporter read** or that the running AzerothCore world database is unchanged. Those source-selection and freshness checks remain human-reviewed, private prerequisites.

**Current checkpoint:** Genuine private quest-1203 Lua 5.1 validation and original-archive provenance remain **NOT VERIFIED** on PR #48. The production v2 exporter Stage A1 is a separate approved **draft development task**, not a working private export or approval to merge PR #48. No private rows are committed, and no live server, installed addon or SavedVariables change is authorised.

---

## Ownership and context at the earlier handover (historical)

- **Grok's framework:** [draft PR #18](https://github.com/CosmicCuddle/N-Questie/pull/18) refines the M1 report-only objective rules, with conservative KillCredit and multi-target matching. Grok remains responsible for M2 input schema, effective-Questie export, batch engine and framework tests; M2 framework implementation has **not** started.
- **Lead developer's private intake:** A **standalone Python 3 exporter has been developed and tested privately**, outside the GitHub repository, on the user-supplied **offline** `acore_world.zip`. The actual converter, full SQL ZIP, generated Lua/JSON rows and private audit reports are **NOT in this PR or GitHub**. Only this non-sensitive contract and progress checkpoint are published.
- **Integrated baseline:** [draft PR #16](https://github.com/CosmicCuddle/N-Questie/pull/16) is the 28-level/3.3.5a-M0/CI test integration branch with all four automated workflows previously green. This documentation branch is stacked on #16 for review only; it does not edit Grok's M1 branches.

## Private exporter — original baseline at the earlier handover (historical)

- Streams a HeidiSQL `.sql` or single-SQL `.zip` **read-only**, without extracting the database archive.
- Accepts **one to fifty explicitly selected quest IDs** and reads only their `quest_template` objective columns.
- Exports numeric fields needed by M1:
  - `ID`, `StartItem`, `ItemDrop1`–`ItemDrop4`
  - `RequiredNpcOrGo1`–`RequiredNpcOrGo4` and `RequiredNpcOrGoCount1`–`RequiredNpcOrGoCount4`
  - `RequiredItemId1`–`RequiredItemId6` and `RequiredItemCount1`–`RequiredItemCount6`
- Optional **private, reviewer-authored manifest** `{questId: [creatureId, ...]}` requests selected `creature_template.KillCredit1/2` records. The exporter does not auto-infer which Questie creatures it has fully covered.
- **All quests are explicitly tagged** `killCreditComplete = false`, `hasConditions = "unknown"`, `ipGated = "unknown"`, `scriptedCredit = "unknown"`. It never silently turns unknown restrictions into false/unrestricted eligibility.
- Records a private source fingerprint (SHA-256 of the input offline archive) and UTC export date as `provenance`, without including absolute file paths or account/realm credentials.
- Writes a selected quest-ID-keyed numeric Lua 5.1-shaped table **or** JSON in a private location, with atomic write and restrictive Unix `0600` permissions. Refuses output inside its public checkout, source-file overwrite, existing-report overwrite without explicit approval, unsupported schema, missing quests, duplicate records and bad integers.
- **Do not conflate this selected record table with M1's cases table.** The final M2 schema adapter and effective-record pairing will be reviewed after Grok completes PR #18 and proposes the actual M2 schema.

## Private source verification — earlier local run (no raw dumps published)

The local 12-case synthetic Python suite **PASSED**, covering ZIP and SQL parsing, positive/negative/GO objectives, explicit creature row lookup, incomplete KillCredit, malformed rows, private output guards, and tri-state provenance.

A separate **read-only** real-world run on the user-provided archive succeeded:

| Quest | Minimal confirmation | What is *not* inferred |
|---|---|---|
| **1203 — Jarl Needs a Blade** | Required item **3853 × 1** | Does not prove current character/IP eligibility or in-game behaviour |
| **2001 — Ravenclaw Cleanup** | Creature targets **1868 × 8** and **1869 × 8**, selected creature KillCredit rows located | Does not prove every alternate credit, spawn accuracy or scripted/phase availability |

The results were written to **private files outside GitHub**, not into this repository. No server or installed addon was accessed or changed. **Lua output has not yet been independently parsed by a Lua 5.1 interpreter**, and the future effective-record M2 integration is not implemented.

## Originally proposed interface checks before M2.4 real-data runs (historical)

1. **Grok completes PR #18 QA** (all expected negative tests, Python tooling, and full Busted test stack with PR #4 shim in a temporary branch). Record actual GitHub evidence; do not claim all checks green on #18 while inherited CI remains without #4.
2. **Grok M2.1 input contract** defines exact Lua/JSON batch schema and validates that all three tri-state flags are explicit and well-formed, `KillCredit` covers all relevant creature IDs before setting `killCreditComplete=true`, and provenance is present.
3. The private exporter needs a small **local-only mapping update** if Grok's final schema differs. Do **not** convert every unknown to `false`, or mark KillCredit complete merely because a creature row was selected.
4. **M2.2 effective records** must be produced by the **validated 3.3.5a post-correction Questie database**, not by assuming the raw `wotlkQuestDB.lua` record is effective. Retain M0's strict preservation check and 28-quest allow-list.
5. Run M2 first on **quest 1203**, then a **small, manually reviewed** group (including objective/gameobject/kill-credit edge cases). Only after expected classifications and non-mutation checks pass should the maintainer consider broader private runs.
6. **No automatic quest fixes** from `CONFIRMED_MISMATCH`; human evidence review and a separate approved correction PR are mandatory. Preserve all full per-quest results privately.

## Safety and collaboration gates

- Only public code and synthetic fixtures may be used in GitHub CI. The private `acore_world.zip`, private original `wotlkQuestDB.lua`, full mismatch workbook and private selected rows do not belong in public GitHub.
- Keep private generated outputs **outside** the public checkout for now, even though Grok's M2 plan proposed a gitignored `private/` folder. This stronger default avoids accidental inclusion; agree on a safe shared path convention before M2's batch runner is implemented.
- Never edit Grok's original PR #15/#17/#18 branches from this workstream.
- No live world SQL writes, Individual Progression or playerbot changes, installed client replacement, SavedVariables reset, merge/release/tag or Addon Collection update without maintainer approval.

**Historical checkpoint (initial version, superseded by the v2 and PR #48 status above):** Private intake prototype worked for selected real quest records and 12 synthetic cases. M2 validator, batch reporting, classification of the 24 item / 151 NPC candidates and in-game QA were pending at that earlier point.
