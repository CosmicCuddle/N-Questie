-- Standalone Lua 5.1 regression: eight verified existing-quest level changes.
-- No access to live server, private world dump or player SavedVariables.
local registry = {}
QuestieCompat = {Is335 = true, RegisterCorrection = function(typ, callback)
    assert(typ == "questData")
    registry[#registry + 1] = callback
end}

local levels = {
    [1166] = {37, 41, 38, 43},
    [1168] = {37, 41, 38, 43},
    [1169] = {37, 41, 38, 43},
    [1170] = {37, 41, 38, 43},
    [1171] = {37, 41, 38, 43},
    [1172] = {37, 41, 38, 45},
    [1205] = {35, 41, 35, 45},
    [1252] = {30, 35, 30, 40},
}
local database = {}
for id, value in pairs(levels) do
    database[id] = {
        [2] = {{4792}}, [3] = {{4792}}, [4] = value[1], [5] = value[2],
        [10] = {{}, {}, {{3853}}}, [13] = {1206}, [17] = 15,
    }
end
database[2001] = {[4] = 12, [5] = 16}
local db = {questKeys = {requiredLevel = 4, questLevel = 5}, questData = database}
QuestieLoader = {ImportModule = function(_, name)
    assert(name == "QuestieDB")
    return db
end}

dofile("Compat/NQuestieReviewedQuestLevelCorrections.lua")
assert(#registry == 1)
local corrected = registry[1]()
local count = 0
for id, value in pairs(levels) do
    count = count + 1
    local fix = corrected[id]
    assert(fix, "missing verified level correction " .. id)
    assert(fix[5] == value[4], "unexpected new quest level")
    if value[1] ~= value[3] then
        assert(fix[4] == value[3], "wrong minimum level")
    else
        assert(fix[4] == nil, "untouched minimum level should not be replaced")
    end
    assert(fix[2] == nil and fix[3] == nil and fix[10] == nil and
           fix[13] == nil and fix[17] == nil, "other quest fields were touched")
    assert(database[id][4] == value[1] and database[id][5] == value[2],
           "inherited Questie data mutated")
end
assert(count == 8)
assert(corrected[2001] == nil, "custom quest unexpectedly overridden")

-- Already corrected or unexpected inherited values must not be overwritten.
database[1166][5] = 99
assert(registry[1]()[1166] == nil, "unknown upstream quest-level fix replaced")
database[1166][5] = 41
database[1252][4] = 31
assert(registry[1]()[1252] == nil, "unexpected minimum level replaced")
database[1252][4] = 30

-- Client-guard and missing-record handling are fail closed.
database[1172] = nil
assert(registry[1]()[1172] == nil, "missing quest was created")
registry = {}
QuestieCompat.Is335 = false
dofile("Compat/NQuestieReviewedQuestLevelCorrections.lua")
assert(#registry == 0, "overrides registered on unsupported client")

print("PASS: 8 precise Dustwallow quest-level updates, base guard, retained metadata")
