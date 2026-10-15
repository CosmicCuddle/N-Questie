-- busted spec for nq-m2-effective v1 (synthetic fixtures only).
-- Picked up by the existing M1 workflow: busted -p ".test.lua" tools/validation
describe("N-Questie M2.2 effective schema", function()
    local E = dofile("tools/validation/EffectiveSchema.lua")
    local Rules = dofile("tools/validation/ObjectiveRules.lua")
    local cases = dofile("tools/validation/fixtures/effective_cases.lua")
    local function deepCopy(t)
        if type(t) ~= "table" then return t end
        local c = {} for k, v in pairs(t) do c[deepCopy(k)] = deepCopy(v) end return c
    end
    local function load(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return assert(E.ParseString(s)) end
    local eff = load("tests/fixtures/m2_effective/effective_selected_quests.lua")
    local stock = load("tests/fixtures/m2_effective/stock_1203.lua")

    it("accepts the effective fixture with 28 corrections", function()
        local ok, errs = E.Validate(eff, { expectKind = "effective", expectCorrectionCount = 28 })
        assert.is_true(ok, table.concat(errs or {}, "; "))
        assert.are.equal(3853, eff.quests[1].objectives.items[1])
    end)

    it("accepts the stock 1203 record but not as effective", function()
        assert.is_true((E.Validate(stock)))
        local ok = E.Validate(stock, { expectKind = "effective" })
        assert.is_false(ok)
    end)

    it("feeds M1: stock 1203 confirmed, effective 1203 not", function()
        local server = Rules.FromQuestTemplateRow({ ID = 1203, RequiredItemId1 = 3853, RequiredItemCount1 = 1 })
        assert.are.equal("CONFIRMED_MISMATCH", Rules.Worst(Rules.Compare(server, E.ToQuestieRecord(stock.quests[1]))))
        assert.are_not.equal("CONFIRMED_MISMATCH", Rules.Worst(Rules.Compare(server, E.ToQuestieRecord(eff.quests[1]))))
    end)

    it("does not mutate input", function()
        local copy = deepCopy(eff)
        E.Validate(copy); E.ToQuestieRecord(copy.quests[2])
        assert.are.same(eff, copy)
    end)

    for _, c in ipairs(cases) do
        it("rejects: " .. c.name, function()
            local d = deepCopy(eff); c.mutate(d)
            local ok, errs = E.Validate(d)
            assert.is_false(ok)
            local text = table.concat(errs, " | ")
            assert.is_truthy(text:find(c.expect, 1, true), "expected '" .. c.expect .. "', got: " .. text)
        end)
    end
end)
