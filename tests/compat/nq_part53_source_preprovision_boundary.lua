-- Public-safe Part53 source-executed negative witness for a missing source row.
-- Invented IDs only. No owner quest data, build/install, or source modifications.
local loaderPath = assert(os.getenv("NQ_PART53_LOADER"), "NQ_PART53_LOADER not set")
local Q = {
    name=1, startedBy=2, finishedBy=3, requiredLevel=4, questLevel=5,
    requiredRaces=6, requiredClasses=7, objectives=10, preQuestGroup=12,
    preQuestSingle=13, exclusiveTo=16, zoneOrSort=17,
    nextQuestInChain=22, questFlags=23, specialFlags=24,
}
local N = {questStarts=10, questEnds=11}
local G = {questStarts=2, questEnds=3}
local inventedQuest, inventedNpc, inventedItem = 910123, 970123, 960123
local checks = 0
local function check(label, truthy)
    checks = checks + 1
    assert(truthy, "FAIL: " .. label)
    print("PASS " .. tostring(checks) .. ": " .. label)
end
local function public2001()
    return {
        name="Ravenclaw Cleanup", requiredLevel=12, questLevel=16,
        zoneOrSort=130, requiredRaces=690, questFlags=8,
        preQuestSingle={437}, startedByNpcs={2121},
        finishedByNpcs={2121}, killNpcs={1868,1869},
    }
end
local function inventedRecord()
    return {
        name="Invented item-goal quest", requiredLevel=20, questLevel=22,
        zoneOrSort=130, requiredRaces=0, questFlags=0,
        startedByNpcs={inventedNpc}, finishedByNpcs={inventedNpc},
        itemObjectives={inventedItem},
    }
end
local function sourceNpc() return {[1]="Invented NPC"} end
local function sourceItem() return {[1]="Invented item, no drop locations"} end

local function scenario(itemBeforeFirstCall, npcBeforeFirstCall, includePublicPrerequisite, includeExistingRaw2001, beforeFirstApproval)
    local npcData = {
        [2121]={[1]="Existing public 2001 giver"},
        [1868]={[1]="Existing public 2001 objective A"},
        [1869]={[1]="Existing public 2001 objective B"},
    }
    if npcBeforeFirstCall then npcData[inventedNpc] = sourceNpc() end
    local rawQuests = (includePublicPrerequisite == false) and {} or {[437]={[Q.name]="Historical prerequisite"}}
    if includeExistingRaw2001 then
        rawQuests[2001] = {[Q.name]="Preexisting upstream 2001 row"}
    end
    local db = {
        questKeys=Q, npcKeys=N, objectKeys=G,
        questData=rawQuests,
        npcData=npcData, objectData={}, itemData={},
    }
    if itemBeforeFirstCall then db.itemData[inventedItem] = sourceItem() end
    local callbacks = {}
    QuestieLoader={ImportModule=function(_,name)
        assert(name == "QuestieDB", "unexpected module import")
        return db
    end}
    QuestieCompat={Is335=true, RegisterCorrection=function(kind, callback)
        assert(callbacks[kind] == nil, "duplicate test callback group")
        callbacks[kind] = callback
    end}
    NQuestieCustomQuestData={revision=9, quests={
        [2001]=public2001(), [inventedQuest]=inventedRecord(),
    }}
    assert(loadfile(loaderPath))()
    -- Synthetic source-provision seam for CS02 review. The hook runs AFTER
    -- original loader callback registration and BEFORE any callback can invoke
    -- memoized approvedQuests(). It does not run inside/modify the loader,
    -- nor simulate a guaranteed post-correction production integration.
    if beforeFirstApproval ~= nil then
        assert(type(beforeFirstApproval) == "function", "invalid preapproval hook")
        beforeFirstApproval(db, callbacks)
    end
    return db, callbacks
end
local function contains(list, id)
    for _, value in ipairs(list or {}) do
        if value == id then return true end
    end
    return false
end

-- This runs UNCHANGED original source, not a reimplemented parser.
local db, callbacks = scenario(false, true)
check("original callbacks exclude itemData source provisioning",
    callbacks.questData and callbacks.npcData and callbacks.objectData and not callbacks.itemData)
local result = callbacks.questData()
check("missing referenced item rejects invented quest", result[inventedQuest] == nil)
check("previously curated quest 2001 survives missing-item rejection",
    result[2001] and result[2001][Q.name] == "Ravenclaw Cleanup")
db.itemData[inventedItem] = sourceItem()
check("late inserted item does not undo cached rejected approval",
    callbacks.questData()[inventedQuest] == nil)
local rejectedNpc = callbacks.npcData()[inventedNpc]
check("late source cannot create orphan NPC reverse index",
    rejectedNpc == nil or (not contains(rejectedNpc[N.questStarts], inventedQuest)
        and not contains(rejectedNpc[N.questEnds], inventedQuest)))

-- A separate loader invocation with sources provisioned BEFORE any
-- approvedQuests() callback demonstrates a necessary ordering condition.
local readyDb, readyCallbacks = scenario(true, true)
local readyNpc = readyCallbacks.npcData() -- reverse-index callback deliberately FIRST
local readyQuest = readyCallbacks.questData()
check("source complete before first approval admits invented quest",
    readyQuest[inventedQuest] and
    readyQuest[inventedQuest][Q.objectives][3][1][1] == inventedItem)
check("early NPC reverse-index callback links the accepted quest",
    readyNpc[inventedNpc] and
    contains(readyNpc[inventedNpc][N.questStarts], inventedQuest) and
    contains(readyNpc[inventedNpc][N.questEnds], inventedQuest))
check("public 2001 remains accepted on early-source path",
    readyQuest[2001] and readyQuest[2001][Q.preQuestSingle][1] == 437)
check("only return corrections, never mutate the original source quest table",
    readyDb.questData[inventedQuest] == nil)

-- A missing starter is independent of whether the required item is present.
local missingNpcDb, missingNpcCallbacks = scenario(true, false)
check("item alone cannot cure missing NPC source",
    missingNpcCallbacks.npcData()[inventedNpc] == nil)
missingNpcDb.npcData[inventedNpc] = sourceNpc()
check("late NPC source remains rejected in the same memoized loader",
    missingNpcCallbacks.questData()[inventedQuest] == nil)

-- Not a positive source-quality verdict: a placeholder item row meets
-- hasId() even though actual drop/position provenance is absent.
check("a placeholder item record is accepted by existence-only check",
    readyQuest[inventedQuest] ~= nil and readyDb.itemData[inventedItem][2] == nil)
-- Closing CS02's equivalent-mutant gap: the protected 2001/437
-- exception must work even when a baseline 437 quest row is absent.
local no437Db, no437Callbacks = scenario(true, true, false)
local no437Quests = no437Callbacks.questData()
check("fixture does not contain public 2001 prerequisite 437",
    no437Db.questData[437] == nil)
check("grandfathered public 2001 remains accepted without raw prerequisite 437",
    no437Quests[2001] and no437Quests[2001][Q.preQuestSingle][1] == 437)
check("no implicit raw 437 source row is written by the validation exception",
    no437Db.questData[437] == nil)
-- Closing CS02's second 2001 collision branch mutation gap: the narrowly
-- grandfathered correction must still supersede a pre-existing raw 2001.
-- This is a synthetic raw row and does NOT alter a real source database.
local occupiedDB, occupiedCallbacks = scenario(true, true, true, true)
local occupiedResult = occupiedCallbacks.questData()
check("synthetic raw quest 2001 collision deliberately exists",
    occupiedDB.questData[2001] and
    occupiedDB.questData[2001][Q.name] == "Preexisting upstream 2001 row")
check("exact public 2001 fingerprint survives pre-existing raw 2001",
    occupiedResult[2001] and
    occupiedResult[2001][Q.name] == "Ravenclaw Cleanup")
check("the protected collision exception does not change the raw source row",
    occupiedDB.questData[2001][Q.name] == "Preexisting upstream 2001 row")
-- CS02-requested optional before-first-approval injection seam. It permits
-- synthetic source batches to be injected AFTER unchanged real loader setup
-- but BEFORE any of its registered callbacks. This is not a production fix.
local injectedCalls = 0
local injectedDb, injectedCallbacks = scenario(false, false, true, false,
    function(sourceDb, registered)
        injectedCalls = injectedCalls + 1
        assert(registered.questData and registered.npcData and registered.objectData)
        assert(sourceDb.npcData[inventedNpc] == nil and
            sourceDb.itemData[inventedItem] == nil)
        sourceDb.npcData[inventedNpc] = sourceNpc()
        sourceDb.itemData[inventedItem] = sourceItem()
    end)
local injectedFirst = injectedCallbacks.objectData() -- callback order variation
local injectedQuests = injectedCallbacks.questData()
local injectedNpc = injectedCallbacks.npcData()
check("preapproval hook executes exactly once before first correction callback",
    injectedCalls == 1)
check("preapproval injected sources admit invented quest regardless of first group",
    injectedQuests[inventedQuest] and
    injectedQuests[inventedQuest][Q.objectives][3][1][1] == inventedItem)
check("preapproval source gets both NPC reverse links",
    injectedNpc[inventedNpc] and
    contains(injectedNpc[inventedNpc][N.questStarts], inventedQuest) and
    contains(injectedNpc[inventedNpc][N.questEnds], inventedQuest))
check("preapproval retains original 2001 and injected raw source without mutation",
    injectedQuests[2001] and injectedQuests[2001][Q.name] == "Ravenclaw Cleanup" and
    injectedDb.questData[inventedQuest] == nil and
    injectedDb.itemData[inventedItem][1] == "Invented item, no drop locations")
print("ALL " .. checks .. " AUTHENTIC-LOADER SYNTHETIC PREPROVISION CHECKS PASS")
print("NOT PROVEN: source provenance, native 3.3.5a, item drop locations,")
print("             correction-group order, compiler persistence, IP or Gate08")
