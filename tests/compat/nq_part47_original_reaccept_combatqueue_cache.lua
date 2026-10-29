-- TEST ONLY: original QuestAccepted/HandleQuestAccepted/QuestRemoved/MarkQuestAsAbandoned,
-- whole original QuestieCombatQueue and QuestLogCache under a FABRICATED game/timer host.
-- Does not prove native 3.3.5a event ordering, timing, quest data or gameplay defects.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(p)
  local f=assert(io.open(root.."/"..p,"rb"),"ORIGINAL_SOURCE_MISSING:"..p)
  local s=assert(f:read("*a"));f:close();return s
end
local handler=read("Modules/Quest/QuestEventHandler.lua")
local queueSource=read("Modules/Libs/QuestieCombatQueue.lua")
local cacheSource=read("Modules/Quest/QuestLogCache.lua")
local function extract(s,a,b)
  local i=assert(s:find(a,1,true),"SOURCE_BEGIN_MISSING:"..a)
  local j=assert(s:find(b,i+#a,true),"SOURCE_END_MISSING:"..b)
  return s:sub(i,j-1)
end
local accepted=extract(handler,"function _QuestEventHandler:QuestAccepted(","\n---@param questId number\n---@return boolean true")
local handled=extract(handler,"function _QuestEventHandler:HandleQuestAccepted(","\n--- Fires when a quest is turned in")
local removed=extract(handler,"function _QuestEventHandler:QuestRemoved(","\n---@param questId number\nfunction _QuestEventHandler:MarkQuestAsAbandoned(")
local abandoned=extract(handler,"function _QuestEventHandler:MarkQuestAsAbandoned(","\n---Fires when the quest log changed")
local function compile(s,name,env)
  local f
  if _VERSION=="Lua 5.1" then f=assert(loadstring(s,name));setfenv(f,env)
  else f=assert(load(s,name,"t",env)) end
  f()
end
local tests=0
local function check(v,n) assert(v,n);tests=tests+1 end
check(accepted:find("questLog[questId] = {}",1,true)~=nil,"R01_ORIGINAL_ACCEPT_REPLACES_RECORD")
check(accepted:find("MarkQuestAsAbandoned(questId)",1,true)~=nil,"R02_ORIGINAL_ACCEPT_QUEUES_PRIOR_ABANDON")
check(queueSource:find("C_Timer.NewTicker(0.1,",1,true)~=nil,"R03_ORIGINAL_COMBATQUEUE_TICKER")
check(queueSource:find("tinsert(_Queue,",1,true)~=nil,"R04_ORIGINAL_COMBATQUEUE_DEFERRED_INSERT")
check(abandoned:find("questLog[questId].state == QUEST_LOG_STATES.QUEST_REMOVED",1,true)~=nil,
  "R05_ORIGINAL_ABANDON_REQUIRES_OLD_STATE")

local state={QUEST_ACCEPTED="QUEST_ACCEPTED",QUEST_REMOVED="QUEST_REMOVED",
  QUEST_ABANDONED="QUEST_ABANDONED"}
local game={inLog=true,ready=true,complete=0,objectives={{
  text="SYNTHETIC_OLD",type="monster",numFulfilled=0,numRequired=1,finished=false}}}
local counts={cancel=0,accepted=0,abandoned=0,dirty=0,journeyAccepted=0,
  journeyAbandoned=0,announceAccepted=0,announceAbandoned=0,names=0,broadcast=0}
local timers={combat=nil,pending={}}
local locked=false
local fakeTimer={NewTicker=function(seconds,callback,iterations)
  assert(type(callback)=="function")
  local timer={seconds=seconds,callback=callback,cancelled=false}
  function timer:Cancel() self.cancelled=true;counts.cancel=counts.cancel+1 end
  function timer:Fire() if not self.cancelled then self.callback() end end
  if seconds==0.1 then
    assert(iterations==nil and timers.combat==nil,"FAKE_COMBAT_INIT_REPEATED")
    timers.combat=timer
  elseif seconds==1 then
    assert(iterations==1,"FAKE_ABANDON_ONE_ITERATION")
    timers.pending[#timers.pending+1]=timer
  else error("UNEXPECTED_FAKE_TIMER_"..tostring(seconds)) end
  return timer
end}
local lib={
  TrimObjectiveText=function(s)return s end,
  CacheItemNames=function(_,id) assert(id==1);counts.names=counts.names+1 end,
  tpack=function(...)return {n=select("#",...),...} end,
  tunpack=function(t)return (unpack or table.unpack)(t,1,t.n) end
}
local modules={QuestieLib=lib}
modules.Sounds={PlayQuestComplete=function()end,PlayObjectiveComplete=function()end,
  PlayObjectiveProgress=function()end}
local loader={}
function loader:CreateModule(n)
  if not modules[n] then modules[n]={} end
  return modules[n]
end
function loader:ImportModule(n)return assert(modules[n],"MISSING_FAKE_MODULE:"..n) end
local compat={C_Timer=fakeTimer,
  GetQuestLogTitle=function(i)
    if not game.inLog or i~=1 then return nil end
    return "SYNTHETIC_QUEST",nil,"normal",false,nil,game.complete,nil,1
  end,
  HaveQuestData=function(id) return id==1 and game.ready end,
  C_QuestLog={GetQuestObjectives=function(id,i)
    assert(id==1 and i==1);return game.objectives end}}
local questie={DEBUG_INFO=1,DEBUG_DEVELOP=2,DEBUG_CRITICAL=3,IsWotlk=false,
  db={global={isleOfQuelDanasPhase=0}}}
function questie:Debug()end
function questie:Warning()end
function questie:SendMessage()counts.broadcast=counts.broadcast+1 end
local quest={
  SetObjectivesDirty=function(_,id)assert(id==1);counts.dirty=counts.dirty+1 end,
  AcceptQuest=function(_,id)assert(id==1);counts.accepted=counts.accepted+1 end,
  AbandonedQuest=function(_,id)assert(id==1);counts.abandoned=counts.abandoned+1 end}
local journey={
  AcceptQuest=function(_,id)assert(id==1);counts.journeyAccepted=counts.journeyAccepted+1 end,
  AbandonQuest=function(_,id)assert(id==1);counts.journeyAbandoned=counts.journeyAbandoned+1 end}
local announce={
  AcceptedQuest=function(_,id)assert(id==1);counts.announceAccepted=counts.announceAccepted+1 end,
  AbandonedQuest=function(_,id)assert(id==1);counts.announceAbandoned=counts.announceAbandoned+1 end}
local tracking={[1]={state=state.QUEST_ACCEPTED}}
local event={}
local env={Questie=questie,QuestieCompat=compat,QuestieLoader=loader,
  QuestieQuest=quest,QuestieJourney=journey,QuestieAnnounce=announce,
  QuestieLib=lib,QUEST_LOG_STATES=state,TRACKING=tracking,
  _QuestEventHandler=event,C_Timer=fakeTimer,GetQuestTimers=function()return nil end,
  InCombatLockdown=function()return locked end, tremove=table.remove,
  tinsert=table.insert,
  _QuestLogUpdateQueue={Insert=function()error("UNEXPECTED_CACHE_MISS") end},
  IsleOfQuelDanas={MAX_ISLE_OF_QUEL_DANAS_PHASES=99}}
setmetatable(env,{__index=_G})
compile(queueSource,"@ORIGINAL_335/Modules/Libs/QuestieCombatQueue.lua",env)
compile(cacheSource,"@ORIGINAL_335/Modules/Quest/QuestLogCache.lua",env)
local queue=assert(modules.QuestieCombatQueue)
local cache=assert(modules.QuestLogCache)
env.QuestieCombatQueue=queue
env.QuestLogCache=cache
compile("local questLog=TRACKING\nlocal skipNextUQLCEvent=false\n"
  ..accepted.."\n"..handled.."\n"..removed.."\n"..abandoned.."\n"
  .."function _QuestEventHandler:ProbeState(id) return questLog[id] and questLog[id].state end\n",
  "=ORIGINAL_335_HANDLER_BODIES_FAKE_UPVALUES",env)
queue.Initialize()
check(timers.combat~=nil and timers.combat.seconds==0.1,
  "R06_ORIGINAL_QUEUE_INITIALIZATION_CREATES_FAKE_TICKER")
local miss,changes=cache.CheckForChanges(nil)
check(not miss and changes[1]~=nil,"R07_CACHE_INITIAL_COLD_INSERT")
check(#cache.questLog_DO_NOT_MODIFY[1].objectives==1,"R08_INITIAL_OBJECTIVE_COUNT")

-- Synthetic order A: REMOVED -> ACCEPTED -> deferred queue tick; fake game 1 -> 0.
event:QuestRemoved(1)
check(event:ProbeState(1)==state.QUEST_REMOVED,"R09_REMOVED_PENDING_STATE")
check(#timers.pending==1 and not timers.pending[1].cancelled,
  "R10_REMOVED_TIMER_WAS_SCHEDULED")
check(cache.questLog_DO_NOT_MODIFY[1]~=nil,"R11_REMOVED_DOES_NOT_INVALIDATE")
event:QuestAccepted(1,1)
check(timers.pending[1].cancelled and counts.cancel==1,"R12_REACCEPT_CANCELS_PENDING_TIMER")
check(event:ProbeState(1)==nil,"R13_REACCEPT_REPLACES_OLD_HANDLER_STATE")
check(counts.abandoned==0 and counts.accepted==0,
  "R14_QUEUED_CALLBACKS_HAVE_NOT_RUN_IMMEDIATELY")
check(cache.questLog_DO_NOT_MODIFY[1]~=nil,"R15_REACCEPT_NOT_YET_CACHE_INVALIDATION")
game.objectives={}
timers.combat:Fire()
check(counts.abandoned==0,"R16_QUEUED_ABANDON_SEES_REPLACED_ACCEPTED_RECORD")
check(event:ProbeState(1)==state.QUEST_ACCEPTED,"R17_QUEUE_COMPLETES_ACCEPT_STATE")
check(counts.accepted==1 and counts.dirty==1,"R18_ORIGINAL_ACCEPT_HANDLER_INVOKED")
check(counts.names==1 and counts.journeyAccepted==1 and counts.announceAccepted==1,
  "R19_ACCEPT_SINKS_RUN_AFTER_FAKE_QUEUE_TICK")
check(#cache.questLog_DO_NOT_MODIFY[1].objectives==1,
  "R20_SOURCE_CACHE_RETAINS_ONE_WHEN_FAKE_CLIENT_NOW_ZERO")
check(cache.TestGameCache(),"R21_FAKE_GAME_READINESS_NOT_SYNCHRONIZATION")
timers.pending[1]:Fire()
check(counts.abandoned==0,"R22_CANCELLED_TIMER_IGNORED_BY_FAKE_HOST")

-- Isolate synthetic order B by explicitly clearing original cache in test host.
cache.RemoveQuest(1)
game.objectives={{text="SYNTHETIC_REENTER",type="item",
  numFulfilled=0,numRequired=1,finished=false}}
miss,changes=cache.CheckForChanges(nil)
check(not miss and changes[1]~=nil,"R23_FIXTURE_REBUILDS_SOURCE_CACHE")
event:QuestRemoved(1)
check(#timers.pending==2 and event:ProbeState(1)==state.QUEST_REMOVED,
  "R24_SECOND_PENDING_REMOVAL")
timers.pending[2]:Fire()  -- Explicitly simulated before reacceptance.
check(counts.abandoned==1 and event:ProbeState(1)==nil,
  "R25_FAKE_TIMER_CALLS_ORIGINAL_ABANDON_HANDLER")
check(cache.questLog_DO_NOT_MODIFY[1]==nil,"R26_ABANDON_INVALIDATES_CACHE")
check(counts.journeyAbandoned==1 and counts.announceAbandoned==1,
  "R27_ABANDON_SINKS_FAKE_ONLY")
game.objectives={}
event:QuestAccepted(1,1)
check(counts.accepted==1 and event:ProbeState(1)==nil,
  "R28_REACCEPT_AFTER_ABANDON_IS_DEFERRED")
timers.combat:Fire()
check(counts.accepted==2 and event:ProbeState(1)==state.QUEST_ACCEPTED,
  "R29_REACCEPT_AFTER_ABANDON_COMPLETES")
check(cache.questLog_DO_NOT_MODIFY[1]~=nil and
  #cache.questLog_DO_NOT_MODIFY[1].objectives==0,
  "R30_ABANDON_INVALIDATION_REBUILDS_ZERO_OBJECTIVE")
check(counts.abandoned==1,"R31_NO_EXTRA_ABANDON_ON_CLEAN_REACCEPT")

-- Synthetic order C: combat-lockdown holds real original queue's callbacks.
cache.RemoveQuest(1)
game.objectives={{text="SYNTHETIC_THIRD",type="monster",
  numFulfilled=0,numRequired=1,finished=false}}
miss,changes=cache.CheckForChanges(nil)
check(not miss and changes[1]~=nil,"R32_THIRD_COLD_CACHE")
event:QuestRemoved(1)
locked=true
event:QuestAccepted(1,1)
check(#timers.pending==3 and timers.pending[3].cancelled,
  "R33_COMBAT_REACCEPT_CANCELLATION")
timers.combat:Fire()
check(counts.accepted==2 and event:ProbeState(1)==nil,
  "R34_ORIGINAL_QUEUE_DEFERS_DURING_FAKE_LOCKDOWN")
check(#cache.questLog_DO_NOT_MODIFY[1].objectives==1,
  "R35_FAKE_LOCKDOWN_NO_CACHE_CLEAR")
game.objectives={}
locked=false
timers.combat:Fire()
check(counts.accepted==3 and event:ProbeState(1)==state.QUEST_ACCEPTED,
  "R36_ORIGINAL_QUEUE_RESUMES_AFTER_FAKE_LOCKDOWN")
check(counts.abandoned==1,"R37_DELAYED_OLD_ABANDON_CALLBACK_NO_EFFECT")
check(#cache.questLog_DO_NOT_MODIFY[1].objectives==1,
  "R38_DELAYED_ACCEPT_FAKE_ONE_TO_ZERO_STILL_RETAINS_CACHE")
check(counts.names==3 and counts.journeyAccepted==3 and counts.announceAccepted==3,
  "R39_ALL_ACCEPT_EVENTS_DRAINED")
check(counts.broadcast==3,"R40_THREE_REMOVALS_BROADCAST_THROUGH_FAKE_SINK")
assert(tests==40,"SOURCE_REACCEPT_COMBAT_QUEUE_CENSUS:"..tests)
print("PUBLIC G08 PART47 ORIGINAL REACCEPT COMBAT QUEUE: 40/40 PASS")
print("PUBLIC G08 PART47 ORIGINAL: unchanged four QuestEventHandler function bodies, whole QuestieCombatQueue and whole QuestLogCache modules.")
print("PUBLIC G08 PART47 NOT NATIVE: fabricated acceptance/removal event order, game objective 1-to-0, tickers, combat state and addon sinks.")
