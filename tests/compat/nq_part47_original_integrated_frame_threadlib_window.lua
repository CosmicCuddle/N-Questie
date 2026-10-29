-- TEST ONLY: genuine source methods and contiguous init fragment coexecute under fake host.
-- TEST ONLY. Source-authentic Queue, QuestLogCache and handler bodies.
-- WoW event delivery, all timers, game state, combat, and loaders are FAKE.
-- Historical QuestieInit source is read and order-checked; NOT executed.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(p)
  local f=assert(io.open(root.."/"..p,"rb"),"ORIGINAL_SOURCE_MISSING:"..p)
  local s=assert(f:read("*a"));f:close();return s
end
local queueSource=read("Modules/Libs/QuestieCombatQueue.lua")
local threadSource=read("Modules/Libs/ThreadLib.lua")
local initSource=read("Modules/QuestieInit.lua")
local handlerSource=read("Modules/Quest/QuestEventHandler.lua")
local cacheSource=read("Modules/Quest/QuestLogCache.lua")
local function extract(s,a,b)
  local i=assert(s:find(a,1,true),"ORIGINAL_BEGIN_NOT_FOUND:"..a)
  local j=assert(s:find(b,i+#a,true),"ORIGINAL_END_NOT_FOUND:"..b)
  return s:sub(i,j-1)
end
local originalRegister=extract(handlerSource,
  "function QuestEventHandler:RegisterEvents()",
  "\n--- On Login mark all quests in the quest log with QUEST_ACCEPTED state")
local originalInitQuestLog=extract(handlerSource,
  "function _QuestEventHandler:InitQuestLog()",
  "\n--- Fires when a quest is accepted")
-- Capture the FIRST string.find return explicitly. Without this local, Lua passes
-- BOTH find indices through the final assert(...) argument into string.sub().
local dispatchStart=assert(handlerSource:find(
  "function _QuestEventHandler:OnEvent(",1,true))
local originalDispatch=handlerSource:sub(dispatchStart)
local accepted=extract(handlerSource,
  "function _QuestEventHandler:QuestAccepted(",
  "\n---@param questId number\n---@return boolean true")
local handled=extract(handlerSource,
  "function _QuestEventHandler:HandleQuestAccepted(",
  "\n--- Fires when a quest is turned in")
local removed=extract(handlerSource,
  "function _QuestEventHandler:QuestRemoved(",
  "\n---@param questId number\nfunction _QuestEventHandler:MarkQuestAsAbandoned(")
local abandoned=extract(handlerSource,
  "function _QuestEventHandler:MarkQuestAsAbandoned(",
  "\n---Fires when the quest log changed")
local function compile(code,name,env)
  local fn
  if _VERSION=="Lua 5.1" then fn=assert(loadstring(code,name));setfenv(fn,env)
  else fn=assert(load(code,name,"t",env)) end
  fn()
end

local function newHost()
  local calls={accept=0,abandon=0,dirty=0,journeyAccept=0,
    announceAccept=0,cacheNames=0,broadcast=0,cancel=0}
  local g={inLog=true,complete=0,ready=true,
    objectives={{text="FAKE_OBJECTIVE",type="monster",
      numFulfilled=0,numRequired=1,finished=false}}}
  local tick={combat=nil,pending={},stage=nil}
  local timerApi={NewTicker=function(seconds,callback,iterations)
    assert(type(callback)=="function")
    local timer={cancelled=false,callback=callback}
    function timer:Cancel()
      self.cancelled=true;calls.cancel=calls.cancel+1
    end
    function timer:Fire()
      if not self.cancelled then self.callback() end
    end
    if seconds==0 then
      assert(iterations==nil and tick.stage==nil,"FAKE_THREAD_STAGE_TIMER_DUPLICATE")
      tick.stage=timer
    elseif seconds==0.1 then
      assert(iterations==nil and tick.combat==nil,"FAKE_COMBAT_TICKER_REPEATED")
      tick.combat=timer
    elseif seconds==1 then
      assert(iterations==1,"FAKE_PENDING_TICKER_COUNT")
      tick.pending[#tick.pending+1]=timer
    else error("FAKE_TIMER_UNSUPPORTED:"..tostring(seconds)) end
    return timer
  end}
  local lib={
    tpack=function(...)return {n=select("#",...),...} end,
    tunpack=function(a)return (unpack or table.unpack)(a,1,a.n) end,
    TrimObjectiveText=function(z)return z end,
    CacheItemNames=function(_,id)assert(id==1);calls.cacheNames=calls.cacheNames+1 end
  }
  local modules={QuestieLib=lib,
    Sounds={PlayQuestComplete=function()end,PlayObjectiveComplete=function()end,
      PlayObjectiveProgress=function()end}}
  local loader={}
  function loader:CreateModule(n)
    if not modules[n] then modules[n]={} end
    return modules[n]
  end
  function loader:ImportModule(n)return assert(modules[n],"FAKE_MODULE_MISSING:"..n) end
  local compat={C_Timer=timerApi,
    GetQuestLogTitle=function(i)
      if i~=1 or not g.inLog then return nil end
      return "FAKE_QUEST",nil,"normal",false,nil,g.complete,nil,1
    end,
    HaveQuestData=function(id)return id==1 and g.ready end,
    C_QuestLog={GetQuestObjectives=function(id,index)
      assert(id==1 and index==1);return g.objectives end}}
  local questie={DEBUG_INFO=1,DEBUG_DEVELOP=2,DEBUG_CRITICAL=3,
    IsWotlk=false,db={global={isleOfQuelDanasPhase=0}}}
  function questie:Debug()end
  function questie:Warning()end
  function questie:Error(_,msg) error("FAKE_THREAD_ERROR:"..tostring(msg)) end
  function questie:SendMessage()calls.broadcast=calls.broadcast+1 end
  local quest={
    SetObjectivesDirty=function(_,id)assert(id==1);calls.dirty=calls.dirty+1 end,
    AcceptQuest=function(_,id)assert(id==1);calls.accept=calls.accept+1 end,
    AbandonedQuest=function(_,id)assert(id==1);calls.abandon=calls.abandon+1 end}
  local journey={
    AcceptQuest=function(_,id)assert(id==1);calls.journeyAccept=calls.journeyAccept+1 end,
    AbandonQuest=function()end}
  local announce={
    AcceptedQuest=function(_,id)assert(id==1);calls.announceAccept=calls.announceAccept+1 end,
    AbandonedQuest=function()end}
  local states={QUEST_ACCEPTED="QUEST_ACCEPTED",QUEST_TURNED_IN="QUEST_TURNED_IN",
    QUEST_REMOVED="QUEST_REMOVED",QUEST_ABANDONED="QUEST_ABANDONED"}
  local gate={locked=false}
  local tracking={[1]={state=states.QUEST_ACCEPTED}}
  local event={}
  local public={private=event}
  local frame={events={},script=nil}
  function frame:RegisterEvent(name) self.events[name]=true end
  function frame:SetScript(which,fn)
    assert(which=="OnEvent" and type(fn)=="function","FAKE_FRAME_SCRIPT")
    self.script=fn
  end
  function frame:Fire(name,...)
    assert(self.events[name],"FAKE_EVENT_NOT_REGISTERED:"..tostring(name))
    assert(type(self.script)=="function","FAKE_FRAME_NO_SCRIPT")
    self.script(self,name,...)
  end
  local env={Questie=questie,QuestieCompat=compat,QuestieLoader=loader,
    QuestEventHandler=public,FRAME=frame,
    QuestieQuest=quest,QuestieJourney=journey,QuestieAnnounce=announce,
    QuestieLib=lib,QUEST_LOG_STATES=states,TRACKING=tracking,
    _QuestEventHandler=event,C_Timer=timerApi,tremove=table.remove,
    tinsert=table.insert,InCombatLockdown=function()return gate.locked end,
    GetQuestTimers=function()return nil end,
    hooksecurefunc=function(name,fn)
      assert((name=="StaticPopup_Show" or name=="DeleteCursorItem") and type(fn)=="function",
        "FAKE_UNEXPECTED_SECURE_HOOK")
      calls.hooks=(calls.hooks or 0)+1
    end,
    _QuestLogUpdateQueue={Insert=function()error("FAKE_UNEXPECTED_CACHE_MISS")end},
    IsleOfQuelDanas={MAX_ISLE_OF_QUEL_DANAS_PHASES=99}}
  setmetatable(env,{__index=_G})
  compile(threadSource,"@ORIGINAL_335/Modules/Libs/ThreadLib.lua",env)
  compile(queueSource,"@ORIGINAL_335/Modules/Libs/QuestieCombatQueue.lua",env)
  compile(cacheSource,"@ORIGINAL_335/Modules/Quest/QuestLogCache.lua",env)
  local queue=assert(modules.QuestieCombatQueue)
  local cache=assert(modules.QuestLogCache)
  env.QuestieCombatQueue=queue
  env.QuestLogCache=cache
  compile("local eventFrame=FRAME\nlocal questLog=TRACKING\n"
    .."local skipNextUQLCEvent=false\n"
    ..originalRegister.."\n"..originalInitQuestLog.."\n"
    ..accepted.."\n"..handled.."\n"..removed.."\n"..abandoned.."\n"
    ..originalDispatch.."\n"
    .."function _QuestEventHandler:FakeState(id) return questLog[id] and questLog[id].state end\n",
    "=ORIGINAL_335_REGISTER_INIT_DISPATCH_AND_HANDLER_BODIES_FAKE_HOST",env)
  local miss,changes=cache.CheckForChanges(nil)
  assert(not miss and changes[1]~=nil,"FAKE_HOST_INITIAL_CACHE_FAILED")
  return {calls=calls,queue=queue,threadLib=assert(modules.ThreadLib),gate=gate,cache=cache,tick=tick,frame=frame,
    public=public,event=event,game=g,states=states}
end


local tests=0
local function check(ok,name)assert(ok,name);tests=tests+1 end
local startMarker="    coYield()\n    QuestEventHandler:RegisterEvents()\n"
local endMarker="    local dateToday = date(\"%y-%m-%d\")"
local startIndex=assert(initSource:find(startMarker,1,true))
local endIndex=assert(initSource:find(endMarker,startIndex+#startMarker,true))
local fragment=initSource:sub(startIndex,endIndex-1)
local _,yieldCount=fragment:gsub("coYield%(%s*%)","")
check(yieldCount==8,"I01_ORIGINAL_QUESTIEINIT_FRAGMENT_EIGHT_YIELDS")
check(fragment:find("QuestEventHandler:RegisterEvents()",1,true) <
  fragment:find("QuestieCombatQueue.Initialize()",1,true),
  "I02_ORIGINAL_ORDER_REGISTER_BEFORE_QUEUE")
check(threadSource:find("coResume(thread)",1,true)~=nil,
  "I03_ORIGINAL_THREADLIB_RESUME_SOURCE_PRESENT")
check(originalRegister:find('SetScript("OnEvent", _QuestEventHandler.OnEvent)',1,true)~=nil,
  "I04_ORIGINAL_REGISTER_SETS_ORIGINAL_DISPATCH")
check(originalDispatch:find('_QuestEventHandler:QuestAccepted(...)',1,true)~=nil,
  "I05_ORIGINAL_DISPATCH_ACCEPT_SOURCE")

local h=newHost()
h.cache.RemoveQuest(1) -- Explicit TEST HOST cache setup before genuine InitQuestLog.
local calls={}
local function mark(name)return function()calls[#calls+1]=name end end
local stageEnv={
  coYield=coroutine.yield,
  QuestEventHandler=h.public,
  QuestieCombatQueue=h.queue,
  ChatFilter={RegisterEvents=mark("chat")},
  QuestieMap={InitializeQueue=mark("map")},
  QuestieQuest={Initialize=mark("quest_init"),
    GetAllQuestIdsNoObjectives=mark("ids_no_objectives"),
    GetAllQuestIds=mark("ids_all")},
  WorldMapButton={Initialize=mark("button")},
  Townsfolk={PostBoot=mark("townsfolk")},
  QuestieTracker={Initialize=mark("tracker")},
  Hooks={HookQuestLogTitle=mark("hooks")}
}
setmetatable(stageEnv,{__index=_G})
local function makeStage()
  local script="return function()\n"..fragment.."\nend"
  local fn
  if _VERSION=="Lua 5.1" then
    fn=assert(loadstring(script,"=ORIGINAL_335_INIT_FRAGMENT_7_HANDLER_BODIES"))
    setfenv(fn,stageEnv)
  else
    fn=assert(load(script,"=ORIGINAL_335_INIT_FRAGMENT_7_HANDLER_BODIES","t",stageEnv))
  end
  return assert(fn())
end
local t,co=h.threadLib.ThreadError(makeStage(),0,"FAKE_ORIGINAL_STAGE")
check(t==h.tick.stage and t~=nil,"I06_ORIGINAL_THREADLIB_INITIALIZES_STAGE_TIMER")
check(coroutine.status(co)=="suspended","I07_GENUINE_THREADLIB_COROUTINE_SUSPENDED")
check(not h.frame.events["QUEST_ACCEPTED"] and h.frame.script==nil,
  "I08_BEFORE_REGISTRATION_FAKE_FRAME_HAS_NO_QUEST_EVENT")
local ok=pcall(function()h.frame:Fire("QUEST_ACCEPTED",1,1)end)
check(not ok,"I09_FAKE_FRAME_REJECTS_BEFORE_REGISTER")
t:Fire() -- Original coYield before RegisterEvents.
check(h.frame.script==nil and coroutine.status(co)=="suspended",
  "I10_FIRST_TRUE_SOURCE_YIELD_BLOCKS_REGISTER")
t:Fire() -- Original RegisterEvents -> InitQuestLog -> genuine OnEvent binding.
check(h.frame.events["QUEST_ACCEPTED"] and h.frame.events["QUEST_REMOVED"],
  "I11_GENUINE_REGISTER_EVENTS_FAKE_FRAME_EVENT_SET")
check(type(h.frame.script)=="function" and h.calls.hooks==2,
  "I12_REAL_REGISTER_BOUND_DISPATCH_AND_HOOKS")
check(h.calls.cacheNames==1 and h.event:FakeState(1)==h.states.QUEST_ACCEPTED,
  "I13_REAL_INITQUESTLOG_SEEDED_FAKE_TRACKING")
check(h.tick.combat==nil and coroutine.status(co)=="suspended",
  "I14_AFTER_REG_BEFORE_QUEUE_WINDOW")
h.frame:Fire("QUEST_ACCEPTED",1,1) -- Fabricated native-like delivery ONLY.
check(h.event:FakeState(1)==nil and h.calls.accept==0,
  "I15_ORIGINAL_FRAME_PREINIT_ACCEPT_NO_EFFECT")
h.frame:Fire("QUEST_REMOVED",1)
check(h.event:FakeState(1)==h.states.QUEST_REMOVED and #h.tick.pending==1,
  "I16_ORIGINAL_DISPATCH_PREINIT_REMOVAL_PENDING_TIMER")
h.frame:Fire("QUEST_ACCEPTED",1,1)
check(h.tick.pending[1].cancelled and h.calls.cancel==1,
  "I17_ORIGINAL_DISPATCH_PREINIT_REACCEPT_CANCELS_TIMER")
check(h.event:FakeState(1)==nil and h.calls.accept==0,
  "I18_PREINIT_QUEUE_DID_NOT_EXECUTE_OLD_ACCEPT_CALLBACKS")
for i=1,6 do t:Fire() end -- Exactly six source yields before final stage resume.
check(h.tick.combat==nil and #calls>=7,"I19_CONTIGUOUS_SOURCE_PROGRESS_BEFORE_LAST_TICK")
t:Fire() -- Final real source fragment invokes original CombatQueue.Initialize.
check(h.tick.combat~=nil and not h.tick.combat.cancelled,
  "I20_SOURCE_FRAGMENT_INITIALIZES_REAL_QUEUE")
check(coroutine.status(co)=="dead","I21_TRUE_THREADLIB_COROUTINE_ENDED")
check(calls[#calls]=="hooks" and h.calls.accept==0,
  "I22_STAGE_LAST_DEPENDENCY_AND_EARLY_CALLBACK_STILL_DROPPED")
h.tick.combat:Fire()
check(h.calls.accept==0 and h.event:FakeState(1)==nil,
  "I23_REAL_COMBATQUEUE_DID_NOT_REPLAY_PREINIT_FRAME_CALLBACKS")
h.tick.pending[1]:Fire()
check(h.calls.abandon==0,"I24_FAKE_CANCELLED_TIMER_DOES_NOT_ABANDON")
h.frame:Fire("QUEST_ACCEPTED",1,1)
check(h.calls.accept==0,"I25_POSTINIT_GENUINE_ON_EVENT_ENQUEUES_NOT_INLINE")
h.gate.locked=true
h.tick.combat:Fire()
check(h.calls.accept==0,"I26_REAL_COMBATQUEUE_WAITING_ON_FAKE_COMBAT")
h.gate.locked=false
h.tick.combat:Fire()
check(h.calls.accept==1 and h.event:FakeState(1)==h.states.QUEST_ACCEPTED,
  "I27_REAL_DISPATCH_AND_REAL_COMBATQUEUE_COMPLETE_POSTINIT_ACCEPT")
check(h.calls.cacheNames==2 and h.calls.journeyAccept==1 and h.calls.announceAccept==1,
  "I28_SOURCE_HANDLER_AND_FAKE_SINKS_POSTINIT_EXECUTED")
t:Fire() -- Original ThreadLib sees dead and cancels its stage timer.
check(t.cancelled,"I29_ORIGINAL_THREADLIB_CANCELLED_DEAD_COROUTINE_TIMER")
check(calls[1]=="chat" and calls[2]=="map" and calls[#calls]=="hooks",
  "I30_UNCHANGED_FRAGMENT_FAKE_DEPENDENCY_SEQUENCE")
assert(tests==30,"INTEGRATED_FRAME_THREADLIB_INIT_WINDOW_CENSUS:"..tests)
print("PUBLIC G08 PART47 ORIGINAL FRAME THREADLIB INIT WINDOW: 30/30 PASS")
print("PUBLIC G08 PART47 ORIGINAL: genuine ThreadLib, CombatQueue and QuestLogCache whole modules; seven original QuestEventHandler bodies and unchanged QuestieInit fragment in ONE fake host.")
print("PUBLIC G08 PART47 NOT NATIVE: original entire QuestieInit stage is not run; manual fake event arrivals/timers/combat and dependent modules, no real 3.3.5a client.")
