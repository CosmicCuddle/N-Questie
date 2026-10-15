-- N-Questie M2 Stage A1: in-process guard that detects any attempt to write
-- or touch the filesystem or start a process while a read-only mode runs.
--
-- Install() wraps io.open (write/append/update modes), io.tmpfile (creates
-- a writable temporary file), io.output with an argument; io.lines/io.input
-- are left alone (read-only). It also wraps os.rename,
-- os.remove, os.tmpname, os.execute and io.popen (a shell can write
-- anything, so ANY call counts). The wrapped call is BLOCKED (it raises an
-- error) and counted. Remove() restores the originals and returns the count
-- and the kinds seen. Read-mode io.open is passed through.
-- Lua 5.1 compatible.

local M = {}

function M.Install(env)
    env = env or { io = io, os = os }
    local saved = {
        open = env.io.open, output = env.io.output, popen = env.io.popen,
        tmpfile = env.io.tmpfile,
        rename = env.os.rename, remove = env.os.remove, tmpname = env.os.tmpname, execute = env.os.execute,
    }
    local state = { count = 0, kinds = {}, env = env, saved = saved }
    local function block(kind)
        state.count = state.count + 1
        state.kinds[kind] = (state.kinds[kind] or 0) + 1
        error("NoWriteGuard: " .. kind .. " blocked in a read-only mode", 3)
    end
    env.io.open = function(path, mode)
        local m = mode or "r"
        if m:find("[wa+]") then block("io.open:" .. m) end
        return saved.open(path, mode)
    end
    env.io.output = function(f)
        if f ~= nil then block("io.output") end
        return saved.output()
    end
    env.io.popen = function() block("io.popen") end
    env.io.tmpfile = function() block("io.tmpfile") end
    env.os.rename = function() block("os.rename") end
    env.os.remove = function() block("os.remove") end
    env.os.tmpname = function() block("os.tmpname") end
    env.os.execute = function() block("os.execute") end
    return state
end

function M.Remove(state)
    local env, s = state.env, state.saved
    env.io.open, env.io.output, env.io.popen, env.io.tmpfile = s.open, s.output, s.popen, s.tmpfile
    env.os.rename, env.os.remove, env.os.tmpname, env.os.execute = s.rename, s.remove, s.tmpname, s.execute
    return state.count, state.kinds
end

return M
