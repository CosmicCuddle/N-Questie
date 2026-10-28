-- G08 TEST ONLY: executes the EXACT protected-335 original QuestieDB:Initialize
-- and GetCreatureLevels function bodies, with synthetic GetDBHandle and NPC data.
-- No original decoder, real realm, SavedVariables, addon runtime or native client.
local root=assert(os.getenv("NQ_G08_DB_CREATURE_CACHE_ROOT"),"PINNED_335_ROOT_REQUIRED")
local fp=assert(io.open(root.."/Database/QuestieDB.lua","rb"))
local src=assert(fp:read("*a"));fp:close()
local function slice(first,last)
  local a=assert(src:find(first,1,true),"MISSING_START:"..first)
  assert(not src:find(first,a+#first,true),"DUPLICATE_START:"..first)
  local b=assert(src:find(last,a+#first,true),"MISSING_END:"..last)
  return src:sub(a,b-1)
end
local init=slice("function QuestieDB:Initialize()","\nfunction QuestieDB:GetObject(objectId)")
local levels=slice("function QuestieDB:GetCreatureLevels(quest)","\nlocal playerFaction = UnitFactionGroup(\"player\")")
local cacheLine="QuestieDB._CreatureLevelCache = {}"
local function compile(source,env)
  local f
  if _VERSION=="Lua 5.1" then
    f=assert(loadstring(source,"=unchanged_335_db_init_and_creature_cache"))
    setfenv(f,env)
  else
    f=assert(load(source,"=unchanged_335_db_init_and_creature_cache","t",env))
  end
  return f()
end
local n=0
local function check(cond,label) assert(cond,label);n=n+1 end
local function empty(t) return next(t)==nil end
local function count(t) local k=0;for _ in pairs(t) do k=k+1 end;return k end
check(init:find('QuestieDB._QueryItemSingle = QuestieDB.QueryItem.QuerySingle',1,true)~=nil,
  "D01_ORIGINAL_ITEM_HANDLE_BIND")
check(init:find("QuestieDB.QueryItemSingle = QuestieDB._QueryItemSingle",1,true)~=nil,
  "D02_ORIGINAL_PUBLIC_QUERY_BIND")
check(init:find("QuestieDB.ItemPointers = QuestieDB.QueryItem.pointers",1,true)~=nil,
  "D03_ORIGINAL_ITEM_POINTER_EXPORT")
check(init:find("_QuestieDB.questCache = {}",1,true)~=nil,"D04_QUEST_CACHE_RESET")
check(init:find("_QuestieDB.itemCache = {}",1,true)~=nil,"D05_ITEM_CACHE_RESET")
check(init:find("_QuestieDB.npcCache = {}",1,true)~=nil,"D06_NPC_CACHE_RESET")
check(init:find("_QuestieDB.objectCache = {}",1,true)~=nil,"D07_OBJECT_CACHE_RESET")
check(init:find("_QuestieDB.zoneCache = {}",1,true)~=nil,"D08_ZONE_CACHE_RESET")
check(src:find(cacheLine,1,true)~=nil,"D09_CREATURE_CACHE_DECLARATION_AUTHENTIC")
check(not init:find("_CreatureLevelCache",1,true),"D10_INIT_HAS_NO_CREATURE_CACHE_INVALIDATION")
check(levels:find("QuestieDB._CreatureLevelCache[quest.Id]",1,true)~=nil,
  "D11_REAL_CREATURE_LEVEL_CACHE_LOOKUP_AND_WRITE")
check(levels:find('QuestieDB.QueryItemSingle(itemId, "npcDrops")',1,true)~=nil,
  "D12_ORIGINAL_CREATURE_ITEM_DROPS_QUERY")
check(levels:find("QuestieDB:GetNPC(npcId)",1,true)~=nil,
  "D13_ORIGINAL_NPC_FETCH")
local kinds={"npc","quest","obj","item"}
local names={npc="NPC",quest="Quest",obj="Object",item="Item"}
local function generation(label)
  local g={label=label,records={npc={},quest={},obj={},item={}}}
  local o=(label=="A" and 100 or 200)
  g.records.npc[o+1]={id=o+1,name=label.."_DIRECT",minLevel=o+1,maxLevel=o+3,rank=0}
  g.records.npc[o+2]={id=o+2,name=label.."_DROPS",minLevel=o+4,maxLevel=o+5,rank=1}
  g.records.item[500]={class=label=="A" and 12 or 13,npcDrops={o+2}}
  for _,kind in ipairs(kinds) do
    local ptr={}
    for id in pairs(g.records[kind]) do ptr[id]=true end
    g[kind.."Bin"]=label.."_BIN_"..kind
    g[kind.."Ptrs"]=ptr
  end
  return g
end
local A,B=generation("A"),generation("B")
local active=A
local legacy={sod={}}
local module={}
for _,kind in ipairs(kinds) do
  local prefix=kind=="obj" and "object" or kind
  module[prefix.."CompilerTypes"]={}
  module[prefix.."CompilerOrder"]={}
  module[prefix.."Keys"]={}
  module[prefix.."DataOverrides"]={}
end
local private={questCache={prior=true},itemCache={prior=true},npcCache={prior=true},
  objectCache={prior=true},zoneCache={prior=true}}
local compiler={calls={},failAt=nil}
function compiler:BuildSkipMap()return {} end
function compiler:GetDBHandle(bin,ptr)
  local kind=assert(kinds[#self.calls+1],"TOO_MANY_GETDBHANDLE_CALLS")
  self.calls[#self.calls+1]={kind=kind,bin=bin,ptr=ptr}
  if self.failAt==kind then error("FICTIONAL_FAIL_"..kind) end
  local data=active.records[kind]
  assert(bin==active[kind.."Bin"] and ptr==active[kind.."Ptrs"],"MIXED_HANDLE_INPUT")
  return {
    pointers=ptr,
    QuerySingle=function(id,key) return data[id] and data[id][key] end,
    Query=function(id) return data[id] end
  }
end
local questie={IsSoD=false,db={global=legacy,profile={},char={hidden={}}}}
local env={QuestieDB=module,_QuestieDB=private,QuestieDBCompiler=compiler,
  Questie=questie,QuestieLib={TableMemoizeFunction=function(_,fn)return fn end},
  QuestieCorrections={hiddenQuests={}},
  QuestiePlayer={HasRequiredRace=function()return true end,HasRequiredClass=function()return true end},
  StaticPopupDialogs={},l10n=function(s)return s end,ReloadUI=function()end}
setmetatable(env,{__index=_G})
compile(init.."\n"..cacheLine.."\n"..levels,env)
function module:GetNPC(id) return active.records.npc[id] end
local function update(which)
  active=which
  for _,kind in ipairs(kinds) do
    legacy[kind.."Bin"]=which[kind.."Bin"]
    legacy[kind.."Ptrs"]=which[kind.."Ptrs"]
  end
  compiler.calls={}
  module:Initialize()
  check(#compiler.calls==4,"D14_FOUR_ORIGINAL_READER_HANDLES_CREATED")
end
local qa={Id=7001,objectives={[1]={{101}},[3]={{500}}}}
local qb={Id=7001,objectives={[1]={{201}},[3]={{500}}}}
local fresh={Id=7002,objectives={[1]={{201}},[3]={{500}}}}
update(A)
check(module.ItemPointers==A.itemPtrs and module.NPCPointers==A.npcPtrs,
  "D15_ORIGINAL_INITIALIZE_PUBLISHES_A_POINTERS")
check(module.QueryItemSingle(500,"class")==12,"D16_ORIGINAL_A_ITEM_CLASS")
check(module.QueryItemSingle(500,"npcDrops")[1]==102,"D17_ORIGINAL_A_ITEM_DROPS")
check(empty(private.questCache) and empty(private.itemCache) and empty(private.npcCache)
  and empty(private.objectCache) and empty(private.zoneCache),
  "D18_ORIGINAL_FIVE_PRIVATE_CACHES_RESET")
local queryA=module.QueryItemSingle
local ptrA=module.ItemPointers
local oldLevels=module:GetCreatureLevels(qa)
check(oldLevels.A_DIRECT[1]==101 and oldLevels.A_DROPS[2]==105,
  "D19_REAL_A_CREATURE_LEVELS_FROM_DIRECT_AND_ITEM")
check(count(oldLevels)==2,"D20_REAL_A_TWO_CREATURE_RECORDS")
check(module._CreatureLevelCache[7001]==oldLevels,"D21_ORIGINAL_CACHE_RESULT_RETAINED")
check(module:GetCreatureLevels(qa)==oldLevels,"D22_REAL_CACHE_REUSE_OLD")
private.questCache={stale=true};private.itemCache={stale=true};
private.npcCache={stale=true};private.objectCache={stale=true};private.zoneCache={stale=true}
update(B)
check(module.ItemPointers==B.itemPtrs and module.NPCPointers==B.npcPtrs,
  "D23_ORIGINAL_INITIALIZE_PUBLISHES_B_POINTERS")
check(module.QueryItemSingle(500,"class")==13 and
  module.QueryItemSingle(500,"npcDrops")[1]==202,
  "D24_REAL_B_QUERY_CLOSURE_REBINDS")
check(queryA(500,"class")==12 and queryA(500,"npcDrops")[1]==102,
  "D25_PREVIOUS_HANDLE_STAYS_A")
check(ptrA==A.itemPtrs and ptrA~=module.ItemPointers,
  "D26_PRIOR_POINTER_ALIAS_STAYS_A")
check(empty(private.questCache) and empty(private.itemCache) and
  empty(private.npcCache) and empty(private.objectCache) and empty(private.zoneCache),
  "D27_REAL_B_INITIALIZE_RESETS_FIVE_CACHES_AGAIN")
check(module._CreatureLevelCache[7001]==oldLevels,
  "D28_REAL_INITIALIZE_DOES_NOT_CLEAR_CREATURE_CACHE")
local stale=module:GetCreatureLevels(qb)
check(stale==oldLevels and stale.A_DIRECT~=nil and stale.B_DIRECT==nil,
  "D29_REAL_STALE_CACHE_RESURFACES_FOR_SAME_QUEST_ID")
local bLevels=module:GetCreatureLevels(fresh)
check(bLevels.B_DIRECT[1]==201 and bLevels.B_DROPS[1]==204,
  "D30_FRESH_QUEST_ID_QUERIES_B_CORRECTLY")
check(count(bLevels)==2 and module._CreatureLevelCache[7002]==bLevels,
  "D31_B_NEW_LEVELS_CACHED_SEPARATELY")
-- Explicit, fictional coordinator action; this is NOT in original Initialize.
module._CreatureLevelCache={}
local refreshed=module:GetCreatureLevels(qb)
check(refreshed~=oldLevels and refreshed.B_DIRECT~=nil and refreshed.A_DIRECT==nil,
  "D32_MODEL_INVALIDATION_ALLOWS_REAL_FUNCTION_TO_BUILD_B")
check(module._CreatureLevelCache[7001]==refreshed,
  "D33_MODEL_CACHE_REBUILD_STORED_NEW_DATA")
update(A)
check(module.QueryItemSingle(500,"npcDrops")[1]==102,
  "D34_ORIGINAL_A_B_A_HANDLE_RETURN")
check(module._CreatureLevelCache[7001]==refreshed,
  "D35_A_B_A_SOURCE_SWAP_ALONE_PRESERVES_B_CACHE")
check(module:GetCreatureLevels(qa)==refreshed and refreshed.B_DIRECT~=nil,
  "D36_A_B_A_STALE_CACHE_REMAINS_WITHOUT_EPOCH")
-- The hypothetical publisher must invalidate cache before announcing READY.
module._CreatureLevelCache={}
local restored=module:GetCreatureLevels(qa)
check(restored.A_DIRECT~=nil and restored.B_DIRECT==nil,
  "D37_MODEL_SECOND_INVALIDATION_RESTORES_A")
check(count(restored)==2 and module._CreatureLevelCache[7001]==restored,
  "D38_ORIGINAL_FUNCTION_RECOMPUTES_AFTER_MODEL_CLEAR")
assert(n==40,"DB_CREATURE_ASSERTION_CENSUS_CHANGED:"..n)
print("PUBLIC G08 PART44 ACTUAL DB INIT AND CREATURE CACHE: 40/40 PASS")
print("PUBLIC G08 AUTHENTIC EXECUTION: unchanged entire original QuestieDB Initialize and GetCreatureLevels function bodies; original 5-cache resets, QueryItemSingle rebinding and CreatureLevelCache lookup/write with fictional GetDBHandle and NPCs.")
print("PUBLIC G08 SYNTHETIC WITNESS: original Initialize does not reset CreatureLevelCache; synthetic A-to-B and A-to-B-to-A snapshots retain earlier quest ID levels until an explicit MODEL-ONLY invalidation.")
print("PUBLIC G08 NOT NATIVE: original full QuestieDB module, true decoder, compiler, QuestieStream, WOW UI, SavedVariables, IP 3.3.5a, actual writer, build, ZIP, install, merge and release NOT tested.")
