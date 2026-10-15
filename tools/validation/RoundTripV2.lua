-- N-Questie M2 Stage A1: in-memory round-trip proof for nq-m2-effective v2.
-- Spec: docs/NQ-VALIDATION-M2-V2-EXPORTER-SPEC.md sections 10-11.
--
--   Project(raw)                 compiled values -> comparable shape (written
--                                independently of the builder on purpose)
--   Rebuild(record)              v2 record -> the same comparable shape, using
--                                kind + slotIndex only (never `position`)
--   RecomputePositions(shape, f) Questie's ObjectiveData order, simulated the
--                                way QuestieDB.GetQuest builds it (tinsert)
--   Compare(a, b)                deep comparison -> list of differing paths
--   V1Equivalent(v1, v2)         spec section 11 contract for SUPPORTED quests
--   Check(query, id, ctx)        all of the above for one quest
--   Aggregate(results)           counts only; FormatAggregate prints them
--
-- Pure: no file or process I/O. Documented exclusions (the only ones):
-- objective/extra display text (extra hasText IS compared), spawn
-- coordinates (spawn zone keys ARE compared), triggerEnd contents (presence
-- IS compared). Two value normalisations, both counted: an empty slot table
-- equals an absent slot, and an absent sourceItemId equals 0. Lua 5.1.

local V2 = dofile("tools/validation/EffectiveExportV2.lua")
local Schema = dofile("tools/validation/EffectiveSchemaV2.lua")
local SCHEMA_OPTS = {}

local M = {}
local SLOT_NAMES = { "creature", "object", "item", "reputation", "killCredit", "spell" }

local function sortedNumKeys(t)
    local ks = {}
    for k in pairs(t) do ks[#ks + 1] = k end
    table.sort(ks, function(a, b) return tostring(a) < tostring(b) end)
    -- numbers sort numerically when all keys are numbers
    local allNum = true
    for _, k in ipairs(ks) do if type(k) ~= "number" then allNum = false end end
    if allNum then table.sort(ks) end
    return ks
end

local function copyList(t)
    local o = {}
    for i, v in ipairs(t or {}) do o[i] = v end
    return o
end

-- Comparable shape of the raw compiled values. `n` collects counts of the
-- documented exclusions and normalisations.
function M.Project(raw, n)
    n = n or {}
    local function inc(k, by) n[k] = (n[k] or 0) + (by or 1) end
    local s = {
        requiredLevel = raw.requiredLevel, questLevel = raw.questLevel,
        sourceItemId = raw.sourceItemId, requiredSourceItems = copyList(raw.requiredSourceItems),
        slots = {}, hasTriggerEnd = raw.triggerEnd ~= nil, extras = {},
    }
    if raw.sourceItemId == nil then s.sourceItemId = 0; inc("normSourceItemNil") end
    if raw.triggerEnd ~= nil then inc("exclTriggerEndContents") end
    local obj = raw.objectives or {}
    if raw.objectives ~= nil and next(raw.objectives) == nil then inc("normEmptyObjectivesTable") end
    for slot = 1, 6 do
        local name = SLOT_NAMES[slot]
        local list = obj[slot]
        if list ~= nil and next(list) == nil then inc("normEmptySlotTable") end
        local out = {}
        if slot == 4 then
            if list ~= nil and next(list) ~= nil then out[1] = { list[1], list[2] } end
        elseif list ~= nil then
            for i = 1, #list do
                local e = list[i]
                if slot == 5 then
                    out[i] = { copyList(e[1]), e[2] }
                    if e[3] ~= nil then inc("exclObjectiveText") end
                else
                    out[i] = { e[1], slot == 6 and e[3] or nil }
                    if e[2] ~= nil then inc("exclObjectiveText") end
                end
            end
        end
        s.slots[name] = out
    end
    for i = 1, #(raw.extraObjectives or {}) do
        local e = raw.extraObjectives[i]
        local zones = {}
        if e[1] ~= nil then
            for _, z in ipairs(sortedNumKeys(e[1])) do
                zones[#zones + 1] = z
                inc("exclSpawnCoordinates", #e[1][z])
            end
        end
        if e[3] ~= nil then inc("exclExtraText") end
        local refs = {}
        for j = 1, #(e[5] or {}) do refs[j] = { e[5][j][1], e[5][j][2] } end
        s.extras[i] = { zones, e[2], e[3] ~= nil, e[4], refs }
    end
    return s
end

-- The same shape rebuilt from a v2 record. Objectives go back into slots by
-- kind and slotIndex; `position` is ignored here and checked separately.
function M.Rebuild(rec)
    local s = {
        requiredLevel = rec.requiredLevel, questLevel = rec.questLevel,
        sourceItemId = rec.sourceItemId, requiredSourceItems = copyList(rec.requiredSourceItems),
        slots = {}, hasTriggerEnd = rec.hasTriggerEnd, extras = {},
    }
    for _, name in ipairs(SLOT_NAMES) do s.slots[name] = {} end
    for _, o in ipairs(rec.objectives or {}) do
        local slot = s.slots[o.kind]
        if slot == nil then s.slots["?" .. tostring(o.kind)] = { o.slotIndex }
        elseif o.kind == "reputation" then slot[o.slotIndex] = { o.factionId, o.requiredValue }
        elseif o.kind == "killCredit" then slot[o.slotIndex] = { copyList(o.ids), o.rootId }
        else slot[o.slotIndex] = { o.id, o.itemSourceId } end
    end
    for i, e in ipairs(rec.extraObjectives or {}) do
        local refs = {}
        for j, r in ipairs(e.refs or {}) do refs[j] = { r.type, r.id } end
        s.extras[i] = { copyList(e.spawnZones), e.icon, e.hasText, e.objectiveIndex, refs }
    end
    return s
end

-- Questie's ObjectiveData order from a comparable shape: append creatures,
-- objects, items, reputation, then killCredit (tinsert at 1 when the quest
-- is in killCreditObjectiveFirst), then spells. Returns { {kind, slotIndex} }.
function M.RecomputePositions(shape, flagged)
    local data = {}
    for _, name in ipairs(SLOT_NAMES) do
        local list = shape.slots[name] or {}
        for i = 1, #list do
            local o = { name, i }
            if name == "killCredit" and flagged then table.insert(data, 1, o) else data[#data + 1] = o end
        end
    end
    return data
end

-- Deep comparison; returns a list of differing paths ("" when equal).
function M.Compare(a, b, path, out)
    out = out or {}
    path = path or ""
    if type(a) ~= type(b) then out[#out + 1] = path; return out end
    if type(a) ~= "table" then
        if a ~= b then out[#out + 1] = path end
        return out
    end
    local keys = {}
    for k in pairs(a) do keys[k] = true end
    for k in pairs(b) do keys[k] = true end
    local list = {}
    for k in pairs(keys) do list[#list + 1] = k end
    table.sort(list, function(x, y) return tostring(x) < tostring(y) end)
    for _, k in ipairs(list) do M.Compare(a[k], b[k], path .. "/" .. tostring(k), out) end
    return out
end

-- Top-level field of a difference path, for per-field counts.
local function fieldOf(p) return p:match("^/([^/]+/?[^/]*)") or p end

-- Spec section 11: v1 vs v2 equivalence for a SUPPORTED quest.
function M.V1Equivalent(v1, v2)
    local d = {}
    local function eq(name, a, b) if #M.Compare(a, b) > 0 then d[#d + 1] = name end end
    eq("requiredLevel", v1.requiredLevel, v2.requiredLevel)
    eq("questLevel", v1.questLevel, v2.questLevel)
    eq("sourceItemId", v1.sourceItemId, v2.sourceItemId)
    eq("requiredSourceItems", v1.requiredSourceItems, v2.requiredSourceItems)
    eq("hasTriggerEnd", v1.hasTriggerEnd, v2.hasTriggerEnd)
    local per = { creature = {}, object = {}, item = {}, spell = {}, killCredit = {} }
    for _, o in ipairs(v2.objectives) do
        if o.kind == "killCredit" then per.killCredit[o.slotIndex] = { ids = o.ids, rootId = o.rootId }
        elseif per[o.kind] then per[o.kind][o.slotIndex] = o.id
        else d[#d + 1] = "objectives." .. o.kind .. " (not held by v1)" end
    end
    eq("objectives.creatures", v1.objectives.creatures, per.creature)
    eq("objectives.objects", v1.objectives.objects, per.object)
    eq("objectives.items", v1.objectives.items, per.item)
    eq("objectives.spells", v1.objectives.spells, per.spell)
    eq("objectives.killCredit", v1.objectives.killCredit, per.killCredit)
    eq("hasExtraObjectives", v1.hasExtraObjectives, #v2.extraObjectives > 0)
    -- v1 lists item references only, in order; v2 must hold the same items.
    local items = {}
    for _, e in ipairs(v2.extraObjectives) do
        for _, r in ipairs(e.refs) do if r.type == "item" then items[#items + 1] = r.id end end
    end
    eq("extraObjectiveItems", v1.extraObjectiveItems, items)
    return d
end

function M.ReadRaw(query, id)
    local raw = {}
    for _, key in ipairs(V2.KEYS) do
        local ok, v = pcall(query, id, key)
        if not ok then return nil end
        raw[key] = v
    end
    return raw
end

-- Check a built record against the raw compiled values it came from.
-- `flagged` is the raw killCreditObjectiveFirst flag for the quest; v1rec is
-- the frozen v1 record (nil when v1 refused the quest). Returns a result.
function M.CheckRecord(rec, raw, flagged, v1rec)
    local r = { id = rec.ID, diffs = {}, norm = {}, record = rec }
    local okv, verrs = Schema.ValidateQuest(rec, SCHEMA_OPTS)
    if not okv then r.validateError = verrs end
    local wantStatus, wantReasons = Schema.ExpectedM1(rec)
    r.expectedM1Agrees = (wantStatus == rec.m1Status) and table.concat(wantReasons, "+") == table.concat(rec.m1Reasons or {}, "+")
    local projected = M.Project(raw, r.norm)
    local rebuilt = M.Rebuild(rec)
    for _, p in ipairs(M.Compare(rebuilt, projected)) do r.diffs[#r.diffs + 1] = fieldOf(p) end
    local want = M.RecomputePositions(projected, flagged == true)
    if #want ~= #rec.objectives then r.diffs[#r.diffs + 1] = "position/count" end
    for i, o in ipairs(rec.objectives) do
        local w = want[i]
        if not w or o.position ~= i or o.kind ~= w[1] or o.slotIndex ~= w[2] then r.diffs[#r.diffs + 1] = "position"; break end
    end
    if rec.m1Status == "SUPPORTED" then
        if not v1rec then r.diffs[#r.diffs + 1] = "v1/missing"
        else
            local d = M.V1Equivalent(v1rec, rec)
            if #d > 0 then r.v1diffs = d end
        end
    elseif v1rec then
        r.diffs[#r.diffs + 1] = "v1/unexpectedRecord"
    end
    return r
end

-- Full check of one quest: build, re-read the raw values, check. Never throws.
function M.Check(query, id, ctx)
    local rec, errs, v1rec = V2.BuildRecord(query, id, ctx)
    if not rec then return { id = id, buildError = errs, diffs = {}, norm = {} } end
    local raw = M.ReadRaw(query, id)
    if not raw then return { id = id, buildError = { "quest " .. id .. ": re-read failed (QUERY_FAILED)" }, diffs = {}, norm = {} } end
    return M.CheckRecord(rec, raw, ctx.killCreditFirst[id] == true, v1rec)
end

-- Counts over all results. Only aggregate numbers; no quest IDs.
function M.Aggregate(results)
    local a = { processed = 0, built = 0, buildErrors = 0, validateErrors = 0, supported = 0, unsupported = 0,
        unclassified = 0, questsDiffering = 0, diffs = 0, diffByField = {}, positionChecked = 0,
        v1Compared = 0, v1Differing = 0, v1DiffByField = {}, expectedM1Disagree = 0, reasons = {},
        objectives = 0, byKind = {}, refsByType = { monster = 0, object = 0, item = 0 }, refs = 0,
        extraEntries = 0, questsWithExtras = 0, spawnOnlyEntries = 0, objectiveIndexZero = 0, objectiveIndexLogOnly = 0,
        reputation = 0, reputationZero = 0, killCreditFirstQuests = 0, killCreditFirstFlaggedSingle = 0,
        duplicateOccurrences = 0, duplicateByKind = {}, scalingLevel = 0, requiredSourceItems = 0,
        triggerEnd = 0, noObjectives = 0, norm = {}, buildErrorKinds = {},
        unsupported758 = { refs = 0, monster = 0, object = 0, reputation = 0, reputationZero = 0, killCreditFirst = 0, duplicates = 0 } }
    for _, r in ipairs(results) do
        a.processed = a.processed + 1
        for k, v in pairs(r.norm or {}) do a.norm[k] = (a.norm[k] or 0) + v end
        if r.buildError then
            a.buildErrors = a.buildErrors + 1
            for _, e in ipairs(r.buildError) do
                local kind = e:gsub("^quest %d+: ", ""):gsub("%d+", "N")
                a.buildErrorKinds[kind] = (a.buildErrorKinds[kind] or 0) + 1
            end
            for _, e in ipairs(r.buildError) do if e:find("UNCLASSIFIED", 1, true) then a.unclassified = a.unclassified + 1 end end
        else
            a.built = a.built + 1
            local q = r.record
            if r.validateError then a.validateErrors = a.validateErrors + 1 end
            if not r.expectedM1Agrees then a.expectedM1Disagree = a.expectedM1Disagree + 1 end
            local uns = q.m1Status ~= "SUPPORTED"
            if uns then a.unsupported = a.unsupported + 1 else a.supported = a.supported + 1 end
            for _, c in ipairs(q.m1Reasons) do a.reasons[c] = (a.reasons[c] or 0) + 1 end
            a.positionChecked = a.positionChecked + 1
            if #r.diffs > 0 then a.questsDiffering = a.questsDiffering + 1 end
            for _, f in ipairs(r.diffs) do a.diffs = a.diffs + 1; a.diffByField[f] = (a.diffByField[f] or 0) + 1 end
            if q.m1Status == "SUPPORTED" then
                a.v1Compared = a.v1Compared + 1
                if r.v1diffs then
                    a.v1Differing = a.v1Differing + 1
                    for _, f in ipairs(r.v1diffs) do a.v1DiffByField[f] = (a.v1DiffByField[f] or 0) + 1 end
                end
            end
            if q.questLevel == -1 then a.scalingLevel = a.scalingLevel + 1 end
            if #q.requiredSourceItems > 0 then a.requiredSourceItems = a.requiredSourceItems + 1 end
            if q.hasTriggerEnd then a.triggerEnd = a.triggerEnd + 1 end
            if #q.objectives == 0 then a.noObjectives = a.noObjectives + 1 end
            if q.killCreditFirst then
                a.killCreditFirstQuests = a.killCreditFirstQuests + 1
                -- Flagged but nothing reorders (decision t54u: SUPPORTED).
                local reorders = false
                for _, code in ipairs(q.m1Reasons) do if code == "KILLCREDIT_FIRST_REORDER" then reorders = true end end
                if not reorders then a.killCreditFirstFlaggedSingle = a.killCreditFirstFlaggedSingle + 1 end
                if uns then a.unsupported758.killCreditFirst = a.unsupported758.killCreditFirst + 1 end
            end
            for _, o in ipairs(q.objectives) do
                a.objectives = a.objectives + 1
                a.byKind[o.kind] = (a.byKind[o.kind] or 0) + 1
                if o.kind == "reputation" then
                    a.reputation = a.reputation + 1
                    if o.requiredValue == 0 then a.reputationZero = a.reputationZero + 1 end
                    if uns then
                        a.unsupported758.reputation = a.unsupported758.reputation + 1
                        if o.requiredValue == 0 then a.unsupported758.reputationZero = a.unsupported758.reputationZero + 1 end
                    end
                end
                if (o.occurrence or 1) > 1 then
                    a.duplicateOccurrences = a.duplicateOccurrences + 1
                    a.duplicateByKind[o.kind] = (a.duplicateByKind[o.kind] or 0) + 1
                    if uns then a.unsupported758.duplicates = a.unsupported758.duplicates + 1 end
                end
            end
            if #q.extraObjectives > 0 then a.questsWithExtras = a.questsWithExtras + 1 end
            for _, e in ipairs(q.extraObjectives) do
                a.extraEntries = a.extraEntries + 1
                if #e.refs == 0 then a.spawnOnlyEntries = a.spawnOnlyEntries + 1 end
                if e.objectiveIndex == 0 then a.objectiveIndexZero = a.objectiveIndexZero + 1 end
                if e.objectiveIndex > #q.objectives then a.objectiveIndexLogOnly = a.objectiveIndexLogOnly + 1 end
                for _, ref in ipairs(e.refs) do
                    a.refs = a.refs + 1
                    a.refsByType[ref.type] = a.refsByType[ref.type] + 1
                    if uns then
                        a.unsupported758.refs = a.unsupported758.refs + 1
                        if a.unsupported758[ref.type] then a.unsupported758[ref.type] = a.unsupported758[ref.type] + 1 end
                    end
                end
            end
        end
    end
    return a
end

local function line(out, label, v) out[#out + 1] = string.format("%-44s %s", label, tostring(v)) end
local function sortedPairs(t)
    local ks = {}
    for k in pairs(t) do ks[#ks + 1] = k end
    table.sort(ks)
    local i = 0
    return function() i = i + 1; if ks[i] ~= nil then return ks[i], t[ks[i]] end end
end

-- Deterministic text (sorted keys, no IDs, no timings).
function M.FormatAggregate(a)
    local out = { "N-QUESTIE V2 ROUND TRIP (in memory; nothing written; counts only)" }
    line(out, "quests processed", a.processed)
    line(out, "records built", a.built)
    line(out, "build errors", a.buildErrors)
    for k, v in sortedPairs(a.buildErrorKinds) do line(out, "  build error: " .. k, v) end
    line(out, "record validation errors", a.validateErrors)
    line(out, "unclassified", a.unclassified)
    line(out, "m1 SUPPORTED (v1 representable)", a.supported)
    line(out, "m1 UNSUPPORTED_BY_RULES (v1 unsupported)", a.unsupported)
    for k, v in sortedPairs(a.reasons) do line(out, "  reason " .. k .. " (quests)", v) end
    line(out, "m1 status disagreeing with v2 ExpectedM1", a.expectedM1Disagree)
    line(out, "round trip: quests compared", a.built)
    line(out, "round trip: quests differing", a.questsDiffering)
    line(out, "round trip: differences", a.diffs)
    for k, v in sortedPairs(a.diffByField) do line(out, "  difference " .. k, v) end
    line(out, "positions checked (quests)", a.positionChecked)
    line(out, "v1 equivalence: quests compared", a.v1Compared)
    line(out, "v1 equivalence: quests differing", a.v1Differing)
    for k, v in sortedPairs(a.v1DiffByField) do line(out, "  v1 difference " .. k, v) end
    line(out, "objectives", a.objectives)
    for k, v in sortedPairs(a.byKind) do line(out, "  kind " .. k, v) end
    line(out, "extra objective entries", a.extraEntries)
    line(out, "quests with extra objectives", a.questsWithExtras)
    line(out, "extra refs (occurrences)", a.refs)
    for k, v in sortedPairs(a.refsByType) do line(out, "  extra refs " .. k, v) end
    line(out, "spawn-only extra entries", a.spawnOnlyEntries)
    line(out, "extra objectiveIndex 0", a.objectiveIndexZero)
    line(out, "extra objectiveIndex past DB objectives", a.objectiveIndexLogOnly)
    line(out, "reputation pairs", a.reputation)
    line(out, "reputation pairs with value 0", a.reputationZero)
    line(out, "killCreditFirst quests", a.killCreditFirstQuests)
    line(out, "  killCreditFirst flagged, nothing reordered", a.killCreditFirstFlaggedSingle)
    line(out, "duplicate objective occurrences", a.duplicateOccurrences)
    for k, v in sortedPairs(a.duplicateByKind) do line(out, "  duplicate " .. k, v) end
    line(out, "scaling questLevel -1", a.scalingLevel)
    line(out, "quests with requiredSourceItems", a.requiredSourceItems)
    line(out, "quests with triggerEnd", a.triggerEnd)
    line(out, "quests without objectives", a.noObjectives)
    for k, v in sortedPairs(a.unsupported758) do line(out, "unsupported no-loss " .. k, v) end
    for k, v in sortedPairs(a.norm) do line(out, "documented " .. k, v) end
    return table.concat(out, "\n") .. "\n"
end

-- Run over every ID (sorted). Returns results, aggregate.
function M.Run(query, ids, ctx)
    local sorted = {}
    for i, id in ipairs(ids) do sorted[i] = id end
    table.sort(sorted)
    local results = {}
    for i, id in ipairs(sorted) do results[i] = M.Check(query, id, ctx) end
    return results, M.Aggregate(results)
end

return M
