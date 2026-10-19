#!/usr/bin/env lua5.1
-- M2.1 path-safety tests. Builds synthetic files and symlinks in temporary
-- directories at run time (nothing committed) and removes them afterwards.
-- Needs a POSIX shell with mktemp, ln and GNU realpath (Ubuntu CI runner).
-- Run from the repository root: lua5.1 tests/test_nquestie_m2_input_paths.lua

local Schema = dofile("tools/validation/InputSchema.lua")

local failures, passes = 0, 0
local function fail(msg) failures = failures + 1; io.stderr:write("FAIL: " .. msg .. "\n") end
local function pass(msg) passes = passes + 1; io.stdout:write("PASS: " .. msg .. "\n") end

local function q(s) return "'" .. s:gsub("'", "'\\''") .. "'" end
local function sh(cmd)
    local ok = os.execute(cmd)
    return ok == 0 or ok == true
end
local function readLine(cmd)
    local h = assert(io.popen(cmd))
    local l = h:read("*l"); h:close(); return l
end

local root = readLine("pwd -P")
local fixture = root .. "/tests/fixtures/m2_input/valid_selected_quests.lua"
local outside = readLine("mktemp -d")
assert(outside and outside:sub(1, 1) == "/", "mktemp failed")
outside = readLine("realpath -e -- " .. q(outside))
-- Remember whether this test created the parent. A pre-existing private/
-- directory can hold operator data and must never be removed by this test.
local privRoot = root .. "/private"
local privateRootWasAbsent = not (sh("test -e " .. q(privRoot)) or sh("test -L " .. q(privRoot)))
local privDir = privRoot .. "/m2-path-test-" .. tostring(os.time()) .. "-" .. tostring(math.random(1e6))
assert(sh("mkdir -p " .. q(privDir)), "cannot create private test dir")

local function cleanup()
    sh("rm -rf -- " .. q(outside) .. " " .. q(privDir))
    -- rmdir is nonrecursive: it refuses to erase any leftover/private files.
    -- Only remove the parent if this test created it and it is now empty.
    if privateRootWasAbsent and not sh("rmdir -- " .. q(privRoot)) then
        fail("temporary private/ parent is not empty or could not be removed")
    end
end

local function expectReject(name, path, needle)
    local ok, msg = Schema.CheckInputPath(path, root)
    if ok then fail(name .. ": accepted (" .. tostring(msg) .. ")")
    elseif needle and not tostring(msg):find(needle, 1, true) then fail(name .. ": wrong reason: " .. tostring(msg))
    else pass(name .. " -> rejected: " .. msg) end
end
local function expectAccept(name, path)
    local ok, msg = Schema.CheckInputPath(path, root)
    if ok then pass(name .. " -> accepted as " .. msg) else fail(name .. ": rejected: " .. tostring(msg)) end
end

local okRun, err = pcall(function()
    -- plain files
    sh("cp " .. q(fixture) .. " " .. q(outside .. "/input.lua"))
    sh("cp " .. q(fixture) .. " " .. q(privDir .. "/input.lua"))
    expectAccept("regular file outside the checkout", outside .. "/input.lua")
    expectAccept("regular file under private/", privDir .. "/input.lua")
    expectAccept("synthetic fixture under tests/fixtures/m2_input/", fixture)
    expectReject("tracked public file", root .. "/cli/validate-335.lua", "inside the public checkout")

    -- symlink outside -> into checkout (public) : reject
    sh("ln -s " .. q(root .. "/cli/validate-335.lua") .. " " .. q(outside .. "/to-public.lua"))
    expectReject("symlink outside pointing at a public file", outside .. "/to-public.lua", "inside the public checkout")
    -- symlink outside -> into an allowed area : accept (target governs)
    sh("ln -s " .. q(fixture) .. " " .. q(outside .. "/to-fixture.lua"))
    expectAccept("symlink outside pointing at tests/fixtures/m2_input/", outside .. "/to-fixture.lua")
    -- directory symlink outside -> checkout root, then a public file via it
    sh("ln -s " .. q(root) .. " " .. q(outside .. "/repo"))
    expectReject("parent-directory symlink into the checkout", outside .. "/repo/cli/validate-335.lua", "inside the public checkout")
    expectAccept("parent-directory symlink into the checkout, then private/", outside .. "/repo/private/" ..
        privDir:match("[^/]+$") .. "/input.lua")

    -- symlink inside private/ -> public checkout : reject
    sh("ln -s " .. q(root .. "/tools/validation/InputSchema.lua") .. " " .. q(privDir .. "/to-public.lua"))
    expectReject("symlink in private/ pointing at a public file", privDir .. "/to-public.lua", "inside the public checkout")
    -- directory symlink inside private/ -> checkout root
    sh("ln -s " .. q(root) .. " " .. q(privDir .. "/root"))
    expectReject("directory symlink in private/ to the checkout root", privDir .. "/root/cli/validate-335.lua",
        "inside the public checkout")
    -- symlink inside private/ -> outside : accept (target governs, and it is outside)
    sh("ln -s " .. q(outside .. "/input.lua") .. " " .. q(privDir .. "/to-outside.lua"))
    expectAccept("symlink in private/ pointing outside the checkout", privDir .. "/to-outside.lua")

    -- broken symlink, loop, nonexistent
    sh("ln -s " .. q(outside .. "/does-not-exist.lua") .. " " .. q(outside .. "/broken.lua"))
    expectReject("broken symlink", outside .. "/broken.lua", "cannot resolve")
    sh("ln -s " .. q(outside .. "/loop-b") .. " " .. q(outside .. "/loop-a") .. " && ln -s " ..
        q(outside .. "/loop-a") .. " " .. q(outside .. "/loop-b"))
    expectReject("symlink loop", outside .. "/loop-a", "cannot resolve")
    expectReject("nonexistent file", outside .. "/missing.lua", "cannot resolve")
    expectReject("nonexistent file under private/", privDir .. "/missing.lua", "cannot resolve")

    -- permission error (skipped when running as root, which bypasses modes)
    if readLine("id -u") ~= "0" then
        sh("mkdir " .. q(outside .. "/locked") .. " && cp " .. q(fixture) .. " " .. q(outside .. "/locked/in.lua") ..
            " && chmod 000 " .. q(outside .. "/locked"))
        expectReject("unreadable parent directory", outside .. "/locked/in.lua", "cannot resolve")
        sh("chmod 700 " .. q(outside .. "/locked"))
    else
        pass("unreadable parent directory: skipped (running as root)")
    end

    -- textual edge cases
    expectReject("relative path", "tests/fixtures/m2_input/valid_selected_quests.lua", "must be absolute")
    expectReject("path with .. segments", outside .. "/../" .. outside:match("[^/]+$") .. "/input.lua", ". or .. segments")
    expectReject("path with . segment", outside .. "/./input.lua", ". or .. segments")
    expectReject("empty path", "", "no input path")
    expectReject("path with a newline", outside .. "/in\nput.lua", "control characters")

    -- quoting: a file name with a single quote and spaces is handled safely
    sh("cp " .. q(fixture) .. " " .. q(outside .. "/it's a file.lua"))
    expectAccept("file name with quote and spaces", outside .. "/it's a file.lua")

    -- simulated resolver failure
    local saved = Schema.resolver
    Schema.resolver = function() return nil, "simulated failure" end
    expectReject("resolver returns nothing", outside .. "/input.lua", "resolver unavailable")
    Schema.resolver = function() error("boom") end
    expectReject("resolver raises an error", outside .. "/input.lua", "resolver unavailable")
    Schema.resolver = function(p) if p == "/" or p == root then return p end return nil, "simulated failure" end
    expectReject("resolver works for / and the root but fails for the input", outside .. "/input.lua", "simulated failure")
    Schema.resolver = function(p) if p == "/" then return "/" end return nil, "simulated failure" end
    expectReject("resolver cannot resolve the repository root", outside .. "/input.lua", "cannot resolve repository root")
    Schema.resolver = function(p) if p == "/" or p == root then return p end return "relative/answer" end
    expectReject("resolver returns a relative path", outside .. "/input.lua", "no absolute path")
    Schema.resolver = saved

    -- Exit-status regression: GNU realpath prints an absolute path, but an
    -- injected wrapper returns failure (17) after printing it. Lua 5.1
    -- io.popen():close() alone cannot be trusted to expose this failure.
    -- Both CheckInputPath and LoadFile must reject the plausible stdout.
    local realpathBin = readLine("command -v realpath")
    local luaBin = readLine("command -v lua5.1")
    assert(realpathBin and realpathBin:sub(1, 1) == "/" and luaBin and luaBin:sub(1, 1) == "/")
    local fakeDir = outside .. "/fake-realpath-bin"
    assert(sh("mkdir -m 700 " .. q(fakeDir)))
    local wrapper = assert(io.open(fakeDir .. "/realpath", "wb"))
    wrapper:write("#!/bin/sh\n" .. q(realpathBin) .. " \"$@\"\n" ..
        "realpath_rc=$?\n" ..
        "if [ \"$3\" = \"$NQ_REALPATH_FAIL_TARGET\" ]; then\n" ..
        "  : > \"$NQ_REALPATH_TRIGGER_MARKER\"\n" ..
        "  exit 17\n" ..
        "fi\n" ..
        "exit \"$realpath_rc\"\n")
    wrapper:close()
    assert(sh("chmod 700 " .. q(fakeDir .. "/realpath")))
    local probe = outside .. "/resolver-status-probe.lua"
    local probeFile = assert(io.open(probe, "wb"))
    probeFile:write(
        "local S = dofile('tools/validation/InputSchema.lua')\n" ..
        "local ok, msg = S.CheckInputPath(arg[1], '.')\n" ..
        "if ok or not tostring(msg):find('cannot resolve', 1, true) then os.exit(11) end\n" ..
        "if S.LoadFile(arg[1], '.') then os.exit(12) end\n" ..
        "os.exit(0)\n"
    )
    probeFile:close()
    local marker = outside .. "/realpath-nonzero-triggered"
    local command = "PATH=" .. q(fakeDir .. ":" .. (os.getenv("PATH") or "")) ..
        " NQ_REALPATH_FAIL_TARGET=" .. q(outside .. "/input.lua") ..
        " NQ_REALPATH_TRIGGER_MARKER=" .. q(marker) ..
        " " .. q(luaBin) .. " " .. q(probe) .. " " .. q(outside .. "/input.lua") ..
        " >/dev/null 2>&1"
    if sh(command) and sh("test -f " .. q(marker)) then
        pass("nonzero realpath with plausible absolute stdout rejected by path and LoadFile")
    else
        fail("realpath stdout accepted despite subprocess exit 17, or wrapper did not execute")
    end

    -- LoadFile end to end via a symlink outside -> public file
    local doc, errs = Schema.LoadFile(outside .. "/to-public.lua", root)
    if doc then fail("LoadFile accepted a symlink into the public checkout")
    else pass("LoadFile refuses a symlink into the public checkout: " .. errs[1]) end
    doc = Schema.LoadFile(outside .. "/input.lua", root)
    if doc then pass("LoadFile accepts a regular file outside the checkout") else fail("LoadFile refused an outside file") end
end)

cleanup()

-- Repository guard: nothing under private/ may be tracked by git.
if sh("bash tests/check_no_tracked_private.sh") then
    pass("no tracked files under private/, and private/ is gitignored")
else
    fail("files under private/ are tracked by git, or private/ is not gitignored")
end
if sh("bash tests/test_check_no_tracked_private.sh >/dev/null") then
    pass("private/ guard self-test (tracked file and missing ignore are both caught)")
else
    fail("private/ guard self-test failed")
end

if not okRun then fail("test harness error: " .. tostring(err)) end
if failures > 0 then
    io.stderr:write(string.format("FAILED: %d failure(s), %d passed\n", failures, passes))
    os.exit(1)
end
io.stdout:write(string.format("PASS: M2.1 path safety (%d cases)\n", passes))
os.exit(0)
