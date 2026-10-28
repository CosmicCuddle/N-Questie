-- Part41 G04 PUBLIC-SAFE real-loader registration and manifest lifecycle fixture.
-- All proposed quest/NPC/GO links below are INVENTED. Never load owner SQL/IP.
-- Two EXPECTED UNSAFE late-write witnesses are limitations, not passed guards.
local root=assert(os.getenv("NQ_G04_SOURCE_ROOT"),
    "G04_PINNED_PROTECTED_SOURCE_REQUIRED")
local function read(file)
    local f=assert(io.open(root.."/"..file,"rb"),"G04_SOURCE_NOT_STAGED")
    local s=assert(f:read("*a"))
    f:close()
    return s
end
local loader=read("Compat/NQuestieCustomQuestLoader.lua")
local publicManifest=read("Compat/NQuestieCustomQuestData.lua")
local function runExact(source,chunkName,env)
    local fn
    if _VERSION=="Lua 5.1" then
        fn=assert(loadstring(source,chunkName))
        setfenv(fn,env)
    else
        fn=assert(load(source,chunkName,"t",env))
    end
    return fn()
end
local Q={name=1,startedBy=2,finishedBy=3,requiredLevel=4,
    questLevel=5,requiredRaces=6,requiredClasses=7,objectives=10,
    zoneOrSort=17,questFlags=23,specialFlags=24}
local N={questStarts=10,questEnds=11}
local G={questStarts=2,questEnds=3}
local ID,S,F,K,GS,GF=940101,940201,940202,940203,940301,940302
local function boot(config)
    config=config or {}
    local proposal={
        name="Invented registration contract",requiredLevel=20,
        questLevel=23,zoneOrSort=101,requiredRaces=0,questFlags=0,
        startedByNpcs={S},finishedByNpcs={F},killNpcs={K},
    }
    local db={
        questKeys=Q,npcKeys=N,objectKeys=G,
        questData={},
        npcData={
            [S]={[N.questStarts]={930101}},
            [F]={[N.questEnds]={930102}},
            [K]={},
        },
        objectData={
            [GS]={[G.questStarts]={930103}},
            [GF]={[G.questEnds]={930104}},
        },
        itemData={},
    }
    local registered,registrations={},0
    local compat={
        Is335=config.is335~=false,
        RegisterCorrection=function(kind,cb)
            registrations=registrations+1
            assert(registered[kind]==nil,"G04_DUPLICATE_CORRECTION_CALLBACK")
            registered[kind]=cb
        end,
    }
    if config.registrationMissing then compat.RegisterCorrection=nil end
    local manifest={revision=1,quests={[ID]=proposal}}
    if config.badQuestTable then manifest.quests="not a table" end
    local selectedCompat=compat
    local selectedManifest=manifest
    if config.noCompat then selectedCompat=nil end
    if config.noManifest then selectedManifest=nil end
    local env=setmetatable({
        QuestieCompat=selectedCompat,
        QuestieLoader={ImportModule=function(_,name)
            assert(name=="QuestieDB","G04_UNEXPECTED_DB_IMPORT")
            return db
        end},
        NQuestieCustomQuestData=selectedManifest,
    },{__index=_G})
    runExact(loader,"=pinned_public_custom_loader",env)
    return {registered=registered,registrations=registrations,db=db,
        manifest=manifest,proposal=proposal}
end
local function emptyCallbacks(b)
    assert(b.registrations==0 and next(b.registered)==nil,
        "G04_DISABLED_REGISTRATION_MUST_BE_EMPTY")
end
local function allKinds(b)
    assert(b.registrations==3 and
        type(b.registered.questData)=="function" and
        type(b.registered.npcData)=="function" and
        type(b.registered.objectData)=="function" and
        b.registered.itemData==nil,
        "G04_EXACT_THREE_REGISTERED_KINDS")
end
local function checkValid(b,order)
    allKinds(b)
    local out={}
    for _,kind in ipairs(order) do
        out[kind]=b.registered[kind]()
    end
    local q=assert(out.questData[ID],"G04_VALID_FICTIONAL_QUEST_MISSING")
    assert(q[Q.requiredLevel]==20 and
        q[Q.startedBy][1][1]==S and
        q[Q.finishedBy][1][1]==F and
        q[Q.objectives][1][1][1]==K,
        "G04_FORWARD_FICTIONAL_FIELDS_DRIFT")
    local starts=assert(out.npcData[S][N.questStarts],
        "G04_REVERSE_START_MISSING")
    local ends=assert(out.npcData[F][N.questEnds],
        "G04_REVERSE_FINISH_MISSING")
    assert(#starts==2 and starts[1]==930101 and starts[2]==ID and
        #ends==2 and ends[1]==930102 and ends[2]==ID,
        "G04_REVERSE_EXISTING_OWNER_PRESERVATION")
    assert(next(out.objectData)==nil,"G04_UNEXPECTED_GO_RELATIONS")
end
local controls={
    function()
        emptyCallbacks(boot({noCompat=true}))
    end,
    function()
        emptyCallbacks(boot({is335=false}))
    end,
    function()
        emptyCallbacks(boot({registrationMissing=true}))
    end,
    function()
        emptyCallbacks(boot({noManifest=true}))
    end,
    function()
        emptyCallbacks(boot({badQuestTable=true}))
    end,
    function()
        local env=setmetatable({}, {__index=_G})
        runExact(publicManifest,"=pinned_public_quest_manifest",env)
        local m=assert(env.NQuestieCustomQuestData,
            "G04_PINNED_PUBLIC_MANIFEST_MISSING")
        local count=0
        for _,r in pairs(m.quests) do
            count=count+1
            assert(type(r)=="table","G04_PUBLIC_MANIFEST_ROW_TYPE")
        end
        assert(m.revision==9 and count==1 and
            type(m.quests[2001])=="table","G04_PUBLIC_MANIFEST_SHAPE_DRIFT")
    end,
    function()
        allKinds(boot())
    end,
    function()
        local b=boot()
        checkValid(b,{"questData","npcData","objectData"})
    end,
    function()
        local b=boot()
        b.proposal.unsupportedServerPhase=true
        assert(next(b.registered.questData())==nil and
            next(b.registered.npcData())==nil and
            next(b.registered.objectData())==nil,
            "G04_UNKNOWN_PRIVATE_POLICY_FIELD_MUST_REJECT")
    end,
    function()
        local b=boot()
        b.proposal.startedByItems={940401}
        assert(next(b.registered.questData())==nil and
            next(b.registered.npcData())==nil,
            "G04_ITEM_STARTER_IS_NOT_SUPPORTED_INPUT")
    end,
    function()
        local b=boot()
        b.db.npcData[S]=nil
        assert(next(b.registered.questData())==nil and
            next(b.registered.npcData())==nil,
            "G04_UNRESOLVED_SOURCE_REFUSED_BEFORE_ADMISSION")
    end,
    function()
        local b=boot()
        b.proposal.startedByGameObjects={GS}
        b.proposal.finishedByGameObjects={GF}
        local q=assert(b.registered.questData()[ID])
        local gos=b.registered.objectData()
        assert(q[Q.startedBy][2][1]==GS and
            q[Q.finishedBy][2][1]==GF and
            gos[GS][G.questStarts][2]==ID and
            gos[GF][G.questEnds][2]==ID,
            "G04_DISTINCT_GO_FORWARD_REVERSE_LINEAGE")
    end,
    function()
        local orders={
            {"questData","npcData","objectData"},
            {"questData","objectData","npcData"},
            {"npcData","questData","objectData"},
            {"npcData","objectData","questData"},
            {"objectData","questData","npcData"},
            {"objectData","npcData","questData"},
        }
        for _,order in ipairs(orders) do checkValid(boot(),order) end
        assert(#orders==6,"G04_CALLBACK_ORDER_MATRIX_MISSING")
    end,
    function()
        local b=boot()
        checkValid(b,{"npcData","objectData","questData"})
        assert(b.db.questData[ID]==nil and
            #b.db.npcData[S][N.questStarts]==1 and
            b.db.npcData[S][N.questStarts][1]==930101 and
            #b.db.objectData[GS][G.questStarts]==1,
            "G04_CORRECTION_CALLBACK_MUST_NOT_WRITE_SOURCE")
    end,
    function()
        -- EXPECTED UNSAFE: approvedQuests caches a reference to mutable q.
        -- After first approval, an unregistered late edit bypasses parseQuest.
        local b=boot()
        local before=assert(b.registered.questData()[ID])
        assert(before[Q.requiredLevel]==20,"G04_LATE_WRITE_BASELINE")
        b.proposal.requiredLevel=300 -- invalid u8, INVENTED TEST DATA ONLY
        local after=assert(b.registered.questData()[ID])
        assert(after[Q.requiredLevel]==300,
            "G04_EXPECTED_UNSAFE_LATE_MANIFEST_FIELD_WRITE_NOT_REPRODUCED")
    end,
    function()
        -- EXPECTED UNSAFE: source disappears after approval, forward still
        -- publishes from cached entry even though the reverse side cannot.
        local b=boot()
        assert(b.registered.questData()[ID],"G04_LATE_SOURCE_BASELINE")
        b.db.npcData[S]=nil
        assert(b.registered.questData()[ID] and
            b.registered.npcData()[S]==nil,
            "G04_EXPECTED_UNSAFE_LATE_OWNER_REMOVAL_NOT_REPRODUCED")
    end,
}
assert(#controls==16,"G04_CONTROL_INVENTORY_CHANGED")
local executed=0
for i,fn in ipairs(controls) do
    fn()
    executed=executed+1
    assert(executed==i,"G04_CONTROL_EXECUTION_DRIFT")
end
assert(executed==16,"G04_CONTROL_COUNT_DRIFT")
print("PUBLIC G04 PINNED LOADER CONTROLS: 16/16 PASS")
print("PUBLIC G04 KNOWN UNSAFE: late mutable manifest field edit and removed source after memoized approval are reproduced.")
print("PUBLIC G04 NOT ACCEPTED: exclusive all-writer provenance, immutable manifest, native client, IP eligibility or production integration.")
