# Part40: Public Gate06 completion cache ordering audit

Status: PUBLIC-SAFE TEST ONLY, 27 October 2026. No production edits, private owner SQL, AzerothCore/IP relationships or SavedVariables.

## Public source scope

The dedicated Lua fixture reads checked-out Compat/Compat.lua and extracts the *actual public* function bodies for ResetDailyQuests, SetQuestComplete, GetQuestsCompleted, QUEST_QUERY_COMPLETE and Merge. QuestieQuest:Initialize uses the immediate cache result. The public completion-query routine initiates QueryQuestsCompleted before returning the existing character cache; the event handler later reads into that cache, filters repeatables and applies optional daily and weekly rules. That is an asynchronous ordering boundary, not proof of a native-client bug.

## Fictional test contract

14 independent controls use invented quest IDs and simulated WoW APIs only: absent/old completion cache, delayed response, hypothetical CLEAR_ADD versus ADD_ONLY table semantics, repeatables, multiple and uncorrelated responses, local completion, daily reset option on/off, weekly completion and merge, pre-reset preservation and elapsed daily reset. The weekly timer, GetServerTime, QueryQuestsCompleted and the client event scheduler remain fictional stubs. All tests run the original extracted public function bodies under real Lua 5.1.5 and Lua 5.4.6.

An ADD_ONLY hypothetical event retains stale entries; an uncorrelated older hypothetical reply may reinstate an outdated state. Both are conditional known-unsafe scenarios *if* the real API behaves that way. The real 3.3.5a GetQuestsCompleted table CLEAR/ADD semantics, actual response correlation and user-visible marker impact are UNVERIFIED. Do not call a passing fixture a client reproduction or source-security fix.

Logs print only control totals and scope limitations; no quest identifiers or relations are printed, and no artifacts are uploaded in the dedicated workflow. The branch is isolated from protected 335 and all reviewed frozen heads.

## Open independent proof obligations

Verify the native 3.3.5a client GetQuestsCompleted(table) mutation contract and event timing. Test daily/weekly resets, repeatables, race/faction/Individual Progression eligibility and actual UI after separately approved backups. Evaluate whether stale initialization caches show incorrect markers, and test a targeted remediation without wiping legitimate SavedVariables. Require exact-head original-branch Lua CI/artifact verification and CS02 reverted mutations. This study does not authorize an integration merge, addon installation, packaging, tagging or release.

Whole gates remain 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; 439 RAW research entries are not 439 approved quest additions, eligible denominator unknown, initial pilot 1207-1209 0/3. Gate08 all-writer epoch, QuestieStream pool, eight Bin/Ptrs and metadata atomic commit, and crash/relog recovery remain RED.
## Historical Patch 3.3 API documentation — material new evidence

Warcraft Wiki's GetQuestsCompleted API reference (https://warcraft.wiki.gg/wiki/API:GetQuestsCompleted) says an optionally supplied table is filled with completed quest IDs, while other existing keys remain unchanged. Its documented introduction is patch 3.3.0. The patch 3.3.0 API change notes (https://warcraft.wiki.gg/wiki/Patch_3.3.0/API_changes) confirm that QueryQuestsCompleted requested the list and QUEST_QUERY_COMPLETE fired when received. The QueryQuestsCompleted reference (https://warcraft.wiki.gg/wiki/API:QueryQuestsCompleted) describes asynchronous server response and request throttling.

Consequently the public QuestieCompat handler's direct GetQuestsCompleted(Questie.db.char.complete) on an existing table has a **credible documented additive-cache risk**, independent of the fictional CLEAR_ADD control. In the documented additive model, a stale nonrepeatable complete entry not reported by the current API result can remain in the existing cache. No actual 3.3.5a/AzerothCore event or player state was instrumented, so the observed effect on game UI and acceptable corrections still need native verification. The CLEAR_ADD branch remains a hypothetical contrast, not an observed API guarantee. Unknown server response sequencing or request correlation is still speculative.

Potential safe remediation should be designed only after verifying the real client: compute a new scratch completed table from authoritative server state, then reconcile legitimate nonrepeatable and local daily/weekly/reset semantics without erasing a legitimate completion. Avoid unconditionally wiping live SavedVariables. This is a design direction, NOT an approved patch; whole G06 remains UNDERWAY.

## Part40 child: independently challenged reset and assertion accounting (test-only)

CS02's [exact-head independent #253 mutation review](https://github.com/CosmicCuddle/N-Questie/pull/253#issuecomment-6454804442) verified the original source-backed 14 cases on both Lua runtimes, but exposed **three surviving fictional mutants** and an execution-accounting weakness:

- **M4c** removing `Questie.db.char.complete[questId]=nil` inside `ResetDailyQuests` survived because the earlier daily reset case used a **repeatable** quest. The event handler filtered it first. This child adds a deliberately **nonrepeatable but daily-flagged fictional record** with an additive completion cache; the only normal code path clearing the stale complete key at an overdue reset is the daily-reset routine. No claim that native client dailies are nonrepeatable.
- **M4d** replacing the source's `now > dailyResetTime` with `now >= dailyResetTime` survived. An invented exact equality (`now==resetTime==100`) now pins the current source semantics, not a product decision about midnight/reset accuracy.
- **M9** removing the `resetDailyQuests` option guard survived. A control with both synthetic daily and weekly saved data and option disabled now ensures the handler does not merge either overlay.
- **K2/K3** replacing a control function body with no-op, or removing the control execution loop, previously left a misleading hardcoded count. The new test tracks **17 actual invoked controls and 20 passed assertions**, checks the expected assertion count **for each indexed control**, and fails if the loop or an individual assertion body is deleted. CI pins the computed output, not merely the inventory length. This is a bounded test-harness integrity check, not protection against an adversary deliberately changing all test and expected values together.

All input IDs are fictional. No production `Compat.lua` functions are modified; the test dynamically loads the actual public definitions inside fictional WoW APIs as before. This does not prove native 3.3.5a server reset behaviour, actual dates/timers or the owner-private Individual Progression state. Original reviewed #253 and parent #248 remain frozen. Historical #253 first-head synthetic-timer failure must remain recorded, and this child's own first-head CI requires exact original-head verification before it can be called green. Peer re-mutation of **M4c/M4d/M9/K2/K3** on real Lua5.1/5.4 is still required. No installation, merge, packaging, tagging or release authorised.
