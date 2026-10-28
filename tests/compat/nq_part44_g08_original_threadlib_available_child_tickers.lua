-- PUBLIC-SAFE TEST ONLY. Genuine original ThreadLib + AvailableQuests loaded unchanged.
-- C_Timer.NewTicker, original DB/Questie host and all quest data are fictional.
local root=assert(os.getenv("NQ_G08_ORIGINAL_TICKERS_ROOT"),"PINNED_SOURCE_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"SOURCE_MISSING:"..path)
  local s=assert(f:read("*a"));f:close();return s
end
local tsrc=read("Modules/Libs/ThreadLib.lua")
local asrc=read("Modules/Quest/AvailableQuests.lua")
local function compile(src,path,env)
  local fn
  if _VERSION=="Lua 5.1" then
    fn=assert(loadstring(src,"@335/"..path));setfenv(fn,env)
  else
    fn=assert(load(src,"@335/"..path,"t",env))
  end
  fn()
end
local n=0
local function check(ok,name) assert(ok,name);n=n+1 end
check(tsrc:find("function ThreadLib.Thread(threadFunction, delay, errorMessage, callbackFunction)",1,true)~=nil,"R01_ORIGINAL_THREAD_API")
check(tsrc:find("timer = newTicker(delay or 0, function()",1,true)~=nil,"R02_ORIGINAL_NEW_TICKER")
check(tsrc:find("timer:Cancel();",1,true)~=nil,"R03_ORIGINAL_TICKER_CANCEL")
check(tsrc:find("function ThreadLib.ThreadSimple(threadFunction, delay)",1,true)~=nil,"R04_ORIGINAL_CHILD_SCHEDULER")
check(tsrc:find("return ThreadLib.Thread(threadFunction, delay)",1,true)~=nil,"R05_CHILD_RETURNS_INDEPENDENT_TIMER")
check(asrc:find("timer = ThreadLib.Thread(_CalculateAvailableQuests",1,true)~=nil,"R06_ORIGINAL_OUTER_TIMER")
check(asrc:find("NewThread(function()",1,true)~=nil,"R07_ORIGINAL_CHILD_DRAW_THREAD")
local ticks,errors,lookups,tooltip={}, {},{},{}
local old,new={},{};
for i=1,52 do old[i]=true;new[i+100]=true end
local current="OLD"
local timers={}
local timerAPI={}
function timerAPI.NewTicker(delay,callback)
  local timer={delay=delay,callback=callback,cancelled=false}
  function timer:Cancel()self.cancelled=true end
  ticks[#ticks+1]=timer
  return timer
end
local questie={db={profile={
    debugEnabled=false,lowLevelStyle="default",
    showRepeatableQuests=true,showPvPQuests=true,showDungeonQuests=true,
    showRaidQuests=true,showAQWarEffortQuests=true
  },char={complete={},hidden={}}},IsClassic=false,IsSoD=false,
  DEBUG_INFO=1,ICON_TYPE_AVAILABLE=1}
function questie:Debug()end
function questie:Error(msg,why) errors[#errors+1]=tostring(msg)..":"..tostring(why) end
local db={QuestPointers=old,autoBlacklist={},activeChildQuests={}}
function db.IsRepeatable()return false end
function db.IsPvPQuest()return false end
function db.IsDungeonQuest()return false end
function db.IsRaidQuest()return false end
function db.IsLevelRequirementsFulfilled()return true end
function db.IsDoable()return true end
function db.IsActiveEventQuest()return false end
function db.IsTrivial()return false end
function db.GetQuest(id)
  lookups[#lookups+1]={id=id,generation=current}
  local found=(current=="OLD" and old or new)[id]
  if not found then return nil end
  return{Id=id,Starts={NPC={id}},tagInfoWasCached=false,requiredLevel=1}
end
function db.GetQuestTagInfo()end
function db:GetNPC(id)
  if not (current=="OLD" and old or new)[id] then return nil end
  return{id=id,name="Fake NPC",spawns={}}
end
local tooltips={}
function tooltips:RegisterQuestStartTooltip(id)tooltip[#tooltip+1]=id end
function tooltips:RemoveQuest()end
local map={questIdFrames={}}
function map:UnloadQuestFrames()end
local modules={
  QuestieDB=db,
  ZoneDB={GetDungeons=function()return {} end},
  QuestiePlayer={GetPlayerLevel=function()return 40 end,currentQuestlog={}},
  QuestieMap=map,QuestieTooltips=tooltips,
  QuestieCorrections={hiddenQuests={}},
  QuestieQuestBlacklist={AQWarEffortQuests={}},
  IsleOfQuelDanas={quests={}},
  QuestieLib={}
}
local loader={}
function loader:CreateModule(name)
  local module={}
  modules[name]=module
  return module
end
function loader:ImportModule(name)
  assert(modules[name],"MISSING_MOCK_IMPORT:"..tostring(name))
  return modules[name]
end
local env={Questie=questie,QuestieLoader=loader,QuestieCompat={C_Timer=timerAPI},
  GetQuestGreenRange=function()return 10 end}
setmetatable(env,{__index=_G})
compile(tsrc,"Modules/Libs/ThreadLib.lua",env)
check(type(modules.ThreadLib.Thread)=="function","R08_GENUINE_THREADLIB_LOADED")
check(type(modules.ThreadLib.ThreadSimple)=="function","R09_GENUINE_THREAD_SIMPLE_LOADED")
compile(asrc,"Modules/Quest/AvailableQuests.lua",env)
local available=modules.AvailableQuests
check(type(available.CalculateAndDrawAll)=="function","R10_GENUINE_AVAILABLE_LOADED")
local function tick(timer)
  if timer.cancelled then return false end
  timer.callback()
  return true
end
available.CalculateAndDrawAll()
local outer=ticks[1]
check(#ticks==1 and not outer.cancelled,"R11_ONE_GENUINE_OUTER_TIMER")
check(tick(outer),"R12_REAL_ORIGINAL_COROUTINE_TICK")
check(#ticks==26,"R13_REAL_ORIGINAL_25_CHILD_TIMERS")
for i=2,26 do assert(not ticks[i].cancelled,"CHILD_CANCELLED_TOO_EARLY") end
check(#errors==0 and #lookups==0,"R14_CHILD_CALLBACKS_STILL_DEFERRED")
local child=ticks[2]
check(tick(child),"R15_ORIGINAL_CHILD_THREAD_RUNS_OLD")
check(#lookups==1 and lookups[1].generation=="OLD","R16_ORIGINAL_OLD_GETQUEST_EXECUTED")
check(#tooltip==1 and tooltip[1]>=1 and tooltip[1]<=52,"R17_ORIGINAL_CHILD_TOOLTIP_PATH")
check(tick(child) and child.cancelled,"R18_ORIGINAL_CHILD_TIMER_SELF_CANCEL_ON_DEAD")
current="NEW"
db.QuestPointers=new
available.CalculateAndDrawAll()
local successor=ticks[#ticks]
check(outer.cancelled and successor~=outer,"R19_REAL_ORIGINAL_OUTER_CANCELLED")
check(#ticks==27 and not successor.cancelled,"R20_NEW_REAL_OUTER_TIMER_CREATED")
local pending=ticks[3]
check(not pending.cancelled,"R21_OLD_CHILD_TICKER_UNCANCELLED_AFTER_OUTER_CANCEL")
check(not tick(outer),"R22_CANCELLED_OUTER_CANNOT_RESUME")
check(tick(pending),"R23_OLD_CHILD_EXECUTES_WITH_NEW_DB")
check(#errors==1,"R24_REAL_THREADLIB_CAUGHT_STALE_CHILD_ERROR")
check(pending.cancelled,"R25_REAL_THREADLIB_CANCELS_FAILED_CHILD")
check(lookups[#lookups].generation=="NEW" and lookups[#lookups].id<=52,
  "R26_REAL_ORIGINAL_GETQUEST_MIXED_GENERATION")
check(tick(successor),"R27_NEW_ORIGINAL_OUTER_STARTS_NEW_POINTERS")
check(#ticks==52,"R28_NEW_ORIGINAL_TASK_QUEUES_25_NEW_CHILDREN")
local firstNew=ticks[28]
check(tick(firstNew),"R29_NEW_CHILD_CALLBACK_EXECUTES")
check(#errors==1 and #tooltip==2,"R30_NEW_CHILD_COHERENT_DRAW")
check(lookups[#lookups].id>=101 and lookups[#lookups].id<=152 and
  lookups[#lookups].generation=="NEW","R31_NEW_CHILD_LOOKUP_CORRECT_POINTER_SET")
check(tick(firstNew) and firstNew.cancelled,"R32_NEW_CHILD_CLEAN_COMPLETION")
-- No actual C_Timer implementation was executed: this fabricated scheduler
-- calls genuine timer callback closures and respects ticker.Cancel.
assert(n==32,"ORIGINAL_THREADLIB_TEST_CENSUS_CHANGED:"..n)
print("PUBLIC G08 PART44 ORIGINAL THREADLIB AND AVAILABLEQUESTS: 32/32 PASS")
print("PUBLIC G08 SOURCE EXECUTION: complete unmodified original ThreadLib.lua and AvailableQuests.lua modules; actual original timer/coroutine/child callback code and Questie Error handler path.")
print("PUBLIC G08 SOURCE FINDING: cancelling original outer AvailableQuests timer does not cancel independent previously created ThreadSimple child tickers in this controlled fabricated C_Timer host.")
print("PUBLIC G08 NOT NATIVE: C_Timer.NewTicker, database, quest rows, map/tooltip/Questie globals and source generation switch are simulated; no real client, network, SavedVariables, original compiler, stream, build/ZIP, merge or install.")
