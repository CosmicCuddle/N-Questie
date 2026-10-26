# N-Questie — Missing-Quest Coverage & Implementation Programme

**Part 35 · 26 October 2026 · PUBLIC-SAFE DEVELOPMENT PLAN — NOT A PRODUCTION PATCH**

## Objective

Our long-term goal is to investigate the **complete 439-record server-only-versus-raw-WotLK-Questie research inventory** and provide N-Questie coverage **only for quests independently verified as missing, playable, source-correct, Individual Progression-eligible and individually authorised**. This is NOT a promise to implement 439 addon records. Nor does completing quests 1207, 1208 and 1209 finish this programme.

The current Living Development Master Checklist records this as **Milestone 10: Missing-Quest Coverage & Implementation Programme**; **the first pilot** is 1207–1209, with **0/3 implemented**. Owner-authorised development Gates 10–12 remain technically pending and are not blanket source/release approval.

Authoritative evidence stays separated:
- [Raw missing-quest audit draft #164](https://github.com/CosmicCuddle/N-Questie/pull/164): four PUBLIC-SAFE, unmerged documents; private reports and source rows NOT in the public repository.
- [Living project master checklist draft #96](https://github.com/CosmicCuddle/N-Questie/pull/96): authoritative twelve-milestone statuses and current development evidence.
- [Gate 05/08 production acceptance contract](research/NQ-PART34-EFFECTIVE-OWNER-TRANSACTION-ACCEPTANCE.md): effective forward/reverse NPC/GO/item ownership and safe compiler publication are **not** production-implemented.

## Audited universe — exact counting, not a release target

| Classification | Count | Current disposition |
|---|---:|---|
| Source-linked first-pass candidates | **12** | **Review only / inclusion undecided**; three lower-level, seven AQ/event, two class/faction slots, tracked with public aliases in #164 |
| Exploratory server-only records without both conventional relation types | **418** | **Unresolved investigation**; item-started, scripted/event/progression-gated or obsolete quests require different evidence routes |
| Owner-excluded quests 30000–30004 | **5** | **DO NOT INCLUDE**, until the owner explicitly changes the decision |
| Identified placeholders/development records | **3** | **Not proposed** for implementation |
| Existing N-Questie overlay quest 2001 | **1** | **Already handled**; preserve previously observed basic gameplay lifecycle and finish the separate unproven QA axes |
| **Total raw server-only research universe** | **439** | **12 + 418 + 5 + 3 + 1 = 439** |

Historical shorthand "12 review + 9 deferred + 418 exploratory" combines **five true owner deferrals, three placeholders and one already-covered quest** into the number nine. **Nine are not nine owner-deferrals.** The separately reported **21** conventionally NPC/GO linked records consist of 12 + 5 + 3 + 1; their links are not proof that the server offers them. The effective compiled Questie set is a different baseline from the raw ID count.

The **pilot quests 1207–1209 are NOT a thirteenth-through-fifteenth bucket**. Their exact private mapping into the above 439 categories has not been established for this public document. Only the owner's statement that those three are offered to players is confirmed; their source/NPC/GO/item/loot/IP details remain private and unverified. **0/3 pilot implemented** is the only defensible implementation numerator here. Do not report “0/439 implemented,” “439 quests missing from the effective DB,” or a percentage complete.

## Delivery model — batches, not one mass import

| Stage | Work | Exit gate / owner of decision |
|---|---|---|
| P0 — Evidence baseline | Preserve the 439 original private rows, source revision and raw/effective Questie comparisons in owner-controlled storage | Reproducible audit and no exposure on GitHub |
| P1 — First playable pilot | Test quests 1207–1209 individually, but do not assume they occupy public aliases LOW-01..LOW-03 | Each verified privately for offered status, true starter/finisher, conditions, loot and IP; owner individually accepts source facts; runtime protections complete |
| P2 — First-pass linked group | Assess 12 anonymised public review slots in #164; do not infer inclusion from SQL links | Each slot classified, evidenced and explicitly approved or deferred; no blanket insertion |
| P3 — Expanded exploratory triage | Investigate all 418 remaining research records in small groups: item starter; scripted/event; faction/class/prerequisite; source-less/obsolete; present-but-filtered | Separate per-quest private evidence and documented reason for absence, exclusion or eligible implementation |
| P4 — Controlled implementation | Generate/add only independently reviewed, eligible and owner-authorised records from any approved wave | Provenance manifest, consistent effective NPC/GO/item F==R, writer/epoch or immutable snapshot, four-category compiler transaction/recovery, Lua5.1 exact-head CI |
| P5 — Client/IP QA | Test each actual included batch with separately authorised client access and backups | Source/offering and starter marker, intermediate objectives, finisher, relog/refresh, faction/IP eligibility, phase/spawn position, memory/GC/frame and rollback |
| P6 — Integration/release | Combine only accepted batches with clear provenance; inventory shows covered/filtered/deferred/unresolved | Peer review, exact-head CI, complete artefact/licensing audit, owner authorisation, package/install/release gates |

P1 may progress before all P2/P3 investigations finish, but **the programme cannot be marked COMPLETE when the three pilot quests are done**. Conversely, it does not require inserting every record; a documented **correctly excluded / already-covered / not-playable** disposition is legitimate coverage of the research universe.

## Per-quest evidence and statuses (private mapping only)

The owner-private tracker must retain the quest ID, audit bucket, source snapshot fingerprint, raw-versus-effective Questie status, server offer evidence, owner NPC/GO/item starter/finisher relationship, item objective versus item starter distinction, scripted/event conditions, Individual Progression phase/class/faction/prerequisites, permitted marker types, peer review, owner decision, implementation ref, in-game QA and rollback result. Never copy this tracker, SQL rows, NPC/GO/item/loot mappings, or private filenames to public PRs or CI logs.

A generic state machine may use:
`UNREVIEWED` → `EVIDENCE_IN_PROGRESS` → one of `PRESENT_BUT_FILTERED`, `ALREADY_COVERED`, `OWNER_DEFERRED`, `NOT_PLAYABLE`, `CONDITIONAL_OR_IP_UNKNOWN`, `SCHEMA_UNSUPPORTED` or `MISSING_AND_ELIGIBLE`. Only after verified provenance and a **per-quest owner approval** can `MISSING_AND_ELIGIBLE` become `APPROVED_TO_IMPLEMENT`, then `IMPLEMENTED_IN_DRAFT`, `QA_PASSED` and `ACCEPTED_IN_RELEASE` following each separate gate. `CONDITIONAL_OR_IP_UNKNOWN` **never** authorises always-on quest markers.

For public status reporting, show **aggregate counts only**: 439 reconciled, 12 first-pass pending, 418 exploratory to classify, five owner exclusions, three placeholders, one existing overlay, 0/3 pilot implemented; later show verified dispositions and approved-batch progress *only when privately supported*. Do not pretend an unknown total of eligible quests is known.

## Current engineering blockers before any new quest insertion

1. [#168](https://github.com/CosmicCuddle/N-Questie/pull/168) item-only postflight passes pinned codec/loader tests, but NPC/GO reverse safety remains a known gap.
2. [#171](https://github.com/CosmicCuddle/N-Questie/pull/171), [#172](https://github.com/CosmicCuddle/N-Questie/pull/172) and [#173](https://github.com/CosmicCuddle/N-Questie/pull/173) are isolated fictional ownership test evidence, NOT the required production-wide effective verifier or faction/late-writer protection.
3. [#167](https://github.com/CosmicCuddle/N-Questie/pull/167) and [#174](https://github.com/CosmicCuddle/N-Questie/pull/174) supply Lua5.1 compiler and coroutine lease research only. Production stream lifetime, source epoch/ABA, four-category staging, checked SUCCESS/BUSY/RETRY/ERROR and revision advancement remain unsolved.
4. Actual 3.3.5a client, Individual Progression, memory/framerate, SavedVariables, cache and marker acceptance cannot be inferred from synthetic CI.

No package, public SQL/private provenance, addon installation, release, protected-`335` push or per-quest source addition is authorised by this document.

## Operational handover and next engineer assignments

**CS01:** own whole-programme progression, public-safe aggregate counters, private-evidence gate design, source-backed production acceptance and reciprocal code review. Prevent short pilot work from closing the 439-record programme.

**CS02 (Grok):** existing primary [#173](https://github.com/CosmicCuddle/N-Questie/pull/173) exact-head independent mutations; backup [#174](https://github.com/CosmicCuddle/N-Questie/pull/174) coroutine lease analysis and [#167](https://github.com/CosmicCuddle/N-Questie/pull/167) four-category compiler transaction. Future no-idle public-safe backup: review the P0–P6 batch state machine, especially unsafe assumptions that conventional starter links establish playable quest availability; no private per-quest workbook access or invented relations.

**Owner:** no repeat approval required for already-approved safe development Gates 10–12. Specific new quest data, private source/IP conclusions and client/install/release decisions remain independently gated. The owner controls the private mappings and eventual QA.
