# N-Questie — Framework Work Packages for Grok (Design-only Follow-up)

**Status:** lead coordination plan; public docs + synthetic tests only.  
**Date:** 14 October 2026.  
**Framework stack:** #39 → #41 → #42 → #43 → #44, all **draft**.  
**Lead-side parallel work:** #40 (private pilot, 16-quest QA matrix, integration inventory).  
**No approval:** production v2 exporter, M2.3 engine, marker exporter, private-server import, quest corrections, live addon or DB changes, merge, release or tag.

## Goal

Make the *design and synthetic-test contracts* dependable enough that separate production decisions can be taken without rewriting basic architecture. The completed framework should eventually distinguish **what the compiled Questie data says**, **what private AzerothCore records show**, **what Questie draws**, and **what happens to the player's quest log in game**. These four evidence levels are never collapsed.

This is a work plan, not a claim that the pending designs already pass full CI or have been exercised against the lead's private server data.

## Work packages, in recommended order

### G1 — Finish review corrections on the existing draft stack (priority: immediate)

**Ownership:** Grok. Work only on Grok's own draft branches or new stacked drafts, without rebasing or force-pushing shared heads.

1. **#39 / #41:** Confirm v1 stays frozen and M0/M1 are unchanged. Document verified evidence for each latest head. Fix any remaining literal `CI_EVIDENCE_3` placeholder in handovers using *real* six-workflow run IDs from that exact commit.
2. **#42 — private report schema:** Strictly limit aggregate reason keys to a reviewed, versioned code vocabulary; reconcile *exact* reason occurrences with private report rows. Reject unknown string keys, unexpected fields and private labels.
3. **#42 — confirmed outcomes:** `CONFIRMED_MISMATCH` must require relevant positive M1 findings **and** complete evidence, not only `m1Supported=true`; `CONFIRMED_MATCH` still requires zero findings and complete evidence. Do not infer positive evidence from an empty table.
4. **#42 — selection:** Validate unique positive selected quest IDs. Distinguish **not in full compiled manifest** from **representable but absent from a selected export** (whole-batch selection failure). Explain the frozen v1 exporter's fail-closed behavior when a requested selection contains any of the 758 unsupported records; design the separate selection protocol without weakening v1.
5. **#42 — malformed data:** Reconcile `REJECTED_MALFORMED_INPUT` with the rule that *any* invalid input rejects the entire batch with no report. Either define a genuinely reachable, schema-valid per-quest situation or reserve the status for rejection diagnostics only; update Q06 and fixture/test vocabulary accordingly.
6. **#43 — custom coordinates:** Include raw `extraObjectives` spawn coordinates, ordered per zone and provenance-tagged as **custom correction data**, not merely `customSpawnZones`. Include no-ref spawn-only events, mixed refs/custom spawns and objectiveIndex=0. Preserve item source category, multiple zones, NPC waypoints (separate) and unknown phase/IP restrictions.
7. **#44 — correction regression:** Require exact M0 field guards and no unrelated changes; do not demand a confirmed M2.3 outcome while known private evidence flags remain `unknown`. Permit documented `NEEDS_MANUAL_REVIEW` until actually resolved.
8. **#41 / #44 — deterministic v1 preservation:** Clarify how byte-identity tests control provenance timestamps / other allowed variable metadata without altering production v1 output. Preserve strict structural/field equivalence on normal runs.

**Acceptance:** focused synthetic negative fixtures for each corrected contract; documentation and validator agree; no production engine/exporter; all six GitHub workflows on the latest tested head of each updated PR.

### G2 — Add *synthetic protocol tests* for the future comparison (priority: after G1)

**Deliverable:** updated draft M2.3 fixture matrix and draft validator tests, not a real batch engine.

Required synthetic cases:

| Case | Expected result |
|---|---|
| Compiled manifest lists 1203 REPRESENTABLE, but selected effective export contains only 2001 | Whole batch REJECT: selection mismatch, **not** ABSENT_FROM_EFFECTIVE_DB |
| Server quest ID not in complete 9,159-ID manifest | ABSENT_FROM_EFFECTIVE_DB, only after manifest completeness is verified |
| Server selects both 1203 and v1-unsupported 11142 | Explicit safe selection policy, retaining an unsupported status without pretending the all-or-nothing v1 exporter wrote it |
| Quest exported but manifest marks UNSUPPORTED | Whole batch REJECT |
| Server or effective file has invalid required provenance or any duplicate quest ID | Whole batch REJECT; no report, aggregate or partial output |
| A synthetic `CONFIRMED_MISMATCH` row has zero M1 findings | Report validator REJECT |
| A synthetic `CONFIRMED_MATCH` row has unknown IP/script/conditions/KillCredit | Report validator REJECT |
| Aggregate reason key is a private-looking label rather than an approved reason code | Aggregate validator REJECT |
| `selected` contains duplicates, invalid IDs or holes | Report validator REJECT |
| Same reason appears on two different unsupported quests | Aggregate per-reason count must equal actual reported occurrences |
| v1→v2 migration contains any killCredit (including two only, reordered) | REFUSE; re-export instead of guessing |
| v2→v1 request | REFUSE |

These tests demonstrate the **contract**, not the engine's end-to-end correctness. If they only assert that matrix descriptions exist, call them design assertions—not executable negative batch tests.

### G3 — Marker-source fidelity synthetic pack (priority: after G1)

**Deliverable:** synthetic marker record schema / design and test plan, never a real spawn exporter yet.

A1. Spawn-only custom event: two distinct custom x/y coordinates in one zone, no NPC/object refs. Round trip preserves both points and provenance.

A2. Mixed custom spawns + creature/object refs: origin tags distinguish all points; the first-ref display identity does not erase other referenced spawns.

A3. Multi-zone NPC with patrol waypoints: static spawn coordinates and waypoints are separate; no inferred active status.

A4. Item-drop objective with creature-drop, object-drop, vendor or nested-item sources: preserve source `kind` and relationship path; don't flatten all to direct quest kill targets.

A5. Unknown map transform/phase/pooling/conditions/IP: no confident positional mismatch. Any suggested default tolerance must be an explicit reviewed parameter, not factual proof.

A6. Starter/ender marker lifecycle: structure, position and observable in-game transitions are reported as **three distinct** results. Existing quest 2001 observations are partial QA, not proof of every spawn.

**Acceptance:** every exported marker is traceable to a specific Questie record, NPC/object spawn, waypoint (only when applicable), or a raw custom extraObjective spawn. No coordinates invented, rounded away or silently deduplicated. All fixtures synthetic.

### G4 — Cross-PR design consistency audit (priority: once G1–G3 are prepared)

**Deliverable:** a single short design audit or handover identifying pass/fail with evidence, exact head SHAs and follow-ups.

- Pin the chain `#39 → #41 → #42 → #43 → #44` and its real ancestry. Note #40 is parallel to #39 on #38, **not** automatically in the Grok stack.
- Reconcile schema names/versions; server vs effective vs coverage provenance; explicit selections; unsupported reason vocabulary; status axes; report/aggregate rules; marker provenance; and script/IP unknown semantics.
- Enumerate any obsolete documentation statements (e.g. older measured 8,407/752 rather than the final v1 8,401/758) as **historical snapshots**, or update them where they are currently presented as live facts. Don't rewrite history or old CI evidence.
- Require complete public/synthetic six-workflow CI for the exact latest integration candidate head. Previous successful commits do not establish the new commit's status.
- Do not silently merge independent legacy #4/#18/#32; analyse diff/equivalence and active workflow before any future integration.

**Acceptance:** updated handover lists precise outstanding blockers and whether the full expected checks actually ran, not merely whether GitHub displayed green on older PRs.

### G5 — Implementation readiness dossiers (priority: only after G1–G4)

Write **two separate, approval-ready proposals**, no implementation.

**Proposal A: production structural v2 exporter**
- Exact module/files, manifest and v2 validation contracts, failure cases, deterministic output (with controlled timestamps), provenance pairing, no-clobber output, 9,159-quest round trip and special tests for the 758 v1-unsupported cases.
- Measured acceptance targets; v1 frozen and checked.
- Explicit list of what **will not** be exported: marker coords, display text and unverified live availability.

**Proposal B: private report-only M2.3 batch engine**
- Three-input validation, explicit subset and mixed-v1 selection contract, version dispatch, two-axis statuses, M1 integration, privacy-safe aggregate, no partial output, immutable inputs and negative matrix.
- Specify what real M2.1 can establish: no invented completeness for `conditions`, `ipGated`, `scriptedCredit` or KillCredit.
- First private pilot is 1203 only, after independent genuine Lua 5.1 validation by the lead. No real data ever reaches public CI.

**STOP and request a separate maintainer decision** before implementing either proposal. Approval of a design or a clean synthetic test is not approval to merge or release.

## Lead-side dependencies Grok must not block on

- The real private `nq-m2-input` file for quest 1203 still needs a **genuine local Lua 5.1** validation in the trusted lead environment. Grok can design synthetic tests now but cannot claim real validation.
- Later quests 11142, 12683 and 64128 remain public-source hypotheses needing normal eligible in-game observation, not reasons to deduplicate or overwrite.
- Source spawn rows and world-to-zone map bounds have not been independently validated; markers must preserve uncertainty until then.

## Final handover format

For each work package, report: **PR URL; exact head SHA; files changed; test cases added; check counts actually executed; six-workflow CI on that SHA; open risks; whether any functionality was implemented; and what requires separate approval.** If a check could not be run, label it `NOT RUN` rather than `PASS`.

This brief is planning **only** and does not authorise the production v2 exporter, M2.3 engine, marker exporter, private source collection, changes to live AzerothCore, installed addon/SavedVariables, merges, tags or releases.
