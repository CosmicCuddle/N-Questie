#!/usr/bin/env lua5.1
-- M2.2 Step 3 provenance tests. Real checkout values plus simulated failures
-- through the overridable command runner (no repository changes).
local P = dofile("tools/validation/ExportProvenance.lua")
local failures, passes = 0, 0
local function check(c, m) if c then passes = passes + 1; print("PASS: " .. m) else failures = failures + 1; io.stderr:write("FAIL: " .. m .. "\n") end end
local function has(errs, s) return table.concat(errs or {}, " | "):find(s, 1, true) ~= nil end
local root = io.popen("pwd -P"):read("*l")
local MODS = { "Compat/NQuestieCustomQuestData.lua", "Compat/NQuestieExistingQuestCorrections.lua" }
local function facts(o)
    local f = { revision = 5, correctionCount = 28, expectedCorrectionCount = 28, m0Checks = 232,
                tocInterface = 30300, buildInterface = 30300, harnessVersion = "1.1.0" }
    for k, v in pairs(o or {}) do f[k] = v end
    return f
end
local real = P._capture
local clean = (real("git -C '" .. root .. "' status --porcelain --untracked-files=all")) == ""

-- Pretend status is clean so the remaining fields can be tested on a dirty dev tree too.
local function withStatus(out)
    return function(cmd)
        if cmd:find("status %-%-porcelain") then return out, 0 end
        return real(cmd)
    end
end
P._capture = withStatus("")
local p, e = P.Collect(root, MODS, facts())
check(p ~= nil, "collects provenance from the checkout" .. (e and (": " .. table.concat(e, "; ")) or ""))
if p then
    check(p.sourceCommit == real("git rev-parse HEAD"), "commit from git")
    check(#p.sourceTree == 40, "tree hash from git")
    check(p.correctionFingerprint:match("^sha256:%x+$") and #p.correctionFingerprint == 71, "fingerprint computed from files")
    check(p.correctionModules[1] == "NQuestieCustomQuestData.lua" and #p.correctionModules == 2, "module names from the loaded list")
    local p2 = P.Collect(root, { MODS[2], MODS[1] }, facts())
    check(p2 and p2.correctionFingerprint ~= p.correctionFingerprint, "fingerprint depends on module order")
end
P._capture = withStatus(" M cli/validate-335.lua")
p, e = P.Collect(root, MODS, facts()); check(not p and has(e, "not clean"), "dirty checkout refused")
P._capture = withStatus("?? new.txt")
p, e = P.Collect(root, MODS, facts()); check(not p and has(e, "not clean"), "untracked file refused")
P._capture = function() return "", 128 end
p, e = P.Collect(root, MODS, facts()); check(not p and has(e, "not a git checkout"), "git unavailable refused")
P._capture = function(cmd) if cmd:find("sha256sum") then return "", 1 end return withStatus("")(cmd) end
p, e = P.Collect(root, MODS, facts()); check(not p and has(e, "cannot hash"), "hash failure refused")

-- Valid-looking stdout does not override the actual nonzero subprocess exit.
-- Lua 5.1 pclose success alone is insufficient; _capture already records rc.
P._capture = function(cmd)
    if cmd:find("realpath %-e") then return root, 17 end
    return withStatus("")(cmd)
end
p, e = P.Collect(root, MODS, facts())
check(not p and has(e, "cannot verify that the harness root"), "realpath stdout with exit 17 refused")

P._capture = function(cmd)
    local stdout, rc = withStatus("")(cmd)
    if cmd:find("sha256sum %-%-") then return stdout, 17 end
    return stdout, rc
end
p, e = P.Collect(root, MODS, facts())
check(not p and has(e, "cannot hash"), "valid-looking module sha256sum stdout with exit 17 refused")

P._capture = function(cmd)
    local stdout, rc = withStatus("")(cmd)
    if cmd:find("| sha256sum", 1, true) then return stdout, 17 end
    return stdout, rc
end
p, e = P.Collect(root, MODS, facts())
check(not p and has(e, "cannot compute correction fingerprint"),
    "valid-looking correction fingerprint stdout with exit 17 refused")

P._capture = withStatus("")
for _, c in ipairs({
    { "missing revision", { revision = false }, "revision not loaded" },
    { "zero revision", { revision = 0 }, "revision not loaded" },
    { "count mismatch", { expectedCorrectionCount = 27 }, "do not match" },
    { "no corrections", { correctionCount = 0 }, "no active corrections" },
    { "no M0 count", { m0Checks = 0 }, "M0 check count missing" },
    { "wrong TOC", { tocInterface = 30400 }, "not 30300" },
    { "wrong build", { buildInterface = 11200 }, "not 30300" },
}) do
    local f = facts(c[2]); if f.revision == false then f.revision = nil end
    p, e = P.Collect(root, MODS, f); check(not p and has(e, c[3]), c[1] .. " refused")
end
p, e = P.Collect(root, {}, facts()); check(not p and has(e, "no N-Questie correction modules"), "empty module list refused")
p, e = P.Collect(root, { "Compat/../x.lua" }, facts()); check(not p and has(e, "unexpected correction module path"), "odd module path refused")
p, e = P.Collect(root, { "Compat/NQuestieNotTracked.lua" }, facts()); check(not p and has(e, "not tracked"), "untracked module refused")
p = P.Collect("/tmp", MODS, facts()); check(not p, "root that is not the checkout top level refused")
P._capture = real
if clean then
    p = P.Collect(root, MODS, facts()); check(p ~= nil and p.sourceDirty == false, "real clean checkout accepted")
else
    print("NOTE: working tree is dirty; real clean-status check skipped (covered by the integration test)")
end
if failures > 0 then io.stderr:write("FAILED: " .. failures .. "\n") os.exit(1) end
print(string.format("PASS: M2.2 provenance (%d checks)", passes))
