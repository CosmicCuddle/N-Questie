-- Public-safe G08 read-side generation ADAPTER MODEL (test only).
-- Executes UNCHANGED original protected-335 QuestieDB:Initialize() under a
-- synthetic GetDBHandle, but coordinator/generation API are NEW/EXPERIMENTAL.
-- No production addon edits, private account data, client, ZIP or SavedVariables.
local root=assert(os.getenv("NQ_G08_READER_ADAPTER_ROOT"),"ORIGINAL_335_READER_ROOT_REQUIRED")
local f=assert(io.open(root.."/Database/QuestieDB.lua","rb"),"PINNED_335_READER_MISSING")
local source=assert(f:read("*a"));f:close()
local first="function QuestieDB:Initialize()"
local last="\nfunction QuestieDB:GetObject(objectId)"
local a=assert(source:find(first,1,true),"335_INITIALIZE_START_MISSING")
local b=assert(source:find(last,a+#first,true),"335_INITIALIZE_END_MISSING")
assert(not source:find(first,a+#first,true),"335_INITIALIZE_DUPLICATE")
local realInitialize=source:sub(a,b-1)
assert(#realInitialize>3500 and realInitialize:find(
    "QuestieDBCompiler:GetDBHandle(",1,true),"335_READER_SOURCE_TRUNCATED")
local function runOriginal(src,env)
    local compiled
    if _VERSION=="Lua 5.1" then
        compiled=assert(loadstring(src,"=protected_335_real_read_side"))
        setfenv(compiled,env)
    else
        compiled=assert(load(src,"=protected_335_real_read_side","t",env))
    end
    compiled()
end
local kinds={"npc","quest","obj","item"}
local names={"NPC","Quest","Object","Item"}
local function generated(tag,revision,count)
    local t={
        tag=tag,revision=revision,dbCompiledOnVersion="9.5.1.1",
        dbCompiledLang="enUS",dbCompiledExpansion=11,dbIsCompiled=true,
        dbCompiledCount=count or 4,nQuestieDataRevision=revision
    }
    for _,kind in ipairs(kinds) do
        t[kind.."Bin"]=tag.."_BIN_"..kind
        t[kind.."Ptrs"]=tag.."_PTR_"..kind
    end
    return t
end
local function matching(t)
    if type(t)~="table" or type(t.tag)~="string" then return false end
    if type(t.revision)~="number" or
       t.nQuestieDataRevision~=t.revision or
       t.dbIsCompiled~=true then return false end
    for _,kind in ipairs(kinds) do
        if t[kind.."Bin"]~=t.tag.."_BIN_"..kind or
           t[kind.."Ptrs"]~=t.tag.."_PTR_"..kind then return false end
    end
    return true
end
local function assemble(gen,options)
    options=options or {}
    assert(matching(gen),"INCOMPLETE_GENERATION_REJECTED")
    local record={}
    local module={
        npcCompilerTypes={},npcCompilerOrder={},npcKeys={},npcDataOverrides={},
        questCompilerTypes={},questCompilerOrder={},questKeys={},questDataOverrides={},
        objectCompilerTypes={},objectCompilerOrder={},objectKeys={},objectDataOverrides={},
        itemCompilerTypes={},itemCompilerOrder={},itemKeys={},itemDataOverrides={}
    }
    local private={
        questCache={stale=true},itemCache={stale=true},npcCache={stale=true},
        objectCache={stale=true},zoneCache={stale=true}
    }
    local compiler={counter=0}
    function compiler:BuildSkipMap()return {stub=true}end
    function compiler:GetDBHandle(bin,ptr,skipmap,keys,overrides)
        self.counter=self.counter+1
        local n=self.counter
        local kind=kinds[n]
        assert(kind,"UNEXPECTED_335_READER_HANDLE_COUNT")
        if options.failHandleAt==kind then error("FICTIONAL_READER_ERROR_"..kind,0) end
        assert(bin==gen[kind.."Bin"] and ptr==gen[kind.."Ptrs"],
            "MIXED_GENERATION_READER_INPUT")
        record[n]={kind=kind,bin=bin,ptr=ptr}
        -- Real GetDBHandle is NOT executed; each invented query retains its
        -- original input strings as an immutable closure.
        return {
            pointers=ptr,
            Query=function()return bin end,
            QuerySingle=function()return ptr end
        }
    end
    local originalGlobal={
        sod=generated("SOD",12,11)
    }
    for k,v in pairs(gen) do originalGlobal[k]=v end
    local env={
        QuestieDB=module,_QuestieDB=private,
        QuestieDBCompiler=compiler,
        Questie={IsSoD=false,db={
            global=originalGlobal,profile={disableDatabaseWarnings=false},
            char={hidden={}}
        }},
        StaticPopupDialogs={},
        l10n=function(s)return s end,
        QuestieLib={TableMemoizeFunction=function(_,fn)return fn end},
        QuestiePlayer={
            HasRequiredRace=function()return true end,
            HasRequiredClass=function()return true end
        },
        QuestieCorrections={hiddenQuests={}},
        ReloadUI=function()end
    }
    setmetatable(env,{__index=_G})
    runOriginal(realInitialize,env)
    module:Initialize()
    assert(#record==4,"INCOMPLETE_335_READER_SET")
    return {
        generation=gen,module=module,private=private,handles=record,
        env=env,
        query=function(_,which)
            if which=="npc" then return module.QueryNPC() end
            if which=="quest" then return module.QueryQuest() end
            if which=="obj" then return module.QueryObject() end
            if which=="item" then return module.QueryItem() end
            error("UNKNOWN_QUERY_KIND")
        end
    }
end
local function host(options)
    options=options or {}
    local h={
        legacy=generated("OLD",6,4),
        source={owner={},epoch=1,revision=7,available=true},
        busy=false,initializerCalls=0,stagedWrites=0
    }
    h.current=assemble(h.legacy)
    h.legacyRecord=h.current
    function h:compile()
        if self.busy then return "BUSY" end
        if not self.source.available then return "RETRY" end
        self.busy=true
        local owner=self.source.owner
        local epoch=self.source.epoch
        local revision=self.source.revision
        local count=self.current.generation.dbCompiledCount+1
        local candidate=generated("NEW_R"..revision,revision,count)
        -- Fictional compile per kind. No writes to legacy fields or live readers.
        for _,kind in ipairs(kinds) do
            self.stagedWrites=self.stagedWrites+1
            if options.failWriterAt==kind then
                self.busy=false
                return "ERROR"
            end
            if options.badPointersAt==kind then
                candidate[kind.."Ptrs"]="INCORRECT_POINTER_KIND"
            end
            coroutine.yield("prepared:"..kind)
        end
        if not self.source.available or self.source.epoch~=epoch or
           self.source.owner~=owner or self.source.revision~=revision then
            self.busy=false
            return "RETRY"
        end
        if not matching(candidate) then
            self.busy=false
            return "ERROR"
        end
        local ok,newReader=pcall(assemble,candidate,options)
        if not ok then
            self.readerError=newReader
            self.busy=false
            return "ERROR"
        end
        if not self.source.available or self.source.epoch~=epoch or
           self.source.owner~=owner or self.source.revision~=revision then
            self.busy=false
            return "RETRY"
        end
        -- This is one assignment to an invented dispatching reader pointer.
        -- The real addon has NO such dispatching pointer/API; it publishes
        -- QuestieDB.Query* and per-kind global fields separately.
        self.current=newReader
        self.busy=false
        return "SUCCESS"
    end
    function h:Stage1()
        local outcome=self:compile()
        if outcome~="SUCCESS" then return outcome end
        self.initializerCalls=self.initializerCalls+1
        return "SUCCESS"
    end
    return h
end
local checks=0
local function check(ok,label)assert(ok,label);checks=checks+1 end
local function runner(h)
    return coroutine.create(function()return h:Stage1()end)
end
local function advance(co)
    local ok,result=coroutine.resume(co)
    assert(ok,"INTERNAL_SHADOW_DRIVER_FAILED:"..tostring(result))
    return result
end
local function complete(co)
    local result
    repeat result=advance(co) until coroutine.status(co)=="dead"
    return result
end
local function allHandles(reader,tag)
    if #reader.handles~=4 then return false end
    for i,kind in ipairs(kinds) do
        local r=reader.handles[i]
        if r.kind~=kind or r.bin~=tag.."_BIN_"..kind or
           r.ptr~=tag.."_PTR_"..kind then return false end
    end
    return true
end
check(#realInitialize>3500,"A01_ORIGINAL_READER_COMPLETE_SOURCE")
check(realInitialize:find("Questie.db.global.npcBin",1,true)~=nil,
    "A02_ORIGINAL_335_DIRECT_FIELD_PATH")
check(realInitialize:find("Questie.db.global.sod.itemPtrs",1,true)~=nil,
    "A03_ORIGINAL_SOD_DIRECT_FIELD_PATH")
check(not realInitialize:find("current.generation",1,true),
    "A04_ORIGINAL_READER_NOT_THIS_ADAPTER")
local h=host()
local old=h.current
check(allHandles(old,"OLD"),"A05_LEGACY_READER_BUILT_FROM_REAL_INIT")
check(old:query("npc")=="OLD_BIN_npc","A06_ORIGINAL_READER_EXPORTED_OLD")
check(old.module.NPCPointers=="OLD_PTR_npc","A07_ORIGINAL_POINTER_HANDLE_OLD")
check(next(old.private.questCache)==nil and
      next(old.private.objectCache)==nil,"A08_ORIGINAL_READER_CACHE_RESET")
local co=runner(h)
check(advance(co)=="prepared:npc","A09_START_PRIVATE_COMPILE")
check(h.current==old,"A10_NPC_STAGING_INVISIBLE")
check(h:compile()=="BUSY","A11_EXPLICIT_BUSY_WHILE_ACTIVE")
check(h.initializerCalls==0,"A12_BUSY_DOES_NOT_INIT")
check(advance(co)=="prepared:quest","A13_QUEST_STAGE_PRIVATE")
check(advance(co)=="prepared:obj","A14_OBJECT_STAGE_PRIVATE")
check(advance(co)=="prepared:item","A15_ITEM_STAGE_PRIVATE")
check(h.current==old and old:query("item")=="OLD_BIN_item",
      "A16_ALL_STAGED_INVISIBLE_TO_LIVE_READER")
check(advance(co)=="SUCCESS","A17_STATUS_AFTER_FULL_READER_PREPARE")
check(coroutine.status(co)=="dead","A18_SOURCE_COROUTINE_TERMINATED")
check(h.current~=old,"A19_ONE_MODEL_POINTER_SWAPPED")
check(allHandles(h.current,"NEW_R7"),"A20_ALL_FOUR_NEW_HANDLES_MATCH_ONE_GENERATION")
check(h.current:query("npc")=="NEW_R7_BIN_npc" and
      h.current:query("item")=="NEW_R7_BIN_item",
      "A21_NEW_READER_DISPATCHES_NEW")
check(old:query("npc")=="OLD_BIN_npc","A22_PREVIOUS_READER_RETAINS_OLD")
check(h.current.generation.dbCompiledCount==5 and
      h.current.generation.nQuestieDataRevision==7,
      "A23_METADATA_AND_PAYLOAD_GENERATION_COHERENT")
check(h.legacy.npcBin=="OLD_BIN_npc" and
      h.legacy.itemPtrs=="OLD_PTR_item",
      "A24_LEGACY_SAVED_VARIABLES_NOT_MUTATED_IN_MODEL")
check(h.initializerCalls==1 and not h.busy,
      "A25_SUCCESS_ONE_DOWNSTREAM_INIT_AND_UNLOCK")
local second=runner(h)
check(advance(second)=="prepared:npc","A26_SECOND_GENERATION_PRIVATE")
check(complete(second)=="SUCCESS" and
      h.current.generation.dbCompiledCount==6 and
      old:query("obj")=="OLD_BIN_obj",
      "A27_SECOND_VALID_RUN_AND_OLD_HANDLE_PINNING")
local badWriter=host({failWriterAt="item"})
local beforeWriter=badWriter.current
check(complete(runner(badWriter))=="ERROR",
      "A28_FINAL_WRITER_FAILURE_IS_ERROR")
check(badWriter.current==beforeWriter and
      badWriter.legacy.npcBin=="OLD_BIN_npc",
      "A29_FINAL_WRITER_ERROR_NO_PUBLICATION")
check(badWriter.initializerCalls==0 and not badWriter.busy,
      "A30_FINAL_WRITER_ERROR_NO_INIT_AND_UNLOCK")
local invalid=host({badPointersAt="obj"})
check(complete(runner(invalid))=="ERROR" and
      invalid.current==invalid.legacyRecord,
      "A31_INVALID_POINTER_REJECTED_BEFORE_READER_BUILD")
check(invalid.initializerCalls==0 and not invalid.busy,
      "A32_INVALID_POINTER_NO_INIT")
local readerFailure=host({failHandleAt="item"})
local oldReader=readerFailure.current
check(complete(runner(readerFailure))=="ERROR",
      "A33_FOURTH_READER_FACTORY_FAILURE_IS_ERROR")
check(readerFailure.current==oldReader and
      oldReader:query("quest")=="OLD_BIN_quest",
      "A34_READER_ERROR_RETURNS_OLD_GENERATION")
check(type(readerFailure.readerError)=="string" and
      readerFailure.readerError:find("FICTIONAL_READER_ERROR_item",1,true)~=nil,
      "A35_LATE_READER_ERROR_RECORDED")
check(not readerFailure.busy and readerFailure.initializerCalls==0,
      "A36_READER_ERROR_NO_INIT_AND_UNLOCK")
local unavailable=host()
unavailable.source.available=false
check(complete(runner(unavailable))=="RETRY" and
      unavailable.current==unavailable.legacyRecord,
      "A37_MISSING_SOURCE_RETRY_NO_GENERATION")
local changing=host()
local oldChanging=changing.current
local running=runner(changing)
advance(running)
local originalOwner=changing.source.owner
changing.source.owner={};changing.source.epoch=2
changing.source.owner=originalOwner;changing.source.epoch=3
check(complete(running)=="RETRY","A38_ABA_EPOCH_INVALIDATES_READER_SET")
check(changing.current==oldChanging and
      oldChanging:query("npc")=="OLD_BIN_npc",
      "A39_ABA_LEAVES_OLD_HANDLES")
check(changing.initializerCalls==0 and not changing.busy,
      "A40_ABA_NO_INIT_AND_UNLOCK")
check(complete(runner(changing))=="SUCCESS",
      "A41_NEW_EPOCH_CAN_BUILD_VALID_READER_SET")
local changedRev=host()
local revRun=runner(changedRev)
advance(revRun)
changedRev.source.revision=8
check(complete(revRun)=="RETRY" and
      changedRev.current.generation.nQuestieDataRevision==6,
      "A42_REVISION_DRIFT_REJECTS_COMMIT")
local busy=host()
busy.busy=true
check(complete(runner(busy))=="BUSY" and
      busy.current==busy.legacyRecord and
      busy.initializerCalls==0,"A43_BUSY_NOT_SUCCESS")
local alias=host()
local legacyAlias=alias.legacy
legacyAlias.npcBin="CORRUPT_EXTERNAL_WRITE"
check(alias.current:query("npc")=="OLD_BIN_npc",
      "A44_ALREADY_CREATED_READER_PINS_OLD_INPUT")
check(alias.current.generation==legacyAlias,
      "A45_ALIAS_MUTATION_SHOWS_SEPARATE_SOURCE_WRITER_GATE")
check(matching(alias.legacy)==false,
      "A46_EXTERNAL_LEGACY_WRITE_DETECTABLE_BUT_NOT_FENCED")
local missingMetadata=generated("META",7,5)
missingMetadata.nQuestieDataRevision=6
check(not matching(missingMetadata),
      "A47_MISMATCHED_METADATA_NOT_AN_ACCEPTABLE_GENERATION")
local incomplete=generated("INCOMPLETE",7,5)
incomplete.itemPtrs=nil
check(not matching(incomplete),
      "A48_MISSING_FOURTH_PTRS_FAILS_COHERENCE_CHECK")
assert(checks==48,"G08_READER_ADAPTER_ASSERTION_CENSUS_CHANGED")
print("PUBLIC G08 PART43 REAL READER SHADOW ADAPTER: 48/48 PASS")
print("PUBLIC G08 TEST-ONLY CONTRACT: unchanged original reader builds each private generation; only a model dispatch pointer moves after all four handles succeed; BUSY/RETRY/ERROR keep old queries.")
print("PUBLIC G08 NOT ACCEPTED: new coordinator API and GetDBHandle stub are fictional; no production 335 query dispatcher, E01-E08/QuestieStream ownership, real disk/native IP or ZIP/install/merge/release.")
