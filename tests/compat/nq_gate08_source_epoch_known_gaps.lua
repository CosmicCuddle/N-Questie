-- Part37/38 Gate08 source-coroutine witnesses, Part39 per-witness RETRY flip-map.
-- All IDs/names are invented. THESE ARE EXPECTED OPEN SAFETY GAPS,
-- not passed source-epoch acceptance cases E01-E08.
-- Candidate RETRY approaches are in-memory shims on a copy of compiler.lua.
-- They are restored before the process exits. Production bytes stay unchanged.
io.stdout:setvbuf("line")
io.stderr:setvbuf("line")
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
    lshift=function(n,s)return (n*2^s)%4294967296 end,
    rshift=function(n,s)return math.floor((n%4294967296)/2^s) end,
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
for _,name in ipairs({"QuestieDB","QuestieLib","l10n"}) do
    QuestieLoader:CreateModule(name)
end
QuestieCompat={Is335=true,WOW_PROJECT_ID=2}
Questie={
    IsSoD=false,IsTBC=false,IsWotlk=true,
    db={profile={debugEnabled=false},global={}},
    Error=function(_,...)error("synthetic Questie error: "..tostring((...)),0)end,
    Debug=function()end,
}
assert(loadfile("Modules/QuestieStream.lua"))()
for _,file in ipairs({"npcDB","objectDB","questDB","itemDB"}) do
    assert(loadfile("Database/"..file..".lua"))()
end
assert(loadfile("Database/compiler.lua"))()
local db=QuestieLoader:ImportModule("QuestieDB")
local compiler=QuestieLoader:ImportModule("DBCompiler")
local productionCompiler=compiler
local saved=Questie.db.global
saved.nQuestieDataRevision=57
saved.dbCompiledCount=9
local READ_ERROR="\0READ_ERROR"
local categories={"CompileNPCs","CompileObjects","CompileQuests","CompileItems"}
local function normalizeReason(reason)
    if type(reason)~="string" then return reason end
    local current=reason
    for _=1,4 do
        local stripped=current:gsub("^.-:%d+: ","")
        if stripped==current then break end
        current=stripped
    end
    return current
end
local function drive(fn)
    local thread=coroutine.create(fn)
    for _=1,256 do
        local resumed,value=coroutine.resume(thread)
        if not resumed then
            return false,normalizeReason(tostring(value))
        end
        if coroutine.status(thread)=="dead" then return true,value end
    end
    return false,"synthetic Questie coroutine exceeded 256 resumes"
end
local function queryName(handle,id)
    local value=handle.QuerySingle(id,"name")
    handle.stream:finished()
    return value
end
local function readName(stage,prefix,kind,keys,id)
    local resumed,handle=drive(function()
        return compiler:GetDBHandle(stage[prefix.."Bin"],stage[prefix.."Ptrs"],
            compiler:BuildSkipMap(db[kind.."CompilerTypes"],
                db[kind.."CompilerOrder"]),db[keys],nil)
    end)
    if not resumed or type(handle)~="table" then return READ_ERROR end
    local qok,value=pcall(queryName,handle,id)
    if not qok then return READ_ERROR end
    return value
end
local function effectiveQuestName(stage,view,id)
    local resumed,handle=drive(function()
        return compiler:GetDBHandle(stage.questBin,stage.questPtrs,
            compiler:BuildSkipMap(db.questCompilerTypes,db.questCompilerOrder),
            db.questKeys,view)
    end)
    if not resumed or type(handle)~="table" then return READ_ERROR end
    local qok,value=pcall(queryName,handle,id)
    if not qok then return READ_ERROR end
    return value
end
local function verifyTrue(stage)
    local ok,res=pcall(function()
        return compiler:VerifyNQStagedGeneration(stage,stage._nqGenerationToken)==true
    end)
    return ok and res==true
end
local function compileStage(hook,hookKind)
    local scratch={}
    local ok,reason=true,nil
    local beginOk,token=pcall(function()
        return compiler:BeginNQStagedGeneration(scratch)
    end)
    if not beginOk then
        ok,reason=false,normalizeReason(tostring(token))
    else
        for _,method in ipairs(categories) do
            local thread=coroutine.create(function()
                compiler[method](compiler,scratch)
            end)
            local resumed,res=coroutine.resume(thread)
            if not resumed or coroutine.status(thread)~="suspended" then
                ok,reason=false,normalizeReason(tostring(res))
                break
            end
            if hook and method==(hookKind or "CompileNPCs") then
                local hookOk,hookErr=pcall(hook)
                if not hookOk then
                    ok,reason=false,normalizeReason(tostring(hookErr))
                    break
                end
            end
            for _=1,256 do
                if coroutine.status(thread)=="dead" then break end
                resumed,res=coroutine.resume(thread)
                if not resumed then
                    ok,reason=false,normalizeReason(tostring(res))
                    break
                end
            end
            if not ok then break end
            if coroutine.status(thread)~="dead" then
                ok,reason=false,"writer did not finish: "..method
                break
            end
        end
        if ok and scratch._nqStatus~=nil and reason==nil then
            reason=tostring(scratch._nqStatus)
        end
    end
    local verified=false
    if ok then
        verified=pcall(function()
            assert(compiler:VerifyNQStagedGeneration(scratch,token)==true)
        end)
    end
    scratch._nqDriverOk=ok
    scratch._nqDriverReason=reason
    scratch._nqDriverVerified=verified and true or false
    return scratch
end
local function fromStage(stage,binField)
    return {
        ok=stage._nqDriverOk and true or false,
        verified=stage._nqDriverVerified and true or false,
        reason=stage._nqDriverReason,
        published=stage[binField]~=nil,
        finish=nil,
        cleanup=nil,
    }
end
local function fromAttempt(attempt,binField)
    return {
        ok=attempt.ok and true or false,
        verified=attempt.verified and true or false,
        reason=attempt.reason,
        published=attempt.stage[binField]~=nil,
        finish=attempt.writerFinishCount,
        cleanup=attempt.driverCleanupCount,
    }
end
local function checkInto(printPins,results,label,predicate,outcome)
    local pok,result=pcall(predicate)
    local predicateError=nil
    local passed
    if pok then
        passed=result and true or false
    else
        passed=false
        predicateError=tostring(result)
    end
    results[#results+1]={
        label=label,
        passed=passed,
        ok=outcome.ok and true or false,
        verified=outcome.verified and true or false,
        reason=outcome.reason,
        published=outcome.published and true or false,
        finish=outcome.finish,
        cleanup=outcome.cleanup,
        predicateError=predicateError,
    }
    if printPins then
        local n=#results
        if passed and not predicateError then
            print("PASS KNOWN-GAP GATE08 SOURCE EPOCH WITNESS "..n.." "..label)
        else
            print("FAIL KNOWN-GAP GATE08 SOURCE EPOCH WITNESS "..n.." "..label)
        end
    end
end
local function resetInvented()
    db.npcData={[77101]={
        [db.npcKeys.name]="Witness A",
        [db.npcKeys.questStarts]={77301},
    }}
    db.objectData={[77201]={[db.objectKeys.name]="Witness Object"}}
    db.questData={[77301]={[db.questKeys.name]="Witness Quest"}}
    db.itemData={[77401]={[db.itemKeys.name]="Witness Item"}}
end

local function runEarly(printPins,results)
    local function check(label,predicate,outcome)
        checkInto(printPins,results,label,predicate,outcome)
    end
    -- E01 characteristic: one late relevant NPC write is included by the real
    -- coroutine; stage receipts still verify. No source-start epoch is checked.
    resetInvented()
    local clean=compileStage()
    resetInvented()
    local late=compileStage(function()
        db.npcData[77101][db.npcKeys.name]="Witness B"
    end)
    check("E01 OPEN: persistent NPC edit across yield stages as B without RETRY",
        function()
            return readName(late,"npc","npc","npcKeys",77101)=="Witness B"
                and late.npcBin~=clean.npcBin
        end, fromStage(late,"npcBin"))

-- E02 characteristic: the *same* source data A at both ends can hide a
-- transient mutation during suspension. Final-value equality cannot prove
-- source immutability, even though four-kind receipt Verify passes.
resetInvented()
local aba=compileStage(function()
    db.npcData[77101][db.npcKeys.name]="Witness B"
    db.npcData[77101][db.npcKeys.name]="Witness A"
end)
check("E02 OPEN: source A-B-A remains compiler-accepted with identical bytes",
    function()
        return aba.npcBin==clean.npcBin and aba.npcPtrs==clean.npcPtrs
            and readName(aba,"npc","npc","npcKeys",77101)=="Witness A"
    end, fromStage(aba,"npcBin"))

-- E03 characteristic: mutating an already-present nested array element does
-- not need to replace the outer record or trigger Lua __newindex at its root.
resetInvented()
local nested=compileStage(function()
    db.npcData[77101][db.npcKeys.questStarts][1]=77302
end)
check("E03 OPEN: nested questStarts index changed across yield with no RETRY",
    function()
        return nested.npcBin~=clean.npcBin and
            db.npcData[77101][db.npcKeys.questStarts][1]==77302
    end, fromStage(nested,"npcBin"))

-- E07 characteristic: a direct write from an unknown addon-like function
-- reaches the exported normal source table with no writer registration.
resetInvented()
local function unknownExternalWriter()
    db.itemData[77401][db.itemKeys.name]="Unknown Writer"
end
local unknown=compileStage(unknownExternalWriter,"CompileItems")
check("E07 OPEN: uninstrumented external item writer reaches staged bytes",
    function()
        return unknown.itemBin~=clean.itemBin and
            readName(unknown,"item","item","itemKeys",77401)=="Unknown Writer"
    end, fromStage(unknown,"itemBin"))

-- E06 boundary: the current scratch API is not a whole-source lock. An
-- unrelated change can happen without changing any of the output bytes.
resetInvented()
local unrelated=compileStage(function()
    db.npcData[77102]={[db.npcKeys.name]="Unrelated Late"}
end,"CompileItems")
check("E06 OPEN: unrelated source append has no defined epoch policy",
    function()
        return unrelated.npcBin==clean.npcBin and
            db.npcData[77102]~=nil
    end, fromStage(unrelated,"npcBin"))

-- E08 limited invariant: legacy no-stage byte encoding with unchanged
-- source is preserved at fixture scale. This is NOT native 3.3.5a QA.
resetInvented()
local current=compileStage()
local legacyOk=drive(function()compiler:CompileNPCs()end)
local e08=fromStage(current,"npcBin")
if not legacyOk then
    e08.ok=false
    e08.verified=false
    e08.reason=e08.reason or "legacy compile failed"
end
check("E08 FIXTURE: unchanged legacy NPC raw encoding equals staged bytes",
    function()
        return legacyOk and current.npcBin==saved.npcBin and current.npcPtrs==saved.npcPtrs
            and saved.nQuestieDataRevision==57 and saved.dbCompiledCount==9
    end, e08)
end

-- Part37 E04/E05: use the REAL QuestieCorrections:MinimalInit/addOverride
-- merge and the REAL compiler:GetDBHandle overlay reader. Only the FIX
-- loader's records and synthetic faction label are test doubles; no WoW
-- player-faction API, owner source, or private realm data is accessed.
local dependencies={
    "ZoneDB", "RamerDouglasPeucker", "QuestieEvent",
    "QuestieQuestBlacklist", "QuestieNPCBlacklist", "QuestieItemBlacklist",
    "HardcoreBlacklist", "SeasonOfDiscovery", "QuestieQuestFixes",
    "QuestieClassicQuestReputationFixes", "QuestieNPCFixes",
    "QuestieItemFixes", "QuestieObjectFixes",
    "QuestieTBCQuestFixes", "QuestieTBCNpcFixes",
    "QuestieTBCItemFixes", "QuestieTBCObjectFixes",
    "QuestieWotlkQuestFixes", "QuestieWotlkNpcFixes",
    "QuestieWotlkItemFixes", "QuestieWotlkObjectFixes",
    "IsleOfQuelDanas", "QuestieItemStartFixes",
}
for _,name in ipairs(dependencies) do QuestieLoader:CreateModule(name) end
modules.ZoneDB.zoneIDs={
    STORMWIND_CITY=1, IRONFORGE=2, TELDRASSIL=3,
    ORGRIMMAR=4, THUNDER_BLUFF=5, UNDERCITY=6,
}
modules.IsleOfQuelDanas.MAX_ISLE_OF_QUEL_DANAS_PHASES=5
modules.IsleOfQuelDanas.quests={}
saved.isleOfQuelDanasPhase=0
QuestieCompat.LoadBlacklists=function()end
for _,name in ipairs({
    "QuestieItemFixes", "QuestieNPCFixes", "QuestieObjectFixes",
    "QuestieTBCItemFixes", "QuestieTBCNpcFixes", "QuestieTBCObjectFixes",
    "QuestieTBCQuestFixes", "QuestieWotlkNpcFixes",
    "QuestieWotlkItemFixes", "QuestieWotlkObjectFixes",
    "SeasonOfDiscovery"
}) do
    modules[name].LoadFactionFixes=function()return {}end
end
for _,name in ipairs({
    "QuestieItemBlacklist", "QuestieNPCBlacklist", "QuestieQuestBlacklist"
}) do
    modules[name].Load=function()return {}end
end
modules.QuestieQuestBlacklist.LoadAutoBlacklistWotlk=function()return {}end
local syntheticFaction="A"
modules.QuestieQuestFixes.LoadFactionFixes=function()
    local prefix=syntheticFaction=="A" and "Invented A" or "Invented H"
    return {
        [77301]={[db.questKeys.name]=prefix.." base override"},
        [77501]={[db.questKeys.name]=prefix.." override-only quest"},
    }
end
assert(loadfile("Database/Corrections/QuestieCorrections.lua"))()
local corrections=QuestieLoader:ImportModule("QuestieCorrections")
local function clearedOverrides()
    db.npcDataOverrides={}
    db.itemDataOverrides={}
    db.objectDataOverrides={}
    db.questDataOverrides={}
end
local function runLate(printPins,results)
    local function check(label,predicate,outcome)
        checkInto(printPins,results,label,predicate,outcome)
    end
    -- Re-runs must not inherit the previous battery's faction or TBC fixture.
    syntheticFaction="A"
    modules.QuestieTBCQuestFixes.LoadFactionFixes=function()return {}end
    resetInvented()
    clearedOverrides()
    local canonicalStage=compileStage()
    check("E04 PRECONDITION: invented override-only quest has no base pointer",
        function()
            return db.questData[77501]==nil and
                effectiveQuestName(canonicalStage,db.questDataOverrides,77501)==nil
        end, fromStage(canonicalStage,"questBin"))
-- The actual MinimalInit code merges all four kinds of loader-supplied
-- overrides. It has no awareness of the already staged four-kind generation.
local fixtureMergeStage=compileStage(function()
    corrections:MinimalInit()
end,"CompileQuests")
check("E04 OPEN: real MinimalInit adds override-only quest after stage Begin",
    function()
        return db.questData[77501]==nil and
            effectiveQuestName(fixtureMergeStage,db.questDataOverrides,77501)
                =="Invented A override-only quest"
            and fixtureMergeStage.questBin==canonicalStage.questBin
            and verifyTrue(fixtureMergeStage)
    end, fromStage(fixtureMergeStage,"questBin"))

-- Real local addOverride merges keys into an already-present table, without
-- replacing its root. This is an in-place mutation of effective source state.
local sameOverrideRecord=db.questDataOverrides[77501]
modules.QuestieTBCQuestFixes.LoadFactionFixes=function()
    return {[77501]={[db.questKeys.name]="Invented replacement"}}
end
local fixtureNestedMergeStage=compileStage(function()
    corrections:MinimalInit()
end,"CompileQuests")
check("E04 OPEN: actual addOverride merges into pre-existing nested entry",
    function()
        return db.questDataOverrides[77501]==sameOverrideRecord and
            effectiveQuestName(fixtureNestedMergeStage,db.questDataOverrides,77501)
                =="Invented replacement"
            and fixtureNestedMergeStage.questBin==canonicalStage.questBin
    end, fromStage(fixtureNestedMergeStage,"questBin"))
modules.QuestieTBCQuestFixes.LoadFactionFixes=function()return {}end

-- E05 models two separately selected effective views. The synthetic loader
-- chooses the data here; this is NOT a test of live faction selection, nor
-- an approved cross-faction ownership relation from the real server.
syntheticFaction="A"
clearedOverrides()
corrections:MinimalInit()
local viewA=db.questDataOverrides
local acceptedA=effectiveQuestName(canonicalStage,viewA,77301)
syntheticFaction="H"
clearedOverrides()
corrections:MinimalInit()
local viewH=db.questDataOverrides
local originalH=effectiveQuestName(canonicalStage,viewH,77301)
local alteredHStage=compileStage(function()
    viewH[77301][db.questKeys.name]="Invented H changed after A check"
end,"CompileQuests")
check("E05 OPEN: A-only preflight cannot certify changed opposite view",
    function()
        return acceptedA=="Invented A base override" and
            effectiveQuestName(alteredHStage,viewA,77301)==acceptedA and
            originalH=="Invented H base override" and
            effectiveQuestName(alteredHStage,viewH,77301)
                =="Invented H changed after A check"
            and alteredHStage.questBin==canonicalStage.questBin and
            verifyTrue(alteredHStage)
    end, fromStage(alteredHStage,"questBin"))
local hAfter=effectiveQuestName(alteredHStage,viewH,77301)
local transientHStage=compileStage(function()
    viewH[77301][db.questKeys.name]="Invented transient H"
    viewH[77301][db.questKeys.name]=hAfter
end,"CompileQuests")
check("E05 OPEN: opposite-view transient A-B-A leaves identical source output",
    function()
        return effectiveQuestName(transientHStage,viewH,77301)==hAfter
            and transientHStage.questBin==canonicalStage.questBin
            and transientHStage.questPtrs==canonicalStage.questPtrs
            and verifyTrue(transientHStage)
    end, fromStage(transientHStage,"questBin"))

-- CS02's independently reproduced stricter mid-compiler timing, now
-- exercised in CI with *real* source rows and a real writer-owned stream.
-- A full 120-row toy table is required so the first 49-entry batch finishes
-- before a source edit changes the not-yet-encoded rows.
local function inventedManyNPCs()
    resetInvented()
    db.npcData={}
    for id=77101,77220 do
        db.npcData[id]={[db.npcKeys.name]="Torn A"}
    end
end
local function interleavedNpcAttempt(mutator,afterSecondBatch)
    local stage={}
    local token=compiler:BeginNQStagedGeneration(stage)
    local lease,finishCount=nil,0
    local driverCleanupCount=0
    local owner={}
    function owner:Acquire(streamParent,mode)
        assert(not lease)
        lease={stream=streamParent:GetStream(mode)}
        return lease
    end
    function owner:Finish(actual)
        assert(actual==lease and finishCount==0)
        finishCount=finishCount+1
        actual.stream:finished()
    end
    stage._nqWriterLeaseOwner=owner
    local thread=coroutine.create(function()
        compiler:CompileNPCs(stage)
    end)
    local ok,reason=true,nil
    local secondBatchHookCalled=false
    local firstOk,firstReason=coroutine.resume(thread)
    if not (firstOk and coroutine.status(thread)=="suspended") then
        ok,reason=false,"first NPC yield failed: "..tostring(firstReason)
    else
        local batchOk,batchReason=coroutine.resume(thread)
        if not (batchOk and coroutine.status(thread)=="suspended") then
            ok,reason=false,"first actual NPC row batch did not suspend: "..tostring(batchReason)
        else
            local mutOk,mutErr=pcall(mutator)
            if not mutOk then
                ok,reason=false,tostring(mutErr)
            else
                for _=1,256 do
                    local resumed,res=coroutine.resume(thread)
                    ok,reason=resumed,res
                    if afterSecondBatch and not secondBatchHookCalled
                        and ok and coroutine.status(thread)=="suspended" then
                        -- The second batch encoded live B while this thread ran.
                        -- Restore A only AFTER that actual suspended writer interval.
                        local hookOk,hookErr=pcall(afterSecondBatch)
                        if not hookOk then
                            ok,reason=false,tostring(hookErr)
                            break
                        end
                        secondBatchHookCalled=true
                    end
                    if not ok or coroutine.status(thread)=="dead" then break end
                end
            end
        end
    end
    local dead=coroutine.status(thread)=="dead"
    if dead and lease and finishCount==0 then
        lease.stream:finished() -- driver cleanup only after DEAD
        driverCleanupCount=driverCleanupCount+1
    end
    if ok then
        -- The remaining unrelated writers use their normal real streams;
        -- this NPC lease's single-use owner has already finished.
        stage._nqWriterLeaseOwner=nil
        for _,method in ipairs({"CompileObjects","CompileQuests","CompileItems"}) do
            local kindOk,kindErr=drive(function()compiler[method](compiler,stage)end)
            if not kindOk then
                ok,reason=false,kindErr
                break
            end
        end
    end
    local verified=false
    if ok then
        verified=pcall(function()
            assert(compiler:VerifyNQStagedGeneration(stage,token)==true)
        end)
    end
    local outReason
    if not ok then
        outReason=normalizeReason(tostring(reason))
    elseif stage._nqStatus~=nil then
        outReason=tostring(stage._nqStatus)
    end
    return {ok=ok,reason=outReason,stage=stage,dead=dead,
        writerFinishCount=finishCount,driverCleanupCount=driverCleanupCount,
        secondBatchHookCalled=secondBatchHookCalled,verified=verified}
end

inventedManyNPCs()
local torn=interleavedNpcAttempt(function()
    for id=77101,77220 do
        db.npcData[id][db.npcKeys.name]="Torn B"
    end
end)
check("E01 STRONG MID-STREAM: already-encoded A and later B coexist",
    function()
        return torn.ok and torn.dead and torn.writerFinishCount==1
            and torn.verified and
            readName(torn.stage,"npc","npc","npcKeys",77101)=="Torn A"
            and readName(torn.stage,"npc","npc","npcKeys",77220)=="Torn B"
    end, fromAttempt(torn,"npcBin"))
check("E02 MID-STREAM: receipts authenticate actual mixed bytes, no epoch",
    function()
        return torn.ok and torn.verified and
            db.npcData[77101][db.npcKeys.name]=="Torn B" and
            db.npcData[77220][db.npcKeys.name]=="Torn B"
            and readName(torn.stage,"npc","npc","npcKeys",77101)~=
                db.npcData[77101][db.npcKeys.name]
    end, fromAttempt(torn,"npcBin"))

inventedManyNPCs()
local deleted=interleavedNpcAttempt(function()
    db.npcData[77180]=nil -- recorded in indexLookup; not yet encoded
end)
check("E03 MID-STREAM deletion fails but with untyped Lua error",
    function()
        return not deleted.ok and deleted.dead and deleted.writerFinishCount==0
            and deleted.driverCleanupCount==1 and not deleted.verified and
            deleted.stage.npcBin==nil and deleted.stage.npcPtrs==nil
            and deleted.reason:find("GATE08_",1,true)==nil
            and deleted.reason:find("nil",1,true)~=nil
    end, fromAttempt(deleted,"npcBin"))
check("E03 deleted writer cleanup is only performed after coroutine DEAD",
    function()
        return not deleted.ok and deleted.dead and deleted.writerFinishCount==0
            and deleted.stage._nqWriterLeaseOwner~=nil
            and deleted.driverCleanupCount==1
    end, fromAttempt(deleted,"npcBin"))

inventedManyNPCs()
local appended=interleavedNpcAttempt(function()
    db.npcData[77999]={[db.npcKeys.name]="New live row"}
end)
check("E06 MID-STREAM appended id silently omitted by prebuilt index",
    function()
        return appended.ok and appended.dead and appended.verified
            and appended.writerFinishCount==1
            and db.npcData[77999]~=nil
            and readName(appended.stage,"npc","npc","npcKeys",77999)==nil
    end, fromAttempt(appended,"npcBin"))
check("E06 original rows remain readably encoded while late row omitted",
    function()
        return appended.ok and appended.verified
            and readName(appended.stage,"npc","npc","npcKeys",77101)=="Torn A"
            and readName(appended.stage,"npc","npc","npcKeys",77220)=="Torn A"
    end, fromAttempt(appended,"npcBin"))

-- E02m is a stronger source A->B->A witness: mutate AFTER first
-- 49 rows, let the real coroutine encode one 49-row B batch, then restore
-- every live row to A before its final batch. Source equality at Begin/End
-- and private scratch receipts cannot detect the torn middle of the Bin.
inventedManyNPCs()
local coherentA=compileStage()
local middleABA=interleavedNpcAttempt(function()
    for id=77101,77220 do
        db.npcData[id][db.npcKeys.name]="Torn B"
    end
end,function()
    for id=77101,77220 do
        assert(db.npcData[id][db.npcKeys.name]=="Torn B")
        db.npcData[id][db.npcKeys.name]="Torn A"
    end
end)
check("E02m OPEN: true mid-stream source A-B-A leaves verified torn middle",
    function()
        return middleABA.ok and middleABA.dead and middleABA.verified
            and middleABA.secondBatchHookCalled
            and middleABA.writerFinishCount==1
            and middleABA.driverCleanupCount==0
            and middleABA.stage._nqStatus==nil
            and middleABA.stage.npcBin~=coherentA.npcBin
            and middleABA.stage.npcPtrs==coherentA.npcPtrs
            and db.npcData[77101][db.npcKeys.name]=="Torn A"
            and db.npcData[77160][db.npcKeys.name]=="Torn A"
            and db.npcData[77220][db.npcKeys.name]=="Torn A"
            and readName(middleABA.stage,"npc","npc","npcKeys",77101)=="Torn A"
            and readName(middleABA.stage,"npc","npc","npcKeys",77160)=="Torn B"
            and readName(middleABA.stage,"npc","npc","npcKeys",77220)=="Torn A"
    end, fromAttempt(middleABA,"npcBin"))

-- E02m audit hardening: CS02 found that testing only three source rows
-- lets an un-restored B (for example row 77180) pass the previous witness.
-- Exhaustively compare ALL 120 live source rows to A and ALL 120 values
-- decoded through the REAL GetDBHandle reader to the exact 49/49/22 map.
-- Separate check retained so the original #18 remains an historical witness.
local allSourceRowsAreA=true
local allReadbackRowsMatch=true
local sourceRowCount=0
for id,record in pairs(db.npcData) do
    sourceRowCount=sourceRowCount+1
    if type(id)~="number" or id<77101 or id>77220 or
            type(record)~="table" or
            record[db.npcKeys.name]~="Torn A" then
        allSourceRowsAreA=false
    end
end
for id=77101,77220 do
    local live=db.npcData[id]
    if type(live)~="table" or
            live[db.npcKeys.name]~="Torn A" then
        allSourceRowsAreA=false
    end
    local expected
    if id<=77149 then
        expected="Torn A"
    elseif id<=77198 then
        expected="Torn B"
    else
        expected="Torn A"
    end
    if readName(middleABA.stage,"npc","npc","npcKeys",id)~=expected then
        allReadbackRowsMatch=false
    end
end
check("E02m EXHAUSTIVE: all 120 source A, reader 49 A / 49 B / 22 A",
    function()
        return middleABA.ok and middleABA.verified
            and sourceRowCount==120
            and allSourceRowsAreA and allReadbackRowsMatch
            and middleABA.stage.npcBin~=coherentA.npcBin
    end, fromAttempt(middleABA,"npcBin"))
end

-- Part39 candidate shims. These strings are applied to an in-memory copy of
-- Database/compiler.lua. Nothing here is written back to the production file.
-- start_end: fingerprint the compiled table before the first yield and again
-- before publish, plus the #201 nil-row check. A match at both ends still
-- accepts a torn middle (E02m). per_row: snapshot each record at encode time
-- and compare it with the live row before publish. Mutations that happen
-- before a row is encoded stay invisible to per_row.
local CANDIDATE_HELPERS=[==[
local function nqDeepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do
        copy[nqDeepCopy(k)] = nqDeepCopy(v)
    end
    return copy
end
local function nqDeepEqual(a, b)
    if a == b then return true end
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return false end
    for k, v in pairs(a) do
        if not nqDeepEqual(v, b[k]) then return false end
    end
    for k, v in pairs(b) do
        if not nqDeepEqual(a[k], v) then return false end
    end
    return true
end
local function nqCandidateRetry(stage, stream, leaseOwner, lease)
    if NQ_CANDIDATE_CLEAN then
        if stage ~= nil then stage._nqStatus = "RETRY" end
        if leaseOwner ~= nil then
            leaseOwner:Finish(lease)
        else
            stream:finished()
        end
        return true
    end
    error(NQ_CANDIDATE_ERROR, 0)
end
]==]

local function mustReplace(source, old, new, what)
    local first, last = source:find(old, 1, true)
    if not first then error("candidate patch anchor missing: "..what, 0) end
    if source:find(old, last + 1, true) then
        error("candidate patch anchor not unique: "..what, 0)
    end
    return source:sub(1, first - 1)..new..source:sub(last + 1)
end

local function applyCandidate(source, spec)
    local header = "local NQ_CANDIDATE_CLEAN = "..(spec.clean and "true" or "false")
        .."\nlocal NQ_CANDIDATE_KIND = "..string.format("%q", spec.kind)
        .."\nlocal NQ_CANDIDATE_ERROR = "..string.format("%q", spec.errString)
        .."\nNQ_CANDIDATE_MARKER = "..string.format("%q", spec.marker)
        .."\n"..CANDIDATE_HELPERS.."\n"
    source = header..source
    source = mustReplace(source,
        "    local supportedTypes = QuestieDBCompiler.supportedTypes\n\n    while true do\n",
        "    local supportedTypes = QuestieDBCompiler.supportedTypes\n"
            .."    local nqSourceAtStart = nqDeepCopy(tbl)\n"
            .."    local nqRowCapture = {}\n\n    while true do\n",
        "source snapshot")
    source = mustReplace(source,
        "            if index == count then\n                if stage ~= nil then\n",
        "            if index == count then\n"
            .."                if NQ_CANDIDATE_KIND == \"start_end\" and not nqDeepEqual(nqSourceAtStart, tbl) then\n"
            .."                    if nqCandidateRetry(stage, stream, leaseOwner, lease) then return end\n"
            .."                end\n"
            .."                if NQ_CANDIDATE_KIND == \"per_row\" then\n"
            .."                    local nqRowMismatch = false\n"
            .."                    for nqId, nqSnap in pairs(nqRowCapture) do\n"
            .."                        if not nqDeepEqual(nqSnap, tbl[nqId]) then\n"
            .."                            nqRowMismatch = true\n"
            .."                            break\n"
            .."                        end\n"
            .."                    end\n"
            .."                    if nqRowMismatch then\n"
            .."                        if nqCandidateRetry(stage, stream, leaseOwner, lease) then return end\n"
            .."                    end\n"
            .."                end\n"
            .."                if stage ~= nil then\n",
        "publish gate")
    source = mustReplace(source,
        "            local entry = tbl[id]\n\n            pointerMap[id] = stream._pointer--pointerStart\n",
        "            local entry = tbl[id]\n"
            .."            if entry == nil and NQ_CANDIDATE_KIND == \"start_end\" then\n"
            .."                if nqCandidateRetry(stage, stream, leaseOwner, lease) then return end\n"
            .."            end\n\n"
            .."            pointerMap[id] = stream._pointer--pointerStart\n",
        "nil-row")
    source = mustReplace(source,
        "            -- tbl[id] = nil -- quicker gabage collection later\n",
        "            if entry ~= nil then nqRowCapture[id] = nqDeepCopy(entry) end\n"
            .."            -- tbl[id] = nil -- quicker gabage collection later\n",
        "row capture")
    return source
end

local function compilerSource()
    local info = debug.getinfo(compiler.CompileTableCoroutine, "S")
    return info and info.source or ""
end
local function isProductionCompiler()
    return compilerSource():find("Database/compiler.lua", 1, true) ~= nil
end
local function isCandidateCompiler()
    return compilerSource():find("nq-candidate-compiler.lua", 1, true) ~= nil
end
local function restoreProduction()
    compiler = productionCompiler
    modules.DBCompiler = productionCompiler
    NQ_CANDIDATE_MARKER = nil
end
local function loadChunk(src, name)
    local loader = loadstring or load
    return loader(src, name)
end
local function readFile(path)
    local handle = assert(io.open(path, "rb"))
    local body = handle:read("*a")
    handle:close()
    return body
end

local function P(extra)
    local row = {
        ok=true, verified=true, reason=nil, passed=true, published=true,
        finish=nil, cleanup=nil,
    }
    if extra then
        for k, v in pairs(extra) do row[k] = v end
    end
    return row
end
local function typed(code, passed, finish, cleanup)
    return {
        ok=false, verified=false, reason=code, passed=passed, published=false,
        finish=finish, cleanup=cleanup,
    }
end
local function cleanOutcome(passed, finish, cleanup)
    return {
        ok=true, verified=false, reason="RETRY", passed=passed, published=false,
        finish=finish, cleanup=cleanup,
    }
end
local function nilErr(passed)
    return {
        ok=false, verified=false, reasonPat="NIL_ERROR", passed=passed,
        published=false, finish=0, cleanup=1,
    }
end
local function interPass()
    return P({finish=1, cleanup=0})
end

-- Declared pin flips: the historical #214 predicate stops passing.
--   start_end_typed  1, 4, 12, 13, 14, 16, 17
--   start_end_clean  1, 4, 12, 13, 14, 15, 16, 17
--   per_row_typed    12, 13, 18, 19
--   per_row_clean    12, 13, 18, 19
-- W03's pin stays PASS under start/end because `nil ~= bin` is true.
-- W15's typed pin stays PASS because any DEAD throw still cleans up once.
-- start/end does not change E02 or E02m. per-row flips E02m only among
-- the coherent-looking witnesses, plus the already-encoded mixed rows.
local EXPECTED_PIN_FLIPS = {
    start_end_typed={1,4,12,13,14,16,17},
    start_end_clean={1,4,12,13,14,15,16,17},
    per_row_typed={12,13,18,19},
    per_row_clean={12,13,18,19},
}
local EXPECTED_OUTCOME_CHANGES = {
    start_end_typed={1,3,4,12,13,14,15,16,17},
    start_end_clean={1,3,4,12,13,14,15,16,17},
    per_row_typed={12,13,18,19},
    per_row_clean={12,13,18,19},
}
local EXPECTED = {
    {label="E01 OPEN: persistent NPC edit across yield stages as B without RETRY",
        baseline=P(), start_end_typed=typed("GATE08_STAGE_SOURCE_RETRY", false),
        start_end_clean=cleanOutcome(false), per_row_typed=P(), per_row_clean=P()},
    {label="E02 OPEN: source A-B-A remains compiler-accepted with identical bytes",
        baseline=P(), start_end_typed=P(), start_end_clean=P(),
        per_row_typed=P(), per_row_clean=P()},
    {label="E03 OPEN: nested questStarts index changed across yield with no RETRY",
        baseline=P(), start_end_typed=typed("GATE08_STAGE_SOURCE_RETRY", true),
        start_end_clean=cleanOutcome(true), per_row_typed=P(), per_row_clean=P()},
    {label="E07 OPEN: uninstrumented external item writer reaches staged bytes",
        baseline=P(), start_end_typed=typed("GATE08_STAGE_SOURCE_RETRY", false),
        start_end_clean=cleanOutcome(false), per_row_typed=P(), per_row_clean=P()},
    {label="E06 OPEN: unrelated source append has no defined epoch policy",
        baseline=P(), start_end_typed=P(), start_end_clean=P(),
        per_row_typed=P(), per_row_clean=P()},
    {label="E08 FIXTURE: unchanged legacy NPC raw encoding equals staged bytes",
        baseline=P(), start_end_typed=P(), start_end_clean=P(),
        per_row_typed=P(), per_row_clean=P()},
    {label="E04 PRECONDITION: invented override-only quest has no base pointer",
        baseline=P(), start_end_typed=P(), start_end_clean=P(),
        per_row_typed=P(), per_row_clean=P()},
    {label="E04 OPEN: real MinimalInit adds override-only quest after stage Begin",
        baseline=P(), start_end_typed=P(), start_end_clean=P(),
        per_row_typed=P(), per_row_clean=P()},
    {label="E04 OPEN: actual addOverride merges into pre-existing nested entry",
        baseline=P(), start_end_typed=P(), start_end_clean=P(),
        per_row_typed=P(), per_row_clean=P()},
    {label="E05 OPEN: A-only preflight cannot certify changed opposite view",
        baseline=P(), start_end_typed=P(), start_end_clean=P(),
        per_row_typed=P(), per_row_clean=P()},
    {label="E05 OPEN: opposite-view transient A-B-A leaves identical source output",
        baseline=P(), start_end_typed=P(), start_end_clean=P(),
        per_row_typed=P(), per_row_clean=P()},
    {label="E01 STRONG MID-STREAM: already-encoded A and later B coexist",
        baseline=interPass(),
        start_end_typed=typed("GATE08_STAGE_SOURCE_RETRY", false, 0, 1),
        start_end_clean=cleanOutcome(false, 1, 0),
        per_row_typed=typed("GATE08_STAGE_ROW_RETRY", false, 0, 1),
        per_row_clean=cleanOutcome(false, 1, 0)},
    {label="E02 MID-STREAM: receipts authenticate actual mixed bytes, no epoch",
        baseline=interPass(),
        start_end_typed=typed("GATE08_STAGE_SOURCE_RETRY", false, 0, 1),
        start_end_clean=cleanOutcome(false, 1, 0),
        per_row_typed=typed("GATE08_STAGE_ROW_RETRY", false, 0, 1),
        per_row_clean=cleanOutcome(false, 1, 0)},
    {label="E03 MID-STREAM deletion fails but with untyped Lua error",
        baseline=nilErr(true),
        start_end_typed=typed("GATE08_STAGE_SOURCE_RETRY", false, 0, 1),
        start_end_clean=cleanOutcome(false, 1, 0),
        per_row_typed=nilErr(true), per_row_clean=nilErr(true)},
    {label="E03 deleted writer cleanup is only performed after coroutine DEAD",
        baseline=nilErr(true),
        start_end_typed=typed("GATE08_STAGE_SOURCE_RETRY", true, 0, 1),
        start_end_clean=cleanOutcome(false, 1, 0),
        per_row_typed=nilErr(true), per_row_clean=nilErr(true)},
    {label="E06 MID-STREAM appended id silently omitted by prebuilt index",
        baseline=interPass(),
        start_end_typed=typed("GATE08_STAGE_SOURCE_RETRY", false, 0, 1),
        start_end_clean=cleanOutcome(false, 1, 0),
        per_row_typed=interPass(), per_row_clean=interPass()},
    {label="E06 original rows remain readably encoded while late row omitted",
        baseline=interPass(),
        start_end_typed=typed("GATE08_STAGE_SOURCE_RETRY", false, 0, 1),
        start_end_clean=cleanOutcome(false, 1, 0),
        per_row_typed=interPass(), per_row_clean=interPass()},
    {label="E02m OPEN: true mid-stream source A-B-A leaves verified torn middle",
        baseline=interPass(), start_end_typed=interPass(), start_end_clean=interPass(),
        per_row_typed=typed("GATE08_STAGE_ROW_RETRY", false, 0, 1),
        per_row_clean=cleanOutcome(false, 1, 0)},
    {label="E02m EXHAUSTIVE: all 120 source A, reader 49 A / 49 B / 22 A",
        baseline=interPass(), start_end_typed=interPass(), start_end_clean=interPass(),
        per_row_typed=typed("GATE08_STAGE_ROW_RETRY", false, 0, 1),
        per_row_clean=cleanOutcome(false, 1, 0)},
}

local MODES = {"baseline","start_end_typed","start_end_clean","per_row_typed","per_row_clean"}
local CANDIDATES = {
    {name="start_end_typed", clean=false, kind="start_end", errString="GATE08_STAGE_SOURCE_RETRY"},
    {name="start_end_clean", clean=true, kind="start_end", errString="GATE08_STAGE_SOURCE_RETRY"},
    {name="per_row_typed", clean=false, kind="per_row", errString="GATE08_STAGE_ROW_RETRY"},
    {name="per_row_clean", clean=true, kind="per_row", errString="GATE08_STAGE_ROW_RETRY"},
}

local function listText(list)
    local parts = {}
    for _, id in ipairs(list) do parts[#parts+1] = tostring(id) end
    return table.concat(parts, ",")
end
local function listsEqual(a, b)
    if #a ~= #b then return false end
    for i=1,#a do
        if a[i] ~= b[i] then return false end
    end
    return true
end
local function reasonKey(cell)
    if cell.reasonPat then return "pat:"..cell.reasonPat end
    if cell.reason == nil then return "nil" end
    return "exact:"..cell.reason
end
local function declaredOutcomeChanged(a, b)
    return a.ok ~= b.ok or a.verified ~= b.verified or a.published ~= b.published
        or a.finish ~= b.finish or a.cleanup ~= b.cleanup
        or reasonKey(a) ~= reasonKey(b)
end
local function sameReason(expected, actual)
    if expected.reasonPat == "NIL_ERROR" then
        return type(actual)=="string"
            and actual:find("nil", 1, true) ~= nil
            and actual:find("GATE08_", 1, true) == nil
    end
    return expected.reason == actual
end
local function showReason(reason)
    if reason == nil then return "-" end
    return (tostring(reason):gsub("[%c|]", " "))
end
local function flag(value)
    if value == true then return "true" end
    if value == false then return "false" end
    if value == nil then return "-" end
    return tostring(value)
end

local function assertDeclaration()
    if #EXPECTED ~= 19 then error("expected table is not 19 witnesses", 0) end
    for _, mode in ipairs({"start_end_typed","start_end_clean","per_row_typed","per_row_clean"}) do
        local pins, changes = {}, {}
        for i, spec in ipairs(EXPECTED) do
            if not spec.baseline.passed then
                error("baseline pin "..i.." is not a KNOWN UNSAFE pass", 0)
            end
            if spec.baseline.passed and not spec[mode].passed then
                pins[#pins+1] = i
            end
            if declaredOutcomeChanged(spec.baseline, spec[mode]) then
                changes[#changes+1] = i
            end
        end
        if not listsEqual(pins, EXPECTED_PIN_FLIPS[mode]) then
            error("pin-flip declaration drifted for "..mode.." got "..listText(pins), 0)
        end
        if not listsEqual(changes, EXPECTED_OUTCOME_CHANGES[mode]) then
            error("outcome-change declaration drifted for "..mode.." got "..listText(changes), 0)
        end
    end
end

local function runBattery(printPins)
    local results = {}
    runEarly(printPins, results)
    runLate(printPins, results)
    return results
end

local function runCandidate(spec, source)
    local patched = applyCandidate(source, {
        marker=spec.name, clean=spec.clean, kind=spec.kind, errString=spec.errString,
    })
    modules.DBCompiler = nil
    local chunk, loadErr = loadChunk(patched, "@nq-candidate-compiler.lua")
    if not chunk then
        restoreProduction()
        error(loadErr, 0)
    end
    local loaded, runErr = pcall(chunk)
    if not loaded then
        restoreProduction()
        error(runErr, 0)
    end
    compiler = modules.DBCompiler
    if not isCandidateCompiler() or NQ_CANDIDATE_MARKER ~= spec.name then
        local seen = compilerSource().." marker="..tostring(NQ_CANDIDATE_MARKER)
        restoreProduction()
        error("candidate shim did not install for "..spec.name.." ("..seen..")", 0)
    end
    local ok, results = pcall(runBattery, false)
    restoreProduction()
    if not ok then error(results, 0) end
    return results
end

assertDeclaration()
local productionSource = readFile("Database/compiler.lua")
if productionSource:find("NQ_CANDIDATE_MARKER", 1, true) then
    error("production compiler already contains a candidate marker", 0)
end
if not isProductionCompiler() or NQ_CANDIDATE_MARKER ~= nil then
    error("baseline is not the production compiler ("..compilerSource()..")", 0)
end

local byMode = {}
byMode.baseline = runBattery(true)
for _, spec in ipairs(CANDIDATES) do
    if not isProductionCompiler() then
        error("production compiler was not restored before "..spec.name, 0)
    end
    byMode[spec.name] = runCandidate(spec, productionSource)
end
if not isProductionCompiler() or NQ_CANDIDATE_MARKER ~= nil then
    error("candidate shim leaked after the suite ("..compilerSource()..")", 0)
end
if readFile("Database/compiler.lua") ~= productionSource then
    error("production compiler bytes changed during the suite", 0)
end

local mismatches = {}
local function note(message)
    mismatches[#mismatches+1] = message
end
local pinCounts, changeCounts = {}, {}
for _, mode in ipairs(MODES) do
    local rows = byMode[mode]
    if #rows ~= 19 then
        note(mode.." produced "..tostring(#rows).." witnesses")
    end
    pinCounts[mode] = 0
    changeCounts[mode] = 0
end
for index, spec in ipairs(EXPECTED) do
    local base = byMode.baseline[index]
    for _, mode in ipairs(MODES) do
        local actual = byMode[mode] and byMode[mode][index]
        local expect = spec[mode]
        if not actual then
            note(string.format("%02d %s missing", index, mode))
        else
            if actual.label ~= spec.label then
                note(string.format("%02d %s label %q", index, mode, tostring(actual.label)))
            end
            if actual.predicateError then
                note(string.format("%02d %s predicate error %s", index, mode, actual.predicateError))
            end
            local fields = {
                {"ok", expect.ok, actual.ok},
                {"verified", expect.verified, actual.verified},
                {"passed", expect.passed, actual.passed},
                {"published", expect.published, actual.published},
                {"finish", expect.finish, actual.finish},
                {"cleanup", expect.cleanup, actual.cleanup},
            }
            for _, field in ipairs(fields) do
                if field[2] ~= field[3] then
                    note(string.format("%02d %s %s expected=%s actual=%s",
                        index, mode, field[1], flag(field[2]), flag(field[3])))
                end
            end
            if not sameReason(expect, actual.reason) then
                note(string.format("%02d %s reason expected=%s actual=%s",
                    index, mode, reasonKey(expect), showReason(actual.reason)))
            end
            local pinFlip = "no"
            if mode ~= "baseline" and base and base.passed and not actual.passed then
                pinFlip = "yes"
                pinCounts[mode] = pinCounts[mode] + 1
            end
            if mode ~= "baseline" and base and (
                base.ok ~= actual.ok or base.verified ~= actual.verified
                or base.published ~= actual.published or base.finish ~= actual.finish
                or base.cleanup ~= actual.cleanup or base.reason ~= actual.reason) then
                changeCounts[mode] = changeCounts[mode] + 1
            end
            print(string.format(
                "WITNESS %02d %s ok=%s verified=%s reason=%s passed=%s published=%s finish=%s cleanup=%s pinFlip=%s",
                index, mode, flag(actual.ok), flag(actual.verified), showReason(actual.reason),
                flag(actual.passed), flag(actual.published), flag(actual.finish),
                flag(actual.cleanup), pinFlip))
        end
    end
end
for _, mode in ipairs({"start_end_typed","start_end_clean","per_row_typed","per_row_clean"}) do
    if pinCounts[mode] ~= #EXPECTED_PIN_FLIPS[mode] then
        note(mode.." pinFlip count "..tostring(pinCounts[mode]))
    end
    if changeCounts[mode] ~= #EXPECTED_OUTCOME_CHANGES[mode] then
        note(mode.." outcomeChange count "..tostring(changeCounts[mode]))
    end
end

local summary = string.format(
    "GATE08 RETRY FLIP-MAP: mismatches=%d witnesses=19 candidates=4 pinFlips=start_end_typed:%d,start_end_clean:%d,per_row_typed:%d,per_row_clean:%d outcomeChanges=start_end_typed:%d,start_end_clean:%d,per_row_typed:%d,per_row_clean:%d",
    #mismatches,
    pinCounts.start_end_typed or -1, pinCounts.start_end_clean or -1,
    pinCounts.per_row_typed or -1, pinCounts.per_row_clean or -1,
    changeCounts.start_end_typed or -1, changeCounts.start_end_clean or -1,
    changeCounts.per_row_typed or -1, changeCounts.per_row_clean or -1)
print(summary)
print("GATE08 RETRY FLIP-MAP RUNTIME: ".._VERSION)
print("GATE08 RETRY FLIP-MAP NOTE: start/end compare RETRY does not flip E02 or E02m; torn middle stays verified")
print("GATE08 RETRY FLIP-MAP NOTE: per-row capture flips E02m and already-encoded mixed rows; pre-encode edits stay accepted")
print("GATE08 RETRY FLIP-MAP NOTE: W03 historical pin stays PASS under start/end because nil ~= bin; outcome is still RETRY")
print("GATE08 RETRY FLIP-MAP NOTE: W15 typed pin stays PASS because any DEAD throw still cleans up once; clean RETRY calls Finish")

local baselinePins = 0
for _, row in ipairs(byMode.baseline) do
    if row.passed and not row.predicateError then baselinePins = baselinePins + 1 end
end
if baselinePins == 19 then
    print("GATE08 SOURCE EPOCH KNOWN-GAPS: 19/19 CHARACTERIZED (NOT FIXED)")
    print("BLOCKED E01-E08: no source-writer exclusion, no source A-B-A epoch, no guarded publication, no client QA")
else
    note("baseline pins "..baselinePins.."/19")
end
print("PRODUCTION COMPILER UNMODIFIED: VERIFIED")
print("CANDIDATE SHIMS RESTORED: VERIFIED")
if #mismatches > 0 then
    for _, message in ipairs(mismatches) do
        print("MISMATCH "..message)
    end
    error("GATE08 RETRY FLIP-MAP mismatches="..#mismatches, 0)
end
