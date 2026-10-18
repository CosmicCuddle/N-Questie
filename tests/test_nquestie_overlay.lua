-- Standalone Lua 5.1 regression test for the N-Questie correction layer.
-- No WoW client, account SavedVariables or private server database required.
local registry = {}
QuestieCompat = {
    Is335 = true,
    RegisterCorrection = function(name, callback)
        assert(type(callback) == "function")
        assert(registry[name] == nil, "duplicate correction registration")
        registry[name] = callback
    end,
}
local QuestieDB = {
    questKeys = {
        name = 1, startedBy = 2, finishedBy = 3, requiredLevel = 4,
        questLevel = 5, requiredRaces = 6, objectives = 10,
        preQuestSingle = 13, zoneOrSort = 17, questFlags = 23,
    },
    npcKeys = {questStarts = 10, questEnds = 11},
    npcData = {
        [2121] = {[10] = {477, 479, 480, 481, 516}, [11] = {478, 479, 480, 482, 516}},
        [1868] = {[10] = {}, [11] = {}},
        [1869] = {[10] = {}, [11] = {}},
    },
}
QuestieLoader = {ImportModule = function(_, module)
    assert(module == "QuestieDB")
    return QuestieDB
end}

dofile("Compat/NQuestieCustomQuestData.lua")
assert(NQuestieCustomQuestData.revision > 0)
dofile("Compat/NQuestieCustomQuestLoader.lua")
assert(type(registry.questData) == "function" and type(registry.npcData) == "function")

local quest = registry.questData()[2001]
assert(quest and quest[1] == "Ravenclaw Cleanup")
assert(quest[2][1][1] == 2121 and quest[3][1][1] == 2121)
assert(quest[4] == 12 and quest[5] == 16 and quest[17] == 130)
assert(quest[6] == 690 and quest[23] == 8)
assert(quest[13][1] == 437)
assert(quest[10][1][1][1] == 1868 and quest[10][1][2][1] == 1869)

local npc = registry.npcData()[2121]
assert(npc and #npc[10] == 6 and #npc[11] == 6)
assert(npc[10][6] == 2001 and npc[11][6] == 2001)
assert(npc[10][1] == 477 and npc[11][1] == 478, "existing quests were erased")
assert(#QuestieDB.npcData[2121][10] == 5, "base NPC data was mutated")
local again = registry.npcData()[2121]
assert(#again[10] == 6 and #again[11] == 6, "repeated callback appended duplicates")

-- Bad input must not crash or publish an invalid quest record.
NQuestieCustomQuestData.quests[999999] = {
    name = "Incomplete example", startedByNpcs = {2121},
}
assert(registry.questData()[999999] == nil, "invalid quest was not rejected")
assert(registry.npcData()[2121][10][6] == 2001, "invalid quest was linked")

-- Invented second quest: two starter mentions of the SAME NPC must not
-- duplicate its existing reverse links or corrupt ordinary vanilla quests.
-- This is only a synthetic extension to the existing public Lua 5.1 harness.
NQuestieCustomQuestData.quests[2002] = {
    name = "Synthetic Link Preservation",
    requiredLevel = 5, questLevel = 8,
    zoneOrSort = 130, requiredRaces = 690, questFlags = 8,
    startedByNpcs = {2121, 2121},
    finishedByNpcs = {2121},
    killNpcs = {1868},
    preQuestSingle = {437},
}
local two = registry.questData()
assert(two[2001] and two[2002], "second valid synthetic quest was lost")
assert(two[2002][10][1][1][1] == 1868, "synthetic objective not forwarded")
local twoNpc = registry.npcData()[2121]
assert(#twoNpc[10] == 7 and #twoNpc[11] == 7,
    "duplicate same-NPC starter emitted duplicate reverse quest links")
-- The custom quest registration uses pairs(), so relative order of
-- invented quest IDs 2001/2002 is unspecified. Only preserve original NPC
-- prefix order and prove each appended quest occurs exactly once.
local function containsExactlyOnce(list, target)
    local count = 0
    for _, id in ipairs(list) do
        if id == target then count = count + 1 end
    end
    return count == 1
end
for _, field in ipairs({10, 11}) do
    assert(containsExactlyOnce(twoNpc[field], 2001)
        and containsExactlyOnce(twoNpc[field], 2002),
        "synthetic quest link missing or duplicated")
    assert((twoNpc[field][6] == 2001 or twoNpc[field][6] == 2002)
        and (twoNpc[field][7] == 2001 or twoNpc[field][7] == 2002)
        and twoNpc[field][6] ~= twoNpc[field][7],
        "new quest links do not occupy both appended slots")
end
assert(twoNpc[10][1] == 477 and twoNpc[11][1] == 478,
    "unrelated vanilla NPC relations changed")
assert(#QuestieDB.npcData[2121][10] == 5
    and #QuestieDB.npcData[2121][11] == 5,
    "base NPC relations mutated by a synthetic overlay")
local twoAgain = registry.npcData()[2121]
assert(#twoAgain[10] == 7 and #twoAgain[11] == 7,
    "re-running callback duplicated synthetic reverse links")

-- A structurally valid quest referencing an NPC missing from the effective
-- public fixture may have questData, but must NOT fabricate NPC/spawn data.
NQuestieCustomQuestData.quests[2003] = {
    name = "Synthetic Missing-NPC Safety",
    requiredLevel = 5, questLevel = 8,
    zoneOrSort = 130, requiredRaces = 690, questFlags = 8,
    startedByNpcs = {900000001},
    finishedByNpcs = {900000001},
    killNpcs = {},
}
assert(registry.questData()[2003], "valid invented quest disappeared")
assert(registry.npcData()[900000001] == nil,
    "missing NPC was invented instead of requiring separate source QA")

-- Invalid objective IDs and invalid starter lists must NOT publish a quest
-- or inject a reverse link into an existing NPC.
NQuestieCustomQuestData.quests[999998] = {
    name = "Synthetic Invalid Objective",
    requiredLevel = 5, questLevel = 8,
    zoneOrSort = 130, requiredRaces = 690, questFlags = 8,
    startedByNpcs = {2121},
    finishedByNpcs = {2121},
    killNpcs = {0},
}
NQuestieCustomQuestData.quests[999997] = {
    name = "Synthetic Missing Starter",
    requiredLevel = 5, questLevel = 8,
    zoneOrSort = 130, requiredRaces = 690, questFlags = 8,
    startedByNpcs = {},
    finishedByNpcs = {2121},
    killNpcs = {},
}
local onlyValid = registry.questData()
assert(onlyValid[999998] == nil and onlyValid[999997] == nil,
    "structurally invalid synthetic quest was published")
local cleanNpc = registry.npcData()[2121]
assert(#cleanNpc[10] == 7 and #cleanNpc[11] == 7,
    "invalid synthetic quest appended a reverse NPC link")
assert(onlyValid[2001] and onlyValid[2002] and onlyValid[2003],
    "invalid quest suppressed previously accepted valid quests")

-- The custom overlay is exclusive to the intended 3.3.5a client.
registry = {}
QuestieCompat.Is335 = false
dofile("Compat/NQuestieCustomQuestLoader.lua")
assert(next(registry) == nil, "custom overlay registered for a different client")

print("PASS: N-Questie quest, multi-quest deduped links, malformed-record refusal, missing-NPC safety, client guard")
