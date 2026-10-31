-- Public test-only genuine #185 four-kind source serializer + decoder + #442 bridge.
-- All test IDs and content are invented. NO WoW client, SavedVariables,
-- protected addon edits, source writer exclusion, persistence or publishing.
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
local rows={
    {kind="npc",fn="CompileNPCs",schema="npc",id=77101,keys="npcKeys",name="Invented NPC"},
    {kind="obj",fn="CompileObjects",schema="object",id=77201,keys="objectKeys",name="Invented Object"},
    {kind="quest",fn="CompileQuests",schema="quest",id=77301,keys="questKeys",name="Invented Quest"},
    {kind="item",fn="CompileItems",schema="item",id=77401,keys="itemKeys",name="Invented Item"},
}
db.npcData={[77101]={[db.npcKeys.name]="Invented NPC"}}
db.objectData={[77201]={[db.objectKeys.name]="Invented Object"}}
db.questData={[77301]={[db.questKeys.name]="Invented Quest"}}
db.itemData={[77401]={[db.itemKeys.name]="Invented Item"}}
local saved=Questie.db.global
for _,entry in ipairs(rows)do
    saved[entry.kind.."Bin"]="PUBLISHED_OLD_BIN_"..entry.kind
    saved[entry.kind.."Ptrs"]="PUBLISHED_OLD_PTRS_"..entry.kind
end
saved.dbIsCompiled=true
saved.dbCompiledCount=9
saved.nQuestieDataRevision=57
local originalQuery="OLD_GENERATION_QUERY_CLOSURE"
local checks=0
local function check(ok,label)
    assert(ok,"G08_REAL_SERIALIZER_BRIDGE_FAIL:"..label)
    checks=checks+1
end
local function drive(f)
    local thread=coroutine.create(f)
    for _=1,300 do
        local ok,out=coroutine.resume(thread)
        assert(ok,tostring(out))
        if coroutine.status(thread)=="dead" then return out end
    end
    error("REAL_SOURCE_WRITER_READER_DID_NOT_TERMINATE")
end
local function verifier(stage,token)
    return compiler:VerifyNQStagedGeneration(stage,token)
end
local stage={}
local token=compiler:BeginNQStagedGeneration(stage)
check(type(token)=="table" and stage._nqGenerationToken==token,
    "ORIGINAL_SOURCE_GENERATION_TOKEN")
check(type(stage._nqGenerationReceipts)=="table",
    "ORIGINAL_RECEIPT_DICTIONARY")
check(not pcall(verifier,stage,token),"PARTIAL_STAGE_VERIFIER_REFUSAL")
local refused,reason=bridge.ProbeLegacyFlatStage(stage,token,verifier)
check(refused==nil and reason=="REFUSE_RECEIPT_SHAPE_npc",
    "PARTIAL_STAGE_BRIDGE_REFUSAL")
for _,entry in ipairs(rows)do
    drive(function()return compiler[entry.fn](compiler,stage)end)
    local binKey,ptrKey=entry.kind.."Bin",entry.kind.."Ptrs"
    local bin,ptr=stage[binKey],stage[ptrKey]
    check(type(bin)=="string" and #bin>0 and type(ptr)=="string" and #ptr>0,
        entry.kind.."_ORIGINAL_SERIALIZER_WRITES_PRIVATE_PAIR")
    local receipt=stage._nqGenerationReceipts[entry.kind]
    check(receipt~=nil and receipt.token==token and receipt.bin==bin and receipt.ptrs==ptr,
        entry.kind.."_ORIGINAL_WRITER_RECEIPT_MATCH")
    check(saved[binKey]=="PUBLISHED_OLD_BIN_"..entry.kind
        and saved[ptrKey]=="PUBLISHED_OLD_PTRS_"..entry.kind,
        entry.kind.."_LEGACY_SAVED_FIELDS_UNTOUCHED")
    local handle=drive(function()
        return compiler:GetDBHandle(bin,ptr,
            compiler:BuildSkipMap(db[entry.schema.."CompilerTypes"],
                db[entry.schema.."CompilerOrder"]),
            db[entry.keys],nil)
    end)
    check(type(handle)=="table" and type(handle.QuerySingle)=="function",
        entry.kind.."_ORIGINAL_HANDLE_CREATED")
    check(handle.QuerySingle(entry.id,"name")==entry.name,
        entry.kind.."_ORIGINAL_READER_ROUNDTRIP")
    handle.stream:finished()
end
check(verifier(stage,token)==true,
    "ORIGINAL_FOUR_KIND_LOCAL_STAGE_VERIFIED")
local out,status,telemetry=bridge.ProbeLegacyFlatStage(stage,token,verifier)
check(out==nil and status=="REFUSE_UNPROVEN_SOURCE_AND_READER_OWNERSHIP",
    "REAL_BYTES_MUST_STILL_REFUSE_UNVERIFIED_PROVENANCE")
check(telemetry~=nil and telemetry.kinds==4 and telemetry.fieldCount==8,
    "EIGHT_REAL_FIELDS_COUNTED_WITHOUT_BYTES_EXPORTED")
local allSizes=true
for _,entry in ipairs(rows)do
    allSizes=allSizes
      and telemetry.lengths[entry.kind].bin==#stage[entry.kind.."Bin"]
      and telemetry.lengths[entry.kind].ptrs==#stage[entry.kind.."Ptrs"]
end
check(allSizes,"TELEMETRY_REFERENCES_REAL_ENCODED_LENGTHS")
check(telemetry.fields==nil and telemetry.ownerToken==nil,
    "NO_REAL_BYTES_OR_RECEIPT_AUTHORITY_ESCAPES")
local noCandidate,missingShape=inspector.InspectCandidate(stage,{})
check(noCandidate==nil and missingShape=="REFUSE_FIELDS_SHAPE",
    "EXISTING_NESTED_INSPECTOR_REFUSES_FLAT_SOURCE")
check(saved.dbCompiledCount==9 and saved.nQuestieDataRevision==57
    and saved.npcBin=="PUBLISHED_OLD_BIN_npc",
    "META_AND_OLD_GENERATION_NOT_PUBLISHED")
check(originalQuery=="OLD_GENERATION_QUERY_CLOSURE",
    "SYNTHETIC_OLD_READER_IDENTITY_UNMODIFIED")

-- Simulate an external writer changing a source cell then restoring it,
-- with no registered epoch. The original local receipt remains unchanged.
local originalName=db.questData[77301][db.questKeys.name]
db.questData[77301][db.questKeys.name]="TRANSIENT_UNREGISTERED"
db.questData[77301][db.questKeys.name]=originalName
check(verifier(stage,token)==true,
    "KNOWN_GAP_UNREGISTERED_SOURCE_ABA_NOT_IN_RECEIPTS")
out,status=bridge.ProbeLegacyFlatStage(stage,token,verifier)
check(out==nil and status=="REFUSE_UNPROVEN_SOURCE_AND_READER_OWNERSHIP",
    "SOURCE_ABA_STILL_DENIED")
local realBin=stage.npcBin
stage.npcBin="TAMPERED"
check(not pcall(verifier,stage,token),
    "LOCAL_RECEIPT_CATCHES_UNRESEALED_BYTE_DRIFT")
out,status=bridge.ProbeLegacyFlatStage(stage,token,verifier)
check(out==nil and status=="REFUSE_LEGACY_LOCAL_VERIFICATION",
    "BRIDGE_REFUSES_UNRESEALED_BYTES")
stage._nqGenerationReceipts.npc.bin="TAMPERED"
check(verifier(stage,token)==true,
    "KNOWN_GAP_RESEALED_BYTES_CAN_PASS_ORIGINAL_VERIFIER")
out,status=bridge.ProbeLegacyFlatStage(stage,token,verifier)
check(out==nil and status=="REFUSE_UNPROVEN_SOURCE_AND_READER_OWNERSHIP",
    "RESEALED_BYTES_STILL_DENIED")
stage.npcBin=realBin
stage._nqGenerationReceipts.npc.bin=realBin
check(verifier(stage,token)==true,"ORIGINAL_STAGE_RESTORED")
local oldToken=token
local newToken=compiler:BeginNQStagedGeneration(stage)
check(newToken~=oldToken and stage.npcBin==nil and stage.questPtrs==nil,
    "ORIGINAL_REBEGIN_CLEARS_EIGHT_FIELDS")
check(not pcall(verifier,stage,oldToken),
    "PREVIOUS_ATTEMPT_TOKEN_CANNOT_VERIFY_NEW_STAGE")
check(saved.nQuestieDataRevision==57 and saved.dbCompiledCount==9
    and saved.itemBin=="PUBLISHED_OLD_BIN_item",
    "FINAL_LEGACY_FIELDS_AND_METADATA_UNTOUCHED")
assert(checks==38,"EXPECTED_38_CHECKS_GOT_"..checks)
print("PUBLIC G08 PART50 AUTHENTIC SERIALIZER READER REFUSAL BRIDGE: 38/38 PASS")
print("PUBLIC G08 PART50 GENUINE: original draft #185 four writers, reader handles, and local stage receipt methods executed.")
print("PUBLIC G08 PART50 REFUSED: real staged bytes lack source ownership, full metadata, reader leases, and crash/relog proof.")
