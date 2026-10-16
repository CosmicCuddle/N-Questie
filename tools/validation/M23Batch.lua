-- M2.3 Part 2: pure, report-only M1 comparison using frozen server input.
-- No I/O or stdout/stderr. Does NOT authenticate commits, hash input files,
-- publish bundles or imply that any private input has been verified.
local Input = dofile("tools/validation/InputSchema.lua")
local Membership = dofile("tools/validation/M23Membership.lua")
local Adapter = dofile("tools/validation/M23QuestieAdapter.lua")
local M1 = dofile("tools/validation/ObjectiveRules.lua")
local M = {}
local function positive(v) return type(v) == "number" and v == math.floor(v) and v > 0 end
local function evidence()
    -- FROZEN v1 does not prove objectiveData completeness. Conditions, scripts,
    -- IP and KillCredit flags likewise lack a machine-verifiable absence
    -- provenance. Never turn structural validation into positive evidence.
    return { killCredit = "unknown", conditions = "unknown",
        scripts = "unknown", ip = "unknown", objectiveData = "unknown" }
end

-- Duplicate server quest IDs have their own agreed batch rejection code.
-- Scan only safely recognisable IDs; the frozen validator still rejects all
-- other malformed shapes and fields without exposing its diagnostic strings.
local function duplicateServerId(doc)
    if type(doc) ~= "table" or type(doc.quests) ~= "table" then return false end
    local seen = {}
    for _, q in ipairs(doc.quests) do
        if type(q) == "table" and positive(q.ID) then
            if seen[q.ID] then return true end
            seen[q.ID] = true
        end
    end
    return false
end

function M.Run(server, effective, manifest, pins)
    if duplicateServerId(server) then return nil, "REJECTED_DUPLICATE_ID" end
    local valid = Input.Validate(server)
    if not valid then return nil, "REJECTED_MALFORMED_INPUT" end
    local index, code = Membership.Check(effective, manifest, pins)
    if not index then return nil, code end
    local rows, seen = {}, {}
    for _, source in ipairs(server.quests) do
        if not positive(source.ID) or seen[source.ID] then
            return nil, "REJECTED_DUPLICATE_ID"
        end
        seen[source.ID] = true
        local q = index.byId[source.ID]
        if not q then return nil, "REJECTED_SELECTION_MISMATCH" end
        local row = { questId = source.ID, m1Supported = q.m1Status == "SUPPORTED",
            evidence = evidence(), m1Classes = {}, representationDiff = false }
        if not row.m1Supported then
            row.outcome = "M1_UNSUPPORTED_BY_RULES"
            row.reasons = {}
            for i, r in ipairs(q.m1Reasons) do row.reasons[i] = r end
        else
            local questie = Adapter.ToQuestieRecordV2(q)
            if not questie then return nil, "REJECTED_MALFORMED_INPUT" end
            local ok, findings = pcall(function()
                return M1.Compare(M1.FromQuestTemplateRow(source), questie)
            end)
            if not ok or type(findings) ~= "table" then
                -- M1 exception text may contain quest IDs; never expose it.
                return nil, "REJECTED_MALFORMED_INPUT"
            end
            local onlyExpected = #findings > 0
            for _, f in ipairs(findings) do
                row.m1Classes[#row.m1Classes + 1] = f.class
                if f.class ~= "EXPECTED_REPRESENTATION_DIFF" then onlyExpected = false end
                if f.class == "EXPECTED_REPRESENTATION_DIFF" then row.representationDiff = true end
            end
            -- B6: NEVER confirm on frozen v1. Underlying M1 findings can still
            -- be reviewed in a future PRIVATE report, not in public logs.
            row.outcome = onlyExpected and "EXPECTED_REPRESENTATION_DIFF"
                or "NEEDS_MANUAL_REVIEW"
            row.reasons = {}
        end
        rows[#rows + 1] = row
    end
    return { rows = rows, selected = #rows,
        allQuestIdsCanonicalBytes = index.idBytes,
        total = index.total, supported = index.supported,
        unsupported = index.unsupported, -- untrusted until CLI approval
        authenticated = false, publishable = false }
end

return M
