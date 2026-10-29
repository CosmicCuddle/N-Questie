-- TEST ONLY: original QuestieInit contiguous startup source fragment executed by
-- the WHOLE unchanged original ThreadLib and CombatQueue under a FAKE timer host.
-- This is NOT the whole original QuestieInit stage and has NO native WoW events.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"ORIGINAL_SOURCE_MISSING:"..path)
  local s=assert(f:read("*a"));f:close();return s
end
local initSrc=read("Modules/QuestieInit.lua")
local threadSrc=read("Modules/Libs/ThreadLib.lua")
local queueSrc=read("Modules/Libs/QuestieCombatQueue.lua")
local begin="    coYield()\n    QuestEventHandler:RegisterEvents()\n"
local finish="    local dateToday = date(\"%y-%m-%d\")"
local i=assert(initSrc:find(begin,1,true),"ORIGINAL_INIT_WINDOW_BEGIN_MISSING")
local j=assert(initSrc:find(finish,i+#begin,true),"ORIGINAL_INIT_WINDOW_END_MISSING")
local fragment=initSrc:sub(i,j-1)
local checks=0
local function check(v,n) assert(v,n);checks=checks+1 end
check(fragment:find("QuestEventHandler:RegisterEvents()",1,true)~=nil,
  "T01_FIRST_PARTY_REGISTER_EVENTS_INSIDE_FRAGMENT")
check(fragment:find("QuestieCombatQueue.Initialize()",1,true)~=nil,
  "T02_FIRST_PARTY_QUEUE_INIT_INSIDE_FRAGMENT")
local _,yieldCount=fragment:gsub("coYield%(%s*%)","")
check(yieldCount==8,"T03_EIGHT_GENUINE_EXPLICIT_YIELDS")
check(fragment:find("QuestEventHandler:RegisterEvents()",1,true) <
      fragment:find("QuestieCombatQueue.Initialize()",1,true),
  "T04_FIRST_PARTY_SOURCE_ORDER")
check(threadSrc:find("coResume(thread)",1,true)~=nil,
  "T05_FIRST_PARTY_THREADLIB_RESUMES_COROUTINE")
check(threadSrc:find("newTicker(delay or 0,",1,true)~=nil,
  "T06_FIRST_PARTY_THREADLIB_USES_TICKER")
check(queueSrc:find("if started then",1,true)~=nil,
  "T07_FIRST_PARTY_QUEUE_GUARDS_UNSTARTED")

local calls={registered=0,accepted=0,rejected=0,queueInit=0,errors=0}
local seen={}
local timers={stage=nil,combat=nil}
local registered=false
local locked=false
local function record(s) seen[#seen+1]=s end
local timerApi={NewTicker=function(delay,callback)
  assert(type(callback)=="function","FAKE_TICKER_CALLBACK_TYPE")
  local t={delay=delay,callback=callback,cancelled=false}
  function t:Cancel()self.cancelled=true end
  function t:Fire()if not self.cancelled then self.callback() end end
  if delay==0 then
    assert(timers.stage==nil,"FAKE_STAGE_TICKER_DUPLICATE")
    timers.stage=t
  elseif delay==0.1 then
    assert(timers.combat==nil,"FAKE_COMBAT_TICKER_DUPLICATE")
    timers.combat=t
  else error("FAKE_UNEXPECTED_TIMER_DELAY:"..tostring(delay)) end
  return t
end}
local questie={Error=function(_,...)calls.errors=calls.errors+1;error(...) end}
local lib={tpack=function(...)return {n=select("#",...),...} end,
  tunpack=function(t)return (unpack or table.unpack)(t,1,t.n) end}
local modules={QuestieLib=lib}
local loader={}
function loader:CreateModule(name)
  if not modules[name] then modules[name]={} end
  return modules[name]
end
local env={QuestieLoader=loader,QuestieCompat={C_Timer=timerApi},
  Questie=questie,InCombatLockdown=function()return locked end,
  tinsert=table.insert,tremove=table.remove}
setmetatable(env,{__index=_G})
local function loadInto(code,name,scope)
  local f
  if _VERSION=="Lua 5.1" then f=assert(loadstring(code,name));setfenv(f,scope)
  else f=assert(load(code,name,"t",scope)) end
  return f()
end
loadInto(threadSrc,"@ORIGINAL_335/Modules/Libs/ThreadLib.lua",env)
loadInto(queueSrc,"@ORIGINAL_335/Modules/Libs/QuestieCombatQueue.lua",env)
local threadLib=assert(modules.ThreadLib)
local queue=assert(modules.QuestieCombatQueue)
local function fakeEvent(label)
  if not registered then calls.rejected=calls.rejected+1;return false end
  queue:Queue(function()calls.accepted=calls.accepted+1;record("accept:"..label) end)
  return true
end
local function simple(name)
  return function()record(name)end
end
local stageEnv={
  coYield=coroutine.yield,
  QuestEventHandler={RegisterEvents=function()
    calls.registered=calls.registered+1;registered=true;record("register")
  end},
  ChatFilter={RegisterEvents=simple("chat")},
  QuestieMap={InitializeQueue=simple("map")},
  QuestieQuest={Initialize=simple("quest_init"),
    GetAllQuestIdsNoObjectives=simple("ids_no_objectives"),
    GetAllQuestIds=simple("ids_all")},
  WorldMapButton={Initialize=simple("worldmap")},
  Townsfolk={PostBoot=simple("townsfolk")},
  QuestieTracker={Initialize=simple("tracker")},
  Hooks={HookQuestLogTitle=simple("hooks")},
  QuestieCombatQueue={Initialize=function()
    calls.queueInit=calls.queueInit+1
    queue.Initialize()
    record("queue_init")
  end}
}
setmetatable(stageEnv,{__index=_G})
local stage=loadInto("return function()\n"..fragment.."\nend",
  "=ORIGINAL_335_CONTIGUOUS_QUESTIEINIT_FRAGMENT_FAKE_DEPENDENCIES",stageEnv)
check(type(stage)=="function","T08_CONTIGUOUS_ORIGINAL_FRAGMENT_COMPILES_AS_FAKE_STAGE")
local stageTimer,co=threadLib.ThreadError(stage,0,"FAKE_INIT_STAGE_ERROR")
check(stageTimer==timers.stage and stageTimer.delay==0,
  "T09_ORIGINAL_THREADLIB_CREATES_FAKE_STAGE_TIMER")
check(coroutine.status(co)=="suspended","T10_ORIGINAL_STAGE_SUSPENDED_INITIAL")
check(not fakeEvent("before_register"),"T11_FAKE_FRAME_REJECTS_BEFORE_REGISTRATION")
check(calls.rejected==1,"T12_FAKE_EVENT_BEFORE_REGISTER_REJECTED")
stageTimer:Fire() -- initial coYield before registration
check(coroutine.status(co)=="suspended","T13_FIRST_REAL_YIELD_SUSPENDS")
check(not registered and calls.queueInit==0,"T14_FIRST_TICK_BEFORE_REGISTER")
stageTimer:Fire() -- registration and following coYield
check(registered and calls.registered==1,"T15_SECOND_TICK_REAL_REGISTER_CALL")
check(coroutine.status(co)=="suspended" and calls.queueInit==0,
  "T16_POST_REGISTER_YIELD_BEFORE_QUEUE")
check(fakeEvent("after_register_before_queue"),
  "T17_FAKE_INGRESS_IN_SOURCE_WINDOW")
check(calls.accepted==0,"T18_PREINIT_EVENT_QUEUED_CALLBACK_NOT_INLINE")
check(timers.combat==nil,"T19_PREINIT_COMBAT_TICKER_ABSENT")
stageTimer:Fire() -- chat + map
check(seen[#seen]=="map","T20_REAL_FRAGMENT_CHAT_MAP_STEP")
stageTimer:Fire() -- QuestieQuest:Initialize
check(seen[#seen]=="quest_init","T21_REAL_FRAGMENT_QUEST_INIT_STEP")
stageTimer:Fire() -- WorldMapButton.Initialize
check(seen[#seen]=="worldmap","T22_REAL_FRAGMENT_MAP_BUTTON_STEP")
stageTimer:Fire() -- GetAllQuestIdsNoObjectives
check(seen[#seen]=="ids_no_objectives","T23_REAL_FRAGMENT_NO_OBJ_QUERY")
stageTimer:Fire() -- Townsfolk.PostBoot
check(seen[#seen]=="townsfolk","T24_REAL_FRAGMENT_TOWNSFOLK")
check(fakeEvent("late_before_queue"),"T25_FAKE_INGRESS_LATE_SOURCE_WINDOW")
stageTimer:Fire() -- GetAllQuestIds
check(seen[#seen]=="ids_all","T26_REAL_FRAGMENT_ALL_IDS")
check(calls.queueInit==0,"T27_STILL_NOT_QUEUE_INIT")
stageTimer:Fire() -- tracker, hooks, combat queue initialization
check(calls.queueInit==1 and timers.combat~=nil,
  "T28_NINTH_TICK_ORIGINAL_QUEUE_INITIALIZED")
check(seen[#seen]=="queue_init","T29_FIRST_PARTY_LAST_CALL_IN_FRAGMENT")
check(coroutine.status(co)=="dead","T30_REAL_THREADLIB_COROUTINE_NOW_DEAD")
timers.combat:Fire()
check(calls.accepted==0,"T31_PREINIT_FAKE_EVENTS_NEVER_REPLAYED")
check(fakeEvent("after_queue_init"),"T32_FAKE_POSTINIT_EVENT_SUBMISSION")
check(calls.accepted==0,"T33_ORIGINAL_COMBATQUEUE_DEFERRED_EXECUTION")
locked=true
timers.combat:Fire()
check(calls.accepted==0,"T34_ORIGINAL_COMBATQUEUE_RESPECTS_FAKE_LOCKDOWN")
locked=false
timers.combat:Fire()
check(calls.accepted==1 and seen[#seen]=="accept:after_queue_init",
  "T35_POSTINIT_FAKE_EVENT_CALLBACK_DRAINED")
stageTimer:Fire() -- ThreadLib sees dead and cancels fake ticker
check(stageTimer.cancelled,"T36_ORIGINAL_THREADLIB_CANCELS_AFTER_DEAD")
check(calls.registered==1 and calls.queueInit==1,
  "T37_ORIGINAL_FRAGMENT_SINGLE_REGISTER_AND_INIT")
check(calls.errors==0,"T38_NO_FAKE_STAGE_ERROR")
check(calls.rejected==1,"T39_ONLY_PRE_REG_FAKE_EVENT_REJECTED")
check(timers.combat.delay==0.1,"T40_ORIGINAL_QUEUE_0_1_SECOND_FAKE_TICKER")
assert(checks==40,"ORIGINAL_INIT_FRAGMENT_THREADLIB_CENSUS:"..checks)
print("PUBLIC G08 PART47 ORIGINAL THREADLIB INIT FRAGMENT: 40/40 PASS")
print("PUBLIC G08 PART47 ORIGINAL: entire unchanged ThreadLib/CombatQueue; exact contiguous original QuestieInit source fragment from pre-registration yield through CombatQueue.Initialize.")
print("PUBLIC G08 PART47 NOT NATIVE: generated wrapper, fake dependent modules, frame ingress, timers, stage tick and combat; not whole QuestieInit or real WoW event delivery.")
