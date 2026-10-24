# Missing Quest Coverage — Development Index

**Status:** research and checklist only — no new quest records approved or deployed.

This folder is the **public-safe** development index for differences between the owner's AzerothCore quest definitions and the Questie 3.3.5a effective database. It is not a dump of private world SQL or a list of all playable quests.

## Current audit checkpoint (24 October 2026)

| Evidence bucket | Count | Interpretation |
| --- | ---: | --- |
| Server quest template IDs (owner-private SQL snapshot) | 9,525 | Static definitions, not evidence of player availability |
| Raw WotLK Questie quest IDs (pinned original blob `abbf2831b6d6b54b5d9383ba2c3e5cce5147379d`) | 9,086 | Public baseline, before inherited corrections |
| Server-only versus raw WotLK Questie | 439 | Research universe, **not 439 approved fixes** |
| Server-only IDs with conventional NPC/GO starter **and** ender relations | 21 | Relations alone do not establish that an NPC offers the quest |
| Identified placeholders / development quests | 3 | Not proposed |
| Already handled by the N-Questie overlay (quest 2001) | 1 | Retain existing tested behavior |
| Original linked candidates requiring review | 17 | 21 minus 3 placeholders minus 1 handled quest |
| Explicitly deferred by the owner | **5** | Quest IDs 30000–30004; excluded from inclusion work |
| Remaining first-pass review candidates | **12** | 3 lower-level/custom chain; 7 AQ/event; 2 class/faction-specific |
| Other server-only IDs without both conventional relation types | 418 | Investigate alternate item/script/event starters and obsolete records separately |

**Important:** The 17 and 12 are *source-linked investigation candidates*, not 17 or 12 confirmed questing bugs. The public **effective compiled** N-Questie baseline contains **9,159** records (9,086 original +72 inherited Questie corrections + quest 2001), documented in [the compiled quest ID-set checkpoint](../NQ-VALIDATION-M2.2-QUEST-ID-SET.md).

## Documents

- [Inclusion review checklist](INCLUSION-CHECKLIST.md) — the 12 remaining *unapproved* candidate slots and acceptance gates.
- [Owner-deferred quests](DEFERRED-QUESTS.md) — explicit do-not-include entries, until the owner changes the decision.
- [Evidence, privacy and handover protocol](EVIDENCE-AND-HANDOVER.md) — how not to lose audit results again, and how to keep private data private.
- Existing public context: [full-server checkpoint](../FULL-SERVER-QUEST-AUDIT-CHECKPOINT.md) and [custom loader safety draft](../NQ-CUSTOM-LOADER-SAFETY-DRAFT.md).

## Source-of-truth boundary

The actual **439-row owner-private CSV** and **private 12-candidate review checklist/workbook** were regenerated from the owner's uploaded `acore_world.zip` on 24 October 2026. Those files contain private server-derived quest identifiers, links and metadata and are **NOT stored in this public repository**. Retain the exact original files in owner-controlled Project/private storage for the next development handover. Do not add raw SQL, character/account data, detailed private candidate IDs, coordinates, or private derived extracts to GitHub.

## Changes are gated

No automatic import, phase bypass, file packaging, SavedVariables edits, live-server mutation, or merges are authorised by these documents. Independent CS01/CS02 review and separate owner approval are required before changing functional quest data. Keep protected `335` and installed addons intact.
