-- Part50 Gate08 isolated compatibility probe for original optional draft #185.
-- TEST ONLY: NEVER load into the playable addon or call Stage1.
-- No candidate selection is possible here: #185 has no independently
-- witnessed source epoch, provenance, full metadata or stream lease proof.
local M = {}
local kinds = {"npc", "obj", "quest", "item"}
local function plain(t)
    return type(t) == "table" and getmetatable(t) == nil
end
local function reject(code)
    return nil, "REFUSE_" .. code
end

-- Verify the actual older stage *shape*, without asserting writer authenticity.
-- When all eight fields are structurally present, return ONLY length telemetry
-- as a THIRD result. The first result remains nil and status remains REFUSE.
-- No bytes, owner token, receipt or source table reference escapes the probe.
function M.ProbeLegacyFlatStage(stage, expectedToken, originalVerify)
    if not plain(stage) then return reject("STAGE_SHAPE") end
    if not plain(expectedToken) then return reject("TOKEN_SHAPE") end
    if type(originalVerify) ~= "function" then
        return reject("VERIFIER_MISSING")
    end
    if not plain(stage._nqGenerationToken) or
            stage._nqGenerationToken ~= expectedToken then
        return reject("TOKEN_MISMATCH")
    end
    if not plain(stage._nqGenerationReceipts) then
        return reject("RECEIPTS_SHAPE")
    end
    for _,kind in ipairs(kinds) do
        local receipt = stage._nqGenerationReceipts[kind]
        if not plain(receipt) then return reject("RECEIPT_SHAPE_" .. kind) end
    end

    -- Calls the *original* #185 VerifyNQStagedGeneration method bound
    -- by the test driver. It throws on missing/stale/forged local receipts.
    -- pcall cannot cross a yielding coroutine: this method itself does NOT
    -- yield and never acquires streams. Never pcall the yielding compiler.
    local ok, verified = pcall(originalVerify, stage, expectedToken)
    if not ok or verified ~= true then
        return reject("LEGACY_LOCAL_VERIFICATION")
    end
    local observed = {kinds = 0, fieldCount = 0, lengths = {}}
    for _,kind in ipairs(kinds) do
        local binKey, ptrKey = kind.."Bin", kind.."Ptrs"
        local bin, ptrs = rawget(stage, binKey), rawget(stage, ptrKey)
        local receipt = stage._nqGenerationReceipts[kind]
        if type(bin) ~= "string" or #bin == 0 or
                type(ptrs) ~= "string" or #ptrs == 0 or
                rawget(receipt, "bin") ~= bin or
                rawget(receipt, "ptrs") ~= ptrs or
                rawget(receipt, "token") ~= expectedToken then
            return reject("MISMATCH_" .. kind)
        end
        observed.kinds = observed.kinds + 1
        observed.fieldCount = observed.fieldCount + 2
        observed.lengths[kind] = {bin = #bin, ptrs = #ptrs}
    end
    -- NOT success: lack of source and reader ownership is a hard stop.
    return nil, "REFUSE_UNPROVEN_SOURCE_AND_READER_OWNERSHIP", observed
end

return M
