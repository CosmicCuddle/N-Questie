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

assert(tests==45,"expected 45 source-backed compiler stage checks, got "..tests)
print("GATE08 SOURCE STAGING RESULT: 45/45 PASS")
print("DRAFT ONLY: no writer epoch/ABA, lease recovery, atomic commit, disk recovery or client QA")
