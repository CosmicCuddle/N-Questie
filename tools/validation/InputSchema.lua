-- N-Questie M2.1: strict input schema and validator for selected server
-- quest objective records (exported privately from acore_world).
--
-- Report-only. This module never writes files, never modifies its input and
-- never generates corrections. Any error rejects the WHOLE input.
--
-- Input is a Lua 5.1 data literal ("return { ... }"). It is parsed by the
-- small data-only parser below, NOT executed: no code, no function calls,
-- no string methods. The parser also rejects duplicate keys, which a normal
-- Lua load would silently overwrite.
--
-- Lua 5.1 compatible.

local M = {}

M.SCHEMA = "nq-m2-input"
M.SCHEMA_VERSION = 1
M.MAX_BYTES = 16 * 1024 * 1024
M.MAX_QUESTS = 20000
M.MAX_ID = 2147483647

local TRI = { [true] = true, [false] = true, unknown = true }

-------------------------------------------------------------------------------
-- Data-only parser
-------------------------------------------------------------------------------

local function parseLiteral(src)
    local pos, len = 1, #src
    local line = 1

    local function fail(msg)
        error({ parse = "line " .. line .. ": " .. msg }, 0)
    end

    local function skip()
        while pos <= len do
            local c = src:sub(pos, pos)
            if c == "\n" then
                line = line + 1; pos = pos + 1
            elseif c == " " or c == "\t" or c == "\r" then
                pos = pos + 1
            elseif src:sub(pos, pos + 1) == "--" then
                if src:sub(pos + 2, pos + 3) == "[[" then
                    local e = src:find("]]", pos + 4, true)
                    if not e then fail("unterminated block comment") end
                    for _ in src:sub(pos, e):gmatch("\n") do line = line + 1 end
                    pos = e + 2
                else
                    local e = src:find("\n", pos, true)
                    pos = e or (len + 1)
                end
            else
                return
            end
        end
    end

    local ESC = { n = "\n", t = "\t", r = "\r", ["\\"] = "\\", ['"'] = '"', ["'"] = "'" }

    local function parseString()
        local q = src:sub(pos, pos)
        pos = pos + 1
        local buf = {}
        while true do
            if pos > len then fail("unterminated string") end
            local c = src:sub(pos, pos)
            if c == q then pos = pos + 1 break end
            if c == "\n" then fail("newline in string") end
            if c == "\\" then
                local n = src:sub(pos + 1, pos + 1)
                if ESC[n] then
                    buf[#buf + 1] = ESC[n]; pos = pos + 2
                elseif n:match("%d") then
                    local d = src:match("^%d%d?%d?", pos + 1)
                    local v = tonumber(d)
                    if v > 255 then fail("bad escape") end
                    buf[#buf + 1] = string.char(v); pos = pos + 1 + #d
                else
                    fail("unsupported escape \\" .. n)
                end
            else
                buf[#buf + 1] = c; pos = pos + 1
            end
        end
        return table.concat(buf)
    end

    local parseValue

    local function parseTable(depth)
        if depth > 8 then fail("tables nested too deeply") end
        pos = pos + 1 -- {
        local t, seen, n = {}, {}, 0
        while true do
            skip()
            local c = src:sub(pos, pos)
            if c == "}" then pos = pos + 1 return t end
            local key
            if c == "[" then
                pos = pos + 1; skip()
                key = parseValue(depth + 1)
                if type(key) == "table" or key == nil or type(key) == "boolean" then fail("invalid table key") end
                skip()
                if src:sub(pos, pos) ~= "]" then fail("expected ]") end
                pos = pos + 1; skip()
                if src:sub(pos, pos) ~= "=" then fail("expected =") end
                pos = pos + 1
            else
                local ident = src:match("^[%a_][%w_]*", pos)
                local after = ident and src:match("^%s*=", pos + #ident)
                if ident and after and src:sub(pos + #ident + #after, pos + #ident + #after) ~= "=" then
                    key = ident
                    pos = pos + #ident + #after
                else
                    n = n + 1
                    key = n
                end
            end
            skip()
            local v = parseValue(depth + 1)
            if seen[key] then fail("duplicate key " .. tostring(key)) end
            seen[key] = true
            if v == nil then fail("nil value for key " .. tostring(key)) end
            t[key] = v
            skip()
            c = src:sub(pos, pos)
            if c == "," or c == ";" then pos = pos + 1
            elseif c ~= "}" then fail("expected , or }") end
        end
    end

    function parseValue(depth)
        skip()
        local c = src:sub(pos, pos)
        if c == "{" then return parseTable(depth) end
        if c == '"' or c == "'" then return parseString() end
        local num = src:match("^%-?%d+%.?%d*[eE]?[%+%-]?%d*", pos)
        if num and num ~= "-" and num ~= "" then
            local v = tonumber(num)
            if not v then fail("bad number " .. num) end
            pos = pos + #num
            return v
        end
        local word = src:match("^[%a_][%w_]*", pos)
        if word == "true" then pos = pos + 4 return true end
        if word == "false" then pos = pos + 5 return false end
        if word == "nil" then pos = pos + 3 return nil end
        fail("unexpected input near '" .. src:sub(pos, pos + 10) .. "' (only data literals are allowed)")
    end

    if src:sub(1, 1) == "\27" then fail("precompiled bytecode is not accepted") end
    skip()
    if src:match("^return[^%w_]", pos) then pos = pos + 6 end
    local v = parseValue(0)
    skip()
    if pos <= len then fail("trailing content after the top-level table") end
    if type(v) ~= "table" then fail("top level must be a table") end
    return v
end

function M.ParseString(src)
    if type(src) ~= "string" then return nil, { "input is not a string" } end
    if #src > M.MAX_BYTES then return nil, { "input larger than " .. M.MAX_BYTES .. " bytes" } end
    local ok, res = pcall(parseLiteral, src)
    if ok then return res end
    if type(res) == "table" and res.parse then return nil, { "parse error: " .. res.parse } end
    return nil, { "parse error: " .. tostring(res) }
end

-------------------------------------------------------------------------------
-- Schema
-------------------------------------------------------------------------------

local QUEST_INT_FIELDS = { "ID", "StartItem" }
for i = 1, 4 do QUEST_INT_FIELDS[#QUEST_INT_FIELDS + 1] = "ItemDrop" .. i end
for i = 1, 4 do
    QUEST_INT_FIELDS[#QUEST_INT_FIELDS + 1] = "RequiredNpcOrGo" .. i
    QUEST_INT_FIELDS[#QUEST_INT_FIELDS + 1] = "RequiredNpcOrGoCount" .. i
end
for i = 1, 6 do
    QUEST_INT_FIELDS[#QUEST_INT_FIELDS + 1] = "RequiredItemId" .. i
    QUEST_INT_FIELDS[#QUEST_INT_FIELDS + 1] = "RequiredItemCount" .. i
end
M.QUEST_INT_FIELDS = QUEST_INT_FIELDS

local QUEST_KEYS = { KillCredit = true, killCreditComplete = true,
    hasConditions = true, ipGated = true, scriptedCredit = true }
for _, f in ipairs(QUEST_INT_FIELDS) do QUEST_KEYS[f] = true end

M.PROVENANCE_FIELDS = {
    exporter = "short name, letters/digits/._-",
    exporterVersion = "semantic version, e.g. 1.0.0",
    sourceLabel = "short non-identifying label, e.g. acore_world-offline",
    sourceFingerprint = "sha256:<64 lowercase hex>",
    exportedAt = "UTC ISO 8601, e.g. 2026-10-14T12:00:00Z",
    selection = "\"explicit\" (quest IDs chosen by a reviewer)",
    questCount = "integer, must equal the number of records",
}

local TOP_KEYS = { schema = true, schemaVersion = true, provenance = true, quests = true }

local function isInt(v) return type(v) == "number" and v == math.floor(v) and v == v end

local function checkProvenance(p, err)
    if type(p) ~= "table" then err("provenance: missing or not a table") return end
    for k in pairs(p) do
        if not M.PROVENANCE_FIELDS[k] then err("provenance." .. tostring(k) .. ": unknown field") end
    end
    local function str(k, pattern, maxLen, what)
        local v = p[k]
        if type(v) ~= "string" then err("provenance." .. k .. ": required string (" .. what .. ")") return end
        if #v > maxLen or not v:match(pattern) then err("provenance." .. k .. ": invalid value (" .. what .. ")") end
    end
    str("exporter", "^[%w][%w%._%-]*$", 64, M.PROVENANCE_FIELDS.exporter)
    str("exporterVersion", "^%d+%.%d+%.%d+[%w%.%-]*$", 32, M.PROVENANCE_FIELDS.exporterVersion)
    str("sourceLabel", "^[%w][%w%._%-]*$", 64, M.PROVENANCE_FIELDS.sourceLabel)
    str("sourceFingerprint", "^sha256:" .. string.rep("[0-9a-f]", 64) .. "$", 71, M.PROVENANCE_FIELDS.sourceFingerprint)
    str("exportedAt", "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ$", 20, M.PROVENANCE_FIELDS.exportedAt)
    if p.selection ~= "explicit" then err("provenance.selection: must be \"explicit\"") end
    if not isInt(p.questCount) or p.questCount < 1 then err("provenance.questCount: required positive integer") end
    if type(p.exportedAt) == "string" then
        local mo, d, h, mi, s = p.exportedAt:match("^%d%d%d%d%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)Z$")
        if mo and (tonumber(mo) < 1 or tonumber(mo) > 12 or tonumber(d) < 1 or tonumber(d) > 31
            or tonumber(h) > 23 or tonumber(mi) > 59 or tonumber(s) > 59) then
            err("provenance.exportedAt: not a valid date/time")
        end
    end
end

local function checkQuest(q, where, err)
    if type(q) ~= "table" then err(where .. ": record is not a table") return end
    for k in pairs(q) do
        if not QUEST_KEYS[k] then err(where .. "." .. tostring(k) .. ": unknown field") end
    end
    for _, f in ipairs(QUEST_INT_FIELDS) do
        local v = q[f]
        if v == nil then err(where .. "." .. f .. ": missing (export 0 for an empty slot)")
        elseif not isInt(v) then err(where .. "." .. f .. ": must be an integer, got " .. tostring(v))
        elseif f:match("^RequiredNpcOrGo%d$") then
            if v < -M.MAX_ID or v > M.MAX_ID then err(where .. "." .. f .. ": out of range") end
        elseif v < 0 or v > M.MAX_ID then
            err(where .. "." .. f .. ": must be between 0 and " .. M.MAX_ID)
        end
    end
    if isInt(q.ID) and q.ID < 1 then err(where .. ".ID: must be positive") end

    -- slot consistency: id and count are both set or both empty
    local function pair(idField, countField)
        local id, count = q[idField], q[countField]
        if not (isInt(id) and isInt(count)) then return end
        if id ~= 0 and count <= 0 then err(where .. "." .. countField .. ": must be > 0 because " .. idField .. " is set") end
        if id == 0 and count ~= 0 then err(where .. "." .. countField .. ": must be 0 because " .. idField .. " is 0") end
    end
    for i = 1, 4 do pair("RequiredNpcOrGo" .. i, "RequiredNpcOrGoCount" .. i) end
    for i = 1, 6 do pair("RequiredItemId" .. i, "RequiredItemCount" .. i) end

    for _, f in ipairs({ "hasConditions", "ipGated", "scriptedCredit" }) do
        local v = q[f]
        if v == nil then err(where .. "." .. f .. ": missing (must be true, false or \"unknown\")")
        elseif not TRI[v] then err(where .. "." .. f .. ": must be true, false or \"unknown\", got " .. tostring(v)) end
    end
    if type(q.killCreditComplete) ~= "boolean" then
        err(where .. ".killCreditComplete: missing or not a boolean")
    end

    local kc = q.KillCredit
    if type(kc) ~= "table" then
        err(where .. ".KillCredit: missing or not a table (use {} when no rows were exported)")
        return
    end
    for creature, credits in pairs(kc) do
        local w = where .. ".KillCredit[" .. tostring(creature) .. "]"
        if not isInt(creature) or creature < 1 or creature > M.MAX_ID then
            err(w .. ": key must be a positive creature id (gameobjects have no KillCredit)")
        elseif type(credits) ~= "table" then
            err(w .. ": must be {credit1, credit2}")
        else
            local n = 0
            for k in pairs(credits) do
                n = n + 1
                if k ~= 1 and k ~= 2 then err(w .. ": only {credit1, credit2} allowed") end
            end
            for i = 1, 2 do
                local c = credits[i]
                if not isInt(c) or c < 0 or c > M.MAX_ID then
                    err(w .. "[" .. i .. "]: must be an integer >= 0 (0 = no credit)")
                end
            end
        end
    end

    -- completeness claim: every server creature target must have a row.
    -- Negative targets are gameobjects and are not looked up.
    if q.killCreditComplete == true then
        for i = 1, 4 do
            local id = q["RequiredNpcOrGo" .. i]
            if isInt(id) and id > 0 and kc[id] == nil then
                err(where .. ".killCreditComplete: true but KillCredit has no row for creature " .. id ..
                    " (RequiredNpcOrGo" .. i .. ")")
            end
        end
    end
end

-- Validate a parsed input table. Returns true, or false plus a list of errors.
-- Never modifies `doc`.
function M.Validate(doc)
    local errors = {}
    local function err(msg) errors[#errors + 1] = msg end
    if type(doc) ~= "table" then return false, { "input: top level must be a table" } end
    for k in pairs(doc) do
        if not TOP_KEYS[k] then err("input." .. tostring(k) .. ": unknown top-level field") end
    end
    if doc.schema ~= M.SCHEMA then err("schema: must be \"" .. M.SCHEMA .. "\"") end
    if doc.schemaVersion ~= M.SCHEMA_VERSION then
        err("schemaVersion: unsupported (" .. tostring(doc.schemaVersion) .. "), this validator accepts " .. M.SCHEMA_VERSION)
    end
    checkProvenance(doc.provenance, err)

    local quests = doc.quests
    if type(quests) ~= "table" then
        err("quests: missing or not a list")
    else
        local n = 0
        for k in pairs(quests) do
            n = n + 1
            if not isInt(k) or k < 1 then err("quests: must be a list; found key " .. tostring(k)) end
        end
        if n ~= #quests then err("quests: list has holes or non-list keys") end
        if n == 0 then err("quests: empty") end
        if n > M.MAX_QUESTS then err("quests: more than " .. M.MAX_QUESTS .. " records") end
        local seen = {}
        for i, q in ipairs(quests) do
            local id = type(q) == "table" and q.ID or nil
            checkQuest(q, "quests[" .. i .. "]" .. (isInt(id) and (" (ID " .. id .. ")") or ""), err)
            if isInt(id) then
                if seen[id] then err("quests[" .. i .. "]: duplicate quest ID " .. id .. " (first at quests[" .. seen[id] .. "])") end
                seen[id] = seen[id] or i
            end
        end
        if type(doc.provenance) == "table" and isInt(doc.provenance.questCount) and doc.provenance.questCount ~= n then
            err("provenance.questCount: " .. doc.provenance.questCount .. " does not match " .. n .. " records")
        end
    end

    if #errors > 0 then return false, errors end
    return true
end

-------------------------------------------------------------------------------
-- Paths
-------------------------------------------------------------------------------

local function normalize(path)
    local parts = {}
    for seg in path:gmatch("[^/]+") do
        if seg == ".." then
            if #parts == 0 then return nil end
            parts[#parts] = nil
        elseif seg ~= "." then
            parts[#parts + 1] = seg
        end
    end
    return "/" .. table.concat(parts, "/")
end

local function realpath(path)
    -- Resolve symlinks when the system realpath is available; fall back to
    -- lexical normalisation. Single quotes are escaped for the shell.
    local ok, h = pcall(io.popen, "realpath -m -- '" .. path:gsub("'", "'\\''") .. "' 2>/dev/null")
    if ok and h then
        local out = h:read("*l")
        h:close()
        if out and out:sub(1, 1) == "/" then return out end
    end
    return normalize(path)
end
M._realpath = realpath

local function under(path, dir)
    return path == dir or path:sub(1, #dir + 1) == dir .. "/"
end

-- Decide whether an input path is acceptable.
-- repoRoot: absolute path of the public checkout.
-- Allowed: absolute paths outside the checkout, or inside it only under
-- private/ (gitignored) or tests/fixtures/m2_input/ (synthetic fixtures).
function M.CheckInputPath(path, repoRoot)
    if type(path) ~= "string" or path == "" then return false, "no input path given (argument or NQ_M2_INPUT)" end
    if path:sub(1, 1) ~= "/" then return false, "input path must be absolute: " .. path end
    local p = realpath(path)
    local root = realpath(repoRoot)
    if not p or not root then return false, "input path could not be normalised" end
    if under(p, root) and not (under(p, root .. "/private") or under(p, root .. "/tests/fixtures/m2_input")) then
        return false, "input path is inside the public checkout; use a path outside it or under private/"
    end
    return true, p
end

-- Read, parse and validate a file. Read-only. Returns doc or nil, errors.
function M.LoadFile(path, repoRoot)
    local ok, resolved = M.CheckInputPath(path, repoRoot)
    if not ok then return nil, { resolved } end
    local f, e = io.open(resolved, "rb")
    if not f then return nil, { "cannot open input: " .. tostring(e) } end
    local src = f:read(M.MAX_BYTES + 1)
    f:close()
    if src and #src > M.MAX_BYTES then return nil, { "input larger than " .. M.MAX_BYTES .. " bytes" } end
    local doc, perrs = M.ParseString(src or "")
    if not doc then return nil, perrs end
    local valid, errs = M.Validate(doc)
    if not valid then return nil, errs end
    return doc
end

return M
