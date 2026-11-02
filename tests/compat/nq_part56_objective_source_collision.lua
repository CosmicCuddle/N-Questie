-- N-Questie Part56: original-source synthetic objective spawn evidence.
-- Invented records only. No live data, addon mutation or client test.
local checks = 0
local function check(condition, detail)
    assert(condition, detail)
    checks = checks + 1
end
local function countKeys(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local npcs = {
    [901] = {
        name = 'Synthetic NPC 901', rank = 0,
        spawns = {[17] = {{10, 20}}, [42] = {{50, 60}}},
        waypoints = {[17] = {{{10, 20}, {11, 21}}}},
    },
    [902] = {name = 'Synthetic rare', rank = 2, spawns = {[17] = {{12, 22}}}, waypoints = {[17] = {{{12, 22}}}}},
    [903] = {name = 'Synthetic blacklisted', rank = 0, spawns = {[17] = {{13, 23}}}, waypoints = {[17] = {{{13, 23}}}}},
}
local objects = {
    [901] = {name = 'Synthetic GO 901', spawns = {[77] = {{70, 80}}}},
    [904] = {name = 'Synthetic GO 904', spawns = {[88] = {{80, 90}}}},
}
local items = {
    [8000] = {Id = 8000, Sources = {{Type = 'monster', Id = 901}, {Type = 'object', Id = 904}}},
    [8001] = {Id = 8001, Sources = {{Type = 'monster', Id = 901}, {Type = 'object', Id = 901}}},
    [8002] = {Id = 8002, Sources = {{Type = 'monster', Id = 903}}},
}
local questieQuest = {private = {}}
local questieDB = {
    QueryNPCSingle = function(id, field) return npcs[id] and npcs[id][field] end,
    QueryObjectSingle = function(id, field) return objects[id] and objects[id][field] end,
    GetItem = function(_, id) return items[id] end,
}
local corrections = {questNPCBlacklist = {[903] = true}}
local modules = {QuestieQuest = questieQuest, QuestieDB = questieDB, QuestieCorrections = corrections}
QuestieLoader = {ImportModule = function(_, name)
    assert(modules[name], 'unexpected import: ' .. tostring(name))
    return modules[name]
end}
Questie = {
    db = {profile = {monsterScale = 1, objectScale = 1, lootScale = 1, eventScale = 1.35}},
    ICON_TYPE_SLAY = 'slay', ICON_TYPE_OBJECT = 'object', ICON_TYPE_LOOT = 'loot', ICON_TYPE_EVENT = 'event',
    DEBUG_CRITICAL = 'critical',
    Debug = function() end,
    Error = function() end,
}

-- Execute the actual protected source, NOT a hand-copied reimplementation.
dofile('Modules/Quest/QuestieQuestPrivates.lua')
local getSpawns = questieQuest.private.objectiveSpawnListCallTable
local objective = {Description = 'Invented objective'}

-- A source NPC's every database zone is offered without per-quest filtering here.
local npc = getSpawns.monster(901, objective)[901]
check(npc.Spawns == npcs[901].spawns, 'NPC source was not the complete database spawn table')
check(npc.Spawns[17] and npc.Spawns[42], 'a synthetic database zone was dropped')
check(npc.Waypoints == npcs[901].waypoints, 'normal NPC waypoints not copied')

-- The existing blacklist is per NPC, not a filter for individual positions.
local blocked = getSpawns.monster(903, objective)[903]
check(countKeys(blocked.Spawns) == 0, 'blacklist did not suppress all NPC zones')
check(countKeys(blocked.Waypoints) == 0, 'blacklist did not suppress waypoints')

local rare = getSpawns.monster(902, objective)[902]
check(rare.Spawns[17] ~= nil, 'rare NPC spawn unexpectedly removed')
check(countKeys(rare.Waypoints) == 0, 'rare NPC waypoints unexpectedly present')

-- Distinct numeric IDs are correctly represented as distinct loot sources.
local normalItem = getSpawns.item(8000, objective)
check(countKeys(normalItem) == 2, 'two different source IDs did not remain separate')
check(normalItem[901].Spawns[17] and normalItem[901].Spawns[42], 'NPC loot did not include every source zone')
check(normalItem[904].Spawns[88], 'GO loot source absent')

-- IMPORTANT diagnostic: NPC and GO sharing one numeric ID merge into ONE key.
local collidingItem = getSpawns.item(8001, objective)
check(countKeys(collidingItem) == 1, 'expected source-type numeric-ID collision did not reproduce')
check(collidingItem[901].Spawns[17] and collidingItem[901].Spawns[77], 'cross-type sources did not merge')
check(collidingItem[901].ItemId == 8001, 'merged item association lost')

-- With a blacklisted NPC, an item objective source remains but produces no pins.
local blacklistedItem = getSpawns.item(8002, objective)
check(blacklistedItem[903] ~= nil and countKeys(blacklistedItem[903].Spawns) == 0,
      'blacklisted source unexpectedly created item pins')

-- These PASS lines prove how existing source handles synthetic input, not live bad pins.
print('PASS: Part56 objective source boundary: ' .. checks .. ' synthetic checks')
print('OBSERVED: original item-source keys merge NPC+GO with identical numeric IDs')
print('NOT TESTED: real loot IDs, live spawns, quest/phase eligibility, rendered map or installed client')
