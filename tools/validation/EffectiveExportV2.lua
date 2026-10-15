-- N-Questie M2 Stage A1: nq-m2-effective v2 record builder (in memory only).
--
-- Builds one v2 record per compiled quest from the POST-correction compiled
-- Questie database, read through a query function (normally
-- QuestieDB.QueryQuestSingle after compilation, exactly as the frozen v1
-- exporter reads it). Spec: docs/NQ-VALIDATION-M2-V2-EXPORTER-SPEC.md
-- sections 3-6.
--
-- Pure: no file or process I/O, nothing is written. Every value taken from
-- the query is copied into new tables, so the compiled data is never
-- aliased or mutated. Anything the spec does not describe fails closed with
-- a message naming the quest and field; nothing is trimmed, guessed or
-- silently dropped. Display text, coordinates and trigger-end contents are
-- deliberately outside v2 (spec section 1); RoundTripV2.Project counts them
-- so the exclusion is measured, not silent.
--
-- Lua 5.1 compatible.

local V1 = dofile("tools/validation/EffectiveExport.lua")

local M = {}
M.SCHEMA = "nq-m2-effective"
M.SCHEMA_VERSION = 2
M.DISPLAY_SCOPE = "structural-only"
M.MAX_ID = 2147483647
-- Compiled objective slots in Questie's ObjectiveData order (QuestieDB.GetQuest).
M.SLOTS = { "creature", "object", "item", "reputation", "killCredit", "spell" }
M.SLOT_OF = { creature = 1, object = 2, item = 3, reputation = 4, killCredit = 5, spell = 6 }
M.EXTRA_REF_TYPES = { monster = true, object = true, item = true }
M.KEYS = { "requiredLevel", "questLevel", "objectives", "sourceItemId", "requiredSourceItems", "triggerEnd", "extraObjectives" }

local function isInt(v) return type(v) == "number" and v == math.floor(v) and v == v end
local function posId(v) return isInt(v) and v >= 1 and v <= M.MAX_ID end

-- Plain list check: integer keys 1..n only.
local function isList(t)
    if type(t) ~= "table" then return false end
    local n = 0
    for k in pairs(t) do
        n = n + 1
        if not (isInt(k) and k >= 1) then return false end
    end
    return n == #t
end

local function sortedKeys(t)
    local ks = {}
    for k in pairs(t) do ks[#ks + 1] = k end
    table.sort(ks, function(a, b)
        if type(a) == type(b) then return a < b end
        return type(a) < type(b)
    end)
    return ks
end

-- Highest valid extra objectiveIndex for a record. Normally the number of
-- ordinary objectives n. n + 1 only when that quest-log line exists without
-- an ordinary objective: the triggerEnd event line (hasTriggerEnd), or a
-- client-only log line on a quest with no ordinary objectives (n == 0).
function M.MaxObjectiveIndex(rec)
    local n = #rec.objectives
    if n == 0 or rec.hasTriggerEnd then return n + 1 end
    return n
end

-- Context: the runtime killCreditObjectiveFirst set is required and must be
-- non-empty (fail closed, as exportContext() in validate-335).
function M.CheckContext(ctx)
    if type(ctx) ~= "table" or type(ctx.killCreditFirst) ~= "table" or next(ctx.killCreditFirst) == nil then
        return false, "context: killCreditObjectiveFirst set missing or empty (order cannot be reproduced)"
    end
    for k, v in pairs(ctx.killCreditFirst) do
        if not posId(k) or v ~= true then
            return false, "context: killCreditObjectiveFirst set has a non-quest key or non-true value"
        end
    end
    return true
end

-- Build the v2 record for quest `id`. Returns record, nil, v1record-or-nil
-- or nil, errors. The M1 classification is recomputed here with the frozen
-- v1 Record function (same codes as the coverage manifest), never copied
-- from a file.
function M.BuildRecord(query, id, ctx)
    local errs = {}
    local function err(msg) errs[#errs + 1] = "quest " .. tostring(id) .. ": " .. msg end
    if not posId(id) then return nil, { "quest " .. tostring(id) .. ": invalid quest ID" } end
    if type(query) ~= "function" then return nil, { "quest " .. id .. ": query function required" } end
    local okc, cerr = M.CheckContext(ctx)
    if not okc then return nil, { "quest " .. id .. ": " .. cerr } end

    local raw = {}
    for _, key in ipairs(M.KEYS) do
        local ok, v = pcall(query, id, key)
        if not ok then err("query for " .. key .. " failed (QUERY_FAILED)") else raw[key] = v end
    end
    if #errs > 0 then return nil, errs end

    local rec = { ID = id }
    -- Levels: raw integers; questLevel -1 means scaling.
    if not (isInt(raw.requiredLevel) and raw.requiredLevel >= 0 and raw.requiredLevel <= 255) then
        err("requiredLevel " .. tostring(raw.requiredLevel) .. " is not an integer 0-255")
    end
    if not (isInt(raw.questLevel) and raw.questLevel >= -1 and raw.questLevel <= 255) then
        err("questLevel " .. tostring(raw.questLevel) .. " is not an integer -1-255")
    end
    rec.requiredLevel, rec.questLevel = raw.requiredLevel, raw.questLevel

    -- sourceItemId: raw value, 0 when absent.
    local src = raw.sourceItemId
    if src == nil then src = 0 end
    if not (isInt(src) and src >= 0 and src <= M.MAX_ID) then err("sourceItemId " .. tostring(src) .. " invalid") end
    rec.sourceItemId = src

    -- requiredSourceItems: every entry in compiled order, repeats kept.
    rec.requiredSourceItems = {}
    if raw.requiredSourceItems ~= nil then
        if not isList(raw.requiredSourceItems) then err("requiredSourceItems is not a plain list")
        else
            for i, v in ipairs(raw.requiredSourceItems) do
                if not posId(v) then err("requiredSourceItems[" .. i .. "] is not a positive ID") end
                rec.requiredSourceItems[i] = v
            end
        end
    end

    -- Objectives, slot by slot.
    local slots = {}
    local obj = raw.objectives
    if obj ~= nil then
        if type(obj) ~= "table" then err("objectives is not a table"); obj = {} end
        for k in pairs(obj) do
            if not (isInt(k) and k >= 1 and k <= 6) then err("objectives has unknown slot " .. tostring(k)) end
        end
        for s = 1, 6 do
            local list = obj[s]
            local kind = M.SLOTS[s]
            slots[kind] = {}
            if list ~= nil then
                if type(list) ~= "table" then err("objectives[" .. s .. "] is not a table")
                elseif kind == "reputation" then
                    for k, v in pairs(list) do
                        if not (k == 1 or k == 2) then err("objectives[4] reputation has unknown field " .. tostring(k)) end
                        if type(v) == "table" then err("objectives[4] reputation is not a single {factionId, value} pair") end
                    end
                    if next(list) ~= nil then
                        if not posId(list[1]) then err("objectives[4] factionId " .. tostring(list[1]) .. " invalid") end
                        if not isInt(list[2]) then err("objectives[4] requiredValue " .. tostring(list[2]) .. " missing or not an integer (0 is a real value)") end
                        slots.reputation[1] = { factionId = list[1], requiredValue = list[2] }
                    end
                elseif not isList(list) then err("objectives[" .. s .. "] is not a plain list")
                else
                    for i, e in ipairs(list) do
                        local w = "objectives[" .. s .. "][" .. i .. "]"
                        if type(e) ~= "table" then err(w .. " is not a table")
                        elseif kind == "killCredit" then
                            for k, v in pairs(e) do
                                if not (k == 1 or k == 2 or (k == 3 and type(v) == "string")) then err(w .. " killCredit has unknown field " .. tostring(k)) end
                            end
                            local ids = {}
                            if not (isList(e[1]) and #e[1] > 0) then err(w .. " killCredit ids must be a non-empty list")
                            else
                                for j, v in ipairs(e[1]) do
                                    if not posId(v) then err(w .. " killCredit ids[" .. j .. "] invalid") end
                                    ids[j] = v
                                end
                            end
                            if not posId(e[2]) then err(w .. " killCredit rootId invalid") end
                            slots.killCredit[i] = { ids = ids, rootId = e[2], hasText = e[3] ~= nil }
                        else
                            for k, v in pairs(e) do
                                local okField = k == 1 or (k == 2 and type(v) == "string") or (kind == "spell" and k == 3)
                                if not okField then err(w .. " has unknown field " .. tostring(k)) end
                            end
                            if not posId(e[1]) then err(w .. " id " .. tostring(e[1]) .. " invalid") end
                            local entry = { id = e[1], hasText = e[2] ~= nil }
                            if kind == "spell" and e[3] ~= nil then
                                if not posId(e[3]) then err(w .. " spell itemSourceId invalid") end
                                entry.itemSourceId = e[3]
                            end
                            slots[kind][i] = entry
                        end
                    end
                end
            end
        end
    else
        for _, kind in ipairs(M.SLOTS) do slots[kind] = {} end
    end

    local kcfFlag = ctx.killCreditFirst[id] == true
    rec.killCreditFirst = kcfFlag and #slots.killCredit > 0

    -- Questie ObjectiveData order: append in slot order; with killCreditFirst
    -- every killCredit entry is inserted at position 1 (so they end up first,
    -- reversed). Occurrence numbers repeats of the same id within a kind.
    local list, occ = {}, {}
    for _, kind in ipairs(M.SLOTS) do
        for si, e in ipairs(slots[kind]) do
            local o = { kind = kind, slotIndex = si }
            if kind == "reputation" then
                o.factionId, o.requiredValue = e.factionId, e.requiredValue
            elseif kind == "killCredit" then
                o.ids, o.rootId = e.ids, e.rootId
            else
                o.id = e.id
                local key = kind .. ":" .. tostring(e.id)
                occ[key] = (occ[key] or 0) + 1
                o.occurrence = occ[key]
                if e.itemSourceId ~= nil then o.itemSourceId = e.itemSourceId end
            end
            if kind == "killCredit" and rec.killCreditFirst then table.insert(list, 1, o) else list[#list + 1] = o end
        end
    end
    for i, o in ipairs(list) do o.position = i end
    rec.objectives = list

    -- triggerEnd: presence only (contents are display data).
    if raw.triggerEnd ~= nil and type(raw.triggerEnd) ~= "table" then err("triggerEnd is not a table") end
    rec.hasTriggerEnd = raw.triggerEnd ~= nil

    -- extraObjectives: every entry, every reference, compiled order.
    rec.extraObjectives = {}
    local ex = raw.extraObjectives
    if ex ~= nil then
        if not isList(ex) then err("extraObjectives is not a plain list")
        else
            for i, e in ipairs(ex) do
                local w = "extraObjectives[" .. i .. "]"
                if type(e) ~= "table" then err(w .. " is not a table")
                else
                    for k in pairs(e) do
                        if not (isInt(k) and k >= 1 and k <= 5) then err(w .. " has unknown field " .. tostring(k)) end
                    end
                    local zones = {}
                    if e[1] ~= nil then
                        if type(e[1]) ~= "table" then err(w .. " spawns is not a table")
                        else
                            for _, z in ipairs(sortedKeys(e[1])) do
                                if not isInt(z) then err(w .. " spawns has non-integer zone key") end
                                if type(e[1][z]) ~= "table" then err(w .. " spawns zone " .. tostring(z) .. " is not a list") end
                                zones[#zones + 1] = z
                            end
                        end
                    end
                    if not (isInt(e[2]) and e[2] >= 1 and e[2] <= 16) then err(w .. " icon " .. tostring(e[2]) .. " invalid") end
                    if e[3] ~= nil and type(e[3]) ~= "string" then err(w .. " text is not a string") end
                    if not (isInt(e[4]) and e[4] >= 0) then err(w .. " objectiveIndex " .. tostring(e[4]) .. " missing or invalid") end
                    local refs = {}
                    if e[5] ~= nil then
                        if not isList(e[5]) then err(w .. " refs is not a plain list")
                        else
                            for j, r in ipairs(e[5]) do
                                if type(r) ~= "table" or not M.EXTRA_REF_TYPES[r[1]] or not posId(r[2]) then
                                    err(w .. " ref " .. j .. " invalid (type monster/object/item and positive id required)")
                                else
                                    for k in pairs(r) do if k ~= 1 and k ~= 2 then err(w .. " ref " .. j .. " has unknown field " .. tostring(k)) end end
                                    refs[j] = { type = r[1], id = r[2], refIndex = j }
                                end
                            end
                        end
                    end
                    if #refs == 0 and #zones == 0 then err(w .. " has neither references nor spawns") end
                    rec.extraObjectives[i] = { position = i, icon = e[2], hasText = e[3] ~= nil,
                        spawnZones = zones, objectiveIndex = e[4], refs = refs }
                end
            end
        end
    end
    -- objectiveIndex is Questie's RealObjectiveIndex: a quest-LOG line. It
    -- may name one line past the DB objectives only when that line exists in
    -- the log without a DB objective: the triggerEnd event line, or a quest
    -- with no DB objectives at all (measured: 5 real quests). Anything else
    -- past the objectives fails closed.
    for i, e in ipairs(rec.extraObjectives) do
        if isInt(e.objectiveIndex) and e.objectiveIndex > M.MaxObjectiveIndex(rec) then
            err("extraObjectives[" .. i .. "] objectiveIndex " .. e.objectiveIndex .. " points past " .. #rec.objectives .. " objectives")
        end
    end

    if #errs > 0 then return nil, errs end

    -- M1 classification: the frozen v1 Record codes, as the coverage manifest.
    local v1rec, _, codes = V1.Record(query, id, ctx)
    local reasons = {}
    if not v1rec then
        local seen = {}
        for _, c in ipairs(codes or {}) do
            if c == V1.UNCLASSIFIED then return nil, { "quest " .. id .. ": v1 refusal without a reason code (UNCLASSIFIED)" } end
            if not seen[c] then seen[c] = true; reasons[#reasons + 1] = c end
        end
        if #reasons == 0 then return nil, { "quest " .. id .. ": v1 refused without codes" } end
        table.sort(reasons)
    end
    rec.m1Status = (#reasons == 0) and "SUPPORTED" or "UNSUPPORTED_BY_RULES"
    rec.m1Reasons = reasons
    return rec, nil, v1rec
end

-- Build every record for `ids` (sorted ascending in the result). Any error
-- fails the whole batch; duplicate or invalid IDs are refused.
function M.BuildAll(query, ids, ctx)
    if not isList(ids) or #ids == 0 then return nil, { "BuildAll: non-empty ID list required" } end
    local sorted, seen = {}, {}
    for i, id in ipairs(ids) do
        if not posId(id) then return nil, { "BuildAll: ids[" .. i .. "] invalid" } end
        if seen[id] then return nil, { "BuildAll: duplicate quest ID " .. id } end
        seen[id] = true
        sorted[#sorted + 1] = id
    end
    table.sort(sorted)
    local out, v1s, errs = {}, {}, {}
    for _, id in ipairs(sorted) do
        local rec, e, v1rec = M.BuildRecord(query, id, ctx)
        if rec then out[#out + 1] = rec; v1s[id] = v1rec or false
        else for _, x in ipairs(e) do errs[#errs + 1] = x end end
    end
    if #errs > 0 then return nil, errs end
    return out, nil, v1s
end

return M
