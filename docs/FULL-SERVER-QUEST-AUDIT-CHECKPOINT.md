# N-Questie — Full Server Quest Audit Checkpoint

**14 October 2026 · Draft research checkpoint · Not a live client change**

## Evidence

The maintainer provided the currently installed `Database/Wotlk/wotlkQuestDB.lua` and a private offline `acore_world.zip` export. The installed Questie Lua file has Git blob SHA `abbf2831b6d6b54b5d9383ba2c3e5cce5147379d`, **identical to the original source in this repository**. Thus the stock quest file is not out of sync with this N-Questie GitHub source.

The private export includes **9,525** quest templates. The installed Questie base file contains **9,086** quest entries. All 9,086 source IDs are present in the exported server table, leaving **439** server-only IDs. **Those 439 are not 439 approved imports**: many have unused/test/NYI/placeholder titles or lack mapped starter and ender data. Only **18** lack a placeholder/test tag and have both starter and ender links, and even those require quest eligibility and progression checks.

## Full-server, first-pass level differences

Raw stock `questLevel`: **139** differences. Raw `requiredLevel`: **150** differences. Union across either field: **259** quest IDs.

Applying the literal numeric level changes found in the Classic, TBC, then WotLK inherited correction tables **as an offline approximation** yields **270** remaining quest IDs with a mismatch in at least one level field: **148** nominal `questLevel` field differences and **154** minimum-level field differences (categories overlap). Six raw differences are explained by existing literal correction layers; 17 differences appear only after their application. The runtime may have further conditional/dynamic fixes. These are **candidates to review**, not 270 approved quest changes.

Known Dustwallow quest level discrepancies (IDs 1166, 1168, 1169, 1170, 1171, 1172, 1205, 1252) remain staged separately in draft PR #7, without changing unrelated quest records.

## Item-objective normalization

A naïve comparison produced **1,484** apparent item-ID mismatches. Questie frequently represents a required server item in `sourceItemId` rather than in `objectives[3]`.

After checking `sourceItemId`, **1,460** apparent differences are consistent with that representation. Only **24** item cases remain for detailed review. Do **not** bulk-replace source items or assume 1,460 cases are fully runtime-verified.

**Quest 1203, Jarl Needs a Blade** remains a confirmed concrete example: server requires one Moonsteel Broadsword (3853), while stock Questie references Razorspine's Sword (33110); the level fields already match. Draft PR #6 stages an item/objective-text-only change.

## Other candidate differences (not confirmed bugs)

- **151** NPC kill-objective differences; kill credits and scripted objectives must be examined.
- **1** gameobject objective difference.
- **623** quest starter NPC-list differences, **445** quest ender NPC-list differences (overlap).
- **570** potential prerequisite differences; negative `PrevQuestID`, exclusive chains and grouped prerequisites require interpretation.

These counts are from offline base Questie versus server SQL, and have **not** been resolved against all effective runtime correction, module, player-progression or quest-condition rules.

## Storage, approvals and next actions

The detailed, filterable **private seven-tab Excel audit** was generated in the conversation for the maintainer and **must not be uploaded to public GitHub**. Neither `acore_world.zip` nor private full mismatch data or character/account information belongs in this repository.

**Next:** Prioritize the 18 linked missing-quest candidates, 24 unresolved item cases, and high-impact early-zone level differences. Audit server/client NPC associations, previous quests, and IP-specific eligibility before proposing further **field-level** changes. Keep all new fixes on reviewed draft branches; test with a backed-up QA addon and saved variables. No automatic merge, stable release, N-Addon-Collection update, live SQL mutation, or installed-addon replacement without explicit maintainer approval.
