-- PUBLIC-SAFE test-only: executes unchanged protected 335 QuestieDB:Initialize()
-- with fictional GetDBHandle to witness the original eight-field reader ABI.
-- NOT real QuestieDBCompiler, QuestieStream, AceDB or client runtime.
local root=assert(os.getenv("NQ_G08_ORIGINAL_DB_READER_ROOT"),
    "PINNED_ORIGINAL_DB_READER_ROOT_REQUIRED")
local file=assert(io.open(root.."/Database/QuestieDB.lua","rb"),
    "ORIGINAL_DB_READER_FILE_MISSING")
local src=assert(file:read("*a"));file:close()
local startToken="function QuestieDB:Initialize()"
local endToken="\nfunction QuestieDB:GetObject(objectId)"
local start=assert(src:find(startToken,1,true),"ORIGINAL_INITIALIZE_START_MISSING")
local finish=assert(src:find(endToken,start+#startToken,true),
    "ORIGINAL_INITIALIZE_END_MISSING")
assert(not src:find(startToken,start+#startToken,true),
    "ORIGINAL_INITIALIZE_DUPLICATE")
local authentic=src:sub(start,finish-1)
local assertions=0
local function check(ok,name)
    assert(ok,name)
    assertions=assertions+1
end
local kinds={"npc","quest","obj","item"}
local names={"NPC","Quest","Object","Item"}
local function sourceGeneration(prefix)
    local data={
        dbCompiledOnVersion=prefix.."_VERSION",
        dbCompiledLang=prefix.."_LOCALE",
        dbCompiledCount=4,nQuestieDataRevision=4,dbIsCompiled=true
    }
    for _,kind in ipairs(kinds) do
        data[kind.."Bin"]=prefix.."_BIN_"..kind
        data[kind.."Ptrs"]=prefix.."_PTR_"..kind
    end
    return data
end
local function eval(source,env)
    local run
    if _VERSION=="Lua 5.1" then
        run=assert(loadstring(source,"=original_protected_335_questiedb_reader"))
        setfenv(run,env)
    else
        run=assert(load(source,"=original_protected_335_questiedb_reader","t",env))
    end
    run()
end
local function host(opts)
    opts=opts or {}
    local global=sourceGeneration("OLD")
    global.sod=sourceGeneration("SOD")
    global.published=sourceGeneration("NEW") -- shadow; original consumer ignores it
    local queryCalls={}
    local compiler={}
    function compiler:BuildSkipMap()
        return {fictional=true}
    end
    function compiler:GetDBHandle(bin,ptrs,skipmap,keys,overrides)
        queryCalls[#queryCalls+1]={bin=bin,ptrs=ptrs,overrides=overrides}
        return {
            pointers=ptrs,
            Query=function()return bin end,
            QuerySingle=function()return ptrs end
        }
    end
    local qDB={
        npcCompilerTypes={},npcCompilerOrder={},npcKeys={},npcDataOverrides={},
        questCompilerTypes={},questCompilerOrder={},questKeys={},questDataOverrides={},
        objectCompilerTypes={},objectCompilerOrder={},objectKeys={},objectDataOverrides={},
        itemCompilerTypes={},itemCompilerOrder={},itemKeys={},itemDataOverrides={}
    }
    local privateDB={
        questCache={stale=true},itemCache={stale=true},
        npcCache={stale=true},objectCache={stale=true},zoneCache={stale=true}
    }
    local env={
        QuestieDB=qDB,_QuestieDB=privateDB,
        Questie={IsSoD=opts.sod==true,db={
            global=global,profile={disableDatabaseWarnings=false},
            char={hidden={}}
        }},
        QuestieDBCompiler=compiler,
        StaticPopupDialogs={},
        l10n=function(s)return s end,
        QuestieLib={TableMemoizeFunction=function(_,f)return f end},
        QuestiePlayer={HasRequiredRace=function()return true end,
            HasRequiredClass=function()return true end},
        QuestieCorrections={hiddenQuests={}},
        ReloadUI=function()end
    }
    setmetatable(env,{__index=_G})
    eval(authentic,env)
    local function initialize()
        for i=#queryCalls,1,-1 do queryCalls[i]=nil end
        env.QuestieDB:Initialize()
    end
    return {env=env,global=global,queryCalls=queryCalls,
        db=qDB,private=privateDB,init=initialize}
end
local function hasGeneration(queries,prefix)
    if #queries~=4 then return false end
    for i,kind in ipairs(kinds) do
        if queries[i].bin~=prefix.."_BIN_"..kind or
            queries[i].ptrs~=prefix.."_PTR_"..kind then
            return false
        end
    end
    return true
end

check(#authentic>3500,"R01_REAL_ORIGINAL_INIT_NOT_TRUNCATED")
check(authentic:find("Questie.db.global.npcBin",1,true)~=nil and
      authentic:find("Questie.db.global.itemPtrs",1,true)~=nil,
      "R02_ORIGINAL_NON_SOD_EIGHT_FIELD_READ_ANCHORED")
check(authentic:find("Questie.db.global.sod.npcBin",1,true)~=nil,
      "R03_ORIGINAL_SOD_SEPARATE_PATH_ANCHORED")
check(authentic:find("QuestieDBCompiler:GetDBHandle(",1,true)~=nil,
      "R04_ORIGINAL_HANDLE_FACTORY_ANCHORED")
check(not authentic:find("global.published",1,true),
      "R05_ORIGINAL_READER_HAS_NO_SHADOW_GENERATION_POINTER")
local h=host()
check(type(h.db.Initialize)=="function","R06_UNMODIFIED_ORIGINAL_INIT_LOADED")
h.init()
check(#h.queryCalls==4,"R07_EXACTLY_FOUR_ORIGINAL_READER_HANDLES")
check(hasGeneration(h.queryCalls,"OLD"),
      "R08_ORIGINAL_335_CONSUMES_EIGHT_OLD_FIELDS")
check(h.global.published.npcBin=="NEW_BIN_npc" and
      h.queryCalls[1].bin=="OLD_BIN_npc",
      "R09_NEW_SHADOW_GENERATION_NOT_OBSERVED")
check(h.db.QueryNPC()=="OLD_BIN_npc" and
      h.db.QueryItem()=="OLD_BIN_item",
      "R10_EXPORTED_ORIGINAL_QUERY_FUNCTIONS_PINNED_OLD")
check(h.db.NPCPointers=="OLD_PTR_npc" and
      h.db.ItemPointers=="OLD_PTR_item",
      "R11_EXPORTED_POINTERS_PINNED_OLD")
check(type(h.private.questCache)=="table" and
      next(h.private.questCache)==nil and
      next(h.private.itemCache)==nil and
      next(h.private.npcCache)==nil and
      next(h.private.objectCache)==nil and
      next(h.private.zoneCache)==nil,
      "R12_ORIGINAL_INIT_RESETS_FIVE_QUERY_CACHES")
check(type(h.env.checkRace)=="function" and
      type(h.env.checkClass)=="function",
      "R13_ORIGINAL_INIT_MEMOIZED_QUERY_HELPERS")
local previousQuery=h.db.QueryNPC
h.global.published=sourceGeneration("OTHER_NEW")
check(h.db.QueryNPC()=="OLD_BIN_npc" and
      previousQuery()=="OLD_BIN_npc",
      "R14_POINTER_REPLACEMENT_IN_SHADOW_NOT_OBSERVED")
h.init()
check(hasGeneration(h.queryCalls,"OLD"),
      "R15_ORIGINAL_REINIT_STILL_IGNORES_SHADOW_GENERATION")
check(h.db.QueryQuest()=="OLD_BIN_quest",
      "R16_REINIT_EXPORTED_QUERY_OLD_WITHOUT_LEGACY_MIGRATION")
h.global.npcBin="NEW_BIN_npc"
h.global.npcPtrs="OLD_PTR_npc"
h.init()
check(h.queryCalls[1].bin=="NEW_BIN_npc" and
      h.queryCalls[1].ptrs=="OLD_PTR_npc",
      "R17_ORIGINAL_READER_ACCEPTS_MIXED_NPC_BIN_PTRS_ARGUMENTS")
check(h.queryCalls[2].bin=="OLD_BIN_quest" and
      h.queryCalls[4].bin=="OLD_BIN_item",
      "R18_PARTIAL_NEW_NPC_DOES_NOT_UPDATE_OTHER_KINDS")
check(h.db.QueryNPC()=="NEW_BIN_npc" and
      h.db.NPCPointers=="OLD_PTR_npc",
      "R19_MIXED_NPC_HANDLE_INSTALLED_WITH_FICTIONAL_FACTORY")
check(previousQuery()=="OLD_BIN_npc",
      "R20_ALREADY_PINNED_QUERY_HANDLE_REMAINS_OLD")
local newGeneration=sourceGeneration("NEW")
for _,kind in ipairs(kinds) do
    h.global[kind.."Bin"]=newGeneration[kind.."Bin"]
    h.global[kind.."Ptrs"]=newGeneration[kind.."Ptrs"]
end
h.init()
check(hasGeneration(h.queryCalls,"NEW"),
      "R21_EIGHT_DIRECT_LEGACY_WRITES_OBSERVED_AFTER_REINIT")
check(h.db.QueryObject()=="NEW_BIN_obj" and
      h.db.QuestPointers=="NEW_PTR_quest",
      "R22_NEW_HANDLES_REQUIRE_LEGACY_DIRECT_FIELDS")
check(h.global.dbCompiledOnVersion=="OLD_VERSION" and
      h.db.QueryNPC()=="NEW_BIN_npc",
      "R23_ORIGINAL_INIT_NOT_A_METADATA_GENERATION_VALIDATOR")
check(not authentic:find("dbCompiledOnVersion",1,true) and
      not authentic:find("nQuestieDataRevision",1,true),
      "R24_ORIGINAL_INIT_DOES_NOT_CHECK_COMPILED_METADATA")
local oldHandle=h.db.QueryNPC
h.global.npcBin="LATER_UNVERIFIED_BIN"
check(oldHandle()=="NEW_BIN_npc",
      "R25_QUERY_HANDLE_PINS_SOURCE_AT_HANDLE_CREATION")
h.init()
check(h.db.QueryNPC()=="LATER_UNVERIFIED_BIN",
      "R26_ORIGINAL_REINIT_CAN_OBSERVE_LATER_SINGLE_FIELD_WRITE")

local sod=host({sod=true})
sod.init()
check(hasGeneration(sod.queryCalls,"SOD"),
      "R27_ORIGINAL_SOD_READS_OWN_EIGHT_FIELDS")
check(sod.db.NPCPointers=="SOD_PTR_npc",
      "R28_SOD_POINTERS_NOT_335_GLOBAL_POINTERS")
sod.global.published=sourceGeneration("PROPOSED")
sod.init()
check(hasGeneration(sod.queryCalls,"SOD"),
      "R29_ORIGINAL_SOD_ALSO_IGNORES_SHADOW_POINTER")

-- Separate conceptual reader snapshot model, NOT the original function.
local generation=sourceGeneration("NEW")
local pinned=generation
local chosen={}
for _,kind in ipairs(kinds) do
    chosen[#chosen+1]={bin=pinned[kind.."Bin"],ptrs=pinned[kind.."Ptrs"]}
end
generation=sourceGeneration("AFTER")
check(chosen[1].bin=="NEW_BIN_npc" and
      chosen[4].ptrs=="NEW_PTR_item",
      "R30_EXPLICIT_PROPOSED_GENERATION_SNAPSHOT_STAYS_COHERENT")
check(generation.npcBin=="AFTER_BIN_npc" and
      chosen[1].bin=="NEW_BIN_npc",
      "R31_PROPOSED_ONE_REFERENCE_READERS_RETAIN_PRIOR_GENERATION")
check(#chosen==4 and
      chosen[1].ptrs=="NEW_PTR_npc" and
      chosen[2].bin=="NEW_BIN_quest",
      "R32_ADAPTER_MODEL_BIN_PTR_PAIRS_MATCH_ONE_GENERATION")
assert(assertions==32,"G08_READER_ABI_TEST_CENSUS_CHANGED")
print("PUBLIC G08 PART43 ORIGINAL 335 READER ABI: 32/32 PASS")
print("PUBLIC G08 ORIGINAL FACT: QuestieDB Initialize reads eight individual global or SoD Bin/Ptrs, builds four query handles and ignores a shadow published generation pointer.")
print("PUBLIC G08 NOT ACCEPTED: GetDBHandle is fictional, shadow reader adapter is hypothetical; no native consumer migration, global stream/atomicity, disk/relog or playable ZIP/install/merge/release.")
