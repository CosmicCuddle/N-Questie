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
local malformedProbeCount = 0
for _, testCase in ipairs(malformed) do
    malformedProbeCount = malformedProbeCount + 1
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
-- A sparse Lua 5.1 sequence can stop ipairs early. Count both executed
-- cases and indexed entries so the claimed twelve probes cannot silently
-- drift after a fixture deletion, nil hole or unexpected table key.
local indexedMalformedCases = 0
for key in pairs(malformed) do
    assert(type(key) == "number" and key == math.floor(key) and
           key >= 1 and key <= 12, "malformed fixture list is not dense")
    indexedMalformedCases = indexedMalformedCases + 1
end
assert(malformedProbeCount == 12 and indexedMalformedCases == 12,
       "quest 1203 did not execute all twelve malformed-objective probes")
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

-- Synthetic extra objective slots must be carried forward without changing
-- either the inherited objective list or unrelated payloads. This exercises
-- the existing outer-table copy, not a new game/client acceptance policy.
local fifthGroup = {{424242}, {434343}}
local supplementalMarker = {source = "synthetic"}
goodObjectives[5] = fifthGroup
goodObjectives.syntheticMarker = supplementalMarker
local firstExtra = registered[1]()[1203]
local secondExtra = registered[1]()[1203]
assert(firstExtra and secondExtra,
       "valid 1203 correction disappeared with unrelated objective data")
for _, patch in ipairs({firstExtra, secondExtra}) do
    local patchedObjectives = patch[10]
    assert(patchedObjectives ~= goodObjectives,
           "correction reused the inherited objective-list table")
    assert(patchedObjectives[3][1][1] == 3853 and
           patchedObjectives[3] ~= goodObjectives[3],
           "item correction failed to replace only the intended group")
    assert(patchedObjectives[5] == fifthGroup and
           patchedObjectives.syntheticMarker == supplementalMarker,
           "unrelated synthetic objective data was dropped or replaced")
    assert(patch[8][1]:find("Moonsteel Broadsword", 1, true),
           "objective text was lost during repeated correction")
end
assert(original[10] == goodObjectives and
       goodObjectives[3][1][1] == 33110 and
       goodObjectives[5] == fifthGroup and
       goodObjectives.syntheticMarker == supplementalMarker,
       "inherited Questie objective payload changed during callbacks")
assert(#fifthGroup == 2 and #fifthGroup[1] == 1 and
       #fifthGroup[2] == 1 and
       fifthGroup[1][1] == 424242 and fifthGroup[2][1] == 434343 and
       supplementalMarker.source == "synthetic",
       "inherited nested objective or metadata values mutated during callbacks")
-- Restore the source fixture so the non-3.3.5a registration test below remains
-- independent of these synthetic preservation probes.
goodObjectives[5] = nil
goodObjectives.syntheticMarker = nil
assert(original[10] == goodObjectives and
       original[10][3][1][1] == 33110 and
       registered[1]()[1203] ~= nil,
       "synthetic objective cleanup damaged the valid source fixture")

registered = {}
QuestieCompat.Is335 = false
dofile("Compat/NQuestieExistingQuestCorrections.lua")
assert(#registered == 0, "correction activated outside 3.3.5a")

print("PASS: quest 1203 item/text correction preserves fields and rejects 12 malformed objective shapes and numeric quest-record inputs")
