-- N-Questie Stage A2: read-only checkout state for NQ_V2_VERIFY_IN.
-- Reuses ExportProvenance's capture helper, git command and error messages
-- (ExportProvenance.lua itself is frozen and sha256-pinned). Fails closed:
-- any git failure, non-zero exit or unexpected output is an error, never
-- "clean". Lua 5.1.
local M = {}

local function q(s) return "'" .. s:gsub("'", "'\\''") .. "'" end

-- prov: the ExportProvenance module (its _capture may be overridden in tests).
-- Returns { commit, tree } or nil, errs. Messages use the "provenance: " prefix
-- and wording of ExportProvenance.Collect.
function M.Check(root, prov)
    local errs = {}
    local function err(m) errs[#errs + 1] = "provenance: " .. m end
    local function git(args)
        local out, rc = prov._capture("git -C " .. q(root) .. " " .. args)
        if rc ~= 0 or out == nil then return nil end
        return out
    end
    if type(root) ~= "string" or root:sub(1, 1) ~= "/" then
        err("not a git checkout (or git unavailable)") return nil, errs
    end
    local top = git("rev-parse --show-toplevel")
    if not top then err("not a git checkout (or git unavailable)") return nil, errs end
    local realTop = prov._capture("realpath -e -- " .. q(top))
    if realTop ~= root then err("harness root " .. root .. " is not the git top level " .. tostring(realTop)) end
    local commit = git("rev-parse --verify HEAD")
    local tree = git("rev-parse --verify HEAD^{tree}")
    if not (commit and commit:match("^%x+$") and #commit == 40) then err("cannot read HEAD commit") commit = nil end
    if not (tree and tree:match("^%x+$") and #tree == 40) then err("cannot read HEAD tree") tree = nil end
    local status = git("status --porcelain --untracked-files=all")
    if status == nil then err("cannot read git status")
    elseif status ~= "" then
        -- Anything non-empty is dirty. Lines that are not porcelain v1 entries
        -- are reported as unexpected output; both refuse.
        for line in (status .. "\n"):gmatch("([^\n]*)\n") do
            if line ~= "" and not line:match("^[ MADRCU?!][ MADRCU?!] .") then
                err("cannot read git status (unexpected output)") break
            end
        end
        err("checkout is not clean (commit or stash changes before exporting)")
    end
    if #errs > 0 then return nil, errs end
    return { commit = commit:lower(), tree = tree:lower() }
end

return M
