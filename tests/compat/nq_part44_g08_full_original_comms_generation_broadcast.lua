-- PUBLIC-SAFE TEST ONLY: genuine complete original 335 QuestieComms module.
-- All Questie/ZoneDB/database/serializer/timer/network adapters are fictional.
-- This file NEVER opens network sockets or sends addon messages.
local root=assert(os.getenv("NQ_G08_FULL_COMMS_ROOT"),"PINNED_SOURCE_ROOT_REQUIRED")
local fp=assert(io.open(root.."/Modules/Network/QuestieComms.lua","rb"))
local src=assert(fp:read("*a"));fp:close()
local assertions=0
local function check(ok,label) assert(ok,label);assertions=assertions+1 end
local function compile(source,env)
  local f
  if _VERSION=="Lua 5.1" then
    f=assert(loadstring(source,"@335/Modules/Network/QuestieComms.lua"));setfenv(f,env)
  else
    f=assert(load(source,"@335/Modules/Network/QuestieComms.lua","t",env))
  end
  return f()
end
check(src:find("function _QuestieComms:BroadcastQuestLog(eventName, sendMode, targetPlayer)",1,true)~=nil,
  "C01_ORIGINAL_BROADCAST_V1")
check(src:find("function _QuestieComms:BroadcastQuestLogV2(eventName, sendMode, targetPlayer)",1,true)~=nil,
  "C02_ORIGINAL_BROADCAST_V2")
check(src:find("if (not QuestieDB.QuestPointers[questId]) then",1,true)~=nil,
  "C03_ORIGINAL_POINTER_MEMBERSHIP")
check(src:find('zoneOrSort = QuestieDB.QueryQuestSingle(questId, "zoneOrSort")',1,true)~=nil,
  "C04_ORIGINAL_SEPARATE_ZONE_QUERY")
check(src:find("if entry.zoneOrSort > 0 then",1,true)~=nil,
  "C05_ORIGINAL_ZONE_NUMERIC_COMPARE")
check(src:find("function QuestieComms:CreateQuestDataPacket(questId)",1,true)~=nil,
  "C06_ORIGINAL_V1_PACKET_BUILDER")
check(src:find("function QuestieComms:PopulateQuestDataPacketV2_noclass_renameme",1,true)~=nil,
  "C07_ORIGINAL_V2_PAYLOAD_BUILDER")
check(src:find("function _QuestieComms:CreatePacket(messageId)",1,true)~=nil,
  "C08_ORIGINAL_PACKET_FACTORY")
check(src:find("function _QuestieComms:Broadcast(packet)",1,true)~=nil,
  "C09_ORIGINAL_BROADCAST_SERIALIZER_PATH")
check(src:find("C_Timer.NewTicker(3, function()",1,true)~=nil,
  "C10_ORIGINAL_DELAYED_SEND_TIMER")
local function mkgen(first)
  local ptr,rows={},{}
  for id=first,first+1 do
    ptr[id]=true
    rows[id]={Id=id,Objectives={{Id=id*10+1}}}
  end
  return {ptr=ptr,rows=rows}
end
local OLD,NEW=mkgen(11),mkgen(111)
local function fixture()
  local group="party"
  local dataGeneration="OLD"
  local source=OLD
  local after,tickers,network,errors,serializeCalls,queryCalls,zoneCalls={},{},{},{},{},{},{}
  local lastSerialized
  local questlog={questLog_DO_NOT_MODIFY={}}
  local db={QuestPointers=OLD.ptr}
  function db.QueryQuestSingle(id,field)
    queryCalls[#queryCalls+1]={id=id,generation=dataGeneration,field=field}
    if field=="zoneOrSort" then
      if source.rows[id] then return 77 end
      return nil
    end
    return nil
  end
  function db.GetQuest(id) return source.rows[id] end
  local serializer={}
  function serializer:Serialize(payload)
    lastSerialized=payload
    serializeCalls[#serializeCalls+1]=payload
    return "SYNTHETIC_SERIALIZER_OUTPUT"
  end
  local player={numberOfGroupMembers=2}
  function player:GetGroupType() return group end
  local zone={}
  function zone:GetUiMapIdByAreaId(area)
    zoneCalls[#zoneCalls+1]=area;return area+100
  end
  local hbd={}
  function hbd:GetPlayerZone() return 5 end
  function hbd:GetZoneDistance() return 3 end
  local timer={}
  function timer.After(delay,callback) after[#after+1]={delay=delay,fn=callback} end
  function timer.NewTicker(delay,callback,count)
    local item={delay=delay,fn=callback,count=count}
    tickers[#tickers+1]=item
    return item
  end
  local questie={IsSoD=false,DEBUG_DEVELOP=1,DEBUG_SPAM=2,_sessionWarnings={}}
  function questie:Debug() end
  function questie:Error(...) errors[#errors+1]=table.concat({...}," ") end
  function questie:SendCommMessage(prefix,payload,mode,target,priority)
    network[#network+1]={prefix=prefix,payload=payload,mode=mode,target=target,
      priority=priority,packet=lastSerialized,atGeneration=dataGeneration}
  end
  local lib={}
  function lib:GetAddonVersionInfo() return 5,0,0 end
  local modules={
    QuestieSerializer=serializer,QuestieLib=lib,QuestiePlayer=player,
    QuestieDB=db,DailyQuests={FilterDailies=function()end},ZoneDB=zone,
    l10n=function(s,...) if select("#",...)>0 then return string.format(s,...) end return s end,
    QuestLogCache=questlog
  }
  local loader={}
  function loader:CreateModule(name)
    assert(name=="QuestieComms","UNEXPECTED_MODULE:"..tostring(name))
    local m={private={}}
    modules[name]=m
    return m
  end
  function loader:ImportModule(name)
    assert(modules[name],"UNEXPECTED_IMPORT:"..tostring(name))
    return modules[name]
  end
  local env={
    QuestieLoader=loader,QuestieCompat={C_Timer=timer,C_Map={},HBD=hbd,
      UnitInParty=function()return true end,IsInRaid=function()return false end},
    Questie=questie,GetTime=function()return 20 end,
    random=function()return 0.25 end,
    UnitInBattleground=function()return false end,
    tinsert=table.insert,tremove=table.remove,
    unpack=unpack or table.unpack,LibStub=function()return hbd end,
    floor=math.floor
  }
  setmetatable(env,{__index=_G})
  local comms=compile(src,env)
  local p=comms.private
  local f={comms=comms,p=p,db=db,questlog=questlog,after=after,tickers=tickers,
    network=network,errors=errors,queryCalls=queryCalls,zoneCalls=zoneCalls,
    serializeCalls=serializeCalls}
  function f.setRows(gen)
    dataGeneration=gen
    source=(gen=="OLD" and OLD or NEW)
  end
  function f.setPointers(gen)
    db.QuestPointers=(gen=="OLD" and OLD or NEW).ptr
  end
  function f.setLog(id,tag)
    questlog.questLog_DO_NOT_MODIFY={}
    if id then questlog.questLog_DO_NOT_MODIFY[id]={questTag=tag or "Normal"} end
    questlog.GetQuestObjectives=function(questId)
      if questlog.questLog_DO_NOT_MODIFY[questId] then
        return {{type="Kill",finished=false,numFulfilled=1,numRequired=3}}
      end
      return nil
    end
  end
  function f.group(v) group=v end
  function f.v1(event,mode,target) p:BroadcastQuestLog(event or "SYNTHETIC",mode,target) end
  function f.v2(event,mode,target) p:BroadcastQuestLogV2(event or "SYNTHETIC",mode,target) end
  function f.fireAfter()
    local first=table.remove(after,1)
    assert(first,"NO_PENDING_DELAY")
    first.fn()
  end
  function f.fireTicker(index)
    local t=tickers[index or #tickers]
    assert(t,"NO_QUEUED_TICKER")
    t.fn()
  end
  return f
end
local a=fixture()
check(type(a.comms)=="table" and type(a.p.BroadcastQuestLog)=="function",
  "C11_FULL_ORIGINAL_MODULE_LOADED")
check(type(a.p.BroadcastQuestLogV2)=="function" and type(a.p.Broadcast)=="function",
  "C12_FULL_ORIGINAL_NETWORK_FUNCTIONS_LOADED")
a.setLog(11,"Dungeon")
a.v1("OLD-START")
check(#a.after==1 and #a.tickers==0,"C13_V1_ORIGINAL_DELAY_SCHEDULED")
check(#a.network==0 and a.p._isBroadcasting,"C14_V1_NO_IMMEDIATE_SEND")
check(#a.queryCalls==1 and a.queryCalls[1].id==11 and a.queryCalls[1].field=="zoneOrSort",
  "C15_V1_ORIGINAL_QUERY_QUEST_ZONE")
check(#a.zoneCalls==1 and a.zoneCalls[1]==77,"C16_V1_ORIGINAL_HBD_ZONE_PATH")
a.fireAfter()
check(#a.tickers==1 and a.tickers[1].count==2,"C17_V1_REAL_TICKER_CREATED")
check(#a.network==0,"C18_V1_PACKET_NOT_YET_SENT")
a.fireTicker(1)
check(#a.network==1 and a.network[1].mode=="PARTY" and a.network[1].priority=="NORMAL",
  "C19_V1_REAL_PACKET_WRITER_MOCK_TRANSPORT")
check(a.network[1].prefix=="questie" and a.network[1].packet.msgId==10,
  "C20_V1_ORIGINAL_MESSAGE_TYPE")
check(a.network[1].packet.rawQuestList[11].objectives[1].id==111,
  "C21_V1_ORIGINAL_QUEST_OBJECTIVE_BUILDER")
a.fireTicker(1)
check(not a.p._isBroadcasting and #a.network==1,"C22_V1_COMPLETION_FREES_BROADCAST")
local b=fixture()
b.setLog(111,"Dungeon")
b.setPointers("NEW")
b.setRows("NEW")
b.v2("NEW-START","WHISPER","fictional-recipient")
check(#b.after==1 and b.p._isBroadcastingV2,"C23_V2_ACTUAL_SCHEDULER_ENTRY")
check(#b.network==0 and #b.queryCalls==1,"C24_V2_NO_EARLY_MESSAGE")
b.fireAfter()
check(#b.tickers==1 and b.tickers[1].count==2,"C25_V2_ACTUAL_TICKER")
b.fireTicker(1)
check(#b.network==1 and b.network[1].mode=="WHISPER" and
  b.network[1].target=="fictional-recipient","C26_V2_REAL_WRITE_MODE")
check(b.network[1].packet.msgId==12 and b.network[1].packet[1][1]==1,
  "C27_V2_ORIGINAL_PACKET_TYPE_AND_COUNT")
check(b.network[1].packet[1][2]==111 and b.network[1].packet[1][3]==1,
  "C28_V2_ORIGINAL_QUEST_ID_AND_OBJECTIVE_COUNT")
check(b.network[1].packet[1][4]==1111,
  "C29_V2_ORIGINAL_OBJECTIVE_ID")
b.fireTicker(1)
check(not b.p._isBroadcastingV2,"C30_V2_COMPLETION_CLEARS_FLAG")
local c=fixture()
c.setLog(11,"Dungeon")
c.setRows("NEW")
local ok,err=pcall(function()c.v1()end)
check(not ok and tostring(err):find("nil",1,true)~=nil,
  "C31_V1_OLD_PTR_NEW_ZONE_NIL_ERROR")
check(#c.after==0 and #c.network==0,"C32_V1_MISMATCH_NO_PACKET_SCHEDULED")
local d=fixture()
d.setLog(111,"Dungeon")
d.setPointers("NEW")
local ok2,err2=pcall(function()d.v2()end)
check(not ok2 and tostring(err2):find("nil",1,true)~=nil,
  "C33_V2_NEW_PTR_OLD_ZONE_NIL_ERROR")
check(#d.after==0 and #d.network==0,"C34_V2_MISMATCH_NO_PACKET")
local e=fixture()
e.setLog(11,"Dungeon")
e.setPointers("NEW")
e.v1()
check(#e.after==0 and #e.errors==1,"C35_MISSING_POINTER_NO_QUEUED_SEND")
check(e.comms~=nil and e.errors[1]:find("missing",1,true)~=nil,
  "C36_ORIGINAL_MISSING_SOURCE_WARNING")
local f=fixture()
f.group(nil)
f.setLog(11,"Dungeon")
f.v2()
check(#f.after==0 and #f.queryCalls==0,"C37_NO_GROUP_NO_BROADCAST")
local g=fixture()
g.group("raid");g.setLog(11,"Normal");g.v1()
check(#g.after==0 and #g.network==0,"C38_RAID_OMITS_SOLO_QUEST")
local h=fixture()
h.group("raid");h.setLog(11,"Dungeon");h.v1();h.fireAfter();h.fireTicker(1)
check(#h.network==1 and h.network[1].mode=="RAID","C39_RAID_DUNGEON_BROADCAST")
local i=fixture()
i.setLog(11,"Dungeon")
i.v1("OLD-REQUEST")
i.v1("QUEUED-REQUEST")
check(#i.p._nextBroadcastData==1,"C40_ORIGINAL_QUEUED_BROADCAST")
i.setLog(111,"Dungeon")
i.setPointers("NEW");i.setRows("NEW")
i.fireAfter();i.fireTicker(1)
check(#i.network==1 and i.network[1].packet.rawQuestList[11]~=nil and
 i.network[1].atGeneration=="NEW","C41_OLD_PACKED_MESSAGE_CAN_SEND_AFTER_SOURCE_CHANGE")
i.fireTicker(1)
check(#i.after==1 and i.p._isBroadcasting,
  "C42_ORIGINAL_NEXT_BROADCAST_RECALCULATES")
i.fireAfter();i.fireTicker(2)
check(#i.network==2 and i.network[2].packet.rawQuestList[111]~=nil,
  "C43_NEXT_QUEUED_BROADCAST_NEW_GENERATION")
i.fireTicker(2)
check(not i.p._isBroadcasting and #i.p._nextBroadcastData==0,
  "C44_QUEUED_BROADCAST_FINISH")
local j=fixture()
j.setLog(11,"Dungeon")
j.v2("OLD-V2")
j.setRows("NEW");j.setPointers("NEW")
j.fireAfter();j.fireTicker(1)
check(j.network[1].packet[1][2]==11 and j.network[1].atGeneration=="NEW",
  "C45_V2_OLD_ENCODED_BLOCK_SENT_AFTER_MODEL_SOURCE_SWAP")
check(#j.errors==0,"C46_DELAYED_PAYLOAD_NO_NATIVE_MUTATION_ERRORS")
assert(assertions==46,"FULL_COMMS_CENSUS_CHANGED:"..assertions)
print("PUBLIC G08 PART44 FULL ORIGINAL COMMS V1 V2: 46/46 PASS")
print("PUBLIC G08 ORIGINAL EXECUTION: unchanged complete QuestieComms.lua loaded; actual full BroadcastQuestLog and BroadcastQuestLogV2, CreateQuestDataPacket, PopulateQuestDataPacketV2, CreatePacket, Broadcast and delayed callbacks executed.")
print("PUBLIC G08 SYNTHETIC FINDINGS: mismatched pointers and zone query fail on nil compare; prepared OLD V1/V2 payload can enter fake outbound sink after invented OLD-to-NEW source swap; queued V1 broadcast rebuilds from NEW.")
print("PUBLIC G08 SAFETY: fake SendCommMessage only records calls; no actual network traffic, real serializer, client timer, AzerothCore/IP client, SavedVariables, compiler, stream, build, ZIP, install, protected merge or release.")
