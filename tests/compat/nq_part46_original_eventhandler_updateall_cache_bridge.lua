-- TEST ONLY: whole authentic QuestLogCache + unchanged QuestEventHandler:UpdateAllQuests.
-- No actual WoW events, frame, character, quest DB or native scheduler.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"ORIGINAL_SOURCE_MISSING:"..path)
  local s=assert(f:read("*a"));f:close();return s
end
local cacheSource=read("Modules/Quest/QuestLogCache.lua")
local handlerSource=read("Modules/Quest/QuestEventHandler.lua")
local function extract(s,a,b)
  local i=assert(s:find(a,1,true),"ORIGINAL_BEGIN_NOT_FOUND")
  local j=assert(s:find(b,i+#a,true),"ORIGINAL_END_NOT_FOUND")
  return s:sub(i,j-1)
end
local originalUpdate=extract(handlerSource,
  "function _QuestEventHandler:UpdateAllQuests()",
  "\nlocal lastTimeQuestRelatedFrameClosedEvent")
local function compile(src,name,env)
  local fn
  if _VERSION=="Lua 5.1" then fn=assert(loadstring(src,name));setfenv(fn,env)
  else fn=assert(load(src,name,"t",env)) end
  fn()
end
local tests=0
local function check(ok,label) assert(ok,label);tests=tests+1 end
check(originalUpdate:find("QuestLogCache.CheckForChanges(questIdsToCheck)",1,true)~=nil,
  "H01_ORIGINAL_EVENT_CHECKS_GAME_LOG_CACHE")
check(originalUpdate:find("QuestieQuest:UpdateQuest(questId)",1,true)~=nil,
  "H02_ORIGINAL_EVENT_CONDITIONAL_UPDATE_CALL_SITE")
check(handlerSource:find("QuestLogCache.RemoveQuest(questId)",1,true)~=nil,
  "H03_ORIGINAL_EVENT_HAS_REMOVE_ON_OTHER_PATHS")
check(cacheSource:find("#cachedObjectives == #newObjectives and #cachedObjectives > 0",1,true)~=nil,
  "H04_ORIGINAL_CACHE_ZERO_COUNT_CHANGE_GUARD")

local game={ready=true,title="SYNTHETIC_ACCEPTED",complete=0,
  objectives={{text="SYNTHETIC_TASK",type="monster",
    numFulfilled=0,numRequired=1,finished=false}}}
local tallies={questCalls=0,objCalls=0,dirty=0,updates=0,
  nameplate=0,queued=0,completeSounds=0,objectiveSounds=0}
local notes={updated={},dirty={}}
local modules={QuestieLib={TrimObjectiveText=function(s) return s end}}
modules.Sounds={
  PlayQuestComplete=function()tallies.completeSounds=tallies.completeSounds+1 end,
  PlayObjectiveComplete=function()tallies.objectiveSounds=tallies.objectiveSounds+1 end,
  PlayObjectiveProgress=function()tallies.objectiveSounds=tallies.objectiveSounds+1 end
}
local loader={}
function loader:CreateModule(name) modules[name]={};return modules[name] end
function loader:ImportModule(name)
  return assert(modules[name],"FAKE_LOADER_MODULE_MISSING:"..name)
end
local compat={
  GetQuestLogTitle=function(index)
    tallies.questCalls=tallies.questCalls+1
    if index~=1 then return nil end
    return game.title,nil,"normal",false,nil,game.complete,nil,1
  end,
  HaveQuestData=function(id) return id==1 and game.ready end,
  C_QuestLog={GetQuestObjectives=function(id,index)
    assert(id==1 and index==1,"FAKE_OBJECTIVE_REQUEST_OTHER_QUEST")
    tallies.objCalls=tallies.objCalls+1
    return game.objectives
  end}
}
local questie={DEBUG_INFO=1,DEBUG_DEVELOP=2,DEBUG_CRITICAL=3}
function questie:Debug()end
function questie:Error()end
function questie:Warning()end
local quest={SetObjectivesDirty=function(_,id)
    tallies.dirty=tallies.dirty+1
    notes.dirty[#notes.dirty+1]=id
  end,
  UpdateQuest=function(_,id)
    tallies.updates=tallies.updates+1
    notes.updated[#notes.updated+1]=id
  end}
local nameplate={UpdateNameplate=function()
  tallies.nameplate=tallies.nameplate+1
end}
local combat={Queue=function(_,fn)
  -- Intentionally do NOT run the queued C_Timer.After or real tracker.
  assert(type(fn)=="function")
  tallies.queued=tallies.queued+1
end}
local event={}
local states={QUEST_ACCEPTED=7,QUEST_ABANDONED=9}
local tracking={[1]={state=states.QUEST_ACCEPTED}}
local env={Questie=questie,QuestieCompat=compat,QuestieLoader=loader,
  QuestieQuest=quest,QuestieNameplate=nameplate,QuestieCombatQueue=combat,
  QUEST_LOG_STATES=states,_QuestEventHandler=event,TRACKING=tracking}
setmetatable(env,{__index=_G})
compile(cacheSource,"@ORIGINAL_335/Modules/Quest/QuestLogCache.lua",env)
local cache=assert(modules.QuestLogCache)
env.QuestLogCache=cache
-- The original whole handler function BODY is unchanged. The source-level
-- questLog and doFullQuestLogScan surrounding upvalues are fake host state.
compile("local questLog=TRACKING\nlocal doFullQuestLogScan=false\n"
  ..originalUpdate.."\n"
  .."function _QuestEventHandler:ProbeFullScan() return doFullQuestLogScan end\n",
  "=ORIGINAL_335_UpdateAllQuests_with_FAKE_local_questlog",env)

local coldMiss,coldChange=cache.CheckForChanges(nil)
check(not coldMiss and coldChange[1]~=nil,
  "H05_AUTHENTIC_CACHE_COLD_INSERT")
check(cache.questLog_DO_NOT_MODIFY[1].objectives[1].raw_numFulfilled==0,
  "H06_REAL_CACHE_INSERTED_INITIAL_OBJECTIVE")
check(tallies.updates==0 and tallies.dirty==0,
  "H07_INITIAL_CACHE_INSERT_NOT_AN_EVENTHANDLER_UPDATE")
event:UpdateAllQuests()
check(tallies.updates==0 and tallies.nameplate==0,
  "H08_UNCHANGED_ACCEPTED_QUEST_NOT_UPDATED")
check(tallies.queued==0,"H09_UNCHANGED_NO_QUEUE")
check(not event:ProbeFullScan(),"H10_UNCHANGED_NO_RETRY_FLAG")

game.objectives={{text="SYNTHETIC_TASK",type="monster",
  numFulfilled=1,numRequired=1,finished=true}}
event:UpdateAllQuests()
check(tallies.updates==1 and tallies.dirty==1,
  "H11_ORIGINAL_EVENT_UPDATES_FOR_CHANGED_OBJECTIVE")
check(notes.updated[1]==1 and notes.dirty[1]==1,
  "H12_ORIGINAL_EVENT_PASSES_ACCEPTED_QUEST_ID")
check(tallies.nameplate==1 and tallies.queued==1,
  "H13_ORIGINAL_EVENT_NAMEPLATE_AND_QUEUE_CALLS")
check(cache.questLog_DO_NOT_MODIFY[1].objectives[1].raw_numFulfilled==1,
  "H14_ORIGINAL_CACHE_RECORDS_PROGRESS")
event:UpdateAllQuests()
check(tallies.updates==1 and tallies.queued==1,
  "H15_NO_DUPLICATE_UPDATE_FOR_SAME_COMPLETION")

-- This is synthetic game API state only. The authentic old cache returns
-- no "changed objective" on the transition from one cached to zero.
game.objectives={}
event:UpdateAllQuests()
check(tallies.updates==1 and tallies.dirty==1,
  "H16_ONE_TO_ZERO_DOES_NOT_CALL_ORIGINAL_UPDATEQUEST")
check(tallies.nameplate==1 and tallies.queued==1,
  "H17_ONE_TO_ZERO_NO_EXTRA_TRACKER_QUEUE")
check(#cache.questLog_DO_NOT_MODIFY[1].objectives==1,
  "H18_ONE_TO_ZERO_ORIGINAL_CACHE_RETAINS_OLD_OBJECTIVE")
check(cache.TestGameCache(),
  "H19_TESTGAMECACHE_CAN_PASS_WHILE_OLD_OBJECTIVE_RETAINED")
check(not event:ProbeFullScan(),
  "H20_NO_CACHE_MISS_FLAG_FROM_ZERO_COUNT_TRANSITION")

-- Only a deliberate test-host call to the original RemoveQuest clears it.
-- The original event handler's UpdateAllQuests does NOT invoke RemoveQuest.
cache.RemoveQuest(1)
check(cache.questLog_DO_NOT_MODIFY[1]==nil,
  "H21_HOST_EXPLICIT_REMOVEQUEST_CLEARS_SOURCE_CACHE")
event:UpdateAllQuests()
check(tallies.updates==2 and tallies.dirty==2,
  "H22_ORIGINAL_EVENT_NOTICES_REBUILT_ENTRY")
check(cache.questLog_DO_NOT_MODIFY[1] and
  #cache.questLog_DO_NOT_MODIFY[1].objectives==0,
  "H23_ORIGINAL_GAME_CACHE_REBUILT_ZERO_OBJECTIVES")
check(tallies.nameplate==2 and tallies.queued==2,
  "H24_REAL_EVENT_QUEUES_ON_REBUILT_ENTRY")

-- A zero-objective cached entry does not even update when completion flag
-- changes in the fabricated client, absent explicit invalidation.
game.complete=1
event:UpdateAllQuests()
check(tallies.updates==2 and tallies.dirty==2,
  "H25_CACHED_EMPTY_OBJECTIVE_COMPLETION_CHANGE_UNOBSERVED")
check(cache.questLog_DO_NOT_MODIFY[1].isComplete==0,
  "H26_CACHED_EMPTY_QUEST_RETURNS_OLD_NUMERIC_FLAG")

-- Genuine original cacheMiss asks the event handler for future full scans.
game.ready=false
event:UpdateAllQuests()
check(event:ProbeFullScan(),"H27_GENUINE_MISSING_CLIENT_DATA_SET_RETRY_FLAG")
check(tallies.updates==2,"H28_CACHE_MISS_DOES_NOT_FALSE_UPDATE")
game.ready=true
event:UpdateAllQuests()
check(tallies.updates==2 and event:ProbeFullScan(),
  "H29_RECOVERED_STILL_NO_CHANGE_AND_ORIGINAL_RETRY_STICKY")
check(cache.questLog_DO_NOT_MODIFY[1].isComplete==0,
  "H30_OLD_CACHED_STATUS_REMAINS_UNLESS_REBUILD")

-- Accepted-state membership filters updates, even when fake objectives
-- change while a cached accepted quest is marked abandoned.
tracking[1].state=states.QUEST_ABANDONED
game.objectives={{text="SYNTHETIC_NEW",type="item",
  numFulfilled=0,numRequired=2,finished=false}}
event:UpdateAllQuests()
check(tallies.updates==2 and tallies.dirty==2,
  "H31_NONACCEPTED_LOG_ENTRY_NOT_UPDATED")
check(#cache.questLog_DO_NOT_MODIFY[1].objectives==0,
  "H32_NONACCEPTED_ENTRY_CACHE_NOT_REFRESHED")
tracking[1].state=states.QUEST_ACCEPTED
event:UpdateAllQuests()
check(tallies.updates==3 and tallies.dirty==3,
  "H33_REACCEPTED_SYNTHETIC_GAME_CHANGE_UPDATES")
check(#cache.questLog_DO_NOT_MODIFY[1].objectives==1,
  "H34_RECOVERED_CACHE_RECORDS_SOURCE_OBJECTIVE")
check(tallies.nameplate==3 and tallies.queued==3,
  "H35_EVENT_QUEUING_ONLY_FOR_CHANGED_ACCEPTED_ID")
check(notes.updated[3]==1,
  "H36_ORIGINAL_EVENT_UPDATES_CORRECT_FAKE_QUEST")
check(tallies.completeSounds==0,
  "H37_NUMERIC_ZERO_PREVENTS_COMPLETE_SOUND")
check(tallies.objCalls>0 and tallies.questCalls>0,
  "H38_WHOLE_CACHE_READS_FABRICATED_GAME_API")
assert(tests==38,"ORIGINAL_EVENT_CACHE_BRIDGE_CENSUS:"..tests)
print("PUBLIC G08 PART46 ORIGINAL EVENTHANDLER CACHE BRIDGE: 38/38 PASS")
print("PUBLIC G08 PART46 ORIGINAL: full original QuestLogCache and original QuestEventHandler.UpdateAllQuests BODY; mock client questlog/accepted-state, UpdateQuest sink, nameplate and combat queue.")
print("PUBLIC G08 PART46 NOT NATIVE: original UpdateQuest full BODY and real event ingress, actual quest states, frames and C_Timer.After not executed.")
