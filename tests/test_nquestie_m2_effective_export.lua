#!/usr/bin/env lua5.1
-- M2.2 Step 2 unit tests: EffectiveExport on compiled shapes copied from the
-- public 3.3.5a DB. Live checks against the real compiled DB run in
-- tests/test_nquestie_m2_export_integration.sh.
local X = dofile("tools/validation/EffectiveExport.lua")
local E = dofile("tools/validation/EffectiveSchema.lua")
local Rules = dofile("tools/validation/ObjectiveRules.lua")
local shapes = dofile("tools/validation/fixtures/compiled_shapes.lua")

local failures, passes = 0, 0
local function fail(m) failures = failures + 1; io.stderr:write("FAIL: " .. m .. "\n") end
local function pass(m) passes = passes + 1; print("PASS: " .. m) end
local function deepCopy(t) if type(t) ~= "table" then return t end local c = {} for k, v in pairs(t) do c[k] = deepCopy(v) end return c end
local function eq(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do if not eq(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
local function query(id, key) return shapes[id] and shapes[id][key] end
local function exists(id) return shapes[id] ~= nil end
local PROV = {
    harness = "validate-335", harnessVersion = "1.0.0", dataKind = "effective",
    sourceCommit = string.rep("a", 40), sourceTree = string.rep("b", 40), sourceDirty = false,
    tocInterface = 30300, flavour = "wotlk-335", nQuestieDataRevision = 5, correctionCount = 28,
    correctionFingerprint = "sha256:" .. string.rep("c", 64), correctionModules = { "NQuestieCustomQuestData.lua" },
    m0Checks = 232, exportedAt = "2026-10-14T16:00:00Z", questCount = 0,
}
local function contains(errs, needle) return table.concat(errs or {}, " | "):find(needle, 1, true) ~= nil end

-- representable set
local before = deepCopy(shapes)
local ids = { 1203, 2001, 2784, 30, 25, 28 }
local recs, errs = X.Snapshot(query, exists, ids)
if not recs then fail("snapshot of representable set: " .. table.concat(errs, "; ")) os.exit(1) end
pass("snapshot of 6 representable quests")
if eq(before, shapes) then pass("compiled records unchanged (deep compare)") else fail("compiled records mutated") end
local byId = {} for i, r in ipairs(recs) do byId[r.ID] = r; if r.ID ~= ids[i] then fail("selection order not kept") end end
pass("records follow selection order")

local function check(c, m) if c then pass(m) else fail(m) end end
check(byId[1203].objectives.items[1] == 3853 and #byId[1203].objectives.items == 1, "1203 effective item objective is 3853")
check(byId[1203].requiredLevel == 30 and byId[1203].questLevel == 35, "1203 levels 30/35")
check(eq(byId[2001].objectives.creatures, { 1868, 1869 }), "2001 creatures 1868, 1869 in order")
check(eq(byId[2784].objectives.killCredit, { { ids = { 7572 }, rootId = 7572 } }), "2784 killCredit {7572} root 7572")
check(eq(byId[30].requiredSourceItems, { 15883, 15882 }) and byId[30].hasExtraObjectives and #byId[30].extraObjectiveItems == 0,
      "30 requiredSourceItems in order; extraObjectives present without item refs")
check(byId[25].hasTriggerEnd and not byId[25].hasExtraObjectives, "25 triggerEnd present")
check(#byId[28].objectives.creatures == 0 and #byId[28].objectives.items == 0 and byId[28].hasTriggerEnd, "28 empty objective lists")
check(byId[2784].sourceItemId == 0 and byId[1203].sourceItemId == 0, "absent sourceItemId exported as 0")

-- schema + serialise + parse round trip
local prov = deepCopy(PROV); prov.questCount = #recs
local doc = X.BuildDocument(recs, prov)
local ok, verrs = E.Validate(doc, { expectKind = "effective", expectCorrectionCount = 28 })
check(ok, "snapshot validates as nq-m2-effective v1" .. (verrs and (": " .. table.concat(verrs, "; ")) or ""))
local text = X.Serialize(doc, "synthetic test export")
local parsed, perr = E.ParseString(text)
check(parsed and eq(parsed, doc), "serialised text parses back identically" .. (perr and (": " .. perr[1]) or ""))
check(E.Validate(parsed), "parsed text validates")

-- back to M1 shape without losing what M1 uses
for _, r in ipairs(recs) do
    local qrec = E.ToQuestieRecord(r)
    local back = X.Record(function(_, key)
        local map = { requiredLevel = 4, questLevel = 5, objectives = 10, sourceItemId = 11, requiredSourceItems = 21,
                      triggerEnd = 9, extraObjectives = 27 }
        return qrec[map[key]]
    end, r.ID)
    if not back then fail("ToQuestieRecord -> Record failed for " .. r.ID)
    elseif not eq(back, r) then fail("round trip lost information for " .. r.ID)
    end
end
pass("ToQuestieRecord -> Record round trip keeps every v1 field for all 6 quests")

local server = Rules.FromQuestTemplateRow({ ID = 1203, RequiredItemId1 = 3853, RequiredItemCount1 = 1 })
check(Rules.Worst(Rules.Compare(server, E.ToQuestieRecord(byId[1203]))) ~= "CONFIRMED_MISMATCH", "M1: effective 1203 not confirmed")
local stockRec = X.Record(function(_, key) if key == "objectives" then return { nil, nil, { { 33110 } } } end
    return ({ requiredLevel = 30, questLevel = 35 })[key] end, 1203)
check(Rules.Worst(Rules.Compare(server, E.ToQuestieRecord(stockRec))) == "CONFIRMED_MISMATCH", "M1: stock-shaped 1203 (33110) still confirmed")

-- refusals: not representable in v1
for _, c in ipairs({
    { 1036, "reputation" }, { 1367, "reputation" }, { 1367, "'monster'" },
    { 11142, "500007 appears more than once" }, { 11706, "25768 appears more than once" },
}) do
    local r, e = X.Snapshot(query, exists, { c[1] })
    check(not r and contains(e, c[2]), "refuses quest " .. c[1] .. " (" .. c[2] .. ")")
end
local r, e = X.Snapshot(query, exists, { 1203, 1036 })
check(not r and contains(e, "1036"), "one unrepresentable quest refuses the whole snapshot")

-- selection errors
for _, c in ipairs({
    { {}, "empty" }, { { 1203, 1203 }, "duplicate quest ID 1203" }, { { 0 }, "invalid quest ID 0" },
    { { 1.5 }, "invalid quest ID" }, { { "1203" }, "invalid quest ID" }, { { [1] = 1203, [3] = 30 }, "holes" },
    { { 999999 }, "not in the compiled Questie database" }, { "1203", "must be a list" },
}) do
    r, e = X.Snapshot(query, exists, c[1])
    check(not r and contains(e, c[2]), "selection rejected: " .. c[2])
end
local list = X.ParseIdList("1203, 2001 30")
check(eq(list, { 1203, 2001, 30 }), "ParseIdList reads comma/space lists")
r, e = X.ParseIdList("1203,abc")
check(not r and contains(e, "abc"), "ParseIdList rejects non-numbers")

-- unusual shapes
local odd = {
    { "objective entry not a table", { objectives = { { 5 } } }, "unusual entry shape" },
    { "objective entry extra field", { objectives = { { { 5, "t", 9 } } } }, "unusual entry field" },
    { "objectives unusual slot", { objectives = { [7] = {} } }, "unusual slot 7" },
    { "killCredit bad shape", { objectives = { nil, nil, nil, nil, { { 7572 } } } }, "unusual shape" },
    { "killCredit empty ids", { objectives = { nil, nil, nil, nil, { { {}, 7572 } } } }, "empty ids" },
    { "spells duplicate", { objectives = { nil, nil, nil, nil, nil, { { 9 }, { 9 } } } }, "appears more than once" },
    { "requiredSourceItems duplicate", { requiredSourceItems = { 5, 5 } }, "appears more than once" },
    { "missing requiredLevel", { requiredLevel = false }, "requiredLevel is" },
    { "triggerEnd not a table", { triggerEnd = "x" }, "triggerEnd has unusual shape" },
    { "extraObjectives ref bad", { extraObjectives = { { nil, 1, "t", 0, { { "item" } } } } }, "unusual shape" },
}
for _, c in ipairs(odd) do
    local base = { requiredLevel = 1, questLevel = 1, objectives = {} }
    for k, v in pairs(c[2]) do base[k] = v end
    if base.requiredLevel == false then base.requiredLevel = nil end
    r, e = X.Record(function(_, key) return base[key] end, 900001)
    check(not r and contains(e, c[3]), "refuses " .. c[1])
end
local spellRec = X.Record(function(_, key) return ({ requiredLevel = 1, questLevel = -1,
    objectives = { nil, nil, nil, nil, nil, { { 9 }, { 10, "Cast it" } } } })[key] end, 900002)
check(spellRec and eq(spellRec.objectives.spells, { 9, 10 }) and spellRec.questLevel == -1, "spells and questLevel -1 exported")
local extraItems = X.Record(function(_, key) return ({ requiredLevel = 1, questLevel = 1, objectives = {},
    extraObjectives = { { nil, 1, "t", 0, { { "item", 5 }, { "item", 6 } } } } })[key] end, 900003)
check(extraItems and eq(extraItems.extraObjectiveItems, { 5, 6 }), "extraObjectives item refs exported in order")
r, e = X.Record(function(_, key) return ({ requiredLevel = 1, questLevel = 1, objectives = {},
    extraObjectives = { { nil, 1, "t", 0, { { "item", 5 } } }, { nil, 1, "u", 0, { { "item", 5 } } } } })[key] end, 900004)
check(not r and contains(e, "referenced more than once"), "refuses duplicate extraObjectives item refs")

if failures > 0 then io.stderr:write("FAILED: " .. failures .. "\n"); os.exit(1) end
print(string.format("PASS: M2.2 effective export (%d checks)", passes))
