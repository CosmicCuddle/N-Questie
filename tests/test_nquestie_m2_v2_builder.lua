-- Stage A1: synthetic tests for EffectiveExportV2 (record builder) and
-- RoundTripV2 (in-memory round trip). Synthetic compiled-shaped data only.
-- Positive shapes, negative (fail-closed) inputs, tampered records,
-- aliasing/mutation, determinism. Lua 5.1.
package.path = "./?.lua;" .. package.path
local V2 = dofile("tools/validation/EffectiveExportV2.lua")
local RT = dofile("tools/validation/RoundTripV2.lua")
local V1 = dofile("tools/validation/EffectiveExport.lua")
local Draft = dofile("tools/validation/draft/EffectiveSchemaV2Draft.lua")
local S = dofile("tests/fixtures/m2_v2_builder/compiled_synthetic.lua")

local n, fails = 0, 0
local function ok(c, m) n = n + 1; if not c then fails = fails + 1; print("FAIL: " .. m) end end
local function copy(t) if type(t) ~= "table" then return t end local o = {} for k, v in pairs(t) do o[k] = copy(v) end return o end
local function same(a, b) return #RT.Compare(a, b) == 0 end
local function has(errs, s) for _, e in ipairs(errs or {}) do if e:find(s, 1, true) then return true end end return false end
local function dbQuery(db) return function(id, key) local q = db[id]; if q == nil then return nil end return q[key] end end
local CTX = { killCreditFirst = S.killCreditFirst }
local Q = dbQuery(S.quests)
local function build(id, db, ctx) return V2.BuildRecord(db and dbQuery(db) or Q, id, ctx or CTX) end
local function obj(rec, i) return rec.objectives[i] end

-- ---------------------------------------------------------------- positive
local r1 = build(910001)
ok(r1 ~= nil, "910001 builds")
ok(same(r1, {
    ID = 910001, requiredLevel = 20, questLevel = 22, sourceItemId = 0, requiredSourceItems = {},
    objectives = {
        { position = 1, kind = "creature", slotIndex = 1, id = 101, occurrence = 1 },
        { position = 2, kind = "object", slotIndex = 1, id = 201, occurrence = 1 },
        { position = 3, kind = "item", slotIndex = 1, id = 301, occurrence = 1 },
        { position = 4, kind = "reputation", slotIndex = 1, factionId = 72, requiredValue = 0 },
        { position = 5, kind = "killCredit", slotIndex = 1, ids = { 401, 402, 403 }, rootId = 401 },
        { position = 6, kind = "spell", slotIndex = 1, id = 501, occurrence = 1 } },
    killCreditFirst = false, hasTriggerEnd = true,
    extraObjectives = { { position = 1, icon = 2, hasText = true, spawnZones = {}, objectiveIndex = 6,
        refs = { { type = "object", id = 202, refIndex = 1 } } } },
    m1Status = "UNSUPPORTED_BY_RULES", m1Reasons = { "EXTRA_OBJECT_REF", "REPUTATION_OBJECTIVE" } }),
    "910001 exact record: six kinds in Questie order, reputation value 0 kept, no text exported")

local r2 = build(910002)
ok(r2 and r2.sourceItemId == 701 and same(r2.requiredSourceItems, { 701, 702 }) and #r2.objectives == 1
   and r2.m1Status == "SUPPORTED", "910002 source item and requiredSourceItems kept even when also an item objective")

local r3 = build(910003)
ok(r3 and r3.killCreditFirst == true and obj(r3, 1).slotIndex == 3 and obj(r3, 2).slotIndex == 2 and obj(r3, 3).slotIndex == 1
   and obj(r3, 1).rootId == 803 and obj(r3, 3).position == 3, "910003 killCreditFirst: three killCredit entries reversed")
ok(r3 and r3.sourceItemId == 0, "910003 absent sourceItemId exported as 0")
ok(r3 and same(r3.m1Reasons, { "KILLCREDIT_FIRST_REORDER" }), "910003 KILLCREDIT_FIRST_REORDER reason")

local r4 = build(910004)
ok(r4 and obj(r4, 1).kind == "killCredit" and same(obj(r4, 1).ids, { 811, 812 }) and obj(r4, 2).kind == "creature",
   "910004 killCredit inserted before the creature")

local r5, r6 = build(910005), build(910006)
ok(r5 and #r5.objectives == 0 and #r5.extraObjectives == 0 and same(r5.requiredSourceItems, {}) and r5.m1Status == "SUPPORTED",
   "910005 empty objectives table: exported, not dropped")
ok(r6 and #r6.objectives == 0, "910006 absent objectives: exported, not dropped")

local r7 = build(910007)
local occ = {}
for _, o in ipairs(r7 and r7.objectives or {}) do occ[#occ + 1] = o.kind .. o.id .. "#" .. o.occurrence end
ok(table.concat(occ, ",") == "creature901#1,creature902#1,creature901#2,creature901#3,creature901#4,object903#1,object903#2",
   "910007 repeated IDs kept in compiled order with occurrence numbers: " .. table.concat(occ, ","))
ok(r7 and same(r7.m1Reasons, { "DUPLICATE_CREATURE", "DUPLICATE_OBJECT" }), "910007 duplicate reasons")

local r8 = build(910008)
ok(r8 and same(r8.extraObjectives[1].spawnZones, { 1, 12, 440 }) and #r8.extraObjectives[1].refs == 0,
   "910008 spawn-only extra: zones sorted, no coordinates, no refs")

local r9 = build(910009)
local refs = {}
for _, e in ipairs(r9 and r9.extraObjectives or {}) do
    for _, x in ipairs(e.refs) do refs[#refs + 1] = e.position .. ":" .. x.refIndex .. x.type .. x.id end
end
ok(table.concat(refs, ",") == "1:1monster907,1:2object908,1:3item909,1:4monster907,2:1monster910",
   "910009 every extra ref kept in order, repeats kept: " .. table.concat(refs, ","))
ok(r9 and r9.extraObjectives[1].hasText == false and r9.extraObjectives[2].hasText == true, "910009 extra hasText")

ok(build(910010) ~= nil, "910010 objectiveIndex 1 with no DB objectives (client quest-log line) built")
ok(build(910011) ~= nil, "910011 objectiveIndex = objectives + 1 naming the triggerEnd event line built")
local r12 = build(910012)
ok(r12 and r12.questLevel == -1 and obj(r12, 1).requiredValue == -42000, "910012 scaling level -1 and negative reputation kept")
local r14 = build(910014)
ok(r14 and r14.m1Status == "SUPPORTED" and r14.extraObjectives[1].refs[1].type == "item", "910014 v1-representable with item extra")

-- Every synthetic non-conflict quest passes the full round trip.
local ids, clean = {}, {}
for id in pairs(S.quests) do ids[#ids + 1] = id; if not S.conflicts[id] then clean[#clean + 1] = id end end
table.sort(ids); table.sort(clean)
local results, agg = RT.Run(Q, clean, CTX)
ok(agg.processed == #clean and agg.built == #clean and agg.buildErrors == 0 and agg.validateErrors == 0,
   "round trip: every clean synthetic quest built and valid")
ok(agg.questsDiffering == 0 and agg.diffs == 0 and agg.v1Differing == 0 and agg.expectedM1Disagree == 0,
   "round trip: 0 differences, 0 v1 differences, m1 agrees")
ok(agg.refs == 9 and agg.refsByType.monster == 5 and agg.refsByType.object == 2 and agg.refsByType.item == 2,
   "aggregate counts refs by type (monster 5, object 2, item 2): " .. agg.refs)
ok(agg.reputation == 2 and agg.reputationZero == 1 and agg.killCreditFirstQuests == 3 and agg.killCreditFirstFlaggedSingle == 1 and agg.duplicateOccurrences == 4
   and agg.spawnOnlyEntries == 1 and agg.objectiveIndexLogOnly == 2 and agg.scalingLevel == 1,
   "aggregate counts reputation, zero values, killCreditFirst, duplicates, spawn-only, log-only index, scaling")
ok(agg.supported + agg.unsupported == #clean, "statuses sum to quests")

-- BuildAll: sorted, each once
local all = V2.BuildAll(Q, { 910014, 910001, 910005 }, CTX)
ok(all and all[1].ID == 910001 and all[2].ID == 910005 and all[3].ID == 910014, "BuildAll returns records sorted by ID")

-- Determinism: same input in a different table insertion order -> identical records
local function rebuildDb()
    local db = {}
    local keys = {}
    for id in pairs(S.quests) do keys[#keys + 1] = id end
    table.sort(keys, function(a, b) return a > b end)
    for _, id in ipairs(keys) do db[id] = copy(S.quests[id]) end
    local sp = db[910008].extraObjectives[1][1]
    db[910008].extraObjectives[1][1] = { [440] = sp[440], [1] = sp[1], [12] = sp[12] }
    return db
end
local db2 = rebuildDb()
local c1 = Draft.Canonical({ quests = V2.BuildAll(Q, clean, CTX) }, {}, { allowDraft = true })
local c2 = Draft.Canonical({ quests = V2.BuildAll(dbQuery(db2), clean, CTX) }, {}, { allowDraft = true })
ok(c1 == c2, "deterministic: different insertion order gives an identical canonical result")
local _, aggB = RT.Run(Q, clean, CTX)
ok(RT.FormatAggregate(agg) == RT.FormatAggregate(aggB), "deterministic: repeated round trip aggregate identical")

-- No mutation, no aliasing
local before = copy(S.quests)
local rr = V2.BuildAll(Q, ids, CTX) or V2.BuildAll(Q, clean, CTX)
RT.Run(Q, ids, CTX)
ok(same(S.quests, before), "source data unchanged after building and round trip")
local rA = build(910001)
rA.objectives[5].ids[1] = 999999; rA.requiredSourceItems[1] = 1; rA.extraObjectives[1].refs[1].id = 1
ok(same(S.quests, before), "mutating a built record does not change the source (deep copies)")
local rB = build(910001)
ok(rB.objectives[5].ids ~= S.quests[910001].objectives[5][1][1], "killCredit ids list is a copy, not the source table")
local dbM = copy(S.quests)
local rC = build(910009, dbM)
dbM[910009].extraObjectives[1][5][1][2] = 1; dbM[910009].objectives[1][1][1] = 2
ok(rC.extraObjectives[1].refs[1].id == 907 and rC.objectives[1].id == 905, "changing the source after building does not change the record")
local _ = rr

-- Former conflicts (decision t54u): v2 ExpectedM1 now agrees with v1.
local r13 = build(910013)
ok(r13 and r13.killCreditFirst == true and r13.m1Status == "SUPPORTED" and #r13.m1Reasons == 0,
   "910013 single killCredit under killCreditFirst: flag kept, SUPPORTED (nothing reorders, as v1)")
local r15 = build(910015)
ok(r15 and #r15.requiredSourceItems == 3 and r15.requiredSourceItems[3] == 701 and r15.m1Status == "UNSUPPORTED_BY_RULES"
   and table.concat(r15.m1Reasons, "+") == "DUPLICATE_SOURCE_ITEM",
   "910015 repeated requiredSourceItems: every occurrence kept, DUPLICATE_SOURCE_ITEM as v1")
for _, id in ipairs({ 910013, 910015 }) do
    local res = RT.Check(Q, id, CTX)
    ok(res.record and res.validateError == nil and res.expectedM1Agrees == true, id .. ": ExpectedM1 agrees with v1, record valid")
end
local _, aggC = RT.Run(Q, ids, CTX)
ok(aggC.expectedM1Disagree == 0 and aggC.validateErrors == 0 and aggC.diffs == 0, "all synthetic quests: 0 disagreements, 0 errors")
-- A disagreement still fails closed.
do
    local t = build(910013); t.m1Reasons = { "KILLCREDIT_FIRST_REORDER" }; t.m1Status = "UNSUPPORTED_BY_RULES"
    ok(not Draft.ValidateQuest(t, { allowDraft = true }), "record whose m1 differs from ExpectedM1 is rejected (fail closed)")
end

-- ---------------------------------------------------------------- negative inputs
local function bad(label, mutateDb, want, id, ctx)
    local db = copy(S.quests)
    mutateDb(db)
    local rec, errs = V2.BuildRecord(dbQuery(db), id or 910001, ctx or CTX)
    ok(rec == nil and (want == nil or has(errs, want)), "fail closed: " .. label .. " (" .. table.concat(errs or { "built!" }, "; ") .. ")")
end
for _, badId in ipairs({ 0, -1, 1.5, 2147483648 }) do
    local rec = V2.BuildRecord(Q, badId, CTX)
    ok(rec == nil, "invalid quest ID refused: " .. tostring(badId))
end
ok(V2.BuildRecord(Q, "910001", CTX) == nil, "string quest ID refused")
ok(V2.BuildRecord(nil, 910001, CTX) == nil, "missing query function refused")
ok(V2.BuildAll(Q, {}, CTX) == nil, "BuildAll: empty list refused")
ok(V2.BuildAll(Q, { 910001, 910001 }, CTX) == nil, "BuildAll: duplicate ID refused")
ok(V2.BuildAll(Q, { 910001, nil, 910002 }, CTX) == nil or #({ 910001, nil, 910002 }) ~= 3, "BuildAll: list with holes refused")
ok(V2.BuildAll(Q, { 910001, 0 }, CTX) == nil, "BuildAll: invalid ID refused")
ok(V2.BuildAll(Q, { 910001, 910002 }, CTX) ~= nil, "BuildAll: valid list accepted")
do
    local db = copy(S.quests); db[910002].requiredLevel = "x"
    ok(V2.BuildAll(dbQuery(db), { 910001, 910002 }, CTX) == nil, "BuildAll: one bad record fails the whole batch")
end
-- missing context / killCreditFirst metadata
bad("killCreditFirst context missing", function() end, "killCreditObjectiveFirst", 910003, {})
bad("killCreditFirst set empty", function() end, "killCreditObjectiveFirst", 910003, { killCreditFirst = {} })
bad("killCreditFirst set with non-true value", function() end, "killCreditObjectiveFirst", 910003, { killCreditFirst = { [910003] = 1 } })
ok(V2.BuildRecord(Q, 910003, nil) == nil, "nil context refused")
-- missing / invalid fields
bad("requiredLevel missing", function(d) d[910001].requiredLevel = nil end, "requiredLevel")
bad("questLevel missing", function(d) d[910001].questLevel = nil end, "questLevel")
bad("requiredLevel not integer", function(d) d[910001].requiredLevel = 20.5 end, "requiredLevel")
bad("questLevel below -1", function(d) d[910001].questLevel = -2 end, "questLevel")
bad("sourceItemId negative", function(d) d[910001].sourceItemId = -1 end, "sourceItemId")
bad("sourceItemId wrong type", function(d) d[910001].sourceItemId = "701" end, "sourceItemId")
bad("requiredSourceItems not a list", function(d) d[910001].requiredSourceItems = { a = 1 } end, "requiredSourceItems")
bad("requiredSourceItems bad id", function(d) d[910001].requiredSourceItems = { 0 } end, "requiredSourceItems")
bad("objectives not a table", function(d) d[910001].objectives = "x" end, "objectives is not a table")
bad("objectives unknown slot 7", function(d) d[910001].objectives[7] = {} end, "unknown slot")
bad("objectives slot not a table", function(d) d[910001].objectives[1] = 5 end, "objectives[1]")
bad("objective entry not a table", function(d) d[910001].objectives[1][1] = 101 end, "objectives[1][1]")
bad("objective id 0", function(d) d[910001].objectives[1][1][1] = 0 end, "id")
bad("objective id missing", function(d) d[910001].objectives[2][1][1] = nil end, "id")
bad("objective unknown field", function(d) d[910001].objectives[3][1][3] = 5 end, "unknown field")
bad("objective text not a string", function(d) d[910001].objectives[1][1][2] = 5 end, "unknown field")
bad("objective slot with holes", function(d) d[910001].objectives[1] = { [1] = { 101 }, [3] = { 102 } } end, "plain list")
bad("reputation value missing", function(d) d[910001].objectives[4] = { 72 } end, "requiredValue")
bad("reputation value not integer", function(d) d[910001].objectives[4] = { 72, 0.5 } end, "requiredValue")
bad("reputation faction invalid", function(d) d[910001].objectives[4] = { 0, 10 } end, "factionId")
bad("reputation as a list of pairs", function(d) d[910001].objectives[4] = { { 72, 0 } } end, "reputation")
bad("reputation unknown field", function(d) d[910001].objectives[4] = { 72, 0, 1 } end, "reputation")
bad("killCredit ids empty", function(d) d[910001].objectives[5][1][1] = {} end, "killCredit ids")
bad("killCredit ids bad", function(d) d[910001].objectives[5][1][1] = { 401, -1 } end, "killCredit ids")
bad("killCredit rootId missing", function(d) d[910001].objectives[5][1][2] = nil end, "rootId")
bad("killCredit unknown field", function(d) d[910001].objectives[5][1][4] = 1 end, "unknown field")
bad("spell itemSourceId invalid", function(d) d[910001].objectives[6][1][3] = 0 end, "itemSourceId")
bad("triggerEnd wrong type", function(d) d[910001].triggerEnd = true end, "triggerEnd")
bad("extraObjectives not a list", function(d) d[910001].extraObjectives = { x = 1 } end, "extraObjectives")
bad("extra entry not a table", function(d) d[910001].extraObjectives[1] = 5 end, "extraObjectives[1]")
bad("extra icon missing", function(d) d[910001].extraObjectives[1][2] = nil end, "icon")
bad("extra icon out of range", function(d) d[910001].extraObjectives[1][2] = 17 end, "icon")
bad("extra objectiveIndex missing", function(d) d[910001].extraObjectives[1][4] = nil end, "objectiveIndex")
bad("extra objectiveIndex negative", function(d) d[910001].extraObjectives[1][4] = -1 end, "objectiveIndex")
bad("extra objectiveIndex fractional", function(d) d[910001].extraObjectives[1][4] = 1.5 end, "objectiveIndex")
bad("extra objectiveIndex two past objectives (with triggerEnd)", function(d) d[910001].extraObjectives[1][4] = 8 end, "points past")
bad("extra objectiveIndex one past objectives without triggerEnd", function(d) d[910014].extraObjectives[1][4] = 3 end, "points past", 910014)
bad("extra objectiveIndex two past with no objectives", function(d) d[910010].extraObjectives[1][4] = 2 end, "points past", 910010)
bad("extra ref unknown type", function(d) d[910001].extraObjectives[1][5][1][1] = "npc" end, "ref 1 invalid")
bad("extra ref bad id", function(d) d[910001].extraObjectives[1][5][1][2] = 0 end, "ref 1 invalid")
bad("extra ref unknown field", function(d) d[910001].extraObjectives[1][5][1][3] = 1 end, "unknown field")
bad("extra text wrong type", function(d) d[910001].extraObjectives[1][3] = 5 end, "text")
bad("extra unknown field", function(d) d[910001].extraObjectives[1][6] = 1 end, "unknown field")
bad("extra spawns not a table", function(d) d[910008].extraObjectives[1][1] = 5 end, "spawns", 910008)
bad("extra spawns zone key not integer", function(d) d[910008].extraObjectives[1][1] = { x = { { 1, 2 } } } end, "zone", 910008)
bad("extra with neither refs nor spawns", function(d) d[910008].extraObjectives[1][1] = nil end, "neither", 910008)
-- query failures
do
    local calls = 0
    local failing = function(id, key) calls = calls + 1; if key == "extraObjectives" then error("boom") end return Q(id, key) end
    local rec, errs = V2.BuildRecord(failing, 910001, CTX)
    ok(rec == nil and has(errs, "QUERY_FAILED"), "query failure fails closed (QUERY_FAILED)")
    ok(V2.BuildAll(failing, { 910001, 910005 }, CTX) == nil, "query failure fails the whole batch")
    local res = RT.Check(failing, 910001, CTX)
    ok(res.buildError ~= nil and #res.diffs == 0 and res.record == nil, "round trip reports a query failure as a build error, not success")
    local _, a = RT.Run(failing, { 910001, 910005 }, CTX)
    ok(a.buildErrors >= 1, "query failure counted as a build error in the aggregate")
end

-- ---------------------------------------------------------------- tampered records (non-reconstructable changes)
local function tamper(label, id, f, want)
    local rec, _, v1rec = build(id)
    local raw = RT.ReadRaw(Q, id)
    f(rec)
    local res = RT.CheckRecord(rec, raw, S.killCreditFirst[id] == true, v1rec)
    local found = #res.diffs > 0 or res.v1diffs ~= nil or res.validateError ~= nil
    if want then found = found and (table.concat(res.diffs, ",") .. table.concat(res.v1diffs or {}, ",")):find(want, 1, true) ~= nil end
    ok(found, "tamper detected: " .. label .. " [" .. table.concat(res.diffs, ",") .. "]")
end
tamper("killCredit order not reversed", 910003, function(r)
    r.objectives = { r.objectives[3], r.objectives[2], r.objectives[1] }
    for i, o in ipairs(r.objectives) do o.position = i end end, "position")
tamper("killCredit moved after the creature", 910004, function(r)
    r.objectives = { r.objectives[2], r.objectives[1] }
    for i, o in ipairs(r.objectives) do o.position = i end end, "position")
tamper("duplicate occurrence lost", 910007, function(r) table.remove(r.objectives, 4); for i, o in ipairs(r.objectives) do o.position = i end end, "slots/creature")
tamper("reputation value changed 0 -> 1", 910001, function(r) r.objectives[4].requiredValue = 1 end, "slots/reputation")
tamper("reputation dropped", 910001, function(r) table.remove(r.objectives, 4); for i, o in ipairs(r.objectives) do o.position = i end end, "slots/reputation")
tamper("killCredit id dropped", 910001, function(r) r.objectives[5].ids = { 401, 402 } end, "slots/killCredit")
tamper("killCredit rootId changed", 910001, function(r) r.objectives[5].rootId = 402 end, "slots/killCredit")
tamper("slotIndex changed", 910007, function(r) r.objectives[2].slotIndex = 5 end, "slots/creature")
tamper("objective id changed", 910014, function(r) r.objectives[1].id = 1 end, "slots/creature")
tamper("objective kind changed", 910014, function(r) r.objectives[2].kind = "object" end)
tamper("extra ref dropped", 910009, function(r) table.remove(r.extraObjectives[1].refs, 4) end, "extras")
tamper("extra ref type changed", 910009, function(r) r.extraObjectives[1].refs[2].type = "monster" end, "extras")
tamper("extra entry dropped", 910009, function(r) table.remove(r.extraObjectives, 2) end, "extras")
tamper("extra objectiveIndex changed", 910009, function(r) r.extraObjectives[1].objectiveIndex = 0 end, "extras")
tamper("extra spawn zone dropped", 910008, function(r) table.remove(r.extraObjectives[1].spawnZones, 2) end, "extras")
tamper("extra icon changed", 910008, function(r) r.extraObjectives[1].icon = 4 end, "extras")
tamper("extra hasText changed", 910009, function(r) r.extraObjectives[1].hasText = true end, "extras")
tamper("requiredSourceItems entry dropped", 910002, function(r) r.requiredSourceItems = { 701 } end, "requiredSourceItems")
tamper("sourceItemId changed", 910002, function(r) r.sourceItemId = 0 end, "sourceItemId")
tamper("questLevel changed", 910012, function(r) r.questLevel = 80 end, "questLevel")
tamper("hasTriggerEnd dropped", 910001, function(r) r.hasTriggerEnd = false end, "hasTriggerEnd")
tamper("spell itemSourceId invented", 910001, function(r) r.objectives[6].itemSourceId = 601 end, "slots/spell")
tamper("killCreditFirst flag removed", 910004, function(r) r.killCreditFirst = false end)
tamper("v1 equivalence: SUPPORTED record differs from v1 (item id)", 910014, function(r) r.objectives[2].id = 999 end, "objectives.items")
tamper("m1 status forged to SUPPORTED", 910001, function(r) r.m1Status = "SUPPORTED"; r.m1Reasons = {} end)
tamper("m1 reason dropped", 910007, function(r) r.m1Reasons = { "DUPLICATE_CREATURE" } end)
tamper("unknown objective kind", 910014, function(r) r.objectives[1].kind = "event" end)

-- The aggregate counts a tampered record as a differing quest (not success)
do
    local rec, _, v1rec = build(910007)
    local raw = RT.ReadRaw(Q, 910007)
    rec.objectives[1].id = 1
    local good = RT.Check(Q, 910014, CTX)
    local a = RT.Aggregate({ RT.CheckRecord(rec, raw, false, v1rec), good })
    ok(a.questsDiffering == 1 and a.diffs >= 1 and a.processed == 2, "aggregate counts a tampered quest as differing")
    local rec2, _, v1b = build(910014)
    rec2.objectives[2].id = 999
    local a2 = RT.Aggregate({ RT.CheckRecord(rec2, RT.ReadRaw(Q, 910014), false, v1b) })
    ok(a2.v1Differing == 1, "aggregate counts a v1 difference")
    local a3 = RT.Aggregate({ { id = 1, buildError = { "quest 1: x" }, diffs = {}, norm = {} } })
    ok(a3.buildErrors == 1 and a3.built == 0, "aggregate counts a build error")
    ok(RT.FormatAggregate(a):find("round trip: quests differing%s+1") ~= nil, "formatted aggregate shows the difference")
end

-- Compare is not vacuous
ok(#RT.Compare({ a = { 1, 2 } }, { a = { 1, 2 } }) == 0 and #RT.Compare({ a = { 1, 2 } }, { a = { 2, 1 } }) == 2
   and #RT.Compare({ a = 0 }, { a = false }) == 1 and #RT.Compare({ 1 }, { 1, 1 }) == 1, "Compare: order, type and length differences found")
-- RecomputePositions follows Questie's tinsert rule
local pos = RT.RecomputePositions({ slots = { creature = { 1 }, object = {}, item = { 1 }, reputation = {}, killCredit = { 1, 1, 1 }, spell = { 1 } } }, true)
local pk = {}
for _, p in ipairs(pos) do pk[#pk + 1] = p[1] .. p[2] end
ok(table.concat(pk, ",") == "killCredit3,killCredit2,killCredit1,creature1,item1,spell1", "RecomputePositions: " .. table.concat(pk, ","))

-- v1 interaction: the builder's m1 status equals v1 Record for every clean quest
for _, id in ipairs(clean) do
    local rec = build(id)
    local v1rec = V1.Record(Q, id, CTX)
    ok((rec.m1Status == "SUPPORTED") == (v1rec ~= nil), "m1 status equals v1 representability for " .. id)
end

if fails > 0 then print("FAIL: " .. fails .. " of " .. n .. " checks failed"); os.exit(1) end
print("PASS: M2 v2 builder and round trip (" .. n .. " checks)")
