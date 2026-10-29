-- TEST ONLY: real historical 335 Compat timer source plus whole ThreadLib and
-- CombatQueue execute the unchanged contiguous QuestieInit window under FAKE
-- AnimationGroup callbacks. No full QuestieInit, native frame or WoW client.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(p)
  local f=assert(io.open(root.."/"..p,"rb"),"ORIGINAL_SOURCE_MISSING:"..p)
  local s=assert(f:read("*a"));f:close();return s
end
local function slice(s,a,b)
  local i=assert(s:find(a,1,true),"ORIGINAL_START_MISSING:"..a)
  local j=assert(s:find(b,i+#a,true),"ORIGINAL_END_MISSING:"..b)
  return s:sub(i,j-1)
end
local compatSrc=read("Compat/Compat.lua")
local timerSource=slice(compatSrc,"local activeTimers = {}","\nlocal mapIdToUiMapId = {}")
local initSrc=read("Modules/QuestieInit.lua")
local initFragment=slice(initSrc,
  "    coYield()\n    QuestEventHandler:RegisterEvents()\n",
  "    local dateToday = date(\"%y-%m-%d\")")
local threadSrc=read("Modules/Libs/ThreadLib.lua")
local queueSrc=read("Modules/Libs/QuestieCombatQueue.lua")
local checks=0
local function check(v,n) assert(v,n);checks=checks+1 end
local _,yields=initFragment:gsub("coYield%(%s*%)","")
check(yields==8,"W01_EIGHT_REAL_SOURCE_YIELDS")
check(initFragment:find("QuestEventHandler:RegisterEvents()",1,true) <
  initFragment:find("QuestieCombatQueue.Initialize()",1,true),"W02_REAL_INIT_ORDER")
check(timerSource:find("duration < 0.01",1,true)~=nil,
  "W03_GENUINE_COMPAT_TIMER_ZERO_CLAMP_SOURCE")
check(timerSource:find('anim:SetLooping("REPEAT")',1,true)~=nil,
  "W04_GENUINE_COMPAT_REPEAT_SOURCE")
local groups={}
local function newGroup()
  local g={playing=false,plays=0,stops=0}
  function g:CreateAnimation()
    assert(not self.anim)
    local a={parent=self}
    function a:SetScript(s,fn)
      assert(s=="OnFinished" and type(fn)=="function");self.onFinished=fn
    end
    function a:SetDuration(d)self.duration=d end
    function a:GetParent()return self.parent end
    self.anim=a;return a
  end
  function g:SetLooping(s)assert(s=="REPEAT");self.looping=s end
  function g:Play()self.playing=true;self.plays=self.plays+1 end
  function g:Stop()self.playing=false;self.stops=self.stops+1 end
  function g:Fire()
    assert(self.playing and self.anim and self.anim.onFinished,"FAKE_ANIMATION_NOT_PLAYING")
    self.anim.onFinished(self.anim)
  end
  groups[#groups+1]=g
  return g
end
local compat={frame={CreateAnimationGroup=function()return newGroup()end}}
local calls={accepted=0,registered=0,rejected=0,initialized=0,errors=0}
local actions={}
local function record(s)actions[#actions+1]=s end
local lib={tpack=function(...)return {n=select("#",...),...} end,
  tunpack=function(t)return (unpack or table.unpack)(t,1,t.n) end}
local modules={QuestieLib=lib}
local loader={}
function loader:CreateModule(n)
  modules[n]=modules[n] or {}
  return modules[n]
end
local combatLocked=false
local env={
  QuestieCompat=compat,QuestieLoader=loader,
  Questie={Error=function(_,...)calls.errors=calls.errors+1;error(...) end},
  tremove=table.remove,tinsert=table.insert,
  InCombatLockdown=function()return combatLocked end
}
setmetatable(env,{__index=_G})
local function loadCode(s,name,scope)
  local f
  if _VERSION=="Lua 5.1" then f=assert(loadstring(s,name));setfenv(f,scope)
  else f=assert(load(s,name,"t",scope)) end
  return f()
end
loadCode(timerSource,"=ORIGINAL_335_CONTIGUOUS_COMPAT_TIMER_SOURCE",env)
loadCode(threadSrc,"@ORIGINAL_335/Modules/Libs/ThreadLib.lua",env)
loadCode(queueSrc,"@ORIGINAL_335/Modules/Libs/QuestieCombatQueue.lua",env)
local thread=assert(modules.ThreadLib)
local queue=assert(modules.QuestieCombatQueue)
check(type(compat.C_Timer.NewTicker)=="function","W05_GENUINE_TIMER_LOADED")
check(type(thread.ThreadError)=="function","W06_WHOLE_THREADLIB_LOADED")
check(type(queue.Initialize)=="function","W07_WHOLE_COMBATQUEUE_LOADED")
local registered=false
local function fakeAccept(label)
  if not registered then calls.rejected=calls.rejected+1;return false end
  queue:Queue(function()calls.accepted=calls.accepted+1;record(label)end)
  return true
end
local function stub(name)
  return function()record(name)end
end
local stageScope={
  coYield=coroutine.yield,
  QuestEventHandler={RegisterEvents=function()
    registered=true;calls.registered=calls.registered+1;record("register")
  end},
  ChatFilter={RegisterEvents=stub("chat")},
  QuestieMap={InitializeQueue=stub("map")},
  QuestieQuest={Initialize=stub("quest-init"),
    GetAllQuestIdsNoObjectives=stub("ids-no-obj"),
    GetAllQuestIds=stub("ids-all")},
  WorldMapButton={Initialize=stub("button")},
  Townsfolk={PostBoot=stub("townsfolk")},
  QuestieTracker={Initialize=stub("tracker")},
  Hooks={HookQuestLogTitle=stub("hooks")},
  QuestieCombatQueue={Initialize=function()
    calls.initialized=calls.initialized+1
    queue.Initialize()
    record("queue-initialize")
  end}
}
setmetatable(stageScope,{__index=_G})
local stage=loadCode("return function()\n"..initFragment.."\nend",
  "=GENUINE_335_INIT_FRAGMENT_FAKE_DEPENDENCIES",stageScope)
local stageTimer,coroutineHandle=thread.ThreadError(stage,0,"FAKE_STARTUP_STAGE")
check(#groups==1 and groups[1].playing,"W08_STAGE_CREATED_ANIMATION_GROUP")
check(groups[1].anim.duration==0.01,"W09_REAL_TIMER_CLAMPS_STAGE_ZERO_DELAY")
check(stageTimer and coroutine.status(coroutineHandle)=="suspended",
  "W10_STAGE_TIMER_AND_COROUTINE_START")
check(not fakeAccept("early"),"W11_FAKE_EARLY_EVENT_REJECTED")
groups[1]:Fire()
check(not registered and coroutine.status(coroutineHandle)=="suspended",
  "W12_FIRST_SOURCE_YIELD_BEFORE_REGISTRATION")
groups[1]:Fire()
check(registered and calls.registered==1,"W13_SECOND_TICK_CALLS_ORIGINAL_REGISTER_SITE")
check(groups[1].playing and calls.initialized==0,
  "W14_POST_REGISTER_QUEUE_UNSTARTED")
check(fakeAccept("during-startup"),"W15_FAKE_INGRESS_WHILE_SOURCE_SUSPENDED")
check(calls.accepted==0,"W16_PREINIT_CALLBACK_NOT_EXECUTED")
for n=1,6 do groups[1]:Fire() end
check(calls.initialized==0 and #groups==1,"W17_SOURCE_INIT_NOT_YET_QUEUED")
check(actions[#actions]=="ids-all","W18_ORIGINAL_SOURCE_INTERMEDIATE_DEPENDENCY_ORDER")
check(fakeAccept("late-startup"),"W19_SECOND_FAKE_PREINIT_EVENT")
groups[1]:Fire()
check(calls.initialized==1 and coroutine.status(coroutineHandle)=="dead",
  "W20_ORIGINAL_SOURCE_INITIALIZES_QUEUE_ON_NINTH_TICK")
check(#groups==2 and groups[2].playing,"W21_REAL_TIMER_CREATES_SECOND_ACTIVE_ANIMATION")
check(groups[1].playing and groups[1].anim.duration==0.01,
  "W22_STAGE_GROUP_STILL_RUNNING_UNTIL_DEAD_DETECTION_TICK")
check(groups[2].anim.duration==0.1,"W23_COMBAT_QUEUE_AUTHENTIC_TIMER_DURATION")
groups[2]:Fire()
check(calls.accepted==0,"W24_NO_REPLAY_OF_PREINIT_FAKE_CALLBACKS")
check(fakeAccept("after-startup"),"W25_FAKE_POSTINIT_EVENT_ENQUEUES")
check(calls.accepted==0,"W26_POSTINIT_CALLBACK_DEFERRED_TO_TICK")
combatLocked=true
groups[2]:Fire()
check(calls.accepted==0,"W27_COMBATQUEUE_GATED_ON_SYNTHETIC_COMBAT")
combatLocked=false
groups[2]:Fire()
check(calls.accepted==1 and actions[#actions]=="after-startup",
  "W28_REAL_COMBATQUEUE_DRAINS_POSTINIT_CALLBACK")
groups[1]:Fire()
check(not groups[1].playing and groups[1].stops==1,
  "W29_REAL_THREADLIB_CANCELS_COMPLETED_STAGE_TIMER")
check(groups[2].playing,"W30_QUEUE_ANIMATION_REMAINS_ACTIVE")
local afterCount=0
compat.C_Timer.After(0,function()afterCount=afterCount+1 end)
check(#groups==2 and groups[1].playing and groups[1].anim.duration==0.01,
  "W31_REAL_TIMER_POOL_REUSES_CANCELLED_STAGE_ANIMATION")
groups[1]:Fire()
check(afterCount==1 and not groups[1].playing,
  "W32_REUSED_STAGE_ANIMATION_AFTER_ONE_SHOT_CANCELS")
check(calls.initialized==1 and calls.registered==1,"W33_SOURCE_STAGE_REGISTER_INIT_ONCE")
check(calls.rejected==1 and calls.errors==0,
  "W34_FAKE_EVENT_REJECTION_NO_COROUTINE_ERRORS")
check(actions[1]=="register" and actions[#actions]=="after-startup",
  "W35_SOURCE_ORDER_AND_FAKE_INGRESS_END_STATE")
assert(checks==35,"G08_335_REAL_TIMER_INIT_WINDOW_CENSUS:"..checks)
print("PUBLIC G08 PART47 ORIGINAL 335 TIMER INIT WINDOW: 35/35 PASS")
print("PUBLIC G08 PART47 ORIGINAL: full unchanged ThreadLib/CombatQueue and contiguous QuestieInit fragment driven by genuine 335 Compat animation timer under fake OnFinished.")
print("PUBLIC G08 PART47 NOT NATIVE: manually fired AnimationGroup callbacks, invented quest events and dependency stubs; full QuestieInit and native WoW client not executed.")
