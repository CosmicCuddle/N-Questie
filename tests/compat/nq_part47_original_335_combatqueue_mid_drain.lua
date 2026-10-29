-- TEST ONLY: authentic 335 Compat animation timer + WHOLE unchanged
-- QuestieCombatQueue under manual fake AnimationGroup OnFinished callbacks.
-- Covers mid-drain combat lockdown, reentrant enqueue and argument ordering.
-- NOT real 3.3.5a event delivery/client clock/performance.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(p)
  local f=assert(io.open(root.."/"..p,"rb"),"ORIGINAL_SOURCE_MISSING:"..p)
  local s=assert(f:read("*a"));f:close();return s
end
local compatSrc=read("Compat/Compat.lua")
local queueSrc=read("Modules/Libs/QuestieCombatQueue.lua")
local i=assert(compatSrc:find("local activeTimers = {}",1,true))
local j=assert(compatSrc:find("\nlocal mapIdToUiMapId = {}",i+1,true))
local source=compatSrc:sub(i,j-1)
local tests=0
local function check(v,name)assert(v,name);tests=tests+1 end
check(source:find("local function timerOnFinished(self)",1,true)~=nil,
  "Q01_335_ORIGINAL_ANIMATION_TIMER_SOURCE")
check(source:find("timer:SetScript(\"OnFinished\", timerOnFinished)",1,true)~=nil,
  "Q02_335_ORIGINAL_ANIMATION_ONFINISHED")
check(queueSrc:find("local maxUpdatesPerCircle = 5",1,true)~=nil,
  "Q03_ORIGINAL_QUEUE_BATCH_LIMIT_SOURCE")
check(queueSrc:find("if InCombatLockdown() or count >= maxUpdatesPerCircle then",1,true)~=nil,
  "Q04_ORIGINAL_QUEUE_MID_BATCH_COMBAT_CHECK")
check(queueSrc:find("if started then",1,true)~=nil,
  "Q05_ORIGINAL_QUEUE_PREINIT_GUARD")
local groups={}
local function newGroup()
  local group={playing=false,stops=0}
  function group:CreateAnimation()
    local a={parent=self}
    function a:SetScript(which,fn)
      assert(which=="OnFinished" and type(fn)=="function")
      self.onFinished=fn -- DISTINCT from original timer.user callback field.
    end
    function a:SetDuration(d)self.duration=d end
    function a:GetParent()return self.parent end
    self.anim=a
    return a
  end
  function group:SetLooping(n)assert(n=="REPEAT");self.loop=n end
  function group:Play()self.playing=true end
  function group:Stop()self.playing=false;self.stops=self.stops+1 end
  function group:Fire()
    assert(self.playing and self.anim and type(self.anim.onFinished)=="function",
      "FAKE_TIMER_NOT_PLAYING")
    self.anim.onFinished(self.anim)
  end
  groups[#groups+1]=group
  return group
end
local compat={frame={CreateAnimationGroup=function()return newGroup()end}}
local modules={QuestieLib={
  tpack=function(...)return {n=select("#",...),...} end,
  tunpack=function(t)return (unpack or table.unpack)(t,1,t.n) end
}}
local loader={}
function loader:CreateModule(name)
  modules[name]=modules[name] or {}
  return modules[name]
end
local locked=false
local env={QuestieLoader=loader,QuestieCompat=compat,
  InCombatLockdown=function()return locked end,
  tinsert=table.insert,tremove=table.remove}
setmetatable(env,{__index=_G})
local function execute(s,name)
  local fn
  if _VERSION=="Lua 5.1" then fn=assert(loadstring(s,name));setfenv(fn,env)
  else fn=assert(load(s,name,"t",env)) end
  return fn()
end
execute(source,"=ORIGINAL_335_COMPAT_ANIMATION_TIMER")
execute(queueSrc,"@ORIGINAL_335/Modules/Libs/QuestieCombatQueue.lua")
local queue=assert(modules.QuestieCombatQueue)
check(type(compat.C_Timer.NewTicker)=="function",
  "Q06_ORIGINAL_335_COMPAT_C_TIMER_EXECUTED")
check(type(queue.Initialize)=="function" and type(queue.Queue)=="function",
  "Q07_WHOLE_ORIGINAL_QUEUE_EXECUTED")
local actions={}
local function record(s)actions[#actions+1]=s end
queue:Queue(function()record("PREINIT_SHOULD_NOT_RUN")end)
check(#groups==0 and #actions==0,"Q08_ORIGINAL_QUEUE_DROPS_PREINIT")
queue.Initialize()
check(#groups==1 and groups[1].playing,"Q09_ORIGINAL_QUEUE_STARTS_TIMER")
check(groups[1].anim.duration==0.1,"Q10_ORIGINAL_QUEUE_REAL_335_TIMER_DURATION")
check(groups[1].loop=="REPEAT","Q11_ORIGINAL_335_TIMER_REPEATS")
groups[1]:Fire()
check(#actions==0,"Q12_EMPTY_REAL_QUEUE_TICK_NOOP")
queue:Queue(function()
  record("A")
  queue:Queue(function()record("D")end)
  locked=true
end)
queue:Queue(function()record("B")end)
queue:Queue(function()record("C")end)
check(#actions==0,"Q13_QUEUED_CALLBACKS_ARE_DEFERRED")
groups[1]:Fire()
check(#actions==1 and actions[1]=="A",
  "Q14_ORIGINAL_QUEUE_STOPS_AFTER_CALLBACK_ACTIVATES_COMBAT")
check(locked,"Q15_FAKE_COMBAT_LOCK_ENGAGED_BY_FIRST_CALLBACK")
groups[1]:Fire()
check(#actions==1,"Q16_REAL_QUEUE_TICK_SKIPS_DURING_FAKE_COMBAT")
locked=false
groups[1]:Fire()
check(table.concat(actions,",")=="A,B,C,D",
  "Q17_REENTRANT_ENQUEUE_FOLLOWS_EXISTING_FIFO")
groups[1]:Fire()
check(#actions==4,"Q18_DRAINED_QUEUE_DOES_NOT_REPLAY_CALLBACKS")
local args
queue:Queue(function(...)
  args={n=select("#",...),...}
  record("ARGS")
end,"first",nil,"last",nil)
groups[1]:Fire()
check(args and args.n==4,"Q19_ORIGINAL_PACK_UNPACK_PRESERVES_NIL_ARITY")
check(args[1]=="first" and args[2]==nil and args[3]=="last" and args[4]==nil,
  "Q20_ORIGINAL_PACK_UNPACK_PRESERVES_POSITIONAL_VALUES")
check(actions[#actions]=="ARGS","Q21_NIL_ARG_CALLBACK_EXECUTED_ON_QUEUE")
local before=#actions
for n=1,8 do
  local name="S"..n
  queue:Queue(function()record(name)end)
end
check(#actions==before,"Q22_EIGHT_CALLBACKS_WAIT_BEFORE_ANIMATION_TICK")
groups[1]:Fire()
check(#actions==before+6,"Q23_ORIGINAL_BATCH_PROCESSES_SIX_NOT_FIVE")
check(actions[before+1]=="S1" and actions[before+6]=="S6",
  "Q24_FIRST_BATCH_ORDERED_ONE_THROUGH_SIX")
groups[1]:Fire()
check(#actions==before+8 and actions[#actions]=="S8",
  "Q25_NEXT_BATCH_DRAINS_SEVEN_AND_EIGHT")
local start=#actions
for n=1,7 do
  local name="R"..n
  queue:Queue(function()
    record(name)
    if name=="R2" then
      queue:Queue(function()record("R_LATE")end)
    end
  end)
end
groups[1]:Fire()
check(#actions==start+6 and actions[#actions]=="R6",
  "Q26_REENTRANT_APPEND_DOES_NOT_BYPASS_SIX_BATCH_LIMIT")
groups[1]:Fire()
check(#actions==start+8 and actions[start+7]=="R7"
  and actions[start+8]=="R_LATE",
  "Q27_REENTRANT_APPEND_REMAINS_FIFO_AFTER_EXISTING_QUEUE")
local last=#actions
queue:Queue(function()
  record("LOCK_AFTER")
  locked=true
end)
queue:Queue(function()record("DEFERRED_AFTER_LOCK")end)
groups[1]:Fire()
check(#actions==last+1 and actions[#actions]=="LOCK_AFTER",
  "Q28_LOCK_ACTIVATED_INSIDE_CALLBACK_STOPS_NEXT_CALLBACK")
groups[1]:Fire()
check(#actions==last+1,"Q29_LOCKED_TICK_DOES_NOT_DRAIN_REMAINDER")
locked=false
groups[1]:Fire()
check(#actions==last+2 and actions[#actions]=="DEFERRED_AFTER_LOCK",
  "Q30_UNLOCKED_TICK_RESUMES_QUEUED_REMAINDER")
check(#groups==1 and groups[1].playing,
  "Q31_GENUINE_335_QUEUE_TICKER_STAYS_ACTIVE")
check(groups[1].stops==0,"Q32_NO_SYNTHETIC_ANIMATION_STOP_EXPECTED")
assert(tests==32,"ORIGINAL_335_COMBATQUEUE_MID_DRAIN_CENSUS:"..tests)
print("PUBLIC G08 PART47 ORIGINAL 335 COMBATQUEUE MID DRAIN: 32/32 PASS")
print("PUBLIC G08 PART47 ORIGINAL: whole unchanged original QuestieCombatQueue and genuine 335 Compat animation timer source; callback enqueue and combat-lock transitions in fake scheduler.")
print("PUBLIC G08 PART47 NOT NATIVE: manually fired fake AnimationGroup, artificial lockdown, callback order and quest-less data; no real Blizzard client event or performance measurements.")
