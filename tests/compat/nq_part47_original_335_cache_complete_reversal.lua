-- TEST ONLY: exact original 335 Compat objective/title adapters and WHOLE
-- unchanged original QuestLogCache under fabricated quest-log values.
-- Completion 1->0 and 1->nil transitions are ARTIFICIAL, not native evidence.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"ORIGINAL_BLOB_MISSING:"..path)
  local s=assert(f:read("*a"));f:close();return s
end
local function slice(source,a,b)
  local x=assert(source:find(a,1,true),"ORIGINAL_START_MISSING:"..a)
  local y=assert(source:find(b,x+#a,true),"ORIGINAL_END_MISSING:"..b)
  return source:sub(x,y-1)
end
local compatSrc=read("Compat/Compat.lua")
local cacheSrc=read("Modules/Quest/QuestLogCache.lua")
local objHelper=slice(compatSrc,"local questObjectivesCache = {}",
  "\nQuestieCompat.C_QuestLog = {")
local objAdapter=slice(compatSrc,"QuestieCompat.C_QuestLog = {",
  "\n-- Can't find anything about this function.")
local haveAdapter=slice(compatSrc,"function QuestieCompat.HaveQuestData(questID)",
  "\n-- https://wowpedia.fandom.com/wiki/API_GetQuestLogTitle?oldid=2214753")
local titleAdapter=slice(compatSrc,
  "function QuestieCompat.GetQuestLogTitle(questLogIndex)",
  "\nlocal MAX_QUEST_LOG_INDEX = 75")
local total=0
local function check(v,n)assert(v,n);total=total+1 end
check(objHelper:find("parseQuestObjective",1,true)~=nil,
  "R01_GENUINE_335_OBJECTIVE_PARSER_SOURCE")
check(objAdapter:find("GetQuestLogLeaderBoard(i, questLogIndex)",1,true)~=nil,
  "R02_GENUINE_335_OBJECTIVE_ADAPTER_SOURCE")
check(titleAdapter:find("if (isComplete == nil) then",1,true)~=nil,
  "R03_GENUINE_335_TITLE_NIL_FALLBACK")
check(cacheSrc:find("newObjectives[objIndex] = oldObj",1,true)~=nil,
  "R04_GENUINE_CACHE_REUSES_SAME_RAW_OBJECTIVE")
check(cacheSrc:find("if isComplete == 1 then",1,true)~=nil,
  "R05_GENUINE_CACHE_FORCES_ON_COMPLETE_ONLY")
local native={active=true,id=2101,name="Synthetic Quest",complete=0,
  rawText="Synthetic Objective: 0/2",finished=false,numObjectives=1}
local sounds={complete=0,progress=0,quest=0}
local lib={TrimObjectiveText=function(text,kind)return text end}
local soundModule={
  PlayObjectiveComplete=function()sounds.complete=sounds.complete+1 end,
  PlayObjectiveProgress=function()sounds.progress=sounds.progress+1 end,
  PlayQuestComplete=function()sounds.quest=sounds.quest+1 end}
local modules={QuestieLib=lib,Sounds=soundModule}
local loader={}
function loader:CreateModule(n)modules[n]=modules[n] or {};return modules[n] end
function loader:ImportModule(n)return assert(modules[n],"MOCK_IMPORT_MISSING:"..n) end
local compat={}
local questie={DEBUG_DEVELOP=1,DEBUG_CRITICAL=2,DEBUG_INFO=3}
function questie:Debug()end
function questie:Warning()end
local env={
  QuestieLoader=loader,QuestieCompat=compat,Questie=questie,
  GetQuestLogTitle=function(i)
    if i~=1 or not native.active then return nil end
    return native.name,15,nil,0,false,false,
      native.complete,false,native.id
  end,
  GetNumQuestLeaderBoards=function(index)
    if index==1 and native.active then return native.numObjectives end
    return 0 -- fake empty end-of-quest-log index; genuine 335 wrapper still queries it.
  end,
  GetQuestLogLeaderBoard=function(i,index)
    assert(i==1 and index==1)
    return native.rawText,"monster",native.finished
  end,
  GetQuestLogRequiredMoney=function()return 0 end,
  GetMoney=function()return 0 end,
  MAX_QUESTLOG_QUESTS=25
}
setmetatable(env,{__index=_G})
local function execute(src,name)
  local fn
  if _VERSION=="Lua 5.1" then fn=assert(loadstring(src,name));setfenv(fn,env)
  else fn=assert(load(src,name,"t",env)) end
  return fn()
end
execute(objHelper.."\n"..objAdapter.."\n"..haveAdapter.."\n"..titleAdapter,
  "=ORIGINAL_335_COMPAT_QUESTLOG_TITLE_OBJECTIVES")
execute(cacheSrc,"@ORIGINAL_335/Modules/Quest/QuestLogCache.lua")
local cache=assert(modules.QuestLogCache)
check(type(cache.CheckForChanges)=="function","R06_WHOLE_ORIGINAL_CACHE_EXECUTED")
check(type(compat.GetQuestLogTitle)=="function","R07_GENUINE_335_TITLE_EXECUTED")
check(type(compat.C_QuestLog.GetQuestObjectives)=="function",
  "R08_GENUINE_335_OBJECTIVE_ADAPTER_EXECUTED")
local function scan()return cache.CheckForChanges({[native.id]=true})end
local missed,delta=scan()
local first=cache.questLog_DO_NOT_MODIFY[native.id]
check(missed==false and delta[native.id] and delta[native.id][1]==1,
  "R09_FIRST_SYNTHETIC_INCOMPLETE_SCAN_CHANGED")
check(first and first.isComplete==0,"R10_INITIAL_INCOMPLETE_STATUS_ZERO")
check(first.objectives[1].numFulfilled==0 and first.objectives[1].numRequired==2
  and first.objectives[1].finished==false,
  "R11_INITIAL_DERIVED_OBJECTIVE_REFLECTS_RAW_ZERO")
check(first.objectives[1].raw_numFulfilled==0
  and first.objectives[1].raw_finished==false,
  "R12_INITIAL_RAW_OBJECTIVE_ZERO")
missed,delta=scan()
check(missed==false and next(delta)==nil,
  "R13_UNCHANGED_INCOMPLETE_OBJECTIVE_NO_DELTA")
native.complete=1 -- FABRICATED completion flag, raw progress remains 0/2.
missed,delta=scan()
local full=cache.questLog_DO_NOT_MODIFY[native.id]
check(missed==false and delta[native.id][1]==1,
  "R14_COMPLETE_METADATA_FORCES_OBJECTIVE_DELTA")
check(full.isComplete==1 and full.objectives[1].finished==true
  and full.objectives[1].numFulfilled==2,
  "R15_ORIGINAL_CACHE_FORCES_DERIVED_FINISHED_ON_COMPLETE")
check(full.objectives[1].raw_numFulfilled==0
  and full.objectives[1].raw_finished==false,
  "R16_FORCED_DERIVED_RETAINS_DIFFERENT_RAW")
check(sounds.quest==1,"R17_QUEST_COMPLETE_SOUND_FROM_ZERO_TO_ONE")
native.complete=0 -- FABRICATED reversal: leaderboard raw remains IDENTICAL.
missed,delta=scan()
local reverted=cache.questLog_DO_NOT_MODIFY[native.id]
check(missed==false and delta[native.id][1]==1,
  "R18_COMPLETE_TO_ZERO_METADATA_DELTA_SEEN")
check(reverted.isComplete==0,"R19_NEW_CACHE_STATUS_IS_INCOMPLETE")
check(reverted.objectives[1]==full.objectives[1],
  "R20_OLD_OBJECTIVE_TABLE_REUSED_BY_RAW_IDENTITY")
check(reverted.objectives[1].numFulfilled==2 and
  reverted.objectives[1].finished==true,
  "R21_FORCED_DERIVED_VALUES_STALE_AFTER_FAKE_REVERSAL")
check(reverted.objectives[1].raw_numFulfilled==0
  and reverted.objectives[1].raw_finished==false,
  "R22_RAW_REMAINS_INCOMPLETE_DESPITE_STALE_DERIVED")
check(sounds.quest==1,"R23_NO_SECOND_QUEST_COMPLETION_SOUND_ON_REVERSAL")
native.rawText="Synthetic Objective: 1/2" -- Fresh raw data now changes.
missed,delta=scan()
local fresh=cache.questLog_DO_NOT_MODIFY[native.id]
check(missed==false and delta[native.id][1]==1,
  "R24_CHANGED_RAW_PROGRESS_REFRESHES_OBJECTIVE")
check(fresh.objectives[1]~=reverted.objectives[1],
  "R25_CHANGED_RAW_REPLACES_FORCED_OBJECTIVE_TABLE")
check(fresh.objectives[1].numFulfilled==1
  and fresh.objectives[1].finished==false
  and fresh.objectives[1].raw_numFulfilled==1,
  "R26_CHANGED_RAW_REFRESHES_DERIVED_PARTIAL_PROGRESS")
native.complete=1
missed,delta=scan()
check(missed==false and delta[native.id][1]==1
  and cache.questLog_DO_NOT_MODIFY[native.id].objectives[1].numFulfilled==2,
  "R27_RECOMPLETE_FORCES_DERIVED_PROGRESS_AGAIN")
native.complete=nil -- FAKE native nil; genuine compat keeps nil for >0 objectives.
missed,delta=scan()
local nilReversal=cache.questLog_DO_NOT_MODIFY[native.id]
check(missed==false and delta[native.id][1]==1 and nilReversal.isComplete==nil,
  "R28_ORIGINAL_335_TITLE_NIL_AFTER_COMPLETE_SEEN")
check(nilReversal.objectives[1].numFulfilled==2
  and nilReversal.objectives[1].raw_numFulfilled==1,
  "R29_FAKE_COMPLETE_TO_NIL_RETURNS_STALE_DERIVED")
native.rawText="Synthetic Objective: 0/2"
missed,delta=scan()
check(missed==false and delta[native.id][1]==1
  and nilReversal.objectives[1].numFulfilled==2,
  "R30_FAKE_NEXT_RAW_CHANGE_REFRESHES_CACHE_SEPARATELY")
local refreshed=cache.questLog_DO_NOT_MODIFY[native.id]
check(refreshed.objectives[1].numFulfilled==0
  and refreshed.objectives[1].finished==false,
  "R31_DERIVED_REFRESHED_ON_RAW_CHANGE_AFTER_NIL")
cache.RemoveQuest(native.id)
check(cache.questLog_DO_NOT_MODIFY[native.id]==nil,
  "R32_GENUINE_CACHE_REMOVE_QUEST_DELETES_ITEM")
native.complete=0
missed,delta=scan()
check(missed==false and delta[native.id][1]==1,
  "R33_FRESH_QUEST_AFTER_REMOVE_REBUILDS_OBJECTIVES")
check(cache.questLog_DO_NOT_MODIFY[native.id].objectives[1].numFulfilled==0,
  "R34_REBUILT_DERIVED_OBJECTIVE_MATCHES_RAW")
check(sounds.complete==0,"R35_NO_OBJECTIVE_COMPLETE_SOUND_FOR_RAW_ZERO")
assert(total==35,"G08_335_COMPLETE_REVERSAL_CENSUS:"..total)
print("PUBLIC G08 PART47 ORIGINAL 335 CACHE COMPLETE REVERSAL: 35/35 PASS")
print("PUBLIC G08 PART47 ORIGINAL: whole unchanged QuestLogCache with original 335 Compat quest-title and objective adapters under fabricated complete 1-to-0/nil raw data.")
print("PUBLIC G08 PART47 NOT NATIVE: synthetic GetQuestLogTitle/GetQuestLogLeaderBoard and progress states; no actual client event, WasComplete or live 1-to-0 transition.")
