-- Public-safe Part42 G08 test-only real initialization and faction source paths.
-- RUNS ORIGINAL UNMODIFIED protected-335 QuestieCorrections function bodies.
-- Only invented numeric records and mocked 3.3.5a addon host dependencies.
local root=assert(os.getenv("NQ_G08_REAL_CORRECTION_INIT_ROOT"),"G08_INIT_PINNED_SOURCE_REQUIRED")
local f=assert(io.open(root.."/Database/Corrections/QuestieCorrections.lua","rb"),
    "G08_ORIGINAL_CORRECTION_FILE_MISSING")
local source=assert(f:read("*a"));f:close()
local function anchor(needle,name)
    local first=assert(source:find(needle,1,true),name.."_MISSING")
    assert(not source:find(needle,first+#needle,true),name.."_DUPLICATED")
    return first
end
local function exact(startToken,endToken,name)
    local a=anchor(startToken,name.."_START")
    local b=anchor(endToken,name.."_END")
    assert(b>a,name.."_REVERSED")
    return source:sub(a,b-1)
end
local flags=exact("QuestieCorrections.TBC_ONLY = 1",
    "\nQuestieCorrections.killCreditObjectiveFirst = {}","G08_FLAGS")
local filter=exact("local function filterExpansion(values)",
    "\ndo\n    local type, assert = type, assert","G08_FILTER")
local minimal=exact("do\n    local type, assert = type, assert",
    "\n---@param databaseTableName string","G08_MINIMAL_INIT")
local loader=exact("local _LoadCorrections = function(",
    "\n---@param validationTables table? Only used by the CI","G08_LOAD")
local initialize=exact("function QuestieCorrections:Initialize(validationTables)",
    "\nlocal WAYPOINT_MIN_DISTANCE","G08_INITIALIZE")
assert(flags:find("SOD_ONLY",1,true) and
    minimal:find("QuestieCorrections:MinimalInit",1,true) and
    loader:find("noNewEntries",1,true) and
    initialize:find("QuestieCompat.LoadCorrections(_LoadCorrections, validationTables)",1,true),
    "G08_REAL_INIT_REQUIRED_BEHAVIOUR_ANCHOR")
assert(#initialize>3100 and #minimal>2800 and #loader>700,
    "G08_REAL_INIT_SOURCE_TRUNCATED")
local function evaluate(src,env)
    local run
    if _VERSION=="Lua 5.1" then
        run=assert(loadstring(src,"=original_335_real_correction_initialization"))
        setfenv(run,env)
    else
        run=assert(load(src,"=original_335_real_correction_initialization","t",env))
    end
    run()
end
local function containsOrdered(events,list)
    local at=1
    for _,event in ipairs(events) do
        if event==list[at] then at=at+1 end
        if at>#list then return true end
    end
    return false
end
local function boot(opts)
    opts=opts or {}
    local isWotlk=opts.isWotlk~=false
    local is335=opts.is335~=false
    local faction=opts.faction or "A"
    local events={},{}
    -- The fixture controls faction explicitly: NO WoW native unit faction API.
    local db={
        questKeys={startedBy=1,requiredRaces=2},
        npcKeys={friendlyToFaction=1},
        raceKeys={ALL_ALLIANCE=77,ALL_HORDE=88},
        questKeysReversed={[1]="startedBy",[2]="requiredRaces"},
        npcKeysReversed={[1]="friendlyToFaction"},
        itemKeysReversed={[1]="value",[2]="optional"},
        objectKeysReversed={[1]="value"},
        npcData={[1]={[1]="AH"},[2]={[1]="AH"}},
        questData={
            [1]={[1]={{1}},[2]=0},
            [2]={[1]={{2}},[2]=0},
            [3]={[1]={{1}},[2]=123},
            [4]={[2]=0},
        },
        itemData={[5]={[1]=5}},
        objectData={},
        itemDataOverrides={},npcDataOverrides={},
        objectDataOverrides={},questDataOverrides={},
    }
    local module={}
    local function track(s)events[#events+1]=s end
    local function stub(name)
        local result={}
        function result:Load()
            track(name..".Load")
            if name=="QuestieNPCFixes" then
                return {[1]={[1]="A"}}
            end
            if name=="QuestieTBCNpcFixes" then
                return {[1]={[1]="H"}}
            end
            if name=="QuestieWotlkNpcFixes" then
                return {[1]={[1]="A"}}
            end
            return {}
        end
        function result:LoadAutomatics()
            track(name..".LoadAutomatics")
            return {[1]={[1]="AH"}}
        end
        function result:LoadFactionFixes()
            track(name..".LoadFactionFixes")
            if name=="QuestieItemFixes" then
                return {[7]={[1]="CLASSIC",[2]="CLASSIC_SECOND"}}
            elseif name=="QuestieTBCItemFixes" then
                return {[7]={[1]="TBC"}}
            elseif name=="QuestieWotlkItemFixes" then
                return {[7]={[2]="WOTLK"},[8]={[1]="WOTLK_ONLY"}}
            elseif name=="QuestieWotlkNpcFixes" then
                return {[10]={[1]=faction}}
            elseif name=="QuestieQuestFixes" then
                return {[9]={[1]=faction}}
            end
            return {}
        end
        return result
    end
    local names={
        "QuestieClassicQuestReputationFixes","QuestieQuestFixes",
        "QuestieNPCFixes","QuestieItemFixes","QuestieObjectFixes",
        "QuestieTBCQuestFixes","QuestieTBCNpcFixes",
        "QuestieTBCItemFixes","QuestieTBCObjectFixes",
        "QuestieWotlkQuestFixes","QuestieWotlkNpcFixes",
        "QuestieWotlkItemFixes","QuestieWotlkObjectFixes",
    }
    local env={
        QuestieDB=db,QuestieCorrections=module,
        Questie={IsClassic=not isWotlk,IsTBC=false,
            IsWotlk=isWotlk,IsSoD=false,IsHardcore=false,
            db={global={isleOfQuelDanasPhase=0},
                profile={showEventQuests=opts.showEventQuests or false}},
            Warning=function(_,s)track("Questie.Warning:"..tostring(s))end},
        QuestieLib={equals=function(a,b)return a==b end},
        QuestieItemStartFixes={LoadAutomaticQuestStarts=function()
            track("QuestieItemStartFixes.LoadAutomaticQuestStarts")
            return {[5]={[1]=88,[2]=55},[6]={[2]=66}}
        end},
        QuestieCompat={
            Is335=is335,
            LoadCorrections=function(apply,validation)
                track("QuestieCompat.LoadCorrections")
                apply("npcData",{[1]={[1]=opts.compatValue or "H"}},
                    db.npcKeysReversed,validation)
            end,
            LoadBlacklists=function()
                track("QuestieCompat.LoadBlacklists")
            end,
        },
        QuestieItemBlacklist={Load=function()
            track("QuestieItemBlacklist.Load")
            return {[7]=3,[8]=7}
        end},
        QuestieNPCBlacklist={Load=function()
            track("QuestieNPCBlacklist.Load")
            return {}
        end},
        QuestieQuestBlacklist={
            Load=function()
                track("QuestieQuestBlacklist.Load")
                return {[9]=false,[11]=3,[12]=7}
            end,
            LoadAutoBlacklistWotlk=function()
                track("QuestieQuestBlacklist.LoadAutoBlacklistWotlk")
                return {[9]=true,[10]=true}
            end,
        },
        HardcoreBlacklist={Load=function()return{}end},
        IsleOfQuelDanas={MAX_ISLE_OF_QUEL_DANAS_PHASES=9,quests={}},
        QuestieEvent={Load=function()track("QuestieEvent.Load")end},
        C_Timer={After=function(sec,callback)
            track("C_Timer.After:"..tostring(sec))
            env.pendingCallback=callback
        end},
    }
    for _,name in ipairs(names) do env[name]=stub(name) end
    function env.QuestieQuestFixes:LoadMissingQuests()
        track("QuestieQuestFixes.LoadMissingQuests")
        db.questData[15]={[2]=0}
    end
    local prefix=flags.."\n"..filter.."\n"..minimal.."\n"..loader.."\n"..initialize
    setmetatable(env,{__index=_G})
    evaluate(prefix,env)
    return {db=db,mod=module,env=env,events=events,
        init=function()module:Initialize()end,
        minimal=function()module:MinimalInit()end}
end
local count=0
local function check(ok,name)
    assert(ok,name);count=count+1
end
do
    local v=boot()
    check(type(v.mod.Initialize)=="function" and
        type(v.mod.MinimalInit)=="function",
        "G08_I01_ACTUAL_ORIGINAL_INITIALIZE_MINIMAL_FUNCTIONS")
    check(#flags>500 and #filter>1000 and #minimal>3000 and
        #loader>700 and #initialize>3400,
        "G08_I02_COMPLETE_AUTHENTICATED_FUNCTION_SOURCE")
    v.init()
    check(containsOrdered(v.events,{
        "QuestieQuestFixes.LoadMissingQuests",
        "QuestieNPCFixes.Load","QuestieTBCNpcFixes.Load",
        "QuestieWotlkNpcFixes.LoadAutomatics",
        "QuestieWotlkNpcFixes.Load","QuestieCompat.LoadCorrections"}),
        "G08_I03_REAL_WOTLK_COMPAT_SOURCE_LAYER_ORDER")
    check(v.db.npcData[1][1]=="H",
        "G08_I04_COMPAT_LAST_CORRECTION_WINS")
    check(v.db.questData[1][2]==88,
        "G08_I05_REAL_DERIVED_HORDE_REQUIRED_RACES")
    check(v.db.questData[2][2]==0,
        "G08_I06_REAL_NEUTRAL_FACTION_DOES_NOT_FORCE_RACE")
    check(v.db.questData[3][2]==123,
        "G08_I07_EXISTING_RACE_RESTRICTION_PRESERVED")
    check(v.db.questData[4][2]==0,
        "G08_I08_NO_STARTER_NO_DERIVED_RACE")
    check(type(v.db.questData[15])=="table",
        "G08_I09_REAL_INITIALIZE_CALLS_MISSING_QUEST_LOADER")
    check(v.db.itemData[5][1]==5 and v.db.itemData[5][2]==55,
        "G08_I10_AUTO_QUEST_ITEM_START_NO_OVERWRITE")
    check(v.db.itemData[6]==nil,
        "G08_I11_AUTO_START_NO_NEW_ITEM_ENTRIES")
    check(containsOrdered(v.events,{
        "QuestieCompat.LoadCorrections",
        "QuestieItemFixes.LoadFactionFixes",
        "QuestieTBCItemFixes.LoadFactionFixes",
        "QuestieWotlkItemFixes.LoadFactionFixes",
        "QuestieCompat.LoadBlacklists"}),
        "G08_I12_REAL_MINIMAL_INIT_IN_INITIALIZE_FOLLOWS_COMPAT")
    check(v.db.itemDataOverrides[7][1]=="TBC" and
        v.db.itemDataOverrides[7][2]=="WOTLK",
        "G08_I13_REAL_FACTION_OVERRIDE_INPLACE_LAYERED_MERGE")
    check(v.db.itemDataOverrides[8][1]=="WOTLK_ONLY",
        "G08_I14_REAL_FACTION_OVERRIDE_ONLY_RECORD")
    check(v.db.itemData[7]==nil and
        v.db.itemDataOverrides[7]~=v.db.itemData[5],
        "G08_I15_EFFECTIVE_OVERRIDE_NOT_BASE_MUTATION")
    check(v.db.npcDataOverrides[10][1]=="A" and
        v.db.questDataOverrides[9][1]=="A",
        "G08_I16_FACTION_OVERRIDE_FROM_FIXTURE_MODULES")
    check(v.mod.questItemBlacklist[7]==true and
        v.mod.questItemBlacklist[8]==nil,
        "G08_I17_REAL_EXPANSION_FILTER_WOTLK_ITEM_BLACKLIST")
    check(v.mod.hiddenQuests[9]==false and
        v.mod.hiddenQuests[10]==true,
        "G08_I18_REAL_WOTLK_BLACKLIST_EXISTING_FALSE_PRECEDENCE")
    check(v.mod.hiddenQuests[11]==true and
        v.mod.hiddenQuests[12]==nil,
        "G08_I19_REAL_EXPANSION_QUEST_BLACKLIST_FILTER")
    check(containsOrdered(v.events,{
        "QuestieQuestBlacklist.LoadAutoBlacklistWotlk",
        "QuestieCompat.LoadBlacklists"}),
        "G08_I20_COMPAT_BLACKLIST_AFTER_WOTLK_ADDITIONS")
    check(not v.env.pendingCallback,
        "G08_I21_NO_UNEXPECTED_EVENT_TIMER_WITH_OPTION_DISABLED")
end
do
    local a=boot({faction="A",compatValue="A"})
    local h=boot({faction="H",compatValue="H"})
    a.init();h.init()
    check(a.db.npcData[1][1]=="A" and h.db.npcData[1][1]=="H",
        "G08_I22_SYNTHETIC_COMPAT_SOURCE_FACTION_DIFFERENCE")
    check(a.db.questData[1][2]==77 and h.db.questData[1][2]==88,
        "G08_I23_REAL_DERIVED_RACE_FROM_DIFFERENT_COMPAT_VALUES")
    check(a.db.npcDataOverrides[10][1]=="A" and
        h.db.npcDataOverrides[10][1]=="H" and
        a.db.questDataOverrides[9][1]=="A" and
        h.db.questDataOverrides[9][1]=="H",
        "G08_I24_TWO_FICTIONAL_OVERRIDE_VIEW_PAYLOADS_DISTINCT")
    check(a.db.npcDataOverrides[10]~=h.db.npcDataOverrides[10],
        "G08_I25_PER_FIXTURE_FACTION_TABLE_IDENTITY_NOT_SHARED")
end
do
    local c=boot({isWotlk=false,is335=false})
    c.init()
    check(c.db.npcData[1][1]=="A" and
        c.db.questData[1][2]==77,
        "G08_I26_REAL_CLASSIC_NO_COMPAT_SOURCE_PATH")
    check(not containsOrdered(c.events,{"QuestieTBCNpcFixes.Load"})
        and not containsOrdered(c.events,{"QuestieWotlkNpcFixes.Load"})
        and not containsOrdered(c.events,{"QuestieCompat.LoadCorrections"}),
        "G08_I27_CLASSIC_BRANCHES_EXCLUDE_TBC_WOTLK_AND_COMPAT")
    check(c.db.itemDataOverrides[7][1]=="CLASSIC" and
        c.db.itemDataOverrides[7][2]=="CLASSIC_SECOND" and
        c.db.itemDataOverrides[8]==nil,
        "G08_I28_CLASSIC_MINIMAL_OVERRIDE_ONLY_CLASSIC_LAYER")
end
do
    local e=boot({showEventQuests=true})
    e.init()
    check(containsOrdered(e.events,{"C_Timer.After:1"}) and
        type(e.env.pendingCallback)=="function",
        "G08_I29_REAL_MINIMALINIT_SCHEDULES_ONE_SECOND_EVENT_CALLBACK")
    e.env.pendingCallback()
    check(containsOrdered(e.events,{"C_Timer.After:1","QuestieEvent.Load"}),
        "G08_I30_FICTIONAL_TIMER_INVOKES_REAL_REGISTERED_CALLBACK")
end
-- The tested original methods contain plain indexed table assignments.
-- No private epoch, add-on ownership lock, exclusion or snapshot is inserted.
check(not source:find("NQ_G08_CERTIFIED_ALL_WRITERS",1,true),
    "G08_I31_NO_PRODUCTION_AUTHENTICATED_EPOCH_IN_ORIGINAL_SOURCE")
-- This confirms only explicit original source text: there is no requirement
-- to execute actual client lifecycle or load private addon mappings.
assert(count==31,"G08_REAL_INITIALIZE_CONTROL_CENSUS_CHANGED")
print("PUBLIC G08 REAL INIT AND FACTION SOURCE CONTROLS: 31/31 PASS")
print("PUBLIC G08 KNOWN RISK: protected Initialize layers built-in and 3.3.5 correction writers before derived race patch and MinimalInit; synthetic faction views are not native ownership proof.")
print("PUBLIC G08 NOT ACCEPTED: normal-client writer timing, third-party source aliases, actual IP/faction route, four-kind atomicity, disk/relog, or release.")
