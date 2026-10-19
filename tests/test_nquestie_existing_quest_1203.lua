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

-- Missing or malformed objective lists must never publish an item/text
-- correction. These are invented public test shapes, not real-world records.
local goodObjectives = original[10]
local originalStarter, originalEnder = original[2], original[3]
local originalPrior, originalText = original[13], original[8]
local malformed = {
    {label = "missing objectives"},
    {label = "non-table objectives", objectives = "malformed"},
    {label = "empty objectives", objectives = {}},
    {label = "missing item group", objectives = {[1] = {{8888}}}},
    {label = "non-table item group", objectives = {[3] = "malformed"}},
    {label = "empty item group", objectives = {[3] = {}}},
    {label = "non-table item entry", objectives = {[3] = {"malformed"}}},
    -- Numeric entries must not bypass the item-entry table-type guard.
    {label = "flat numeric item entry", objectives = {[3] = {33110}}},
    {label = "empty item entry", objectives = {[3] = {{}}}},
    {label = "text instead of item ID", objectives = {[3] = {{"33110"}}}},
    {label = "different numeric ID", objectives = {[3] = {{33111}}}},
    {label = "two item entries", objectives = {[3] = {{33110}, {33110}}}},
}
for _, testCase in ipairs(malformed) do
    original[10] = testCase.objectives
    local refused = registered[1]()
    assert(next(refused) == nil,
           "unsafe quest 1203 correction accepted: " .. testCase.label)
    assert(original[10] == testCase.objectives,
           "input objective list changed: " .. testCase.label)
    assert(original[2] == originalStarter and original[3] == originalEnder
           and original[13] == originalPrior and original[8] == originalText
           and original[4] == 30 and original[5] == 35,
           "unrelated inherited quest fields changed: " .. testCase.label)
end
original[10] = goodObjectives
assert(registered[1]()[1203] ~= nil,
       "valid quest correction not restored after malformed fixtures")

-- A newer Questie correction with a different ID should be respected.
original[10][3] = {{12345}}
assert(next(registered[1]()) == nil, "unexpected source objective was overwritten")
original[10][3] = {{33110}, {22222}}
assert(next(registered[1]()) == nil, "multiple objectives were overwritten")
original[10][3] = {{33110}}
questDB.questData[1203] = nil
assert(next(registered[1]()) == nil, "missing quest entry was created")
-- A numeric quest record detects weak `quest ~= nil` substitutes for the
-- Lua 5.1 table guard; all invented fixtures must refuse without mutation.
questDB.questData[1203] = 7
assert(next(registered[1]()) == nil, "numeric quest entry was corrected")
assert(questDB.questData[1203] == 7, "numeric quest entry was mutated")
questDB.questData[1203] = original
assert(registered[1]()[1203] ~= nil,
       "valid quest was not restored after numeric quest-record probe")

registered = {}
QuestieCompat.Is335 = false
dofile("Compat/NQuestieExistingQuestCorrections.lua")
assert(#registered == 0, "correction activated outside 3.3.5a")

print("PASS: quest 1203 item/text correction preserves fields and rejects 12 malformed objective shapes and numeric quest-record inputs")
