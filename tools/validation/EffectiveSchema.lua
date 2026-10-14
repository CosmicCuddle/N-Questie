-- N-Questie M2.2 Step 1: strict schema and validator for EFFECTIVE Questie
-- objective records (nq-m2-effective v1), as a future M0-harness export would
-- write them after the normal 3.3.5a compile and corrections pipeline.
--
-- Report-only and read-only. This module contains no export logic. It reuses
-- the frozen M2.1 data-only parser and fail-closed path rules from
-- InputSchema.lua without changing them.
--
-- Lua 5.1 compatible.

local Input = dofile("tools/validation/InputSchema.lua")

local M = {}

M.SCHEMA = "nq-m2-effective"
M.SCHEMA_VERSION = 1
M.MAX_QUESTS = 20000
M.MAX_ID = 2147483647
M.TOC_INTERFACE = 30300
M.FLAVOUR = "wotlk-335"

local function isInt(v) return type(v) == "number" and v == math.floor(v) and v == v end
local function isHex(v, n) return type(v) == "string" and #v == n and v:match("^[0-9a-f]+$") ~= nil end

M.PROVENANCE_FIELDS = {
    harness = "name of the exporting harness, e.g. validate-335",
    harnessVersion = "semantic version of the harness",
    dataKind = "\"effective\" (post-correction) or \"stock\" (no N-Questie corrections)",
    sourceCommit = "git commit of the compiled Questie checkout, 40 lowercase hex",
    sourceTree = "git tree hash of that commit, 40 lowercase hex",
    sourceDirty = "false; a dirty working tree cannot be identified and is rejected",
    tocInterface = "30300 (3.3.5a client build in the TOC)",
    flavour = "\"wotlk-335\"",
    nQuestieDataRevision = "effective: integer >= 1; stock: 0",
    correctionCount = "effective: integer >= 1 (28 today); stock: 0",
    correctionFingerprint = "effective: sha256:<64 hex> over the correction modules; stock: \"none\"",
    correctionModules = "list of correction module file names (effective: non-empty; stock: empty)",
    m0Checks = "effective: number of M0 assertions that passed before export (>= 1); stock: 0",
    exportedAt = "UTC ISO 8601, e.g. 2026-10-14T12:00:00Z",
    questCount = "integer, must equal the number of records",
}

local TOP_KEYS = { schema = true, schemaVersion = true, provenance = true, quests = true }
local QUEST_KEYS = { ID = true, requiredLevel = true, questLevel = true, sourceItemId = true,
    requiredSourceItems = true, objectives = true, hasTriggerEnd = true,
    hasExtraObjectives = true, extraObjectiveItems = true }
local OBJ_KEYS = { creatures = true, objects = true, items = true, killCredit = true, spells = true }

local function checkProvenance(p, err)
    if type(p) ~= "table" then err("provenance: missing or not a table") return end
    for k in pairs(p) do
        if not M.PROVENANCE_FIELDS[k] then err("provenance." .. tostring(k) .. ": unknown field") end
    end
    local function str(k, pattern, maxLen)
        local v = p[k]
        if type(v) ~= "string" or #v > maxLen or not v:match(pattern) then
            err("provenance." .. k .. ": invalid or missing (" .. M.PROVENANCE_FIELDS[k] .. ")")
        end
    end
    str("harness", "^[%w][%w%._%-]*$", 64)
    str("harnessVersion", "^%d+%.%d+%.%d+[%w%.%-]*$", 32)
    if not isHex(p.sourceCommit, 40) then err("provenance.sourceCommit: invalid or missing (" .. M.PROVENANCE_FIELDS.sourceCommit .. ")") end
    if not isHex(p.sourceTree, 40) then err("provenance.sourceTree: invalid or missing (" .. M.PROVENANCE_FIELDS.sourceTree .. ")") end
    if p.sourceDirty ~= false then err("provenance.sourceDirty: must be false (" .. M.PROVENANCE_FIELDS.sourceDirty .. ")") end
    if p.tocInterface ~= M.TOC_INTERFACE then err("provenance.tocInterface: must be " .. M.TOC_INTERFACE) end
    if p.flavour ~= M.FLAVOUR then err("provenance.flavour: must be \"" .. M.FLAVOUR .. "\"") end
    str("exportedAt", "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ$", 20)
    if type(p.exportedAt) == "string" then
        local mo, d, h, mi, s = p.exportedAt:match("^%d%d%d%d%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)Z$")
        if mo and (tonumber(mo) < 1 or tonumber(mo) > 12 or tonumber(d) < 1 or tonumber(d) > 31
            or tonumber(h) > 23 or tonumber(mi) > 59 or tonumber(s) > 59) then
            err("provenance.exportedAt: not a valid date/time")
        end
    end
    if not isInt(p.questCount) or p.questCount < 1 then err("provenance.questCount: required positive integer") end

    -- correctionModules: list of plain file names
    local mods = p.correctionModules
    local nmods = 0
    if type(mods) ~= "table" then
        err("provenance.correctionModules: missing or not a list")
    else
        local seen = {}
        for k, v in pairs(mods) do
            nmods = nmods + 1
            if not isInt(k) or k < 1 then err("provenance.correctionModules: must be a list") end
            if type(v) ~= "string" or #v > 128 or not v:match("^[%w][%w_%-]*%.lua$") then
                err("provenance.correctionModules[" .. tostring(k) .. "]: must be a plain .lua file name (no paths)")
            elseif seen[v] then
                err("provenance.correctionModules: duplicate " .. v)
            end
            if type(v) == "string" then seen[v] = true end
        end
        if nmods ~= #mods then err("provenance.correctionModules: list has holes") end
    end

    if p.dataKind == "effective" then
        if not isInt(p.nQuestieDataRevision) or p.nQuestieDataRevision < 1 then
            err("provenance.nQuestieDataRevision: effective export needs an integer >= 1")
        end
        if not isInt(p.correctionCount) or p.correctionCount < 1 then
            err("provenance.correctionCount: effective export needs an integer >= 1")
        end
        if type(p.correctionFingerprint) ~= "string" or not p.correctionFingerprint:match("^sha256:" .. string.rep("[0-9a-f]", 64) .. "$") then
            err("provenance.correctionFingerprint: effective export needs sha256:<64 lowercase hex>")
        end
        if type(mods) == "table" and nmods == 0 then err("provenance.correctionModules: effective export needs at least one module") end
        if not isInt(p.m0Checks) or p.m0Checks < 1 then
            err("provenance.m0Checks: effective export needs the number of passed M0 checks (>= 1)")
        end
    elseif p.dataKind == "stock" then
        if p.nQuestieDataRevision ~= 0 then err("provenance.nQuestieDataRevision: stock export must be 0") end
        if p.correctionCount ~= 0 then err("provenance.correctionCount: stock export must be 0") end
        if p.correctionFingerprint ~= "none" then err("provenance.correctionFingerprint: stock export must be \"none\"") end
        if type(mods) == "table" and nmods ~= 0 then err("provenance.correctionModules: stock export must be empty") end
        if p.m0Checks ~= 0 then err("provenance.m0Checks: stock export must be 0") end
    else
        err("provenance.dataKind: must be \"effective\" or \"stock\"")
    end
end

local function idList(v, where, err, allowEmpty)
    if type(v) ~= "table" then err(where .. ": missing or not a list") return end
    local n, seen = 0, {}
    for k in pairs(v) do
        n = n + 1
        if not isInt(k) or k < 1 then err(where .. ": must be a list; found key " .. tostring(k)) end
    end
    if n ~= #v then err(where .. ": list has holes") end
    if n == 0 and allowEmpty == false then err(where .. ": must not be empty") end
    for i, id in ipairs(v) do
        if not isInt(id) or id < 1 or id > M.MAX_ID then
            err(where .. "[" .. i .. "]: must be a positive integer id, got " .. tostring(id))
        elseif seen[id] then
            err(where .. "[" .. i .. "]: duplicate id " .. id)
        else
            seen[id] = true
        end
    end
end

local function checkQuest(q, where, err)
    if type(q) ~= "table" then err(where .. ": record is not a table") return end
    for k in pairs(q) do
        if not QUEST_KEYS[k] then err(where .. "." .. tostring(k) .. ": unknown field") end
    end
    for k in pairs(QUEST_KEYS) do
        if q[k] == nil then err(where .. "." .. k .. ": missing") end
    end
    if q.ID ~= nil and (not isInt(q.ID) or q.ID < 1 or q.ID > M.MAX_ID) then err(where .. ".ID: must be a positive integer") end
    if q.requiredLevel ~= nil and (not isInt(q.requiredLevel) or q.requiredLevel < 0 or q.requiredLevel > 255) then
        err(where .. ".requiredLevel: must be an integer 0-255")
    end
    if q.questLevel ~= nil and (not isInt(q.questLevel) or q.questLevel < -1 or q.questLevel > 255) then
        err(where .. ".questLevel: must be an integer -1-255 (-1 = scales with the player)")
    end
    if q.sourceItemId ~= nil and (not isInt(q.sourceItemId) or q.sourceItemId < 0 or q.sourceItemId > M.MAX_ID) then
        err(where .. ".sourceItemId: must be an integer >= 0 (0 = none)")
    end
    if q.requiredSourceItems ~= nil then idList(q.requiredSourceItems, where .. ".requiredSourceItems", err) end
    for _, b in ipairs({ "hasTriggerEnd", "hasExtraObjectives" }) do
        if q[b] ~= nil and type(q[b]) ~= "boolean" then err(where .. "." .. b .. ": must be a boolean") end
    end
    if q.extraObjectiveItems ~= nil then
        idList(q.extraObjectiveItems, where .. ".extraObjectiveItems", err)
        if q.hasExtraObjectives == false and type(q.extraObjectiveItems) == "table" and #q.extraObjectiveItems > 0 then
            err(where .. ".extraObjectiveItems: listed but hasExtraObjectives is false")
        end
    end

    local o = q.objectives
    if o ~= nil then
        if type(o) ~= "table" then err(where .. ".objectives: not a table") return end
        for k in pairs(o) do
            if not OBJ_KEYS[k] then err(where .. ".objectives." .. tostring(k) .. ": unknown field") end
        end
        for _, k in ipairs({ "creatures", "objects", "items", "spells" }) do
            idList(o[k], where .. ".objectives." .. k, err)
        end
        local kc = o.killCredit
        if type(kc) ~= "table" then
            err(where .. ".objectives.killCredit: missing or not a list")
        else
            local n = 0
            for k in pairs(kc) do
                n = n + 1
                if not isInt(k) or k < 1 then err(where .. ".objectives.killCredit: must be a list") end
            end
            if n ~= #kc then err(where .. ".objectives.killCredit: list has holes") end
            for i, e in ipairs(kc) do
                local w = where .. ".objectives.killCredit[" .. i .. "]"
                if type(e) ~= "table" then
                    err(w .. ": must be { ids = {...}, rootId = n }")
                else
                    for k in pairs(e) do
                        if k ~= "ids" and k ~= "rootId" then err(w .. "." .. tostring(k) .. ": unknown field") end
                    end
                    idList(e.ids, w .. ".ids", err, false)
                    if not isInt(e.rootId) or e.rootId < 1 or e.rootId > M.MAX_ID then
                        err(w .. ".rootId: must be a positive creature id")
                    end
                end
            end
        end
    end
end

-- Validate a parsed document. opts (optional):
--   expectKind = "effective" | "stock"   (reject the other kind)
--   expectCorrectionCount = n             (e.g. 28)
-- Returns true, or false plus a list of errors. Never modifies doc.
function M.Validate(doc, opts)
    opts = opts or {}
    local errors = {}
    local function err(msg) errors[#errors + 1] = msg end
    if type(doc) ~= "table" then return false, { "input: top level must be a table" } end
    for k in pairs(doc) do
        if not TOP_KEYS[k] then err("input." .. tostring(k) .. ": unknown top-level field") end
    end
    if doc.schema ~= M.SCHEMA then err("schema: must be \"" .. M.SCHEMA .. "\"") end
    if doc.schemaVersion ~= M.SCHEMA_VERSION then
        err("schemaVersion: unsupported (" .. tostring(doc.schemaVersion) .. "), this validator accepts " .. M.SCHEMA_VERSION)
    end
    checkProvenance(doc.provenance, err)
    local p = type(doc.provenance) == "table" and doc.provenance or {}
    if opts.expectKind and p.dataKind ~= opts.expectKind then
        err("provenance.dataKind: expected \"" .. opts.expectKind .. "\", got \"" .. tostring(p.dataKind) .. "\"")
    end
    if opts.expectCorrectionCount and p.correctionCount ~= opts.expectCorrectionCount then
        err("provenance.correctionCount: expected " .. opts.expectCorrectionCount .. ", got " .. tostring(p.correctionCount))
    end

    local quests = doc.quests
    if type(quests) ~= "table" then
        err("quests: missing or not a list")
    else
        local n = 0
        for k in pairs(quests) do
            n = n + 1
            if not isInt(k) or k < 1 then err("quests: must be a list; found key " .. tostring(k)) end
        end
        if n ~= #quests then err("quests: list has holes or non-list keys") end
        if n == 0 then err("quests: empty") end
        if n > M.MAX_QUESTS then err("quests: more than " .. M.MAX_QUESTS .. " records") end
        local seen = {}
        for i, q in ipairs(quests) do
            local id = type(q) == "table" and q.ID or nil
            checkQuest(q, "quests[" .. i .. "]" .. (isInt(id) and (" (ID " .. id .. ")") or ""), err)
            if isInt(id) then
                if seen[id] then err("quests[" .. i .. "]: duplicate quest ID " .. id .. " (first at quests[" .. seen[id] .. "])") end
                seen[id] = seen[id] or i
            end
        end
        if isInt(p.questCount) and p.questCount ~= n then
            err("provenance.questCount: " .. p.questCount .. " does not match " .. n .. " records")
        end
    end
    if #errors > 0 then return false, errors end
    return true
end

M.ParseString = Input.ParseString
M.CheckInputPath = function(path, repoRoot) return Input.CheckInputPath(path, repoRoot) end

-- Read-only load: same fail-closed path rules and parser as M2.1.
function M.LoadFile(path, repoRoot, opts)
    local ok, resolved = Input.CheckInputPath(path, repoRoot)
    if not ok then return nil, { resolved } end
    local f, e = io.open(resolved, "rb")
    if not f then return nil, { "cannot open input: " .. tostring(e) } end
    local src = f:read(Input.MAX_BYTES + 1)
    f:close()
    if src and #src > Input.MAX_BYTES then return nil, { "input larger than " .. Input.MAX_BYTES .. " bytes" } end
    local doc, perrs = Input.ParseString(src or "")
    if not doc then return nil, perrs end
    local valid, errs = M.Validate(doc, opts)
    if not valid then return nil, errs end
    return doc
end

-- Pure helper for M2.3: turn one validated effective record into the
-- questKeys-indexed table that ObjectiveRules.Compare expects. Returns a new
-- table; the record is not modified.
function M.ToQuestieRecord(rec)
    local function wrap(list)
        local out = {}
        for i, id in ipairs(list) do out[i] = { id } end
        return out
    end
    local kc = {}
    for i, e in ipairs(rec.objectives.killCredit) do
        local ids = {}
        for j, id in ipairs(e.ids) do ids[j] = id end
        kc[i] = { ids, e.rootId }
    end
    local q = {}
    q[10] = { wrap(rec.objectives.creatures), wrap(rec.objectives.objects), wrap(rec.objectives.items),
              nil, kc, wrap(rec.objectives.spells) }
    q[11] = rec.sourceItemId > 0 and rec.sourceItemId or nil
    local rsi = {}
    for i, id in ipairs(rec.requiredSourceItems) do rsi[i] = id end
    q[21] = rsi
    q[9] = rec.hasTriggerEnd and {} or nil
    if rec.hasExtraObjectives then
        local refs = {}
        for i, id in ipairs(rec.extraObjectiveItems) do refs[i] = { "item", id } end
        q[27] = { { nil, nil, nil, nil, refs } }
    end
    q[4] = rec.requiredLevel
    q[5] = rec.questLevel
    return q
end

return M
