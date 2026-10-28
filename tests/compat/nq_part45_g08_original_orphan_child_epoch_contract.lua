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
local originalGetQuestLog=extract(qsrc,"function QuestieQuest:GetAllQuestIdsNoObjectives()",
  "\n-- iterate all notes")
local originalCheckSource=extract(qsrc,"function QuestieQuest:CheckQuestSourceItem(questId, makeObjective)",
  "\nlocal function _GetIconScaleForAvailable()")
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
  local tooltipWrites,worldWrites={},{}
  local bagSlotChecks,bagItemChecks,cacheReads=0,0,0
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
  function compat.GetContainerNumSlots(bag)
    bagSlotChecks=bagSlotChecks+1
    return mode=="authpresent" and bag==0 and 1 or 0
  end
  function compat.GetContainerItemInfo(bag,slot)
    bagItemChecks=bagItemChecks+1
    if mode=="authpresent" and bag==0 and slot==1 then
      return nil,nil,nil,nil,nil,nil,nil,nil,nil,5
    end
  end
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
  local quest={Id=1,WasComplete=(mode=="wascomplete" or mode=="orphan" or mode=="orphanwriter"
      or mode=="writererror" or mode=="childerror" or mode=="authwas"),
    sourceItemId=(mode=="missing" or mode=="authmissing" or mode=="authpresent") and 5 or 0,
    Objectives={},SpecialObjectives={},Starts={NPC={1}}}
  function quest:IsComplete()return 0 end
  local db={QuestPointers={},autoBlacklist={},activeChildQuests={}}
  for i=1,26 do db.QuestPointers[i]=true end
  function db.GetQuest(id)
    if id==1 then cacheReads=cacheReads+1;return quest end
    if db.QuestPointers[id] then
      return {Id=id,Starts={NPC={id}},tagInfoWasCached=false,requiredLevel=1}
    end
  end
  function db.GetQuestTagInfo()
    tagReads=tagReads+1
    if mode=="childerror" then error("SYNTHETIC_CHILD_TAG_ERROR") end
  end
  function db.GetNPC(_,id)
    if mode=="orphanwriter" or mode=="writererror" then
      return {id=id,name="SYNTHETIC_SOURCE_NPC",spawns={[12]={{11,22}}}}
    end
    return nil
  end
  function db.GetObject()return nil end
  function db.QueryQuestSingle()return nil end
  function db.QueryItemSingle(itemId,field)
    if itemId==5 and field=="name" then return "SYNTHETIC_SOURCE_ITEM" end
    return nil
  end
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
  function map:DrawWorldIcon(data,zone,x,y)
    if mode=="writererror" then error("SYNTHETIC_MAP_WRITER_ERROR") end
    worldWrites[#worldWrites+1]={id=data.Id,zone=zone,x=x,y=y}
    return {}
  end
  local tooltips={RemoveQuest=function()end}
  function tooltips:RegisterQuestStartTooltip(questId,name,id,key)
    tooltipWrites[#tooltipWrites+1]={questId=questId,name=name,id=id,key=key}
  end
  local questie={db={profile={debugEnabled=false,lowLevelStyle="default",
    showRepeatableQuests=true,showPvPQuests=true,showDungeonQuests=true,
    showRaidQuests=true,showAQWarEffortQuests=true},
    char={complete={},hidden={}}},DEBUG_DEVELOP=1,DEBUG_INFO=2,
    ICON_TYPE_AVAILABLE=1,IsClassic=false,IsSoD=false,
    _sessionWarnings={}}
  function questie:Debug()end
  function questie:Error(_,why)errors[#errors+1]=tostring(why)end
  function questie:SendMessage()end
  local reset={_resetNeedsAvailables=false}
  function reset:ClearAllNotes()end
  function reset:ClearAllToolTips()end
  function reset:GetAllQuestIdsNoObjectives()player.currentQuestlog[1]=quest end
  function reset:GetAllLeaderBoardDetails()return {} end
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
    QuestLogCache={TestGameCache=function()return true end,
      questLog_DO_NOT_MODIFY={[1]={title="SYNTHETIC_CACHE_QUEST"}}},
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
  local authenticHelpers=(mode=="authwas" or mode=="authmissing" or mode=="authpresent")
  if authenticHelpers then
    -- Unchanged original function BODY; its unrelated two source-objective
    -- helpers are mocked to focus on questlog and source-item ownership.
    local fakeHelperLocals="local _AddSourceItemObjective=function()end\n"
      .."local _AddRequiredSourceItemObjective=function()end\n"
    compile(fakeHelperLocals..originalGetQuestLog,
      "=original_335_GetAllQuestIdsNoObjectives_fake_objective_helpers",env)
    compile(originalCheckSource,"=original_335_CheckQuestSourceItem_fake_bags",env)
    local realCheck=reset.CheckQuestSourceItem
    function reset:CheckQuestSourceItem(...)
      sourceItemChecks=sourceItemChecks+1
      return realCheck(self,...)
    end
  end
  reset:SmoothReset()
  local resetTicker=assert(timers[1],"RESET_TICKER_NOT_STARTED")
  for i=1,8 do assert(tick(resetTicker),"RESET_STEP_FAILED:"..i) end
  local before=assert(lastCalculatorTicker,"ORIGINAL_CALCULATOR_NOT_STARTED")
  local logIdentityBefore=(player.currentQuestlog[1]==quest)
  local localizedBefore=quest.LocalizedName
  local wasCompleteBefore=quest.WasComplete
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
  local tooltipWritesBefore,worldWritesBefore=#tooltipWrites,#worldWrites
  local staleChildActiveBefore=child and active(child) or false
  if consumeStaleChild then
    assert(staleChildActiveBefore,"STALE_CHILD_NOT_ACTIVE_AFTER_PARENT_CANCEL")
    assert(tick(child),"STALE_CHILD_FIRST_RESUME_MISSING")
    tick(child)
  end
  return {reset=reset,before=before,after=after,child=child,
    tagReadsBefore=tagReadsBefore,tagReadsAfter=tagReads,
    tooltipWritesBefore=tooltipWritesBefore,worldWritesBefore=worldWritesBefore,
    tooltipWrites=tooltipWrites,worldWrites=worldWrites,drawCalls=drawCalls,staleChildActiveBefore=staleChildActiveBefore,
    staleChildActiveAfter=child and active(child) or false,
    completionCalls=completionCalls,active=active,
    errors=errors,checks=sourceItemChecks,activeBefore=activeBefore,
    authenticHelpers=authenticHelpers,logIdentityBefore=logIdentityBefore,
    localizedBefore=localizedBefore,wasCompleteBefore=wasCompleteBefore,
    cacheReads=cacheReads,bagSlotChecks=bagSlotChecks,
    bagItemChecks=bagItemChecks,
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


-- PART46 REAL-SOURCE WRITER ORDER. These are unchanged original calls
-- reached with fictional NPC data and fake map/tooltip sinks. NOT client writes.
check(asrc:find("QuestieTooltips:RegisterQuestStartTooltip",1,true)~=nil,
  "S40_ORIGINAL_TOOLTIP_CALLSITE")
check(asrc:find("QuestieMap:DrawWorldIcon",1,true)~=nil,
  "S41_ORIGINAL_WORLD_ICON_CALLSITE")
local writer=scenario("orphanwriter",true)
check(writer.after~=writer.before and writer.staleChildActiveBefore,
  "S42_WRITER_CHILD_ORPHANED_BY_ORIGINAL_PARENT")
check(writer.tooltipWritesBefore==0 and writer.worldWritesBefore==0,
  "S43_NO_PRE_CANCEL_WRITER_EVENTS")
check(writer.tagReadsAfter>writer.tagReadsBefore,
  "S44_ORIGINAL_CHILD_TAG_LOOKUP_AFTER_CANCEL")
check(writer.drawCalls>0,"S45_ORIGINAL_DRAW_ENTERED_AFTER_CANCEL")
check(#writer.tooltipWrites==1,"S46_ORIGINAL_TOOLTIP_CALLED")
check(#writer.worldWrites==1,"S47_ORIGINAL_WORLD_ICON_CALLED")
check(writer.tooltipWrites[1].key=="m_"..writer.tooltipWrites[1].id,
  "S48_REAL_STARTER_TOOLTIP_KEY")
check(writer.worldWrites[1].zone==12,"S49_FAKE_ZONE_PROPAGATED")
check(writer.worldWrites[1].x==11 and writer.worldWrites[1].y==22,
  "S50_FAKE_NPC_COORDINATES_PROPAGATED")
check(writer.tooltipWrites[1].questId==writer.worldWrites[1].id,
  "S51_SAME_ORIGINAL_CHILD_QUEST_FOR_BOTH_WRITES")
check(not writer.staleChildActiveAfter,"S52_ORIGINAL_CHILD_STOPPED_AFTER_WRITES")
check(writer.completionCalls==0 and writer.reset._resetNeedsAvailables==true,
  "S53_STALE_WRITES_DID_NOT_RELEASE_RESET_CALLBACK")

-- Controlled invented host error AFTER original tooltip call, BEFORE icon sink.
local writeError=scenario("writererror",true)
check(#writeError.tooltipWrites==1,"S54_TOOLTIP_PRECEDES_MAP_ERROR")
check(#writeError.worldWrites==0,"S55_FAKE_MAP_ERROR_PREVENTS_ICON")
check(#writeError.errors==1 and writeError.errors[1]:find("SYNTHETIC_MAP_WRITER_ERROR",1,true),
  "S56_ORIGINAL_THREADLIB_REPORTS_FAKE_MAP_ERROR")
check(not writeError.staleChildActiveAfter and writeError.reset._resetNeedsAvailables==true,
  "S57_CHILD_ERROR_STOPS_CHILD_NOT_RESET_LATCH")

-- Controlled failure during fake tag lookup, before original DrawAvailableQuest.
local childError=scenario("childerror",true)
check(childError.tagReadsAfter>childError.tagReadsBefore and childError.drawCalls==0,
  "S58_TAG_ERROR_PREVENTS_DRAW")
check(#childError.tooltipWrites==0 and #childError.worldWrites==0,
  "S59_TAG_ERROR_HAS_NO_WRITER_EVENTS")
check(#childError.errors==1 and childError.errors[1]:find("SYNTHETIC_CHILD_TAG_ERROR",1,true),
  "S60_ORIGINAL_THREADLIB_REPORTS_FAKE_TAG_ERROR")
check(not childError.staleChildActiveAfter and childError.reset._resetNeedsAvailables==true,
  "S61_TAG_ERROR_CHILD_TERMINAL_NOT_RESET_SUCCESS")

-- COUNTERFACTUAL MODEL ONLY: a proposed writer adapter vetoes publication
-- based on monotonic owner identity before dispatching to hypothetical sinks.
local function guardedSink(ledger)
  local sink={tooltip={},world={}}
  function sink:write(ticket,kind,payload)
    assert(kind=="tooltip" or kind=="world")
    if not ledger:publish(ticket) then return false end
    self[kind][#self[kind]+1]=payload
    return true
  end
  return sink
end
local w=newLedger()
local first=w:begin("A")
local firstChild=w:child(first)
local sink=guardedSink(w)
check(first.serial==1 and firstChild~=nil,"M31_FIRST_WRITER_OWNER")
check(sink:write(firstChild,"tooltip",{id=7}),"M32_CURRENT_TOOLTIP_ALLOWED")
check(sink:write(firstChild,"world",{id=7}),"M33_CURRENT_ICON_ALLOWED")
check(#sink.tooltip==1 and #sink.world==1,"M34_CURRENT_WRITES_RECORDED")
local middle=w:begin("B")
check(first.state=="ABORTED" and middle.serial==2,"M35_ABORT_ON_SUPERSESSION")
check(not sink:write(firstChild,"tooltip",{id=7}),"M36_ABORTED_TOOLTIP_REJECTED")
check(not sink:write(firstChild,"world",{id=7}),"M37_ABORTED_ICON_REJECTED")
local again=w:begin("A")
check(again.label==first.label and again.serial==3,"M38_NEW_A_EPOCH")
check(not sink:write(firstChild,"world",{id=7}),"M39_OLD_A_STILL_REJECTED")
local freshChild=w:child(again)
check(freshChild~=nil and sink:write(freshChild,"world",{id=8}),
  "M40_NEW_A_ICON_ALLOWED")
check(#sink.world==2 and sink.world[2].id==8,"M41_ONLY_FRESH_ICON_RECORDED")
check(w:error(again) and again.state=="ERROR","M42_CURRENT_ERROR_TERMINAL")
check(not sink:write(freshChild,"tooltip",{id=8})
  and not sink:write(freshChild,"world",{id=8}),"M43_ERROR_WRITES_REJECTED")
check(#sink.tooltip==1 and #sink.world==2,"M44_REJECTED_WRITES_NO_SIDE_EFFECTS")
check(not w:parentDone(again) and not w:childDone(freshChild),
  "M45_ERROR_CANNOT_REPORT_SUCCESS")
assert(n==106,"PART46_WRITER_ASSERTION_CENSUS_CHANGED:"..n)
print("PUBLIC G08 PART46 ORPHAN WRITER AND GUARDED MODEL: 106/106 PASS")
print("PUBLIC G08 PART46 SOURCE: unchanged original tooltip and world-icon call sites reached AFTER original parent cancellation; synthetic NPC and sinks only.")
print("PUBLIC G08 PART46 LIMITS: controlled fake tag/map errors and counterfactual guards, no native UI, gameplay data, SavedVariables or addon patch.")


-- PART46 AUTHENTIC ORIGINAL QUEST-LOG AND ITEM-CHECK FUNCTION BODIES.
-- Original QuestieDB.GetQuest and native 3.3.5 bag APIs are NOT executed.
-- The synthetic GetQuest returns a stable in-memory object; original source
-- functions read it through the same call sites as the original reset.
check(originalGetQuestLog:find("QuestiePlayer.currentQuestlog[questId] = quest",1,true)~=nil,
  "S62_ORIGINAL_LOG_SOURCE_STORES_QUEST_OBJECT")
check(originalCheckSource:find("QuestieCompat.GetContainerItemInfo",1,true)~=nil,
  "S63_ORIGINAL_SOURCE_ITEM_CALLSITE")
local cacheWas=scenario("authwas",false)
check(cacheWas.authenticHelpers and cacheWas.logIdentityBefore,
  "S64_ORIGINAL_LOG_RETAINED_CACHED_OBJECT")
check(cacheWas.localizedBefore=="SYNTHETIC_CACHE_QUEST",
  "S65_ORIGINAL_LOG_STORED_FAKE_TITLE")
check(cacheWas.cacheReads>=2,"S66_ORIGINAL_LOG_AND_UPDATE_REQUEST_SAME_MOCK_QUEST")
check(cacheWas.wasCompleteBefore==true,"S67_PERSISTED_WASCOMPLETE_BEFORE_UPDATE")
check(cacheWas.after~=cacheWas.before and not cacheWas.active(cacheWas.before),
  "S68_AUTHENTIC_LOG_WASCOMPLETE_SUPERSEDES")
check(cacheWas.quest.WasComplete==nil,"S69_AUTHENTIC_UPDATE_CLEARS_WASCOMPLETE")
check(cacheWas.completionCalls==0 and cacheWas.reset._resetNeedsAvailables,
  "S70_CACHED_FLAG_SUPERSESSION_LOST_CALLBACK")

local bagMissing=scenario("authmissing",false)
check(bagMissing.authenticHelpers and bagMissing.logIdentityBefore,
  "S71_ORIGINAL_LOG_SOURCE_ITEM_QUEST_STORED")
check(bagMissing.cacheReads>=3,"S72_ITEM_CHECKS_SAME_MOCK_QUEST")
check(bagMissing.bagSlotChecks>=14 and bagMissing.bagItemChecks==0,
  "S73_FAKE_EMPTY_BAGS_ALL_SCANNED")
check(bagMissing.checks>=2,"S74_ORIGINAL_CHECK_ITEM_TWICE")
check(bagMissing.quest.Objectives[1]~=nil and
  bagMissing.quest.Objectives[1].Id==5 and
  bagMissing.quest.Objectives[1].Description=="SYNTHETIC_SOURCE_ITEM",
  "S75_ORIGINAL_MISSING_ITEM_OBJECTIVE_CREATED")
check(bagMissing.after~=bagMissing.before and not bagMissing.active(bagMissing.before),
  "S76_ORIGINAL_MISSING_ITEM_SUPERSESSION")
check(bagMissing.completionCalls==0 and bagMissing.reset._resetNeedsAvailables,
  "S77_MISSING_ITEM_CALLBACK_STILL_UNRESOLVED")

local bagPresent=scenario("authpresent",false)
check(bagPresent.authenticHelpers and bagPresent.logIdentityBefore,
  "S78_ORIGINAL_LOG_WITH_PRESENT_ITEM")
check(bagPresent.bagSlotChecks>=3 and bagPresent.bagItemChecks==1,
  "S79_FAKE_BAG_RETURNS_PRESENT_SOURCE_ITEM")
check(bagPresent.checks>=1,"S80_ORIGINAL_PRESENT_ITEM_CHECK_CALLED")
check(bagPresent.after==bagPresent.before,"S81_PRESENT_ITEM_NO_SELF_SUPERSESSION")
check(bagPresent.completionCalls==1,"S82_PRESENT_ITEM_NORMAL_CALLBACK")
check(bagPresent.reset._resetNeedsAvailables==false and bagPresent.reset._isResetting==nil,
  "S83_PRESENT_ITEM_NORMAL_RESET_RELEASE")
check(bagPresent.quest.Objectives[1]==nil,"S84_PRESENT_ITEM_NO_FAKE_MISSING_OBJECTIVE")
assert(n==129,"PART46_AUTHENTIC_QUESTLOG_SOURCEITEM_CENSUS_CHANGED:"..n)
print("PUBLIC G08 PART46 AUTHENTIC QUESTLOG AND SOURCE ITEM: 129/129 PASS")
print("PUBLIC G08 PART46 SOURCE FUNCTIONS: original GetAllQuestIdsNoObjectives and CheckQuestSourceItem bodies; fake source-objective helpers, cached quest and bag APIs.")
print("PUBLIC G08 PART46 SOURCE LIMITS: no original whole QuestieDB, actual game bag/questlog cache, native timer timing or production fix.")
