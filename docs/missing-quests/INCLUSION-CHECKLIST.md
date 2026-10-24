# Missing Quests — Inclusion Review Checklist

**Review only; 0 new quests approved or implemented.** Source: regenerated private owner audit, 24 October 2026. The underlying exact quest IDs/names live in an **owner-private** companion report, not this public page.

## Work queue — 12 source-linked candidates

These aliases are a **public-facing tracking scheme**, not actual AzerothCore quest IDs. In the private tracker, every alias must be tied to exactly one verified quest ID, source revision and supporting data before implementation begins.

| Public review slot | Group | Review state | Inclusion decision |
| --- | --- | --- | --- |
| LOW-01 | Lower-level/custom-chain | Pending per-quest evidence | UNDECIDED |
| LOW-02 | Lower-level/custom-chain | Pending per-quest evidence | UNDECIDED |
| LOW-03 | Lower-level/custom-chain | Pending per-quest evidence | UNDECIDED |
| AQ-01 | AQ/War Effort/event | Server/IP phase required | UNDECIDED |
| AQ-02 | AQ/War Effort/event | Server/IP phase required | UNDECIDED |
| AQ-03 | AQ/War Effort/event | Server/IP phase required | UNDECIDED |
| AQ-04 | AQ/War Effort/event | Server/IP phase required | UNDECIDED |
| AQ-05 | AQ/War Effort/event | Server/IP phase required | UNDECIDED |
| AQ-06 | AQ/War Effort/event | Server/IP phase required | UNDECIDED |
| AQ-07 | AQ/War Effort/event | Server/IP phase required | UNDECIDED |
| CLASS-01 | Class/faction-specific chain | Class/prerequisites required | UNDECIDED |
| CLASS-02 | Class/faction-specific chain | Class/prerequisites required | UNDECIDED |

**Owner's explicit exclusions: quest IDs 30000, 30001, 30002, 30003 and 30004 must NOT appear in the above inclusion work.** They are recorded solely in [DEFERRED-QUESTS.md](DEFERRED-QUESTS.md). The source-audit first-wave eight lower-level candidates became **three** after these five were deferred.

## Gates for each of the twelve candidates

- [ ] Verify exact original Questie **effective compiled ID** membership, not merely the raw source file.
- [ ] Confirm the live server actually offers the quest under natural play. Existing starter/ender links and spawn rows do not prove live availability.
- [ ] Check faction, class, level, prerequisites, mutually exclusive chains, active/completed quest and profile filters.
- [ ] Check Individual Progression stage and any server-side conditions or scripted/event requirements. Unknown conditions **must not** be converted into permanently visible markers.
- [ ] Verify visible, locatable NPC/GameObject starter in the **applicable** stage. Item-only starters, phase-hidden spawns, and missing coordinates need separate treatment.
- [ ] Confirm objective *types and order* against the client quest log (kills, gameobjects, items, special kill credit, scripted objectives). Do not weaken the guarded loader to accept unknown mixed objective categories.
- [ ] Verify starter, active objective, completion and turn-in icon/tooltip behavior and after-`/reload` persistence as appropriate on a permitted QA build.
- [ ] Add/execute isolated Lua 5.1 synthetic tests and obtain reciprocal CS01↔CS02 review on the exact tested head.
- [ ] Obtain **separate owner approval** for any specific source changes, installation or merge.

## Decision labels

- `NOT_REVIEWED` — linked static candidate only.
- `PRESENT_BUT_FILTERED` — exists in effective Questie and filtering explains absence.
- `MISSING_AND_ELIGIBLE` — independently proven live-available quest missing from effective Questie (requires strong evidence).
- `CONDITIONAL_OR_IP_UNKNOWN` — phase/event/script conditions not yet verified.
- `SCHEMA_UNSUPPORTED` — custom loader cannot represent without separate reviewed development.
- `OWNER_DEFERRED` — excluded from proposed inclusion, tracked only for later.
- `APPROVED_TO_IMPLEMENT` — only after explicit owner decision and reciprocal review.

**Policy:** No `APPROVED_TO_IMPLEMENT` entries exist yet. Do not equate `quest_template` membership with a currently playable quest.
