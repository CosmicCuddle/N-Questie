-- Isolated, fail-closed new quest corrections for the 3.3.5a client.
-- No server conditions, private quest records, or inferred source locations live here.
if not (QuestieCompat and QuestieCompat.Is335 and QuestieCompat.RegisterCorrection) then
    return
end

local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
local custom = NQuestieCustomQuestData
if type(custom) ~= "table" or type(custom.quests) ~= "table" then
    return
end

local MAX_ID = 16777215 -- Questie u24 quest/NPC/object/item references
local MAX_LIST = 255    -- Questie u8 list length

local allowedKeys = {
    name = true, requiredLevel = true, questLevel = true, zoneOrSort = true,
    requiredRaces = true, requiredClasses = true, questFlags = true,
    specialFlags = true, preQuestSingle = true, preQuestGroup = true,
    exclusiveTo = true, parentQuest = true, nextQuestInChain = true,
    startedByNpcs = true, finishedByNpcs = true, startedByItems = true,
    startedByGameObjects = true, finishedByGameObjects = true,
    killNpcs = true, objectObjectives = true, itemObjectives = true,
    noDirectObjectives = true,
}

local function integerInRange(value, minimum, maximum)
    return type(value) == "number" and value >= minimum and
        value <= maximum and value == math.floor(value)
end

-- ipairs alone silently skips holes and unexpected dictionary keys.
local function denseIdList(value)
    if value == nil then return {} end
    if type(value) ~= "table" then return nil end
    local size, seen = 0, {}
    for key, id in pairs(value) do
        if not integerInRange(key, 1, MAX_LIST) or
            not integerInRange(id, 1, MAX_ID) or seen[id] then
            return nil
        end
        size = size + 1
        seen[id] = true
    end
    for index = 1, size do
        if value[index] == nil then return nil end
    end
    local output = {}
    for index = 1, size do output[index] = value[index] end
    return output
end

local function hasId(db, id)
    return type(db) == "table" and type(db[id]) == "table"
end

local function allResolve(list, db)
    for _, id in ipairs(list) do
        if not hasId(db, id) then return false end
    end
    return true
end

local function uniqueAppend(existing, addition)
    local output, seen = {}, {}
    for _, list in ipairs({existing or {}, addition}) do
        for _, id in ipairs(list) do
            if not seen[id] then
                if #output == MAX_LIST then return nil end
                output[#output + 1] = id
                seen[id] = true
            end
        end
    end
    return output
end

local listKeys = {
    "startedByNpcs", "finishedByNpcs", "startedByGameObjects",
    "startedByItems",
    "finishedByGameObjects", "killNpcs", "objectObjectives",
    "itemObjectives", "preQuestSingle", "preQuestGroup", "exclusiveTo",
}

-- The previously released public record can replace its existing effective
-- correction. It has a specific, fixed fingerprint; no arbitrary collision is
-- permitted, including future new records using this reserved ID.
-- The deployed public 2001 record is frozen, not just approximately identified.
-- No unrelated source fields may ride through its grandfathered collision path.
local public2001Keys = {
    name = true, requiredLevel = true, questLevel = true,
    zoneOrSort = true, requiredRaces = true, questFlags = true,
    preQuestSingle = true, startedByNpcs = true,
    finishedByNpcs = true, killNpcs = true,
}

local function sameDenseIds(list, expected)
    local actual = denseIdList(list)
    if not actual or #actual ~= #expected then return false end
    for index = 1, #expected do
        if actual[index] ~= expected[index] then return false end
    end
    return true
end

local function isPublic2001(id, q)
    if id ~= 2001 or type(q) ~= "table" then return false end
    for key in pairs(q) do
        if not public2001Keys[key] then return false end
    end
    for key in pairs(public2001Keys) do
        if q[key] == nil then return false end
    end
    return q.name == "Ravenclaw Cleanup" and
        q.requiredLevel == 12 and q.questLevel == 16 and
        q.zoneOrSort == 130 and q.requiredRaces == 690 and q.questFlags == 8 and
        sameDenseIds(q.startedByNpcs, {2121}) and
        sameDenseIds(q.finishedByNpcs, {2121}) and
        sameDenseIds(q.killNpcs, {1868, 1869}) and
        sameDenseIds(q.preQuestSingle, {437})
end

local function parseQuest(id, q)
    if not integerInRange(id, 1, MAX_ID) or type(q) ~= "table" then return nil end
    -- Enforce the exact public baseline whether or not another source
    -- happens to contain the same numeric ID.
    if id == 2001 and not isPublic2001(id, q) then return nil end
    -- Existing quest field corrections use a distinct reviewed path. Preserve
    -- only the exact existing public custom record 2001 as a narrow exception.
    if QuestieDB.questData and QuestieDB.questData[id] ~= nil and
        not isPublic2001(id, q) then return nil end
    for key in pairs(q) do
        if not allowedKeys[key] then return nil end
    end
    if type(q.name) ~= "string" or #q.name == 0 or #q.name > 255 or q.name == "nil" then return nil end
    if not integerInRange(q.requiredLevel, 0, 255) or
        not (q.questLevel == -1 or integerInRange(q.questLevel, 1, 32767)) or
        not integerInRange(q.zoneOrSort, -32767, 32767) or
        not integerInRange(q.requiredRaces, 0, 65535) or
        not integerInRange(q.questFlags, 0, MAX_ID) or
        (q.requiredClasses ~= nil and not integerInRange(q.requiredClasses, 0, 65535)) or
        (q.specialFlags ~= nil and q.specialFlags ~= 0 and q.specialFlags ~= 1) then
        return nil
    end
    if q.noDirectObjectives ~= nil and q.noDirectObjectives ~= true then return nil end
    if q.parentQuest ~= nil and not integerInRange(q.parentQuest, 1, MAX_ID) then return nil end
    if q.nextQuestInChain ~= nil and not integerInRange(q.nextQuestInChain, 1, MAX_ID) then return nil end

    local entry = {id = id, data = q}
    for _, key in ipairs(listKeys) do
        entry[key] = denseIdList(q[key])
        if not entry[key] then return nil end
    end
    if #entry.startedByNpcs + #entry.startedByGameObjects + #entry.startedByItems == 0 or
        #entry.finishedByNpcs + #entry.finishedByGameObjects == 0 then return nil end
    if not allResolve(entry.startedByNpcs, QuestieDB.npcData) or
        not allResolve(entry.finishedByNpcs, QuestieDB.npcData) or
        not allResolve(entry.startedByItems, QuestieDB.itemData) or
        not allResolve(entry.startedByGameObjects, QuestieDB.objectData) or
        not allResolve(entry.finishedByGameObjects, QuestieDB.objectData) or
        not allResolve(entry.killNpcs, QuestieDB.npcData) or
        not allResolve(entry.objectObjectives, QuestieDB.objectData) or
        not allResolve(entry.itemObjectives, QuestieDB.itemData) then
        return nil
    end
    -- Questie matches static objectives to client quest-log objectives by
    -- position. Until the actual 3.3.5a mixed-type order is verified, hold
    -- records spanning more than one objective category.
    local objectiveKinds = 0
    for _, field in ipairs({"killNpcs", "objectObjectives", "itemObjectives"}) do
        if #entry[field] > 0 then objectiveKinds = objectiveKinds + 1 end
    end
    if objectiveKinds > 1 then return nil end
    if #entry.killNpcs + #entry.objectObjectives + #entry.itemObjectives == 0 and
        q.noDirectObjectives ~= true then return nil end
    if #entry.killNpcs + #entry.objectObjectives + #entry.itemObjectives > 0 and
        q.noDirectObjectives == true then return nil end
    return entry
end

-- Verify new records against the existing source database without assuming
-- correction callback execution order (which uses pairs, not ipairs).
local approved
local function approvedQuests()
    if approved then return approved end
    approved = {}
    for id, q in pairs(custom.quests) do
        local entry = parseQuest(id, q)
        if entry then approved[id] = entry end
    end

    -- Remove unresolved dependencies and all dependants until stable.
    local function exists(id)
        return hasId(QuestieDB.questData, id) or approved[id] ~= nil
    end
    local function resolved(entry)
        for _, field in ipairs({"preQuestSingle", "preQuestGroup", "exclusiveTo"}) do
            for _, reference in ipairs(entry[field]) do
                if reference == entry.id or (not exists(reference) and
                    not (isPublic2001(entry.id, entry.data) and reference == 437)) then
                    return false
                end
            end
        end
        for _, field in ipairs({"parentQuest", "nextQuestInChain"}) do
            local reference = entry.data[field]
            if reference ~= nil and (reference == entry.id or not exists(reference)) then return false end
        end
        return true
    end
    local changed = true
    while changed do
        changed = false
        for id, entry in pairs(approved) do
            if not resolved(entry) then
                approved[id] = nil
                changed = true
            end
        end
    end

    -- Prerequisite cycles are impossible to fulfil. Exclusions are deliberately
    -- omitted here because mutual exclusions are expected to be symmetric.
    local visiting, visited, inCycle = {}, {}, {}
    local function markCycles(id, stack)
        if visiting[id] then
            for index = #stack, 1, -1 do
                inCycle[stack[index]] = true
                if stack[index] == id then break end
            end
            return
        end
        if visited[id] then return end
        local entry = approved[id]
        if not entry then return end
        visiting[id] = true
        stack[#stack + 1] = id
        for _, key in ipairs({"preQuestSingle", "preQuestGroup"}) do
            for _, ref in ipairs(entry[key]) do
                if approved[ref] then markCycles(ref, stack) end
            end
        end
        if entry.data.parentQuest and approved[entry.data.parentQuest] then
            markCycles(entry.data.parentQuest, stack)
        end
        stack[#stack] = nil
        visiting[id] = nil
        visited[id] = true
    end
    for id in pairs(approved) do markCycles(id, {}) end
    for id in pairs(inCycle) do approved[id] = nil end
    if next(inCycle) then
        changed = true
        while changed do
            changed = false
            for id, entry in pairs(approved) do
                if not resolved(entry) then approved[id] = nil; changed = true end
            end
        end
    end

    -- Check the *combined* index additions, not one quest at a time. A full
    -- source index rejects every proposed addition to that source, never a
    -- partial set which could leave questData and reverse indexes inconsistent.
    local function pruneOverfull(kind, keys, starter, finisher)
        local indexed = {}
        for questId, entry in pairs(approved) do
            for _, pair in ipairs({
                {entry[starter], "starts"}, {entry[finisher], "ends"},
            }) do
                for _, sourceId in ipairs(pair[1]) do
                    indexed[sourceId] = indexed[sourceId] or {starts = {}, ends = {}}
                    local ids = indexed[sourceId][pair[2]]
                    ids[#ids + 1] = questId
                end
            end
        end
        local discarded = false
        for sourceId, additions in pairs(indexed) do
            local source = QuestieDB[kind][sourceId]
            if not uniqueAppend(source[keys.questStarts], additions.starts) or
                not uniqueAppend(source[keys.questEnds], additions.ends) then
                for _, id in ipairs(additions.starts) do approved[id] = nil end
                for _, id in ipairs(additions.ends) do approved[id] = nil end
                discarded = true
            end
        end
        return discarded
    end
    -- Item startQuest is a SINGLE u24 value, not a u8 questStarts array.
    -- Never assign two proposed quests to one item or overwrite an existing
    -- item startQuest. Reject all participants in the contested source,
    -- rather than picking whichever pairs() callback happens to run first.
    local function pruneItemStarterConflicts()
        local claimedBy, rejectedItem = {}, {}
        for questId, entry in pairs(approved) do
            for _, itemId in ipairs(entry.startedByItems) do
                local item = QuestieDB.itemData[itemId]
                local previous = item[QuestieDB.itemKeys.startQuest]
                if (previous ~= nil and previous ~= questId) or
                    (claimedBy[itemId] ~= nil and claimedBy[itemId] ~= questId) then
                    rejectedItem[itemId] = true
                end
                claimedBy[itemId] = questId
            end
        end
        local didPrune = false
        for questId, entry in pairs(approved) do
            for _, itemId in ipairs(entry.startedByItems) do
                if rejectedItem[itemId] then
                    approved[questId] = nil
                    didPrune = true
                    break
                end
            end
        end
        return didPrune
    end
    changed = true
    while changed do
        changed = false
        if pruneOverfull("npcData", QuestieDB.npcKeys,
                "startedByNpcs", "finishedByNpcs") then changed = true end
        if pruneOverfull("objectData", QuestieDB.objectKeys,
                "startedByGameObjects", "finishedByGameObjects") then changed = true end
        if pruneItemStarterConflicts() then changed = true end
        for id, entry in pairs(approved) do
            if not resolved(entry) then approved[id] = nil; changed = true end
        end
    end
    return approved
end

local function objectivePairs(ids)
    local output = {}
    for _, id in ipairs(ids) do output[#output + 1] = {id} end
    return output
end

QuestieCompat.RegisterCorrection("questData", function()
    local keys, updates = QuestieDB.questKeys, {}
    for id, entry in pairs(approvedQuests()) do
        local q = entry.data
        local fields = {
            [keys.name] = q.name,
            [keys.requiredLevel] = q.requiredLevel,
            [keys.questLevel] = q.questLevel,
            [keys.zoneOrSort] = q.zoneOrSort,
            [keys.requiredRaces] = q.requiredRaces,
            [keys.questFlags] = q.questFlags,
            [keys.startedBy] = {entry.startedByNpcs},
            [keys.finishedBy] = {entry.finishedByNpcs},
        }
        if #entry.startedByGameObjects > 0 then
            fields[keys.startedBy][2] = entry.startedByGameObjects
        end
        if #entry.startedByItems > 0 then
            fields[keys.startedBy][3] = entry.startedByItems
        end
        if #entry.finishedByGameObjects > 0 then
            fields[keys.finishedBy][2] = entry.finishedByGameObjects
        end
        if q.requiredClasses ~= nil then fields[keys.requiredClasses] = q.requiredClasses end
        if q.specialFlags ~= nil then fields[keys.specialFlags] = q.specialFlags end
        for _, field in ipairs({"preQuestSingle", "preQuestGroup", "exclusiveTo"}) do
            if #entry[field] > 0 then fields[keys[field]] = entry[field] end
        end
        if q.parentQuest then fields[keys.parentQuest] = q.parentQuest end
        if q.nextQuestInChain then fields[keys.nextQuestInChain] = q.nextQuestInChain end
        if #entry.killNpcs + #entry.objectObjectives + #entry.itemObjectives > 0 then
            local objectives = {objectivePairs(entry.killNpcs)}
            if #entry.objectObjectives > 0 or #entry.itemObjectives > 0 then
                objectives[2] = objectivePairs(entry.objectObjectives)
            end
            if #entry.itemObjectives > 0 then
                objectives[3] = objectivePairs(entry.itemObjectives)
            end
            fields[keys.objectives] = objectives
        end
        updates[id] = fields
    end
    return updates
end)

local function relationUpdates(kind, startKey, endKey, sourceKey1, sourceKey2)
    local indexed = {}
    local function add(sourceId, questId, which)
        indexed[sourceId] = indexed[sourceId] or {starts = {}, ends = {}}
        local relations = indexed[sourceId][which]
        relations[#relations + 1] = questId
    end
    for questId, entry in pairs(approvedQuests()) do
        for _, id in ipairs(entry[sourceKey1]) do add(id, questId, "starts") end
        for _, id in ipairs(entry[sourceKey2]) do add(id, questId, "ends") end
    end
    local updates = {}
    for sourceId, relations in pairs(indexed) do
        local source = QuestieDB[kind] and QuestieDB[kind][sourceId]
        if source then
            local starts = uniqueAppend(source[startKey], relations.starts)
            local ends = uniqueAppend(source[endKey], relations.ends)
            if starts and ends then
                updates[sourceId] = { [startKey] = starts, [endKey] = ends }
            end
        end
    end
    return updates
end

QuestieCompat.RegisterCorrection("npcData", function()
    local keys = QuestieDB.npcKeys
    return relationUpdates("npcData", keys.questStarts, keys.questEnds,
        "startedByNpcs", "finishedByNpcs")
end)

QuestieCompat.RegisterCorrection("objectData", function()
    local keys = QuestieDB.objectKeys
    return relationUpdates("objectData", keys.questStarts, keys.questEnds,
        "startedByGameObjects", "finishedByGameObjects")
end)

-- Item-started quests carry an itemData.startQuest scalar, unlike an item
-- objective or an NPC/GO questStarts array. All conflicting claims are
-- excluded by approvedQuests() before ANY callback emits corrections.
QuestieCompat.RegisterCorrection("itemData", function()
    local updates = {}
    local key = QuestieDB.itemKeys and QuestieDB.itemKeys.startQuest
    for questId, entry in pairs(approvedQuests()) do
        for _, itemId in ipairs(entry.startedByItems) do
            local record = QuestieDB.itemData[itemId]
            -- An approval computed by an earlier correction callback can
            -- become stale before the itemData callback executes. Failing
            -- explicitly is safer than silently leaving an orphaned
            -- quest.startedBy[3] → item.startQuest reverse relationship.
            -- This is only a callback-time guard: a later writer still
            -- requires an independent postflight before compilation.
            if not key or not record or
                (record[key] ~= nil and record[key] ~= questId) then
                error("N-Questie item starter source changed after approval; aborting corrections")
            end
            updates[itemId] = {[key] = questId}
        end
    end
    return updates
end)


-- Final targeted source check: run AFTER all corrections, gathering changes and
-- PreCompile, but BEFORE the existing binary compiler begins publication.
-- This checks only approved custom quest item-starter pairs: it is NOT a
-- comprehensive four-category source freeze or a coroutine-yielding safeguard.
-- Its failure is deliberately uncaught by Stage1 so the custom cache revision
-- cannot be advanced through a known-bad item-starter relationship.
function QuestieCompat.VerifyNQuestieCustomItemSources()
    local questKey = QuestieDB.questKeys and QuestieDB.questKeys.startedBy
    local itemKey = QuestieDB.itemKeys and QuestieDB.itemKeys.startQuest
    if not questKey or not itemKey then
        error("N-Questie item starter postflight missing source keys")
    end
    for questId, entry in pairs(approvedQuests()) do
        local expected = entry.startedByItems
        if #expected > 0 then
            local quest = QuestieDB.questData and QuestieDB.questData[questId]
            local starters = type(quest) == "table" and quest[questKey]
            local actual = type(starters) == "table" and denseIdList(starters[3])
            if not actual or #actual ~= #expected then
                error("N-Questie item starter postflight quest source mismatch")
            end
            -- The existing compiler can reorder arrays through pairs().
            -- Compare sets rather than assuming a stable Lua hash order.
            local seen = {}
            for _, itemId in ipairs(actual) do seen[itemId] = true end
            for _, itemId in ipairs(expected) do
                if not seen[itemId] then
                    error("N-Questie item starter postflight quest source mismatch")
                end
                local item = QuestieDB.itemData and QuestieDB.itemData[itemId]
                if type(item) ~= "table" or item[itemKey] ~= questId then
                    error("N-Questie item starter postflight item owner mismatch")
                end
            end
        end
    end
    return true
end
