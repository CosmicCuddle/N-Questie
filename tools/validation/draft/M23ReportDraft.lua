-- DRAFT validators for the proposed M2.3 contracts. Design validation only:
-- this is NOT the M2.3 comparison engine. It never reads server data or
-- files, never runs M1 and never writes anything. It checks
--   * the selection protocol (PreflightSplit, PlanSelection) on synthetic
--     ID sets, so the batch-rejection and status rules are executable;
--   * the private report, the aggregate, the bundle and the fixed stderr codes.
-- Rules: docs/NQ-VALIDATION-M2.3-DESIGN.md. Lua 5.1.
local M = { DRAFT = true }

-- Report export statuses (successful report only).
M.EXPORT_STATUS = { ABSENT_FROM_EFFECTIVE_DB = true, UNSUPPORTED_BY_SCHEMA_VERSION = true, EXPORTED = true }
-- Batch rejection codes: appear only as fixed stderr lines (nq-m2-3: CODE),
-- never in a report. REJECTED_MALFORMED_INPUT is batch-level only.
M.REJECTION = { REJECTED_MALFORMED_INPUT = true, REJECTED_DUPLICATE_ID = true, REJECTED_PAIRING = true,
    REJECTED_MEMBERSHIP = true, REJECTED_SELECTION_MISMATCH = true, REJECTED_MANIFEST_INCOMPLETE = true,
    REJECTED_INPUT_CHANGED = true, REJECTED_UNSAFE_OUTPUT = true,
    -- v1 cannot write zero records (questCount > 0): a v1 batch whose preflight
    -- v1Request is empty is refused; such selections need a full v2 export.
    REJECTED_V1_SELECTION_EMPTY_AFTER_PREFLIGHT = true }
M.OUTCOME = { M1_UNSUPPORTED_BY_RULES = true, NEEDS_MANUAL_REVIEW = true,
    EXPECTED_REPRESENTATION_DIFF = true, CONFIRMED_MATCH = true, CONFIRMED_MISMATCH = true }
-- M1 finding classes (tools/validation/ObjectiveRules.lua M.CLASS, unchanged).
M.M1_CLASS = { CONFIRMED_MISMATCH = true, EXPECTED_REPRESENTATION_DIFF = true, NEEDS_MANUAL_REVIEW = true, UNSUPPORTED = true }
M.EVIDENCE = { "killCredit", "conditions", "scripts", "ip", "objectiveData" }
-- Closed, versioned reason-code vocabulary (= EffectiveExport.REASONS keys,
-- checked by the test). Aggregates may use only these keys.
M.REASON_VOCAB_VERSION = 1
M.REASON_CODES = {}
for _, c in ipairs({ "DUPLICATE_CREATURE", "DUPLICATE_EXTRA_ITEM", "DUPLICATE_ITEM", "DUPLICATE_KILLCREDIT_ID",
    "DUPLICATE_OBJECT", "DUPLICATE_SOURCE_ITEM", "DUPLICATE_SPELL", "EXTRA_CREATURE_REF", "EXTRA_OBJECT_REF",
    "EXTRA_OTHER_REF", "KILLCREDIT_FIRST_REORDER", "LEVEL_INVALID", "QUERY_FAILED", "REPUTATION_OBJECTIVE",
    "SHAPE_UNUSUAL", "SOURCE_ITEM_INVALID", "UNCLASSIFIED" }) do M.REASON_CODES[c] = true end

local function guard(opts)
    if not (type(opts) == "table" and opts.allowDraft == true) then
        error("M23ReportDraft is a draft; pass { allowDraft = true }", 2)
    end
end
local function isId(v) return type(v) == "number" and v == math.floor(v) and v > 0 end

-- A proper ID list: dense array, positive integers, no duplicates.
function M.CheckIdList(list, what)
    local errs = {}
    if type(list) ~= "table" then return false, { what .. ": list required" } end
    local n, seen = 0, {}
    for k in pairs(list) do
        n = n + 1
        if not isId(k) then errs[#errs + 1] = what .. ": non-array key" end
    end
    if n ~= #list then errs[#errs + 1] = what .. ": sparse list (holes)" end
    for i = 1, #list do
        local v = list[i]
        if not isId(v) then errs[#errs + 1] = what .. "[" .. i .. "]: positive integer required"
        elseif seen[v] then errs[#errs + 1] = what .. ": duplicate ID " .. v
        else seen[v] = true end
    end
    return #errs == 0, errs
end

-- manifest = { complete = true, expectedCount = 9159, quests = { [id] = { status = "REPRESENTABLE"|"UNSUPPORTED", reasons = {...} } } }
local function checkManifest(manifest)
    if type(manifest) ~= "table" or type(manifest.quests) ~= "table" then return "REJECTED_MALFORMED_INPUT", "manifest" end
    local n = 0
    for id, q in pairs(manifest.quests) do
        n = n + 1
        if not isId(id) or type(q) ~= "table" then return "REJECTED_MALFORMED_INPUT", "manifest entry" end
        if q.status == "REPRESENTABLE" then
            if type(q.reasons) ~= "table" or #q.reasons ~= 0 then return "REJECTED_MALFORMED_INPUT", "representable with reasons" end
        elseif q.status == "UNSUPPORTED" then
            if type(q.reasons) ~= "table" or #q.reasons == 0 then return "REJECTED_MALFORMED_INPUT", "unsupported without reasons" end
            for _, r in ipairs(q.reasons) do if not M.REASON_CODES[r] then return "REJECTED_MALFORMED_INPUT", "unknown reason code" end end
        else return "REJECTED_MALFORMED_INPUT", "manifest status" end
    end
    -- Absence can only be proven by a complete manifest of the pinned size.
    if manifest.complete ~= true or not isId(manifest.expectedCount) or n ~= manifest.expectedCount then
        return "REJECTED_MANIFEST_INCOMPLETE", "manifest does not prove full-DB membership"
    end
end

-- Mixed-selection protocol: split a server selection BEFORE any export, so
-- the frozen all-or-nothing v1 exporter is only ever asked for
-- REPRESENTABLE IDs. Returns the exact v1 request and the other groups.
function M.PreflightSplit(serverIds, manifest, opts)
    guard(opts)
    local ok, e = M.CheckIdList(serverIds, "server selection")
    if not ok then return nil, "REJECTED_DUPLICATE_ID", e end
    local code, why = checkManifest(manifest)
    if code then return nil, code, { why } end
    local split = { v1Request = {}, unsupported = {}, absent = {} }
    for _, id in ipairs(serverIds) do
        local q = manifest.quests[id]
        if not q then split.absent[#split.absent + 1] = id
        elseif q.status == "UNSUPPORTED" then split.unsupported[#split.unsupported + 1] = id
        else split.v1Request[#split.v1Request + 1] = id end
    end
    for _, t in pairs(split) do table.sort(t) end
    return split
end

-- Selection plan: proves the exact ID sets and assigns one export status per
-- selected quest, or rejects the whole batch with one rejection code.
-- export = { schemaVersion = 1|2, ids = {...} }
function M.PlanSelection(serverIds, manifest, export, opts)
    guard(opts)
    local split, code, e = M.PreflightSplit(serverIds, manifest, opts)
    if not split then return nil, code, e end
    if type(export) ~= "table" or (export.schemaVersion ~= 1 and export.schemaVersion ~= 2) then
        return nil, "REJECTED_MALFORMED_INPUT", { "effective export version" }
    end
    local ok, ee = M.CheckIdList(export.ids, "effective export")
    if not ok then return nil, "REJECTED_DUPLICATE_ID", ee end
    local inExport = {}
    for _, id in ipairs(export.ids) do
        local q = manifest.quests[id]
        if not q then return nil, "REJECTED_MEMBERSHIP", { "exported quest " .. id .. " not in manifest" } end
        if export.schemaVersion == 1 and q.status == "UNSUPPORTED" then
            return nil, "REJECTED_MEMBERSHIP", { "v1 export contains manifest-UNSUPPORTED quest " .. id }
        end
        inExport[id] = true
    end
    if export.schemaVersion == 1 and #split.v1Request == 0 then
        return nil, "REJECTED_V1_SELECTION_EMPTY_AFTER_PREFLIGHT", { "no v1-representable quest selected; use a full v2 export" }
    end
    if export.schemaVersion == 1 then
        -- exact set: export == preflight v1Request
        if #export.ids ~= #split.v1Request then
            return nil, "REJECTED_SELECTION_MISMATCH", { "v1 export set differs from the preflight request" }
        end
        for _, id in ipairs(split.v1Request) do
            if not inExport[id] then
                return nil, "REJECTED_SELECTION_MISMATCH", { "representable quest " .. id .. " missing from selected export" }
            end
        end
    else
        for id in pairs(manifest.quests) do
            if not inExport[id] then return nil, "REJECTED_SELECTION_MISMATCH", { "v2 export must contain every manifest quest" } end
        end
    end
    local rows = {}
    for _, id in ipairs(serverIds) do
        local q = manifest.quests[id]
        if not q then rows[#rows + 1] = { questId = id, exportStatus = "ABSENT_FROM_EFFECTIVE_DB" }
        elseif export.schemaVersion == 1 and q.status == "UNSUPPORTED" then
            local r = {} for i, v in ipairs(q.reasons) do r[i] = v end
            rows[#rows + 1] = { questId = id, exportStatus = "UNSUPPORTED_BY_SCHEMA_VERSION", reasons = r }
        else
            rows[#rows + 1] = { questId = id, exportStatus = "EXPORTED", m1Supported = (q.status == "REPRESENTABLE") }
        end
    end
    return rows
end

local function complete(ev)
    if type(ev) ~= "table" then return false end
    for _, k in ipairs(M.EVIDENCE) do if ev[k] ~= "complete" then return false end end
    return true
end
local function classCount(classes, c)
    local n = 0
    for _, x in ipairs(classes) do if x == c then n = n + 1 end end
    return n
end

-- Outcome rules (design section 6). `m1Classes` lists the M1 class of every
-- finding; an empty list means no findings.
function M.OutcomeAllowed(row)
    local o, cls = row.outcome, row.m1Classes
    -- Support must be an explicit boolean. Only false may get
    -- M1_UNSUPPORTED_BY_RULES (and then carries no M1 findings); only true may
    -- get any other outcome. nil, "unknown" or anything else never passes.
    if row.m1Supported == false then
        return o == "M1_UNSUPPORTED_BY_RULES" and (cls == nil or (type(cls) == "table" and #cls == 0))
    end
    if row.m1Supported ~= true then return false end
    if o == "M1_UNSUPPORTED_BY_RULES" then return false end
    if type(cls) ~= "table" then return o == "NEEDS_MANUAL_REVIEW" end
    for _, c in ipairs(cls) do if not M.M1_CLASS[c] then return false end end
    if o == "NEEDS_MANUAL_REVIEW" then return true end -- conservative: always permitted
    if o == "CONFIRMED_MATCH" then
        return #cls == 0 and complete(row.evidence) and row.representationDiff ~= true
    end
    if o == "CONFIRMED_MISMATCH" then
        return classCount(cls, "CONFIRMED_MISMATCH") > 0 and classCount(cls, "NEEDS_MANUAL_REVIEW") == 0
            and classCount(cls, "UNSUPPORTED") == 0 and complete(row.evidence)
    end
    if o == "EXPECTED_REPRESENTATION_DIFF" then
        return #cls > 0 and classCount(cls, "EXPECTED_REPRESENTATION_DIFF") == #cls
    end
    return false
end

-- Closed key sets: extra fields are rejected (no free text, no private extras).
local REPORT_KEYS = { schema = 1, schemaVersion = 1, private = 1, selected = 1, rows = 1 }
local ROW_KEYS = { questId = 1, exportStatus = 1, m1Supported = 1, m1Classes = 1, representationDiff = 1,
    evidence = 1, outcome = 1, reasons = 1 }

function M.ValidateReport(doc, opts)
    guard(opts)
    local errs = {}
    local function err(s) errs[#errs + 1] = s end
    if type(doc) ~= "table" then return false, { "report: table required" } end
    if doc.schema ~= "nq-m2-3-report" or doc.schemaVersion ~= 1 then err("schema/schemaVersion") end
    if doc.private ~= true then err("private: must be true") end
    for k in pairs(doc) do if not REPORT_KEYS[k] then err("report: field not allowed: " .. tostring(k)) end end
    local okSel, se = M.CheckIdList(doc.selected, "selected")
    if not okSel then for _, x in ipairs(se) do err(x) end end
    if type(doc.rows) ~= "table" then err("rows required"); return false, errs end
    local sel, seen = {}, {}
    for _, id in ipairs(type(doc.selected) == "table" and doc.selected or {}) do sel[id] = true end
    for i, r in ipairs(doc.rows) do
        local w = "rows[" .. i .. "]"
        if type(r) ~= "table" then err(w .. ": table required"); r = {} end
        for k in pairs(r) do if not ROW_KEYS[k] then err(w .. ": field not allowed: " .. tostring(k)) end end
        if not (isId(r.questId) and sel[r.questId]) then err(w .. ".questId: not a selected ID") end
        if seen[r.questId] then err(w .. ": quest " .. tostring(r.questId) .. " appears twice") end
        seen[r.questId] = true
        if M.REJECTION[r.exportStatus] then
            err(w .. ".exportStatus: " .. r.exportStatus .. " is a batch rejection code, never a report status")
        elseif not M.EXPORT_STATUS[r.exportStatus] then err(w .. ".exportStatus: unknown") end
        if r.exportStatus == "EXPORTED" then
            if type(r.m1Supported) ~= "boolean" then err(w .. ".m1Supported: explicit true or false required for an EXPORTED row") end
            if not M.OUTCOME[r.outcome] then err(w .. ".outcome: EXPORTED quest needs exactly one known outcome")
            elseif not M.OutcomeAllowed(r) then err(w .. ": outcome " .. r.outcome .. " not supported by the M1 findings and evidence") end
        elseif r.outcome ~= nil then
            err(w .. ".outcome: only EXPORTED quests have an outcome")
        end
        if r.exportStatus == "UNSUPPORTED_BY_SCHEMA_VERSION" then
            if not (type(r.reasons) == "table" and #r.reasons > 0) then err(w .. ".reasons: unsupported quest needs its manifest reason codes") end
        elseif r.reasons ~= nil then err(w .. ".reasons: only unsupported quests carry reasons") end
        for _, c in ipairs(type(r.reasons) == "table" and r.reasons or {}) do
            if not M.REASON_CODES[c] then err(w .. ".reasons: unknown reason code") end
        end
    end
    for _, id in ipairs(type(doc.selected) == "table" and doc.selected or {}) do
        if not seen[id] then err("quest " .. id .. ": selected but missing from report (silent disappearance)") end
    end
    return #errs == 0, errs
end

-- Rejection output: there is NO rejection file. A rejected batch prints
-- exactly one fixed line per failed gate to stderr, "nq-m2-3: <CODE>", with
-- CODE from the closed REJECTION vocabulary. No paths, quest IDs, records,
-- labels or fingerprints.
M.STDERR_PREFIX = "nq-m2-3: "
function M.StderrLine(code)
    if not M.REJECTION[code] then error("StderrLine: code not in the closed vocabulary", 2) end
    return M.STDERR_PREFIX .. code
end
function M.CheckStderr(text, opts)
    guard(opts)
    local errs = {}
    if type(text) ~= "string" or text == "" then return false, { "stderr: at least one rejection line required" } end
    if text:find("/", 1, true) then errs[#errs + 1] = "stderr: path character '/'" end
    if text:find("%x%x%x%x%x%x%x%x") then
        errs[#errs + 1] = "stderr: hex run (possible fingerprint)"
    end
    for line in (text:sub(-1) == "\n" and text or text .. "\n"):gmatch("(.-)\n") do
        local code = line:sub(#M.STDERR_PREFIX + 1)
        if line:sub(1, #M.STDERR_PREFIX) ~= M.STDERR_PREFIX or not M.REJECTION[code] then
            errs[#errs + 1] = "stderr: line is not a fixed rejection code line"
        end
    end
    -- Digits may appear only inside the fixed prefix and codes.
    local stripped = text:gsub("nq%-m2%-3: ", ""):gsub("REJECTED_V1_SELECTION_EMPTY_AFTER_PREFLIGHT", "")
    if stripped:find("%d") then errs[#errs + 1] = "stderr: digits outside the code set" end
    return #errs == 0, errs
end

-- Atomic publication (design section 7a): report and aggregate travel as ONE
-- bundle file, published by a single no-clobber install. `fs` is an injected
-- set of primitives so failure and crash points can be simulated in tests.
--
-- Guarantee, stated precisely:
--   * implemented and tested: atomic VISIBILITY (a reader sees no file or the
--     complete file, never a partial one) and NO-CLOBBER (link(2) fails if the
--     final name exists). The shared tools/validation/SafeWrite.lua provides
--     both today (temp file, close, read-back, `ln` without -f).
--   * NOT guaranteed and NOT implemented: power-loss DURABILITY. SafeWrite
--     calls no fsync(2) on the file or the directory, so after a power cut
--     the final name may be missing or point at an incomplete file. This is
--     an open item that needs a future, separately approved implementation.
-- fs = { writeTemp(content) -> tmp|nil, closeTemp(tmp) -> ok, link(tmp, final) -> ok,
--        unlink(tmp) -> ok, exists(final) -> bool }
-- closeTemp is the close/read-back step only; it does not imply durability.

-- Deterministic canonical text of a value (sorted keys), used for the digest.
local function canon(v)
    local t = type(v)
    if t == "table" then
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys, function(x, y)
            if type(x) == type(y) then return x < y end
            return type(x) < type(y)
        end)
        local parts = {}
        for _, k in ipairs(keys) do parts[#parts + 1] = canon(k) .. "=" .. canon(v[k]) end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif t == "string" then return string.format("%q", v)
    else return tostring(v) end
end
-- Tamper digest: two independent 31-bit polynomial hashes over the canonical
-- text (pure Lua 5.1, no bit library). It detects any change made after
-- BuildBundle; it is NOT cryptographic and is never written to stderr.
local function digest(report, aggregate)
    local s = canon({ report = report, aggregate = aggregate })
    local h1, h2, m = 7, 11, 2147483647
    for i = 1, #s do
        local c = s:byte(i)
        h1 = (h1 * 31 + c) % m
        h2 = (h2 * 131 + c + i) % m
    end
    return string.format("d1:%d:%d:%d", #s, h1, h2)
end
M.Digest = digest

local BUNDLE_KEYS = { schema = 1, schemaVersion = 1, private = 1, report = 1, aggregate = 1, digest = 1 }

function M.BuildBundle(report, aggregate, opts)
    guard(opts)
    local ok1, e1 = M.ValidateReport(report, opts)
    if not ok1 then return nil, e1 end
    local ok2, e2 = M.ValidateAggregate(aggregate, report, opts)
    if not ok2 then return nil, e2 end
    return { schema = "nq-m2-3-bundle", schemaVersion = 1, private = true, report = report, aggregate = aggregate,
        digest = digest(report, aggregate) }
end

-- Full revalidation of a bundle: outer schema, closed keys, both inner parts
-- (schemas, closed codes, m1Supported rule, reconciliation per status,
-- outcome and reason) and the digest recorded at BuildBundle.
function M.ValidateBundle(bundle, opts)
    guard(opts)
    if type(bundle) ~= "table" then return false, { "bundle: table required" } end
    local errs = {}
    for k in pairs(bundle) do if not BUNDLE_KEYS[k] then errs[#errs + 1] = "bundle: field not allowed: " .. tostring(k) end end
    if bundle.schema ~= "nq-m2-3-bundle" or bundle.schemaVersion ~= 1 then errs[#errs + 1] = "bundle schema" end
    if bundle.private ~= true then errs[#errs + 1] = "bundle: private must be true" end
    if bundle.report == nil or bundle.aggregate == nil then
        errs[#errs + 1] = "bundle: report and aggregate both required"
        return false, errs
    end
    local ok1, e1 = M.ValidateReport(bundle.report, opts)
    if not ok1 then for _, x in ipairs(e1) do errs[#errs + 1] = x end end
    local ok2, e2 = M.ValidateAggregate(bundle.aggregate, bundle.report, opts)
    if not ok2 then for _, x in ipairs(e2) do errs[#errs + 1] = x end end
    if type(bundle.digest) ~= "string" or bundle.digest ~= digest(bundle.report, bundle.aggregate) then
        errs[#errs + 1] = "bundle: digest mismatch (modified after BuildBundle)"
    end
    return #errs == 0, errs
end

-- Fail closed: nothing is written unless the whole bundle revalidates.
function M.PublishBundle(bundle, finalPath, fs, serialise, opts)
    guard(opts)
    local okv = M.ValidateBundle(bundle, opts)
    if not okv then return false, "REJECTED_UNSAFE_OUTPUT" end
    if fs.exists(finalPath) then return false, "REJECTED_UNSAFE_OUTPUT" end
    local tmp = fs.writeTemp(serialise(bundle))
    if not tmp then return false, "REJECTED_UNSAFE_OUTPUT" end
    if not fs.closeTemp(tmp) then fs.unlink(tmp); return false, "REJECTED_UNSAFE_OUTPUT" end
    if not fs.link(tmp, finalPath) then fs.unlink(tmp); return false, "REJECTED_UNSAFE_OUTPUT" end
    fs.unlink(tmp) -- a failure here leaves a stray temp beside a complete final file
    return true
end

-- Aggregate: counts only, closed key sets, exact reconciliation.
local AGG_KEYS = { schema = 1, schemaVersion = 1, reasonVocabVersion = 1, selectedCount = 1, exportStatus = 1, outcome = 1, reasons = 1 }
function M.ValidateAggregate(agg, report, opts)
    guard(opts)
    local errs = {}
    local function err(s) errs[#errs + 1] = s end
    if type(agg) ~= "table" then return false, { "aggregate: table required" } end
    for k in pairs(agg) do if not AGG_KEYS[k] then err("aggregate: field not allowed: " .. tostring(k)) end end
    if agg.schema ~= "nq-m2-3-aggregate" or agg.schemaVersion ~= 1 then err("aggregate schema") end
    if agg.reasonVocabVersion ~= M.REASON_VOCAB_VERSION then err("aggregate: reasonVocabVersion must be " .. M.REASON_VOCAB_VERSION) end
    local function counts(t, enum, w)
        local sum = 0
        if type(t) ~= "table" then err(w .. ": table required"); return 0 end
        for k, v in pairs(t) do
            if type(k) ~= "string" or not enum[k] then err(w .. ": key not in the closed vocabulary")
            elseif not (type(v) == "number" and v == math.floor(v) and v >= 0) then err(w .. "." .. k .. ": count")
            else sum = sum + v end
        end
        return sum
    end
    local s1 = counts(agg.exportStatus, M.EXPORT_STATUS, "exportStatus")
    local s2 = counts(agg.outcome, M.OUTCOME, "outcome")
    counts(agg.reasons, M.REASON_CODES, "reasons")
    if s1 ~= agg.selectedCount then err("exportStatus counts do not sum to selectedCount") end
    if s2 ~= ((type(agg.exportStatus) == "table" and agg.exportStatus.EXPORTED) or 0) then err("outcome counts do not sum to EXPORTED") end
    if type(report) ~= "table" or type(report.rows) ~= "table" then
        err("aggregate: the private report is required for reconciliation")
    else
        local es, oc, rc = {}, {}, {}
        for _, r in ipairs(report.rows) do
            es[r.exportStatus] = (es[r.exportStatus] or 0) + 1
            if r.outcome then oc[r.outcome] = (oc[r.outcome] or 0) + 1 end
            for _, c in ipairs(type(r.reasons) == "table" and r.reasons or {}) do rc[c] = (rc[c] or 0) + 1 end
        end
        local function same(a, b, enum, w)
            for k in pairs(enum) do
                if (a[k] or 0) ~= ((type(b) == "table" and b[k]) or 0) then err("aggregate differs from report: " .. w .. "." .. k) end
            end
        end
        same(es, agg.exportStatus, M.EXPORT_STATUS, "exportStatus")
        same(oc, agg.outcome, M.OUTCOME, "outcome")
        same(rc, agg.reasons, M.REASON_CODES, "reasons")
        if agg.selectedCount ~= #report.selected then err("aggregate selectedCount differs from report") end
    end
    return #errs == 0, errs
end

return M
