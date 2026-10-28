-- TEST ONLY / PUBLIC FICTIONAL DATA. Load the WHOLE unmodified original 335 module.
-- Scheduler, QuestieDB query results, tooltip/map sinks and game API are synthetic.
local root=assert(os.getenv("NQ_G08_FULL_AVAILABLE_ROOT"),"SOURCE_ROOT_REQUIRED")
local fp=assert(io.open(root.."/Modules/Quest/AvailableQuests.lua","rb"))
local source=assert(fp:read("*a"));fp:close()
local function compile(s, env)
  local f
  if _VERSION=="Lua 5.1" then
    f=assert(loadstring(s,"@335/Modules/Quest/AvailableQuests.lua"))
    setfenv(f,env)
  else
    f=assert(load(s,"@335/Modules/Quest/AvailableQuests.lua","t",env))
  end
  return f()
end
local n=0
local function check(ok,label) assert(ok,label); n=n+1 end
local function size(t)
  local c=0;for _ in pairs(t) do c=c+1 end;return c
end
local function generation(tag,first)
  local p,rows={},{}
  for i=first,first+51 do
    p[i]=true
    rows[i]={Id=i,requiredLevel=1,IsRepeatable=false,tagInfoWasCached=false,
      Starts={NPC={i}}}
  end
  return {tag=tag,pointers=p,rows=rows}
end
local old,new=generation("OLD",1),generation("NEW",101)
check(source:find("local questData = QuestieDB.QuestPointers or QuestieDB.questData",1,true)~=nil,"F01_ORIGINAL_POINTER_LOCAL")
check(source:find("ThreadLib.Thread(_CalculateAvailableQuests",1,true)~=nil,"F02_ORIGINAL_THREAD_ENTRY")
check(source:find("if questCount > QUESTS_PER_YIELD then",1,true)~=nil,"F03_YIELD_BOUNDARY")
check(source:find("QuestieDB.activeChildQuests = {}",1,true)~=nil,"F04_REAL_CHILD_CACHE_RESET")
check(source:find("availableQuests[questId] = true",1,true)~=nil,"F05_REAL_AVAILABLE_CACHE_MUTATION")
check(source:find("local quest = QuestieDB.GetQuest(questId)",1,true)~=nil,"F06_DEFERRED_GETQUEST")
check(source:find("QuestieTooltips:RegisterQuestStartTooltip",1,true)~=nil,"F07_REAL_TOOLTIP_PATH")
check(source:find("QuestieMap:DrawWorldIcon",1,true)~=nil,"F08_REAL_MAP_PATH")
local function fixture()
  local current=old
  local epoch=1
  local workers,pending,drawn,tooltips,unloaded,tagged={},{},{},{},{},{}
  local allowDoable=true
  local db={QuestPointers=old.pointers,autoBlacklist={},activeChildQuests={}}
  function db.IsRepeatable() return false end
  function db.IsPvPQuest() return false end
  function db.IsDungeonQuest() return false end
  function db.IsRaidQuest() return false end
  function db.IsRuneAndShouldBeHidden() return false end
  function db.IsLevelRequirementsFulfilled() return true end
  function db.IsDoable() return allowDoable end
  function db.IsComplete() return -1 end
  function db.IsActiveEventQuest() return false end
  function db.IsTrivial() return false end
  function db.GetQuest(id) return current.rows[id] end
  function db.GetQuestTagInfo(id) tagged[#tagged+1]=id end
  function db:GetNPC(id)
    if not current.rows[id] then return nil end
    return {id=id,name="Synthetic NPC "..id,spawns={[77]={{0.5,0.5}}}}
  end
  local map={questIdFrames={}}
  function map:DrawWorldIcon(data)
    drawn[#drawn+1]={id=data.Id,gen=current.tag}
    return {}
  end
  function map:UnloadQuestFrames(id) unloaded[#unloaded+1]=id end
  function map:GetFramesForQuest() return {} end
  local tips={}
  function tips:RegisterQuestStartTooltip(id) tooltips[#tooltips+1]=id end
  function tips:RemoveQuest() end
  local threadlib={}
  function threadlib.ThreadSimple(fn)
    pending[#pending+1]=fn
  end
  function threadlib.Thread(fn)
    local worker={co=coroutine.create(fn),cancelled=false,ownerEpoch=epoch}
    function worker:Cancel() self.cancelled=true end
    workers[#workers+1]=worker
    return worker
  end
  local modules={
    ThreadLib=threadlib,QuestieDB=db,ZoneDB={GetDungeons=function()return {} end},
    QuestiePlayer={GetPlayerLevel=function()return 40 end,currentQuestlog={}},
    QuestieMap=map,QuestieTooltips=tips,
    QuestieCorrections={hiddenQuests={}},
    QuestieQuestBlacklist={AQWarEffortQuests={}},
    IsleOfQuelDanas={quests={}},QuestieLib={GetSpawnDistance=function()return 100 end}
  }
  local available={}
  local loader={
    CreateModule=function(_,name) assert(name=="AvailableQuests");return available end,
    ImportModule=function(_,name)
      assert(modules[name],"UNMOCKED_IMPORT:"..tostring(name))
      return modules[name]
    end
  }
  local questie={
    db={profile={debugEnabled=false,lowLevelStyle="default",
      showRepeatableQuests=true,showDungeonQuests=true,showRaidQuests=true,
      showPvPQuests=true,showAQWarEffortQuests=true,availableScale=1.3},
      char={complete={},hidden={}}},
    IsClassic=false,IsSoD=false,ICON_TYPE_AVAILABLE=1,DEBUG_INFO=1
  }
  function questie:Debug() end
  local env={
    QuestieLoader=loader,Questie=questie,GetQuestGreenRange=function()return 10 end,
    coroutine=coroutine,table=table,pairs=pairs,ipairs=ipairs,tostring=tostring
  }
  setmetatable(env,{__index=_G})
  compile(source,env)
  local f={db=db,available=available,workers=workers,drawn=drawn,
    tooltips=tooltips,unloaded=unloaded,tagged=tagged}
  function f.start() available.CalculateAndDrawAll() return workers[#workers] end
  function f.step(worker)
    local ok,err=coroutine.resume(worker.co)
    assert(ok,"ORIGINAL_CALCULATOR_ERROR:"..tostring(err))
  end
  function f.swap(tag)
    current=(tag=="OLD" and old or new)
    db.QuestPointers=current.pointers
    epoch=epoch+1
  end
  function f.epoch() return epoch end
  function f.pending() return #pending end
  function f.dropPending()
    local count=#pending
    for i=#pending,1,-1 do pending[i]=nil end
    return count
  end
  function f.drain(limit)
    local success,errors=0,0
    local nleft=math.min(limit or #pending,#pending)
    for i=1,nleft do
      local callback=table.remove(pending,1)
      local ok=pcall(callback)
      if ok then success=success+1 else errors=errors+1 end
    end
    return success,errors
  end
  function f.advanceIfOwned(worker)
    if worker.cancelled or worker.ownerEpoch~=epoch then return false end
    f.step(worker)
    return true
  end
  function f.setDoable(v) allowDoable=v end
  return f
end
-- Unchanged original CalculateAndDrawAll > full calculator > deferred Draw path.
local a=fixture()
local first=a.start()
check(#a.workers==1 and first.ownerEpoch==1,"F09_ACTUAL_ORIGINAL_ENTRY_CALLED")
a.step(first)
check(coroutine.status(first.co)=="suspended","F10_REAL_CALCULATOR_YIELDED")
check(a.pending()==25,"F11_FULL_CALCULATOR_QUEUED_25")
local ok,errors=a.drain(5)
check(ok==5 and errors==0,"F12_ORIGINAL_DEFERRED_CALLBACK_OLD")
check(#a.drawn==5 and #a.tooltips==5,"F13_REAL_ORIGINAL_MAP_TOOLTIP_PATH_EXECUTED")
check(#a.tagged==5,"F14_ORIGINAL_QUEST_TAG_CACHE_PATH_EXECUTED")
a.swap("NEW")
check(a.db.QuestPointers==new.pointers,"F15_NEW_PUBLIC_QUEST_POINTER_SET")
a.step(first)
check(coroutine.status(first.co)=="suspended","F16_OLD_CALCULATOR_RESUMES_AFTER_SWAP")
check(a.pending()==45,"F17_OLD_CALCULATOR_QUEUES_MORE_WORK")
ok,errors=a.drain(1)
check(ok==0 and errors==1,"F18_OLD_DEFERRED_QUEST_NEW_READER_FAILS")
check(#a.drawn==5 and #a.tooltips==5,"F19_FAILED_DEFERRED_DRAW_DID_NOT_PUBLISH")
a.step(first)
check(coroutine.status(first.co)=="dead","F20_ORIGINAL_CALCULATOR_FINISHES")
check(a.pending()==46,"F21_ORIGINAL_52_TOTAL_QUEUE_MINUS_SIX_DRAINED")
-- Fresh full original calculator with matched NEW data succeeds independent of pairs order.
local b=fixture()
b.swap("NEW")
local fresh=b.start()
b.step(fresh);b.step(fresh);b.step(fresh)
check(coroutine.status(fresh.co)=="dead","F22_FRESH_NEW_CALCULATOR_FINISHED")
check(b.pending()==52,"F23_FRESH_NEW_QUEUED_ALL_52")
ok,errors=b.drain()
check(ok==52 and errors==0,"F24_FRESH_NEW_ORIGINAL_DRAW_ALL")
local newSet={}
for _,ev in ipairs(b.drawn) do
  assert(ev.gen=="NEW" and ev.id>=101 and ev.id<=152 and not newSet[ev.id],
    "NEW_ORIGINAL_DRAW_WRONG_GENERATION")
  newSet[ev.id]=true
end
check(size(newSet)==52,"F25_FRESH_NEW_ORDER_INDEPENDENT_SET")
check(#b.tooltips==52 and #b.tagged==52,"F26_FRESH_NEW_TOOLTIP_TAG_CALLBACKS")
b.setDoable(false)
b.available.UnloadUndoable()
check(#b.unloaded==52,"F27_ACTUAL_PRIVATE_AVAILABLE_CACHE_RETAINS_52")
-- Original timer.Cancel cancels a prior timer but does not, by itself, erase
-- already scheduled ThreadSimple callbacks in this fictional scheduler.
local c=fixture()
local cancelled=c.start();c.step(cancelled)
check(c.pending()==25,"F28_FIRST_TASK_HAS_25_DEFERRED_CHILD_WORK_ITEMS")
local successor=c.start()
check(cancelled.cancelled and successor~=cancelled,"F29_ORIGINAL_TIMER_CANCEL_INVOKED")
check(c.pending()==25,"F30_PENDING_DRAWS_SURVIVE_CANCEL_IN_FICTIONAL_SCHEDULER")
-- A separate hypothetical lease/restart policy, NOT part of the original addon.
local d=fixture()
local stale=d.start();d.step(stale)
local ownerEpoch=stale.ownerEpoch
d.swap("NEW")
check(not d.advanceIfOwned(stale),"F31_MODEL_FENCE_DENIES_STALE_RESUME")
check(d.pending()==25 and coroutine.status(stale.co)=="suspended",
  "F32_FENCE_LEAVES_OLD_TASK_SUSPENDED_WITH_PRIOR_OUTPUT")
check(d.dropPending()==25,"F33_MODEL_DISCARDS_OLD_DEFERRED_DRAWS")
local retry=d.start()
d.step(retry);d.step(retry);d.step(retry)
ok,errors=d.drain()
check(ok==52 and errors==0 and #d.drawn==52,
  "F34_MODEL_NEW_TASK_RECOMPUTES_CLEAN_OUTPUT")
local e=fixture()
local aba=e.start();e.step(aba)
local samePointer=e.db.QuestPointers
e.swap("NEW");e.swap("OLD")
check(e.db.QuestPointers==samePointer and e.epoch()~=aba.ownerEpoch,
  "F35_ABA_SAME_POINTER_DIFFERENT_EPOCH")
check(not e.advanceIfOwned(aba),"F36_MONOTONIC_EPOCH_REJECTS_ABA")
check(ownerEpoch==1,"F37_OLD_TASK_OWNER_SNAPSHOT_RECORDED")
assert(n==37,"FULL_AVAILABLE_CHECK_CENSUS_CHANGED:"..n)
print("PUBLIC G08 PART44 FULL ORIGINAL AVAILABLEQUESTS: 37/37 PASS")
print("PUBLIC G08 AUTHENTIC EXECUTION: unmodified complete original AvailableQuests.lua module and real CalculateAndDrawAll, _CalculateAvailableQuests, deferred DrawAvailableQuest, tooltip/map and UnloadUndoable paths under fictional host.")
print("PUBLIC G08 KNOWN UNSAFE MODEL: OLD suspended original task can queue work after NEW source switch; invented pending scheduler can run an old deferred GetQuest callback with NEW reader and fail.")
print("PUBLIC G08 PROPOSED MODEL ONLY: epoch fence, dropPending, restart and ABA controls are NOT original Questie/ThreadLib behavior.")
print("PUBLIC G08 NOT NATIVE: fictional data, GetQuest, ThreadLib timers, ThreadSimple queue, map/tooltip/game APIs; no actual QuestieComms send, IP client, SavedVariables, stream, original compiler, ZIP, merge, build or install.")
