-- N-Questie M2.3 design research: synthetic frozen-v2 numeric edge cases.
-- NOT a Part 3 validator/codec, not an approved new profile or a private run.
-- Uses invented in-memory quest records and the existing data-only parser.
-- Lua 5.1 / Busted from repository root.
describe("M2.3 frozen v2 numeric-domain research (synthetic only)", function()
    local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
    local Input = dofile("tools/validation/InputSchema.lua")
    local MAX = 2147483647

    local function quest()
        return {
            ID = 60001, requiredLevel = 1, questLevel = 60,
            sourceItemId = 0, requiredSourceItems = {},
            objectives = {}, killCreditFirst = false,
            hasTriggerEnd = false, extraObjectives = {},
            m1Status = "SUPPORTED", m1Reasons = {},
        }
    end

    local function checkAccepted(q)
        local ok, errs = V2.ValidateQuest(q)
        assert.is_true(ok, table.concat(errs or {}, "; "))
    end

    local function extraWithZones(zones)
        return {
            position = 1, icon = 1, hasText = true,
            spawnZones = zones, objectiveIndex = 0, refs = {},
        }
    end

    it("frozen v2 structurally accepts sourceItemId above int32 MAX", function()
        local q = quest()
        q.sourceItemId = MAX + 1
        checkAccepted(q)
        q.sourceItemId = 9007199254740994 -- 2^53+2, exactly representable
        checkAccepted(q)
        -- Neither acceptance is future private-profile permission.
        q.sourceItemId = -1
        assert.is_false(V2.ValidateQuest(q))
    end)

    it("frozen v2 structurally accepts infinite sourceItemId", function()
        local q = quest()
        q.sourceItemId = math.huge
        checkAccepted(q)
        assert.are.equal(math.huge, q.sourceItemId)
        -- Frozen v2's isInt regards infinity as equal to floor(infinity).
    end)

    it("frozen v2 accepts positive/negative infinity as spawn-zone entries", function()
        local q = quest()
        q.extraObjectives[1] = extraWithZones({ math.huge, -math.huge })
        checkAccepted(q)
        q.extraObjectives[1].spawnZones = { 1.5 }
        assert.is_false(V2.ValidateQuest(q))
        -- No real zone data or semantics are inferred from these values.
    end)

    it("frozen v2 keeps positive IDs in its separate bounded domain", function()
        local q = quest()
        q.requiredSourceItems = { MAX }
        checkAccepted(q)
        q.requiredSourceItems = { MAX + 1 }
        assert.is_false(V2.ValidateQuest(q))
        q.requiredSourceItems = { math.huge }
        assert.is_false(V2.ValidateQuest(q))
        -- This is different from sourceItemId and spawnZones.
    end)

    it("data-only parser can represent overflow literals as infinities", function()
        -- ParseString parses a data literal, without executing source code.
        -- This small synthetic table is intentionally NOT a valid v2 doc.
        local parsed, err = Input.ParseString(
            "return { sourceItemId = 1e999, spawnZones = { -1e999 } }")
        assert.is_nil(err)
        assert.is_table(parsed)
        assert.are.equal(math.huge, parsed.sourceItemId)
        assert.are.equal(-math.huge, parsed.spawnZones[1])
        -- Any future Part 3 preflight must not assume a parsed number is
        -- finite or representable merely because the parser returned it.
    end)

    it("Lua 5.1 double precision cannot preserve every large integer", function()
        local limit = 9007199254740992 -- 2^53
        assert.are.equal(limit, limit + 1)
        local q = quest()
        q.sourceItemId = limit + 1
        checkAccepted(q)
        assert.are.equal(limit, q.sourceItemId)
        -- A future private codec must refuse out-of-profile numbers
        -- before any decimal formatting; frozen v2 remains untouched.
    end)
end)
