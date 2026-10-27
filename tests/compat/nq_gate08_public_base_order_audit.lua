-- Part39 PUBLIC BASE-ONLY WotLK order compatibility audit.
-- READ-ONLY: do not emit NPC/GO/item/quest identifiers or association values.
-- This does NOT run runtime corrections, faction overrides, private IP sources
-- or a native 3.3.5a client; it cannot approve Stage1 or PR #219.
local modules = {}
QuestieLoader = {
    CreateModule = function(_, name)
        modules[name] = modules[name] or {}
        return modules[name]
    end,
    ImportModule = function(_, name)
        assert(modules[name], "missing public module " .. tostring(name))
        return modules[name]
    end,
}
Questie = {IsWotlk=true, IsTBC=false, IsClassic=false, IsSoD=false}
QuestieCompat = {Is335=true, WOW_PROJECT_ID=2}
local db = QuestieLoader:CreateModule("QuestieDB")

-- Load only real public schema definitions and WotLK base tables. No compiler
-- stage, writes, patches, account data or private server input are involved.
for _,schema in ipairs({"npc", "object", "quest", "item"}) do
    assert(loadfile("Database/" .. schema .. "DB.lua"))()
end

local specs = {
    u12pair = {"pair", 0, 4095},
    u24pair = {"pair", 0, 16777215},
    s24pair = {"pair", -8388608, 8388607},
    u8u16array = {"array", 0, 65535, 255},
    u8s16pairs = {"pairArray", -32767, 32768, 255},
    u16u16array = {"array", 0, 65535, 65535},
    u8s24pairs = {"pairArray", -8388608, 8388607, 255},
    u8u24array = {"array", 0, 16777215, 255},
    u16u24array = {"array", 0, 16777215, 65535},
}
local function numberInRange(value, low, high)
    return type(value) == "number" and value == value
        and value % 1 == 0 and value >= low and value <= high
end
local function exactPair(value, low, high, topLevel)
    if type(value) ~= "table" then return false end
    local n = 0
    for k, v in pairs(value) do
        if (k ~= 1 and k ~= 2) or not numberInRange(v, low, high) then
            return false
        end
        n = n + 1
    end
    if n ~= 2 then return false end
    if topLevel and value[1] == 0 and value[2] == 0 then return false end
    return true
end
local function classify(value, spec)
    if type(value) ~= "table" then return "malformed" end
    if next(value) == nil then return "empty" end
    local how, low, high, maximum = spec[1], spec[2], spec[3], spec[4]
    if how == "pair" then
        return exactPair(value, low, high, true) and "ordered" or "malformed"
    end
    local count, actualOrderWrong, malformed = 0, false, false
    for k, v in pairs(value) do
        count = count + 1
        if type(k) ~= "number" or k < 1 or k % 1 ~= 0
            or k > maximum or count > maximum then
            malformed = true
        elseif k ~= count then
            actualOrderWrong = true
        end
        if how == "array" then
            if not numberInRange(v, low, high) then malformed = true end
        elseif not exactPair(v, low, high, false) then
            malformed = true
        end
    end
    if count == 0 or count > maximum then malformed = true end
    -- Distinguish a truly dense but pairs()-reordered array from malformed
    -- sparse/mixed-key, bad inner-pair, noninteger or out-of-range structures.
    for i=1,count do
        if value[i] == nil then malformed = true; break end
    end
    if malformed then return "malformed" end
    if actualOrderWrong then return "reordered" end
    return "ordered"
end
local files = {
    {kind="npc", file="wotlkNpcDB.lua"},
    {kind="object", file="wotlkObjectDB.lua"},
    {kind="quest", file="wotlkQuestDB.lua"},
    {kind="item", file="wotlkItemDB.lua"},
}
local totalFields, totalReordered = 0, 0
for _,s in ipairs(files) do
    local dataKey = s.kind .. "Data"
    local keys = assert(db[s.kind .. "Keys"])
    local compilerTypes = assert(db[s.kind .. "CompilerTypes"])
    db[dataKey] = nil
    local chunk, problem = loadfile("Database/Wotlk/" .. s.file)
    assert(chunk, problem)
    local returned = chunk()
    local dataset = db[dataKey] or returned
    -- Questie's generated public base DB files store "return {...}" text
    -- for later loadstring compilation. Decode the in-memory PUBLIC table
    -- before shape checking; never print any decoded IDs or associations.
    if type(dataset) == "string" then
        local decode, decodeProblem = (loadstring or load)(dataset)
        assert(decode, decodeProblem)
        dataset = decode()
    end
    assert(type(dataset) == "table", "public WotLK base table was not loaded: " .. s.kind)
    local stats = {ordered=0, reordered=0, malformed=0, empty=0}
    local rows, fields = 0, 0
    for _,record in pairs(dataset) do
        rows = rows + 1
        if type(record) == "table" then
            for field, typename in pairs(compilerTypes) do
                local spec = specs[typename]
                local fieldIndex = keys[field]
                if spec and fieldIndex and record[fieldIndex] ~= nil then
                    fields = fields + 1
                    local classification = classify(record[fieldIndex], spec)
                    stats[classification] = stats[classification] + 1
                end
            end
        end
    end
    assert(rows > 0, "public WotLK base table is empty: " .. s.kind)
    assert(fields == stats.ordered + stats.reordered
        + stats.malformed + stats.empty, "audit accounting mismatch")
    totalFields = totalFields + fields
    totalReordered = totalReordered + stats.reordered
    print(string.format("PUBLIC WOTLK BASE %s rows=%d simple_fields=%d ordered=%d reordered_dense=%d malformed=%d intentional_empty=%d",
        s.kind, rows, fields, stats.ordered, stats.reordered,
        stats.malformed, stats.empty))
    db[dataKey] = nil
    collectgarbage("collect")
end
assert(totalFields > 0, "no simple compound fields were audited")
print(string.format("PUBLIC WOTLK BASE AUDIT COMPLETE simple_fields=%d reordered_dense=%d", totalFields, totalReordered))
print("SCOPE LIMIT: BASE tables only; effective Corrections, faction overrides, late writers and client QA NOT AUDITED.")
print("DRAFT AUDIT ONLY: discovering zero reordered base fields cannot certify Stage1 compatibility or source epoch.")
