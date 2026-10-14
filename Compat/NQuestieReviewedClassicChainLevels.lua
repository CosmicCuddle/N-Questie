-- N-Questie: carefully reviewed quest-level differences in two Classic quest chains.
-- Private source: read-only AzerothCore quest_template export, 14 October 2026.
-- Existing quest / objective, chain, NPC/gameobject and item metadata remain inherited.
-- Quest difficulty colours remain Questie's normal character-relative calculation.
if not (QuestieCompat and QuestieCompat.Is335 and QuestieCompat.RegisterCorrection) then
    return
end

local QuestieDB = QuestieLoader:ImportModule("QuestieDB")

-- [questId] = {inherited minimum, inherited nominal level,
--              confirmed server minimum, confirmed server nominal level}
--
-- Duskwood: Mor'Ladim chain (gameobject gravestone at either end).
-- Quest 225 also has a literal TBC requiredLevel correction to the same value 25.
-- Do not modify starter/ender links or preQuestSingle / nextQuestInChain.
local verifiedLevels = {
    [225] = {25, 30, 28, 35}, -- The Weathered Grave
    [227] = {25, 30, 28, 35}, -- Morgan Ladimore
    [228] = {25, 30, 28, 35}, -- Mor'Ladim
    [229] = {25, 30, 28, 35}, -- The Daughter Who Lived
    [231] = {25, 30, 28, 35}, -- A Daughter's Love

    -- Wetlands: Report to Captain Stoutfist -> Defeat Nek'rosh.
    [473] = {23, 26, 23, 28}, -- Report to Captain Stoutfist
    [464] = {23, 26, 23, 28}, -- War Banners
    [465] = {23, 26, 23, 31}, -- Nek'rosh's Gambit
    [474] = {23, 26, 23, 32}, -- Defeat Nek'rosh
}

QuestieCompat.RegisterCorrection("questData", function()
    local keys = QuestieDB.questKeys
    local database = QuestieDB.questData
    local changes = {}
    if type(database) ~= "table" then return changes end

    for questId, expected in pairs(verifiedLevels) do
        local current = database[questId]
        if type(current) == "table" and
           current[keys.requiredLevel] == expected[1] and
           current[keys.questLevel] == expected[2] then
            local fields = {}
            if expected[1] ~= expected[3] then
                fields[keys.requiredLevel] = expected[3]
            end
            if expected[2] ~= expected[4] then
                fields[keys.questLevel] = expected[4]
            end
            if next(fields) then changes[questId] = fields end
        end
        -- Fail closed on unexpected or already changed inherited records.
    end
    return changes
end)
