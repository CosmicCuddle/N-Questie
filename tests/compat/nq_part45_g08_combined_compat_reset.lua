-- PUBLIC-SAFE SOURCE-EXECUTION TEST ONLY. Never use real realm or SavedVariables data.
-- Executes unchanged original 335 SmoothReset + UpdateQuest function bodies,
-- complete unchanged ThreadLib + AvailableQuests, under an invented scheduler/DB.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"PINNED_SOURCE_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"MISSING_ORIGINAL:"..path)
  local s=assert(f:read("*a"));f:close();return s
end
local qsrc=read("Modules/Quest/QuestieQuest.lua")
local asrc=read("Modules/Quest/AvailableQuests.lua")
local tsrc=read("Modules/Libs/ThreadLib.lua")
local csrc=read("Compat/Compat.lua")
local compatTimer=extract -- assigned below after source extractor definition
local function extract(src,first,last)
  local i=assert(src:find(first,1,true),"ORIGINAL_START_MISSING:"..first)
  local j=assert(src:find(last,i+#first,true),"ORIGINAL_END_MISSING:"..first)
  return src:sub(i,j-1)
end
local smooth=extract(qsrc,"function QuestieQuest:SmoothReset()",
  "\n---@param questId number\n---@return boolean\nfunction QuestieQuest:ShouldShowQuestNotes")
local update=extract(qsrc,"function QuestieQuest:UpdateQuest(questId)",
  "\n---@param questId number\nfunction QuestieQuest:SetObjectivesDirty")
compatTimer=extract(csrc,"local activeTimers = {}","\nlocal mapIdToUiMapId = {}")
local function compile(src,name,env)
  local f
  if _VERSION=="Lua 5.1" then f=assert(loadstring(src,name));setfenv(f,env)
  else f=assert(load(src,name,"t",env)) end
  f()
end
local n=0
local function check(ok,label)assert(ok,label);n=n+1 end
check(smooth:find("AvailableQuests.CalculateAndDrawAll(function()",1,true)~=nil,"S01_REAL_RESET_CALLBACK")
check(update:find("AvailableQuests.CalculateAndDrawAll()",1,true)~=nil,"S02_REAL_UPDATE_SUPERSEDES")
check(asrc:find("timer:Cancel()",1,true)~=nil,"S03_REAL_AVAILABLE_CANCEL")
check(tsrc:find("if(callbackFunction) then",1,true)~=nil,"S04_REAL_THREAD_CALLBACK")
check(compatTimer:find("if id == self.id then",1,true)~=nil,"S25_REAL_COMPAT_OWNER_GUARD")
local function scenario(mode)
  local timers,errors,groups={},{},{}
  -- Fabricated AnimationGroup objects, but original Compat timer functions.
  local frame={}
  function frame:CreateAnimationGroup()
    local group={playing=false}
    function group:CreateAnimation()
      local animation={parent=self}
      function animation:GetParent()return self.parent end
      function animation:SetDuration(duration)self.duration=duration end
      function animation:SetScript(event,fn)
        assert(event=="OnFinished","UNEXPECTED_ANIMATION_EVENT")
        self.onFinished=fn
      end
      self.animation=animation
      return animation
    end
    function group:SetLooping(mode)self.looping=mode end
    function group:Play()self.playing=true end
    function group:Stop()self.playing=false end
    function group:Fire()
      if not self.playing then return false end
      self.animation.onFinished(self.animation)
      return true
    end
    groups[#groups+1]=group
    return group
  end
  local compat={frame=frame}
  local function ticker(delay,cb,iterations)
    -- The test observer below records all original Compat calls, including
    -- ThreadLib's direct reference; no double-counting in this adapter.
    return compat.C_Timer.NewTicker(delay,cb,iterations)
  end
  local function active(handle)
    for _,group in ipairs(groups) do
      if group.playing and group.animation.id==handle then return true end
    end
    return false
  end
  local function tick(handle)
    if not handle then return false end
    for _,group in ipairs(groups) do
      if group.playing and group.animation.id==handle then
        return group:Fire()
      end
    end
    return false
  end
  local quest={Id=1,WasComplete=mode=="wascomplete",sourceItemId=mode=="missing" and 5 or 0,
    Objectives={},SpecialObjectives={},Starts={NPC={1}}}
  function quest:IsComplete()return 0 end
  local db={QuestPointers={},autoBlacklist={},activeChildQuests={}}
  for i=1,26 do db.QuestPointers[i]=true end
  function db.GetQuest(id)
    if id==1 then return quest end
    if db.QuestPointers[id] then
      return {Id=id,Starts={NPC={id}},tagInfoWasCached=false,requiredLevel=1}
    end
  end
  function db.QueryQuestSingle()return nil end
  function db.IsComplete()return 0 end
  function db.IsRepeatable()return false end
  function db.IsPvPQuest()return false end
  function db.IsDungeonQuest()return false end
  function db.IsRaidQuest()return false end
  function db.IsLevelRequirementsFulfilled()return true end
  function db.IsDoable()
    if mode=="error" then error("SYNTHETIC_ORIGINAL_DB_ERROR") end
    return true
  end
  function db.IsActiveEventQuest()return false end
  function db.IsTrivial()return false end
  local player={currentQuestlog={},GetPlayerLevel=function()return 40 end}
  local map={_mapDrawQueue={},_minimapDrawQueue={},questIdFrames={}}
  function map:UnloadQuestFrames()end
  local tooltips={RemoveQuest=function()end,RegisterQuestStartTooltip=function()end}
  local questie={db={profile={debugEnabled=false,lowLevelStyle="default",
    showRepeatableQuests=true,showPvPQuests=true,showDungeonQuests=true,
    showRaidQuests=true,showAQWarEffortQuests=true},
    char={complete={},hidden={}}},DEBUG_DEVELOP=1,DEBUG_INFO=2,
    ICON_TYPE_AVAILABLE=1,IsClassic=false,IsSoD=false}
  function questie:Debug()end
  function questie:Error(_,why)errors[#errors+1]=tostring(why)end
  function questie:SendMessage()end
  local reset={_resetNeedsAvailables=false}
  function reset:ClearAllNotes()end
  function reset:ClearAllToolTips()end
  function reset:GetAllQuestIdsNoObjectives()player.currentQuestlog[1]=quest end
  function reset:ShouldShowQuestNotes()return true end
  function reset:UpdateObjectiveNotes()end
  function reset:PopulateObjectiveNotes()end
  function reset:PopulateQuestLogInfo()end
  local sourceItemChecks=0
  function reset:CheckQuestSourceItem()
    sourceItemChecks=sourceItemChecks+1
    return mode~="missing"
  end
  local modules={QuestieDB=db,ZoneDB={GetDungeons=function()return {} end},
    QuestiePlayer=player,QuestieMap=map,QuestieTooltips=tooltips,
    QuestieCorrections={hiddenQuests={}},
    QuestieQuestBlacklist={AQWarEffortQuests={}},
    IsleOfQuelDanas={quests={}},QuestieLib={}}
  local loader={}
  function loader:CreateModule(name)
    modules[name]={};return modules[name]
  end
  function loader:ImportModule(name)
    return assert(modules[name],"NO_TEST_MODULE:"..tostring(name))
  end
  local env={QuestieLoader=loader,Questie=questie,QuestieQuest=reset,
    QuestieDB=db,QuestieMap=map,QuestiePlayer=player,QuestieTooltips=tooltips,
    QuestieCompat=compat,
    C_Timer={NewTicker=ticker,After=function(delay,fn) return compat.C_Timer.After(delay,fn) end},
    GetQuestGreenRange=function()return 10 end,
    GetQuestsCompleted=function()return {}end,
    _UpdateSpecials=function()end,
    QuestieDBMIntegration={ClearAll=function()end},
    QuestLogCache={TestGameCache=function()return true end},
    QuestieMenu={OnLogin=function()end},
    QuestieProfessions={Update=function()end},
    QuestieReputation={Update=function()end},
    QuestieCombatQueue={Queue=function(_,f)f()end},
    QuestieTracker={Update=function()end}}
  setmetatable(env,{__index=_G})
  compile(compatTimer,"=original_335_Compat_timer_fragment",env)
  -- Test-only passive observer: genuine ThreadLib imports Compat.NewTicker
  -- directly, bypassing SmoothReset's C_Timer alias. Capture EVERY issued ID.
  local originalNewTicker=compat.C_Timer.NewTicker
  compat.C_Timer.NewTicker=function(delay,callback,iterations)
    local handle=originalNewTicker(delay,callback,iterations)
    timers[#timers+1]=handle
    return handle
  end
  compile(tsrc,"@335/Modules/Libs/ThreadLib.lua",env)
  compile(asrc,"@335/Modules/Quest/AvailableQuests.lua",env)
  env.AvailableQuests=modules.AvailableQuests
  local completionCalls=0
  local originalCalculate=modules.AvailableQuests.CalculateAndDrawAll
  -- Test-side counting observer, forwarding unchanged original production method.
  modules.AvailableQuests.CalculateAndDrawAll=function(callback)
    if not callback then return originalCalculate() end
    return originalCalculate(function(...)
      completionCalls=completionCalls+1
      return callback(...)
    end)
  end
  compile(smooth,"=original_335_SmoothReset",env)
  compile(update,"=original_335_UpdateQuest",env)
  reset:SmoothReset()
  local resetTicker=assert(timers[1],"RESET_TICKER_NOT_STARTED")
  for i=1,8 do assert(tick(resetTicker),"RESET_STEP_FAILED:"..i) end
  local before=assert(timers[2],"ORIGINAL_CALCULATOR_NOT_STARTED")
  assert(tick(before),"CALC_FIRST_RESUME_FAILED")
  local child=timers[3]
  local activeBefore=reset._resetNeedsAvailables==true
  local preUpdateTickerCount=#timers
  assert(tick(resetTicker),"ORIGINAL_UPDATE_QUEST_STEP_FAILED")
  -- The original first calculator already spawned independent child tickers.
  -- Compare the count across UpdateQuest; the final old child is NOT a replacement.
  local after=(#timers>preUpdateTickerCount) and timers[#timers] or before
  for i=1,6 do
    tick(before);if after~=before then tick(after)end
    tick(resetTicker)
  end
  return {reset=reset,before=before,after=after,child=child,
    completionCalls=completionCalls,active=active,
    errors=errors,checks=sourceItemChecks,activeBefore=activeBefore,
    timers=timers,quest=quest}
end
local normal=scenario("normal")
check(normal.activeBefore,"S05_NORMAL_CALC_PENDING")
check(normal.after==normal.before,"S06_NORMAL_NO_SUPERSESSION")
check(not normal.active(normal.before),"S07_NORMAL_CALC_DONE")
check(normal.reset._resetNeedsAvailables==false,"S08_NORMAL_COMPLETION_CALLBACK")
check(normal.reset._isResetting==nil,"S09_NORMAL_RESET_RELEASE")
check(#normal.errors==0,"S10_NORMAL_NO_ERRORS")
local was=scenario("wascomplete")
check(was.activeBefore,"S11_WAS_COMPLETE_RESET_WAITING")
check(was.after~=was.before,"S12_REAL_UPDATE_STARTED_REPLACEMENT")
check(not was.active(was.before),"S13_REAL_UPDATE_CANCELLED_RESET_CALC")
check(was.child~=nil and was.active(was.child),"S14_ORIGINAL_CHILD_SURVIVES_PARENT")
check(was.reset._resetNeedsAvailables==true,"S15_WAS_COMPLETE_CALLBACK_NOT_DELIVERED")
check(was.reset._isResetting==true,"S16_WAS_COMPLETE_RESET_REMAINS_ACTIVE")
check(was.quest.WasComplete==nil,"S17_REAL_UPDATE_CLEARS_QUEST_FLAG")
check(#was.errors==0,"S18_STALL_WITHOUT_THREAD_ERROR")
local missing=scenario("missing")
check(missing.checks>=2,"S19_MISSING_ITEM_BRANCH_CHECKED")
check(missing.after~=missing.before and not missing.active(missing.before),"S20_MISSING_ITEM_CANCELS")
check(missing.reset._resetNeedsAvailables==true,"S21_MISSING_ITEM_LOST_COMPLETION")
check(missing.reset._isResetting==true,"S22_MISSING_ITEM_RESET_LATCH")
-- Model-only rule: matching source name A after B cannot accept an old A ticket.
local epochs={id="A",serial=1}
local old={id=epochs.id,serial=epochs.serial}
epochs.id="B";epochs.serial=epochs.serial+1
epochs.id="A";epochs.serial=epochs.serial+1
check(old.id==epochs.id,"S23_MODEL_ABA_SAME_NAME")
check(old.serial~=epochs.serial,"S24_MODEL_ABA_STALE_OWNER_REJECTED")
check(normal.completionCalls==1,"S26_NORMAL_CALLBACK_EXACTLY_ONCE")
check(was.completionCalls==0,"S27_WASCOMPLETE_CALLBACK_LOST")
check(missing.completionCalls==0,"S28_MISSING_ITEM_CALLBACK_LOST")
local failed=scenario("error")
check(failed.reset._resetNeedsAvailables==true and failed.reset._isResetting==true,
  "S29_ERROR_LATCH_REMAINS")
check(failed.completionCalls==0,"S30_ERROR_NO_COMPLETION")
check(#failed.errors==1 and failed.errors[1]:find("SYNTHETIC_ORIGINAL_DB_ERROR",1,true),
  "S31_ERROR_RECORD_CREATED")
assert(n==31,"COMBINED_COMPAT_ASSERTION_CENSUS_CHANGED:"..n)
print("PUBLIC G08 PART45 COMBINED ORIGINAL COMPAT RESET: 31/31 PASS")
print("PUBLIC G08 SOURCE: original Compat timer fragment, complete ThreadLib and AvailableQuests, unmodified SmoothReset and UpdateQuest functions, fake AnimationGroup and quest DB.")
print("PUBLIC G08 WITNESS: synthetic WasComplete and missing-item supersession, plus synthetic coroutine error, lose completion; original Compat identity guard preserves pooled timer ownership.")
print("PUBLIC G08 LIMITS: genuine Compat timer code but invented AnimationGroup frame engine; no native client, original entire Compat, private data, networking, build, ZIP, release, install or production fix.")
