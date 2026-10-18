-- Synthetic-only source research for frozen M1 explanation amplification.
-- No private findings serializer, G3 resource gate, production code, or I/O.
-- K=64 per creature/object/item is owner-approved in principle, while B1
-- findings/byte limits and C1 canonical codec remain UNAPPROVED proposals.
describe("M2.3 K64 scripted explanation amplification baseline", function()
    local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
    local Adapter = dofile("tools/validation/M23QuestieAdapter.lua")
    local M1 = dofile("tools/validation/ObjectiveRules.lua")

    local function copy(value)
        if type(value) ~= "table" then return value end
        local out = {}
        for k, v in pairs(value) do out[copy(k)] = copy(v) end
        return out
    end

    local function syntheticQuest()
        local objectives = {}
        for _, group in ipairs({
            { "creature", 1000000000 },
            { "object", 1100000000 },
            { "item", 1200000000 },
        }) do
            for slot = 1, 64 do
                objectives[#objectives + 1] = {
                    position = #objectives + 1,
                    kind = group[1], slotIndex = slot,
                    id = group[2] + slot, occurrence = 1,
                }
            end
        end
        local q = {
            ID = 95001, requiredLevel = 1, questLevel = 60,
            sourceItemId = 0, requiredSourceItems = {},
            objectives = objectives, killCreditFirst = false,
            hasTriggerEnd = false, extraObjectives = {},
        }
        q.m1Status, q.m1Reasons = V2.ExpectedM1(q)
        assert.are.equal("SUPPORTED", q.m1Status)
        assert.are.same({}, q.m1Reasons)
        local valid, errors = V2.ValidateQuest(q)
        assert.is_true(valid, table.concat(errors or {}, "; "))
        local before = copy(q)
        local adapted, errCode = Adapter.ToQuestieRecordV2(q)
        assert.is_nil(errCode)
        local a = adapted[M1.QK.objectives]
        for k = 1, 3 do assert.are.equal(64, #a[k]) end
        assert.are.same({ 1000000001 }, a[1][1])
        assert.are.same({ 1000000064 }, a[1][64])
        assert.are.same({ 1100000001 }, a[2][1])
        assert.are.same({ 1100000064 }, a[2][64])
        assert.are.same({ 1200000001 }, a[3][1])
        assert.are.same({ 1200000064 }, a[3][64])
        assert.are.same(before, q)
        return q, adapted
    end

    local function syntheticServer(scripted)
        local row = {
            ID = 95001,
            hasConditions = "unknown",
            ipGated = "unknown",
            scriptedCredit = scripted,
            killCreditComplete = false,
        }
        for i = 1, 4 do
            row["RequiredNpcOrGo" .. i] = 1600000000 + i
            row["RequiredNpcOrGoCount" .. i] = 1
            row["ItemDrop" .. i] = 1400000000 + i
        end
        return M1.FromQuestTemplateRow(row)
    end

    local function inspect(findings)
        local rules, bytes, scriptedBytes, scriptedLengths = {}, 0, 0, {}
        for _, finding in ipairs(findings) do
            assert.is_table(finding.rules)
            assert.are.equal(1, #finding.rules)
            local rule = finding.rules[1]
            rules[rule] = (rules[rule] or 0) + 1
            -- Pin the original frozen M1 kind for every observed rule.
            local expectedKind = {
                ["C-UNKNOWN"] = "availability",
                ["E-QTY"] = "quantity",
                ["C-SCRIPT"] = "creature",
                ["R-NPC-SET"] = "creature",
                ["E-SRCITEM"] = "item",
                ["R-ITEM-UNPAIRED"] = "item",
            }
            assert.are.equal(expectedKind[rule], finding.kind)
            assert.are.equal("string", type(finding.explanation))
            assert.is_true(#finding.explanation > 0)
            if rule == "R-NPC-SET" then
                -- Frozen set finding carries two typed comma-space strings;
                -- these bytes belong to output budget accounting too.
                assert.are.equal(944, #finding.explanation)
                assert.are.equal("string", type(finding.server))
                assert.are.equal("string", type(finding.questie))
                assert.are.equal(46, #finding.server)
                assert.are.equal(766, #finding.questie)
            end
            bytes = bytes + #finding.explanation
            if rule == "C-SCRIPT" then
                assert.are.equal("number", type(finding.server))
                assert.is_nil(finding.questie)
                scriptedBytes = scriptedBytes + #finding.explanation
                scriptedLengths[#scriptedLengths + 1] = #finding.explanation
            end
        end
        return rules, bytes, scriptedBytes, scriptedLengths
    end

    it("contrasts four repeated scripted explanations with one creature set", function()
        local q, adapted = syntheticQuest()
        local qBefore, adaptedBefore = copy(q), copy(adapted)
        local scripted, ordinary = syntheticServer(true), syntheticServer(false)
        local scriptedBefore, ordinaryBefore = copy(scripted), copy(ordinary)
        local a = M1.Compare(scripted, adapted)
        local b = M1.Compare(ordinary, adapted)
        assert.are.equal(75, #a)
        assert.are.equal(72, #b)

        local ar, aBytes, scriptBytes, lengths = inspect(a)
        local br, bBytes, _, missingScriptLengths = inspect(b)
        assert.are.same({
            ["C-UNKNOWN"] = 2,
            ["E-QTY"] = 1,
            ["C-SCRIPT"] = 4,
            ["E-SRCITEM"] = 4,
            ["R-ITEM-UNPAIRED"] = 64,
        }, ar)
        assert.are.same({
            ["C-UNKNOWN"] = 2,
            ["E-QTY"] = 1,
            ["R-NPC-SET"] = 1,
            ["E-SRCITEM"] = 4,
            ["R-ITEM-UNPAIRED"] = 64,
        }, br)
        assert.are.same({ 877, 877, 877, 877 }, lengths)
        assert.are.equal(3508, scriptBytes)
        assert.are.same({}, missingScriptLengths)
        -- Exact original explanation bytes, independent of rules counts.
        -- 4x877 C-SCRIPT explains the 2,564-byte delta vs R-NPC-SET.
        assert.are.equal(8222, aBytes)
        assert.are.equal(5658, bBytes)
        assert.are.equal(2564, aBytes - bBytes)
        -- The ordinary R-NPC-SET additionally carries 46 + 766 reference
        -- string bytes. This is still NOT canonical JSON/framing overhead.
        assert.are.equal(6470, bBytes + 46 + 766)
        -- Every count/byte observation is about ORIGINAL M1 explanations.
        -- Neither figure is a full canonical JSON quest/bundle byte count.
        assert.are.same(qBefore, q)
        assert.are.same(adaptedBefore, adapted)
        assert.are.same(scriptedBefore, scripted)
        assert.are.same(ordinaryBefore, ordinary)
    end)
end)
