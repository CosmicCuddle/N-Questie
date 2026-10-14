#!/usr/bin/env lua5.1
-- M2.2 Step 4 safe-writer tests. Uses temporary directories created at run
-- time; removes them afterwards. Linux + GNU coreutils.
local W = dofile("tools/validation/SafeWrite.lua")
local Input = W.Input

local failures, passes = 0, 0
local function fail(m) failures = failures + 1; io.stderr:write("FAIL: " .. m .. "\n") end
local function pass(m) passes = passes + 1; print("PASS: " .. m) end
local function q(s) return "'" .. s:gsub("'", "'\\''") .. "'" end
local function sh(c) local r = os.execute(c .. " >/dev/null 2>&1"); return r == 0 or r == true end
local function line(c) local h = io.popen(c); local l = h:read("*l"); h:close(); return l end
local function read(p) local f = io.open(p, "rb"); if not f then return nil end local s = f:read("*a"); f:close(); return s end
local function count(dir) return tonumber(line("ls -A " .. q(dir) .. " | wc -l")) end

local root = line("pwd -P")
local base = line("realpath -e -- \"$(mktemp -d)\"")
local out = base .. "/out"
sh("mkdir -m 700 " .. q(out))
local privDir = root .. "/private/m2-write-test-" .. os.time() .. "-" .. math.random(1e6)
sh("mkdir -p -m 700 " .. q(privDir))

local function expectFail(name, path, content, opts, needle)
    opts = opts or {}; opts.repoRoot = root
    local ok, msg = W.WriteFile(path, content or "x", opts)
    if ok then fail(name .. ": accepted")
    elseif needle and not msg:find(needle, 1, true) then fail(name .. ": wrong reason: " .. msg)
    else pass(name .. " -> " .. msg) end
end

local okRun, err = pcall(function()
    -- success
    local ok, final = W.WriteFile(out .. "/a.lua", "return {}\n", { repoRoot = root })
    if ok and read(final) == "return {}\n" then pass("writes a new file outside the checkout") else fail("basic write: " .. tostring(final)) end
    if line("stat -c %a " .. q(out .. "/a.lua")) == "600" then pass("final file mode 0600") else fail("mode not 600") end
    if count(out) == 1 then pass("no temp files left after success") else fail("temp files left") end
    ok = W.WriteFile(privDir .. "/r.lua", "x", { repoRoot = root })
    if ok then pass("writes under private/") else fail("private/ write refused") end

    -- no-clobber and force
    expectFail("existing file without --force", out .. "/a.lua", "NEW", nil, "exists")
    if read(out .. "/a.lua") == "return {}\n" then pass("existing file unchanged after refused write") else fail("existing file changed") end
    ok = W.WriteFile(out .. "/a.lua", "NEW\n", { repoRoot = root, force = true })
    if ok and read(out .. "/a.lua") == "NEW\n" then pass("--force replaces atomically") else fail("--force failed") end
    if count(out) == 1 then pass("no temp files left after --force") else fail("temp left after force") end
    -- race: target appears between check and install (no-clobber must still refuse)
    expectFail("target created just before install (link no-clobber)", out .. "/race.lua", "MINE",
        { hooks = { beforeInstall = function(_, fin) local f = io.open(fin, "wb"); f:write("THEIRS"); f:close(); return true end } },
        "no-clobber")
    if read(out .. "/race.lua") == "THEIRS" then pass("racing file kept intact (not clobbered)") else fail("racing file clobbered") end

    -- locations
    expectFail("inside the public checkout", root .. "/docs/x.lua", "x", nil, "inside the public checkout")
    expectFail("tests/fixtures is not a write location", root .. "/tests/fixtures/m2_input/x.lua", "x", nil, "inside the public checkout")
    sh("ln -s " .. q(root .. "/docs") .. " " .. q(out .. "/docs-link"))
    expectFail("directory symlink redirecting into the checkout", out .. "/docs-link/x.lua", "x", nil, "inside the public checkout")
    sh("ln -s " .. q(root .. "/docs/ROADMAP.md") .. " " .. q(out .. "/link.lua"))
    expectFail("final path is a symlink (no force)", out .. "/link.lua", "x", nil, "symlink")
    expectFail("final path is a symlink (force)", out .. "/link.lua", "x", { force = true }, "symlink")
    expectFail("missing directory", base .. "/nope/x.lua", "x", nil, "does not exist")
    expectFail("relative path", "out/x.lua", "x", nil, "absolute")
    expectFail(".. segment", out .. "/../out/x.lua", "x", nil, ". or ..")
    expectFail("bad file name", out .. "/x y.lua", "x", nil, "plain")
    sh("mkdir -m 755 " .. q(base .. "/open"))
    expectFail("directory with group/other access", base .. "/open/x.lua", "x", nil, "chmod 700")
    sh("mkdir " .. q(out .. "/sub.lua"))
    expectFail("final path is a directory (force)", out .. "/sub.lua", "x", { force = true }, "not a regular file")

    -- simulated failures: nothing partial left, existing file intact
    W.WriteFile(out .. "/keep.lua", "GOOD", { repoRoot = root })
    for _, h in ipairs({ "afterTempCreate", "afterWrite", "beforeInstall" }) do
        local hooks = {}; hooks[h] = function() return false end
        expectFail("simulated failure: " .. h .. " (new file)", out .. "/new-" .. h .. ".lua", "DATA", { hooks = hooks }, "simulated")
        if not read(out .. "/new-" .. h .. ".lua") then pass("no final file after " .. h .. " failure") else fail("partial final after " .. h) end
        hooks = {}; hooks[h] = function() error("crash") end
        expectFail("simulated crash: " .. h .. " (force over existing)", out .. "/keep.lua", "BAD", { hooks = hooks, force = true }, "simulated")
        if read(out .. "/keep.lua") == "GOOD" then pass("existing valid file intact after " .. h .. " crash") else fail("existing file damaged after " .. h) end
    end
    local leftovers = tonumber(line("ls -A " .. q(out) .. " | grep -c '^.nq-write' || true"))
    if leftovers == 0 then pass("no temp files left after simulated failures") else fail(leftovers .. " temp files left") end

    -- resolver failure
    local saved = Input.resolver
    Input.resolver = function() return nil end
    expectFail("resolver unavailable", out .. "/z.lua", "x", nil, "resolver unavailable")
    Input.resolver = saved

    -- unreadable/unwritable directory (skip as root)
    if line("id -u") ~= "0" then
        sh("mkdir -m 500 " .. q(out .. "/ro"))
        expectFail("read-only directory", out .. "/ro/x.lua", "x", nil, nil)
        sh("chmod 700 " .. q(out .. "/ro"))
    end
end)

sh("rm -rf -- " .. q(base) .. " " .. q(privDir))
if not okRun then fail("harness error: " .. tostring(err)) end
if failures > 0 then io.stderr:write("FAILED: " .. failures .. "\n"); os.exit(1) end
print(string.format("PASS: M2.2 safe writer (%d checks)", passes))
