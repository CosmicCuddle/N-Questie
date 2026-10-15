-- DRAFT tests for the proposed nq-m2-markers record and location rules.
-- Synthetic data only; no exporter. Lua 5.1.
local K = dofile("tools/validation/draft/MarkersDraft.lua")
local OPT = { allowDraft = true }
local n, fails = 0, 0
local function ok(c, m) n = n + 1; if not c then fails = fails + 1; print("FAIL: " .. m) end end
local function copy(t) if type(t) ~= "table" then return t end local o = {} for k, v in pairs(t) do o[k] = copy(v) end return o end
local function has(errs, s) for _, e in ipairs(errs or {}) do if e:find(s, 1, true) then return true end end return false end
local F = dofile("tests/fixtures/m2_markers_draft/markers_synthetic.lua")
local function mut(i, f) local r = copy(F[i]); f(r); return K.Validate(r, OPT) end

ok(not pcall(K.Validate, F[1]), "draft guard")
for i, r in ipairs(F) do local v, e = K.Validate(r, OPT); ok(v, "fixture " .. r.ID .. " valid: " .. table.concat(e or {}, "; ")) end

-- A1 custom spawn-only: exact pins, no loss, no invention, no rounding
local r, e = mut(1, function(x) table.remove(x.points, 2) end)
ok(not r and has(e, "lost from points"), "A1 dropping a custom pin rejected")
r, e = mut(1, function(x) x.points[2].x = 41.4 end)
ok(not r and has(e, "differ from the raw pin"), "A1 rounded custom coordinate rejected")
r, e = mut(1, function(x) x.points[3] = { origin = "custom_extra", extraPosition = 1, zone = 9001, x = 5, y = 5, pinIndex = 3 } end)
ok(not r and has(e, "invented"), "A1 invented custom point rejected")
r = mut(1, function(x) x.extraObjectives[1].customSpawns = { { zone = 9001 } }; x.points = {} end)
ok(not r, "A1 zone-only custom spawn (no pins) rejected")
r = mut(1, function(x) x.points[2].pinIndex = 1 end)
ok(not r, "A1 two pins collapsed into one index rejected")
ok(F[1].extraObjectives[1].objectiveIndex == 0, "A1 objectiveIndex 0 kept")
r = mut(1, function(x) x.points[1].ownerId = 911001 end)
ok(not r, "A1 custom point may not claim a DB owner")

-- A2 mixed refs and custom pins
r, e = mut(2, function(x) x.extraObjectives[1].displayRef = { type = "object", id = 912003 } end)
ok(not r and has(e, "first ref"), "A2 display metadata must be the first ref")
r = mut(2, function(x) table.remove(x.points, 4) end)
ok(not r, "A2 custom pin lost beside refs rejected")
r = mut(2, function(x) x.points[3].origin = "custom_extra"; x.points[3].extraPosition = 1 end)
ok(not r, "A2 DB object spawn relabelled as custom rejected")
r = mut(2, function(x) x.points[4].origin = "db_npc"; x.points[4].ownerId = 912002; x.points[4].extraPosition = nil end)
ok(not r, "A2 custom pin relabelled as DB spawn rejected (pin then lost)")

-- A3 waypoints separate
r, e = mut(3, function(x) x.points[3] = { origin = "waypoint", zone = 9003, x = 25.0, y = 22.0, pinIndex = 1 } end)
ok(not r and has(e, "waypoints are never points"), "A3 waypoint as point rejected")
ok(#F[3].waypoints[1].path == 3 and #F[3].points == 2, "A3 waypoints kept apart from 2 spawns")
r = mut(3, function(x) x.points[3] = copy(x.points[1]) end)
ok(not r, "A3 duplicate point rejected")

-- A4 item source categories
r, e = mut(4, function(x) x.objectives[1].targets[3].sourceKind = nil end)
ok(not r and has(e, "category required"), "A4 source category required")
r = mut(4, function(x) x.objectives[1].targets[2].sourceKind = "npcDrop" end)
ok(not r, "A4 object source relabelled as npcDrop rejected")
r = mut(4, function(x) x.objectives[1].targets[4].type = "monster" end)
ok(not r, "A4 nested item source must stay an item")
r = mut(4, function(x) x.objectives[1].targets[1].path = { 914001 } end)
ok(not r, "A4 relationship path required")
r = mut(4, function(x) x.objectives[1].targets[1].via = "direct" end)
ok(not r, "A4 item source flattened to a direct target rejected")
local kinds = {} for _, t in ipairs(F[4].objectives[1].targets) do kinds[t.sourceKind] = true end
for k in pairs(K.SOURCE_KIND) do ok(kinds[k], "A4 covers " .. k) end

-- A5 location results: never confirmed
local base = { transformVerified = true, phase = "known", conditions = "known", ip = "known", spawnActivity = "known", distance = 0.4, tolerance = 1.0 }
ok(K.LocationResult(base, OPT) == "WITHIN_PROVISIONAL_TOLERANCE", "A5 all known, inside provisional tolerance")
local far = copy(base); far.distance = 3
ok(K.LocationResult(far, OPT) == "OUTSIDE_PROVISIONAL_TOLERANCE", "A5 all known, outside provisional tolerance")
for _, k in ipairs({ "phase", "conditions", "ip", "spawnActivity" }) do
    local c = copy(far); c[k] = "unknown"
    ok(K.LocationResult(c, OPT) == "NEEDS_MANUAL_REVIEW", "A5 unknown " .. k .. ": no positional mismatch")
end
local nt = copy(far); nt.transformVerified = false
ok(K.LocationResult(nt, OPT) == "NEEDS_MANUAL_REVIEW", "A5 unverified map transform: no positional mismatch")
local tol = copy(far); tol.tolerance = nil
ok(K.LocationResult(tol, OPT) == "NEEDS_MANUAL_REVIEW", "A5 tolerance must be an explicit parameter")
for res in pairs(K.LOCATION_RESULT) do ok(not res:find("CONFIRMED"), "A5 no confirmed location result: " .. res) end

if fails > 0 then print(("FAIL: %d of %d checks failed"):format(fails, n)); os.exit(1) end
print(("PASS: nq-m2-markers DRAFT (%d checks)"):format(n))
