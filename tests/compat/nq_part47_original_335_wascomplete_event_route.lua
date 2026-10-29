-- TEST ONLY: genuine original 335 Compat questlog adapters, WHOLE QuestLogCache,
-- real QuestieDB.IsComplete, real QuestieQuest Populate/Update/ObjectiveUpdate
-- run against FABRICATED client complete 1 -> nil, fake Blizzard functions.
-- Nothing here demonstrates live-client reachability or player-visible effects.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"ORIGINAL_SOURCE_MISSING:"..path)
  local s=assert(f:read("*a"));f:close();return s
end
local function original(src,a,b)
  local i=assert(src:find(a,1,true),"SOURCE_START_MISSING:"..a)
  local j=assert(src:find(b,i+#a,true),"SOURCE_END_MISSING:"..b)
  return src:sub(i,j-1)
end
local compatSrc=read("Compat/Compat.lua")
local cacheSrc=read("Modules/Quest/QuestLogCache.lua")
local dbSrc=read("Database/QuestieDB.lua")
local questSrc=read("Modules/Quest/QuestieQuest.lua")
local evtSrc=read("Modules/Quest/QuestEventHandler.lua")
local compatFns=table.concat({
 original(compatSrc,"local questObjectivesCache = {}","\nQuestieCompat.C_QuestLog = {"),
 original(compatSrc,"QuestieCompat.C_QuestLog = {","\n-- Can't find anything about this function."),
 original(compatSrc,"function QuestieCompat.HaveQuestData(questID)","\n-- https://wowpedia.fandom.com/wiki/API_GetQuestLogTitle?oldid=2214753"),
 original(compatSrc,"function QuestieCompat.GetQuestLogTitle(questLogIndex)","\nlocal MAX_QUEST_LOG_INDEX = 75")
},"\n")
local dbComplete=original(dbSrc,"function QuestieDB.IsComplete(questId)","\n---@param self Quest")
local questMethods=table.concat({
 original(questSrc,"function QuestieQuest:UpdateQuest(questId)","\n---@param questId number\nfunction QuestieQuest:SetObjectivesDirty"),
 original(questSrc,"function QuestieQuest:SetObjectivesDirty(questId)","\n--Run this if you want to update the entire table"),
 original(questSrc,"function QuestieQuest:PopulateQuestLogInfo(quest)","\n---@param self QuestObjective @quest.Objectives[] entry"),
 original(questSrc,"function _QuestieQuest.ObjectiveUpdate(self)","\n---@param questId number\n---@return table<ObjectiveIndex, QuestLogCacheObjectiveData>|nil"),
 original(questSrc,"function QuestieQuest:GetAllLeaderBoardDetails(questId)","\nfunction QuestieQuest.DrawDailyQuest")
},"\n")
local evtMethods=table.concat({
 original(evtSrc,"function _QuestEventHandler:QuestLogUpdate()",
   "\n--- Fires whenever a quest objective progressed"),
 original(evtSrc,"function _QuestEventHandler:QuestWatchUpdate(questId)",
   "\nlocal _UnitQuestLogChangedCallback = function()"),
 original(evtSrc,"function _QuestEventHandler:UpdateAllQuests()",
   "\nlocal lastTimeQuestRelatedFrameClosedEvent = -1"),
 evtSrc:sub(assert(evtSrc:find("function _QuestEventHandler:OnEvent(event, ...)",1,true)))
} ,"\n")
local count=0
local function check(ok,name)assert(ok,name);count=count+1 end
check(dbComplete:find("questLogEntry.objectives[1] and 0",1,true)~=nil,
  "P01_REAL_DB_CONVERTS_NIL_RAW_TO_ZERO_FOR_OBJECTIVES")
check(questMethods:find("quest.WasComplete = true",1,true)~=nil,
  "P02_REAL_UPDATE_REMEMBERS_COMPLETE")
check(questMethods:find("quest.WasComplete = nil",1,true)~=nil,
  "P03_REAL_UPDATE_CLEARS_WASCOMPLETE")
check(questMethods:find("self.Completed = (self.Needed == self.Collected",1,true)~=nil,
  "P04_REAL_OBJECTIVE_UPDATE_READS_NORMALIZED_CACHE")
check(cacheSrc:find("newObjectives[objIndex] = oldObj",1,true)~=nil,
  "P05_REAL_CACHE_REUSES_OBJECTIVE_IF_RAW_IDENTICAL")
local native={id=2101,title="Fake WasComplete Quest",complete=1,
  description="Fake Objective: 0/2",finished=false}
local effects={finisher=0,unload=0,tooltips=0,populate=0,notes=0,
  broadcast=0,announced=0,sourceChecks=0,calculated=0}
local lib={TrimObjectiveText=function(t,k)return t end}
local sounds={PlayObjectiveComplete=function()end,
  PlayObjectiveProgress=function()end,PlayQuestComplete=function()end}
local modules={QuestieLib=lib,Sounds=sounds}
local loader={}
function loader:CreateModule(n)
  modules[n]=modules[n] or {}
  return modules[n]
end
function loader:ImportModule(n)return assert(modules[n],n)end
local compat,db,quest,private={},{},{},{}
local questObject={Id=native.id,Objectives={},ObjectiveData={[1]={
  Id=1901,Coordinates={}}},SpecialObjectives={},sourceItemId=0,
  Finisher={},Name=native.title}
function questObject:IsComplete()return db.IsComplete(self.Id)end
function db.GetQuest(qid)if qid==native.id then return questObject end end
function quest:ShouldShowQuestNotes(qid)return false end
function quest:PopulateObjectiveNotes(q)effects.notes=effects.notes+1 end
function quest:AddFinisher(q)effects.finisher=effects.finisher+1 end
function quest:CheckQuestSourceItem(qid,repair)
  effects.sourceChecks=effects.sourceChecks+1;return true
end
local announce={}
function announce:ObjectiveChanged(...)effects.announced=effects.announced+1 end
local qmap={}
function qmap:UnloadQuestFrames(qid)effects.unload=effects.unload+1 end
local tips={}
function tips:RemoveQuest(qid)effects.tooltips=effects.tooltips+1 end
local avail={}
function avail.CalculateAndDrawAll()effects.calculated=effects.calculated+1 end
local player={}
local questie={db={char={complete={[native.id]=nil},collapsedQuests={}}},
  DEBUG_DEVELOP=1,DEBUG_INFO=2,DEBUG_CRITICAL=3}
function questie:Debug()end
function questie:Warning()end
function questie:SendMessage(name,id)
  assert(name=="QC_ID_BROADCAST_QUEST_UPDATE" and id==native.id)
  effects.broadcast=effects.broadcast+1
end
local evtHandler={}
local queuedCalls={}
local fakeQueue={Queue=function(self,fn) queuedCalls[#queuedCalls+1]=fn end}
local nameplate={UpdateNameplate=function(self)effects.nameplate=(effects.nameplate or 0)+1 end}
local tracker={Update=function(self)effects.tracker=(effects.tracker or 0)+1 end}
local env={QuestieCompat=compat,QuestieLoader=loader,Questie=questie,
  QuestieQuest=quest,_QuestieQuest=private,QuestieDB=db,
  QuestiePlayer=player,QuestieMap=qmap,QuestieTooltips=tips,
  AvailableQuests=avail,QuestieAnnounce=announce,
  _QuestEventHandler=evtHandler,
  QuestieCombatQueue=fakeQueue,QuestieNameplate=nameplate,QuestieTracker=tracker,
  C_Timer={After=function(delay,fn)assert(delay==1.0);fn()end},
  GetQuestLogTitle=function(i)
    if i~=1 then return nil end
    return native.title,15,nil,0,false,false,native.complete,false,native.id
  end,
  GetNumQuestLeaderBoards=function(i)
    if i==1 then return 1 end
    return 0
  end,
  GetQuestLogLeaderBoard=function(i,logIndex)
    assert(i==1 and logIndex==1)
    return native.description,"monster",native.finished
  end,
  GetQuestLogRequiredMoney=function(i)return 0 end,
  GetMoney=function()return 0 end}
setmetatable(env,{__index=_G})
local function execute(src,name)
  local f
  if _VERSION=="Lua 5.1" then f=assert(loadstring(src,name));setfenv(f,env)
  else f=assert(load(src,name,"t",env)) end
  return f()
end
execute(compatFns,"=ORIGINAL_335_COMPAT_TITLE_OBJECTIVES")
execute(cacheSrc,"@ORIGINAL_335/Modules/Quest/QuestLogCache.lua")
execute(dbComplete,"=ORIGINAL_335_DB_ISCOMPLETE_FULL_BODY")
execute(questMethods,"=ORIGINAL_335_QUEST_UPDATE_POPULATE_OBJECTIVE_FULL_BODIES")
env.questLog={[native.id]={state="QUEST_ACCEPTED"}}
execute(table.concat({
 "local _QuestEventHandler=_QuestEventHandler",
 "local questLog=questLog",
 "local QUEST_LOG_STATES={QUEST_ACCEPTED='QUEST_ACCEPTED'}",
 "local questLogUpdateQueue={}",
 "local _QuestLogUpdateQueue={GetFirst=function() error('FAKE_EVENT_QUEUE_UNEXPECTED') end}",
 "local doFullQuestLogScan=false",
 "local skipNextUQLCEvent=false",
 evtMethods
} ,"\n"),"=ORIGINAL_335_QUEST_LOG_EVENT_METHODS")
local cache=assert(modules.QuestLogCache)
env.QuestLogCache=cache -- genuine DB and QuestieQuest bodies resolve the original module global.
check(type(cache.CheckForChanges)=="function","P06_WHOLE_REAL_CACHE_LOADED")
check(type(db.IsComplete)=="function","P07_REAL_DB_ISCOMPLETE_LOADED")
check(type(quest.UpdateQuest)=="function","P08_REAL_QUEST_UPDATE_LOADED")
check(type(quest.PopulateQuestLogInfo)=="function","P09_REAL_POPULATE_LOADED")
check(type(private.ObjectiveUpdate)=="function","P10_REAL_OBJECTIVE_UPDATE_LOADED")
check(type(quest.GetAllLeaderBoardDetails)=="function",
  "P11_REAL_OBJECTIVE_DETAILS_LOADED")
local function scan()return cache.CheckForChanges({[native.id]=true})end
local miss,change=scan()
local qcache=cache.questLog_DO_NOT_MODIFY[native.id]
check(miss==false and change[native.id][1]==1,
  "P12_FIRST_REAL_CACHE_SCAN_LOADS_FAKE_COMPLETE_QUEST")
check(qcache.isComplete==1 and qcache.objectives[1].numFulfilled==2,
  "P13_REAL_CACHE_FORCES_0_OF_2_TO_NORMALIZED_2_OF_2")
check(qcache.objectives[1].raw_numFulfilled==0 and
  qcache.objectives[1].raw_finished==false,
  "P14_REAL_CACHE_PRESERVES_UNFINISHED_RAW_FIELDS")
check(db.IsComplete(native.id)==1,"P15_REAL_DB_SAYS_COMPLETE_ON_RAW_ONE")
quest:UpdateQuest(native.id)
check(questObject.WasComplete==true,
  "P16_REAL_UPDATE_STORES_WASCOMPLETE_TRUE")
check(questObject.Objectives[1] and questObject.Objectives[1].Completed==true,
  "P17_REAL_POPULATE_OBJECTIVE_READS_FORCED_NORMALIZED_FULL")
check(questObject.Objectives[1].Collected==2 and
  questObject.Objectives[1].Needed==2,
  "P18_REAL_OBJECTIVE_UPDATE_SEES_2_OF_2")
check(effects.finisher==1,
  "P19_FIRST_REAL_UPDATE_CALLS_FAKE_FINISHER_ONCE")
native.complete=nil -- the invented client-level 1->nil, NOT native proof.
miss,change=scan()
local after=cache.questLog_DO_NOT_MODIFY[native.id]
check(miss==false and change[native.id][1]==1 and after.isComplete==nil,
  "P20_REAL_CACHE_METADATA_TRANSITIONS_ONE_TO_NIL")
check(after.objectives[1]==qcache.objectives[1] and
  after.objectives[1].raw_numFulfilled==0,
  "P21_REAL_CACHE_REUSES_IDENTICAL_RAW_OBJECTIVE")
check(after.objectives[1].numFulfilled==2 and
  after.objectives[1].finished==true,
  "P22_REAL_CACHE_RETAINS_FORCED_NORMALIZED_COMPLETE")
check(db.IsComplete(native.id)==0,
  "P23_REAL_DB_MAPS_RAW_NIL_WITH_OBJECTIVE_TO_ADDON_ZERO")
local prior=questObject.Objectives
quest:UpdateQuest(native.id)
check(questObject.WasComplete==nil and questObject.isComplete==nil,
  "P24_REAL_UPDATE_RESET_BRANCH_CLEARS_FLAGS_ON_INTERNAL_ZERO")
check(questObject.Objectives~=prior and
  questObject.Objectives[1] and questObject.Objectives[1].Completed==true,
  "P25_REAL_RESET_REPOPULATES_FROM_STALE_NORMALIZED_CACHE")
check(questObject.Objectives[1].Collected==2,
  "P26_REAL_OBJECTIVE_REPOPULATION_RETAINS_2_OF_2")
check(effects.calculated==1 and effects.notes==1,
  "P27_REAL_RESET_CALLS_FAKE_MAP_AND_NOTES_SINKS")
check(db.IsComplete(native.id)==0,
  "P28_REAL_DB_STILL_ZERO_AFTER_REPOPULATE")
quest:UpdateQuest(native.id)
check(questObject.WasComplete==true and questObject.isComplete==true,
  "P29_REAL_FALLBACK_BRANCH_REMARKS_COMPLETE_AFTER_RESET")
check(effects.finisher==2,
  "P30_REAL_SECOND_FINISHER_SOURCE_CALL_UNDER_FAKE_OBJECTIVES")
native.description="Fake Objective: 1/2"
miss,change=scan()
check(miss==false and change[native.id][1]==1,
  "P31_RAW_PROGRESS_CHANGE_DETECTED_BY_REAL_CACHE")
check(cache.questLog_DO_NOT_MODIFY[native.id].objectives[1].numFulfilled==1,
  "P32_CHANGED_RAW_RESETS_NORMALIZED_TO_ONE_OF_TWO")
quest:SetObjectivesDirty(native.id)
check(questObject.Objectives[1].isUpdated==false,
  "P33_REAL_OBJECTIVES_DIRTY_METHOD_CLEARS_ISUPDATED")
quest:UpdateQuest(native.id)
check(questObject.WasComplete==nil and questObject.isComplete==nil,
  "P34_REAL_UPDATE_RESETS_FLAGS_ON_NEW_INCOMPLETE_PROGRESS")
check(questObject.Objectives[1].Collected==1 and
  questObject.Objectives[1].Completed==false,
  "P35_REAL_OBJECTIVE_UPDATE_RECOVERS_ONE_OF_TWO")
check(db.IsComplete(native.id)==0,
  "P36_REAL_DB_REMAINS_INCOMPLETE_AFTER_RAW_PROGRESS_CHANGE")
check(cache.questLog_DO_NOT_MODIFY[native.id].objectives[1].raw_numFulfilled==1,
  "P37_RAW_PROGRESS_CORRESPONDS_TO_DERIVED_ONE_OF_TWO")
check(effects.broadcast==4,
  "P38_REAL_UPDATE_BROADCASTS_FOR_EACH_SYNTHETIC_CALL")
check(questObject.Objectives[1].Needed==2,
  "P39_REAL_OBJECTIVE_NEEDED_VALUE_NOT_CORRUPTED")
-- SOURCE-AUTHENTIC DISPATCH: original OnEvent -> QuestWatchUpdate ->
-- QuestLogUpdate -> UpdateAllQuests with fabricated events; NO WoW frame.
check(type(evtHandler.OnEvent)=="function"
  and type(evtHandler.UpdateAllQuests)=="function",
  "E40_ORIGINAL_EVENT_DISPATCH_AND_SCAN_LOADED")
check(type(evtHandler.QuestWatchUpdate)=="function"
  and type(evtHandler.QuestLogUpdate)=="function",
  "E41_ORIGINAL_EVENT_WATCH_AND_LOG_LOADED")
native.complete=1
miss,change=scan()
check(miss==false and change[native.id][1]==1,
  "E42_FAKE_RETURN_TO_COMPLETE_REBUILDS_FORCED_CACHE")
quest:SetObjectivesDirty(native.id)
quest:UpdateQuest(native.id)
check(questObject.WasComplete==true and db.IsComplete(native.id)==1,
  "E43_FIRST_PARTY_UPDATE_STARTS_COMPLETE_BEFORE_FAKE_EVENT")
native.complete=nil
local oldBroad=effects.broadcast
evtHandler:OnEvent("QUEST_LOG_UPDATE")
check(effects.broadcast==oldBroad and
  cache.questLog_DO_NOT_MODIFY[native.id].isComplete==1,
  "E44_QUEST_LOG_UPDATE_ALONE_WITHOUT_WATCH_DOES_NOT_SCAN")
check(#queuedCalls>=1,
  "E45_NON_SCAN_EVENT_ENQUEUES_FAKE_TRACKER_CALLBACK")
evtHandler:OnEvent("QUEST_WATCH_UPDATE",native.id)
evtHandler:OnEvent("QUEST_LOG_UPDATE")
check(cache.questLog_DO_NOT_MODIFY[native.id].isComplete==nil
  and effects.broadcast==oldBroad+1,
  "E46_ORIGINAL_WATCH_THEN_LOG_TRIGGERS_CACHE_SCAN_AND_UPDATE")
check(db.IsComplete(native.id)==0
  and questObject.WasComplete==nil,
  "E47_GENUINE_EVENT_CHAIN_CONVERTS_NIL_TO_ZERO_AND_RESETS")
check(questObject.Objectives[1].Completed==true
  and questObject.Objectives[1].Collected==2,
  "E48_GENUINE_EVENT_UPDATE_REPOPULATES_FORCED_OBJECTIVE")
local beforeNoChange=effects.broadcast
evtHandler:OnEvent("QUEST_WATCH_UPDATE",native.id)
evtHandler:OnEvent("QUEST_LOG_UPDATE")
check(effects.broadcast==beforeNoChange
  and questObject.WasComplete==nil,
  "E49_SAME_RAW_OBJECTIVE_AND_METADATA_DO_NOT_RERUN_UPDATE")
native.title="Fake WasComplete Quest Renamed"
evtHandler:OnEvent("QUEST_WATCH_UPDATE",native.id)
evtHandler:OnEvent("QUEST_LOG_UPDATE")
check(effects.broadcast==beforeNoChange+1,
  "E50_FAKE_TITLE_METADATA_CHANGE_TRIGGERS_ORIGINAL_UPDATE")
check(db.IsComplete(native.id)==0
  and questObject.WasComplete==true and questObject.isComplete==true,
  "E51_ORIGINAL_FALLBACK_RESETS_WASCOMPLETE_TRUE_WHILE_DB_ZERO")
native.description="Fake Objective: 0/2"
evtHandler:OnEvent("QUEST_WATCH_UPDATE",native.id)
evtHandler:OnEvent("QUEST_LOG_UPDATE")
check(cache.questLog_DO_NOT_MODIFY[native.id].objectives[1].numFulfilled==0,
  "E52_FAKE_RAW_CHANGE_RESTORES_NORMALIZED_INCOMPLETE_CACHE")
check(db.IsComplete(native.id)==0
  and questObject.WasComplete==nil and questObject.isComplete==nil,
  "E53_ORIGINAL_EVENT_RESET_CLEARS_WASCOMPLETE_AFTER_RAW_CHANGE")
check(questObject.Objectives[1].Completed==false
  and questObject.Objectives[1].Collected==0,
  "E54_REAL_POPULATED_OBJECTIVE_REFLECTS_FAKE_RAW_ZERO")
check((effects.nameplate or 0)==3,
  "E55_ORIGINAL_UPDATE_ALL_QUESTS_NAMEPLATE_FOR_THREE_DELTAS")
check(effects.broadcast==beforeNoChange+2,
  "E56_GENUINE_SOURCE_EVENT_CHANGED_QUEST_BROADCAST_CENSUS")
check(#queuedCalls>=4,
  "E57_GENUINE_SOURCE_EVENTS_QUEUE_FAKE_TRACKER_WORK")
check(questObject.Objectives[1].Needed==2,
  "E58_OBJECTIVE_NEEDED_REMAINS_TWO_AFTER_EVENT_UPDATES")

assert(count==58,"G08_335_EVENT_WASCOMPLETE_CENSUS:"..count)
print("PUBLIC G08 PART47 ORIGINAL 335 EVENT WASCOMPLETE SOURCE: 58/58 PASS")
print("PUBLIC G08 PART47 ORIGINAL: genuine QuestEventHandler.OnEvent/QuestWatchUpdate/QuestLogUpdate/UpdateAllQuests + QuestLogCache, DB.IsComplete and five QuestieQuest method bodies.")
print("PUBLIC G08 PART47 NOT NATIVE: manually dispatched fake quest events, synthetic complete 1-to-nil, fake tracker/nameplate and raw objective state; no actual client observation.")
