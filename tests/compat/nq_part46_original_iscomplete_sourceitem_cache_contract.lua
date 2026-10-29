-- PUBLIC-SAFE TEST ONLY: unchanged original QuestieDB.IsComplete / QuestieQuest.CheckQuestSourceItem.
-- Whole original QuestLogCache under invented game log and bags; no actual client.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"ORIGINAL_FILE_MISSING:"..path)
  local body=assert(f:read("*a"));f:close();return body
end
local dbSource=read("Database/QuestieDB.lua")
local questSource=read("Modules/Quest/QuestieQuest.lua")
local cacheSource=read("Modules/Quest/QuestLogCache.lua")
local function extract(src,first,last)
  local x=assert(src:find(first,1,true),"MISSING_ORIGINAL_BEGIN:"..first)
  local y=assert(src:find(last,x+#first,true),"MISSING_ORIGINAL_END:"..first)
  return src:sub(x,y-1)
end
local originalComplete=extract(dbSource,"function QuestieDB.IsComplete(questId)",
  "\n---@param questLevel number")
local originalSourceItem=extract(questSource,
  "function QuestieQuest:CheckQuestSourceItem(questId, makeObjective)",
  "\nlocal function _GetIconScaleForAvailable()")
local function compile(code,name,env)
  local f
  if _VERSION=="Lua 5.1" then f=assert(loadstring(code,name));setfenv(f,env)
  else f=assert(load(code,name,"t",env)) end
  f()
end
local total=0
local function check(v,key) assert(v,key);total=total+1 end
check(originalComplete:find("QuestLogCache.questLog_DO_NOT_MODIFY",1,true)~=nil,
  "I01_ORIGINAL_COMPLETE_READS_QUESTLOG_CACHE")
check(originalComplete:find("QuestieQuest:CheckQuestSourceItem",1,true)~=nil,
  "I02_ORIGINAL_COMPLETE_CALLS_ORIGINAL_ITEM_CHECK")
check(originalSourceItem:find("QuestieCompat.GetContainerItemInfo",1,true)~=nil,
  "I03_ORIGINAL_ITEM_CHECK_READS_BAG_API")
check(cacheSource:find("QuestLogCache.CheckForChanges",1,true)~=nil,
  "I04_WHOLE_ORIGINAL_GAME_CACHE_SOURCE")

local function host(opts)
  local game={title="FAKE_QUEST",ready=opts.ready~=false,
    complete=opts.complete,sourceItem=opts.sourceItem or 5,
    haveItem=opts.haveItem or false,
    objectives=opts.objectives or {}}
  local reads={questlog=0,objective=0,bagSlots=0,bagItems=0,getQuest=0,
    sourceChecks=0,completeSound=0}
  local modules={
    QuestieLib={TrimObjectiveText=function(txt)return txt end},
    Sounds={PlayObjectiveComplete=function()end,
      PlayObjectiveProgress=function()end,
      PlayQuestComplete=function()reads.completeSound=reads.completeSound+1 end}
  }
  local loader={}
  function loader:CreateModule(name) modules[name]={};return modules[name] end
  function loader:ImportModule(name) return assert(modules[name],"MOCK_IMPORT:"..name) end
  local compat={
    GetQuestLogTitle=function(i)
      reads.questlog=reads.questlog+1
      if i~=1 then return nil end
      return game.title,nil,"normal",false,nil,game.complete,nil,1
    end,
    HaveQuestData=function(id) return id==1 and game.ready end,
    C_QuestLog={GetQuestObjectives=function(id,index)
      assert(id==1 and index==1)
      reads.objective=reads.objective+1
      return game.objectives
    end},
    GetContainerNumSlots=function(bag)
      reads.bagSlots=reads.bagSlots+1
      if bag==0 and game.haveItem then return 1 end
      return 0
    end,
    GetContainerItemInfo=function(bag,slot)
      reads.bagItems=reads.bagItems+1
      assert(bag==0 and slot==1 and game.haveItem)
      return nil,nil,nil,nil,nil,nil,nil,nil,nil,game.sourceItem
    end
  }
  local quest={Id=1,sourceItemId=game.sourceItem,Objectives={}}
  local db={GetQuest=function(id)
      reads.getQuest=reads.getQuest+1
      if id==1 then return quest end
    end,
    QueryItemSingle=function(id,key)
      assert(id==game.sourceItem and key=="name")
      return "FAKE_SOURCE_ITEM"
    end}
  local reset={}
  function reset:GetAllLeaderBoardDetails(id)
    assert(id==1)
    return {}
  end
  local questie={DEBUG_INFO=1,DEBUG_CRITICAL=2,DEBUG_DEVELOP=3}
  function questie:Debug()end
  function questie:Warning()end
  function questie:Error()end
  local env={QuestieLoader=loader,QuestieCompat=compat,Questie=questie,
    QuestieDB=db,QuestieQuest=reset}
  setmetatable(env,{__index=_G})
  compile(cacheSource,"@ORIGINAL_335_QuestLogCache_FULL",env)
  local cache=assert(modules.QuestLogCache)
  env.QuestLogCache=cache
  compile(originalSourceItem,"=ORIGINAL_335_CheckQuestSourceItem",env)
  local underlying=reset.CheckQuestSourceItem
  function reset:CheckQuestSourceItem(...)
    reads.sourceChecks=reads.sourceChecks+1
    return underlying(self,...)
  end
  compile(originalComplete,"=ORIGINAL_335_IsComplete_and_wrapped_IsComplete",env)
  local missing,changes=cache.CheckForChanges(nil)
  return {cache=cache,db=db,reset=reset,quest=quest,game=game,
    missing=missing,changes=changes,reads=reads}
end

local objective={{text="FAKE_KILL_OBJECTIVE",type="monster",
  numFulfilled=0,numRequired=1,finished=false}}
local incomplete=host({complete=0,haveItem=false,objectives=objective})
check(not incomplete.missing and incomplete.changes[1]~=nil,
  "I05_ORIGINAL_CACHE_INSERTS_INCOMPLETE_OBJECTIVE")
check(incomplete.cache.questLog_DO_NOT_MODIFY[1].isComplete==0,
  "I06_ORIGINAL_QUESTLOG_NUMERIC_ZERO")
check(incomplete.db.IsComplete(1)==0,
  "I07_ORIGINAL_COMPLETE_RETURNS_ZERO_WITH_OBJECTIVE")
check(incomplete.reads.sourceChecks==1 and incomplete.reads.bagSlots==7,
  "I08_ORIGINAL_SOURCE_ITEM_CHECK_SCANS_SEVEN_FAKE_BAGS")
check(incomplete.reads.bagItems==0,
  "I09_ABSENT_SOURCE_NO_ITEM_SLOT_READS")
check(not incomplete.reset:CheckQuestSourceItem(1,false),
  "I10_ORIGINAL_SOURCE_ITEM_ABSENT")
check(incomplete.quest.Objectives[1]==nil,
  "I11_CHECK_WITHOUT_MAKE_OBJECTIVE_NO_MUTATION")

local present=host({complete=0,haveItem=true,objectives=objective})
check(present.cache.questLog_DO_NOT_MODIFY[1].isComplete==0,
  "I12_PRESENT_ITEM_QUEST_NOT_MARKED_COMPLETE")
check(present.reset:CheckQuestSourceItem(1,false),
  "I13_ORIGINAL_PRESENT_SOURCE_ITEM_TRUE")
check(present.reads.bagItems==1,
  "I14_ORIGINAL_ITEM_READ_TENTH_RETURN_VALUE")
check(present.db.IsComplete(1)==0,
  "I15_EXISTING_OBJECTIVE_OVERRIDES_PRESENT_ITEM")
check(present.reads.sourceChecks==2,
  "I16_COMPLETE_CALLS_SOURCE_ITEM_CHECK_EVEN_IF_CACHED")

local noObjectivePresent=host({haveItem=true})
check(noObjectivePresent.changes[1]~=nil and not noObjectivePresent.missing,
  "I17_ZERO_OBJECTIVES_ORIGINAL_CACHE_INITIALIZES")
check(#noObjectivePresent.cache.questLog_DO_NOT_MODIFY[1].objectives==0,
  "I18_ORIGINAL_EMPTY_QUEST_LOG_OBJECTIVES")
check(noObjectivePresent.db.IsComplete(1)==1,
  "I19_NO_OBJECTIVES_WITH_SOURCE_PRESENT_COMPLETE")
check(noObjectivePresent.reads.bagItems==1,
  "I20_NO_OBJECTIVE_ITEM_PRESENT_BAG_CHECK")

local noObjectiveMissing=host({haveItem=false})
check(noObjectiveMissing.db.IsComplete(1)==0,
  "I21_NO_OBJECTIVES_MISSING_SOURCE_INCOMPLETE")
check(noObjectiveMissing.reads.sourceChecks==1,
  "I22_ORIGINAL_DB_CALLS_SOURCE_CHECK")
check(not noObjectiveMissing.reset:CheckQuestSourceItem(1,true),
  "I23_MISSING_SOURCE_MAKE_OBJECTIVE_RETURNS_FALSE")
check(noObjectiveMissing.quest.Objectives[1] and
  noObjectiveMissing.quest.Objectives[1].Id==5 and
  noObjectiveMissing.quest.Objectives[1].Description=="FAKE_SOURCE_ITEM",
  "I24_ORIGINAL_MISSING_SOURCE_OBJECTIVE_MADE")
check(noObjectiveMissing.db.IsComplete(1)==0,
  "I25_SYNTHETIC_OBJECTIVE_MUTATION_NOT_IN_GAME_LOG_CACHE")

local complete=host({complete=1,haveItem=false,objectives=objective})
check(complete.db.IsComplete(1)==1,
  "I26_COMPLETED_GAME_LOG_TAKES_PRECEDENCE")
check(complete.reads.sourceChecks==1 and complete.reads.bagSlots==7,
  "I27_COMPLETE_GAME_LOG_STILL_SCANS_MISSING_SOURCE")
local failed=host({complete=-1,haveItem=false,objectives=objective})
check(failed.db.IsComplete(1)==-1,
  "I28_FAILED_GAME_LOG_TAKES_PRECEDENCE")
local noSource=host({sourceItem=0,haveItem=false,objectives={}})
check(noSource.reset:CheckQuestSourceItem(1,false),
  "I29_NO_SOURCE_ITEM_RETURNS_TRUE")
check(noSource.reads.bagSlots==0,
  "I30_NO_SOURCE_ITEM_SKIPS_BAGS")
check(noSource.db.IsComplete(1)==1,
  "I31_ZERO_OBJECTIVE_NO_SOURCE_ITEM_COMPLETE")

local cold=host({ready=false,haveItem=false})
check(cold.missing and next(cold.changes)==nil,
  "I32_ORIGINAL_CACHE_MISS_NOT_INSERTED")
check(next(cold.cache.questLog_DO_NOT_MODIFY)==nil,
  "I33_NO_CACHED_QUEST_WHEN_GAME_DATA_UNREADY")
check(cold.db.IsComplete(1)==0,
  "I34_UNREADY_GAME_QUEST_INCOMPLETE")
check(not cold.cache.TestGameCache(),
  "I35_ORIGINAL_RESET_STEP_ONE_MUST_WAIT")
cold.game.ready=true
local recovered,changed=cold.cache.CheckForChanges(nil)
check(not recovered and changed[1]~=nil,
  "I36_GAME_DATA_RECOVERY_INSERTS_ENTRY")
check(cold.db.IsComplete(1)==0,
  "I37_NO_OBJECTIVE_MISSING_ITEM_STAYS_INCOMPLETE")
check(cold.reads.getQuest>=2,
  "I38_ORIGINAL_SOURCE_ITEM_DEPENDENCY_REPEATED_ON_CACHE_CHECK")

-- Native timing and actual quest-state mutation are not verified.
-- This positive control retains the original GetQuest cache bridge in #366.
check(dbSource:find("QO.IsComplete = _IsComplete",1,true)~=nil,
  "I39_ORIGINAL_GETQUEST_BINDS_ITS_ISCOMPLETE_WRAPPER")
check(originalComplete:find("return QuestieDB.IsComplete(self.Id)",1,true)~=nil,
  "I40_ORIGINAL_METHOD_DELEGATES_TO_AUTHENTIC_FUNC")
assert(total==40,"ISCOMPLETE_SOURCE_CENSUS:"..total)
print("PUBLIC G08 PART46 ORIGINAL COMPLETE AND SOURCE ITEM: 40/40 PASS")
print("PUBLIC G08 PART46 ORIGINAL FUNCTIONS: complete QuestieDB.IsComplete, QuestieQuest.CheckQuestSourceItem and whole QuestLogCache under fake WoW quest-log/bag APIs.")
print("PUBLIC G08 PART46 LIMITS: QuestieDB.GetQuest supplied by mock in THIS fixture; native event order, actual bags/quest cache, game client, and player state untested.")
