-- Part37 Gate08: actual Questie owned-copy source-input feasibility experiment.
-- All IDs/names/faction views invented. LOCAL BOUNDED FEASIBILITY ONLY.
-- Snapshot construction itself is NOT atomic, robust, sealed or RAM-profiled.
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
    assert(ok,"FAIL GATE08 OWNED SNAPSHOT "..count.." "..label)
    print("PASS FEASIBILITY GATE08 OWNED SNAPSHOT "..count.." "..label)
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

-- This is not a candidate production snapshot/driver; the only real
-- production components called are the pinned Questie compiler, stream codec,
-- readers and four-kind scratch receipts. Copying here is synchronous only
-- because the invented data are tiny and under this harness's control.
local function deepOwnedCopy(v,known)
    if type(v)~="table" then return v end
    known=known or {}
    if known[v] then return known[v] end
    local result={}
    known[v]=result
    for k,x in pairs(v) do
        assert(type(k)~="table","PROTOTYPE_UNSUPPORTED_TABLE_KEY")
        result[k]=deepOwnedCopy(x,known)
    end
    return result
end
local defs={
    {source="npcData",id="npc",label="NPC",types="npcCompilerTypes",order="npcCompilerOrder",keys="npcKeys"},
    {source="objectData",id="obj",label="Object",types="objectCompilerTypes",order="objectCompilerOrder",keys="objectKeys"},
    {source="questData",id="quest",label="Quest",types="questCompilerTypes",order="questCompilerOrder",keys="questKeys"},
    {source="itemData",id="item",label="Item",types="itemCompilerTypes",order="itemCompilerOrder",keys="itemKeys"},
}
local factionViews={}
local function initInventedSources()
    resetInvented()
    factionViews={
        A={[77301]={[db.questKeys.name]="Invented A effective"},
           [77501]={[db.questKeys.name]="Invented A override-only"}},
        H={[77301]={[db.questKeys.name]="Invented H effective"},
           [77501]={[db.questKeys.name]="Invented H override-only"}},
    }
end
local function ownInputs(afterNpcCopy)
    local owned={base={},views={}}
    local seen={}
    -- Four source kinds and both effective views are copied together in the
    -- fixture, but no real-world writer can yet be blocked during this loop.
    for _,k in ipairs(defs) do
        owned.base[k.id]=deepOwnedCopy(db[k.source],seen)
        if afterNpcCopy and k.id=="npc" then afterNpcCopy() end
    end
    owned.views.A=deepOwnedCopy(factionViews.A,seen)
    owned.views.H=deepOwnedCopy(factionViews.H,seen)
    return owned
end
local function compileOwned(owned,hook,when)
    local stage={}
    local token=compiler:BeginNQStagedGeneration(stage)
    for _,k in ipairs(defs) do
        local thread=coroutine.create(function()
            return compiler:CompileTableCoroutine(
                owned.base[k.id],db[k.types],db[k.order],db[k.keys],
                k.id,k.label,nil,stage)
        end)
        local ok,err=coroutine.resume(thread)
        assert(ok and coroutine.status(thread)=="suspended",tostring(err))
        if hook and k.id==(when or "npc") then hook() end
        for _=1,256 do
            if coroutine.status(thread)=="dead" then break end
            ok,err=coroutine.resume(thread)
            assert(ok,tostring(err))
        end
        assert(coroutine.status(thread)=="dead","owned writer did not finish "..k.id)
    end
    assert(compiler:VerifyNQStagedGeneration(stage,token)==true)
    return stage
end
local function readOwned(stage,kind,field,id,view)
    local one
    for _,k in ipairs(defs) do if k.id==kind then one=k end end
    assert(one)
    local h=drive(function()
        return compiler:GetDBHandle(
            stage[kind.."Bin"],stage[kind.."Ptrs"],
            compiler:BuildSkipMap(db[one.types],db[one.order]),
            db[one.keys],view)
    end)
    local v=h.QuerySingle(id,field)
    h.stream:finished()
    return v
end
initInventedSources()
local owned=ownInputs()
local clean=compileOwned(owned)
check("01 all four source tables deeply distinct from live originals",
    owned.base.npc~=db.npcData and owned.base.obj~=db.objectData
    and owned.base.quest~=db.questData and owned.base.item~=db.itemData
    and owned.base.npc[77101]~=db.npcData[77101]
    and owned.base.npc[77101][db.npcKeys.questStarts]~=
            db.npcData[77101][db.npcKeys.questStarts])
check("02 real four-kind owned compilation and private scratch receipts",
    type(clean.npcBin)=="string" and type(clean.objBin)=="string"
    and type(clean.questBin)=="string" and type(clean.itemBin)=="string"
    and readOwned(clean,"npc","name",77101,nil)=="Witness A"
    and readOwned(clean,"quest","name",77301,nil)=="Witness Quest")

-- Persistent and nested writes after owned copy cannot modify its encoded
-- four-kind result. This is source ISOLATION in a tiny fixture, not proof
-- every real module reader/writer consumes the copy.
local late=compileOwned(owned,function()
    db.npcData[77101][db.npcKeys.name]="Witness mutated LIVE"
    db.npcData[77101][db.npcKeys.questStarts][1]=77302
end,"npc")
local fromClone=readOwned(late,"npc","questStarts",77101,nil)
check("03 live NPC scalar edit during yield leaves owned bytes intact",
    late.npcBin==clean.npcBin and late.npcPtrs==clean.npcPtrs
    and readOwned(late,"npc","name",77101,nil)=="Witness A"
    and db.npcData[77101][db.npcKeys.name]~="Witness A")
check("04 live nested NPC questStarts edit does not alias cloned nested list",
    fromClone and fromClone[1]==77301
    and db.npcData[77101][db.npcKeys.questStarts][1]==77302
    and owned.base.npc[77101][db.npcKeys.questStarts][1]==77301)

local outsider=compileOwned(owned,function()
    db.itemData[77401][db.itemKeys.name]="Unknown LIVE item writer"
end,"item")
check("05 unregistered item writer after copy cannot modify owned item bytes",
    outsider.itemBin==clean.itemBin
    and readOwned(outsider,"item","name",77401,nil)=="Witness Item"
    and db.itemData[77401][db.itemKeys.name]~= "Witness Item")

local aba=compileOwned(owned,function()
    db.questData[77301][db.questKeys.name]="Temporary LIVE Quest"
    db.questData[77301][db.questKeys.name]="Witness Quest"
end,"quest")
check("06 live source A-B-A after copy cannot influence already-owned bytes",
    aba.questBin==clean.questBin and aba.questPtrs==clean.questPtrs
    and readOwned(aba,"quest","name",77301,nil)=="Witness Quest")

local insert=compileOwned(owned,function()
    db.npcData[77102]={[db.npcKeys.name]="Added LIVE after capture"}
end,"npc")
check("07 newly added source row is absent from the owned generation",
    readOwned(insert,"npc","name",77102,nil)==nil and
    db.npcData[77102]~=nil and insert.npcBin==clean.npcBin)

local both=compileOwned(owned,function()
    factionViews.A[77301][db.questKeys.name]="Modified A after copy"
    factionViews.H[77301][db.questKeys.name]="Modified H after copy"
end,"quest")
check("08 both captured faction views stay isolated from late live edits",
    readOwned(both,"quest","name",77301,owned.views.A)=="Invented A effective"
    and readOwned(both,"quest","name",77301,owned.views.H)=="Invented H effective"
    and readOwned(both,"quest","name",77301,factionViews.A)=="Modified A after copy"
    and readOwned(both,"quest","name",77301,factionViews.H)=="Modified H after copy"
    and both.questBin==clean.questBin)

factionViews.H[77501][db.questKeys.name]="Changed LIVE override-only"
check("09 captured override-only record remains separate from live view",
    readOwned(both,"quest","name",77501,owned.views.H)
        =="Invented H override-only"
    and readOwned(both,"quest","name",77501,factionViews.H)
        =="Changed LIVE override-only"
    and db.questData[77501]==nil)

-- CRITICAL NEGATIVE: a multi-table source copy can be incoherent without an
-- exclusive writer contract even if its copies are thereafter privately held.
initInventedSources()
local mixed=ownInputs(function()
    db.npcData[77101][db.npcKeys.name]="LIVE NEW"
    db.questData[77301][db.questKeys.name]="LIVE NEW"
end)
local mixedOutput=compileOwned(mixed)
check("10 CAPTURE GAP: writer between kind copies produces inconsistent epoch",
    readOwned(mixedOutput,"npc","name",77101,nil)=="Witness A"
    and readOwned(mixedOutput,"quest","name",77301,nil)=="LIVE NEW"
    and db.npcData[77101][db.npcKeys.name]=="LIVE NEW"
    and db.questData[77301][db.questKeys.name]=="LIVE NEW")
check("11 no publication of partial SavedVariables or revision by prototype",
    saved.npcBin==nil and saved.objBin==nil
    and saved.questBin==nil and saved.itemBin==nil
    and saved.nQuestieDataRevision==57 and saved.dbCompiledCount==9)

assert(count==11,"expected eleven bounded snapshot feasibility checks, got "..count)
print("GATE08 OWNED SNAPSHOT: 11/11 BOUNDED FIXTURE CHECKS (NOT IMPLEMENTED)")
print("BLOCKED SOURCE CAPTURE: atomicity, coverage, unknown writers, faction APIs, RAM/GC, publish, relog and client QA")
