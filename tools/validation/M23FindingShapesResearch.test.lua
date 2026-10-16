-- M2.3 design research: inspect real frozen M1 finding shapes using ONLY
-- synthetic quest rows. This is not a Part 3 schema or publisher.
-- Lua 5.1, Busted, run from the repository root.
describe("M2.3 private finding-shape research (synthetic only)", function()
    local M1 = dofile("tools/validation/ObjectiveRules.lua")

    local function source(changes)
        local row = {
            ID = 60000,
            hasConditions = false,
            ipGated = false,
            scriptedCredit = false,
            killCreditComplete = false,
        }
        for k, v in pairs(changes or {}) do row[k] = v end
        return M1.FromQuestTemplateRow(row)
    end

    local function questie(creatures, objects, items)
        local objectives = {}
        local function entries(ids)
            local out = {}
            for i, id in ipairs(ids or {}) do out[i] = { id } end
            return out
        end
        objectives[1] = entries(creatures)
        objectives[2] = entries(objects)
        objectives[3] = entries(items)
        return { [M1.QK.objectives] = objectives }
    end

    local function hasRule(finding, rule)
        for _, code in ipairs(finding.rules) do
            if code == rule then return true end
        end
        return false
    end

    local function withRule(findings, rule)
        for _, f in ipairs(findings) do
            if hasRule(f, rule) then return f end
        end
        return nil
    end

    local function compare(row, q)
        return M1.Compare(source(row), q)
    end

    it("preserves signed server gameobject IDs, not positive-only refs", function()
        local findings = compare(
            { RequiredNpcOrGo1 = -60001, RequiredNpcOrGoCount1 = 1 },
            questie({}, { 60001 }, {}))
        local f = withRule(findings, "E-GO-SIGN")
        assert.is_not_nil(f)
        assert.are.equal("object", f.kind)
        assert.are.equal("EXPECTED_REPRESENTATION_DIFF", f.class)
        assert.are.equal(-60001, f.server)
        assert.are.equal(60001, f.questie)
        assert.is_true(type(f.explanation) == "string" and #f.explanation > 0)
    end)

    it("preserves ambiguous creature/item sets as unpaired comma-space strings", function()
        local npc = withRule(compare({
            RequiredNpcOrGo1 = 60001, RequiredNpcOrGoCount1 = 1,
            RequiredNpcOrGo2 = 60002, RequiredNpcOrGoCount2 = 1,
        }, questie({ 60003, 60004 }, {}, {})), "R-NPC-SET")
        assert.is_not_nil(npc)
        assert.are.equal("60001, 60002", npc.server)
        assert.are.equal("60003, 60004", npc.questie)
        assert.are.equal("string", type(npc.server))
        assert.are.equal("string", type(npc.questie))

        local item = withRule(compare({
            RequiredItemId1 = 60001, RequiredItemCount1 = 1,
            RequiredItemId2 = 60002, RequiredItemCount2 = 1,
        }, questie({}, {}, { 60003, 60004 })), "R-ITEM-SET")
        assert.is_not_nil(item)
        assert.are.equal("60001, 60002", item.server)
        assert.are.equal("60003, 60004", item.questie)
    end)

    it("does not deduplicate two same-class unknown flags with different explanations", function()
        local findings = compare({
            hasConditions = false,
            ipGated = "unknown",
            scriptedCredit = "unknown",
        }, questie({}, {}, {}))
        local unknown = {}
        for _, f in ipairs(findings) do
            if hasRule(f, "C-UNKNOWN") then
                unknown[#unknown + 1] = f
            end
        end
        assert.are.equal(2, #unknown)
        assert.are.equal("availability", unknown[1].kind)
        assert.are.equal("availability", unknown[2].kind)
        assert.are.equal(unknown[1].class, unknown[2].class)
        assert.are.equal("C-UNKNOWN", unknown[1].rules[1])
        assert.are.equal("C-UNKNOWN", unknown[2].rules[1])
        assert.is_true(unknown[1].explanation ~= unknown[2].explanation)
        assert.is_true(unknown[1].explanation:find("ipGated", 1, true) ~= nil)
        assert.is_true(unknown[2].explanation:find("scriptedCredit", 1, true) ~= nil)
    end)

    it("keeps missing sides nil and single item mismatches numeric", function()
        local serverOnly = withRule(compare({
            RequiredNpcOrGo1 = 60001, RequiredNpcOrGoCount1 = 1,
        }, questie({}, {}, {})), "R-NPC-UNPAIRED")
        assert.is_not_nil(serverOnly)
        assert.are.equal(60001, serverOnly.server)
        assert.is_nil(serverOnly.questie)

        local questieOnly = withRule(compare({}, questie({ 60002 }, {}, {})),
            "R-NPC-UNPAIRED")
        assert.is_not_nil(questieOnly)
        assert.is_nil(questieOnly.server)
        assert.are.equal(60002, questieOnly.questie)

        local mismatch = withRule(compare({
            RequiredItemId1 = 60001, RequiredItemCount1 = 1,
        }, questie({}, {}, { 60002 })), "M-ITEM-TARGET")
        assert.is_not_nil(mismatch)
        assert.are.equal("CONFIRMED_MISMATCH", mismatch.class)
        assert.are.equal(60001, mismatch.server)
        assert.are.equal(60002, mismatch.questie)
        -- This is M1's finding class, NOT a permissible M2.3 B6 outcome.
    end)

    it("observes printable bounded explanations on representative M1 shapes", function()
        local cases = {
            compare({ RequiredNpcOrGo1 = -60001, RequiredNpcOrGoCount1 = 1 },
                questie({}, { 60001 }, {})),
            compare({ RequiredNpcOrGo1 = 60001, RequiredNpcOrGoCount1 = 1,
                RequiredNpcOrGo2 = 60002, RequiredNpcOrGoCount2 = 1 },
                questie({ 60003, 60004 }, {}, {})),
            compare({ RequiredItemId1 = 60001, RequiredItemCount1 = 1,
                RequiredItemId2 = 60002, RequiredItemCount2 = 1 },
                questie({}, {}, { 60003, 60004 })),
            compare({ scriptedCredit = "unknown", ipGated = "unknown" },
                questie({}, {}, {})),
        }
        local total, longest = 0, 0
        for _, findings in ipairs(cases) do
            for _, f in ipairs(findings) do
                total = total + 1
                assert.are.equal("string", type(f.explanation))
                assert.is_true(#f.explanation > 0)
                longest = math.max(longest, #f.explanation)
                for i = 1, #f.explanation do
                    local byte = f.explanation:byte(i)
                    assert.is_true(byte >= 32 and byte <= 126)
                end
            end
        end
        assert.is_true(total >= 6)
        assert.is_true(longest <= 1024)
        -- A bounded synthetic sample is NOT proof of the global 1024-byte cap.
    end)
end)
