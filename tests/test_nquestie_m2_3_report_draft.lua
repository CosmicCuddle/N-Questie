-- DRAFT tests for the proposed M2.3 contracts: selection protocol (executed),
-- report, aggregate, bundle and stderr-code formats. No engine, no server
-- data, no file output. Lua 5.1.
local R = dofile("tools/validation/draft/M23ReportDraft.lua")
local D = dofile("tools/validation/draft/EffectiveSchemaV2Draft.lua")
local OPT = { allowDraft = true }
local n, fails = 0, 0
local function ok(c, m) n = n + 1; if not c then fails = fails + 1; print("FAIL: " .. m) end end
local function copy(t) if type(t) ~= "table" then return t end local o = {} for k, v in pairs(t) do o[k] = copy(v) end return o end
local function has(errs, s) for _, e in ipairs(errs or {}) do if e:find(s, 1, true) then return true end end return false end
local base = dofile("tests/fixtures/m2_3_draft/report_synthetic.lua")
local function row(d, id) for _, r in ipairs(d.rows) do if r.questId == id then return r end end end
local function mut(f) local d = copy(base); f(d); return R.ValidateReport(d, OPT) end

ok(not pcall(R.ValidateReport, base), "draft guard")
local r, e = R.ValidateReport(base, OPT)
ok(r, "synthetic report valid: " .. table.concat(e or {}, "; "))
local st = {} for _, x in ipairs(base.rows) do st[x.exportStatus] = true; if x.outcome then st[x.outcome] = true end end
for k in pairs(R.EXPORT_STATUS) do ok(st[k], "fixture uses status " .. k) end
for k in pairs(R.OUTCOME) do ok(st[k], "fixture uses outcome " .. k) end

-- Vocabulary equals the exporter's reason codes
local E = dofile("tools/validation/EffectiveExport.lua")
local a, b = 0, 0
for k in pairs(E.REASONS) do a = a + 1; ok(R.REASON_CODES[k], "vocabulary has " .. k) end
for _ in pairs(R.REASON_CODES) do b = b + 1 end
ok(a == b, "vocabulary equals EffectiveExport.REASONS exactly")

-- Report rules
r, e = mut(function(d) table.remove(d.rows, 7) end)
ok(not r and has(e, "silent disappearance"), "missing selected quest rejected")
r, e = mut(function(d) d.rows[#d.rows + 1] = copy(d.rows[1]) end)
ok(not r and has(e, "appears twice"), "quest twice rejected")
r, e = mut(function(d) d.selected[#d.selected + 1] = 1203 end)
ok(not r and has(e, "duplicate ID"), "duplicate selected ID rejected")
r, e = mut(function(d) d.selected[#d.selected + 1] = -4 end)
ok(not r and has(e, "positive integer"), "non-positive selected ID rejected")
r = mut(function(d) d.selected[#d.selected + 1] = 1.5 end)
ok(not r, "non-integer selected ID rejected")
r, e = mut(function(d) d.selected[20] = 4242 end)
ok(not r and has(e, "sparse"), "sparse selected list rejected")
r, e = mut(function(d) row(d, 10503).outcome = "CONFIRMED_MATCH" end)
ok(not r and has(e, "only EXPORTED"), "outcome on non-exported quest rejected")
r, e = mut(function(d) row(d, 1203).outcome = nil end)
ok(not r and has(e, "exactly one known outcome"), "exported quest without outcome rejected")
r = mut(function(d) row(d, 498).outcome = "CONFIRMED_MATCH" end)
ok(not r, "unknown KillCredit never confirms a match")
for _, k in ipairs({ "conditions", "scripts", "ip", "objectiveData" }) do
    r = mut(function(d) row(d, 2001).evidence = copy(row(d, 2001).evidence); row(d, 2001).evidence[k] = "unknown" end)
    ok(not r, "unknown " .. k .. " never confirms a match")
end
r = mut(function(d) row(d, 2001).evidence = nil end)
ok(not r, "missing evidence never confirms (empty is not positive evidence)")
r = mut(function(d) row(d, 1203).outcome = "CONFIRMED_MATCH" end)
ok(not r, "findings present: no CONFIRMED_MATCH (1203)")
r = mut(function(d) row(d, 25199).outcome = "CONFIRMED_MATCH"; row(d, 25199).m1Classes = {} end)
ok(not r, "M1-unsupported never confirms")
r, e = mut(function(d) row(d, 900007).m1Classes = {} end)
ok(not r and has(e, "not supported by the M1 findings"), "CONFIRMED_MISMATCH with zero findings rejected")
r = mut(function(d) row(d, 900007).m1Classes = { "EXPECTED_REPRESENTATION_DIFF" } end)
ok(not r, "CONFIRMED_MISMATCH without a CONFIRMED_MISMATCH-class finding rejected")
r = mut(function(d) row(d, 900007).m1Classes = { "CONFIRMED_MISMATCH", "NEEDS_MANUAL_REVIEW" } end)
ok(not r, "CONFIRMED_MISMATCH alongside a review finding rejected")
r = mut(function(d) row(d, 900007).evidence = { killCredit = "unknown" } end)
ok(not r, "CONFIRMED_MISMATCH needs complete evidence")
r = mut(function(d) row(d, 900007).outcome = "NEEDS_MANUAL_REVIEW" end)
ok(r, "NEEDS_MANUAL_REVIEW always permitted for an M1-supported exported quest")
r = mut(function(d) row(d, 1203).m1Classes = {} end)
ok(not r, "EXPECTED_REPRESENTATION_DIFF needs findings")
r = mut(function(d) row(d, 1203).m1Classes = { "BOGUS" } end)
ok(not r, "unknown M1 class rejected")
r, e = mut(function(d) row(d, 11142).reasons = {} end)
ok(not r and has(e, "reason codes"), "unsupported quest without reasons rejected")
r, e = mut(function(d) row(d, 11142).reasons = { "quest-11142-private-label" } end)
ok(not r and has(e, "unknown reason code"), "private label as reason rejected in report")
r, e = mut(function(d) row(d, 1203).exportStatus = "REJECTED_MALFORMED_INPUT"; row(d, 1203).outcome = nil end)
ok(not r and has(e, "batch rejection code"), "REJECTED_MALFORMED_INPUT never appears in a report")
r = mut(function(d) row(d, 1203).exportStatus = "SKIPPED" end)
ok(not r, "unknown export status rejected")
r = mut(function(d) d.private = nil end)
ok(not r, "report must be marked private")

-- 1A: explicit m1Supported == true for any CONFIRMED outcome
for _, v in ipairs({ { nil, "nil" }, { false, "false" }, { "unknown", "'unknown'" }, { "true", "'true'" }, { 1, "1" }, { {}, "table" } }) do
    local rm = mut(function(d) row(d, 2001).m1Supported = v[1] end)
    ok(not rm, "1A CONFIRMED_MATCH rejected with m1Supported = " .. v[2])
    local rx = mut(function(d) row(d, 900007).m1Supported = v[1] end)
    ok(not rx, "1A CONFIRMED_MISMATCH rejected with m1Supported = " .. v[2])
    ok(not R.OutcomeAllowed({ m1Supported = v[1], m1Classes = {}, outcome = "CONFIRMED_MATCH",
        evidence = { killCredit = "complete", conditions = "complete", scripts = "complete", ip = "complete", objectiveData = "complete" } }),
        "1A OutcomeAllowed: no CONFIRMED_MATCH with m1Supported = " .. v[2])
end
r, e = mut(function(d) row(d, 498).m1Supported = nil end)
ok(not r and has(e, "explicit true or false"), "1A EXPORTED row without m1Supported rejected even for NEEDS_MANUAL_REVIEW")
r = mut(function(d) row(d, 25199).m1Classes = { "CONFIRMED_MISMATCH" } end)
ok(not r, "1A M1-unsupported row may not carry M1 findings")
r = mut(function(d) row(d, 25199).m1Supported = "unknown" end)
ok(not r, "1A M1_UNSUPPORTED_BY_RULES needs explicit false")

-- 1D: no rejection file; fixed codes on stderr only
ok(R.ValidateDiagnostic == nil, "1D no rejection-file format exists")
for code in pairs(R.REJECTION) do
    ok(R.CheckStderr(R.StderrLine(code) .. "\n", OPT), "1D fixed line accepted: " .. code)
end
ok(R.CheckStderr(R.StderrLine("REJECTED_PAIRING") .. "\n" .. R.StderrLine("REJECTED_MEMBERSHIP") .. "\n", OPT), "1D several fixed lines accepted")
ok(not pcall(R.StderrLine, "quest 1203 missing"), "1D StderrLine refuses free text")
local bads = {
    { "nq-m2-3: REJECTED_SELECTION_MISMATCH quest 1203\n", "quest ID digits" },
    { "nq-m2-3: REJECTED_UNSAFE_OUTPUT\n/home/user/private/out.lua\n", "path" },
    { "nq-m2-3: REJECTED_PAIRING sha256:" .. string.rep("ab", 32) .. "\n", "fingerprint" },
    { "nq-m2-3: REJECTED_PAIRING deadbeef\n", "hex run" },
    { "nq-m2-3: SOMETHING_ELSE\n", "unknown code" },
    { "REJECTED_PAIRING\n", "missing prefix" },
    { "nq-m2-3: REJECTED_PAIRING\nsourceLabel=prod-realm\n", "extra line" },
    { "", "empty" },
}
for _, bd in ipairs(bads) do ok(not R.CheckStderr(bd[1], OPT), "1D stderr rejected: " .. bd[2]) end

-- 1B: one atomic bundle, published by a single no-clobber install
local agg0 = { schema = "nq-m2-3-aggregate", schemaVersion = 1, reasonVocabVersion = 1, selectedCount = 8,
    exportStatus = { EXPORTED = 5, UNSUPPORTED_BY_SCHEMA_VERSION = 2, ABSENT_FROM_EFFECTIVE_DB = 1 },
    outcome = { EXPECTED_REPRESENTATION_DIFF = 1, CONFIRMED_MATCH = 1, NEEDS_MANUAL_REVIEW = 1, M1_UNSUPPORTED_BY_RULES = 1, CONFIRMED_MISMATCH = 1 },
    reasons = { KILLCREDIT_FIRST_REORDER = 1, DUPLICATE_OBJECT = 1, EXTRA_CREATURE_REF = 1 } }
local bundle = R.BuildBundle(base, agg0, OPT)
ok(bundle and bundle.report and bundle.aggregate, "1B bundle built from a validated pair")
local badAgg = copy(agg0); badAgg.outcome.CONFIRMED_MATCH = 2
ok(R.BuildBundle(base, badAgg, OPT) == nil, "1B no bundle when the aggregate does not reconcile")
local badRep = copy(base); row(badRep, 2001).m1Supported = nil
ok(R.BuildBundle(badRep, agg0, OPT) == nil, "1B no bundle when the report is invalid")
local function fakeFs(failAt)
    local st = { files = {}, temps = {} }
    local fs = {}
    function fs.exists(p) return st.files[p] ~= nil end
    function fs.writeTemp(c)
        if failAt == "writeTemp" then return nil end
        if failAt == "partialTemp" then st.temps.t1 = c:sub(1, 10); return nil end
        st.temps.t1 = c; return "t1"
    end
    function fs.fsync() return failAt ~= "fsync" end
    function fs.link(t, p)
        if failAt == "link" or failAt == "crashBeforeLink" then return false end
        if st.files[p] then return false end
        st.files[p] = st.temps[t]; return true
    end
    function fs.unlink(t) if failAt ~= "unlink" then st.temps[t] = nil end return true end
    return fs, st
end
local function ser(b) return "BUNDLE:" .. b.schema .. ":" .. #b.report.rows end
for _, fp in ipairs({ "writeTemp", "partialTemp", "fsync", "link", "crashBeforeLink" }) do
    local fs, fst = fakeFs(fp)
    local okp, code = R.PublishBundle(bundle, "out.lua", fs, ser, OPT)
    ok(not okp and code == "REJECTED_UNSAFE_OUTPUT" and fst.files["out.lua"] == nil, "1B failure at " .. fp .. ": no published file")
end
do
    local fs, fst = fakeFs(nil)
    ok(R.PublishBundle(bundle, "out.lua", fs, ser, OPT) and fst.files["out.lua"] == ser(bundle) and next(fst.temps) == nil, "1B success: one complete file, temp removed")
    ok(not R.PublishBundle(bundle, "out.lua", fs, ser, OPT) and fst.files["out.lua"] == ser(bundle), "1B no-clobber: existing bundle untouched")
end
do
    local fs, fst = fakeFs("unlink")
    ok(R.PublishBundle(bundle, "out.lua", fs, ser, OPT) and fst.files["out.lua"] == ser(bundle) and fst.temps.t1 ~= nil,
       "1B crash after link: final complete, stray temp left for documented cleanup")
end
ok(not R.PublishBundle({ schema = "x" }, "o2.lua", fakeFs(nil), ser, OPT), "1B only a validated bundle can be published")

-- Aggregate
local agg = { schema = "nq-m2-3-aggregate", schemaVersion = 1, reasonVocabVersion = 1, selectedCount = 8,
    exportStatus = { EXPORTED = 5, UNSUPPORTED_BY_SCHEMA_VERSION = 2, ABSENT_FROM_EFFECTIVE_DB = 1 },
    outcome = { EXPECTED_REPRESENTATION_DIFF = 1, CONFIRMED_MATCH = 1, NEEDS_MANUAL_REVIEW = 1, M1_UNSUPPORTED_BY_RULES = 1, CONFIRMED_MISMATCH = 1 },
    reasons = { KILLCREDIT_FIRST_REORDER = 1, DUPLICATE_OBJECT = 1, EXTRA_CREATURE_REF = 1 } }
r = R.ValidateAggregate(agg, base, OPT)
ok(r, "aggregate valid and reconciles: " .. table.concat(e or {}, "; "))
local function aggMut(f) local x = copy(agg); f(x); return R.ValidateAggregate(x, base, OPT) end
ok(not aggMut(function(x) x.reasons["quest-1203-private-label"] = 1 end), "private label as aggregate reason key rejected")
ok(not aggMut(function(x) x.reasons.SOME_NEW_CODE = 1 end), "unknown code-like reason key rejected")
ok(not aggMut(function(x) x.reasons[1203] = 1 end), "numeric reason key rejected")
ok(not aggMut(function(x) x.reasons.DUPLICATE_OBJECT = 2 end), "reason count not matching report rejected")
ok(not aggMut(function(x) x.reasons.EXTRA_CREATURE_REF = nil end), "missing reason count rejected")
ok(not aggMut(function(x) x.questIds = { 1203 } end), "aggregate with quest IDs rejected")
ok(not aggMut(function(x) x.sourceFingerprint = "sha256:x" end), "aggregate with fingerprint rejected")
ok(not aggMut(function(x) x.outcome.CONFIRMED_MATCH = 2 end), "aggregate not reconciling rejected")
ok(not aggMut(function(x) x.reasonVocabVersion = 2 end), "wrong vocabulary version rejected")
ok(not aggMut(function(x) x.exportStatus.REJECTED_MALFORMED_INPUT = 0 end), "rejection code as aggregate status rejected")
ok(not R.ValidateAggregate(agg, nil, OPT), "aggregate must be reconciled against the report")
-- same reason on two quests counts twice
local b2 = copy(base); row(b2, 10503).reasons = { "KILLCREDIT_FIRST_REORDER", "EXTRA_CREATURE_REF" }
local a2 = copy(agg); a2.reasons.EXTRA_CREATURE_REF = 2
ok(R.ValidateReport(b2, OPT) and R.ValidateAggregate(a2, b2, OPT), "same reason on two quests counted per occurrence")
ok(not R.ValidateAggregate(agg, b2, OPT), "per-occurrence count enforced")

-- Executable protocol matrix
local Mx = dofile("tests/fixtures/m2_3_draft/batch_matrix.lua")
local executed, design = 0, 0
for _, c in ipairs(Mx.cases) do
    if c.designAssertion then design = design + 1
    elseif c.run == "plan" then
        executed = executed + 1
        local rows, code = R.PlanSelection(c.server, c.manifest, c.export, OPT)
        if type(c.expect) == "string" then
            ok(rows == nil and code == c.expect, c.id .. ": expected " .. c.expect .. ", got " .. tostring(code or "rows"))
        else
            ok(rows and #rows == #c.expect, c.id .. ": one row per selected quest (" .. tostring(code) .. ")")
            for i, ex in ipairs(c.expect) do
                ok(rows and rows[i] and rows[i].questId == ex[1] and rows[i].exportStatus == ex[2], c.id .. ": row " .. i .. " " .. ex[2])
            end
            if c.id == "S06" then ok(rows and table.concat(rows[2].reasons, ",") == "DUPLICATE_OBJECT,EXTRA_CREATURE_REF", "S06: manifest reasons carried") end
            if c.id == "S14" then ok(rows and rows[1].m1Supported == false, "S14: v2 unsupported quest marked m1Supported=false") end
        end
    elseif c.run == "split" then
        executed = executed + 1
        local s = R.PreflightSplit(c.server, c.manifest, OPT)
        for k, v in pairs(c.expect) do ok(s and table.concat(s[k], ",") == table.concat(v, ","), c.id .. ": " .. k) end
    end
end
ok(executed == 21 and design == 3, ("matrix: %d executed, %d design assertions"):format(executed, design))

-- Server and pairing gates (executed via the v2 draft validator)
local srv = dofile("tests/fixtures/m2_input/private_adapter_v3_synthetic.lua")
local bad = copy(srv); bad.provenance.exporter = nil
ok(not D.CheckServerDocument(bad, OPT), "B: incomplete server provenance rejects the batch")
local dup = copy(srv); dup.records = dup.records or dup.quests
local list = dup.records
if list and list[1] then list[#list + 1] = copy(list[1]); dup.provenance.questCount = #list
    ok(not D.CheckServerDocument(dup, OPT), "B: duplicate server quest ID rejects the batch") end
local V2 = dofile("tests/fixtures/m2_effective_v2_draft/v2_categories.lua")
local cov = copy(V2.provenance); cov.dataKind = nil
ok(D.CheckPairing(V2.provenance, cov, OPT), "B: paired provenance accepted")
for _, f in ipairs({ "sourceCommit", "correctionFingerprint", "harnessVersion" }) do
    local c2 = copy(cov); c2[f] = (f == "harnessVersion") and "1.2.0" or (f == "sourceCommit" and string.rep("d", 40) or "sha256:" .. string.rep("e", 64))
    ok(not D.CheckPairing(V2.provenance, c2, OPT), "B: pairing rejects differing " .. f)
end
local c3 = copy(cov); c3.sourceDirty = true
ok(not D.CheckPairing(V2.provenance, c3, OPT), "B: dirty manifest rejects the batch")

if fails > 0 then print(("FAIL: %d of %d checks failed"):format(fails, n)); os.exit(1) end
print(("PASS: M2.3 contract DRAFT (%d checks; %d matrix cases executed, %d design assertions not executed)"):format(n, executed, design))
