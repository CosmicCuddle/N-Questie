-- DRAFT tests for the proposed M2.3 report/aggregate formats and batch matrix.
-- No engine, no server data, no file output. Lua 5.1.
local R = dofile("tools/validation/draft/M23ReportDraft.lua")
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

r, e = mut(function(d) table.remove(d.rows, 7) end)
ok(not r and has(e, "silent disappearance"), "missing selected quest rejected")
r, e = mut(function(d) d.rows[#d.rows + 1] = copy(d.rows[1]) end)
ok(not r and has(e, "appears twice"), "quest twice rejected")
r, e = mut(function(d) row(d, 10503).outcome = "CONFIRMED_MATCH" end)
ok(not r and has(e, "only EXPORTED"), "outcome on non-exported quest rejected")
r, e = mut(function(d) row(d, 1203).outcome = nil end)
ok(not r and has(e, "exactly one outcome"), "exported quest without outcome rejected")
r, e = mut(function(d) row(d, 498).outcome = "CONFIRMED_MATCH" end)
ok(not r and has(e, "CONFIRMED_MATCH without"), "unknown KillCredit never confirms")
for _, k in ipairs({ "conditions", "scripts", "ip" }) do
    r, e = mut(function(d) row(d, 2001).evidence = copy(row(d, 2001).evidence); row(d, 2001).evidence[k] = "unknown" end)
    ok(not r, "unknown " .. k .. " never confirms")
end
r, e = mut(function(d) row(d, 1203).outcome = "CONFIRMED_MATCH" end)
ok(not r, "findings present: no CONFIRMED_MATCH (1203)")
r, e = mut(function(d) row(d, 25199).outcome = "CONFIRMED_MATCH"; row(d, 25199).m1Findings = 0 end)
ok(not r, "M1-unsupported never confirms")
r, e = mut(function(d) row(d, 900007).evidence = { killCredit = "unknown" } end)
ok(not r and has(e, "CONFIRMED_MISMATCH needs"), "mismatch needs complete evidence")
r, e = mut(function(d) row(d, 11142).reasons = {} end)
ok(not r and has(e, "reason codes"), "unsupported quest without reasons rejected")
r, e = mut(function(d) row(d, 1203).exportStatus = "SKIPPED" end)
ok(not r, "unknown export status rejected")
r, e = mut(function(d) d.private = nil end)
ok(not r, "report must be marked private")

-- Aggregate
local agg = { schema = "nq-m2-3-aggregate", schemaVersion = 1, selectedCount = 9,
    exportStatus = { EXPORTED = 5, UNSUPPORTED_BY_SCHEMA_VERSION = 2, ABSENT_FROM_EFFECTIVE_DB = 1, REJECTED_MALFORMED_INPUT = 1 },
    outcome = { EXPECTED_REPRESENTATION_DIFF = 1, CONFIRMED_MATCH = 1, NEEDS_MANUAL_REVIEW = 1, M1_UNSUPPORTED_BY_RULES = 1, CONFIRMED_MISMATCH = 1 },
    reasons = { KILLCREDIT_FIRST_REORDER = 1, DUPLICATE_OBJECT = 1, EXTRA_CREATURE_REF = 1 } }
r, e = R.ValidateAggregate(agg, base, OPT)
ok(r, "aggregate valid and reconciles: " .. table.concat(e or {}, "; "))
local a2 = copy(agg); a2.questIds = { 1203 }
ok(not R.ValidateAggregate(a2, base, OPT), "aggregate with quest IDs rejected")
a2 = copy(agg); a2.sourceFingerprint = "sha256:x"
ok(not R.ValidateAggregate(a2, base, OPT), "aggregate with fingerprint rejected")
a2 = copy(agg); a2.reasons = { [1203] = 1 }
ok(not R.ValidateAggregate(a2, base, OPT), "aggregate keyed by ID rejected")
a2 = copy(agg); a2.outcome.CONFIRMED_MATCH = 2
ok(not R.ValidateAggregate(a2, base, OPT), "aggregate not reconciling rejected")

-- Batch matrix completeness
local Mx = dofile("tests/fixtures/m2_3_draft/batch_matrix.lua")
local ids, inputs, results = {}, {}, {}
for _, c in ipairs(Mx) do
    ok(not ids[c.id], "matrix id unique " .. c.id); ids[c.id] = true
    inputs[c.input] = true
    local s, o = c.result:match("^([A-Z_]+)/?([A-Z_0-9]*)$")
    ok(c.result == "reject" or R.EXPORT_STATUS[s], "matrix result valid " .. c.id)
    if o and o ~= "" then ok(s == "EXPORTED" and R.OUTCOME[o], "outcome only with EXPORTED " .. c.id); results[o] = true end
    if s then results[s] = true end
end
for _, k in ipairs({ "server", "effective", "manifest", "pairing", "membership", "quest" }) do ok(inputs[k], "matrix covers " .. k) end
for k in pairs(R.EXPORT_STATUS) do ok(results[k], "matrix reaches " .. k) end
for k in pairs(R.OUTCOME) do ok(results[k], "matrix reaches " .. k) end

if fails > 0 then print(("FAIL: %d of %d checks failed"):format(fails, n)); os.exit(1) end
print(("PASS: M2.3 report format DRAFT (%d checks)"):format(n))
