-- TEST ONLY: original 335 Compat functions and original quest-event RegisterEvents.
-- Fake frame/hooksecurefunc, reward and abandon calls. NOT native client.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"ORIGINAL_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"SOURCE_MISSING:"..path)
  local s=assert(f:read("*a"));f:close();return s
end
local handlerSrc=read("Modules/Quest/QuestEventHandler.lua")
local compatSrc=read("Compat/Compat.lua")
local function extract(src,a,b)
  local i=assert(src:find(a,1,true),"START_MISSING:"..a)
  local j=assert(src:find(b,i+#a,true),"END_MISSING:"..b)
  return src:sub(i,j-1)
end
local originalRegister=extract(handlerSrc,"function QuestEventHandler:RegisterEvents()",
  "\n--- On Login mark all quests in the quest log with QUEST_ACCEPTED state")
local originalOverlay=extract(compatSrc,"function QuestieCompat.QuestEventHandler_RegisterEvents()",
  "\nfunction QuestieCompat.QuestieTracker_Initialize(")
local originalSystem=extract(compatSrc,"function QuestieCompat:CHAT_MSG_SYSTEM(event, message)",
  "\nfunction QuestieCompat.QuestEventHandler_RegisterEvents()")
local hookLine='hooksecurefunc(QuestEventHandler, "RegisterEvents", QuestieCompat.QuestEventHandler_RegisterEvents)'
local addonStart=assert(compatSrc:find("function QuestieCompat:ADDON_LOADED(",1,true))
local hookStart=assert(compatSrc:find(hookLine,addonStart,true))
local tests=0
local function check(v,n)assert(v,n);tests=tests+1 end
check(hookStart>addonStart,"H01_ORIGINAL_ADDON_LOADED_INSTALL_SOURCE")
check(originalRegister:find('RegisterEvent("QUEST_TURNED_IN")',1,true)~=nil,
  "H02_ORIGINAL_MAIN_REGISTER_TURNIN")
check(originalRegister:find('RegisterEvent("QUEST_REMOVED")',1,true)~=nil,
  "H03_ORIGINAL_MAIN_REGISTER_REMOVE")
check(originalOverlay:find('UnregisterEvent("QUEST_TURNED_IN")',1,true)~=nil,
  "H04_ORIGINAL_335_UNREGISTER_TURNIN")
check(originalOverlay:find('UnregisterEvent("QUEST_REMOVED")',1,true)~=nil,
  "H05_ORIGINAL_335_UNREGISTER_REMOVE")
check(originalOverlay:find('hooksecurefunc("AbandonQuest"',1,true)~=nil,
  "H06_ORIGINAL_335_ABANDON_HOOK")
check(originalOverlay:find('hooksecurefunc("GetQuestReward"',1,true)~=nil,
  "H07_ORIGINAL_335_REWARD_HOOK")
check(originalOverlay:find('_QuestEventHandler:QuestRemoved(QuestieCompat.abandonQuestID)',1,true)~=nil,
  "H08_ORIGINAL_335_ABANDON_CAPTURED_ID_CALL")
check(originalSystem:find('_QuestEventHandler:QuestTurnedIn(questId)',1,true)~=nil,
  "H09_ORIGINAL_335_CHAT_SYSTEM_TURNIN_SOURCE")
local questFrame={events={}}
function questFrame:RegisterEvent(s)self.events[s]=true end
function questFrame:UnregisterEvent(s)self.events[s]=nil end
function questFrame:SetScript(n,fn)
  assert(n=="OnEvent" and type(fn)=="function");self.script=fn
end
local compatFrame={events={}}
function compatFrame:RegisterEvent(s)self.events[s]=true end
local effects={removed={},turned={},init=0,hooks=0}
local priv={
  OnEvent=function()end,QuestRelatedFrameClosed=function()end,
  InitQuestLog=function()effects.init=effects.init+1 end,
  QuestRemoved=function(_,id)effects.removed[#effects.removed+1]=id or "NIL_ID" end,
  QuestTurnedIn=function(_,id)effects.turned[#effects.turned+1]=id or "NIL_ID" end
}
local public={}
local compat={frame=compatFrame}
function compat.GetQuestIDFromName(s)if s=="Synthetic Quest" then return 1 end end
local hooks, methodHooks = {}, {}
local function hooksecure(a,b,c)
  if type(a)=="table" then
    assert(type(b)=="string" and type(c)=="function")
    local original=assert(a[b])
    a[b]=function(self,...)
      local value=original(self,...)
      c(self,...)
      return value
    end
    methodHooks[b]=(methodHooks[b] or 0)+1
  else
    assert(type(a)=="string" and type(b)=="function" and c==nil)
    hooks[a]=hooks[a] or {}
    hooks[a][#hooks[a]+1]=b
  end
  effects.hooks=effects.hooks+1
end
local function fireHook(s,...)
  assert(hooks[s],"FAKE_HOOK_MISSING:"..s)
  for _,f in ipairs(hooks[s]) do f(...) end
end
local questie={DEBUG_DEVELOP=1,DEBUG_INFO=2,db={profile={resetDailyQuests=false}}}
function questie:Debug()end
local env={Questie=questie,QuestEventHandler=public,QuestieCompat=compat,
  PRIVATE=priv,FRAME=questFrame,QuestieQuestEventFrame=questFrame,
  hooksecurefunc=hooksecure,
  GetQuestLogSelection=function()return 1 end,
  GetQuestLogTitle=function(i)
    assert(i==1);return "Synthetic Quest",nil,nil,nil,nil,nil,nil,nil,1
  end,
  GetTitleText=function()return "Synthetic Quest" end,
  GetMaxDailyQuests=function()return 25 end}
setmetatable(env,{__index=_G})
local prologue=table.concat({
  "local eventFrame=FRAME",
  "local _QuestEventHandler=PRIVATE",
  "local completeQuestCache={}",
  'local QUEST_COMPLETE_MSG=string.gsub("Quest completed: %s","(%%s)","(.+)")',
  'local DAILY_QUESTS_MSG="Remaining (%d+)"'
},"\n").."\n"
local script=prologue..originalRegister.."\n"..originalSystem.."\n"
  ..originalOverlay.."\n"..hookLine.."\n"
local fn
if _VERSION=="Lua 5.1" then fn=assert(loadstring(script,"=ORIGINAL_335_COMPAT_QUEST_HOOK_BODIES"));setfenv(fn,env)
else fn=assert(load(script,"=ORIGINAL_335_COMPAT_QUEST_HOOK_BODIES","t",env)) end
fn()
check(methodHooks.RegisterEvents==1,"H10_ORIGINAL_POSTHOOK_INSTALLED")
public:RegisterEvents()
check(effects.init==1,"H11_ORIGINAL_BASE_REGISTER_INIT_CALLED")
check(type(questFrame.script)=="function" and questFrame.events.QUEST_ACCEPTED,
  "H12_335_QUEST_ACCEPTED_REMAINS_REGISTERED")
check(not questFrame.events.QUEST_TURNED_IN and not questFrame.events.QUEST_REMOVED,
  "H13_335_TURNIN_REMOVED_UNREGISTERED")
check(questFrame.events.QUEST_LOG_UPDATE,"H14_335_QUEST_LOG_UPDATE_REMAINS")
check(compatFrame.events.CHAT_MSG_SYSTEM and compatFrame.events.QUEST_QUERY_COMPLETE,
  "H15_335_COMPAT_FRAME_NEW_EVENTS")
check(#hooks.GetQuestReward==1 and #hooks.SetAbandonQuest==1 and #hooks.AbandonQuest==1,
  "H16_ORIGINAL_REWARD_ABANDON_HOOKS_REGISTERED")
check(#hooks.StaticPopup_Show==1 and #hooks.DeleteCursorItem==1,
  "H17_ORIGINAL_QUEST_ITEM_HOOKS_REGISTERED")
check(compat.TRADE_CLOSED==priv.QuestRelatedFrameClosed,
  "H18_ORIGINAL_335_QUEST_FRAME_CLOSE_ROUTE")
check(effects.hooks==6,"H19_TOTAL_FAKE_POSTHOOK_INSTALL_COUNT")
fireHook("GetQuestReward",1)
check(#effects.turned==0,"H20_REWARD_HOOK_ONLY_CACHES_NAME")
compat:CHAT_MSG_SYSTEM("CHAT_MSG_SYSTEM","Quest completed: Synthetic Quest")
check(#effects.turned==1 and effects.turned[1]==1,
  "H21_335_CHAT_TURNIN_CALLS_ORIGINAL_PRIVATE_SINK")
check(#effects.removed==1 and effects.removed[1]==1,
  "H22_335_CHAT_TURNIN_ALSO_CALLS_REMOVED_SINK")
compat:CHAT_MSG_SYSTEM("CHAT_MSG_SYSTEM","Quest completed: Synthetic Quest")
check(#effects.turned==1 and #effects.removed==1,
  "H23_335_QUEST_COMPLETION_NAME_CACHE_CONSUMED")
fireHook("SetAbandonQuest")
check(compat.abandonQuestID==1,"H24_335_SET_ABANDON_CAPTURES_ID")
fireHook("AbandonQuest")
check(#effects.removed==2 and effects.removed[2]==1,
  "H25_335_ABANDON_POSTHOOK_USES_CAPTURED_ID")
compat.abandonQuestID=nil
fireHook("AbandonQuest")
check(#effects.removed==3 and effects.removed[3]=="NIL_ID",
  "H26_335_ABANDON_LOCAL_FALLBACK_NOT_FORWARDED_IF_UNCAPTURED")
check(#effects.turned==1,"H27_ABANDON_DOES_NOT_TURN_IN")
check(effects.init==1,"H28_ONLY_ONE_REGISTER_INIT")
check(questFrame.events.QUEST_ACCEPTED and not questFrame.events.QUEST_REMOVED,
  "H29_335_FINAL_EVENT_FRAME_ROUTING")
check(compatFrame.events.TRADE_CLOSED and compatFrame.events.AUCTION_HOUSE_CLOSED,
  "H30_335_ADAPTER_FRAME_CLOSE_REGISTRATIONS")
assert(tests==30,"ORIGINAL_335_COMPAT_HOOK_CHECKS:"..tests)
print("PUBLIC G08 PART47 ORIGINAL 335 COMPAT QUEST HOOKS: 30/30 PASS")
print("PUBLIC G08 PART47 ORIGINAL: full genuine QuestEventHandler RegisterEvents, Compat QuestEventHandler_RegisterEvents and CHAT_MSG_SYSTEM bodies plus genuine ADDON_LOADED installer line.")
print("PUBLIC G08 PART47 NOT NATIVE: fabricated secure posthooks, reward/abandon actions, frames, quest strings and QuestEventHandler private sinks; whole Compat ADDON_LOADED not executed.")
