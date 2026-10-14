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
-- Optional M2.2 effective export (off unless NQ_EXPORT_EFFECTIVE_OUT is set):
--   NQ_EXPORT_EFFECTIVE_OUT=/abs/dir/file.lua  output (outside the checkout or private/)
--   NQ_EXPORT_QUESTS="1203,2001"               explicit quest IDs, or
--   NQ_EXPORT_SELECTION=/abs/input.lua          IDs from a validated nq-m2-input file
--   NQ_EXPORT_FORCE=1                           replace an existing output file
-- Optional M2.2 coverage report (read-only, all quests; not an export):
--   NQ_COVERAGE_MANIFEST_OUT=/abs/private/m.lua per-quest manifest (private paths only)
--   NQ_COVERAGE_AGGREGATE_OUT=/abs/agg.txt      optional aggregate copy (counts only)
-- The export runs only after every M0 check has passed, needs a clean git
-- checkout and NQ_VALIDATE_EXPECT_LEVEL_COUNT, and never changes the checks.
-- No private server data is read. Without the export option nothing is written.
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

-- questId = {before requiredLevel, before questLevel, after requiredLevel, after questLevel, source}
-- Each quest has its own expected values (no shared fixtures).
local LEVEL_CORRECTIONS = {
    -- PR #7: Dustwallow Marsh (Compat/NQuestieReviewedQuestLevelCorrections.lua)
    [1166] = {37, 41, 38, 43, "PR #7"},
    [1168] = {37, 41, 38, 43, "PR #7"},
    [1169] = {37, 41, 38, 43, "PR #7"},
    [1170] = {37, 41, 38, 43, "PR #7"},
    [1171] = {37, 41, 38, 43, "PR #7"},
    [1172] = {37, 41, 38, 45, "PR #7"},
    [1205] = {35, 41, 35, 45, "PR #7"},
    [1252] = {30, 35, 30, 40, "PR #7"},
}
-- PR #8: early-zone quests (Compat/NQuestieReviewedEarlyQuestLevels.lua).
-- Only asserted when that module is part of the TOC being validated.
local EARLY_LEVEL_CORRECTIONS = {
    [98]   = {22, 32, 22, 35, "PR #8"},
    [126]  = {15, 21, 15, 25, "PR #8"},
    [169]  = {11, 26, 15, 26, "PR #8"},
    [180]  = {11, 26, 15, 26, "PR #8"},
    [249]  = {20, 26, 20, 27, "PR #8"},
    [256]  = {9, 22, 17, 22, "PR #8"},
    [304]  = {26, 31, 26, 34, "PR #8"},
    [398]  = {4, 10, 6, 10, "PR #8"},
    [442]  = {10, 20, 10, 24, "PR #8"},
    [895]  = {9, 16, 11, 16, "PR #8"},
    [6284] = {12, 21, 15, 21, "PR #8"},
}
do
    local toc = io.open("Questie-335.toc", "r")
    local text = toc and toc:read("*a") or ""
    if toc then toc:close() end
    if text:find("Compat\\NQuestieReviewedEarlyQuestLevels.lua", 1, true) then
        for id, v in pairs(EARLY_LEVEL_CORRECTIONS) do LEVEL_CORRECTIONS[id] = v end
    end
    -- PR #13: Mor'Ladim (Duskwood) and Nek'rosh (Wetlands) source-reviewed
    -- numeric changes. Keep these independently asserted and field-limited.
    -- The inherited TBC correction for quest 225 is requiredLevel=25.
    local CLASSIC_CHAIN_LEVEL_CORRECTIONS = {
        [225] = {25, 30, 28, 35, "PR #13"},
        [227] = {25, 30, 28, 35, "PR #13"},
        [228] = {25, 30, 28, 35, "PR #13"},
        [229] = {25, 30, 28, 35, "PR #13"},
        [231] = {25, 30, 28, 35, "PR #13"},
        [473] = {23, 26, 23, 28, "PR #13"},
        [464] = {23, 26, 23, 28, "PR #13"},
        [465] = {23, 26, 23, 31, "PR #13"},
        [474] = {23, 26, 23, 32, "PR #13"},
    }
    if text:find("Compat\\NQuestieReviewedClassicChainLevels.lua", 1, true) then
        for id, v in pairs(CLASSIC_CHAIN_LEVEL_CORRECTIONS) do
            assert(LEVEL_CORRECTIONS[id] == nil, "duplicate approved level quest " .. id)
            LEVEL_CORRECTIONS[id] = v
        end
    end
end

-- Allow-list of (database, id, field) that the N-Questie callbacks may change.
-- field "*" = whole record may be new (custom quest).
local ALLOWED = {
    questData = { [2001] = "*", [1203] = { [QK.objectivesText] = true, [QK.objectives] = true } },
    npcData = { [2121] = { [10] = true, [11] = true } }, -- questStarts / questEnds
    objectData = {},
    itemData = {},
}
-- Allow-list only the level fields that actually change.
for id, v in pairs(LEVEL_CORRECTIONS) do
    local f = {}
    if v[1] ~= v[3] then f[QK.requiredLevel] = true end
    if v[2] ~= v[4] then f[QK.questLevel] = true end
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

-- The compiler stores absent ints as 0 and absent lists as {} (or nil).
-- Normalise both sides so only real value differences remain.
local function normalize(v)
    if v == 0 then return nil end
    if type(v) ~= "table" then return v end
    local out, any = {}, false
    for k, x in pairs(v) do
        local n = normalize(x)
        if n ~= nil then out[k] = n; any = true end
    end
    return any and out or nil
end

local COMPILED_KEYS = { "requiredLevel", "questLevel", "preQuestSingle", "preQuestGroup",
                        "exclusiveTo", "nextQuestInChain", "parentQuest", "startedBy", "finishedBy" }

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
local loadedFiles = {}
local function loadTOC(file)
    local rfile = assert(io.open(file, "r"))
    for line in rfile:lines() do
        if string.len(line) > 1 and string.byte(line, 1) ~= 35 and (not string.find(line, ".xml")) then
            line = line:gsub("\\", "/"):gsub("%s+", "")
            currentFile = line
            local chunk, loadErr = loadfile(line)
            local ok, err = false, loadErr
            if chunk then ok, err = pcall(chunk, "Questie", {}) end
            if not ok then loadErrors[line] = tostring(err) else loadedFiles[#loadedFiles + 1] = line end
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
local HARNESS_VERSION = "1.1.0"

-- M2.2 export options. Parsed and checked before M0 runs; nil when off.
local function exportOptions()
    local out = os.getenv("NQ_EXPORT_EFFECTIVE_OUT")
    local ids, sel = os.getenv("NQ_EXPORT_QUESTS"), os.getenv("NQ_EXPORT_SELECTION")
    if (out == nil or out == "") then
        if (ids and ids ~= "") or (sel and sel ~= "") then
            return nil, { "export: NQ_EXPORT_QUESTS/NQ_EXPORT_SELECTION given without NQ_EXPORT_EFFECTIVE_OUT" }
        end
        return false
    end
    local errs = {}
    local Export = dofile("tools/validation/EffectiveExport.lua")
    local root = io.popen("pwd -P"):read("*l")
    if (ids and ids ~= "") == (sel and sel ~= "") then
        errs[#errs + 1] = "export: give exactly one of NQ_EXPORT_QUESTS or NQ_EXPORT_SELECTION"
    end
    if os.getenv("NQ_VALIDATE_FIXTURE") and os.getenv("NQ_VALIDATE_FIXTURE") ~= "" then
        errs[#errs + 1] = "export: not allowed together with NQ_VALIDATE_FIXTURE"
    end
    if os.getenv("NQ_VALIDATE_SKIP_COMPILE") == "1" then
        errs[#errs + 1] = "export: needs the compiled database (unset NQ_VALIDATE_SKIP_COMPILE)"
    end
    if not tonumber(os.getenv("NQ_VALIDATE_EXPECT_LEVEL_COUNT") or "") then
        errs[#errs + 1] = "export: NQ_VALIDATE_EXPECT_LEVEL_COUNT must be set so the correction count is asserted"
    end
    local list
    if ids and ids ~= "" then
        local e; list, e = Export.ParseIdList(ids)
        for _, x in ipairs(e or {}) do errs[#errs + 1] = "export: " .. x end
    elseif sel and sel ~= "" then
        local Input = dofile("tools/validation/InputSchema.lua")
        local doc, e = Input.LoadFile(sel, root)
        if not doc then
            for _, x in ipairs(e) do errs[#errs + 1] = "export: selection file: " .. x end
        else
            list = {}
            for _, r in ipairs(doc.quests) do list[#list + 1] = r.ID end
        end
    end
    if list then
        local _, e = Export.CheckSelection(list)
        for _, x in ipairs(e or {}) do errs[#errs + 1] = "export: " .. x end
    end
    local Writer = dofile("tools/validation/SafeWrite.lua")
    local dest, why = Writer.CheckDestination(out, root)
    if not dest then errs[#errs + 1] = "export: " .. why end
    if #errs > 0 then return nil, errs end
    return { out = out, ids = list, root = root, force = os.getenv("NQ_EXPORT_FORCE") == "1" }
end

-- Runtime facts the exporter needs besides the compiled records. Fail closed:
-- without the killCreditObjectiveFirst set, order loss could go unnoticed.
local function exportContext()
    local QC = QuestieLoader:ImportModule("QuestieCorrections")
    local kcf = QC and QC.killCreditObjectiveFirst
    if type(kcf) ~= "table" or next(kcf) == nil then
        return nil, "export: QuestieCorrections.killCreditObjectiveFirst missing or empty; refusing (order check impossible)"
    end
    return { killCreditFirst = kcf }
end

-- M2.2 coverage / preflight options (read-only report over ALL compiled
-- quests; never an export). Checked before M0; nil on error, false when off.
local function coverageOptions()
    local man, agg = os.getenv("NQ_COVERAGE_MANIFEST_OUT"), os.getenv("NQ_COVERAGE_AGGREGATE_OUT")
    if man == nil or man == "" then
        if agg and agg ~= "" then return nil, { "coverage: NQ_COVERAGE_AGGREGATE_OUT given without NQ_COVERAGE_MANIFEST_OUT" } end
        return false
    end
    local errs = {}
    local root = io.popen("pwd -P"):read("*l")
    if os.getenv("NQ_EXPORT_EFFECTIVE_OUT") and os.getenv("NQ_EXPORT_EFFECTIVE_OUT") ~= "" then
        errs[#errs + 1] = "coverage: not allowed together with an effective export"
    end
    if os.getenv("NQ_VALIDATE_FIXTURE") and os.getenv("NQ_VALIDATE_FIXTURE") ~= "" then
        errs[#errs + 1] = "coverage: not allowed together with NQ_VALIDATE_FIXTURE"
    end
    if os.getenv("NQ_VALIDATE_SKIP_COMPILE") == "1" then
        errs[#errs + 1] = "coverage: needs the compiled database (unset NQ_VALIDATE_SKIP_COMPILE)"
    end
    if not tonumber(os.getenv("NQ_VALIDATE_EXPECT_LEVEL_COUNT") or "") then
        errs[#errs + 1] = "coverage: NQ_VALIDATE_EXPECT_LEVEL_COUNT must be set"
    end
    local Writer = dofile("tools/validation/SafeWrite.lua")
    -- The per-quest manifest must be private: inside the checkout only under
    -- private/ (SafeWrite also allows paths outside the checkout).
    local d, why = Writer.CheckDestination(man, root)
    if not d then errs[#errs + 1] = "coverage: manifest: " .. why end
    if agg and agg ~= "" then
        local d2, why2 = Writer.CheckDestination(agg, root)
        if not d2 then errs[#errs + 1] = "coverage: aggregate: " .. why2 end
        if agg == man then errs[#errs + 1] = "coverage: manifest and aggregate paths must differ" end
    end
    if #errs > 0 then return nil, errs end
    return { manifest = man, aggregate = (agg ~= "" and agg) or nil, root = root,
             force = os.getenv("NQ_EXPORT_FORCE") == "1" }
end

-- Runs after every M0 check passed. Returns true, summary or false, errors.
local function runCoverage(opts, QuestieDB, Q, levelCount)
    local Export = dofile("tools/validation/EffectiveExport.lua")
    local Coverage = dofile("tools/validation/Coverage.lua")
    local Prov = dofile("tools/validation/ExportProvenance.lua")
    local Writer = dofile("tools/validation/SafeWrite.lua")
    local ids = {}
    for id in pairs(QuestieDB.QuestPointers) do ids[#ids + 1] = id end
    local ctx, cerr = exportContext()
    if not ctx then return false, { cerr } end
    local results = Coverage.Run(Export, Q, ids, ctx)
    local agg = Coverage.Aggregate(results)
    local modules = {}
    for _, f in ipairs(loadedFiles) do
        if f:find("^Compat/NQuestie") then modules[#modules + 1] = f end
    end
    local tocInterface
    for l in io.lines("Questie-335.toc") do
        local v = l:match("^##%s*Interface:%s*(%d+)")
        if v then tocInterface = tonumber(v) end
    end
    local _, _, _, build = GetBuildInfo()
    local nq = rawget(_G, "NQuestieCustomQuestData")
    local prov, perr = Prov.Collect(opts.root, modules, {
        revision = type(nq) == "table" and nq.revision or nil,
        correctionCount = levelCount,
        expectedCorrectionCount = tonumber(os.getenv("NQ_VALIDATE_EXPECT_LEVEL_COUNT") or ""),
        m0Checks = passes, tocInterface = tocInterface, buildInterface = build,
        harnessVersion = HARNESS_VERSION,
    })
    if not prov then return false, perr end
    local text = Coverage.FormatAggregate(agg, Export)
    io.write(text)
    local manifest = Export.Serialize(Coverage.Manifest(results, agg, prov),
        "N-Questie M2.2 COVERAGE MANIFEST (per quest). Not an export. Keep private.")
    local ok, where = Writer.WriteFile(opts.manifest, manifest, { repoRoot = opts.root, force = opts.force })
    if not ok then return false, { "coverage: manifest: " .. where } end
    if opts.aggregate then
        local ok2, w2 = Writer.WriteFile(opts.aggregate, text, { repoRoot = opts.root, force = opts.force })
        if not ok2 then return false, { "coverage: aggregate: " .. w2 } end
    end
    return true, where
end

-- Runs after every M0 check passed. Returns true or false, errors.
local function runExport(opts, QuestieDB, Q, levelCount)
    local Export = dofile("tools/validation/EffectiveExport.lua")
    local Schema = dofile("tools/validation/EffectiveSchema.lua")
    local Prov = dofile("tools/validation/ExportProvenance.lua")
    local Writer = dofile("tools/validation/SafeWrite.lua")
    local exists = function(id) return QuestieDB.QuestPointers[id] ~= nil end
    local KEYS = { "requiredLevel", "questLevel", "objectives", "sourceItemId", "requiredSourceItems", "triggerEnd", "extraObjectives" }
    local function rawState()
        local t = {}
        for _, id in ipairs(opts.ids) do
            if exists(id) then for _, k in ipairs(KEYS) do t[#t + 1] = ser(normalize(Q(id, k))) end end
        end
        return table.concat(t, "\1")
    end
    local beforeState = rawState()
    local ctx, cerr = exportContext()
    if not ctx then return false, { cerr } end
    local records, errs = Export.Snapshot(Q, exists, opts.ids, ctx)
    if not records then return false, errs end
    if rawState() ~= beforeState then return false, { "export: compiled records changed during the snapshot" } end

    local modules = {}
    for _, f in ipairs(loadedFiles) do
        if f:find("^Compat/NQuestie") then modules[#modules + 1] = f end
    end
    local tocInterface
    for l in io.lines("Questie-335.toc") do
        local v = l:match("^##%s*Interface:%s*(%d+)")
        if v then tocInterface = tonumber(v) end
    end
    local _, _, _, build = GetBuildInfo()
    local nq = rawget(_G, "NQuestieCustomQuestData")
    local prov, perr = Prov.Collect(opts.root, modules, {
        revision = type(nq) == "table" and nq.revision or nil,
        correctionCount = levelCount,
        expectedCorrectionCount = tonumber(os.getenv("NQ_VALIDATE_EXPECT_LEVEL_COUNT") or ""),
        m0Checks = passes, tocInterface = tocInterface, buildInterface = build,
        harnessVersion = HARNESS_VERSION,
    })
    if not prov then return false, perr end
    prov.questCount = #records
    local doc = Export.BuildDocument(records, prov)
    local ok, verr = Schema.Validate(doc, { expectKind = "effective", expectCorrectionCount = levelCount })
    if not ok then return false, verr end
    local text = Export.Serialize(doc, "N-Questie effective Questie records (nq-m2-effective v1). Generated by\n" ..
        "cli/validate-335.lua after all M0 checks passed. Public Questie data only.")
    local parsed = Schema.ParseString(text)
    if not parsed or not Schema.Validate(parsed) then return false, { "export: serialised output failed to re-parse" } end
    local wok, where = Writer.WriteFile(opts.out, text, { repoRoot = opts.root, force = opts.force })
    if not wok then return false, { "export: " .. where } end
    local back, berr = Schema.LoadFile(where, opts.root, { expectKind = "effective", expectCorrectionCount = levelCount })
    if not back then return false, berr end
    return true, where
end

local function run()
    local exportOpts, exportErr = exportOptions()
    if exportOpts == nil then
        for _, e in ipairs(exportErr) do print("\27[31m" .. e .. "\27[0m") end
        print("\27[31m[validate-335] export refused before validation; nothing written\27[0m")
        os.exit(1)
    end
    local coverageOpts, coverageErr = coverageOptions()
    if coverageOpts == nil then
        for _, e in ipairs(coverageErr) do print("\27[31m" .. e .. "\27[0m") end
        print("\27[31m[validate-335] coverage refused before validation; nothing written\27[0m")
        os.exit(1)
    end
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
    check(nqCallbacks >= 6, "expected at least 6 N-Questie correction registrations (2001, 1203, 8+11+9 levels), got " .. nqCallbacks)

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
            if dbName == "questData" then
                -- Informational (not an extra check): exact quest ID changes made by
                -- the N-Questie callbacks. Inherited Questie corrections that run
                -- earlier are part of the "before" set.
                local added, removed = {}, {}
                for id in pairs(after) do if not before[id] then added[#added + 1] = tostring(id) end end
                for id in pairs(before) do if not after[id] then removed[#removed + 1] = tostring(id) end end
                table.sort(added); table.sort(removed)
                print(string.format("[validate-335] questData IDs added by N-Questie: %s; removed: %s",
                    #added > 0 and table.concat(added, ",") or "none", #removed > 0 and table.concat(removed, ",") or "none"))
            end
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
    -- M1 objective rules on the real effective records for quest 1203.
    -- The server-shaped row is synthetic, built from the public facts in
    -- docs/REVIEW-2026-10-14.md (one Moonsteel Broadsword, item 3853).
    ---------------------------------------------------------------------------
    do
        local Rules = dofile("tools/validation/ObjectiveRules.lua")
        local row = Rules.FromQuestTemplateRow({ ID = 1203, RequiredItemId1 = 3853, RequiredItemCount1 = 1 })
        local stock = { [QK.objectives] = snapshots.orig1203Objectives }
        local stockClass = Rules.Worst(Rules.Compare(row, stock))
        local effectiveClass = Rules.Worst(Rules.Compare(row, QuestieDB.questData[1203]))
        print("[validate-335] M1 rules on quest 1203: stock Questie = " .. stockClass .. ", effective N-Questie = " .. effectiveClass)
        check(stockClass == "CONFIRMED_MISMATCH", "M1: stock Questie 1203 must classify as CONFIRMED_MISMATCH (got " .. stockClass .. ")")
        check(effectiveClass == "EXPECTED_REPRESENTATION_DIFF",
              "M1: corrected 1203 must classify as EXPECTED_REPRESENTATION_DIFF only (got " .. effectiveClass .. ")")
    end

    ---------------------------------------------------------------------------
    -- Reviewed level corrections (PR #7 Dustwallow, #8 early zones,
    -- PR #13 Classic chain quests),
    -- each with its own expected values. Unchanged fields must stay equal.
    ---------------------------------------------------------------------------
    local levelCount = 0
    for id, v in pairs(LEVEL_CORRECTIONS) do
        levelCount = levelCount + 1
        local tag = v[5] .. " quest " .. id
        local bq, aq = before[id], QuestieDB.questData[id]
        check(bq ~= nil and type(aq) == "table", tag .. " present")
        if bq and type(aq) == "table" then
            check(bq[QK.requiredLevel] == ser(v[1]) and bq[QK.questLevel] == ser(v[2]),
                  tag .. " original levels " .. v[1] .. "/" .. v[2] .. " (got " ..
                  tostring(bq[QK.requiredLevel]) .. "/" .. tostring(bq[QK.questLevel]) .. ")")
            check(aq[QK.requiredLevel] == v[3], tag .. " requiredLevel " .. v[3] .. " (got " .. tostring(aq[QK.requiredLevel]) .. ")")
            check(aq[QK.questLevel] == v[4], tag .. " questLevel " .. v[4] .. " (got " .. tostring(aq[QK.questLevel]) .. ")")
            if v[1] == v[3] then
                check(ser(aq[QK.requiredLevel]) == bq[QK.requiredLevel], tag .. " requiredLevel must stay unchanged")
            end
            if v[2] == v[4] then
                check(ser(aq[QK.questLevel]) == bq[QK.questLevel], tag .. " questLevel must stay unchanged")
            end
        end
    end
    print("[validate-335] level corrections asserted: " .. levelCount)
    local expectedCount = tonumber(os.getenv("NQ_VALIDATE_EXPECT_LEVEL_COUNT") or "")
    if expectedCount then
        check(levelCount == expectedCount, "expected " .. expectedCount .. " level corrections, found " .. levelCount)
    end

    ---------------------------------------------------------------------------
    -- Compile through the real DB compiler and read back compiled values
    ---------------------------------------------------------------------------
    if os.getenv("NQ_VALIDATE_SKIP_COMPILE") ~= "1" and #failures == 0 then
        -- Baseline for the compiled round trip: the source table exactly as
        -- handed to the compiler (after the full Initialize() pipeline,
        -- including inherited post-correction steps such as faction inference).
        local norm = {}
        for id, record in pairs(QuestieDB.questData) do
            local fields = {}
            for _, key in ipairs(COMPILED_KEYS) do
                fields[key] = ser(normalize(record[QuestieDB.questKeys[key]]))
            end
            norm[id] = fields
        end
        snapshots.afterNormalized = norm
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
        for id, v in pairs(LEVEL_CORRECTIONS) do
            check(Q(id, "requiredLevel") == v[3] and Q(id, "questLevel") == v[4],
                  "compiled " .. id .. " levels " .. v[3] .. "/" .. v[4])
        end
        -- Compiled round trip for every quest: levels and prerequisite /
        -- chain fields must equal the post-correction source table.
        -- Runtime overrides (QuestieDB.questDataOverrides) are applied on top of
        -- the compiled data by the query handle. None may shadow an N-Questie
        -- correction; set them aside to compare the compiled binary itself.
        local overrides, saved, overrideCount = QuestieDB.questDataOverrides, {}, 0
        for id, v in pairs(overrides) do
            saved[id] = v; overrideCount = overrideCount + 1
            check(not LEVEL_CORRECTIONS[id] and id ~= 1203 and id ~= 2001,
                  "runtime questDataOverrides shadows N-Questie corrected quest " .. tostring(id))
        end
        for id in pairs(saved) do overrides[id] = nil end
        print("[validate-335] runtime questDataOverrides entries set aside: " .. overrideCount)
        local after = snapshots.afterNormalized or {}
        local mismatches, compared = 0, 0
        for id, fields in pairs(after) do
            for _, key in ipairs(COMPILED_KEYS) do
                local got = ser(normalize(Q(id, key)))
                compared = compared + 1
                if got ~= fields[key] then
                    mismatches = mismatches + 1
                    if mismatches <= 10 then
                        print("compiled mismatch quest " .. tostring(id) .. " " .. key .. ": " .. got .. " vs " .. fields[key])
                    end
                end
            end
        end
        for id, v in pairs(saved) do overrides[id] = v end
        print("[validate-335] compiled round trip: " .. compared .. " quest fields compared, " .. mismatches .. " mismatches")
        check(mismatches == 0, "compiled quest fields differ from the corrected source (" .. mismatches .. ")")
    end

    if #failures > 0 then
        print(string.format("\27[31m[validate-335] FAILED: %d failure(s), %d check(s) passed\27[0m", #failures, passes))
        os.exit(1)
    end
    print(string.format("\27[32m[validate-335] PASS: %d checks\27[0m", passes))

    if exportOpts then
        if os.getenv("NQ_VALIDATE_SKIP_COMPILE") == "1" or not snapshots.afterNormalized then
            print("\27[31m[validate-335] export refused: compiled round trip did not run\27[0m")
            os.exit(1)
        end
        local ok, res = runExport(exportOpts, QuestieLoader:ImportModule("QuestieDB"),
            QuestieLoader:ImportModule("QuestieDB").QueryQuestSingle, levelCount)
        if not ok then
            for _, e in ipairs(res) do print("\27[31m" .. e .. "\27[0m") end
            print("\27[31m[validate-335] EXPORT FAILED: nothing written\27[0m")
            os.exit(1)
        end
        print("\27[32m[validate-335] effective export written: " .. #exportOpts.ids .. " quest(s) -> " .. res .. "\27[0m")
    end
    if coverageOpts then
        if not snapshots.afterNormalized then
            print("\27[31m[validate-335] coverage refused: compiled round trip did not run\27[0m")
            os.exit(1)
        end
        local ok, res = runCoverage(coverageOpts, QuestieLoader:ImportModule("QuestieDB"),
            QuestieLoader:ImportModule("QuestieDB").QueryQuestSingle, levelCount)
        if not ok then
            for _, e in ipairs(res) do print("\27[31m" .. e .. "\27[0m") end
            print("\27[31m[validate-335] COVERAGE FAILED\27[0m")
            os.exit(1)
        end
        print("\27[32m[validate-335] coverage manifest written (private): " .. res .. "\27[0m")
    end
end

local ok, err = pcall(run)
if not ok then
    print("\27[31m[validate-335] ERROR: " .. tostring(err) .. "\27[0m")
    os.exit(1)
end
os.exit(0)
