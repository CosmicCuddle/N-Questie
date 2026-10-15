-- M2.3 Part 1: status-checked, bounded stdout capture for trusted commands.
-- Lua 5.1; no shell output, paths or captured data are ever printed here.
-- A caller MUST shell-quote every variable argument before constructing cmd.
-- This helper NEVER treats plausible stdout as success without an exit code.
local M = {}
M.MAX_BYTES = 1024 * 1024
local MARK = "__NQ_M23_CAPTURE_STATUS__="

function M.Run(cmd)
    if type(cmd) ~= "string" or cmd == "" or cmd:find("[%z\r\n]") then
        return nil, nil
    end

    -- Keep the command in a subshell so 'exit 17' cannot suppress our marker.
    -- The status marker is emitted by our outer shell after the command exits.
    -- Do not rely on io.popen():close() to return the child exit status in 5.1.
    local wrapper = "(" .. cmd .. ") 2>/dev/null; __nq_m23_rc=$?; "
        .. "printf '\\n" .. MARK .. "%s\\n' \"$__nq_m23_rc\""
    local handle = io.popen(wrapper, "r")
    if not handle then return nil, nil end

    local readOK, captured = pcall(function() return handle:read(M.MAX_BYTES + 1) end)
    local closeOK, closeResult = pcall(function() return handle:close() end)
    if not readOK or type(captured) ~= "string"
        or #captured > M.MAX_BYTES or not closeOK or not closeResult then
        return nil, nil
    end

    local body, digits = captured:match("^(.-)\n" .. MARK .. "(%d+)\n$")
    if not body or not digits or body:find(MARK, 1, true) then
        -- No marker, malformed marker, or forged marker in command output.
        return nil, nil
    end
    local rc = tonumber(digits)
    if not rc or rc < 0 or rc > 255 or rc ~= math.floor(rc) then return nil, nil end
    if rc ~= 0 then return nil, rc end
    return body, 0
end

return M
