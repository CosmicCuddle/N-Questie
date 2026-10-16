-- N-Questie M2.3 research, public/synthetic ONLY.
-- Frozen M1 and frozen v1 schema acceptance at the signed GO boundary.
-- This is not a Part 3 worker, schema implementation, exporter or publisher.
-- Lua 5.1 / Busted from the repository root.
describe("M2.3 negative gameobject boundary research (synthetic only)", function()
    local M1 = dofile("tools/validation/ObjectiveRules.lua")
    local Input = dofile("tools/validation/InputSchema.lua")
    local MAX = 2147483647

    local function serverRow(goId, scripted)
        local q = {
            ID = 60001, StartItem = 0, KillCredit = {},
            killCreditComplete = true, hasConditions = false,
            scriptedCredit = scripted == true, ipGated = false,
        }
        for i = 1, 4 do
            q["RequiredNpcOrGo" .. i] = 0
            q["RequiredNpcOrGoCount" .. i] = 0
            q["ItemDrop" .. i] = 0
        end
        q.RequiredNpcOrGo1 = goId
        q.RequiredNpcOrGoCount1 = 1
        for i = 1, 6 do
            q["RequiredItemId" .. i] = 0
            q["RequiredItemCount" .. i] = 0
        end
        return q
    end

    local function effectiveQuestie(creatures, objects)
        local function targets(ids)
            local out = {}
            for i, id in ipairs(ids or {}) do out[i] = { id } end
            return out
        end
        return {
            [M1.QK.objectives] = {
                targets(creatures), targets(objects),
                {}, {}, {}, {},
            },
        }
    end

    local function getRule(findings, name)
        local hit
        for _, f in ipairs(findings) do
            if type(f.rules) == "table" then
                for _, code in ipairs(f.rules) do
                    if code == name then
                        assert.is_nil(hit, "expected one instance of " .. name)
                        hit = f
                    end
                end
            end
        end
        assert.is_not_nil(hit, "expected rule " .. name)
        return hit
    end

    local function case(rule, creatures, objects, scripted, klass, questieSide)
        local row = serverRow(-MAX, scripted)
        local findings = M1.Compare(
            M1.FromQuestTemplateRow(row),
            effectiveQuestie(creatures, objects))
        local f = getRule(findings, rule)
        assert.are.equal("object", f.kind)
        assert.are.equal(klass, f.class)
        assert.are.equal(-MAX, f.server)
        if questieSide then
            assert.are.equal(MAX, f.questie)
        else
            assert.is_nil(f.questie)
        end
        assert.is_true(type(f.explanation) == "string" and #f.explanation > 0)
        assert.are.equal(-MAX, row.RequiredNpcOrGo1)
    end

    it("retains -INT32 server sign for E-GO-SIGN", function()
        case("E-GO-SIGN", {}, { MAX }, false,
            "EXPECTED_REPRESENTATION_DIFF", true)
    end)

    it("retains -INT32 server sign when GO is listed as creature", function()
        case("R-GO-AS-NPC", { MAX }, {}, false,
            "NEEDS_MANUAL_REVIEW", true)
    end)

    it("retains -INT32 server sign for scripted GO with absent questie side", function()
        case("C-SCRIPT", {}, {}, true,
            "UNSUPPORTED", false)
    end)

    it("retains -INT32 server sign for unpaired GO with absent questie side", function()
        case("R-GO-UNPAIRED", {}, {}, false,
            "NEEDS_MANUAL_REVIEW", false)
    end)

    it("frozen v1 accepts -2147483647 but rejects -2147483648", function()
        local doc = {
            schema = "nq-m2-input", schemaVersion = 1,
            provenance = {
                exporter = "nquestie-private-objectives",
                exporterVersion = "3.0.0",
                sourceLabel = "synthetic-only",
                sourceFingerprint = "sha256:" .. string.rep("d", 64),
                exportedAt = "2026-10-15T18:00:00Z",
                selection = "explicit", questCount = 1,
            },
            quests = { serverRow(-MAX, false) },
        }
        assert.is_true(Input.Validate(doc))
        doc.quests[1].RequiredNpcOrGo1 = -(MAX + 1)
        local ok = Input.Validate(doc)
        assert.is_false(ok)
        -- This is a frozen-v1 input refusal, NOT evidence that a
        -- future private findings-v1 engine exists.
    end)
end)
