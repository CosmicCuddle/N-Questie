-- busted spec for the M1 objective validation rules (synthetic fixtures only).
-- Run from the repository root: busted -p ".test.lua" tools/validation
describe("N-Questie objective validation rules", function()
    local Rules = dofile("tools/validation/ObjectiveRules.lua")
    local cases = dofile("tools/validation/fixtures/objective_cases.lua")
    local check = dofile("tools/validation/run_cases.lua")

    for _, case in ipairs(cases) do
        it(case.name, function()
            local failures = check(Rules, { case })
            assert.are.same({}, failures)
        end)
    end

    it("classifies quest 1203 against stock Questie as a confirmed item mismatch", function()
        local server = Rules.FromQuestTemplateRow({ ID = 1203, RequiredItemId1 = 3853, RequiredItemCount1 = 1 })
        local findings = Rules.Compare(server, { [10] = { nil, nil, { { 33110 } } } })
        assert.are.equal("CONFIRMED_MISMATCH", Rules.Worst(findings))
    end)

    it("never mutates its inputs", function()
        local row = { ID = 900001, RequiredNpcOrGo1 = -5, RequiredNpcOrGoCount1 = 1 }
        local q = { [10] = { nil, { { 5 } } } }
        Rules.Compare(Rules.FromQuestTemplateRow(row), q)
        assert.are.same({ ID = 900001, RequiredNpcOrGo1 = -5, RequiredNpcOrGoCount1 = 1 }, row)
        assert.are.same({ [10] = { nil, { { 5 } } } }, q)
    end)
end)
