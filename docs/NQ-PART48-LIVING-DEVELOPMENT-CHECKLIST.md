# N-Questie — Part 48 Living Development Checklist

**Opened 30 October 2026 (Europe/London). PUBLIC-SAFE. DRAFT / SOURCE RESEARCH / ISOLATED TESTS AND DOCS ONLY.** This checklist is a living Part48 plan, not release permission.

**MANDATORY new-chat entry: read BOTH COMPLETE files before engineering:**
1. [Complete Part47 → Part48 Engineering Handover](HANDOVERS/2026-10-30_PART47_TO_PART48.md).
2. **This entire Part48 Living Development Checklist**.

Then consult the [Part47 Living Checklist](NQ-PART47-LIVING-DEVELOPMENT-CHECKLIST.md), [Whole-Project Master Checklist](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), [native observation gate](research/NQ-PART47-NATIVE-335-EVIDENCE-OBSERVATION-GATE.md), and [central team coordination PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42). Historical Part47 pending CI snapshots are superseded by independently checked final statuses below.

## A. Protected 335, approval and provenance — mandatory

- [x] Independently rechecked **30 October 2026**, protected live `335` exact SHA **`26053bd28b0df3a01e5859f779d5f3cb4f57b221`**, `protected=true`, owner-approved README-only scope. No gameplay addon code merged in Part47.
- [x] Actual immutable historical original 335 addon code pin **`8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`** is NOT live `335`; source tests SHA authenticate nine Git blobs. See handover table.
- [x] **Gate08 MAJOR RED**, **439 RAW candidates NOT owner-approved**, eligible denominator UNKNOWN, pilots **1207–1209 = 0/3 implemented**. **No playable Alpha0 or accepted native QA**.
- [ ] No production addon Lua/SQL/TOC/DBC/server/DB changes, ZIP/build/install/merge/tag/release, user/character/account/SavedVariables access, client testing or visibility changes without **fresh specific owner permission**. README-only approval does NOT transfer to feature testing.
- [ ] Native QA, if later explicitly approved, must stay on disposable staging with exact source/client/server identity, verified snapshots/backups + file hashes + independently proven rollback and privacy protections. A docs-only observation plan is NOT approval.
- [ ] The project is intentionally PUBLIC and unfinished. Preserve clear prominent **no-emoji WIP README warning**, existing fork state and repository protections.

## B. Final Part47 source and CI status — independently verified

- [x] [TEST-ONLY DRAFT #420](https://github.com/CosmicCuddle/N-Questie/pull/420) original frozen **`481069bdf369bbec4028e030b8ae21ecb4dba4db`**, **37/37 full exact-head GitHub Actions SUCCESS** confirmed 30 Oct 2026; dedicated [run 40915500741](https://github.com/CosmicCuddle/N-Questie/actions/runs/40915500741) job `123594503787`, **19 NEW + 894 inherited = 913/913 EXECUTED EACH actual Lua5.1.5 + 5.4.6**, nine historical original SHA source blobs verified, clean checkout, **ZERO artifacts**. OPEN DRAFT UNMERGED. Exactly three TEST/CI/RESEARCH paths, no production source.
- [x] [DOCS-ONLY DRAFT #421](https://github.com/CosmicCuddle/N-Questie/pull/421) original frozen **`23de949b3cabaa7f057a67bf65735204c6e12e44`**, **7/7 full exact-head Actions SUCCESS** confirmed 30 Oct 2026; exactly TWO append-only checklist files, 15 lines added and 0 deleted. OPEN DRAFT UNMERGED.
- [x] Historic original RED tests **#390, #396, #397, #405, #406, #407, #414, #415** remain frozen failures; separate corrected green descendants (#392, #398, #408, #416) are not retroactive edits. All other Part47 original green test/docs SHA heads preserved. Review chronology in complete handover.
- [ ] Independently refresh protected branch, latest relevant PR #42 comments and these **exact original heads** on Part48 entry; do not mistake a draft child for live source.

## C. The new original-event and WasComplete source boundary — proved vs UNKNOWN

- [x] Historic 335 client completeness usually **1 complete / -1 failed / nil otherwise** (client numeric `0` is NONCANONICAL); genuine original `QuestieDB.IsComplete` maps cached client `nil` with an objective to **addon internal numeric 0**. Source code explicitly distinguishes client and addon-level transitions.
- [x] Original QuestLogCache can retain normalized forced completed 2/2 values after **FABRICATED** client `1→nil` with unchanged raw incomplete objective 0/2. Genuine first-party QuestieQuest UpdateQuest can reset WasComplete on original DB internal 0, but a later **changed-quest** UpdateQuest can set it true again through all-objectives-complete fallback.
- [x] #420 executes complete genuine first-party `QuestEventHandler.OnEvent`, `QuestWatchUpdate`, `QuestLogUpdate` and `UpdateAllQuests` source bodies with original whole QuestLogCache + DB/Quest methods under fake client APIs. **QUEST_LOG_UPDATE alone may not rescan; Watch+Log can scan**. Repeated identical events with **NO cache delta do not automatically rerun UpdateQuest or remark WasComplete**. A fabricated title change produces a new genuine source update; fabricated raw objective change restores incomplete objective state.
- [x] Other isolated first-party source under fake APIs covers original 335 Compat reward/abandon routing, original AnimationGroup C_Timer/ThreadLib/CombatQueue lifecycle, source startup RegisterEvents-to-queue window, original cache states, and conditional missing-SetAbandonQuest nil forwarding. See handover.
- [ ] Real client quest flag `1→nil` with identical raw objectives **NOT observed**. Real 335 QUEST_ACCEPTED/QUEST_WATCH_UPDATE timing, original whole-addon RegisterEvents/Posthook/CombatQueue interaction, real AnimationGroup tick scheduling, abandonment hook order, player-facing WasComplete/objective behaviour, AzerothCore/IP compatibility **UNKNOWN**.
- [ ] **No native gameplay bug, production fix, regression acceptance or Alpha0 claim** from synthetic 913-per-interpreter checks.

## D. Part48 priority decisions

- [ ] Before adding another fake-host suite, identify **one new first-party method contract or untested causal dependency** and why it materially reduces native uncertainty; otherwise avoid unnecessary assertion-count inflation.
- [ ] Determine with owner whether and when the next genuinely useful step is **separately authorized disposable native QA**. Be transparent about what is and is not currently testable; do not offer an unverified ZIP, ask for live client access, or tell user to pull/recompile prematurely.
- [ ] If separately approved, plan privacy-safe staging read-only event traces for (a) startup registration vs queue initialization, (b) client completeness and raw objectives across real client events, (c) WasComplete normalized state, (d) abandon selection/hook ordering, and (e) actual 335 AnimationGroup callbacks. Verify backups, file hashes and rollback **BEFORE** touching native setup.
- [ ] For allowed isolated TEST/DOCS work: new branch from last independently green **same-lane frozen original head**; **DRAFT PR only**; never edit `335`, original red heads, or hash pins. Exact-checkout original source and both actual Lua5.1.5 / 5.4.6, inspect dedicated and wider exact-head Actions, ensure clean checkout and zero artifacts.
- [ ] Check peer coordination for new **verifiable** evidence. CS02/Grok earlier mutant study closed by #378; CS03/Claude native-client timing conclusions unverified. Do not fabricate peer replies or reassign repetitive tasks.
- [ ] Append new independently verified evidence to Part48 and master checklists, and update [PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42) only on a meaningful new milestone. Preserve negative test heads and historical source provenance.

## E. Part48 handover PR verification

- [ ] Record the original frozen submitted SHA, changed-file census, GitHub compare, 7/7 or other **actual** original-head docs CI status for this Part48 handover/checklist **after the DRAFT PR has been opened and verified**. Do not pre-credit any CI.
- [ ] Once verified, hand the new chat the exact handover URL and checklist URL pinned to this Part48 docs-only head. Both entry documents must be read fully.
- [ ] Keep production `335` last-known SHA and Gate08 MAJOR RED as frozen status unless separately verified fresh state and owner-approved change.

**No gameplay/source edits, actual native client QA, package, install, merge or release are authorised by this checklist.**
