-- Minimal existing-quest level corrections from a private, read-only
-- Naxxramas AzerothCore world export. Never commit that SQL archive.
-- These are NOT arbitrary quest color overrides: Questie's ordinary character-
-- relative difficulty calculation uses the corrected questLevel values.
if not (QuestieCompat and QuestieCompat.Is335 and QuestieCompat.RegisterCorrection) then
    return
end

local QuestieDB = QuestieLoader:ImportModule("QuestieDB")

-- questId = {expected Questie MinLevel, expected Questie QuestLevel,
--            verified server MinLevel, verified server QuestLevel}
-- Only alter fields that actually differ, after verifying the base values.
local verifiedLevels = {
    [1166] = {37, 41, 38, 43}, -- Overlord Mok'Morokk's Concern
    [1168] = {37, 41, 38, 43}, -- Army of the Black Dragon
    [1169] = {37, 41, 38, 43}, -- Identifying the Brood
    [1170] = {37, 41, 38, 43}, -- The Brood of Onyxia
    [1171] = {37, 41, 38, 43}, -- The Brood of Onyxia
    [1172] = {37, 41, 38, 45}, -- The Brood of Onyxia
    [1205] = {35, 41, 35, 45}, -- Deadmire
    [1252] = {30, 35, 30, 40}, -- Lieutenant Paval Reethe
}

QuestieCompat.RegisterCorrection("questData", function()
    local keys = QuestieDB.questKeys
    local database = QuestieDB.questData
    local updates = {}
    if type(database) ~= "table" then return updates end

    for id, levels in pairs(verifiedLevels) do
        local base = database[id]
        if type(base) == "table" and
           base[keys.requiredLevel] == levels[1] and
           base[keys.questLevel] == levels[2] then
            local fields = {}
            if levels[1] ~= levels[3] then
                fields[keys.requiredLevel] = levels[3]
            end
            if levels[2] ~= levels[4] then
                fields[keys.questLevel] = levels[4]
            end
            if next(fields) then updates[id] = fields end
        end
        -- A later upstream correction with different original values wins:
        -- never overwrite an unexpected or already updated Questie record.
    end
    return updates
end)
