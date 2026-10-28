-- PUBLIC-SAFE TEST-ONLY: authentic original QuestLogCache full module in a fake WoW API.
-- Do not use real accounts, character data, SavedVariables, client or networking.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"ORIGINAL_SOURCE_NOT_FOUND:"..path)
  local v=assert(f:read("*a"));f:close();return v
end
local cacheSource=read("Modules/Quest/QuestLogCache.lua")
local questSource=read("Modules/Quest/QuestieQuest.lua")
local function extract(src,first,last)
  local i=assert(src:find(first,1,true),"SOURCE_BEGIN_MISSING:"..first)
  local j=assert(src:find(last,i+#first,true),"SOURCE_END_MISSING:"..first)
  return src:sub(i,j-1)
end
local originalGetLog=extract(questSource,
  "function QuestieQuest:GetAllQuestIdsNoObjectives()","\n-- iterate all notes")
local function compile(code,name,env)
  local fn
  if _VERSION=="Lua 5.1" then fn=assert(loadstring(code,name));setfenv(fn,env)
  else fn=assert(load(code,name,"t",env)) end
  fn()
end
local assertions=0
local function check(value,label)
  assert(value,label);assertions=assertions+1
end
check(cacheSource:find("QuestLogCache.questLog_DO_NOT_MODIFY = cache",1,true)~=nil,
  "C01_AUTHENTIC_CACHE_EXPOSED")
check(cacheSource:find("function QuestLogCache.CheckForChanges(",1,true)~=nil,
  "C02_AUTHENTIC_CACHE_CHECKER")
check(cacheSource:find("function QuestLogCache.TestGameCache()",1,true)~=nil,
  "C03_AUTHENTIC_READINESS")
check(originalGetLog:find("local quest = QuestieDB.GetQuest(questId)",1,true)~=nil,
  "C04_RESET_QUEST_OBJECT_READER")

local function harness()
  local game={
    title="SYNTHETIC_QUEST",tag="normal",complete=0,ready=true,header=false,
    objectives={{text="SYNTHETIC_OBJECTIVE",type="item",
      numFulfilled=0,numRequired=2,finished=false}}
  }
  local sounds={questComplete=0,objectiveComplete=0,objectiveProgress=0}
  local modules={}
  modules.QuestieLib={TrimObjectiveText=function(text) return text end}
  modules.Sounds={
    PlayQuestComplete=function() sounds.questComplete=sounds.questComplete+1 end,
    PlayObjectiveComplete=function() sounds.objectiveComplete=sounds.objectiveComplete+1 end,
    PlayObjectiveProgress=function() sounds.objectiveProgress=sounds.objectiveProgress+1 end
  }
  local loader={}
  function loader:CreateModule(name)
    modules[name]={};return modules[name]
  end
  function loader:ImportModule(name)
    return assert(modules[name],"UNEXPECTED_IMPORT:"..tostring(name))
  end
  local compat={
    GetQuestLogTitle=function(index)
      if index~=1 or not game.title then return nil end
      return game.title,nil,game.tag,game.header,nil,game.complete,nil,1
    end,
    HaveQuestData=function(id) return id==1 and game.ready end,
    C_QuestLog={GetQuestObjectives=function(id,index)
      assert(id==1 and index==1,"SYNTHETIC_WRONG_QUEST")
      return game.objectives
    end}
  }
  local errors={}
  local questie={DEBUG_INFO=1,DEBUG_CRITICAL=2,DEBUG_DEVELOP=3,IsSoD=false,_sessionWarnings={}}
  function questie:Debug()end
  function questie:Error(...) errors[#errors+1]={...} end
  function questie:Warning(...)errors[#errors+1]={...} end
  local player={currentQuestlog={}}
  local dbQuest={Id=1,WasComplete=true,sourceItemId=5}
  local db={QuestPointers={[1]=true}}
  local dbCalls=0
  function db.GetQuest(id)
    dbCalls=dbCalls+1
    if id==1 then return dbQuest end
    return nil
  end
  local reset={}
  local env={QuestieLoader=loader,QuestieCompat=compat,Questie=questie,
    QuestiePlayer=player,QuestieDB=db,QuestieQuest=reset}
  setmetatable(env,{__index=_G})
  compile(cacheSource,"@original_335/Modules/Quest/QuestLogCache.lua",env)
  local cache=assert(modules.QuestLogCache)
  env.QuestLogCache=cache -- mirror QuestieLoader export for original QuestieQuest
  -- Only the two source-item *helpers* are synthetic; original GetAllQuestIds
  -- is unchanged. The original full QuestLogCache runs from its original blob.
  local fakeHelpers="local _AddSourceItemObjective=function() end\n"
    .."local _AddRequiredSourceItemObjective=function() end\n"
  compile(fakeHelpers..originalGetLog,
    "=original_335_GetAllQuestIdsNoObjectives_with_fake_objective_helpers",env)
  return {game=game,cache=cache,reset=reset,player=player,dbQuest=dbQuest,
    sounds=sounds,errors=errors,dbCalls=function()return dbCalls end}
end

-- Positive control: authentic original cache code initializes from a fake API.
local a=harness()
check(next(a.cache.questLog_DO_NOT_MODIFY)==nil,"C05_COLD_CACHE_EMPTY")
check(a.cache.TestGameCache(),"C06_VALID_FAKE_GAME_DATA_READY")
local miss,delta=a.cache.CheckForChanges(nil)
check(not miss and delta[1] and delta[1][1]==1,
  "C07_ORIGINAL_FIRST_PARTY_CACHE_INSERT")
local originalEntry=a.cache.questLog_DO_NOT_MODIFY[1]
check(originalEntry.title=="SYNTHETIC_QUEST" and originalEntry.isComplete==0,
  "C08_GAME_LOG_FIELDS_STORED")
check(originalEntry.WasComplete==nil,"C09_GAME_CACHE_HAS_NO_WASCOMPLETE")
check(originalEntry.objectives[1].raw_text=="SYNTHETIC_OBJECTIVE",
  "C10_ORIGINAL_OBJECTIVE_READER_EXECUTED")
check(a.cache.GetQuest(1)==originalEntry,"C11_ORIGINAL_CACHE_GETTER_IDENTITY")
check(a.cache.GetQuestObjectives(1)==originalEntry.objectives,
  "C12_ORIGINAL_CACHE_OBJECTIVE_GETTER")
a.reset:GetAllQuestIdsNoObjectives()
check(a.player.currentQuestlog[1]==a.dbQuest,
  "C13_ORIGINAL_RESET_CONSUMES_GAME_CACHE_ID_AND_FAKE_DB_OBJECT")
check(a.dbCalls()==1 and a.dbQuest.LocalizedName=="SYNTHETIC_QUEST",
  "C14_ORIGINAL_RESET_LOOKUP_AND_LOCALIZED_NAME")
check(a.dbQuest.WasComplete==true and originalEntry.WasComplete==nil,
  "C15_SEPARATE_DB_OBJECT_FLAG_NOT_IN_GAME_CACHE")

-- The real original cache does not own that separate fake quest-object flag.
a.game.complete=1
a.game.objectives={{text="SYNTHETIC_OBJECTIVE",type="item",
  numFulfilled=2,numRequired=2,finished=true}}
local miss2,delta2=a.cache.CheckForChanges(nil)
check(not miss2 and delta2[1] and delta2[1][1]==1,
  "C16_ORIGINAL_GAME_COMPLETE_TRANSITION_RECORDED")
check(a.sounds.questComplete==1,"C17_ORIGINAL_CACHE_QUEST_COMPLETE_SIGNAL")
local finishedEntry=a.cache.questLog_DO_NOT_MODIFY[1]
check(finishedEntry.isComplete==1 and
  finishedEntry.objectives[1].numFulfilled==2,
  "C18_ORIGINAL_COMPLETION_CACHE_ENTRY")
check(a.dbQuest.WasComplete==true,"C19_SEPARATE_FAKE_DB_FLAG_SURVIVES")
a.reset:GetAllQuestIdsNoObjectives()
check(a.player.currentQuestlog[1]==a.dbQuest and a.dbCalls()==2,
  "C20_SECOND_ORIGINAL_RESET_REUSES_FAKE_DB_OBJECT")

-- Missing game data: original cache retains a previous snapshot but readiness
-- disallows reset step 1. It does not erase prior cached entries.
a.game.ready=false
check(not a.cache.TestGameCache(),"C21_GAME_DATA_UNREADY")
local miss3,delta3=a.cache.CheckForChanges(nil)
check(miss3 and next(delta3)==nil,"C22_ORIGINAL_CACHE_MISS_REPORTED")
check(a.cache.questLog_DO_NOT_MODIFY[1]==finishedEntry,
  "C23_PREVIOUS_GAME_CACHE_SNAPSHOT_RETAINED")
check(a.dbQuest.WasComplete==true,"C24_FAKE_DB_QUEST_FLAG_UNALTERED")

-- When only objective text is unavailable but old objective exists, the
-- original GetNewObjectives falls back to old data without reporting cacheMiss.
a.game.ready=true
a.game.objectives={{text=" pending",type="item",
  numFulfilled=2,numRequired=2,finished=true}}
check(not a.cache.TestGameCache(),"C25_UNCACHED_OBJECTIVE_TEXT_NOT_READY")
local miss4,delta4=a.cache.CheckForChanges(nil)
check(not miss4 and next(delta4)==nil,
  "C26_ORIGINAL_OBJECTIVE_FALLBACK_NOT_AN_EXPLICIT_MISS")
check(a.cache.questLog_DO_NOT_MODIFY[1]==finishedEntry,
  "C27_FALLBACK_PRESERVES_CACHED_OBJECTIVE")
a.game.objectives={{text="SYNTHETIC_RECOVERED",type="item",
  numFulfilled=2,numRequired=2,finished=true}}
local miss5,delta5=a.cache.CheckForChanges(nil)
check(not miss5 and delta5[1] and delta5[1][1]==1,
  "C28_NEW_OBJECTIVE_TEXT_UPDATES_CACHE")
check(a.cache.TestGameCache(),"C29_READY_AFTER_TEXT_RECOVERY")
check(a.cache.questLog_DO_NOT_MODIFY[1].objectives[1].raw_text=="SYNTHETIC_RECOVERED",
  "C30_RECOVERED_OBJECTIVE_PERSISTED")

-- Cold miss must not fabricate a QuestLogCache entry; once game data returns,
-- the same authentic checker can create one without any game/realm access.
local cold=harness()
cold.game.ready=false
local coldMiss,coldChanges=cold.cache.CheckForChanges(nil)
check(coldMiss and next(coldChanges)==nil,"C31_COLD_GAME_MISS")
check(next(cold.cache.questLog_DO_NOT_MODIFY)==nil,"C32_COLD_MISS_NO_ENTRY")
check(not cold.cache.TestGameCache(),"C33_COLD_RESET_WAIT")
cold.reset:GetAllQuestIdsNoObjectives()
check(next(cold.player.currentQuestlog)==nil and cold.dbCalls()==0,
  "C34_COLD_RESET_NO_QUEST_OBJECT")
cold.game.ready=true
local warmMiss,warmChanges=cold.cache.CheckForChanges(nil)
check(not warmMiss and warmChanges[1]~=nil,"C35_WARM_CACHE_INIT")
cold.reset:GetAllQuestIdsNoObjectives()
check(cold.player.currentQuestlog[1]==cold.dbQuest and cold.dbCalls()==1,
  "C36_WARM_RESET_READS_FAKE_QUEST_OBJECT")

-- A synthetic header is deliberately excluded from the original cache.
local header=harness()
header.game.header=true
local hmiss,hchanges=header.cache.CheckForChanges(nil)
check(not hmiss and next(hchanges)==nil,"C37_HEADERS_NOT_QUESTS")
check(next(header.cache.questLog_DO_NOT_MODIFY)==nil,
  "C38_HEADER_NOT_CACHED")
check(header.cache.TestGameCache(),"C39_HEADER_SKIPPED_FOR_READINESS")

-- A cold uncached objective also prevents first-party insertion.
local blank=harness()
blank.game.objectives={{text=" not yet cached",type="item",
  numFulfilled=0,numRequired=2,finished=false}}
local bmiss,bchanges=blank.cache.CheckForChanges(nil)
check(bmiss and next(bchanges)==nil,"C40_COLD_OBJECTIVE_TEXT_MISS")
check(next(blank.cache.questLog_DO_NOT_MODIFY)==nil,
  "C41_COLD_OBJECTIVE_DOES_NOT_CREATE_PARTIAL_CACHE")
check(not blank.cache.TestGameCache(),"C42_COLD_OBJECTIVE_PREVENTS_READY")

assert(assertions==42,"ORIGINAL_QUESTLOGCACHE_ASSERTION_CENSUS:"..assertions)
print("PUBLIC G08 PART46 AUTHENTIC FULL QUESTLOGCACHE: 42/42 PASS")
print("PUBLIC G08 PART46 SOURCE: whole unchanged QuestLogCache module and original reset GetAllQuestIdsNoObjectives body, under fake client questlog/objective API.")
print("PUBLIC G08 PART46 LIMITS: independent QuestieDB.GetQuest, game questlog/inventory/frames, objective helper functions and native scheduling remain fake or unexecuted.")
