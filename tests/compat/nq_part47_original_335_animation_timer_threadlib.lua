-- TEST ONLY: WHOLE unchanged original ThreadLib and CombatQueue plus exact
-- contiguous original 335 Compat animation-timer code under FAKE AnimationGroup.
-- Animation OnFinished delivery is manually simulated; NOT native WoW.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"HISTORIC_SOURCE_MISSING:"..path)
  local s=assert(f:read("*a"));f:close();return s
end
local compatSrc=read("Compat/Compat.lua")
local threadSrc=read("Modules/Libs/ThreadLib.lua")
local queueSrc=read("Modules/Libs/QuestieCombatQueue.lua")
local initSrc=read("Modules/QuestieInit.lua")
local function originalSlice(src,startMark,endMark)
  local a=assert(src:find(startMark,1,true),"SOURCE_START_NOT_FOUND:"..startMark)
  local b=assert(src:find(endMark,a+#startMark,true),"SOURCE_END_NOT_FOUND:"..endMark)
  return src:sub(a,b-1)
end
local timerSource=originalSlice(compatSrc,
  "local activeTimers = {}",
  "\nlocal mapIdToUiMapId = {}")
local tests=0
local function check(ok,n)assert(ok,n);tests=tests+1 end
check(timerSource:find("local function timerCancel(id)",1,true)~=nil,
  "A01_TIMER_CANCEL_GENUINE_SOURCE")
check(timerSource:find("local function timerOnFinished(self)",1,true)~=nil,
  "A02_TIMER_FINISHED_GENUINE_SOURCE")
check(timerSource:find("QuestieCompat.C_Timer = {",1,true)~=nil,
  "A03_TIMER_REPEATING_AND_AFTER_GENUINE_SOURCE")
check(timerSource:find("duration < 0.01",1,true)~=nil,
  "A04_TIMER_335_MINIMUM_DURATION_SOURCE")
check(timerSource:find("inactiveTimers[timer] = true",1,true)~=nil,
  "A05_TIMER_335_REUSE_POOL_SOURCE")
check(threadSrc:find("newTicker(delay or 0,",1,true)~=nil,
  "A06_THREADLIB_GENUINE_TIMER_SCHEDULING")
check(queueSrc:find("C_Timer.NewTicker(0.1, function()",1,true)~=nil,
  "A07_COMBATQUEUE_GENUINE_TIMER_SCHEDULING")
local reg=assert(initSrc:find("QuestEventHandler:RegisterEvents()",1,true))
local queueInit=assert(initSrc:find("QuestieCombatQueue.Initialize()",reg+1,true))
check(reg<queueInit,"A08_GENUINE_INIT_REGISTER_BEFORE_QUEUE")
local _,barriers=initSrc:sub(reg,queueInit):gsub("coYield%(%s*%)","")
check(barriers==7,"A09_SEVEN_YIELDS_BETWEEN_REGISTER_AND_QUEUE")
local created={}
local function newGroup()
  local group={playing=false,stopped=0,plays=0}
  function group:CreateAnimation()
    assert(not self.animation,"FAKE_GROUP_MULTIPLE_ANIMATIONS")
    local anim={parent=self}
    function anim:SetScript(event,fn)
      assert(event=="OnFinished" and type(fn)=="function")
      self.onFinished=fn
    end
    function anim:SetDuration(seconds) self.duration=seconds end
    function anim:GetParent()return self.parent end
    self.animation=anim
    return anim
  end
  function group:SetLooping(v)assert(v=="REPEAT");self.looping=v end
  function group:Stop() self.playing=false;self.stopped=self.stopped+1 end
  function group:Play() self.playing=true;self.plays=self.plays+1 end
  function group:Fire()
    assert(self.playing and self.animation and type(self.animation.onFinished)=="function",
      "FAKE_FINISHED_EVENT_WHILE_NOT_PLAYING")
    self.animation.onFinished(self.animation)
  end
  created[#created+1]=group
  return group
end
local frame={}
function frame:CreateAnimationGroup()return newGroup()end
local compat={frame=frame}
local lib={tpack=function(...) return {n=select("#",...),...} end,
  tunpack=function(t) return (unpack or table.unpack)(t,1,t.n) end}
local modules={QuestieLib=lib}
local loader={}
function loader:CreateModule(name)
  if not modules[name] then modules[name]={} end
  return modules[name]
end
local errors={}
local questie={Error=function(_,msg,detail)
  errors[#errors+1]=tostring(msg)..":"..tostring(detail)
end}
local locked=false
local env={QuestieCompat=compat,QuestieLoader=loader,Questie=questie,
  tinsert=table.insert,tremove=table.remove,
  InCombatLockdown=function()return locked end}
setmetatable(env,{__index=_G})
local function execute(code,name)
  local f
  if _VERSION=="Lua 5.1" then
    f=assert(loadstring(code,name));setfenv(f,env)
  else f=assert(load(code,name,"t",env)) end
  f()
end
execute(timerSource,"=ORIGINAL_335_CONTIGUOUS_COMPAT_ANIMATION_TIMERS")
execute(threadSrc,"@ORIGINAL_335/Modules/Libs/ThreadLib.lua")
execute(queueSrc,"@ORIGINAL_335/Modules/Libs/QuestieCombatQueue.lua")
local ctimer=assert(compat.C_Timer)
local thread=assert(modules.ThreadLib)
local queue=assert(modules.QuestieCombatQueue)
check(type(ctimer.NewTicker)=="function" and type(ctimer.After)=="function",
  "A10_ORIGINAL_335_TIMER_LOADED")
check(type(thread.ThreadError)=="function" and type(queue.Initialize)=="function",
  "A11_WHOLE_THREADLIB_AND_QUEUE_LOADED")
local ticks=0
local id=ctimer.NewTicker(0,function(received)
  ticks=ticks+1
  check(received==id,"A12_CALLBACK_HAS_ORIGINAL_TIMER_ID")
end)
check(#created==1 and created[1].playing,"A13_ORIGINAL_TIMER_CREATES_FAKE_GROUP")
check(created[1].animation.duration==0.01,"A14_ORIGINAL_TIMER_CLAMPS_ZERO_TO_POINT_ZERO_ONE")
check(created[1].looping=="REPEAT","A15_ORIGINAL_TIMER_SET_REPEAT")
created[1]:Fire()
check(ticks==1,"A16_ORIGINAL_FIRST_TICK_FIRED")
created[1]:Fire()
check(ticks==2,"A17_ORIGINAL_REPEATING_TIMER_FIRED_TWICE")
id:Cancel()
check(not created[1].playing and created[1].stopped==1,
  "A18_ORIGINAL_CANCEL_STOPS_ANIMATION_GROUP")
id:Cancel()
check(created[1].stopped==1,"A19_REPEATED_CANCEL_IDEMPOTENT")
local afterHits=0
local afterID=ctimer.After(0,function()afterHits=afterHits+1 end)
check(#created==1 and created[1].playing,
  "A20_335_TIMER_REUSES_INACTIVE_ANIMATION")
check(afterID~=id,"A21_REUSED_ANIMATION_HAS_NEW_TIMER_ID")
check(created[1].animation.duration==0.01,
  "A22_AFTER_ZERO_CLAMPED")
created[1]:Fire()
check(afterHits==1 and not created[1].playing,
  "A23_AFTER_ONE_SHOT_AUTO_CANCELS")
local iterations=0
local twice=ctimer.NewTicker(0.4,function()iterations=iterations+1 end,2)
check(created[1].animation.duration==0.4 and #created==1,
  "A24_NEW_TICKER_REUSES_GROUP_WITH_DURATION")
created[1]:Fire()
check(iterations==1 and created[1].playing,
  "A25_ONE_OF_TWO_ITERATIONS_KEEPS_PLAYING")
created[1]:Fire()
check(iterations==2 and not created[1].playing,
  "A26_SECOND_ITERATION_AUTO_CANCELS")
local reincarnated,firstSelf,secondHits
secondHits=0
firstSelf=ctimer.NewTicker(0.2,function()
  firstSelf:Cancel()
  reincarnated=ctimer.NewTicker(0.3,function()
    secondHits=secondHits+1
  end,2)
end,1)
local reused=created[1]
check(reused.playing and reused.animation.duration==0.2,
  "A27_REENTRANT_TEST_INITIAL_TIMER_RUNNING")
reused:Fire()
check(firstSelf~=reincarnated and #created==1,
  "A28_CANCEL_THEN_REUSE_IN_SAME_CALLBACK")
check(reused.playing and reused.animation.duration==0.3,
  "A29_REENTRANT_REUSE_WAS_NOT_STOPPED_BY_OLD_CALLBACK")
reused:Fire()
check(secondHits==1 and reused.playing,
  "A30_REENTRANT_NEW_TIMER_ITERATIONS_NOT_CONSUMED_BY_OLD")
reused:Fire()
check(secondHits==2 and not reused.playing,
  "A31_REENTRANT_NEW_TIMER_COMPLETES_TWICE")
local done=0
local stageTicks=0
local stageTimer,co=thread.ThreadCallback(function()
  stageTicks=stageTicks+1
  coroutine.yield()
  stageTicks=stageTicks+1
end,0,function()done=done+1 end)
check(type(stageTimer)=="table" and coroutine.status(co)=="suspended",
  "A32_GENUINE_THREADLIB_TIMER_AND_COROUTINE")
check(created[1].animation.duration==0.01 and created[1].playing,
  "A33_THREADLIB_ZERO_DELAY_USES_ORIGINAL_335_CLAMP")
created[1]:Fire()
check(stageTicks==1 and done==0 and coroutine.status(co)=="suspended",
  "A34_THREADLIB_FIRST_RESUME_AND_YIELD")
created[1]:Fire()
check(stageTicks==2 and done==0 and coroutine.status(co)=="dead",
  "A35_THREADLIB_SECOND_RESUME_COMPLETES")
created[1]:Fire()
check(done==1 and not created[1].playing,
  "A36_THREADLIB_CANCELS_TIMER_AND_CALLS_COMPLETION_NEXT_TICK")
queue:Queue(function() error("UNINITIALIZED_CALLBACK_MUST_NOT_RUN") end)
check(#created==1,"A37_PREINIT_QUEUE_HAS_NO_TIMER")
queue.Initialize()
check(created[1].playing and created[1].animation.duration==0.1,
  "A38_ORIGINAL_QUEUE_INIT_STARTS_335_ANIMATION_TIMER")
local count=0
for n=1,7 do
  queue:Queue(function()count=count+1 end)
end
check(count==0,"A39_QUEUE_DEFERS_CALLBACKS_UNTIL_TIMER")
locked=true
created[1]:Fire()
check(count==0,"A40_ORIGINAL_QUEUE_RESPECTS_FAKE_COMBAT_LOCKDOWN")
locked=false
created[1]:Fire()
check(count==6,"A41_ORIGINAL_QUEUE_FIRST_TICK_DRAINS_SIX")
created[1]:Fire()
check(count==7,"A42_ORIGINAL_QUEUE_SECOND_TICK_DRAINS_REST")
check(created[1].playing,"A43_ORIGINAL_COMBATQUEUE_REPEATING_TIMER_ACTIVE")
check(#errors==0,"A44_NO_THREADLIB_FAKE_ERRORS")
check(#created==1,"A45_POOL_REUSED_SINGLE_FAKE_ANIMATION_GROUP")
assert(tests==45,"335_REAL_ANIMATION_TIMER_CENSUS:"..tests)
print("PUBLIC G08 PART47 ORIGINAL 335 ANIMATION TIMER: 45/45 PASS")
print("PUBLIC G08 PART47 ORIGINAL: intact Compat timer source block plus entire original ThreadLib and QuestieCombatQueue, with fake AnimationGroup OnFinished callbacks.")
print("PUBLIC G08 PART47 NOT NATIVE: animation callbacks fired manually; no WoW UI frame scheduler, event timing, real character or whole Compat ADDON_LOADED executed.")
