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

-- Matrix: each reviewed ID must refuse all unexpected, partially missing,
-- already-patched, absent and non-table inherited records. Unlike the
-- original two spot checks, this covers every one of the eight level pairs.
-- All mutations are temporary synthetic fixtures, not a production database.
local guardChecks = 0
for id, value in pairs(levels) do
    local row = database[id]
    local originalStarter, originalEnder = row[2], row[3]
    local originalObjectives, originalPrior = row[10], row[13]
    local originalFlags = row[17]

    local function refused(label, minimum, questLevel)
        row[4], row[5] = minimum, questLevel
        assert(registry[1]()[id] == nil,
               "unsafe level update for quest " .. id .. ": " .. label)
        assert(row[2] == originalStarter and row[3] == originalEnder and
               row[10] == originalObjectives and row[13] == originalPrior and
               row[17] == originalFlags,
               "unrelated inherited metadata changed: " .. id .. " " .. label)
        assert(row[4] == minimum and row[5] == questLevel,
               "inherited level values mutated: " .. id .. " " .. label)
        guardChecks = guardChecks + 1
    end

    refused("unexpected minimum", value[1] + 1, value[2])
    refused("unexpected quest level", value[1], value[2] + 1)
    refused("both levels unexpected", value[1] + 1, value[2] + 1)
    refused("missing minimum", nil, value[2])
    refused("missing quest level", value[1], nil)
    refused("already corrected", value[3], value[4])

    row[4], row[5] = value[1], value[2]
    assert(registry[1]()[id] ~= nil,
           "legitimate corrected pair not restored for quest " .. id)
    database[id] = nil
    assert(registry[1]()[id] == nil,
           "missing quest record unexpectedly patched: " .. id)
    guardChecks = guardChecks + 1
    database[id] = "malformed"
    assert(registry[1]()[id] == nil,
           "non-table quest record unexpectedly patched: " .. id)
    guardChecks = guardChecks + 1
    -- Lua 5.1 strings can return nil on numeric indexing, so a string-only
    -- fixture may fail to detect a weakened type(base) guard. A number cannot
    -- be indexed: this checks the table-type requirement independently.
    database[id] = 7
    assert(registry[1]()[id] == nil,
           "numeric quest record unexpectedly patched: " .. id)
    guardChecks = guardChecks + 1
    database[id] = row
    assert(row[4] == value[1] and row[5] == value[2],
           "synthetic level fixture not restored: " .. id)
end
assert(guardChecks == 72, "did not execute all eight-by-nine guard probes")

-- Whole-quest-database guard: malformed storage must fail closed before
-- looking up any individual quest. Restore the original table afterwards.
local savedQuestData = db.questData
local databaseGuardChecks = 0
local function rejectBadQuestDatabase(label)
    local refusal = registry[1]()
    assert(type(refusal) == "table" and next(refusal) == nil,
           "Dustwallow accepted malformed quest database: " .. label)
    databaseGuardChecks = databaseGuardChecks + 1
end
db.questData = nil
rejectBadQuestDatabase("missing")
for _, scalar in ipairs({7, true}) do
    db.questData = scalar
    rejectBadQuestDatabase("scalar " .. type(scalar))
    assert(db.questData == scalar, "quest database scalar was mutated")
end
db.questData = savedQuestData
assert(db.questData == savedQuestData and registry[1]()[1166] ~= nil,
       "Dustwallow valid database was not restored")
assert(databaseGuardChecks == 3, "incomplete quest database guard probes")

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

print("PASS: 8 precise Dustwallow level updates and 72 synthetic base-guard probes")
