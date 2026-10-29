-- TEST-ONLY: full original QuestieDB.GetQuest and QuestLogCache run with fake WoW APIs.
-- No native 3.3.5a client, characters, inventory, SavedVariables, network or builds.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"MISSING_ORIGINAL:"..path)
  local s=assert(f:read("*a"));f:close();return s
end
local questSource=read("Modules/Quest/QuestieQuest.lua")
local cacheSource=read("Modules/Quest/QuestLogCache.lua")
local dbSource=read("Database/QuestieDB.lua")
local function extract(src,first,last)
  local a=assert(src:find(first,1,true),"MISSING_BEGIN:"..first)
  local b=assert(src:find(last,a+#first,true),"MISSING_END:"..first)
  return src:sub(a,b-1)
end
local authenticGetQuest=extract(dbSource,
  "function QuestieDB.GetQuest(questId)","\nQuestieDB._CreatureLevelCache = {}")
local authenticGetLog=extract(questSource,
  "function QuestieQuest:GetAllQuestIdsNoObjectives()","\n-- iterate all notes")
local function compile(s,name,env)
  local f
  if _VERSION=="Lua 5.1" then f=assert(loadstring(s,name));setfenv(f,env)
  else f=assert(load(s,name,"t",env)) end
  f()
end
local n=0
local function check(ok,tag) assert(ok,tag);n=n+1 end
check(dbSource:find("_QuestieDB.questCache[questId] = QO",1,true)~=nil,
  "D01_ORIGINAL_DB_CACHES_CONSTRUCTED_OBJECT")
check(dbSource:find("if _QuestieDB.questCache[questId] then",1,true)~=nil,
  "D02_ORIGINAL_DB_CACHE_HIT")
check(dbSource:find("_QuestieDB.questCache = {};",1,true)~=nil,
  "D03_ORIGINAL_DB_HAS_CACHE_INIT")
check(cacheSource:find("QuestLogCache.questLog_DO_NOT_MODIFY = cache",1,true)~=nil,
  "D04_ORIGINAL_CACHE_QUESTLOG_IDS")
check(authenticGetLog:find("QuestieDB.GetQuest(questId)",1,true)~=nil,
  "D05_RESET_CALLS_ORIGINAL_GETQUEST")

local rawQuest={[1]={[1]={},[2]={},[3]=5}}
local game={ready=true,title="SYNTHETIC_QUEST",complete=0,tag="normal",
  objectives={{text="SYNTHETIC_OBJECTIVE",type="item",numFulfilled=0,numRequired=2,finished=false}}}
local counts={query=0,questLogReads=0,objectiveReads=0,completeSound=0}
local errors={}
local modules={}
modules.QuestieLib={
  GetTbcLevel=function() return 12,10 end,
  TrimObjectiveText=function(s) return s end
}
modules.Sounds={
  PlayObjectiveComplete=function()end,
  PlayObjectiveProgress=function()end,
  PlayQuestComplete=function()counts.completeSound=counts.completeSound+1 end
}
local loader={}
function loader:CreateModule(k)modules[k]={};return modules[k] end
function loader:ImportModule(k)return assert(modules[k],"FAKE_MODULE_NOT_FOUND:"..k)end
local compat={
  GetQuestLogTitle=function(index)
    counts.questLogReads=counts.questLogReads+1
    if index~=1 then return nil end
    return game.title,nil,game.tag,false,nil,game.complete,nil,1
  end,
  HaveQuestData=function(id)return id==1 and game.ready end,
  C_QuestLog={GetQuestObjectives=function(id,index)
    counts.objectiveReads=counts.objectiveReads+1
    assert(id==1 and index==1)
    return game.objectives
  end}
}
local questie={DEBUG_DEVELOP=1,DEBUG_INFO=1,DEBUG_CRITICAL=1,
  IsSoD=false,_sessionWarnings={}}
function questie:Debug()end
function questie:Error(...)errors[#errors+1]={...}end
function questie:Warning(...)errors[#errors+1]={...}end
local db={questKeys={startedBy=1,finishedBy=2,sourceItemId=3},
  _questAdapterQueryOrder={},QuestPointers={[1]=true}}
function db.QueryQuest(id,order)
  assert(order==db._questAdapterQueryOrder)
  counts.query=counts.query+1
  return rawQuest[id]
end
local privateDB={questCache={}}
local player={currentQuestlog={}}
local reset={}
local env={
  Questie=questie,QuestieCompat=compat,QuestieLoader=loader,QuestieDB=db,
  QuestieLib=modules.QuestieLib,QuestieCorrections={hiddenQuests={}},
  QuestiePlayer=player,QuestieQuest=reset
}
setmetatable(env,{__index=_G})
compile(cacheSource,"@original_335/Modules/Quest/QuestLogCache.lua",env)
local cache=assert(modules.QuestLogCache)
env.QuestLogCache=cache

-- Inject only the original module's private cache binding and original local
-- IsComplete dependency. The entire original GetQuest function BODY is verbatim.
env.FAKE_DB_PRIVATE=privateDB
local sourceShim="local _QuestieDB=FAKE_DB_PRIVATE\n"
  .."local _IsComplete=function() return 0 end -- NOT original IsComplete\n"
  .."local bitband=function() error('UNEXPECTED_BITBAND') end\n"
  .."local tinsert=table.insert\n"
compile(sourceShim..authenticGetQuest,
  "=original_335_FULL_QuestieDB_GetQuest_with_fake_external_dependencies",env)
compile("local _AddSourceItemObjective=function()end\n"
  .."local _AddRequiredSourceItemObjective=function()end\n"
  ..authenticGetLog,
  "=original_335_GetAllQuestIdsNoObjectives_with_fake_sourceitem_helpers",env)

check(next(privateDB.questCache)==nil,"D06_COLD_DB_CACHE_EMPTY")
local q=db.GetQuest(1)
check(type(q)=="table" and q.Id==1,"D07_ORIGINAL_COLD_GETQUEST_CREATED_OBJECT")
check(counts.query==1 and privateDB.questCache[1]==q,
  "D08_ORIGINAL_FIRST_PARTY_CACHE_INSERT")
check(q.startedBy==rawQuest[1][1] and q.finishedBy==rawQuest[1][2],
  "D09_SOURCE_DB_KEYS_TRANSFERRED")
check(q.sourceItemId==5 and q.level==12 and q.requiredLevel==10,
  "D10_ORIGINAL_OBJECT_ADAPTER_FIELDS")
check(type(q.ObjectiveData)=="table" and type(q.Objectives)=="table"
  and type(q.SpecialObjectives)=="table",
  "D11_ORIGINAL_OBJECT_INITIALIZATION")
check(q.IsComplete~=nil and q.WasComplete==nil,
  "D12_ORIGINAL_NEW_OBJECT_NO_WASCOMPLETE")
local same=db.GetQuest(1)
check(same==q and counts.query==1,"D13_ORIGINAL_CACHE_HIT_SKIPS_QUERY")
check(db.GetQuest(nil)==nil and counts.query==1,"D14_ORIGINAL_NIL_QUEST_ID")
check(db.GetQuest(99)==nil and counts.query==2,
  "D15_ORIGINAL_MISSING_RAW_QUEST_RETURNS_NIL")
check(privateDB.questCache[99]==nil,"D16_MISSING_DB_QUEST_NOT_CACHED")
check(next(cache.questLog_DO_NOT_MODIFY)==nil,
  "D17_GAME_QUESTLOG_CACHE_INDEPENDENT_OF_DB")
local cacheMiss,delta=cache.CheckForChanges(nil)
check(not cacheMiss and delta[1] and
  next(cache.questLog_DO_NOT_MODIFY)~=nil,
  "D18_ORIGINAL_QUESTLOG_GAME_CACHE_INITIALIZES")
check(counts.objectiveReads==1,"D19_ORIGINAL_GETOBJECTIVES_FROM_FAKE_API")
check(cache.questLog_DO_NOT_MODIFY[1]~=q
  and cache.questLog_DO_NOT_MODIFY[1].WasComplete==nil,
  "D20_DISTINCT_GAME_LOG_AND_DB_OBJECTS")

-- The mutation is deliberately TEST-ONLY, simulating a preexisting
-- WasComplete flag. We never claim it was set by a native quest event.
q.WasComplete=true
q.Objectives={{Type="item",Id=5}}
check(db.GetQuest(1)==q and counts.query==2,
  "D21_ORIGINAL_GETQUEST_CARRIES_FAKE_FLAG_WITHOUT_REQUERY")
reset:GetAllQuestIdsNoObjectives()
check(player.currentQuestlog[1]==q,
  "D22_ORIGINAL_RESET_RETURNS_ACTUAL_DB_CACHED_OBJECT")
check(q.LocalizedName==game.title and q.WasComplete==true,
  "D23_ORIGINAL_RESET_DOES_NOT_RESET_FAKE_FLAG")
check(counts.query==2,
  "D24_ORIGINAL_RESET_GETQUEST_CACHE_HIT")

-- Changing the first-party *QuestLogCache* fields never replaces the
-- separate original QuestieDB cached quest object.
game.title="SYNTHETIC_RENAMED"
game.complete=1
local m2,d2=cache.CheckForChanges(nil)
check(not m2 and d2[1]~=nil,"D25_ORIGINAL_GAME_LOG_CHANGED")
check(cache.questLog_DO_NOT_MODIFY[1].title=="SYNTHETIC_RENAMED",
  "D26_ORIGINAL_GAME_LOG_TITLE_UPDATED")
check(privateDB.questCache[1]==q and q.WasComplete==true,
  "D27_SEPARATE_QUEST_OBJECT_RETAINED")
reset:GetAllQuestIdsNoObjectives()
check(player.currentQuestlog[1]==q and
  q.LocalizedName=="SYNTHETIC_RENAMED",
  "D28_ORIGINAL_RESET_REUSES_OBJECT_AFTER_LOG_UPDATE")
check(counts.query==2,"D29_SOURCE_RESET_STILL_NO_DB_QUERY")

-- Explicit cache invalidation below is FAKE HOST ACTION, NOT an action
-- performed by SmoothReset. The separate QuestieDB.Initialize *can* clear
-- questCache in source, but no native initialization occurs in this fixture.
privateDB.questCache={}
check(privateDB.questCache[1]==nil and
  player.currentQuestlog[1]==q,"D30_HOST_CLEAR_DID_NOT_RETROACTIVELY_REPLACE_LOG")
local replacement=db.GetQuest(1)
check(replacement~=q and replacement.Id==1,
  "D31_ORIGINAL_COLD_GETQUEST_AFTER_HOST_CLEAR_NEW_IDENTITY")
check(counts.query==3 and privateDB.questCache[1]==replacement,
  "D32_ORIGINAL_NEW_OBJECT_QUERIED_AND_CACHED")
check(replacement.WasComplete==nil,"D33_NEW_DB_OBJECT_HAS_NO_INVENTED_FLAG")
check(q.WasComplete==true,"D34_OLD_OBJECT_FLAG_NOT_ERASED")
reset:GetAllQuestIdsNoObjectives()
check(player.currentQuestlog[1]==replacement,
  "D35_ORIGINAL_RESET_REBINDS_AFTER_HOST_DB_CACHE_CLEAR")
check(player.currentQuestlog[1].WasComplete==nil,
  "D36_NEW_QUESTLOG_OBJECT_NO_OLD_FLAG")
check(counts.query==3,"D37_REBIND_CACHE_HIT")
check(counts.completeSound==0,
  "D38_NUMERIC_ZERO_TO_ONE_NOT_SOURCE_SOUND")
check(#errors==0,"D39_NO_FAKE_ERRORS_DURING_VALID_OBJECT_PATH")
assert(n==39,"ORIGINAL_QUESTIEDB_CACHE_TEST_CENSUS:"..n)
print("PUBLIC G08 PART46 ORIGINAL FULL QUESTIEDB CACHE: 39/39 PASS")
print("PUBLIC G08 PART46 GENUINE SOURCE: whole original QuestieDB.GetQuest, whole original QuestLogCache and original GetAllQuestIdsNoObjectives function body; synthetic QueryQuest, adapter, module dependencies, client questlog and cache invalidation.")
print("PUBLIC G08 PART46 LIMITS: fake persisted WasComplete, fake game data, no native quest event, full original QuestieDB.Initialize, real 3.3.5a frames or actual character state.")
