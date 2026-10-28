# Part41 G09/G10 — public 439-RAW research admission contract

**28 October 2026 — PUBLIC-SAFE TEST-ONLY research model; owner-private quest evidence is NOT present, and no new quest is approved or implemented.**

## Why this test is needed

The public [Missing-Quest Coverage Programme](../NQ-MISSING-QUEST-COVERAGE-PROGRAMME.md) contains precisely **439 raw investigation slots**, but neither the number of truly missing eligible quests nor their individual approval decisions is established publicly. Its classifications are **12 source-linked first-pass**, **418 exploratory**, **5 owner-excluded**, **3 development placeholders**, and **1 already-handled overlay**. Pilot 1207–1209 are three *separately tracked tasks*, **0/3 implemented**, NOT three new rows to add to 439. An absent available-quest map pin, raw server quest relation, or item-drop field is not eligibility evidence.

The standalone [Lua test](../../tests/compat/nq_part41_g10_public_research_admission.lua) reads **only a pinned public copy** of this published programme. GitHub Actions fetches the frozen docs parent commit `83dd366a2288de444b1ce39d945410ae35bf86e5` and checks the exact Git blob `86a91568e6619f161552e6682bc6b9eb557d592b` against both the immutable tree path and staged temporary file. It parses the five public table rows, verifies the public 439 total and the `0/3 implemented` label, then generates 439 **anonymous synthetic in-memory aliases**. Those aliases are NOT actual quest identifiers and are not mapped to the owner's server or Questie database. No 439 private quest rows, coordinates, SQL, loot or Individual Progression mappings are loaded.

## Falsifiable admission and release state machine

21 executed positive/negative fictional controls (to be verified on Lua 5.1 and 5.4) check the raw bucket census, no accidental raw→approved conversion, excluded/placeholder/already-handled no-addition rules, and strict status transitions.

Only a fictional, *qualified* record can progress:
`UNREVIEWED → EVIDENCE_IN_PROGRESS → MISSING_AND_ELIGIBLE → APPROVED_TO_IMPLEMENT → IMPLEMENTED_IN_DRAFT → QA_PASSED → ACCEPTED_IN_RELEASE`.

**Each arrow is gated independently**, not inferred from an earlier approved state. The model requires distinct private source snapshot, raw-versus-effective check, actual absence from effective data, confirmed offered/played state, starter+finisher, item-starter-vs-objective separation, confirmed IP/phase/history/conditions, independent source review and source approval **before fictional eligibility**; then a distinct owner *per-quest* implementation decision; implementation code review; native client QA and verified rollback; and finally separate release authority. It rejects unknown private phase/conditions, raw-only evidence, absent map markers and mere source links. A fictional pilot that is offered does not automatically become eligible or implemented.

The gate intentionally **does not implement any private source validation**. Boolean evidence fields are **fixture stand-ins**, not real proof or an instruction to insert data. The positive path exists only to catch a test which rejects everything and mistakenly appears safe. The authority check is a synthetic refusal exercise, **not a method to authorize a release through CI**.

## What still remains RED

- The complete 439 owner-private, per-quest classification and disposition are not accessible from this public model, and the eligible/approved counts remain UNKNOWN. Public CI must not print any private identifiers or raw relationships.
- Owner-supplied server `acore_world`, loot, NPC/GO/item, phase, class/faction/IP and owner-specific review need a separate **PRIVATE** evidence workflow. Existing exclusions may change only by explicit owner decision outside this public test.
- Gate04 immutable manifest and all-writer source ownership, Gate05 effective forward/reverse integrity, Gate06 native completion semantics, Gate07 item start and client map behaviour, and Gate08 E01–E08 ABA/QuestieStream pooled leases/complete four-kind atomic publication/SavedVariables disk recovery remain unfinished.
- Gate11 native 3.3.5a/IP client RAM, GC, frame, relog, genuine UI and rollback must remain separately approved and tested; Gate12 integration, install, package, tag and release require separate explicit authority.

**No production source changes, no protected `335` update, no client installation or release.** The twelve-gate scoreboard remains **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING** and pilot 1207–1209 remains **0/3 implemented**. Independent CS02 review should challenge invalid transition acceptance, weakened owner decisions, private-phase unknown treated as true, raw+pilot double count, and tautological/removed tests while preserving historical CI failures. All mutations must be reverted and conducted comment-only.
