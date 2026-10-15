#!/usr/bin/env lua5.1
-- Standalone M2.2 Step 1 tests: nq-m2-effective v1 schema. Synthetic only.
-- Run from the repository root: lua5.1 tests/test_nquestie_m2_effective_schema.lua
local E = dofile("tools/validation/EffectiveSchema.lua")
local Rules = dofile("tools/validation/ObjectiveRules.lua")
local cases = dofile("tools/validation/fixtures/effective_cases.lua")

local failures, passes = 0, 0
local function fail(m) failures = failures + 1; io.stderr:write("FAIL: " .. m .. "\n") end
local function pass(m) passes = passes + 1; io.stdout:write("PASS: " .. m .. "\n") end
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {} for k, v in pairs(t) do c[deepCopy(k)] = deepCopy(v) end return c
end
local function eq(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do if not eq(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
local function read(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return s end
local function byId(doc, id) for _, r in ipairs(doc.quests) do if r.ID == id then return r end end end

local effSrc = read("tests/fixtures/m2_effective/effective_selected_quests.lua")
local stockSrc = read("tests/fixtures/m2_effective/stock_1203.lua")
local eff = assert(E.ParseString(effSrc))
local stock = assert(E.ParseString(stockSrc))

local ok, errs = E.Validate(eff)
if ok then pass("effective fixture is valid (" .. #eff.quests .. " records)") else fail("effective fixture: " .. table.concat(errs, "; ")) end
ok, errs = E.Validate(eff, { expectKind = "effective", expectCorrectionCount = 28 })
if ok then pass("effective fixture matches expectKind=effective, 28 corrections") else fail(table.concat(errs, "; ")) end
if byId(eff, 1203).objectives.items[1] == 3853 then pass("effective 1203 item objective is 3853") else fail("effective 1203 item is not 3853") end

ok, errs = E.Validate(stock)
if ok then pass("stock-shaped 1203 (item 33110) is valid schema-wise") else fail("stock fixture: " .. table.concat(errs, "; ")) end
ok, errs = E.Validate(stock, { expectKind = "effective" })
if not ok and table.concat(errs, " "):find("dataKind: expected \"effective\"", 1, true) then
    pass("provenance distinguishes stock from effective (stock rejected when effective is required)")
else fail("stock export was not distinguished from effective") end
ok = E.Validate(eff, { expectKind = "stock" })
if not ok then pass("effective rejected when stock is required") else fail("effective accepted as stock") end
ok, errs = E.Validate(eff, { expectCorrectionCount = 27 })
if not ok and table.concat(errs, " "):find("expected 27", 1, true) then pass("wrong expected correction count rejected") else fail("correction count expectation ignored") end

-- stock provenance rules
for _, c in ipairs({
    { "stock with revision", function(d) d.provenance.nQuestieDataRevision = 3 end, "stock export must be 0" },
    { "stock with corrections", function(d) d.provenance.correctionCount = 28 end, "stock export must be 0" },
    { "stock with fingerprint", function(d) d.provenance.correctionFingerprint = "sha256:" .. string.rep("c", 64) end, "must be \"none\"" },
    { "stock with modules", function(d) d.provenance.correctionModules = { "X.lua" } end, "stock export must be empty" },
    { "stock with M0 checks", function(d) d.provenance.m0Checks = 232 end, "m0Checks: stock export must be 0" },
}) do
    local d = deepCopy(stock); c[2](d)
    local good, e2 = E.Validate(d)
    if not good and table.concat(e2, " "):find(c[3], 1, true) then pass(c[1]) else fail(c[1] .. ": " .. table.concat(e2 or {}, "; ")) end
end

-- non-mutation
local snap = deepCopy(eff)
E.Validate(eff, { expectKind = "effective" })
if eq(snap, eff) then pass("Validate does not mutate input") else fail("Validate mutated input") end
local rec = byId(eff, 900301)
local before = deepCopy(rec)
E.ToQuestieRecord(rec)
if eq(before, rec) then pass("ToQuestieRecord does not mutate the record") else fail("ToQuestieRecord mutated the record") end

-- M2.3 compatibility through M1 ObjectiveRules
local server1203 = Rules.FromQuestTemplateRow({ ID = 1203, RequiredItemId1 = 3853, RequiredItemCount1 = 1,
    hasConditions = "unknown", ipGated = "unknown", scriptedCredit = "unknown", KillCredit = {} })
local stockWorst = Rules.Worst(Rules.Compare(server1203, E.ToQuestieRecord(byId(stock, 1203))))
local effFindings = Rules.Compare(server1203, E.ToQuestieRecord(byId(eff, 1203)))
local hasConfirmed = false
for _, f in ipairs(effFindings) do if f.class == "CONFIRMED_MISMATCH" then hasConfirmed = true end end
if stockWorst == "CONFIRMED_MISMATCH" then pass("M1 on stock 1203 record: CONFIRMED_MISMATCH") else fail("stock 1203 gave " .. tostring(stockWorst)) end
if not hasConfirmed then pass("M1 on effective 1203 record: no confirmed mismatch") else fail("effective 1203 produced a confirmed mismatch") end
local sm = Rules.Compare(Rules.FromQuestTemplateRow({ ID = 900301, RequiredNpcOrGo1 = 900142, RequiredNpcOrGoCount1 = 1 }),
    E.ToQuestieRecord(byId(eff, 900301)))
local kcSeen = false
for _, f in ipairs(sm) do for _, r in ipairs(f.rules or {}) do if r == "E-KILLCREDIT" then kcSeen = true end end end
if kcSeen then pass("killCredit objectives reach M1 (E-KILLCREDIT)") else fail("killCredit objectives not recognised by M1") end

-- negative cases
for _, c in ipairs(cases) do
    local d = deepCopy(eff); c.mutate(d)
    local good, e2 = E.Validate(d)
    if good then fail(c.name .. ": accepted")
    elseif not table.concat(e2, " | "):find(c.expect, 1, true) then fail(c.name .. ": expected '" .. c.expect .. "', got: " .. table.concat(e2, " | "))
    else pass(c.name) end
end

-- parser and path rules are the M2.1 ones
local d, perr = E.ParseString('return { schema = os.getenv("X") }')
if not d and perr[1]:find("only data literals", 1, true) then pass("parser rejects code (shared M2.1 parser)") else fail("parser accepted code") end
d, perr = E.ParseString('return { schema = "a", schema = "b" }')
if not d and perr[1]:find("duplicate key", 1, true) then pass("parser rejects duplicate keys") else fail("parser accepted duplicate keys") end

local root = io.popen("pwd -P"):read("*l")
local tmp = io.popen("mktemp -d"):read("*l")
os.execute("cp tests/fixtures/m2_effective/effective_selected_quests.lua '" .. tmp .. "/eff.lua'")
os.execute("ln -s '" .. root .. "/tools/validation/EffectiveSchema.lua' '" .. tmp .. "/to-public.lua'")
local doc = E.LoadFile(tmp .. "/eff.lua", root, { expectKind = "effective" })
if doc then pass("LoadFile accepts an effective export outside the checkout") else fail("LoadFile refused an outside file") end
local _, lerr = E.LoadFile(root .. "/tests/fixtures/m2_effective/effective_selected_quests.lua", root)
if lerr and lerr[1]:find("public checkout", 1, true) then pass("LoadFile refuses a tracked path (fail-closed M2.1 path rules)") else fail("LoadFile accepted a tracked path") end
_, lerr = E.LoadFile(tmp .. "/to-public.lua", root)
if lerr and lerr[1]:find("public checkout", 1, true) then pass("LoadFile refuses a symlink into the checkout") else fail("symlink into checkout accepted") end
_, lerr = E.LoadFile(tmp .. "/missing.lua", root)
if lerr and lerr[1]:find("cannot resolve", 1, true) then pass("LoadFile refuses a missing file") else fail("missing file not rejected") end
os.execute("rm -rf '" .. tmp .. "'")

if failures > 0 then io.stderr:write("FAILED: " .. failures .. " failure(s)\n"); os.exit(1) end
print(string.format("PASS: M2.2 Step 1 effective schema (%d checks, %d negative cases)", passes, #cases))
