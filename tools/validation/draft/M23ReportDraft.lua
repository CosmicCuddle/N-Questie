-- DRAFT validator for the proposed M2.3 private report and aggregate formats.
-- Design validation only: this is NOT the M2.3 comparison engine. It never
-- reads server data, never runs M1 and never writes files. It checks that a
-- report document (hand-written synthetic fixtures today) obeys the two-axis
-- rules in docs/NQ-VALIDATION-M2.3-DESIGN.md. Lua 5.1.
local M = { DRAFT = true }

M.EXPORT_STATUS = { ABSENT_FROM_EFFECTIVE_DB = true, UNSUPPORTED_BY_SCHEMA_VERSION = true,
    EXPORTED = true, REJECTED_MALFORMED_INPUT = true }
M.OUTCOME = { M1_UNSUPPORTED_BY_RULES = true, NEEDS_MANUAL_REVIEW = true,
    EXPECTED_REPRESENTATION_DIFF = true, CONFIRMED_MATCH = true, CONFIRMED_MISMATCH = true }
-- Evidence that must be "complete" before any CONFIRMED_* outcome.
M.EVIDENCE = { "killCredit", "conditions", "scripts", "ip", "objectiveData" }

local function guard(opts)
    if not (type(opts) == "table" and opts.allowDraft == true) then
        error("M23ReportDraft is a draft; pass { allowDraft = true }", 2)
    end
end
local function isInt(v) return type(v) == "number" and v == math.floor(v) end

-- CONFIRMED_MATCH mapping (design §6): allowed only when M1 returned no
-- findings at all, the record is M1-SUPPORTED, every evidence item is
-- "complete", and no representation difference applies.
function M.ConfirmedMatchAllowed(row)
    if row.m1Findings ~= 0 or row.m1Supported ~= true or row.representationDiff == true then return false end
    for _, k in ipairs(M.EVIDENCE) do
        if not (type(row.evidence) == "table" and row.evidence[k] == "complete") then return false end
    end
    return true
end

function M.ValidateReport(doc, opts)
    guard(opts)
    local errs = {}
    local function err(s) errs[#errs + 1] = s end
    if type(doc) ~= "table" then return false, { "report: table required" } end
    if doc.schema ~= "nq-m2-3-report" or doc.schemaVersion ~= 1 then err("schema/schemaVersion") end
    if doc.private ~= true then err("private: must be true") end
    if type(doc.selected) ~= "table" or type(doc.rows) ~= "table" then
        err("selected and rows required"); return false, errs
    end
    local sel, seen = {}, {}
    for _, id in ipairs(doc.selected) do sel[id] = true end
    for i, r in ipairs(doc.rows) do
        local w = "rows[" .. i .. "]"
        if not (isInt(r.questId) and sel[r.questId]) then err(w .. ".questId: not a selected ID") end
        if seen[r.questId] then err(w .. ": quest " .. tostring(r.questId) .. " appears twice") end
        seen[r.questId] = true
        if not M.EXPORT_STATUS[r.exportStatus] then err(w .. ".exportStatus: unknown") end
        if r.exportStatus == "EXPORTED" then
            if r.outcome ~= nil and not M.OUTCOME[r.outcome] then err(w .. ".outcome: unknown") end
            if r.outcome == nil then err(w .. ".outcome: EXPORTED quest needs exactly one outcome") end
            if (r.outcome == "CONFIRMED_MATCH") and not M.ConfirmedMatchAllowed(r) then
                err(w .. ": CONFIRMED_MATCH without no-findings + complete evidence")
            end
            if r.outcome == "CONFIRMED_MISMATCH" then
                local complete = true
                for _, k in ipairs(M.EVIDENCE) do
                    if not (type(r.evidence) == "table" and r.evidence[k] == "complete") then complete = false end
                end
                if not complete or r.m1Supported ~= true then err(w .. ": CONFIRMED_MISMATCH needs complete evidence and M1 support") end
            end
            if r.m1Supported == false and r.outcome ~= "M1_UNSUPPORTED_BY_RULES" then
                err(w .. ": M1-unsupported record must be M1_UNSUPPORTED_BY_RULES")
            end
        elseif r.outcome ~= nil then
            err(w .. ".outcome: only EXPORTED quests have an outcome")
        end
        if r.exportStatus == "UNSUPPORTED_BY_SCHEMA_VERSION" and not (type(r.reasons) == "table" and #r.reasons > 0) then
            err(w .. ".reasons: unsupported quest needs its manifest reason codes")
        end
    end
    for _, id in ipairs(doc.selected) do
        if not seen[id] then err("quest " .. id .. ": selected but missing from report (silent disappearance)") end
    end
    return #errs == 0, errs
end

-- Aggregate: counts only. No quest IDs, names, fingerprints or labels.
local AGG_KEYS = { schema = 1, schemaVersion = 1, selectedCount = 1, exportStatus = 1, outcome = 1, reasons = 1 }
function M.ValidateAggregate(agg, report, opts)
    guard(opts)
    local errs = {}
    local function err(s) errs[#errs + 1] = s end
    if type(agg) ~= "table" then return false, { "aggregate: table required" } end
    for k in pairs(agg) do if not AGG_KEYS[k] then err("aggregate: field not allowed: " .. tostring(k)) end end
    if agg.schema ~= "nq-m2-3-aggregate" or agg.schemaVersion ~= 1 then err("aggregate schema") end
    local function counts(t, enum, w)
        local sum = 0
        if type(t) ~= "table" then err(w .. ": table required"); return 0 end
        for k, v in pairs(t) do
            if enum and not enum[k] then err(w .. ": unknown key " .. tostring(k)) end
            if type(k) ~= "string" then err(w .. ": keys must be names, not IDs") end
            if not (isInt(v) and v >= 0) then err(w .. "." .. tostring(k) .. ": count") else sum = sum + v end
        end
        return sum
    end
    local s1 = counts(agg.exportStatus, M.EXPORT_STATUS, "exportStatus")
    local s2 = counts(agg.outcome, M.OUTCOME, "outcome")
    counts(agg.reasons, nil, "reasons")
    if s1 ~= agg.selectedCount then err("exportStatus counts do not sum to selectedCount") end
    if s2 ~= ((agg.exportStatus or {}).EXPORTED or 0) then err("outcome counts do not sum to EXPORTED") end
    if report then
        local es, oc = {}, {}
        for _, r in ipairs(report.rows) do
            es[r.exportStatus] = (es[r.exportStatus] or 0) + 1
            if r.outcome then oc[r.outcome] = (oc[r.outcome] or 0) + 1 end
        end
        for k in pairs(M.EXPORT_STATUS) do if (es[k] or 0) ~= ((agg.exportStatus or {})[k] or 0) then err("aggregate differs from report: " .. k) end end
        for k in pairs(M.OUTCOME) do if (oc[k] or 0) ~= ((agg.outcome or {})[k] or 0) then err("aggregate differs from report: " .. k) end end
    end
    return #errs == 0, errs
end

return M
