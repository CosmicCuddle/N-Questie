-- Synthetic-only: additive frozen M1 findings under mixed per-kind K64.
-- This observes actual historical M1 and adapter behavior, NOT a G3 guard.
-- K64 creature/object/item is an approved *design* boundary; 192 findings
-- and all other B1 resource/output ceilings remain unapproved proposals.
-- No private export, worker, writer, trust action, or production change.
describe("M2.3 K64 additive M1 finding sources (synthetic)", function()
    local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
    local Adapter = dofile("tools/validation/M23QuestieAdapter.lua")
    local M1 = dofile("tools/validation/ObjectiveRules.lua")

    local function clone(t)
        if type(t) ~= "table" then return t end
        local c = {}
        for k, v in pairs(t) do c[clone(k)] = clone(v) end
        return c
    end

    local function quest(objects)
        local objectives = {}
        for _, group in ipairs({
            { "creature", 64, 1000000000 },
            { "object", objects, 1100000000 },
            { "item", 64, 1200000000 },
        }) do
            for slot = 1, group[2] do
                objectives[#objectives + 1] = {
                    position = #objectives + 1,
                    kind = group[1], slotIndex = slot,
                    id = group[3] + slot, occurrence = 1,
                }
            end
        end
        local q = {
            ID = 94001, requiredLevel = 1, questLevel = 60,
            sourceItemId = 0, requiredSourceItems = {},
            objectives = objectives, killCreditFirst = false,
            hasTriggerEnd = false, extraObjectives = {},
        }
        q.m1Status, q.m1Reasons = V2.ExpectedM1(q)
        assert.are.equal("SUPPORTED", q.m1Status)
        assert.are.same({}, q.m1Reasons)
        local valid, issues = V2.ValidateQuest(q)
        assert.is_true(valid, table.concat(issues or {}, "; "))
        local original = clone(q)
        local adapted, err = Adapter.ToQuestieRecordV2(q)
        assert.is_nil(err)
        assert.is_table(adapted)
        local arrays = adapted[M1.QK.objectives]
        assert.are.equal(64, #arrays[1])
        assert.are.equal(objects, #arrays[2])
        assert.are.equal(64, #arrays[3])
        assert.are.same({ 1100000001 }, arrays[2][1])
        assert.are.same({ 1100000000 + objects }, arrays[2][objects])
        assert.are.same(original, q)
        return q, adapted
    end

    local function server()
        local row = {
            ID = 94001,
            hasConditions = "unknown",
            ipGated = "unknown",
            scriptedCredit = "unknown",
            killCreditComplete = false,
        }
        for i = 1, 4 do
            row["RequiredNpcOrGo" .. i] = -(1600000000 + i)
            row["RequiredNpcOrGoCount" .. i] = 1
            row["ItemDrop" .. i] = 1400000000 + i
        end
        return M1.FromQuestTemplateRow(row)
    end

    local function ruleCounts(findings)
        local counts = {}
        for _, f in ipairs(findings) do
            assert.is_table(f.rules)
            assert.are.equal(1, #f.rules)
            assert.are.equal("string", type(f.explanation))
            assert.is_true(#f.explanation > 0)
            counts[f.rules[1]] = (counts[f.rules[1]] or 0) + 1
        end
        return counts
    end

    it("observes the additive 140-finding K64 specimen with exact rules", function()
        local q, adapted = quest(64)
        local s = server()
        local beforeQ, beforeA, beforeS = clone(q), clone(adapted), clone(s)
        local findings = M1.Compare(s, adapted)
        assert.is_table(findings)
        assert.are.equal(140, #findings)
        assert.are.same({
            ["C-UNKNOWN"] = 3,
            ["E-QTY"] = 1,
            ["R-GO-UNPAIRED"] = 4,
            ["R-NPC-UNPAIRED"] = 64,
            ["E-SRCITEM"] = 4,
            ["R-ITEM-UNPAIRED"] = 64,
        }, ruleCounts(findings))
        assert.are.same(beforeQ, q)
        assert.are.same(beforeA, adapted)
        assert.are.same(beforeS, s)
        -- This is ONE fabricated configuration, not a proof of a 160 bound,
        -- a 192 finding refusal or complete encoded record/bundle budgets.
    end)

    it("shows adding a 65th Questie-only object does not grow frozen M1 findings", function()
        local q, adapted = quest(65)
        local s = server()
        local beforeQ, beforeA, beforeS = clone(q), clone(adapted), clone(s)
        local findings = M1.Compare(s, adapted)
        assert.are.equal(140, #findings)
        local counts = ruleCounts(findings)
        assert.are.equal(4, counts["R-GO-UNPAIRED"])
        assert.are.equal(64, counts["R-NPC-UNPAIRED"])
        assert.are.equal(64, counts["R-ITEM-UNPAIRED"])
        assert.are.same(beforeQ, q)
        assert.are.same(beforeA, adapted)
        assert.are.same(beforeS, s)
        -- K65 remains valid in frozen v2, but exceeds the approved
        -- initial private-profile K64 design; no refusal is implemented here.
        -- Questie-only GO silence is an M1 legacy limitation (#89).
    end)

    it("observes additive K64 source, ordering and kill-credit rule paths", function()
        -- Still one invented M1-SUPPORTED v2 quest, not a real export.
        -- In addition to K64 creature/object/item, this has exactly
        -- one other ordinary killCredit and six source-item references.
        local objectives = {}
        local function add(kind, entries)
            for slot, spec in ipairs(entries) do
                objectives[#objectives + 1] = {
                    position = #objectives + 1,
                    kind = kind, slotIndex = slot,
                    id = spec, occurrence = 1,
                }
            end
        end
        local creatures, objects, items, sources = {}, {}, {}, {}
        for i = 1, 64 do
            creatures[i] = 1000000000 + i
            objects[i] = 1100000000 + i
            items[i] = 1200000000 + i
        end
        -- Two positive Questie objects match server GOs in reverse order:
        -- both E-GO-SIGN findings survive, plus R-ORDER-WITHIN-TYPE.
        objects[1], objects[2] = 1600000002, 1600000001
        for i = 1, 6 do sources[i] = 1700000000 + i end
        add("creature", creatures)
        add("object", objects)
        add("item", items)
        -- A server creature after the GOs is represented only by
        -- killCredit, forcing E-KILLCREDIT and R-ORDER-MIXED.
        objectives[#objectives + 1] = {
            position = #objectives + 1, kind = "killCredit",
            slotIndex = 1, ids = { 1600000004 }, rootId = 1900000001,
        }
        local q = {
            ID = 94002, requiredLevel = 1, questLevel = 60,
            sourceItemId = 0, requiredSourceItems = sources,
            objectives = objectives, killCreditFirst = false,
            hasTriggerEnd = false, extraObjectives = {},
        }
        q.m1Status, q.m1Reasons = V2.ExpectedM1(q)
        assert.are.equal("SUPPORTED", q.m1Status)
        assert.are.same({}, q.m1Reasons)
        local valid, errors = V2.ValidateQuest(q)
        assert.is_true(valid, table.concat(errors or {}, "; "))
        local beforeQ = clone(q)
        local adapted, errCode = Adapter.ToQuestieRecordV2(q)
        assert.is_nil(errCode)
        assert.is_table(adapted)
        local arrays = adapted[M1.QK.objectives]
        assert.are.equal(64, #arrays[1])
        assert.are.equal(64, #arrays[2])
        assert.are.equal(64, #arrays[3])
        assert.are.equal(1, #arrays[5])
        assert.are.same({ 1600000002 }, arrays[2][1])
        assert.are.same({ 1600000001 }, arrays[2][2])
        assert.are.same({ { 1600000004 }, 1900000001 }, arrays[5][1])
        assert.are.same(sources, adapted[M1.QK.requiredSourceItems])
        assert.are.same(beforeQ, q)

        local row = {
            ID = 94002,
            hasConditions = "unknown",
            ipGated = "unknown",
            scriptedCredit = "unknown",
            killCreditComplete = false,
        }
        for i = 1, 4 do
            row["RequiredNpcOrGo" .. i] =
                (i == 4) and 1600000004 or -(1600000000 + i)
            row["RequiredNpcOrGoCount" .. i] = 1
            row["ItemDrop" .. i] = 1800000000 + i
        end
        for i = 1, 6 do
            row["RequiredItemId" .. i] = sources[i]
            row["RequiredItemCount" .. i] = 1
        end
        local serverRecord = M1.FromQuestTemplateRow(row)
        assert.are.same({}, serverRecord.problems)
        local beforeServer, beforeAdapter = clone(serverRecord), clone(adapted)
        local findings = M1.Compare(serverRecord, adapted)
        assert.are.equal(148, #findings)
        assert.are.same({
            ["C-UNKNOWN"] = 3,
            ["E-QTY"] = 1,
            ["E-GO-SIGN"] = 2,
            ["R-GO-UNPAIRED"] = 1,
            ["E-KILLCREDIT"] = 1,
            ["R-NPC-UNPAIRED"] = 64,
            ["R-ITEM-UNPAIRED"] = 70,
            ["E-SRCITEM"] = 4,
            ["R-ORDER-WITHIN-TYPE"] = 1,
            ["R-ORDER-MIXED"] = 1,
        }, ruleCounts(findings))
        assert.are.same(beforeQ, q)
        assert.are.same(beforeAdapter, adapted)
        assert.are.same(beforeServer, serverRecord)
        -- Observing 148 (versus earlier 140) still cannot prove a global
        -- 160 bound, approve B1's 192 limit, or count full C1 JSON bytes.
    end)
end)
