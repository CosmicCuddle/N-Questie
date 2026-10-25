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
    itemKeys={startQuest=5},
    questData={
        [437]={[Q.name]="Pre-existing prerequisite"},
        [920010]={[Q.name]="An existing quest"},
    },
    npcData={
        [7711]={[1]="Known starter",[N.questStarts]={23},[N.questEnds]={24}},
        [7712]={[1]="Synthetic target"},
        [7715]={[1]="Invented independent quest starter"},
        [7716]={[1]="Invented independent quest finisher"},
        [2121]={[1]="Public baseline NPC"},
        [1868]={[1]="Public baseline target"},
        [1869]={[1]="Public baseline target"},
    },
    objectData={
        [8811]={[1]="Known game object",[G.questStarts]={34}},
        [8816]={[1]="Invented independent GO starter"},
        [8817]={[1]="Invented independent GO finisher"},
    },
    itemData={
        [6611]={[1]="Synthetic trade item"}, -- deliberately has no drop coordinates
        [6612]={[1]="Synthetic dual-mode starter item"},
        [6613]={[1]="Synthetic already-assigned starter item",[5]=920010},
        [6614]={[1]="Synthetic contested item source"},
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
-- GameObject quest-start and quest-end arrays have the same u8 capacity.
-- These synthetic sources exercise both limits independently of NPC indexes.
db.objectData[8812] = {[1]="Full GO starter", [G.questStarts]=fullStarts}
db.objectData[8813] = {[1]="Nearly full GO starter", [G.questStarts]=almostFullStarts}
db.objectData[8814] = {[1]="Full GO finisher", [G.questEnds]=fullStarts}
db.objectData[8815] = {[1]="Nearly full GO finisher", [G.questEnds]=almostFullStarts}
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
    [920033]=rec({startedByNpcs={},startedByGameObjects={8812}}), -- full GO start must reject
    [920034]=rec({startedByNpcs={},startedByGameObjects={8813}}), -- final GO start slot
    [920035]=rec({finishedByNpcs={},finishedByGameObjects={8814}}), -- full GO end must reject
    [920036]=rec({finishedByNpcs={},finishedByGameObjects={8815}}), -- final GO end slot
    [920037]=rec({zoneOrSort=-32768}), -- invalid s16 offset: WriteShort(-1)
    [920038]=rec({zoneOrSort=-32767}), -- lowest encodable negative sort
    [920039]=rec({zoneOrSort=32767}), -- retained accepted upper bound
    [920040]=rec({name="nil"}), -- u8string read sentinel; must fail closed
    [920041]=rec({name="Nil"}), -- distinct ordinary name must survive
    [920042]=rec({zoneOrSort=32768}), -- still rejected by loader upper bound
    [920043]=rec({startedByNpcs={7715},finishedByNpcs={7716}}),
    [920044]=rec({startedByNpcs={},finishedByNpcs={},
        startedByGameObjects={8816},finishedByGameObjects={8817}}),
    [920045]=rec({startedByNpcs={},startedByItems={6611},
        finishedByNpcs={7716}}), -- item-only starter, NPC finisher
    [920046]=rec({startedByNpcs={7715},startedByItems={6613}}),
    [920047]=rec({startedByNpcs={7711},startedByItems={6614}}),
    [920048]=rec({startedByNpcs={},startedByItems={6614}}),
    [920049]=rec({startedByNpcs={},startedByItems={9999}}),
    [920050]=rec({startedByNpcs={},startedByItems={6611,6611}}),
    [920051]=rec({startedByNpcs={},startedByItems={[1]=6611,[3]=6612}}),
    [920052]=rec({startedByNpcs={7715},startedByItems={6612},
        finishedByNpcs={7716}}), -- mixed NPC + item starters
    [920053]=rec({startedByNpcs={},startedByItems={16777216}}),
}}
assert(loadfile(path))()
assert(callbacks.questData and callbacks.npcData and callbacks.objectData
    and callbacks.itemData)
-- Reverse callbacks first: prove callback-order independence without changing
-- the source tables or adding any real server/world references.
local itemUpdates = callbacks.itemData()
local npcUpdates = callbacks.npcData()
local goUpdates = callbacks.objectData()
local quests = callbacks.questData()
local count=0
local function check(message,condition)
    count=count+1
    assert(condition,"FAIL: "..message)
    print("PASS "..string.format("%02d",count).." "..message)
end
-- The approved plan is visited with pairs(). Multiple legitimate invented
-- quests can use one NPC; reverse lists therefore have no stable first ID.
-- Assert membership, not an incidental order chosen by Lua table hashing.
local function hasId(ids,want)
    if type(ids)~="table" then return false end
    for _,id in ipairs(ids) do
        if id==want then return true end
    end
    return false
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
check("full GO start index rejects entire quest and preserves 255 links",
    quests[920033]==nil and goUpdates[8812]==nil and
    #db.objectData[8812][G.questStarts]==255)
check("254-entry GO start index accepts exactly one new link",
    quests[920034] and goUpdates[8813] and
    #goUpdates[8813][G.questStarts]==255 and
    goUpdates[8813][G.questStarts][255]==920034 and
    goUpdates[8813][G.questStarts][1]==300001)
check("full GO end index rejects entire quest and preserves 255 links",
    quests[920035]==nil and goUpdates[8814]==nil and
    #db.objectData[8814][G.questEnds]==255)
check("254-entry GO end index accepts exactly one new link",
    quests[920036] and goUpdates[8815] and
    #goUpdates[8815][G.questEnds]==255 and
    goUpdates[8815][G.questEnds][255]==920036 and
    goUpdates[8815][G.questEnds][1]==300001)
check("s16 zoneOrSort -32768 underflow input rejected",quests[920037]==nil)
check("s16 zoneOrSort -32767 boundary retained",
    quests[920038] and quests[920038][Q.zoneOrSort]==-32767)
check("s16 zoneOrSort upper accepted boundary retained",
    quests[920039] and quests[920039][Q.zoneOrSort]==32767)
check("literal nil u8string quest-name sentinel rejected",quests[920040]==nil)
check("case-distinct Nil quest name stays valid",
    quests[920041] and quests[920041][Q.name]=="Nil")
check("zoneOrSort above existing upper bound still rejected",quests[920042]==nil)
check("GO rejection does not create unrelated NPC reverse links",
    npcUpdates[7711] and
    not (function()
        for _, v in ipairs(npcUpdates[7711][N.questStarts]) do
            if v == 920035 then return true end
        end
        for _, v in ipairs(npcUpdates[7711][N.questEnds]) do
            if v == 920033 then return true end
        end
        return false
    end)())
check("public 2001 remains present",quests[2001] and quests[2001][Q.name]=="Ravenclaw Cleanup")
check("public 2001 prereq preserved",quests[2001] and quests[2001][Q.preQuestSingle][1]==437)
check("public 2001 kill goals preserved",quests[2001] and
    quests[2001][Q.objectives][1][1][1]==1868 and
    quests[2001][Q.objectives][1][2][1]==1869)
check("public 2001 has no additional starter slot",quests[2001] and quests[2001][Q.startedBy][2]==nil
    and quests[2001][Q.startedBy][3]==nil)
check("public 2001 has no additional finisher slot",quests[2001] and quests[2001][Q.finishedBy][2]==nil)
check("public 2001 kill-only objective has no extra slots",quests[2001] and
    quests[2001][Q.objectives][2]==nil and quests[2001][Q.objectives][3]==nil)
-- Distinct invented NPC IDs catch reverse-index start/end swaps that public
-- quest 2001 cannot reveal (it starts and ends at the same NPC).
check("different NPC starter and finisher preserved in quest row",
    quests[920043] and quests[920043][Q.startedBy][1][1]==7715 and
    quests[920043][Q.finishedBy][1][1]==7716)
check("independent NPC starter updates only questStarts",
    npcUpdates[7715] and
    hasId(npcUpdates[7715][N.questStarts],920043) and
    hasId(npcUpdates[7715][N.questStarts],920052) and
    not hasId(npcUpdates[7715][N.questStarts],920046) and
    (not npcUpdates[7715][N.questEnds] or #npcUpdates[7715][N.questEnds]==0))
check("independent NPC finisher updates only questEnds",
    npcUpdates[7716] and
    hasId(npcUpdates[7716][N.questEnds],920043) and
    hasId(npcUpdates[7716][N.questEnds],920045) and
    hasId(npcUpdates[7716][N.questEnds],920052) and
    (not npcUpdates[7716][N.questStarts] or #npcUpdates[7716][N.questStarts]==0))
-- GameObject direction is independently testable: the earlier public and
-- synthetic same-GameObject cases cannot reveal swapped reverse roles.
check("different GO starter and finisher preserved in quest row",
    quests[920044] and quests[920044][Q.startedBy][2][1]==8816 and
    quests[920044][Q.finishedBy][2][1]==8817)
check("independent GO starter updates only questStarts",
    goUpdates[8816] and goUpdates[8816][G.questStarts] and
    goUpdates[8816][G.questStarts][1]==920044 and
    (not goUpdates[8816][G.questEnds] or #goUpdates[8816][G.questEnds]==0))
check("independent GO finisher updates only questEnds",
    goUpdates[8817] and goUpdates[8817][G.questEnds] and
    goUpdates[8817][G.questEnds][1]==920044 and
    (not goUpdates[8817][G.questStarts] or #goUpdates[8817][G.questStarts]==0))
check("vanilla NPC start index retained",npcUpdates[7711] and npcUpdates[7711][N.questStarts][1]==23)
check("vanilla NPC end index retained",npcUpdates[7711] and npcUpdates[7711][N.questEnds][1]==24)
check("public NPC starter 2001 indexed",npcUpdates[2121] and npcUpdates[2121][N.questStarts][1]==2001)
check("client item-source coordinates never invented",quests[920003] and db.itemData[6611][2]==nil)
-- The item starter codec uses quest.startedBy[3] and item.startQuest;
-- itemObjectives uses quest.objectives[3] and is a SEPARATE relationship.
check("item-only starter quest admitted",quests[920045] and
    quests[920045][Q.startedBy][3][1]==6611 and
    #quests[920045][Q.startedBy][1]==0)
check("item-start updates one-to-one scalar source",itemUpdates[6611] and
    itemUpdates[6611][db.itemKeys.startQuest]==920045)
check("item-only starter retains NPC finisher",quests[920045] and
    quests[920045][Q.finishedBy][1][1]==7716)
check("item objective is independent of item starter",quests[920003] and
    quests[920003][Q.objectives][3][1][1]==6611 and
    quests[920003][Q.startedBy][3]==nil)
check("preclaimed item start is not overwritten",quests[920046]==nil and
    itemUpdates[6613]==nil and db.itemData[6613][db.itemKeys.startQuest]==920010)
check("contested item rejects both proposed quests",quests[920047]==nil and
    quests[920048]==nil and itemUpdates[6614]==nil)
check("unknown item starter rejected",quests[920049]==nil)
check("duplicate item source ID rejected",quests[920050]==nil)
check("sparse item-source list rejected",quests[920051]==nil)
check("joint NPC+item starter preserved",quests[920052] and
    quests[920052][Q.startedBy][1][1]==7715 and
    quests[920052][Q.startedBy][3][1]==6612 and
    itemUpdates[6612][db.itemKeys.startQuest]==920052)
check("item-starter u24 overflow rejected",quests[920053]==nil)
check("previous public quest has no item source assignment",itemUpdates[2121]==nil and
    itemUpdates[1868]==nil)
check("rejected item-source quests do not leak NPC reverse links",
    not (function()
        for _, list in pairs(npcUpdates) do
            for _, field in ipairs({N.questStarts,N.questEnds}) do
                for _, questId in ipairs(list[field] or {}) do
                    if questId==920046 or questId==920047 or questId==920048 then
                        return true
                    end
                end
            end
        end
        return false
    end)())
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
