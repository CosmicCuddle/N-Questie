-- DRAFT validator for the proposed nq-m2-markers v1 record. Design
-- validation only: NOT a marker exporter. No file, game or server access.
-- Rules: docs/NQ-VALIDATION-M2-MARKERS-DESIGN.md section 3-4. Lua 5.1.
local M = { DRAFT = true }

M.ORIGIN = { db_npc = "monster", db_object = "object", custom_extra = true }
M.VIA = { direct = true, killCredit = true, itemSource = true, extraRef = true, requiredSourceItem = true }
-- Item source categories, kept as they are in Questie's itemDB.
M.SOURCE_KIND = { npcDrop = true, objectDrop = true, vendor = true, itemDrop = true }
M.LOCATION_RESULT = { NEEDS_MANUAL_REVIEW = true, WITHIN_PROVISIONAL_TOLERANCE = true, OUTSIDE_PROVISIONAL_TOLERANCE = true }

local function guard(opts)
    if not (type(opts) == "table" and opts.allowDraft == true) then
        error("MarkersDraft is a draft; pass { allowDraft = true }", 2)
    end
end
local function isId(v) return type(v) == "number" and v == math.floor(v) and v > 0 end
local function isCoord(v) return type(v) == "number" and v >= 0 and v <= 100 end

function M.Validate(rec, opts)
    guard(opts)
    local errs = {}
    local function err(s) errs[#errs + 1] = s end
    if type(rec) ~= "table" then return false, { "record: table required" } end
    if not isId(rec.ID) then err("ID") end
    for k in pairs(rec) do
        if not ({ ID = 1, starters = 1, finishers = 1, objectives = 1, extraObjectives = 1, points = 1, waypoints = 1 })[k] then
            err("unknown field " .. tostring(k))
        end
    end
    for _, list in ipairs({ "starters", "finishers" }) do
        for i, g in ipairs(type(rec[list]) == "table" and rec[list] or {}) do
            if not ((g.type == "monster" or g.type == "object" or g.type == "item") and isId(g.id)) then err(list .. "[" .. i .. "]") end
        end
    end
    for i, o in ipairs(type(rec.objectives) == "table" and rec.objectives or {}) do
        for j, t in ipairs(type(o.targets) == "table" and o.targets or {}) do
            local w = "objectives[" .. i .. "].targets[" .. j .. "]"
            if not M.VIA[t.via] then err(w .. ".via") end
            if not isId(t.id) then err(w .. ".id") end
            if t.via == "itemSource" then
                if not M.SOURCE_KIND[t.sourceKind] then err(w .. ".sourceKind: item source category required") end
                if type(t.path) ~= "table" or #t.path < 2 then err(w .. ".path: item -> source path required") end
                if t.sourceKind == "itemDrop" and t.type ~= "item" then err(w .. ": itemDrop source must be an item") end
                if (t.sourceKind == "npcDrop" or t.sourceKind == "vendor") and t.type ~= "monster" then err(w .. ": " .. t.sourceKind .. " source must be a monster") end
                if t.sourceKind == "objectDrop" and t.type ~= "object" then err(w .. ": objectDrop source must be an object") end
            elseif t.sourceKind ~= nil then err(w .. ".sourceKind: only for itemSource") end
        end
    end
    -- extra objectives: custom pins and refs kept apart
    local pinsByExtra = {}
    for i, x in ipairs(type(rec.extraObjectives) == "table" and rec.extraObjectives or {}) do
        local w = "extraObjectives[" .. i .. "]"
        if x.position ~= i then err(w .. ".position") end
        if not (type(x.objectiveIndex) == "number" and x.objectiveIndex >= 0) then err(w .. ".objectiveIndex") end
        local refs = type(x.refs) == "table" and x.refs or {}
        if #refs > 0 then
            if not (type(x.displayRef) == "table" and x.displayRef.type == refs[1].type and x.displayRef.id == refs[1].id) then
                err(w .. ".displayRef: must be the first ref (Questie display metadata), refs kept in full")
            end
        elseif x.displayRef ~= nil then err(w .. ".displayRef: no refs, so no display ref") end
        local pins = {}
        for _, z in ipairs(type(x.customSpawns) == "table" and x.customSpawns or {}) do
            if not isId(z.zone) then err(w .. ".customSpawns.zone") end
            for k, p in ipairs(type(z.pins) == "table" and z.pins or {}) do
                if not (isCoord(p.x) and isCoord(p.y)) then err(w .. ".customSpawns pin coordinates") end
                if p.pinIndex ~= k then err(w .. ".customSpawns pinIndex must follow source order") end
                pins[z.zone .. ":" .. k] = p
            end
        end
        if #refs == 0 and next(pins) == nil then err(w .. ": neither refs nor custom spawns") end
        pinsByExtra[i] = pins
    end
    -- points: every point traceable to a DB spawn or a raw custom pin
    local seen, usedPins = {}, {}
    for i, p in ipairs(type(rec.points) == "table" and rec.points or {}) do
        local w = "points[" .. i .. "]"
        if not M.ORIGIN[p.origin] then err(w .. ".origin: unknown (waypoints are never points)") end
        if not (isId(p.zone) and isCoord(p.x) and isCoord(p.y) and isId(p.pinIndex)) then err(w .. ": zone/x/y/pinIndex") end
        local key
        if p.origin == "custom_extra" then
            local pins = pinsByExtra[p.extraPosition]
            local src = pins and pins[tostring(p.zone) .. ":" .. tostring(p.pinIndex)]
            if not src then err(w .. ": custom point without a raw custom pin (invented)")
            elseif src.x ~= p.x or src.y ~= p.y then err(w .. ": custom point coordinates differ from the raw pin")
            else usedPins[p.extraPosition .. ":" .. p.zone .. ":" .. p.pinIndex] = true end
            if p.ownerId ~= nil then err(w .. ": custom point has no DB owner") end
            key = "c" .. tostring(p.extraPosition) .. ":" .. tostring(p.zone) .. ":" .. tostring(p.pinIndex)
        elseif M.ORIGIN[p.origin] then
            if not isId(p.ownerId) then err(w .. ".ownerId: DB spawn owner required") end
            if p.extraPosition ~= nil then err(w .. ": DB point is not a custom pin") end
            key = p.origin .. ":" .. tostring(p.ownerId) .. ":" .. tostring(p.zone) .. ":" .. tostring(p.pinIndex)
        end
        if key then
            if seen[key] then err(w .. ": duplicate point") end
            seen[key] = true
        end
    end
    for e, pins in pairs(pinsByExtra) do
        for k in pairs(pins) do
            if not usedPins[e .. ":" .. k] then err("extraObjectives[" .. e .. "] pin " .. k .. " lost from points") end
        end
    end
    for i, wp in ipairs(type(rec.waypoints) == "table" and rec.waypoints or {}) do
        if not (isId(wp.npcId) and isId(wp.zone) and type(wp.path) == "table") then err("waypoints[" .. i .. "]") end
    end
    return #errs == 0, errs
end

-- Location comparison result for one Questie point against one server
-- spawn. Investigation only: there is no confirmed outcome at all.
-- c = { transformVerified, phase, conditions, ip, spawnActivity, distance, tolerance }
function M.LocationResult(c, opts)
    guard(opts)
    for _, k in ipairs({ "phase", "conditions", "ip", "spawnActivity" }) do
        if c[k] ~= "known" then return "NEEDS_MANUAL_REVIEW" end
    end
    if c.transformVerified ~= true or type(c.distance) ~= "number" or type(c.tolerance) ~= "number" then
        return "NEEDS_MANUAL_REVIEW"
    end
    if c.distance <= c.tolerance then return "WITHIN_PROVISIONAL_TOLERANCE" end
    return "OUTSIDE_PROVISIONAL_TOLERANCE"
end

return M
