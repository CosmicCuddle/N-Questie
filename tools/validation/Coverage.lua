-- N-Questie M2.2 coverage / preflight (read-only).
--
-- Reports which compiled Questie quests nq-m2-effective v1 can represent.
-- This is a COVERAGE REPORT, not an export: it produces no effective records.
-- Every quest is classified by calling EffectiveExport.Record, the exact code
-- path the exporter uses, so coverage reasons are the exporter's refusal
-- reasons (same codes, same messages). All reasons per quest are kept.
--
-- Pure: no file or process I/O. Lua 5.1 compatible.

local M = {}

M.KIND = "nq-m2-coverage"
M.VERSION = 1

-- Reason codes grouped as Michael's report categories.
M.CATEGORY = {
    EXTRA_CREATURE_REF = "extra_creature",
    EXTRA_OBJECT_REF = "extra_object",
    REPUTATION_OBJECTIVE = "reputation",
    DUPLICATE_CREATURE = "duplicate_creature",
    DUPLICATE_OBJECT = "duplicate_object",
    UNCLASSIFIED = "unclassified",
    UNEXPECTED_ERROR = "unclassified",
}
local OTHER = "other_identified"

function M.Category(code) return M.CATEGORY[code] or OTHER end

-- Classify one quest. Never raises: an error inside Record is reported as
-- UNEXPECTED_ERROR (unclassified), never as representable.
function M.Classify(Export, query, id)
    local ok, rec, errs, codes = pcall(Export.Record, query, id)
    if not ok then
        return { id = id, status = "UNSUPPORTED", codes = { "UNEXPECTED_ERROR" },
                 counts = { UNEXPECTED_ERROR = 1 }, messages = { "quest " .. tostring(id) .. ": " .. tostring(rec) } }
    end
    if rec then return { id = id, status = "REPRESENTABLE", codes = {}, counts = {}, messages = {} } end
    local counts = {}
    codes = codes or {}
    if #codes ~= #(errs or {}) or #codes == 0 then
        -- Defensive: refusal without codes is a tool gap, never dropped.
        codes = { Export.UNCLASSIFIED }
    end
    for _, c in ipairs(codes) do counts[c] = (counts[c] or 0) + 1 end
    local u = Export.UniqueCodes(codes)
    table.sort(u)
    return { id = id, status = "UNSUPPORTED", codes = u, counts = counts, messages = errs or {} }
end

-- Classify every id in ids (sorted ascending copy).
function M.Run(Export, query, ids)
    local list = {}
    for i, id in ipairs(ids) do list[i] = id end
    table.sort(list)
    local results = {}
    for i, id in ipairs(list) do results[i] = M.Classify(Export, query, id) end
    return results
end

-- Aggregate results. Raises if the numbers do not reconcile.
function M.Aggregate(results)
    local a = { kind = M.KIND .. "-aggregate", version = M.VERSION, total = #results,
                representable = 0, unsupported = 0, unclassified = 0,
                reasonQuests = {}, reasonOccurrences = {}, categoryQuests = {}, combinations = {} }
    local combo = {}
    for _, r in ipairs(results) do
        if r.status == "REPRESENTABLE" then a.representable = a.representable + 1
        else
            a.unsupported = a.unsupported + 1
            local cats, catList, unc = {}, {}, false
            for _, c in ipairs(r.codes) do
                a.reasonQuests[c] = (a.reasonQuests[c] or 0) + 1
                a.reasonOccurrences[c] = (a.reasonOccurrences[c] or 0) + (r.counts[c] or 1)
                local cat = M.Category(c)
                if cat == "unclassified" then unc = true end
                if not cats[cat] then cats[cat] = true; catList[#catList + 1] = cat end
            end
            if unc then a.unclassified = a.unclassified + 1 end
            for _, cat in ipairs(catList) do a.categoryQuests[cat] = (a.categoryQuests[cat] or 0) + 1 end
            local key = table.concat(r.codes, "+")
            combo[key] = (combo[key] or 0) + 1
        end
    end
    local keys = {}
    for k in pairs(combo) do keys[#keys + 1] = k end
    table.sort(keys)
    local sum = 0
    for _, k in ipairs(keys) do
        a.combinations[#a.combinations + 1] = { codes = k, quests = combo[k] }
        sum = sum + combo[k]
    end
    assert(a.representable + a.unsupported == a.total, "coverage: representable + unsupported ~= total")
    assert(sum == a.unsupported, "coverage: combinations do not sum to unsupported")
    a.reconciled = true
    return a
end

-- Human-readable aggregate (public: counts only, no per-quest list).
function M.FormatAggregate(a, Export)
    local out = {}
    local function p(s) out[#out + 1] = s end
    p("N-Questie M2.2 COVERAGE REPORT (nq-m2-effective v1) - not an export")
    p(string.format("total quests            %d", a.total))
    p(string.format("v1 representable        %d", a.representable))
    p(string.format("v1 unsupported (unique) %d", a.unsupported))
    p(string.format("unclassified            %d", a.unclassified))
    p("by reason code (quests / occurrences):")
    local codes = {}
    for c in pairs(a.reasonQuests) do codes[#codes + 1] = c end
    table.sort(codes)
    for _, c in ipairs(codes) do
        p(string.format("  %-24s %5d / %5d  [%s] %s", c, a.reasonQuests[c], a.reasonOccurrences[c],
            M.Category(c), (Export and Export.REASONS[c]) or ""))
    end
    p("by category (quests):")
    local cats = {}
    for c in pairs(a.categoryQuests) do cats[#cats + 1] = c end
    table.sort(cats)
    for _, c in ipairs(cats) do p(string.format("  %-26s %5d", c, a.categoryQuests[c])) end
    p("reason combinations (quests):")
    for _, c in ipairs(a.combinations) do p(string.format("  %-60s %5d", c.codes, c.quests)) end
    p("reconciled: representable + unsupported = total; combinations sum to unsupported")
    return table.concat(out, "\n") .. "\n"
end

-- Per-quest manifest document (PRIVATE paths only; written via SafeWrite).
function M.Manifest(results, aggregate, provenance)
    local quests = {}
    for i, r in ipairs(results) do
        quests[i] = { ID = r.id, status = r.status, reasons = r.codes }
    end
    return { kind = M.KIND .. "-manifest", version = M.VERSION,
             note = "Coverage report, not an export. Contains no effective records.",
             provenance = provenance, aggregate = aggregate, quests = quests }
end

return M
