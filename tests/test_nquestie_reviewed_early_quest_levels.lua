-- Synthetic Lua 5.1 verification of eleven reviewed early-zone quest levels.
-- Does not load a live server, original world SQL or player SavedVariables.
local callbacks = {}
QuestieCompat = {
    Is335 = true,
    RegisterCorrection = function(category, callback)
        assert(category == "questData")
        callbacks[#callbacks + 1] = callback
    end,
}
local expected = {
    [98] = {22, 32, 22, 35}, [126] = {15, 21, 15, 25},
    [169] = {11, 26, 15, 26}, [180] = {11, 26, 15, 26},
    [249] = {20, 26, 20, 27}, [256] = {9, 22, 17, 22},
    [304] = {26, 31, 26, 34}, [398] = {4, 10, 6, 10},
    [442] = {10, 20, 10, 24}, [895] = {9, 16, 11, 16},
    [6284] = {12, 21, 15, 21},
}
local originals = {}
for id, levels in pairs(expected) do
    originals[id] = {
        [2] = {{100 + id}}, [3] = {{200 + id}},
        [4] = levels[1], [5] = levels[2],
        [8] = {"Keep original objective text"},
        [10] = {{}, {}, {{7777}}},
        [13] = {3}, [17] = 10,
    }
end
originals[1203] = {[4] = 30, [5] = 35}
originals[2001] = {[4] = 12, [5] = 16}
local questDb = {
    questKeys = {requiredLevel = 4, questLevel = 5},
    questData = originals,
}
QuestieLoader = {ImportModule = function(_, name)
    assert(name == "QuestieDB")
    return questDb
end}

dofile("Compat/NQuestieReviewedEarlyQuestLevels.lua")
assert(#callbacks == 1, "one correction callback must be registered")
local changes = callbacks[1]()
local count = 0
for questId, source in pairs(expected) do
    count = count + 1
    local patch = changes[questId]
    assert(patch, "missing correction " .. questId)
    local expectedMinPatch = source[1] ~= source[3] and source[3] or nil
    local expectedQuestPatch = source[2] ~= source[4] and source[4] or nil
    assert(patch[4] == expectedMinPatch, "unexpected minimum-level patch " .. questId)
    assert(patch[5] == expectedQuestPatch, "unexpected quest-level patch " .. questId)
    assert(patch[2] == nil and patch[3] == nil and patch[8] == nil and
           patch[10] == nil and patch[13] == nil and patch[17] == nil,
           "unapproved unrelated quest field changed " .. questId)
    assert(originals[questId][4] == source[1] and
           originals[questId][5] == source[2],
           "original quest data was mutated " .. questId)
end
assert(count == 11, "expected 11 reviewed quests")
assert(changes[1203] == nil and changes[2001] == nil,
       "unrelated existing/custom quests altered")

-- Regression matrix: each reviewed quest refuses all eight unexpected
-- inherited-record states. These are invented, temporary Lua 5.1 fixtures.
-- Retain the original spot checks and positive metadata/chain assertions.
local guardChecks = 0
for id, levels in pairs(expected) do
    local row = originals[id]
    local starter, ender = row[2], row[3]
    local text, objectives, prior, flags = row[8], row[10], row[13], row[17]

    local function refused(label, minLevel, questLevel)
        row[4], row[5] = minLevel, questLevel
        assert(callbacks[1]()[id] == nil,
               "unsafe level update for quest " .. id .. ": " .. label)
        assert(row[2] == starter and row[3] == ender and
               row[8] == text and row[10] == objectives and
               row[13] == prior and row[17] == flags,
               "unrelated early-zone source fields changed: " .. id .. " " .. label)
        assert(row[4] == minLevel and row[5] == questLevel,
               "source level fields mutated: " .. id .. " " .. label)
        guardChecks = guardChecks + 1
    end

    refused("unexpected minimum", levels[1] + 1, levels[2])
    refused("unexpected quest level", levels[1], levels[2] + 1)
    refused("both levels unexpected", levels[1] + 1, levels[2] + 1)
    refused("missing minimum", nil, levels[2])
    refused("missing quest level", levels[1], nil)
    refused("already corrected", levels[3], levels[4])

    row[4], row[5] = levels[1], levels[2]
    assert(callbacks[1]()[id] ~= nil,
           "valid source levels not restored for " .. id)
    originals[id] = nil
    assert(callbacks[1]()[id] == nil,
           "absent quest was unexpectedly corrected: " .. id)
    guardChecks = guardChecks + 1
    -- A number checks table-type guards better than a Lua 5.1 string.
    originals[id] = 7
    assert(callbacks[1]()[id] == nil,
           "numeric quest record unexpectedly corrected: " .. id)
    guardChecks = guardChecks + 1
    originals[id] = row
    assert(row[4] == levels[1] and row[5] == levels[2] and
           callbacks[1]()[id] ~= nil,
           "legitimate quest source not restored: " .. id)
end
assert(guardChecks == 88,
       "incomplete synthetic source-guard matrix")

-- Whole-quest-database guard: malformed storage must fail closed before
-- looking up any individual quest. Restore the original table afterwards.
local savedQuestData = questDb.questData
local databaseGuardChecks = 0
local function rejectBadQuestDatabase(label)
    local refusal = callbacks[1]()
    assert(type(refusal) == "table" and next(refusal) == nil,
           "early-zone accepted malformed quest database: " .. label)
    databaseGuardChecks = databaseGuardChecks + 1
end
questDb.questData = nil
rejectBadQuestDatabase("missing")
for _, scalar in ipairs({7, true}) do
    questDb.questData = scalar
    rejectBadQuestDatabase("scalar " .. type(scalar))
    assert(questDb.questData == scalar, "quest database scalar was mutated")
end
questDb.questData = savedQuestData
assert(questDb.questData == savedQuestData and callbacks[1]()[98] ~= nil,
       "early-zone valid database was not restored")
assert(databaseGuardChecks == 3, "incomplete quest database guard probes")

-- Source guards fail closed when another correction already changed values.
originals[398][4] = 88
assert(callbacks[1]()[398] == nil, "unknown minimum-level value overwritten")
originals[398][4] = 4
originals[442][5] = 88
assert(callbacks[1]()[442] == nil, "unknown quest-level value overwritten")
originals[442][5] = 20
originals[895] = nil
assert(callbacks[1]()[895] == nil, "missing quest was created")

-- Unsupported client must not register corrections.
callbacks = {}
QuestieCompat.Is335 = false
dofile("Compat/NQuestieReviewedEarlyQuestLevels.lua")
assert(#callbacks == 0, "registered corrections outside 3.3.5a")

print("PASS: eleven guarded early-zone level corrections; metadata unchanged; 88 source-guard probes")
