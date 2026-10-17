-- Synthetic Part 2 baseline for the G1 2,048 combined OTHER-ordinary proposal.
-- This is RESEARCH ONLY, not a Part 3 resource guard or an approval.
-- Observe frozen EffectiveSchemaV2 + M23QuestieAdapter without calling M1.
-- No real M23Batch.Run or M1.Compare: adapter acceptance is not M1 success.
-- Never modify frozen modules, trusted CLI, private exports or real data.
describe("M2.3 other ordinary 2048/2049 boundary (synthetic only)", function()
    local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
    local Adapter = dofile("tools/validation/M23QuestieAdapter.lua")
    local PROPOSED_OTHER_LIMIT = 2048 -- ceiling; exact G1 worker rules not approved

    local function copy(value)
        if type(value) ~= "table" then return value end
        local result = {}
        for k, v in pairs(value) do result[copy(k)] = copy(v) end
        return result
    end

    local function synthetic(spells, withKillCredit, withReputation, withCreature)
        local q = {
            ID = 9007, requiredLevel = 1, questLevel = 3,
            sourceItemId = 0, requiredSourceItems = {},
            objectives = {}, killCreditFirst = false, hasTriggerEnd = false,
            extraObjectives = {}, m1Status = "SUPPORTED", m1Reasons = {},
        }
        local objectives = q.objectives
        if withCreature then
            objectives[#objectives + 1] = {
                position = #objectives + 1, kind = "creature",
                slotIndex = 1, id = 40001, occurrence = 1,
            }
        end
        if withReputation then
            objectives[#objectives + 1] = {
                position = #objectives + 1, kind = "reputation",
                slotIndex = 1, factionId = 1001, requiredValue = 0,
            }
        end
        local killCount = type(withKillCredit) == "number" and withKillCredit
            or (withKillCredit and 1 or 0)
        for i = 1, killCount do
            objectives[#objectives + 1] = {
                position = #objectives + 1, kind = "killCredit",
                slotIndex = i, rootId = 30000 + i, ids = { 30000 + i },
            }
        end
        for i = 1, spells do
            objectives[#objectives + 1] = {
                position = #objectives + 1, kind = "spell",
                slotIndex = i, id = 100000 + i, occurrence = 1,
            }
        end
        q.m1Status, q.m1Reasons = V2.ExpectedM1(q)
        return q
    end

    -- Proposed other-ordinary candidate arithmetic only. A nominally
    -- over-limit result is NOT a frozen-v2 refusal or a new-worker verdict.
    local function otherCount(q)
        local counts = { reputation = 0, killCredit = 0, spell = 0 }
        for _, obj in ipairs(q.objectives) do
            if counts[obj.kind] ~= nil then
                counts[obj.kind] = counts[obj.kind] + 1
            end
        end
        return counts.reputation + counts.killCredit + counts.spell, counts
    end

    local cases = {
        {
            label = "2048 spells, supported equality",
            spells = 2048, kill = false, rep = false,
            count = 2048, pass = true,
        },
        {
            label = "2049 spells, frozen supported past proposal",
            spells = 2049, kill = false, rep = false,
            count = 2049, pass = false,
        },
        {
            label = "2047 spells plus killCredit, supported equality",
            spells = 2047, kill = true, rep = false,
            count = 2048, pass = true,
        },
        {
            label = "2048 spells plus killCredit, supported past proposal",
            spells = 2048, kill = true, rep = false,
            count = 2049, pass = false,
        },
        {
            label = "2046 spells plus TWO killCredits: equality",
            spells = 2046, kill = 2, rep = false,
            count = 2048, pass = true,
        },
        {
            label = "2047 spells plus TWO killCredits: past proposal",
            spells = 2047, kill = 2, rep = false,
            count = 2049, pass = false,
        },
        {
            label = "creature plus 2048 spells: creature excluded, equality",
            spells = 2048, kill = false, rep = false, creature = true,
            count = 2048, pass = true,
        },
        {
            label = "creature plus 2049 spells: creature excluded, past proposal",
            spells = 2049, kill = false, rep = false, creature = true,
            count = 2049, pass = false,
        },
        {
            label = "2046 spells plus killCredit plus reputation, unsupported equality",
            spells = 2046, kill = true, rep = true,
            count = 2048, pass = true,
        },
        {
            label = "2047 spells plus killCredit plus reputation, unsupported past proposal",
            spells = 2047, kill = true, rep = true,
            count = 2049, pass = false,
        },
    }

    it("separately proves frozen v2 permits both boundary sizes", function()
        local originalDofile = _G.dofile
        for _, case in ipairs(cases) do
            local q = synthetic(case.spells, case.kill, case.rep,
                case.creature)
            local expectedStatus = case.rep and "UNSUPPORTED_BY_RULES" or "SUPPORTED"
            local expectedReasons = case.rep and { "REPUTATION_OBJECTIVE" } or {}
            local computedStatus, computedReasons = V2.ExpectedM1(q)
            assert.are.equal(expectedStatus, computedStatus, case.label)
            assert.are.same(expectedReasons, computedReasons, case.label)
            assert.are.equal(expectedStatus, q.m1Status, case.label)
            assert.are.same(expectedReasons, q.m1Reasons, case.label)

            local valid, errors = V2.ValidateQuest(q)
            assert.is_true(valid, case.label .. ": " ..
                table.concat(errors or {}, "; "))

            local before = copy(q)
            local total, counts = otherCount(q)
            assert.are.equal(case.spells, counts.spell, case.label)
            local expectedKill = type(case.kill) == "number" and case.kill
                or (case.kill and 1 or 0)
            assert.are.equal(expectedKill, counts.killCredit, case.label)
            assert.are.equal(total + (case.creature and 1 or 0),
                #q.objectives, case.label)
            assert.are.equal(case.rep and 1 or 0, counts.reputation, case.label)
            assert.are.equal(case.count, total, case.label)
            assert.are.equal(case.pass, total <= PROPOSED_OTHER_LIMIT, case.label)

            local adapted, code = Adapter.ToQuestieRecordV2(q)
            if case.rep then
                -- Historical adapter refuses unsupported records; this
                -- code says NOTHING about future over-limit classification.
                assert.is_nil(adapted, case.label)
                assert.are.equal("REJECTED_MALFORMED_INPUT", code, case.label)
            else
                -- Both 2048 and 2049 supported source records reach the
                -- pure adapter; any NEW preflight would be a policy change.
                assert.is_nil(code, case.label)
                assert.is_table(adapted, case.label)
                assert.are.equal(case.spells, #adapted[10][6], case.label)
                assert.are.same({ 100001 }, adapted[10][6][1], case.label)
                assert.are.same({ 100000 + case.spells },
                    adapted[10][6][case.spells], case.label)
                assert.are.equal(expectedKill, #adapted[10][5], case.label)
                for i = 1, expectedKill do
                    assert.are.same({ { 30000 + i }, 30000 + i },
                        adapted[10][5][i], case.label)
                end
                assert.are.equal(case.creature and 1 or 0,
                    #adapted[10][1], case.label)
                if case.creature then
                    assert.are.same({ 40001 }, adapted[10][1][1], case.label)
                end
            end
            assert.are.same(before, q, case.label)
        end
        assert.are.equal(originalDofile, _G.dofile)
    end)
end)
