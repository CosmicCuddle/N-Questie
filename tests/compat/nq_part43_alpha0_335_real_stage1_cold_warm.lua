-- Part43 Alpha0: execute unchanged ORIGINAL protected 335 QuestieInit Stage1.
-- This is a fictional Lua host: NO WoW client, SavedVariables, package or realm data.
local root=assert(os.getenv("NQ_ALPHA0_REAL_STAGE1_ROOT"),"ALPHA0_ORIGINAL_SOURCE_ROOT_REQUIRED")
local file=assert(io.open(root.."/Modules/QuestieInit.lua","rb"),"ALPHA0_ORIGINAL_QUESTIEINIT_MISSING")
local source=assert(file:read("*a")); file:close()
local function anchor(token)
    local i=assert(source:find(token,1,true),"ALPHA0_SOURCE_ANCHOR_MISSING:"..token)
    assert(not source:find(token,i+#token,true),"ALPHA0_DUPLICATED_SOURCE_ANCHOR:"..token)
    return i
end
local function exact(first,last)
    local a,b=anchor(first),anchor(last)
    assert(b>a,"ALPHA0_ANCHOR_ORDER")
    return source:sub(a,b-1)
end
local helpers=exact("local function loadFullDatabase()",
    "-- ********************************************************************************\n-- Start of QuestieInit.Stages")
local stage=exact("QuestieInit.Stages[1] = function() -- run as a coroutine",
    "\nQuestieInit.Stages[2] = function()")
assert(#helpers>1300 and #stage>3000,"ALPHA0_UNMODIFIED_SOURCE_TRUNCATED")
for _,token in ipairs({
    "QuestieCorrections:Initialize()", "QuestieCorrections:PreCompile()",
    "QuestieDBCompiler:Compile()", "QuestieCorrections:MinimalInit()",
    "Questie.db.global.nQuestieDataRevision = nQuestieRevision",
    "Questie.db.profile.skipValidation ~= true",
}) do
    assert((helpers..stage):find(token,1,true),"ALPHA0_REQUIRED_REAL_SOURCE_ANCHOR:"..token)
end

-- Authenticate and execute the unchanged original outer four-kind compiler too.
local compilerFile=assert(io.open(root.."/Database/compiler.lua","rb"),
    "ALPHA0_ORIGINAL_COMPILER_SOURCE_REQUIRED")
local compilerSource=assert(compilerFile:read("*a"));compilerFile:close()
local a=assert(compilerSource:find("function QuestieDBCompiler:Compile()",1,true))
local b=assert(compilerSource:find("\nfunction QuestieDBCompiler:ValidateNPCs()",a+1,true))
assert(b>a and not compilerSource:find("function QuestieDBCompiler:Compile()",a+1,true),
    "ALPHA0_ORIGINAL_OUTER_COMPILER_ANCHOR")
local originalOuter=compilerSource:sub(a,b-1)
assert(#originalOuter>1000 and
    originalOuter:find("if QuestieDBCompiler._isCompiling then",1,true) and
    originalOuter:find("Questie.db.global.dbIsCompiled = true",1,true),
    "ALPHA0_REAL_OUTER_COMPILER_SOURCE_TRUNCATED")
local function execute_original(chunk,env)
    local run
    if _VERSION=="Lua 5.1" then
        run=assert(loadstring(chunk,"=protected_335_stage1"))
        setfenv(run,env)
    else
        run=assert(load(chunk,"=protected_335_stage1","t",env))
    end
    run()
end

local function count(events,wanted)
    local n=0
    for _,e in ipairs(events) do if e==wanted then n=n+1 end end
    return n
end
local function occurs_in_order(events,names)
    local i=1
    for _,e in ipairs(events) do
        if e==names[i] then i=i+1 end
        if i>#names then return true end
    end
    return false
end

local function fixture(opts)
    opts=opts or {}
    local events={}
    local function mark(e) events[#events+1]=e end
    local function module(name)
        return setmetatable({}, {__index=function(t,k)
            local f=function()mark(name.."."..k)end
            rawset(t,k,f)
            return f
        end})
    end
    local localDB={
        global={
            dbIsCompiled=opts.compiled~=false,
            dbCompiledOnVersion=opts.cachedVersion or "9.5.1.1",
            dbCompiledLang=opts.cachedLocale or "enUS",
            dbCompiledExpansion=opts.cachedExpansion or 11,
            nQuestieDataRevision=opts.cachedRevision or 7,
            dbCompiledCount=4,
        },
        char={townsfolk=true,townsfolkVersion=4,townsfolkClass="Mage"},
        profile={
            debugEnabled=opts.debug==true,
            skipValidation=opts.skipValidation==true,
            questieShutUp=false,
        },
    }
    if opts.explicitCompiled~=nil then
        localDB.global.dbIsCompiled=opts.explicitCompiled
    end
    if opts.explicitRevision~=nil then
        localDB.global.nQuestieDataRevision=opts.explicitRevision
    end
    local QuestieDB=module("QuestieDB")
    QuestieDB.private=module("QuestieDB.private")
    QuestieDB.questData={}; QuestieDB.npcData={}
    QuestieDB.objectData={}; QuestieDB.itemData={}
    local corrections=module("QuestieCorrections")
    local compiler=module("QuestieDBCompiler")
    function compiler:Compile()
        mark("QuestieDBCompiler.Compile")
        if opts.compilerFails then error("FICTIONAL_COMPILER_FAILURE",0) end
        localDB.global.dbIsCompiled=true
    end
    local l10nLocale=opts.activeLocale or "enUS"
    local l10n=setmetatable({},{
        __call=function(_,message) return message end
    })
    function l10n:SetUILocale(loc) mark("l10n.SetUILocale"); l10nLocale=loc end
    function l10n:GetUILocale() return l10nLocale end
    function l10n:Initialize() mark("l10n.Initialize") end
    local env={
        QuestieInit={Stages={}},
        Questie={
            db=localDB,IsSoD=false,IsWotlk=true,
            DEBUG_CRITICAL=1,DEBUG_DEVELOP=2,
            Debug=function()end,
            SetIcons=function()mark("Questie.SetIcons")end,
        },
        QuestieCompat={WOW_PROJECT_ID=11},
        QuestieLib={GetAddonVersionString=function()return "9.5.1.1"end},
        ThreadLib={ThreadSimple=function()mark("ThreadLib.ThreadSimple")end},
        QuestieOptions={Initialize=function()end},
        MinimapIcon=module("MinimapIcon"),
        HBDHooks=module("HBDHooks"),
        QuestieShutUp=module("QuestieShutUp"),
        ZoneDB=module("ZoneDB"),
        Migration=module("Migration"),
        IsleOfQuelDanas={Initialize=function()mark("IsleOfQuelDanas.Initialize")end},
        QuestieProfessions=module("QuestieProfessions"),
        QuestXP={Init=function()mark("QuestXP.Init")end},
        SeasonOfDiscovery={Initialize=function()mark("SeasonOfDiscovery.Initialize")end},
        QuestieCorrections=corrections,
        QuestieDBCompiler=compiler,
        QuestieDB=QuestieDB,
        Townsfolk=module("Townsfolk"),
        Tutorial={Initialize=function()mark("Tutorial.Initialize")end},
        QuestieCleanup=module("QuestieCleanup"),
        l10n=l10n,
        GetLocale=function()return opts.clientLocale or "enUS"end,
        UnitClass=function()return "Mage"end,
        print=function()end,
        coroutine=coroutine,
        rawget=rawget,
    }
    function env.QuestieInit:LoadBaseDB()mark("QuestieInit.LoadBaseDB")end
    env._G=env
    if not opts.missingCustomData then
        env.NQuestieCustomQuestData={revision=opts.sourceRevision or 7}
    end
    setmetatable(env,{__index=_G})
    if opts.useOuterSource then
        for _,kind in ipairs({"npc","obj","quest","item"}) do
            localDB.global[kind.."Bin"]="OLD_BIN_"..kind
            localDB.global[kind.."Ptrs"]="OLD_PTR_"..kind
        end
        local forms={{"NPCs","npc"},{"Objects","obj"},
            {"Quests","quest"},{"Items","item"}}
        for _,pair in ipairs(forms) do
            local method,kind="Compile"..pair[1],pair[2]
            compiler[method]=function()
                mark("QuestieDBCompiler."..method)
                if opts.outerFailAt==kind then
                    error("FICTIONAL_OUTER_FAILURE_"..kind,0)
                end
                localDB.global[kind.."Bin"]="NEW_BIN_"..kind
                localDB.global[kind.."Ptrs"]="NEW_PTR_"..kind
            end
        end
        compiler._isCompiling=opts.outerBusy==true
        env.GetTime=function()return 123 end
        execute_original("local WOW_PROJECT_ID = QuestieCompat.WOW_PROJECT_ID\n"..
            originalOuter,env)
    end
    assert(source:find("local WOW_PROJECT_ID = QuestieCompat.WOW_PROJECT_ID",1,true),
        "ALPHA0_ORIGINAL_EXPANSION_BINDING_MISSING")
    execute_original("local WOW_PROJECT_ID = QuestieCompat.WOW_PROJECT_ID\n"..
        "local coYield=coroutine.yield\n"..helpers..
        "\nQuestieInit.Stages={}\n"..stage,env)

    local thread=coroutine.create(env.QuestieInit.Stages[1])
    local resumes,yields=0,0
    local ok,err=true,nil
    while coroutine.status(thread)~="dead" do
        resumes=resumes+1
        assert(resumes<150,"ALPHA0_NONTERMINATING_TEST_COROUTINE")
        local resumed,message=coroutine.resume(thread)
        if not resumed then ok,err=false,message; break end
        if coroutine.status(thread)~="dead" then yields=yields+1 end
    end
    return {ok=ok,err=err,events=events,db=localDB,yields=yields,env=env}
end

local checks=0
local function check(ok,label)
    assert(ok,label)
    checks=checks+1
end

local cold=fixture({compiled=false})
check(cold.ok,"S01_COLD_EXECUTES_ORIGINAL_STAGE1")
check(count(cold.events,"QuestieInit.LoadBaseDB")==1,
      "S02_COLD_REAL_LOAD_HELPER_INVOCATION")
check(count(cold.events,"QuestieCorrections.Initialize")==1,
      "S03_COLD_CORRECTION_WRITER_REQUIRED")
check(count(cold.events,"QuestieCorrections.PreCompile")==1,
      "S04_COLD_PRECOMPILER_REQUIRED")
check(count(cold.events,"QuestieDBCompiler.Compile")==1,
      "S05_COLD_COMPILER_REQUIRED")
check(count(cold.events,"QuestieCorrections.MinimalInit")==0,
      "S06_COLD_NOT_WARM_MINIMAL_INIT")
check(occurs_in_order(cold.events,{"QuestieInit.LoadBaseDB",
      "QuestieCorrections.Initialize","QuestieCorrections.PreCompile",
      "QuestieDBCompiler.Compile","QuestieDB.Initialize",
      "QuestieCleanup.Run"}),"S07_REAL_COLD_STAGE_ORDER")
check(cold.yields>=8,"S08_REAL_COLD_COROUTINE_YIELDS")
check(cold.db.global.nQuestieDataRevision==7,"S09_COLD_REVISION_WRITTEN")
check(count(cold.events,"QuestieCleanup.Run")==1,
      "S10_COLD_CLEANUP_COMPLETES")

local warm=fixture()
check(warm.ok,"S11_MATCHING_WARM_EXECUTES")
check(count(warm.events,"QuestieCorrections.MinimalInit")==1,
      "S12_WARM_CALLS_REAL_MINIMAL_INIT")
check(count(warm.events,"QuestieDBCompiler.Compile")==0 and
      count(warm.events,"QuestieInit.LoadBaseDB")==0,
      "S13_WARM_DOES_NOT_RECOMPILE")
check(count(warm.events,"QuestieDB.Initialize")==1,
      "S14_WARM_INITIALIZES_QUESTIE_DB")
check(occurs_in_order(warm.events,{"l10n.Initialize",
      "QuestieCorrections.MinimalInit","QuestieDB.Initialize",
      "QuestieCleanup.Run"}),"S15_WARM_SOURCE_ORDER")
check(warm.yields>0 and warm.yields<cold.yields,
      "S16_WARM_YIELDS_FEWER_THAN_COLD")

local missingFlag=fixture({explicitCompiled=false})
check(missingFlag.ok and count(missingFlag.events,
      "QuestieDBCompiler.Compile")==1,
      "S17_EXPLICIT_FALSE_CACHE_RECOMPILES")
local changedVersion=fixture({cachedVersion="stale"})
check(changedVersion.ok and count(changedVersion.events,
      "QuestieDBCompiler.Compile")==1,
      "S18_VERSION_MISMATCH_RECOMPILES")
local changedLocale=fixture({cachedLocale="frFR"})
check(changedLocale.ok and count(changedLocale.events,
      "QuestieDBCompiler.Compile")==1,
      "S19_LOCALE_MISMATCH_RECOMPILES")
local changedExpansion=fixture({cachedExpansion=3})
check(changedExpansion.ok and count(changedExpansion.events,
      "QuestieDBCompiler.Compile")==1,
      "S20_EXPANSION_MISMATCH_RECOMPILES")
local changedRevision=fixture({cachedRevision=6})
check(changedRevision.ok and count(changedRevision.events,
      "QuestieDBCompiler.Compile")==1,
      "S21_CUSTOM_REVISION_MISMATCH_RECOMPILES")
check(changedRevision.db.global.nQuestieDataRevision==7,
      "S22_REAL_STAGE1_UPDATES_NEW_REVISION")
local newRevision=fixture({sourceRevision=8})
check(newRevision.ok and count(newRevision.events,
      "QuestieDBCompiler.Compile")==1 and
      newRevision.db.global.nQuestieDataRevision==8,
      "S23_REVISION_INCREASE_RECOMPILES")
local noCustom=fixture({missingCustomData=true,cachedRevision=7})
check(noCustom.ok and count(noCustom.events,
      "QuestieDBCompiler.Compile")==1 and
      noCustom.db.global.nQuestieDataRevision==0,
      "S24_MISSING_CUSTOM_TABLE_FALLBACK_ZERO")
local skip=fixture({compiled=false,debug=true,skipValidation=true})
check(skip.ok and count(skip.events,"QuestieDBCompiler.Compile")==1,
      "S25_SKIP_VALIDATION_DOES_NOT_SKIP_COMPILE")
check(count(skip.events,"QuestieDBCompiler.ValidateNPCs")==0,
      "S26_SKIP_DEBUG_VALIDATOR_ONLY")
local validate=fixture({compiled=false,debug=true,skipValidation=false})
check(validate.ok,"S27_DEBUG_VALIDATOR_PATH_COMPLETES")
check(occurs_in_order(validate.events,{"QuestieDBCompiler.Compile",
      "QuestieDBCompiler.ValidateNPCs","QuestieDBCompiler.ValidateObjects",
      "QuestieDBCompiler.ValidateItems","QuestieDBCompiler.ValidateQuests",
      "QuestieCleanup.Run"}),"S28_DEBUG_VALIDATION_FOLLOWS_COMPILE")
local warmDebug=fixture({debug=true})
check(warmDebug.ok and count(warmDebug.events,
      "QuestieDBCompiler.ValidateNPCs")==0,
      "S29_WARM_CACHE_NEVER_RUNS_RECOMPILE_VALIDATION")
local failure=fixture({compiled=false,compilerFails=true})
check(not failure.ok and tostring(failure.err):find(
      "FICTIONAL_COMPILER_FAILURE",1,true)~=nil,
      "S30_COMPILER_ERROR_PROPAGATES")
check(count(failure.events,"QuestieCorrections.Initialize")==1 and
      count(failure.events,"QuestieDBCompiler.Compile")==1,
      "S31_COMPILER_FAILURE_AFTER_CORRECTIONS")
check(count(failure.events,"QuestieDB.Initialize")==0 and
      count(failure.events,"QuestieCleanup.Run")==0,
      "S32_FAILURE_DOES_NOT_CONTINUE_STAGE")
check(failure.db.global.nQuestieDataRevision==7 and
      failure.db.global.dbIsCompiled==false,
      "S33_FAILURE_DOES_NOT_CERTIFY_NEW_GENERATION")
local failureChanged=fixture({compiled=true,cachedRevision=6,
    compilerFails=true})
check(not failureChanged.ok and
      failureChanged.db.global.nQuestieDataRevision==6,
      "S34_FAILED_REFRESH_DOES_NOT_SET_NEW_REVISION")
check(count(failureChanged.events,"QuestieCorrections.MinimalInit")==0,
      "S35_FAILED_REFRESH_NOT_SILENT_WARM_FALLBACK")

-- The actual original outer :Compile() is now connected to the unchanged Stage1.
-- Only per-kind serializers are invented. Failure/reentry are intentionally unsafe.
local outerOK=fixture({compiled=false,useOuterSource=true})
check(outerOK.ok,"S36_REAL_OUTER_COMPILE_STAGE1_SUCCESS")
check(occurs_in_order(outerOK.events,{"QuestieDBCompiler.CompileNPCs",
    "QuestieDBCompiler.CompileObjects","QuestieDBCompiler.CompileQuests",
    "QuestieDBCompiler.CompileItems","QuestieDB.Initialize"}),
    "S37_REAL_FOUR_KIND_OUTER_ORDER")
local function valuesAre(f,expected)
    for _,kind in ipairs({"npc","obj","quest","item"}) do
        if f.db.global[kind.."Bin"]~=expected.."BIN_"..kind or
            f.db.global[kind.."Ptrs"]~=expected.."PTR_"..kind then return false end
    end
    return true
end
check(valuesAre(outerOK,"NEW_"),"S38_SYNTHETIC_EIGHT_PAYLOAD_FIELDS_WRITTEN")
check(outerOK.db.global.dbIsCompiled==true and
    outerOK.db.global.dbCompiledOnVersion=="9.5.1.1" and
    outerOK.db.global.dbCompiledLang=="enUS" and
    outerOK.db.global.dbCompiledExpansion==11 and
    outerOK.db.global.dbCompiledCount==5,
    "S39_REAL_OUTER_METADATA_SEQUENCED_AFTER_FOUR_KINDS")
check(outerOK.db.global.nQuestieDataRevision==7 and
    count(outerOK.events,"QuestieDB.Initialize")==1,
    "S40_REAL_STAGE1_REVISION_AFTER_REAL_OUTER")
check(outerOK.env.QuestieDBCompiler._isCompiling==true,
    "S41_REAL_OUTER_SUCCESS_RETains_LOCK")
local successfulReturns=outerOK.env.QuestieDBCompiler:Compile()
check(successfulReturns==nil and
    count(outerOK.events,"QuestieDBCompiler.CompileNPCs")==1,
    "S42_SECOND_SUCCESSFUL_CALL_SILENTLY_RETURNS")
local failObject=fixture({useOuterSource=true,cachedRevision=6,
    outerFailAt="obj"})
check(not failObject.ok and tostring(failObject.err):find(
    "FICTIONAL_OUTER_FAILURE_obj",1,true)~=nil,
    "S43_REAL_OUTER_OBJECT_FAIL_ESCAPES")
check(failObject.db.global.npcBin=="NEW_BIN_npc" and
    failObject.db.global.npcPtrs=="NEW_PTR_npc" and
    failObject.db.global.objBin=="OLD_BIN_obj" and
    failObject.db.global.questBin=="OLD_BIN_quest" and
    failObject.db.global.itemBin=="OLD_BIN_item",
    "S44_REAL_OUTER_PARTIAL_PAYLOAD_VISIBLE_AFTER_ERROR")
check(failObject.db.global.dbIsCompiled==true and
    failObject.db.global.dbCompiledCount==4 and
    failObject.db.global.nQuestieDataRevision==6,
    "S45_FAILURE_PRESERVES_OLD_CACHE_METADATA")
local retryResult=failObject.env.QuestieDBCompiler:Compile()
check(retryResult==nil and
    count(failObject.events,"QuestieDBCompiler.CompileNPCs")==1 and
    failObject.env.QuestieDBCompiler._isCompiling==true,
    "S46_FAILED_OUTER_LOCK_SILENT_RETRY")
check(count(failObject.events,"QuestieDB.Initialize")==0 and
    count(failObject.events,"QuestieCleanup.Run")==0,
    "S47_THROWN_FAILURE_STOPS_STAGE1_DOWNSTREAM")
local failItem=fixture({useOuterSource=true,cachedRevision=6,
    outerFailAt="item"})
check(not failItem.ok and count(failItem.events,
    "QuestieDBCompiler.CompileItems")==1,
    "S48_REAL_OUTER_ITEM_FAIL_REACHED")
check(failItem.db.global.npcBin=="NEW_BIN_npc" and
    failItem.db.global.objBin=="NEW_BIN_obj" and
    failItem.db.global.questBin=="NEW_BIN_quest" and
    failItem.db.global.itemBin=="OLD_BIN_item",
    "S49_REAL_OUTER_LATE_PARTIAL_PUBLICATION")
local busy=fixture({useOuterSource=true,cachedRevision=6,outerBusy=true})
check(busy.ok and count(busy.events,"QuestieDB.Initialize")==1,
    "S50_REAL_STAGE1_BUSY_RETURNS_AS_IF_SUCCESSFUL")
check(valuesAre(busy,"OLD_") and
    count(busy.events,"QuestieDBCompiler.CompileNPCs")==0,
    "S51_BUSY_OUTER_SKIPS_ALL_FOUR_KINDS")
check(busy.db.global.nQuestieDataRevision==7 and
    busy.db.global.dbIsCompiled==true and
    busy.db.global.dbCompiledCount==4,
    "S52_BUSY_STAGE1_WRITES_NEW_REVISION_WITH_OLD_PAYLOAD")
check(busy.env.QuestieDBCompiler._isCompiling==true and
    busy.env.QuestieDBCompiler:Compile()==nil,
    "S53_BUSY_RETURN_UNDISTINGUISHABLE_FROM_SUCCESS")
local apparentWarm=fixture({useOuterSource=true,cachedRevision=
    busy.db.global.nQuestieDataRevision})
check(apparentWarm.ok and
    count(apparentWarm.events,"QuestieCorrections.MinimalInit")==1 and
    count(apparentWarm.events,"QuestieDBCompiler.CompileNPCs")==0,
    "S54_BAD_REVISION_COULD_APPEAR_WARM_ON_RELOG_MODEL")
check(not valuesAre(busy,"NEW_") and
    count(busy.events,"QuestieCleanup.Run")==1,
    "S55_STAGE1_COMPLETED_WITHOUT_FOUR_KIND_RECOMPILE")
assert(checks==55,"ALPHA0_STAGE1_TEST_CENSUS_CHANGED")
print("PUBLIC ALPHA0 PART43 REAL 335 STAGE1 AND OUTER: 55/55 PASS")
print("PUBLIC ALPHA0 SOURCE FACT: real outer four-kind compiler silently returns on busy and writes separate payload pairs before final metadata; unchanged Stage1 can certify revision after a busy return.")
print("PUBLIC ALPHA0 NOT ACCEPTED: per-kind serializers are fictional, no global lease/atomicity fix, real addon/SavedVariables/native 3.3.5a/IP, ZIP/install/merge/release.")
