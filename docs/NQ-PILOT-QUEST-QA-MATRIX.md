# N-Questie — Curated 16-Quest QA Matrix and Evidence Gates

**Status:** DRAFT test planning. No new source inspection, live quest testing or private M2.3 comparison claimed here.  
**Public evidence baseline:** `docs/NQ-VALIDATION-M2.2-PILOT.md` (compiled quest records); `docs/QUEST-2001-SMOKE-TEST.md` (maintainer's in-game observations).  
**Operational safety and backups:** `docs/NQ-PRIVATE-1203-PILOT-AND-INGAME-QA.md`.  
**Date:** 14 October 2026. **All quests below are v1-representable in the recorded 9,159-quest baseline.**

## 1. What "passed" means — never mix the three levels

| Level | Evidence needed | Status right now |
|---|---|---|
| **A. Public compiled export** | M0 passes, effective records reconstruct exactly what the N-Questie compiled DB contains. | **PASS** for the 16-quest v1 pilot on the recorded commit. Does **not** verify the server. |
| **B. Real private server comparison** | Genuine Lua 5.1 validation of the server's selected `nq-m2-input` file, then separately approved M2.3 versioned comparison with paired coverage manifest. | **NOT RUN**; real private file not yet validated by Lua 5.1 and production M2.3 not implemented. Existing prior offline SQL readings for 1203/2001 are not a completed M2.3 batch. |
| **C. In-game marker/behaviour QA** | Approved QA build after backup; eligible character; actual quest log, marker presence, location and lifecycle recorded. | **Partially PASS on 2001 only**, for starter, initial targets, completed turn-in and post-hand-in removal. All other listed quests untested under this QA matrix. |

`CONFIRMED_MISMATCH` in any future M2.3 report is still a **review candidate**, not automatic permission to modify Lua, quests, maps or the live server. Server eligibility, current phase, Individual Progression stage, scripted credit and active spawns cannot be assumed from static compiled Questie data.

## 2. The 16-quest public compiled checklist

The following objective IDs/values are from the **effective compiled N-Questie pilot**. They are **not** claims that all matching server records, quest-log lines or spawn positions have been checked.

| Order | Quest ID | Compiled objective shape to exercise | Primary check before claiming equivalence | Evidence checkpoint |
|---:|---:|---|---|---|
| 1 | **1203** | Item **3853**; levels **30/35** | Verify private `nq-m2-input` under Lua 5.1; compare one required 3853 in actual offline server row. Later: quest log, objective item and turn-in marker on an eligible character. | Public export PASS. Private M2.1 Lua validation outstanding; no new in-game QA claim. |
| 2 | **2001** | NPCs **1868** and **1869**; levels **12/16** | Preserve distinct kill lines (8 each on server source) and prereq 437; later check intermediate counter updates and actual spawn/phase positions. | Public export PASS; source-checked server facts and partial in-game lifecycle PASS. |
| 3 | **498** | Gameobjects **1721**, **1722**; required source items **3467**, **3499** | Two GO objective markers plus distinct source-item relationships; do not treat an item-source marker as direct GO credit. | Public export PASS; server/in-game unverified. |
| 4 | **553** | Gameobjects **1768**, **1769**, **1770**; source item **3710** | Three independent GO objectives and source-item behaviour, without inventing item drops or GO spawns. | Public export PASS; server/in-game unverified. |
| 5 | **786** | Gameobjects **3189**, **3190**, **3192** | Distinct three-line GO ordering, counts, marker placement and completion transitions. | Public export PASS; server/in-game unverified. |
| 6 | **2784** | KillCredit IDs/root **{7572}/7572** | Resolve actual KillCredit mechanism and whether server evidence is complete before any comparison confirms. | Public export PASS; server/in-game unverified. |
| 7 | **3377** | KillCredit IDs/root **{8436}/8436** | Confirm exactly what server credits count; unknown script/alternative credit = manual review. | Public export PASS; server/in-game unverified. |
| 8 | **9666** | NPC **17701**, KillCredit **{17701}/17701**, source item **24084** | Same ID appears in more than one **objective kind**; preserve quest-log positions and distinguish kill and credit from source item. | Public export PASS; server/in-game unverified. |
| 9 | **4022** | Item **10575**, KillCredit **{9459}/9459** | Mixed kinds and relevant source/credit evidence; do not flatten into one target. | Public export PASS; server/in-game unverified. |
| 10 | **532** | NPCs **2335**, **2387**; GO **1761**; item **3657** | Creature/GO/item coexistence with correct per-kind quest-log ordering and separate markers. | Public export PASS; server/in-game unverified. |
| 11 | **10392** | NPC **19298**; GO **182935**; item **29795**; required source item **29795** | Same item is both objective and required source; avoid double-counting, verify map source separately. | Public export PASS; server/in-game unverified. |
| 12 | **1045** | NPCs **3696**, **3932**; item **5388**; source item **5462** | Distinct item source from required item; independent NPC positions. | Public export PASS; server/in-game unverified. |
| 13 | **611** | Item **4034**, source item **4027**, required source items **4034**, **4027** | Item-source and required-source overlap; avoid invented extra quest-log objectives. | Public export PASS; server/in-game unverified. |
| 14 | **717** | Items **4615**, **4645**; source **4640**; required sources **4843**, **4844**, **4845** | Multiple source pathways; do not infer drops/locations without verified item-source records. | Public export PASS; server/in-game unverified. |
| 15 | **30** | Item **15885**; required sources **15883**, **15882**; questLevel **-1**; spawn-only extra objective | Retain scaling-level sentinel `-1` and special marker existence. **The v1 export does not prove exact custom spawn coordinates**, which belong in future marker validation. | Public export PASS; server/in-game unverified. |
| 16 | **25** | NPC **3917** plus `triggerEnd` | Verify trigger completion and event-line relationship. Static structure cannot independently prove scripted completion/marker behaviour. | Public export PASS; server/in-game unverified. |

**Do not interpret these numeric IDs as in-game line counts** without checking actual quest logs. The compiled data demonstrates an intended structure; it does not establish current server conditions or exact marker coordinates.

## 3. Safe sequence for moving from public pilot to real evidence

1. **Gate A — only 1203:** Run the real exported private `quest-1203.lua` through `lua5.1 cli/validate-m2-input.lua "/absolute/private/path/quest-1203.lua"` on a trusted, separate Linux development checkout. Stop on failure. This check has **not** run in this conversation; report only PASS/FAIL and record count, without any private file contents.
2. **Gate B — full selected input:** Once 1203 passes, extend the private exporter selection in small audited batches **only where source rows were actually verified**. Prior evidence says the other pilot IDs exist in the offline index, **not** that their objective rows were checked.
3. **Gate C — wait for approved M2.3:** The production M2.3 engine and production v2 exporter require separate maintainer approval. A public-only pilot or draft synthetic test cannot replace a server comparison. Pair effective export **and full coverage manifest** from exactly the same compiled commit.
4. **Gate D — real in-game QA:** Test only on an explicitly approved QA build. Close WoW; first back up existing addon and the account/character `QuestieConfig`/`QuestieConfigCharacter` SavedVariables. Never reinstall or overwrite the working copy merely to satisfy this matrix.

For testing order, 1203 and regression of 2001 are the lowest-friction existing examples. Next prefer visible GO/item quests (498, 553, 786), then mixed-kind cases (532, 1045, 10392), then KillCredit/script cases. Access to an eligible quest/character **must not** be forced by bypassing faction, level, completion, phase or IP prerequisites.

## 4. In-game observation template (one copy per quest, kept privately)

```text
Quest ID:
Build/revision tested:
Date and test character (private):
Quest availability checked?  Y / N / Unknown
Eligibility (faction/class/level/IP/prerequisites): verified / unknown
Quest state: available / accepted / incomplete / complete / handed in

Actual quest-log line count:
Line 1 text / required / current / objective order:
Line 2 text / required / current / objective order:
Additional lines if present:

World-map starter/ender pins: pass / fail / unknown
World-map objective pins: pass / fail / unknown
Minimap pins: pass / fail / unknown
One intermediary progress update: pass / fail / not observed
Completion transition: pass / fail / not observed
Hand-in and pin disappearance: pass / fail / not observed
Compared to currently active server spawn/phase? Y / N / Unknown

Screenshot/log evidence path (private, never GitHub by default):
Result: verified / candidate difference / needs manual review
Exact next action or uncertainty:
```

Use `unknown` instead of guessing. If a quest cannot be accessed normally, record the restriction and move to another case. Do not conflate map percentage coordinates with raw AzerothCore world x/y; until map transforms and spawn activity are independently verified, location judgments remain manual-review only.

## 5. Separate v2-only cases: do NOT inject them into the v1 pilot

| Quest | Reason for separate queue | Necessary next evidence |
|---|---|---|
| **11142** | Public Questie correction uses two 500007 placeholder-object objectives; v1 unsupported | Real in-game quest-log line count/text. **No automatic deduplication.** |
| **12683** | Public mapping appears to use creature 28003 as a location hint on the sample line; v1 unsupported | Verify distinct lines and map interpretation; do not assume identical IDs mean identical kill credits. |
| **64128** | Hidden/blacklisted boosted-character quest, possible Tal/Frezza ID anomaly | Investigate only if legitimately visible; never unhide solely for testing. |
| **10503**, **11652** | Kill-credit-first ordering, with multiple-credit reversal on 11652 | Future v2 round-trip proof, not v1 forced export or objective flattening. |

No correction is approved by this matrix. The 758 unsupported v1 quests remain subject to the same fail-closed coverage rules. Grok owns v2/M2.3/marker architecture in draft PRs; the lead owns private-source and eventual in-game evidence review.

## 6. Completion policy

- [x] Sixteen selected effective records export successfully in the recorded M2.2 pilot.
- [x] Quest 2001 starter/objective/turn-in/remove lifecycle partially tested in game as recorded.
- [ ] Real quest 1203 private `nq-m2-input` accepted by genuine Lua 5.1.
- [ ] Independently verified private objective rows for other pilot selections.
- [ ] Production M2.3 separately approved, implemented and safely tested.
- [ ] First private report-only 1203 comparison completed without false confirmation.
- [ ] Any future in-game QA build explicitly approved; addons/SavedVariables backed up and restore path verified.
- [ ] Selected additional quest log, marker and progression tests actually performed.
- [ ] Narrow correction proposal only after human source review; never automatic bulk fixes.

**Everything in this document is planning or an explicitly attributed earlier observation, not permission to install or change live server state.**
