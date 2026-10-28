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
local function extract(src,first,last)
  local i=assert(src:find(first,1,true),"ORIGINAL_START_MISSING:"..first)
  local j=assert(src:find(last,i+#first,true),"ORIGINAL_END_MISSING:"..first)
  return src:sub(i,j-1)
end
local smooth=extract(qsrc,"function QuestieQuest:SmoothReset()",
  "\n---@param questId number\n---@return boolean\nfunction QuestieQuest:ShouldShowQuestNotes")
local update=extract(qsrc,"function QuestieQuest:UpdateQuest(questId)",
  "\n---@param questId number\nfunction QuestieQuest:SetObjectivesDirty")
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
local function scenario(mode)
  local timers,errors={},{}
  local function ticker(delay,cb)
    local t={delay=delay,cb=cb,cancelled=false}
    function t:Cancel()self.cancelled=true end
    timers[#timers+1]=t
    return t
  end
  local function tick(t)
    if not t or t.cancelled then return false end
    t.cb();return true
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
  function db.IsDoable()return true end
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
    QuestieCompat={C_Timer={NewTicker=ticker}},
    C_Timer={NewTicker=ticker,After=function(_,f)f()end},
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
  compile(tsrc,"@335/Modules/Libs/ThreadLib.lua",env)
  compile(asrc,"@335/Modules/Quest/AvailableQuests.lua",env)
  env.AvailableQuests=modules.AvailableQuests
  compile(smooth,"=original_335_SmoothReset",env)
  compile(update,"=original_335_UpdateQuest",env)
  reset:SmoothReset()
  local resetTicker=assert(timers[1],"RESET_TICKER_NOT_STARTED")
  for i=1,8 do assert(tick(resetTicker),"RESET_STEP_FAILED:"..i) end
  local before=assert(timers[2],"ORIGINAL_CALCULATOR_NOT_STARTED")
  assert(tick(before),"CALC_FIRST_RESUME_FAILED")
  local child=timers[3]
  local activeBefore=reset._resetNeedsAvailables==true
  assert(tick(resetTicker),"ORIGINAL_UPDATE_QUEST_STEP_FAILED")
  local after=timers[#timers]
  for i=1,6 do
    tick(before);if after~=before then tick(after)end
    tick(resetTicker)
  end
  return {reset=reset,before=before,after=after,child=child,
    errors=errors,checks=sourceItemChecks,activeBefore=activeBefore,
    timers=timers,quest=quest}
end
local normal=scenario("normal")
check(normal.activeBefore,"S05_NORMAL_CALC_PENDING")
check(normal.after==normal.before,"S06_NORMAL_NO_SUPERSESSION")
check(normal.before.cancelled,"S07_NORMAL_CALC_DONE")
check(normal.reset._resetNeedsAvailables==false,"S08_NORMAL_COMPLETION_CALLBACK")
check(normal.reset._isResetting==nil,"S09_NORMAL_RESET_RELEASE")
check(#normal.errors==0,"S10_NORMAL_NO_ERRORS")
local was=scenario("wascomplete")
check(was.activeBefore,"S11_WAS_COMPLETE_RESET_WAITING")
check(was.after~=was.before,"S12_REAL_UPDATE_STARTED_REPLACEMENT")
check(was.before.cancelled,"S13_REAL_UPDATE_CANCELLED_RESET_CALC")
check(was.child~=nil and not was.child.cancelled,"S14_ORIGINAL_CHILD_SURVIVES_PARENT")
check(was.reset._resetNeedsAvailables==true,"S15_WAS_COMPLETE_CALLBACK_NOT_DELIVERED")
check(was.reset._isResetting==true,"S16_WAS_COMPLETE_RESET_REMAINS_ACTIVE")
check(was.quest.WasComplete==nil,"S17_REAL_UPDATE_CLEARS_QUEST_FLAG")
check(#was.errors==0,"S18_STALL_WITHOUT_THREAD_ERROR")
local missing=scenario("missing")
check(missing.checks>=2,"S19_MISSING_ITEM_BRANCH_CHECKED")
check(missing.after~=missing.before and missing.before.cancelled,"S20_MISSING_ITEM_CANCELS")
check(missing.reset._resetNeedsAvailables==true,"S21_MISSING_ITEM_LOST_COMPLETION")
check(missing.reset._isResetting==true,"S22_MISSING_ITEM_RESET_LATCH")
-- Model-only rule: matching source name A after B cannot accept an old A ticket.
local epochs={id="A",serial=1}
local old={id=epochs.id,serial=epochs.serial}
epochs.id="B";epochs.serial=epochs.serial+1
epochs.id="A";epochs.serial=epochs.serial+1
check(old.id==epochs.id,"S23_MODEL_ABA_SAME_NAME")
check(old.serial~=epochs.serial,"S24_MODEL_ABA_STALE_OWNER_REJECTED")
assert(n==24,"PART45_ASSERTION_CENSUS_MISMATCH:"..n)
print("PUBLIC G08 PART45 ORIGINAL RESET SELF-SUPERSESSION: 24/24 PASS")
print("PUBLIC G08 SOURCE: exact unchanged SmoothReset and UpdateQuest functions plus complete original ThreadLib and AvailableQuests modules, fictional scheduling and DB.")
print("PUBLIC G08 WITNESS: WasComplete and missing-source-item synthetic quest paths supersede the reset calculation, lose its completion callback, and retain the latch.")
print("PUBLIC G08 LIMITS: no original Compat animation clock or native game client; no real data, SavedVariables, network, production fix, build, ZIP, merge, install or release.")
