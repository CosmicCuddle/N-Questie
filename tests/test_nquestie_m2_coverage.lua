-- M2.2 coverage / preflight: synthetic tests. Lua 5.1, no I/O.
-- Coverage must use the exporter's own refusal code (same reasons, same
-- messages), keep every reason per quest and reconcile to the total.
local Export = dofile("tools/validation/EffectiveExport.lua")
local Coverage = dofile("tools/validation/Coverage.lua")
local n, fails = 0, 0
local function ok(c, m) n = n + 1; if not c then fails = fails + 1; print("FAIL: " .. m) end end

-- Synthetic records shaped like the real compiled values (see
-- docs/NQ-VALIDATION-M2-EFFECTIVE-V2-DESIGN.md for the real examples).
local base = { requiredLevel = 10, questLevel = 12 }
local DB = {
    [1] = { objectives = { nil, nil, { { 100 } } } },                                   -- representable
    [2] = { objectives = { { { 7, "a" }, { 7, "b" } } } },                              -- DUPLICATE_CREATURE
    [3] = { objectives = { nil, { { 9 }, { 9 } } } },                                   -- DUPLICATE_OBJECT
    [4] = { objectives = { [4] = { 93, 3000 } } },                                      -- REPUTATION
    [5] = { extraObjectives = { { nil, 1, "slay", nil, { { "monster", 11 }, { "monster", 12 } } } } },
    [6] = { extraObjectives = { { nil, 4, "use", 2, { { "object", 21 } } } } },
    -- every v1 problem at once: all reasons must be kept
    [7] = { objectives = { { { 7 }, { 7 } }, { { 9 }, { 9 } }, nil, { 92 } },
            extraObjectives = { { nil, 3, "x", nil, { { "monster", 1 }, { "object", 2 } } } } },
    [8] = { requiredLevel = "x" },                                                      -- other identified
    [9] = { objectives = { { { 7 } }, [9] = {} } },                                     -- SHAPE_UNUSUAL
    [10] = { extraObjectives = { { nil, 3, "x", nil, { { "spell", 5 } } } } },          -- EXTRA_OTHER_REF
}
local function query(id, key)
    local r = DB[id]
    if key == "boom" then error("x") end
    if r[key] ~= nil then return r[key] end
    return base[key]
end
local ids = {}
for id in pairs(DB) do ids[#ids + 1] = id end
local function deep(v)
    if type(v) ~= "table" then return tostring(v) end
    local ks = {}
    for k in pairs(v) do ks[#ks + 1] = k end
    table.sort(ks, function(a, b) return tostring(a) < tostring(b) end)
    local o = {}
    for _, k in ipairs(ks) do o[#o + 1] = tostring(k) .. "=" .. deep(v[k]) end
    return "{" .. table.concat(o, ",") .. "}"
end
local before = deep(DB)
local res = Coverage.Run(Export, query, ids)
local byId = {}
for _, r in ipairs(res) do byId[r.id] = r end
ok(#res == 10 and res[1].id == 1 and res[10].id == 10, "sorted, all classified")
ok(byId[1].status == "REPRESENTABLE" and #byId[1].codes == 0, "1 representable")
local function codes(id) return table.concat(byId[id].codes, "+") end
ok(codes(2) == "DUPLICATE_CREATURE", "2 dup creature: " .. codes(2))
ok(codes(3) == "DUPLICATE_OBJECT", "3 dup object")
ok(codes(4) == "REPUTATION_OBJECTIVE", "4 reputation")
ok(codes(5) == "EXTRA_CREATURE_REF" and byId[5].counts.EXTRA_CREATURE_REF == 2, "5 extra monster x2 occurrences")
ok(codes(6) == "EXTRA_OBJECT_REF", "6 extra object")
ok(codes(7) == "DUPLICATE_CREATURE+DUPLICATE_OBJECT+EXTRA_CREATURE_REF+EXTRA_OBJECT_REF+REPUTATION_OBJECTIVE",
   "7 keeps ALL reasons: " .. codes(7))
ok(codes(8) == "LEVEL_INVALID" and Coverage.Category("LEVEL_INVALID") == "other_identified", "8 other identified")
ok(codes(9) == "SHAPE_UNUSUAL", "9 unusual slot")
ok(codes(10) == "EXTRA_OTHER_REF", "10 other extra type")

-- Same reasons and messages as the exporter (shared code path).
for _, r in ipairs(res) do
    local rec, errs, cs = Export.Record(query, r.id)
    if rec then ok(r.status == "REPRESENTABLE", "parity rep " .. r.id)
    else
        ok(#errs == #cs, "one code per message " .. r.id)
        ok(table.concat(errs, "|") == table.concat(r.messages, "|"), "identical messages " .. r.id)
        local u = Export.UniqueCodes(cs); table.sort(u)
        ok(table.concat(u, "+") == codes(r.id), "identical codes " .. r.id)
        for _, c in ipairs(cs) do ok(Export.REASONS[c] ~= nil, "code documented: " .. c) end
    end
end
-- Export refuses the same quests and reports the reasons.
local recs, errs, refused = Export.Snapshot(query, function(id) return DB[id] ~= nil end, { 1, 7 })
ok(recs == nil and refused and #refused == 1 and refused[1].id == 7, "export refuses unsupported id")
ok(errs[#errs]:find("refused, reasons: ", 1, true) ~= nil, "export summary line with reasons")
local _, e2, r2 = Export.Snapshot(query, function(id) return id ~= 99 end, { 99 })
ok(r2[1].codes[1] == "ABSENT_FROM_EFFECTIVE_DB", "absent quest reason")

-- Unexpected crash is unclassified, never representable.
local crash = Coverage.Classify({ Record = function() error("boom") end, UniqueCodes = Export.UniqueCodes }, query, 1)
ok(crash.status == "UNSUPPORTED" and crash.codes[1] == "UNEXPECTED_ERROR", "crash -> unclassified")
-- Refusal without codes (tool gap) becomes UNCLASSIFIED.
local gap = Coverage.Classify({ Record = function() return nil, { "x" }, nil end, UniqueCodes = Export.UniqueCodes,
    UNCLASSIFIED = "UNCLASSIFIED" }, query, 1)
ok(gap.codes[1] == "UNCLASSIFIED", "missing codes -> UNCLASSIFIED")

-- Aggregate reconciles.
local all = {}
for _, r in ipairs(res) do all[#all + 1] = r end
all[#all + 1] = crash
local a = Coverage.Aggregate(all)
ok(a.total == 11 and a.representable == 1 and a.unsupported == 10, "totals")
ok(a.unclassified == 1, "unclassified counted")
ok(a.reasonQuests.DUPLICATE_CREATURE == 2 and a.reasonOccurrences.DUPLICATE_CREATURE == 2, "dup creature counts")
ok(a.reasonQuests.EXTRA_CREATURE_REF == 2 and a.reasonOccurrences.EXTRA_CREATURE_REF == 3, "extra monster quests/occurrences")
ok(a.categoryQuests.other_identified == 3, "other identified (LEVEL_INVALID, SHAPE_UNUSUAL, EXTRA_OTHER_REF)")
local s = 0
for _, c in ipairs(a.combinations) do s = s + c.quests end
ok(s == a.unsupported and a.reconciled, "combinations reconcile")
local bad = { { id = 1, status = "REPRESENTABLE", codes = {}, counts = {} } }
ok(Coverage.Aggregate(bad).total == 1, "aggregate single")

-- Report labelling and manifest content.
local txt = Coverage.FormatAggregate(a, Export)
ok(txt:find("COVERAGE REPORT", 1, true) and txt:find("not an export", 1, true), "labelled as coverage, not export")
ok(not txt:find("ID = ", 1, true), "aggregate has no per-quest list")
local m = Coverage.Manifest(res, a, { sourceCommit = "x" })
ok(m.kind == "nq-m2-coverage-manifest" and #m.quests == 10 and m.quests[7].reasons[5] == "REPUTATION_OBJECTIVE", "manifest")
ok(m.quests[1].objectives == nil and m.quests[1].requiredLevel == nil, "manifest carries no effective records")
ok(pcall(Export.Serialize, m), "manifest serialisable")
-- Read-only: inputs unchanged.
local after = deep(DB)
ok(before == after, "no mutation of query results")

if fails > 0 then print("FAILED: M2.2 coverage (" .. fails .. " of " .. n .. ")") os.exit(1) end
print("PASS: M2.2 coverage (" .. n .. " checks)")
