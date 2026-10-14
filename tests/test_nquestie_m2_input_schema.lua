#!/usr/bin/env lua5.1
-- Standalone M2.1 input-schema tests. Synthetic fixtures only.
-- Run from the repository root: lua5.1 tests/test_nquestie_m2_input_schema.lua

local Schema = dofile("tools/validation/InputSchema.lua")
local cases = dofile("tools/validation/fixtures/input_cases.lua")
local parseCases = dofile("tools/validation/fixtures/input_parse_cases.lua")

local failures = 0
local function fail(msg) failures = failures + 1; io.stderr:write("FAIL: " .. msg .. "\n") end
local function pass(msg) io.stdout:write("PASS: " .. msg .. "\n") end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[deepCopy(k)] = deepCopy(v) end
    return c
end

local function joined(errs)
    local parts = {}
    for _, e in ipairs(errs or {}) do parts[#parts + 1] = e end
    return table.concat(parts, " | ")
end

-- Positive: parse + validate the fixture file
local f = assert(io.open("tests/fixtures/m2_input/valid_selected_quests.lua", "rb"))
local src = f:read("*a"); f:close()
local doc, errs = Schema.ParseString(src)
if not doc then fail("valid fixture did not parse: " .. joined(errs))
else
    local ok, verrs = Schema.Validate(doc)
    if not ok then fail("valid fixture rejected: " .. joined(verrs))
    else
        pass("valid_selected_quests.lua (" .. #doc.quests .. " records, includes quest 1203)")
        -- Input not mutated by a second Validate
        local snap = deepCopy(doc)
        Schema.Validate(doc)
        local function eq(a, b)
            if type(a) ~= type(b) then return false end
            if type(a) ~= "table" then return a == b end
            for k, v in pairs(a) do if not eq(v, b[k]) then return false end end
            for k in pairs(b) do if a[k] == nil then return false end end
            return true
        end
        if not eq(doc, snap) then fail("Validate mutated its input") else pass("Validate does not mutate input") end
        -- Round-trip into ObjectiveRules.FromQuestTemplateRow for every record
        local Rules = dofile("tools/validation/ObjectiveRules.lua")
        for _, row in ipairs(doc.quests) do
            local server = Rules.FromQuestTemplateRow(row)
            if #server.problems > 0 then
                fail("quest " .. row.ID .. " rejected by ObjectiveRules: " .. table.concat(server.problems, "; "))
            end
        end
        pass("every valid record is accepted by ObjectiveRules.FromQuestTemplateRow")
        -- 1203 against stock Questie is still a confirmed item mismatch
        local q1203
        for _, r in ipairs(doc.quests) do if r.ID == 1203 then q1203 = r end end
        local findings = Rules.Compare(Rules.FromQuestTemplateRow(q1203), { [10] = { nil, nil, { { 33110 } } } })
        if Rules.Worst(findings) ~= "CONFIRMED_MISMATCH" then
            fail("quest 1203 vs stock should be CONFIRMED_MISMATCH, got " .. tostring(Rules.Worst(findings)))
        else
            pass("quest 1203 in the fixture is CONFIRMED_MISMATCH against stock Questie")
        end
    end
end

-- Negative validation cases
for _, case in ipairs(cases) do
    local base = Schema.ParseString(src)
    local copy = deepCopy(base)
    case.mutate(copy)
    local ok, verrs = Schema.Validate(copy)
    if ok then
        fail(case.name .. ": expected rejection, got OK")
    else
        local text = joined(verrs)
        if not text:find(case.expect, 1, true) then
            fail(case.name .. ": expected '" .. case.expect .. "', got: " .. text)
        else
            pass(case.name)
        end
    end
end

-- Parser cases
for _, case in ipairs(parseCases) do
    local got, perrs = Schema.ParseString(case.src)
    if got then
        fail(case.name .. ": parser accepted bad input")
    else
        local text = joined(perrs)
        if not text:find(case.expect, 1, true) then
            fail(case.name .. ": expected '" .. case.expect .. "', got: " .. text)
        else
            pass(case.name)
        end
    end
end

-- Path gate
local root = assert(io.popen("pwd"):read("*l"))
local ok, msg = Schema.CheckInputPath(root .. "/tools/validation/InputSchema.lua", root)
if ok then fail("path gate allowed a tracked public file") else pass("path gate refuses a tracked public path: " .. msg) end
ok = Schema.CheckInputPath(root .. "/tests/fixtures/m2_input/valid_selected_quests.lua", root)
if not ok then fail("path gate refused fixture path") else pass("path gate allows tests/fixtures/m2_input/") end
ok = Schema.CheckInputPath(root .. "/private/sample.lua", root)
if not ok then fail("path gate refused private/") else pass("path gate allows private/") end
ok = Schema.CheckInputPath("relative.lua", root)
if ok then fail("path gate allowed a relative path") else pass("path gate requires an absolute path") end
ok = Schema.CheckInputPath("/tmp/nq-m2-does-not-need-to-exist.lua", root)
if not ok then fail("path gate refused an outside absolute path: " .. tostring(msg)) else pass("path gate allows absolute paths outside the checkout") end

-- CLI against the fixture (absolute path)
local cmd = string.format("lua5.1 cli/validate-m2-input.lua '%s/tests/fixtures/m2_input/valid_selected_quests.lua'", root)
local h = io.popen(cmd .. " 2>&1"); local out = h:read("*a"); local st = h:close()
if st and out:find("^OK:", 1) then pass("CLI accepts the valid fixture")
else fail("CLI rejected the valid fixture: " .. out) end

-- CLI against a public tracked path must refuse
h = io.popen(string.format("lua5.1 cli/validate-m2-input.lua '%s/cli/validate-335.lua' 2>&1", root))
out = h:read("*a"); st = h:close()
if out:find("REJECT", 1, true) and out:find("public checkout", 1, true) then
    pass("CLI refuses a tracked public path")
else
    fail("CLI did not refuse a tracked public path: " .. out)
end

-- Whole-input rejection: one bad record rejects everything
local bad = deepCopy(Schema.ParseString(src))
bad.quests[1].hasConditions = nil
local ok2, verrs2 = Schema.Validate(bad)
if ok2 or #verrs2 == 0 then fail("whole-input rejection failed")
else pass("whole input rejected when one record is malformed (" .. #verrs2 .. " error(s))") end

if failures > 0 then
    io.stderr:write(string.format("FAILED: %d failure(s)\n", failures))
    os.exit(1)
end
io.stdout:write(string.format("PASS: M2.1 input schema (%d validation cases, %d parse cases)\n",
    #cases, #parseCases))
os.exit(0)
