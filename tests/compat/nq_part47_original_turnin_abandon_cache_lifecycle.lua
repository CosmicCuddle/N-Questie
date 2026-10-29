-- TEST ONLY. Original 335 QuestEventHandler method bodies and WHOLE QuestLogCache.
-- Fake WoW quest log, simulated event order, synthetic timers, fake addon sinks.
-- Not native 3.3.5a callback or gameplay verification.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"ORIGINAL_SOURCE_MISSING:"..path)
  local s=assert(f:read("*a")); f:close(); return s
end
local handler=read("Modules/Quest/QuestEventHandler.lua")
local cacheSource=read("Modules/Quest/QuestLogCache.lua")
local function extract(s,a,b)
  local i=assert(s:find(a,1,true),"ORIGINAL_BEGIN_NOT_FOUND:"..a)
  local j=assert(s:find(b,i+#a,true),"ORIGINAL_END_NOT_FOUND:"..b)
  return s:sub(i,j-1)
end
local turned=extract(handler,"function _QuestEventHandler:QuestTurnedIn(","\n--- Fires when a quest is removed")
local removed=extract(handler,"function _QuestEventHandler:QuestRemoved(","\n---@param questId number\nfunction _QuestEventHandler:MarkQuestAsAbandoned(")
local abandoned=extract(handler,"function _QuestEventHandler:MarkQuestAsAbandoned(","\n---Fires when the quest log changed")
local function compile(s,name,env)
  local fn
  if _VERSION=="Lua 5.1" then fn=assert(loadstring(s,name));setfenv(fn,env)
  else fn=assert(load(s,name,"t",env)) end
  fn()
end
local count=0
local function check(value,label) assert(value,label);count=count+1 end
check(turned:find("QuestLogCache.RemoveQuest(questId)",1,true)~=nil,"L01_TURNIN_HAS_ORIGINAL_REMOVE")
check(abandoned:find("QuestLogCache.RemoveQuest(questId)",1,true)~=nil,"L02_ABANDON_HAS_ORIGINAL_REMOVE")
check(removed:find("C_Timer.NewTicker(1,",1,true)~=nil,"L03_REMOVAL_DEFERS_DECISION")

local game={inLog=true,ready=true,complete=0,objectives={
  {text="SYNTHETIC_TASK",type="monster",numFulfilled=0,numRequired=1,finished=false}}}
local counts={dirty=0,complete=0,abandon=0,journeyComplete=0,journeyAbandon=0,
  announcedComplete=0,announcedAbandon=0,broadcast=0,scheduled=0,cancelled=0}
local modules={QuestieLib={TrimObjectiveText=function(text) return text end}}
modules.Sounds={PlayQuestComplete=function()end,PlayObjectiveComplete=function()end,
  PlayObjectiveProgress=function()end}
local loader={}
function loader:CreateModule(name) modules[name]={};return modules[name] end
function loader:ImportModule(name) return assert(modules[name],"FAKE_MODULE_MISSING:"..name) end
local compat={Is335=true,
  GetQuestLogTitle=function(index)
    if index~=1 or not game.inLog then return nil end
    return "SYNTHETIC_QUEST",nil,"normal",false,nil,game.complete,nil,1
  end,
  HaveQuestData=function(id) return id==1 and game.ready end,
  C_QuestLog={GetQuestObjectives=function(id,index)
    assert(id==1 and index==1);return game.objectives end}}
local questie={DEBUG_INFO=1,DEBUG_DEVELOP=2,DEBUG_CRITICAL=3,IsWotlk=true}
function questie:Debug()end
function questie:Warning()end
function questie:SendMessage() counts.broadcast=counts.broadcast+1 end
local quest={
  SetObjectivesDirty=function(_,id) assert(id==1);counts.dirty=counts.dirty+1 end,
  CompleteQuest=function(_,id) assert(id==1);counts.complete=counts.complete+1 end,
  AbandonedQuest=function(_,id) assert(id==1);counts.abandon=counts.abandon+1 end}
local journey={
  CompleteQuest=function(_,id) assert(id==1);counts.journeyComplete=counts.journeyComplete+1 end,
  AbandonQuest=function(_,id) assert(id==1);counts.journeyAbandon=counts.journeyAbandon+1 end}
local announce={
  CompletedQuest=function(_,id) assert(id==1);counts.announcedComplete=counts.announcedComplete+1 end,
  AbandonedQuest=function(_,id) assert(id==1);counts.announcedAbandon=counts.announcedAbandon+1 end}
local db={QueryQuestSingle=function(id,field)
  assert(id==1 and field=="parentQuest");return nil end}
local timers={}
local timerApi={NewTicker=function(seconds,cb,iterations)
  assert(seconds==1 and type(cb)=="function" and iterations==1)
  local t={cancelled=false,callback=cb}
  function t:Cancel() self.cancelled=true;counts.cancelled=counts.cancelled+1 end
  function t:FireIfActive() if not self.cancelled then self.callback() end end
  timers[#timers+1]=t;counts.scheduled=counts.scheduled+1;return t
end}
local state={QUEST_ACCEPTED=7,QUEST_REMOVED=8,QUEST_ABANDONED=9,QUEST_TURNED_IN=10}
local tracking={[1]={state=state.QUEST_ACCEPTED}}
local event={}
local env={Questie=questie,QuestieCompat=compat,QuestieLoader=loader,
  QuestieQuest=quest,QuestieJourney=journey,QuestieAnnounce=announce,
  QuestieDB=db,QuestLogCache=nil,QUEST_LOG_STATES=state,
  _QuestEventHandler=event,TRACKING=tracking,C_Timer=timerApi,
  GetNumQuestLogRewards=function()return 0 end,
  GetQuestLogRewardInfo=function()return nil,nil,nil,nil,nil,nil end}
setmetatable(env,{__index=_G})
compile(cacheSource,"@ORIGINAL_335/Modules/Quest/QuestLogCache.lua",env)
local cache=assert(modules.QuestLogCache)
env.QuestLogCache=cache
-- Original function bodies unchanged; local handler state below is synthetic.
compile("local questLog=TRACKING\nlocal doFullQuestLogScan=false\nlocal skipNextUQLCEvent=false\n"
  ..turned.."\n"..removed.."\n"..abandoned.."\n"
  .."function _QuestEventHandler:FakeState(id) return questLog[id] and questLog[id].state end\n",
  "=ORIGINAL_335_QuestEventHandler_methods_FAKE_upvalues",env)

local miss,changes=cache.CheckForChanges(nil)
check(not miss and changes[1]~=nil,"L04_ORIGINAL_CACHE_INITIAL_INSERT")
check(#cache.questLog_DO_NOT_MODIFY[1].objectives==1,"L05_CACHE_ONE_SYNTHETIC_OBJECTIVE")
game.objectives={}
miss,changes=cache.CheckForChanges({[1]=true})
check(not miss and next(changes)==nil,"L06_ONE_TO_ZERO_FAKE_NO_CHANGE")
check(#cache.questLog_DO_NOT_MODIFY[1].objectives==1,"L07_UNCHANGED_SOURCE_CACHE_RETAINS_ONE")

-- Fabricate TURNED_IN before REMOVED, not claiming Blizzard native order.
game.inLog=false
event:QuestTurnedIn(1,0,0)
check(cache.questLog_DO_NOT_MODIFY[1]==nil,"L08_TURNIN_ORIGINAL_REMOVAL_CLEARS_CACHE")
check(event:FakeState(1)==state.QUEST_TURNED_IN,"L09_TURNIN_FLAG_TRACKED")
check(counts.complete==1 and counts.dirty==1,"L10_TURNIN_QUEST_SINKS_CALLED")
check(counts.journeyComplete==1 and counts.announcedComplete==1,"L11_TURNIN_OTHER_MOCK_SINKS")
event:QuestRemoved(1)
check(event:FakeState(1)==nil,"L12_LATER_REMOVED_CLEARS_TURNIN_TRACKING")
check(counts.scheduled==0,"L13_TURNIN_THEN_REMOVED_DOES_NOT_SCHEDULE_ABANDON")
check(cache.questLog_DO_NOT_MODIFY[1]==nil,"L14_CACHE_STAYS_CLEARED")

-- Fabricate another accepted quest and a REMOVED event before TURNED_IN.
game.inLog=true
game.objectives={{text="SYNTHETIC_AGAIN",type="monster",numFulfilled=0,
  numRequired=1,finished=false}}
tracking[1]={state=state.QUEST_ACCEPTED}
miss,changes=cache.CheckForChanges(nil)
check(not miss and changes[1]~=nil,"L15_REINSERT_CACHE_FOR_SECOND_SEQUENCE")
event:QuestRemoved(1)
check(event:FakeState(1)==state.QUEST_REMOVED,"L16_REMOVED_ENTERS_PENDING_STATE")
check(counts.scheduled==1 and #timers==1,"L17_FAKE_TICKER_RECORDED_NOT_RUN")
check(cache.questLog_DO_NOT_MODIFY[1]~=nil,"L18_REMOVED_ALONE_DOES_NOT_CLEAR_CACHE")
event:QuestTurnedIn(1,0,0)
check(timers[1].cancelled and counts.cancelled==1,"L19_TURNIN_CANCELS_PENDING_FAKE_TICKER")
check(cache.questLog_DO_NOT_MODIFY[1]==nil,"L20_PENDING_REMOVAL_TURNIN_CLEARS_CACHE")
check(event:FakeState(1)==state.QUEST_TURNED_IN,"L21_PENDING_RECLASSIFIED_TURNIN")
timers[1]:FireIfActive() -- FAKE scheduler respects its Cancel flag.
check(counts.abandon==0 and counts.complete==2,"L22_CANCELLED_FAKE_TICK_NO_ABANDON")
event:QuestRemoved(1)
check(event:FakeState(1)==nil,"L23_POST_TURNIN_REMOVED_CLEARS_TRACKING")

-- Fabricate removal with NO turn-in, then explicitly tick the fake timer.
tracking[1]={state=state.QUEST_ACCEPTED}
miss,changes=cache.CheckForChanges(nil)
check(not miss and changes[1]~=nil,"L24_CACHE_FOR_ABANDON_SEQUENCE")
event:QuestRemoved(1)
check(counts.scheduled==2 and cache.questLog_DO_NOT_MODIFY[1]~=nil,
  "L25_ABANDON_PENDING_PRESERVES_CACHE")
timers[2]:FireIfActive()
check(cache.questLog_DO_NOT_MODIFY[1]==nil,"L26_ORIGINAL_ABANDON_CLEARS_CACHE")
check(counts.abandon==1 and counts.dirty==3,"L27_ORIGINAL_ABANDON_QUEST_SINKS")
check(counts.journeyAbandon==1 and counts.announcedAbandon==1,
  "L28_ABANDON_OTHER_MOCK_SINKS")
check(event:FakeState(1)==nil,"L29_ABANDON_REMOVES_TRACKING")
check(counts.broadcast==4,"L30_ORIGINAL_REMOVED_BROADCAST_CALLS")
assert(count==30,"EVENT_LIFECYCLE_ASSERTION_CENSUS:"..count)
print("PUBLIC G08 PART47 ORIGINAL TURNIN ABANDON CACHE LIFECYCLE: 30/30 PASS")
print("PUBLIC G08 PART47 ORIGINAL: whole QuestLogCache and extracted QuestTurnedIn/QuestRemoved/MarkQuestAsAbandoned source bodies.")
print("PUBLIC G08 PART47 NOT NATIVE: invented event orders, quest state, timer firings and addon sink implementations.")
