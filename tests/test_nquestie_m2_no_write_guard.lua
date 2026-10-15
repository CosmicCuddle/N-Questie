-- Stage A1: NoWriteGuard blocks and counts every write/process attempt, and
-- the v2 round trip itself makes none. Synthetic data only. Lua 5.1.
local Guard = dofile("tools/validation/NoWriteGuard.lua")
local RT = dofile("tools/validation/RoundTripV2.lua")
local SafeWrite = dofile("tools/validation/SafeWrite.lua")
local S = dofile("tests/fixtures/m2_v2_builder/compiled_synthetic.lua")
local n, fails = 0, 0
local function ok(c, m) n = n + 1; if not c then fails = fails + 1; print("FAIL: " .. m) end end

local origOpen, origPopen, origTmpfile, origExec = io.open, io.popen, io.tmpfile, os.execute
local g = Guard.Install()
local tries = {
    { "io.open w", function() return io.open("/nonexistent-dir/x", "w") end },
    { "io.open a", function() return io.open("/nonexistent-dir/x", "a") end },
    { "io.open r+", function() return io.open("/nonexistent-dir/x", "r+") end },
    { "io.open wb", function() return io.open("/nonexistent-dir/x", "wb") end },
    { "io.tmpfile", function() return io.tmpfile() end },
    { "io.output", function() return io.output("/nonexistent-dir/x") end },
    { "io.popen", function() return io.popen("true") end },
    { "os.execute", function() return os.execute("true") end },
    { "os.rename", function() return os.rename("/nonexistent-dir/a", "/nonexistent-dir/b") end },
    { "os.remove", function() return os.remove("/nonexistent-dir/a") end },
    { "os.tmpname", function() return os.tmpname() end },
}
for _, t in ipairs(tries) do
    local okCall = pcall(t[2])
    ok(not okCall, "guard blocks " .. t[1])
end
local fr = io.open("tools/validation/NoWriteGuard.lua", "r")
ok(fr ~= nil, "guard passes read-mode io.open")
if fr then fr:close() end
local fr2 = io.open("tools/validation/NoWriteGuard.lua")
ok(fr2 ~= nil, "guard passes default-mode io.open")
if fr2 then fr2:close() end
-- SafeWrite (the only sanctioned writer) cannot write under the guard
local sw = pcall(SafeWrite.WriteFile, "/tmp/nq-guard-test-should-not-exist", "x", { repoRoot = "/nonexistent" })
ok(not sw or io.open("/tmp/nq-guard-test-should-not-exist") == nil, "SafeWrite cannot write under the guard")
local count, kinds = Guard.Remove(g)
ok(count >= #tries, "every attempt counted: " .. count)
ok(kinds["io.open:w"] == 1 and kinds["io.tmpfile"] == 1 and kinds["os.execute"] >= 1 and kinds["io.popen"] >= 1, "kinds recorded, including tempfile creation")
ok(io.open == origOpen and io.popen == origPopen and io.tmpfile == origTmpfile and os.execute == origExec, "Remove restores the originals, including io.tmpfile")

-- The round trip under the guard makes zero attempts
local g2 = Guard.Install()
local ids = {}
for id in pairs(S.quests) do ids[#ids + 1] = id end
local okRun = pcall(RT.Run, function(id, key) return S.quests[id] and S.quests[id][key] end, ids, { killCreditFirst = S.killCreditFirst })
local c2 = Guard.Remove(g2)
ok(okRun and c2 == 0, "round trip under the guard: no write or process attempt (" .. c2 .. ")")

-- The guard works on an injected environment too (no real I/O)
local calls = 0
local fake = { io = { open = function() calls = calls + 1 return "f" end, output = function() end,
    popen = function() end, tmpfile = function() calls = calls + 1 return "f" end },
    os = { rename = function() end, remove = function() end, tmpname = function() end, execute = function() end } }
local g3 = Guard.Install(fake)
ok(fake.io.open("x", "r") == "f" and calls == 1, "read passes through to the original")
ok(not pcall(fake.io.open, "x", "w") and calls == 1, "write blocked before reaching the original")
ok(not pcall(fake.io.tmpfile) and calls == 1, "temporary-file creation blocked in injected environment")
ok(type(fake.io.tmpfile) == "function", "injected guard exposes a protected tempfile function")
ok(Guard.Remove(g3) == 2, "injected environment counted both blocked writes")
ok(fake.io.tmpfile() == "f" and calls == 2, "injected temporary-file function restored")

if fails > 0 then print("FAIL: " .. fails .. " of " .. n .. " checks failed"); os.exit(1) end
print("PASS: M2 no-write guard (" .. n .. " checks)")
