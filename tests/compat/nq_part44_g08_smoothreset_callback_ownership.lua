-- PUBLIC-SAFE TEST ONLY. Execute unchanged original ThreadLib and exact original
-- QuestieQuest:SmoothReset function with entirely invented C_Timer / quest globals.
local root=assert(os.getenv("NQ_G08_SMOOTHRESET_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"));local s=assert(f:read("*a"));f:close();return s
end
local q=read("Modules/Quest/QuestieQuest.lua")
local a=read("Modules/Quest/AvailableQuests.lua")
local t=read("Modules/Libs/ThreadLib.lua")
local n=0
local function check(p,msg)assert(p,msg);n=n+1 end
local function compile(s,env,name)
 local f
 if _VERSION=="Lua 5.1" then f=assert(loadstring(s,name));setfenv(f,env)
 else f=assert(load(s,name,"t",env)) end
 return f()
end
local first="function QuestieQuest:SmoothReset()"
local last="\n---@param questId number\n---@return boolean\nfunction QuestieQuest:ShouldShowQuestNotes"
local i=assert(q:find(first,1,true),"SOURCE_BEGIN_MISSING")
local j=assert(q:find(last,i+#first,true),"SOURCE_END_MISSING")
local body=q:sub(i,j-1)
check(not q:find(first,i+#first,true),"S01_UNIQUE_ORIGINAL_SMOOTHRESET")
check(body:find("_resetNeedsAvailables = true",1,true)~=nil,"S02_REAL_WAIT_LATCH")
check(body:find("AvailableQuests.CalculateAndDrawAll(function()",1,true)~=nil,"S03_REAL_CALC_CALLBACK")
check(body:find("return (not QuestieQuest._resetNeedsAvailables)",1,true)~=nil,"S04_REAL_WAIT_CONDITION")
check(body:find("_isResetting = nil",1,true)~=nil,"S05_REAL_RESET_CLEAR")
check(body:find("_resetAgain and not QuestieQuest._resetNeedsAvailables",1,true)~=nil,"S06_REAL_REENTRY_FENCE")
check(a:find("timer:Cancel()",1,true)~=nil,"S07_REAL_OUTER_CANCEL")
check(t:find("if(callbackFunction) then",1,true)~=nil,"S08_REAL_THREAD_CALLBACK_BRANCH")
check(t:find("if not success then",1,true)~=nil,"S09_REAL_ERROR_BRANCH")
local function fixture()
 local timers,errors={},{}
 local function newTicker(delay,fn)
  local o={cancelled=false,delay=delay,fn=fn}
  function o:Cancel()self.cancelled=true end
  timers[#timers+1]=o;return o
 end
 local questie={db={char={complete={}}},DEBUG_DEVELOP=1}
 function questie:Debug()end
 function questie:Error(_,e)errors[#errors+1]=tostring(e)end
 local db={autoBlacklist={}}
 local player={currentQuestlog={}}
 local map={_mapDrawQueue={},_minimapDrawQueue={}}
 local tracker={Update=function()end}
 local module={_isResetting=nil,_resetAgain=nil,_resetNeedsAvailables=false}
 local stepEnv={QuestieQuest=module,Questie=questie,
  QuestieDBMIntegration={ClearAll=function()end},
  QuestLogCache={TestGameCache=function()return true end},
  QuestieMap=map,QuestieMenu={OnLogin=function()end},
  QuestiePlayer=player,QuestieDB=db,
  QuestieProfessions={Update=function()end},
  QuestieReputation={Update=function()end},
  QuestieCombatQueue={Queue=function(_,fn)fn()end},
  C_Timer={NewTicker=newTicker,After=function(_,fn)fn()end},
  QuestieTracker=tracker,
  GetQuestsCompleted=function()return {}end,
  next=next}
 function module:ClearAllNotes()end
 function module:ClearAllToolTips()end
 function module:GetAllQuestIdsNoObjectives()end
 function module:UpdateQuest()end
 setmetatable(stepEnv,{__index=_G})
 local libEnv={QuestieLoader={CreateModule=function()return {}end},
  QuestieCompat={C_Timer={NewTicker=newTicker}},Questie=questie}
 setmetatable(libEnv,{__index=_G})
 compile(t,libEnv,"=original_threadlib")
 local thread=libEnv.QuestieLoader:CreateModule()
 -- Retrieve actual created module by adapting CreateModule's return capture.
 return stepEnv,timers,errors,libEnv
end
-- The actual production callback-owner semantics are exercised below using
-- the unmodified ThreadLib source; only its NewTicker implementation is fake.
local function scenario(mode)
 local timers,errors={},{}
 local function ticker(delay,cb)
  local o={cancelled=false,cb=cb,delay=delay}
  function o:Cancel()self.cancelled=true end
  timers[#timers+1]=o;return o
 end
 local threadlib
 local loader={CreateModule=function(_,name)
   assert(name=="ThreadLib");threadlib={};return threadlib end}
 local qenv={QuestieLoader=loader,QuestieCompat={C_Timer={NewTicker=ticker}},
   Questie={Error=function(_,_,err)errors[#errors+1]=tostring(err)end}}
 setmetatable(qenv,{__index=_G})
 compile(t,qenv,"=real_original_threadlib")
 local questie={db={char={complete={}}},DEBUG_DEVELOP=1}
 function questie:Debug()end
 function questie:Error(_,err)errors[#errors+1]=tostring(err)end
 local reset={_resetNeedsAvailables=false}
 function reset:ClearAllNotes()end
 function reset:ClearAllToolTips()end
 function reset:GetAllQuestIdsNoObjectives()end
 function reset:UpdateQuest()end
 local aval={}
 local ownerTicker
 function aval.CalculateAndDrawAll(cb)
  if ownerTicker then ownerTicker:Cancel()end
  local fn=function()if mode=="error" then error("FICTIONAL_CALCULATOR_ERROR")end end
  ownerTicker=threadlib.Thread(fn,0,"original calculator test error",cb)
 end
 local questiePlayer={currentQuestlog={}}
 local env={
  QuestieQuest=reset,Questie=questie,
  QuestieDBMIntegration={ClearAll=function()end},
  QuestLogCache={TestGameCache=function()return true end},
  QuestieMap={_mapDrawQueue={},_minimapDrawQueue={}},
  QuestieMenu={OnLogin=function()end},
  QuestiePlayer=questiePlayer,QuestieDB={autoBlacklist={}},
  QuestieProfessions={Update=function()end},
  QuestieReputation={Update=function()end},
  QuestieCombatQueue={Queue=function(_,fn)fn()end},
  QuestieTracker={Update=function()end},
  AvailableQuests=aval,
  C_Timer={NewTicker=ticker,After=function(_,fn)fn()end},
  GetQuestsCompleted=function()return {}end}
 setmetatable(env,{__index=_G})
 compile(body,env,"=exact_original_SmoothReset")
 local function spin(filter,count)
  for _=1,count do
   local snapshot={}
   for k=1,#timers do snapshot[k]=timers[k]end
   for _,o in ipairs(snapshot) do
    if not o.cancelled and (not filter or filter(o)) then o.cb()end
   end
  end
 end
 local function read()return reset._resetNeedsAvailables,reset._isResetting,reset._resetAgain end
 return {begin=function()reset:SmoothReset()end,reset=reset,timers=timers,
  spin=spin,read=read,outer=function()return ownerTicker end,
  supersede=function()aval.CalculateAndDrawAll(nil)end,
  errors=errors}
end
local normal=scenario("normal")
normal.begin();normal.spin(nil,14)
local wait,active=normal.read()
check(wait==false,"S10_NORMAL_COMPLETION_CLEARS_LATCH")
check(active==nil,"S11_NORMAL_ORIGINAL_RESET_FINISHES")
check(normal.outer().cancelled,"S12_NORMAL_CALC_TIMER_CANCELS")
local superseded=scenario("normal")
superseded.begin();superseded.spin(function(o)return o.delay==0.01 end,8)
local old=superseded.outer()
check(old~=nil and not old.cancelled,"S13_RESET_CALCULATOR_SCHEDULED")
local w,x=superseded.read()
check(w==true and x==true,"S14_ORIGINAL_RESET_WAITING")
superseded.supersede()
check(old.cancelled,"S15_ORIGINAL_CALC_CANCELLED_BY_NEW_CALL")
superseded.spin(nil,15)
w,x=superseded.read()
check(w==true and x==true,"S16_REAL_RESET_LATCH_STRANDED_ON_CANCEL")
superseded.reset:SmoothReset()
local _,__,again=superseded.read()
check(again==true,"S17_REENTRY_ONLY_QUEUES_RESET_AGAIN")
superseded.spin(nil,5)
w,x,again=superseded.read()
check(w and x and again,"S18_RESET_STILL_WAITING_AFTER_REENTRY")
local failed=scenario("error")
failed.begin()
failed.spin(function(o)return o.delay==0.01 end,8)
failed.spin(nil,15)
w,x=failed.read()
check(w==true and x==true,"S19_CALC_ERROR_DROPS_ORIGINAL_COMPLETION_CALLBACK")
check(#failed.errors>0 and failed.outer().cancelled,"S20_ORIGINAL_ERROR_HANDLER_CANCELLED_TIMER")
-- Fictional model ONLY: no production code/contract established.
local hypothetical={epoch=1,completed=false,aborted=false}
local ticket=hypothetical.epoch
hypothetical.epoch=2
if ticket~=hypothetical.epoch then hypothetical.aborted=true end
check(hypothetical.aborted and not hypothetical.completed,"S21_MODEL_ABORT_DISTINCT_FROM_READY")
local oldEpoch=hypothetical.epoch
hypothetical.epoch=3
check(oldEpoch~=hypothetical.epoch,"S22_MONOTONIC_OWNER_EPOCH")
assert(n==22,"SMOOTHRESET_TEST_COUNT_CHANGED:"..n)
print("PUBLIC G08 PART44 SMOOTHRESET CALLBACK SOURCE: 22/22 PASS")
print("PUBLIC G08 REAL ORIGINAL: unchanged ThreadLib module and exact unmodified QuestieQuest.SmoothReset function execute with fictional timer, calculation and game host.")
print("PUBLIC G08 MODEL WITNESS: synthetic supersession and calculator error can strand original reset completion latch; no 3.3.5a native timing or client reproduction.")
print("PUBLIC G08 NO AUTHORIZATION: model abort distinction is NOT a production fix; no saved variables, real addon install, networking, build, ZIP, merge, tag or release.")
