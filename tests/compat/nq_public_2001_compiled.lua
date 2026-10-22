-- Public quest 2001: loader-to-real-compiler synthetic round-trip regression.
-- No user-private world DB, game client, SavedVariables, SQL, or packages.
-- All non-public rows below are invented in-memory stubs.

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

local modules, callbacks = {}, {}
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
QuestieCompat = {
    Is335 = true, WOW_PROJECT_ID = 2,
    RegisterCorrection = function(kind, fn) callbacks[kind] = fn end,
}
Questie = {
    db = {profile = {debugEnabled = true}, global = {}},
    IsSoD = false, IsTBC = false, IsWotlk = true, DEBUG_INFO = "INFO",
    Error = function(_, ...) error("Questie error: " .. tostring((...)), 0) end,
    Warning = function(_, ...) error("Questie warning: " .. tostring((...)), 0) end,
    Debug = function() end,
}

-- The actual Questie schema, stream implementation, custom data and loader
-- are loaded; none of the compiler or stream methods is replaced.
assert(loadfile("Modules/QuestieStream.lua"))()
assert(loadfile("Database/questDB.lua"))()
local db = assert(modules.QuestieDB)
local keys = assert(db.questKeys)

-- Minimal invented DB references required to make the already-public quest
-- 2001 pass the actual loader's reference and prerequisite validation.
db.questData = {
    [437] = {[keys.name] = "Synthetic known prerequisite"},
}
db.npcKeys = {questStarts = 10, questEnds = 11}
db.objectKeys = {questStarts = 2, questEnds = 3}
db.npcData = {
    [2121] = {[1] = "Synthetic public questgiver stub"},
    [1868] = {[1] = "Synthetic objective NPC stub A"},
    [1869] = {[1] = "Synthetic objective NPC stub B"},
}
db.objectData = {}
db.itemData = {}

assert(loadfile("Compat/NQuestieCustomQuestData.lua"))()
local public = assert(NQuestieCustomQuestData.quests[2001],
    "already-public 2001 record missing")
assert(next(NQuestieCustomQuestData.quests, 2001) == nil,
    "unexpected additional quest records: fixture must remain public-only")
assert(public.name == "Ravenclaw Cleanup" and public.zoneOrSort == 130
    and public.questLevel == 16 and public.requiredLevel == 12,
    "canonical public quest 2001 inputs changed")

assert(loadfile("Compat/NQuestieCustomQuestLoader.lua"))()
assert(type(callbacks.questData) == "function"
    and type(callbacks.npcData) == "function"
    and type(callbacks.objectData) == "function",
    "loader callbacks missing")

local checks = 0
local function check(label, value)
    checks = checks + 1
    assert(value, "FAIL public 2001 compiled check " .. checks .. ": " .. label)
    print("PASS public2001 " .. checks .. " " .. label)
end
local npcRelations = callbacks.npcData() -- deliberately invoke before questData
local goRelations = callbacks.objectData()
local updates = callbacks.questData()
local row = updates[2001]
check("public 2001 admitted by actual loader", type(row) == "table")
check("no unapproved quest row inserted", next(updates, 2001) == nil)
check("public NPC starts relation", npcRelations[2121]
    and npcRelations[2121][db.npcKeys.questStarts][1] == 2001)
check("public NPC finishes relation", npcRelations[2121]
    and npcRelations[2121][db.npcKeys.questEnds][1] == 2001)
check("no invented GO source relation", next(goRelations) == nil)

assert(loadfile("Database/compiler.lua"))()
local compiler = assert(modules.DBCompiler)
local types, order = assert(db.questCompilerTypes), assert(db.questCompilerOrder)
local compileInput = {[2001] = row}

local function completeCoroutine(fn)
    local co = coroutine.create(fn)
    for attempt = 1, 10000 do
        local ok, result = coroutine.resume(co)
        if not ok then error(debug.traceback(co, tostring(result)), 0) end
        if coroutine.status(co) == "dead" then return result end
    end
    error("compiler or handle coroutine did not finish", 0)
end

local rawBin, rawPtrs = compiler:CompileTable(compileInput, types, order, keys)
check("actual CompileTable produced binary and pointers",
    type(rawBin) == "string" and #rawBin > 0
    and type(rawPtrs) == "string" and #rawPtrs > 0)

Questie.db.global = {}
Questie.db.profile.debugEnabled = true
completeCoroutine(function()
    compiler:CompileTableCoroutine(compileInput, types, order, keys,
        "quest", "Quest", 1)
end)
local debugBin, debugPtrs =
    Questie.db.global.questBin, Questie.db.global.questPtrs
check("actual debug CompileTableCoroutine produced binary and pointers",
    type(debugBin) == "string" and #debugBin > 0
    and type(debugPtrs) == "string" and #debugPtrs > 0)

local skip = compiler:BuildSkipMap(types, order)
for _, path in ipairs({
    {"CompileTable/raw", rawBin, rawPtrs},
    {"CompileTableCoroutine/raw_assert", debugBin, debugPtrs},
}) do
    local label, binary, pointers = unpack(path)
    local handle = completeCoroutine(function()
        return compiler:GetDBHandle(binary, pointers, skip)
    end)
    check(label .. " reopened public 2001 name",
        handle.QuerySingle(2001, "name") == "Ravenclaw Cleanup")
    check(label .. " reopened requiredLevel 12",
        handle.QuerySingle(2001, "requiredLevel") == 12)
    check(label .. " reopened questLevel 16",
        handle.QuerySingle(2001, "questLevel") == 16)
    check(label .. " reopened zoneOrSort 130",
        handle.QuerySingle(2001, "zoneOrSort") == 130)
    check(label .. " reopened requiredRaces 690",
        handle.QuerySingle(2001, "requiredRaces") == 690)
    check(label .. " reopened questFlags 8",
        handle.QuerySingle(2001, "questFlags") == 8)

    local prerequisite = handle.QuerySingle(2001, "preQuestSingle")
    check(label .. " preserved prerequisite 437",
        type(prerequisite) == "table" and #prerequisite == 1
        and prerequisite[1] == 437)
    local starter = handle.QuerySingle(2001, "startedBy")
    local finisher = handle.QuerySingle(2001, "finishedBy")
    check(label .. " preserved only NPC quest starter 2121",
        type(starter) == "table" and type(starter[1]) == "table"
        and starter[1][1] == 2121 and #starter[1] == 1
        and starter[2] == nil and starter[3] == nil)
    check(label .. " preserved only NPC quest finisher 2121",
        type(finisher) == "table" and type(finisher[1]) == "table"
        and finisher[1][1] == 2121 and #finisher[1] == 1
        and finisher[2] == nil and finisher[3] == nil)
    local objectives = handle.QuerySingle(2001, "objectives")
    check(label .. " preserved kill objective order 1868, 1869",
        type(objectives) == "table" and type(objectives[1]) == "table"
        and #objectives[1] == 2 and objectives[1][1][1] == 1868
        and objectives[1][2][1] == 1869
        and objectives[2] == nil and objectives[3] == nil)
    -- Reverse-order reads must not depend on lingering stream position.
    local reverse = handle.Query(2001, {
        "objectives", "name", "preQuestSingle", "zoneOrSort",
    })
    check(label .. " reversed query preserves adjacent fields",
        type(reverse) == "table" and reverse[2] == "Ravenclaw Cleanup"
        and reverse[3] and reverse[3][1] == 437 and reverse[4] == 130
        and reverse[1] and reverse[1][1][1][1] == 1868)
    check(label .. " no unexpected invented quest row",
        handle.QuerySingle(920299, "name") == nil)
end

print("ALL " .. checks
    .. " PUBLIC 2001 SYNTHETIC LOADER+FULLTABLE CHECKS PASS;"
    .. " client/SavedVariables/real-world-DB NOT TESTED.")
