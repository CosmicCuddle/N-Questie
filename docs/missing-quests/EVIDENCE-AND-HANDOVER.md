# Missing-Quest Evidence and Handover Rules

## Reproducible checkpoints

1. Record source archive timestamp/identity privately, method of read-only extraction, complete `quest_template` row count, raw Questie source blob SHA and effective compiled ID-set revision.
2. Distinguish **server-only vs raw Questie**, **absent from effective Questie**, **present-but-filtered**, **no locatable starter**, **unsupported objective shape**, and **server/IP eligibility unknown**. Never call all server-only IDs bugs.
3. Preserve two levels: a **full 439-row private candidate universe**, and the **21-entry conventionally linked subset** (of which 3 are placeholders, 1 is existing quest 2001, 5 owner-deferred, and 12 pending review).
4. Back up and retain the original owner-private artifacts independently of the chat: complete CSV, linked-candidate CSV, workbook, and owner-private summary. Do not rely on GitHub PR comments or a text handover to reconstruct these exact rows.
5. Write only safe **aggregate and owner-explicitly-permitted fields** to GitHub. Never commit `acore_world.zip`, SQL rows, raw server data, live coordinates, login/character data, or server-derived candidate-by-candidate extracts.
6. For each inclusion candidate, record `source_evidence`, `effective_db_status`, `quest_eligibility`, `IP_phase`, `objective_shape`, `marker_coverage`, `reviewer`, `decision` and exact approved implementation commit (if any) in the private tracker. IDs/names can be in owner-private data only; GitHub public aliases LOW-01 etc. can point to them via an owner-controlled private mapping.
7. Grok (CS02) independently checks public source/loader/marker/phase assumptions and synthetic tests. CS01 independently evaluates per-quest data and reviews CS02's proposed fixes. Both report findings in PR #42, and master work is tracked in PR #96.

## How to read counts

- **9,525** private server quest template records and **9,086** raw WotLK Questie IDs: **439** server-only records. Historical comparison reproduced in private read-only audit on 24 October 2026.
- **9,159** effective Questie compiled IDs is a *separate* public baseline that includes inherited Questie additions and the N-Questie overlay for quest 2001.
- **21** conventional dual-linked server-only IDs is a filter for prioritisation only. It excludes item-only, script-based and event-based possible starts. Even dual links may be phase-gated or non-playable.
- **12** remain in the proposed first-pass review set following 5 explicit owner deferrals; **zero** are implementation-approved.

## Don't lose work between conversations

Handover text must explicitly name the location of the owner-private master report and workbook, indicate whether they are actually mounted/accessible in the new session, and avoid claiming that an inaccessible file can be read. If inaccessible, prefer the small prior owner-private audit over requesting another large SQL archive. Keep this public summary synchronized with *aggregate* counts after any authorised updated analysis.

## Testing discipline

Use explicit backups before any *separately approved* addon install or live-data action; avoid releasing, packaging, merging, editing protected branches, importing private SQL, or modifying SavedVariables without the owner's separate permission. This documentation does not grant that permission.
