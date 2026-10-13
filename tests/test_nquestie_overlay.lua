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

-- The custom overlay is exclusive to the intended 3.3.5a client.
registry = {}
QuestieCompat.Is335 = false
dofile("Compat/NQuestieCustomQuestLoader.lua")
assert(next(registry) == nil, "custom overlay registered for a different client")

print("PASS: N-Questie quest, kill objectives, preserved NPC links, client guard")
