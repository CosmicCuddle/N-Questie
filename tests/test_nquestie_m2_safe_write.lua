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

    -- Publish a file, then force the real writer's own *post-install*
    -- path recheck to fail. It must preserve the file and explicitly report
    -- publication, not return the same shape as pre-install failures.
    local postFinal = out .. "/writer-post-install.lua"
    local savedResolve = Input.resolver
    local afterPreInstall = false
    Input.resolver = function(path)
        if afterPreInstall and path == postFinal then return nil end
        return savedResolve(path)
    end
    local postOk, postReason, postState = W.WriteFile(postFinal, "PUBLISHED", {
        repoRoot = root, hooks = { beforeInstall = function() afterPreInstall = true end },
    })
    Input.resolver = savedResolve
    if postOk == false and tostring(postReason):find("post-install check failed", 1, true)
       and type(postState) == "table" and postState.published == true
       and postState.final == postFinal and read(postFinal) == "PUBLISHED" then
        pass("post-install verification failure explicitly reports published file")
    else
        fail("post-install verification failure lost publication status or file")
    end

    -- A mock mktemp emits a believable already-existing filename, but exits
    -- 17. Old Lua 5.1 io.popen():close() code trusted stdout, opened that file
    -- with "wb" and silently destroyed its previous bytes. Reject before ANY
    -- attempted file open, and prove both sentinel and final remain untouched.
    local failbin = base .. "/fake-mktemp-bin"
    assert(sh("mkdir -m 700 " .. q(failbin)))
    local sentinel = out .. "/.nq-write.DO_NOT_OVERWRITE"
    local sf = assert(io.open(sentinel, "wb"))
    sf:write("SENTINEL_CONTENTS_UNCHANGED\n"); sf:close()
    assert(sh("chmod 600 " .. q(sentinel)))
    local fake = assert(io.open(failbin .. "/mktemp", "wb"))
    fake:write("#!/bin/sh\n" ..
        ": > \"$NQ_TEST_MKTEMP_MARKER\"\n" ..
        "printf '%s\\n' \"$NQ_TEST_MKTEMP_SENTINEL\"\n" ..
        "exit 17\n")
    fake:close()
    assert(sh("chmod 700 " .. q(failbin .. "/mktemp")))

    local realLua = line("command -v lua5.1")
    assert(realLua and realLua:sub(1, 1) == "/")
    local probe = base .. "/check-safe-capture.lua"
    local pf = assert(io.open(probe, "wb"))
    pf:write("local W = dofile('tools/validation/SafeWrite.lua')\n" ..
        "local yes, why = W.WriteFile(arg[1], 'NEW_PRIVATE_CONTENTS', {repoRoot=arg[2]})\n" ..
        "if yes then os.exit(11) end\n" ..
        "if not tostring(why):find(arg[3], 1, true) then os.exit(12) end\n" ..
        "os.exit(0)\n")
    pf:close()
    local mark = base .. "/failed-mktemp-was-invoked"
    local final = out .. "/should-not-be-created.lua"
    local command = "PATH=" .. q(failbin .. ":" .. (os.getenv("PATH") or "")) ..
        " NQ_TEST_MKTEMP_SENTINEL=" .. q(sentinel) ..
        " NQ_TEST_MKTEMP_MARKER=" .. q(mark) ..
        " " .. q(realLua) .. " " .. q(probe) .. " " .. q(final) .. " " .. q(root) ..
        " " .. q("cannot create a temporary file") .. " >/dev/null 2>&1"
    if sh(command) and sh("test -f " .. q(mark)) and read(sentinel) == "SENTINEL_CONTENTS_UNCHANGED\n"
        and not read(final) then
        pass("failed mktemp plausible stdout cannot overwrite a preexisting private sentinel")
    else
        fail("failed mktemp stdout was trusted or a preexisting private file was altered")
    end

    -- A mock stat prints the real directory ownership/mode, then exits 17.
    -- Even a plausible trusted-looking stat line must not authorise a write.
    local failStatBin = base .. "/fake-stat-bin"
    assert(sh("mkdir -m 700 " .. q(failStatBin)))
    local realStat = line("command -v stat")
    assert(realStat and realStat:sub(1, 1) == "/")
    local st = assert(io.open(failStatBin .. "/stat", "wb"))
    st:write("#!/bin/sh\n" ..
        "if [ \"$4\" = \"$NQ_TEST_STAT_TARGET\" ]; then\n" ..
        "  : > \"$NQ_TEST_STAT_MARKER\"\n" ..
        "  \"$NQ_REAL_STAT\" \"$@\"\n" ..
        "  exit 17\n" ..
        "fi\n" ..
        "exec \"$NQ_REAL_STAT\" \"$@\"\n")
    st:close()
    assert(sh("chmod 700 " .. q(failStatBin .. "/stat")))
    local statMark = base .. "/failed-stat-was-invoked"
    local statDest = out .. "/should-not-stat-write.lua"
    command = "PATH=" .. q(failStatBin .. ":" .. (os.getenv("PATH") or "")) ..
        " NQ_TEST_STAT_TARGET=" .. q(out) ..
        " NQ_TEST_STAT_MARKER=" .. q(statMark) ..
        " NQ_REAL_STAT=" .. q(realStat) ..
        " " .. q(realLua) .. " " .. q(probe) .. " " .. q(statDest) .. " " .. q(root) ..
        " " .. q("cannot stat output directory") .. " >/dev/null 2>&1"
    if sh(command) and sh("test -f " .. q(statMark)) and not read(statDest) then
        pass("failed stat with plausible metadata cannot authorise a private output")
    else
        fail("failed stat stdout was trusted or write survived failed destination check")
    end

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
