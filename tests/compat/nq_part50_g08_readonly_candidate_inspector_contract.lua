-- Part50 Gate08: execute TEST-ONLY read-only candidate inspector under PUC Lua.
-- Invented byte strings and epochs. Historical source is pinned in CI.
-- Does not execute the original serializer or release any streams.
local selector = assert(loadfile("tests/compat/nq_part50_g08_readonly_candidate_inspector.lua"))()

local original = assert(os.getenv("NQ_PART50_ORIGINAL_ROOT"), "ORIGINAL_PIN_REQUIRED")
local function read(path)
    local f = assert(io.open(original .. "/" .. path, "rb"), "SOURCE_MISSING:" .. path)
    local src = assert(f:read("*a")); f:close(); return src
end
local compiler = read("Database/compiler.lua")
local db = read("Database/QuestieDB.lua")
local init = read("Modules/QuestieInit.lua")
local n = 0
local function check(ok, name)
    assert(ok, "PART50_G08_SELECTOR:" .. name)
    n = n + 1
end
-- These are source ABI anchors, NOT assertions of real codec compatibility.
check(compiler:find('Questie.db.global[databaseKey.."Bin"] = stream:Save()',1,true)~=nil,
    "SOURCE_NORMAL_DIRECT_BIN_PUBLISH")
check(compiler:find('Questie.db.global.sod[databaseKey.."Ptrs"]',1,true)~=nil,
    "SOURCE_SOD_DIRECT_PTRS_PUBLISH")
check(db:find("npcBin = Questie.db.global.npcBin",1,true)~=nil and
    db:find("itemPtrs = Questie.db.global.itemPtrs",1,true)~=nil,
    "SOURCE_READER_LEGACY_EIGHT_GLOBAL_FIELDS")
check(init:find("Questie.db.global.nQuestieDataRevision = nQuestieRevision",1,true)~=nil,
    "SOURCE_STAGE1_CUSTOM_REVISION_WRITER")

local kinds={"npc","obj","quest","item"}
local function fresh(scope)
    local token={}
    local stage={
        scope=scope or "normal", generation=7, sourceEpoch=31,
        ownerToken=token, fields={}, receipts={},
        metadata={
            dbCompiledOnVersion="invented-1.2",dbCompiledLang="enUS",
            dbCompiledExpansion=2,dbCompiledCount=9,
            dbIsCompiled=true,nQuestieDataRevision=0
        }
    }
    for _,kind in ipairs(kinds) do
        local bin="BIN:"..kind..":invented",ptrs="PTR:"..kind..":invented"
        stage.fields[kind.."Bin"]=bin
        stage.fields[kind.."Ptrs"]=ptrs
        stage.receipts[kind]={
            bin=bin,ptrs=ptrs,token=token,generation=7,sourceEpoch=31
        }
    end
    local expected={
        scope=stage.scope, generation=7,sourceEpoch=31,
        ownerToken=token,dbCompiledOnVersion="invented-1.2",
        dbCompiledLang="enUS",dbCompiledExpansion=2,
        dbCompiledCount=9,nQuestieDataRevision=0
    }
    return stage,expected
end

local stage,expected=fresh()
local detached,status=selector.InspectCandidate(stage,expected)
check(detached~=nil and status=="STRUCTURAL_PASS","VALID_NORMAL")
check(detached.fields~=stage.fields,"DETACHED_EIGHT_FIELD_MAP")
check(detached.metadata~=stage.metadata,"DETACHED_METADATA_MAP")
local complete=true
for _,kind in ipairs(kinds) do
    complete=complete and detached.fields[kind.."Bin"]==stage.fields[kind.."Bin"]
        and detached.fields[kind.."Ptrs"]==stage.fields[kind.."Ptrs"]
end
check(complete,"ALL_EIGHT_FIELD_VALUES_COPIED")
check(detached.metadata.nQuestieDataRevision==0 and
    detached.metadata.dbCompiledLang=="enUS" and
    detached.metadata.dbCompiledExpansion==2,"REQUIRED_METADATA_COPIED")
check(detached.ownerToken==nil and detached.receipts==nil,
    "NO_AUTHORITY_OR_RECEIPT_ALIAS_ESCAPES")
local oldPublic={npcBin="OLD:NPC",nQuestieDataRevision=27,QueryQuest="OLD:CLOSURE"}
check(oldPublic.npcBin=="OLD:NPC" and oldPublic.QueryQuest=="OLD:CLOSURE"
    and oldPublic.nQuestieDataRevision==27,"UNTOUCHED_PUBLIC_LEGACY_FIXTURE")
stage.fields.npcBin="CORRUPTED_AFTER_CHECK"
check(detached.fields.npcBin=="BIN:npc:invented","DETACHED_AFTER_SOURCE_EDIT")
local declined,reason=selector.InspectCandidate(stage,expected)
check(declined==nil and reason=="REFUSE_RECEIPT_BYTES_npc",
    "CORRUPTED_AFTER_CHECK_REQUIRES_REINSPECTION")

local sod,sodExpected=fresh("sod")
local sodDetached,sodStatus=selector.InspectCandidate(sod,sodExpected)
check(sodStatus=="STRUCTURAL_PASS" and sodDetached.scope=="sod",
    "SOD_ALTERNATE_SLOT_SHAPE")
check(sodDetached.fields.objPtrs==sod.fields.objPtrs,
    "SOD_SELECTED_PAIR_VALUE")

-- Every case must explicitly refuse instead of throwing, yielding or writing.
-- Mutations return BOTH arguments so nil is not hidden by fallback logic.
local negative={
    {"NIL_STAGE","REFUSE_STAGE_SHAPE",function(s,e)return nil,e end},
    {"STAGE_SCALAR","REFUSE_STAGE_SHAPE",function(s,e)return 3,e end},
    {"STAGE_METATABLE","REFUSE_STAGE_SHAPE",function(s,e)return setmetatable(s,{__index=function()error("BAD READ")end}),e end},
    {"NIL_EXPECTATION","REFUSE_EXPECTATION_SHAPE",function(s,e)return s,nil end},
    {"EXPECTATION_METATABLE","REFUSE_EXPECTATION_SHAPE",function(s,e)return s,setmetatable(e,{}) end},
    {"FIELDS_MISSING","REFUSE_FIELDS_SHAPE",function(s,e)s.fields=nil;return s,e end},
    {"FIELDS_METATABLE","REFUSE_FIELDS_SHAPE",function(s,e)setmetatable(s.fields,{});return s,e end},
    {"METADATA_SCALAR","REFUSE_METADATA_SHAPE",function(s,e)s.metadata=7;return s,e end},
    {"METADATA_METATABLE","REFUSE_METADATA_SHAPE",function(s,e)setmetatable(s.metadata,{});return s,e end},
    {"RECEIPTS_MISSING","REFUSE_RECEIPTS_SHAPE",function(s,e)s.receipts=nil;return s,e end},
    {"RECEIPTS_METATABLE","REFUSE_RECEIPTS_SHAPE",function(s,e)setmetatable(s.receipts,{});return s,e end},
    {"EXPECTED_SCOPE","REFUSE_EXPECTED_SCOPE",function(s,e)e.scope="retail";return s,e end},
    {"WRONG_SCOPE","REFUSE_SCOPE",function(s,e)s.scope="sod";return s,e end},
    {"EXPECTED_TOKEN","REFUSE_EXPECTED_TOKEN",function(s,e)e.ownerToken="forged";return s,e end},
    {"MISMATCHED_TOKEN","REFUSE_OWNER_TOKEN",function(s,e)s.ownerToken={};return s,e end},
    {"STALE_GENERATION","REFUSE_GENERATION",function(s,e)s.generation=6;return s,e end},
    {"FRACTIONAL_GENERATION","REFUSE_GENERATION",function(s,e)s.generation=7.5;return s,e end},
    {"ZERO_GENERATION","REFUSE_GENERATION",function(s,e)e.generation=0;return s,e end},
    {"STALE_EPOCH","REFUSE_SOURCE_EPOCH",function(s,e)s.sourceEpoch=30;return s,e end},
    {"NEGATIVE_EPOCH","REFUSE_SOURCE_EPOCH",function(s,e)s.sourceEpoch=-1;return s,e end},
    {"NOT_COMPILED","REFUSE_COMPILED_FLAG",function(s,e)s.metadata.dbIsCompiled=false;return s,e end},
    {"VERSION_CHANGED","REFUSE_VERSION",function(s,e)s.metadata.dbCompiledOnVersion="other";return s,e end},
    {"VERSION_EMPTY","REFUSE_VERSION",function(s,e)s.metadata.dbCompiledOnVersion="";return s,e end},
    {"WRONG_LOCALE","REFUSE_LOCALE",function(s,e)s.metadata.dbCompiledLang="deDE";return s,e end},
    {"WRONG_EXPANSION","REFUSE_EXPANSION",function(s,e)s.metadata.dbCompiledExpansion=3;return s,e end},
    {"FRACTIONAL_EXPANSION","REFUSE_EXPANSION",function(s,e)s.metadata.dbCompiledExpansion=2.5;return s,e end},
    {"COUNT_DRIFT","REFUSE_COUNT",function(s,e)s.metadata.dbCompiledCount=10;return s,e end},
    {"COUNT_ZERO","REFUSE_COUNT",function(s,e)s.metadata.dbCompiledCount=0;return s,e end},
    {"REVISION_DRIFT","REFUSE_REVISION",function(s,e)s.metadata.nQuestieDataRevision=1;return s,e end},
    {"REVISION_TYPE_DRIFT","REFUSE_REVISION",function(s,e)s.metadata.nQuestieDataRevision="0";return s,e end},
    {"BIN_MISSING","REFUSE_BIN_npc",function(s,e)s.fields.npcBin=nil;return s,e end},
    {"PTRS_MISSING","REFUSE_PTRS_obj",function(s,e)s.fields.objPtrs=nil;return s,e end},
    {"BIN_EMPTY","REFUSE_BIN_quest",function(s,e)s.fields.questBin="";return s,e end},
    {"PTRS_TABLE","REFUSE_PTRS_item",function(s,e)s.fields.itemPtrs={};return s,e end},
    {"RECEIPT_MISSING","REFUSE_RECEIPT_obj",function(s,e)s.receipts.obj=nil;return s,e end},
    {"RECEIPT_METATABLE","REFUSE_RECEIPT_obj",function(s,e)setmetatable(s.receipts.obj,{});return s,e end},
    {"RECEIPT_TOKEN","REFUSE_RECEIPT_TOKEN_npc",function(s,e)s.receipts.npc.token={};return s,e end},
    {"RECEIPT_GENERATION","REFUSE_RECEIPT_EPOCH_quest",function(s,e)s.receipts.quest.generation=8;return s,e end},
    {"RECEIPT_EPOCH","REFUSE_RECEIPT_EPOCH_item",function(s,e)s.receipts.item.sourceEpoch=30;return s,e end},
    {"MIXED_BIN_RECEIPT","REFUSE_RECEIPT_BYTES_obj",function(s,e)s.fields.objBin="BIN:another-generation";return s,e end},
    {"MIXED_PTRS_RECEIPT","REFUSE_RECEIPT_BYTES_item",function(s,e)s.fields.itemPtrs="PTR:another-generation";return s,e end}
}
for _,case in ipairs(negative) do
    local s,e=fresh()
    s,e=case[3](s,e)
    local ok,view,reason=pcall(selector.InspectCandidate,s,e)
    check(ok and view==nil and reason==case[2],case[1])
end

-- Deliberately NOT detected: caller-controlled receipts can be resealed,
-- and an unregistered A->B->A mutation is invisible to final-value checks.
local tampered,tamperExpect=fresh()
tampered.fields.npcBin="MALICIOUS:RESEALED"
tampered.receipts.npc.bin="MALICIOUS:RESEALED"
local unknownResult,unknownStatus=selector.InspectCandidate(tampered,tamperExpect)
check(unknownStatus=="STRUCTURAL_PASS" and
    unknownResult.fields.npcBin=="MALICIOUS:RESEALED",
    "KNOWN_GAP_FORGED_RESEAL_ACCEPTED")
local aba,abaExpect=fresh()
local before=aba.fields.questBin
aba.fields.questBin="TRANSIENT"
aba.fields.questBin=before
local abaView,abaStatus=selector.InspectCandidate(aba,abaExpect)
check(abaView~=nil and abaStatus=="STRUCTURAL_PASS",
    "KNOWN_GAP_UNREGISTERED_ABA_ACCEPTED")
check(oldPublic.npcBin=="OLD:NPC" and oldPublic.nQuestieDataRevision==27,
    "NO_LEGACY_FIELD_PUBLISH_ON_PASS_OR_FAIL")
check(#negative==41,"NEGATIVE_CONTROL_CENSUS:"..#negative)
check(n==4+9+2+#negative+4,"TOTAL_CONTROL_CENSUS:"..n)
print("PUBLIC G08 PART50 READONLY CANDIDATE INSPECTOR: "..n.."/"..n.." PASS")
print("PUBLIC G08 PART50 KNOWN UNPROTECTED: forged resealed receipts and unregistered A-B-A both accepted by structural check.")
print("PUBLIC G08 PART50 NOT NATIVE: fake binary strings/metadata, no actual codec/handle/stream, crash, 3.3.5a/IP source exclusivity, release or installation.")
