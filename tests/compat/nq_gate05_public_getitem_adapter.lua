-- Part41 G05/G07 PUBLIC-SAFE contract: actual pinned-335 GetItem adapter.
-- Original function extracted without changing its body; invented records only.
-- This is NOT a server item ownership/eligibility audit or full GetQuest test.
local root=assert(os.getenv("NQ_G05_SOURCE_ROOT"),"G05_PINNED_PUBLIC_SOURCE_REQUIRED")
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"),"G05_MISSING_PINNED_FILE")
    local s=assert(f:read("*a"))
    f:close()
    return s
end
local dbSource=read("Database/QuestieDB.lua")
local itemSource=read("Database/itemDB.lua")
local questSource=read("Database/questDB.lua")
local marker="function QuestieDB:GetItem(itemId)"
local from=assert(dbSource:find(marker,1,true),"G05_GETITEM_SOURCE_MISSING")
assert(not dbSource:find(marker,from+#marker,true),"G05_GETITEM_DUPLICATE")
local after=assert(dbSource:find("\n---@param questId number",from+#marker,true),
    "G05_GETITEM_BOUNDARY_CHANGED")
local original=dbSource:sub(from,after-1)
assert(original:find("local sources = item.Sources",1,true),
    "G05_SOURCE_ASSEMBLY_MISSING")
assert(questSource:find("['startedBy'] = 2",1,true),
    "G05_QUEST_FORWARD_SCHEMA_CHANGED")
assert(questSource:find("['sourceItemId'] = 11",1,true),
    "G05_QUEST_GRANTED_ITEM_SCHEMA_CHANGED")
assert(itemSource:find("['startQuest'] = 5",1,true),
    "G05_ITEM_REVERSE_SCHEMA_CHANGED")

QuestieDB={}
QuestieLoader={
    ImportModule=function(_,name)
        assert(name=="QuestieDB","G05_UNEXPECTED_SCHEMA_IMPORT")
        return QuestieDB
    end,
}
assert(loadfile(root.."/Database/itemDB.lua"))()
assert(QuestieDB.itemKeys.startQuest==5 and
    QuestieDB.itemCompilerTypes.startQuest=="u24" and
    QuestieDB.itemKeysReversed[5]=="startQuest" and
    QuestieDB._itemAdapterQueryOrder[5]=="startQuest",
    "G05_ITEM_START_KEY_OR_CODEC_DRIFT")
local startCount=0
for _,name in ipairs(QuestieDB.itemCompilerOrder) do
    if name=="startQuest" then startCount=startCount+1 end
end
assert(startCount==1,"G05_STARTQUEST_ORDER_CHANGED")

local queryCount,debugCount=0,0
local rows={}
local function record(fields)
    local row={}
    for name,value in pairs(fields) do
        local index=assert(QuestieDB.itemKeys[name],"G05_UNKNOWN_FIXTURE_FIELD")
        row[index]=value
    end
    return row
end
local Q,I,N1,N2,N3,O1,O2=991001,991002,991003,991004,991005,991006,991007
rows[I]=record({name="invented quest starter",startQuest=Q})
rows[I+1]=record({npcDrops={N1},vendors={N2},name="invented monster sources"})
rows[I+2]=record({objectDrops={O1},name="invented object source"})
rows[I+3]=record({npcDrops={N1,N3},vendors={N2},
    objectDrops={O1,O2},startQuest=Q,name="invented mixed"})
rows[I+4]=record({itemDrops={I},startQuest=Q,name="invented item source"})
rows[I+5]=record({questRewards={Q+1},relatedQuests={Q+2},name="invented related"})
rows[I+6]=record({name="invented ordinary item"})
rows[I+7]=record({name="invented blacklisted item",startQuest=Q+2})
_QuestieDB={itemCache={}}
QuestieCorrections={questItemBlacklist={[I+7]=true}}
Questie={DEBUG_CRITICAL="CRITICAL",Debug=function() debugCount=debugCount+1 end}
QuestieDB.QueryItem=function(id,order)
    assert(order==QuestieDB._itemAdapterQueryOrder,"G05_ADAPTER_QUERY_ORDER_DRIFT")
    queryCount=queryCount+1
    return rows[id]
end
local loader=(loadstring or load)
assert(loader(original,"=pinned_public_GetItem"))()

local function sourceCount(item,expected)
    assert(type(item.Sources)=="table","G05_SOURCE_TABLE_MISSING")
    assert(#item.Sources==#expected,"G05_SOURCE_COUNT_MISMATCH")
    local actual={}
    for _,src in ipairs(item.Sources) do
        assert(type(src.Id)=="number" and
            (src.Type=="monster" or src.Type=="object"),
            "G05_SOURCE_TYPE_UNKNOWN")
        local key=src.Type..":"..src.Id
        actual[key]=(actual[key] or 0)+1
    end
    for _,entry in ipairs(expected) do
        local key=entry[1]..":"..entry[2]
        assert(actual[key] and actual[key]>0,"G05_SOURCE_LINEAGE_MISMATCH")
        actual[key]=actual[key]-1
    end
    for _,count in pairs(actual) do
        assert(count==0,"G05_EXTRA_SOURCE")
    end
end
local tests={
    function()
        local before=queryCount
        assert(QuestieDB:GetItem(nil)==nil and queryCount==before,
            "G05_NIL_ID_MUST_NOT_QUERY")
    end,
    function()
        local before=queryCount
        assert(QuestieDB:GetItem(0)==nil and queryCount==before,
            "G05_ZERO_ID_MUST_NOT_QUERY")
    end,
    function()
        local before,debug=queryCount,debugCount
        assert(QuestieDB:GetItem(I+999)==nil and
            queryCount==before+1 and debugCount==debug+1,
            "G05_MISSING_ITEM_RETURNS_NIL")
    end,
    function()
        local item=assert(QuestieDB:GetItem(I))
        assert(item.Id==I and item.startQuest==Q and item.Hidden==nil,
            "G05_REVERSE_STARTQUEST_FIELD_LOST")
        sourceCount(item,{})
    end,
    function()
        sourceCount(assert(QuestieDB:GetItem(I+1)),
            {{"monster",N1},{"monster",N2}})
    end,
    function()
        sourceCount(assert(QuestieDB:GetItem(I+2)),{{"object",O1}})
    end,
    function()
        local item=assert(QuestieDB:GetItem(I+3))
        assert(item.startQuest==Q,"G05_MIXED_REVERSE_START_LOST")
        sourceCount(item,{{"monster",N1},{"monster",N3},
            {"monster",N2},{"object",O1},{"object",O2}})
    end,
    function()
        local item=assert(QuestieDB:GetItem(I+4))
        assert(item.startQuest==Q and item.itemDrops[1]==I,
            "G05_ITEM_DROPS_FIELD_LOST")
        sourceCount(item,{})
    end,
    function()
        local item=assert(QuestieDB:GetItem(I+5))
        assert(item.relatedQuests[1]==Q+2 and item.questRewards[1]==Q+1,
            "G05_RELATED_FIELDS_LOST")
        sourceCount(item,{})
    end,
    function()
        local item=assert(QuestieDB:GetItem(I+3))
        assert(item.startQuest==Q and item.Id~=Q and
            item.npcDrops[1]==N1 and item.objectDrops[1]==O1,
            "G05_STARTQUEST_VS_LOOT_LINEAGE_CONFUSED")
    end,
    function()
        local item=assert(QuestieDB:GetItem(I+7))
        assert(item.Hidden==true and item.startQuest==Q+2,
            "G05_BLACKLIST_SOURCE_ADAPTER")
    end,
    function()
        local cached={Id=I+8,Sources={},startQuest=Q+4}
        _QuestieDB.itemCache[I+8]=cached
        local before=queryCount
        assert(QuestieDB:GetItem(I+8)==cached and queryCount==before,
            "G05_CACHED_ADAPTER_BYPASS")
    end,
    function()
        local item=assert(QuestieDB:GetItem(I+6))
        assert(item.startQuest==nil,"G05_NO_INVENTED_STARTQUEST")
        sourceCount(item,{})
    end,
    function()
        assert(QuestieDB.itemKeys.startQuest==5 and
            QuestieDB.itemCompilerTypes.startQuest=="u24" and
            QuestieDB.itemKeysReversed[5]=="startQuest",
            "G05_REVERSE_CODEC_INVARIANT")
    end,
}
assert(#tests==14,"G05_CONTROL_LIST_CHANGED")
local executed=0
for i,check in ipairs(tests) do
    check()
    executed=executed+1
    assert(executed==i,"G05_CONTROL_ORDER_CHANGED")
end
assert(executed==14,"G05_NOT_ALL_CONTROLS_EXECUTED")
print("PUBLIC G05 PINNED GETITEM ADAPTER CONTROLS: 14/14 PASS")
print("PUBLIC G05 LIMIT: item startQuest is separate from item drops/vendors; GetItem Sources excludes itemDrops in this code path.")
print("PUBLIC G05 NOT ACCEPTED: complete quest forward/reverse consistency, eligibility, server loot/IP links, native 3.3.5a client or all-writer provenance.")
