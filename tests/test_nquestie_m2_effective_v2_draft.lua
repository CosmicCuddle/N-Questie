-- DRAFT nq-m2-effective v2 prototype tests (design validation only; no
-- exporter). Covers the 10 v2 requirements in
-- docs/NQ-VALIDATION-M2-EFFECTIVE-V2-DESIGN.md section 6. Lua 5.1, no I/O
-- beyond reading fixtures.
local D = dofile("tools/validation/draft/EffectiveSchemaV2Draft.lua")
local V1 = dofile("tools/validation/EffectiveSchema.lua")
local OPT = { allowDraft = true }
local n, fails = 0, 0
local function ok(c, m) n = n + 1; if not c then fails = fails + 1; print("FAIL: " .. m) end end
local function copy(t) if type(t) ~= "table" then return t end local o = {} for k, v in pairs(t) do o[k] = copy(v) end return o end
local function has(errs, s) for _, e in ipairs(errs or {}) do if e:find(s, 1, true) then return true end end return false end
local base = dofile("tests/fixtures/m2_effective_v2_draft/v2_categories.lua")
local function mutate(f) local d = copy(base); f(d); return D.Validate(d, OPT) end
local function q(d, id) for _, x in ipairs(d.quests) do if x.ID == id then return x end end end

-- 0. draft guard
ok(not pcall(D.Validate, base), "draft refuses without allowDraft")
ok(D.DRAFT == true, "module marked draft")
local good, gerr = D.Validate(base, OPT)
ok(good, "category fixture valid: " .. table.concat(gerr or {}, "; "))

-- R1 type preserved (kind enumerated; unknown rejected)
local r, e = mutate(function(d) q(d, 1203).objectives[1].kind = "gameobject" end)
ok(not r and has(e, "unknown kind"), "R1 unknown kind rejected")
-- R2 target id preserved
r, e = mutate(function(d) q(d, 1203).objectives[1].id = 0 end)
ok(not r and has(e, ".id"), "R2 invalid target id rejected")
-- R3 relationship: extra objectiveIndex kept; killCredit ids/root kept
ok(q(base, 735).extraObjectives[1].objectiveIndex == 2, "R3 extra linked to objective 2 kept")
r, e = mutate(function(d) q(d, 735).extraObjectives[1].objectiveIndex = 9 end)
ok(not r and has(e, "objectiveIndex"), "R3 objectiveIndex past the objectives rejected")
r, e = mutate(function(d) q(d, 735).extraObjectives[1].objectiveIndex = nil end)
ok(not r and has(e, "objectiveIndex"), "R3 objectiveIndex required (0 = not linked)")
ok(q(base, 11142).extraObjectives[1].objectiveIndex == 0, "R3 0 = not linked kept")
r, e = mutate(function(d) q(d, 9666).objectives[2].rootId = nil end)
ok(not r and has(e, "rootId"), "R3 killCredit root required")
-- R4 order: Questie ObjectiveData order enforced
r, e = mutate(function(d) local o = q(d, 1369).objectives; o[1], o[2] = o[2], o[1]; o[1].position = 1; o[2].position = 2 end)
ok(not r and has(e, "out of Questie objective order"), "R4 reputation before item rejected")
r = mutate(function(d) local x = q(d, 9666); x.killCreditFirst = true; local o = x.objectives
    o[1], o[2] = o[2], o[1]; o[1].position = 1; o[2].position = 2
    x.m1Status = "UNSUPPORTED_BY_RULES"; x.m1Reasons = { "KILLCREDIT_FIRST_REORDER" } end)
ok(r, "R4 killCreditFirst puts killCredit first")
-- ordering limitation (10503 / 11652): v1 cannot say this, v2 must
ok(q(base, 10503).objectives[1].kind == "killCredit" and q(base, 10503).killCreditFirst, "R4 10503 killCredit on line 1")
ok(q(base, 11652).objectives[1].slotIndex == 2 and q(base, 11652).objectives[2].slotIndex == 1, "R4 11652 killCredit reversed")
r, e = mutate(function(d) local o = q(d, 11652).objectives; o[1], o[2] = o[2], o[1]; o[1].position = 1; o[2].position = 2 end)
ok(not r and has(e, "out of Questie objective order"), "R4 11652 in slot order rejected (Questie reverses)")
r, e = mutate(function(d) local x = q(d, 10503); local o = x.objectives; o[1], o[2] = o[2], o[1]; o[1].position = 1; o[2].position = 2 end)
ok(not r and has(e, "out of Questie objective order"), "R4 10503 default order rejected when killCreditFirst")
r = mutate(function(d) local x = q(d, 10503); x.killCreditFirst = false end)
ok(not r, "R4 killCreditFirst flag must agree with the order")
r, e = mutate(function(d) local x = q(d, 10503); x.m1Status = "SUPPORTED"; x.m1Reasons = {} end)
ok(not r and has(e, "no false SUPPORTED"), "R9 reordered quest never M1 SUPPORTED")
-- R5 position: contiguous, equals list index; extra refs keep refIndex
r, e = mutate(function(d) q(d, 735).objectives[3].position = 4 end)
ok(not r and has(e, "position"), "R5 position gap rejected")
r, e = mutate(function(d) q(d, 1367).extraObjectives[1].refs[2].refIndex = 5 end)
ok(not r and has(e, "refIndex"), "R5 ref order index enforced")
-- R6 ordinary vs extra distinction: separate lists, extras need refs or spawns
r, e = mutate(function(d) q(d, 1203).objectives[1].icon = 2 end)
ok(not r and has(e, "unknown field"), "R6 extra field on ordinary objective rejected")
r, e = mutate(function(d) q(d, 11142).extraObjectives[1].spawnZones = {} end)
ok(not r and has(e, "neither refs nor spawns"), "R6 empty extra rejected")
r, e = mutate(function(d) q(d, 11142).extraObjectives[2].refs[1].type = "npc" end)
ok(not r and has(e, "monster, object or item"), "R6 extra ref type enumerated")
-- R7 duplicates kept with occurrence
ok(#q(base, 25199).objectives == 4 and q(base, 25199).objectives[4].occurrence == 4, "R7 four occurrences kept")
r, e = mutate(function(d) q(d, 25199).objectives[3].occurrence = 1 end)
ok(not r and has(e, "occurrence"), "R7 wrong occurrence rejected")
r = mutate(function(d) table.remove(q(d, 25199).objectives, 2) end)
ok(not r, "R7 silently dropping a duplicate breaks positions/occurrence")
-- R8 reputation explicit; absent value never defaulted
ok(q(base, 8470).objectives[1].requiredValue == 0, "R8 required value 0 kept as 0")
r, e = mutate(function(d) q(d, 8470).objectives[1].requiredValue = nil end)
ok(not r and has(e, "requiredValue"), "R8 missing required value rejected (never dropped)")
r, e = mutate(function(d) q(d, 1367).objectives[1].factionId = nil end)
ok(not r and has(e, "factionId"), "R8 faction required")
r, e = mutate(function(d) local o = q(d, 1369).objectives
    o[3] = { position = 3, kind = "reputation", slotIndex = 2, factionId = 1, requiredValue = 1 } end)
ok(not r and has(e, "at most one reputation"), "R8 single reputation pair")
-- R9 M1-uninterpretable content preserved but UNSUPPORTED (no false SUPPORTED)
r, e = mutate(function(d) local x = q(d, 1367); x.m1Status = "SUPPORTED"; x.m1Reasons = {} end)
ok(not r and has(e, "no false SUPPORTED"), "R9 false SUPPORTED rejected")
r = mutate(function(d) local x = q(d, 11142); x.m1Reasons = { "EXTRA_CREATURE_REF" } end)
ok(not r, "R9 all reasons required")
ok(q(base, 1203).m1Status == "SUPPORTED" and q(base, 9666).m1Status == "SUPPORTED", "R9 v1-shaped quests SUPPORTED")
r, e = mutate(function(d) q(d, 1367).m1Status = "NEEDS_MANUAL_REVIEW" end)
ok(not r and has(e, "m1Status"), "R9 NEEDS_MANUAL_REVIEW is not a record status (comparison outcome only)")
r = mutate(function(d) q(d, 1367).m1Status = "UNSUPPORTED" end)
ok(not r, "R9 old collapsed UNSUPPORTED value rejected")

-- Display scope: omission is intentional and explicit
r, e = mutate(function(d) d.displayScope = nil end)
ok(not r and has(e, "displayScope"), "display scope marker required")
r, e = mutate(function(d) q(d, 1367).extraObjectives[1].text = "Slay Gelkis centaur" end)
ok(not r and has(e, "unknown field"), "display text never carried in v2")
r, e = mutate(function(d) q(d, 11142).extraObjectives[1].spawns = { [15] = { { 69.95, 19.53 } } } end)
ok(not r and has(e, "unknown field"), "exact coordinates never carried in v2")
ok(q(base, 11142).extraObjectives[1].hasText == true and #q(base, 11142).extraObjectives[1].spawnZones == 1,
   "presence of text and custom spawns recorded (omission is not absence)")

-- Provenance pairing
local P = copy(base.provenance)
ok(D.CheckPairing(P, copy(P), OPT), "pairing: same checkout accepted")
local P2 = copy(P); P2.sourceCommit = string.rep("d", 40)
r, e = D.CheckPairing(P, P2, OPT)
ok(not r and has(e, "sourceCommit"), "pairing: different commit rejected")
P2 = copy(P); P2.correctionFingerprint = "sha256:" .. string.rep("e", 64)
ok(not D.CheckPairing(P, P2, OPT), "pairing: different correction fingerprint rejected")
P2 = copy(P); P2.correctionModules = { "x.lua" }
ok(not D.CheckPairing(P, P2, OPT), "pairing: different modules rejected")
P2 = copy(P); P2.nQuestieDataRevision = 4
ok(not D.CheckPairing(P, P2, OPT), "pairing: different revision rejected")
local stock = copy(P); stock.dataKind = "stock"
ok(not D.CheckPairing(stock, copy(stock), OPT), "pairing: stock export never paired as effective")
local srv = dofile("tests/fixtures/m2_input/private_adapter_v3_synthetic.lua")
ok(D.CheckServerDocument(srv, OPT), "server document validated in full by the M2.1 validator")
for _, f in ipairs({ "exporter", "exporterVersion", "sourceLabel", "sourceFingerprint", "exportedAt", "selection", "questCount" }) do
    local bad = copy(srv); bad.provenance[f] = nil
    r, e = D.CheckServerDocument(bad, OPT)
    ok(not r and has(e, "provenance." .. f), "incomplete server provenance rejected: " .. f)
end
local badv = copy(srv); badv.provenance.exporterVersion = "three"
ok(not D.CheckServerDocument(badv, OPT), "invalid exporterVersion rejected")
local badt = copy(srv); badt.provenance.exportedAt = "2026-13-40T99:00:00Z"
ok(not D.CheckServerDocument(badt, OPT), "invalid exportedAt rejected")
local badq = copy(srv); badq.provenance.questCount = 99
ok(not D.CheckServerDocument(badq, OPT), "questCount mismatch rejected")
local withCommit = copy(srv); withCommit.provenance.sourceCommit = P.sourceCommit
r, e = D.CheckServerDocument(withCommit, OPT)
ok(not r and has(e, "unknown field"), "server provenance cannot carry a git commit (never compared with Questie)")
ok(D.CheckServerProvenance == nil, "no provenance-only server entry point exists")

-- Migration never invents order facts (lead review #39 point 3)
local function v1doc(objs)
    local d = { schema = "nq-m2-effective", schemaVersion = 1, provenance = copy(base.provenance), quests = { {
        ID = 900001, requiredLevel = 10, questLevel = 12, sourceItemId = 0, requiredSourceItems = {},
        objectives = objs, hasTriggerEnd = false, hasExtraObjectives = false, extraObjectiveItems = {} } } }
    d.provenance.questCount = 1
    return d
end
local one = v1doc({ creatures = {}, objects = {}, items = {}, killCredit = { { ids = { 5 }, rootId = 5 } }, spells = {} })
r, e = D.MigrateV1(one, OPT)
ok(not r and has(e, "cannot be proven"), "migration refuses single-killCredit quest (flag unknown in v1)")
local two = v1doc({ creatures = {}, objects = {}, items = {}, killCredit = { { ids = { 5 }, rootId = 5 }, { ids = { 6 }, rootId = 6 } }, spells = {} })
r, e = D.MigrateV1(two, OPT)
ok(not r and has(e, "cannot be proven"), "migration refuses two-killCredit-only quest (order may be reversed)")
local mixed = v1doc({ creatures = { 7 }, objects = {}, items = {}, killCredit = { { ids = { 5 }, rootId = 5 } }, spells = {} })
ok(not D.MigrateV1(mixed, OPT), "migration refuses killCredit beside other objectives")
local nokc = D.MigrateV1(v1doc({ creatures = { 7, 8 }, objects = {}, items = { 3 }, killCredit = {}, spells = {} }), OPT)
ok(nokc and nokc.quests[1].killCreditFirst == false and D.Validate(nokc, OPT), "no-killCredit quest migrates; false is provable")
r, e = mutate(function(d) q(d, 1203).killCreditFirst = true; q(d, 1203).m1Status = "UNSUPPORTED_BY_RULES"; q(d, 1203).m1Reasons = { "KILLCREDIT_FIRST_REORDER" } end)
ok(not r and has(e, "requires a killCredit objective"), "killCreditFirst true without killCredit rejected")

if fails > 0 then print("FAILED: M2 v2 DRAFT (" .. fails .. " of " .. n .. ")") os.exit(1) end
print("PASS: M2 v2 DRAFT prototype (" .. n .. " checks)")
