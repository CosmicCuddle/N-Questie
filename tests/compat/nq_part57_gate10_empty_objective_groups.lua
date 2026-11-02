-- Part57: item-only objective groups must stay nil so the real objectives
-- writer/reader round-trip matches under the original compiler equals().
-- Uses the real loader, real quest records 1207/1208/1209/2001, and the real
-- Database/compiler.lua codec and ValidateQuests. No client, SavedVariables,
-- SQL, server, or addon package. Native WoW 3.3.5a is NOT TESTED.

if not unpack then unpack = table.unpack end
tremove = table.remove

local function positiveBand(a, b)
    local result, bitValue = 0, 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then result = result + bitValue end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bitValue = bitValue * 2
    end
    return result
end
bit = {
    band = positiveBand,
    lshift = function(v, n) return v * (2 ^ n) end,
    rshift = function(v, n) return math.floor(v / (2 ^ n)) end,
}

local modules = {}
QuestieLoader = {
    CreateModule = function(_, name)
        modules[name] = modules[name] or {}
        return modules[name]
    end,
    ImportModule = function(_, name)
        modules[name] = modules[name] or {}
        return modules[name]
    end,
}
QuestieCompat = {Is335 = true, WOW_PROJECT_ID = 2}
Questie = {
    db = {profile = {debugEnabled = true, skipValidation = false}, global = {}},
    IsSoD = false, IsTBC = false, IsWotlk = true, DEBUG_INFO = "INFO",
    Error = function(_, ...) error("Questie error: " .. tostring((...)), 0) end,
    Warning = function() end,
    Debug = function() end,
}
DevTools_Dump = function() end
UnitLevel = function() return 60 end

assert(loadfile("Modules/QuestieStream.lua"))()
for _, path in ipairs({
    "Database/questDB.lua", "Database/npcDB.lua",
    "Database/objectDB.lua", "Database/itemDB.lua",
}) do
    assert(loadfile(path))()
end

local db = assert(modules.QuestieDB)
local keys = assert(db.questKeys)
local loaderPath = os.getenv("NQ_LOADER_PATH") or "Compat/NQuestieCustomQuestLoader.lua"
local dataPath = os.getenv("NQ_DATA_PATH") or "Compat/NQuestieCustomQuestData.lua"

local function deepcopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for k, v in pairs(value) do
        copy[deepcopy(k, seen)] = deepcopy(v, seen)
    end
    return copy
end

NQuestieCustomQuestData = nil
assert(loadfile(dataPath))()
local canonical = assert(NQuestieCustomQuestData)
local revisionAtLoad = canonical.revision

local function freshDb()
    db.questData = {[437] = {[keys.name] = "Existing prerequisite"}}
    db.npcData = {
        [2121] = {[db.npcKeys.name] = "Existing 2001 giver"},
        [1868] = {[db.npcKeys.name] = "Existing 2001 objective A"},
        [1869] = {[db.npcKeys.name] = "Existing 2001 objective B"},
        [3393] = {[db.npcKeys.name] = "Existing drop source"},
    }
    db.objectData = {}
    db.itemData = {}
end

local function boot(mutate)
    freshDb()
    if mutate then
        NQuestieCustomQuestData = deepcopy(canonical)
        mutate(NQuestieCustomQuestData, db)
    else
        NQuestieCustomQuestData = canonical
    end
    local callbacks = {}
    QuestieCompat.RegisterCorrection = function(kind, fn) callbacks[kind] = fn end
    assert(loadfile(loaderPath))()
    assert(type(callbacks.questData) == "function", "loader did not register questData")
    return callbacks.questData()
end

local checks = 0
local function check(label, ok)
    checks = checks + 1
    if not ok then error("FAIL " .. checks .. ": " .. label, 0) end
    print("PASS " .. checks .. ": " .. label)
end

local function keyList(t)
    local list = {}
    for k in pairs(t) do list[#list + 1] = tostring(k) end
    table.sort(list)
    return table.concat(list, ",")
end

local function sameIdList(group, ids)
    if type(group) ~= "table" or #group ~= #ids then return false end
    for i = 1, #ids do
        local pair = group[i]
        if type(pair) ~= "table" or pair[1] ~= ids[i] or pair[2] ~= nil or keyList(pair) ~= "1" then
            return false
        end
    end
    return true
end

-- Admission is unchanged: a kill+item record is still rejected, while each
-- single category (and an object-only record) is still accepted. Invented
-- IDs only; the canonical data file is not modified.
local MIXED, ITEM_ONLY, KILL_ONLY, OBJECT_ONLY = 99073, 99071, 99072, 99074
local side = boot(function(data, stub)
    stub.itemData[6611] = {[1] = "Synthetic trade item"}
    stub.objectData[8811] = {[1] = "Synthetic object objective"}
    local function base(extra)
        local row = {
            name = "Synthetic objective admission",
            requiredLevel = 12, questLevel = 16, zoneOrSort = 130,
            requiredRaces = 0, questFlags = 0,
            startedByNpcs = {2121}, finishedByNpcs = {2121},
        }
        for k, v in pairs(extra) do row[k] = v end
        return row
    end
    data.quests[ITEM_ONLY] = base({itemObjectives = {6611}})
    data.quests[KILL_ONLY] = base({killNpcs = {1868}})
    data.quests[MIXED] = base({killNpcs = {1868}, itemObjectives = {6611}})
    data.quests[OBJECT_ONLY] = base({objectObjectives = {8811}})
end)

check("mixed kill+item custom quest stays rejected", side[MIXED] == nil)
check("item-only synthetic still admitted beside the mixed rejection", side[ITEM_ONLY] ~= nil)
check("item-only synthetic leaves empty groups nil (keys exactly 3)",
    side[ITEM_ONLY] and keyList(side[ITEM_ONLY][keys.objectives]) == "3"
    and side[ITEM_ONLY][keys.objectives][1] == nil
    and side[ITEM_ONLY][keys.objectives][2] == nil
    and sameIdList(side[ITEM_ONLY][keys.objectives][3], {6611}))
check("kill-only synthetic still admitted with only slot 1",
    side[KILL_ONLY] and keyList(side[KILL_ONLY][keys.objectives]) == "1"
    and sameIdList(side[KILL_ONLY][keys.objectives][1], {1868}))
check("object-only empty kill group is nil and slot 2 is kept",
    side[OBJECT_ONLY] and keyList(side[OBJECT_ONLY][keys.objectives]) == "2"
    and sameIdList(side[OBJECT_ONLY][keys.objectives][2], {8811}))
check("gate10 quests stay admitted when an unrelated mixed quest is rejected",
    side[1207] and side[1208] and side[1209] and side[2001])

local updates = boot(nil)
check("combined owner-hover + objective fix uses revision 11",
    revisionAtLoad == 11 and NQuestieCustomQuestData.revision == 11)

local expect = {
    [1207] = {name = "The Kirin Tor Aid", items = {166}, starter = 1209},
    [1208] = {name = "Northwatch Intel", items = {167}, starter = 1209},
    [1209] = {name = "WANTED: The Northwatch Guard", items = {160, 161, 162}, starter = 1209},
}
for _, id in ipairs({1207, 1208, 1209}) do
    local row = updates[id]
    local objectives = row and row[keys.objectives]
    local spec = expect[id]
    check(id .. " approved with item objectives only in slot 3",
        row and row[keys.name] == spec.name
        and row[keys.startedBy][1][1] == spec.starter
        and row[keys.finishedBy][1][1] == spec.starter
        and type(objectives) == "table" and keyList(objectives) == "3"
        and objectives[1] == nil and objectives[2] == nil
        and sameIdList(objectives[3], spec.items))
end

local kill = updates[2001] and updates[2001][keys.objectives]
check("2001 keeps the kill-only shape with no empty slots",
    updates[2001] and updates[2001][keys.name] == "Ravenclaw Cleanup"
    and updates[2001][keys.startedBy][1][1] == 2121
    and updates[2001][keys.finishedBy][1][1] == 2121
    and updates[2001][keys.preQuestSingle][1] == 437
    and type(kill) == "table" and keyList(kill) == "1"
    and kill[2] == nil and kill[3] == nil
    and sameIdList(kill[1], {1868, 1869}))

assert(loadfile("Database/compiler.lua"))()
local compiler = assert(modules.DBCompiler)
local function originalEquals()
    local names = {}
    local i = 1
    while true do
        local name, value = debug.getupvalue(compiler.ValidateQuests, i)
        if not name then break end
        names[#names + 1] = name
        if name == "equals" and type(value) == "function" then return value end
        i = i + 1
    end
    error("original equals upvalue missing (" .. table.concat(names, ",") .. ")", 0)
end
local equals = originalEquals()
check("original equals still treats {} and nil as different keys",
    equals(nil, nil) == true
    and equals({}, nil) == false
    and equals({[1] = {}}, {}) == false
    and equals({[3] = {{166}}}, {[1] = {}, [2] = {}, [3] = {{166}}}) == false
    and equals({[3] = {{166}}}, {nil, nil, {{166}}}) == true)

local function roundTrip(payload)
    local writer = modules.QuestieStreamLib:GetStream("raw_assert")
    compiler.writers.objectives(writer, payload)
    local bytes = writer:Save()
    local reader = modules.QuestieStreamLib:GetStream("raw_assert")
    reader:Load(bytes)
    local decoded = compiler.readers.objectives(reader)
    return decoded, reader._pointer == #bytes + 1
end

for _, id in ipairs({1207, 1208, 1209, 2001}) do
    local payload = updates[id][keys.objectives]
    local decoded, consumed = roundTrip(payload)
    check(id .. " objectives round-trip under original equals",
        consumed and equals(decoded, payload) == true and equals(payload, decoded) == true)
end
do
    local decoded, consumed = roundTrip(side[OBJECT_ONLY][keys.objectives])
    check("object-only objectives round-trip under original equals",
        consumed and equals(decoded, side[OBJECT_ONLY][keys.objectives]) == true)
    local bad = {[1] = {}, [3] = updates[1207][keys.objectives][3]}
    local decodedBad = roundTrip(bad)
    check("reintroduced empty slot 1 still mismatches original equals",
        equals(decodedBad, bad) == false)
    bad = {[2] = {}, [3] = updates[1207][keys.objectives][3]}
    decodedBad = roundTrip(bad)
    check("reintroduced empty slot 2 still mismatches original equals",
        equals(decodedBad, bad) == false)
end

local function drive(fn)
    local co = coroutine.create(fn)
    for _ = 1, 100000 do
        local ok, err = coroutine.resume(co)
        if not ok then error(debug.traceback(co, tostring(err)), 0) end
        if coroutine.status(co) == "dead" then return end
    end
    error("validator coroutine did not finish", 0)
end

local compileRows = {}
for _, id in ipairs({1207, 1208, 1209, 2001}) do compileRows[id] = updates[id] end
db.questData = compileRows
drive(function()
    compiler:CompileTableCoroutine(compileRows, db.questCompilerTypes, db.questCompilerOrder,
        keys, "quest", "Quest", 1)
end)

local function runValidator(visitOrder)
    local warnings, visited, debugs = {}, {}, {}
    Questie.Warning = function(_, msg) warnings[#warnings + 1] = tostring(msg) end
    Questie.Debug = function(_, _, msg) debugs[#debugs + 1] = tostring(msg) end
    local savedPairs = pairs
    local function ordered(t)
        if t ~= db.questData then return savedPairs(t) end
        local i = 0
        return function()
            i = i + 1
            local id = visitOrder[i]
            if id == nil then return nil end
            visited[#visited + 1] = id
            return id, t[id]
        end
    end
    pairs = ordered
    _G.pairs = ordered
    local ok, err = pcall(function()
        drive(function() compiler:ValidateQuests() end)
    end)
    pairs = savedPairs
    _G.pairs = savedPairs
    if not ok then error(err, 0) end
    return warnings, visited, debugs
end

local function sameSeq(actual, expected)
    if #actual ~= #expected then return false end
    for i = 1, #actual do
        if tostring(actual[i]) ~= tostring(expected[i]) then return false end
    end
    return true
end

local cleanWarnings, cleanVisited, cleanDebug = runValidator({1207, 1208, 1209, 2001})
check("real ValidateQuests finishes 1207 then 1208, 1209 and 2001",
    #cleanWarnings == 0
    and sameSeq(cleanVisited, {1207, 1208, 1209, 2001})
    and table.concat(cleanDebug, "\n"):find("Finished quests validation without issues!", 1, true) ~= nil)

local savedObjectives = compileRows[1207][keys.objectives]
local savedName = compileRows[2001][keys.name]
local function restore()
    compileRows[1207][keys.objectives] = savedObjectives
    compileRows[2001][keys.name] = savedName
end

compileRows[1207][keys.objectives] = {
    [1] = {}, [2] = {}, [3] = savedObjectives[3],
}
compileRows[2001][keys.name] = "SENTINEL_SHOULD_NOT_BE_VALIDATED"
local beforeWarnings, beforeVisited = runValidator({1207, 2001})
restore()
check("pre-fix empty groups still make ValidateQuests return at 1207 before 2001",
    #beforeWarnings == 1
    and beforeWarnings[1] == "Nonmatching table at objectives  28 for ID: 1207"
    and sameSeq(beforeVisited, {1207}))

compileRows[2001][keys.name] = "SENTINEL_SHOULD_BE_VALIDATED"
local afterWarnings, afterVisited = runValidator({1207, 2001})
restore()
check("fixed 1207 no longer stops ValidateQuests before the next quest",
    #afterWarnings == 1
    and afterWarnings[1]:find("for ID: 2001", 1, true) ~= nil
    and afterWarnings[1]:find("for ID: 1207", 1, true) == nil
    and sameSeq(afterVisited, {1207, 2001}))

print("ALL " .. checks .. " PART57 EMPTY-OBJECTIVE-GROUP CHECKS PASS;"
    .. " native WoW client NOT TESTED.")
