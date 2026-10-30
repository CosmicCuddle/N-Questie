# N-Questie — Part 49 Living Development Checklist

**Opened 30 October 2026 UTC; DOCS/TEST research only.** Read the [full Part48→49 handover](HANDOVERS/2026-10-30_PART48_TO_PART49.md) and this entire checklist before work. Also check [Part48](NQ-PART48-LIVING-DEVELOPMENT-CHECKLIST.md), [master](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), [native approval gate](research/NQ-PART47-NATIVE-335-EVIDENCE-OBSERVATION-GATE.md) and [coordination PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42).

## A. Ownership, protected branch, release blockers
- [x] At entry, protected live **335** is **26053bd28b0df3a01e5859f779d5f3cb4f57b221**, protected=true; approved README-only work, no research PR merges. Reverify next session.
- [x] Authentic historical original code commit **8b23c6e2cfa00bb81cb26d40c44fef154e9e0070** is DISTINCT from live 335.
- [ ] Gate08 **MAJOR RED**, 439 RAW quest candidates unapproved, eligible denominator unknown, pilots **1207–1209 0/3**; no Alpha0 or release.
- [ ] No owner-unapproved live edits, original addon Lua/SQL/TOC/DB, client, player/account/character/SavedVariables, install/build/ZIP/merge/tag/release/visibility/protection change.
- [ ] Native QA or instrumentation requires fresh explicit owner approval, isolated test identities/quests, verified addon/WTF/DBC/DB backup hashes, demonstrated rollback, privacy/stop conditions.

## B. Preserve immutable PR status and check new head
- [x] #420 TEST first head **481069bdf369bbec4028e030b8ae21ecb4dba4db** previously full 37/37 CI, 913/913 EACH Lua5.1.5 and Lua5.4.6 synthetic.
- [x] #421 DOCS first head **23de949b3cabaa7f057a67bf65735204c6e12e44** previous 7/7 CI.
- [x] #422 TEST first head **bcd6e6afa58295710d5965418cc6dfdd213836d3** recorded 932/932 EACH dedicated fake-host checks; rapid reaccept 40/40 already covered.
- [x] #424 DOCS first head **5a3bb3e51a9645b67ac988689bbdad12077e6c82** is authoritative Part48 entry; duplicate #425 CLOSED UNMERGED.
- [x] #426 DOCS first head **46f3337cb164d01f96411c6ed382010acbb95845** exactly 3 docs +60/-0, independently rechecked 8/8 matching original-head Actions completed SUCCESS; remains DRAFT UNMERGED.
- [ ] After opening **this Part49** DOCS child PR, inspect **its exact new head**, complete diff, own Actions and zero artifacts. Do not inherit prior green CI by implication.
- [x] Preserve failed first-submitted synthetic heads #390/#396/#397/#405/#406/#407/#414/#415; no force/rewrite/false native bug conclusions.

## C. Source findings and unknowns
- [x] Startup acceptance A/B/C is documented in #426. Registered-but-prequeue QUEST_ACCEPTED drop is conditional source path; independent delayed tracker recovery exists. Native timing/Journey/impact **UNKNOWN**.
- [x] Rapid abandon/reaccept source conditional is already tested under fabricated host; no duplicate.
- [x] Ordinary archive 3.3.5 abandon UI usually prepares SetAbandonQuest; missing captured ID real reachability **UNKNOWN**.
- [x] Reward completion original hook uses first-title quest-log scan; same-title static duplicates exist but simultaneous eligible logged quests unproven. Alternative giver-aware method also nonunique. Stock native GetQuestID appears only post-3.3.5a. Do not guess fix.
- [ ] Real reward-hook questlog timing, resolver ID accuracy, concurrent same-title eligibility and user impact **UNKNOWN**.

## D. Part49 immediate work
1. [ ] Read-only review of original reward identifier method, post-hook/system-message chain and #422 stub gaps. Test only if truly DISTINCT original-source coverage, not redundant assertion count.
2. [ ] Consider concise future **observation-only** reward-ID decision grid; no native execution until fresh owner/staging/rollback approval.
3. [ ] Review #42 for new genuine CS02/CS03 results; do not invent replies or reassign developers.
4. [ ] No N-Questie Maintenance Issue unless real cross-project dependency, after searching existing coordination Issues.
5. [ ] Keep all drafts unmerged and production unchanged. Gate08 remains the release blocker.

**This checklist is a plan, not evidence of native testing, a successful build or a merge.**

## E. Part49 distinct reward identity observation gate (30 October 2026)

- [x] Original first-party `Compat/Compat.lua` source confirmed: first-title quest-log ID resolver, reward post-hook title→ID cache, later localized completion message consumes and clears the entry. **Missing lookup does not clear a previously cached same-title ID**, and no independent expiry exists in that module. This is an original-source conditional, NOT a reproduced native 3.3.5a bug.
- [x] Archived 3.3.5 Blizzard **ordinary reward button and expense-confirmation popup both call `GetQuestReward`**; their post-hook quest-log/title state and client/server ordering remain UNKNOWN.
- [x] New [Part49 Reward Completion Identity Evidence Gate](research/NQ-PART49-335-REWARD-COMPLETION-IDENTITY-EVIDENCE-GATE.md) documents R1–R6 distinguishing unique match, missing match, actual same-title collision, stale map, overwrite and expense popup; sets strict future-only observation requirements. **DOCS-ONLY, no native QA authorization.**
- [ ] Only if separately owner-approved with disposable staging scope, real test quests, verified addon/WTF/DBC/DB backups and restoration, collect native hook-order/after-state evidence. No source patch, fabricated duplicate quest state, Journey replay, build, install, merge or release.

## F. Part49 Gate08 debug-validator writer and reader-lease audit (30 October 2026)

- [x] Read immutable original [`Database/compiler.lua`](https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/Database/compiler.lua#L1277-L1370): conditional debug `ValidateQuests()` mutates raw `QuestieDB.questData[*].extraObjectives[i][4]` nil→0 **post-compile** to normalize comparison. New concrete source-writer category, **NOT** measured native issue, and not proof a qualifying row occurs.
- [x] Audited original `ValidateNPCs`, `ValidateObjects`, `ValidateItems`, `ValidateQuests`: ordinary successful exits release **1/1/3/1** reader streams, but early mismatch/missing-drop returns occur **before** release. The three-reader `ValidateItems` case is an important conditional ownership boundary. Actual client leakage and pool impact **UNKNOWN**.
- [x] [Part49 Gate08 debug-validator writer / lease boundary](research/NQ-PART49-G08-DEBUG-VALIDATOR-SOURCE-WRITER-LEASE-BOUNDARY.md) records falsifiable W01/W02 and L01–L04 acceptance checks. SOURCE-ONLY, no test/client/code modification or Gate08 advancement.
- [ ] No further pure synthetic test unless it covers **genuinely untested original method bodies** and adds a discriminating result. Preserve source immutability and obtain separate user approval for future original addon changes or native verification.
