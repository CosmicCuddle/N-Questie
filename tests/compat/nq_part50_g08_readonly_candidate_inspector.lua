-- Part50 Gate08: TEST-ONLY candidate inspector, never loaded by the WoW addon.
-- Structural preflight only. Receipt/token equality is NOT writer provenance,
-- an immutable snapshot, real codec validation, SavedVariables durability, or
-- permission to select a generation in a production Questie client.
local M = {}
local kinds = {"npc", "obj", "quest", "item"}

local function plain(t)
    return type(t) == "table" and getmetatable(t) == nil
end

local function integer(n, min)
    return type(n) == "number" and n == n
        and n >= min and n % 1 == 0 and n < math.huge
end

local function refuse(reason)
    return nil, "REFUSE_" .. reason
end

-- Return a detached scalar-only description; never bind Questie globals,
-- load actual handles, claim stream ownership, or publish a revision.
-- The caller must separately certify source epoch, writer provenance,
-- codec roundtrips, reader lifetimes and crash/relog recovery.
function M.InspectCandidate(stage, expected)
    if not plain(stage) then return refuse("STAGE_SHAPE") end
    if not plain(expected) then return refuse("EXPECTATION_SHAPE") end
    if not plain(stage.fields) then return refuse("FIELDS_SHAPE") end
    if not plain(stage.metadata) then return refuse("METADATA_SHAPE") end
    if not plain(stage.receipts) then return refuse("RECEIPTS_SHAPE") end

    if expected.scope ~= "normal" and expected.scope ~= "sod" then
        return refuse("EXPECTED_SCOPE")
    end
    if stage.scope ~= expected.scope then return refuse("SCOPE") end

    if not plain(expected.ownerToken) then return refuse("EXPECTED_TOKEN") end
    if stage.ownerToken ~= expected.ownerToken then return refuse("OWNER_TOKEN") end
    if not integer(expected.generation, 1) or
            not integer(stage.generation, 1) or
            stage.generation ~= expected.generation then
        return refuse("GENERATION")
    end
    if not integer(expected.sourceEpoch, 0) or
            not integer(stage.sourceEpoch, 0) or
            stage.sourceEpoch ~= expected.sourceEpoch then
        return refuse("SOURCE_EPOCH")
    end

    local m = stage.metadata
    if m.dbIsCompiled ~= true then return refuse("COMPILED_FLAG") end
    if type(m.dbCompiledOnVersion) ~= "string" or
            m.dbCompiledOnVersion == "" or
            type(expected.dbCompiledOnVersion) ~= "string" or
            m.dbCompiledOnVersion ~= expected.dbCompiledOnVersion then
        return refuse("VERSION")
    end
    if type(m.dbCompiledLang) ~= "string" or
            m.dbCompiledLang == "" or
            type(expected.dbCompiledLang) ~= "string" or
            m.dbCompiledLang ~= expected.dbCompiledLang then
        return refuse("LOCALE")
    end
    if not integer(m.dbCompiledExpansion, 1) or
            not integer(expected.dbCompiledExpansion, 1) or
            m.dbCompiledExpansion ~= expected.dbCompiledExpansion then
        return refuse("EXPANSION")
    end
    if not integer(m.dbCompiledCount, 1) or
            not integer(expected.dbCompiledCount, 1) or
            m.dbCompiledCount ~= expected.dbCompiledCount then
        return refuse("COUNT")
    end
    local rtype = type(expected.nQuestieDataRevision)
    if (rtype ~= "number" and rtype ~= "string") or
            type(m.nQuestieDataRevision) ~= rtype or
            m.nQuestieDataRevision ~= expected.nQuestieDataRevision then
        return refuse("REVISION")
    end

    local detached = {
        scope = stage.scope,
        generation = stage.generation,
        sourceEpoch = stage.sourceEpoch,
        fields = {},
        metadata = {
            dbIsCompiled = true,
            dbCompiledOnVersion = m.dbCompiledOnVersion,
            dbCompiledLang = m.dbCompiledLang,
            dbCompiledExpansion = m.dbCompiledExpansion,
            dbCompiledCount = m.dbCompiledCount,
            nQuestieDataRevision = m.nQuestieDataRevision,
        },
    }

    for _, kind in ipairs(kinds) do
        local binKey, ptrKey = kind .. "Bin", kind .. "Ptrs"
        local bin, ptrs = stage.fields[binKey], stage.fields[ptrKey]
        if type(bin) ~= "string" or bin == "" then
            return refuse("BIN_" .. kind)
        end
        if type(ptrs) ~= "string" or ptrs == "" then
            return refuse("PTRS_" .. kind)
        end
        local receipt = stage.receipts[kind]
        if not plain(receipt) then return refuse("RECEIPT_" .. kind) end
        if receipt.token ~= stage.ownerToken then
            return refuse("RECEIPT_TOKEN_" .. kind)
        end
        if receipt.generation ~= stage.generation or
                receipt.sourceEpoch ~= stage.sourceEpoch then
            return refuse("RECEIPT_EPOCH_" .. kind)
        end
        if receipt.bin ~= bin or receipt.ptrs ~= ptrs then
            return refuse("RECEIPT_BYTES_" .. kind)
        end
        detached.fields[binKey] = bin
        detached.fields[ptrKey] = ptrs
    end

    return detached, "STRUCTURAL_PASS"
end

return M
