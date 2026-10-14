-- N-Questie M0: effective Questie database validation for WoW 3.3.5a.
--
-- Loads the public WotLK Questie database through Questie-335.toc as a
-- 3.3.5a client (build 12340, interface 30300), runs the real
-- QuestieCorrections:Initialize() including QuestieCompat.LoadCorrections
-- and the N-Questie correction callbacks, then compiles the database.
--
-- It asserts the approved N-Questie corrections and checks that no other
-- quest/npc/object/item record field changed while the N-Questie callbacks
-- ran. Exit code 0 = all checks passed, 1 = any failure.
--
-- Usage (repository root):  lua5.1 cli/validate-335.lua
-- Optional environment:
--   NQ_VALIDATE_FIXTURE=<file>  synthetic fault injection (tests/fixtures/validate335)
--   NQ_VALIDATE_SKIP_COMPILE=1  stop after the correction checks (faster)
-- No private server data is read. Nothing is written to disk.
require("cli.dump")

WOW_PROJECT_ID = 11
WOW_PROJECT_CLASSIC = 2
WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5
WOW_PROJECT_WRATH_CLASSIC = 11
WOW_PROJECT_MAINLINE = 1

QUEST_MONSTERS_KILLED = "QUEST_MONSTERS_KILLED"
QUEST_ITEMS_NEEDED = "QUEST_ITEMS_NEEDED"
QUEST_OBJECTS_FOUND = "QUEST_OBJECTS_FOUND"
ERR_QUEST_ACCEPTED_S = "ERR_QUEST_ACCEPTED_S"
ERR_QUEST_COMPLETE_S = "ERR_QUEST_COMPLETE_S"

tremove = table.remove
tinsert = table.insert

local _EmptyDummyFunction = function() end
local _TableDummyFunction = function() return {} end

coroutine.yield = _EmptyDummyFunction -- no need to yield in the cli (TODO: maybe find a less hacky fix)
mod = function(a, b)
    return a % b
end
bit = require("bit32")
hooksecurefunc = _EmptyDummyFunction
GetBuildInfo = function()
    return "3.3.5", "12340", "Jun 24 2010", 30300
end
GetAddOnInfo = function()
    return "Questie", "|cFFFFFFFFQuestie|r|cFF00FF00 v6.3.9 (TBC B2)|r", "A standalone Classic QuestHelper", true, "INSECURE", false
end
-- Values mirror Questie-335.toc so the 3.3.5a code paths are selected.
GetAddOnMetadata = function(_, field)
    if field == "X-WOW_PROJECT_ID" then return "11" end
    return "9.5.1.1"
end
GetTime = function()
    return os.time(os.date("!*t")) - 1616930000 -- convert unix time to wow time (actually accurate)
end
IsAddOnLoaded = function() return false, true end
UnitFactionGroup = function()
    return arg[1] or "Horde"
end
UnitClass = function()
    return "Druid", "DRUID", 11
end
UnitLevel = function()
    return 60
end
GetLocale = function()
    return "enUS"
end
GetQuestGreenRange = function()
    return 10
end
UnitName = function()
    return "QuestieNPC"
end
LibStub = {
    NewLibrary = _EmptyDummyFunction,
    GetLibrary = _TableDummyFunction,
}
setmetatable(LibStub, { __call = function(_, ...)
    return {NewAddon = _TableDummyFunction, New = _TableDummyFunction }
end})
StaticPopupDialogs = {}

CreateFrame = function()
    return {
        Show = _EmptyDummyFunction,
        SetScript = _EmptyDummyFunction,
        RegisterEvent = _EmptyDummyFunction,
    }
end
C_QuestLog = {}
C_Timer = {
    After = function(_, f)
        f()
    end,
    NewTicker = function(_, f, times)
        if times then
            for _=1,times do
                f()
            end
        else
            -- hack
            local finished = false
            QuestieLoader:ImportModule("DBCompiler").ticker = {
                Cancel = function()
                    finished = true
                end
            }
            while not finished do
                f()
            end
        end
    end
}
C_Seasons = {
    HasActiveSeason = function() return false end,
}

ItemRefTooltip = {
    SetHyperlink = _EmptyDummyFunction,
    IsShown = _EmptyDummyFunction,
    SetOwner = _EmptyDummyFunction,
    Show = _EmptyDummyFunction,
    Hide = _EmptyDummyFunction,
    AddLine = _EmptyDummyFunction,
    HookScript = _EmptyDummyFunction,
}

C_Map = {}

-- WoW addon namespace
local addonName = "Questie"
local addonTable = {}


local function print(text)
    io.stderr:write(tostring(text) .. "\n")
end

-------------------------------------------------------------------------------
-- Expectations (public, curated values from PR #2, #6 and #7)
-------------------------------------------------------------------------------
local QK = { name = 1, startedBy = 2, finishedBy = 3, requiredLevel = 4, questLevel = 5,
             requiredRaces = 6, objectivesText = 8, objectives = 10, preQuestGroup = 12,
             preQuestSingle = 13, exclusiveTo = 16, zoneOrSort = 17, questFlags = 23 }

-- questId = {before requiredLevel, before questLevel, after requiredLevel, after questLevel}
local DUSTWALLOW = {
    [1166] = {37, 41, 38, 43},
    [1168] = {37, 41, 38, 43},
    [1169] = {37, 41, 38, 43},
    [1170] = {37, 41, 38, 43},
    [1171] = {37, 41, 38, 43},
    [1172] = {37, 41, 38, 45},
    [1205] = {35, 41, 35, 45},
    [1252] = {30, 35, 30, 40},
}

-- Allow-list of (database, id, field) that the N-Questie callbacks may change.
-- field "*" = whole record may be new (custom quest).
local ALLOWED = {
    questData = { [2001] = "*", [1203] = { [QK.objectivesText] = true, [QK.objectives] = true } },
    npcData = { [2121] = { [10] = true, [11] = true } }, -- questStarts / questEnds
    objectData = {},
    itemData = {},
}
for id, v in pairs(DUSTWALLOW) do
    local f = { [QK.questLevel] = true }
    if v[1] ~= v[3] then f[QK.requiredLevel] = true end
    ALLOWED.questData[id] = f
end

-------------------------------------------------------------------------------
-- Deterministic serialisation and hash (Lua 5.1, no bit library needed)
-------------------------------------------------------------------------------
local function sortKeys(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return ta < tb end
    if ta == "number" or ta == "string" then return a < b end
    return tostring(a) < tostring(b)
end

local function serialize(v, out)
    local t = type(v)
    if t == "table" then
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys, sortKeys)
        out[#out + 1] = "{"
        for i = 1, #keys do
            local k = keys[i]
            out[#out + 1] = (type(k) == "number" and string.format("%.17g", k) or ("s" .. tostring(k))) .. "="
            serialize(v[k], out)
            out[#out + 1] = ","
        end
        out[#out + 1] = "}"
    elseif t == "number" then
        out[#out + 1] = string.format("%.17g", v)
    elseif t == "string" then
        out[#out + 1] = string.format("%q", v)
    else
        out[#out + 1] = tostring(v)
    end
end

local function ser(v)
    local out = {}
    serialize(v, out)
    return table.concat(out)
end

-- 32-bit polynomial rolling hash over a string, exact in Lua 5.1 doubles.
local function hashString(s, h)
    h = h or 5381
    local byte = string.byte
    for i = 1, #s, 64 do
        local chunk = { byte(s, i, i + 63) }
        for j = 1, #chunk do
            h = (h * 33 + chunk[j]) % 4294967296
        end
    end
    return h
end

-- Snapshot: id -> field -> serialised value
local function snapshot(db)
    local snap = {}
    for id, record in pairs(db) do
        local fields = {}
        if type(record) == "table" then
            for field, value in pairs(record) do fields[field] = ser(value) end
        else
            fields["<non-table>"] = ser(record)
        end
        snap[id] = fields
    end
    return snap
end

local function digest(snap)
    local ids = {}
    for id in pairs(snap) do ids[#ids + 1] = id end
    table.sort(ids, sortKeys)
    local h = 5381
    for _, id in ipairs(ids) do
        local fields, fkeys = snap[id], {}
        for f in pairs(fields) do fkeys[#fkeys + 1] = f end
        table.sort(fkeys, sortKeys)
        h = hashString(tostring(id), h)
        for _, f in ipairs(fkeys) do
            h = hashString(tostring(f) .. "=" .. fields[f], h)
        end
    end
    return string.format("%08x", h), #ids
end

-------------------------------------------------------------------------------
-- Result tracking
-------------------------------------------------------------------------------
local failures, passes = {}, 0
local function check(cond, message)
    if cond then
        passes = passes + 1
    else
        failures[#failures + 1] = message
        print("\27[31mFAIL\27[0m " .. message)
    end
end

-------------------------------------------------------------------------------
-- TOC loader (Questie-335.toc), with QuestieCompat registry from Compat.lua
-------------------------------------------------------------------------------
local currentFile
local snapshots = { before = {}, after = {} }
local nqCallbacks = 0

-- Load the correction/blacklist registry section of Compat/Compat.lua verbatim.
-- The full Compat.lua needs a live client UI; only this section is needed.
local function loadCompatRegistry()
    local f = assert(io.open("Compat/Compat.lua", "r"))
    local src = f:read("*a")
    f:close()
    local s = src:find("local correctionsRegistry = {}", 1, true)
    local e = src:find("function QuestieCompat:ADDON_LOADED", 1, true)
    assert(s and e and e > s, "could not locate the correction registry in Compat/Compat.lua")
    local chunk = 'local QuestieDB = QuestieLoader:ImportModule("QuestieDB")\n' ..
                  'local QuestieCorrections = QuestieLoader:ImportModule("QuestieCorrections")\n' ..
                  src:sub(s, e - 1)
    assert(loadstring(chunk, "=Compat/Compat.lua (registry section)"))()

    -- Instrument registrations made by N-Questie files: snapshot each database
    -- immediately before the first N-Questie callback for it runs.
    local register = QuestieCompat.RegisterCorrection
    QuestieCompat.RegisterCorrection = function(dbName, callback)
        if currentFile and currentFile:find("^Compat/NQuestie") then
            nqCallbacks = nqCallbacks + 1
            local wrapped = function()
                local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
                -- objectData/itemData have no N-Questie callbacks; snapshot them
                -- at the first N-Questie callback so direct writes are caught.
                for _, other in ipairs({ "objectData", "itemData" }) do
                    if not snapshots.before[other] and type(QuestieDB[other]) == "table" then
                        snapshots.before[other] = snapshot(QuestieDB[other])
                    end
                end
                if not snapshots.before[dbName] then
                    snapshots.before[dbName] = snapshot(QuestieDB[dbName])
                    if dbName == "questData" and type(QuestieDB.questData[1203]) == "table" then
                        snapshots.orig1203Objectives = QuestieDB.questData[1203][QK.objectives]
                        snapshots.orig1203ObjectivesSer = ser(snapshots.orig1203Objectives)
                    end
                end
                local result = callback()
                if type(result) ~= "table" then
                    check(false, "N-Questie " .. dbName .. " correction returned " .. type(result) .. ", expected table")
                    return {}
                end
                return result
            end
            return register(dbName, wrapped)
        end
        return register(dbName, callback)
    end
end

local loadErrors = {}
local function loadTOC(file)
    local rfile = assert(io.open(file, "r"))
    for line in rfile:lines() do
        if string.len(line) > 1 and string.byte(line, 1) ~= 35 and (not string.find(line, ".xml")) then
            line = line:gsub("\\", "/"):gsub("%s+", "")
            currentFile = line
            local chunk, loadErr = loadfile(line)
            local ok, err = false, loadErr
            if chunk then ok, err = pcall(chunk, "Questie", {}) end
            if not ok then loadErrors[line] = tostring(err) end
            if line == "Modules/QuestieCompat.lua" then
                loadCompatRegistry()
                currentFile = "Compat/Corrections.lua"
                local cok, cerr = pcall(dofile, "Compat/Corrections.lua")
                if not cok then loadErrors["Compat/Corrections.lua"] = tostring(cerr) end
            end
        end
    end
    rfile:close()
    currentFile = nil
end

-------------------------------------------------------------------------------
-- Main
-------------------------------------------------------------------------------
local function run()
    print("\27[36m[validate-335] Loading Questie-335.toc as a 3.3.5a client\27[0m")
    loadTOC("Questie-335.toc")

    -- Files that cannot load headless (UI frames) are expected; anything in
    -- Database/, Compat/ or the core loader failing is a hard error.
    for file, err in pairs(loadErrors) do
        local critical = file:find("^Database/") or file:find("^Compat/") or
                         file == "Modules/QuestieInit.lua" or file == "Modules/QuestieCompat.lua"
        if critical then check(false, "load error in " .. file .. ": " .. err)
        else print("note: headless load skipped " .. file .. " (" .. err:sub(1, 80) .. ")") end
    end

    check(QuestieCompat.Is335 == true, "QuestieCompat.Is335 must be true (build 30300)")
    check(Questie.IsWotlk == true, "Questie.IsWotlk must be true for Questie-335.toc")
    check(nqCallbacks >= 4, "expected at least 4 N-Questie correction registrations, got " .. nqCallbacks)

    Questie.Debug = function() end
    Questie.Error = function(_, text) io.stderr:write(tostring(text) .. "\n") end
    Questie.Warning = Questie.Error
    Questie.db = { char = { showEventQuests = false }, global = {}, profile = {} }
    QuestieConfig = {}

    local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
    local QuestieCorrections = QuestieLoader:ImportModule("QuestieCorrections")

    QuestieDB.npcData = loadstring(QuestieDB.npcData)()
    QuestieDB.objectData = loadstring(QuestieDB.objectData)()
    QuestieDB.questData = loadstring(QuestieDB.questData)()
    QuestieDB.itemData = loadstring(QuestieDB.itemData)()

    for name, key in pairs(QK) do
        check(QuestieDB.questKeys[name] == key, "questKeys." .. name .. " expected " .. key)
    end

    local fixture = os.getenv("NQ_VALIDATE_FIXTURE")
    if fixture and fixture ~= "" then
        print("\27[33m[validate-335] Applying synthetic fixture " .. fixture .. "\27[0m")
        local ctx = { QuestieDB = QuestieDB, QK = QK }
        -- Register a callback that the harness treats as an N-Questie file.
        ctx.registerNQuestie = function(dbName, callback)
            currentFile = "Compat/NQuestieSyntheticFixture.lua"
            QuestieCompat.RegisterCorrection(dbName, callback)
            currentFile = nil
        end
        assert(loadfile(fixture))(ctx)
    end

    Questie:SetIcons()
    QuestieLoader:ImportModule("ZoneDB"):Initialize()

    -- Take the "after" snapshot as soon as QuestieCompat.LoadCorrections returns,
    -- before the inherited faction inference that follows it in Initialize().
    local loadCorrections = QuestieCompat.LoadCorrections
    QuestieCompat.LoadCorrections = function(...)
        loadCorrections(...)
        for dbName in pairs(snapshots.before) do
            snapshots.after[dbName] = snapshot(QuestieDB[dbName])
        end
    end

    local t0 = os.clock()
    QuestieCorrections:Initialize()
    print(string.format("[validate-335] Corrections applied in %.1fs", os.clock() - t0))

    ---------------------------------------------------------------------------
    -- Unrelated-data preservation
    ---------------------------------------------------------------------------
    check(snapshots.before.questData ~= nil, "N-Questie questData corrections never ran")
    for _, dbName in ipairs({ "questData", "npcData", "objectData", "itemData" }) do
        local before, after = snapshots.before[dbName], snapshots.after[dbName]
        if before and after then
            local allowed, unexpected = ALLOWED[dbName], 0
            local seen = {}
            for id, afterFields in pairs(after) do
                seen[id] = true
                local beforeFields = before[id]
                local rule = allowed[id]
                if not beforeFields then
                    if rule ~= "*" then
                        unexpected = unexpected + 1
                        check(false, dbName .. " " .. tostring(id) .. ": new record not allow-listed")
                    end
                elseif rule ~= "*" then
                    local fields = {}
                    for f in pairs(afterFields) do fields[f] = true end
                    for f in pairs(beforeFields) do fields[f] = true end
                    for f in pairs(fields) do
                        if beforeFields[f] ~= afterFields[f] and not (rule and rule[f]) then
                            unexpected = unexpected + 1
                            check(false, dbName .. " " .. tostring(id) .. " field " .. tostring(f) .. " changed but is not allow-listed")
                        end
                    end
                end
            end
            for id in pairs(before) do
                if not seen[id] then
                    unexpected = unexpected + 1
                    check(false, dbName .. " " .. tostring(id) .. ": record removed")
                end
            end
            local hb, n = digest(before)
            local ha = digest(after)
            print(string.format("[validate-335] %-10s records=%d before=%s after=%s unexpected=%d", dbName, n, hb, ha, unexpected))
            check(unexpected == 0, dbName .. ": " .. unexpected .. " unexpected change(s)")
        end
    end

    ---------------------------------------------------------------------------
    -- Quest 2001 (custom quest, PR #2)
    ---------------------------------------------------------------------------
    local before = snapshots.before.questData or {}
    local q = QuestieDB.questData[2001]
    check(before[2001] == nil, "quest 2001 must not exist in the base DB (overlay adds it)")
    check(type(q) == "table", "quest 2001 missing after corrections")
    if type(q) == "table" then
        check(q[QK.name] == "Ravenclaw Cleanup", "2001 name")
        check(q[QK.requiredLevel] == 12 and q[QK.questLevel] == 16, "2001 levels 12/16")
        check(q[QK.zoneOrSort] == 130, "2001 zoneOrSort 130")
        check(q[QK.requiredRaces] == 690, "2001 requiredRaces 690")
        check(q[QK.questFlags] == 8, "2001 questFlags 8")
        check(ser(q[QK.startedBy]) == ser({ { 2121 } }), "2001 startedBy {{2121}}")
        check(ser(q[QK.finishedBy]) == ser({ { 2121 } }), "2001 finishedBy {{2121}}")
        check(ser(q[QK.preQuestSingle]) == ser({ 437 }), "2001 preQuestSingle {437}")
        check(ser(q[QK.objectives]) == ser({ { { 1868 }, { 1869 } } }), "2001 kill objectives 1868/1869")
    end
    local npc = QuestieDB.npcData[2121]
    if type(npc) == "table" then
        local function has(list, v) for _, x in ipairs(list or {}) do if x == v then return true end end return false end
        check(has(npc[10], 2001) and has(npc[11], 2001), "NPC 2121 questStarts/questEnds include 2001")
    else
        check(false, "NPC 2121 missing")
    end

    ---------------------------------------------------------------------------
    -- Quest 1203 (PR #6)
    ---------------------------------------------------------------------------
    local b1203, q1203 = before[1203], QuestieDB.questData[1203]
    check(type(q1203) == "table" and b1203 ~= nil, "quest 1203 present before and after")
    if type(q1203) == "table" and b1203 then
        local obj = q1203[QK.objectives]
        check(type(obj) == "table" and type(obj[3]) == "table" and #obj[3] == 1 and
              type(obj[3][1]) == "table" and obj[3][1][1] == 3853, "1203 item objective is 3853")
        check(type(q1203[QK.objectivesText]) == "table" and
              tostring(q1203[QK.objectivesText][1]):find("Moonsteel Broadsword", 1, true) ~= nil,
              "1203 objective text mentions Moonsteel Broadsword")
        check(q1203[QK.requiredLevel] == 30 and q1203[QK.questLevel] == 35, "1203 levels stay 30/35")
        check(ser(q1203[QK.startedBy]) == ser({ { 4792 } }), "1203 startedBy {{4792}} unchanged")
        check(ser(q1203[QK.preQuestSingle]) == ser({ 1206 }), "1203 preQuestSingle {1206} unchanged")
        check(ser(q1203[QK.exclusiveTo]) == (b1203[QK.exclusiveTo] or "nil"), "1203 exclusiveTo unchanged")
        local orig = snapshots.orig1203Objectives
        check(type(orig) == "table" and ser(orig) == snapshots.orig1203ObjectivesSer,
              "1203 original objectives table was not mutated")
        if type(orig) == "table" and type(obj) == "table" then
            for slot = 1, 6 do
                if slot ~= 3 then
                    check(ser(obj[slot]) == ser(orig[slot]), "1203 objective slot " .. slot .. " intact")
                end
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Eight Dustwallow quests (PR #7), each with its own expected values
    ---------------------------------------------------------------------------
    for id, v in pairs(DUSTWALLOW) do
        local bq, aq = before[id], QuestieDB.questData[id]
        check(bq ~= nil and type(aq) == "table", id .. " present")
        if bq and type(aq) == "table" then
            check(bq[QK.requiredLevel] == ser(v[1]) and bq[QK.questLevel] == ser(v[2]),
                  id .. " base levels " .. v[1] .. "/" .. v[2])
            check(aq[QK.requiredLevel] == v[3], id .. " requiredLevel " .. v[3] .. " (got " .. tostring(aq[QK.requiredLevel]) .. ")")
            check(aq[QK.questLevel] == v[4], id .. " questLevel " .. v[4] .. " (got " .. tostring(aq[QK.questLevel]) .. ")")
        end
    end

    ---------------------------------------------------------------------------
    -- Compile through the real DB compiler and read back compiled values
    ---------------------------------------------------------------------------
    if os.getenv("NQ_VALIDATE_SKIP_COMPILE") ~= "1" and #failures == 0 then
        local QuestieDBCompiler = QuestieLoader:ImportModule("DBCompiler")
        t0 = os.clock()
        QuestieDBCompiler:Compile(function() end)
        QuestieDB:Initialize()
        print(string.format("[validate-335] Compiled in %.1fs", os.clock() - t0))
        local Q = QuestieDB.QueryQuestSingle
        check(Q(1203, "questLevel") == 35 and Q(1203, "requiredLevel") == 30, "compiled 1203 levels 30/35")
        local cobj = Q(1203, "objectives")
        check(type(cobj) == "table" and cobj[3] and cobj[3][1] and cobj[3][1][1] == 3853, "compiled 1203 item 3853")
        check(Q(2001, "name") == "Ravenclaw Cleanup", "compiled 2001 name")
        for id, v in pairs(DUSTWALLOW) do
            check(Q(id, "requiredLevel") == v[3] and Q(id, "questLevel") == v[4],
                  "compiled " .. id .. " levels " .. v[3] .. "/" .. v[4])
        end
    end

    if #failures > 0 then
        print(string.format("\27[31m[validate-335] FAILED: %d failure(s), %d check(s) passed\27[0m", #failures, passes))
        os.exit(1)
    end
    print(string.format("\27[32m[validate-335] PASS: %d checks\27[0m", passes))
end

local ok, err = pcall(run)
if not ok then
    print("\27[31m[validate-335] ERROR: " .. tostring(err) .. "\27[0m")
    os.exit(1)
end
os.exit(0)
