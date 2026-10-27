-- Gate08 Part36: actual pinned Questie four-kind compiler stage seam.
-- Fictional records only; no WoW client, private SQL, source ownership, or IP.
-- This verifies local staging, NOT an all-eight-field commit/stream recovery.
unpack = unpack or table.unpack
tremove = table.remove
local function band(a,b)
    local result,place=0,1
    for _=1,32 do
        if a%2==1 and b%2==1 then result=result+place end
        a,b,place=math.floor(a/2),math.floor(b/2),place*2
    end
    return result
end
bit={
    band=band,
    lshift=function(n,s) return (n*2^s)%4294967296 end,
    rshift=function(n,s) return math.floor((n%4294967296)/2^s) end,
}
local modules={}
QuestieLoader={
    CreateModule=function(_,name)
        modules[name]=modules[name] or {}
        return modules[name]
    end,
    ImportModule=function(_,name)
        assert(modules[name],"missing Questie module "..name)
        return modules[name]
    end,
}
for _,kind in ipairs({"QuestieDB","QuestieLib","l10n"}) do QuestieLoader:CreateModule(kind) end
QuestieCompat={Is335=true,WOW_PROJECT_ID=2}
Questie={
    IsSoD=false,IsTBC=false,IsWotlk=true,
    db={profile={debugEnabled=false},global={}},
    Error=function(_,...) error("synthetic Questie error: "..tostring((...)),0) end,
    Debug=function()end,
}
assert(loadfile("Modules/QuestieStream.lua"))()
for _,file in ipairs({"npcDB","objectDB","questDB","itemDB"}) do
    assert(loadfile("Database/"..file..".lua"))()
end
assert(loadfile("Database/compiler.lua"))()
local db=QuestieLoader:ImportModule("QuestieDB")
local compiler=QuestieLoader:ImportModule("DBCompiler")
db.npcData={[77101]={[db.npcKeys.name]="Invented NPC"}}
db.objectData={[77201]={[db.objectKeys.name]="Invented Object"}}
db.questData={[77301]={[db.questKeys.name]="Invented Quest"}}
db.itemData={[77401]={[db.itemKeys.name]="Invented Item"}}
local categories={
    {kind="npc",fn="CompileNPCs",id=77101,tableKeys="npcKeys",
        schema="npc",name="Invented NPC"},
    {kind="obj",fn="CompileObjects",id=77201,tableKeys="objectKeys",
        schema="object",name="Invented Object"},
    {kind="quest",fn="CompileQuests",id=77301,tableKeys="questKeys",
        schema="quest",name="Invented Quest"},
    {kind="item",fn="CompileItems",id=77401,tableKeys="itemKeys",
        schema="item",name="Invented Item"},
}
local saved=Questie.db.global
for _,entry in ipairs(categories) do
    saved[entry.kind.."Bin"]="OLD_BIN_"..entry.kind
    saved[entry.kind.."Ptrs"]="OLD_PTRS_"..entry.kind
end
saved.nQuestieDataRevision=57
saved.dbIsCompiled=true
saved.dbCompiledCount=9
local tests=0
local function check(label,ok)
    tests=tests+1
    assert(ok,"FAIL GATE08 STAGE "..tests.." "..label)
    print("PASS GATE08 STAGE "..tests.." "..label)
end
local function drive(fn)
    local thread=coroutine.create(fn)
    for _=1,256 do
        local ok,result=coroutine.resume(thread)
        assert(ok,tostring(result))
        if coroutine.status(thread)=="dead" then return result end
    end
    error("Gate08 synthetic compiler coroutine exceeded 256 resumes")
end
check("actual source compiler wrappers exposed",type(compiler.CompileNPCs)=="function"
    and type(compiler.CompileObjects)=="function"
    and type(compiler.CompileQuests)=="function"
    and type(compiler.CompileItems)=="function")
local stage={}
for _,entry in ipairs(categories) do
    local prefix=entry.kind
    drive(function() return compiler[entry.fn](compiler,stage) end)
    check(prefix.." staged real nonempty bytes and pointer map",
        type(stage[prefix.."Bin"])=="string" and #stage[prefix.."Bin"]>0
        and type(stage[prefix.."Ptrs"])=="string" and #stage[prefix.."Ptrs"]>0)
    check(prefix.." live pair and revision stayed untouched",
        saved[prefix.."Bin"]=="OLD_BIN_"..prefix
        and saved[prefix.."Ptrs"]=="OLD_PTRS_"..prefix
        and saved.nQuestieDataRevision==57 and saved.dbCompiledCount==9)
    local handle=drive(function()
        return compiler:GetDBHandle(stage[prefix.."Bin"],stage[prefix.."Ptrs"],
            compiler:BuildSkipMap(db[entry.schema.."CompilerTypes"],
                db[entry.schema.."CompilerOrder"]),db[entry.tableKeys],nil)
    end)
    check(prefix.." real reader returns original synthetic name",
        handle.QuerySingle(entry.id,"name")==entry.name)
    handle.stream:finished()
end
local keys=0
for _,entry in ipairs(categories) do
    if type(stage[entry.kind.."Bin"])=="string" then keys=keys+1 end
    if type(stage[entry.kind.."Ptrs"])=="string" then keys=keys+1 end
end
check("exact eight distinct fields staged without publication",keys==8)
drive(function()compiler:CompileNPCs()end)
check("legacy no-stage NPC compiler still writes SavedVariables",
    type(saved.npcBin)=="string" and saved.npcBin~="OLD_BIN_npc"
    and type(saved.npcPtrs)=="string" and saved.npcPtrs~="OLD_PTRS_npc")
local okBadStage=pcall(function()
    drive(function() compiler:CompileObjects("not a staging table") end)
end)
check("invalid stage object is rejected before publication",not okBadStage)
db.itemData={[77401]={[db.itemKeys.name]={99}}}
local failingStage={}
local okBadCodec=pcall(function()
    drive(function()compiler:CompileItems(failingStage)end)
end)
check("malformed final item stage fails closed",not okBadCodec
    and failingStage.itemBin==nil and failingStage.itemPtrs==nil)
check("failed later stage cannot change previous saved fields or metadata",
    saved.itemBin=="OLD_BIN_item" and saved.itemPtrs=="OLD_PTRS_item"
    and saved.objBin=="OLD_BIN_obj" and saved.questBin=="OLD_BIN_quest"
    and saved.nQuestieDataRevision==57 and saved.dbCompiledCount==9)
-- Inject a throwing writer finished() AFTER Save and pointer encoding,
-- but BEFORE either caller-owned stage field may be updated. The driver
-- must quarantine this poisoned writer in a future integration; do NOT retry.
local function writerOwner()
    for index=1,40 do
        local name,value=debug.getupvalue(compiler.CompileTableCoroutine,index)
        if name=="QuestieStream" then
            assert(type(value)=="table" and type(value.GetStream)=="function")
            return value
        end
        if name==nil then break end
    end
    error("pinned compiler writer-stream owner unavailable")
end
local owner=writerOwner()
local originalGetStream=owner.GetStream
local attempts=0
owner.GetStream=function(self,mode)
    local s=originalGetStream(self,mode)
    s.finished=function()
        attempts=attempts+1
        error("SYNTHETIC_STAGE_FINISH_FAILURE",0)
    end
    return s
end
local poisonedStage={objBin="PRIOR_BIN",objPtrs="PRIOR_PTRS"}
local finishOk,finishErr=pcall(function()
    drive(function() compiler:CompileObjects(poisonedStage) end)
end)
owner.GetStream=originalGetStream
check("writer finish failure is reported rather than accepted",
    not finishOk and tostring(finishErr):find("SYNTHETIC_STAGE_FINISH_FAILURE",1,true)~=nil
    and attempts==1 and owner.GetStream==originalGetStream)
check("writer finish failure preserves both old staged fields",
    poisonedStage.objBin=="PRIOR_BIN" and poisonedStage.objPtrs=="PRIOR_PTRS")
check("writer finish failure leaves live objects and revision unchanged",
    saved.objBin=="OLD_BIN_obj" and saved.objPtrs=="OLD_PTRS_obj"
    and saved.nQuestieDataRevision==57 and saved.dbCompiledCount==9)
-- Part36 Gate08 follow-up: driver-owned writer leases pass DIRECTLY to the
-- real staged compiler. This avoids globally replacing GetStream. Ownership
-- is demonstrated here, not yet installed as the production Stage1 driver.
db.itemData={[77401]={[db.itemKeys.name]="Invented Item"}}
local realGlobalGet=owner.GetStream
local function newLeaseDriver(opts)
    opts=opts or {}
    local busy=false
    local leases,finishAttempts={},0
    local stage={npcBin="OLD_STAGE_NPC",npcPtrs="OLD_STAGE_NPC_PTRS"}
    local leaseOwner={}
    function leaseOwner:Acquire(streamParent,mode)
        assert(streamParent==owner and (mode=="raw" or mode=="raw_assert"))
        if opts.failAcquire then error("SYNTHETIC_ACQUIRE_BEFORE_POOL",0) end
        local s=streamParent:GetStream(mode)
        local lease={stream=s,done=false,releasing=false,poolTouched=false,attempts=0}
        leases[#leases+1]=lease
        if opts.stallAfterAcquire then
            while true do coroutine.yield("SYNTHETIC_WRITER_STALLED") end
        end
        return lease
    end
    function leaseOwner:Finish(lease)
        assert(type(lease)=="table" and not lease.done and not lease.releasing)
        lease.releasing=true
        lease.attempts=lease.attempts+1
        finishAttempts=finishAttempts+1
        if opts.failBeforePool then error("SYNTHETIC_FINISH_BEFORE_POOL",0) end
        lease.stream:finished()
        lease.poolTouched=true
        if opts.failAfterPool then error("SYNTHETIC_FINISH_AFTER_POOL",0) end
        lease.done=true
        lease.releasing=false
    end
    stage._nqWriterLeaseOwner=leaseOwner
    local function run()
        if busy then return {status="BUSY",stage=stage,leases=leases,
            finishAttempts=finishAttempts,busy=busy} end
        busy=true
        local co=coroutine.create(function()
            for _,entry in ipairs(categories) do
                compiler[entry.fn](compiler,stage)
            end
            return "SUCCESS"
        end)
        local status,reason,dead=nil,nil,false
        for _=1,(opts.budget or 256) do
            local ok,value=coroutine.resume(co)
            dead=coroutine.status(co)=="dead"
            if not ok then status,reason="ERROR",tostring(value);break end
            if dead then status=value;break end
        end
        dead=coroutine.status(co)=="dead"
        if not status then status="ABORTED_QUARANTINED" end
        local quarantined=not dead
        if dead then
            for _,lease in ipairs(leases) do
                if not lease.done then
                    if lease.releasing then
                        -- Any throwing finished() is pool-unknown. Never retry it.
                        quarantined=true
                    else
                        -- Called only after coroutine is DEAD. No pcall wraps a yield.
                        lease.releasing=true
                        lease.attempts=lease.attempts+1
                        finishAttempts=finishAttempts+1
                        local ok=pcall(lease.stream.finished,lease.stream)
                        if ok then
                            lease.done=true
                            lease.releasing=false
                            lease.poolTouched=true
                        else
                            quarantined=true
                            status="ERROR"
                        end
                    end
                end
            end
        end
        if quarantined then
            busy=true -- Intentional fail-stop: do not resume a suspended thread.
        else
            busy=false
        end
        return {status=status,reason=reason,stage=stage,leases=leases,
            finishAttempts=finishAttempts,busy=busy,quarantined=quarantined,
            dead=dead}
    end
    return run
end

local ownedSuccess=newLeaseDriver()()
check("explicit writer owner stages all four real compiler categories",
    ownedSuccess.status=="SUCCESS" and ownedSuccess.dead
    and #ownedSuccess.leases==4 and ownedSuccess.finishAttempts==4
    and type(ownedSuccess.stage.itemBin)=="string"
    and type(ownedSuccess.stage.questPtrs)=="string")
local completed=true
for _,lease in ipairs(ownedSuccess.leases) do
    if not lease.done or lease.releasing or not lease.poolTouched
        or lease.attempts~=1 then completed=false end
end
check("each successful writer lease finished exactly once and unlocked",
    completed and not ownedSuccess.busy and not ownedSuccess.quarantined)
check("explicit leased compiler preserved live generation and GetStream",
    saved.objBin=="OLD_BIN_obj" and saved.questBin=="OLD_BIN_quest"
    and saved.nQuestieDataRevision==57 and owner.GetStream==realGlobalGet)

db.objectData={[77201]={[db.objectKeys.name]={99}}}
local failedWrite=newLeaseDriver()()
db.objectData={[77201]={[db.objectKeys.name]="Invented Object"}}
check("malformed GO codec terminates with DEAD owned writer cleanup",
    failedWrite.status=="ERROR" and failedWrite.dead and not failedWrite.busy
    and not failedWrite.quarantined and #failedWrite.leases==2
    and failedWrite.leases[1].done and failedWrite.leases[2].done
    and failedWrite.leases[2].attempts==1)
check("malformed GO never exposes partially encoded GO scratch pair",
    failedWrite.stage.objBin==nil and failedWrite.stage.objPtrs==nil
    and saved.objBin=="OLD_BIN_obj")

local failBeforeRun=newLeaseDriver({failAcquire=true})
local failedAcquire=failBeforeRun()
check("pre-acquire failure creates zero writer leases and unlocks",
    failedAcquire.status=="ERROR" and failedAcquire.dead and not failedAcquire.busy
    and #failedAcquire.leases==0 and failedAcquire.finishAttempts==0)

local beforeRun=newLeaseDriver({failBeforePool=true})
local poisonedBefore=beforeRun()
check("failed writer finish before pool quarantines without second attempt",
    poisonedBefore.status=="ERROR" and poisonedBefore.dead
    and poisonedBefore.quarantined and poisonedBefore.busy
    and #poisonedBefore.leases==1 and poisonedBefore.finishAttempts==1
    and not poisonedBefore.leases[1].poolTouched
    and poisonedBefore.stage.npcBin=="OLD_STAGE_NPC"
    and poisonedBefore.stage.npcPtrs=="OLD_STAGE_NPC_PTRS"
    and beforeRun().status=="BUSY")

local afterRun=newLeaseDriver({failAfterPool=true})
local poisonedAfter=afterRun()
check("pool-return-then-throw quarantines and never retries finished",
    poisonedAfter.status=="ERROR" and poisonedAfter.dead
    and poisonedAfter.quarantined and poisonedAfter.busy
    and poisonedAfter.finishAttempts==1
    and poisonedAfter.leases[1].poolTouched
    and poisonedAfter.leases[1].attempts==1
    and poisonedAfter.stage.npcBin=="OLD_STAGE_NPC"
    and poisonedAfter.stage.npcPtrs=="OLD_STAGE_NPC_PTRS"
    and afterRun().status=="BUSY")

local suspendRun=newLeaseDriver({stallAfterAcquire=true,budget=4})
local suspended=suspendRun()
check("suspended acquired writer is never returned or resumed",
    suspended.status=="ABORTED_QUARANTINED" and not suspended.dead
    and suspended.quarantined and suspended.busy
    and #suspended.leases==1 and not suspended.leases[1].done
    and suspended.finishAttempts==0 and suspendRun().status=="BUSY")

local rejectedStage={_nqWriterLeaseOwner={}}
local invalidOwner=pcall(function()
    drive(function()compiler:CompileNPCs(rejectedStage)end)
end)
check("unimplemented writer lease owner contract is refused before acquire",
    not invalidOwner and rejectedStage.npcBin==nil and
    rejectedStage.npcPtrs==nil and owner.GetStream==realGlobalGet)
-- Part36 Gate08 reader-owned pre-handle acquisition. The real
-- GetDBHandle yields before it loads pointers. The caller driver (not a
-- global GetStream wrapper) must retain the stream even without a handle.
local function newReaderDriver(opts)
    opts=opts or {}
    local busy,leases,finishAttempts=false,{},0
    local leaseOwner={}
    function leaseOwner:Acquire(streamParent,mode)
        assert(streamParent==owner and mode=="raw")
        if opts.failAcquire then error("SYNTHETIC_READER_PRE_ACQUIRE",0) end
        local s=streamParent:GetStream(mode)
        local lease={stream=s,done=false,releasing=false,attempts=0,
            originalLoad=s.Load,poolTouched=false}
        leases[#leases+1]=lease
        return lease
    end
    function leaseOwner:Finish(lease)
        assert(not lease.done and not lease.releasing)
        lease.releasing=true
        lease.attempts=lease.attempts+1
        finishAttempts=finishAttempts+1
        if opts.failBeforePool then error("SYNTHETIC_READER_FINISH_BEFORE",0) end
        lease.stream.Load=lease.originalLoad
        lease.stream:finished()
        lease.poolTouched=true
        if opts.failAfterPool then error("SYNTHETIC_READER_FINISH_AFTER",0) end
        lease.done=true
        lease.releasing=false
    end
    local function run()
        if busy then return {status="BUSY",leases=leases,busy=busy,
            finishAttempts=finishAttempts} end
        busy=true
        local co=coroutine.create(function()
            local handle=compiler:GetDBHandle(
                stage.npcBin,opts.badPointers or stage.npcPtrs,
                compiler:BuildSkipMap(db.npcCompilerTypes,db.npcCompilerOrder),
                db.npcKeys,nil,leaseOwner)
            assert(handle.readerLease==leases[1],"handle did not keep owned lease")
            if opts.failAfterHandle then error("SYNTHETIC_READER_POSTHANDLE",0) end
            local value=handle.QuerySingle(77101,"name")
            assert(value=="Invented NPC","real reader decode mismatch")
            leaseOwner:Finish(handle.readerLease)
            return "SUCCESS"
        end)
        local status,reason=nil,nil
        for _=1,(opts.budget or 256) do
            local ok,value=coroutine.resume(co)
            if not ok then status,reason="ERROR",tostring(value);break end
            if coroutine.status(co)=="dead" then status=value;break end
        end
        local dead=coroutine.status(co)=="dead"
        if not status then status="ABORTED_QUARANTINED" end
        local quarantine=not dead
        if dead then
            for _,lease in ipairs(leases) do
                if not lease.done then
                    if lease.releasing then
                        quarantine=true -- pool state may be unknown: no retry
                    else
                        -- AFTER the reader coroutine is DEAD only.
                        lease.releasing=true
                        lease.attempts=lease.attempts+1
                        finishAttempts=finishAttempts+1
                        lease.stream.Load=lease.originalLoad
                        local ok=pcall(lease.stream.finished,lease.stream)
                        if ok then
                            lease.done=true
                            lease.releasing=false
                            lease.poolTouched=true
                        else
                            quarantine=true
                            status="ERROR"
                        end
                    end
                end
            end
        end
        busy=quarantine
        return {status=status,reason=reason,leases=leases,dead=dead,
            busy=busy,quarantined=quarantine,finishAttempts=finishAttempts}
    end
    return run
end

local readerSuccess=newReaderDriver()()
check("explicit pre-handle reader lease succeeds with real pointer readback",
    readerSuccess.status=="SUCCESS" and readerSuccess.dead
    and #readerSuccess.leases==1 and readerSuccess.finishAttempts==1)
check("successful reader lease returned once with no busy lock",
    readerSuccess.leases[1].done and readerSuccess.leases[1].attempts==1
    and readerSuccess.leases[1].poolTouched and not readerSuccess.busy)

local badReader=newReaderDriver({badPointers=string.char(0)})()
check("DEAD malformed pre-handle pointer decode reclaims owned reader",
    badReader.status=="ERROR" and badReader.dead
    and #badReader.leases==1 and badReader.leases[1].done
    and badReader.finishAttempts==1 and not badReader.busy)
local postHandleReader=newReaderDriver({failAfterHandle=true})()
check("DEAD post-handle error returns reader once without publication",
    postHandleReader.status=="ERROR" and postHandleReader.dead
    and postHandleReader.leases[1].done and
    postHandleReader.leases[1].attempts==1 and not postHandleReader.busy
    and saved.nQuestieDataRevision==57)
local preAcquireReader=newReaderDriver({failAcquire=true})()
check("reader acquisition refusal before pool has zero leases",
    preAcquireReader.status=="ERROR" and preAcquireReader.dead
    and #preAcquireReader.leases==0 and not preAcquireReader.busy)

local poisonReaderBefore=newReaderDriver({failBeforePool=true})
local readerBefore=poisonReaderBefore()
check("reader failed finish before pool is poisoned without second attempt",
    readerBefore.status=="ERROR" and readerBefore.quarantined
    and readerBefore.busy and readerBefore.finishAttempts==1
    and readerBefore.leases[1].attempts==1
    and not readerBefore.leases[1].poolTouched
    and poisonReaderBefore().status=="BUSY")
local poisonReaderAfter=newReaderDriver({failAfterPool=true})
local readerAfter=poisonReaderAfter()
check("reader pool-return-then-throw fails closed and stays BUSY",
    readerAfter.status=="ERROR" and readerAfter.quarantined
    and readerAfter.busy and readerAfter.finishAttempts==1
    and readerAfter.leases[1].poolTouched
    and poisonReaderAfter().status=="BUSY")

local heldReader=newReaderDriver({budget=1})
local held=heldReader()
check("suspended pre-handle reader stays quarantined without a pool return",
    held.status=="ABORTED_QUARANTINED" and not held.dead
    and held.busy and held.quarantined and #held.leases==1
    and held.finishAttempts==0 and not held.leases[1].done
    and heldReader().status=="BUSY")

local invalidReaderOwner=pcall(function()
    drive(function()compiler:GetDBHandle(
        stage.npcBin,stage.npcPtrs,
        compiler:BuildSkipMap(db.npcCompilerTypes,db.npcCompilerOrder),
        db.npcKeys,nil,{})end)
end)
check("invalid reader ownership contract refused before acquire",
    not invalidReaderOwner and owner.GetStream==realGlobalGet)
check("reader and writer owner paths did not intercept global GetStream",
    owner.GetStream==realGlobalGet and saved.nQuestieDataRevision==57
    and saved.npcBin~="OLD_STAGE_NPC")
-- The real Questie:Error logs diagnostics without raising. Staged writes
-- must therefore fail with an explicit Lua error instead of silently
-- returning, which a transaction driver could misread as SUCCESS.
local priorError=Questie.Error
local reported={}
Questie.Error=function(_,message)
    reported[#reported+1]=tostring(message)
end
db.objectData={[77201]={[db.objectKeys.name]={99}}}
local stale={objBin="PRIOR_GO_BIN",objPtrs="PRIOR_GO_PTRS"}
local stageOk,stageErr=pcall(function()
    drive(function() compiler:CompileObjects(stale) end)
end)
check("print-only Questie Error cannot silently accept invalid staged GO",
    not stageOk and type(stageErr)=="string" and
    stageErr:find("GATE08_STAGE_INVALID_DATATYPE",1,true)~=nil
    and #reported==1)
check("nonthrowing log error cannot replace old scratch or live GO pair",
    stale.objBin=="PRIOR_GO_BIN" and stale.objPtrs=="PRIOR_GO_PTRS"
    and saved.objBin=="OLD_BIN_obj" and saved.objPtrs=="OLD_PTRS_obj"
    and saved.nQuestieDataRevision==57 and saved.dbCompiledCount==9)

local ownedBadRun=newLeaseDriver()
local ownedBad=ownedBadRun()
check("owned multi-kind stage reports ERROR and cleans DEAD leases",
    ownedBad.status=="ERROR" and ownedBad.dead and not ownedBad.busy
    and not ownedBad.quarantined and #ownedBad.leases==2
    and ownedBad.leases[1].done and ownedBad.leases[2].done
    and ownedBad.leases[1].attempts==1 and ownedBad.leases[2].attempts==1
    and ownedBad.stage.objBin==nil and ownedBad.stage.objPtrs==nil)
db.objectData={[77201]={[db.objectKeys.name]="Invented Object"}}
local repaired=ownedBadRun()
Questie.Error=priorError
check("clean retry after DEAD staged datatype ERROR remains possible",
    repaired.status=="SUCCESS" and not repaired.busy
    and type(repaired.stage.objBin)=="string"
    and type(repaired.stage.objPtrs)=="string"
    and type(repaired.stage.itemBin)=="string"
    and #reported==2 and Questie.Error==priorError)

-- Gate08 Part36: current-generation completeness receipts, backed by
-- the real four compiler writers. The original data and all IDs are fictional.
local fresh={oldMarker="untouched"}
for _,entry in ipairs(categories) do
    fresh[entry.kind.."Bin"]="STALE_"..entry.kind.."_BIN"
    fresh[entry.kind.."Ptrs"]="STALE_"..entry.kind.."_PTRS"
end
local gen=compiler:BeginNQStagedGeneration(fresh)
local cleared=type(gen)=="table" and fresh.oldMarker=="untouched"
for _,entry in ipairs(categories) do
    if fresh[entry.kind.."Bin"]~=nil or fresh[entry.kind.."Ptrs"]~=nil then
        cleared=false
    end
end
check("fresh generation clears all eight stale bytes and pointer fields",
    cleared and type(fresh._nqGenerationReceipts)=="table")
local noEntries,noReason=pcall(function()
    compiler:VerifyNQStagedGeneration(fresh,gen)
end)
check("uncompiled generation cannot claim success",
    not noEntries and tostring(noReason):find("GATE08_STAGE_INCOMPLETE",1,true)~=nil)
drive(function()compiler:CompileNPCs(fresh)end)
local partialOk=pcall(function()compiler:VerifyNQStagedGeneration(fresh,gen)end)
check("single successful NPC receipt is not a complete generation",
    not partialOk and fresh._nqGenerationReceipts.npc.token==gen)
for _,method in ipairs({"CompileObjects","CompileQuests","CompileItems"}) do
    drive(function()compiler[method](compiler,fresh)end)
end
local allReceipts=true
local savedPairs={}
for _,entry in ipairs(categories) do
    local k=entry.kind
    local receipt=fresh._nqGenerationReceipts[k]
    if type(receipt)~="table" or receipt.token~=gen or
        receipt.bin~=fresh[k.."Bin"] or
        receipt.ptrs~=fresh[k.."Ptrs"] then allReceipts=false end
    savedPairs[k.."Bin"]=fresh[k.."Bin"]
    savedPairs[k.."Ptrs"]=fresh[k.."Ptrs"]
end
check("all four real writers stamped current-generation receipts",
    allReceipts and type(fresh.itemBin)=="string")
check("exact generation with eight current writer outputs verifies",
    compiler:VerifyNQStagedGeneration(fresh,gen)==true)

fresh.itemBin="FOREIGN_WRITER_CHANGED_BYTES"
local dirtyOk,dirtyReason=pcall(function()
    compiler:VerifyNQStagedGeneration(fresh,gen)
end)
check("post-staging byte mutation invalidates receipt",
    not dirtyOk and tostring(dirtyReason):find("GATE08_STAGE_INCOMPLETE_OR_STALE",1,true)~=nil)
fresh.itemBin=savedPairs.itemBin
check("restored immutable encoded value matches original current receipt",
    compiler:VerifyNQStagedGeneration(fresh,gen)==true)

local oldToken=gen
gen=compiler:BeginNQStagedGeneration(fresh)
local wrongToken,wrongMessage=pcall(function()
    compiler:VerifyNQStagedGeneration(fresh,oldToken)
end)
check("old generation token cannot be replayed in a fresh attempt",
    not wrongToken and gen~=oldToken and
    tostring(wrongMessage):find("GATE08_STAGE_GENERATION_MISMATCH",1,true)~=nil)
for key,value in pairs(savedPairs) do fresh[key]=value end
local replayOk=pcall(function()compiler:VerifyNQStagedGeneration(fresh,gen)end)
check("stale eight bytes replayed without fresh receipts are rejected",
    not replayOk and next(fresh._nqGenerationReceipts)==nil)

local logger=Questie.Error
local logCalls=0
Questie.Error=function()logCalls=logCalls+1 end
db.objectData={[77201]={[db.objectKeys.name]={99}}}
compiler:BeginNQStagedGeneration(fresh)
drive(function()compiler:CompileNPCs(fresh)end)
local invalidKind,invalidKindErr=pcall(function()
    drive(function()compiler:CompileObjects(fresh)end)
end)
local errorReceipt=pcall(function()compiler:VerifyNQStagedGeneration(fresh,fresh._nqGenerationToken)end)
db.objectData={[77201]={[db.objectKeys.name]="Invented Object"}}
Questie.Error=logger
check("print-only datatype refusal never issues GO generation receipt",
    not invalidKind and
    tostring(invalidKindErr):find("GATE08_STAGE_INVALID_DATATYPE",1,true)~=nil
    and logCalls==1 and not errorReceipt and
    fresh._nqGenerationReceipts.obj==nil)

local retryToken=compiler:BeginNQStagedGeneration(fresh)
local noInitialReceipt=next(fresh._nqGenerationReceipts)==nil
for _,entry in ipairs(categories) do
    drive(function()compiler[entry.fn](compiler,fresh)end)
end
check("repaired input succeeds with only current generation receipts",
    noInitialReceipt and retryToken~=oldToken and
    compiler:VerifyNQStagedGeneration(fresh,retryToken)==true)
check("receipts never publish to SavedVariables or advance revision",
    saved.nQuestieDataRevision==57 and saved.dbCompiledCount==9 and
    saved.objBin=="OLD_BIN_obj" and saved.itemBin=="OLD_BIN_item")

local forged={_nqGenerationToken={},_nqGenerationReceipts={}}
local invalid=pcall(function()
    compiler:VerifyNQStagedGeneration(forged,{})
end)
check("foreign receipt token cannot authenticate staged bytes",
    not invalid)

-- Source-backed concurrency counterexample: a writer may be suspended
-- while the same SCRATCH stage is reused. Only an external coroutine driver
-- resumes threads and returns their leases AFTER coroutine status is DEAD.
local function interruptedScratchAttempt(restorePriorToken, restorePriorSerial, nilSerialBeforeBegin)
    local scratch={}
    local oldToken=compiler:BeginNQStagedGeneration(scratch)
    local oldSerial=scratch._nqGenerationSerial
    local acquired,finished=nil,0
    local writerFinishCount=0
    local externalOwner={}
    function externalOwner:Acquire(streamParent,mode)
        assert(acquired==nil and streamParent==owner)
        acquired={stream=streamParent:GetStream(mode)}
        return acquired
    end
    function externalOwner:Finish(lease)
        assert(lease==acquired and finished==0)
        writerFinishCount=writerFinishCount+1
        finished=finished+1
        lease.stream:finished()
    end
    scratch._nqWriterLeaseOwner=externalOwner
    local thread=coroutine.create(function()
        return compiler:CompileNPCs(scratch)
    end)
    local resumed=coroutine.resume(thread)
    assert(resumed and coroutine.status(thread)=="suspended" and acquired)
    if nilSerialBeforeBegin then scratch._nqGenerationSerial=nil end
    local newToken=compiler:BeginNQStagedGeneration(scratch)
    local newSerial=scratch._nqGenerationSerial
    if restorePriorToken then
        -- Caller-visible diagnostic rollback must not roll back private state.
        scratch._nqGenerationToken=oldToken
    end
    if restorePriorSerial then scratch._nqGenerationSerial=oldSerial end
    local ok,reason=coroutine.resume(thread)
    local dead=coroutine.status(thread)=="dead"
    if dead and finished==0 then
        -- Driver cleanup after DEAD only; no pcall across a yielding writer.
        acquired.stream:finished()
        finished=finished+1
    end
    return {ok=ok,reason=tostring(reason),dead=dead,
        stage=scratch,oldToken=oldToken,newToken=newToken,
        oldSerial=oldSerial,newSerial=newSerial,
        cleanupCount=finished,writerFinishCount=writerFinishCount}
end
local resetAttempt=interruptedScratchAttempt(false)
check("suspended writer cannot stamp a newer scratch attempt",
    not resetAttempt.ok and resetAttempt.dead and
    resetAttempt.reason:find("GATE08_STAGE_ATTEMPT_CHANGED",1,true)~=nil
    and resetAttempt.oldToken~=resetAttempt.newToken and
    resetAttempt.newSerial==resetAttempt.oldSerial+1)
check("suspended stale writer emitted no receipt and DEAD cleanup occurred once",
    resetAttempt.stage.npcBin==nil and resetAttempt.stage.npcPtrs==nil
    and next(resetAttempt.stage._nqGenerationReceipts)==nil
    and resetAttempt.cleanupCount==1)
local abaAttempt=interruptedScratchAttempt(true)
check("reverting a scratch token A-B-A cannot bypass attempt serial guard",
    not abaAttempt.ok and abaAttempt.dead and
    abaAttempt.stage._nqGenerationToken==abaAttempt.oldToken and
    abaAttempt.newSerial>abaAttempt.oldSerial and
    abaAttempt.reason:find("GATE08_STAGE_ATTEMPT_CHANGED",1,true)~=nil
    and abaAttempt.cleanupCount==1)
local reusedStage=resetAttempt.stage
-- The aborted transaction's lease owner must not be reused. A new
-- caller-owned driver installs its own lease control; this synthetic
-- post-DEAD proof uses the legacy unleased opt-in stage for convenience.
reusedStage._nqWriterLeaseOwner=nil
local subsequent=compiler:BeginNQStagedGeneration(reusedStage)
for _,entry in ipairs(categories) do
    drive(function()compiler[entry.fn](compiler,reusedStage)end)
end
check("safe fresh attempt after DEAD cleanup generates all four current receipts",
    compiler:VerifyNQStagedGeneration(reusedStage,subsequent)==true
    and reusedStage._nqGenerationSerial==resetAttempt.newSerial+1)
local badSerial={_nqGenerationSerial="malformed"}
local serialOk,serialErr=pcall(function()
    compiler:BeginNQStagedGeneration(badSerial)
end)
check("invalid generation serial is rejected instead of silently resetting",
    not serialOk and tostring(serialErr):find("GATE08_STAGE_BAD_SERIAL",1,true)~=nil
    and badSerial._nqGenerationToken==nil)

-- Part37: preserve all 63 earlier source-backed cases, then attack CS02's
-- real Q1–Q6 counterexamples. Genuine compiler methods and real stream pool
-- exercise invented fixture data only; no Stage1 or SavedVariables writes.
local priorSerial=reusedStage._nqGenerationSerial
reusedStage._nqGenerationSerial=priorSerial+1
local alteredSerialOk=pcall(function()
    compiler:VerifyNQStagedGeneration(reusedStage,subsequent)
end)
reusedStage._nqGenerationSerial=priorSerial
check("Q1 changing visible serial after receipts refuses verification",
    not alteredSerialOk and compiler:VerifyNQStagedGeneration(reusedStage,subsequent)==true)

check("Q2 visible-token ABA must stop before either scratch field write",
    abaAttempt.stage.npcBin==nil and abaAttempt.stage.npcPtrs==nil
    and next(abaAttempt.stage._nqGenerationReceipts)==nil)

local fullABA=interruptedScratchAttempt(true,true,false)
check("Q5 full public token and serial ABA cannot authenticate stale writer",
    not fullABA.ok and fullABA.dead and fullABA.cleanupCount==1
    and fullABA.reason:find("GATE08_STAGE_ATTEMPT_CHANGED",1,true)~=nil
    and fullABA.stage.npcBin==nil and fullABA.stage.npcPtrs==nil)

local nilReset=interruptedScratchAttempt(true,false,true)
check("Q6 nil-reset public serial cannot restart private generation identity",
    not nilReset.ok and nilReset.dead and nilReset.cleanupCount==1
    and nilReset.newSerial==nilReset.oldSerial+1
    and nilReset.stage.npcBin==nil and nilReset.stage.npcPtrs==nil)

local forgedStage={_nqGenerationToken={},_nqGenerationSerial=1,
    _nqGenerationReceipts={}}
for _,entry in ipairs(categories) do
    local k=entry.kind
    forgedStage[k.."Bin"]="GARBAGE_"..k
    forgedStage[k.."Ptrs"]="X_"..k
    forgedStage._nqGenerationReceipts[k]={
        token=forgedStage._nqGenerationToken,serial=1,
        bin=forgedStage[k.."Bin"],ptrs=forgedStage[k.."Ptrs"]}
end
local forgedNoBegin=pcall(function()
    compiler:VerifyNQStagedGeneration(forgedStage,forgedStage._nqGenerationToken)
end)
check("compiler refuses hand-made token and four receipt pairs without Begin",
    not forgedNoBegin)

local precompiledForge={}
local forgeToken=compiler:BeginNQStagedGeneration(precompiledForge)
for _,entry in ipairs(categories) do
    local k=entry.kind
    precompiledForge[k.."Bin"]="GARBAGE_"..k
    precompiledForge[k.."Ptrs"]="X_"..k
    precompiledForge._nqGenerationReceipts[k]={
        token=forgeToken,serial=precompiledForge._nqGenerationSerial,
        bin=precompiledForge[k.."Bin"],ptrs=precompiledForge[k.."Ptrs"]}
end
local forgedWithBegin=pcall(function()
    compiler:VerifyNQStagedGeneration(precompiledForge,forgeToken)
end)
check("public receipt forgery after real Begin has no private writer proof",
    not forgedWithBegin)

local originalBin=reusedStage.npcBin
local originalDiagnosticBin=reusedStage._nqGenerationReceipts.npc.bin
reusedStage.npcBin="FORGED_AFTER_VALID_WRITE"
reusedStage._nqGenerationReceipts.npc.bin=reusedStage.npcBin
local forgedAfterWriter=pcall(function()
    compiler:VerifyNQStagedGeneration(reusedStage,subsequent)
end)
reusedStage.npcBin=originalBin
reusedStage._nqGenerationReceipts.npc.bin=originalDiagnosticBin
check("editing bytes plus public receipt cannot forge compiler provenance",
    not forgedAfterWriter
    and compiler:VerifyNQStagedGeneration(reusedStage,subsequent)==true)

local reentrantStage={}
local beforeReentrant=compiler:BeginNQStagedGeneration(reentrantStage)
local reentrantDone,reentrantLease=0,nil
local reentrantOwner={}
function reentrantOwner:Acquire(streamParent,mode)
    reentrantLease={stream=streamParent:GetStream(mode)}
    return reentrantLease
end
function reentrantOwner:Finish(lease)
    assert(lease==reentrantLease and reentrantDone==0)
    reentrantDone=reentrantDone+1
    lease.stream:finished()
    compiler:BeginNQStagedGeneration(reentrantStage)
end
reentrantStage._nqWriterLeaseOwner=reentrantOwner
local reentrantOK,reentrantErr=pcall(function()
    drive(function()compiler:CompileNPCs(reentrantStage)end)
end)
check("Q3 Begin re-entrant during Finish cannot write stale Bin or Ptrs",
    not reentrantOK and tostring(reentrantErr):find("GATE08_STAGE_ATTEMPT_CHANGED",1,true)~=nil
    and reentrantDone==1 and reentrantStage.npcBin==nil
    and reentrantStage.npcPtrs==nil
    and not pcall(function()
        compiler:VerifyNQStagedGeneration(reentrantStage,beforeReentrant)
    end))

local tokenlessStage={}
local tokenlessLease=nil
local tokenlessOwner={}
function tokenlessOwner:Acquire(streamParent,mode)
    assert(tokenlessLease==nil)
    tokenlessLease={stream=streamParent:GetStream(mode)}
    return tokenlessLease
end
function tokenlessOwner:Finish(lease)
    assert(lease==tokenlessLease)
    lease.stream:finished()
end
tokenlessStage._nqWriterLeaseOwner=tokenlessOwner
local staleThread=coroutine.create(function()
    compiler:CompileNPCs(tokenlessStage)
end)
local firstResume=coroutine.resume(staleThread)
assert(firstResume and coroutine.status(staleThread)=="suspended")
local begunToken=compiler:BeginNQStagedGeneration(tokenlessStage)
local tokenlessOK,tokenlessReason=coroutine.resume(staleThread)
local tokenlessDead=coroutine.status(staleThread)=="dead"
if tokenlessDead then tokenlessLease.stream:finished() end
check("Q4 suspended tokenless writer cannot contaminate freshly begun stage",
    not tokenlessOK and tokenlessDead
    and tostring(tokenlessReason):find("GATE08_STAGE_ATTEMPT_CHANGED",1,true)~=nil
    and tokenlessStage.npcBin==nil and tokenlessStage.npcPtrs==nil
    and not pcall(function()
        compiler:VerifyNQStagedGeneration(tokenlessStage,begunToken)
    end))

local unchangedTokenless={}
drive(function()compiler:CompileNPCs(unchangedTokenless)end)
check("legacy tokenless scratch stage retains successful byte staging",
    type(unchangedTokenless.npcBin)=="string"
    and type(unchangedTokenless.npcPtrs)=="string"
    and unchangedTokenless._nqGenerationReceipts==nil)

-- Part37 independent staged scalar-encoding audit. These are not mock
-- codecs: each test invokes the actual Lua5.1-era Questie wrapper and stream.
-- The source data/IDs are invented. Prior 73 cases remain unchanged.
local scalarCases = {
    {"npc", "zoneID", 70000, false, "u16 overflow"},
    {"npc", "zoneID", -1, false, "u16 negative"},
    {"npc", "zoneID", 65535, true, "u16 boundary"},
    {"npc", "minLevel", 1.5, false, "u8 fractional"},
    {"npc", "minLevel", 256, false, "u8 overflow"},
    {"npc", "minLevel", 255, true, "u8 boundary"},
    {"quest", "sourceItemId", 16777216, false, "u24 overflow"},
    {"quest", "sourceItemId", -1, false, "u24 negative"},
    {"quest", "sourceItemId", 16777215, true, "u24 boundary"},
    {"npc", "npcFlags", 4294967296, false, "u32 overflow"},
    {"npc", "npcFlags", -1, false, "u32 negative"},
    {"npc", "npcFlags", 4294967295, true, "u32 boundary"},
    {"quest", "questLevel", -32768, false, "s16 lower overflow"},
    {"quest", "questLevel", 32769, false, "s16 upper overflow"},
    {"quest", "questLevel", -32767, true, "s16 signed-offset boundary"},
    {"quest", "requiredSpell", -8388608, false, "s24 lower overflow"},
    {"quest", "requiredSpell", 8388609, false, "s24 upper overflow"},
    {"quest", "requiredSpell", -8388607, true, "s24 signed-offset boundary"},
    {"npc", "minLevel", false, false, "false cannot silently encode as zero"},
}
local preScalarLive = {}
for _,entry in ipairs(categories) do
    preScalarLive[entry.kind.."Bin"] = saved[entry.kind.."Bin"]
    preScalarLive[entry.kind.."Ptrs"] = saved[entry.kind.."Ptrs"]
end
local function scalarRealSourceProbe(spec)
    local k,field,value,valid = spec[1],spec[2],spec[3],spec[4]
    local entry
    for _,row in ipairs(categories) do if row.kind==k then entry=row end end
    assert(entry)
    local dataField = entry.schema.."Data"
    local originalData = db[dataField]
    local row = {[db[entry.tableKeys].name]=entry.name}
    row[db[entry.tableKeys][field]] = value
    db[dataField] = {[entry.id]=row}
    local st = {}
    local lease,finishCount=nil,0
    local leaseOwner={}
    function leaseOwner:Acquire(streamParent,mode)
        assert(not lease)
        lease={stream=streamParent:GetStream(mode)}
        return lease
    end
    function leaseOwner:Finish(got)
        assert(got==lease and finishCount==0)
        finishCount=finishCount+1
        got.stream:finished()
    end
    st._nqWriterLeaseOwner=leaseOwner
    local thread=coroutine.create(function()
        compiler[entry.fn](compiler,st)
    end)
    local ok,err=true,nil
    for _=1,256 do
        ok,err=coroutine.resume(thread)
        if not ok or coroutine.status(thread)=="dead" then break end
    end
    assert(coroutine.status(thread)=="dead","source probe unexpectedly suspended")
    if lease and finishCount==0 then
        lease.stream:finished() -- external owner cleans only AFTER DEAD
        finishCount=finishCount+1
    end
    local observed=nil
    if ok and valid then
        local handle=drive(function()
            return compiler:GetDBHandle(st[k.."Bin"],st[k.."Ptrs"],
                compiler:BuildSkipMap(db[entry.schema.."CompilerTypes"],
                    db[entry.schema.."CompilerOrder"]),db[entry.tableKeys],nil)
        end)
        observed=handle.QuerySingle(entry.id,field)
        handle.stream:finished()
    end
    db[dataField]=originalData
    return ok,tostring(err),st,finishCount,observed
end

for _,spec in ipairs(scalarCases) do
    local ok,reason,st,finished,readBack=scalarRealSourceProbe(spec)
    local accepted=spec[4]
    check("stage numeric "..spec[5].." preserves exact encoding or refuses",
        finished==1 and (
            (accepted and ok and readBack==spec[3] and
                type(st[spec[1].."Bin"])=="string" and
                type(st[spec[1].."Ptrs"])=="string") or
            (not accepted and not ok and
                reason:find("GATE08_STAGE_NUMERIC_RANGE",1,true)~=nil and
                st[spec[1].."Bin"]==nil and
                st[spec[1].."Ptrs"]==nil)
        ))
end
local allLiveStillOriginal=saved.nQuestieDataRevision==57 and
    saved.dbCompiledCount==9
for _,entry in ipairs(categories) do
    if saved[entry.kind.."Bin"]~=preScalarLive[entry.kind.."Bin"] or
        saved[entry.kind.."Ptrs"]~=preScalarLive[entry.kind.."Ptrs"] then
        allLiveStillOriginal=false
    end
end
check("invalid staged scalars never published or advanced live revision",
    allLiveStillOriginal)

-- Stage-only safety: no-stage compiler deliberately retains the old raw
-- encoder's historical behaviour at this development stage.
local beforeLegacyBin,beforeLegacyPtrs=saved.npcBin,saved.npcPtrs
local originalNPCs=db.npcData
db.npcData={[77101]={[db.npcKeys.name]="Invented NPC",
    [db.npcKeys.zoneID]=70000}}
drive(function()compiler:CompileNPCs()end)
local legacyHandle=drive(function()
    return compiler:GetDBHandle(saved.npcBin,saved.npcPtrs,
        compiler:BuildSkipMap(db.npcCompilerTypes,db.npcCompilerOrder),
        db.npcKeys,nil)
end)
local legacyWrapped=legacyHandle.QuerySingle(77101,"zoneID")
legacyHandle.stream:finished()
db.npcData=originalNPCs
saved.npcBin,saved.npcPtrs=beforeLegacyBin,beforeLegacyPtrs
check("legacy raw u16 path retains existing wrap, without endorsing it",
    legacyWrapped==4464 and saved.npcBin==beforeLegacyBin and
    saved.npcPtrs==beforeLegacyPtrs and saved.nQuestieDataRevision==57)

-- Part37 CS02 independent #187 mutation follow-up, TEST-ONLY child.
-- The stale writer must NOT invoke its own Finish: only the external driver
-- may return the lease after observing DEAD. This specifically kills M1
-- (removing per-resume NQAssertStageAttempt) rather than relying on final
-- scratch-byte refusal, which could still occur after Finish.
check("CS02 M1 reset writer must not call Finish before stale-resume refusal",
    resetAttempt.writerFinishCount==0 and resetAttempt.cleanupCount==1
    and resetAttempt.dead and not resetAttempt.ok)
check("CS02 M1 full public ABA writer must not Finish a stale lease",
    fullABA.writerFinishCount==0 and fullABA.cleanupCount==1
    and fullABA.dead and not fullABA.ok)

-- CS02 M10: public receipt diagnostics are part of the current candidate's
-- explicit validation. Mutating them alone must be observable and rejected.
local itemDiagnostic=reusedStage._nqGenerationReceipts.item.bin
reusedStage._nqGenerationReceipts.item.bin="CORRUPTED_DIAGNOSTIC_ONLY"
local diagnosticAccepted=pcall(function()
    compiler:VerifyNQStagedGeneration(reusedStage,subsequent)
end)
reusedStage._nqGenerationReceipts.item.bin=itemDiagnostic
check("CS02 M10 diagnostic-only receipt tampering is rejected and recoverable",
    not diagnosticAccepted
    and compiler:VerifyNQStagedGeneration(reusedStage,subsequent)==true)

-- Policy pin: a stage that has already been begun may not be converted into
-- a tokenless stage by deleting public fields. It retains private ownership.
local previouslyBegun={}
compiler:BeginNQStagedGeneration(previouslyBegun)
previouslyBegun._nqGenerationToken=nil
previouslyBegun._nqGenerationSerial=nil
previouslyBegun._nqGenerationReceipts=nil
local tokenlessReuseOK,tokenlessReuseReason=pcall(function()
    drive(function()compiler:CompileNPCs(previouslyBegun)end)
end)
check("started stage cannot silently revert into tokenless legacy mode",
    not tokenlessReuseOK and
    tostring(tokenlessReuseReason):find("GATE08_STAGE_ATTEMPT_CHANGED",1,true)~=nil
    and previouslyBegun.npcBin==nil and previouslyBegun.npcPtrs==nil)

-- CS02's independent #191 mutation retest verified that original M1/M10
-- were killed, but three smaller diagnostic/defensive mutants survived.
-- These tests pin only the REAL public compiler API and real pooled streams.
local originallyValidPtr=reusedStage._nqGenerationReceipts.item.ptrs
reusedStage._nqGenerationReceipts.item.ptrs="FORGED_DIAGNOSTIC_PTR_ONLY"
local ptrDiagOK=pcall(function()
    compiler:VerifyNQStagedGeneration(reusedStage,subsequent)
end)
reusedStage._nqGenerationReceipts.item.ptrs=originallyValidPtr
check("CS02 M10b: public ptrs-only diagnostic edit is rejected and recoverable",
    not ptrDiagOK
    and compiler:VerifyNQStagedGeneration(reusedStage,subsequent)==true)

local diagItem=reusedStage._nqGenerationReceipts.item
local originalDiagToken=diagItem.token
diagItem.token={}
local tokenDiagOK=pcall(function()
    compiler:VerifyNQStagedGeneration(reusedStage,subsequent)
end)
diagItem.token=originalDiagToken
check("CS02 M10d token-only diagnostic edit is rejected and recoverable",
    not tokenDiagOK and
    compiler:VerifyNQStagedGeneration(reusedStage,subsequent)==true)

local originalDiagSerial=diagItem.serial
diagItem.serial=originalDiagSerial+1
local serialDiagOK=pcall(function()
    compiler:VerifyNQStagedGeneration(reusedStage,subsequent)
end)
diagItem.serial=originalDiagSerial
check("CS02 M10d serial-only diagnostic edit is rejected and recoverable",
    not serialDiagOK and
    compiler:VerifyNQStagedGeneration(reusedStage,subsequent)==true)

-- CS02 M11: a stage NEVER passed through Begin is suspended at the first
-- compiler yield, then a caller forges a visible token. The stale writer
-- must fail before its own lease Finish, leaving cleanup to the DEAD driver.
local neverBegun={}
local counterfeitFinishCount=0
local counterfeitLease
local counterfeitOwner={}
function counterfeitOwner:Acquire(streamParent,mode)
    assert(counterfeitLease==nil)
    counterfeitLease={stream=streamParent:GetStream(mode)}
    return counterfeitLease
end
function counterfeitOwner:Finish(lease)
    assert(lease==counterfeitLease)
    counterfeitFinishCount=counterfeitFinishCount+1
    lease.stream:finished()
end
neverBegun._nqWriterLeaseOwner=counterfeitOwner
local counterfeitThread=coroutine.create(function()
    compiler:CompileNPCs(neverBegun)
end)
local firstCounterfeitResume=coroutine.resume(counterfeitThread)
assert(firstCounterfeitResume and counterfeitLease and
    coroutine.status(counterfeitThread)=="suspended")
neverBegun._nqGenerationToken={}
local counterfeitOK,counterfeitReason=coroutine.resume(counterfeitThread)
local counterfeitDead=coroutine.status(counterfeitThread)=="dead"
if counterfeitDead and counterfeitFinishCount==0 then
    counterfeitLease.stream:finished()
end
check("CS02 M11 never-begun tokenless writer refuses forged token before Finish",
    not counterfeitOK and counterfeitDead and counterfeitFinishCount==0
    and tostring(counterfeitReason):find("GATE08_STAGE_ATTEMPT_CHANGED",1,true)~=nil
    and neverBegun.npcBin==nil and neverBegun.npcPtrs==nil)

-- Compound-number safety (simple pair and array codecs only).
-- These tests use the actual source-backed compiler, pooled QuestieStream,
-- and real GetDBHandle reader, through scalarRealSourceProbe above.
-- No real quest/NPC/item associations or owner-private evidence.
-- Synthetic exact-boundary mutants; oversized lists generated without private data.
local nqU16CountOverflow={}
for i=1,65536 do nqU16CountOverflow[i]=1 end
local nqU8PairCountOverflow={}
for i=1,256 do nqU8PairCountOverflow[i]={1,1} end
local nqU8CountOverflow={}
for i=1,256 do nqU8CountOverflow[i]=1 end
local compoundCases = {
    {"quest","requiredMinRep",{1,8388608},false,"MUTANT s24pair upper edge plus one"},
    {"quest","requiredSkill",{4096,1},false,"MUTANT u12pair upper edge plus one"},
    {"quest","reputationReward",{{1,8388608}},false,"MUTANT u8s24pairs upper edge plus one"},
    {"quest","reputationReward",{{-8388609,1}},false,"MUTANT u8s24pairs lower edge minus one"},
    {"item","npcDrops",nqU16CountOverflow,false,"MUTANT u16u24array 65536 count"},
    {"quest","reputationReward",nqU8PairCountOverflow,false,"MUTANT u8s24pairs 256 count"},
    {"npc","questStarts",{0/0},false,"MUTANT u8u24array non-finite input"},
    {"npc","questStarts",{"7"},false,"MUTANT u8u24array numeric string"},
    {"quest","reputationReward",{5},false,"MUTANT u8s24pairs non-pair element"},
    {"npc","questStarts",{[1]=10,[3]=30},false,"SHAPE sparse numeric keys"},
    {"npc","questStarts",{[1]=10,extra=30},false,"SHAPE mixed hash key"},
    {"npc","questStarts",{[0]=10,[1]=20},false,"SHAPE zero-based index"},
    {"npc","questStarts",{[1]=10,[2.5]=20},false,"SHAPE fractional table key"},
    {"npc","questStarts",{10,30},true,"SHAPE valid dense array"},
    {"quest","requiredSkill",{10,20,30},false,"SHAPE standalone pair third entry"},
    {"quest","requiredSkill",{10,20,extra=30},false,"SHAPE standalone pair hash entry"},
    {"quest","requiredSkill",{[2]=7},false,"SHAPE standalone pair missing first"},
    {"quest","requiredSkill",{[1]=7},false,"SHAPE standalone pair missing second"},
    {"quest","requiredSkill",{0,0},false,"SENTINEL u12pair zero pair decodes nil"},
    {"quest","requiredSkill",{0,7},true,"SHAPE u12pair zero first with second valid"},
    {"quest","requiredMinRep",{0,0},false,"SENTINEL s24pair zero pair decodes nil"},
    {"quest","reputationReward",{[1]={1,2},[3]={3,4}},false,"SHAPE sparse pair-array"},
    {"quest","reputationReward",{{[1]=1}},false,"SHAPE pair-array missing second"},
    {"quest","reputationReward",{{1,2,3}},false,"SHAPE pair-array third entry"},
    {"quest","reputationReward",{{[1]=1,[2]=2,x=3}},false,"SHAPE pair-array hash key"},
    {"quest","reputationReward",{{0,0}},true,"SHAPE nested zero pair is not standalone sentinel"},
    {"item","npcDrops",{[2]=1},false,"SHAPE sparse u16 count array"},
    {"item","npcDrops",{1,2},true,"SHAPE valid dense u16 count array"},
    {"quest","reputationReward",{[1]={1,2},extra={3,4}},false,"SHAPE pair-array outer hash key"},
    {"quest","requiredSkill",{-1,0},false,"u12pair negative"},
    {"quest","requiredSkill",{5000,1},false,"u12pair overflow"},
    {"quest","requiredSkill",{1,1.5},false,"u12pair fractional"},
    {"quest","requiredSkill",{4095,4095},true,"u12pair exact boundary"},
    {"quest","requiredMinRep",{1,9000000},false,"s24pair sign wrap"},
    {"quest","requiredMinRep",{-8388609,1},false,"s24pair negative overflow"},
    {"quest","requiredMinRep",{-8388608,8388607},true,"s24pair exact boundaries"},
    {"quest","requiredMinRep",{1,1.5},false,"s24pair fractional"},
    {"npc","questStarts",{16777216},false,"u8u24array 24bit overflow"},
    {"npc","questStarts",{1.5},false,"u8u24array fractional"},
    {"npc","questStarts",{16777215},true,"u8u24array exact boundary"},
    {"npc","questStarts",{-1},false,"u8u24array negative"},
    {"npc","questStarts",{1,2,3},true,"u8u24array good list"},
    {"item","npcDrops",{16777216},false,"u16u24array overflow"},
    {"item","npcDrops",{-1},false,"u16u24array negative"},
    {"item","npcDrops",{16777215},true,"u16u24array boundary"},
    {"quest","reputationReward",{{1,9000000}},false,"u8s24pairs signed overflow"},
    {"quest","reputationReward",{{1,8388607}},true,"u8s24pairs boundary"},
    {"quest","reputationReward",{{-8388608,1}},true,"u8s24pairs lower boundary"},
    {"npc","questStarts",nqU8CountOverflow,false,"u8 array count overflow"},
}
local function sameCompound(a,b)
    if type(a)~="table" or type(b)~="table" then return a==b end
    for k,v in pairs(a) do
        if not sameCompound(v,b[k]) then return false end
    end
    for k,v in pairs(b) do
        if not sameCompound(v,a[k]) then return false end
    end
    return true
end
for _,case in ipairs(compoundCases) do
    local kind,field,val,accept,label=case[1],case[2],case[3],case[4],case[5]
    local ok,reason,stage,finished,result=scalarRealSourceProbe(case)
    check("stage simple compound "..label.." exact or fail-closed",
        finished==1 and (
            (accept and ok and type(stage[kind.."Bin"])=="string"
                and sameCompound(result,val)) or
            (not accept and not ok and
                reason:find("GATE08_STAGE_COMPOUND_NUMERIC_RANGE",1,true)~=nil
                and stage[kind.."Bin"]==nil and stage[kind.."Ptrs"]==nil)
        ))
end

-- Verified public source compatibility: Questie Corrections deliberately
-- uses {} as a "clear" for simple numeric compounds. Historical writers
-- serialize that intentional clear as a nil sentinel, so the staged path
-- must accept it, without accepting sparse/nonempty ambiguous shapes.
local nqIntentionalClearCases={
    {"npc","questStarts","u8u24array"},
    {"item","npcDrops","u16u24array"},
    {"quest","reputationReward","u8s24pairs"},
    {"quest","requiredSkill","u12pair"},
    {"quest","requiredMinRep","s24pair"},
}
for _,spec in ipairs(nqIntentionalClearCases) do
    local kind,field,label=spec[1],spec[2],spec[3]
    local ok,reason,stage,finished,readback=scalarRealSourceProbe(
        {kind,field,{},true})
    check("stage intentional empty-table clear "..label.." remains nil",
        ok and finished==1 and readback==nil
        and type(stage[kind.."Bin"])=="string"
        and type(stage[kind.."Ptrs"])=="string"
        and not tostring(reason):find("GATE08_STAGE_COMPOUND",1,true))
end

-- The no-stage legacy encoding is intentionally byte/semantic compatible
-- with the parent on malformed compound inputs, not implicitly approved.
local legacyBeforeQuestBin,legacyBeforeQuestPtrs=saved.questBin,saved.questPtrs
local legacyBeforeQuestData=db.questData
db.questData={[77101]={[db.questKeys.name]="Legacy fictional quest",
    [db.questKeys.requiredSkill]={-1,0}}}
drive(function()compiler:CompileQuests()end)
local legacyQuestHandle=drive(function()
    return compiler:GetDBHandle(saved.questBin,saved.questPtrs,
        compiler:BuildSkipMap(db.questCompilerTypes,db.questCompilerOrder),
        db.questKeys,nil)
end)
local legacySkill=legacyQuestHandle.QuerySingle(77101,"requiredSkill")
legacyQuestHandle.stream:finished()
db.questData=legacyBeforeQuestData
saved.questBin,saved.questPtrs=legacyBeforeQuestBin,legacyBeforeQuestPtrs
check("legacy u12pair wrap remains unchanged and is not staged acceptance",
    legacySkill and legacySkill[1]==4095 and legacySkill[2]==0
    and saved.questBin==legacyBeforeQuestBin
    and saved.questPtrs==legacyBeforeQuestPtrs
    and saved.nQuestieDataRevision==57)

-- Part38 compatibility: exactly the same in-memory fictional source is
-- compiled by REAL optional stage, ordinary no-stage and SoD no-stage paths.
-- On invalid nonempty numeric compounds, only STAGED mode must fail closed;
-- the two historical no-stage paths must keep their existing byte identity.
-- This is *within-head* binary parity, not independently comparing #204's
-- historical blob bytes, nor a validation of the real SoD client/corpus.
local parityInputs={
    {"npc","questStarts",{77301,77302},true,"dense NPC list"},
    {"npc","questStarts",{},true,"intentional NPC clear"},
    {"npc","questStarts",{[1]=77301,[3]=77302},false,"sparse NPC legacy"},
    {"obj","questStarts",{77301},true,"dense object list"},
    {"obj","questStarts",{},true,"intentional object clear"},
    {"obj","questStarts",{[0]=77301,[1]=77302},false,"zero-key object legacy"},
    {"quest","requiredSkill",{164,250},true,"valid skill pair"},
    {"quest","requiredSkill",{},true,"intentional skill clear"},
    {"quest","requiredSkill",{164,250,999},false,"extra skill pair legacy"},
    {"item","npcDrops",{77101,77102},true,"valid item drops"},
    {"item","npcDrops",{},true,"intentional item clear"},
    {"item","npcDrops",{[1]=77101,[3]=77102},false,"sparse item legacy"},
}
local savedSodBefore=saved.sod
local isSodBefore=Questie.IsSoD
local parityRevision=saved.nQuestieDataRevision
local parityCompiledCount=saved.dbCompiledCount
for _,spec in ipairs(parityInputs) do
    local kind,field,value,accepted,label=spec[1],spec[2],spec[3],spec[4],spec[5]
    local category
    for _,candidate in ipairs(categories) do
        if candidate.kind==kind then category=candidate;break end
    end
    assert(category,"parity category missing: "..tostring(kind))
    local dataKey=category.schema.."Data"
    local previousTable=db[dataKey]
    local previousBin=saved[kind.."Bin"]
    local previousPtrs=saved[kind.."Ptrs"]
    local actualKeys=db[category.tableKeys]
    local row={[actualKeys.name]=category.name}
    row[actualKeys[field]]=value
    db[dataKey]={[category.id]=row}
    Questie.IsSoD=false
    local newStage={}
    local stagedOK,stagedReason=pcall(function()
        drive(function()compiler[category.fn](compiler,newStage)end)
    end)
    -- No-stage historical encoding, with deliberately malformed data too.
    drive(function()compiler[category.fn](compiler)end)
    local normalBin,normalPtrs=saved[kind.."Bin"],saved[kind.."Ptrs"]
    saved.sod={}
    Questie.IsSoD=true
    drive(function()compiler[category.fn](compiler)end)
    local sodBin,sodPtrs=saved.sod[kind.."Bin"],saved.sod[kind.."Ptrs"]
    Questie.IsSoD=false
    local matched=type(normalBin)=="string" and type(normalPtrs)=="string"
        and normalBin==sodBin and normalPtrs==sodPtrs
        and saved.nQuestieDataRevision==parityRevision
        and saved.dbCompiledCount==parityCompiledCount
    if accepted then
        matched=matched and stagedOK
            and newStage[kind.."Bin"]==normalBin
            and newStage[kind.."Ptrs"]==normalPtrs
    else
        matched=matched and not stagedOK
            and tostring(stagedReason):find(
                "GATE08_STAGE_COMPOUND_NUMERIC_RANGE",1,true)~=nil
            and newStage[kind.."Bin"]==nil
            and newStage[kind.."Ptrs"]==nil
    end
    db[dataKey]=previousTable
    saved[kind.."Bin"],saved[kind.."Ptrs"]=previousBin,previousPtrs
    saved.sod=savedSodBefore
    Questie.IsSoD=isSodBefore
    check("stage vs WotLK/SoD no-stage byte parity: "..label,matched)
end

assert(tests==169,"expected 169 source-backed compiler stage checks, got "..tests)
print("GATE08 SOURCE STAGING RESULT: 169/169 PASS")
print("DRAFT ONLY: simple compounds guarded; complex nested codec, source epoch, pool isolation, commit, relog recovery and client QA remain blocked")
