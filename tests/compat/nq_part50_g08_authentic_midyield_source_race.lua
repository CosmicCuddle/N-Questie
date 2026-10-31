-- TEST ONLY authentic source-mutation race witness on frozen #185 writer.
-- All source rows/IDs are invented; no private or playable client data.
-- This proves a specific TOCTOU mismatch, not native scheduling or QA.
local root=assert(os.getenv("NQ_PART50_STAGE185_ROOT"),"AUTHENTIC_STAGE_ROOT_REQUIRED")
unpack=unpack or table.unpack
tremove=table.remove
local function band(a,b)
    local result, place=0,1
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
    CreateModule=function(_,name)modules[name]=modules[name] or {};return modules[name]end,
    ImportModule=function(_,name)assert(modules[name],"NO_MODULE_"..name);return modules[name]end,
}
for _,name in ipairs({"QuestieDB","QuestieLib","l10n"})do QuestieLoader:CreateModule(name)end
QuestieCompat={Is335=true,WOW_PROJECT_ID=2}
Questie={
    IsSoD=false,IsTBC=false,IsWotlk=true,
    db={profile={debugEnabled=false},global={}},
    Error=function(_,message)error("TEST_QUESTIE_ERROR:"..tostring(message),0)end,
    Debug=function()end,
}
local function source(path)
    return assert(loadfile(root.."/"..path), "PINNED_STAGE_SOURCE_REQUIRED:"..path)()
end
source("Modules/QuestieStream.lua")
for _,part in ipairs({"npcDB","objectDB","questDB","itemDB"})do source("Database/"..part..".lua")end
source("Database/compiler.lua")
local db=QuestieLoader:ImportModule("QuestieDB")
local compiler=QuestieLoader:ImportModule("DBCompiler")
local bridge=assert(loadfile("tests/compat/nq_part50_g08_legacy_stage_failclosed_probe.lua"))()
local inspector=assert(loadfile("tests/compat/nq_part50_g08_readonly_candidate_inspector.lua"))()

local checks=0
local function check(condition,label)
    assert(condition,"PART50_SOURCE_RACE:"..label)
    checks=checks+1
end
local sourceStart=88001
local sourceEnd=88060
db.questData={}
for id=sourceStart,sourceEnd do
    db.questData[id]={[db.questKeys.name]="ORIGINAL_"..id}
end
local lateId=88045
local addedId=88100
local lateOriginal=db.questData[lateId][db.questKeys.name]
local saved=Questie.db.global
for _,kind in ipairs({"npc","obj","quest","item"}) do
    saved[kind.."Bin"]="OLD_BIN_"..kind
    saved[kind.."Ptrs"]="OLD_PTRS_"..kind
end
saved.nQuestieDataRevision=68
saved.dbCompiledCount=12
saved.dbIsCompiled=true
local stage={}
local token=compiler:BeginNQStagedGeneration(stage)
check(type(token)=="table" and stage._nqGenerationToken==token,
    "AUTHENTIC_STAGE_BEGIN")
check(type(stage._nqGenerationReceipts)=="table" and stage.questBin==nil,
    "STAGE_EMPTY_BEFORE_WRITER")
local function verify()
    return compiler:VerifyNQStagedGeneration(stage,token)
end
local writer=coroutine.create(function()return compiler:CompileQuests(stage)end)
local function resumeWriter(expected)
    local ok,err=coroutine.resume(writer)
    assert(ok,"ORIGINAL_WRITER:"..tostring(err))
    check(coroutine.status(writer)==expected,"WRITER_STATUS_"..expected)
end
-- The original method enumerates its numeric indexLookup BEFORE its first
-- coroutine.yield, so a later quest insert is NOT in that indexLookup.
resumeWriter("suspended")
check(stage.questBin==nil and stage.questPtrs==nil,
    "BEFORE_FIRST_TICK_NOT_PUBLISHED")
db.questData[addedId]={[db.questKeys.name]="INSERTED_AFTER_INDEX_CAPTURE"}
check(db.questData[addedId]~=nil and stage.questBin==nil,
    "UNREGISTERED_INSERT_DURING_FIRST_YIELD")
-- Actual #185 quest compiler uses 28 entriesPerTick, with a 0..28 loop,
-- so the first resumed batch encodes entries 1..29 and suspends again.
resumeWriter("suspended")
check(stage.questBin==nil,"FIRST_BATCH_STILL_PRIVATE")
-- Edit entry 45 before it is encoded during the next batch.
db.questData[lateId][db.questKeys.name]="TRANSIENT_MID_YIELD"
check(db.questData[lateId][db.questKeys.name]~=lateOriginal,
    "SOURCE_MUTATION_WHILE_SUSPENDED")
resumeWriter("suspended")
-- The first batch encoded ORIGINAL_88001; the second encoded mutated 88045.
-- Undo the mutation before final Save, imitating an unregistered A->B->A.
db.questData[lateId][db.questKeys.name]=lateOriginal
check(db.questData[lateId][db.questKeys.name]==lateOriginal,
    "MUTATOR_RESTORES_FINAL_SOURCE_ROW")
resumeWriter("dead")
check(type(stage.questBin)=="string" and #stage.questBin>0
    and type(stage.questPtrs)=="string" and #stage.questPtrs>0,
    "AUTHENTIC_SERIALIZER_FINISHES_TWO_FIELDS")
local receipt=stage._nqGenerationReceipts.quest
check(type(receipt)=="table" and receipt.token==token
    and receipt.bin==stage.questBin and receipt.ptrs==stage.questPtrs,
    "GENUINE_RECEIPT_MATCHES_WRITER_OUTPUT")
-- Other three genres are absent on purpose: only the quest result exists.
check(not pcall(verify),"FOUR_KIND_VERIFIER_STILL_REFUSES_PARTIAL_STAGE")
local readCo=coroutine.create(function()
    return compiler:GetDBHandle(stage.questBin,stage.questPtrs,
        compiler:BuildSkipMap(db.questCompilerTypes,db.questCompilerOrder),
        db.questKeys,nil)
end)
local handle
for _=1,100 do
    local ok,value=coroutine.resume(readCo)
    assert(ok,tostring(value))
    if coroutine.status(readCo)=="dead" then handle=value;break end
end
check(type(handle)=="table" and type(handle.QuerySingle)=="function",
    "AUTHENTIC_QUERY_HANDLE_AVAILABLE")
check(handle.QuerySingle(sourceStart,"name")=="ORIGINAL_"..sourceStart,
    "EARLY_ENCODED_ROW_ORIGINAL")
check(handle.QuerySingle(lateId,"name")=="TRANSIENT_MID_YIELD",
    "LATER_ENCODED_ROW_TRANSIENT")
check(db.questData[lateId][db.questKeys.name]==lateOriginal,
    "FINAL_SOURCE_DIFFERS_FROM_COMPILED_LATE_ROW")
check(handle.QuerySingle(addedId,"name")==nil,
    "INSERT_AFTER_INDEX_LOOKUP_OMITTED_FROM_ENCODED_POINTERS")
check(db.questData[addedId][db.questKeys.name]=="INSERTED_AFTER_INDEX_CAPTURE",
    "OMITTED_ROW_STILL_EXISTS_IN_FINAL_SOURCE")
check(handle.QuerySingle(sourceEnd,"name")=="ORIGINAL_"..sourceEnd,
    "LATER_UNCHANGED_ROW_STILL_READS")
handle.stream:finished()
check(saved.questBin=="OLD_BIN_quest" and saved.questPtrs=="OLD_PTRS_quest",
    "EXISTING_PUBLIC_QUEST_PAIR_UNCHANGED")
check(saved.nQuestieDataRevision==68 and saved.dbCompiledCount==12,
    "EXISTING_PUBLIC_METADATA_UNCHANGED")
check(stage._nqGenerationReceipts.quest.sourceEpoch==nil
    and stage._nqGenerationReceipts.quest.generation==nil,
    "ORIGINAL_RECEIPT_NO_SOURCE_EPOCH_OR_GENERATION")
local ret,reason=bridge.ProbeLegacyFlatStage(stage,token,function(a,t)
    return compiler:VerifyNQStagedGeneration(a,t)
end)
check(ret==nil and reason=="REFUSE_RECEIPT_SHAPE_npc",
    "BRIDGE_REFUSES_PARTIAL_FOUR_KIND_STAGE")
local fake,why=inspector.InspectCandidate(stage,{})
check(fake==nil and why=="REFUSE_FIELDS_SHAPE",
    "NESTED_CANDIDATE_INSPECTOR_REFUSES_FLAT_STAGE")
-- Counterfactual: supply well-matched fictional receipts for the other
-- three untouched kinds. This makes original four-kind receipt verification
-- return true WITHOUT repairing torn quest contents or skipped new row.
for _,kind in ipairs({"npc","obj","item"}) do
    stage[kind.."Bin"]="FICTITIOUS_BIN_"..kind
    stage[kind.."Ptrs"]="FICTITIOUS_PTR_"..kind
    stage._nqGenerationReceipts[kind]={
        token=token,bin=stage[kind.."Bin"],ptrs=stage[kind.."Ptrs"]
    }
end
check(verify()==true,
    "FOUR_KIND_LOCAL_RECEIPTS_ACCEPT_TORN_QUEST_SOURCE")
ret,reason=bridge.ProbeLegacyFlatStage(stage,token,function(a,t)
    return compiler:VerifyNQStagedGeneration(a,t)
end)
check(ret==nil and reason=="REFUSE_UNPROVEN_SOURCE_AND_READER_OWNERSHIP",
    "STRICT_BRIDGE_STILL_DENIES_TORN_SOURCE")
check(saved.questBin=="OLD_BIN_quest" and saved.dbCompiledCount==12,
    "STRICT_BRIDGE_NEVER_PUBLISHES_TORN_RESULT")
check(checks==29,"CHECK_COUNT_"..checks)
print("PUBLIC G08 PART50 AUTHENTIC MID-YIELD SOURCE RACE: "..checks.."/"..checks.." PASS")
print("PUBLIC G08 PART50 VERIFIED RACE: original writer captured 60 IDs before yield, skipped late inserted row, encoded an A-B-A-mutated quest.")
print("PUBLIC G08 PART50 FAIL CLOSED: original local receipts can pass torn source, but new bridge refuses; no original addon change or native game proof.")
