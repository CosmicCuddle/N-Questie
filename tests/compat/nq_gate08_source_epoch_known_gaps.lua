-- Part37 Gate08: actual Questie source-coroutine mutation witnesses.
-- All IDs/names are invented. THESE ARE EXPECTED OPEN SAFETY GAPS,
-- not passed source-epoch acceptance cases E01-E08.
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
local saved=Questie.db.global
saved.nQuestieDataRevision=57
saved.dbCompiledCount=9
local count=0
local function check(label,ok)
    count=count+1
    assert(ok,"FAIL GATE08 SOURCE EPOCH WITNESS "..count.." "..label)
    print("PASS KNOWN-GAP GATE08 SOURCE EPOCH WITNESS "..count.." "..label)
end
local function drive(fn)
    local t=coroutine.create(fn)
    for _=1,256 do
        local ok,res=coroutine.resume(t)
        assert(ok,tostring(res))
        if coroutine.status(t)=="dead" then return res end
    end
    error("synthetic Questie coroutine exceeded 256 resumes")
end
local categories={"CompileNPCs","CompileObjects","CompileQuests","CompileItems"}
local function resetInvented()
    db.npcData={[77101]={
        [db.npcKeys.name]="Witness A",
        [db.npcKeys.questStarts]={77301},
    }}
    db.objectData={[77201]={[db.objectKeys.name]="Witness Object"}}
    db.questData={[77301]={[db.questKeys.name]="Witness Quest"}}
    db.itemData={[77401]={[db.itemKeys.name]="Witness Item"}}
end
local function compileStage(hook,hookKind)
    local scratch={}
    local token=compiler:BeginNQStagedGeneration(scratch)
    for _,method in ipairs(categories) do
        local t=coroutine.create(function() compiler[method](compiler,scratch) end)
        local ok,res=coroutine.resume(t)
        assert(ok and coroutine.status(t)=="suspended",tostring(res))
        if hook and method==(hookKind or "CompileNPCs") then hook() end
        for _=1,256 do
            if coroutine.status(t)=="dead" then break end
            ok,res=coroutine.resume(t)
            assert(ok,tostring(res))
        end
        assert(coroutine.status(t)=="dead","writer did not finish: "..method)
    end
    assert(compiler:VerifyNQStagedGeneration(scratch,token)==true)
    return scratch
end
local function readName(stage,prefix,kind,keys,id)
    local h=drive(function()
        return compiler:GetDBHandle(stage[prefix.."Bin"],stage[prefix.."Ptrs"],
            compiler:BuildSkipMap(db[kind.."CompilerTypes"],
                db[kind.."CompilerOrder"]),db[keys],nil)
    end)
    local result=h.QuerySingle(id,"name")
    h.stream:finished()
    return result
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
    readName(late,"npc","npc","npcKeys",77101)=="Witness B"
    and late.npcBin~=clean.npcBin)

-- E02 characteristic: the *same* source data A at both ends can hide a
-- transient mutation during suspension. Final-value equality cannot prove
-- source immutability, even though four-kind receipt Verify passes.
resetInvented()
local aba=compileStage(function()
    db.npcData[77101][db.npcKeys.name]="Witness B"
    db.npcData[77101][db.npcKeys.name]="Witness A"
end)
check("E02 OPEN: source A-B-A remains compiler-accepted with identical bytes",
    aba.npcBin==clean.npcBin and aba.npcPtrs==clean.npcPtrs
    and readName(aba,"npc","npc","npcKeys",77101)=="Witness A")

-- E03 characteristic: mutating an already-present nested array element does
-- not need to replace the outer record or trigger Lua __newindex at its root.
resetInvented()
local nested=compileStage(function()
    db.npcData[77101][db.npcKeys.questStarts][1]=77302
end)
check("E03 OPEN: nested questStarts index changed across yield with no RETRY",
    nested.npcBin~=clean.npcBin and
    db.npcData[77101][db.npcKeys.questStarts][1]==77302)

-- E07 characteristic: a direct write from an unknown addon-like function
-- reaches the exported normal source table with no writer registration.
resetInvented()
local function unknownExternalWriter()
    db.itemData[77401][db.itemKeys.name]="Unknown Writer"
end
local unknown=compileStage(unknownExternalWriter,"CompileItems")
check("E07 OPEN: uninstrumented external item writer reaches staged bytes",
    unknown.itemBin~=clean.itemBin and
    readName(unknown,"item","item","itemKeys",77401)=="Unknown Writer")

-- E06 boundary: the current scratch API is not a whole-source lock. An
-- unrelated change can happen without changing any of the output bytes.
resetInvented()
local unrelated=compileStage(function()
    db.npcData[77102]={[db.npcKeys.name]="Unrelated Late"}
end,"CompileItems")
check("E06 OPEN: unrelated source append has no defined epoch policy",
    unrelated.npcBin==clean.npcBin and
    db.npcData[77102]~=nil)

-- E08 limited invariant: legacy no-stage byte encoding with unchanged
-- source is preserved at fixture scale. This is NOT native 3.3.5a QA.
resetInvented()
local current=compileStage()
drive(function()compiler:CompileNPCs()end)
check("E08 FIXTURE: unchanged legacy NPC raw encoding equals staged bytes",
    current.npcBin==saved.npcBin and current.npcPtrs==saved.npcPtrs
    and saved.nQuestieDataRevision==57 and saved.dbCompiledCount==9)

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
local function effectiveQuestName(stage,view,id)
    local handle=drive(function()
        return compiler:GetDBHandle(stage.questBin,stage.questPtrs,
            compiler:BuildSkipMap(db.questCompilerTypes,db.questCompilerOrder),
            db.questKeys,view)
    end)
    local value=handle.QuerySingle(id,"name")
    handle.stream:finished()
    return value
end
resetInvented()
clearedOverrides()
local canonicalStage=compileStage()
check("E04 PRECONDITION: invented override-only quest has no base pointer",
    db.questData[77501]==nil and
    effectiveQuestName(canonicalStage,db.questDataOverrides,77501)==nil)
-- The actual MinimalInit code merges all four kinds of loader-supplied
-- overrides. It has no awareness of the already staged four-kind generation.
local fixtureMergeStage=compileStage(function()
    corrections:MinimalInit()
end,"CompileQuests")
check("E04 OPEN: real MinimalInit adds override-only quest after stage Begin",
    db.questData[77501]==nil and
    effectiveQuestName(fixtureMergeStage,db.questDataOverrides,77501)
        =="Invented A override-only quest"
    and fixtureMergeStage.questBin==canonicalStage.questBin
    and compiler:VerifyNQStagedGeneration(
        fixtureMergeStage,fixtureMergeStage._nqGenerationToken)==true)

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
    db.questDataOverrides[77501]==sameOverrideRecord and
    effectiveQuestName(fixtureNestedMergeStage,db.questDataOverrides,77501)
        =="Invented replacement"
    and fixtureNestedMergeStage.questBin==canonicalStage.questBin)
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
    acceptedA=="Invented A base override" and
    effectiveQuestName(alteredHStage,viewA,77301)==acceptedA and
    originalH=="Invented H base override" and
    effectiveQuestName(alteredHStage,viewH,77301)
        =="Invented H changed after A check"
    and alteredHStage.questBin==canonicalStage.questBin and
    compiler:VerifyNQStagedGeneration(
        alteredHStage,alteredHStage._nqGenerationToken)==true)
local hAfter=effectiveQuestName(alteredHStage,viewH,77301)
local transientHStage=compileStage(function()
    viewH[77301][db.questKeys.name]="Invented transient H"
    viewH[77301][db.questKeys.name]=hAfter
end,"CompileQuests")
check("E05 OPEN: opposite-view transient A-B-A leaves identical source output",
    effectiveQuestName(transientHStage,viewH,77301)==hAfter
    and transientHStage.questBin==canonicalStage.questBin
    and transientHStage.questPtrs==canonicalStage.questPtrs
    and compiler:VerifyNQStagedGeneration(
        transientHStage,transientHStage._nqGenerationToken)==true)

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
local function interleavedNpcAttempt(mutator)
    local stage={}
    local token=compiler:BeginNQStagedGeneration(stage)
    local lease,finishCount=nil,0
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
    local firstOk,firstReason=coroutine.resume(thread)
    assert(firstOk and coroutine.status(thread)=="suspended",
        "first NPC yield failed: "..tostring(firstReason))
    local batchOk,batchReason=coroutine.resume(thread)
    assert(batchOk and coroutine.status(thread)=="suspended",
        "first actual NPC row batch did not suspend: "..tostring(batchReason))
    mutator()
    local ok,reason=true,nil
    for _=1,256 do
        ok,reason=coroutine.resume(thread)
        if not ok or coroutine.status(thread)=="dead" then break end
    end
    local dead=coroutine.status(thread)=="dead"
    if dead and lease and finishCount==0 then
        lease.stream:finished() -- driver cleanup only after DEAD
    end
    if ok then
        for _,method in ipairs({"CompileObjects","CompileQuests","CompileItems"}) do
            drive(function()compiler[method](compiler,stage)end)
        end
    end
    local verified=false
    if ok then
        verified=pcall(function()
            assert(compiler:VerifyNQStagedGeneration(stage,token)==true)
        end)
    end
    return {ok=ok,reason=tostring(reason),stage=stage,dead=dead,
        writerFinishCount=finishCount,verified=verified}
end

inventedManyNPCs()
local torn=interleavedNpcAttempt(function()
    for id=77101,77220 do
        db.npcData[id][db.npcKeys.name]="Torn B"
    end
end)
check("E01 STRONG MID-STREAM: already-encoded A and later B coexist",
    torn.ok and torn.dead and torn.writerFinishCount==1
    and torn.verified and
    readName(torn.stage,"npc","npc","npcKeys",77101)=="Torn A"
    and readName(torn.stage,"npc","npc","npcKeys",77220)=="Torn B")
check("E02 MID-STREAM: receipts authenticate actual mixed bytes, no epoch",
    torn.ok and torn.verified and
    db.npcData[77101][db.npcKeys.name]=="Torn B" and
    db.npcData[77220][db.npcKeys.name]=="Torn B"
    and readName(torn.stage,"npc","npc","npcKeys",77101)~=
        db.npcData[77101][db.npcKeys.name])

inventedManyNPCs()
local deleted=interleavedNpcAttempt(function()
    db.npcData[77180]=nil -- recorded in indexLookup; not yet encoded
end)
check("E03 MID-STREAM deletion fails but with untyped Lua error",
    not deleted.ok and deleted.dead and deleted.writerFinishCount==0
    and not deleted.verified and
    deleted.stage.npcBin==nil and deleted.stage.npcPtrs==nil
    and deleted.reason:find("GATE08_",1,true)==nil
    and deleted.reason:find("nil",1,true)~=nil)
check("E03 deleted writer cleanup is only performed after coroutine DEAD",
    not deleted.ok and deleted.dead and deleted.writerFinishCount==0
    and deleted.stage._nqWriterLeaseOwner~=nil)

inventedManyNPCs()
local appended=interleavedNpcAttempt(function()
    db.npcData[77999]={[db.npcKeys.name]="New live row"}
end)
check("E06 MID-STREAM appended id silently omitted by prebuilt index",
    appended.ok and appended.dead and appended.verified
    and appended.writerFinishCount==1
    and db.npcData[77999]~=nil
    and readName(appended.stage,"npc","npc","npcKeys",77999)==nil)
check("E06 original rows remain readably encoded while late row omitted",
    appended.ok and appended.verified
    and readName(appended.stage,"npc","npc","npcKeys",77101)=="Torn A"
    and readName(appended.stage,"npc","npc","npcKeys",77220)=="Torn A")

assert(count==17,"expected seventeen known-gap witness checks, got "..count)
print("GATE08 SOURCE EPOCH KNOWN-GAPS: 17/17 CHARACTERIZED (NOT FIXED)")
print("BLOCKED E01-E08: no source-writer exclusion, no source A-B-A epoch, no guarded publication, no client QA")
