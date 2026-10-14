-- Synthetic 3.3.5a test for a reviewed correction of EXISTING quest 1203.
-- Does not connect to the server, alter SavedVariables or load private SQL.
local registered = {}
QuestieCompat = {
    Is335 = true,
    RegisterCorrection = function(category, callback)
        assert(category == "questData", "only quest data may be corrected")
        registered[#registered + 1] = callback
    end,
}
local keys = {objectivesText = 8, objectives = 10, requiredLevel = 4,
              questLevel = 5, startedBy = 2, finishedBy = 3, preQuestSingle = 13}
local original = {
    [2] = {{4792}},
    [3] = {{4792}},
    [4] = 30,
    [5] = 35,
    [8] = {"Bring Razorspine's Sword to Jarl."},
    [10] = {{{8888}}, {{9999}}, {{33110}}, {{7777}}},
    [13] = {1206},
}
local questDB = {questKeys = keys, questData = {[1203] = original}}
QuestieLoader = {ImportModule = function(_, name)
    assert(name == "QuestieDB")
    return questDB
end}

dofile("Compat/NQuestieExistingQuestCorrections.lua")
assert(#registered == 1, "correction not registered")
local updates = registered[1]()
local quest = updates[1203]
assert(quest, "quest 1203 correction not returned")
assert(quest[10][3][1][1] == 3853, "wrong item objective")
assert(quest[8][1]:find("Moonsteel Broadsword", 1, true), "wrong objective text")
assert(quest[4] == nil and quest[5] == nil, "quest levels must not be changed")
assert(quest[2] == nil and quest[3] == nil and quest[13] == nil,
       "starter/ender/prerequisite must not be replaced")
assert(quest[10][1] == original[10][1] and
       quest[10][2] == original[10][2] and
       quest[10][4] == original[10][4],
       "existing non-item objectives were lost")
assert(original[10][3][1][1] == 33110, "original Questie objectives were mutated")

-- A newer Questie correction with a different ID should be respected.
original[10][3] = {{12345}}
assert(next(registered[1]()) == nil, "unexpected source objective was overwritten")
original[10][3] = {{33110}, {22222}}
assert(next(registered[1]()) == nil, "multiple objectives were overwritten")
original[10][3] = {{33110}}
questDB.questData[1203] = nil
assert(next(registered[1]()) == nil, "missing quest entry was created")

registered = {}
QuestieCompat.Is335 = false
dofile("Compat/NQuestieExistingQuestCorrections.lua")
assert(#registered == 0, "correction activated outside 3.3.5a")

print("PASS: quest 1203 item/text correction preserves existing levels and relationships")
