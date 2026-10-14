# N-Questie — Quest Text, Tooltip and Marker QA Checklist

**Status:** DRAFT maintainer-side, manual-QA planning only; **not** an automated text exporter, not an installed addon change, not a claim that additional live quests were tested.  
**Date:** 14 October 2026.  
**Related:** `NQ-PILOT-QUEST-QA-MATRIX.md` (16 public compiled quest shapes), `NQ-PRIVATE-1203-PILOT-AND-INGAME-QA.md` (safe local/private gates), Grok's M2.2 structural v2 and M2.4 `nq-m2-markers` design (#39–#44).

## 1. Why text deserves its own check

N-Questie can have **the right objective target ID** but show a wrong, stale or misleading line of text; it can show the right words but draw the marker in the wrong place. Conversely a correct Questie marker label need not match a private AzerothCore quest title or a client-localised quest-log line.

The structural `nq-m2-effective` v2 design deliberately does **not** export player-visible text or coordinates. The proposed `nq-m2-markers` format is for locations, not a proof of marker-tooltip text. Neither schema is a substitute for checking what the player actually sees.

Keep **four separate results**:

| Evidence lane | Question | Evidence source | What it does **not** prove |
|---|---|---|---|
| Structure | Which compiled target IDs, types and objective order exist? | Public M2.2 export plus future private M2.3 | Quest-log wording, currently active spawns, translations |
| Location | Where would an objective marker be placed? | Future marker export, source-tagged public spawns and independently verified private world-to-map transforms | Current quest eligibility or visible marker text |
| **Text / tooltips** | What does Questie say, and is it consistent with the eligible character's actual quest log? | Public addon source/correction, approved 3.3.5a in-game observation; verified private server text kept private if used | An exact location match or a complete server comparison |
| In-game lifecycle | When do icons and counters appear/change/disappear? | Approved manual character QA | Other characters, phases, languages or IP stages |

Do **not** fold an unverified text discrepancy into `CONFIRMED_MISMATCH` from M1. M1's objective rules are not text-auditing rules. Record the separate text result `PASS / DIFFERENCE TO REVIEW / UNKNOWN` with the observed client language and build revision.

## 2. Safety and evidence rules

1. For future in-game QA, first obtain the maintainer's explicit permission for **one** QA build. Close WoW and make verified backups of the existing Questie-335 addon folder and relevant `QuestieConfig` / `QuestieConfigCharacter` SavedVariables. Keep a rollback plan; never overwrite the working installation to run this checklist automatically.
2. Keep all private server exports, SQL rows, character/account identifiers, private screenshots, file paths, server provenance fingerprints and saved variables **outside public GitHub**. A source-specific public correction may later cite separately reviewed **non-sensitive** individual values, never an entire export.
3. State language/locale observed in the client and the currently tested character's faction, level and independently verified IP stage (if available). Do **not** assume one client's locale is the server's authoritative text, nor that English strings apply to every locale.
4. Before saying a quest is missing or its text is wrong, check current accepted/completed state, prerequisite, race/class/faction, IP, phase/conditions and addon cache. If availability cannot be established, mark `UNKNOWN` and do not force eligibility.
5. When screenshots are taken, capture only the relevant quest log and marker/tooltip area. Check that no private account/character details or server information will be disclosed before sharing anything externally. Prefer a private local evidence directory.

## 3. Manual test sequence — once an approved QA build exists

For **one eligible quest**, perform only the natural parts the character can legitimately reach:

| Stage | Observe separately |
|---|---|
| 1. Before acceptance | Available quest icon and tooltip show the correct title, giver and relevant known requirements; absent/hidden due to eligibility is not an automatic bug |
| 2. Quest accepted | Quest-log objective **line count, order and labels** agree with each other and with expected separately verified objective structure |
| 3. Marker visible | World-map and minimap tooltip labels, target kind and displayed objective counter are distinguishable from the quest-log text where the addon intentionally uses a helpful display hint |
| 4. Counter advances | After one legitimate objective event, the **correct line's** current/required count updates; no other line falsely increments; some scripted goals require a different action and must be documented, not guessed |
| 5. Completion | Objective markers and their text transition correctly; expected finisher or completion marker appears |
| 6. Hand-in | Marker/tooltip no longer advertises the quest as active once the server confirms hand-in |
| 7. Relog or reload, when practical | Existing preferences and quest state remain consistent; no stale text/markers from the prior state |

Report an observation at the **specific stage actually tested**. Do not fill other stages as PASS. Compare client quest-log wording to Questie strings, but allow documented UI summarisation/localisation; a stylistic difference is not automatically wrong data.

## 4. Initial public cases and the precise unknowns

| Quest | Public evidence already held | Text / tooltip question still requiring proof |
|---|---|---|
| **1203 — Jarl Needs a Blade** | Effective compiled N-Questie item **3853**; stock WotLK Questie **33110**. Private offline source previously identified Moonsteel Broadsword ×1, but the real M2.1 Lua file still needs genuine Lua 5.1 validation. | Does the eligible client's quest log and N-Questie map tooltip actually name/show the Moonsteel Broadsword objective correctly? Distinguish item name, item-drop/source marker and actual quest text. No new in-game PASS claimed. |
| **2001 — Ravenclaw Cleanup** | Prior maintainer QA verified starter at NPC 2121, targets NPC 1868/1869 initially at **0/8** each, completed finisher at 2121, and marker removal after hand-in. | Check each line's **intermediate increments**, absence of cross-line updates, locale-dependent labels, world-map/minimap tooltip agreement and any stale text on relog. Existing milestone stays partial PASS. |
| **498, 553, 786** | Public v1 pilot has distinct gameobject objective IDs. | Confirm one label per visible quest-log line and corresponding GO tooltip. Item sources must not be reported as direct gameobject credit. |
| **9666, 4022** | Mixed killCredit with creature or item structures. | Preserve distinct lines and labels even if the same creature ID appears in more than one structural slot; do not infer which action credits the quest from a tooltip alone. |
| **532, 10392, 1045** | Public pilot mixes creature, object and item objectives. | Separate objective type, item source and visible quest text. Verify ordering against actual client quest-log line order. |
| **30** | Scaling questLevel **-1** and spawn-only extra objective. | Custom event/spawn-only icon text needs independent proof and exact pin location belongs to marker QA, not structural v1. |
| **25** | Creature plus triggerEnd. | Scripted/trigger completion label and actual visibility may not be reducible to a standard creature kill. |
| **11142** | Public-source hypothesis: two placeholder object objectives with the same object ID; v1 unsupported. | Observe actual **number and wording of quest-log lines**. Never deduplicate just because two IDs match. |
| **12683** | Public-source hypothesis: samples and hydra kill lines use the same Questie creature location hint; v1 unsupported. | Compare **sample-objective text** with location-hint tooltip separately; the marker's 28003 location ID is not proof of kill credit. |
| **64128** | Boosted-character variant is normally blacklisted in public Questie source; Tal/Frezza mapping is an unverified anomaly hypothesis. | Only test if naturally visible/available; do not bypass the blacklist to create an artificial test case. |

These are **test questions**, not approved corrections. The listed quest IDs, shapes and old QA facts come from the already reviewed public records and maintainer observations, not a new private comparison.

## 5. Compact observation record (private)

```text
Build / commit:                     Quest ID:
Client locale:                     Date:
Character eligibility/IP: VERIFIED / UNKNOWN
Quest state reached: available / accepted / partial / complete / handed in

Quest log number of lines: 
Line 1: exact visible label (private), required, current:
Line 2+: exact visible label (private), required, current:
Visible marker label vs quest-log wording: SAME / INTENTIONAL DISPLAY HINT / DIFF / UNKNOWN
World-map tooltip observed: YES / NO / UNKNOWN
Minimap tooltip observed: YES / NO / UNKNOWN
Counter update on correct line: PASS / DIFFERENCE / UNOBSERVED
Completion tooltip transition: PASS / DIFFERENCE / UNOBSERVED
Hand-in marker removal: PASS / DIFFERENCE / UNOBSERVED
After relog/reload: PASS / DIFFERENCE / UNOBSERVED
Source category checked: compiled Questie / client / private server / not checked
Could translation, conditions, caching or script explain difference? YES / NO / UNKNOWN
Text QA result: PASS / DIFFERENCE TO REVIEW / UNKNOWN
Location QA result (separate): PASS / DIFFERENCE TO REVIEW / UNKNOWN
In-game lifecycle result (separate): PASS / PARTIAL / DIFFERENCE / UNKNOWN
Evidence location: private only
Reviewer decision / proposed next check:
```

When an exact string appears in a **private** AzerothCore row or a screenshot includes private identifiers, retain it in the private record and publish only a reviewed non-identifying summary.

## 6. Later acceptance and ownership

- **Grok's design lane:** document that structural v2, geographic markers, display text and live transitions have distinct evidence contracts; synthetic text/tooltip ambiguity examples may be public and invented. No production text exporter is authorised.
- **Lead lane:** prove that Questie compiled IDs are correct, validate real 1203 input under genuine Lua 5.1, then collect narrowly scoped in-game QA on an approved build. No full server text dump goes to GitHub.
- **Maintainer:** explicitly approve installation, backups, stage-appropriate tests, narrow correction PRs, eventual merge/release.

A quest becomes **fully QA reviewed** only when each *applicable* lane either has direct evidence or is explicitly marked not applicable with a reason. Unknown language, locale, progress or IP is never silently promoted to PASS.
