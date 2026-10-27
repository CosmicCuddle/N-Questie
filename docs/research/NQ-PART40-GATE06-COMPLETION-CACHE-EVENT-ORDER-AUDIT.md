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