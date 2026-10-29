-- TEST-ONLY INTEGRATED original-source path under MOCK 3.3.5 APIs.
-- Real original QuestieDB.GetQuest, QuestieDB.IsComplete/_IsComplete,
-- QuestieQuest.CheckQuestSourceItem, whole QuestLogCache and
-- QuestieQuest.GetAllQuestIdsNoObjectives. No native client.
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
local authenticComplete=extract(dbSource,
  "function QuestieDB.IsComplete(questId)","\n---@param questLevel number")
local authenticItem=extract(questSource,
  "function QuestieQuest:CheckQuestSourceItem(questId, makeObjective)",
  "\nlocal function _GetIconScaleForAvailable()")
local function compile(s,name,env)
  local f
  if _VERSION=="Lua 5.1" then f=assert(loadstring(s,name));setfenv(f,env)
  else f=assert(load(s,name,"t",env)) end
  f()
end
local n=0
local function check(ok,tag) assert(ok,tag);n=n+1 end
local rawQuest={[1]={[1]={},[2]={},[3]=5}}
local game={ready=true,title="SYNTHETIC_QUEST",complete=0,tag="normal",haveItem=false,
  objectives={{text="SYNTHETIC_OBJECTIVE",type="item",numFulfilled=0,numRequired=2,finished=false}}}
local counts={query=0,questLogReads=0,objectiveReads=0,completeSound=0,bagSlot=0,bagItem=0}
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
  end},
  GetContainerNumSlots=function(bag)
    counts.bagSlot=counts.bagSlot+1
    return bag==0 and game.haveItem and 1 or 0
  end,
  GetContainerItemInfo=function(bag,slot)
    counts.bagItem=counts.bagItem+1
    assert(bag==0 and slot==1 and game.haveItem)
    return nil,nil,nil,nil,nil,nil,nil,nil,nil,5
  end
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
function db.QueryItemSingle(id,key)
  assert(id==5 and key=="name")
  return "SYNTHETIC_ITEM"
end
local privateDB={questCache={}}
local player={currentQuestlog={}}
local reset={}
function reset:GetAllLeaderBoardDetails(id)
  assert(id==1)
  return {}
end
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
  .."local bitband=function() error('UNEXPECTED_BITBAND') end\n"
  .."local tinsert=table.insert\n"
compile(authenticItem,"=original_335_CheckQuestSourceItem_fake_bag",env)
compile(sourceShim..authenticComplete..authenticGetQuest,
  "=original_335_IsComplete_and_FULL_GetQuest_with_fake_dependencies",env)
compile("local _AddSourceItemObjective=function()end\n"
  .."local _AddRequiredSourceItemObjective=function()end\n"
  ..authenticGetLog,
  "=original_335_GetAllQuestIdsNoObjectives_with_fake_sourceitem_helpers",env)


-- Five original first-party source functions execute in this same fixture,
-- with fake QuestieDB QueryQuest rawdata, fake game questlog and fake bags.
check(authenticGetQuest:find("_QuestieDB.questCache[questId] = QO",1,true)~=nil,
  "J01_WHOLE_ORIGINAL_GETQUEST_CACHE_WRITE")
check(authenticComplete:find("return QuestieDB.IsComplete(self.Id)",1,true)~=nil,
  "J02_ORIGINAL_ISCOMPLETE_METHOD_WRAPPER")
check(authenticItem:find("QuestieCompat.GetContainerItemInfo",1,true)~=nil,
  "J03_ORIGINAL_ITEM_CHECK_FUNCTION")
check(cacheSource:find("QuestLogCache.questLog_DO_NOT_MODIFY = cache",1,true)~=nil,
  "J04_WHOLE_ORIGINAL_GAME_LOG_CACHE")
check(authenticGetLog:find("QuestieDB.GetQuest(questId)",1,true)~=nil,
  "J05_ORIGINAL_RESET_CALLS_ORIGINAL_GETQUEST")
check(next(privateDB.questCache)==nil,"J06_DB_CACHE_COLD")
check(next(cache.questLog_DO_NOT_MODIFY)==nil,"J07_GAME_CACHE_COLD")
local q=db.GetQuest(1)
check(q and q.Id==1 and privateDB.questCache[1]==q,
  "J08_ORIGINAL_DB_CONSTRUCTS_AND_CACHES_QUEST")
check(q.IsComplete~=nil and q.sourceItemId==5,
  "J09_ORIGINAL_DB_INSTALLS_REAL_ISCOMPLETE_WRAPPER")
check(counts.query==1,"J10_RAW_QUEST_QUERIED_ONCE")
check(q:IsComplete()==0,
  "J11_WITHOUT_GAME_LOG_REAL_ISCOMPLETE_INCOMPLETE")
check(counts.bagSlot==7 and counts.bagItem==0,
  "J12_REAL_ISCOMPLETE_CHECKS_MISSING_SOURCE_IN_SEVEN_FAKE_BAGS")
local miss,changes=cache.CheckForChanges(nil)
check(not miss and changes[1]~=nil,
  "J13_WHOLE_GAME_LOG_CACHE_FROM_FAKE_QUEST_API")
check(cache.questLog_DO_NOT_MODIFY[1].isComplete==0
  and cache.questLog_DO_NOT_MODIFY[1].objectives[1]~=nil,
  "J14_GAME_LOG_NUMERIC_ZERO_AND_OBJECTIVE")
check(q:IsComplete()==0,
  "J15_REAL_METHOD_READS_GAME_CACHE_AND_REQUIRED_SOURCE")
check(db.GetQuest(1)==q and counts.query==1,
  "J16_CACHED_DB_OBJECT_REUSED")
reset:GetAllQuestIdsNoObjectives()
check(player.currentQuestlog[1]==q,
  "J17_ORIGINAL_RESET_LOG_BRIDGE_REUSES_ORIGINAL_DB_OBJECT")
check(q.LocalizedName=="SYNTHETIC_QUEST",
  "J18_ORIGINAL_RESET_BRIDGE_COPIES_FAKE_LOCALIZED_TITLE")

-- Source item present: the genuine original method calls the real item checker,
-- but the objective list still makes the quest incomplete.
game.haveItem=true
local beforeBagItem=counts.bagItem
check(reset:CheckQuestSourceItem(1,false),
  "J19_REAL_SOURCE_CHECK_FINDS_SYNTHETIC_ITEM")
check(counts.bagItem==beforeBagItem+1,
  "J20_TENTH_FAKE_ITEMINFO_RETURN_READ")
check(q:IsComplete()==0,
  "J21_PRESENT_ITEM_WITH_OBJECTIVE_STILL_INCOMPLETE")
game.objectives={}
local emptyMiss,emptyChanges=cache.CheckForChanges(nil)
check(not emptyMiss and emptyChanges[1]~=nil,
  "J22_ORIGINAL_CACHE_TRANSITION_TO_EMPTY_OBJECTIVES")
check(#cache.questLog_DO_NOT_MODIFY[1].objectives==0,
  "J23_ORIGINAL_CACHE_EMPTY_OBJECTIVES")
check(q:IsComplete()==1,
  "J24_ORIGINAL_GETQUEST_ISCOMPLETE_EMPTY_OBJS_PRESENT_SOURCE")

-- Original source item disappears; same cached original DB QO now computes 0.
game.haveItem=false
check(q:IsComplete()==0,
  "J25_ORIGINAL_QO_NOW_INCOMPLETE_WHEN_SOURCE_REMOVED")
check(privateDB.questCache[1]==q and counts.query==1,
  "J26_ORIGINAL_CACHED_OBJECT_IDENTITY_PERSISTS_CHANGE")

-- Completed flag in game quest log wins the original expression, even though
-- CheckQuestSourceItem still runs and finds the source item absent.
game.complete=1
local completeMiss,completeChanges=cache.CheckForChanges(nil)
check(not completeMiss and completeChanges[1]~=nil,
  "J27_GAME_CACHE_COMPLETION_FLAG_UPDATES")
local beforeCompleteScan=counts.bagSlot
check(q:IsComplete()==1,
  "J28_REAL_ISCOMPLETE_RETURNS_COMPLETE_FROM_GAME_CACHE")
check(counts.bagSlot==beforeCompleteScan+7,
  "J29_REAL_ISCOMPLETE_STILL_INSPECTS_FAKE_BAGS")

-- ONLY the fixture injects WasComplete; no native completion event fires.
q.WasComplete=true
game.complete=0
local backMiss,backChanges=cache.CheckForChanges(nil)
check(not backMiss and backChanges[1]~=nil,
  "J30_GAME_CACHE_COMPLETION_RESET_TO_ZERO")
check(q:IsComplete()==0 and q.WasComplete==true,
  "J31_REAL_METHOD_INCOMPLETE_BUT_TEST_FLAG_STILL_SET")
reset:GetAllQuestIdsNoObjectives()
check(player.currentQuestlog[1]==q and q.WasComplete==true,
  "J32_ORIGINAL_RESET_REUSES_TEST_FLAGGED_ORIGINAL_OBJECT")
check(not reset:CheckQuestSourceItem(1,true),
  "J33_REAL_SOURCE_CHECK_MISSING_ITEM_CREATES_OPTIONAL_OBJECTIVE")
check(q.Objectives[1] and q.Objectives[1].Id==5 and
  q.Objectives[1].Description=="SYNTHETIC_ITEM",
  "J34_ORIGINAL_SOURCE_MISSING_ITEM_OBJECTIVE_STORED_ON_QO")
check(counts.query==1,"J35_NO_EXTRA_QUERY_DURING_RESET_OR_ITEM_CHECK")

-- Fake host-only database cache clear, never asserted to be a reset operation.
privateDB.questCache={}
local replacement=db.GetQuest(1)
check(replacement~=q and replacement.WasComplete==nil,
  "J36_FAKE_DB_INVALIDATION_CHANGES_QUEST_IDENTITY")
check(counts.query==2 and privateDB.questCache[1]==replacement,
  "J37_REPLACEMENT_CREATED_BY_WHOLE_ORIGINAL_GETQUEST")
check(replacement:IsComplete()==0,
  "J38_NEW_ORIGINAL_QUEST_OBJECT_READS_SAME_GAME_CACHE_STATE")
reset:GetAllQuestIdsNoObjectives()
check(player.currentQuestlog[1]==replacement and
  player.currentQuestlog[1].WasComplete==nil,
  "J39_ORIGINAL_RESET_REBINDS_NEW_SOURCE_QUEST_OBJECT")
check(q.WasComplete==true and q~=replacement,
  "J40_OLD_TEST_INJECTED_FLAG_STAYS_ON_UNREFERENCED_OBJECT")
check(#errors==0,"J41_NO_MOCK_ERROR_IN_INTEGRATED_SOURCE_CHAIN")
check(counts.completeSound==0,
  "J42_NUMERIC_COMPLETION_NOT_TRIGGERING_OLD_CACHED_SOUND")
assert(n==42,"PART46_INTEGRATED_SOURCE_CHECK_CENSUS:"..n)
print("PUBLIC G08 PART46 INTEGRATED REAL CACHE COMPLETE ITEM: 42/42 PASS")
print("PUBLIC G08 PART46 REAL SOURCES: full unchanged QuestieDB.GetQuest, IsComplete/_IsComplete, QuestieQuest.CheckQuestSourceItem, whole QuestLogCache, original reset GetAllQuestIdsNoObjectives; fake APIs.")
print("PUBLIC G08 PART46 NO NATIVE CLAIM: game log, inventory, query database, frame timing and WasComplete flag trigger remain synthetic.")
