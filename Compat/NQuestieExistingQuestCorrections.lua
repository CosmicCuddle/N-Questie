-- Reviewed server-specific correction for an EXISTING 3.3.5a quest.
-- Source: private read-only acore_world export (14 October 2026).
-- Only approved field-level changes are emitted. All quest levels, NPC links,
-- prerequisites and non-item objectives remain inherited from Questie.
if not (QuestieCompat and QuestieCompat.Is335 and QuestieCompat.RegisterCorrection) then
    return
end

local QuestieDB = QuestieLoader:ImportModule("QuestieDB")

QuestieCompat.RegisterCorrection("questData", function()
    local keys = QuestieDB.questKeys
    local quest = QuestieDB.questData and QuestieDB.questData[1203]
    if type(quest) ~= "table" then return {} end

    local oldObjectives = quest[keys.objectives]
    if type(oldObjectives) ~= "table" then return {} end
    local itemObjectives = oldObjectives[3]
    if type(itemObjectives) ~= "table" or #itemObjectives ~= 1 then return {} end
    local oldItem = itemObjectives[1]
    if type(oldItem) ~= "table" or oldItem[1] ~= 33110 then
        -- Do not erase a later Questie/server correction with unexpected values.
        return {}
    end

    local objectives = {}
    for slot, value in pairs(oldObjectives) do
        objectives[slot] = value
    end

    -- Quest 1203: Classic-era server requires one crafted Moonsteel Broadsword,
    -- not the WotLK Razorspine's Sword item objective.
    objectives[3] = {{3853}}

    return {
        [1203] = {
            [keys.objectives] = objectives,
            [keys.objectivesText] = {
                "Bring a Moonsteel Broadsword to Jarl in Dustwallow Marsh.",
            },
        },
    }
end)
