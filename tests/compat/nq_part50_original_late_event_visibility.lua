-- Part50 G08 PUBLIC-SAFE SOURCE EXPERIMENT ONLY.
-- Executes unchanged pinned 335 QuestieEvent:Load and QuestieDB:Initialize
-- with *fictional* event/date/quest IDs and a fake DB handle factory.
-- Not native 3.3.5a/IP, no real event schedule, stream pool or production fix.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"PINNED_SOURCE_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"ORIGINAL_FILE_MISSING:"..path)
  local s=assert(f:read("*a")); f:close(); return s
end
local eSrc=read("Database/Corrections/QuestieEvent.lua")
local dSrc=read("Database/QuestieDB.lua")
local cSrc=read("Database/Corrections/QuestieCorrections.lua")
local function cut(source,startMark,endMark)
  local i=assert(source:find(startMark,1,true),"METHOD_MISSING:"..startMark)
  local j=assert(source:find(endMark,i+#startMark,true),"METHOD_END_MISSING:"..endMark)
  assert(j>i,"METHOD_INVALID_ORDER")
  return source:sub(i,j-1)
end
local eventLoad=cut(eSrc,"function QuestieEvent:Load()",
  "\n---@param dayOfMonth number")
local dbInit=cut(dSrc,"function QuestieDB:Initialize()",
  "\nfunction QuestieDB:GetObject(")
local n=0
local function check(ok,name)
  assert(ok,"G08_PART50_EVENT:"..name)
  n=n+1
end
check(eventLoad:find("QuestieCorrections.hiddenQuests[questId] = nil",1,true)~=nil,
  "GENUINE_EVENT_UNHIDE_WRITER")
check(eventLoad:find("QuestieEvent.eventQuests = nil",1,true)~=nil,
  "GENUINE_EVENT_ONE_SHOT_CLEANUP")
check(eventLoad:find("if Questie.IsClassic then",1,true)~=nil,
  "CLASSIC_BRANCH_SEPARATE_FROM_WOTLK")
check(eSrc:find("QuestieDB.npcDataOverrides[id] = data",1,true)~=nil,
  "CLASSIC_DARKMOON_OVERRIDE_MUTATOR_EXISTS")
check(cSrc:find("C_Timer.After(1, function()",1,true)~=nil and
      cSrc:find("QuestieEvent:Load()",1,true)~=nil and
      cSrc:find("Questie.db.profile.showEventQuests",1,true)~=nil,
  "ORIGINAL_MINIMALINIT_LATE_CALLBACK_GATED")
check(dbInit:find("QuestieCorrectionshiddenQuests = QuestieCorrections.hiddenQuests",1,true)~=nil,
  "ORIGINAL_DBINIT_LOCAL_HIDDEN_TABLE_ALIAS")

local oldHidden={[990001]=true,[990002]=true,[990003]=true,[990004]=true}
local corrections={hiddenQuests=oldHidden, CLASSIC_ONLY=2}
local global={
  npcBin="NPCBIN",npcPtrs="NPCPTR",questBin="QBIN",questPtrs="QPTR",
  objBin="OBJBIN",objPtrs="OBJPTR",itemBin="IBIN",itemPtrs="IPTR",
  dbCompiledOnVersion="OLD_VERSION"
}
local questie={
  IsSoD=false, IsClassic=false, IsTBC=false, IsWotlk=true,
  db={global=global,profile={showEventQuests=true},char={hidden={}}}
}
function questie:Colorize(x) return x end
local compiler={calls={}}
function compiler:BuildSkipMap() return {} end
function compiler:GetDBHandle(bin,ptrs,skip,keys,overrides)
  self.calls[#self.calls+1]={bin=bin,ptrs=ptrs,overrides=overrides}
  local fn=function() return bin end
  return {Query=fn,QuerySingle=fn,pointers={synthetic=true}}
end
local kinds={"npc","quest","object","item"}
local db={}
for _,kind in ipairs(kinds) do
  db[kind.."CompilerTypes"]={}
  db[kind.."CompilerOrder"]={}
  db[kind.."Keys"]={}
  db[kind.."DataOverrides"]={}
end
local privateDB={questCache={},itemCache={},npcCache={},objectCache={},zoneCache={}}
local dbEnv=setmetatable({
  QuestieDB=db,_QuestieDB=privateDB,Questie=questie,
  QuestieCorrections=corrections,QuestieDBCompiler=compiler,
  StaticPopupDialogs={},
  QuestieLib={TableMemoizeFunction=function(_,f)return f end},
  QuestiePlayer={HasRequiredRace=function()return true end,
    HasRequiredClass=function()return true end},
  l10n=function(x)return x end,
  ReloadUI=function()end
},{__index=_G})
local function runChunk(src,env,name)
  local f
  if _VERSION=="Lua 5.1" then
    f=assert(loadstring(src,name));setfenv(f,env)
  else
    f=assert(load(src,name,"t",env))
  end
  return f()
end
runChunk(dbInit,dbEnv,"=unchanged_335_db_initialize")
check(type(db.Initialize)=="function","ORIGINAL_DBINIT_COMPILED")
db:Initialize()
check(#compiler.calls==4,"ORIGINAL_DBINIT_ACQUIRED_FOUR_HANDLE_FIXTURES")
check(dbEnv.QuestieCorrectionshiddenQuests==oldHidden,
  "ORIGINAL_DBINIT_BORROWS_SAME_HIDDEN_TABLE")
check(oldHidden[990001]==true,"EVENT_UNHIDE_NOT_YET_RUN")

local eventObj={
  eventDates={
    ["Invented Event"]={startDate="1/1",endDate="31/12"},
    ["Inactive Event"]={startDate="20/1",endDate="21/1"}
  },
  lunarFestival={["26"]={startDate="20/1",endDate="21/1"}},
  eventDateCorrections={CLASSIC={},TBC={}},
  eventQuests={
    {"Invented Event",990001},
    {"Invented Event",990002,nil,nil,corrections.CLASSIC_ONLY},
    {"Inactive Event",990003}
  },
  activeQuests={}
}
local eventPrivate={eventNamesForQuests={}}
local darkmoonCalls=0
local eventEnv=setmetatable({
  QuestieEvent=eventObj,_QuestieEvent=eventPrivate,
  QuestieCorrections=corrections, Questie=questie,
  date=function(fmt)assert(fmt=="%y");return "26" end,
  strsplit=function(separator,str)
    assert(separator=="/")
    return str:match("^(%d+)/(%d+)$")
  end,
  _WithinDates=function(startDay)
    return startDay==nil or startDay==1
  end,
  _LoadDarkmoonFaire=function() darkmoonCalls=darkmoonCalls+1 end,
  l10n=function(x)return x end,
  print=function()end
},{__index=_G})
runChunk(eventLoad,eventEnv,"=unchanged_335_questie_event_load")
check(type(eventObj.Load)=="function","ORIGINAL_EVENT_LOAD_COMPILED")
eventObj:Load()
check(oldHidden[990001]==nil,"ORIGINAL_LATE_EVENT_UNHIDES_WOTLK_ELIGIBILITY")
check(dbEnv.QuestieCorrectionshiddenQuests==oldHidden and
  dbEnv.QuestieCorrectionshiddenQuests[990001]==nil,
  "DBINIT_TABLE_ALIAS_SEES_IN_PLACE_EVENT_MUTATION")
check(oldHidden[990002]==true,
  "CLASSIC_ONLY_EVENT_DOES_NOT_UNHIDE_IN_WOTLK_FAKE_HOST")
check(oldHidden[990003]==true,
  "INACTIVE_EVENT_DOES_NOT_UNHIDE")
check(eventObj.activeQuests[990001]==true and
  eventObj.activeQuests[990003]==nil,
  "SOURCE_ACTIVE_QUEST_BOOKKEEPING")
check(eventPrivate.eventNamesForQuests[990001]=="Invented Event",
  "SOURCE_EVENT_NAME_LOOKUP")
check(eventObj.eventQuests==nil,"SOURCE_RELEASES_EVENT_QUEST_LIST")
check(darkmoonCalls==0,"WOTLK_PATH_DOES_NOT_CALL_CLASSIC_DARKMOON")
check(#compiler.calls==4 and global.npcBin=="NPCBIN" and
  global.dbCompiledOnVersion=="OLD_VERSION",
  "EVENT_MUTATION_DOES_NOT_RECOMPILE_FOUR_BIN_PAIRS")
check(next(db.npcDataOverrides)==nil,"WOTLK_EXAMPLE_DOES_NOT_WRITE_NPC_OVERRIDES")

-- No actual delayed duplicate callback is observed: synthetic invocation
-- reveals that the one-shot event list is assumed present at first load.
local ok=pcall(function()eventObj:Load()end)
check(not ok,"FABRICATED_SECOND_EVENT_LOAD_AFTER_CLEARED_LIST_THROWS")

-- A hypothetical SECOND MinimalInit replacing the root hiddenQuests table
-- would detach the original QuestieDB.Initialize local alias until reinit.
corrections.hiddenQuests={[990004]=true}
eventObj.eventQuests={{"Invented Event",990004}}
eventObj:Load()
check(corrections.hiddenQuests[990004]==nil,
  "REPLACEMENT_VISIBLE_TO_NEW_EVENT_WRITER")
check(dbEnv.QuestieCorrectionshiddenQuests[990004]==true,
  "OLD_DBINIT_ALIAS_STALE_AFTER_ROOT_REPLACEMENT")
check(dbEnv.QuestieCorrectionshiddenQuests~=corrections.hiddenQuests,
  "REPLACEMENT_IS_NOT_IN_PLACE_MUTATION")
check(#compiler.calls==4,"SIMULATED_REPLACEMENT_WITHOUT_DB_REINITIALIZE")

assert(n==26,"PART50_EVENT_ASSERTION_COUNT:"..n)
print("PUBLIC G08 PART50 ORIGINAL LATE EVENT VISIBILITY: 26/26 PASS")
print("PUBLIC G08 PART50 WOTLK-SHAPED FAKE HOST: original Load mutates the bound hidden-quest table; a hypothetical root replacement detaches the captured reader alias.")
print("PUBLIC G08 PART50 NOT NATIVE: mocked event timing, date, compiled DB handles and APIs; no actual WotLK event bug, Darkmoon writer execution, saved variables or runtime release proof.")
