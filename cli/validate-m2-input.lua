#!/usr/bin/env lua5.1
-- N-Questie M2.1: validate a selected-quest input file (read-only).
-- Usage: lua5.1 cli/validate-m2-input.lua [absolute-path]
--        or set NQ_M2_INPUT to an absolute path.
-- Never writes files. Never modifies the input. Exit 0 only when the whole
-- document is valid; any error rejects the whole input (exit 1).

local Schema = dofile("tools/validation/InputSchema.lua")

local function repoRoot()
    local src = debug.getinfo(1, "S").source
    if src:sub(1, 1) == "@" then
        local dir = src:sub(2):match("(.+)/")
        if dir then
            local h = io.popen("cd '" .. dir:gsub("'", "'\\''") .. "/..' && pwd")
            local out = h and h:read("*l")
            if h then h:close() end
            if out and out ~= "" then return out end
        end
    end
    return "."
end

local path = arg[1] or os.getenv("NQ_M2_INPUT")
local doc, errs = Schema.LoadFile(path or "", repoRoot())
if not doc then
    io.stderr:write("REJECT: whole input refused (" .. #errs .. " error" .. (#errs == 1 and "" or "s") .. ")\n")
    for i, e in ipairs(errs) do io.stderr:write(string.format("  %d. %s\n", i, e)) end
    os.exit(1)
end
io.stdout:write(string.format(
    "OK: %d quest record(s), schema %s v%d, exporter %s %s, source %s\n",
    #doc.quests, doc.schema, doc.schemaVersion,
    doc.provenance.exporter, doc.provenance.exporterVersion, doc.provenance.sourceLabel))
os.exit(0)
