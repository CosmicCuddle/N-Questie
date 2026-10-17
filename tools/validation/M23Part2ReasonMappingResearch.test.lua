-- N-Questie M2.3 public/synthetic research only.
-- This probes EXISTING Part 2 and historical draft report/aggregate validators.
-- It does not create a private findings worker, trust an export or write files.
-- Lua 5.1-compatible Busted; no real server records.
describe("M2.3 Part 2 reasons and report-v1 mapping (synthetic only)", function()
    local Batch = dofile("tools/validation/M23Batch.lua")
    local Report = dofile("tools/validation/draft/M23ReportDraft.lua")
    local draft = { allowDraft = true }

    local function copy(value)
        if type(value) ~= "table" then return value end
        local out = {}
        for k, v in pairs(value) do out[k] = copy(v) end
        return out
    end

    local function fixtures()
        local prov = {
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
            displayScope = "structural-only", provenance = prov, quests = {},
        }
        local manifest = {
            kind = "nq-m2-coverage-manifest", version = 1,
            note = "Coverage report, not an export. Contains no effective records.",
            provenance = copy(prov), quests = {},
            aggregate = {
                kind = "nq-m2-coverage-aggregate", version = 1,
                total = 3, representable = 2, unsupported = 1,
                reconciled = true, reasonQuests = { REPUTATION_OBJECTIVE = 1 },
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
                ID = id, status = unsupported and "UNSUPPORTED" or "REPRESENTABLE",
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
                exportedAt = "2026-10-15T18:00:00Z", selection = "explicit",
                questCount = 3,
            },
            quests = {},
        }
        -- Deliberately out-of-order selection; full export and manifest stay sorted.
        for _, id in ipairs({ 3, 2, 1 }) do
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
        return server, effective, manifest, {
            questCount = 3, supportedCount = 2, unsupportedCount = 1,
        }
    end

    local function run()
        local server, effective, manifest, pins = fixtures()
        local result, code = Batch.Run(server, effective, manifest, pins)
        assert.is_nil(code)
        assert.is_table(result)
        return result
    end

    local function reportFromPart2(result)
        local rows = {}
        for _, row in ipairs(result.rows) do
            rows[#rows + 1] = {
                questId = row.questId, exportStatus = "EXPORTED",
                m1Supported = row.m1Supported,
                m1Classes = copy(row.m1Classes),
                representationDiff = row.representationDiff,
                evidence = copy(row.evidence), outcome = row.outcome,
                -- Deliberately OMIT reasons on *all* EXPORTED rows.
            }
        end
        table.sort(rows, function(a, b) return a.questId < b.questId end)
        return {
            schema = "nq-m2-3-report", schemaVersion = 1,
            private = true, selected = { 1, 2, 3 }, rows = rows,
        }
    end

    local function aggregate()
        return {
            schema = "nq-m2-3-aggregate", schemaVersion = 1,
            reasonVocabVersion = Report.REASON_VOCAB_VERSION,
            selectedCount = 3, exportStatus = { EXPORTED = 3 },
            outcome = { NEEDS_MANUAL_REVIEW = 2, M1_UNSUPPORTED_BY_RULES = 1 },
            reasons = {}, -- IMPORTANT: selected v2 unsupported reasons stay private
        }
    end

    -- Twelve PUBLIC aggregate reason combinations, recreated as invented
    -- v2 structures rather than copying a real/private Questie quest.
    local cohorts = {
        { n = 317, monster = true, reasons = { "EXTRA_CREATURE_REF" } },
        { n = 205, objectRef = true, reasons = { "EXTRA_OBJECT_REF" } },
        { n = 175, reputation = true, reasons = { "REPUTATION_OBJECTIVE" } },
        { n = 6, duplicateCreature = true, reasons = { "DUPLICATE_CREATURE" } },
        { n = 6, killCreditFirst = true, reasons = { "KILLCREDIT_FIRST_REORDER" } },
        { n = 31, monster = true, objectRef = true,
          reasons = { "EXTRA_CREATURE_REF", "EXTRA_OBJECT_REF" } },
        { n = 7, monster = true, killCreditFirst = true,
          reasons = { "EXTRA_CREATURE_REF", "KILLCREDIT_FIRST_REORDER" } },
        { n = 4, objectRef = true, reputation = true,
          reasons = { "EXTRA_OBJECT_REF", "REPUTATION_OBJECTIVE" } },
        { n = 3, objectRef = true, killCreditFirst = true,
          reasons = { "EXTRA_OBJECT_REF", "KILLCREDIT_FIRST_REORDER" } },
        { n = 2, monster = true, reputation = true,
          reasons = { "EXTRA_CREATURE_REF", "REPUTATION_OBJECTIVE" } },
        { n = 1, duplicateCreature = true, monster = true,
          reasons = { "DUPLICATE_CREATURE", "EXTRA_CREATURE_REF" } },
        { n = 1, duplicateObject = true, monster = true,
          reasons = { "DUPLICATE_OBJECT", "EXTRA_CREATURE_REF" } },
    }

    local function cohortQuest(id, shape)
        local q = {
            ID = id, requiredLevel = 1, questLevel = 3,
            sourceItemId = 0, requiredSourceItems = {},
            objectives = {}, killCreditFirst = false,
            hasTriggerEnd = false, extraObjectives = {},
        }
        local function add(kind, slot, fields)
            local o = { position = #q.objectives + 1,
                        kind = kind, slotIndex = slot }
            for k, v in pairs(fields) do o[k] = v end
            q.objectives[#q.objectives + 1] = o
        end
        if shape.killCreditFirst then
            q.killCreditFirst = true
            add("killCredit", 1, { ids = { 88001 }, rootId = 88001 })
            add("creature", 1, { id = 88002, occurrence = 1 })
        elseif shape.duplicateCreature then
            add("creature", 1, { id = 88003, occurrence = 1 })
            add("creature", 2, { id = 88003, occurrence = 2 })
        elseif shape.duplicateObject then
            add("object", 1, { id = 88004, occurrence = 1 })
            add("object", 2, { id = 88004, occurrence = 2 })
        elseif shape.reputation then
            add("reputation", 1, { factionId = 72, requiredValue = 0 })
        end
        local refs = {}
        if shape.monster then
            refs[#refs + 1] = {
                type = "monster", id = 88101, refIndex = #refs + 1 }
        end
        if shape.objectRef then
            refs[#refs + 1] = {
                type = "object", id = 88102, refIndex = #refs + 1 }
        end
        if #refs > 0 then
            q.extraObjectives[1] = {
                position = 1, icon = 1, hasText = true,
                objectiveIndex = 0, spawnZones = {}, refs = refs,
            }
        end
        -- Copy the exact independently asserted computed status/reason list.
        q.m1Status, q.m1Reasons = dofile(
            "tools/validation/EffectiveSchemaV2.lua").ExpectedM1(q)
        return q
    end

    local function cohortFixtures()
        local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
        local Membership = dofile("tools/validation/M23Membership.lua")
        local server, effective, manifest, pins = fixtures()
        local template = copy(server.quests[1])
        server.quests, effective.quests, manifest.quests = {}, {}, {}
        server.provenance.questCount = #cohorts
        effective.provenance.questCount = #cohorts
        manifest.provenance.questCount = #cohorts
        manifest.aggregate.total = #cohorts
        manifest.aggregate.representable = 0
        manifest.aggregate.unsupported = #cohorts
        manifest.aggregate.reasonQuests = {}
        pins.questCount, pins.supportedCount, pins.unsupportedCount = #cohorts, 0, #cohorts
        for i, shape in ipairs(cohorts) do
            local q = cohortQuest(i, shape)
            local status, calculated = V2.ExpectedM1(q)
            assert.are.equal("UNSUPPORTED_BY_RULES", status)
            assert.are.same(shape.reasons, calculated)
            assert.is_true(V2.ValidateQuest(q))
            effective.quests[i] = q
            manifest.quests[i] = {
                ID = i, status = "UNSUPPORTED", reasons = copy(calculated),
            }
            for _, code in ipairs(calculated) do
                manifest.aggregate.reasonQuests[code] =
                    (manifest.aggregate.reasonQuests[code] or 0) + 1
            end
            local row = copy(template)
            row.ID = i
            server.quests[i] = row
        end
        assert.is_true(V2.Validate(effective))
        local index, code = Membership.Check(effective, manifest, pins)
        assert.is_nil(code)
        assert.is_table(index)
        assert.are.equal(#cohorts, index.unsupported)
        return server, effective, manifest, pins
    end

    it("accepts all twelve synthetic unsupported reason combinations without an M1 call", function()
        local server, effective, manifest, pins = cohortFixtures()
        -- Test-loader interception is temporary and never modifies M23Batch.
        local original = _G.dofile
        local compareCalls = 0
        _G.dofile = function(path)
            local mod = original(path)
            if path ~= "tools/validation/ObjectiveRules.lua" then return mod end
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
        local serverBefore, effectiveBefore, manifestBefore, pinsBefore =
            copy(server), copy(effective), copy(manifest), copy(pins)
        local result, code = spied.Run(server, effective, manifest, pins)
        assert.are.same(serverBefore, server)
        assert.are.same(effectiveBefore, effective)
        assert.are.same(manifestBefore, manifest)
        assert.are.same(pinsBefore, pins)
        assert.is_nil(code)
        assert.is_table(result)
        assert.are.equal(12, result.unsupported)
        assert.are.equal(0, result.supported)
        assert.are.equal(0, compareCalls)
        -- Pin the cardinality: ipairs alone silently skips missing tail rows.
        assert.are.equal(#cohorts, #result.rows)
        for i, row in ipairs(result.rows) do
            assert.are.equal(i, row.questId)
            assert.is_false(row.m1Supported)
            assert.are.equal("M1_UNSUPPORTED_BY_RULES", row.outcome)
            assert.are.same(cohorts[i].reasons, row.reasons)
            assert.are.same({}, row.m1Classes)
            -- A pairs-only loop would pass vacuously if evidence were {}.
            -- Require every one of the five known axes, and no extra axes.
            local expectedEvidence = {}
            for _, axis in ipairs(Report.EVIDENCE) do
                assert.are.equal("unknown", row.evidence[axis])
                expectedEvidence[axis] = true
            end
            local observedCount = 0
            for axis in pairs(row.evidence) do
                assert.is_true(expectedEvidence[axis])
                observedCount = observedCount + 1
            end
            assert.are.equal(#Report.EVIDENCE, observedCount)
        end
        assert.is_false(result.authenticated)
        assert.is_false(result.publishable)
        -- Positive control: without this, a broken spy or misspelt import
        -- path would also "pass" a zero-call test. Existing 3-quest fixtures
        -- contain TWO supported selections and ONE unsupported selection.
        local cs, ce, cm, cp = fixtures()
        local control, controlCode = spied.Run(cs, ce, cm, cp)
        assert.is_nil(controlCode)
        assert.is_table(control)
        assert.are.equal(2, compareCalls)
        assert.are.equal(2, control.supported)
        assert.are.equal(1, control.unsupported)
    end)

    it("refuses six unsafe selection and provenance cases before M1 runs", function()
        -- Assert zero M1 calls only after a valid same-spy positive control;
        -- a misspelt loader interception must not vacuously pass.
        local original = _G.dofile
        local compareCalls = 0
        _G.dofile = function(path)
            local mod = original(path)
            if path ~= "tools/validation/ObjectiveRules.lua" then
                return mod
            end
            local spy = {}
            for key, value in pairs(mod) do spy[key] = value end
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

        local goodServer, goodEffective, goodManifest, goodPins = fixtures()
        local good, goodCode = spied.Run(
            goodServer, goodEffective, goodManifest, goodPins)
        assert.is_nil(goodCode)
        assert.is_table(good)
        assert.are.equal(2, compareCalls)
        assert.are.equal(2, good.supported)
        assert.are.equal(1, good.unsupported)

        local cases = {
            { name = "duplicate server ID", expected = "REJECTED_DUPLICATE_ID",
              change = function(server)
                  server.quests[1].ID = server.quests[2].ID
              end },
            { name = "out-of-range signed gameobject",
              expected = "REJECTED_MALFORMED_INPUT",
              change = function(server)
                  server.quests[1].RequiredNpcOrGo1 = -2147483648
                  server.quests[1].RequiredNpcOrGoCount1 = 1
              end },
            { name = "invalid effective v2 scalar",
              expected = "REJECTED_MALFORMED_INPUT",
              change = function(_, effective)
                  effective.quests[1].sourceItemId = -1
              end },
            { name = "unpaired manifest provenance",
              expected = "REJECTED_PAIRING",
              change = function(_, _, manifest)
                  manifest.provenance.sourceTree = string.rep("e", 40)
              end },
            { name = "inconsistent manifest aggregate",
              expected = "REJECTED_MANIFEST_INCOMPLETE",
              change = function(_, _, manifest)
                  manifest.aggregate.reasonQuests.REPUTATION_OBJECTIVE = 2
              end },
            { name = "absent first selected quest",
              expected = "REJECTED_SELECTION_MISMATCH",
              change = function(server)
                  server.quests[1].ID = 4
              end },
        }
        for _, case in ipairs(cases) do
            local server, effective, manifest, pins = fixtures()
            case.change(server, effective, manifest, pins)
            local ss, ee, mm, pp =
                copy(server), copy(effective), copy(manifest), copy(pins)
            compareCalls = 0
            local result, code = spied.Run(server, effective, manifest, pins)
            assert.is_nil(result, case.name)
            assert.are.equal(case.expected, code, case.name)
            assert.are.equal(0, compareCalls, case.name)
            assert.are.same(ss, server)
            assert.are.same(ee, effective)
            assert.are.same(mm, manifest)
            assert.are.same(pp, pins)
        end
        assert.are.equal(original, _G.dofile)
    end)

    it("distinguishes single killCredit from two reversed killCredit lines", function()
        -- A single flagged killCredit line stays in the same displayed
        -- position. The flag alone must NOT make the quest unsupported.
        local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
        local Membership = dofile("tools/validation/M23Membership.lua")
        local single = cohortQuest(5, { killCreditFirst = true })
        single.objectives = {
            { position = 1, kind = "killCredit", slotIndex = 1,
              ids = { 88201 }, rootId = 88201 },
        }
        single.m1Status, single.m1Reasons = V2.ExpectedM1(single)
        assert.is_true(V2.ValidateQuest(single))
        assert.are.equal("SUPPORTED", single.m1Status)
        assert.are.same({}, single.m1Reasons)

        -- Without the flag, two killCredit entries remain in ascending
        -- compiled slot order; v1 can represent that order.
        local ordered = copy(single)
        ordered.killCreditFirst = false
        ordered.objectives[2] = {
            position = 2, kind = "killCredit", slotIndex = 2,
            ids = { 88202 }, rootId = 88202,
        }
        ordered.m1Status, ordered.m1Reasons = V2.ExpectedM1(ordered)
        assert.is_true(V2.ValidateQuest(ordered))
        assert.are.equal("SUPPORTED", ordered.m1Status)
        assert.are.same({}, ordered.m1Reasons)

        -- When flagged, Questie inserts each killCredit at the front:
        -- the two display in slot order 2,1, even without a creature
        -- or item objective. v1 cannot reconstruct that order.
        local reversed = copy(ordered)
        reversed.killCreditFirst = true
        reversed.objectives = {
            { position = 1, kind = "killCredit", slotIndex = 2,
              ids = { 88202 }, rootId = 88202 },
            { position = 2, kind = "killCredit", slotIndex = 1,
              ids = { 88201 }, rootId = 88201 },
        }
        reversed.m1Status, reversed.m1Reasons = V2.ExpectedM1(reversed)
        assert.is_true(V2.ValidateQuest(reversed))
        assert.are.equal("UNSUPPORTED_BY_RULES", reversed.m1Status)
        assert.are.same({ "KILLCREDIT_FIRST_REORDER" }, reversed.m1Reasons)

        -- Substitute the invented reversed variant for cohort 5. It keeps
        -- the exact same public reason, manifest, pins and selected count.
        local server, effective, manifest, pins = cohortFixtures()
        effective.quests[5] = reversed
        assert.is_true(V2.Validate(effective))
        local index, membershipCode = Membership.Check(
            effective, manifest, pins)
        assert.is_nil(membershipCode)
        assert.is_table(index)
        local before = copy(effective)
        local out, code = Batch.Run(server, effective, manifest, pins)
        assert.is_nil(code)
        assert.is_table(out)
        assert.are.equal(12, out.unsupported)
        assert.are.equal("M1_UNSUPPORTED_BY_RULES", out.rows[5].outcome)
        assert.are.same({ "KILLCREDIT_FIRST_REORDER" },
            out.rows[5].reasons)
        assert.are.same(before, effective)
        assert.are.same({ 88202 }, effective.quests[5].objectives[1].ids)
        assert.are.same({ 88201 }, effective.quests[5].objectives[2].ids)
    end)

    it("keeps repeated extra creature/object refs and separate extra objectives", function()
        -- This is not a copied quest: multiple references may lead to the
        -- SAME two v1-unrepresentable reasons. Neither repeated references
        -- nor separate extras may inflate the unique unsupported quest count.
        local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
        local Membership = dofile("tools/validation/M23Membership.lua")
        local server, effective, manifest, pins = cohortFixtures()
        local q = effective.quests[6] -- creature-extra + object-extra cohort
        q.extraObjectives[1].refs = {
            { type = "monster", id = 88101, refIndex = 1 },
            { type = "object", id = 88102, refIndex = 2 },
            { type = "monster", id = 88103, refIndex = 3 },
            { type = "object", id = 88104, refIndex = 4 },
        }
        q.extraObjectives[2] = {
            position = 2, icon = 2, hasText = false,
            objectiveIndex = 0, spawnZones = { 1, 3 },
            refs = { { type = "monster", id = 88105, refIndex = 1 } },
        }
        local status, reasons = V2.ExpectedM1(q)
        assert.are.equal("UNSUPPORTED_BY_RULES", status)
        assert.are.same({
            "EXTRA_CREATURE_REF", "EXTRA_OBJECT_REF",
        }, reasons)
        assert.are.same(reasons, q.m1Reasons)
        assert.is_true(V2.ValidateQuest(q))
        assert.is_true(V2.Validate(effective))
        local index, membershipCode = Membership.Check(
            effective, manifest, pins)
        assert.is_nil(membershipCode)
        assert.is_table(index)
        assert.are.equal(12, index.unsupported)

        local original = copy(effective)
        local output, code = Batch.Run(server, effective, manifest, pins)
        assert.is_nil(code)
        assert.is_table(output)
        assert.are.equal(12, output.unsupported)
        assert.are.equal(12, #output.rows)
        assert.are.same(reasons, output.rows[6].reasons)
        assert.are.equal("M1_UNSUPPORTED_BY_RULES", output.rows[6].outcome)
        assert.are.same(original, effective)
        assert.are.equal(2, #effective.quests[6].extraObjectives)
        assert.are.same({
            { type = "monster", id = 88101, refIndex = 1 },
            { type = "object", id = 88102, refIndex = 2 },
            { type = "monster", id = 88103, refIndex = 3 },
            { type = "object", id = 88104, refIndex = 4 },
        }, effective.quests[6].extraObjectives[1].refs)
        assert.are.same({ 1, 3 },
            effective.quests[6].extraObjectives[2].spawnZones)
        assert.are.same({
            { type = "monster", id = 88105, refIndex = 1 },
        }, effective.quests[6].extraObjectives[2].refs)
    end)

    it("rejects malformed extra-objective references and indices before M1", function()
        -- The frozen v2 schema must refuse corrupt fields, rather than
        -- silently losing one member of a multiple-objective quest.
        local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
        local Membership = dofile("tools/validation/M23Membership.lua")
        local cases = {
            { name = "wrong reference index", edit = function(q)
                q.extraObjectives[1].refs[2].refIndex = 1
            end },
            { name = "repeated extra position", edit = function(q)
                q.extraObjectives[2].position = 1
            end },
            { name = "invalid objective link", edit = function(q)
                q.extraObjectives[2].objectiveIndex = 3
            end },
            { name = "fractional zone", edit = function(q)
                q.extraObjectives[2].spawnZones[1] = 1.5
            end },
            { name = "unknown ref type", edit = function(q)
                q.extraObjectives[1].refs[2].type = "npc"
            end },
        }
        for _, case in ipairs(cases) do
            local server, effective, manifest, pins = cohortFixtures()
            local q = effective.quests[6]
            q.extraObjectives[2] = {
                position = 2, icon = 1, hasText = true,
                objectiveIndex = 0, spawnZones = { 1, 3 },
                refs = { { type = "monster", id = 88106, refIndex = 1 } },
            }
            assert.is_true(V2.ValidateQuest(q), case.name)
            case.edit(q)
            assert.is_false(V2.ValidateQuest(q), case.name)
            -- Even with a matching invented coverage manifest and pins,
            -- malformed effective v2 input must not enter Part 2/M1.
            local ss, ee, mm, pp =
                copy(server), copy(effective), copy(manifest), copy(pins)
            local index, membershipCode = Membership.Check(
                effective, manifest, pins)
            assert.is_nil(index)
            assert.are.equal("REJECTED_MALFORMED_INPUT", membershipCode)
            local result, batchCode = Batch.Run(
                server, effective, manifest, pins)
            assert.is_nil(result)
            assert.are.equal("REJECTED_MALFORMED_INPUT", batchCode)
            assert.are.same(ss, server)
            assert.are.same(ee, effective)
            assert.are.same(mm, manifest)
            assert.are.same(pp, pins)
        end
    end)

    it("keeps all twelve v2-only reasons out of report-v1 EXPORTED rows", function()
        -- This is a synthetic-only projection of existing Part 2 rows, NOT
        -- the unimplemented G3 private findings worker or its bundle codec.
        local server, effective, manifest, pins = cohortFixtures()
        local source, code = Batch.Run(server, effective, manifest, pins)
        assert.is_nil(code)
        assert.are.equal(12, #source.rows)
        local rows, selected = {}, {}
        for i, part2 in ipairs(source.rows) do
            assert.are.same(cohorts[i].reasons, part2.reasons)
            selected[i] = part2.questId
            rows[i] = {
                questId = part2.questId,
                exportStatus = "EXPORTED",
                m1Supported = part2.m1Supported,
                m1Classes = copy(part2.m1Classes),
                representationDiff = part2.representationDiff,
                evidence = copy(part2.evidence),
                outcome = part2.outcome,
                -- NO reasons key: v2-only unsupported reasons belong only
                -- to future separately approved PRIVATE G3 findings data.
            }
        end
        local report = {
            schema = "nq-m2-3-report", schemaVersion = 1,
            private = true, selected = selected, rows = rows,
        }
        local valid, errors = Report.ValidateReport(report, draft)
        assert.is_true(valid, table.concat(errors or {}, "; "))
        local aggregate12 = {
            schema = "nq-m2-3-aggregate", schemaVersion = 1,
            reasonVocabVersion = Report.REASON_VOCAB_VERSION,
            selectedCount = 12, exportStatus = { EXPORTED = 12 },
            outcome = { M1_UNSUPPORTED_BY_RULES = 12 },
            reasons = {},
        }
        assert.is_true(Report.ValidateAggregate(aggregate12, report, draft))
        -- Every supported-v2-format but M1-unsupported shape must refuse
        -- an accidental report-v1 reasons field, even for a valid code list.
        for i = 1, #rows do
            rows[i].reasons = copy(source.rows[i].reasons)
            assert.is_false(Report.ValidateReport(report, draft))
            rows[i].reasons = nil
        end
        assert.is_true(Report.ValidateReport(report, draft))
        -- Nor may counts-only aggregate-v1 absorb those private reasons.
        aggregate12.reasons = { EXTRA_CREATURE_REF = 1 }
        assert.is_false(Report.ValidateAggregate(aggregate12, report, draft))
    end)

    it("refuses a mismatched public reason list and count rather than dropping an overlap", function()
        local server, effective, manifest, pins = cohortFixtures()
        -- Change one two-reason manifest list but keep it structurally valid.
        manifest.quests[6].reasons = { "EXTRA_CREATURE_REF" }
        local result, code = Batch.Run(server, effective, manifest, pins)
        assert.is_nil(result)
        assert.are.equal("REJECTED_M1_STATUS_MISMATCH", code)
        -- Restore the reason list but falsify just the aggregate.
        manifest.quests[6].reasons = copy(cohorts[6].reasons)
        manifest.aggregate.reasonQuests.EXTRA_OBJECT_REF =
            manifest.aggregate.reasonQuests.EXTRA_OBJECT_REF - 1
        result, code = Batch.Run(server, effective, manifest, pins)
        assert.is_nil(result)
        assert.are.equal("REJECTED_MANIFEST_INCOMPLETE", code)
    end)

    it("rejects reordered, duplicated or injected overlap reasons without mutation", function()
        -- Quest 6 deliberately has two supported, known reason codes.
        -- An out-of-order or duplicate list violates the CLOSED sorted set;
        -- an extra valid sorted reason is well-typed but disagrees with v2.
        local cases = {
            { reasons = { "EXTRA_OBJECT_REF", "EXTRA_CREATURE_REF" },
              code = "REJECTED_MALFORMED_INPUT" },
            { reasons = { "EXTRA_CREATURE_REF", "EXTRA_CREATURE_REF" },
              code = "REJECTED_MALFORMED_INPUT" },
            { reasons = { "EXTRA_CREATURE_REF", "EXTRA_OBJECT_REF",
                          "REPUTATION_OBJECTIVE" },
              code = "REJECTED_M1_STATUS_MISMATCH" },
        }
        for _, case in ipairs(cases) do
            local server, effective, manifest, pins = cohortFixtures()
            manifest.quests[6].reasons = copy(case.reasons)
            local ss, ee, mm, pp =
                copy(server), copy(effective), copy(manifest), copy(pins)
            local result, code = Batch.Run(server, effective, manifest, pins)
            assert.is_nil(result)
            assert.are.equal(case.code, code)
            assert.are.same(ss, server)
            assert.are.same(ee, effective)
            assert.are.same(mm, manifest)
            assert.are.same(pp, pins)
        end
    end)

    it("reconciles all public coverage buckets in a fabricated aggregate", function()
        local Coverage = dofile("tools/validation/Coverage.lua")
        local results = {}
        for id = 1, 8401 do
            results[#results + 1] = {
                id = id, status = "REPRESENTABLE", codes = {}, counts = {},
            }
        end
        -- Fabricated occurrence multiplicity using PUBLIC AGGREGATE ONLY:
        -- 466 creature occurrences vs 359 quests; 335 object vs 243;
        -- 9 duplicate-creature occurrences vs 7 quests. The assignment
        -- to invented rows is arbitrary and does NOT model real quest IDs.
        local extraOccurrences = {
            EXTRA_CREATURE_REF = 107,
            EXTRA_OBJECT_REF = 92,
            DUPLICATE_CREATURE = 2,
        }
        for _, shape in ipairs(cohorts) do
            for _ = 1, shape.n do
                local counts = {}
                for _, code in ipairs(shape.reasons) do
                    local count = 1
                    if (extraOccurrences[code] or 0) > 0 then
                        count = 2
                        extraOccurrences[code] = extraOccurrences[code] - 1
                    end
                    counts[code] = count
                end
                results[#results + 1] = {
                    id = #results + 1, status = "UNSUPPORTED",
                    codes = copy(shape.reasons), counts = counts,
                }
            end
        end
        assert.are.same({
            EXTRA_CREATURE_REF = 0, EXTRA_OBJECT_REF = 0,
            DUPLICATE_CREATURE = 0,
        }, extraOccurrences)
        local summary = Coverage.Aggregate(results)
        assert.are.equal(9159, summary.total)
        assert.are.equal(8401, summary.representable)
        assert.are.equal(758, summary.unsupported)
        assert.are.equal(0, summary.unclassified)
        assert.are.equal(12, #summary.combinations)
        -- Independently pin every PUBLIC disjoint bucket. Reconciled grand
        -- totals and per-reason marginals alone can conceal a bad allocation.
        local exactCombinations = {
            EXTRA_CREATURE_REF = 317,
            EXTRA_OBJECT_REF = 205,
            REPUTATION_OBJECTIVE = 175,
            DUPLICATE_CREATURE = 6,
            KILLCREDIT_FIRST_REORDER = 6,
            ["EXTRA_CREATURE_REF+EXTRA_OBJECT_REF"] = 31,
            ["EXTRA_CREATURE_REF+KILLCREDIT_FIRST_REORDER"] = 7,
            ["EXTRA_OBJECT_REF+REPUTATION_OBJECTIVE"] = 4,
            ["EXTRA_OBJECT_REF+KILLCREDIT_FIRST_REORDER"] = 3,
            ["EXTRA_CREATURE_REF+REPUTATION_OBJECTIVE"] = 2,
            ["DUPLICATE_CREATURE+EXTRA_CREATURE_REF"] = 1,
            ["DUPLICATE_OBJECT+EXTRA_CREATURE_REF"] = 1,
        }
        local observedCombinations = {}
        for _, bucket in ipairs(summary.combinations) do
            observedCombinations[bucket.codes] = bucket.quests
        end
        assert.are.same(exactCombinations, observedCombinations)
        assert.are.same({
            extra_creature = 359, extra_object = 243,
            reputation = 181, order = 16,
            duplicate_creature = 7, duplicate_object = 1,
        }, summary.categoryQuests)
        assert.are.same({
            EXTRA_CREATURE_REF = 359, EXTRA_OBJECT_REF = 243,
            REPUTATION_OBJECTIVE = 181, KILLCREDIT_FIRST_REORDER = 16,
            DUPLICATE_CREATURE = 7, DUPLICATE_OBJECT = 1,
        }, summary.reasonQuests)
        -- Quests and objective occurrences must remain DIFFERENT measures.
        assert.are.same({
            EXTRA_CREATURE_REF = 466, EXTRA_OBJECT_REF = 335,
            REPUTATION_OBJECTIVE = 181, KILLCREDIT_FIRST_REORDER = 16,
            DUPLICATE_CREATURE = 9, DUPLICATE_OBJECT = 1,
        }, summary.reasonOccurrences)
        local single, multiple = 0, 0
        for _, c in ipairs(summary.combinations) do
            if c.codes:find("+", 1, true) then
                multiple = multiple + c.quests
            else
                single = single + c.quests
            end
        end
        assert.are.equal(709, single)
        assert.are.equal(49, multiple)
        -- Subtle mutation: swap one (creature+object) and one reputation-only
        -- record into (creature+reputation) and object-only. This preserves
        -- ALL six reason totals, 9,159/8,401/758, and even 709/49, but
        -- changes four exact disjoint cohort counts.
        local creatureAndObject, reputationOnly
        for _, row in ipairs(results) do
            if not creatureAndObject
                and #row.codes == 2
                and row.codes[1] == "EXTRA_CREATURE_REF"
                and row.codes[2] == "EXTRA_OBJECT_REF" then
                creatureAndObject = row
            end
            if not reputationOnly and #row.codes == 1
                and row.codes[1] == "REPUTATION_OBJECTIVE" then
                reputationOnly = row
            end
            if creatureAndObject and reputationOnly then break end
        end
        assert.is_table(creatureAndObject)
        assert.is_table(reputationOnly)
        local originalA, originalB =
            copy(creatureAndObject), copy(reputationOnly)
        creatureAndObject.codes = {
            "EXTRA_CREATURE_REF", "REPUTATION_OBJECTIVE" }
        creatureAndObject.counts = {
            EXTRA_CREATURE_REF = 1, REPUTATION_OBJECTIVE = 1 }
        reputationOnly.codes = { "EXTRA_OBJECT_REF" }
        reputationOnly.counts = { EXTRA_OBJECT_REF = 1 }
        local redistributed = Coverage.Aggregate(results)
        assert.are.equal(summary.total, redistributed.total)
        assert.are.equal(summary.representable, redistributed.representable)
        assert.are.equal(summary.unsupported, redistributed.unsupported)
        assert.are.same(summary.reasonQuests, redistributed.reasonQuests)
        assert.are.same(summary.reasonOccurrences, redistributed.reasonOccurrences)
        assert.are.same(summary.categoryQuests, redistributed.categoryQuests)
        local changedBuckets = {}
        for _, bucket in ipairs(redistributed.combinations) do
            changedBuckets[bucket.codes] = bucket.quests
        end
        assert.are.equal(30,
            changedBuckets["EXTRA_CREATURE_REF+EXTRA_OBJECT_REF"])
        assert.are.equal(3,
            changedBuckets["EXTRA_CREATURE_REF+REPUTATION_OBJECTIVE"])
        assert.are.equal(206, changedBuckets.EXTRA_OBJECT_REF)
        assert.are.equal(174, changedBuckets.REPUTATION_OBJECTIVE)
        -- Restore before the independent one-reason-drop mutation below.
        creatureAndObject.codes = originalA.codes
        creatureAndObject.counts = originalA.counts
        reputationOnly.codes = originalB.codes
        reputationOnly.counts = originalB.counts
        -- Mutation: losing one overlapping reason must change a reason total.
        results[#results].codes = { "EXTRA_CREATURE_REF" }
        results[#results].counts = { EXTRA_CREATURE_REF = 1 }
        local changed = Coverage.Aggregate(results)
        assert.is_false(changed.reasonQuests.DUPLICATE_OBJECT == 1)
    end)

    it("Part 2 preserves server selection order and public unsupported reasons", function()
        local out = run()
        assert.are.same({ 3, 2, 1 }, {
            out.rows[1].questId, out.rows[2].questId, out.rows[3].questId,
        })
        assert.are.equal("1\n2\n3\n", out.allQuestIdsCanonicalBytes)
        assert.are.same({}, out.rows[1].reasons)
        assert.are.same({ "REPUTATION_OBJECTIVE" }, out.rows[2].reasons)
        assert.are.same({}, out.rows[3].reasons)
        assert.are.equal("M1_UNSUPPORTED_BY_RULES", out.rows[2].outcome)
        assert.are.same({}, out.rows[2].m1Classes)
        assert.is_false(out.rows[2].m1Supported)
        assert.is_false(out.authenticated)
        assert.is_false(out.publishable)
    end)

    it("normalized v2-only report-v1 EXPORTED rows omit all reasons", function()
        local report = reportFromPart2(run())
        local ok, errors = Report.ValidateReport(report, draft)
        assert.is_true(ok, table.concat(errors or {}, "; "))
        assert.are.same({ 1, 2, 3 }, {
            report.rows[1].questId, report.rows[2].questId, report.rows[3].questId,
        })
        assert.is_nil(report.rows[2].reasons)
        assert.are.equal("M1_UNSUPPORTED_BY_RULES", report.rows[2].outcome)
        assert.is_false(report.rows[2].m1Supported)
        for _, row in ipairs(report.rows) do
            assert.is_nil(row.reasons)
            for _, key in ipairs(Report.EVIDENCE) do
                assert.are.equal("unknown", row.evidence[key])
            end
        end
    end)

    it("frozen report-v1 rejects copying Part 2 reasons onto EXPORTED rows", function()
        local report = reportFromPart2(run())
        report.rows[2].reasons = { "REPUTATION_OBJECTIVE" }
        local ok = Report.ValidateReport(report, draft)
        assert.is_false(ok)
        report.rows[2].reasons = nil
        report.rows[1].reasons = {} -- even empty reasons is a forbidden field
        assert.is_false(Report.ValidateReport(report, draft))
    end)

    it("aggregate-v1 reason occurrences are zero for v2-only selected quests", function()
        local report = reportFromPart2(run())
        local agg = aggregate()
        local ok, errors = Report.ValidateAggregate(agg, report, draft)
        assert.is_true(ok, table.concat(errors or {}, "; "))
        agg.reasons.REPUTATION_OBJECTIVE = 1
        assert.is_false(Report.ValidateAggregate(agg, report, draft))
        -- Aggregates reconcile against report-v1, not hidden private reasons.
    end)

    it("historical schema-unsupported report status still requires public reasons", function()
        -- Contrast only: this is NOT the v2-only successful selection path.
        local report = {
            schema = "nq-m2-3-report", schemaVersion = 1, private = true,
            selected = { 2 }, rows = {
                { questId = 2, exportStatus = "UNSUPPORTED_BY_SCHEMA_VERSION",
                  reasons = { "REPUTATION_OBJECTIVE" } },
            },
        }
        assert.is_true(Report.ValidateReport(report, draft))
        local agg = {
            schema = "nq-m2-3-aggregate", schemaVersion = 1,
            reasonVocabVersion = Report.REASON_VOCAB_VERSION,
            selectedCount = 1, exportStatus = { UNSUPPORTED_BY_SCHEMA_VERSION = 1 },
            outcome = {}, reasons = { REPUTATION_OBJECTIVE = 1 },
        }
        assert.is_true(Report.ValidateAggregate(agg, report, draft))
    end)

    it("existing Part 2 neither mutates its synthetic inputs nor self-authenticates", function()
        local server, effective, manifest, pins = fixtures()
        local a, b, c, d = copy(server), copy(effective), copy(manifest), copy(pins)
        local out, code = Batch.Run(server, effective, manifest, pins)
        assert.is_nil(code)
        assert.is_table(out)
        assert.are.same(a, server)
        assert.are.same(b, effective)
        assert.are.same(c, manifest)
        assert.are.same(d, pins)
        assert.is_false(out.authenticated)
        assert.is_false(out.publishable)
    end)

    it("contrasts approved M1 mismatch code with old nine-code draft stderr", function()
        local server, effective, manifest, pins = fixtures()
        -- Make the coverage manifest internally consistent for all-supported
        -- claims, but deliberately disagree with effective v2 on quest 2.
        manifest.quests[2].status = "REPRESENTABLE"
        manifest.quests[2].reasons = {}
        manifest.aggregate.representable = 3
        manifest.aggregate.unsupported = 0
        manifest.aggregate.reasonQuests = {}
        pins.supportedCount = 3
        pins.unsupportedCount = 0

        local result, code = Batch.Run(server, effective, manifest, pins)
        assert.is_nil(result)
        assert.are.equal("REJECTED_M1_STATUS_MISMATCH", code)
        -- The maintainer-approved Part 3 CLI 14-code set INCLUDES this code.
        -- Only the historical nine-code M23ReportDraft.REJECTION omits it.
        assert.is_nil(Report.REJECTION[code])
        local formatOk = pcall(Report.StderrLine, code)
        assert.is_false(formatOk)
        local stderrOk, reasons = Report.CheckStderr(
            "nq-m2-3: " .. code .. "\n", draft)
        assert.is_false(stderrOk)
        assert.is_table(reasons)
        assert.is_true(table.concat(reasons, "; "):find(
            "stderr: line is not a fixed rejection code line", 1, true) ~= nil)
        -- The historical digit rule also refuses the M1 in the code, even
        -- if one naively added it to that OLD nine-code table.
        assert.is_true(table.concat(reasons, "; "):find(
            "stderr: digits outside the code set", 1, true) ~= nil)
        -- A future CLI must implement the ALREADY APPROVED 14-code checker
        -- separately; it must not re-use/extend the historical draft helper.
    end)

    it("confirms two old-draft codes were already in its nine-code set", function()
        for _, code in ipairs({ "REJECTED_MEMBERSHIP",
                "REJECTED_MALFORMED_INPUT" }) do
            assert.is_true(Report.REJECTION[code])
            local line = Report.StderrLine(code)
            assert.are.equal("nq-m2-3: " .. code, line)
            local ok = Report.CheckStderr(line .. "\n", draft)
            assert.is_true(ok)
        end
        -- This is historical compatibility research. Neither code is a
        -- substitute for the approved REJECTED_M1_STATUS_MISMATCH CLI code.
    end)
end)
