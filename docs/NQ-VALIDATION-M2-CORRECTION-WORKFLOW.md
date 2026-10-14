# N-Questie conservative correction workflow

Status: **process design**. Nothing here applies a correction automatically, now or later. Every correction is written by a person, reviewed, and merged by the maintainer. Stacked on the markers design (PR #43).

Date: 14 October 2026.

## 1. What exists today

| Module (`Compat/`) | Kind | Pattern |
|---|---|---|
| `NQuestieCustomQuestData.lua` + `NQuestieCustomQuestLoader.lua` | missing custom quest (2001 "Ravenclaw Cleanup") | full curated record, `revision` bumped on change |
| `NQuestieExistingQuestCorrections.lua` | objective field of an existing quest | field-level change only; everything else inherited |
| `NQuestieReviewedQuestLevelCorrections.lua`, `NQuestieReviewedEarlyQuestLevels.lua`, `NQuestieReviewedClassicChainLevels.lua` | quest levels | `{expected inherited min, expected inherited level, server min, server level}`: applied only when the inherited values still equal the expected ones |

Together these are the 28 reviewed corrections plus quest 2001 (`correctionCount = 28`, correction fingerprint in every M2 export). The "expected inherited value" guard is the model for everything below: a correction states what it replaces, so an upstream change can never be silently overwritten.

## 2. Rules for every correction

1. **One fact, one source.** Each correction cites its own evidence (server table and row key, export date, reviewer). No correction relies on another correction's evidence.
2. **Field-level only.** Only the reviewed field changes. Unrelated fields of the same quest stay inherited and are checked unchanged by M0.
3. **Compare-and-swap.** The correction records the inherited value it expects; if Questie upstream has changed it, the correction does not apply and the harness reports it.
4. **No private data in the repository.** Values that come from the private export are copied as individual reviewed numbers or IDs, never as dumps; no fingerprints of private files, no reports.
5. **Never automatic.** M2.3 and marker reports produce review candidates only.
6. **Revision.** Any change bumps `NQuestieCustomQuestData.revision` (or the module's own revision) so the compiled DB rebuilds; the revision guard workflow enforces this.

## 3. Workflow per correction type

| Type | Candidate source | Evidence required | Change | Regression check |
|---|---|---|---|---|
| Wrong level | M2.1 vs effective levels | `quest_template` MinLevel/QuestLevel row | level module entry with expected inherited values | M0 pin of the corrected value; inherited guard test |
| Wrong objective (simple: item/creature/object ID or count) | M2.3 CONFIRMED_MISMATCH, or NEEDS_MANUAL_REVIEW once a person has collected the missing evidence | `quest_template` RequiredNpcOrGo/RequiredItem rows, and KillCredit/loot evidence | field-level objective change in `NQuestieExistingQuestCorrections.lua` | tier A M0 record pin; tier B M2.3 outcome recorded (§5) |
| Missing custom quest | quest present on server, ABSENT_FROM_EFFECTIVE_DB | full `quest_template` row, starter/ender tables, objective targets existing in npc/object DB | new record in `NQuestieCustomQuestData.lua` | quest ID set pin updated (count and sha256, procedure in the ID-set doc); M0 record checks |
| NPC/object association (starter, ender) | queststarter/questender tables vs Questie startedBy/finishedBy | the server rows plus the NPC/object existing in Questie data | startedBy/finishedBy field change | M0 pin; marker structural check |
| Markers / locations | marker comparison (when built) | verified spawn rows **and** verified map bounds, phase/condition/IP evidence | spawn correction only for the specific NPC/object | location check rerun; in-game QA item |
| Scripted / IP-dependent | NEEDS_MANUAL_REVIEW | SmartAI/script, conditions, IP stage evidence, in-game confirmation | case by case, maintainer decision | in-game QA checklist entry |

## 4. Multiple server revisions

- Every M2.1 server file carries its own `sourceLabel` and `sourceFingerprint`. Corrections record the label of the export they came from (never the fingerprint itself in the repository).
- When a new server revision is exported, rerun M2.3 against the current Questie head. A reviewed correction whose server value changed shows up as CONFIRMED_MISMATCH on that quest and becomes a new review item; the old correction is not edited automatically.
- Corrections that only hold for one server revision are not supported; N-Questie targets one server line at a time, and this is stated in the correction header.

## 5. Regression checks for reviewed corrections (two tiers)

**Tier A, strict (M0, always required).**

- The approved compiled field value is asserted exactly (M0 pin), as today for the 28.
- The compare-and-swap guard records the expected inherited value; upstream drift is reported, never overwritten.
- No unrelated field of the quest differs (M0 field-level read-back over all 82,431 fields).
- A correction is never removed without a matching M0 pin change in the same PR.

**Tier B, recorded (M2.3, once it exists).**

- M2.3 runs on the server revision the correction was reviewed against and its outcome is recorded.
- Allowed: `CONFIRMED_MATCH`, `EXPECTED_REPRESENTATION_DIFF`, or `NEEDS_MANUAL_REVIEW` **with a documented reason** (which evidence item is incomplete: KillCredit, conditions, scripts, IP or objective data). With frozen M2.1 input these flags can stay unknown, so manual review is an accepted, conservative result, not a failure.
- `CONFIRMED_MISMATCH` or any other outcome is a regression and fails.
- New unexpected differences are verified independently by a person.
- CONFIRMED is only demanded where the evidence contract supports it.

Draft: `tools/validation/draft/CorrectionQaDraft.lua` `CheckRegression` (synthetic tests in `tests/test_nquestie_m2_qa_draft.lua`).

## 6. Prioritised review queue (public categories only)

Order by how much evidence a decision needs, lowest first. Counts are public coverage categories; no private data.

| Priority | Category | Why |
|---|---|---|
| 1 | Levels (MinLevel, QuestLevel) | single numeric fields, fully in `quest_template` |
| 2 | Simple objectives on v1-representable quests (8,401 pool) with CONFIRMED_MISMATCH | direct ID/count rows; M1 supports them |
| 3 | Starter/ender associations | direct rows |
| 4 | Missing custom quests | full record needed, but self-contained |
| 5 | Reputation objectives (181) and duplicate-target quests (8) | need v2 and careful order checks |
| 6 | Extra-reference quests (EXTRA_CREATURE_REF 359, EXTRA_OBJECT_REF 243) | depend on Questie display choices; markers needed |
| 7 | Kill-credit-first quests (16) | order-sensitive; v2 required |
| 8 | Scripted, phased, condition- or IP-dependent quests | need server scripts and in-game confirmation |

Each queue item is a private review note; only the public category and count appear in repository documents.

## 7. Text and tooltip QA lane (separate)

Correct IDs and markers are not proof of correct text. Text is checked in its own lane, aligned with the maintainer-side checklist on #40 (`docs/NQ-QUEST-MARKER-TEXT-QA.md`), and never folded into M1 or M2.3 outcomes. `displayScope = "structural-only"` in v2 is unchanged.

| Surface | What is observed |
|---|---|
| Quest log line, count, order | client-visible objective text, current/required count and line order for an accepted quest |
| Tracker line | Questie tracker text against the quest log |
| Starter / finisher tooltip | title and giver on map and minimap pins |
| Objective marker tooltip | label and counter on objective pins, distinguished from the quest-log line |
| Item source tooltip | source and item names for loot, object, vendor sources |
| Extra objective text | custom text from public Questie corrections only, traced to the source file |

Rules:

1. Result is `PASS`, `DIFFERENCE_TO_REVIEW` or `UNKNOWN`; there is no CONFIRMED text result.
2. Record the stage actually tested (before acceptance, accepted, progress, completion, hand-in, relog) and the observed client locale. No enUS assumption; private AzerothCore locales are not assumed verified.
3. Unknown availability (prerequisites, race/class, phase, conditions, IP) gives `UNKNOWN`.
4. Static addon text (Questie strings, corrections) and client quest-log text are recorded separately; a stylistic difference is a review item, not wrong data.
5. Stale cache text and transitions on acceptance, progress, completion, hand-in and relog are separate observations.
6. No automatic text rewrite. A text correction is a field-scoped, human-reviewed proposal with its own source.
7. Private server text is never published and never used as a public PASS reference.

Public anchors (no new in-game result claimed): 1203 effective item 3853 vs inherited 33110 (client text still to check in an authorised QA session); 2001 earlier showed 0/8 counters and marker lifecycle (partial); 12683 and 11142 need quest-log line vs tooltip distinction.

Draft: `CheckTextObservation` with synthetic fixtures (unknown availability, locale missing, CONFIRMED text result, auto-rewrite, text turned into an M1 outcome all rejected).
