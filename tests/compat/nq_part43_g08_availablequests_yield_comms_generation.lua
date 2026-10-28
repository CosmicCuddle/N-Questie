-- PUBLIC-SAFE G08 test-only SOURCE-FRAGMENT scheduler witness.
-- Executes exact unchanged 335 AvailableQuests pointer capture and iteration
-- (NOT its full _CalculateAvailableQuests body). Fictional quest callback.
local root=assert(os.getenv("NQ_G08_AVAIL_COMMS_ROOT"),"PINNED_ORIGINAL_ROOT_REQUIRED")
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"),"ORIGINAL_FILE_MISSING:"..path)
    local src=assert(f:read("*a"));f:close();return src
end
local available=read("Modules/Quest/AvailableQuests.lua")
local comms=read("Modules/Network/QuestieComms.lua")
local tracker=read("Modules/Tracker/TrackerLinePool.lua")
local function slice(s,first,last)
    local a=assert(s:find(first,1,true),"SOURCE_START_MISSING:"..first)
    assert(not s:find(first,a+#first,true),"SOURCE_NOT_UNIQUE:"..first)
    local b=assert(s:find(last,a+#first,true),"SOURCE_END_MISSING:"..first)
    return s:sub(a,b-1)
end
local captureLine="    local questData = QuestieDB.QuestPointers or QuestieDB.questData"
local originalLoop=slice(available,
    "    local questCount = 0\n    for questId in pairs(questData) do",
    "\nend\n\n--- Mark all child quests")
local checkCount=0
local function check(ok,name)assert(ok,name);checkCount=checkCount+1 end
local function compile(code,env)
    local f
    if _VERSION=="Lua 5.1" then
        f=assert(loadstring(code,"=unchanged_original_335_fragments"));setfenv(f,env)
    else
        f=assert(load(code,"=unchanged_original_335_fragments","t",env))
    end
    return f()
end
local function generation(tag,start)
    local data={};local ptr={}
    for i=0,51 do
        ptr[start+i]=true
        data[start+i]={name=tag.."_"..(start+i),zoneOrSort=tag=="OLD" and 1 or 2}
    end
    return{tag=tag,ptr=ptr,data=data}
end
local old=generation("OLD",1)
local new=generation("NEW",101)
local function fixture()
    local current={pointers=old.ptr,queryData=old.data,tag="OLD"}
    local facade={QuestPointers=current.pointers}
    function facade.QueryQuestSingle(id,key)
        return current.queryData[id] and current.queryData[id][key]
    end
    local attempts,missing={},0
    local env={QuestieDB=facade,yield=coroutine.yield,QUESTS_PER_YIELD=24}
    env._DrawQuestIfAvailable=function(questId)
        local zone=facade.QueryQuestSingle(questId,"zoneOrSort")
        attempts[#attempts+1]={id=questId,zone=zone,current=current.tag}
        if zone==nil then missing=missing+1 end
    end
    setmetatable(env,{__index=_G})
    local fn=compile("return function()\n"..captureLine.."\n"..
        originalLoop.."\nend",env)
    local thread=coroutine.create(fn)
    local function step()
        local ok,result=coroutine.resume(thread)
        assert(ok,"TEST_DRIVER_FAILED:"..tostring(result))
        return result
    end
    return{
        thread=thread,step=step,facade=facade,events=attempts,
        setCurrent=function(tag)
            current={tag=tag,pointers=(tag=="OLD" and old.ptr or new.ptr),
                queryData=(tag=="OLD" and old.data or new.data)}
            facade.QuestPointers=current.pointers
        end,
        missing=function()return missing end,
        sourcePointer=function()return current.pointers end
    }
end
check(available:find(captureLine,1,true)~=nil,
      "V01_ORIGINAL_LOCAL_QUEST_POINTER_CAPTURE")
check(originalLoop:find("for questId in pairs(questData) do",1,true)~=nil,
      "V02_ORIGINAL_QUEST_POINTER_ENUMERATION")
check(originalLoop:find("if questCount > QUESTS_PER_YIELD then",1,true)~=nil,
      "V03_ORIGINAL_LOOP_YIELD_THRESHOLD")
check(originalLoop:find("yield()",1,true)~=nil,
      "V04_ORIGINAL_SUSPENSION_POINT")
check(available:find("local QUESTS_PER_YIELD = 24",1,true)~=nil,
      "V05_ORIGINAL_24_THRESHOLD_PINNED")
check(available:find("ThreadLib.Thread(_CalculateAvailableQuests",1,true)~=nil,
      "V06_ORIGINAL_ASYNC_THREAD_LAUNCH_ANCHORED")
check(available:find("QuestieDB.QueryQuestSingle(questId, \"childQuests\")",1,true)~=nil,
      "V07_ORIGINAL_REAL_QUEST_QUERY_USED_DOWNSTREAM")
check(available:find("QuestieDB.activeChildQuests = {}",1,true)~=nil,
      "V08_REAL_DERIVED_CACHE_RESET_IN_CALCULATOR")
check(comms:find("if (not QuestieDB.QuestPointers[questId]) then",1,true)~=nil,
      "V09_ORIGINAL_COMMS_QUEST_POINTER_GUARD")
check(comms:find('zoneOrSort = QuestieDB.QueryQuestSingle(questId, "zoneOrSort"),',1,true)~=nil,
      "V10_ORIGINAL_COMMS_SEPARATE_ZONE_QUERY")
check(tracker:find('QuestieDB.QueryItemSingle(itemId, "class") == 12',1,true)~=nil,
      "V11_ORIGINAL_TRACKER_ITEM_QUERY_ANCHORED")
check(available:find("availableQuests[questId] = true",1,true)~=nil,
      "V12_ORIGINAL_AVAILABLE_DISPLAY_CACHE_ANCHORED")

local f=fixture()
check(f.sourcePointer()==old.ptr,"V13_START_OLD_GLOBAL_POINTERS")
f.step()
check(coroutine.status(f.thread)=="suspended",
      "V14_ORIGINAL_LOOP_YIELDS_AFTER_THRESHOLD")
check(#f.events==25 and f.missing()==0,
      "V15_FIRST_25_OLD_QUERIES_ALL_COHERENT")
check(f.events[1].zone==1 and f.events[25].zone==1,
      "V16_FIRST_25_FROM_OLD_QUERY")
local firstEvents=f.events
f.setCurrent("NEW")
check(f.sourcePointer()==new.ptr,
      "V17_GLOBAL_QUEST_POINTER_SWAPPED_WHILE_YIELDED")
f.step()
check(coroutine.status(f.thread)=="suspended",
      "V18_SECOND_ORIGINAL_YIELD")
check(#firstEvents==50 and f.missing()==25,
      "V19_OLD_POINTER_IDS_NEW_QUERY_MISSES_25")
check(firstEvents[26].current=="NEW" and firstEvents[26].zone==nil,
      "V20_MISALIGNED_FIRST_RESUMED_QUEST")
f.step()
check(coroutine.status(f.thread)=="dead",
      "V21_ORIGINAL_LOOP_FINISHED_AFTER_SWAP")
check(#f.events==52 and f.missing()==27,
      "V22_REMAINING_27_OLD_ID_NEW_QUERY_MISMATCHES")
check(f.events[52].id<=52 and f.events[52].zone==nil,
      "V23_SOURCE_LOCAL_OLD_POINTERS_STILL_ENUMERATED")
local originalOld=fixture()
originalOld.step();originalOld.step();originalOld.step()
check(#originalOld.events==52 and originalOld.missing()==0,
      "V24_STABLE_OLD_GENERATION_HAS_NO_MISSING_LOOKUPS")
check(originalOld.events[52].zone==1,
      "V25_STABLE_OLD_FINAL_ZONE_CORRECT")
local restart=fixture()
restart.setCurrent("NEW")
restart.step();restart.step();restart.step()
check(#restart.events==52 and restart.missing()==0,
      "V26_FRESH_NEW_POINTERS_NEW_QUERY_COHERENT")
check(restart.events[1].id==101 and restart.events[52].id==152,
      "V27_FRESH_NEW_POINTERS_EXCLUDE_OLD_IDS")
-- Comms original expression guard and lookup, under a synthetic swap.
local pointerExpression="QuestieDB.QuestPointers[questId]"
local queryExpression='QuestieDB.QueryQuestSingle(questId, "zoneOrSort")'
check(comms:find(pointerExpression,1,true)~=nil,
      "V28_COMMS_POINTER_EXPRESSION_AUTHENTIC")
check(comms:find(queryExpression,1,true)~=nil and
      comms:find("if entry.zoneOrSort > 0 then",1,true)~=nil,
      "V29_COMMS_QUERY_AND_ZONE_COMPARE_AUTHENTIC")
local c={QuestPointers=old.ptr}
c.QueryQuestSingle=function(id,key)
    return old.data[id] and old.data[id][key]
end
local ce={QuestieDB=c}
setmetatable(ce,{__index=_G})
local commsProbe=compile("return function(questId)\n"..
    "if not ("..pointerExpression..") then return 'MISSING' end\n"..
    "local zone="..queryExpression.."\n"..
    "if zone > 0 then return 'ZONE' end\nreturn 'OTHER'\nend",ce)
check(commsProbe(1)=="ZONE",
      "V30_MATCHING_OLD_QUEST_COMMS_QUERY")
c.QuestPointers=new.ptr
local mismatchOk,mismatchError=pcall(commsProbe,101)
check(not mismatchOk and tostring(mismatchError):find("nil",1,true)~=nil,
      "V31_NEW_PTR_OLD_QUERY_CAN_THROW_AT_ZONE_COMPARE")
c.QueryQuestSingle=function(id,key)
    return new.data[id] and new.data[id][key]
end
check(commsProbe(101)=="ZONE",
      "V32_MATCHING_NEW_COMMS_QUERY_RECOVERS")
c.QuestPointers=old.ptr
local ok,err=pcall(commsProbe,1)
check(not ok and tostring(err):find("nil",1,true)~=nil,
      "V33_OLD_PTR_NEW_QUERY_CAN_THROW_AT_ZONE_COMPARE")
local safe=fixture()
local safeEpoch=1
local safeActiveEpoch=safeEpoch
safe.step()
safeEpoch=2
check(safeEpoch~=safeActiveEpoch and
      coroutine.status(safe.thread)=="suspended",
      "V34_MODEL_SOURCE_EPOCH_CHECK_DETECTS_STALE_COROUTINE")
local published=old
if safeEpoch==safeActiveEpoch then published=new end
check(published==old,
      "V35_MODEL_ABORT_KEEPS_OLD_GENERATION_PUBLISHED")
local newWorker=fixture()
newWorker.step();newWorker.step();newWorker.step()
check(newWorker.missing()==0,
      "V36_NEW_TASK_WITH_STABLE_GENERATION_COMPLETES")
check(newWorker.events[1].id==1 and newWorker.events[52].id==52,
      "V37_STABLE_TASK_SOURCE_PTR_IDS_COHERENT")
check(comms:find("for questId, data in pairs(QuestLogCache.questLog_DO_NOT_MODIFY) do",1,true)~=nil,
      "V38_COMMS_ORIGINAL_ITERATES_QUESTLOG")
check(available:find("QuestieMap:UnloadQuestFrames(questId)",1,true)~=nil,
      "V39_AVAILABLE_QUESTS_HAS_DERIVED_FRAME_DISPOSAL")
check(available:find("QuestieTooltips:RemoveQuest(questId)",1,true)~=nil,
      "V40_AVAILABLE_QUESTS_HAS_TOOLTIP_DERIVED_CACHE")
assert(checkCount==40,"G08_AVAILABLE_COMMS_TEST_CENSUS_CHANGED")
print("PUBLIC G08 PART43 AVAILABLE QUESTS YIELD AND COMMS PAIR: 40/40 PASS")
print("PUBLIC G08 ORIGINAL FRAGMENT WITNESS: actual 335 AvailableQuests pointer capture and yielded iteration can enumerate old pointer IDs while an invented new query handle returns missing fields.")
print("PUBLIC G08 COMMS FRAGMENT WITNESS: original pointer and zone query expressions are distinct; constructed mismatched values can return missing or fail on a nil zone comparison.")
print("PUBLIC G08 NOT ACCEPTED: only authentic source fragments executed, not complete AvailableQuests/QuestieComms; quest callbacks, data, query handles and epoch coordinator fictional; no native scheduling, stream ownership, disk/relog or ZIP/install/merge/release.")
