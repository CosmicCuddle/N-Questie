-- Synthetic-only read-only research: frozen M1 R-ITEM-SET explanation bytes.
-- No G3 worker, codec, budget enforcement, private data or trusted action.
-- Approved K64 is a future selected private-design profile, NOT a new limit
-- in frozen EffectiveSchemaV2. The proposed 1,024-byte B1 ceiling is OPEN.
describe("M2.3 K64 item-set explanation byte boundary (synthetic)", function()
    local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
    local Adapter = dofile("tools/validation/M23QuestieAdapter.lua")
    local M1 = dofile("tools/validation/ObjectiveRules.lua")

    local function clone(value)
        if type(value) ~= "table" then return value end
        local out = {}
        for k, v in pairs(value) do out[clone(k)] = clone(v) end
        return out
    end

    local function ids(base, count)
        local out = {}
        for i = 1, count do out[i] = base + i end
        return out
    end

    local function joined(values)
        local out = {}
        for i, value in ipairs(values) do out[i] = tostring(value) end
        return table.concat(out, ", ")
    end

    local function quest(itemCount)
        local objectives = {}
        for _, group in ipairs({
            { "creature", ids(1000000000, 64) },
            { "object", ids(1100000000, 64) },
            { "item", ids(1200000000, itemCount) },
        }) do
            for slot, id in ipairs(group[2]) do
                objectives[#objectives + 1] = {
                    position = #objectives + 1,
                    kind = group[1], slotIndex = slot,
                    id = id, occurrence = 1,
                }
            end
        end
        local q = {
            ID = 96001, requiredLevel = 1, questLevel = 60,
            sourceItemId = 0, requiredSourceItems = {},
            objectives = objectives, killCreditFirst = false,
            hasTriggerEnd = false, extraObjectives = {},
        }
        q.m1Status, q.m1Reasons = V2.ExpectedM1(q)
        assert.are.equal("SUPPORTED", q.m1Status)
        assert.are.same({}, q.m1Reasons)
        local valid, issues = V2.ValidateQuest(q)
        assert.is_true(valid, table.concat(issues or {}, "; "))
        local qBefore = clone(q)
        local adapted, err = Adapter.ToQuestieRecordV2(q)
        assert.is_nil(err)
        assert.is_table(adapted)
        local arrays = adapted[M1.QK.objectives]
        assert.are.equal(64, #arrays[1])
        assert.are.equal(64, #arrays[2])
        assert.are.equal(itemCount, #arrays[3])
        assert.are.same({ 1200000001 }, arrays[3][1])
        assert.are.same({ 1200000000 + itemCount }, arrays[3][itemCount])
        assert.are.same(qBefore, q)
        return q, adapted
    end

    local function server()
        local row = {
            ID = 96001,
            hasConditions = false,
            ipGated = false,
            scriptedCredit = false,
            killCreditComplete = false,
        }
        for slot = 1, 6 do
            row["RequiredItemId" .. slot] = 1600000000 + slot
            row["RequiredItemCount" .. slot] = 1
        end
        local s = M1.FromQuestTemplateRow(row)
        assert.are.same({}, s.problems)
        return s
    end

    local function measure(itemCount, explanationBytes, questieRefBytes)
        local q, adapted = quest(itemCount)
        local s = server()
        local qBefore, adaptedBefore, sBefore = clone(q), clone(adapted), clone(s)
        local findings = M1.Compare(s, adapted)
        -- Frozen M1 groups six unmatched server items and all Questie items
        -- into ONE set finding. The first finding is the single quantity rule.
        assert.are.equal(2, #findings)
        assert.are.equal("quantity", findings[1].kind)
        assert.are.equal(M1.CLASS.EXPECTED, findings[1].class)
        assert.are.same({ "E-QTY" }, findings[1].rules)
        local f = findings[2]
        assert.are.equal("item", f.kind)
        assert.are.equal(M1.CLASS.REVIEW, f.class)
        assert.are.same({ "R-ITEM-SET" }, f.rules)
        assert.are.equal("string", type(f.server))
        assert.are.equal("string", type(f.questie))
        assert.are.equal("string", type(f.explanation))
        local serverIds = ids(1600000000, 6)
        local questieIds = ids(1200000000, itemCount)
        local expectedServer, expectedQuestie = joined(serverIds), joined(questieIds)
        assert.are.equal(expectedServer, f.server)
        assert.are.equal(expectedQuestie, f.questie)
        assert.are.equal(70, #f.server)
        assert.are.equal(questieRefBytes, #f.questie)
        local expectedExplanation = "Item targets differ as sets. Server: {" ..
            expectedServer .. "}; Questie: {" .. expectedQuestie ..
            "}. More than one unmatched item, so no one-to-one replacement is claimed."
        assert.are.equal(expectedExplanation, f.explanation)
        assert.are.equal(explanationBytes, #f.explanation)
        assert.are.same(qBefore, q)
        assert.are.same(adaptedBefore, adapted)
        assert.are.same(sBefore, s)
        -- These are original frozen-M1 bytes, NOT encoded JSON or whole
        -- record/bundle size, and do not approve B1/C1/D5/D6 policy.
    end

    it("pins the K64 960-byte item-set explanation and both typed refs", function()
        measure(64, 960, 766)
    end)

    it("observes frozen-v2-valid K69 at 1,020 explanation bytes", function()
        -- This is outside the approved initial private K64 design profile.
        -- Frozen v2 has no K64 guard, so source M1 still runs for research.
        measure(69, 1020, 826)
    end)

    it("observes frozen-v2-valid K70 at 1,032 bytes beyond proposed B1", function()
        -- 1,024 is PROPOSED, not implemented or approved. This case proves
        -- only that frozen v2 itself does not enforce that proposed budget.
        measure(70, 1032, 838)
    end)
end)
