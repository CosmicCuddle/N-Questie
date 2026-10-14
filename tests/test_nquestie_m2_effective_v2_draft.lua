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
r, e = mutate(function(d) q(d, 735).extraObjectives[1].objectiveIndex = 0 end)
ok(not r and has(e, "objectiveIndex"), "R3 bad objectiveIndex rejected")
r, e = mutate(function(d) q(d, 9666).objectives[2].rootId = nil end)
ok(not r and has(e, "rootId"), "R3 killCredit root required")
-- R4 order: Questie ObjectiveData order enforced
r, e = mutate(function(d) local o = q(d, 1369).objectives; o[1], o[2] = o[2], o[1]; o[1].position = 1; o[2].position = 2 end)
ok(not r and has(e, "out of Questie objective order"), "R4 reputation before item rejected")
r = mutate(function(d) local x = q(d, 9666); x.killCreditFirst = true; local o = x.objectives
    o[1], o[2] = o[2], o[1]; o[1].position = 1; o[2].position = 2 end)
ok(r, "R4 killCreditFirst allows killCredit first")
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
ok(q(base, 8470).objectives[1].requiredValue == nil, "R8 faction-only reputation kept without value")
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
-- R10 versioning
ok(D.ValidateAnyVersion(dofile("tests/fixtures/m2_effective/effective_selected_quests.lua"), OPT), "R10 v1 still valid via dispatch")
local v3 = copy(base); v3.schemaVersion = 3
r, e = D.ValidateAnyVersion(v3, OPT)
ok(not r and has(e, "unknown version"), "R10 unknown version rejected")
local nv = copy(base); nv.schemaVersion = nil
ok(not D.ValidateAnyVersion(nv, OPT), "R10 missing version rejected")
ok(not V1.Validate(base), "R10 frozen v1 validator rejects v2 documents")
local mig, merr = D.MigrateV1(dofile("tests/fixtures/m2_effective/effective_selected_quests.lua"), OPT)
if mig then
    ok(D.Validate(mig, OPT), "R10 migrated v1 document validates as v2")
    ok(mig.quests[1].objectives[1].kind == "item" and mig.quests[1].objectives[1].id == 3853, "R10 migration keeps 1203 item 3853")
else
    ok(merr and #merr > 0, "R10 migration refuses what v1 cannot tell (" .. tostring(merr and merr[1]) .. ")")
end
local simple = { schema = "nq-m2-effective", schemaVersion = 1, provenance = copy(base.provenance), quests = { {
    ID = 1203, requiredLevel = 30, questLevel = 35, sourceItemId = 0, requiredSourceItems = {},
    objectives = { creatures = {}, objects = {}, items = { 3853 }, killCredit = {}, spells = {} },
    hasTriggerEnd = false, hasExtraObjectives = false, extraObjectiveItems = {} } } }
simple.provenance.questCount = 1
local m2 = D.MigrateV1(simple, OPT)
ok(m2 and D.Validate(m2, OPT) and m2.quests[1].objectives[1].id == 3853, "R10 v1 -> v2 migration lossless for 1203")
local withExtra = copy(simple); withExtra.quests[1].hasExtraObjectives = true
local m3, e3 = D.MigrateV1(withExtra, OPT)
ok(not m3 and has(e3, "not guessed"), "R10 migration refuses to guess extras")
local d1, de = D.DowngradeToV1(base, OPT)
ok(d1 == nil and has(de, "refused"), "R10 downgrade v2 -> v1 refused")
-- data-only parse of the fixture text
local f = io.open("tests/fixtures/m2_effective_v2_draft/v2_categories.lua"); local src = f:read("*a"); f:close()
ok(V1.ParseString(src) ~= nil, "fixture parses with the frozen data-only parser")

if fails > 0 then print("FAILED: M2 v2 DRAFT (" .. fails .. " of " .. n .. ")") os.exit(1) end
print("PASS: M2 v2 DRAFT prototype (" .. n .. " checks)")
