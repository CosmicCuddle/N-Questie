-- M2.3 Part 1: pure strict validation of the trusted-export allowlist.
-- Accepts BYTES only. The future CLI must separately verify a clean, tracked
-- checkout before reading this file; no arbitrary CLI override is permitted.
-- No dofile/load/require of the allowlist. Errors contain NO input contents.
local Input = dofile("tools/validation/InputSchema.lua")
local M = {}
M.ERROR = "REJECTED_ENGINE_CHECKOUT"
M.MAX_ENTRIES = 256

local topFields = { schema = true, schemaVersion = true, entries = true }
local entryFields = {
    sourceCommit = true, sourceTree = true, harnessVersion = true,
    correctionFingerprint = true, correctionCount = true,
    correctionModules = true, nQuestieDataRevision = true,
    tocInterface = true, flavour = true, harness = true,
    dataset = true, approvalRef = true,
}
local datasetFields = {
    questCount = true, supportedCount = true, unsupportedCount = true,
    idListSha256 = true,
}

local function integer(x, min)
    return type(x) == "number" and x == math.floor(x) and x >= min
        and x <= 2147483647
end

local function exactKeys(t, allowed)
    if type(t) ~= "table" then return false end
    for key in pairs(t) do if not allowed[key] then return false end end
    for key in pairs(allowed) do if t[key] == nil then return false end end
    return true
end

local function denseList(t, max)
    if type(t) ~= "table" then return false end
    local n = 0
    for k in pairs(t) do
        if not integer(k, 1) or k > max then return false end
        n = n + 1
    end
    if n > max or #t ~= n then return false end
    for i = 1, n do if t[i] == nil then return false end end
    return true
end

local function lowerHex(value, length)
    return type(value) == "string" and #value == length
        and value:match("^[0-9a-f]+$") ~= nil
end

local function validEntry(e)
    if not exactKeys(e, entryFields) then return false end
    if not lowerHex(e.sourceCommit, 40) or not lowerHex(e.sourceTree, 40) then return false end
    if type(e.harnessVersion) ~= "string"
        or #e.harnessVersion > 32
        or not e.harnessVersion:match("^%d+%.%d+%.%d+$") then return false end
    if type(e.correctionFingerprint) ~= "string"
        or e.correctionFingerprint:sub(1, 7) ~= "sha256:"
        or not lowerHex(e.correctionFingerprint:sub(8), 64) then return false end
    if not integer(e.correctionCount, 1) or not integer(e.nQuestieDataRevision, 1) then
        return false
    end
    if e.tocInterface ~= 30300 or e.flavour ~= "wotlk-335"
        or e.harness ~= "validate-335" or not integer(e.approvalRef, 1) then
        return false
    end

    if not denseList(e.correctionModules, 128) or #e.correctionModules == 0 then
        return false
    end
    local mods = {}
    for _, name in ipairs(e.correctionModules) do
        if type(name) ~= "string" or #name > 128
            or not name:match("^NQuestie[%w_%-]*%.lua$") or mods[name] then
            return false
        end
        mods[name] = true
    end
    local d = e.dataset
    if not exactKeys(d, datasetFields) then return false end
    if not integer(d.questCount, 1) or not integer(d.supportedCount, 0)
        or not integer(d.unsupportedCount, 0)
        or d.supportedCount + d.unsupportedCount ~= d.questCount
        or not lowerHex(d.idListSha256, 64) then
        return false
    end
    return true
end

function M.Validate(doc)
    if not exactKeys(doc, topFields)
        or doc.schema ~= "nq-m2-3-approved-exports"
        or doc.schemaVersion ~= 1
        or not denseList(doc.entries, M.MAX_ENTRIES) then
        return false
    end
    local seen = {}
    for _, entry in ipairs(doc.entries) do
        if not validEntry(entry) or seen[entry.sourceCommit] then return false end
        seen[entry.sourceCommit] = true
    end
    return true
end

function M.ParseBytes(bytes)
    -- Input.ParseString is a restricted data-literal parser: it never executes
    -- the supplied bytes, rejects duplicate keys and has a 16 MiB limit.
    local doc = Input.ParseString(bytes)
    if not doc or not M.Validate(doc) then return nil, M.ERROR end
    return doc
end

return M
