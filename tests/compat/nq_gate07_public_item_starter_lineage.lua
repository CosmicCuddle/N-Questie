-- Part40 Gate07 PUBLIC-SAFE synthetic item starter source/renderer lineage.
-- Execute the actual public itemDB schema, extract the exact public GetQuest
-- Starts assignment, and load the real AvailableQuests.lua renderer.
-- Fictional source IDs only; not server/Individual Progression eligibility.
local function read(path)
    local f=assert(io.open(path,"rb"),"G07_REQUIRED_PUBLIC_FILE_MISSING")
    local body=assert(f:read("*a"))
    f:close()
    return body
end
local itemSource=read("Database/itemDB.lua")
local questSchema=read("Database/questDB.lua")
local dbSource=read("Database/QuestieDB.lua")
local rendererSource=read("Modules/Quest/AvailableQuests.lua")
local function one(source,needle,reason)
    local first=assert(source:find(needle,1,true),reason)
    assert(not source:find(needle,first+#needle,true),
        reason.."_DUPLICATE")
    return first
end
local assignmentStart="    local startedBy = QO.startedBy\n    QO.Starts = {\n"
local assignmentEnd="\n    QO.isHidden ="
local from=one(dbSource,assignmentStart,"G07_GETQUEST_STARTS_MISSING")
local to=assert(dbSource:find(assignmentEnd,from+#assignmentStart,true),
    "G07_GETQUEST_STARTS_BOUNDARY")
local assignment=dbSource:sub(from,to-1)
-- Source excerpt is unmodified public GetQuest code, not a reimplemented
-- positional mapping. This does NOT exercise the full GetQuest function.
local mk=assert((loadstring or load)("return function(QO)\n"..assignment..
    "\nreturn QO.Starts\nend","=public_getquest_starts"))()
assert(questSchema:find("['startedBy'] = 2",1,true),
    "G07_QUEST_STARTEDBY_SCHEMA_DRIFT")
assert(questSchema:find("['startedBy'] = \"questgivers\"",1,true),
    "G07_QUEST_STARTS_CODEC_DRIFT")
-- Run the actual ItemDB metadata-only schema, not real item records.
QuestieDB={}
-- The real itemDB.lua imports the DB module through QuestieLoader;
-- install the minimum schema-only stub before executing that source.
QuestieLoader={
    ImportModule=function(_,name)
        assert(name=="QuestieDB","G07_UNEXPECTED_ITEM_SCHEMA_IMPORT")
        return QuestieDB
    end,
}
assert(loadfile("Database/itemDB.lua"))()
assert(QuestieDB.itemKeys.startQuest==5 and
    QuestieDB.itemCompilerTypes.startQuest=="u24",
    "G07_ITEM_REVERSE_FIELD_SCHEMA_DRIFT")
local foundStartQuest=0
for _,field in ipairs(QuestieDB.itemCompilerOrder) do
    if field=="startQuest" then foundStartQuest=foundStartQuest+1 end
end
assert(foundStartQuest==1,"G07_ITEM_START_FIELD_ORDER_DRIFT")
-- The item schema has an independent reverse reference startQuest; a quest's
-- startedBy[3] is not interchangeable with sourceItemId (quest-granted item).
one(questSchema,"['sourceItemId'] = 11","G07_QUEST_SOURCEITEM_SCHEMA_DRIFT")
one(rendererSource,'if quest.Starts["GameObject"] then',
    "G07_RENDERER_GO_PATH_DRIFT")
one(rendererSource,'if (quest.Starts["NPC"]) then',
    "G07_RENDERER_NPC_PATH_DRIFT")
-- Keep this separate from an eligibility guarantee: this renderer has no
-- item pin path; its absence says nothing about quest availability.
local modules={}
QuestieLoader={
    CreateModule=function(_,name)
        modules[name]=modules[name] or {}
        return modules[name]
    end,
    ImportModule=function(_,name)
        assert(modules[name],"G07_REQUIRED_RENDERER_STUB_MISSING")
        return modules[name]
    end,
}
Questie={
    IsSoD=false,DEBUG_INFO="INFO",
    db={profile={availableScale=1.3}},
    ICON_TYPE_AVAILABLE=1,ICON_TYPE_AVAILABLE_GRAY=2,
    ICON_TYPE_REPEATABLE=3,ICON_TYPE_PVPQUEST=4,
    ICON_TYPE_EVENTQUEST=5,ICON_TYPE_SODRUNE=6,
    Debug=function() end,
}
local npc,go={},{}
local drawn,tooltips,routes={},{},{}
local itemQueries=0
modules.ThreadLib={ThreadSimple=function(fn) fn() end}
modules.QuestieDB={
    GetNPC=function(_,id) return npc[id] end,
    GetObject=function(_,id) return go[id] end,
    GetItem=function()
        itemQueries=itemQueries+1
        error("G07_ITEM_MUST_NOT_BECOME_MAP_STARTER")
    end,
    IsActiveEventQuest=function() return false end,
    IsPvPQuest=function() return false end,
    IsTrivial=function() return false end,
}
modules.ZoneDB={
    GetDungeons=function() return {} end,
    GetDungeonLocation=function() return nil end,
}
modules.QuestiePlayer={GetPlayerLevel=function() return 60 end}
modules.QuestieMap={
    DrawWorldIcon=function(_,data,zone,x,y)
        local icon={zone=zone,x=x,y=y,kind=data.Type}
        drawn[#drawn+1]=icon
        return icon
    end,
    DrawWaypoints=function(_,icon,waypoints,zone)
        routes[#routes+1]={icon=icon,zone=zone}
    end,
}
modules.QuestieTooltips={
    RegisterQuestStartTooltip=function(_,questId,name,id,key)
        tooltips[#tooltips+1]={questId=questId,sourceId=id,key=key}
    end,
}
modules.QuestieCorrections={}
modules.QuestieQuestBlacklist={AQWarEffortQuests={}}
modules.IsleOfQuelDanas={quests={}}
modules.QuestieLib={
    GetSpawnDistance=function(a,b)
        local dx,dy=a[1]-b[1],a[2]-b[2]
        return math.sqrt(dx*dx+dy*dy)*100
    end,
}
GetQuestGreenRange=function() return 5 end
assert(loadfile("Modules/Quest/AvailableQuests.lua"))()
local renderer=assert(modules.AvailableQuests.DrawAvailableQuest,
    "G07_REAL_AVAILABLE_RENDERER_NOT_LOADED")
local I,N,G=920901,920902,920903
npc[N]={id=N,name="fictional NPC",spawns={[201]={{22,31}}}}
go[G]={id=G,name="fictional GO",spawns={[202]={{41,16}}}}
local function quest(npcList,goList,itemList)
    local base={[1]=npcList,[2]=goList,[3]=itemList}
    local qo={startedBy=base,sourceItemId=920990}
    local starts=mk(qo)
    return {
        Id=920911,Starts=starts,sourceItemId=qo.sourceItemId,
        requiredLevel=1,level=2,IsRepeatable=false,
    }
end
local function render(q)
    drawn,tooltips,routes={},{},{}
    renderer(q)
    return #drawn,#tooltips,#routes
end
local controls={
    function()
        local q=quest(nil,nil,{I})
        assert(q.Starts.Item[1]==I and q.Starts.NPC==nil
            and q.Starts.GameObject==nil,
            "G07_ITEM_ONLY_FORWARD_MAPPING")
    end,
    function()
        local q=quest({N},nil,{I})
        assert(q.Starts.NPC[1]==N and q.Starts.Item[1]==I,
            "G07_NPC_ITEM_FORWARD_MAPPING")
    end,
    function()
        local q=quest(nil,{G},{I})
        assert(q.Starts.GameObject[1]==G and q.Starts.Item[1]==I,
            "G07_GO_ITEM_FORWARD_MAPPING")
    end,
    function()
        local q=quest({N},{G},{I})
        assert(q.Starts.NPC[1]==N and q.Starts.GameObject[1]==G
            and q.Starts.Item[1]==I,"G07_THREE_KIND_MAPPING")
    end,
    function()
        local q=quest(nil,nil,{I})
        assert(q.sourceItemId~=I and q.Starts.Item[1]==I,
            "G07_SOURCEITEM_IS_NOT_STARTEDBY_ITEM")
    end,
    function()
        local a,b,c=render(quest(nil,nil,{I}))
        assert(a==0 and b==0 and c==0,
            "G07_ITEM_ONLY_NO_FABRICATED_MAP_SOURCE")
    end,
    function()
        local a,b,c=render(quest(nil,nil,{I,I+1}))
        assert(a==0 and b==0 and c==0,
            "G07_MULTIPLE_ITEM_ONLY_NO_FABRICATED_MAP_SOURCE")
    end,
    function()
        local a,b,c=render(quest({N},nil,{I}))
        assert(a==1 and b==1 and c==0 and
            tooltips[1].key=="m_"..N and drawn[1].zone==201,
            "G07_NPC_ITEM_PRESERVES_ONLY_NPC_MAP_PIN")
    end,
    function()
        local a,b,c=render(quest(nil,{G},{I}))
        assert(a==1 and b==1 and c==0 and
            tooltips[1].key=="o_"..G and drawn[1].zone==202,
            "G07_GO_ITEM_PRESERVES_ONLY_GO_MAP_PIN")
    end,
    function()
        local a,b,c=render(quest({N},{G},{I}))
        assert(a==2 and b==2 and c==0 and
            tooltips[1].key=="o_"..G and
            tooltips[2].key=="m_"..N,
            "G07_NPC_GO_ITEM_NO_EXTRA_ITEM_MAP_PIN")
    end,
    function()
        local a,b,c=render(quest({N+10},nil,{I}))
        assert(a==0 and b==0 and c==0,
            "G07_UNRESOLVED_NPC_WITH_ITEM_FAILS_CLOSED")
    end,
    function()
        local a,b,c=render(quest(nil,{G+10},{I}))
        assert(a==0 and b==0 and c==0,
            "G07_UNRESOLVED_GO_WITH_ITEM_FAILS_CLOSED")
    end,
    function()
        local a,b,c=render(quest({N+10},{G},{I}))
        assert(a==1 and b==1 and c==0 and
            tooltips[1].key=="o_"..G,
            "G07_VALID_GO_NOT_MASKED_BY_MISSING_NPC_AND_ITEM")
    end,
    function()
        local a,b,c=render(quest({N},{G+10},{I}))
        assert(a==1 and b==1 and c==0 and
            tooltips[1].key=="m_"..N,
            "G07_VALID_NPC_NOT_MASKED_BY_MISSING_GO_AND_ITEM")
    end,
    function()
        assert(itemQueries==0,"G07_ITEM_RENDERER_LOOKUP_NOT_EXPECTED")
    end,
}
assert(#controls==15,"G07_CONTROL_INVENTORY_CHANGED")
local executed=0
for _,check in ipairs(controls) do
    check()
    executed=executed+1
end
assert(executed==15,"G07_CONTROL_EXECUTION_CHANGED")
print("PUBLIC G07 ITEM STARTER LINEAGE CONTROLS: "..executed.."/15 PASS")
print("PUBLIC G07 LIMIT: item-only source creates no NPC/GO map pin in the tested renderer, NOT an eligibility verdict.")
print("PUBLIC G07 NOT ACCEPTED: complete GetQuest execution, actual item use/start, server IP phase, source integrity, native WoW 3.3.5a UI or SavedVariables.")
