-- N-Questie M2.3 Part 3: test-only loader spy research on MERGED Part 2.
-- This is PUBLIC/SYNTHETIC-only. It does not implement a Part 3 worker,
-- change frozen ObjectiveRules, authorise private data, or publish findings.
-- Lua 5.1 / Busted; executed from the repository root.
describe("M2.3 M1 single-call test-loader research (synthetic only)", function()
    local originalDofile = dofile
    local realM1 = originalDofile("tools/validation/ObjectiveRules.lua")

    local function clone(t)
        if type(t) ~= "table" then return t end
        local out = {}
        for k, v in pairs(t) do out[k] = clone(v) end
        return out
    end

    local function data()
        local p = {
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
            displayScope = "structural-only", provenance = p, quests = {},
        }
        local manifest = {
            kind = "nq-m2-coverage-manifest", version = 1,
            note = "Coverage report, not an export. Contains no effective records.",
            provenance = clone(p), quests = {},
            aggregate = {
                kind = "nq-m2-coverage-aggregate", version = 1,
                total = 3, representable = 2, unsupported = 1,
                reconciled = true, reasonQuests = { REPUTATION_OBJECTIVE = 1 },
            },
        }
        for id = 1, 3 do
            local unsupported = id == 1
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
                ID = id, status = unsupported and "UNSUPPORTED" or "REPRESENTABLE",
                reasons = unsupported and { "REPUTATION_OBJECTIVE" } or {},
            }
        end
        return effective, manifest, {
            questCount = 3, supportedCount = 2, unsupportedCount = 1,
        }
    end

    local function sourceRow(id)
        local r = {
            ID = id, StartItem = 0, KillCredit = {},
            killCreditComplete = true, hasConditions = false,
            scriptedCredit = false, ipGated = false,
        }
        for i = 1, 4 do
            r["RequiredNpcOrGo" .. i] = 0
            r["RequiredNpcOrGoCount" .. i] = 0
            r["ItemDrop" .. i] = 0
        end
        for i = 1, 6 do
            r["RequiredItemId" .. i] = 0
            r["RequiredItemCount" .. i] = 0
        end
        return r
    end

    local function serverDoc(ids)
        local rows = {}
        for i, id in ipairs(ids) do rows[i] = sourceRow(id) end
        return {
            schema = "nq-m2-input", schemaVersion = 1,
            provenance = {
                exporter = "nquestie-private-objectives", exporterVersion = "3.0.0",
                sourceLabel = "synthetic-only",
                sourceFingerprint = "sha256:" .. string.rep("d", 64),
                exportedAt = "2026-10-15T18:00:00Z", selection = "explicit",
                questCount = #rows,
            },
            quests = rows,
        }
    end

    -- Only the TEST loader temporarily intercepts the module's dependency.
    -- The resulting Batch still exports exactly the historical Run signature.
    -- No production override, injected parameter or changed frozen file.
    local function loadWithM1Spy(compareOverride)
        local calls = 0
        local wrapper = {}
        for k, v in pairs(realM1) do wrapper[k] = v end
        wrapper.Compare = function(...)
            calls = calls + 1
            if compareOverride then return compareOverride(...) end
            return realM1.Compare(...)
        end
        local previous = _G.dofile
        _G.dofile = function(file)
            if file == "tools/validation/ObjectiveRules.lua" then
                return wrapper
            end
            return previous(file)
        end
        -- Even if the module load throws, restore global dofile NOW.
        local ok, mod = pcall(previous, "tools/validation/M23Batch.lua")
        _G.dofile = previous
        assert.is_true(ok, "test-only loading Part 2 failed")
        assert.is_table(mod)
        return mod, function() return calls end
    end

    it("restores original dofile immediately after spy module load", function()
        local previous = _G.dofile
        local batch = loadWithM1Spy()
        assert.are.equal(previous, _G.dofile)
        assert.is_function(batch.Run)
    end)

    it("counts once per supported selected quest and zero for unsupported", function()
        local effective, manifest, pins = data()
        local Batch, calls = loadWithM1Spy()
        local result, code = Batch.Run(serverDoc({ 1, 2, 3 }),
            effective, manifest, pins)
        assert.is_nil(code)
        assert.is_not_nil(result)
        assert.are.equal(2, calls())
        assert.are.equal(3, result.selected)
        assert.is_false(result.rows[1].m1Supported)
        assert.is_true(result.rows[2].m1Supported)
        assert.is_true(result.rows[3].m1Supported)
        assert.is_false(result.authenticated)
        assert.is_false(result.publishable)
        assert.are.equal(originalDofile, _G.dofile)

        local unsupportedOnly, calls2 = loadWithM1Spy()
        local selected, reject = unsupportedOnly.Run(serverDoc({ 1 }),
            effective, manifest, pins)
        assert.is_nil(reject)
        assert.is_not_nil(selected)
        assert.are.equal(0, calls2())
    end)

    it("rejects duplicate selected IDs without invoking M1", function()
        local effective, manifest, pins = data()
        local Batch, calls = loadWithM1Spy()
        local out, code = Batch.Run(serverDoc({ 2, 2 }),
            effective, manifest, pins)
        assert.is_nil(out)
        assert.are.equal("REJECTED_DUPLICATE_ID", code)
        assert.are.equal(0, calls())
    end)

    it("turns a synthetic M1 exception into fixed code without exception text", function()
        local effective, manifest, pins = data()
        local Batch, calls = loadWithM1Spy(function()
            error("SYNTHETIC_SECRET_SENTINEL_123", 0)
        end)
        local out, code = Batch.Run(serverDoc({ 2 }),
            effective, manifest, pins)
        assert.is_nil(out)
        assert.are.equal("REJECTED_MALFORMED_INPUT", code)
        assert.is_nil(code:find("SYNTHETIC_SECRET_SENTINEL", 1, true))
        assert.are.equal(1, calls())
    end)

    it("documents the deliberate future R-MALFORMED semantic difference", function()
        local effective, manifest, pins = data()
        local Batch, calls = loadWithM1Spy(function()
            return {
                {
                    questId = 2, kind = "availability",
                    class = "NEEDS_MANUAL_REVIEW", rules = { "R-MALFORMED" },
                    explanation = "SYNTHETIC_SECRET_SENTINEL_456",
                },
            }
        end)
        local out, code = Batch.Run(serverDoc({ 2 }),
            effective, manifest, pins)
        assert.is_nil(code)
        assert.is_not_nil(out)
        assert.are.equal(1, calls())
        assert.are.equal("NEEDS_MANUAL_REVIEW", out.rows[1].outcome)
        assert.are.same({ "NEEDS_MANUAL_REVIEW" }, out.rows[1].m1Classes)
        -- This confirms Part 2's present behavior, NOT the future
        -- Part 3 policy: a future worker must reject R-MALFORMED.
        assert.is_nil(out.rows[1].explanation)
        assert.is_false(out.publishable)
    end)
end)
