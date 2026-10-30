-- Part50 G08, TEST ONLY: execute two additional unchanged first-party raw DB
-- writers under INVENTED records. No user/private data, native client or patch.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_SOURCE_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"ORIGINAL_SOURCE_MISSING:"..path)
  local s=assert(f:read("*a"));f:close();return s
end
local questSrc=read("Database/Corrections/classicQuestFixes.lua")
local dbSrc=read("Database/QuestieDB.lua")
local correctionsSrc=read("Database/Corrections/QuestieCorrections.lua")
local startupSrc=read("Modules/QuestieInit.lua")
local function uniqueAt(source,token,label)
  local i=assert(source:find(token,1,true),label.."_MISSING")
  assert(not source:find(token,i+#token,true),label.."_DUPLICATED")
  return i
end
local function method(source,first,last,name)
  local a=uniqueAt(source,first,name.."_START")
  local b=assert(source:find(last,a+#first,true),name.."_END_MISSING")
  assert(b>a,name.."_ORDER")
  return source:sub(a,b-1)
end
local rawMissing=method(questSrc,
  "function QuestieQuestFixes:LoadMissingQuests()",
  "\nfunction QuestieQuestFixes:Load()","MISSING_QUESTS")
local rawGather=method(dbSrc,
  "function _QuestieDB:DeleteGatheringNodes()",
  "\nfunction _QuestieDB:CheckAchievementRequirements(","GATHERING_NODES")
local total=0
local function check(ok,label)
  assert(ok,"PART50_G08_WRITER:"..label)
  total=total+1
end
local function evaluate(src,env,label)
  local chunk
  if _VERSION=="Lua 5.1" then
    chunk=assert(loadstring(src,label))
    setfenv(chunk,env)
  else
    chunk=assert(load(src,label,"t",env))
  end
  return chunk()
end
local originalQuesties={questData={},objectData={},objectKeys={spawns=1}}
local fixes,privateDB={},{}
local env=setmetatable({
  QuestieDB=originalQuesties,
  QuestieQuestFixes=fixes,
  _QuestieDB=privateDB
},{__index=_G})
evaluate(rawMissing.."\n"..rawGather,env,"=unchanged_335_raw_source_writers")
check(type(fixes.LoadMissingQuests)=="function" and
  type(privateDB.DeleteGatheringNodes)=="function",
  "BOTH_AUTHENTIC_ORIGINAL_METHODS_LOADED")

-- These method bodies mutate raw source tables; they are NOT pure readers.
local replacementIds={}
for id in rawMissing:gmatch("%[(%d+)%]%s*=%s*%{%s*%}") do
  replacementIds[#replacementIds+1]=tonumber(id)
end
check(#replacementIds==12,"TWELVE_ORIGINAL_HARDCODED_QUEST_ROWS")
local priorRows={}
for _,id in ipairs(replacementIds) do
  local row={synthetic_marker="sentinel"}
  originalQuesties.questData[id]=row
  priorRows[id]=row
end
local unrelated={synthetic_marker="keep"}
originalQuesties.questData[990001]=unrelated
fixes:LoadMissingQuests()
check(type(originalQuesties.questData[replacementIds[1]])=="table",
  "SOURCE_METHOD_EXECUTED")
local allReset=true
for _,id in ipairs(replacementIds) do
  local newRow=originalQuesties.questData[id]
  if newRow==priorRows[id] or next(newRow)~=nil then allReset=false end
end
check(allReset,"ALL_TWELVE_ROWS_REPLACED_NOT_MERGED")
check(originalQuesties.questData[990001]==unrelated and
  unrelated.synthetic_marker=="keep","UNRELATED_QUEST_UNCHANGED")
local firstReplacement=originalQuesties.questData[replacementIds[1]]
fixes:LoadMissingQuests()
check(originalQuesties.questData[replacementIds[1]]~=firstReplacement,
  "SECOND_LOAD_REPLACES_ROW_IDENTITY_AGAIN")
check(next(originalQuesties.questData[replacementIds[1]])==nil,
  "SECOND_LOAD_STILL_EMPTY_NOT_MERGED")
check(priorRows[replacementIds[1]].synthetic_marker=="sentinel",
  "PREVIOUS_OBJECT_REFERENCE_REMAINS_BUT_NO_LONGER_PUBLISHED")

-- Literal prune list comes from the unchanged original source, not a
-- hand-authored fake list. All source rows here are fabricated.
local literal=assert(rawGather:match("local prune = (%b{})"),
  "ORIGINAL_PRUNE_LIST_MISSING")
local prune=evaluate("return "..literal,env,"=unchanged_335_prune_ids")
check(#prune==24,"ORIGINAL_GATHERING_NODE_LIST_COUNT")
local rowRefs={}
for _,id in ipairs(prune) do
  local row={[1]="invented-spawns",[2]="invented-name"}
  originalQuesties.objectData[id]=row
  rowRefs[id]=row
end
local unrelatedObject={[1]="keep-spawns",[2]="keep-name"}
originalQuesties.objectData[990002]=unrelatedObject
privateDB:DeleteGatheringNodes()
local allNil=true
for _,id in ipairs(prune) do
  local row=originalQuesties.objectData[id]
  if row~=rowRefs[id] or row[1]~=nil or row[2]~="invented-name" then
    allNil=false
  end
end
check(allNil,"ORIGINAL_PRUNE_MUTATES_EXISTING_ROWS_IN_PLACE")
check(originalQuesties.objectData[990002]==unrelatedObject and
  unrelatedObject[1]=="keep-spawns","UNRELATED_OBJECT_SPAWN_UNTOUCHED")
check(originalQuesties.objectData[prune[1]]~=nil,
  "SPAWN_NIL_DOES_NOT_DELETE_OBJECT_ROW")

-- The original method is not nil-row tolerant. This is an invented
-- missing-row counterexample; NOT evidence that real public source lacks it.
originalQuesties.objectData[prune[1]]=nil
local ok=pcall(function()privateDB:DeleteGatheringNodes()end)
check(not ok,"MISSING_PRUNE_ROW_CAN_THROW_UNDER_INVENTED_INPUT")
originalQuesties.objectData[prune[1]]=rowRefs[prune[1]]

-- Source-backed startup sequence: loaders are separated by yields and
-- are not a single atomic snapshot/transaction.
local loadStart=uniqueAt(startupSrc,"local function loadFullDatabase()",
  "ORIGINAL_STARTUP_LOAD_FUNCTION")
local loadEnd=assert(startupSrc:find("\n---Run the validator",loadStart,true),
  "ORIGINAL_STARTUP_LOAD_BOUNDARY")
local startupLoad=startupSrc:sub(loadStart,loadEnd-1)
local a=uniqueAt(startupLoad,"QuestieInit:LoadBaseDB()","STARTUP_BASE_LOAD")
local b=uniqueAt(startupLoad,"QuestieCorrections:Initialize()","STARTUP_CORRECTIONS")
local c=uniqueAt(startupLoad,"QuestieDB.private:DeleteGatheringNodes()","STARTUP_PRUNE")
local d=uniqueAt(startupLoad,"QuestieCorrections:PreCompile()","STARTUP_PRECOMPILE")
check(a<b and b<c and c<d,"ORIGINAL_STARTUP_RAW_WRITER_ORDER")
check(startupLoad:sub(b,c):find("coYield()",1,true)~=nil and
  startupLoad:sub(c,d):find("coYield()",1,true)~=nil,
  "STARTUP_WRITER_OPERATIONS_HAVE_YIELD_GAPS")
local corrCall=uniqueAt(correctionsSrc,
  "QuestieQuestFixes:LoadMissingQuests()","CORRECTION_MISSING_QUEST_CALL")
local corrPatch=uniqueAt(correctionsSrc,
  '_LoadCorrections("questData", QuestieQuestFixes:Load()',
  "CORRECTION_QUEST_PATCH_CALL")
check(corrCall<corrPatch,"MISSING_QUEST_ROW_REPLACEMENT_PRECEDES_CORRECTIONS")
check(not rawMissing:find("coroutine.yield()",1,true) and
  not rawGather:find("coroutine.yield()",1,true),
  "TWO_METHOD_BODIES_HAVE_NO_INTERNAL_EXPLICIT_YIELD")

assert(total==17,"PART50_SOURCE_WRITER_ASSERTION_COUNT:"..total)
print("PUBLIC G08 PART50 ORIGINAL PRECOMPILE SOURCE WRITERS: 17/17 PASS")
print("PUBLIC G08 PART50 FACT: original methods replace 12 selected raw quest rows and remove spawn fields from 24 selected object records; original startup order has yields between stages.")
print("PUBLIC G08 PART50 NOT NATIVE: invented inputs; no production missing row, owner overwrite, untrusted writer race, published bytes, client, package or server change.")
