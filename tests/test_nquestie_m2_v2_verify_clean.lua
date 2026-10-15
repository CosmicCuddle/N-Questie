-- Stage A2: CheckoutState.Check, the clean-checkout gate of NQ_V2_VERIFY_IN.
-- Synthetic git output via an overridden _capture, plus a real temporary git
-- repository (no database needed). Run from the repo root: lua5.1 <file>
local CS = dofile("tools/validation/CheckoutState.lua")
local Prov = dofile("tools/validation/ExportProvenance.lua")
local n, fails = 0, 0
local function ok(c, m) n = n + 1; if c then print("PASS: " .. m) else fails = fails + 1; print("FAIL: " .. m) end end
local function has(errs, s) for _, e in ipairs(errs or {}) do if tostring(e):find(s, 1, true) then return true end end return false end
local function q(s) return "'" .. s:gsub("'", "'\\''") .. "'" end
local C = ("a"):rep(40); local T = ("b"):rep(40)

-- synthetic: a fake provenance module whose _capture answers per command
local function fake(over)
    local ans = { ["rev-parse --show-toplevel"] = { "/r", 0 }, ["realpath"] = { "/r", 0 },
                  ["rev-parse --verify HEAD^{tree}"] = { T, 0 }, ["rev-parse --verify HEAD"] = { C, 0 },
                  ["status --porcelain --untracked-files=all"] = { "", 0 } }
    for k, v in pairs(over or {}) do ans[k] = v end
    local order = { "rev-parse --show-toplevel", "realpath", "rev-parse --verify HEAD^{tree}", "rev-parse --verify HEAD",
                    "status --porcelain --untracked-files=all" }
    return { _capture = function(cmd)
        for _, k in ipairs(order) do if cmd:find(k, 1, true) then return ans[k][1], ans[k][2] end end
        return nil, 1 end }
end
local st, e = CS.Check("/r", fake())
ok(st and st.commit == C and st.tree == T and e == nil, "synthetic clean checkout passes with commit and tree")
local cases = {
    { "untracked file", { ["status --porcelain --untracked-files=all"] = { "?? new.txt", 0 } }, "checkout is not clean" },
    { "modified tracked file", { ["status --porcelain --untracked-files=all"] = { " M a.lua", 0 } }, "checkout is not clean" },
    { "staged change", { ["status --porcelain --untracked-files=all"] = { "M  a.lua", 0 } }, "checkout is not clean" },
    { "several entries", { ["status --porcelain --untracked-files=all"] = { "A  x\n?? y", 0 } }, "checkout is not clean" },
    { "git status non-zero exit", { ["status --porcelain --untracked-files=all"] = { "", 128 } }, "cannot read git status" },
    { "git status no output at all", { ["status --porcelain --untracked-files=all"] = { nil, 0 } }, "cannot read git status" },
    { "git status unexpected output", { ["status --porcelain --untracked-files=all"] = { "fatal: index file corrupt", 0 } }, "unexpected output" },
    { "HEAD unreadable", { ["rev-parse --verify HEAD"] = { "", 128 } }, "cannot read HEAD commit" },
    { "HEAD not a full sha", { ["rev-parse --verify HEAD"] = { "abc", 0 } }, "cannot read HEAD commit" },
    { "tree unreadable", { ["rev-parse --verify HEAD^{tree}"] = { "", 1 } }, "cannot read HEAD tree" },
    { "not a git checkout", { ["rev-parse --show-toplevel"] = { "", 128 } }, "not a git checkout" },
    { "root is not the top level", { ["realpath"] = { "/elsewhere", 0 } }, "is not the git top level" },
}
for _, c in ipairs(cases) do
    local s2, e2 = CS.Check("/r", fake(c[2]))
    ok(s2 == nil and has(e2, c[3]) and has(e2, "provenance: "), "synthetic " .. c[1] .. " fails closed (" .. table.concat(e2 or {}, "; ") .. ")")
end
local s3, e3 = CS.Check("relative", fake())
ok(s3 == nil and has(e3, "not a git checkout"), "relative root refused")
-- messages are the ExportProvenance ones (same codes/wording)
local src = io.open("tools/validation/ExportProvenance.lua"):read("*a")
for _, m in ipairs({ "cannot read git status", "checkout is not clean (commit or stash changes before exporting)",
                     "not a git checkout (or git unavailable)", "status --porcelain --untracked-files=all" }) do
    ok(src:find(m, 1, true) ~= nil, "same wording as ExportProvenance: " .. m)
end

-- real git: a temporary repository
local function cap(cmd) local h = io.popen(cmd); local o = h:read("*a"); h:close(); return (o:gsub("\n$", "")) end
local R = cap("mktemp -d"); cap("chmod 700 " .. q(R)); R = cap("realpath -e -- " .. q(R))
local function sh(c) return os.execute("cd " .. q(R) .. " && " .. c .. " >/dev/null 2>&1") == 0 end
ok(sh("git init -q . && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init && printf a >a.txt && git add a.txt && git -c user.name=t -c user.email=t@t commit -q -m a"),
    "temporary repository created")
local function check() return CS.Check(R, Prov) end
local r1 = check()
ok(r1 and #r1.commit == 40 and r1.commit == cap("git -C " .. q(R) .. " rev-parse HEAD"), "real clean checkout passes")
sh("printf x >untracked.txt"); local r2, e2 = check()
ok(r2 == nil and has(e2, "checkout is not clean"), "real untracked file fails"); sh("rm untracked.txt")
sh("printf b >a.txt"); local r3, e3b = check()
ok(r3 == nil and has(e3b, "checkout is not clean"), "real modified tracked file fails")
sh("git add a.txt"); local r4, e4 = check()
ok(r4 == nil and has(e4, "checkout is not clean"), "real staged change fails"); sh("git reset -q --hard")
ok(check() ~= nil, "clean again after reset")
sh("cp .git/index .git/idx.bak; printf garbage >.git/index"); local r5, e5 = check()
ok(r5 == nil and has(e5, "cannot read git status"), "real git status failure (corrupt index) fails closed")
sh("cp .git/idx.bak .git/index"); ok(check() ~= nil, "clean again after restoring the index")
os.execute("rm -rf " .. q(R))
print((fails == 0 and "PASS" or "FAIL") .. ": M2 v2 verify clean-checkout gate (" .. n .. " checks" .. (fails > 0 and (", " .. fails .. " failed") or "") .. ")")
os.exit(fails == 0 and 0 or 1)
