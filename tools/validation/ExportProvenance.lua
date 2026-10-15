-- N-Questie M2.2 Step 3: provenance for effective exports, derived from the
-- actual checkout and loaded data. Never from caller claims. Any value that
-- cannot be established makes Collect() fail (no export).
-- Linux + git + GNU coreutils (sha256sum). Lua 5.1.
local M = {}

local function q(s) return "'" .. s:gsub("'", "'\\''") .. "'" end
local function capture(cmd)
    local h = io.popen(cmd .. " 2>/dev/null; echo \"__rc=$?\"")
    if not h then return nil, 1 end
    local out = h:read("*a") or ""
    h:close()
    local body, rc = out:match("^(.-)\n?__rc=(%d+)\n?$")
    return body, tonumber(rc)
end
M._capture = capture -- overridable in tests

local function git(root, args)
    local out, rc = M._capture("git -C " .. q(root) .. " " .. args)
    if rc ~= 0 then return nil end
    return out
end

-- modules: list of repo-relative paths like "Compat/NQuestieX.lua", TOC order.
-- facts: { revision, correctionCount, expectedCorrectionCount, m0Checks,
--          tocInterface, buildInterface, harnessVersion }
function M.Collect(root, modules, facts)
    local errs = {}
    local function err(m) errs[#errs + 1] = "provenance: " .. m end
    local p = { harness = "validate-335", harnessVersion = facts.harnessVersion, dataKind = "effective",
                tocInterface = facts.tocInterface, flavour = "wotlk-335", sourceDirty = true }

    local top = git(root, "rev-parse --show-toplevel")
    if not top then err("not a git checkout (or git unavailable)") return nil, errs end
    local realTop, realRc = M._capture("realpath -e -- " .. q(top))
    if realRc ~= 0 or realTop ~= root then
        err("cannot verify that the harness root is the git top level")
    end
    local commit = git(root, "rev-parse --verify HEAD")
    local tree = git(root, "rev-parse --verify HEAD^{tree}")
    if not (commit and commit:match("^%x+$") and #commit == 40) then err("cannot read HEAD commit") else p.sourceCommit = commit:lower() end
    if not (tree and tree:match("^%x+$") and #tree == 40) then err("cannot read HEAD tree") else p.sourceTree = tree:lower() end
    local status = git(root, "status --porcelain --untracked-files=all")
    if status == nil then err("cannot read git status")
    elseif status ~= "" then err("checkout is not clean (commit or stash changes before exporting)")
    else p.sourceDirty = false end

    if facts.tocInterface ~= 30300 or facts.buildInterface ~= 30300 then
        err("TOC/build interface is not 30300 (got " .. tostring(facts.tocInterface) .. "/" .. tostring(facts.buildInterface) .. ")")
    end
    if type(facts.revision) ~= "number" or facts.revision < 1 or facts.revision ~= math.floor(facts.revision) then
        err("NQuestieCustomQuestData.revision not loaded or not a positive integer")
    else p.nQuestieDataRevision = facts.revision end
    if type(facts.correctionCount) ~= "number" or facts.correctionCount < 1 then err("no active corrections counted")
    elseif facts.expectedCorrectionCount ~= facts.correctionCount then
        err("active corrections " .. tostring(facts.correctionCount) .. " do not match NQ_VALIDATE_EXPECT_LEVEL_COUNT " ..
            tostring(facts.expectedCorrectionCount))
    else p.correctionCount = facts.correctionCount end
    if type(facts.m0Checks) ~= "number" or facts.m0Checks < 1 then err("M0 check count missing") else p.m0Checks = facts.m0Checks end

    -- correction modules: tracked, unmodified (clean status), hashed from file content
    p.correctionModules = {}
    local lines = {}
    if type(modules) ~= "table" or #modules == 0 then err("no N-Questie correction modules were loaded") end
    for _, rel in ipairs(modules or {}) do
        local name = rel:match("^Compat/([%w][%w_%-]*%.lua)$")
        if not name then err("unexpected correction module path " .. tostring(rel))
        else
            if not git(root, "ls-files --error-unmatch -- " .. q(rel)) then err(rel .. " is not tracked by git") end
            local sum, hashRc = M._capture("sha256sum -- " .. q(root .. "/" .. rel))
            local hex = hashRc == 0 and sum and sum:match("^(%x+)%s")
            if not hex or #hex ~= 64 then err("cannot hash " .. rel)
            else
                p.correctionModules[#p.correctionModules + 1] = name
                lines[#lines + 1] = name .. " " .. hex:lower()
            end
        end
    end
    if #lines > 0 then
        local parts = {}
        for _, l in ipairs(lines) do parts[#parts + 1] = q(l) end
        local out, fingerprintRc = M._capture("printf '%s\\n' " .. table.concat(parts, " ") .. " | sha256sum")
        local hex = fingerprintRc == 0 and out and out:match("^(%x+)%s")
        if not hex or #hex ~= 64 then err("cannot compute correction fingerprint")
        else p.correctionFingerprint = "sha256:" .. hex:lower() end
    end
    p.exportedAt = os.date("!%Y-%m-%dT%H:%M:%SZ")
    if #errs > 0 then return nil, errs end
    return p
end

return M
