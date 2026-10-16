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

    it("detects an M1 explanation longer than the proposed 1024-byte private cap", function()
        -- A valid frozen-input shaped server selection uses four creature slots,
        -- and Questie's v2 objective list can represent many unmatched targets.
        -- These are invented IDs (not a production quest or export).
        local manyCreatures = {}
        for i = 1, 128 do manyCreatures[i] = 1000000000 + i end
        -- Ensure this large synthetic shape is accepted by the ACTUAL frozen
        -- v2 structural validator, not just by M1's unvalidated questieLists.
        local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
        local objectives = {}
        for i, id in ipairs(manyCreatures) do
            objectives[i] = {
                position = i, kind = "creature", slotIndex = i,
                id = id, occurrence = 1,
            }
        end
        local qv2 = {
            ID = 60000, requiredLevel = 1, questLevel = 60, sourceItemId = 0,
            requiredSourceItems = {}, objectives = objectives,
            killCreditFirst = false, hasTriggerEnd = false, extraObjectives = {},
            m1Status = "SUPPORTED", m1Reasons = {},
        }
        local valid, problems = V2.ValidateQuest(qv2)
        assert.is_true(valid, table.concat(problems or {}, "; "))
        local findings = compare({
            RequiredNpcOrGo1 = 60001, RequiredNpcOrGoCount1 = 1,
            RequiredNpcOrGo2 = 60002, RequiredNpcOrGoCount2 = 1,
            RequiredNpcOrGo3 = 60003, RequiredNpcOrGoCount3 = 1,
            RequiredNpcOrGo4 = 60004, RequiredNpcOrGoCount4 = 1,
        }, questie(manyCreatures, {}, {}))
        local f = withRule(findings, "R-NPC-SET")
        assert.is_not_nil(f)
        assert.are.equal("string", type(f.questie))
        assert.is_true(#f.questie > 1024)
        assert.is_true(#f.explanation > 1024)
        assert.is_true(f.questie:find("1000000128", 1, true) ~= nil)
        -- This deliberately demonstrates that a 1024-byte limit cannot be
        -- justified from the frozen M1 templates alone. No data is truncated.
    end)

    it("keeps a one-token unmatched target-set STRING distinct from a number", function()
        -- Two unmatched Questie targets versus one server target trigger
        -- R-ITEM-SET, not the one-to-one M-ITEM-TARGET case.
        local f = withRule(compare({
            RequiredItemId1 = 60001, RequiredItemCount1 = 1,
        }, questie({}, {}, { 60003, 60004 })), "R-ITEM-SET")
        assert.is_not_nil(f)
        assert.are.equal("string", type(f.server))
        assert.are.equal("60001", f.server)
        assert.are.equal("string", type(f.questie))
        assert.are.equal("60003, 60004", f.questie)
        assert.is_true(f.server ~= 60001)

        -- The single token can occur on the other side as well.
        local g = withRule(compare({
            RequiredNpcOrGo1 = 60001, RequiredNpcOrGoCount1 = 1,
            RequiredNpcOrGo2 = 60002, RequiredNpcOrGoCount2 = 1,
        }, questie({ 60003 }, {}, {})), "R-NPC-SET")
        assert.is_not_nil(g)
        assert.are.equal("string", type(g.questie))
        assert.are.equal("60003", g.questie)
        assert.is_true(g.questie ~= 60003)
    end)

    it("identifies R-MALFORMED as untrusted text which Part 3 must refuse", function()
        -- Frozen M1 can embed arbitrary invalid tri-state input in its
        -- diagnostic. The future private findings builder must reject this
        -- rule and must never serialise or print its explanation.
        local f = withRule(compare({
            ipGated = "INVALID SYNTHETIC INPUT",
        }, questie({}, {}, {})), "R-MALFORMED")
        assert.is_not_nil(f)
        assert.are.equal("input", f.kind)
        assert.is_true(f.explanation:find("INVALID SYNTHETIC INPUT", 1, true) ~= nil)
        -- This research probe does not implement the future Part 3 rejection.
    end)

    it("compares proposed 512-objective profile against still-valid 513-objective v2 input", function()
        -- A 512-entry resource profile is a NEW future M2.3 design choice.
        -- Frozen EffectiveSchemaV2.ValidateQuest accepts 513 entries too.
        local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
        local ids, objs = {}, {}
        for i = 1, 513 do
            local id = 1000000000 + i
            ids[i] = id
            objs[i] = {
                position = i, kind = "creature", slotIndex = i,
                id = id, occurrence = 1,
            }
        end
        local q = {
            ID = 60000, requiredLevel = 1, questLevel = 60, sourceItemId = 0,
            requiredSourceItems = {}, objectives = objs,
            killCreditFirst = false, hasTriggerEnd = false,
            extraObjectives = {}, m1Status = "SUPPORTED", m1Reasons = {},
        }
        local valid, issues = V2.ValidateQuest(q)
        assert.is_true(valid, table.concat(issues or {}, "; "))
        q.objectives[513] = nil
        valid, issues = V2.ValidateQuest(q)
        assert.is_true(valid, table.concat(issues or {}, "; "))

        ids[513] = nil
        local findings = compare({
            RequiredNpcOrGo1 = 2147483647, RequiredNpcOrGoCount1 = 1,
            RequiredNpcOrGo2 = 2147483646, RequiredNpcOrGoCount2 = 1,
            RequiredNpcOrGo3 = 2147483645, RequiredNpcOrGoCount3 = 1,
            RequiredNpcOrGo4 = 2147483644, RequiredNpcOrGoCount4 = 1,
        }, questie(ids, {}, {}))
        local f = withRule(findings, "R-NPC-SET")
        assert.is_not_nil(f)
        assert.are.equal("string", type(f.questie))
        assert.is_true(#f.questie > 1024 and #f.questie <= 8192)
        assert.is_true(#f.explanation > 1024 and #f.explanation <= 16384)
        assert.is_true(f.questie:find("1000000512", 1, true) ~= nil)
        -- Future implementation must separately enforce the approved count/
        -- byte policy and refuse, not truncate, inputs above its profile.
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
