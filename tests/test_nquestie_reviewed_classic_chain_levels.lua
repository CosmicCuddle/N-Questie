-- Lua 5.1 synthetic regression for two existing Classic quest chains.
-- This is not a substitute for Grok's combined real-DB M0 integration.
local callbacks = {}
QuestieCompat = {
    Is335 = true,
    RegisterCorrection = function(category, callback)
        assert(category == "questData")
        callbacks[#callbacks + 1] = callback
    end,
}

local expected = {
    [225] = {25, 30, 28, 35}, [227] = {25, 30, 28, 35},
    [228] = {25, 30, 28, 35}, [229] = {25, 30, 28, 35},
    [231] = {25, 30, 28, 35},
    [473] = {23, 26, 23, 28}, [464] = {23, 26, 23, 28},
    [465] = {23, 26, 23, 31}, [474] = {23, 26, 23, 32},
}
local predecessors = {
    [225] = nil, [227] = 225, [228] = 227, [229] = 228, [231] = 229,
    [473] = nil, [464] = 473, [465] = 464, [474] = 465,
}
local originals = {}
for id, values in pairs(expected) do
    originals[id] = {
        [1] = "Original quest name " .. id,
        [2] = {nil, {61}}, -- synthetic GO starter: must remain unchanged
        [3] = {{500 + id}}, -- synthetic NPC ender
        [4] = values[1], [5] = values[2],
        [8] = {"Keep original objective text"},
        [10] = {{}, {}, {{8888}}},
        [13] = predecessors[id] and {predecessors[id]} or nil,
        [16] = {id + 1000}, -- exclusive group
        [17] = id == 225 and 10 or 11,
        [22] = {9999},
    }
end
originals[1203] = {[4] = 30, [5] = 35}
originals[2001] = {[4] = 12, [5] = 16}

local db = {questKeys = {requiredLevel = 4, questLevel = 5}, questData = originals}
QuestieLoader = {ImportModule = function(_, name)
    assert(name == "QuestieDB")
    return db
end}

dofile("Compat/NQuestieReviewedClassicChainLevels.lua")
assert(#callbacks == 1, "expected exactly one correction callback")

local result = callbacks[1]()
local count = 0
for id, levels in pairs(expected) do
    count = count + 1
    local patch = result[id]
    assert(patch, "expected quest-level patch missing for " .. id)
    local minimum = levels[1] ~= levels[3] and levels[3] or nil
    assert(patch[4] == minimum, "incorrect minimum-level patch for " .. id)
    assert(patch[5] == levels[4], "incorrect quest-level patch for " .. id)
    for field in pairs(patch) do
        assert(field == 4 or field == 5, "unapproved quest field changed")
    end
    assert(originals[id][4] == levels[1] and originals[id][5] == levels[2],
           "source quest record mutated")
    assert(type(originals[id][2]) == "table" and originals[id][2][2][1] == 61,
           "GO starter was changed")
    assert(originals[id][3][1][1] == 500 + id, "NPC recipient changed")
    if predecessors[id] then
        assert(originals[id][13][1] == predecessors[id], "predecessor was changed")
    end
    assert(originals[id][10][3][1][1] == 8888, "item objective changed")
end
assert(count == 9, "expected precisely nine reviewed quest IDs")
assert(result[1203] == nil and result[2001] == nil, "unrelated quest overridden")

-- Regression matrix: each reviewed quest refuses all eight unexpected
-- inherited-record states. These are invented, temporary Lua 5.1 fixtures.
-- Retain the original spot checks and positive metadata/chain assertions.
local guardChecks = 0
for id, levels in pairs(expected) do
    local row = originals[id]
    local name, starter, ender = row[1], row[2], row[3]
    local text, objectives, prior = row[8], row[10], row[13]
    local exclusive, flags, successor = row[16], row[17], row[22]

    local function refused(label, minLevel, questLevel)
        row[4], row[5] = minLevel, questLevel
        assert(callbacks[1]()[id] == nil,
               "unsafe level update for quest " .. id .. ": " .. label)
        assert(row[1] == name and row[2] == starter and row[3] == ender and
               row[8] == text and row[10] == objectives and
               row[13] == prior and row[16] == exclusive and
               row[17] == flags and row[22] == successor,
               "unrelated Classic-chain source fields changed: " .. id .. " " .. label)
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
assert(guardChecks == 72,
       "incomplete synthetic source-guard matrix")

-- Whole-quest-database guard: malformed storage must fail closed before
-- looking up any individual quest. Restore the original table afterwards.
local savedQuestData = db.questData
local databaseGuardChecks = 0
local function rejectBadQuestDatabase(label)
    local refusal = callbacks[1]()
    assert(type(refusal) == "table" and next(refusal) == nil,
           "Classic-chain accepted malformed quest database: " .. label)
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
assert(db.questData == savedQuestData and callbacks[1]()[225] ~= nil,
       "Classic-chain valid database was not restored")
assert(databaseGuardChecks == 3, "incomplete quest database guard probes")

-- Guard: a changed upstream nominal level must not be replaced.
originals[225][5] = 99
assert(callbacks[1]()[225] == nil, "unexpected upstream nominal level overwritten")
originals[225][5] = 30
originals[464][4] = 99
assert(callbacks[1]()[464] == nil, "unexpected upstream minimum level overwritten")
originals[464][4] = 23
originals[474] = nil
assert(callbacks[1]()[474] == nil, "missing base quest was created")

-- Guard: nothing is registered for other client versions.
callbacks = {}
QuestieCompat.Is335 = false
dofile("Compat/NQuestieReviewedClassicChainLevels.lua")
assert(#callbacks == 0, "corrections activated outside WoW 3.3.5a")

print("PASS: 9 Classic quest chain corrections; prerequisites and GO starters preserved; 72 source-guard probes")
