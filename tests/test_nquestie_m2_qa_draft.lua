-- DRAFT tests: two-tier correction regression and text/tooltip QA records.
-- Synthetic only. Lua 5.1.
local Q = dofile("tools/validation/draft/CorrectionQaDraft.lua")
local OPT = { allowDraft = true }
local n, fails = 0, 0
local function ok(c, m) n = n + 1; if not c then fails = fails + 1; print("FAIL: " .. m) end end
local function copy(t) if type(t) ~= "table" then return t end local o = {} for k, v in pairs(t) do o[k] = copy(v) end return o end
local function has(errs, s) for _, e in ipairs(errs or {}) do if e:find(s, 1, true) then return true end end return false end
local F = dofile("tests/fixtures/m2_qa_draft/qa_synthetic.lua")

ok(not pcall(Q.CheckRegression, F.regression[1]), "draft guard")
for i, e in ipairs(F.regression) do local v, er = Q.CheckRegression(e, OPT); ok(v, "regression fixture " .. i .. ": " .. table.concat(er or {}, "; ")) end
for i, o in ipairs(F.text) do local v, er = Q.CheckTextObservation(o, OPT); ok(v, "text fixture " .. i .. ": " .. table.concat(er or {}, "; ")) end

local function reg(i, f) local x = copy(F.regression[i]); f(x); return Q.CheckRegression(x, OPT) end
local r, e = reg(1, function(x) x.fields.objectives.compiled = 33110 end)
ok(not r and has(e, "tier A"), "tier A: compiled value not the approved value")
r, e = reg(1, function(x) x.unrelatedDiffs = 1 end)
ok(not r and has(e, "unrelated"), "tier A: unrelated field change fails")
r, e = reg(1, function(x) x.fields.objectives.expectedInherited = nil end)
ok(not r and has(e, "guard"), "tier A: inherited guard required")
r, e = reg(2, function(x) x.reviewNote = nil end)
ok(not r and has(e, "documented reason"), "tier B: undocumented manual review fails")
ok(Q.CheckRegression(F.regression[2], OPT), "tier B: documented NEEDS_MANUAL_REVIEW allowed (no forced confirmation)")
r, e = reg(1, function(x) x.m23Outcome = "CONFIRMED_MISMATCH" end)
ok(not r and has(e, "regression"), "tier B: CONFIRMED_MISMATCH is a regression")
r = reg(1, function(x) x.m23Outcome = "M1_UNSUPPORTED_BY_RULES" end)
ok(not r, "tier B: unexpected outcome fails")
ok(Q.CheckRegression(F.regression[3], OPT), "tier B optional until M2.3 exists (tier A alone)")

local function txt(i, f) local x = copy(F.text[i]); f(x); return Q.CheckTextObservation(x, OPT) end
r, e = txt(2, function(x) x.result = "PASS"; x.observed = true end)
ok(not r and has(e, "verified quest availability"), "unknown availability never PASS")
r = txt(2, function(x) x.result = "DIFFERENCE_TO_REVIEW" end)
ok(not r, "unknown availability gives UNKNOWN, not a difference")
r, e = txt(1, function(x) x.result = "CONFIRMED_MATCH" end)
ok(not r and has(e, "PASS, DIFFERENCE_TO_REVIEW or UNKNOWN"), "no CONFIRMED text result")
r = txt(1, function(x) x.clientLocale = nil end)
ok(not r, "client locale must be recorded (no enUS assumption)")
r = txt(1, function(x) x.observed = false end)
ok(not r, "PASS needs an actual observation")
r = txt(1, function(x) x.textSource = "server-private" end)
ok(not r, "private server text is not a public PASS reference")
r, e = txt(3, function(x) x.autoRewrite = true end)
ok(not r and has(e, "automatic"), "no automatic text rewrite")
r = txt(3, function(x) x.m1Outcome = "CONFIRMED_MISMATCH" end)
ok(not r, "text difference never becomes an M1 outcome")
r = txt(1, function(x) x.stage = "all" end)
ok(not r, "stage must be the one actually tested")
r = txt(1, function(x) x.surface = "everything" end)
ok(not r, "surface must be specific")

if fails > 0 then print(("FAIL: %d of %d checks failed"):format(fails, n)); os.exit(1) end
print(("PASS: correction regression and text QA DRAFT (%d checks)"):format(n))
