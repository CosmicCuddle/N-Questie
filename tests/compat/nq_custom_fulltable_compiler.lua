-- Isolated synthetic whole-table compiler harness.
-- Production path under test (no stubs of these functions):
--   QuestieDBCompiler:CompileTable
--   QuestieDBCompiler:CompileTableCoroutine
--   QuestieDBCompiler:BuildSkipMap
--   QuestieDBCompiler:GetDBHandle
-- Stream: real Modules/QuestieStream.lua. CompileTable asks for "raw".
-- CompileTableCoroutine asks for "raw_assert" when debugEnabled is set.
-- Schema: real Database/questDB.lua compiler order, types and questKeys.
--
-- This is compiler-only. It is NOT a WoW client PASS, NOT a SavedVariables
-- rebuild and NOT a real-database compile. Quest 2001 is not in this fixture.
-- zoneOrSort/questLevel -32768 is intentionally absent.
-- Mixed-kind objectives are not present and are not asserted.
--
-- Invented public IDs only. No private quest data.

if not unpack then unpack = table.unpack end

local function positiveBand(a, b)
    local answer, place = 0, 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then answer = answer + place end
        a, b, place = math.floor(a / 2), math.floor(b / 2), place * 2
    end
    return answer
end
bit = {
    band = positiveBand,
    lshift = function(v, n) return v * (2 ^ n) end,
    rshift = function(v, n) return math.floor(v / (2 ^ n)) end,
}
tremove = table.remove

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
    db = {profile = {debugEnabled = true}, global = {}},
    IsSoD = false,
    IsTBC = false,
    IsWotlk = true,
    DEBUG_INFO = "INFO",
    Error = function(_, ...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[#parts + 1] = tostring(select(i, ...))
        end
        error("Questie:Error: " .. table.concat(parts, " "), 0)
    end,
    Warning = function(_, ...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[#parts + 1] = tostring(select(i, ...))
        end
        error("Questie:Warning: " .. table.concat(parts, " "), 0)
    end,
    Debug = function() end,
}

assert(loadfile("Modules/QuestieStream.lua"))()
local streamLib = modules.QuestieStreamLib
assert(type(streamLib.GetStream) == "function", "QuestieStreamLib did not load")
assert(type(streamLib._WriteShort_assert) == "function", "raw_assert short writer missing")
local realGetStream = streamLib.GetStream
local streamModes = {}
function streamLib:GetStream(mode)
    streamModes[#streamModes + 1] = mode
    return realGetStream(self, mode)
end

assert(loadfile("Database/questDB.lua"))()
assert(loadfile("Database/compiler.lua"))()
local db = modules.QuestieDB
local compiler = modules.DBCompiler
assert(compiler and compiler.CompileTable and compiler.CompileTableCoroutine, "compiler not loaded")
assert(compiler.BuildSkipMap and compiler.GetDBHandle, "skip-map/handle API missing")
assert(compiler.writers and compiler.readers and compiler.writers.u8string and compiler.readers.u8string,
    "production u8string codec missing")

local keys = db.questKeys
local types = db.questCompilerTypes
local order = db.questCompilerOrder
local checks = 0
local function check(label, condition)
    checks = checks + 1
    if not condition then
        error("FAIL fulltable " .. checks .. " " .. label, 0)
    end
    print("PASS fulltable " .. checks .. " " .. label)
end
local function show(value)
    if value == nil then return "Lua nil" end
    if type(value) == "string" then return "string \"" .. value .. "\"" end
    return type(value) .. " " .. tostring(value)
end
local function join(list, sep)
    local out = {}
    for i = 1, #list do out[i] = tostring(list[i]) end
    return table.concat(out, sep or ",")
end
local function drive(fn)
    local co = coroutine.create(fn)
    local resumes, yields = 0, 0
    while true do
        resumes = resumes + 1
        if resumes > 100000 then error("runaway coroutine", 0) end
        local ok, value = coroutine.resume(co)
        if not ok then error(debug.traceback(co, tostring(value)), 0) end
        if coroutine.status(co) == "dead" then return value, yields, resumes end
        yields = yields + 1
    end
end
local function copyList(src)
    local out = {}
    for i = 1, #src do out[i] = src[i] end
    return out
end

-- Production schema must be the real quest compiler order, not a subset.
local seenOrder = {}
for index = 1, #order do
    local key = order[index]
    check("compiler order entry " .. index .. " " .. tostring(key) .. " has a type",
        type(key) == "string" and type(types[key]) == "string" and keys[key] ~= nil)
    check("compiler order key is unique: " .. tostring(key), not seenOrder[key])
    seenOrder[key] = index
end
for key, index in pairs(keys) do
    check("questKeys." .. key .. " is in compiler order", seenOrder[key] ~= nil and type(index) == "number")
end

local function objectiveIds(base, count)
    local ids = {}
    for i = 1, count do ids[i] = base + i end
    return ids
end
local function oneKindObjectives(kind, ids, text)
    local list = {}
    for i = 1, #ids do list[i] = {ids[i], text} end
    if kind == "go" then return {nil, list} end
    if kind == "item" then return {nil, nil, list} end
    error("unknown objective kind " .. tostring(kind), 0)
end
local function kindCount(objectives)
    local count = 0
    if objectives[1] ~= nil then count = count + 1 end
    if objectives[2] ~= nil then count = count + 1 end
    if objectives[3] ~= nil then count = count + 1 end
    return count
end

-- Capacity names are the same length so entry-size deltas are objective bytes only.
local capGo = {
    [1] = "GO-capacity-list-01",
    [2] = "GO-capacity-list-02",
    [255] = "GO-capacity-list-FF",
}
local capItem = {
    [1] = "IT-capacity-list-01",
    [2] = "IT-capacity-list-02",
    [255] = "IT-capacity-list-FF",
}
for _, name in pairs(capGo) do
    assert(#name == #capGo[1], "GO capacity names must share a length")
end
for _, name in pairs(capItem) do
    assert(#name == #capItem[1], "item capacity names must share a length")
end

local specs = {
    [920241] = {
        role = "control", inputName = "Synthetic control name",
        kind = "go", count = 1, text = nil, idBase = 881100,
        questLevel = -1, requiredLevel = 10, flags = 8, rep = {930001, 11},
    },
    [920242] = {
        role = "literal-nil-name", inputName = "nil",
        kind = "item", count = 1, text = nil, idBase = 661100,
        questLevel = 21, requiredLevel = 11, flags = 16, rep = {930002, 22},
        literalNilFinding = true,
    },
    [920243] = {
        role = "lua-nil-name", inputName = nil,
        kind = "go", count = 1, text = nil, idBase = 881200,
        questLevel = 16, requiredLevel = 12, flags = 32, rep = {930003, 33},
    },
    [920244] = {
        role = "go-cap-1", inputName = capGo[1],
        kind = "go", count = 1, text = nil, idBase = 881300,
        questLevel = 15, requiredLevel = 13, flags = 64, rep = {910001, 1},
        sizeGroup = "go",
    },
    [920245] = {
        role = "go-cap-2", inputName = capGo[2],
        kind = "go", count = 2, text = nil, idBase = 881400,
        questLevel = 15, requiredLevel = 14, flags = 128, rep = {910002, 2},
        sizeGroup = "go",
    },
    [920246] = {
        role = "go-cap-255", inputName = capGo[255],
        kind = "go", count = 255, text = nil, idBase = 881500,
        questLevel = 15, requiredLevel = 15, flags = 256, rep = {910255, 255},
        sizeGroup = "go",
    },
    [920247] = {
        role = "item-cap-1", inputName = capItem[1],
        kind = "item", count = 1, text = nil, idBase = 661200,
        questLevel = 15, requiredLevel = 16, flags = 512, rep = {920001, 1},
        sizeGroup = "item",
    },
    [920248] = {
        role = "item-cap-2", inputName = capItem[2],
        kind = "item", count = 2, text = nil, idBase = 661300,
        questLevel = 15, requiredLevel = 17, flags = 1024, rep = {920002, 2},
        sizeGroup = "item",
    },
    [920249] = {
        role = "item-cap-255", inputName = capItem[255],
        kind = "item", count = 255, text = nil, idBase = 661400,
        questLevel = 15, requiredLevel = 18, flags = 2048, rep = {920255, 255},
        sizeGroup = "item",
    },
}
local probeId = 920250
local probeObjectiveText = "Use synthetic object"
local probeExtraText = "extra-probe"
local probe = {
    role = "order-probe", inputName = "Order probe synthetic",
    kind = "go", count = 1, text = probeObjectiveText, idBase = 881900,
    questLevel = 42, requiredLevel = 19, flags = 4096, rep = {930004, 44},
}

local function buildEntry(spec)
    local ids = objectiveIds(spec.idBase, spec.count)
    spec.ids = ids
    local objectives = oneKindObjectives(spec.kind, ids, spec.text)
    spec.objectives = objectives
    local entry = {
        [keys.name] = spec.inputName,
        [keys.startedBy] = {{7711}},
        [keys.finishedBy] = {{7712}},
        [keys.requiredLevel] = spec.requiredLevel,
        [keys.questLevel] = spec.questLevel,
        [keys.requiredRaces] = 0,
        [keys.zoneOrSort] = 130,
        [keys.questFlags] = spec.flags,
        [keys.objectives] = objectives,
        [keys.reputationReward] = {{spec.rep[1], spec.rep[2]}},
    }
    return entry
end

local tbl = {}
local specById = {}
for id, spec in pairs(specs) do
    spec.id = id
    specById[id] = spec
    tbl[id] = buildEntry(spec)
end
probe.id = probeId
probe.ids = objectiveIds(probe.idBase, probe.count)
probe.objectives = oneKindObjectives(probe.kind, probe.ids, probe.text)
specById[probeId] = probe
tbl[probeId] = {
    [keys.name] = probe.inputName,
    [keys.startedBy] = {{7711, 7713}},
    [keys.finishedBy] = {{7712}},
    [keys.requiredLevel] = probe.requiredLevel,
    [keys.questLevel] = probe.questLevel,
    [keys.requiredRaces] = 690,
    [keys.requiredClasses] = 2,
    [keys.objectivesText] = {"Synthetic order probe text"},
    [keys.triggerEnd] = {"probe-trigger", {[130] = {{10, 20}}}},
    [keys.objectives] = probe.objectives,
    [keys.sourceItemId] = 660099,
    [keys.preQuestGroup] = {920281},
    [keys.preQuestSingle] = {920282, 920283},
    [keys.childQuests] = {920284},
    [keys.inGroupWith] = {920285},
    [keys.exclusiveTo] = {920286},
    [keys.zoneOrSort] = 130,
    [keys.requiredSkill] = {11, 22},
    [keys.requiredMinRep] = {68, 10},
    [keys.requiredMaxRep] = {69, 20},
    [keys.requiredSourceItems] = {660098},
    [keys.nextQuestInChain] = 920299,
    [keys.questFlags] = probe.flags,
    [keys.specialFlags] = 1,
    [keys.parentQuest] = 920298,
    [keys.reputationReward] = {{probe.rep[1], probe.rep[2]}},
    [keys.extraObjectives] = {
        {
            {[130] = {{1, 1}}},
            5,
            probeExtraText,
            1,
            {{"object", 881901}},
        },
    },
    [keys.requiredSpell] = 123,
    [keys.requiredSpecialization] = 456,
    [keys.requiredMaxLevel] = 60,
}
probe.entry = tbl[probeId]

local questCount = 0
for id, entry in pairs(tbl) do
    questCount = questCount + 1
    local spec = specById[id]
    check("fixture " .. id .. " is one objective kind",
        kindCount(entry[keys.objectives]) == 1 and entry[keys.objectives][5] == nil
        and entry[keys.objectives][6] == nil and spec.kind ~= "mixed")
    check("fixture " .. id .. " keeps zoneOrSort away from -32768",
        entry[keys.zoneOrSort] ~= -32768 and entry[keys.questLevel] ~= -32768
        and entry[keys.zoneOrSort] == 130)
    assert(id ~= 2001, "quest 2001 must not be part of this compiler fixture")
    assert(id >= 920241 and id <= 920250, "fixture id left the invented range")
end
check("fixture quest count is the invented set", questCount == 10)
check("quest 2001 is not in the compiler fixture", tbl[2001] == nil)
check("literal nil-name fixture is the string nil", tbl[920242][keys.name] == "nil")
check("lua nil-name fixture stores Lua nil", tbl[920243][keys.name] == nil)
check("control fixture stores an ordinary name", tbl[920241][keys.name] == "Synthetic control name")

-- Every order-probe field is a distinct non-nil value so a pairs(order)
-- permutation cannot hide behind identical nil encodings.
local probeSeen = {}
for index = 1, #order do
    local key = order[index]
    local value = probe.entry[keys[key]]
    check("order probe field " .. key .. " is populated", value ~= nil)
    local token = types[key] .. ":" .. tostring(value)
    check("order probe field " .. key .. " value is distinct", not probeSeen[token])
    probeSeen[token] = key
end

local trace = {}
local depth = 0
for typ, fn in pairs(compiler.writers) do
    compiler.writers[typ] = function(stream, value)
        local top = depth == 0
        depth = depth + 1
        if top then
            trace[#trace + 1] = {typ = typ, value = value, start = stream._pointer}
        end
        local ok, err = pcall(fn, stream, value)
        if top then trace[#trace].finish = stream._pointer end
        depth = depth - 1
        if not ok then error(err, 0) end
    end
end

local function clearTrace()
    for i = 1, #trace do trace[i] = nil end
end
local function snapshotModes()
    return #streamModes
end
local function modesSince(mark)
    local out = {}
    for i = mark + 1, #streamModes do out[#out + 1] = streamModes[i] end
    return out
end
local function chunkEntries(recorded)
    assert(#recorded % #order == 0, "top-level writer calls " .. #recorded .. " not divisible by " .. #order)
    local entries = {}
    for start = 1, #recorded, #order do
        local chunk = {}
        for offset = 0, #order - 1 do chunk[#chunk + 1] = recorded[start + offset] end
        entries[#entries + 1] = chunk
    end
    return entries
end
local function chunkName(chunk)
    local found
    for i = 1, #chunk do
        if chunk[i].typ == "u8string" then
            assert(found == nil, "more than one u8string field was written")
            found = chunk[i].value
        end
    end
    return found
end
local function idForWrittenName(value)
    if value == nil then return 920243 end
    for id, spec in pairs(specById) do
        if spec.inputName == value then return id end
    end
    return nil
end
local function entryOrder(chunks)
    local ids = {}
    for i = 1, #chunks do
        local id = idForWrittenName(chunkName(chunks[i]))
        assert(id, "could not map a compiled entry back to a fixture")
        ids[i] = id
    end
    return ids
end
local function sameSequence(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do
        if a[i] ~= b[i] then return false end
    end
    return true
end
local function fieldOrderMatchesIndexed(chunks)
    for _, chunk in ipairs(chunks) do
        local id = idForWrittenName(chunkName(chunk))
        local entry = tbl[id]
        for index = 1, #order do
            local key = order[index]
            local call = chunk[index]
            if call.typ ~= types[key] or call.value ~= entry[keys[key]] then
                return false, id, key, index
            end
        end
    end
    return true
end
local function indexedIds()
    local ids = {}
    for id in pairs(tbl) do ids[#ids + 1] = id end
    table.sort(ids)
    return ids
end
local function pairsIds()
    local ids = {}
    for id in pairs(tbl) do ids[#ids + 1] = id end
    return ids
end

local modeMark = snapshotModes()
local binTable, ptrTable = compiler:CompileTable(tbl, types, order, keys)
local modesTable = modesSince(modeMark)
local traceTable = copyList(trace)
clearTrace()

Questie.db.profile.debugEnabled = true
Questie.db.global = {}
modeMark = snapshotModes()
local _, yieldsDebug = drive(function()
    compiler:CompileTableCoroutine(tbl, types, order, keys, "quest", "Quest", 1)
end)
local binDebug = Questie.db.global.questBin
local ptrDebug = Questie.db.global.questPtrs
local modesDebug = modesSince(modeMark)
local traceDebug = copyList(trace)
clearTrace()

Questie.db.profile.debugEnabled = false
Questie.db.global = {}
modeMark = snapshotModes()
local _, yieldsStepped = drive(function()
    compiler:CompileTableCoroutine(tbl, types, order, keys, "quest", "Quest", 0)
end)
local binStepped = Questie.db.global.questBin
local ptrStepped = Questie.db.global.questPtrs
local modesStepped = modesSince(modeMark)
local traceStepped = copyList(trace)
clearTrace()

check("CompileTable requests the real raw stream", #modesTable == 1 and modesTable[1] == "raw")
check("debug CompileTableCoroutine requests raw_assert",
    #modesDebug == 1 and modesDebug[1] == "raw_assert")
check("stepped CompileTableCoroutine requests raw",
    #modesStepped == 1 and modesStepped[1] == "raw")
check("CompileTable returned binary payloads",
    type(binTable) == "string" and #binTable > 0 and type(ptrTable) == "string" and #ptrTable > 0)
check("debug coroutine stored questBin and questPtrs",
    type(binDebug) == "string" and #binDebug > 0 and type(ptrDebug) == "string" and #ptrDebug > 0)
check("stepped coroutine stored questBin and questPtrs",
    type(binStepped) == "string" and #binStepped > 0 and type(ptrStepped) == "string" and #ptrStepped > 0)
check("debug coroutine yielded and then finished in one batch", yieldsDebug == 1)
check("stepped coroutine yields once per entry plus the terminal index",
    yieldsStepped == questCount + 1)

local chunksTable = chunkEntries(traceTable)
local chunksDebug = chunkEntries(traceDebug)
local chunksStepped = chunkEntries(traceStepped)
check("CompileTable wrote every fixture entry", #chunksTable == questCount)
check("debug coroutine wrote every fixture entry", #chunksDebug == questCount)
check("stepped coroutine wrote every fixture entry", #chunksStepped == questCount)

local orderTable = entryOrder(chunksTable)
local orderDebug = entryOrder(chunksDebug)
local orderStepped = entryOrder(chunksStepped)
local numericIds = indexedIds()
local hashIds = pairsIds()
print("OBSERVED CompileTable entry order: " .. join(orderTable))
print("OBSERVED CompileTableCoroutine debug entry order: " .. join(orderDebug))
print("OBSERVED CompileTableCoroutine stepped entry order: " .. join(orderStepped))
print("OBSERVED pairs(tbl) entry order: " .. join(hashIds))
print("OBSERVED numeric id order: " .. join(numericIds))
check("CompileTable entry order matches this runtime's pairs(tbl)", sameSequence(orderTable, hashIds))
check("debug coroutine entry order is numeric ascending", sameSequence(orderDebug, numericIds))
check("stepped coroutine entry order is numeric ascending", sameSequence(orderStepped, numericIds))

local function reportFieldOrder(label, chunks)
    local ok, id, key, index = fieldOrderMatchesIndexed(chunks)
    print("OBSERVED " .. label .. " field order matches indexed 1..#order: " .. tostring(ok))
    if not ok then
        print("OBSERVED " .. label .. " first field-order mismatch quest " .. tostring(id)
            .. " index " .. tostring(index) .. " expected " .. tostring(key))
    end
    check(label .. " field order matches production indexed order", ok)
end
reportFieldOrder("CompileTable", chunksTable)
reportFieldOrder("debug coroutine", chunksDebug)
reportFieldOrder("stepped coroutine", chunksStepped)

local function entrySize(chunks, id)
    for i = 1, #chunks do
        if idForWrittenName(chunkName(chunks[i])) == id then
            local bytes = chunks[i][#chunks[i]].finish - chunks[i][1].start
            return bytes
        end
    end
    return nil
end
local function assertCapacitySizes(label, chunks, group, counts)
    local sizes = {}
    for i = 1, #counts do
        local count = counts[i]
        local id
        for specId, spec in pairs(specById) do
            if spec.sizeGroup == group and spec.count == count then id = specId end
        end
        sizes[count] = entrySize(chunks, id)
        check(label .. " " .. group .. " capacity " .. count .. " entry size recorded",
            type(sizes[count]) == "number" and sizes[count] > 0)
    end
    check(label .. " " .. group .. " capacity 2 is 4 bytes larger than capacity 1",
        sizes[2] - sizes[1] == 4)
    check(label .. " " .. group .. " capacity 255 is 1016 bytes larger than capacity 1",
        sizes[255] - sizes[1] == 254 * 4)
end
for _, packed in ipairs({
    {"CompileTable", chunksTable},
    {"debug coroutine", chunksDebug},
    {"stepped coroutine", chunksStepped},
}) do
    assertCapacitySizes(packed[1], packed[2], "go", {1, 2, 255})
    assertCapacitySizes(packed[1], packed[2], "item", {1, 2, 255})
end

local skip = compiler:BuildSkipMap(types, order)
local skipMap, lastIndex, lastPtr = unpack(skip)
local staticBytes, firstDynamic = 0, nil
for index = 1, #order do
    local typ = types[order[index]]
    if compiler.dynamics[typ] then firstDynamic = index break end
    staticBytes = staticBytes + compiler.statics[typ]
end
check("BuildSkipMap direct-skips the static prefix through the first dynamic",
    firstDynamic ~= nil and lastIndex == firstDynamic and lastPtr == staticBytes
    and skipMap[order[firstDynamic]] == staticBytes)
check("BuildSkipMap has no direct skip for objectives", skipMap.objectives == nil)
check("BuildSkipMap has no direct skip for the field after objectives", skipMap.reputationReward == nil)
check("BuildSkipMap has no direct skip for extraObjectives", skipMap.extraObjectives == nil)
check("first dynamic field is name", order[firstDynamic] == "name")

local function dump(value, depth)
    depth = depth or 0
    if depth > 6 then return "..." end
    if type(value) ~= "table" then return show(value) end
    local parts = {}
    local n = 0
    for k, v in pairs(value) do
        n = n + 1
        if n > 8 then parts[#parts + 1] = "..." break end
        parts[#parts + 1] = "[" .. tostring(k) .. "]=" .. dump(v, depth + 1)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end
local function objectivesMatch(got, spec)
    if type(got) ~= "table" then return false, "objectives not a table (" .. show(got) .. ")" end
    if got[1] ~= nil then return false, "npc slot populated" end
    if spec.kind ~= "go" and got[2] ~= nil then return false, "go slot populated" end
    if spec.kind ~= "item" and got[3] ~= nil then return false, "item slot populated" end
    if got[4] ~= nil or got[5] ~= nil or got[6] ~= nil then return false, "extra objective slot populated" end
    local slot = spec.kind == "go" and 2 or 3
    local list = got[slot]
    if type(list) ~= "table" or #list ~= spec.count then
        return false, "count " .. tostring(list and #list) .. " ~= " .. spec.count
    end
    for i = 1, spec.count do
        if list[i][1] ~= spec.ids[i] then return false, "id mismatch at " .. i end
        if list[i][2] ~= spec.text then return false, "text mismatch at " .. i end
    end
    return true
end
local function repMatch(got, spec)
    return type(got) == "table" and #got == 1 and got[1][1] == spec.rep[1] and got[1][2] == spec.rep[2]
end

local paths = {
    {label = "CompileTable", bin = binTable, ptrs = ptrTable},
    {label = "CompileTableCoroutine-raw_assert", bin = binDebug, ptrs = ptrDebug},
    {label = "CompileTableCoroutine-stepped-raw", bin = binStepped, ptrs = ptrStepped},
}
local nameReport = {}
for _, path in ipairs(paths) do
    local modeMarkHandle = snapshotModes()
    local handle, yieldsHandle = drive(function()
        return compiler:GetDBHandle(path.bin, path.ptrs, skip)
    end)
    local modesHandle = modesSince(modeMarkHandle)
    check(path.label .. " GetDBHandle requests raw and yields through pointer decode",
        yieldsHandle == 4 and #modesHandle == 1 and modesHandle[1] == "raw"
        and type(handle) == "table" and type(handle.QuerySingle) == "function"
        and type(handle.Query) == "function" and type(handle.QueryValidator) == "function")
    for _, id in ipairs(numericIds) do
        local spec = specById[id]
        local openedName = handle.QuerySingle(id, "name")
        local openedLevel = handle.QuerySingle(id, "requiredLevel")
        nameReport[#nameReport + 1] = path.label .. " QuerySingle(" .. id .. ",\"name\") = " .. show(openedName)
            .. " requiredLevel=" .. show(openedLevel) .. " role=" .. spec.role
        check(path.label .. " quest " .. id .. " row reopened (requiredLevel)",
            openedLevel == spec.requiredLevel)
        if spec.literalNilFinding then
            check(path.label .. " CONFIRMED FINDING quest " .. id
                .. " literal name \"nil\" reopens as Lua nil", openedName == nil)
        else
            check(path.label .. " quest " .. id .. " name reopens as " .. show(spec.inputName),
                openedName == spec.inputName)
        end
        local openedObjectives = handle.QuerySingle(id, "objectives")
        local objectiveOk, objectiveWhy = objectivesMatch(openedObjectives, spec)
        if not objectiveOk then
            print("OBSERVED objective mismatch " .. path.label .. " quest " .. id .. ": " .. tostring(objectiveWhy))
            print("OBSERVED objectives " .. dump(openedObjectives))
        end
        check(path.label .. " quest " .. id .. " " .. spec.kind .. " objectives x" .. spec.count
            .. " reopen in order with text " .. show(spec.text), objectiveOk)
        local forward = handle.Query(id, {"objectives", "reputationReward", "questLevel", "extraObjectives"})
        local reverse = handle.Query(id, {"extraObjectives", "questLevel", "reputationReward", "objectives"})
        check(path.label .. " quest " .. id .. " neighbour query is not sequential leftover state",
            type(forward) == "table" and type(reverse) == "table")
        local forwardOk = objectivesMatch(forward[1], spec) and repMatch(forward[2], spec)
            and forward[3] == spec.questLevel
        local reverseOk = objectivesMatch(reverse[4], spec) and repMatch(reverse[3], spec)
            and reverse[2] == spec.questLevel
        if id == probeId then
            forwardOk = forwardOk and type(forward[4]) == "table" and forward[4][1][3] == probeExtraText
            reverseOk = reverseOk and type(reverse[1]) == "table" and reverse[1][1][3] == probeExtraText
        else
            forwardOk = forwardOk and forward[4] == nil
            reverseOk = reverseOk and reverse[1] == nil
        end
        check(path.label .. " quest " .. id .. " field after variable objectives is reputation "
            .. spec.rep[1] .. "," .. spec.rep[2], forwardOk and reverseOk)
        check(path.label .. " quest " .. id .. " QuerySingle reputation matches",
            repMatch(handle.QuerySingle(id, "reputationReward"), spec))
        check(path.label .. " quest " .. id .. " static questFlags direct-skip",
            handle.QuerySingle(id, "questFlags") == spec.flags)
        local validated = handle.QueryValidator(id, order)
        check(path.label .. " quest " .. id .. " QueryValidator skipper/reader walk",
            type(validated) == "table" and validated[seenOrder.requiredLevel] == spec.requiredLevel
            and validated[seenOrder.questLevel] == spec.questLevel
            and validated[seenOrder.name] == openedName
            and validated[seenOrder.questFlags] == spec.flags)
    end
    local probeRow = handle.Query(probeId, {
        "preQuestSingle", "requiredSkill", "startedBy", "finishedBy", "objectivesText",
    })
    check(path.label .. " order probe list and giver fields reopen",
        type(probeRow) == "table"
        and probeRow[1][1] == 920282 and probeRow[1][2] == 920283
        and probeRow[2][1] == 11 and probeRow[2][2] == 22
        and probeRow[3][1][1] == 7711 and probeRow[3][1][2] == 7713 and probeRow[3][2] == nil
        and probeRow[4][1][1] == 7712 and probeRow[4][2] == nil
        and probeRow[5][1] == "Synthetic order probe text")
end

print("NAME REOPEN REPORT")
for i = 1, #nameReport do print("OBSERVED " .. nameReport[i]) end
print("FINDING literal quest name \"nil\" (id 920242) reopens as Lua nil on every path above.")
print("FINDING ordinary control name (id 920241) reopens unchanged.")
print("FINDING Lua nil name (id 920243) is normalised to Lua nil. That part is the existing u8string sentinel, distinct from the literal-string collision.")
print("RECOMMENDATION not applied: a separate fail-closed loader check q.name ~= \"nil\", plus a negative loader test. Loader and compiler were not modified.")
print("NOT_TESTED mixed-kind objectives are not in the fixture and acceptance was not asserted.")
print("NOT_TESTED zoneOrSort=-32768 and questLevel=-32768 were excluded from this fixture.")
print("NOT_TESTED quest 2001 was not compiled here; the loader suite still owns that record.")
print("NOT_TESTED loader acceptance of the literal name \"nil\" was not invoked by this harness.")
print("NOT_TESTED full client, SavedVariables, real quest database, packaging, release.")
print("ALL " .. checks .. " SYNTHETIC FULLTABLE COMPILER CHECKS PASS; client/SavedVariables/real-DB NOT TESTED.")
print("FULLTABLE_SUMMARY checks=" .. checks .. " quests=" .. questCount
    .. " literal_nil_name=Lua nil control_name=\"Synthetic control name\""
    .. " field_order_matches_indexed=true yields_debug=" .. yieldsDebug
    .. " yields_stepped=" .. yieldsStepped)
