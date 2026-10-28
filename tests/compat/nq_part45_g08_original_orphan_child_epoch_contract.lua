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
local function scenario(mode,consumeStaleChild)
  local timers,errors,groups={},{},{}
  local tagReads,drawCalls=0,0
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
  local quest={Id=1,WasComplete=(mode=="wascomplete" or mode=="orphan"),sourceItemId=mode=="missing" and 5 or 0,
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
  function db.GetQuestTagInfo()tagReads=tagReads+1 end
  function db.GetNPC()return nil end
  function db.GetObject()return nil end
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
  -- Observe entry to original full DrawAvailableQuest; no client UI is present.
  local originalDraw=modules.AvailableQuests.DrawAvailableQuest
  modules.AvailableQuests.DrawAvailableQuest=function(...)
    drawCalls=drawCalls+1
    return originalDraw(...)
  end
  local completionCalls=0
  local lastCalculatorTicker=nil
  local originalCalculate=modules.AvailableQuests.CalculateAndDrawAll
  -- Test-side observer tracks only the synchronous parent ticker allocated
  -- by this genuine original call, never unrelated C_Timer.After/child timers.
  modules.AvailableQuests.CalculateAndDrawAll=function(callback)
    local prior=#timers
    local actualCallback=callback
    if callback then
      actualCallback=function(...)
        completionCalls=completionCalls+1
        return callback(...)
      end
    end
    local result=originalCalculate(actualCallback)
    assert(#timers==prior+1,"ORIGINAL_CALC_EXPECTED_ONE_PARENT_TIMER")
    lastCalculatorTicker=timers[#timers]
    return result
  end
  compile(smooth,"=original_335_SmoothReset",env)
  compile(update,"=original_335_UpdateQuest",env)
  reset:SmoothReset()
  local resetTicker=assert(timers[1],"RESET_TICKER_NOT_STARTED")
  for i=1,8 do assert(tick(resetTicker),"RESET_STEP_FAILED:"..i) end
  local before=assert(lastCalculatorTicker,"ORIGINAL_CALCULATOR_NOT_STARTED")
  assert(tick(before),"CALC_FIRST_RESUME_FAILED")
  local child=timers[3]
  local activeBefore=reset._resetNeedsAvailables==true
  assert(tick(resetTicker),"ORIGINAL_UPDATE_QUEST_STEP_FAILED")
  -- A new parent owner is proved only when the ORIGINAL CalculateAndDrawAll
  -- source executes; timer counts also include unrelated one-shot timers.
  local after=lastCalculatorTicker
  for i=1,6 do
    tick(before);if after~=before then tick(after)end
    tick(resetTicker)
  end
  local tagReadsBefore=tagReads
  local staleChildActiveBefore=child and active(child) or false
  if consumeStaleChild then
    assert(staleChildActiveBefore,"STALE_CHILD_NOT_ACTIVE_AFTER_PARENT_CANCEL")
    assert(tick(child),"STALE_CHILD_FIRST_RESUME_MISSING")
    tick(child)
  end
  return {reset=reset,before=before,after=after,child=child,
    tagReadsBefore=tagReadsBefore,tagReadsAfter=tagReads,
    drawCalls=drawCalls,staleChildActiveBefore=staleChildActiveBefore,
    staleChildActiveAfter=child and active(child) or false,
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


-- Additional ORIGINAL-source child witness: the parent has been superseded
-- by UpdateQuest, but its independent original ThreadLib child still resumes.
local orphan=scenario("orphan",true)
check(orphan.after~=orphan.before,"S32_ORPHAN_PARENT_REPLACED")
check(not orphan.active(orphan.before),"S33_ORPHAN_PARENT_CANCELLED")
check(orphan.staleChildActiveBefore,"S34_ORPHAN_CHILD_WAS_ACTIVE")
check(orphan.tagReadsAfter>orphan.tagReadsBefore,"S35_ORPHAN_ORIGINAL_CHILD_READS_TAG_AFTER_CANCEL")
check(orphan.drawCalls>0,"S36_ORPHAN_ORIGINAL_DRAW_FUNCTION_INVOKED")
check(not orphan.staleChildActiveAfter,"S37_ORPHAN_CHILD_FINISHES_ITS_OWN_TIMER")
check(orphan.completionCalls==0 and orphan.reset._resetNeedsAvailables==true,
  "S38_ORPHAN_RESET_CALLBACK_STILL_LOST")
check(#orphan.errors==0,"S39_ORPHAN_NO_FAKE_CLIENT_ERROR")

-- COUNTERFACTUAL DESIGN CONTRACT: model-only proposed cleanup semantics.
-- Nothing below modifies the genuine original addon functions or timers.
local function newLedger()
  local v={serial=0,current=nil,visible=0,counts={COMPLETED=0,ABORTED=0,ERROR=0}}
  function v:terminal(t,status)
    if self.current~=t or t.state~="PENDING" then return false end
    t.state=status
    self.counts[status]=self.counts[status]+1
    return true
  end
  function v:begin(label)
    if self.current and self.current.state=="PENDING" then
      assert(self:terminal(self.current,"ABORTED"))
    end
    self.serial=self.serial+1
    local t={label=label,serial=self.serial,state="PENDING",
      parentFinished=false,outstanding=0}
    self.current=t
    return t
  end
  function v:child(t)
    if self.current~=t or t.state~="PENDING" then return nil end
    t.outstanding=t.outstanding+1
    return {owner=t,serial=t.serial,done=false}
  end
  function v:publish(child)
    local t=child.owner
    if t~=self.current or t.state~="PENDING"
      or child.serial~=self.serial or child.done then return false end
    self.visible=self.visible+1
    return true
  end
  function v:parentDone(t)
    if t~=self.current or t.state~="PENDING" then return false end
    t.parentFinished=true
    if t.outstanding==0 then return self:terminal(t,"COMPLETED") end
    return true
  end
  function v:childDone(child)
    local t=child.owner
    if t~=self.current or t.state~="PENDING"
      or child.serial~=self.serial or child.done then return false end
    child.done=true
    t.outstanding=t.outstanding-1
    if t.outstanding==0 and t.parentFinished then
      assert(self:terminal(t,"COMPLETED"))
    end
    return true
  end
  function v:error(t) return self:terminal(t,"ERROR") end
  return v
end
local v=newLedger()
local a=v:begin("A")
check(a.serial==1 and a.state=="PENDING","M01_START_PENDING")
local aChild=v:child(a)
check(aChild~=nil and a.outstanding==1,"M02_TRACKED_CHILD_OWNERSHIP")
check(v:publish(aChild) and v.visible==1,"M03_ACTIVE_CHILD_WRITES")
check(v:parentDone(a) and a.state=="PENDING","M04_PARENT_DONE_NOT_READY_WITH_CHILD")
check(v.counts.COMPLETED==0,"M05_NO_EARLY_SUCCESS")
check(v:childDone(aChild) and a.state=="COMPLETED","M06_CHILD_FINISH_RELEASES_READY")
check(v.counts.COMPLETED==1,"M07_SINGLE_TERMINAL_COMPLETION")
check(not v:childDone(aChild),"M08_DUPLICATE_CHILD_TERMINAL_BLOCKED")
check(not v:publish(aChild),"M09_COMPLETED_CHILD_CANNOT_WRITE")
check(not v:parentDone(a),"M10_DUPLICATE_PARENT_COMPLETE_BLOCKED")
local doomed=v:begin("A")
local stale=v:child(doomed)
check(doomed.serial==2 and stale.serial==2,"M11_SECOND_GENERATION_ISSUED")
local second=v:begin("B")
check(doomed.state=="ABORTED" and v.counts.ABORTED==1,"M12_NEW_OWNER_ABORTS_OLD")
check(second.state=="PENDING","M13_REPLACEMENT_PENDING")
check(not v:publish(stale),"M14_ABORTED_CHILD_WRITES_REJECTED")
check(not v:childDone(stale),"M15_ABORTED_CHILD_COMPLETION_REJECTED")
check(not v:parentDone(doomed),"M16_ABORTED_PARENT_COMPLETION_REJECTED")
local third=v:begin("A")
check(second.state=="ABORTED" and v.counts.ABORTED==2,"M17_B_ABORTED")
check(third.label==doomed.label and third.serial~=doomed.serial,
  "M18_ABA_LABEL_EQUAL_EPOCH_DIFFERENT")
check(not v:publish(stale),"M19_ABA_STALE_CHILD_REJECTED")
local fresh=v:child(third)
check(fresh and fresh.serial==4 and v:publish(fresh),"M20_FRESH_CHILD_ALLOWED")
check(v:error(third) and third.state=="ERROR","M21_ERROR_TERMINAL")
check(v.counts.ERROR==1,"M22_ERROR_ACCOUNTED_ONCE")
check(not v:publish(fresh),"M23_ERROR_DISALLOWS_CHILD_WRITES")
check(not v:parentDone(third),"M24_ERROR_DISALLOWS_COMPLETION")
check(not v:error(third),"M25_REPEAT_ERROR_IGNORED")
check(v.visible==2,"M26_ONLY_CURRENT_GENERATION_VISIBLE")
local fourth=v:begin("C")
check(v:parentDone(fourth) and fourth.state=="COMPLETED","M27_ZERO_CHILD_NORMAL_COMPLETE")
check(v.counts.COMPLETED==2 and v.counts.ABORTED==2 and v.counts.ERROR==1,
  "M28_EXPLICIT_TERMINAL_STATE_CENSUS")
check(v.serial==5,"M29_MONOTONIC_EPOCH")
check(not v:publish(stale) and not v:publish(fresh),"M30_STALE_GENERATION_STILL_REJECTED")
assert(n==69,"ORPHAN_EPOCH_ASSERTION_CENSUS_CHANGED:"..n)
print("PUBLIC G08 PART45 ORIGINAL ORPHAN CHILD + EPOCH MODEL: 69/69 PASS")
print("PUBLIC G08 CHILD: original ThreadLib-owned child ran after original parent supersession, with fake DB tag read and original DrawAvailableQuest entry.")
print("PUBLIC G08 MODEL: proposed owner ledger distinguishes COMPLETED / ABORTED / ERROR, blocks stale A-B-A writes, and waits for children; model is NOT a production patch.")
print("PUBLIC G08 BOUNDARIES: fake AnimationGroup, invented quest and DB, no native event order, no real character data, no production Lua changes.")
