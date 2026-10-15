-- Pins the validate-335 harness version (1.3.0 = Stage A2 v2 export mode; 1.2.0 = kill-credit ordering
-- protection). Static source check plus the version grammar used by the
-- frozen v1 schema. Lua 5.1, reads one file.
local n, fails = 0, 0
local function ok(c, m) n = n + 1; if not c then fails = fails + 1; print("FAIL: " .. m) end end
local src = io.open("cli/validate-335.lua"):read("*a")
local v = src:match('local HARNESS_VERSION = "([^"]+)"')
ok(v == "1.3.0", "HARNESS_VERSION is 1.3.0 (got " .. tostring(v) .. ")")
local count = 0 for _ in src:gmatch("HARNESS_VERSION =") do count = count + 1 end
ok(count == 1, "HARNESS_VERSION defined exactly once")
ok(select(2, src:gsub("harnessVersion = HARNESS_VERSION", "")) >= 3, "v1 export, coverage manifest and v2 export provenance all use HARNESS_VERSION")
ok(src:find("KILLCREDIT_FIRST_REORDER", 1, true) or src:find("killCreditObjectiveFirst", 1, true), "order protection present in the harness")
ok(v and v:match("^%d+%.%d+%.%d+[%w%.%-]*$"), "matches the frozen v1 harnessVersion grammar")
if fails > 0 then print(("FAIL: %d of %d"):format(fails, n)); os.exit(1) end
print(("PASS: harness version pin (%d checks)"):format(n))
