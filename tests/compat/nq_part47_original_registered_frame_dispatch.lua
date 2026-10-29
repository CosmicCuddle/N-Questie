-- TEST ONLY. Source-authentic Queue, QuestLogCache and handler bodies.
-- WoW event delivery, all timers, game state, combat, and loaders are FAKE.
-- Historical QuestieInit source is read and order-checked; NOT executed.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(p)
  local f=assert(io.open(root.."/"..p,"rb"),"ORIGINAL_SOURCE_MISSING:"..p)
  local s=assert(f:read("*a"));f:close();return s
end
local queueSource=read("Modules/Libs/QuestieCombatQueue.lua")
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
local originalDispatch=handlerSource:sub(assert(
  handlerSource:find("function _QuestEventHandler:OnEvent(",1,true)))
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
local tests=0
local function check(v,label)assert(v,label);tests=tests+1 end
local registerIndex=assert(initSource:find("QuestEventHandler:RegisterEvents()",1,true))
local queueIndex=assert(initSource:find("QuestieCombatQueue.Initialize()",registerIndex+1,true))
check(registerIndex<queueIndex,"P01_REAL_INIT_REGISTERS_BEFORE_QUEUE")
local between=initSource:sub(registerIndex,queueIndex)
local _,yields=between:gsub("coYield%(%s*%)","")
check(yields>=2,"P02_REAL_INIT_HAS_INTERVENING_YIELDS")
check(queueSource:find("local started = false",1,true)~=nil,
  "P03_ORIGINAL_QUEUE_STARTS_UNINITIALIZED")
check(queueSource:find("if started then",1,true)~=nil,
  "P04_ORIGINAL_QUEUE_INSERT_CONDITIONAL")
check(accepted:find("QuestieCombatQueue:Queue(function()",1,true)~=nil,
  "P05_ORIGINAL_ACCEPT_CALLBACK_QUEUED")
check(accepted:find("questLog[questId] = {}",1,true)~=nil,
  "P06_ORIGINAL_REACCEPT_OVERWRITES_OLD_STATE")
check(abandoned:find("questLog[questId].state == QUEST_LOG_STATES.QUEST_REMOVED",1,true)~=nil,
  "P07_ORIGINAL_ABANDON_STATE_GUARD")

local function newHost()
  local calls={accept=0,abandon=0,dirty=0,journeyAccept=0,
    announceAccept=0,cacheNames=0,broadcast=0,cancel=0}
  local g={inLog=true,complete=0,ready=true,
    objectives={{text="FAKE_OBJECTIVE",type="monster",
      numFulfilled=0,numRequired=1,finished=false}}}
  local tick={combat=nil,pending={}}
  local timerApi={NewTicker=function(seconds,callback,iterations)
    assert(type(callback)=="function")
    local timer={cancelled=false,callback=callback}
    function timer:Cancel()
      self.cancelled=true;calls.cancel=calls.cancel+1
    end
    function timer:Fire()
      if not self.cancelled then self.callback() end
    end
    if seconds==0.1 then
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
  local states={QUEST_ACCEPTED="QUEST_ACCEPTED",
    QUEST_REMOVED="QUEST_REMOVED",QUEST_ABANDONED="QUEST_ABANDONED"}
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
    tinsert=table.insert,InCombatLockdown=function()return false end,
    GetQuestTimers=function()return nil end,
    hooksecurefunc=function(name,fn)
      assert((name=="StaticPopup_Show" or name=="DeleteCursorItem") and type(fn)=="function",
        "FAKE_UNEXPECTED_SECURE_HOOK")
      calls.hooks=(calls.hooks or 0)+1
    end,
    _QuestLogUpdateQueue={Insert=function()error("FAKE_UNEXPECTED_CACHE_MISS")end},
    IsleOfQuelDanas={MAX_ISLE_OF_QUEL_DANAS_PHASES=99}}
  setmetatable(env,{__index=_G})
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
  return {calls=calls,queue=queue,cache=cache,tick=tick,frame=frame,
    public=public,event=event,game=g,states=states}
end

-- A: fake QUEST_ACCEPTED arrives after event registration but BEFORE queue Initialize.
local a=newHost()
local marker=0
a.queue:Queue(function()marker=marker+1 end)
check(marker==0,"P08_UNINITIALIZED_QUEUE_NOT_INLINE")
a.event:QuestAccepted(1,1)
check(a.event:FakeState(1)==nil,"P09_EARLY_ACCEPT_REPLACES_STATE")
check(a.calls.accept==0 and a.calls.cacheNames==0,
  "P10_PREINIT_ACCEPT_HAS_NO_CALLBACK_EFFECT")
check(#a.cache.questLog_DO_NOT_MODIFY[1].objectives==1,
  "P11_PREINIT_CACHE_NOT_INVALIDATED")
a.queue.Initialize()
check(a.tick.combat~=nil,"P12_REAL_QUEUE_STARTS_FAKE_TIMER")
a.tick.combat:Fire()
check(marker==0 and a.calls.accept==0,
  "P13_PREINIT_QUEUED_CALLS_NOT_REPLAYED_AFTER_INIT")
check(a.event:FakeState(1)==nil,"P14_EARLY_ACCEPT_STILL_PENDING_EMPTY_STATE")
a.event:QuestAccepted(1,1)
check(a.calls.accept==0,"P15_POSTINIT_ACCEPT_STILL_QUEUED_NOT_INLINE")
a.tick.combat:Fire()
check(a.event:FakeState(1)==a.states.QUEST_ACCEPTED,
  "P16_POSTINIT_QUEUE_SETS_ACCEPTED")
check(a.calls.accept==1 and a.calls.dirty==1,
  "P17_POSTINIT_ACCEPT_HANDLER_CALLED")
check(a.calls.cacheNames==1 and a.calls.journeyAccept==1
  and a.calls.announceAccept==1,"P18_POSTINIT_SINKS_CALLED")

-- B: invented QUEST_REMOVED->QUEST_ACCEPTED before original queue is initialized.
local b=newHost()
b.event:QuestRemoved(1)
check(b.event:FakeState(1)==b.states.QUEST_REMOVED and #b.tick.pending==1,
  "P19_PREINIT_REMOVAL_PENDING_TIMER")
b.event:QuestAccepted(1,1)
check(b.tick.pending[1].cancelled and b.calls.cancel==1,
  "P20_PREINIT_REACCEPT_CANCELS_REAL_SOURCE_TIMER")
check(b.event:FakeState(1)==nil,"P21_PREINIT_REACCEPT_REPLACES_TRACKED_STATE")
b.queue.Initialize()
b.tick.combat:Fire()
check(b.calls.accept==0 and b.calls.abandon==0,
  "P22_PREINIT_REMOVAL_REACCEPT_CALLBACKS_NOT_REPLAYED")
check(b.cache.questLog_DO_NOT_MODIFY[1]~=nil,
  "P23_PREINIT_REACCEPT_RETAINS_ORIGINAL_CACHE")
b.tick.pending[1]:Fire()
check(b.calls.abandon==0,"P24_FAKE_TIMER_RESPECTS_CANCEL")
b.event:QuestAccepted(1,1)
b.tick.combat:Fire()
check(b.event:FakeState(1)==b.states.QUEST_ACCEPTED,
  "P25_RECOVERED_POSTINIT_ACCEPT_STATE")
check(b.calls.accept==1 and b.calls.dirty==1,
  "P26_RECOVERED_POSTINIT_ACCEPT_CALLBACK")

-- C: same original queue and handler, but initialized BEFORE invented reacceptance.
local c=newHost()
c.queue.Initialize()
c.event:QuestRemoved(1)
c.event:QuestAccepted(1,1)
check(c.tick.pending[1].cancelled,"P27_INITIALIZED_REACCEPT_CANCELS_PENDING")
check(c.calls.accept==0 and c.event:FakeState(1)==nil,
  "P28_INITIALIZED_ACCEPT_STILL_DEFERRED")
c.tick.combat:Fire()
check(c.event:FakeState(1)==c.states.QUEST_ACCEPTED,
  "P29_INITIALIZED_QUEUE_HANDLES_REACCEPT")
check(c.calls.accept==1 and c.calls.abandon==0,
  "P30_INITIALIZED_QUEUE_RUNS_ACCEPT_NO_ABANDON")
check(c.calls.cacheNames==1 and c.calls.dirty==1,
  "P31_INITIALIZED_QUEST_SINKS")
-- D: invoke REAL RegisterEvents and InitQuestLog bodies on FAKE frame and fake questlog.
local d=newHost()
d.cache.RemoveQuest(1)
d.public:RegisterEvents()
check(d.frame.events["QUEST_ACCEPTED"] and d.frame.events["QUEST_REMOVED"],
  "F01_ORIGINAL_REGISTRATION_ACCEPT_REMOVED_EVENTS")
check(type(d.frame.script)=="function","F02_ORIGINAL_SETS_FAKE_ON_EVENT_SCRIPT")
check(d.calls.hooks==2,"F03_ORIGINAL_REGISTER_HAS_TWO_HOOK_CALLS")
check(d.cache.questLog_DO_NOT_MODIFY[1]~=nil,"F04_ORIGINAL_INIT_REFILLS_QUEST_CACHE")
check(d.calls.cacheNames==1 and d.event:FakeState(1)==d.states.QUEST_ACCEPTED,
  "F05_ORIGINAL_INIT_RECONSTRUCTS_ACCEPTED_TRACKING")
d.frame:Fire("QUEST_ACCEPTED",1,1)
check(d.event:FakeState(1)==nil,"F06_ORIGINAL_DISPATCH_PREINIT_SETS_EMPTY_RECORD")
check(d.calls.accept==0,"F07_ORIGINAL_FRAME_PREINIT_ACCEPT_NOT_COMPLETED")
check(#d.tick.pending==0,"F08_FAKE_EARLY_ACCEPT_NO_REMOVAL_TIMER")
d.queue.Initialize()
d.tick.combat:Fire()
check(d.calls.accept==0 and d.event:FakeState(1)==nil,
  "F09_ORIGINAL_DISPATCH_PREINIT_CALLBACK_NOT_REPLAYED")
d.frame:Fire("QUEST_ACCEPTED",1,1)
check(d.calls.accept==0,"F10_ORIGINAL_FRAME_POSTINIT_ACCEPT_STILL_DEFERRED")
d.tick.combat:Fire()
check(d.event:FakeState(1)==d.states.QUEST_ACCEPTED and d.calls.accept==1,
  "F11_ORIGINAL_FRAME_POSTINIT_ACCEPT_COMPLETES")
check(d.calls.cacheNames==2 and d.calls.dirty==1 and
      d.calls.journeyAccept==1 and d.calls.announceAccept==1,
  "F12_ORIGINAL_FRAME_POSTINIT_SINKS")

-- E: same unchanged original registration/dispatch, fabricated removal and reaccept.
local e=newHost()
e.cache.RemoveQuest(1)
e.public:RegisterEvents()
check(e.event:FakeState(1)==e.states.QUEST_ACCEPTED,
  "F13_ORIGINAL_INIT_ACCEPTS_INITIAL_FAKE_QUEST")
e.frame:Fire("QUEST_REMOVED",1)
check(e.event:FakeState(1)==e.states.QUEST_REMOVED and #e.tick.pending==1,
  "F14_ORIGINAL_DISPATCH_FAKE_REMOVAL_SETS_PENDING")
e.frame:Fire("QUEST_ACCEPTED",1,1)
check(e.tick.pending[1].cancelled and e.calls.cancel==1,
  "F15_ORIGINAL_DISPATCH_REACCEPT_CANCELS_TIMER")
check(e.event:FakeState(1)==nil and e.calls.accept==0,
  "F16_ORIGINAL_DISPATCH_REACCEPT_LOSES_PREINIT_CALLBACKS")
e.queue.Initialize()
e.tick.combat:Fire()
check(e.calls.accept==0 and e.calls.abandon==0,
  "F17_ORIGINAL_QUEUE_DID_NOT_REPLAY_DISPATCH_CALLBACKS")
e.tick.pending[1]:Fire()
check(e.calls.abandon==0,"F18_FAKE_CANCELLED_TIMER_IGNORED")
e.frame:Fire("QUEST_ACCEPTED",1,1)
e.tick.combat:Fire()
check(e.event:FakeState(1)==e.states.QUEST_ACCEPTED and e.calls.accept==1,
  "F19_ORIGINAL_FRAME_POSTINIT_ACCEPT_AFTER_FAKE_REMOVAL")
local ok=pcall(function()e.frame:Fire("FAKE_UNREGISTERED_EVENT",1,1)end)
check(not ok,"F20_FAKE_FRAME_REJECTS_UNREGISTERED_EVENT")
assert(tests==51,"ORIGINAL_FRAME_EVENT_QUEUE_CENSUS:"..tests)
print("PUBLIC G08 PART47 ORIGINAL REGISTER DISPATCH FRAME: 20/20 PASS")
print("PUBLIC G08 PART47 ORIGINAL: 51/51 total original-source checks; original RegisterEvents/InitQuestLog/OnEvent + four methods, whole original CombatQueue/QuestLogCache under FAKE frame.")
print("PUBLIC G08 PART47 NOT NATIVE: fabricated frame, manually fired quest events, startup timing and game client; historical QuestieInit only read, not executed.")
