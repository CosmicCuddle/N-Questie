-- M2.3 Part 2 object/item boundary research, PUBLIC SYNTHETIC DATA ONLY.
-- This spec observes FROZEN v2 and M23Batch, not the future G3 worker.
-- K=64/65 is a proposed future resource gate; no new code, precedence or
-- trust/authentication/publication policy is approved by these observations.
-- Lua 5.1-compatible Busted. No real quest records or private exports.
describe("M2.3 frozen Part 2 object/item K64-K65 baseline (synthetic)", function()
    local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
    local Input = dofile("tools/validation/InputSchema.lua")
    local Membership = dofile("tools/validation/M23Membership.lua")

    local function copy(t)
        if type(t) ~= "table" then return t end
        local result = {}
        for k, v in pairs(t) do result[k] = copy(v) end
        return result
    end

    local function fixtures()
        local provenance = {
            harness = "validate-335", harnessVersion = "1.3.0",
            dataKind = "effective", sourceCommit = string.rep("a", 40),
            sourceTree = string.rep("b", 40), sourceDirty = false,
            tocInterface = 30300, flavour = "wotlk-335",
            nQuestieDataRevision = 5, correctionCount = 28,
            correctionFingerprint = "sha256:" .. string.rep("c", 64),
            correctionModules = { "NQuestieExistingQuestCorrections.lua" },
            m0Checks = 232, exportedAt = "2026-10-15T18:00:00Z",
            questCount = 3,
        }
        local effective = {
            schema = "nq-m2-effective", schemaVersion = 2,
            displayScope = "structural-only",
            provenance = provenance, quests = {},
        }
        local manifest = {
            kind = "nq-m2-coverage-manifest", version = 1,
            note = "Coverage report, not an export. Contains no effective records.",
            provenance = copy(provenance), quests = {},
            aggregate = {
                kind = "nq-m2-coverage-aggregate", version = 1,
                total = 3, representable = 2, unsupported = 1,
                reconciled = true,
                reasonQuests = { REPUTATION_OBJECTIVE = 1 },
            },
        }
        for id = 1, 3 do
            local unsupported = id == 2
            effective.quests[id] = {
                ID = id, requiredLevel = 1, questLevel = 3,
                sourceItemId = 0, requiredSourceItems = {},
                objectives = unsupported and {
                    { position = 1, kind = "reputation", slotIndex = 1,
                      factionId = 72, requiredValue = 0 },
                } or {},
                killCreditFirst = false, hasTriggerEnd = false,
                extraObjectives = {},
                m1Status = unsupported and "UNSUPPORTED_BY_RULES" or "SUPPORTED",
                m1Reasons = unsupported and { "REPUTATION_OBJECTIVE" } or {},
            }
            manifest.quests[id] = {
                ID = id,
                status = unsupported and "UNSUPPORTED" or "REPRESENTABLE",
                reasons = unsupported and { "REPUTATION_OBJECTIVE" } or {},
            }
        end
        local server = {
            schema = "nq-m2-input", schemaVersion = 1,
            provenance = {
                exporter = "nquestie-private-objectives",
                exporterVersion = "3.0.0",
                sourceLabel = "synthetic-only",
                sourceFingerprint = "sha256:" .. string.rep("d", 64),
                exportedAt = "2026-10-15T18:00:00Z",
                selection = "explicit", questCount = 3,
            },
            quests = {},
        }
        -- The unsupported quest is LAST, after two supported M1 comparisons.
        for _, id in ipairs({ 3, 1, 2 }) do
            local row = {
                ID = id, StartItem = 0, KillCredit = {},
                killCreditComplete = true, hasConditions = false,
                scriptedCredit = false, ipGated = false,
            }
            for i = 1, 4 do
                row["RequiredNpcOrGo" .. i] = 0
                row["RequiredNpcOrGoCount" .. i] = 0
                row["ItemDrop" .. i] = 0
            end
            for i = 1, 6 do
                row["RequiredItemId" .. i] = 0
                row["RequiredItemCount" .. i] = 0
            end
            server.quests[#server.quests + 1] = row
        end
        local pins = {
            questCount = 3, supportedCount = 2, unsupportedCount = 1,
        }
        return server, effective, manifest, pins
    end

    local function fillObjectives(q, kind, n, unsupported)
        q.objectives = {}
        for i = 1, n do
            q.objectives[i] = {
                position = i, kind = kind, slotIndex = i,
                id = 90000 + i, occurrence = 1,
            }
        end
        if unsupported then
            q.objectives[n + 1] = {
                position = n + 1, kind = "reputation", slotIndex = 1,
                factionId = 72, requiredValue = 0,
            }
        end
    end

    it("observes K64 and K65 object/item records, supported and unsupported-last", function()
        -- Interception is TEST-ONLY and restored before execution.
        -- The control proves that subsequent M1 call-count claims are live.
        local original = _G.dofile
        local compareCalls = 0
        _G.dofile = function(path)
            local mod = original(path)
            if path ~= "tools/validation/ObjectiveRules.lua" then
                return mod
            end
            local spy = {}
            for k, v in pairs(mod) do spy[k] = v end
            spy.Compare = function(...)
                compareCalls = compareCalls + 1
                return mod.Compare(...)
            end
            return spy
        end
        local loaded, spied = pcall(original, "tools/validation/M23Batch.lua")
        _G.dofile = original
        assert.is_true(loaded)
        assert.are.equal(original, _G.dofile)

        local s0, e0, m0, p0 = fixtures()
        local control, controlCode = spied.Run(s0, e0, m0, p0)
        assert.is_nil(controlCode)
        assert.is_table(control)
        assert.are.equal(2, compareCalls)

        for _, kind in ipairs({ "object", "item" }) do
            for _, n in ipairs({ 64, 65 }) do
                for _, unsupported in ipairs({ false, true }) do
                    local label = kind .. ":" .. n .. ":unsupported=" ..
                        tostring(unsupported)
                    local server, effective, manifest, pins = fixtures()
                    local q = effective.quests[unsupported and 2 or 3]
                    fillObjectives(q, kind, n, unsupported)
                    assert.are.equal(n + (unsupported and 1 or 0),
                        #q.objectives, label)

                    local status, reasons = V2.ExpectedM1(q)
                    assert.are.equal(
                        unsupported and "UNSUPPORTED_BY_RULES" or "SUPPORTED",
                        status, label)
                    assert.are.same(
                        unsupported and { "REPUTATION_OBJECTIVE" } or {},
                        reasons, label)
                    -- Positive fixture controls: test a NEW gate later,
                    -- not a malformed old-v2 record that fails early.
                    assert.is_true(V2.ValidateQuest(q), label)
                    assert.is_true(V2.Validate(effective), label)
                    assert.is_true(Input.Validate(server), label)
                    local index, membershipCode = Membership.Check(
                        effective, manifest, pins)
                    assert.is_nil(membershipCode, label)
                    assert.is_table(index, label)
                    assert.are.equal(2, index.supported, label)
                    assert.are.equal(1, index.unsupported, label)

                    local ss, ee, mm, pp = copy(server), copy(effective),
                        copy(manifest), copy(pins)
                    compareCalls = 0
                    local result, code = spied.Run(
                        server, effective, manifest, pins)
                    assert.is_nil(code, label)
                    assert.is_table(result, label)
                    assert.are.equal(2, compareCalls, label)
                    assert.are.equal(3, #result.rows, label)
                    assert.are.same({ 3, 1, 2 }, {
                        result.rows[1].questId,
                        result.rows[2].questId,
                        result.rows[3].questId,
                    }, label)
                    assert.is_false(result.authenticated, label)
                    assert.is_false(result.publishable, label)
                    assert.is_false(result.rows[3].m1Supported, label)
                    assert.are.equal("M1_UNSUPPORTED_BY_RULES",
                        result.rows[3].outcome, label)
                    assert.are.same({ "REPUTATION_OBJECTIVE" },
                        result.rows[3].reasons, label)
                    assert.are.same({}, result.rows[3].m1Classes, label)
                    for _, row in ipairs(result.rows) do
                        assert.are.same({
                            killCredit = "unknown", conditions = "unknown",
                            scripts = "unknown", ip = "unknown",
                            objectiveData = "unknown",
                        }, row.evidence, label)
                    end
                    assert.are.same(ss, server, label)
                    assert.are.same(ee, effective, label)
                    assert.are.same(mm, manifest, label)
                    assert.are.same(pp, pins, label)
                end
            end
        end
        assert.are.equal(original, _G.dofile)
        -- Frozen Part 2 does not have a K65 preflight. Future G3's
        -- possible zero-M1 K65 refusal is UNIMPLEMENTED and blocked by
        -- D5 (pipeline), D6 (exact fixed code), and G1 resource policy.
    end)
end)
