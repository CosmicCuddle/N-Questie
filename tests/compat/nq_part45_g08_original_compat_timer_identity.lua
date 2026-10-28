-- TEST-ONLY: original Compat ticker fragment + complete ThreadLib; fake frame host.
local root=assert(os.getenv("NQ_G08_ORIGINAL_COMPAT_ROOT"),"PINNED_SOURCE_REQUIRED")
local function read(p)
 local f=assert(io.open(root.."/"..p,"rb"));local s=assert(f:read("*a"));f:close();return s
end
local cs,ts=read("Compat/Compat.lua"),read("Modules/Libs/ThreadLib.lua")
local i=assert(cs:find("local activeTimers = {}",1,true))
local j=assert(cs:find("\nlocal mapIdToUiMapId = {}",i+1,true))
local originalTimer=cs:sub(i,j-1)
local n=0
local function check(p,name)assert(p,name);n=n+1 end
check(originalTimer:find("if id == self.id then",1,true),"R01_GUARD_PRESENT")
check(originalTimer:find("inactiveTimers[timer] = true",1,true),"R02_POOL_PRESENT")
check(originalTimer:find("if duration < 0.01 then",1,true),"R03_MIN_DURATION")
check(ts:find("timer:Cancel();",1,true),"R04_THREAD_CANCEL_SOURCE")
local groups={}
local frame={}
function frame:CreateAnimationGroup()
 local g={playing=false}
 function g:CreateAnimation()
  local a={parent=self}
  function a:SetScript(k,f)assert(k=="OnFinished");self.onFinished=f end
  function a:SetDuration(d)self.duration=d end
  function a:GetParent()return self.parent end
  self.animation=a;return a
 end
 function g:SetLooping(v)self.loop=v end
 function g:Play()self.playing=true end
 function g:Stop()self.playing=false end
 function g:Fire()
  if self.playing then self.animation.onFinished(self.animation) end
 end
 groups[#groups+1]=g;return g
end
local function tick()
 local copy={};for i=1,#groups do copy[i]=groups[i] end
 for _,g in ipairs(copy) do g:Fire() end
end
local errors={}
local compat={frame=frame}
local lib
local loader={CreateModule=function(_,name)
 assert(name=="ThreadLib");lib={};return lib
end}
local env={QuestieCompat=compat,QuestieLoader=loader,
 Questie={Error=function(_,message,detail)
  errors[#errors+1]=tostring(message)..":"..tostring(detail)
 end}}
setmetatable(env,{__index=_G})
local function execute(s,name)
 local fn
 if _VERSION=="Lua 5.1" then fn=assert(loadstring(s,name));setfenv(fn,env)
 else fn=assert(load(s,name,"t",env)) end
 fn()
end
execute(originalTimer,"=original_335_Compat_timer_fragment")
execute(ts,"=complete_original_335_ThreadLib")
check(type(compat.C_Timer.NewTicker)=="function","R05_COMPAT_LOADED")
check(type(lib.Thread)=="function","R06_THREADLIB_LOADED")
local finished=0
local normal=lib.Thread(function()end,0,"normal",function()finished=finished+1 end)
check(normal~=nil and #groups==1,"R07_TICKER_CREATED")
tick();check(finished==0,"R08_NOT_EARLY")
tick();check(finished==1,"R09_EXACTLY_ONCE")
tick();check(finished==1 and not groups[1].playing,"R10_STOPPED")
local lost=0
local broken=lib.Thread(function()error("FAKE_ERROR")end,0,"synthetic",function()lost=lost+1 end)
check(broken~=normal and #groups==1,"R11_REUSE_UNIQUE_HANDLE")
tick()
check(lost==0,"R12_ERROR_NO_CALLBACK")
check(#errors==1 and errors[1]:find("FAKE_ERROR",1,true),"R13_ERROR_LOG")
check(not groups[1].playing,"R14_ERROR_CANCELLED")
local cancelled=0
local old=lib.Thread(function()coroutine.yield()end,0,"cancel",function()cancelled=cancelled+1 end)
tick();old:Cancel()
check(not groups[1].playing,"R15_CANCEL_STOPS_GROUP")
local nextCalls=0
local newer=lib.Thread(function()end,0,"new",function()nextCalls=nextCalls+1 end)
check(old~=newer and #groups==1,"R16_UNIQUE_ID_ON_REUSE")
tick();tick()
check(cancelled==0 and nextCalls==1,"R17_CANCEL_LOST_NEW_COMPLETED")
local oldDirect,newDirect,oldCount,newCount=nil,nil,0,0
oldDirect=compat.C_Timer.NewTicker(0,function()
 oldCount=oldCount+1;oldDirect:Cancel()
 newDirect=compat.C_Timer.NewTicker(0.04,function()newCount=newCount+1 end,1)
end,1)
check(groups[1].animation.duration==0.01,"R18_CLAMPED_DURATION")
tick()
check(oldCount==1 and newDirect~=nil,"R19_REENTRANT_REARM")
check(newDirect~=oldDirect and groups[1].playing,"R20_SAME_GROUP_FRESH_ID_LIVE")
oldDirect:Cancel()
check(groups[1].playing,"R21_OLD_HANDLE_CANNOT_CANCEL_REUSED_TIMER")
tick();check(newCount==1,"R22_REUSED_CALLBACK_RUNS")
tick();check(newCount==1 and not groups[1].playing,"R23_NO_DOUBLE_RUN")
local afterCount=0
local after=compat.C_Timer.After(0,function()afterCount=afterCount+1 end)
check(after~=nil and groups[1].animation.duration==0.01,"R24_AFTER_CLAMPED")
tick();tick();check(afterCount==1,"R25_AFTER_ONE_SHOT")
local iters=0
compat.C_Timer.NewTicker(0.03,function()iters=iters+1 end,2)
tick();check(iters==1 and groups[1].playing,"R26_TWO_TICK_FIRST")
tick();check(iters==2 and not groups[1].playing,"R27_TWO_TICK_FINAL")
assert(n==27,"SOURCE_CHECK_CENSUS_CHANGED:"..n)
print("PUBLIC G08 PART45 ORIGINAL COMPAT TIMER: 27/27 PASS")
print("PUBLIC G08 REAL SOURCE: unmodified original Compat timer FRAGMENT and entire unmodified ThreadLib; invented frame host.")
print("PUBLIC G08 FINDING: original timer ID guard survives pooled animation reuse; ThreadLib cancels without completion on error/manual cancel.")
print("PUBLIC G08 NOT NATIVE: no real AnimationGroup, WoW 3.3.5a, reset, database, SavedVariables, network, production edits, ZIP, merge, install or release.")
