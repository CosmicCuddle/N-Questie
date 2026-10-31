-- Genuine #185 methods, TEST-ONLY fake per-kind writer output, no game client.
local probe=assert(loadfile("tests/compat/nq_part50_g08_legacy_stage_failclosed_probe.lua"))()
local inspector=assert(loadfile("tests/compat/nq_part50_g08_readonly_candidate_inspector.lua"))()
local root=assert(os.getenv("NQ_PART50_FLAT_STAGE_SOURCE"),"PINNED_DRAFT_REQUIRED")
local f=assert(io.open(root.."/Database/compiler.lua","rb"))
local source=assert(f:read("*a")); f:close()
local function cut(startLabel,endLabel)
    local i=assert(source:find(startLabel,1,true),"METHOD_MISSING:"..startLabel)
    local j=assert(source:find(endLabel,i+#startLabel,true),"METHOD_END_MISSING")
    return source:sub(i,j-1)
end
local beginCode=cut("function QuestieDBCompiler:BeginNQStagedGeneration(stage)",
    "\nfunction QuestieDBCompiler:VerifyNQStagedGeneration(stage, expectedToken)")
local verifyCode=cut("function QuestieDBCompiler:VerifyNQStagedGeneration(stage, expectedToken)",
    "\nfunction QuestieDBCompiler:CompileTableCoroutine(")
local compiler={}
local env=setmetatable({QuestieDBCompiler=compiler},{__index=_G})
local src='local NQ_STAGE_KINDS={"npc","obj","quest","item"}\n'..
    beginCode.."\n"..verifyCode
local fn
if _VERSION=="Lua 5.1" then
    fn=assert(loadstring(src,"=genuine_185_stage_methods"));setfenv(fn,env)
else
    fn=assert(load(src,"=genuine_185_stage_methods","t",env))
end
fn()
local count=0
local function check(ok,label)
    assert(ok,"G08_FLAT_BRIDGE:"..label)
    count=count+1
end
local function verifier(stage,token)
    return compiler:VerifyNQStagedGeneration(stage,token)
end
local oldPublic={npcBin="OLDER",objPtrs="OLDER",nQuestieDataRevision=77,
    QueryNPC="ORIGINAL_READER"}
local stage={npcBin="SHOULD_BE_RESET",questPtrs="OLD_PTRS",_nqGenerationToken={}}
local token=compiler:BeginNQStagedGeneration(stage)
check(type(compiler.BeginNQStagedGeneration)=="function" and
    type(compiler.VerifyNQStagedGeneration)=="function",
    "UNCHANGED_185_METHOD_BODIES_COMPILED")
check(type(token)=="table" and stage._nqGenerationToken==token,
    "GENUINE_BEGIN_CREATES_NEW_TOKEN")
check(stage.npcBin==nil and stage.questPtrs==nil,
    "GENUINE_BEGIN_CLEARS_STALE_FLAT_FIELDS")
check(type(stage._nqGenerationReceipts)=="table",
    "GENUINE_BEGIN_CLEARS_RECEIPTS")
local okPre=pcall(verifier,stage,token)
check(not okPre,"ORIGINAL_VERIFY_REFUSES_EMPTY_STAGE")
local nilOut,reason=probe.ProbeLegacyFlatStage(stage,token,verifier)
check(nilOut==nil and reason=="REFUSE_RECEIPT_SHAPE_npc",
    "PROBE_REJECTS_MISSING_RECEIPTS")
for _,kind in ipairs({"npc","obj","quest","item"}) do
    local b="INVENTED_BIN_"..kind
    local p="INVENTED_PTR_"..kind
    stage[kind.."Bin"]=b
    stage[kind.."Ptrs"]=p
    stage._nqGenerationReceipts[kind]={token=token,bin=b,ptrs=p}
end
check(verifier(stage,token)==true,"ORIGINAL_VERIFY_ACCEPTS_FOUR_FAKE_RECEIPTS")
local accepted,why,telemetry=probe.ProbeLegacyFlatStage(stage,token,verifier)
check(accepted==nil and why=="REFUSE_UNPROVEN_SOURCE_AND_READER_OWNERSHIP",
    "FOUR_CORRECT_RECEIPTS_STILL_NO_ADMISSION")
check(telemetry~=nil and telemetry.kinds==4 and telemetry.fieldCount==8,
    "DIAGNOSTIC_COUNTS_FOUR_KINDS_EIGHT_FIELDS")
check(telemetry.lengths.npc.bin==#stage.npcBin and
    telemetry.lengths.item.ptrs==#stage.itemPtrs,
    "LENGTHS_ARE_SOURCE_FIELDS")
check(telemetry.ownerToken==nil and telemetry.fields==nil,
    "NO_ACTUAL_BYTES_OR_TOKEN_ESCAPE")
check(oldPublic.npcBin=="OLDER" and oldPublic.objPtrs=="OLDER" and
    oldPublic.QueryNPC=="ORIGINAL_READER" and
    oldPublic.nQuestieDataRevision==77,
    "NO_LEGACY_GLOBAL_OR_READER_CHANGE")
local inspected,status=inspector.InspectCandidate(stage,{})
check(inspected==nil and status=="REFUSE_FIELDS_SHAPE",
    "REAL_FLAT_STAGE_CANNOT_SNEAK_INTO_NESTED_INSPECTOR")

local function cloneFixture()
    local s={}
    local t=compiler:BeginNQStagedGeneration(s)
    for _,kind in ipairs({"npc","obj","quest","item"}) do
        local b,p="B_"..kind,"P_"..kind
        s[kind.."Bin"]=b;s[kind.."Ptrs"]=p
        s._nqGenerationReceipts[kind]={token=t,bin=b,ptrs=p}
    end
    return s,t
end
local function rejectFixture(name,mutate,expected)
    local s,t=cloneFixture()
    mutate(s,t)
    local out,why=probe.ProbeLegacyFlatStage(s,t,verifier)
    check(out==nil and why==expected,name)
end
rejectFixture("STALE_BIN",function(s)s.npcBin="WRONG" end,
    "REFUSE_LEGACY_LOCAL_VERIFICATION")
rejectFixture("MISSING_POINTER",function(s)s.objPtrs=nil end,
    "REFUSE_LEGACY_LOCAL_VERIFICATION")
rejectFixture("EMPTY_BINARY",function(s)s.questBin="" end,
    "REFUSE_LEGACY_LOCAL_VERIFICATION")
rejectFixture("WRONG_RECEIPT_TOKEN",function(s)
    s._nqGenerationReceipts.item.token={}
end,"REFUSE_LEGACY_LOCAL_VERIFICATION")
rejectFixture("NO_RECEIPTS",function(s)s._nqGenerationReceipts=nil end,
    "REFUSE_RECEIPTS_SHAPE")
rejectFixture("RECEIPTS_METATABLE",function(s)
    setmetatable(s._nqGenerationReceipts,{})
end,"REFUSE_RECEIPTS_SHAPE")
rejectFixture("NESTED_RECEIPT_METATABLE",function(s)
    setmetatable(s._nqGenerationReceipts.npc,{})
end,"REFUSE_RECEIPT_SHAPE_npc")
rejectFixture("TOKEN_REPLACED",function(s)s._nqGenerationToken={} end,
    "REFUSE_TOKEN_MISMATCH")
local s,t=cloneFixture()
local out,why=probe.ProbeLegacyFlatStage(s,{},verifier)
check(out==nil and why=="REFUSE_TOKEN_MISMATCH",
    "EXTERNAL_INVENTED_TOKEN_REJECTED")
local o,w=probe.ProbeLegacyFlatStage({},nil,verifier)
check(o==nil and w=="REFUSE_TOKEN_SHAPE","NIL_TOKEN_REJECTED")
o,w=probe.ProbeLegacyFlatStage("not a stage",{},verifier)
check(o==nil and w=="REFUSE_STAGE_SHAPE","SCALAR_STAGE_REJECTED")
o,w=probe.ProbeLegacyFlatStage(setmetatable({},{}),{},verifier)
check(o==nil and w=="REFUSE_STAGE_SHAPE","METATABLE_STAGE_REJECTED")
local s2,t2=cloneFixture()
o,w=probe.ProbeLegacyFlatStage(s2,t2,nil)
check(o==nil and w=="REFUSE_VERIFIER_MISSING","MISSING_VERIFIER_REJECTED")
-- Even a detached foreign verifier that returns true cannot manufacture
-- proven source ownership: all shape checks still end in explicit refusal.
o,w=probe.ProbeLegacyFlatStage(s2,t2,function()return true end)
check(o==nil and w=="REFUSE_UNPROVEN_SOURCE_AND_READER_OWNERSHIP",
    "FORGED_SUCCESS_VERIFIER_CANNOT_AUTHORIZE")
-- An A->B->A write leaves original #185 receipt comparison untouched.
local orig=s2.questBin
s2.questBin="TRANSIENT";s2.questBin=orig
check(verifier(s2,t2)==true,
    "KNOWN_UNSAFE_TRANSIENT_ABA_UNDETECTABLE_BY_ORIGINAL_RECEIPT")
o,w=probe.ProbeLegacyFlatStage(s2,t2,verifier)
check(o==nil and w=="REFUSE_UNPROVEN_SOURCE_AND_READER_OWNERSHIP",
    "PROBE_REFUSES_KNOWN_UNSAFE_ABA")
-- With fully re-sealed inputs the original #185 verifier also accepts.
s2.npcBin="FORGED";s2._nqGenerationReceipts.npc.bin="FORGED"
check(verifier(s2,t2)==true,
    "KNOWN_UNSAFE_RESEALED_BYTES_ACCEPTED_BY_ORIGINAL_RECEIPT")
o,w=probe.ProbeLegacyFlatStage(s2,t2,verifier)
check(o==nil and w=="REFUSE_UNPROVEN_SOURCE_AND_READER_OWNERSHIP",
    "PROBE_REFUSES_RESEALED_LOCAL_CHECK")
local stage3,token3=cloneFixture()
local newToken=compiler:BeginNQStagedGeneration(stage3)
check(newToken~=token3 and stage3.npcBin==nil and
    next(stage3._nqGenerationReceipts)==nil,
    "REBEGIN_DESTROYS_OLD_GENERATION_SHAPE")
check(not pcall(verifier,stage3,token3),
    "ORIGINAL_VERIFY_REFUSES_OLD_TOKEN")
check(oldPublic.QueryNPC=="ORIGINAL_READER" and
    oldPublic.nQuestieDataRevision==77,
    "PUBLIC_CONSUMER_AND_CUSTOM_REVISION_STILL_UNTOUCHED")
assert(count==34,"EXPECTED_34_CONTROLS_GOT_"..count)
print("PUBLIC G08 PART50 AUTHENTIC FLAT STAGE FAIL-CLOSED BRIDGE: 34/34 PASS")
print("PUBLIC G08 PART50 BRIDGE ALWAYS REFUSES: original #185 receipts contain no certified source epoch, metadata or reader lifetime.")
print("PUBLIC G08 PART50 NOT NATIVE: original two #185 methods only, fake bytes, no live staged serializer, client, SavedVariables or deployment.")
