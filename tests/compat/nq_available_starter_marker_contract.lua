-- Synthetic available-quest starter-marker contract for WoW 3.3.5a.
-- Execute actual Modules/Quest/AvailableQuests.lua with isolated in-memory
-- sources. No Questie production source/data, private server export, SQL,
-- WoW client, SavedVariables or install/package action is involved.
--
-- Purpose: distinguish a present quest / resolvable NPC or GameObject ID
-- from a drawable starter location. No fabricated coordinates are allowed.

local modules = {}
QuestieLoader = {
    CreateModule = function(_, name)
        modules[name] = modules[name] or {}
        return modules[name]
    end,
    ImportModule = function(_, name)
        assert(modules[name], "missing synthetic module " .. tostring(name))
        return modules[name]
    end,
}
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
local drawn, tooltips, routes = {}, {}, {}
local sourcesNPC, sourcesGO, entrances = {}, {}, {}

modules.ThreadLib = {ThreadSimple = function(fn) fn() end}
modules.QuestieDB = {
    GetNPC = function(_, id) return sourcesNPC[id] end,
    GetObject = function(_, id) return sourcesGO[id] end,
    IsActiveEventQuest = function() return false end,
    IsPvPQuest = function() return false end,
    IsTrivial = function() return false end,
}
modules.ZoneDB = {
    GetDungeons = function() return {[900301] = true, [900302] = true} end,
    GetDungeonLocation = function(_, zone) return entrances[zone] end,
}
modules.QuestiePlayer = {GetPlayerLevel = function() return 60 end}
modules.QuestieMap = {
    DrawWorldIcon = function(_, data, zone, x, y)
        local icon = {id = data.Id, kind = data.Type, zone = zone, x = x, y = y}
        drawn[#drawn + 1] = icon
        return icon
    end,
    DrawWaypoints = function(_, icon, waypoints, zone)
        routes[#routes + 1] = {icon = icon, waypoints = waypoints, zone = zone}
    end,
}
modules.QuestieTooltips = {
    RegisterQuestStartTooltip = function(_, questId, name, sourceId, tooltipKey)
        tooltips[#tooltips + 1] =
            {questId = questId, name = name, sourceId = sourceId, key = tooltipKey}
    end,
}
modules.QuestieCorrections = {}
modules.QuestieQuestBlacklist = {AQWarEffortQuests = {}}
modules.IsleOfQuelDanas = {quests = {}}
modules.QuestieLib = {
    GetSpawnDistance = function(a, b)
        local dx, dy = a[1] - b[1], a[2] - b[2]
        return math.sqrt(dx * dx + dy * dy) * 100
    end,
}

-- Global helper used only by the uninvoked availability-scan path.
GetQuestGreenRange = function() return 5 end
assert(loadfile("Modules/Quest/AvailableQuests.lua"))()
local actual = assert(modules.AvailableQuests)
assert(type(actual.DrawAvailableQuest) == "function",
    "actual AvailableQuests.DrawAvailableQuest not loaded")

local checks = 0
local function check(message, ok)
    checks = checks + 1
    assert(ok, "FAIL starter marker " .. checks .. ": " .. message)
    print("PASS starter-marker " .. checks .. " " .. message)
end
local function draw(starts)
    drawn, tooltips, routes = {}, {}, {}
    actual.DrawAvailableQuest({
        Id = 920351,
        Starts = starts,
        requiredLevel = 10,
        level = 11,
        IsRepeatable = false,
    })
    return drawn, tooltips, routes
end

sourcesNPC[920361] = {id = 920361, name = "Invented NPC without spawn"}
local icons, tips, paths = draw({NPC = {920361}})
check("resolvable NPC without spawns registers starter tooltip",
    #tips == 1 and tips[1].sourceId == 920361)
check("resolvable NPC without spawns produces zero map pins",
    #icons == 0 and #paths == 0)

sourcesNPC[920362] =
    {id = 920362, name = "Invented NPC empty spawns", spawns = {}}
icons, tips, paths = draw({NPC = {920362}})
check("empty-spawn NPC has zero available-quest map pins",
    #icons == 0 and #paths == 0 and #tips == 1)

sourcesNPC[920363] = {
    id = 920363, name = "Invented NPC with a coordinate",
    spawns = {[201] = {{21, 34}}},
}
icons, tips, paths = draw({NPC = {920363}})
check("NPC with one known coordinate draws one available-quest pin",
    #icons == 1 and icons[1].zone == 201
    and icons[1].x == 21 and icons[1].y == 34)
check("locatable NPC retains correct source tooltip",
    #tips == 1 and tips[1].key == "m_920363")

sourcesGO[920371] = {
    id = 920371, name = "Invented GameObject with a coordinate",
    spawns = {[202] = {{42, 16}}},
}
icons, tips, paths = draw({GameObject = {920371}})
check("GameObject with one known coordinate draws one starter pin",
    #icons == 1 and icons[1].zone == 202
    and icons[1].x == 42 and icons[1].y == 16)
check("locatable GameObject retains GameObject tooltip key",
    #tips == 1 and tips[1].key == "o_920371")

sourcesGO[920372] = {
    id = 920372, name = "Invented GameObject without spawns",
}
icons, tips, paths = draw({GameObject = {920372}})
check("resolvable GameObject with no spawns yields no invented pin",
    #icons == 0 and #paths == 0 and #tips == 1)

sourcesNPC[920364] = {
    id = 920364, name = "Invented waypoint-only NPC",
    waypoints = {[203] = {{{19, 28}, {20, 29}}}},
}
icons, tips, paths = draw({NPC = {920364}})
check("real available-quest renderer creates a waypoint-derived starter pin",
    #icons == 1 and icons[1].zone == 203
    and icons[1].x == 19 and icons[1].y == 28)
check("waypoint-derived starter pin retains its route reference",
    #paths == 1 and paths[1].zone == 203
    and paths[1].icon == icons[1])

sourcesGO[920373] = {
    id = 920373, name = "Invented dungeon GO lacking mapped entrance",
    spawns = {[900301] = {{-1, -1}}},
}
icons, tips, paths = draw({GameObject = {920373}})
check("instance sentinel without entrance mapping does not fabricate a pin",
    #icons == 0 and #tips == 1)
entrances[900302] = {{204, 37, 44}}
sourcesGO[920374] = {
    id = 920374, name = "Invented GO with known dungeon entrance",
    spawns = {[900302] = {{-1, -1}}},
}
icons, tips, paths = draw({GameObject = {920374}})
check("instance sentinel with entrance mapping uses mapped location",
    #icons == 1 and icons[1].zone == 204
    and icons[1].x == 37 and icons[1].y == 44)

icons, tips, paths = draw({Item = {920381}})
check("item-only starter has no NPC/GO map or tooltip path in this renderer",
    #icons == 0 and #tips == 0 and #paths == 0)

icons, tips, paths = draw({NPC = {920363}, GameObject = {920371}})
check("multi-source NPC and GameObject each retain their own known pin",
    #icons == 2 and #tips == 2
    and tips[1].key == "o_920371" and tips[2].key == "m_920363")

print("ALL " .. checks .. " SYNTHETIC STARTER-MARKER CONTRACT CHECKS PASS;"
    .. " client eligibility, real world spawns and map alignment NOT TESTED.")
