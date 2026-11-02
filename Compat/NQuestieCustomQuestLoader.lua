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
    startedByNpcs = true, finishedByNpcs = true,
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
    if #entry.startedByNpcs + #entry.startedByGameObjects == 0 or
        #entry.finishedByNpcs + #entry.finishedByGameObjects == 0 then return nil end
    if not allResolve(entry.startedByNpcs, QuestieDB.npcData) or
        not allResolve(entry.finishedByNpcs, QuestieDB.npcData) or
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
-- Gate10 source provisioning. New quests may need NPC/object/item source rows
-- that the inherited database lacks. They are validated as one batch against
-- the effective (post-inherited-correction) tables and written only together,
-- before the quest list is first built; on any failure nothing is written.
local sourceSpecs = {
    npcs = {
        db = "npcData", keys = "npcKeys",
        fields = {name = "string", minLevel = "u8", maxLevel = "u8", rank = "rank",
            factionID = "u16", npcFlags = "u32", zoneID = "u16", spawns = "spawns"},
        required = {"name", "minLevel", "maxLevel", "zoneID", "spawns"},
    },
    objects = {
        db = "objectData", keys = "objectKeys",
        fields = {name = "string", zoneID = "u16", spawns = "spawns"},
        required = {"name", "zoneID", "spawns"},
    },
    items = {
        db = "itemData", keys = "itemKeys",
        fields = {name = "string", class = "u8", subClass = "u8",
            npcDrops = "ids", objectDrops = "ids"},
        required = {"name"},
    },
}
local sourceKinds = {"npcs", "objects", "items"}

local function validSpawns(value)
    if type(value) ~= "table" then return nil end
    local output, zones = {}, 0
    for zone, list in pairs(value) do
        if not integerInRange(zone, 1, 65535) or type(list) ~= "table" then return nil end
        zones = zones + 1
        if zones > MAX_LIST then return nil end
        local count = 0
        for _ in pairs(list) do count = count + 1 end
        if count == 0 or count > 65535 then return nil end
        local copy = {}
        for index = 1, count do
            local point = list[index]
            if type(point) ~= "table" or #point ~= 2 then return nil end
            local keys = 0
            for _ in pairs(point) do keys = keys + 1 end
            if keys ~= 2 then return nil end
            for _, c in ipairs(point) do
                if type(c) ~= "number" or c ~= c or c < 0 or c > 100 then return nil end
            end
            copy[index] = {point[1], point[2]}
        end
        output[zone] = copy
    end
    if zones == 0 then return nil end
    return output
end

local sourceValidators = {
    string = function(v)
        if type(v) == "string" and #v > 0 and #v <= 255 and v ~= "nil" then return v end
    end,
    u8 = function(v) if integerInRange(v, 0, 255) then return v end end,
    u16 = function(v) if integerInRange(v, 0, 65535) then return v end end,
    u32 = function(v) if integerInRange(v, 0, 4294967295) then return v end end,
    rank = function(v) if integerInRange(v, 0, 4) then return v end end,
    spawns = validSpawns,
    ids = function(v)
        local list = denseIdList(v)
        if list and #list > 0 then return list end
    end,
}

-- Returns the validated write set (possibly empty) and the pending ID sets,
-- or nil when anything in the batch is invalid or collides.
local function buildSourceBatch()
    local sources = custom.sources
    local pending = {npcs = {}, objects = {}, items = {}}
    if sources == nil then return {}, pending end
    if type(sources) ~= "table" then return nil end
    for kind in pairs(sources) do
        if not sourceSpecs[kind] then return nil end
    end
    local batch = {}
    for _, kind in ipairs(sourceKinds) do
        local spec, rows = sourceSpecs[kind], sources[kind]
        if rows ~= nil then
            local db, keys = QuestieDB[spec.db], QuestieDB[spec.keys]
            if type(rows) ~= "table" or type(db) ~= "table" or type(keys) ~= "table" then
                return nil
            end
            for id, row in pairs(rows) do
                if not integerInRange(id, 1, MAX_ID) or type(row) ~= "table" then return nil end
                if db[id] ~= nil then return nil end -- effective ID collision
                local record = {}
                for field, value in pairs(row) do
                    local check, key = spec.fields[field], keys[field]
                    if not check or type(key) ~= "number" then return nil end
                    local normalized = sourceValidators[check](value)
                    if normalized == nil then return nil end
                    record[key] = normalized
                end
                for _, field in ipairs(spec.required) do
                    if row[field] == nil then return nil end
                end
                if kind == "npcs" and row.minLevel > row.maxLevel then return nil end
                if kind == "items" and row.npcDrops == nil and row.objectDrops == nil then
                    return nil
                end
                batch[#batch + 1] = {kind = kind, db = spec.db, id = id, record = record, row = row}
                pending[kind][id] = true
            end
        end
    end
    for _, entry in ipairs(batch) do
        if entry.kind == "items" then
            for _, id in ipairs(entry.row.npcDrops or {}) do
                if not (pending.npcs[id] or hasId(QuestieDB.npcData, id)) then return nil end
            end
            for _, id in ipairs(entry.row.objectDrops or {}) do
                if not (pending.objects[id] or hasId(QuestieDB.objectData, id)) then return nil end
            end
        end
    end
    return batch, pending
end

local approved

-- Every provisioned source must be used by an approved quest (directly, or as
-- the drop source of a provisioned objective item) and every quest that uses a
-- provisioned source must be approved. Otherwise the batch is rolled back.
local function sourceBatchClosed(batch, pending)
    local used = {npcs = {}, objects = {}, items = {}}
    for id in pairs(custom.quests) do
        local entry = approved[id]
        local q = custom.quests[id]
        local touches = false
        for _, pair in ipairs({{"startedByNpcs", "npcs"}, {"finishedByNpcs", "npcs"},
                {"killNpcs", "npcs"}, {"startedByGameObjects", "objects"},
                {"finishedByGameObjects", "objects"}, {"objectObjectives", "objects"},
                {"itemObjectives", "items"}}) do
            local list = type(q) == "table" and denseIdList(q[pair[1]]) or nil
            for _, ref in ipairs(list or {}) do
                if pending[pair[2]][ref] then
                    touches = true
                    if entry then used[pair[2]][ref] = true end
                end
            end
        end
        if touches and not entry then return false end
    end
    for _, item in ipairs(batch) do
        if item.kind == "items" and used.items[item.id] then
            for _, id in ipairs(item.row.npcDrops or {}) do used.npcs[id] = true end
            for _, id in ipairs(item.row.objectDrops or {}) do used.objects[id] = true end
        end
    end
    for _, item in ipairs(batch) do
        if not used[item.kind][item.id] then return false end
    end
    return true
end

-- Quests that depend on the declared source batch: any reference to an ID
-- declared under `sources`. Collected best-effort from the raw declaration so
-- it also works when the batch itself is malformed. `all` is true when the
-- declaration is unreadable, in which case every custom quest except the
-- exact frozen public 2001 record is treated as dependent (fail closed).
local sourceRefFields = {{"startedByNpcs", "npcs"}, {"finishedByNpcs", "npcs"},
    {"killNpcs", "npcs"}, {"startedByGameObjects", "objects"},
    {"finishedByGameObjects", "objects"}, {"objectObjectives", "objects"},
    {"itemObjectives", "items"}}
local function batchDependentQuests()
    local sources, excluded = custom.sources, {}
    if sources == nil then return excluded end
    local declared = {npcs = {}, objects = {}, items = {}}
    local all = type(sources) ~= "table"
    if not all then
        for kind, rows in pairs(sources) do
            -- Unknown or malformed groups still mark their IDs as declared in
            -- every kind, so nothing that may depend on them slips through.
            if type(rows) == "table" then
                for id in pairs(rows) do
                    for _, set in pairs(declared) do
                        if declared[kind] == nil or set == declared[kind] then set[id] = true end
                    end
                end
            end
        end
    end
    for id, q in pairs(custom.quests) do
        if all then
            if not isPublic2001(id, q) then excluded[id] = true end
        elseif type(q) == "table" then
            for _, pair in ipairs(sourceRefFields) do
                for _, ref in ipairs(denseIdList(q[pair[1]]) or {}) do
                    if declared[pair[2]][ref] then excluded[id] = true end
                end
            end
        end
    end
    return excluded
end

local function computeApproved(excluded)
    approved = {}
    for id, q in pairs(custom.quests) do
        local entry = not (excluded and excluded[id]) and parseQuest(id, q) or nil
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
    changed = true
    while changed do
        changed = false
        if pruneOverfull("npcData", QuestieDB.npcKeys,
                "startedByNpcs", "finishedByNpcs") then changed = true end
        if pruneOverfull("objectData", QuestieDB.objectKeys,
                "startedByGameObjects", "finishedByGameObjects") then changed = true end
        for id, entry in pairs(approved) do
            if not resolved(entry) then approved[id] = nil; changed = true end
        end
    end
    return approved
end

-- Latched for the rest of this loader lifetime after any failed or
-- interrupted source batch, so a later callback never re-provisions or admits
-- the batch quests. Only a clean reload re-evaluates the batch from scratch.
local sourceBatchFailed = false

-- Admission without the batch-dependent quests. A fault here must not leave a
-- partial memo behind, so the memo is cleared before the error propagates.
local function approvedWithoutBatch()
    local ok, result = pcall(computeApproved, batchDependentQuests())
    if not ok then
        approved = nil
        error(result, 0)
    end
    return result
end

local function approvedQuests()
    if approved then return approved end
    if sourceBatchFailed then return approvedWithoutBatch() end
    local batch, pending = buildSourceBatch()
    if not batch then
        -- Fail closed: a failed batch (collision, invalid row, unresolved drop)
        -- writes nothing and rejects every quest depending on it, even if the
        -- referenced IDs happen to exist from another source.
        sourceBatchFailed = true
        return approvedWithoutBatch()
    end
    local written = {}
    local function rollback()
        for index = #written, 1, -1 do
            QuestieDB[written[index].db][written[index].id] = nil
        end
        written = {}
    end
    local ok, err = pcall(function()
        for _, entry in ipairs(batch) do
            QuestieDB[entry.db][entry.id] = entry.record
            written[#written + 1] = entry
        end
        computeApproved()
        if #written > 0 and not sourceBatchClosed(batch, pending) then
            rollback()
            sourceBatchFailed = true
            approved = nil
        end
    end)
    if not ok then
        -- Interrupted write or admission: undo every source row, latch the
        -- failure and re-raise.
        rollback()
        sourceBatchFailed = true
        approved = nil
        error(err, 0)
    end
    if sourceBatchFailed then return approvedWithoutBatch() end
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
