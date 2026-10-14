-- Synthetic fixtures for tools/validation/ObjectiveRules.lua.
-- Server rows use AzerothCore quest_template column names (SQL-shaped).
-- All ids are synthetic (9xxxxx) except quest 1203, whose public facts are
-- documented in docs/REVIEW-2026-10-14.md: the server requires one Moonsteel
-- Broadsword (3853); stock WotLK Questie has Razorspine's Sword (33110).
-- Questie records use QuestieDB.questKeys indices: 9 triggerEnd,
-- 10 objectives, 11 sourceItemId, 21 requiredSourceItems, 27 extraObjectives.
-- expect: list of {kind, class, rule-or-nil} that must appear.
-- forbid: classes that must NOT appear.

local CONFIRMED, EXPECTED = "CONFIRMED_MISMATCH", "EXPECTED_REPRESENTATION_DIFF"
local REVIEW, UNSUPPORTED = "NEEDS_MANUAL_REVIEW", "UNSUPPORTED"

return {
    {
        name = "normal kill and item quest matches",
        row = { ID = 900001, RequiredNpcOrGo1 = 900101, RequiredNpcOrGoCount1 = 8,
                RequiredItemId1 = 900201, RequiredItemCount1 = 5 },
        questie = { [10] = { { { 900101 } }, nil, { { 900201 } } } },
        expect = { { "quantity", EXPECTED, "E-QTY" }, { "order", EXPECTED, "E-ORDER-TYPE" } },
        forbid = { CONFIRMED, REVIEW, UNSUPPORTED },
    },
    {
        name = "quest 1203 Jarl Needs a Blade vs stock Questie (genuine item mismatch)",
        row = { ID = 1203, RequiredItemId1 = 3853, RequiredItemCount1 = 1 },
        questie = { [8] = { "Bring Razorspine's Sword to \"Swamp Eye\" Jarl at Swamplight Manor." },
                    [10] = { nil, nil, { { 33110 } } } },
        expect = { { "item", CONFIRMED, "M-ITEM-TARGET" } },
    },
    {
        name = "quest 1203 vs N-Questie corrected record",
        row = { ID = 1203, RequiredItemId1 = 3853, RequiredItemCount1 = 1 },
        questie = { [10] = { nil, nil, { { 3853 } } } },
        expect = { { "quantity", EXPECTED, "E-QTY" } },
        forbid = { CONFIRMED, REVIEW },
    },
    {
        name = "negative RequiredNpcOrGo is a gameobject",
        row = { ID = 900002, RequiredNpcOrGo1 = -900301, RequiredNpcOrGoCount1 = 1 },
        questie = { [10] = { nil, { { 900301, "Rune activated" } } } },
        expect = { { "object", EXPECTED, "E-GO-SIGN" } },
        forbid = { CONFIRMED, REVIEW },
    },
    {
        name = "gameobject listed by Questie as creature",
        row = { ID = 900003, RequiredNpcOrGo1 = -900302, RequiredNpcOrGoCount1 = 1 },
        questie = { [10] = { { { 900302 } } } },
        expect = { { "object", REVIEW, "R-GO-AS-NPC" } },
        forbid = { CONFIRMED },
        maxFindings = 2, -- E-QTY + R-GO-AS-NPC; no duplicate creature finding
    },
    {
        name = "gameobject missing, Questie models it as a spell objective",
        row = { ID = 900004, RequiredNpcOrGo1 = -900303, RequiredNpcOrGoCount1 = 1 },
        questie = { [10] = { nil, nil, nil, nil, nil, { { 900999, "Use the totem" } } } },
        expect = { { "object", REVIEW, "R-GO-UNPAIRED" } },
        forbid = { CONFIRMED },
    },
    {
        name = "server target covered by Questie killCreditObjective",
        row = { ID = 900005, RequiredNpcOrGo1 = 900110, RequiredNpcOrGoCount1 = 6 },
        questie = { [10] = { nil, nil, nil, nil, { { { 900111, 900112, 900113 }, 900110, "Spirits freed" } } } },
        expect = { { "creature", EXPECTED, "E-KILLCREDIT" } },
        forbid = { CONFIRMED, REVIEW },
    },
    {
        name = "creature_template KillCredit links Questie creature to server target",
        row = { ID = 900006, RequiredNpcOrGo1 = 900120, RequiredNpcOrGoCount1 = 10,
                KillCredit = { [900121] = { 900120, 0 } }, killCreditComplete = true },
        questie = { [10] = { { { 900121 } } } },
        expect = { { "creature", EXPECTED, "E-KC-TEMPLATE" } },
        forbid = { CONFIRMED, REVIEW },
    },
    {
        name = "different creatures, no KillCredit data supplied",
        row = { ID = 900007, RequiredNpcOrGo1 = 900130, RequiredNpcOrGoCount1 = 4 },
        questie = { [10] = { { { 900131 } } } },
        expect = { { "creature", REVIEW, "R-NPC-NOCREDIT" } },
        forbid = { CONFIRMED },
    },
    {
        name = "different creatures, complete KillCredit data, no link",
        row = { ID = 900008, RequiredNpcOrGo1 = 900140, RequiredNpcOrGoCount1 = 4,
                KillCredit = { [900141] = { 0, 0 } }, killCreditComplete = true },
        questie = { [10] = { { { 900141 } } } },
        expect = { { "creature", CONFIRMED, "M-NPC-TARGET" } },
    },
    {
        name = "required item is the StartItem kept as sourceItemId",
        row = { ID = 900009, StartItem = 900210, RequiredItemId1 = 900210, RequiredItemCount1 = 1 },
        questie = { [10] = nil, [11] = 900210 },
        expect = { { "item", EXPECTED, "E-STARTITEM" } },
        forbid = { CONFIRMED, REVIEW },
    },
    {
        name = "ItemDrop source item in requiredSourceItems",
        row = { ID = 900010, RequiredNpcOrGo1 = 900150, RequiredNpcOrGoCount1 = 1,
                ItemDrop1 = 900220 },
        questie = { [10] = { { { 900150 } } }, [21] = { 900220 } },
        expect = { { "item", EXPECTED, "E-SRCITEM" } },
        forbid = { CONFIRMED, REVIEW },
    },
    {
        name = "ItemDrop source item tracked by Questie as an objective",
        row = { ID = 900011, RequiredItemId1 = 900230, RequiredItemCount1 = 3, ItemDrop1 = 900231 },
        questie = { [10] = { nil, nil, { { 900230 }, { 900231 } } } },
        expect = { { "item", REVIEW, "R-SRC-AS-OBJECTIVE" } },
        forbid = { CONFIRMED },
    },
    {
        name = "extra required item on the server only",
        row = { ID = 900012, RequiredItemId1 = 900240, RequiredItemCount1 = 1,
                RequiredItemId2 = 900241, RequiredItemCount2 = 1 },
        questie = { [10] = { nil, nil, { { 900240 } } } },
        expect = { { "item", REVIEW, "R-ITEM-UNPAIRED" } },
        forbid = { CONFIRMED },
    },
    {
        name = "same creatures in a different order",
        row = { ID = 900013, RequiredNpcOrGo1 = 900160, RequiredNpcOrGoCount1 = 5,
                RequiredNpcOrGo2 = 900161, RequiredNpcOrGoCount2 = 5 },
        questie = { [10] = { { { 900161 }, { 900160 } } } },
        expect = { { "order", REVIEW, "R-ORDER-WITHIN-TYPE" } },
        forbid = { CONFIRMED },
    },
    {
        name = "gameobject slot before creature slot",
        row = { ID = 900014, RequiredNpcOrGo1 = -900310, RequiredNpcOrGoCount1 = 1,
                RequiredNpcOrGo2 = 900170, RequiredNpcOrGoCount2 = 3 },
        questie = { [10] = { { { 900170 } }, { { 900310 } } } },
        expect = { { "order", REVIEW, "R-ORDER-MIXED" }, { "object", EXPECTED, "E-GO-SIGN" } },
        forbid = { CONFIRMED },
    },
    {
        name = "scripted credit, conditions and Individual Progression gate",
        row = { ID = 900015, RequiredNpcOrGo1 = 900180, RequiredNpcOrGoCount1 = 1,
                scriptedCredit = true, hasConditions = true, ipGated = true },
        questie = { [10] = { { { 900181 } } } },
        expect = { { "creature", UNSUPPORTED, "C-SCRIPT" }, { "availability", UNSUPPORTED, "C-COND" },
                   { "availability", UNSUPPORTED, "C-IP" } },
        forbid = { CONFIRMED },
    },
    {
        name = "malformed input is not classified further",
        row = { ID = 900016, RequiredItemId1 = 900250.5, RequiredItemCount1 = -1 },
        questie = { [10] = { nil, nil, { { 900999 } } } },
        expect = { { "input", REVIEW, "R-MALFORMED" } },
        forbid = { CONFIRMED, EXPECTED },
    },
    {
        name = "server creature target with no Questie objective at all",
        row = { ID = 900018, RequiredNpcOrGo1 = 900195, RequiredNpcOrGoCount1 = 2 },
        questie = { [8] = { "Synthetic objective text" } },
        expect = { { "creature", REVIEW, "R-NPC-UNPAIRED" } },
        forbid = { CONFIRMED },
    },
    {
        name = "quest missing from Questie",
        row = { ID = 900017, RequiredNpcOrGo1 = 900190, RequiredNpcOrGoCount1 = 1 },
        questie = nil,
        expect = { { "quest", REVIEW, "R-QUEST-MISSING" } },
        forbid = { CONFIRMED },
    },
}
