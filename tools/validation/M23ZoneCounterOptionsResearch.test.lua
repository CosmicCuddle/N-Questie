-- M2.3 G1 options A/B/C: SYNTHETIC RESEARCH, NOT POLICY OR IMPLEMENTATION.
-- This spec compares the three unapproved counting proposals in draft #82.
-- It does not select a winner, implement resource refusal, call M1, trust
-- private exports, publish output, or change frozen v2 / Part 2.
-- Counts here are TEST-LOCAL arithmetic ONLY. Lua 5.1-compatible Busted.
describe("M2.3 proposed nested/zone counter options (synthetic only)", function()
    local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
    local Adapter = dofile("tools/validation/M23QuestieAdapter.lua")
    local LIMIT = 4096 -- owner-approved numeric ceiling; formula NOT approved

    local function quest()
        return {
            ID = 7, requiredLevel = 1, questLevel = 3,
            sourceItemId = 0, requiredSourceItems = {},
            objectives = {}, killCreditFirst = false,
            hasTriggerEnd = false, extraObjectives = {},
            m1Status = "SUPPORTED", m1Reasons = {},
        }
    end

    local function numbers(n, base)
        local t = {}
        for i = 1, n do t[i] = (base or 0) + i end
        return t
    end

    local function extraRefs(n, kind)
        local out = {}
        for i = 1, n do
            out[i] = { type = kind or "monster", id = 90000 + i, refIndex = i }
        end
        return out
    end

    local function copy(value)
        if type(value) ~= "table" then return value end
        local out = {}
        for k, v in pairs(value) do out[copy(k)] = copy(v) end
        return out
    end

    local function extra(i, zoneCount, refs)
        return {
            position = i, icon = 1, hasText = false,
            objectiveIndex = 0, spawnZones = numbers(zoneCount),
            refs = refs or {},
        }
    end

    local function finalise(q)
        local status, reasons = V2.ExpectedM1(q)
        q.m1Status, q.m1Reasons = status, reasons
        return q
    end

    -- Derived verbatim from draft #82 §2's unapproved candidate arithmetic.
    -- "Pass" below means ONE candidate COUNT GATE only, never approval of
    -- the record for M1/CLI/bundle publication or even other safety gates.
    local function candidateCounts(q)
        local m1Nested = #q.requiredSourceItems + #q.extraObjectives
        local zoneEntries = 0
        for _, o in ipairs(q.objectives) do
            if o.kind == "killCredit" then
                m1Nested = m1Nested + #o.ids
                -- rootId is a scalar, not a second nested array member.
            end
        end
        for _, e in ipairs(q.extraObjectives) do
            m1Nested = m1Nested + #e.refs
            zoneEntries = zoneEntries + #e.spawnZones
        end
        return m1Nested, zoneEntries
    end

    local function options(m1Nested, zoneEntries)
        -- A: M1-only bound. B: one combined count. C: two separate caps.
        return {
            A = m1Nested <= LIMIT,
            B = m1Nested + zoneEntries <= LIMIT,
            C = m1Nested <= LIMIT and zoneEntries <= LIMIT,
        }
    end

    -- A genuinely SUPPORTED fixture with three kinds of M1-forwarded
    -- nested arrays. The private worker and actual M1 are NEVER invoked.
    local function mixedSupported(killIdCount)
        local q = quest()
        q.requiredSourceItems = numbers(1000, 100000)
        q.extraObjectives = { extra(1, 1, extraRefs(1000, "item")) }
        q.objectives = {
            { position = 1, kind = "killCredit", slotIndex = 1,
              rootId = 200001, ids = numbers(killIdCount, 200000) },
        }
        return finalise(q)
    end

    local function twoKillCredits(secondCount)
        local q = quest()
        q.objectives = {
            { position = 1, kind = "killCredit", slotIndex = 1,
              rootId = 100001, ids = numbers(2048, 100000) },
            { position = 2, kind = "killCredit", slotIndex = 2,
              rootId = 200001, ids = numbers(secondCount, 200000) },
        }
        return finalise(q)
    end

    local cases = {
        {
            name = "one extra with 4095 zones: B equality passes",
            make = function()
                local q = quest()
                q.extraObjectives = { extra(1, 4095) }
                return finalise(q)
            end,
            m1 = 1, zones = 4095,
            expected = { A = true, B = true, C = true },
        },
        {
            name = "one extra with 4096 zones: A/C pass, B refuses",
            make = function()
                local q = quest()
                q.extraObjectives = { extra(1, 4096) }
                return finalise(q)
            end,
            m1 = 1, zones = 4096,
            expected = { A = true, B = false, C = true },
        },
        {
            name = "one extra with 4097 zones: only A passes",
            make = function()
                local q = quest()
                q.extraObjectives = { extra(1, 4097) }
                return finalise(q)
            end,
            m1 = 1, zones = 4097,
            expected = { A = true, B = false, C = false },
        },
        {
            name = "two extras split 2047 plus 2047 zones: B equality passes",
            make = function()
                local q = quest()
                q.extraObjectives = { extra(1, 2047), extra(2, 2047) }
                return finalise(q)
            end,
            m1 = 2, zones = 4094,
            expected = { A = true, B = true, C = true },
        },
        {
            name = "two extras split 2048 plus 2048 zones: C equality passes",
            make = function()
                local q = quest()
                q.extraObjectives = { extra(1, 2048), extra(2, 2048) }
                return finalise(q)
            end,
            m1 = 2, zones = 4096,
            expected = { A = true, B = false, C = true },
        },
        {
            name = "two extras split 2048 plus 2049 zones: C refuses",
            make = function()
                local q = quest()
                q.extraObjectives = { extra(1, 2048), extra(2, 2049) }
                return finalise(q)
            end,
            m1 = 2, zones = 4097,
            expected = { A = true, B = false, C = false },
        },
        {
            name = "2048 extras with one zone: all count gates pass",
            make = function()
                local q = quest()
                for i = 1, 2048 do
                    q.extraObjectives[i] = extra(i, 1)
                end
                return finalise(q)
            end,
            m1 = 2048, zones = 2048,
            expected = { A = true, B = true, C = true },
        },
        {
            name = "2049 extras with one zone: B alone refuses",
            make = function()
                local q = quest()
                for i = 1, 2049 do
                    q.extraObjectives[i] = extra(i, 1)
                end
                return finalise(q)
            end,
            m1 = 2049, zones = 2049,
            expected = { A = true, B = false, C = true },
        },
        {
            name = "4096 required source items: equality passes",
            make = function()
                local q = quest()
                q.requiredSourceItems = numbers(4096, 100000)
                return finalise(q)
            end,
            m1 = 4096, zones = 0,
            expected = { A = true, B = true, C = true },
        },
        {
            name = "4097 required source items: all refuse",
            make = function()
                local q = quest()
                q.requiredSourceItems = numbers(4097, 100000)
                return finalise(q)
            end,
            m1 = 4097, zones = 0,
            expected = { A = false, B = false, C = false },
        },
        {
            name = "4095 extra monster refs plus extra itself: equality",
            make = function()
                local q = quest()
                q.extraObjectives = { extra(1, 0, extraRefs(4095)) }
                return finalise(q)
            end,
            m1 = 4096, zones = 0,
            expected = { A = true, B = true, C = true },
            unsupported = true,
        },
        {
            name = "4096 extra monster refs plus extra: all refuse",
            make = function()
                local q = quest()
                q.extraObjectives = { extra(1, 0, extraRefs(4096)) }
                return finalise(q)
            end,
            m1 = 4097, zones = 0,
            expected = { A = false, B = false, C = false },
            unsupported = true,
        },
        {
            name = "mixed supported arrays total 4096: B alone refuses",
            make = function() return mixedSupported(2095) end,
            -- 1000 sources + 1 extra + 1000 refs + 2095 kill IDs = 4096
            m1 = 4096, zones = 1,
            expected = { A = true, B = false, C = true },
        },
        {
            name = "mixed supported arrays total 4097: all refuse",
            make = function() return mixedSupported(2096) end,
            m1 = 4097, zones = 1,
            expected = { A = false, B = false, C = false },
        },
        {
            name = "4095 source items plus one extra: B refuses",
            make = function()
                local q = quest()
                q.requiredSourceItems = numbers(4095, 100000)
                q.extraObjectives = { extra(1, 1) }
                return finalise(q)
            end,
            m1 = 4096, zones = 1,
            expected = { A = true, B = false, C = true },
        },
        {
            name = "4096 source items plus one extra: all refuse",
            make = function()
                local q = quest()
                q.requiredSourceItems = numbers(4096, 100000)
                q.extraObjectives = { extra(1, 1) }
                return finalise(q)
            end,
            m1 = 4097, zones = 1,
            expected = { A = false, B = false, C = false },
        },
        {
            name = "4096 killCredit IDs: rootId is not double-counted",
            make = function()
                local q = quest()
                q.objectives = {
                    { position = 1, kind = "killCredit", slotIndex = 1,
                      rootId = 100001, ids = numbers(4096, 100000) },
                }
                return finalise(q)
            end,
            m1 = 4096, zones = 0,
            expected = { A = true, B = true, C = true },
        },
        {
            name = "4097 killCredit IDs: all refuse count gate",
            make = function()
                local q = quest()
                q.objectives = {
                    { position = 1, kind = "killCredit", slotIndex = 1,
                      rootId = 100001, ids = numbers(4097, 100000) },
                }
                return finalise(q)
            end,
            m1 = 4097, zones = 0,
            expected = { A = false, B = false, C = false },
        },
        {
            name = "two killCredit objectives sum to 4096: all pass",
            make = function() return twoKillCredits(2048) end,
            m1 = 4096, zones = 0,
            expected = { A = true, B = true, C = true },
        },
        {
            name = "two killCredit objectives sum to 4097: all refuse",
            make = function() return twoKillCredits(2049) end,
            m1 = 4097, zones = 0,
            expected = { A = false, B = false, C = false },
        },
        {
            name = "unsupported extra monster ref is counted too",
            make = function()
                local q = quest()
                q.extraObjectives = { extra(1, 4095, {
                    { type = "monster", id = 90901, refIndex = 1 },
                }) }
                return finalise(q)
            end,
            m1 = 2, zones = 4095,
            expected = { A = true, B = false, C = true },
            unsupported = true,
        },
    }

    it("verifies each candidate result on genuinely frozen-v2-valid records", function()
        -- Every fixture is individually validated BEFORE test-local counting.
        -- An older schema rejection cannot masquerade as the proposed cap.
        local originalDofile = _G.dofile
        for _, case in ipairs(cases) do
            local q = case.make()
            local status, reasons = V2.ExpectedM1(q)
            assert.are.equal(case.unsupported and "UNSUPPORTED_BY_RULES"
                or "SUPPORTED", status, case.name)
            assert.are.same(case.unsupported and { "EXTRA_CREATURE_REF" }
                or {}, reasons, case.name)
            local ok, errors = V2.ValidateQuest(q)
            assert.is_true(ok, case.name .. ": " ..
                table.concat(errors or {}, "; "))
            local before = copy(q)
            local m1, zones = candidateCounts(q)
            assert.are.equal(case.m1, m1, case.name)
            assert.are.equal(case.zones, zones, case.name)
            assert.are.same(case.expected, options(m1, zones), case.name)
            -- Full deep snapshot, including all array members and fields.
            assert.are.same(before, q, case.name)
        end
        assert.are.equal(originalDofile, _G.dofile)
    end)

    it("pins actual M1 adapter arrays for the mixed 4096/4097 cases", function()
        -- These are adapter observations, NOT an M1 invocation or a new
        -- pre-M1 resource gate. A/B/C remain unapproved alternatives.
        for _, count in ipairs({ 2095, 2096 }) do
            local q = mixedSupported(count)
            assert.are.equal("SUPPORTED", q.m1Status)
            assert.are.same({}, q.m1Reasons)
            assert.is_true(V2.ValidateQuest(q))
            local snapshot = copy(q)
            local adapted, code = Adapter.ToQuestieRecordV2(q)
            assert.is_nil(code)
            assert.is_table(adapted)
            assert.are.equal(1000, #adapted[21])
            assert.are.same(q.requiredSourceItems, adapted[21])
            assert.are.equal(1, #adapted[27])
            assert.are.equal(0, adapted[27][1][4])
            local refs = adapted[27][1][5]
            assert.are.equal(1000, #refs)
            assert.are.same({ "item", 90001 }, refs[1])
            assert.are.same({ "item", 91000 }, refs[1000])
            assert.is_nil(adapted[27][1][6]) -- zones are not forwarded
            local killCredit = adapted[10][5][1]
            assert.are.equal(count, #killCredit[1])
            assert.are.equal(200001, killCredit[1][1])
            assert.are.equal(200000 + count, killCredit[1][count])
            assert.are.equal(200001, killCredit[2]) -- rootId is scalar
            local nested, zones = candidateCounts(q)
            assert.are.equal(1000 + 1 + 1000 + count, nested)
            assert.are.equal(1, zones)
            assert.are.same(snapshot, q) -- adapter did not mutate input
        end
    end)

    it("checks frozen adapter preserves BOTH killCredit objective arrays", function()
        -- Guards against first-only counting while avoiding real M1 calls.
        for _, secondCount in ipairs({ 2048, 2049 }) do
            local q = twoKillCredits(secondCount)
            assert.are.equal("SUPPORTED", q.m1Status)
            assert.is_true(V2.ValidateQuest(q))
            local before = copy(q)
            local adapted, code = Adapter.ToQuestieRecordV2(q)
            assert.is_nil(code)
            assert.is_table(adapted)
            assert.are.equal(2, #adapted[10][5])
            assert.are.equal(2048, #adapted[10][5][1][1])
            assert.are.equal(secondCount, #adapted[10][5][2][1])
            assert.are.equal(100001, adapted[10][5][1][2])
            assert.are.equal(200001, adapted[10][5][2][2])
            assert.are.equal(2048 + secondCount, candidateCounts(q))
            assert.are.same(before, q)
        end
    end)

    it("confirms frozen M1 adapter drops zones without changing source", function()
        local q = finalise(quest())
        q.extraObjectives = { extra(1, 4096) }
        q = finalise(q)
        assert.is_true(V2.ValidateQuest(q))
        local before = copy(q)
        local adapted, code = Adapter.ToQuestieRecordV2(q)
        assert.is_nil(code)
        assert.is_table(adapted)
        assert.are.equal(1, #adapted[27])
        assert.are.equal(0, adapted[27][1][4])
        assert.are.same({}, adapted[27][1][5])
        assert.is_nil(adapted[27][1][6])
        assert.are.equal(4096, #q.extraObjectives[1].spawnZones)
        assert.are.same({ A = true, B = false, C = true },
            options(candidateCounts(q)))
        -- The original v2 record retains all 4096 zones: no mutation.
        assert.are.same(before, q)
    end)
end)
