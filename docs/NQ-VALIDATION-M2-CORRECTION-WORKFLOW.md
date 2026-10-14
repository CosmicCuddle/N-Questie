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
| Wrong objective (simple: item/creature/object ID or count) | M2.3 CONFIRMED_MISMATCH | `quest_template` RequiredNpcOrGo/RequiredItem rows, and KillCredit/loot evidence complete | field-level objective change in `NQuestieExistingQuestCorrections.lua` | M0 record pin; M2.3 rerun gives CONFIRMED_MATCH or EXPECTED_REPRESENTATION_DIFF |
| Missing custom quest | quest present on server, ABSENT_FROM_EFFECTIVE_DB | full `quest_template` row, starter/ender tables, objective targets existing in npc/object DB | new record in `NQuestieCustomQuestData.lua` | quest ID set pin updated (count and sha256, procedure in the ID-set doc); M0 record checks |
| NPC/object association (starter, ender) | queststarter/questender tables vs Questie startedBy/finishedBy | the server rows plus the NPC/object existing in Questie data | startedBy/finishedBy field change | M0 pin; marker structural check |
| Markers / locations | marker comparison (when built) | verified spawn rows **and** verified map bounds, phase/condition/IP evidence | spawn correction only for the specific NPC/object | location check rerun; in-game QA item |
| Scripted / IP-dependent | NEEDS_MANUAL_REVIEW | SmartAI/script, conditions, IP stage evidence, in-game confirmation | case by case, maintainer decision | in-game QA checklist entry |

## 4. Multiple server revisions

- Every M2.1 server file carries its own `sourceLabel` and `sourceFingerprint`. Corrections record the label of the export they came from (never the fingerprint itself in the repository).
- When a new server revision is exported, rerun M2.3 against the current Questie head. A reviewed correction whose server value changed shows up as CONFIRMED_MISMATCH on that quest and becomes a new review item; the old correction is not edited automatically.
- Corrections that only hold for one server revision are not supported; N-Questie targets one server line at a time, and this is stated in the correction header.

## 5. Regression checks for reviewed corrections

- M0 pins each corrected field value (as today for the 28).
- The compare-and-swap guard makes upstream drift visible.
- M2.3, when built, must report every corrected quest as CONFIRMED_MATCH or EXPECTED_REPRESENTATION_DIFF against the server revision it was reviewed on; anything else fails the regression run.
- A correction is never removed without a matching M0 pin change in the same PR.

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
