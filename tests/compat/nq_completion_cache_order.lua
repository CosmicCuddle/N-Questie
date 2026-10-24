-- CS02-CACHE-01. Synthetic characterisation of the WoW 3.3.5a completion cache.
-- Prepared by CS02 (CosmicScript02). Test-only. No production addon change.
--
-- Loads the real Compat/Compat.lua shims (GetQuestsCompleted, QUEST_QUERY_COMPLETE,
-- ResetDailyQuests, IsQuestFlaggedCompleted, Merge) and the real
-- QuestieDB:IsPreQuestSingleFulfilled classifier. WoW client APIs are stubbed.
-- Quest IDs are invented (990001+). No server data and no in-game claim.
--
-- Whether the real 3.3.5a native GetQuestsCompleted(t) clears t is UNKNOWN.
-- Every case runs two stub modes and does not pick a winner:
--   CLEAR    native wipes t, then adds the reply keys
--   ADD-ONLY native only adds reply keys
--
-- Run from the repository root:
--   lua5.1 tests/compat/nq_completion_cache_order.lua
-- Local in-memory probes (not production edits, do not treat as the default run):
--   lua5.1 tests/compat/nq_completion_cache_order.lua --mutate=skip-repeatable-strip
--   lua5.1 tests/compat/nq_completion_cache_order.lua --mutate=return-copy
--   lua5.1 tests/compat/nq_completion_cache_order.lua --mutate=swap-fill-modes
--
-- This file does not explain any in-game "marker appeared after /reload" report.

local mutate
if type(arg) == "table" then
    local index
    for index = 1, #arg do
        local value = arg[index]
        if type(value) == "string" then
            local flag = value:match("^%-%-mutate=(%S+)$")
            if flag then
                mutate = flag
            end
        end
    end
end

local mutationKills = {
    ["skip-repeatable-strip"] = "T3-repeatable-absent",
    ["return-copy"] = "T5-same-object",
    ["swap-fill-modes"] = "T2-ADD-ONLY-retains-stale",
}
if mutate and not mutationKills[mutate] then
    error("unknown --mutate value " .. tostring(mutate))
end

local function mustExist(path)
    local handle = io.open(path, "r")
    if not handle then
        error("run from the repository root; missing " .. path)
    end
    handle:close()
end

mustExist("Compat/Compat.lua")
mustExist("Modules/Libs/QuestieLoader.lua")
mustExist("Modules/QuestieCompat.lua")
mustExist("Database/QuestieDB.lua")

local Q_ANCHOR = 990001
local Q_GATED = 990010
local Q_PREREQ = 990011
local Q_STALE = 990020
local Q_FRESH = 990021
local Q_STALE_REPEATABLE = 990022
local Q_REPEAT = 990030
local Q_DAILY = 990040
local Q_WEEKLY = 990041
local Q_REPEAT_DAILY = 990042
local Q_LIVE = 990050

local function assertSynthetic(questId)
    if type(questId) ~= "number" or questId < 990001 then
        error("refusing non-synthetic quest id " .. tostring(questId))
    end
end

local synthetic = {
    [Q_STALE_REPEATABLE] = {repeatable = true},
    [Q_REPEAT] = {repeatable = true},
    [Q_DAILY] = {daily = true},
    [Q_WEEKLY] = {weekly = true},
    [Q_REPEAT_DAILY] = {repeatable = true, daily = true},
}

local fillMode = "CLEAR"
local serverReply = {}
local redrawLog = {}
local nativeCalls = 0
local queryCalls = 0
local playCount = 0
local lastNativeTable = nil
local midKeys = {}
local repeatableLookups = 0
local dailyLookups = 0
local weeklyLookups = 0
local failed = {}
local passCount = 0
local observed = {}

local function check(id, message, ok)
    if ok then
        passCount = passCount + 1
        print("PASS " .. id .. " " .. message)
    else
        failed[id] = message
        print("FAIL " .. id .. " " .. message)
    end
    return ok
end

local function loadChunk(source, name)
    local loader = loadstring or load
    local chunk, err = loader(source, name)
    if not chunk then
        error(err)
    end
    return chunk
end

local function readAll(path)
    local handle = assert(io.open(path, "r"))
    local text = handle:read("*a")
    handle:close()
    return text:gsub("\r\n", "\n")
end

local function lineNumbers(path, needle)
    local found = {}
    local number = 0
    for line in io.lines(path) do
        number = number + 1
        if line:find(needle, 1, true) then
            found[#found + 1] = number
        end
    end
    return found
end

local function formatLines(list)
    if #list == 0 then
        return "MISSING"
    end
    local parts = {}
    local index
    for index = 1, #list do
        parts[index] = tostring(list[index])
    end
    return table.concat(parts, ",")
end

local function readSpan(path, firstLine, lastLine)
    local buffer = {}
    local number = 0
    for line in io.lines(path) do
        number = number + 1
        if number >= firstLine and number <= lastLine then
            buffer[#buffer + 1] = line
        end
        if number >= lastLine then
            break
        end
    end
    return table.concat(buffer, "\n")
end

local function deepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, item in pairs(value) do
        copy[deepCopy(key, seen)] = deepCopy(item, seen)
    end
    return copy
end

local function fingerprint(tableValue)
    local parts = {}
    for key, value in pairs(tableValue) do
        parts[#parts + 1] = tostring(key) .. "=" .. tostring(value)
    end
    table.sort(parts)
    if #parts == 0 then
        return "(empty)"
    end
    return table.concat(parts, ",")
end

local function copyKeys(tableValue)
    local copy = {}
    for key, value in pairs(tableValue) do
        copy[key] = value
    end
    return copy
end

local function newFrame()
    local frame = {events = {}, scripts = {}}
    function frame:RegisterEvent(eventName)
        self.events[eventName] = true
    end
    function frame:UnregisterEvent(eventName)
        self.events[eventName] = nil
    end
    function frame:SetScript(scriptName, fn)
        self.scripts[scriptName] = fn
    end
    function frame:GetScript(scriptName)
        return self.scripts[scriptName]
    end
    function frame:CreateAnimationGroup()
        local group = {}
        function group:CreateAnimation()
            local anim = {scripts = {}}
            function anim:SetScript(scriptName, fn)
                self.scripts[scriptName] = fn
            end
            function anim:SetDuration(duration)
                self.duration = duration
            end
            function anim:GetParent()
                return group
            end
            return anim
        end
        function group:SetLooping(mode)
            self.looping = mode
        end
        function group:Play()
            playCount = playCount + 1
            self.playing = true
        end
        function group:Stop()
            self.playing = false
        end
        return group
    end
    function frame:CreateFontString()
        local fontString = {}
        function fontString:SetPoint() end
        function fontString:Hide() end
        function fontString:SetWidth() end
        function fontString:SetFont() end
        function fontString:SetText() end
        function fontString:GetStringWidth()
            return 0
        end
        function fontString:GetHeight()
            return 0
        end
        function fontString:GetText()
            return ""
        end
        function fontString:GetFont()
            return "font", 12, ""
        end
        return fontString
    end
    return setmetatable(frame, {
        __index = function()
            return function() end
        end,
    })
end

local function nativeClears()
    local clears = (fillMode == "CLEAR")
    if mutate == "swap-fill-modes" then
        clears = not clears
    end
    return clears
end

function GetBuildInfo()
    return "3.3.5", "12340", "synthetic", 30300
end

function GetAddOnMetadata(addonName, field)
    if field == "X-WOW_PROJECT_ID" then
        return "11"
    end
    return nil
end

function CreateFrame()
    return newFrame()
end

function GetMapContinents()
end

function GetAuctionItemClasses()
end

function UnitName()
    return "Synthetic"
end

function CalendarGetDate()
    return 4, 10, 24, 2026
end

function GetGameTime()
    return 12, 0
end

function GetQuestResetTime()
    return 3600
end

function QueryQuestsCompleted()
    queryCalls = queryCalls + 1
end

function GetQuestsCompleted(target)
    nativeCalls = nativeCalls + 1
    lastNativeTable = target
    if type(target) ~= "table" then
        error("native GetQuestsCompleted expected a table")
    end
    if nativeClears() then
        for key in pairs(target) do
            target[key] = nil
        end
    end
    for questId, value in pairs(serverReply) do
        assertSynthetic(questId)
        target[questId] = value
    end
    midKeys = copyKeys(target)
    return target
end

function hooksecurefunc()
end

ERR_QUEST_COMPLETE_S = "%s completed."
DAILY_QUESTS_REMAINING = "You have %d daily quests remaining."
StaticPopupDialogs = {}
time = os.time
date = os.date

UIParent = CreateFrame("Frame", "UIParent")
QuestieQuestEventFrame = CreateFrame("Frame", "QuestieQuestEventFrame")

Questie = {
    Is335 = true,
    IsWotlk = true,
    IsTBC = false,
    IsClassic = false,
    IsSoD = false,
    started = true,
    DEBUG_INFO = "INFO",
    DEBUG_DEVELOP = "DEVELOP",
    DEBUG_CRITICAL = "CRITICAL",
    db = {
        char = {
            complete = {},
            daily = {},
            weekly = {},
            hidden = {},
        },
        profile = {
            resetDailyQuests = true,
            weeklyResetDay = 2,
            weeklyResetHour = 3,
            debugEnabled = false,
            availableScale = 1.3,
            showAQWarEffortQuests = false,
        },
        global = {},
    },
    Debug = function() end,
    Error = function(_, message)
        error("Questie:Error " .. tostring(message))
    end,
    Print = function() end,
}

dofile("Modules/Libs/QuestieLoader.lua")
dofile("Modules/QuestieCompat.lua")

local compatChunk = assert(loadfile("Compat/Compat.lua"))
compatChunk("Questie")

local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
_G.QuestieDB = QuestieDB
local QuestiePlayer = QuestieLoader:ImportModule("QuestiePlayer")
local AvailableQuests = QuestieLoader:ImportModule("AvailableQuests")
local QuestieProfessions = QuestieLoader:ImportModule("QuestieProfessions")
local QuestieReputation = QuestieLoader:ImportModule("QuestieReputation")
local ZoneDB = QuestieLoader:ImportModule("ZoneDB")

local function definedIn(fn, pathNeedle, signatureNeedle, explicitBody)
    local info = debug.getinfo(fn, "S")
    if not info or not info.source or not info.source:find(pathNeedle, 1, true) then
        return false, "source=" .. tostring(info and info.source)
    end
    local body = explicitBody
    if not body then
        if info.source:sub(1, 1) ~= "@" then
            return false, "chunk is not a loaded file (" .. info.source .. ")"
        end
        body = readSpan(info.source:gsub("^@", ""), info.linedefined, info.lastlinedefined)
    end
    if signatureNeedle and not body:find(signatureNeedle, 1, true) then
        return false, "lines " .. tostring(info.linedefined) .. "-" .. tostring(info.lastlinedefined)
    end
    return true, tostring(info.linedefined) .. "-" .. tostring(info.lastlinedefined)
end

do
    local ok, detail = definedIn(
        QuestieCompat.GetQuestsCompleted,
        "Compat/Compat.lua",
        "function QuestieCompat.GetQuestsCompleted()"
    )
    check("load-shim", "real QuestieCompat.GetQuestsCompleted from Compat.lua lines " .. detail, ok)

    ok, detail = definedIn(
        QuestieCompat.QUEST_QUERY_COMPLETE,
        "Compat/Compat.lua",
        "GetQuestsCompleted(Questie.db.char.complete)"
    )
    check("load-handler", "real QUEST_QUERY_COMPLETE from Compat.lua lines " .. detail, ok)

    ok, detail = definedIn(
        QuestieCompat.IsQuestFlaggedCompleted,
        "Compat/Compat.lua",
        "Questie.db.char.complete[questID]"
    )
    check("load-flagged", "real IsQuestFlaggedCompleted from Compat.lua lines " .. detail, ok)

    ok, detail = definedIn(
        QuestieCompat.ResetDailyQuests,
        "Compat/Compat.lua",
        "AvailableQuests.CalculateAndDrawAll()"
    )
    check("load-daily-reset", "real ResetDailyQuests from Compat.lua lines " .. detail, ok)

    ok, detail = definedIn(QuestieCompat.Merge, "Compat/Compat.lua", "function QuestieCompat.Merge")
    check("load-merge", "real QuestieCompat.Merge from Compat.lua lines " .. detail, ok)

    local onEvent = QuestieCompat.frame.scripts and QuestieCompat.frame.scripts.OnEvent
    ok, detail = definedIn(onEvent, "Compat/Compat.lua", "QuestieCompat[event]")
    check("load-frame-dispatch", "real compat frame OnEvent from Compat.lua lines " .. detail, ok)

    local handlerInfo = debug.getinfo(QuestieCompat.QUEST_QUERY_COMPLETE, "S")
    local handlerBody = readSpan(
        handlerInfo.source:gsub("^@", ""),
        handlerInfo.linedefined,
        handlerInfo.lastlinedefined
    )
    check(
        "source-handler-no-direct-redraw",
        "QUEST_QUERY_COMPLETE source does not name CalculateAndDrawAll",
        not handlerBody:find("CalculateAndDrawAll", 1, true)
            and handlerBody:find("ResetDailyQuests", 1, true)
    )
end

local classifierSource = readAll("Database/QuestieDB.lua")
local classifierStart = classifierSource:find(
    "function QuestieDB:IsPreQuestSingleFulfilled(preQuestSingle)",
    1,
    true
)
if not classifierStart then
    error("real IsPreQuestSingleFulfilled not found")
end
local classifierLineStart = 1
do
    local scan = 1
    while true do
        local newline = classifierSource:find("\n", scan, true)
        if not newline or newline >= classifierStart then
            break
        end
        classifierLineStart = newline + 1
        scan = newline + 1
    end
end
local depth = 0
local cursor = classifierLineStart
local classifierChunk
while cursor <= #classifierSource do
    local newline = classifierSource:find("\n", cursor, true) or (#classifierSource + 1)
    local line = classifierSource:sub(cursor, newline - 1)
    if line:find("^function%s") or line:find("^local%s+function%s") then
        depth = depth + 1
    elseif line == "end" then
        depth = depth - 1
        if depth == 0 then
            classifierChunk = classifierSource:sub(classifierLineStart, newline)
            break
        end
    end
    if newline > #classifierSource then
        break
    end
    cursor = newline + 1
end
if not classifierChunk then
    error("could not extract IsPreQuestSingleFulfilled")
end
check(
    "load-classifier-source",
    "extracted real IsPreQuestSingleFulfilled reads char.complete",
    classifierChunk:find("Questie.db.char.complete[preQuestSingle[preQuestIndex]]", 1, true)
        and true
        or false
)
loadChunk(classifierChunk, "IsPreQuestSingleFulfilled")()
do
    local ok, detail = definedIn(
        QuestieDB.IsPreQuestSingleFulfilled,
        "IsPreQuestSingleFulfilled",
        "Questie.db.char.complete[preQuestSingle[preQuestIndex]]",
        classifierChunk
    )
    check("load-classifier", "classifier chunk is the extracted QuestieDB function (" .. detail .. ")", ok)
end

function QuestieDB.IsRepeatable(questId)
    repeatableLookups = repeatableLookups + 1
    if mutate == "skip-repeatable-strip" then
        return false
    end
    local info = synthetic[questId]
    return info and info.repeatable or false
end

function QuestieDB.IsDailyQuest(questId)
    dailyLookups = dailyLookups + 1
    local info = synthetic[questId]
    return info and info.daily or false
end

function QuestieDB.IsWeeklyQuest(questId)
    weeklyLookups = weeklyLookups + 1
    local info = synthetic[questId]
    return info and info.weekly or false
end

local realGetQuestsCompleted = QuestieCompat.GetQuestsCompleted
if mutate == "return-copy" then
    QuestieCompat.GetQuestsCompleted = function()
        local live = realGetQuestsCompleted()
        local copy = {}
        local key, value
        for key, value in pairs(live) do
            copy[key] = value
        end
        return copy
    end
end

QuestieCompat.HBD = {}
function QuestieProfessions:Update() end
function QuestieReputation:Update() end
function ZoneDB:GetDungeons()
    return {}
end

assert(loadfile("Modules/Quest/QuestieQuest.lua"))()
assert(loadfile("Modules/Quest/AvailableQuests.lua"))()
assert(loadfile("Modules/QuestieInit.lua"))()

AvailableQuests.CalculateAndDrawAll = function()
    redrawLog[#redrawLog + 1] = "CalculateAndDrawAll"
end

local QuestieQuest = QuestieLoader:ImportModule("QuestieQuest")
local QuestieInit = QuestieLoader:ImportModule("QuestieInit")

local function oraclePreQuestSingle(snapshot, preQuestSingle)
    if not preQuestSingle then
        return true
    end
    local index
    for index = 1, #preQuestSingle do
        if snapshot[preQuestSingle[index]] then
            return true
        end
    end
    return false
end

local classifierWrites = 0
local function classify(preQuestSingle, snapshot)
    local live = Questie.db.char.complete
    local before = fingerprint(live)
    local writes = 0
    local proxy = setmetatable({}, {
        __index = function(_, key)
            return snapshot[key]
        end,
        __newindex = function(_, key)
            writes = writes + 1
            classifierWrites = classifierWrites + 1
            error("classifier write " .. tostring(key))
        end,
    })
    Questie.db.char.complete = proxy
    local ok, result = pcall(function()
        return QuestieDB:IsPreQuestSingleFulfilled(preQuestSingle)
    end)
    Questie.db.char.complete = live
    if fingerprint(live) ~= before then
        error("classifier mutated the live completion cache")
    end
    if not ok then
        error(result)
    end
    if writes ~= 0 then
        error("classifier writes=" .. tostring(writes))
    end
    local expected = oraclePreQuestSingle(snapshot, preQuestSingle)
    if result ~= expected then
        error("extracted classifier disagrees with the pure preQuestSingle oracle")
    end
    return result
end

local function resetState()
    Questie.db.char.complete = {}
    Questie.db.char.daily = {}
    Questie.db.char.weekly = {}
    Questie.started = true
    Questie.IsWotlk = true
    QuestiePlayer.GetPlayerLevel = function()
        return 80
    end
    QuestiePlayer.currentQuestlog = {}
    local now = QuestieCompat.GetServerTime()
    Questie.db.profile.resetDailyQuests = true
    Questie.db.profile.dailyResetTime = now + 100000
    Questie.db.profile.weeklyResetTime = now + 100000
    Questie.db.profile.weeklyResetHour = 3
    Questie.db.profile.weeklyResetDay = 2
    serverReply = {}
    redrawLog = {}
    nativeCalls = 0
    queryCalls = 0
    playCount = 0
    lastNativeTable = nil
    midKeys = {}
    repeatableLookups = 0
    dailyLookups = 0
    weeklyLookups = 0
end

local function fireQueryComplete()
    local frame = QuestieCompat.frame
    if not frame.events["QUEST_QUERY_COMPLETE"] then
        error("QUEST_QUERY_COMPLETE is not registered on the compat frame")
    end
    local queriesBefore = queryCalls
    frame.scripts.OnEvent(frame, "QUEST_QUERY_COMPLETE")
    if queryCalls ~= queriesBefore then
        error("QUEST_QUERY_COMPLETE dispatch called QueryQuestsCompleted; the handler should call native GetQuestsCompleted")
    end
end

local function remember(mode, caseId, fields)
    observed[mode] = observed[mode] or {}
    observed[mode][caseId] = fields
end

local function eachMode(fn)
    fn("CLEAR")
    fn("ADD-ONLY")
end

print("CS02-CACHE-01 completion-cache characterisation")
print("Lua " .. _VERSION .. (mutate and (" mutate=" .. mutate) or " mutate=none"))
print("Native clear semantics are UNKNOWN; CLEAR and ADD-ONLY are both stubs.")
print("In-game client behaviour is NOT TESTED. This run does not explain a marker-after-reload report.")

do
    local binding = lineNumbers(
        "Modules/Quest/QuestieQuest.lua",
        "local GetQuestsCompleted = QuestieCompat.GetQuestsCompleted"
    )
    local assign = lineNumbers(
        "Modules/Quest/QuestieQuest.lua",
        "Questie.db.char.complete = GetQuestsCompleted()"
    )
    local finisher = lineNumbers(
        "Modules/Quest/QuestieQuest.lua",
        "IsQuestFlaggedCompleted(questId) == false"
    )
    local preSingle = lineNumbers(
        "Database/QuestieDB.lua",
        "Questie.db.char.complete[preQuestSingle[preQuestIndex]]"
    )
    local verbose = lineNumbers(
        "Database/QuestieDB.lua",
        "if IsQuestFlaggedCompleted(questId) then"
    )
    local liveRef = lineNumbers(
        "Modules/Quest/AvailableQuests.lua",
        "local completedQuests = Questie.db.char.complete"
    )
    local startup = lineNumbers(
        "Modules/QuestieInit.lua",
        "AvailableQuests.CalculateAndDrawAll()"
    )
    check(
        "C-questiequest-binding",
        "QuestieQuest binds the shim at line " .. formatLines(binding),
        #binding == 1
    )
    check(
        "C-questiequest-assign",
        "QuestieQuest copies the shim return into char.complete at lines " .. formatLines(assign),
        #assign >= 2
    )
    check(
        "C-addfinisher-source",
        "AddFinisher reads IsQuestFlaggedCompleted and char.complete at line " .. formatLines(finisher),
        #finisher == 1
    )
    check(
        "C-prequest-source",
        "IsPreQuestSingleFulfilled reads char.complete at line " .. formatLines(preSingle),
        #preSingle == 1
    )
    check(
        "C-verbose-source",
        "QuestieDB verbose eligibility reads IsQuestFlaggedCompleted at line " .. formatLines(verbose),
        #verbose == 1
    )
    check(
        "C-available-live-ref",
        "AvailableQuests holds char.complete by reference at line " .. formatLines(liveRef),
        #liveRef == 1
    )
    check(
        "C-init-startup-draw",
        "QuestieInit stage 3 requests CalculateAndDrawAll at line " .. formatLines(startup),
        #startup >= 1 and type(QuestieInit.Stages[3]) == "function"
    )
    print("NOT TESTED C-init-stage3-execution QuestieInit.Stages[3] was loaded and not run")
    print("NOT TESTED C-smoothreset-execution SmoothReset's coroutine steps were not pumped")
    print("NOT TESTED C-map-draw CalculateAndDrawAll's icon body is replaced by a request counter")
end

QuestieCompat.QuestEventHandler_RegisterEvents()
check(
    "C-event-registered",
    "QuestEventHandler_RegisterEvents registers QUEST_QUERY_COMPLETE",
    QuestieCompat.frame.events["QUEST_QUERY_COMPLETE"] == true
)
check(
    "C-shim-is-not-native",
    "QuestieCompat.GetQuestsCompleted and global native GetQuestsCompleted are different functions",
    realGetQuestsCompleted ~= GetQuestsCompleted
)

do
    resetState()
    Questie.db.char.complete = nil
    local queriesBefore = queryCalls
    local nativesBefore = nativeCalls
    QuestieQuest:Initialize()
    local afterInit = Questie.db.char.complete
    check(
        "C-initialize-queries",
        "QuestieQuest:Initialize calls the shim, which calls QueryQuestsCompleted and does not call native fill",
        queryCalls == queriesBefore + 1 and nativeCalls == nativesBefore and type(afterInit) == "table"
    )
    local again = QuestieCompat.GetQuestsCompleted()
    check(
        "C-initialize-identity",
        "Initialize keeps the SavedVariables table when the shim returns that same table",
        again == afterInit
    )
end

do
    resetState()
    local npcCalls = 0
    function QuestieDB:GetNPC()
        npcCalls = npcCalls + 1
        return nil
    end
    Questie.db.char.complete[Q_GATED] = true
    QuestiePlayer.currentQuestlog[Q_GATED] = {Id = Q_GATED}
    QuestieQuest:AddFinisher({
        Id = Q_GATED,
        IsComplete = function()
            return 1
        end,
        Finisher = {Type = "monster", Id = 990060},
    })
    check(
        "C-addfinisher-blocked",
        "AddFinisher does not resolve a finisher when IsQuestFlaggedCompleted is true (npcCalls=" .. tostring(npcCalls) .. ")",
        npcCalls == 0 and QuestieCompat.IsQuestFlaggedCompleted(Q_GATED) == true
    )
    Questie.db.char.complete[Q_GATED] = nil
    QuestieQuest:AddFinisher({
        Id = Q_GATED,
        IsComplete = function()
            return 1
        end,
        Finisher = {Type = "monster", Id = 990060},
    })
    check(
        "C-addfinisher-reads-cache",
        "AddFinisher enters the finisher lookup when the cache and flag both say incomplete (npcCalls=" .. tostring(npcCalls) .. ")",
        npcCalls == 1 and QuestieCompat.IsQuestFlaggedCompleted(Q_GATED) == false
    )
    print("NOT TESTED C-addfinisher-icons finisher draw was not executed (lookup returned nil)")
end

local function runT1(mode)
    fillMode = mode
    resetState()
    local returned = QuestieCompat.GetQuestsCompleted()
    local beforeSnap = deepCopy(Questie.db.char.complete)
    local beforeVerdict = classify({Q_PREREQ}, beforeSnap)
    local beforeFlag = QuestieCompat.IsQuestFlaggedCompleted(Q_PREREQ)
    local beforeGated = QuestieCompat.IsQuestFlaggedCompleted(Q_GATED)
    check(
        "T1-" .. mode .. "-before-native",
        mode .. " before reply nativeCalls=" .. tostring(nativeCalls) .. " queryCalls=" .. tostring(queryCalls),
        nativeCalls == 0 and queryCalls == 1 and returned == Questie.db.char.complete
    )
    serverReply = {[Q_PREREQ] = true, [Q_ANCHOR] = true}
    fireQueryComplete()
    local afterSnap = deepCopy(Questie.db.char.complete)
    local afterVerdict = classify({Q_PREREQ}, afterSnap)
    local afterFlag = QuestieCompat.IsQuestFlaggedCompleted(Q_PREREQ)
    check(
        "T1-" .. mode .. "-verdicts",
        mode .. " preQuestSingle " .. tostring(Q_GATED) .. " via " .. tostring(Q_PREREQ)
            .. " before=" .. tostring(beforeVerdict) .. " after=" .. tostring(afterVerdict)
            .. " flaggedBefore=" .. tostring(beforeFlag) .. " flaggedAfter=" .. tostring(afterFlag)
            .. " gatedFlagged=" .. tostring(beforeGated),
        beforeVerdict == false and afterVerdict == true
            and beforeFlag == false and afterFlag == true
            and beforeGated == false
            and QuestieCompat.IsQuestFlaggedCompleted(Q_GATED) == false
            and type(beforeFlag) == "boolean" and type(afterFlag) == "boolean"
    )
    check(
        "T1-" .. mode .. "-no-redraw",
        mode .. " redraws=" .. tostring(#redrawLog),
        #redrawLog == 0
    )
    remember(mode, "T1", {
        before = beforeVerdict,
        after = afterVerdict,
        flaggedBefore = beforeFlag,
        flaggedAfter = afterFlag,
        redraws = #redrawLog,
    })
end

local function runT2(mode)
    fillMode = mode
    resetState()
    Questie.db.char.complete[Q_STALE] = true
    Questie.db.char.complete[Q_ANCHOR] = true
    serverReply = {[Q_ANCHOR] = true, [Q_FRESH] = true}
    fireQueryComplete()
    local stale = Questie.db.char.complete[Q_STALE] == true
    local fresh = Questie.db.char.complete[Q_FRESH] == true
    local anchor = Questie.db.char.complete[Q_ANCHOR] == true
    local staleFlag = QuestieCompat.IsQuestFlaggedCompleted(Q_STALE)
    if mode == "CLEAR" then
        check(
            "T2-CLEAR-drops-stale",
            "CLEAR stale=" .. tostring(stale) .. " fresh=" .. tostring(fresh)
                .. " anchor=" .. tostring(anchor) .. " flagged=" .. tostring(staleFlag)
                .. " cache=" .. fingerprint(Questie.db.char.complete),
            stale == false and fresh == true and anchor == true and staleFlag == false
        )
    else
        check(
            "T2-ADD-ONLY-retains-stale",
            "ADD-ONLY stale=" .. tostring(stale) .. " fresh=" .. tostring(fresh)
                .. " anchor=" .. tostring(anchor) .. " flagged=" .. tostring(staleFlag)
                .. " cache=" .. fingerprint(Questie.db.char.complete),
            stale == true and fresh == true and anchor == true and staleFlag == true
        )
    end
    remember(mode, "T2", {stale = stale, fresh = fresh, anchor = anchor, flagged = staleFlag})

    resetState()
    Questie.db.char.complete[Q_STALE_REPEATABLE] = true
    serverReply = {[Q_ANCHOR] = true}
    fireQueryComplete()
    local repeatableStale = Questie.db.char.complete[Q_STALE_REPEATABLE] == true
    check(
        "T2R-" .. mode .. "-repeatable-stale-stripped",
        mode .. " stale repeatable " .. tostring(Q_STALE_REPEATABLE) .. " retained=" .. tostring(repeatableStale),
        repeatableStale == false
    )
    remember(mode, "T2R", {retained = repeatableStale})
end

local function runT3(mode)
    fillMode = mode
    resetState()
    serverReply = {[Q_REPEAT] = true, [Q_ANCHOR] = true}
    fireQueryComplete()
    local mid = midKeys[Q_REPEAT] == true
    local after = Questie.db.char.complete[Q_REPEAT]
    local anchor = Questie.db.char.complete[Q_ANCHOR] == true
    check(
        "T3-" .. mode .. "-visible-during-fill",
        mode .. " repeatable visible inside native fill=" .. tostring(mid) .. " lookups=" .. tostring(repeatableLookups),
        mid == true and repeatableLookups > 0
    )
    local absentId = (mode == "CLEAR") and "T3-CLEAR-repeatable-absent" or "T3-repeatable-absent"
    if mode == "ADD-ONLY" then
        absentId = "T3-repeatable-absent"
    end
    check(
        absentId,
        mode .. " repeatable after handler=" .. tostring(after) .. " anchor=" .. tostring(anchor)
            .. " flagged=" .. tostring(QuestieCompat.IsQuestFlaggedCompleted(Q_REPEAT)),
        after == nil and anchor == true and QuestieCompat.IsQuestFlaggedCompleted(Q_REPEAT) == false
    )
    remember(mode, "T3", {duringFill = mid, afterPresent = after ~= nil, anchor = anchor})
end

local function runT4(mode)
    fillMode = mode
    resetState()
    Questie.db.char.daily[Q_DAILY] = true
    Questie.db.char.weekly[Q_WEEKLY] = true
    Questie.db.char.daily[Q_REPEAT_DAILY] = true
    serverReply = {[Q_REPEAT_DAILY] = true, [Q_ANCHOR] = true}
    fireQueryComplete()
    local dailyPresent = Questie.db.char.complete[Q_DAILY] == true
    local weeklyPresent = Questie.db.char.complete[Q_WEEKLY] == true
    local repeatDailyPresent = Questie.db.char.complete[Q_REPEAT_DAILY] == true
    local anchor = Questie.db.char.complete[Q_ANCHOR] == true
    check(
        "T4-" .. mode .. "-merged",
        mode .. " daily=" .. tostring(dailyPresent) .. " weekly=" .. tostring(weeklyPresent)
            .. " repeatDaily=" .. tostring(repeatDailyPresent) .. " anchor=" .. tostring(anchor)
            .. " dailyLookups=" .. tostring(dailyLookups) .. " weeklyLookups=" .. tostring(weeklyLookups)
            .. " plays=" .. tostring(playCount) .. " cache=" .. fingerprint(Questie.db.char.complete),
        dailyPresent and weeklyPresent and repeatDailyPresent and anchor
            and dailyLookups == 0 and weeklyLookups == 0 and playCount == 0
            and Questie.db.char.daily[Q_DAILY] == true
            and Questie.db.char.weekly[Q_WEEKLY] == true
    )
    remember(mode, "T4", {
        daily = dailyPresent,
        weekly = weeklyPresent,
        repeatDaily = repeatDailyPresent,
        dailyLookups = dailyLookups,
        weeklyLookups = weeklyLookups,
    })

    resetState()
    QuestiePlayer.GetPlayerLevel = function()
        return 77
    end
    Questie.db.char.daily[Q_DAILY] = true
    Questie.db.char.weekly[Q_WEEKLY] = true
    serverReply = {[Q_ANCHOR] = true}
    fireQueryComplete()
    check(
        "T4-" .. mode .. "-level-gate",
        mode .. " level77 daily=" .. tostring(Questie.db.char.complete[Q_DAILY] == true)
            .. " weekly=" .. tostring(Questie.db.char.complete[Q_WEEKLY] == true),
        Questie.db.char.complete[Q_DAILY] == true and Questie.db.char.complete[Q_WEEKLY] == nil
    )
    remember(mode, "T4L77", {
        daily = Questie.db.char.complete[Q_DAILY] == true,
        weekly = Questie.db.char.complete[Q_WEEKLY] == true,
    })
end

local function runT5(mode)
    fillMode = mode
    resetState()
    local first = QuestieCompat.GetQuestsCompleted()
    local second = QuestieCompat.GetQuestsCompleted()
    local completedQuests = Questie.db.char.complete
    check(
        "T5-same-object",
        mode .. " first==second==char.complete (" .. tostring(first == second) .. ", " .. tostring(first == completedQuests) .. ")",
        first == second and first == completedQuests
    )
    serverReply = {[Q_LIVE] = true, [Q_REPEAT] = true}
    fireQueryComplete()
    local snap = deepCopy(completedQuests)
    local liveBefore = fingerprint(completedQuests)
    local verdict = classify({Q_LIVE}, snap)
    local liveAfter = fingerprint(completedQuests)
    snap[990099] = true
    check(
        "T5-" .. mode .. "-inplace",
        mode .. " holderSawLive=" .. tostring(midKeys[Q_LIVE] == true)
            .. " holderSawRepeatableDuringFill=" .. tostring(midKeys[Q_REPEAT] == true)
            .. " holderAfterLive=" .. tostring(completedQuests[Q_LIVE] == true)
            .. " holderAfterRepeatable=" .. tostring(completedQuests[Q_REPEAT])
            .. " nativeTableIsHolder=" .. tostring(lastNativeTable == completedQuests)
            .. " verdict=" .. tostring(verdict)
            .. " classifierWrites=" .. tostring(classifierWrites),
        lastNativeTable == completedQuests
            and completedQuests == first
            and midKeys[Q_LIVE] == true
            and midKeys[Q_REPEAT] == true
            and completedQuests[Q_LIVE] == true
            and completedQuests[Q_REPEAT] == nil
            and verdict == true
            and liveBefore == liveAfter
            and completedQuests[990099] == nil
            and classifierWrites == 0
    )
    remember(mode, "T5", {
        sameObject = first == second and first == Questie.db.char.complete,
        duringFillRepeatable = midKeys[Q_REPEAT] == true,
        afterRepeatablePresent = completedQuests[Q_REPEAT] ~= nil,
        afterLive = completedQuests[Q_LIVE] == true,
        classifierWrites = classifierWrites,
        verdict = verdict,
    })
end

local function runT6(mode)
    fillMode = mode
    resetState()
    local resetTime = Questie.db.profile.dailyResetTime
    serverReply = {[Q_ANCHOR] = true, [Q_PREREQ] = true}
    fireQueryComplete()
    local redraws = #redrawLog
    local resetUnchanged = Questie.db.profile.dailyResetTime == resetTime
    check(
        "T6-" .. mode .. "-no-redraw",
        mode .. " redraws=" .. tostring(redraws)
            .. " started=" .. tostring(Questie.started)
            .. " resetUnchanged=" .. tostring(resetUnchanged)
            .. " plays=" .. tostring(playCount),
        redraws == 0 and Questie.started == true and resetUnchanged and playCount == 0
    )
    remember(mode, "T6", {redraws = redraws, resetUnchanged = resetUnchanged, started = Questie.started})
    if redraws == 0 then
        print("GAP NOTE (" .. mode .. "): QUEST_QUERY_COMPLETE updates char.complete in place and does not request AvailableQuests.CalculateAndDrawAll while the daily-reset branch is inactive. Questie.started is already true. This pins today's source behaviour. It is not an in-game result and it does not explain a marker-after-reload report. Other events that might redraw later are NOT TESTED.")
    end
end

local function runDaily(mode)
    fillMode = mode
    resetState()
    Questie.db.char.daily[Q_DAILY] = true
    Questie.db.char.complete[Q_DAILY] = true
    local now = QuestieCompat.GetServerTime()
    Questie.db.profile.dailyResetTime = now - 5
    Questie.started = true
    serverReply = {[Q_ANCHOR] = true}
    fireQueryComplete()
    check(
        "D1-" .. mode .. "-redraws",
        mode .. " daily-reset redraws=" .. tostring(#redrawLog)
            .. " dailyLeft=" .. tostring(Questie.db.char.daily[Q_DAILY])
            .. " completeLeft=" .. tostring(Questie.db.char.complete[Q_DAILY]),
        #redrawLog == 1
            and Questie.db.char.daily[Q_DAILY] == nil
            and Questie.db.char.complete[Q_DAILY] == nil
            and Questie.db.char.complete[Q_ANCHOR] == true
    )
    remember(mode, "D1", {
        redraws = #redrawLog,
        dailyLeft = Questie.db.char.daily[Q_DAILY] ~= nil,
        completeLeft = Questie.db.char.complete[Q_DAILY] ~= nil,
    })

    resetState()
    Questie.db.char.daily[Q_DAILY] = true
    Questie.db.char.complete[Q_DAILY] = true
    now = QuestieCompat.GetServerTime()
    Questie.db.profile.dailyResetTime = now - 5
    Questie.started = false
    serverReply = {[Q_ANCHOR] = true}
    fireQueryComplete()
    check(
        "D2-" .. mode .. "-no-redraw-until-started",
        mode .. " started=false redraws=" .. tostring(#redrawLog)
            .. " dailyLeft=" .. tostring(Questie.db.char.daily[Q_DAILY]),
        #redrawLog == 0 and Questie.db.char.daily[Q_DAILY] == nil
    )
    remember(mode, "D2", {redraws = #redrawLog, dailyLeft = Questie.db.char.daily[Q_DAILY] ~= nil})
end

eachMode(runT1)
eachMode(runT2)
eachMode(runT3)
eachMode(runT4)
eachMode(runT5)
eachMode(runT6)
eachMode(runDaily)

check(
    "classifier-never-wrote",
    "classifier write count across cases is " .. tostring(classifierWrites),
    classifierWrites == 0
)

local function fieldString(fields)
    local parts = {}
    local key
    for key, value in pairs(fields) do
        parts[#parts + 1] = tostring(key) .. "=" .. tostring(value)
    end
    table.sort(parts)
    return table.concat(parts, " ")
end

print("OBSERVED BEGIN")
local modeName
for _, modeName in ipairs({"CLEAR", "ADD-ONLY"}) do
    local caseId
    for _, caseId in ipairs({"T1", "T2", "T2R", "T3", "T4", "T4L77", "T5", "T6", "D1", "D2"}) do
        local fields = observed[modeName] and observed[modeName][caseId]
        if fields then
            print("OBSERVED " .. caseId .. " " .. modeName .. " " .. fieldString(fields))
        end
    end
end
print("OBSERVED END")

print("FINDING load VERIFIED real Compat.lua functions and the extracted IsPreQuestSingleFulfilled ran under the stubs.")
print("FINDING client-fill UNKNOWN the 3.3.5a client may clear or only add; this test records both and claims neither.")
print("FINDING T1 VERIFIED a pure preQuestSingle classifier is false on the before-reply snapshot and true after the reply contains only-synthetic 990011, in both stub modes.")
print("FINDING T2 VERIFIED CLEAR drops stale 990020; ADD-ONLY retains it. POTENTIAL ISSUE only if a real client were add-only: a server-side un-completion would stay cached. That client mode is UNKNOWN.")
print("FINDING T2R VERIFIED a stale repeatable is removed in both modes because stripping walks the whole table after fill.")
print("FINDING T3 VERIFIED a repeatable present in the native reply is visible mid-fill and absent after the handler, in both modes.")
print("FINDING T4 VERIFIED Questie-tracked daily and weekly keys are merged after fill. Weekly merge also requires IsWotlk and level >= 78. The handler did not call IsDailyQuest or IsWeeklyQuest. A repeatable that is also tracked in char.daily is stripped and then merged back.")
print("FINDING T5 VERIFIED the shim returns one table object, the native reply mutates that object, and a deep-copied classifier snapshot is not written.")
print("FINDING T6 VERIFIED pinned current behaviour: outside the daily-reset branch, QUEST_QUERY_COMPLETE requests no CalculateAndDrawAll even when Questie.started is true. GAP: the cache can change with no redraw from this handler. NOT an explanation of any marker-after-reload report.")
print("FINDING D1 VERIFIED when daily reset time has passed and Questie.started is true, the handler's ResetDailyQuests path requests exactly one CalculateAndDrawAll and clears tracked dailies before the merge.")
print("FINDING D2 VERIFIED the same reset clears tracked dailies but requests no redraw when Questie.started is false.")
print("FINDING in-game NOT TESTED. Map drawing, SmoothReset ticks, QuestieInit stage 3, and the real 3.3.5a client were not executed.")

local failCount = 0
local failId
for failId in pairs(failed) do
    failCount = failCount + 1
    print("FAILED CHECK " .. failId .. " " .. failed[failId])
end

if mutate then
    local killId = mutationKills[mutate]
    if failed[killId] then
        print("MUTATION KILLED " .. mutate .. " by " .. killId)
        os.exit(0)
    end
    print("MUTATION SURVIVED " .. mutate .. " expected failure of " .. killId)
    os.exit(1)
end

if failCount > 0 then
    print("RESULT FAIL checks=" .. tostring(failCount) .. " passed=" .. tostring(passCount))
    os.exit(1)
end

print("RESULT PASS checks=" .. tostring(passCount))
print("ALL SYNTHETIC COMPLETION-CACHE CHARACTERISATION CHECKS PASS")
