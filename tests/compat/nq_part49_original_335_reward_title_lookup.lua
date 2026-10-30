-- TEST ONLY. Executes unchanged historical original 335 Compat first-title lookup,
-- CHAT_MSG_SYSTEM and GetQuestReward hook body under fabricated quest logs/events.
-- Does NOT execute a native 3.3.5a client or prove actual reward-message timing.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local f=assert(io.open(root.."/Compat/Compat.lua","rb"),"AUTHENTIC_COMPAT_BLOB_REQUIRED")
local source=assert(f:read("*a"));f:close()
local function extract(a,b)
  local x=assert(source:find(a,1,true),"SOURCE_START_MISSING:"..a)
  local y=assert(source:find(b,x+#a,true),"SOURCE_END_MISSING:"..b)
  return source:sub(x,y-1)
end
local lookup=extract("function QuestieCompat.GetQuestIDFromName(questTitle)",
  "\n-- https://wowwiki-archive.fandom.com/wiki/API_UnitGUID")
local system=extract("function QuestieCompat:CHAT_MSG_SYSTEM(event, message)",
  "\nfunction QuestieCompat.QuestEventHandler_RegisterEvents()")
local hook=extract('    hooksecurefunc("GetQuestReward", function(itemChoice)',
  '\n\n    hooksecurefunc("SetAbandonQuest"')
local tests=0
local function check(v,n)
  assert(v,"PART49_ORIGINAL_REWARD_LOOKUP:"..n)
  tests=tests+1
end
check(lookup:find("return id",1,true)~=nil,"ORIGINAL_LOOKUP_RETURN")
check(lookup:find("if (not title) then",1,true)~=nil,"ORIGINAL_LOOKUP_EARLY_STOP")
check(system:find("completeQuestCache[questName] = nil",1,true)~=nil,"ORIGINAL_SYSTEM_CONSUMPTION")
check(hook:find("completeQuestCache[questTitle] = questId",1,true)~=nil,"ORIGINAL_REWARD_CACHE_ASSIGNMENT")
local rows,title={},nil
local rewardHooks={}
local effects={}
local scanned={}
local function getQuestLogTitle(i)
  scanned[#scanned+1]=i
  local r=rows[i]
  if not r then return nil end
  return r.title,nil,nil,nil,r.header,nil,nil,nil,r.id
end
local handler={
  QuestTurnedIn=function(_,id)effects[#effects+1]="turn:"..tostring(id) end,
  QuestRemoved=function(_,id)effects[#effects+1]="remove:"..tostring(id) end
}
local compat={}
local questie={db={profile={resetDailyQuests=false}}}
local env={
  QuestieCompat=compat,
  Questie=questie,
  QuestEventHandler={private=handler},
  GetQuestLogTitle=getQuestLogTitle,
  MAX_QUEST_LOG_INDEX=25,
  GetTitleText=function()return title end,
  hooksecurefunc=function(which,callback)
    assert(which=="GetQuestReward" and type(callback)=="function")
    rewardHooks[#rewardHooks+1]=callback
  end
}
setmetatable(env,{__index=_G})
local program=table.concat({
  "local _QuestEventHandler=QuestEventHandler.private",
  "local completeQuestCache={}",
  'local QUEST_COMPLETE_MSG=string.gsub("Quest completed: %s","(%%s)","(.+)")',
  'local DAILY_QUESTS_MSG="Remaining (%d+)"',
  lookup,
  system,
  "function installRewardHook()",
  hook,
  "end",
  "installRewardHook()"
},"\n")
local fn
if _VERSION=="Lua 5.1" then
  fn=assert(loadstring(program,"=AUTHENTIC_335_REWARD_SOURCE"))
  setfenv(fn,env)
else
  fn=assert(load(program,"=AUTHENTIC_335_REWARD_SOURCE","t",env))
end
fn()
local function setRows(entries)rows=entries;scanned={} end
local function reward(name)
  title=name
  assert(#rewardHooks==1)
  rewardHooks[1](1)
end
local function complete(name)
  compat:CHAT_MSG_SYSTEM("CHAT_MSG_SYSTEM","Quest completed: "..name)
end
local function count()return #effects end
check(type(compat.GetQuestIDFromName)=="function","AUTHENTIC_LOOKUP_EXECUTED")
check(type(compat.CHAT_MSG_SYSTEM)=="function","AUTHENTIC_SYSTEM_METHOD_EXECUTED")
check(#rewardHooks==1,"AUTHENTIC_REWARD_HOOK_INSTALLED")
setRows({{title="CATEGORY",header=true,id=999},{title="Unique",id=101}})
check(compat.GetQuestIDFromName("Unique")==101,"HEADER_SKIPPED_UNIQUE_FOUND")
check(#scanned==2 and scanned[1]==1 and scanned[2]==2,"STOPS_AT_FIRST_MATCH")
setRows({{title="Duplicate",id=201},{title="Duplicate",id=202}})
check(compat.GetQuestIDFromName("Duplicate")==201,"FIRST_SAME_TITLE_SELECTED")
check(#scanned==1,"SECOND_SAME_TITLE_NOT_EXAMINED")
setRows({{title="Other",id=300}})
check(compat.GetQuestIDFromName("Missing")==nil,"UNKNOWN_TITLE_IS_NIL")
check(#scanned==2,"SCAN_STOPS_AT_NIL_TITLE")
setRows({{title="Stop",id=311},nil,{title="Stop",id=312}})
check(compat.GetQuestIDFromName("Never")==nil,"HOLE_STOPS_LOOKUP")
check(#scanned==2,"DOES_NOT_SKIP_NIL_ENTRY")
setRows({{title="Exact",id=321}})
check(compat.GetQuestIDFromName("exact")==nil,"TITLE_COMPARE_EXACT_CASE")
setRows({{title="Unique",id=101}})
reward("Unique")
check(count()==0,"REWARD_HOOK_DEFERS_HANDLER_EFFECTS")
complete("Different")
check(count()==0,"UNRELATED_COMPLETION_IGNORED")
complete("Unique")
check(count()==2 and effects[1]=="turn:101" and effects[2]=="remove:101",
  "EXACT_NAME_COMPLETION_ROUTES_TO_FIRST_LOG_ID")
complete("Unique")
check(count()==2,"CACHE_CONSUMED_ON_MATCHING_CHAT")
setRows({})
reward("Unknown")
complete("Unknown")
check(count()==2,"NO_MATCH_NO_NEW_CACHE_NO_EFFECTS")
setRows({{title="Stale",id=401}})
reward("Stale")
complete("Unrelated")
check(count()==2,"UNMATCHED_CHAT_DOES_NOT_CONSUME_STALE_KEY")
setRows({})
reward("Stale")
check(count()==2,"NO_MATCH_REWARD_DOES_NOT_TURN_IN")
complete("Stale")
check(count()==4 and effects[3]=="turn:401" and effects[4]=="remove:401",
  "OLD_CACHE_SURVIVES_FAILED_NEW_LOOKUP_FAKE_INPUT")
complete("Stale")
check(count()==4,"LATE_MATCH_CONSUMES_STALE_KEY_ONCE")
setRows({{title="Overwrite",id=501}})
reward("Overwrite")
setRows({{title="Overwrite",id=502}})
reward("Overwrite")
complete("Overwrite")
check(count()==6 and effects[5]=="turn:502" and effects[6]=="remove:502",
  "NEW_SUCCESSFUL_HOOK_OVERWRITES_OLDER_SAME_TITLE")
setRows({{title="Shared",id=601},{title="Shared",id=602}})
reward("Shared")
complete("Shared")
check(count()==8 and effects[7]=="turn:601" and effects[8]=="remove:601",
  "FABRICATED_DUPLICATE_SELECTS_FIRST_MATCH")
setRows({{title="Daily",id=701}})
reward("Daily")
complete("Daily")
check(count()==10 and effects[9]=="turn:701" and effects[10]=="remove:701",
  "OTHER_NAME_ID_INDEPENDENT")
check(questie.db.profile.resetDailyQuests==false,"DISABLED_DAILY_RESET_UNDER_FAKE_HOST")
check(#rewardHooks==1,"NO_DUPLICATED_HOOKS")
assert(tests==30,"PART49_REWARD_LOOKUP_ASSERTION_CENSUS:"..tests)
print("PUBLIC G08 PART49 ORIGINAL 335 REWARD TITLE SOURCE: 30/30 PASS")
print("PUBLIC G08 PART49 SOURCE: genuine immutable first-match lookup, GetQuestReward callback and CHAT_MSG_SYSTEM method; fabricated GetQuestLogTitle/title/messages and private handler sinks.")
print("PUBLIC G08 PART49 NOT NATIVE: no actual client, server reward, hook ordering, simultaneous duplicate log or player impact.")
