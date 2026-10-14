# N-Questie — Private M2 Objective Data Intake Handover

**14 October 2026 · Local-only preparation · Draft/read-only · No public quest-data import**

## Latest private intake hardening — version 2 (14 October 2026)

The standalone **local-only** objective exporter was upgraded without replacing its previous package or publishing its implementation/private outputs. The **24-case synthetic Python suite PASSED** (12 original plus 12 new fail-closed tests). Version 2 now rejects negative item IDs/counts/start/source items, missing target IDs with positive counts, malformed or negative creature KillCredit pairs, unsafe completeness claims, omitted/changed `"unknown"` script/condition/IP flags, invalid provenance, and duplicate/overlapping creature candidate lists. Signed **negative NPC/GO IDs remain valid** for AzerothCore gameobject objectives.

The private output remains atomically written with Unix `0600` permissions. A new **atomic no-clobber** link step prevents an output appearing mid-run (including an existing dangling symlink) from being silently replaced when `--overwrite` was not supplied.

**Read-only real-archive regression:** Quest 1203 required item **3853 × 1**, quest 2001 creatures **1868 × 8 / 1869 × 8**, and selected creature KillCredit rows were read successfully from the maintainer's original offline ZIP. Only the two requested quests were exported to files outside the checkout. The exported rows retained `killCreditComplete=false` and `hasConditions/ipGated/scriptedCredit="unknown"`; source archive and all per-quest rows remain strictly private.

**Lua syntax qualification:** Generated Lua data parsed successfully through the locally available **Lua 5.4** library; an actual Lua **5.1** interpreter was not available in this private environment. Therefore **Lua 5.1 execution remains unverified** until tested with the M2 framework under its required version. The final M2 schema and report engine are still pending.

**Cross-workstream progress:** Grok reported completing PR #18's outstanding 4 negative fixtures, temporary PR #4 full Busted (**49 passed**) and Python tools (**28 passed**). Separately, [PR #20](https://github.com/CosmicCuddle/N-Questie/pull/20) combined the safer M1 report-only rules with the strict 28-level M0, and **all five GitHub workflows passed** at commit `76cbdb2945d4afd0e38aa5c2ce6aa7963f07e975`. No source PR was merged and no server/client runtime was changed.

## Ownership and current context

- **Grok's framework:** [draft PR #18](https://github.com/CosmicCuddle/N-Questie/pull/18) refines the M1 report-only objective rules, with conservative KillCredit and multi-target matching. Grok remains responsible for M2 input schema, effective-Questie export, batch engine and framework tests; M2 framework implementation has **not** started.
- **Lead developer's private intake:** A **standalone Python 3 exporter has been developed and tested privately**, outside the GitHub repository, on the user-supplied **offline** `acore_world.zip`. The actual converter, full SQL ZIP, generated Lua/JSON rows and private audit reports are **NOT in this PR or GitHub**. Only this non-sensitive contract and progress checkpoint are published.
- **Integrated baseline:** [draft PR #16](https://github.com/CosmicCuddle/N-Questie/pull/16) is the 28-level/3.3.5a-M0/CI test integration branch with all four automated workflows previously green. This documentation branch is stacked on #16 for review only; it does not edit Grok's M1 branches.

## Private exporter — currently tested functionality

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

## Private source verification (no raw dumps published)

The initial 12-case synthetic Python suite **PASSED** (now expanded to **24 passing tests** in version 2), covering ZIP and SQL parsing, positive/negative/GO objectives, explicit creature row lookup, incomplete KillCredit, malformed rows, private output guards, and tri-state provenance.

A separate **read-only** real-world run on the user-provided archive succeeded:

| Quest | Minimal confirmation | What is *not* inferred |
|---|---|---|
| **1203 — Jarl Needs a Blade** | Required item **3853 × 1** | Does not prove current character/IP eligibility or in-game behaviour |
| **2001 — Ravenclaw Cleanup** | Creature targets **1868 × 8** and **1869 × 8**, selected creature KillCredit rows located | Does not prove every alternate credit, spawn accuracy or scripted/phase availability |

The results were written to **private files outside GitHub**, not into this repository. No server or installed addon was accessed or changed. **Lua output has not yet been independently parsed by a Lua 5.1 interpreter**, and the future effective-record M2 integration is not implemented.

## Proposed interface checks before M2.4 real-data runs

1. **Grok PR #18 QA is complete according to the contributor's recorded local results:** four negative fixtures rejected as intended, Python tooling 28 tests, and 49 Busted checks with PR #4 applied in a disposable branch. The isolated Grok PR #18 inherited CI remains red without #4, while combined PR #20's five workflows all passed. No code change or merge to the original contributor branch is implied.
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

**Current status:** Private intake version 2 **works for selected real quest records** and 24 synthetic cases, including safe no-clobber writes and additional source-shape validation. **M2 validator, batch reporting, classification of the 24 item / 151 NPC candidates and in-game QA remain pending.**
