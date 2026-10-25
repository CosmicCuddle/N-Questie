-- 3.3.5a item-starter proof: real pinned Questie compiler/stream, fictional data only.
-- Never import user-private SQL, real client data, character data or loot mappings.
tremove = table.remove
unpack = unpack or table.unpack
local function positiveBand(a,b)
    local out,place=0,1
    for _=1,32 do
        if a%2==1 and b%2==1 then out=out+place end
        a,b,place=math.floor(a/2),math.floor(b/2),place*2
    end
    return out
end
bit={
    band=positiveBand,
    lshift=function(n,s)return (n*2^s)%4294967296 end,
    rshift=function(n,s)return math.floor((n%4294967296)/2^s)end,
}
local modules,callbacks={},{}
QuestieLoader={
    CreateModule=function(_,name)
        assert(not modules[name],"duplicate module "..name)
        modules[name]={}
        return modules[name]
    end,
    ImportModule=function(_,name)
        assert(modules[name],"missing module "..name)
        return modules[name]
    end,
}
for _,name in ipairs({"QuestieDB","QuestieLib","l10n"}) do
    QuestieLoader:CreateModule(name)
end
QuestieCompat={Is335=true,WOW_PROJECT_ID=2,
    RegisterCorrection=function(kind,fn)callbacks[kind]=fn end}
Questie={IsSoD=false,IsTBC=false,IsWotlk=true,
    db={profile={debugEnabled=false},global={}}}
function Questie:Error(...)error("scratch Questie error",0)end

assert(loadfile("Modules/QuestieStream.lua"))()
assert(loadfile("Database/questDB.lua"))()
assert(loadfile("Database/itemDB.lua"))()
local db=QuestieLoader:ImportModule("QuestieDB")
db.npcKeys={questStarts=10,questEnds=11}
db.objectKeys={questStarts=2,questEnds=3}
db.questData={}
db.npcData={[7716]={[1]="Fictional finisher"},
    [1868]={[1]="Fictional objective"}}
db.objectData={}
db.itemData={[6611]={[db.itemKeys.name]="Fictional starter token"}}
NQuestieCustomQuestData={revision=10,quests={
    [920245]={
        name="Fictional Item Quest",requiredLevel=12,questLevel=16,
        zoneOrSort=130,requiredRaces=0,questFlags=8,
        startedByNpcs={},startedByItems={6611},
        finishedByNpcs={7716},killNpcs={1868}
    },
}}
assert(loadfile("Compat/NQuestieCustomQuestLoader.lua"))()
assert(callbacks.questData and callbacks.npcData and callbacks.itemData)
local itemUpdates=callbacks.itemData() -- item FIRST tests ordering
local npcUpdates=callbacks.npcData()
local questUpdates=callbacks.questData()
local q=assert(questUpdates[920245],"synthetic item quest denied")
local iq=assert(itemUpdates[6611],"synthetic item start absent")
local tests=0
local function check(label,value)
    tests=tests+1
    assert(value,"FAIL item-starter codec "..tests.." "..label)
    print("PASS ITEM-START "..tests.." "..label)
end
check("quest has only item starter slot",q[db.questKeys.startedBy] and
    #q[db.questKeys.startedBy][1]==0 and
    q[db.questKeys.startedBy][2]==nil and
    q[db.questKeys.startedBy][3][1]==6611)
check("reverse item startQuest scalar emitted",
    iq[db.itemKeys.startQuest]==920245)
check("finisher NPC reverse link preserved",npcUpdates[7716] and
    npcUpdates[7716][db.npcKeys.questEnds][1]==920245)
check("no fake NPC starter reverse link",npcUpdates[7716] and
    (npcUpdates[7716][db.npcKeys.questStarts]==nil or
     #npcUpdates[7716][db.npcKeys.questStarts]==0))
check("item source has no invented drops",db.itemData[6611][db.itemKeys.npcDrops]==nil and
    db.itemData[6611][db.itemKeys.objectDrops]==nil)

assert(loadfile("Database/compiler.lua"))()
local compiler=QuestieLoader:ImportModule("DBCompiler")
local function drive(fn)
    local thread=coroutine.create(fn)
    for _=1,256 do
        local ok,result=coroutine.resume(thread)
        assert(ok,tostring(result))
        if coroutine.status(thread)=="dead" then return result end
    end
    error("compiler/readback coroutine exceeded safety limit")
end
local bin,ptrs=compiler:CompileTable(
    {[920245]=q},db.questCompilerTypes,db.questCompilerOrder,db.questKeys)
check("real Questie quest compiler produced staged bytes",
    type(bin)=="string" and #bin>0 and type(ptrs)=="string" and #ptrs>0)
local questHandle=drive(function()
    return compiler:GetDBHandle(bin,ptrs,
        compiler:BuildSkipMap(db.questCompilerTypes,db.questCompilerOrder),
        db.questKeys,nil)
end)
local decoded=questHandle.QuerySingle(920245,"startedBy")
check("unmasked actual decoder preserves item startedBy[3]",
    type(decoded)=="table" and decoded[1]==nil and
    decoded[2]==nil and decoded[3] and
    #decoded[3]==1 and decoded[3][1]==6611)
check("unmasked decoder does not invent NPC starter",
    questHandle.QuerySingle(920245,"finishedBy")[1][1]==7716)
questHandle.stream:finished()

-- Apply only the proposed correction to this imaginary item before using
-- Questie's real item codec. Never change a saved game or upstream source.
db.itemData[6611][db.itemKeys.startQuest]=iq[db.itemKeys.startQuest]
local itemBin,itemPtrs=compiler:CompileTable(
    db.itemData,db.itemCompilerTypes,db.itemCompilerOrder,db.itemKeys)
local itemHandle=drive(function()
    return compiler:GetDBHandle(itemBin,itemPtrs,
        compiler:BuildSkipMap(db.itemCompilerTypes,db.itemCompilerOrder),
        db.itemKeys,nil)
end)
check("actual item encoder/decoder preserves reverse startQuest",
    itemHandle.QuerySingle(6611,"startQuest")==920245)
check("actual item decoder does not invent loot source",
    itemHandle.QuerySingle(6611,"npcDrops")==nil and
    itemHandle.QuerySingle(6611,"objectDrops")==nil)
itemHandle.stream:finished()
assert(tests==10,"wrong item starter test count")
print("ITEM-START REAL QUESTIE SOURCE RESULT: 10/10 PASS")
