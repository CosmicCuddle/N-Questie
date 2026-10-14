-- DRAFT validators for the correction regression and the text/tooltip QA
-- record. Design validation only: no corrections, no game access, no files.
-- Rules: docs/NQ-VALIDATION-M2-CORRECTION-WORKFLOW.md sections 5 and 7.
-- Lua 5.1.
local M = { DRAFT = true }

local function guard(opts)
    if not (type(opts) == "table" and opts.allowDraft == true) then
        error("CorrectionQaDraft is a draft; pass { allowDraft = true }", 2)
    end
end

-- Two-tier regression for one reviewed correction.
-- entry = { questId, fields = { [name] = { expectedInherited, approved, compiled } },
--           unrelatedDiffs = n, m23Outcome = "...", reviewNote = "..." }
M.TIER_B_ALLOWED = { CONFIRMED_MATCH = true, EXPECTED_REPRESENTATION_DIFF = true, NEEDS_MANUAL_REVIEW = true }
function M.CheckRegression(entry, opts)
    guard(opts)
    local errs = {}
    local function err(s) errs[#errs + 1] = s end
    if type(entry) ~= "table" or type(entry.fields) ~= "table" or next(entry.fields) == nil then
        return false, { "entry: fields required" }
    end
    -- Tier A (strict, M0): approved value compiled exactly, guard recorded, nothing else changed.
    for name, f in pairs(entry.fields) do
        if f.expectedInherited == nil then err("tier A: " .. name .. ": inherited guard value missing") end
        if f.approved == nil or f.compiled ~= f.approved then err("tier A: " .. name .. ": compiled value differs from the approved value") end
    end
    if entry.unrelatedDiffs ~= 0 then err("tier A: unrelated field differences") end
    -- Tier B (M2.3, recorded): conservative review allowed while evidence is incomplete.
    if entry.m23Outcome ~= nil then
        if not M.TIER_B_ALLOWED[entry.m23Outcome] then err("tier B: outcome " .. tostring(entry.m23Outcome) .. " is a regression")
        elseif entry.m23Outcome == "NEEDS_MANUAL_REVIEW" and not (type(entry.reviewNote) == "string" and #entry.reviewNote > 0) then
            err("tier B: NEEDS_MANUAL_REVIEW needs a documented reason (which evidence is incomplete)")
        end
    end
    return #errs == 0, errs
end

-- Text / tooltip QA observation (separate lane; vocabulary aligned with
-- #40 NQ-QUEST-MARKER-TEXT-QA.md: PASS / DIFFERENCE_TO_REVIEW / UNKNOWN).
M.TEXT_RESULT = { PASS = true, DIFFERENCE_TO_REVIEW = true, UNKNOWN = true }
M.SURFACE = { questLogLine = true, questLogCount = true, questLogOrder = true, starterTooltip = true,
    finisherTooltip = true, objectiveMarkerTooltip = true, itemSourceTooltip = true, extraObjectiveText = true, trackerLine = true }
M.STAGE = { beforeAcceptance = true, accepted = true, progress = true, completion = true, handIn = true, relog = true }
function M.CheckTextObservation(o, opts)
    guard(opts)
    local errs = {}
    local function err(s) errs[#errs + 1] = s end
    if type(o) ~= "table" then return false, { "observation: table required" } end
    if not M.TEXT_RESULT[o.result] then err("result: PASS, DIFFERENCE_TO_REVIEW or UNKNOWN only") end
    if not M.SURFACE[o.surface] then err("surface") end
    if not M.STAGE[o.stage] then err("stage: the stage actually tested") end
    if type(o.clientLocale) ~= "string" or not o.clientLocale:match("^%a%a%a%a$") then err("clientLocale: observed client locale required (e.g. enUS)") end
    if o.result == "PASS" then
        if o.availability ~= "verified" then err("PASS needs verified quest availability for the tested character") end
        if o.observed ~= true then err("PASS needs an actual in-game observation") end
        if o.textSource == "server-private" then err("private server text cannot be the public PASS reference") end
    end
    if o.availability ~= "verified" and o.result ~= "UNKNOWN" then err("unknown availability gives UNKNOWN") end
    if o.result == "DIFFERENCE_TO_REVIEW" and o.autoRewrite == true then err("no automatic text rewrite") end
    if o.autoRewrite ~= nil and o.autoRewrite ~= false then err("autoRewrite must be absent or false") end
    if o.m1Outcome ~= nil then err("text observations never set an M1/M2.3 outcome") end
    return #errs == 0, errs
end

return M
