-- N-Questie M2.3 G2: public/synthetic ONLY research of frozen v2 limits.
-- This test DOES NOT implement or approve M2.3 private preflight limits.
-- The frozen v2 validator's acceptance is deliberately NOT evidence of a
-- future private reporter's acceptance, authentication or publication.
-- Lua 5.1 / Busted, from repository root.
describe("M2.3 frozen v2 nested-resource shape research (synthetic only)", function()
    local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")

    local function base()
        return {
            ID = 60001, requiredLevel = 1, questLevel = 60,
            sourceItemId = 0, requiredSourceItems = {}, objectives = {},
            killCreditFirst = false, hasTriggerEnd = false,
            extraObjectives = {}, m1Status = "SUPPORTED", m1Reasons = {},
        }
    end

    local function integers(n, first)
        local result = {}
        first = first or 100000
        for i = 1, n do result[i] = first + i end
        return result
    end

    local function accepted(q)
        local ok, errs = V2.ValidateQuest(q)
        assert.is_true(ok, table.concat(errs or {}, "; "))
    end

    it("accepts 2048 and 2049 distinct ordinary spell objectives", function()
        -- Spell, killCredit and reputation are the non-K64 ordinary kinds.
        -- The future combined 2048/2049 pre-M1 rule is NOT implemented here.
        local q = base()
        for i = 1, 2049 do
            q.objectives[i] = {
                position = i, kind = "spell", slotIndex = i,
                id = 100000 + i, occurrence = 1,
            }
        end
        accepted(q)
        assert.are.equal("SUPPORTED", V2.ExpectedM1(q))
        q.objectives[2049] = nil
        accepted(q)
        assert.are.equal(2048, #q.objectives)
    end)

    it("accepts 4096 and 4097 distinct required-source-item IDs", function()
        local q = base()
        q.requiredSourceItems = integers(4097)
        accepted(q)
        q.requiredSourceItems[4097] = nil
        accepted(q)
        assert.are.equal(4096, #q.requiredSourceItems)
    end)

    it("accepts 4096 and 4097 distinct IDs inside one killCredit objective", function()
        local q = base()
        local ids = integers(4097)
        q.objectives[1] = {
            position = 1, kind = "killCredit", slotIndex = 1,
            ids = ids, rootId = 99001,
        }
        accepted(q)
        assert.are.equal("SUPPORTED", V2.ExpectedM1(q))
        ids[4097] = nil
        accepted(q)
        assert.are.equal(4096, #ids)
        -- Whether rootId also counts in the NEW 4096 nested budget
        -- is an unresolved design choice; this is not an assertion about it.
    end)

    it("accepts 4096 and 4097 spawn-zone entries in one extra objective", function()
        local q = base()
        local zones = integers(4097, 200000)
        q.extraObjectives[1] = {
            position = 1, icon = 1, hasText = true,
            spawnZones = zones, objectiveIndex = 0, refs = {},
        }
        accepted(q)
        assert.are.equal("SUPPORTED", V2.ExpectedM1(q))
        zones[4097] = nil
        accepted(q)
        assert.are.equal(4096, #zones)
        -- Frozen v2 validates integer/dense spawnZones but does not
        -- presently enforce an M2.3-style nested entry ceiling.
    end)

    it("accepts 4096 and 4097 unique item refs inside one extra objective", function()
        local q = base()
        local refs = {}
        for i = 1, 4097 do
            refs[i] = { type = "item", id = 300000 + i, refIndex = i }
        end
        q.extraObjectives[1] = {
            position = 1, icon = 1, hasText = true,
            spawnZones = {}, objectiveIndex = 0, refs = refs,
        }
        accepted(q)
        assert.are.equal("SUPPORTED", V2.ExpectedM1(q))
        refs[4097] = nil
        accepted(q)
        assert.are.equal(4096, #refs)
    end)

    it("accepts 4096 and 4097 extra-objective entries with spawn-zone data", function()
        local q = base()
        for i = 1, 4097 do
            q.extraObjectives[i] = {
                position = i, icon = 1, hasText = true,
                spawnZones = { 1 }, objectiveIndex = 0, refs = {},
            }
        end
        accepted(q)
        q.extraObjectives[4097] = nil
        accepted(q)
        assert.are.equal(4096, #q.extraObjectives)
        -- A candidate 4096 nested budget that counts both extra
        -- entries and their child zones would already reject at 2049
        -- such entries. Policy requires independent review.
    end)

    it("records frozen-v2 scalar/zone bounds without claiming private acceptance", function()
        -- Existing v2 validates sourceItemId as nonnegative integer but
        -- currently does not apply the same MAX_ID limit as ordinary
        -- objective IDs. This is a structural-validator observation,
        -- NOT an accepted private-finding numeric reference.
        local q = base()
        q.sourceItemId = 2147483648
        accepted(q)
        q.sourceItemId = 0
        q.extraObjectives[1] = {
            position = 1, icon = 1, hasText = true,
            spawnZones = { -1 }, objectiveIndex = 0, refs = {},
        }
        -- Spawn-zone values have an isInt check rather than posId.
        -- This synthetic value illustrates schema shape, not an actual
        -- game-zone claim or an approved future input policy.
        accepted(q)
    end)

    it("distinguishes a prospective combined nested budget from per-list caps", function()
        -- Every individual list below is small. A combined preflight
        -- cannot safely assume a single bounded list proves total safety.
        local q = base()
        q.requiredSourceItems = integers(2048)
        q.objectives[1] = {
            position = 1, kind = "killCredit", slotIndex = 1,
            ids = integers(2048, 500000), rootId = 90001,
        }
        q.extraObjectives[1] = {
            position = 1, icon = 1, hasText = true,
            spawnZones = { 1 }, objectiveIndex = 0, refs = {},
        }
        accepted(q)
        assert.are.equal(2048, #q.requiredSourceItems)
        assert.are.equal(2048, #q.objectives[1].ids)
        assert.are.equal(1, #q.extraObjectives)
        assert.are.equal(1, #q.extraObjectives[1].spawnZones)
        -- Candidate sum excluding scalar rootId = 2048+2048+1+1=4098;
        -- including scalar rootId = 4099. Neither rule is approved yet.
        assert.are.equal(4098,
            #q.requiredSourceItems + #q.objectives[1].ids
            + #q.extraObjectives + #q.extraObjectives[1].spawnZones)
    end)
end)
