-- Synthetic-only research of the FROZEN M1/Part 2 boundary at K=64.
-- No Part 3 private worker, new resource gate, policy selection, or I/O.
-- K=64 creature/object/item is an owner-approved *design* boundary only;
-- the frozen v2 validator and M1 still accept 65 structurally.
-- All data below are fabricated, not private/real quest records.
describe("M2.3 mixed K64/K65 creature+item frozen M1 baseline", function()
    local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
    local Adapter = dofile("tools/validation/M23QuestieAdapter.lua")
    local M1 = dofile("tools/validation/ObjectiveRules.lua")

    local function deepCopy(t)
        if type(t) ~= "table" then return t end
        local out = {}
        for k, v in pairs(t) do out[deepCopy(k)] = deepCopy(v) end
        return out
    end

    local function fakeQuest(creatures, items)
        local objectives = {}
        local function add(kind, count, firstId)
            for i = 1, count do
                objectives[#objectives + 1] = {
                    position = #objectives + 1, kind = kind,
                    slotIndex = i, id = firstId + i, occurrence = 1,
                }
            end
        end
        add("creature", creatures, 1000000000)
        add("item", items, 1200000000)
        local quest = {
            ID = 92001, requiredLevel = 1, questLevel = 60,
            sourceItemId = 0, requiredSourceItems = {},
            objectives = objectives, killCreditFirst = false,
            hasTriggerEnd = false, extraObjectives = {},
        }
        quest.m1Status, quest.m1Reasons = V2.ExpectedM1(quest)
        return quest
    end

    local cases = {
        { creatures = 64, items = 64, permittedByK64 = true  },
        { creatures = 64, items = 65, permittedByK64 = false },
        { creatures = 65, items = 64, permittedByK64 = false },
        { creatures = 65, items = 65, permittedByK64 = false },
    }

    local function record(q, creatures, items)
        assert.are.equal("SUPPORTED", q.m1Status)
        assert.are.same({}, q.m1Reasons)
        local valid, errors = V2.ValidateQuest(q)
        assert.is_true(valid, table.concat(errors or {}, "; "))
        local snapshot = deepCopy(q)
        local adapted, errCode = Adapter.ToQuestieRecordV2(q)
        assert.is_nil(errCode)
        assert.is_table(adapted)
        local objectives = adapted[M1.QK.objectives]
        assert.is_table(objectives)
        assert.are.equal(creatures, #objectives[1])
        assert.are.equal(0, #objectives[2])
        assert.are.equal(items, #objectives[3])
        assert.are.same({ 1000000001 }, objectives[1][1])
        assert.are.same({ 1000000000 + creatures }, objectives[1][creatures])
        assert.are.same({ 1200000001 }, objectives[3][1])
        assert.are.same({ 1200000000 + items }, objectives[3][items])
        assert.are.same(snapshot, q)
        return adapted
    end

    local function hasRule(f, rule)
        for _, r in ipairs(f.rules or {}) do
            if r == rule then return true end
        end
        return false
    end

    it("confirms frozen v2 accepts all four mixed K64/K65 shapes", function()
        for _, case in ipairs(cases) do
            local q = fakeQuest(case.creatures, case.items)
            assert.are.equal(case.permittedByK64,
                case.creatures <= 64 and case.items <= 64)
            assert.are.equal(case.creatures + case.items, #q.objectives)
            record(q, case.creatures, case.items)
        end
        -- This test does NOT implement K64: valid-v2 is not profile approval.
    end)

    it("observes real M1 Compare on mixed arrays with no truncation", function()
        local server = M1.FromQuestTemplateRow({
            ID = 92001, hasConditions = false, ipGated = false,
            scriptedCredit = false, killCreditComplete = false,
        })
        local beforeServer = deepCopy(server)
        for _, case in ipairs(cases) do
            local q = fakeQuest(case.creatures, case.items)
            local beforeQuest = deepCopy(q)
            local adapted = record(q, case.creatures, case.items)
            local beforeAdapter = deepCopy(adapted)
            local findings = M1.Compare(server, adapted)
            assert.is_table(findings)
            -- No server objectives: one UNPAIRED finding for each synthetic
            -- creature and each item, even at structurally valid 65-per-kind.
            assert.are.equal(case.creatures + case.items, #findings)
            local npc, item, textBytes = 0, 0, 0
            for _, finding in ipairs(findings) do
                if hasRule(finding, "R-NPC-UNPAIRED") then
                    npc = npc + 1
                elseif hasRule(finding, "R-ITEM-UNPAIRED") then
                    item = item + 1
                else
                    error("unexpected synthetic M1 rule")
                end
                assert.are.equal("string", type(finding.explanation))
                textBytes = textBytes + #finding.explanation
            end
            assert.are.equal(case.creatures, npc)
            assert.are.equal(case.items, item)
            assert.is_true(textBytes > 0)
            assert.are.same(beforeAdapter, adapted)
            assert.are.same(beforeQuest, q)
            assert.are.same(beforeServer, server)
        end
        -- 128/129/130 observed findings do NOT prove the proposed B1
        -- 192-finding, 1024-string, 256-KiB or 64-MiB encoding budgets.
        -- Full future bundle bytes require the separately approved C1 codec.
    end)
end)
