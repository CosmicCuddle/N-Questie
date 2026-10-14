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

print("PASS: 9 Classic quest chain corrections; prerequisites and GO starters preserved")
