-- Synthetic-only research: frozen M1 asymmetry for Questie-only gameobjects.
-- No changes to M1, v2, adapter, private worker or resource policy.
-- The owner-approved K=64 gameobject KIND boundary does not imply M1 parity.
describe("M2.3 frozen M1 Questie-only object objective research", function()
    local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
    local Adapter = dofile("tools/validation/M23QuestieAdapter.lua")
    local M1 = dofile("tools/validation/ObjectiveRules.lua")

    local function deepCopy(value)
        if type(value) ~= "table" then return value end
        local copy = {}
        for k, v in pairs(value) do copy[deepCopy(k)] = deepCopy(v) end
        return copy
    end

    local function quest(creatures, objects, items)
        local objectives = {}
        local kinds = {
            { "creature", creatures, 1000000000 },
            { "object", objects, 1100000000 },
            { "item", items, 1200000000 },
        }
        for _, group in ipairs(kinds) do
            for slot = 1, group[2] do
                objectives[#objectives + 1] = {
                    position = #objectives + 1, kind = group[1],
                    slotIndex = slot, id = group[3] + slot, occurrence = 1,
                }
            end
        end
        local q = {
            ID = 93001, requiredLevel = 1, questLevel = 60,
            sourceItemId = 0, requiredSourceItems = {},
            objectives = objectives, killCreditFirst = false,
            hasTriggerEnd = false, extraObjectives = {},
        }
        q.m1Status, q.m1Reasons = V2.ExpectedM1(q)
        assert.are.equal("SUPPORTED", q.m1Status)
        assert.are.same({}, q.m1Reasons)
        local valid, problems = V2.ValidateQuest(q)
        assert.is_true(valid, table.concat(problems or {}, "; "))
        local prior = deepCopy(q)
        local adapted, errorCode = Adapter.ToQuestieRecordV2(q)
        assert.is_nil(errorCode)
        assert.is_table(adapted)
        local arrays = adapted[M1.QK.objectives]
        assert.are.equal(creatures, #arrays[1])
        assert.are.equal(objects, #arrays[2])
        assert.are.equal(items, #arrays[3])
        if objects > 0 then
            assert.are.same({ 1100000001 }, arrays[2][1])
            assert.are.same({ 1100000000 + objects }, arrays[2][objects])
        end
        assert.are.same(prior, q)
        return q, adapted
    end

    local function emptyServer()
        return M1.FromQuestTemplateRow({
            ID = 93001, hasConditions = false, ipGated = false,
            scriptedCredit = false, killCreditComplete = false,
        })
    end

    local function countRule(findings, name)
        local count = 0
        for _, f in ipairs(findings) do
            for _, rule in ipairs(f.rules or {}) do
                if rule == name then count = count + 1 end
            end
        end
        return count
    end

    it("observes no frozen M1 findings for Questie-only objects at 1/64/65", function()
        for _, objectCount in ipairs({ 1, 64, 65 }) do
            local q, adapted = quest(0, objectCount, 0)
            local source = emptyServer()
            local oldQ, oldAdapted, oldSource =
                deepCopy(q), deepCopy(adapted), deepCopy(source)
            local findings = M1.Compare(source, adapted)
            assert.is_table(findings)
            assert.are.equal(0, #findings)
            assert.are.same(oldQ, q)
            assert.are.same(oldAdapted, adapted)
            assert.are.same(oldSource, source)
        end
        -- Observed omission is legacy M1 behaviour, not a G3 approval or fix.
        -- In particular, frozen v2 accepting K65 is not private-profile approval.
    end)

    it("separates Questie-only objects from creature/item findings in mixed K64/K65", function()
        for _, objectCount in ipairs({ 64, 65 }) do
            local q, adapted = quest(64, objectCount, 64)
            local source = emptyServer()
            local oldQ, oldAdapted, oldSource =
                deepCopy(q), deepCopy(adapted), deepCopy(source)
            local findings = M1.Compare(source, adapted)
            assert.are.equal(128, #findings)
            assert.are.equal(64, countRule(findings, "R-NPC-UNPAIRED"))
            assert.are.equal(64, countRule(findings, "R-ITEM-UNPAIRED"))
            assert.are.equal(0, countRule(findings, "R-GO-UNPAIRED"))
            assert.are.same(oldQ, q)
            assert.are.same(oldAdapted, adapted)
            assert.are.same(oldSource, source)
        end
        -- These 128 are observed M1 results; they do not prove any B1
        -- findings/record/bundle limits or C1 encoded bytes.
    end)

    it("still reports server-side gameobjects and preserves sign matching", function()
        local _, absent = quest(0, 0, 0)
        local _, present = quest(0, 1, 0)
        local serverUnpaired = M1.FromQuestTemplateRow({
            ID = 93001, RequiredNpcOrGo1 = -1100000001,
            RequiredNpcOrGoCount1 = 1, hasConditions = false,
            ipGated = false, scriptedCredit = false,
            killCreditComplete = false,
        })
        local prior = deepCopy(serverUnpaired)
        local missingFindings = M1.Compare(serverUnpaired, absent)
        assert.are.equal(1, countRule(missingFindings, "R-GO-UNPAIRED"))
        assert.are.equal(0, countRule(missingFindings, "E-GO-SIGN"))
        local matchedFindings = M1.Compare(serverUnpaired, present)
        assert.are.equal(1, countRule(matchedFindings, "E-GO-SIGN"))
        assert.are.equal(0, countRule(matchedFindings, "R-GO-UNPAIRED"))
        assert.are.same(prior, serverUnpaired)
        -- This is a baseline observation only; repairing the frozen M1
        -- would be a separately reviewed, explicitly authorised change.
    end)
end)
