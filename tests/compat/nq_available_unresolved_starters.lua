-- Synthetic regression: unresolved available-quest starter lookup fails closed.
-- Loads the real production AvailableQuests.lua (not a copied function).
-- Only invented test IDs, in-memory source rows and mock UI dependencies.
-- No private server/SQL, client, SavedVariables, imports or addon packages.

local modules = {}
QuestieLoader = {
    CreateModule = function(_, name)
        modules[name] = modules[name] or {}
        return modules[name]
    end,
    ImportModule = function(_, name)
        assert(modules[name], "missing mock module " .. tostring(name))
        return modules[name]
    end,
}
local npcSources, goSources = {}, {}
local drawn, tooltips = {}, {}

Questie = {
    IsSoD = false,
    DEBUG_INFO = "INFO",
    db = {profile = {availableScale = 1.3}},
    ICON_TYPE_AVAILABLE = 1,
    ICON_TYPE_AVAILABLE_GRAY = 2,
    ICON_TYPE_REPEATABLE = 3,
    ICON_TYPE_PVPQUEST = 4,
    ICON_TYPE_EVENTQUEST = 5,
    ICON_TYPE_SODRUNE = 6,
    Debug = function() end,
}
modules.ThreadLib = {ThreadSimple = function(fn) fn() end}
modules.QuestieDB = {
    GetNPC = function(_, id) return npcSources[id] end,
    GetObject = function(_, id) return goSources[id] end,
    IsActiveEventQuest = function() return false end,
    IsPvPQuest = function() return false end,
    IsTrivial = function() return false end,
}
modules.ZoneDB = {
    GetDungeons = function() return {} end,
    GetDungeonLocation = function() return nil end,
}
modules.QuestiePlayer = {GetPlayerLevel = function() return 60 end}
modules.QuestieMap = {
    DrawWorldIcon = function(_, data, zone, x, y)
        local icon = {id = data.Id, zone = zone, x = x, y = y}
        drawn[#drawn + 1] = icon
        return icon
    end,
    DrawWaypoints = function() end,
}
modules.QuestieTooltips = {
    RegisterQuestStartTooltip = function(_, questId, name, sourceId, key)
        tooltips[#tooltips + 1] =
            {questId = questId, name = name, sourceId = sourceId, key = key}
    end,
}
modules.QuestieCorrections = {}
modules.QuestieQuestBlacklist = {AQWarEffortQuests = {}}
modules.IsleOfQuelDanas = {quests = {}}
modules.QuestieLib = {
    GetSpawnDistance = function() return 100 end,
}
GetQuestGreenRange = function() return 5 end

assert(loadfile("Modules/Quest/AvailableQuests.lua"))()
local renderer = assert(modules.AvailableQuests.DrawAvailableQuest,
    "actual available-quest renderer not registered")
local checks = 0
local function check(label, predicate)
    checks = checks + 1
    assert(predicate, "FAIL nil-starter " .. checks .. ": " .. label)
    print("PASS nil-starter " .. checks .. " " .. label)
end

local function run(starts)
    drawn, tooltips = {}, {}
    local ok, err = pcall(renderer, {
        Id = 920411,
        Starts = starts,
        requiredLevel = 10,
        level = 11,
        IsRepeatable = false,
    })
    return ok, err, drawn, tooltips
end

-- All IDs below are invented: deliberately unresolved source lookups.
local ok, err, icons, tips = run({NPC = {920421}})
check("missing NPC lookup does not abort whole quest render", ok)
check("missing NPC produces no fabricated pin or tooltip",
    #icons == 0 and #tips == 0)

ok, err, icons, tips = run({GameObject = {920431}})
check("missing GameObject lookup does not abort render", ok)
check("missing GameObject produces no fabricated pin or tooltip",
    #icons == 0 and #tips == 0)

npcSources[920422] = {
    id = 920422,
    name = "Invented valid NPC source",
    spawns = {[203] = {{24, 37}}},
}
goSources[920432] = {
    id = 920432,
    name = "Invented valid GO source",
    spawns = {[204] = {{45, 18}}},
}

ok, err, icons, tips = run({NPC = {920421, 920422}})
check("unresolved NPC does not mask subsequent valid NPC", ok)
check("subsequent valid NPC still draws correctly",
    #icons == 1 and icons[1].zone == 203
    and #tips == 1 and tips[1].key == "m_920422")

ok, err, icons, tips = run({GameObject = {920431, 920432}})
check("unresolved GameObject does not mask valid GO", ok)
check("subsequent valid GameObject still draws correctly",
    #icons == 1 and icons[1].zone == 204
    and #tips == 1 and tips[1].key == "o_920432")

ok, err, icons, tips = run({NPC = {920421}, GameObject = {920432}})
check("missing NPC does not hide an independent valid GO", ok)
check("valid GO remains visible when quest NPC starter is unresolved",
    #icons == 1 and #tips == 1 and tips[1].key == "o_920432")

ok, err, icons, tips = run({NPC = {920422}, GameObject = {920431}})
check("missing GO does not hide an independent valid NPC", ok)
check("valid NPC remains visible when GO starter is unresolved",
    #icons == 1 and #tips == 1 and tips[1].key == "m_920422")

-- Unexpected malformed source records also have no usable source ID;
-- do not invent a key from the caller's quest starter ID.
npcSources[920423] = {name = "Synthetic malformed NPC no id"}
goSources[920433] = {name = "Synthetic malformed GO no id"}
ok, err, icons, tips = run({NPC = {920423}, GameObject = {920433}})
check("source record lacking id never triggers concatenation error", ok)
check("source record lacking id produces no invented marker",
    #icons == 0 and #tips == 0)

ok, err, icons, tips = run({NPC = {920422}, GameObject = {920432}})
check("complete valid starters preserve existing behavior", ok)
check("valid mixed NPC+GO still draws both distinct icons",
    #icons == 2 and #tips == 2
    and tips[1].key == "o_920432" and tips[2].key == "m_920422")

print("ALL " .. checks .. " SYNTHETIC UNRESOLVED STARTER CHECKS PASS;"
    .. " live client/server eligibility, real coordinates NOT TESTED.")
