-- Synthetic-only offline regression tests for the custom quest loader.
-- Uses invented IDs and the already-public quest 2001 fixture; no server data.
local path = assert(os.getenv("NQ_LOADER_PATH"), "NQ_LOADER_PATH is required")
local Q = {name=1,startedBy=2,finishedBy=3,requiredLevel=4,questLevel=5,
    requiredRaces=6,requiredClasses=7,objectives=10,preQuestGroup=12,
    preQuestSingle=13,exclusiveTo=16,zoneOrSort=17,
    nextQuestInChain=22,questFlags=23,specialFlags=24}
local N = {questStarts=10,questEnds=11}
local G = {questStarts=2,questEnds=3}
local db = {
    questKeys=Q,npcKeys=N,objectKeys=G,
    questData={
        [437]={[Q.name]="Pre-existing prerequisite"},
        [920010]={[Q.name]="An existing quest"},
    },
    npcData={
        [7711]={[1]="Known starter",[N.questStarts]={23},[N.questEnds]={24}},
        [7712]={[1]="Synthetic target"},
        [2121]={[1]="Public baseline NPC"},
        [1868]={[1]="Public baseline target"},
        [1869]={[1]="Public baseline target"},
    },
    objectData={
        [8811]={[1]="Known game object",[G.questStarts]={34}},
    },
    itemData={
        [6611]={[1]="Synthetic trade item"}, -- deliberately has no drop coordinates
    },
}
-- Boundary fixtures for u8-packed reverse quest-start arrays. They use
-- invented quest IDs and do not alter or infer any real NPC data.
local fullStarts, almostFullStarts = {}, {}
for i = 1, 255 do
    fullStarts[i] = 300000 + i
    if i <= 254 then almostFullStarts[i] = 300000 + i end
end
db.npcData[7713] = {[1]="Full synthetic starter", [N.questStarts]=fullStarts}
db.npcData[7714] = {[1]="Nearly full synthetic starter", [N.questStarts]=almostFullStarts}
local callbacks={}
QuestieLoader={ImportModule=function(_,name)
    assert(name=="QuestieDB")
    return db
end}
QuestieCompat={Is335=true,RegisterCorrection=function(kind,fn) callbacks[kind]=fn end}
local function rec(overrides)
    local v={name="Synthetic only",requiredLevel=20,questLevel=25,
        zoneOrSort=130,requiredRaces=0,questFlags=0,
        startedByNpcs={7711},finishedByNpcs={7711},killNpcs={7712}}
    for k,x in pairs(overrides or {}) do v[k]=x end
    return v
end
local public2001 = {
    name="Ravenclaw Cleanup",requiredLevel=12,questLevel=16,
    zoneOrSort=130,requiredRaces=690,questFlags=8,
    preQuestSingle={437},startedByNpcs={2121},
    finishedByNpcs={2121},killNpcs={1868,1869},
}
NQuestieCustomQuestData={revision=6,quests={
    [2001]=public2001,
    [920001]=rec(),
    [920002]=rec({questLevel=-1}),
    [920003]=rec({killNpcs={},itemObjectives={6611}}),
    [920004]=rec({startedByNpcs={},finishedByNpcs={},
        startedByGameObjects={8811},finishedByGameObjects={8811}}),
    [920005]=rec({requiredClasses=2}),
    [920006]=rec({specialFlags=1}),
    [920007]=rec({exclusiveTo={920008}}),
    [920008]=rec({nextQuestInChain=920022}),
    [920009]=rec({unknownServerCondition=true}),
    [920010]=rec(),
    [920011]=rec({startedByNpcs={9999},finishedByNpcs={9999}}),
    [920012]=rec({killNpcs={},itemObjectives={9998}}),
    [920013]=rec({startedByNpcs={[1]=7711,[3]=7711}}),
    [920014]=rec({startedByNpcs={[1]=7711,unexpected=7711}}),
    [920015]=rec({startedByNpcs={7711,7711}}),
    [920016]=rec({requiredLevel=256}),
    [920017]=rec({questLevel=32768}),
    [920018]=rec({zoneOrSort=-32769}),
    [920019]=rec({requiredRaces=65536}),
    [920020]=rec({questFlags=16777216}),
    [920021]=rec({preQuestSingle={9998}}),
    [920022]=rec({requiredClasses=0}),
    [920023]=rec({noDirectObjectives=true,killNpcs={}}),
    [920024]=rec({killNpcs={}}), -- must not silently autocomplete
    [920025]=rec({specialFlags=2}), -- event bit forbidden
    [920026]=rec({preQuestSingle={920027}}),
    [920027]=rec({preQuestSingle={920026}}), -- cyclic prerequisites
    [920028]=rec({preQuestSingle={920026}}), -- dependent on invalid cycle
    [920029]=rec({startedByNpcs={},startedByGameObjects={9999}}),
    [920030]=rec({startedByNpcs={7711},objectObjectives={8811},
        itemObjectives={6611}}),
    [920031]=rec({startedByNpcs={7713}}), -- full source must reject the quest
    [920032]=rec({startedByNpcs={7714}}), -- one final slot is allowed
}}
assert(loadfile(path))()
assert(callbacks.questData and callbacks.npcData and callbacks.objectData)
-- Reverse callback first: must give consistent outputs independent of registry order.
local npcUpdates = callbacks.npcData()
local goUpdates = callbacks.objectData()
local quests = callbacks.questData()
local count=0
local function check(message,condition)
    count=count+1
    assert(condition,"FAIL: "..message)
    print("PASS "..string.format("%02d",count).." "..message)
end
check("baseline NPC quest accepted",quests[920001]~=nil)
check("scaling quest level preserved",quests[920002] and quests[920002][Q.questLevel]==-1)
check("item objective retained",quests[920003] and
    quests[920003][Q.objectives][3][1][1]==6611)
check("GO starter preserved",quests[920004] and quests[920004][Q.startedBy][2][1]==8811)
check("GO finisher preserved",quests[920004] and quests[920004][Q.finishedBy][2][1]==8811)
check("GO source keeps previous quest",goUpdates[8811] and goUpdates[8811][G.questStarts][1]==34)
check("GO source gains new starter",goUpdates[8811] and goUpdates[8811][G.questStarts][2]==920004)
check("GO source gains finisher",goUpdates[8811] and goUpdates[8811][G.questEnds][1]==920004)
check("class restriction preserved",quests[920005] and quests[920005][Q.requiredClasses]==2)
check("repeatable flag preserved",quests[920006] and quests[920006][Q.specialFlags]==1)
check("approved exclusion preserved",quests[920007] and quests[920007][Q.exclusiveTo][1]==920008)
check("reviewed next-chain preserved",quests[920008] and quests[920008][Q.nextQuestInChain]==920022)
check("unknown server condition rejected",quests[920009]==nil)
check("pre-existing quest ID collision rejected",quests[920010]==nil)
check("unknown starter NPC rejected",quests[920011]==nil and npcUpdates[9999]==nil)
check("unknown item record rejected",quests[920012]==nil)
check("sparse starter array rejected",quests[920013]==nil)
check("unexpected keyed array entry rejected",quests[920014]==nil)
check("duplicate starter ID rejected",quests[920015]==nil)
check("requiredLevel u8 bound",quests[920016]==nil)
check("questLevel s16 bound",quests[920017]==nil)
check("zoneOrSort s16 bound",quests[920018]==nil)
check("requiredRaces u16 bound",quests[920019]==nil)
check("questFlags u24 bound",quests[920020]==nil)
check("dangling prerequisite rejected",quests[920021]==nil)
check("unrestricted class zero supported",quests[920022]~=nil)
check("explicit no-direct-objective case",quests[920023] and quests[920023][Q.objectives]==nil)
check("implicit missing objectives rejected",quests[920024]==nil)
check("unvalidated event flag rejected",quests[920025]==nil)
check("prerequisite cycle rejected",quests[920026]==nil and quests[920027]==nil)
check("dependent of cyclic prerequisite rejected",quests[920028]==nil)
check("unknown GO starter rejected",quests[920029]==nil)
check("mixed objective categories held pending client-order proof",quests[920030]==nil)
check("full NPC reverse index rejects quest before emitting questData",
    quests[920031]==nil and npcUpdates[7713]==nil and
    #db.npcData[7713][N.questStarts]==255)
check("254-entry NPC reverse index accepts exactly one more link",
    quests[920032] and npcUpdates[7714] and
    #npcUpdates[7714][N.questStarts]==255 and
    npcUpdates[7714][N.questStarts][255]==920032)
check("NPC near-limit index preserves its first existing link",
    npcUpdates[7714] and npcUpdates[7714][N.questStarts][1]==300001)
check("public 2001 remains present",quests[2001] and quests[2001][Q.name]=="Ravenclaw Cleanup")
check("public 2001 prereq preserved",quests[2001] and quests[2001][Q.preQuestSingle][1]==437)
check("public 2001 kill goals preserved",quests[2001] and
    quests[2001][Q.objectives][1][1][1]==1868 and
    quests[2001][Q.objectives][1][2][1]==1869)
check("public 2001 has no additional starter slot",quests[2001] and quests[2001][Q.startedBy][2]==nil)
check("public 2001 has no additional finisher slot",quests[2001] and quests[2001][Q.finishedBy][2]==nil)
check("public 2001 kill-only objective has no extra slots",quests[2001] and
    quests[2001][Q.objectives][2]==nil and quests[2001][Q.objectives][3]==nil)
check("vanilla NPC start index retained",npcUpdates[7711] and npcUpdates[7711][N.questStarts][1]==23)
check("vanilla NPC end index retained",npcUpdates[7711] and npcUpdates[7711][N.questEnds][1]==24)
check("public NPC starter 2001 indexed",npcUpdates[2121] and npcUpdates[2121][N.questStarts][1]==2001)
check("client item-source coordinates never invented",quests[920003] and db.itemData[6611][2]==nil)
-- A previously released public custom record must never be modified via
-- its narrow collision exception, even when the raw DB does not contain it.
local function public2001MutationRejected(modify)
    local changed = {}
    for key, value in pairs(public2001) do
        if type(value) == "table" then
            local copied = {}
            for index, id in pairs(value) do copied[index] = id end
            changed[key] = copied
        else
            changed[key] = value
        end
    end
    modify(changed)
    NQuestieCustomQuestData.quests[2001] = changed
    callbacks = {}
    assert(loadfile(path))()
    local result = callbacks.questData()
    NQuestieCustomQuestData.quests[2001] = public2001
    return result[2001] == nil
end
check("2001 class override rejected",public2001MutationRejected(function(q)
    q.requiredClasses = 2
end))
check("2001 exclusion override rejected",public2001MutationRejected(function(q)
    q.exclusiveTo = {437}
end))
check("2001 extra starter rejected",public2001MutationRejected(function(q)
    q.startedByNpcs = {2121,7711}
end))
check("2001 repeatability override rejected",public2001MutationRejected(function(q)
    q.specialFlags = 1
end))
check("2001 extra kill objective rejected",public2001MutationRejected(function(q)
    q.killNpcs = {1868,1869,7712}
end))
print("ALL "..count.." SYNTHETIC CONTRACT CHECKS PASS; Lua client/packer tests pending.")
