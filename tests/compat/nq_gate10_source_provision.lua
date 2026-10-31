-- Gate10 (quests 1207-1209): synthetic, offline contract tests for the
-- all-or-nothing source provisioning in Compat/NQuestieCustomQuestLoader.lua.
-- Uses the real loader, the real Compat/NQuestieCustomQuestData.lua and the
-- real Questie key schemas against an in-memory QuestieDB stub.
-- No client, SavedVariables, SQL, server or package. NOT an in-game test.
local loaderPath = os.getenv("NQ_LOADER_PATH") or "Compat/NQuestieCustomQuestLoader.lua"
local dataPath = os.getenv("NQ_DATA_PATH") or "Compat/NQuestieCustomQuestData.lua"

Questie = {IsSoD = false, IsWotlk = true, IsTBC = false}
local schema = {}
QuestieLoader = {
    ImportModule = function(_, n) schema[n] = schema[n] or {} return schema[n] end,
    CreateModule = function(_, n) schema[n] = schema[n] or {} return schema[n] end,
}
for _, f in ipairs({"Database/questDB.lua", "Database/npcDB.lua", "Database/objectDB.lua", "Database/itemDB.lua"}) do
    assert(loadfile(f))()
end
local S = schema.QuestieDB
local QK, NK, OK, IK = S.questKeys, S.npcKeys, S.objectKeys, S.itemKeys

local NEW_QUESTS = {1207, 1208, 1209}
local SOURCES = {npcs = {1209, 3506, 3526, 3677}, objects = {2013}, items = {160, 161, 162, 166, 167}}
local DBNAME = {npcs = "npcData", objects = "objectData", items = "itemData"}

local checks = 0
local function check(label, ok)
    checks = checks + 1
    if not ok then error("FAIL " .. checks .. ": " .. label, 0) end
    print("PASS " .. checks .. ": " .. label)
end

local function deepcopy(v)
    if type(v) ~= "table" then return v end
    local o = {}
    for k, x in pairs(v) do o[k] = deepcopy(x) end
    return o
end

local function loadData()
    NQuestieCustomQuestData = nil
    assert(loadfile(dataPath))()
    return NQuestieCustomQuestData
end
local baseData = deepcopy(loadData())

local sameTables
local function count(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end

-- opts: order (list of group names), mutate(data), preDb(db), raw437 (default true)
local function run(opts)
    opts = opts or {}
    local data = deepcopy(baseData)
    if opts.mutate then opts.mutate(data) end
    local db = {
        questKeys = QK, npcKeys = NK, objectKeys = OK, itemKeys = IK,
        questData = {}, npcData = {
            [2121] = {[NK.name] = "Existing 2001 giver"},
            [1868] = {[NK.name] = "Existing 2001 objective A"},
            [1869] = {[NK.name] = "Existing 2001 objective B"},
            [3393] = {[NK.name] = "Existing drop source"},
        }, objectData = {}, itemData = {},
    }
    if opts.raw437 ~= false then db.questData[437] = {[QK.name] = "Existing prerequisite"} end
    if opts.preDb then opts.preDb(db) end
    local before = deepcopy(db)
    local callbacks = {}
    QuestieLoader = {ImportModule = function(_, n) assert(n == "QuestieDB") return db end}
    QuestieCompat = {Is335 = true, RegisterCorrection = function(kind, fn)
        callbacks[kind] = callbacks[kind] or {}
        table.insert(callbacks[kind], fn)
    end}
    NQuestieCustomQuestData = data
    assert(loadfile(loaderPath))()
    local results = {}
    for _, group in ipairs(opts.order or {"questData", "npcData", "objectData"}) do
        results[group] = {}
        for _, fn in ipairs(callbacks[group] or {}) do
            for id, row in pairs(fn()) do results[group][id] = row end
        end
    end
    -- second invocation must be stable (memoized, no re-provisioning)
    local again = callbacks.questData and callbacks.questData[1]() or {}
    -- removing a record after the first approval must not change memoized output
    local saved = data.quests[1207]
    data.quests[1207] = nil
    local again2 = callbacks.questData and callbacks.questData[1]() or {}
    data.quests[1207] = saved
    return {db = db, before = before, results = results, again = again,
        memoSame = sameTables(again, again2), callbacks = callbacks}
end

local function questsApproved(r)
    for _, id in ipairs(NEW_QUESTS) do if not r.results.questData[id] then return false end end
    return true
end
local function noneApproved(r)
    for _, id in ipairs(NEW_QUESTS) do if r.results.questData[id] then return false end end
    return true
end
local function sourcesWritten(r)
    for kind, ids in pairs(SOURCES) do
        for _, id in ipairs(ids) do if type(r.db[DBNAME[kind]][id]) ~= "table" then return false end end
    end
    return true
end
function sameTables(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do if not sameTables(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
local function sourcesUntouched(r)
    for _, name in ipairs({"npcData", "objectData", "itemData"}) do
        if not sameTables(r.db[name], r.before[name]) then return false end
    end
    return true
end

-- 1. Data shape
check("data revision bumped to 10", baseData.revision == 10)
local allowed = {
    npcs = {name=1, minLevel=1, maxLevel=1, rank=1, factionID=1, npcFlags=1, zoneID=1, spawns=1},
    objects = {name=1, zoneID=1, spawns=1},
    items = {name=1, class=1, subClass=1, npcDrops=1, objectDrops=1},
}
local onlyVisible, counts = true, {}
for kind, rows in pairs(baseData.sources) do
    counts[kind] = count(rows)
    for _, row in pairs(rows) do
        for field in pairs(row) do if not allowed[kind][field] then onlyVisible = false end end
    end
end
check("sources: exactly 4 NPC / 1 object / 5 item records", counts.npcs == 4 and counts.objects == 1 and counts.items == 5 and count(baseData.sources) == 3)
check("sources carry only allow-listed player-visible fields", onlyVisible)
local zoneKeyed = true
for _, kind in ipairs({"npcs", "objects"}) do
    for _, row in pairs(baseData.sources[kind]) do
        if type(row.spawns) ~= "table" or count(row.spawns) ~= 1 or type(row.spawns[17]) ~= "table" then zoneKeyed = false end
    end
end
check("all spawns zone-keyed under zone 17", zoneKeyed)
check("exactly 4 records in quests table (2001 + 1207-1209)", count(baseData.quests) == 4)

-- 2. Every correction-group order
local orders = {
    {"questData", "npcData", "objectData"}, {"questData", "objectData", "npcData"},
    {"npcData", "questData", "objectData"}, {"npcData", "objectData", "questData"},
    {"objectData", "questData", "npcData"}, {"objectData", "npcData", "questData"},
}
local reference
for _, order in ipairs(orders) do
    local r = run({order = order})
    local label = table.concat(order, ">")
    check(label .. ": 1207-1209 and 2001 approved, all 10 sources provisioned",
        questsApproved(r) and r.results.questData[2001] ~= nil and sourcesWritten(r))
    local giver = r.results.npcData[1209]
    local ok = giver and #giver[NK.questStarts] == 3 and #giver[NK.questEnds] == 3
    check(label .. ": quest giver gets 3 start and 3 end links", ok)
    if not reference then reference = r.results else
        check(label .. ": identical results to first order", sameTables(reference, r.results))
    end
    check(label .. ": repeated callback is memoized and stable", sameTables(r.again, r.results.questData) and r.memoSame)
end
local r0 = run()
check("1209 objectives keep item order 160,161,162",
    sameTables(r0.results.questData[1209][QK.objectives][3], {{160}, {161}, {162}}))
check("1208 uses object-dropped item 167", sameTables(r0.results.questData[1208][QK.objectives][3], {{167}}))
check("2001 record unchanged by provisioning", sameTables(run({mutate = function(d) d.sources = nil; d.quests[1207], d.quests[1208], d.quests[1209] = nil, nil, nil end}).results.questData[2001], r0.results.questData[2001]))
check("existing NPC 3393 not rewritten", sameTables(r0.db.npcData[3393], r0.before.npcData[3393]))

-- 3. Removing each source record: whole batch rejected, nothing written, 2001 kept
for kind, ids in pairs(SOURCES) do
    for _, id in ipairs(ids) do
        local r = run({mutate = function(d) d.sources[kind][id] = nil end})
        check("remove " .. kind .. " record #" .. _ .. ": 1207-1209 rejected, no source written, 2001 kept",
            noneApproved(r) and sourcesUntouched(r) and r.results.questData[2001] ~= nil)
    end
end

-- 4. Collision for every source ID and every new quest ID
for kind, ids in pairs(SOURCES) do
    for i, id in ipairs(ids) do
        local r = run({preDb = function(db) db[DBNAME[kind]][id] = {[1] = "Pre-existing row"} end})
        check("collision " .. kind .. " #" .. i .. ": batch rejected, existing row untouched, 2001 kept",
            noneApproved(r) and sourcesUntouched(r) and r.db[DBNAME[kind]][id][1] == "Pre-existing row"
            and r.results.questData[2001] ~= nil)
    end
end
for _, qid in ipairs(NEW_QUESTS) do
    local r = run({preDb = function(db) db.questData[qid] = {[QK.name] = "Pre-existing quest"} end})
    check("collision quest " .. qid .. ": whole batch rolled back, no source written, 2001 kept",
        noneApproved(r) and sourcesUntouched(r) and r.results.questData[2001] ~= nil
        and r.db.questData[qid][QK.name] == "Pre-existing quest")
end

-- 5. Invalid batch content
local invalid = {
    {"unknown field", function(d) d.sources.npcs[1209].lootid = 1 end},
    {"coordinate > 100", function(d) d.sources.npcs[3506].spawns[17][1][1] = 100.5 end},
    {"flat (not zone-keyed) spawns", function(d) d.sources.objects[2013].spawns = {{50, 50}} end},
    {"unresolved item drop", function(d) d.sources.items[162].npcDrops = {999999} end},
    {"item without any drop source", function(d) d.sources.items[166].npcDrops = nil end},
    {"minLevel > maxLevel", function(d) d.sources.npcs[3677].minLevel = 30 end},
    {"unknown source group", function(d) d.sources.quests = {} end},
    {"unused extra source", function(d) d.sources.npcs[3394000] = {name = "Unused", minLevel = 1, maxLevel = 1, zoneID = 17, spawns = {[17] = {{1, 1}}}} end},
}
local nodrop = run({mutate = function(d) d.sources.items[166].npcDrops = nil; d.sources.npcs[3677] = nil end})
check("item without any drop source rejected even when batch is otherwise closed",
    noneApproved(nodrop) and sourcesUntouched(nodrop))
for _, case in ipairs(invalid) do
    local r = run({mutate = case[2]})
    check("invalid batch (" .. case[1] .. "): rejected all-or-nothing, 2001 kept",
        noneApproved(r) and sourcesUntouched(r) and r.results.questData[2001] ~= nil)
end

-- 6. Existing 2001 / 437 behaviour
local r437 = run({raw437 = false})
check("2001 still approved without raw 437; Gate10 batch unaffected",
    r437.results.questData[2001] ~= nil and questsApproved(r437) and r437.db.questData[437] == nil)
local raw2001 = run({preDb = function(db) db.questData[2001] = {[QK.name] = "Raw 2001"} end})
check("2001 exception with raw 2001 row present; Gate10 batch unaffected",
    raw2001.results.questData[2001] ~= nil and questsApproved(raw2001))
local no2001 = run({mutate = function(d) d.quests[2001].preQuestSingle = {438} end, raw437 = false})
check("non-exact 2001 with missing prerequisite rejected", no2001.results.questData[2001] == nil and questsApproved(no2001))

-- 7. No sources table: behaves as before (quests needing them rejected, nothing written)
local nosrc = run({mutate = function(d) d.sources = nil end})
check("without sources table: 1207-1209 rejected, nothing written, 2001 kept",
    noneApproved(nosrc) and sourcesUntouched(nosrc) and nosrc.results.questData[2001] ~= nil)

print("ALL " .. checks .. " GATE10 SOURCE-PROVISION CHECKS PASS")
print("NOT TESTED: in-game display, map coordinates, drops, IP/phase gating, real compiler round-trip.")
