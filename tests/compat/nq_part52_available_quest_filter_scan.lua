-- N-Questie Part52: source-backed missing-quest availability scan.
-- Execute actual AvailableQuests.lua, never a copied implementation.
-- All quest/NPC IDs are invented test identifiers. No live/owner data.
-- This models one calculation pass, NOT the map system's full icon cleanup.

local modules = {}
QuestieLoader = {
    CreateModule = function(_, key)
        modules[key] = modules[key] or {}
        return modules[key]
    end,
    ImportModule = function(_, key)
        assert(modules[key], "missing module mock " .. tostring(key))
        return modules[key]
    end,
}
Questie = {
    DEBUG_INFO = 1,
    LOWLEVEL_NONE = 1,
    LOWLEVEL_RANGE = 2,
    LOWLEVEL_OFFSET = 3,
    IsClassic = false,
    IsSoD = false,
    db = {
        profile = {
            debugEnabled = false,
            lowLevelStyle = 1,
            availableScale = 1.3,
            showRepeatableQuests = true,
            showPvPQuests = true,
            showDungeonQuests = true,
            showRaidQuests = true,
            showAQWarEffortQuests = false,
        },
        char = {complete = {}, hidden = {}},
    },
    ICON_TYPE_AVAILABLE = 1,
    ICON_TYPE_AVAILABLE_GRAY = 2,
    ICON_TYPE_REPEATABLE = 3,
    ICON_TYPE_PVPQUEST = 4,
    ICON_TYPE_EVENTQUEST = 5,
    ICON_TYPE_SODRUNE = 6,
    Debug = function() end,
}
local aqId, normalId, rawOnlyId = 920501, 920502, 920503
local npcIds = {[aqId] = 920511, [normalId] = 920512, [rawOnlyId] = 920513}
local quests, npcs = {}, {}
for questId, npcId in pairs(npcIds) do
    quests[questId] = {
        Id = questId,
        Starts = {NPC = {npcId}},
        requiredLevel = 10,
        level = 11,
        IsRepeatable = false,
    }
    npcs[npcId] = {
        id = npcId,
        name = "Invented source",
        spawns = {[201] = {{22, 33}}},
    }
end

local drawn, tips = {}, {}
local levelCalls, doableCalls = 0, 0
local allowDoable = true
modules.ThreadLib = {
    ThreadSimple = function(fn) return fn() end,
    Thread = function(fn)
        fn()
        return {Cancel = function() end}
    end,
}
modules.QuestieDB = {
    questData = quests,
    QuestPointers = {[aqId] = 1},
    autoBlacklist = {},
    activeChildQuests = {},
    GetQuest = function(id) return quests[id] end,
    GetNPC = function(_, id) return npcs[id] end,
    GetObject = function() return nil end,
    GetQuestTagInfo = function() end,
    IsRepeatable = function() return false end,
    IsPvPQuest = function() return false end,
    IsDungeonQuest = function() return false end,
    IsRaidQuest = function() return false end,
    IsRuneAndShouldBeHidden = function() return false end,
    IsActiveEventQuest = function() return false end,
    IsTrivial = function() return false end,
    IsLevelRequirementsFulfilled = function()
        levelCalls = levelCalls + 1
        return true
    end,
    IsDoable = function()
        doableCalls = doableCalls + 1
        return allowDoable
    end,
}
modules.ZoneDB = {
    GetDungeons = function() return {} end,
    GetDungeonLocation = function() return nil end,
}
modules.QuestiePlayer = {
    currentQuestlog = {},
    GetPlayerLevel = function() return 60 end,
}
modules.QuestieMap = {
    questIdFrames = {},
    DrawWorldIcon = function(_, data, zone, x, y)
        drawn[#drawn + 1] = {id = data.Id, zone = zone, x = x, y = y}
        return drawn[#drawn]
    end,
    UnloadQuestFrames = function() end,
    DrawWaypoints = function() end,
}
modules.QuestieTooltips = {
    RegisterQuestStartTooltip = function(_, questId)
        tips[#tips + 1] = questId
    end,
    RemoveQuest = function() end,
}
modules.QuestieCorrections = {hiddenQuests = {}}
modules.QuestieQuestBlacklist = {AQWarEffortQuests = {[aqId] = true}}
modules.IsleOfQuelDanas = {quests = {}}
modules.QuestieLib = {GetSpawnDistance = function() return 100 end}
GetQuestGreenRange = function() return 5 end

local optionsSource = assert(io.open("Modules/Options/QuestieOptionsDefaults.lua", "rb")):read("*a")
assert(optionsSource:match("showAQWarEffortQuests%s*=%s*false"),
    "review the original AQ War Effort default before interpreting this test")
assert(loadfile("Modules/Quest/AvailableQuests.lua"))()
local actual = assert(modules.AvailableQuests.CalculateAndDrawAll)

local checks = 0
local function check(label, ok)
    checks = checks + 1
    assert(ok, "FAIL Part52 " .. checks .. " " .. label)
    print("PASS Part52 " .. checks .. " " .. label)
end
local function calculate()
    drawn, tips = {}, {}
    levelCalls, doableCalls = 0, 0
    modules.QuestieMap.questIdFrames = {}
    actual()
end

-- AQ classified ID is present in the effective index and the raw table.
-- Default off skips the record BEFORE eligibility, without implying its absence.
calculate()
check("AQ disabled => no NEW map marker emitted", #drawn == 0 and #tips == 0)
check("AQ disabled => level/doability not checked", levelCalls == 0 and doableCalls == 0)

Questie.db.profile.showAQWarEffortQuests = true
calculate()
check("AQ enabled => indexed eligible quest receives a pin",
    #drawn == 1 and drawn[1].id == aqId and #tips == 1)
check("AQ enabled => eligibility was checked", levelCalls == 1 and doableCalls == 1)

-- The AQ-specific toggle must not mask ordinary Vanilla quest starts.
Questie.db.profile.showAQWarEffortQuests = false
modules.QuestieDB.QuestPointers = {[aqId] = 1, [normalId] = 1}
calculate()
check("AQ off leaves non-AQ quest in the newly drawn set",
    #drawn == 1 and drawn[1].id == normalId)
check("non-AQ alone reaches eligibility", levelCalls == 1 and doableCalls == 1)

-- Character-specific hidden flags are independent of data and AQ settings.
modules.QuestieDB.QuestPointers = {[normalId] = 1}
Questie.db.char.hidden[normalId] = true
calculate()
check("manually hidden existing normal quest has no new marker", #drawn == 0)
check("manually hidden existing normal quest is skipped early",
    levelCalls == 0 and doableCalls == 0)
Questie.db.char.hidden[normalId] = nil

-- The scan intentionally selects *either* QuestPointers *or* raw questData.
-- A raw source row not included in effective QuestPointers is not enumerated.
modules.QuestieDB.QuestPointers = {}
calculate()
check("raw source quest without compiled index entry is not scanned",
    #drawn == 0 and levelCalls == 0 and doableCalls == 0)

-- Confirm the scan's specified fallback is different when no compiled
-- pointer table exists. This is a mock path, NOT proof of live cache recovery.
modules.QuestieDB.questData = {[rawOnlyId] = quests[rawOnlyId]}
modules.QuestieDB.QuestPointers = nil
calculate()
check("when pointer table absent, raw fallback scans invented quest",
    #drawn == 1 and drawn[1].id == rawOnlyId)

-- An indexed quest still needs IsDoable; our mock says it is ineligible.
modules.QuestieDB.QuestPointers = {[normalId] = 1}
allowDoable = false
calculate()
check("indexed but ineligible quest is not newly drawn", #drawn == 0)
check("ineligibility is reached after level check",
    levelCalls == 1 and doableCalls == 1)

print("ALL " .. checks .. " PART52 SOURCE-EXECUTED SYNTHETIC SCAN CHECKS PASS; "
    .. " no native client, effective real quest ID, current profile, cleanup, "
    .. " private SQL or IP availability was tested.")
