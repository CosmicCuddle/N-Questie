-- M2.3 Part 2: pure, fail-closed coverage/v2 membership reconciliation.
-- This does NOT authenticate export bytes or a commit. The future trusted CLI
-- must re-run A2 verification, verify allowlist pins and SHA-256 of IdBytes().
local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
local V1Reasons = dofile("tools/validation/EffectiveExport.lua").REASONS
local M = {}
local STATUS = { REPRESENTABLE = "SUPPORTED", UNSUPPORTED = "UNSUPPORTED_BY_RULES" }
local NOTE = "Coverage report, not an export. Contains no effective records."
local MANIFEST_FIELDS = { kind = true, version = true, note = true,
    provenance = true, aggregate = true, quests = true }

local function int(v, low)
    return type(v) == "number" and v == math.floor(v)
        and v >= low and v <= 2147483647
end
local function dense(a)
    if type(a) ~= "table" then return false end
    local n = 0
    for k in pairs(a) do
        if not int(k, 1) then return false end
        n = n + 1
    end
    if n ~= #a then return false end
    for i = 1, n do if a[i] == nil then return false end end
    return true
end
local function reasonsOK(a)
    if not dense(a) then return false end
    local previous
    for _, reason in ipairs(a) do
        if type(reason) ~= "string" or not V1Reasons[reason]
            or (previous and previous >= reason) then return false end
        previous = reason
    end
    return true
end

-- Canonical format from M2.2 quest ID pin: ascending decimal ID per line,
-- each with LF, including final LF. No BOM/CRLF, no spaces. Returns bytes,
-- not a digest: SHA-256 must be computed by the later trusted CLI.
function M.IdBytes(orderedIds)
    if not dense(orderedIds) or #orderedIds == 0 then return nil, "REJECTED_MANIFEST_INCOMPLETE" end
    local out, previous = {}, 0
    for _, id in ipairs(orderedIds) do
        if not int(id, 1) or id <= previous then return nil, "REJECTED_MANIFEST_INCOMPLETE" end
        out[#out + 1] = tostring(id) .. "\n"
        previous = id
    end
    return table.concat(out)
end

-- pins are explicit, externally reviewed count pins, not trust assertions.
-- Returns indexed records and canonical bytes for later independent hashing.
function M.Check(effective, manifest, pins)
    if type(pins) ~= "table" or not int(pins.questCount, 1)
        or not int(pins.supportedCount, 0) or not int(pins.unsupportedCount, 0)
        or pins.supportedCount + pins.unsupportedCount ~= pins.questCount then
        return nil, "REJECTED_MANIFEST_INCOMPLETE"
    end
    if type(effective) ~= "table" or type(effective.quests) ~= "table"
        or effective.schemaVersion ~= 2 then
        return nil, "REJECTED_MALFORMED_INPUT"
    end
    local ok = V2.Validate(effective)
    if not ok then return nil, "REJECTED_MALFORMED_INPUT" end
    if type(manifest) ~= "table" or manifest.kind ~= "nq-m2-coverage-manifest"
        or manifest.version ~= 1 or manifest.note ~= NOTE
        or not dense(manifest.quests) or #manifest.quests == 0
        or type(manifest.aggregate) ~= "table"
        or type(manifest.provenance) ~= "table" then
        return nil, "REJECTED_MALFORMED_INPUT"
    end
    for key in pairs(manifest) do
        if not MANIFEST_FIELDS[key] then return nil, "REJECTED_MALFORMED_INPUT" end
    end
    local paired = V2.CheckPairing(effective.provenance, manifest.provenance)
    if not paired then return nil, "REJECTED_PAIRING" end
    if #effective.quests ~= #manifest.quests or #manifest.quests ~= pins.questCount then
        return nil, "REJECTED_MANIFEST_INCOMPLETE"
    end
    local ma = manifest.aggregate
    if ma.kind ~= "nq-m2-coverage-aggregate" or ma.version ~= 1
        or ma.reconciled ~= true or ma.total ~= pins.questCount
        or ma.representable ~= pins.supportedCount
        or ma.unsupported ~= pins.unsupportedCount then
        return nil, "REJECTED_MANIFEST_INCOMPLETE"
    end
    local ids, effectiveById, manifestById = {}, {}, {}
    local supported, unsupported, reasonQuests = 0, 0, {}
    local previous = 0
    for i, e in ipairs(effective.quests) do
        if not int(e.ID, 1) or e.ID <= previous then
            return nil, "REJECTED_MANIFEST_INCOMPLETE"
        end
        previous = e.ID
        ids[i] = e.ID
        effectiveById[e.ID] = e
        if not reasonsOK(e.m1Reasons) then return nil, "REJECTED_MALFORMED_INPUT" end
    end
    previous = 0
    for i, c in ipairs(manifest.quests) do
        if type(c) ~= "table" or not int(c.ID, 1) or c.ID <= previous
            or not STATUS[c.status] or not reasonsOK(c.reasons) then
            return nil, "REJECTED_MALFORMED_INPUT"
        end
        for key in pairs(c) do
            if key ~= "ID" and key ~= "status" and key ~= "reasons" then
                return nil, "REJECTED_MALFORMED_INPUT"
            end
        end
        previous = c.ID
        manifestById[c.ID] = c
        local e = effectiveById[c.ID]
        if not e or e.ID ~= ids[i] then
            return nil, "REJECTED_MEMBERSHIP"
        end
        if e.m1Status ~= STATUS[c.status] or #e.m1Reasons ~= #c.reasons then
            return nil, "REJECTED_M1_STATUS_MISMATCH"
        end
        for j, r in ipairs(c.reasons) do
            if e.m1Reasons[j] ~= r then return nil, "REJECTED_M1_STATUS_MISMATCH" end
            reasonQuests[r] = (reasonQuests[r] or 0) + 1
        end
        if c.status == "REPRESENTABLE" then
            if #c.reasons ~= 0 then return nil, "REJECTED_M1_STATUS_MISMATCH" end
            supported = supported + 1
        else
            if #c.reasons == 0 then return nil, "REJECTED_M1_STATUS_MISMATCH" end
            unsupported = unsupported + 1
        end
    end
    if supported ~= pins.supportedCount or unsupported ~= pins.unsupportedCount then
        return nil, "REJECTED_M1_STATUS_MISMATCH"
    end
    if type(ma.reasonQuests) ~= "table" then return nil, "REJECTED_MANIFEST_INCOMPLETE" end
    for r, c in pairs(ma.reasonQuests) do
        if not V1Reasons[r] or not int(c, 1) or c ~= reasonQuests[r] then
            return nil, "REJECTED_MANIFEST_INCOMPLETE"
        end
    end
    for r, c in pairs(reasonQuests) do
        if ma.reasonQuests[r] ~= c then return nil, "REJECTED_MANIFEST_INCOMPLETE" end
    end
    local bytes = M.IdBytes(ids)
    if not bytes then return nil, "REJECTED_MANIFEST_INCOMPLETE" end
    return { byId = effectiveById, coverage = manifestById,
        idBytes = bytes, total = #ids, supported = supported,
        unsupported = unsupported }
end

return M
