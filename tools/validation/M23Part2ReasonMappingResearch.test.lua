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
