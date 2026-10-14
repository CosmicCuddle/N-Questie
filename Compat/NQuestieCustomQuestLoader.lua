-- Isolated Naxxramas Questie corrections. Loaded after the Questie DB keys
-- and WotLK correction modules, but before QuestieInit compiles the database.
-- Targets only 3.3.5a. Existing Questie code/IDs are never replaced in bulk.
if not (QuestieCompat and QuestieCompat.Is335 and QuestieCompat.RegisterCorrection) then
    return
end

local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
local custom = NQuestieCustomQuestData
if type(custom) ~= "table" or type(custom.quests) ~= "table" then
    return
end

local function uniqueAppend(existing, addition)
    local output, seen = {}, {}
    if type(existing) == "table" then
        for _, id in ipairs(existing) do
            if not seen[id] then
                output[#output + 1] = id
                seen[id] = true
            end
        end
    end
    for _, id in ipairs(addition) do
        if not seen[id] then
            output[#output + 1] = id
            seen[id] = true
        end
    end
    return output
end

local function isId(id)
    return type(id) == "number" and id > 0 and id == math.floor(id)
end

local function validIdList(list)
    if type(list) ~= "table" then return false end
    for _, id in ipairs(list) do
        if not isId(id) then return false end
    end
    return true
end

local function validQuest(id, q)
    return isId(id) and type(q) == "table" and
        type(q.name) == "string" and q.name ~= "" and
        type(q.requiredLevel) == "number" and q.requiredLevel >= 0 and
        q.requiredLevel == math.floor(q.requiredLevel) and
        isId(q.questLevel) and
        type(q.zoneOrSort) == "number" and q.zoneOrSort == math.floor(q.zoneOrSort) and
        type(q.requiredRaces) == "number" and q.requiredRaces >= 0 and
        q.requiredRaces == math.floor(q.requiredRaces) and
        type(q.questFlags) == "number" and q.questFlags >= 0 and
        q.questFlags == math.floor(q.questFlags) and
        validIdList(q.startedByNpcs) and #q.startedByNpcs > 0 and
        validIdList(q.finishedByNpcs) and #q.finishedByNpcs > 0 and
        validIdList(q.killNpcs) and
        (q.preQuestSingle == nil or validIdList(q.preQuestSingle))
end

QuestieCompat.RegisterCorrection("questData", function()
    local keys, updates = QuestieDB.questKeys, {}
    for id, quest in pairs(custom.quests) do
        if validQuest(id, quest) then
            local startNpc, endNpc = {}, {}
            for _, npc in ipairs(quest.startedByNpcs) do startNpc[#startNpc + 1] = npc end
            for _, npc in ipairs(quest.finishedByNpcs) do endNpc[#endNpc + 1] = npc end

            local fields = {
                [keys.name] = quest.name,
                [keys.requiredLevel] = quest.requiredLevel,
                [keys.questLevel] = quest.questLevel,
                [keys.zoneOrSort] = quest.zoneOrSort,
                [keys.requiredRaces] = quest.requiredRaces,
                [keys.questFlags] = quest.questFlags,
                [keys.startedBy] = {startNpc},
                [keys.finishedBy] = {endNpc},
            }
            if quest.preQuestSingle and #quest.preQuestSingle > 0 then
                fields[keys.preQuestSingle] = quest.preQuestSingle
            end
            if #quest.killNpcs > 0 then
                local kills = {}
                for _, npc in ipairs(quest.killNpcs) do
                    kills[#kills + 1] = {npc}
                end
                fields[keys.objectives] = {kills}
            end
            updates[id] = fields
        end
    end
    return updates
end)

-- Questie also indexes quest relations on the quest-giver NPC. Preserve
-- existing reverse links rather than overwriting unrelated vanilla quests.
QuestieCompat.RegisterCorrection("npcData", function()
    local keys, indexed = QuestieDB.npcKeys, {}
    local function link(npcId, questId, field)
        indexed[npcId] = indexed[npcId] or {starts = {}, ends = {}}
        indexed[npcId][field][#indexed[npcId][field] + 1] = questId
    end

    for questId, quest in pairs(custom.quests) do
        if validQuest(questId, quest) then
            for _, id in ipairs(quest.startedByNpcs) do link(id, questId, "starts") end
            for _, id in ipairs(quest.finishedByNpcs) do link(id, questId, "ends") end
        end
    end

    local updates = {}
    for npcId, relations in pairs(indexed) do
        local npc = QuestieDB.npcData and QuestieDB.npcData[npcId]
        if npc then
            updates[npcId] = {
                [keys.questStarts] = uniqueAppend(npc[keys.questStarts], relations.starts),
                [keys.questEnds] = uniqueAppend(npc[keys.questEnds], relations.ends),
            }
        end
        -- Missing NPCs require separately verified NPC/spawn data; do not
        -- invent NPC templates, zone IDs or map coordinates.
    end
    return updates
end)
