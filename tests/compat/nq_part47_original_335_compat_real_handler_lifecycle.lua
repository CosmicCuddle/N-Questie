-- TEST ONLY: whole original QuestTurnedIn/QuestRemoved/MarkQuestAsAbandoned
-- and original 335 Compat reward/abandon hook bodies + real 335 C_Timer source,
-- all under fabricated WoW event hooks, quest data and Animation.OnFinished.
-- This is NOT native client testing or evidence of real hook order.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(p)
  local f=assert(io.open(root.."/"..p,"rb"),"ORIGINAL_BLOB_MISSING:"..p)
  local s=assert(f:read("*a"));f:close();return s
end
local function part(src,a,b)
  local x=assert(src:find(a,1,true),"ORIGINAL_START_NOT_FOUND:"..a)
  local y=assert(src:find(b,x+#a,true),"ORIGINAL_END_NOT_FOUND:"..b)
  return src:sub(x,y-1)
end
local handlerSource=read("Modules/Quest/QuestEventHandler.lua")
local compatSource=read("Compat/Compat.lua")
local turnin=part(handlerSource,
  "function _QuestEventHandler:QuestTurnedIn(",
  "\n--- Fires when a quest is removed from the quest log.")
local removed=part(handlerSource,
  "function _QuestEventHandler:QuestRemoved(",
  "\n---@param questId number\nfunction _QuestEventHandler:MarkQuestAsAbandoned(")
local abandoned=part(handlerSource,
  "function _QuestEventHandler:MarkQuestAsAbandoned(",
  "\n---Fires when the quest log changed in any way.")
local compatSystem=part(compatSource,
  "function QuestieCompat:CHAT_MSG_SYSTEM(event, message)",
  "\nfunction QuestieCompat.QuestEventHandler_RegisterEvents()")
local compatRegister=part(compatSource,
  "function QuestieCompat.QuestEventHandler_RegisterEvents()",
  "\nfunction QuestieCompat.QuestieTracker_Initialize(")
local timer=part(compatSource,"local activeTimers = {}",
  "\nlocal mapIdToUiMapId = {}")
local tests=0
local function check(v,s)assert(v,s);tests=tests+1 end
check(turnin:find("QuestLogCache.RemoveQuest(questId)",1,true)~=nil,
  "B01_ORIGINAL_TURNIN_CACHE_REMOVAL")
check(removed:find("C_Timer.NewTicker(1,",1,true)~=nil,
  "B02_ORIGINAL_REMOVAL_DEFERRED_TIMER")
check(abandoned:find("QuestieJourney:AbandonQuest(questId)",1,true)~=nil,
  "B03_ORIGINAL_ABANDON_HANDLER_METHOD")
check(compatSystem:find("_QuestEventHandler:QuestTurnedIn(questId)",1,true)~=nil,
  "B04_ORIGINAL_COMPAT_TURNIN_BRIDGE")
check(compatRegister:find("_QuestEventHandler:QuestRemoved(QuestieCompat.abandonQuestID)",1,true)~=nil,
  "B05_ORIGINAL_COMPAT_CAPTURE_ID_CALL")
check(timer:find("timer:SetScript(\"OnFinished\", timerOnFinished)",1,true)~=nil,
  "B06_ORIGINAL_TIMER_FINISHED_SCRIPT")
local groups={}
local function newGroup()
  local g={playing=false,stops=0}
  function g:CreateAnimation()
    local a={parent=g}
    function a:SetScript(n,fn)
      assert(n=="OnFinished" and type(fn)=="function")
      self.onFinished=fn -- NOT genuine timer.user callback field.
    end
    function a:SetDuration(n)self.duration=n end
    function a:GetParent()return self.parent end
    g.anim=a;return a
  end
  function g:SetLooping(n)assert(n=="REPEAT");self.loop=n end
  function g:Play()self.playing=true end
  function g:Stop()self.playing=false;self.stops=self.stops+1 end
  function g:Fire()
    assert(self.playing and self.anim and type(self.anim.onFinished)=="function")
    self.anim.onFinished(self.anim)
  end
  groups[#groups+1]=g
  return g
end
local frame={events={}}
function frame:RegisterEvent(s)self.events[s]=true end
function frame:UnregisterEvent(s)self.events[s]=nil end
frame.events.QUEST_REMOVED=true
frame.events.QUEST_TURNED_IN=true
frame.events.QUEST_ACCEPTED=true
local compatFrame={events={}}
function compatFrame:RegisterEvent(s)self.events[s]=true end
local actions={}
local function capture(s,id)
  actions[#actions+1]=s..":"..tostring(id)
end
local questLog={}
local states={QUEST_ACCEPTED="QUEST_ACCEPTED",
  QUEST_REMOVED="QUEST_REMOVED",QUEST_ABANDONED="QUEST_ABANDONED",
  QUEST_TURNED_IN="QUEST_TURNED_IN"}
local handler={}
local compat={Is335=true,frame=compatFrame,
  frameTimer={CreateAnimationGroup=function()return newGroup()end}}
function compat.GetQuestIDFromName(n)
  if n=="Synthetic Complete" then return 1001 end
  return nil
end
local selectedQuestID=1002
local fakeGlobals={}
local function fakeHooksecurefunc(name,fn)
  assert(type(name)=="string" and type(fn)=="function")
  fakeGlobals[name]=fn
end
local function fireHook(name,...)assert(fakeGlobals[name],"FAKE_HOOK_MISSING:"..name);return fakeGlobals[name](...) end
local db={QueryQuestSingle=function(id,name)
  assert(name=="parentQuest");return nil
end}
local qlogCache={RemoveQuest=function(id)capture("cache-remove",id)end}
local questieQuest={
  SetObjectivesDirty=function(_,id)capture("objectives-dirty",id)end,
  CompleteQuest=function(_,id)capture("quest-complete",id)end,
  AbandonedQuest=function(_,id)capture("quest-abandon",id)end
}
local questieJourney={
  CompleteQuest=function(_,id)capture("journey-complete",id)end,
  AbandonQuest=function(_,id)capture("journey-abandon",id)end
}
local questieAnnounce={
  CompletedQuest=function(_,id)capture("announce-complete",id)end,
  AbandonedQuest=function(_,id)capture("announce-abandon",id)end
}
local questie={DEBUG_DEVELOP=1,DEBUG_INFO=2,
  db={profile={resetDailyQuests=false}}}
function questie:Debug()end
function questie:SendMessage(topic,id)
  assert(topic=="QC_ID_BROADCAST_QUEST_REMOVE")
  capture("broadcast-remove",id)
end
local env={QuestieCompat=compat,Questie=questie,QuestEventHandler={private=handler},
  PRIVATE=handler,QUEST_LOG_STATES=states,
  questLog=questLog,QuestieDB=db,QuestLogCache=qlogCache,
  QuestieQuest=questieQuest,QuestieJourney=questieJourney,
  QuestieAnnounce=questieAnnounce,
  QuestieQuestEventFrame=frame,hooksecurefunc=fakeHooksecurefunc,
  GetTitleText=function()return "Synthetic Complete" end,
  GetQuestLogSelection=function()return 1 end,
  GetQuestLogTitle=function(index)
    assert(index==1)
    return "Synthetic Abandon",nil,nil,nil,nil,nil,nil,nil,selectedQuestID
  end,
  GetNumQuestLogRewards=function()return 0 end,
  GetQuestLogRewardInfo=function()return nil end,
  GetMaxDailyQuests=function()return 25 end
}
setmetatable(env,{__index=_G})
local function execute(src,name)
  local fn
  if _VERSION=="Lua 5.1" then fn=assert(loadstring(src,name));setfenv(fn,env)
  else fn=assert(load(src,name,"t",env)) end
  return fn()
end
-- timer block requires its own captured frame assignment from QuestieCompat.frame;
-- use the same fake frame for BOTH original timer and compat event registrations.
compat.frame.CreateAnimationGroup=function()return newGroup()end
execute(timer,"=ORIGINAL_335_COMPAT_ANIMATION_TIMER_BLOCK")
local prelude=table.concat({
  "local _QuestEventHandler=PRIVATE",
  "local questLog=questLog",
  "local QUEST_LOG_STATES=QUEST_LOG_STATES",
  "local C_Timer=QuestieCompat.C_Timer",
  "local skipNextUQLCEvent=false",
  "local doFullQuestLogScan=false",
  "local completeQuestCache={}",
  'local QUEST_COMPLETE_MSG=string.gsub("Quest completed: %s","(%%s)","(.+)")',
  'local DAILY_QUESTS_MSG="Dailies (%d+)"'
},"\n").."\n"
execute(prelude..turnin.."\n"..removed.."\n"..abandoned.."\n"
  ..compatSystem.."\n"..compatRegister,
  "=ORIGINAL_335_FULL_PRIVATE_METHODS_AND_COMPAT_HOOKS")
check(type(handler.QuestTurnedIn)=="function"
  and type(handler.QuestRemoved)=="function"
  and type(handler.MarkQuestAsAbandoned)=="function",
  "B07_THREE_GENUINE_PRIVATE_METHODS_INSTALLED")
check(type(compat.QuestEventHandler_RegisterEvents)=="function"
  and type(compat.CHAT_MSG_SYSTEM)=="function",
  "B08_TWO_GENUINE_COMPAT_METHODS_INSTALLED")
compat.QuestEventHandler_RegisterEvents()
check(not frame.events.QUEST_REMOVED and not frame.events.QUEST_TURNED_IN
  and frame.events.QUEST_ACCEPTED,
  "B09_COMPAT_UNREGISTERS_MODERN_EVENT_NAMES")
check(compatFrame.events.CHAT_MSG_SYSTEM and compatFrame.events.QUEST_QUERY_COMPLETE,
  "B10_COMPAT_REGISTERS_SYSTEM_MESSAGE")
check(type(fakeGlobals.GetQuestReward)=="function"
  and type(fakeGlobals.SetAbandonQuest)=="function"
  and type(fakeGlobals.AbandonQuest)=="function",
  "B11_THREE_GENUINE_COMPAT_HOOK_CALLBACKS")
questLog[1001]={state=states.QUEST_ACCEPTED}
fireHook("GetQuestReward",1)
check(#actions==0,"B12_REWARD_HOOK_ONLY_CACHES_ID")
compat:CHAT_MSG_SYSTEM("CHAT_MSG_SYSTEM","Quest completed: Synthetic Complete")
check(questLog[1001]==nil,"B13_GENUINE_PRIVATE_TURNIN_AND_REMOVE_CLEAR_STATE")
check(#groups==0,"B14_COMPLETED_TURNIN_SCHEDULES_NO_ABANDON_TIMER")
check(actions[1]=="cache-remove:1001"
  and actions[2]=="objectives-dirty:1001",
  "B15_REAL_TURNIN_CACHE_AND_OBJECTIVES_DIRTY")
check(actions[3]=="quest-complete:1001"
  and actions[4]=="journey-complete:1001"
  and actions[5]=="announce-complete:1001",
  "B16_REAL_TURNIN_COMPLETION_SINK_ORDER")
check(actions[6]=="broadcast-remove:1001",
  "B17_REMOVAL_BROADCAST_AFTER_TURNIN")
compat:CHAT_MSG_SYSTEM("CHAT_MSG_SYSTEM","Quest completed: Synthetic Complete")
check(#actions==6,"B18_COMPAT_REPEATED_COMPLETION_MESSAGE_IGNORED")
questLog[1002]={state=states.QUEST_ACCEPTED}
fireHook("SetAbandonQuest")
check(compat.abandonQuestID==1002,"B19_CAPTURED_SELECTED_QUEST_ID")
fireHook("AbandonQuest")
check(questLog[1002] and questLog[1002].state==states.QUEST_REMOVED,
  "B20_GENUINE_PRIVATE_REMOVE_STARTS_REMOVED_STATE")
check(#groups==1 and groups[1].playing and groups[1].anim.duration==1,
  "B21_GENUINE_335_ANIMATION_TIMER_SCHEDULED_FOR_ABANDON")
check(actions[7]=="broadcast-remove:1002","B22_ABANDON_REMOVAL_BROADCAST")
check(not actions[8],"B23_ABANDON_SIDE_EFFECTS_WAIT_FOR_ANIMATION")
groups[1]:Fire()
check(questLog[1002]==nil,"B24_TIMER_FIRES_GENUINE_MARK_ABANDONED")
check(actions[8]=="cache-remove:1002"
  and actions[9]=="objectives-dirty:1002",
  "B25_ABANDON_CLEARS_CACHE_AND_OBJECTIVES")
check(actions[10]=="quest-abandon:1002"
  and actions[11]=="journey-abandon:1002"
  and actions[12]=="announce-abandon:1002",
  "B26_ABANDON_TRIPLE_SINK_ORDER")
check(not groups[1].playing and groups[1].stops==1,
  "B27_ONE_SHOT_TIMER_CANCELS_AFTER_ABANDON")
questLog[1002]={state=states.QUEST_ACCEPTED}
compat.abandonQuestID=nil
local before=#actions
local ok,err=pcall(function()fireHook("AbandonQuest")end)
check(not ok and tostring(err):find("table index is nil",1,true)~=nil,
  "B28_MISSING_CAPTURE_FORWARDS_NIL_TO_GENUINE_QUESTREMOVED")
check(questLog[1002].state==states.QUEST_ACCEPTED and #actions==before,
  "B29_SYNTHETIC_NIL_CAPTURE_ERRORS_BEFORE_BROADCAST")
check(#groups==1,"B30_MISSING_CAPTURE_CREATED_NO_TIMER")
check(compat.abandonQuestID==nil,"B31_UNCAPTURED_NIL_NOT_MUTATED")
check(frame.events.QUEST_ACCEPTED and not frame.events.QUEST_REMOVED,
  "B32_335_COMPAT_EVENT_FRAME_REMAINS_REGISTERED_AS_EXPECTED")
assert(tests==32,"335_COMPAT_GENUINE_HANDLER_BRIDGE_CENSUS:"..tests)
print("PUBLIC G08 PART47 ORIGINAL 335 REAL HANDLER HOOK BRIDGE: 32/32 PASS")
print("PUBLIC G08 PART47 ORIGINAL: genuine QuestTurnedIn, QuestRemoved, MarkQuestAsAbandoned, 335 Compat hook and CHAT_MSG_SYSTEM method bodies, original 335 animation timer source.")
print("PUBLIC G08 PART47 NOT NATIVE: invented quest log/reward/abandon hook sequence, fake AnimationGroup and all handler effect sinks; full addon/client not executed.")
