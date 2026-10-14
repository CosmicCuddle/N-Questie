dofile("Modules/Libs/QuestieLoader.lua")

_G.bit = {band = function() return 0 end}
_G.GetTime = function() return 0 end

_G.QUEST_MONSTERS_KILLED = ""
_G.QUEST_ITEMS_NEEDED = ""
_G.QUEST_OBJECTS_FOUND = ""
_G.C_QuestLog = {IsQuestFlaggedCompleted = function() return false end}
_G.ExpandFactionHeader = function() end
_G.IsInGroup = function() return false end
_G.UnitInParty = function() return false end
_G.UnitInRaid = function() return false end
_G.UnitFactionGroup = function() return "Horde" end
_G.UnitName = function() return "Testi" end

_G.LibStub = function() return {} end

_G["Questie"] = {
    db = {
        char = {},
        profile = {},
    },
    Debug = function() end,
}

-- Current Questie modules access QuestieCompat when required. WoW normally
-- loads Compat/ files through the TOC, but standalone Busted has no WoW client.
-- Keep only explicit client API shims for the unit tests; never load this file
-- into the actual addon or silently change production compatibility behavior.
_G.QuestieCompat = {
    IsQuestFlaggedCompleted = function(...)
        return _G.C_QuestLog.IsQuestFlaggedCompleted(...)
    end,
    GetFactionInfo = function(...)
        return _G.GetFactionInfo(...)
    end,
    GetQuestsCompleted = function() return {} end,
    C_Timer = {},
    C_Map = {},
    HBD = {},
    xpcall = _G.xpcall,
    UnitInParty = function(...) return _G.UnitInParty(...) end,
    IsInGroup = function(...) return _G.IsInGroup(...) end,
    IsInRaid = function(...) return _G.UnitInRaid(...) end,
    GetClassColor = function() return 1, 1, 1 end,
    UnitRace = function() return "Orc", "Orc", 2 end,
    UnitClass = function() return "Warrior", "WARRIOR", 1 end,
    GetHomePartyInfo = function() return nil end,
    LE_PARTY_CATEGORY_INSTANCE = 2,
}
