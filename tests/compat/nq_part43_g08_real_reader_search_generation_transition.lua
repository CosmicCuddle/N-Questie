-- PUBLIC SAFE, TEST ONLY: unchanged protected-335 QuestieDB:Initialize()
-- and entire original QuestieSearch.lua run together against invented records.
-- Proposed generation coordinator is SHADOW ONLY. GetDBHandle is NOT real.
local root=assert(os.getenv("NQ_G08_ORIGINAL_READER_SEARCH_ROOT"),"PINNED_ORIGINAL_ROOT_REQUIRED")
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"),"ORIGINAL_FILE_MISSING:"..path)
    local data=assert(f:read("*a"));f:close()
    return data
end
local dbSource=read("Database/QuestieDB.lua")
local searchSource=read("Modules/Journey/QuestieSearch.lua")
local resultsSource=read("Modules/Journey/QuestieSearchResults.lua")
local availableSource=read("Modules/Quest/AvailableQuests.lua")
local first="function QuestieDB:Initialize()"
local last="\nfunction QuestieDB:GetObject(objectId)"
local a=assert(dbSource:find(first,1,true),"REAL_DB_INIT_START_MISSING")
local b=assert(dbSource:find(last,a+#first,true),"REAL_DB_INIT_END_MISSING")
assert(not dbSource:find(first,a+#first,true),"REAL_DB_INIT_NOT_UNIQUE")
local realInit=dbSource:sub(a,b-1)
local function compile(source,env,chunkname)
    local fn
    if _VERSION=="Lua 5.1" then
        fn=assert(loadstring(source,chunkname))
        setfenv(fn,env)
    else
        fn=assert(load(source,chunkname,"t",env))
    end
    return fn()
end
local checks=0
local function check(cond,label)
    assert(cond,label)
    checks=checks+1
end
local kinds={"npc","quest","obj","item"}
local queryNames={npc="NPC",quest="Quest",obj="Object",item="Item"}
local searchKinds={npc="npc",quest="quest",obj="object",item="item"}
local kindIndex={npc=100,quest=400,obj=200,item=300}
local function makeGeneration(label,revision,count)
    local g={tag=label,revision=revision,dbCompiledCount=count,
        dbCompiledOnVersion="9.5.1.1",dbCompiledLang="enUS",
        dbCompiledExpansion=11,nQuestieDataRevision=revision,dbIsCompiled=true}
    for _,kind in ipairs(kinds) do
        local key=kindIndex[kind]+(label=="OLD" and 1 or 2)
        local ptr={[key]=true,[key+10]=true}
        g[kind.."Bin"]=label.."_BIN_"..kind
        g[kind.."Ptrs"]=ptr
        g[kind.."Records"]={
            [key]={name=label.." token "..kind.." "..tostring(key)},
            [key+10]={name=label.." token "..kind.." "..tostring(key+10)}
        }
    end
    return g
end
local function count(t)
    local n=0;for _ in pairs(t or {}) do n=n+1 end;return n
end
local function coherent(g)
    if type(g)~="table" or type(g.tag)~="string" or
       g.nQuestieDataRevision~=g.revision or g.dbIsCompiled~=true then
        return false
    end
    for _,kind in ipairs(kinds) do
        if g[kind.."Bin"]~=g.tag.."_BIN_"..kind or
           type(g[kind.."Ptrs"])~="table" or
           type(g[kind.."Records"])~="table" then return false end
        for id in pairs(g[kind.."Ptrs"]) do
            if not g[kind.."Records"][id] then return false end
        end
    end
    return true
end
local function makeReader(g,opts)
    opts=opts or {}
    assert(coherent(g),"READER_GENERATION_INCOHERENT")
    local module={
        npcCompilerTypes={},npcCompilerOrder={},npcKeys={},npcDataOverrides={},
        questCompilerTypes={},questCompilerOrder={},questKeys={},questDataOverrides={},
        objectCompilerTypes={},objectCompilerOrder={},objectKeys={},objectDataOverrides={},
        itemCompilerTypes={},itemCompilerOrder={},itemKeys={},itemDataOverrides={}
    }
    local compiler={created=0}
    function compiler:BuildSkipMap()return {}end
    function compiler:GetDBHandle(bin,ptr,skip,keys,overrides)
        self.created=self.created+1
        local kind=assert(kinds[self.created],"TOO_MANY_READER_HANDLES")
        if opts.failReaderAt==kind then error("FICTIONAL_READER_FAILURE_"..kind,0) end
        assert(bin==g[kind.."Bin"] and ptr==g[kind.."Ptrs"],
            "MIXED_READER_INPUT_DETECTED")
        local data=g[kind.."Records"]
        return {
            pointers=ptr,
            QuerySingle=function(id,key) return data[id] and data[id][key] end,
            Query=function(id,query)
                local record=data[id]
                if not record then return nil end
                if type(query)=="table" then
                    local out={}
                    for i,key in ipairs(query) do out[i]=record[key] end
                    return out
                end
                return record
            end
        }
    end
    local private={questCache={stale=true},itemCache={stale=true},
        npcCache={stale=true},objectCache={stale=true},zoneCache={stale=true}}
    local legacy={sod={}}
    for key,value in pairs(g) do legacy[key]=value end
    local env={
        QuestieDB=module,_QuestieDB=private,QuestieDBCompiler=compiler,
        Questie={IsSoD=false,db={global=legacy,
            profile={disableDatabaseWarnings=false},char={hidden={}}}},
        QuestieLib={TableMemoizeFunction=function(_,fn)return fn end},
        QuestieCorrections={hiddenQuests={}},
        QuestiePlayer={HasRequiredRace=function()return true end,
            HasRequiredClass=function()return true end},
        StaticPopupDialogs={},l10n=function(s)return s end,ReloadUI=function()end
    }
    setmetatable(env,{__index=_G})
    compile(realInit,env,"=real_335_questiedb_initialize")
    module:Initialize()
    assert(compiler.created==4,"NOT_FOUR_REAL_SOURCE_INITIALIZED_HANDLES")
    local search
    env.QuestieLoader={
        CreateModule=function(_,name)
            assert(name=="QuestieSearch","UNEXPECTED_REAL_SEARCH_MODULE")
            search={}
            return search
        end,
        ImportModule=function(_,name)
            assert(name=="QuestieDB","UNEXPECTED_SEARCH_IMPORT")
            return module
        end
    }
    compile(searchSource,env,"=real_335_questiesearch")
    assert(type(search.Search)=="function" and
           type(search.ByName)=="function","REAL_SEARCH_FUNCTIONS_MISSING")
    return {generation=g,db=module,search=search,
        private=private,env=env,compiler=compiler}
end
local function expectedId(kind,label)
    return kindIndex[kind]+(label=="OLD" and 1 or 2)
end
local function correct(reader,label)
    for _,kind in ipairs(kinds) do
        local id=expectedId(kind,label)
        local query=reader.db["Query"..queryNames[kind].."Single"]
        local ptr=reader.db[queryNames[kind].."Pointers"]
        if ptr[id]~=true or count(ptr)~=2 or
           query(id,"name")~=(label.." token "..kind.." "..tostring(id)) then
            return false
        end
    end
    return true
end
local function searchMatches(reader,label,method)
    method=method or "ByName"
    local r=reader.search[method](reader.search,"token")
    return count(r.npc)==2 and count(r.object)==2 and
        count(r.item)==2 and count(r.quest)==2 and
        r.npc[expectedId("npc",label)]==true and
        r.npc[expectedId("npc",label=="OLD" and "NEW" or "OLD")]==nil
end
local function model(opts)
    opts=opts or {}
    local h={source={owner={},epoch=1,revision=7,available=true},
       busy=false,staged=0,downstream=0,legacy=makeGeneration("OLD",6,4)}
    h.current=makeReader(h.legacy)
    h.original=h.current
    function h:Stage1()
        if self.busy then return "BUSY" end
        if not self.source.available then return "RETRY" end
        self.busy=true
        local owner,epoch,revision=self.source.owner,self.source.epoch,self.source.revision
        local candidate=makeGeneration("NEW",revision,
            self.current.generation.dbCompiledCount+1)
        for _,kind in ipairs(kinds) do
            self.staged=self.staged+1
            if opts.failWriterAt==kind then
                self.busy=false
                return "ERROR"
            end
            if opts.badPointerAt==kind then
                candidate[kind.."Ptrs"][9999]=true
            end
            coroutine.yield("staged:"..kind)
        end
        if not self.source.available or self.source.owner~=owner or
           self.source.epoch~=epoch or self.source.revision~=revision then
            self.busy=false
            return "RETRY"
        end
        if not coherent(candidate) then
            self.busy=false
            return "ERROR"
        end
        local ok,prepared=pcall(makeReader,candidate,opts)
        if not ok then
            self.lastReaderError=prepared
            self.busy=false
            return "ERROR"
        end
        -- Cache built privately, original old module is never cleared.
        -- New Search is a fresh module; the unmodified ByName is executed
        -- before the model pointer selection as a read-side preflight.
        if not searchMatches(prepared,"NEW") then
            self.busy=false
            return "ERROR"
        end
        if not self.source.available or self.source.owner~=owner or
           self.source.epoch~=epoch or self.source.revision~=revision then
            self.busy=false
            return "RETRY"
        end
        -- Model-only no-yield pointer selection, NOT actual QuestieDB exports.
        self.current=prepared
        self.busy=false
        self.downstream=self.downstream+1
        return "SUCCESS"
    end
    return h
end
local function newThread(h)
    return coroutine.create(function()return h:Stage1()end)
end
local function tick(co)
    local ok,value=coroutine.resume(co)
    assert(ok,"SHADOW_DRIVER_ERROR:"..tostring(value))
    return value
end
local function drain(co)
    local value
    repeat value=tick(co) until coroutine.status(co)=="dead"
    return value
end

check(#realInit>3500,"T01_WHOLE_REAL_335_DB_INITIALIZE_EXTRACTED")
check(searchSource:find("databaseKeys = QuestieDB.QuestPointers",1,true)~=nil,
      "T02_REAL_SEARCH_QUEST_POINTER_REFERENCE")
check(searchSource:find("QuestieSearch.LastResult[searchType][id] = true",1,true)~=nil,
      "T03_REAL_SEARCH_RESULT_CACHE_WRITE")
check(searchSource:find("function QuestieSearch:ByName(query)",1,true)~=nil,
      "T04_REAL_SEARCH_RESET_ENTRYPOINT")
check(resultsSource:find('AddLinkedParagraph(details, "npc", startedBy[1]',1,true)~=nil,
      "T05_SEARCH_RESULTS_CALLBACK_CONSUMER_ANCHORED")
check(availableSource:find("local questData = QuestieDB.QuestPointers or QuestieDB.questData",1,true)~=nil,
      "T06_AVAILABLE_QUESTS_POINTER_ALIAS_ANCHORED")
local h=model()
local prior=h.current
check(correct(prior,"OLD"),"T07_REAL_DB_READER_OLD_FOUR_KINDS_COHERENT")
check(prior.compiler.created==4,"T08_REAL_DB_INIT_FOUR_HANDLE_FACTORY_CALLS")
check(searchMatches(prior,"OLD"),"T09_REAL_SEARCH_OLD_FOUR_KINDS")
check(prior.search.LastResult.npc[101]==true and
      prior.search.LastResult.npc[102]==nil,
      "T10_OLD_SEARCH_CACHED_ONLY_OLD_ID")
check(next(prior.private.questCache)==nil and
      next(prior.private.itemCache)==nil,
      "T11_REAL_DB_INIT_RESETS_FIVE_CACHES")
local run=newThread(h)
check(tick(run)=="staged:npc","T12_NPC_STAGED_PRIVATELY")
check(h.current==prior,"T13_OLD_READER_PINNED_AFTER_NPC")
check(h:Stage1()=="BUSY","T14_BUSY_STATUS_DISTINCT_FROM_SUCCESS")
check(h.downstream==0,"T15_BUSY_NO_DOWNSTREAM_READY")
check(tick(run)=="staged:quest","T16_QUEST_STAGED_PRIVATELY")
check(tick(run)=="staged:obj","T17_OBJECT_STAGED_PRIVATELY")
check(tick(run)=="staged:item","T18_ITEM_STAGED_PRIVATELY")
check(h.current==prior and prior.search.LastResult.npc[101]==true,
      "T19_ALL_STAGED_NO_LIVE_CHANGE")
check(tick(run)=="SUCCESS","T20_READY_AFTER_COMPLETE_COMMIT")
check(coroutine.status(run)=="dead","T21_COMMIT_COROUTINE_FINISHED")
check(h.current~=prior,"T22_MODEL_GENERATION_POINTER_CHANGED")
check(correct(h.current,"NEW"),"T23_REAL_DB_NEW_FOUR_HANDLES_COHERENT")
check(searchMatches(h.current,"NEW"),"T24_REAL_SEARCH_NEW_FOUR_KINDS")
check(h.current.search.LastResult.npc[101]==nil and
      h.current.search.LastResult.npc[102]==true,
      "T25_NEW_SEARCH_HAS_NO_OLD_CACHED_IDS")
check(prior.search.LastResult.npc[101]==true and
      prior.search.LastResult.npc[102]==nil,
      "T26_OLD_SEARCH_KEEPS_ITS_OWN_CACHE")
check(prior.db.QueryNPCSingle(101,"name")=="OLD token npc 101",
      "T27_PREVIOUS_QUERY_FUNCTION_REMAINS_OLD")
check(prior.db.NPCPointers[101]==true and
      prior.db.NPCPointers[102]==nil,
      "T28_PREVIOUS_POINTER_MAP_REMAINS_OLD")
check(h.legacy.npcBin=="OLD_BIN_npc" and
      h.legacy.nQuestieDataRevision==6,
      "T29_LEGACY_GLOBAL_STATE_NOT_CHANGED")
check(h.current.generation.nQuestieDataRevision==7 and
      h.current.generation.dbCompiledCount==5,
      "T30_NEW_DATA_REVISION_AND_COUNT_MATCH_COMMIT")
check(h.downstream==1 and h.busy==false,
      "T31_SUCCESS_ONE_READY_SIGNAL_AND_UNLOCK")
local later=newThread(h)
tick(later)
check(h.current.search.LastResult.npc[102]==true,
      "T32_SECOND_STAGE_PRESERVES_CURRENT_NEW_SEARCH")
check(drain(later)=="SUCCESS" and h.downstream==2,
      "T33_SECOND_SUCCESS_REUSES_GENERATION_MODEL")
check(prior.db.QueryNPCSingle(101,"name")=="OLD token npc 101",
      "T34_OLDER_READER_PINNED_THROUGH_TWO_COMMITS")
local lateWriter=model({failWriterAt="item"})
local preWriter=lateWriter.current
check(drain(newThread(lateWriter))=="ERROR",
      "T35_FINAL_ITEM_WRITER_FAULT_ERROR")
check(lateWriter.current==preWriter and lateWriter.downstream==0,
      "T36_WRITER_FAULT_PRESERVES_OLD_SEARCH_AND_READERS")
check(searchMatches(lateWriter.current,"OLD") and not lateWriter.busy,
      "T37_WRITER_FAULT_LEAVES_SEARCH_FUNCTIONAL")
local badPointer=model({badPointerAt="quest"})
local beforeBad=badPointer.current
check(drain(newThread(badPointer))=="ERROR",
      "T38_INCONSISTENT_PTR_MAP_ABORT")
check(badPointer.current==beforeBad and badPointer.downstream==0,
      "T39_PTR_MAP_ABORT_NO_CACHE_REPLACEMENT")
local lateHandle=model({failReaderAt="item"})
local oldHandle=lateHandle.current
check(drain(newThread(lateHandle))=="ERROR",
      "T40_FOURTH_READER_BUILD_FAULT_ERROR")
check(lateHandle.current==oldHandle and lateHandle.downstream==0 and
      tostring(lateHandle.lastReaderError):find("FICTIONAL_READER_FAILURE_item",1,true)~=nil,
      "T41_READER_BUILD_ABORT_PRESERVES_OLD")
check(searchMatches(oldHandle,"OLD") and not lateHandle.busy,
      "T42_READER_ERROR_OLD_SEARCH_STILL_WORKS")
local aba=model()
local oldAba=aba.current
local race=newThread(aba)
tick(race)
local priorOwner=aba.source.owner
aba.source.owner={};aba.source.epoch=2
aba.source.owner=priorOwner;aba.source.epoch=3
check(drain(race)=="RETRY","T43_ABA_WITH_RESTORED_ID_REJECTED")
check(aba.current==oldAba and aba.downstream==0,
      "T44_ABA_KEEPS_OLD_READER_AND_CACHE")
check(searchMatches(aba.current,"OLD") and not aba.busy,
      "T45_ABA_OLD_SEARCH_STILL_WORKS")
local drift=model()
local oldDrift=drift.current
local co=newThread(drift)
tick(co)
drift.source.revision=8
check(drain(co)=="RETRY" and drift.current==oldDrift,
      "T46_SOURCE_REVISION_DRIFT_RETRY")
local missing=model()
missing.source.available=false
check(drain(newThread(missing))=="RETRY" and
      missing.staged==0 and missing.downstream==0,
      "T47_SOURCE_UNAVAILABLE_NO_COMPILE")
local busy=model()
busy.busy=true
check(drain(newThread(busy))=="BUSY" and busy.staged==0,
      "T48_ALREADY_BUSY_NO_FALSE_SUCCESS")
-- Show why updating the actual *public* old Query + Pointers exports
-- without resetting the actual old QuestieSearch LastResult is inadequate.
local unsafe=makeReader(makeGeneration("OLD",6,4))
check(searchMatches(unsafe,"OLD"),"T49_UNSAFE_FIXTURE_FIRST_OLD_SEARCH")
local replacement=makeReader(makeGeneration("NEW",7,5))
for _,kind in ipairs(kinds) do
    local upper=queryNames[kind]
    unsafe.db["Query"..upper.."Single"]=
        replacement.db["Query"..upper.."Single"]
    unsafe.db[upper.."Pointers"]=replacement.db[upper.."Pointers"]
end
local mixedResult=unsafe.search:Search("token","npc")
check(count(mixedResult)==4 and mixedResult[101]==true and
      mixedResult[102]==true,
      "T50_LEGACY_DIRECT_SEARCH_RETAINS_OLD_AND_NEW_IDS")
check(searchMatches(unsafe,"NEW") and
      unsafe.search.LastResult.npc[101]==nil,
      "T51_BYNAME_RESETS_OLD_SEARCH_RESULTS")
check(replacement.db.QueryQuestSingle(402,"name")=="NEW token quest 402",
      "T52_INDEPENDENT_REPLACEMENT_QUERY_STAYS_NEW")
check(unsafe.db.NPCPointers[102]==true and
      unsafe.db.NPCPointers[101]==nil,
      "T53_REBOUND_LEGACY_POINTERS_NOW_NEW")
check(prior.db.NPCPointers[101]==true and
      prior.db.QueryNPCSingle(101,"name")=="OLD token npc 101",
      "T54_OTHER_OLD_READER_NOT_AFFECTED_BY_DELIBERATE_REBIND")
assert(checks==54,"G08_ORIGINAL_READER_SEARCH_TEST_CENSUS_CHANGED")
print("PUBLIC G08 PART43 ORIGINAL READER SEARCH GENERATION TRANSITION: 54/54 PASS")
print("PUBLIC G08 TEST-ONLY WITNESS: unchanged 335 DB Initialize and Journey Search execute together; private read-side generations and fresh search caches prevent OLD IDs entering NEW reader selection in the model.")
print("PUBLIC G08 KNOWN-UNSAFE REBIND: changing public query functions and pointer maps without resetting original Search LastResult retains OLD and NEW IDs together.")
print("PUBLIC G08 NOT ACCEPTED: coordinator and GetDBHandle decoder are fictional; no actual 335 production query dispatcher, QuestieStream/real writer, SavedVariables disk/relog, native 3.3.5a/IP or ZIP/install/merge/release.")
