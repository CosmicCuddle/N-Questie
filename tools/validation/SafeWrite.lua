-- N-Questie M2.2 Step 4: safe writer for private validation outputs.
-- Shared by the M2.2 effective export and, later, the M2.3 reports.
--
-- Rules (any failure rejects; nothing is guessed from path text):
--   * absolute path, no . or .. segments, no control characters, plain file name
--   * the destination DIRECTORY must exist and resolve with `realpath -e`
--     to a location outside the public checkout, or under <checkout>/private/
--   * that directory must be owned by the current user, be a real directory
--     and have no group/other permissions (mode 0700 or stricter)
--   * an existing final path that is a symlink is always refused
--   * data is written to a new temp file created by `mktemp` in the same
--     directory (exclusive create, mode 0600), read back and compared
--   * install without --force uses link(2) via `ln` (no -f), which fails if
--     the final name exists: a real no-clobber install. The temp name is then
--     removed. With --force, rename(2) via `mv -fT` replaces the file
--     atomically, so readers see the old or the new file, never a partial one
--   * after install the final file is re-checked (location, owner, mode 0600,
--     content); on any failure the temp file is removed and an existing final
--     file is left untouched
-- Remaining races are documented in docs/NQ-VALIDATION-M2.2-SAFE-WRITER.md.
--
-- Linux with GNU coreutils only (realpath, mktemp, stat, ln, mv, id).
-- Lua 5.1 compatible.

local Input = dofile("tools/validation/InputSchema.lua")

local M = {}
M.Input = Input -- resolver is overridable for tests via M.Input.resolver

local function q(s) return "'" .. s:gsub("'", "'\\''") .. "'" end

local function run(cmd)
    local r = os.execute(cmd .. " >/dev/null 2>&1")
    return r == 0 or r == true
end

local function capture(cmd)
    -- Lua 5.1 io.popen():close() can succeed even if the child command exits
    -- nonzero. Never treat stat/id/mktemp stdout as successful unless the
    -- original command itself returned status 0. In particular, a failed
    -- mktemp that prints a plausible name must not become io.open(...,"wb").
    -- A marker emitted by the parent shell AFTER the child has exited is
    -- anchored at the end, so an earlier stdout line cannot forge success.
    local shell = "( " .. cmd .. " ) 2>/dev/null; " ..
        "nq_safe_status=$?; printf '\\nNQ_SAFEWRITE_EXIT:%s\\n' \"$nq_safe_status\""
    local ok, h = pcall(io.popen, shell)
    if not ok or not h then return nil end
    local out = h:read("*a")
    h:close()
    if type(out) ~= "string" then return nil end
    local data, status = out:match("^(.*)\nNQ_SAFEWRITE_EXIT:(%d+)\n$")
    if status ~= "0" then return nil end
    return data and data:match("^(.-)\n?$")
end

local function resolve(path)
    local ok, res = pcall(Input.resolver, path)
    if not ok or type(res) ~= "string" or res:sub(1, 1) ~= "/" then return nil end
    return res
end

local function under(path, dir) return path == dir or path:sub(1, #dir + 1) == dir .. "/" end

local function readAll(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

-- stat -c '%u %a %F' without following a final symlink
local function statInfo(path)
    local out = capture("stat -c '%u %a %F' -- " .. q(path))
    if not out then return nil end
    local uid, mode, kind = out:match("^(%d+) (%d+) (.+)$")
    if not uid then return nil end
    return { uid = tonumber(uid), mode = tonumber(mode, 8), kind = kind }
end

local function noGroupOther(mode) return mode % 64 == 0 end -- low 6 bits (group+other) zero

-- Check a destination. Returns { dir, final, name } or nil, reason.
function M.CheckDestination(path, repoRoot)
    if type(path) ~= "string" or path == "" then return nil, "no output path given" end
    if path:sub(1, 1) ~= "/" then return nil, "output path must be absolute: " .. path end
    if path:find("[%z\n\r]") then return nil, "output path contains control characters" end
    for seg in path:gmatch("[^/]+") do
        if seg == "." or seg == ".." then return nil, "output path must not contain . or .. segments" end
    end
    local dirText, name = path:match("^(.*)/([^/]+)$")
    if not name or not name:match("^[%w][%w%._%-]*$") or #name > 128 then
        return nil, "output file name must be plain (letters, digits, . _ -)"
    end
    if dirText == "" then dirText = "/" end
    if resolve("/") ~= "/" then return nil, "path resolver unavailable; refusing to write" end
    local root = resolve(repoRoot or "")
    if not root then return nil, "cannot resolve repository root" end
    local dir = resolve(dirText)
    if not dir then return nil, "output directory does not exist or cannot be resolved: " .. dirText end
    if under(dir, root) and not under(dir, root .. "/private") then
        return nil, "output directory resolves inside the public checkout; use a directory outside it or under private/"
    end
    local st = statInfo(dir)
    if not st then return nil, "cannot stat output directory" end
    if st.kind ~= "directory" then return nil, "output directory is not a directory" end
    local uid = tonumber(capture("id -u") or "")
    if not uid or st.uid ~= uid then return nil, "output directory is not owned by the current user" end
    if not noGroupOther(st.mode) then
        return nil, string.format("output directory mode %o allows group/other access; use chmod 700", st.mode)
    end
    return { dir = dir, name = name, final = (dir == "/" and "" or dir) .. "/" .. name, uid = uid }
end

-- hooks (tests only): afterTempCreate(temp), afterWrite(temp), beforeInstall(temp, final)
-- each may return false or raise to simulate a failure.
function M.WriteFile(path, content, opts)
    opts = opts or {}
    local hooks = opts.hooks or {}
    if type(content) ~= "string" then return false, "content must be a string" end
    local dest, why = M.CheckDestination(path, opts.repoRoot)
    if not dest then return false, why end

    local final = dest.final
    local finalStat = statInfo(final)
    if finalStat then
        if finalStat.kind == "symbolic link" then return false, "output path is a symlink; refusing" end
        if not opts.force then return false, "output file exists; pass --force to replace it" end
        if finalStat.kind ~= "regular file" and finalStat.kind ~= "regular empty file" then
            return false, "output path exists and is not a regular file"
        end
    end

    local temp = capture("mktemp -p " .. q(dest.dir) .. " .nq-write.XXXXXXXXXX")
    if not temp or temp:sub(1, #dest.dir + 1) ~= (dest.dir == "/" and "/" or dest.dir .. "/") then
        return false, "cannot create a temporary file in the output directory"
    end
    local function cleanup() run("rm -f -- " .. q(temp)) end
    local function hook(name, ...)
        local h = hooks[name]
        if not h then return true end
        local ok, res = pcall(h, ...)
        return ok and res ~= false
    end

    if not hook("afterTempCreate", temp) then cleanup() return false, "simulated failure after temp create" end
    if not run("chmod 600 -- " .. q(temp)) then cleanup() return false, "cannot set temp file mode" end
    local f = io.open(temp, "wb")
    if not f then cleanup() return false, "cannot open temp file" end
    local okw = f:write(content)
    local okc = f:close()
    if not okw or not okc then cleanup() return false, "write to temp file failed" end
    if not hook("afterWrite", temp) then cleanup() return false, "simulated failure after write" end
    if readAll(temp) ~= content then cleanup() return false, "temp file content check failed" end

    -- Re-verify the directory and temp file before installing.
    if resolve(dest.dir) ~= dest.dir or resolve(temp) ~= temp then
        cleanup() return false, "output directory changed during the write; refusing"
    end
    local tst = statInfo(temp)
    if not tst or tst.kind ~= "regular file" or tst.uid ~= dest.uid or tst.mode ~= tonumber("600", 8) then
        cleanup() return false, "temp file is not a private regular file"
    end
    if not hook("beforeInstall", temp, final) then cleanup() return false, "simulated failure before install" end

    local installed
    if opts.force then
        local cur = statInfo(final)
        if cur and cur.kind == "symbolic link" then cleanup() return false, "output path became a symlink; refusing" end
        installed = run("mv -fT -- " .. q(temp) .. " " .. q(final))
    else
        installed = run("ln -T -- " .. q(temp) .. " " .. q(final))
        if installed then run("rm -f -- " .. q(temp)) end
    end
    if not installed then
        cleanup()
        return false, opts.force and "atomic replace failed" or "output file exists (no-clobber install refused) or link failed"
    end

    -- Post-install verification.
    local fst = statInfo(final)
    if resolve(final) ~= final or not fst or fst.kind ~= "regular file" or fst.uid ~= dest.uid
       or fst.mode ~= tonumber("600", 8) or readAll(final) ~= content then
        return false, "post-install check failed for " .. final .. " (file left in place for inspection)"
    end
    return true, final
end

return M
