-- N-Questie M2.2 Step 2: pure snapshot of effective Questie quest records.
--
-- Turns records read from the COMPILED 3.3.5a Questie database (after the
-- normal correction pipeline) into nq-m2-effective v1 quest records.
--
-- Pure: no file or process I/O. The caller passes a query function, usually
-- QuestieDB.QueryQuestSingle from cli/validate-335.lua after compilation.
-- Only an explicit list of quest IDs is exported; there is no "all" mode.
-- Values returned by the query are copied, never modified.
--
-- v1 cannot represent every real Questie objective. Records with such
-- content are REFUSED (whole export fails), never trimmed or reinterpreted:
--   * reputation objectives (objectives[4])
--   * the same id twice in one objective list (objectives[1..3], [6])
--   * extraObjectives references other than items (e.g. "monster")
--   * any objective entry or list shape not listed below
-- Display text (objective text, triggerEnd text/coordinates, extraObjectives
-- text/coordinates) is outside v1 by design and is not exported.
--
-- Lua 5.1 compatible.

local M = {}

M.MAX_SELECTION = 20000
M.MAX_ID = 2147483647

local function isInt(v) return type(v) == "number" and v == math.floor(v) and v == v end

-- Validate an explicit selection. Returns sorted-as-given copy or nil, errors.
function M.CheckSelection(ids)
    local errors = {}
    if type(ids) ~= "table" then return nil, { "selection: must be a list of quest IDs" } end
    local n = 0
    for k in pairs(ids) do
        n = n + 1
        if not isInt(k) or k < 1 then errors[#errors + 1] = "selection: must be a list; found key " .. tostring(k) end
    end
    if n ~= #ids then errors[#errors + 1] = "selection: list has holes" end
    if n == 0 then errors[#errors + 1] = "selection: empty (an explicit quest ID list is required)" end
    if n > M.MAX_SELECTION then errors[#errors + 1] = "selection: more than " .. M.MAX_SELECTION .. " IDs" end
    local seen, out = {}, {}
    for i, id in ipairs(ids) do
        if not isInt(id) or id < 1 or id > M.MAX_ID then
            errors[#errors + 1] = "selection[" .. i .. "]: invalid quest ID " .. tostring(id)
        elseif seen[id] then
            errors[#errors + 1] = "selection[" .. i .. "]: duplicate quest ID " .. id
        else
            seen[id] = true
            out[#out + 1] = id
        end
    end
    if #errors > 0 then return nil, errors end
    return out
end

-- Parse "1203,2001 98" style text into a list (for the CLI/env option).
function M.ParseIdList(text)
    if type(text) ~= "string" or text == "" then return nil, { "selection: empty" } end
    local ids, errors = {}, {}
    for tok in text:gmatch("[^,%s]+") do
        if tok:match("^%d+$") then ids[#ids + 1] = tonumber(tok)
        else errors[#errors + 1] = "selection: not a quest ID: " .. tok end
    end
    if #errors > 0 then return nil, errors end
    return ids
end

-- Read one objective list (creatures/objects/items/spells): entries {id} or {id, text}.
local function idEntries(list, where, err)
    local out, seen = {}, {}
    if list == nil then return out end
    if type(list) ~= "table" then err(where .. ": not a table") return out end
    local n = 0
    for _ in pairs(list) do n = n + 1 end
    if n ~= #list then err(where .. ": unusual shape (not a plain list)") end
    for i, e in ipairs(list) do
        if type(e) ~= "table" or not isInt(e[1]) or e[1] < 1 then
            err(where .. "[" .. i .. "]: unusual entry shape")
        else
            for k, v in pairs(e) do
                if not (k == 1 or (k == 2 and type(v) == "string")) then
                    err(where .. "[" .. i .. "]: unusual entry field " .. tostring(k))
                end
            end
            if seen[e[1]] then
                err(where .. ": id " .. e[1] .. " appears more than once (v1 cannot represent duplicates)")
            end
            seen[e[1]] = true
            out[#out + 1] = e[1]
        end
    end
    return out
end

local function plainIds(list, where, err)
    local out = {}
    if list == nil then return out end
    if type(list) ~= "table" then err(where .. ": not a table") return out end
    local n, seen = 0, {}
    for _ in pairs(list) do n = n + 1 end
    if n ~= #list then err(where .. ": unusual shape (not a plain list)") end
    for i, id in ipairs(list) do
        if not isInt(id) or id < 1 then err(where .. "[" .. i .. "]: not a positive id")
        elseif seen[id] then err(where .. ": id " .. id .. " appears more than once (v1 cannot represent duplicates)")
        else seen[id] = true; out[#out + 1] = id end
    end
    return out
end

-- Build one nq-m2-effective v1 record from query(id, key).
function M.Record(query, id)
    local errors = {}
    local function err(msg) errors[#errors + 1] = "quest " .. id .. ": " .. msg end
    local function q(key)
        local ok, v = pcall(query, id, key)
        if not ok then err("query for " .. key .. " failed: " .. tostring(v)) return nil end
        return v
    end

    local rl, ql = q("requiredLevel"), q("questLevel")
    local obj = q("objectives")
    local src, rsi = q("sourceItemId"), q("requiredSourceItems")
    local trig, extra = q("triggerEnd"), q("extraObjectives")

    local rec = { ID = id }
    if not isInt(rl) then err("requiredLevel is " .. tostring(rl)) end
    if not isInt(ql) then err("questLevel is " .. tostring(ql)) end
    rec.requiredLevel, rec.questLevel = rl, ql

    if src == nil then src = 0 end
    if not isInt(src) or src < 0 then err("sourceItemId is " .. tostring(src)) end
    rec.sourceItemId = src
    rec.requiredSourceItems = plainIds(rsi, "requiredSourceItems", err)

    local o = { creatures = {}, objects = {}, items = {}, killCredit = {}, spells = {} }
    if obj ~= nil and type(obj) ~= "table" then
        err("objectives is not a table")
    elseif type(obj) == "table" then
        for k in pairs(obj) do
            if not isInt(k) or k < 1 or k > 6 then err("objectives has unusual slot " .. tostring(k)) end
        end
        o.creatures = idEntries(obj[1], "objectives[1] creatures", err)
        o.objects = idEntries(obj[2], "objectives[2] objects", err)
        o.items = idEntries(obj[3], "objectives[3] items", err)
        if obj[4] ~= nil and not (type(obj[4]) == "table" and next(obj[4]) == nil) then
            err("objectives[4] reputation objective present (v1 cannot represent reputation)")
        end
        if obj[5] ~= nil then
            if type(obj[5]) ~= "table" then err("objectives[5] killCredit is not a table")
            else
                local n = 0
                for _ in pairs(obj[5]) do n = n + 1 end
                if n ~= #obj[5] then err("objectives[5] killCredit: unusual shape") end
                for i, e in ipairs(obj[5]) do
                    local w = "objectives[5] killCredit[" .. i .. "]"
                    if type(e) ~= "table" or type(e[1]) ~= "table" or not isInt(e[2]) or e[2] < 1 then
                        err(w .. ": unusual shape (expected {{ids}, rootId, text})")
                    else
                        for k, v in pairs(e) do
                            if not (k == 1 or k == 2 or (k == 3 and type(v) == "string")) then
                                err(w .. ": unusual field " .. tostring(k))
                            end
                        end
                        local ids = plainIds(e[1], w .. ".ids", err)
                        if #ids == 0 then err(w .. ": empty ids") end
                        o.killCredit[#o.killCredit + 1] = { ids = ids, rootId = e[2] }
                    end
                end
            end
        end
        o.spells = idEntries(obj[6], "objectives[6] spells", err)
    end
    rec.objectives = o

    rec.hasTriggerEnd = trig ~= nil
    if trig ~= nil and type(trig) ~= "table" then err("triggerEnd has unusual shape") end

    rec.hasExtraObjectives = false
    rec.extraObjectiveItems = {}
    if extra ~= nil then
        if type(extra) ~= "table" then err("extraObjectives is not a table")
        elseif next(extra) ~= nil then
            rec.hasExtraObjectives = true
            local seen = {}
            for i, e in ipairs(extra) do
                if type(e) ~= "table" then err("extraObjectives[" .. i .. "]: unusual shape")
                elseif e[5] ~= nil then
                    if type(e[5]) ~= "table" then err("extraObjectives[" .. i .. "][5]: unusual shape") else
                        for j, ref in ipairs(e[5]) do
                            if type(ref) ~= "table" or not isInt(ref[2]) then
                                err("extraObjectives[" .. i .. "] ref " .. j .. ": unusual shape")
                            elseif ref[1] ~= "item" then
                                err("extraObjectives[" .. i .. "] ref " .. j .. " is '" .. tostring(ref[1]) ..
                                    "' (v1 can only represent item references)")
                            elseif seen[ref[2]] then
                                err("extraObjectives item " .. ref[2] .. " referenced more than once (v1 cannot represent duplicates)")
                            else
                                seen[ref[2]] = true
                                rec.extraObjectiveItems[#rec.extraObjectiveItems + 1] = ref[2]
                            end
                        end
                    end
                end
            end
        end
    end

    if #errors > 0 then return nil, errors end
    return rec
end

-- Snapshot an explicit selection. exists(id) must return true only for quests
-- present in the compiled DB. Returns list of records or nil, errors. Any
-- error refuses the whole snapshot.
function M.Snapshot(query, exists, ids)
    local sel, serr = M.CheckSelection(ids)
    if not sel then return nil, serr end
    if type(query) ~= "function" or type(exists) ~= "function" then
        return nil, { "snapshot: query and exists functions are required" }
    end
    local out, errors = {}, {}
    for _, id in ipairs(sel) do
        if not exists(id) then
            errors[#errors + 1] = "quest " .. id .. ": not in the compiled Questie database"
        else
            local rec, rerr = M.Record(query, id)
            if rec then out[#out + 1] = rec
            else for _, e in ipairs(rerr) do errors[#errors + 1] = e end end
        end
    end
    if #errors > 0 then return nil, errors end
    return out
end

-- Deterministic serialisation as a Lua data literal readable by the M2.1
-- data-only parser (strings escaped without \<newline> forms).
local function serStr(s)
    return '"' .. s:gsub('[%c"\\]', function(c)
        if c == "\\" then return "\\\\" end
        if c == '"' then return '\\"' end
        if c == "\n" then return "\\n" end
        if c == "\t" then return "\\t" end
        if c == "\r" then return "\\r" end
        return string.format("\\%03d", c:byte())
    end) .. '"'
end

local function ser(v, indent, out)
    local t = type(v)
    if t == "number" then
        if not isInt(v) then error("serialise: non-integer number " .. tostring(v)) end
        out[#out + 1] = string.format("%d", v)
    elseif t == "string" then out[#out + 1] = serStr(v)
    elseif t == "boolean" then out[#out + 1] = tostring(v)
    elseif t == "table" then
        local n = #v
        local keys = {}
        for k in pairs(v) do
            if not (isInt(k) and k >= 1 and k <= n) then keys[#keys + 1] = k end
        end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        if n == 0 and #keys == 0 then out[#out + 1] = "{}" return end
        local pad = string.rep("    ", indent + 1)
        out[#out + 1] = "{\n"
        for i = 1, n do
            out[#out + 1] = pad; ser(v[i], indent + 1, out); out[#out + 1] = ",\n"
        end
        for _, k in ipairs(keys) do
            if type(k) ~= "string" or not k:match("^[%a_][%w_]*$") then error("serialise: unsupported key " .. tostring(k)) end
            out[#out + 1] = pad .. k .. " = "; ser(v[k], indent + 1, out); out[#out + 1] = ",\n"
        end
        out[#out + 1] = string.rep("    ", indent) .. "}"
    else
        error("serialise: unsupported type " .. t)
    end
end

function M.Serialize(doc, header)
    local out = {}
    if header then
        for line in (header .. "\n"):gmatch("([^\n]*)\n") do out[#out + 1] = "-- " .. line .. "\n" end
    end
    out[#out + 1] = "return "
    ser(doc, 0, out)
    out[#out + 1] = "\n"
    return table.concat(out)
end

function M.BuildDocument(records, provenance)
    return { schema = "nq-m2-effective", schemaVersion = 1, provenance = provenance, quests = records }
end

return M
