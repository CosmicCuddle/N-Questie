-- N-Questie: individually reviewed early-zone existing quest level corrections.
-- Numeric values are taken from a private, read-only Naxxramas AzerothCore
-- acore_world quest_template comparison with the installed WotLK Questie DB.
-- This changes no objective, NPC, quest-chain, item or quest-condition fields.
-- The game's standard quest difficulty-color rules remain authoritative.
if not (QuestieCompat and QuestieCompat.Is335 and QuestieCompat.RegisterCorrection) then
    return
end

local QuestieDB = QuestieLoader:ImportModule("QuestieDB")

-- [quest ID] = {expected inherited min, expected inherited quest level,
--               server min, server quest level}
-- These 11 IDs have no literal quest-level override in inherited
-- Classic/TBC/WotLK Questie correction tables as reviewed 14 Oct 2026.
local verifiedLevels = {
    [98]   = {22, 32, 22, 35}, -- The Legend of Stalvan
    [126]  = {15, 21, 15, 25}, -- Howling in the Hills
    [169]  = {11, 26, 15, 26}, -- Wanted: Gath'Ilzogg
    [180]  = {11, 26, 15, 26}, -- Wanted: Lieutenant Fangore
    [249]  = {20, 26, 20, 27}, -- Morganth
    [256]  = {9, 22, 17, 22}, -- WANTED: Chok'sul
    [304]  = {26, 31, 26, 34}, -- A Grim Task
    [398]  = {4, 10, 6, 10}, -- Wanted: Maggot Eye
    [442]  = {10, 20, 10, 24}, -- Assault on Fenris Isle
    [895]  = {9, 16, 11, 16}, -- WANTED: Baron Longshore
    [6284] = {12, 21, 15, 21}, -- Arachnophobia
}

QuestieCompat.RegisterCorrection("questData", function()
    local keys = QuestieDB.questKeys
    local database = QuestieDB.questData
    local updates = {}
    if type(database) ~= "table" then return updates end

    for questId, values in pairs(verifiedLevels) do
        local existing = database[questId]
        if type(existing) == "table" and
           existing[keys.requiredLevel] == values[1] and
           existing[keys.questLevel] == values[2] then
            local fields = {}
            if values[1] ~= values[3] then
                fields[keys.requiredLevel] = values[3]
            end
            if values[2] ~= values[4] then
                fields[keys.questLevel] = values[4]
            end
            if next(fields) then updates[questId] = fields end
        end
        -- Fail closed if an upstream/server correction changes either original
        -- value; never overwrite unknown Questie data.
    end
    return updates
end)
