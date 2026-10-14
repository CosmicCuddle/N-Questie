-- Standalone Lua 5.1 test for the M1 objective validation rules.
-- Synthetic fixtures only; no server data, no WoW client, no file writes.
local Rules = dofile("tools/validation/ObjectiveRules.lua")
local cases = dofile("tools/validation/fixtures/objective_cases.lua")
local failures, results = dofile("tools/validation/run_cases.lua")(Rules, cases)

-- Every catalogued rule should be exercised by at least one fixture.
local used = {}
for _, r in ipairs(results) do
    for _, f in ipairs(r.findings) do for _, id in ipairs(f.rules) do used[id] = true end end
end
for id in pairs(Rules.RULES) do
    if not used[id] then failures[#failures + 1] = "rule " .. id .. " has no fixture" end
end

-- Report-only: Compare must not mutate its inputs.
local q = { [10] = { nil, nil, { { 33110 } } } }
Rules.Compare(Rules.FromQuestTemplateRow({ ID = 1203, RequiredItemId1 = 3853, RequiredItemCount1 = 1 }), q)
if q[10][3][1][1] ~= 33110 then failures[#failures + 1] = "Compare mutated the Questie record" end

if #failures > 0 then
    for _, f in ipairs(failures) do print("FAIL: " .. f) end
    os.exit(1)
end
print("PASS: " .. #cases .. " objective-rule fixtures, all rules exercised, inputs unchanged")
