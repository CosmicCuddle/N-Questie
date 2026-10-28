-- PUBLIC-SAFE ALPHA0 G08 TEST-ONLY SHADOW MODEL. NOT PRODUCTION CODE.
-- Authenticates original source control-flow anchors then explores a DIFFERENT
-- proposed fail-closed generation protocol with invented writers and records.
local root=assert(os.getenv("NQ_G08_SHADOW_ORIGINAL_ROOT"),"PINNED_ORIGINAL_ROOT_REQUIRED")
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"),"ORIGINAL_SOURCE_MISSING:"..path)
    local src=assert(f:read("*a"));f:close()
    return src
end
local originalStage=read("Modules/QuestieInit.lua")
local originalCompiler=read("Database/compiler.lua")
local checks=0
local function check(ok,label)
    assert(ok,label)
    checks=checks+1
end
local function unique(text,token)
    local a=assert(text:find(token,1,true),"ORIGINAL_SOURCE_MISSING:"..token)
    assert(not text:find(token,a+#token,true),"ORIGINAL_SOURCE_DUPLICATE:"..token)
    return a
end
check(unique(originalStage,"QuestieDBCompiler:Compile()")>0,
      "H01_ORIGINAL_STAGE1_COMPILER_HANDOFF_PINNED")
check(unique(originalStage,
      "Questie.db.global.nQuestieDataRevision = nQuestieRevision")>0,
      "H02_ORIGINAL_STAGE1_SEPARATE_REVISION_WRITE_PINNED")
check(unique(originalCompiler,
      "if QuestieDBCompiler._isCompiling then")>0,
      "H03_ORIGINAL_COMPILER_SILENT_BUSY_ANCHORED")
check(unique(originalCompiler,
      'Questie.db.global[databaseKey.."Bin"] = stream:Save()')>0
      and unique(originalCompiler,
      'Questie.db.global[databaseKey.."Ptrs"] = QuestieDBCompiler:EncodePointerMap(stream, pointerMap)')>0,
      "H04_ORIGINAL_BIN_PTRS_DIRECT_WRITES_ANCHORED")

local kinds={"npc","obj","quest","item"}
local function shallowCopy(obj)
    local result={}
    for key,value in pairs(obj) do result[key]=value end
    return result
end
local function model(opts)
    opts=opts or {}
    local h={active=false,initializations=0,writes=0,source={
        epoch=1,revision=7,owner={},available=true
    }}
    local old={
        dbCompiledOnVersion="OLD",dbCompiledLang="frFR",
        dbCompiledExpansion=3,dbIsCompiled=true,dbCompiledCount=4,
        nQuestieDataRevision=6
    }
    for _,kind in ipairs(kinds) do
        old[kind.."Bin"]="OLD_BIN_"..kind
        old[kind.."Ptrs"]="OLD_PTR_"..kind
    end
    h.published=old
    function h:writer(kind,rev)
        self.writes=self.writes+1
        if opts.failAt==kind then
            error("FICTIONAL_WRITER_ERROR_"..kind,0)
        end
        if opts.invalidAt==kind then return 77,nil end
        return "NEW_BIN_"..kind.."_r"..rev,
            "NEW_PTR_"..kind.."_r"..rev
    end
    function h:Compile()
        if self.active then return "BUSY" end
        if not self.source.available then return "RETRY" end
        self.active=true
        local capturedOwner=self.source.owner
        local capturedEpoch=self.source.epoch
        local capturedRevision=self.source.revision
        local staging={}
        for _,kind in ipairs(kinds) do
            local ok,bin,ptrs=pcall(self.writer,self,kind,capturedRevision)
            if not ok or type(bin)~="string" or type(ptrs)~="string" then
                self.active=false
                return "ERROR"
            end
            staging[kind.."Bin"]=bin
            staging[kind.."Ptrs"]=ptrs
            -- The real compiler yields between per-kind writes. This proposed
            -- model yields while keeping all results PRIVATE in staging.
            coroutine.yield("staged:"..kind)
        end
        -- Explicit ABA-relevant monotonic epoch plus identity/revision checks.
        if not self.source.available or
            self.source.epoch~=capturedEpoch or
            self.source.owner~=capturedOwner or
            self.source.revision~=capturedRevision then
            self.active=false
            return "RETRY"
        end
        local candidate=shallowCopy(self.published)
        for _,kind in ipairs(kinds) do
            candidate[kind.."Bin"]=staging[kind.."Bin"]
            candidate[kind.."Ptrs"]=staging[kind.."Ptrs"]
        end
        candidate.dbCompiledOnVersion="9.5.1.1"
        candidate.dbCompiledLang="enUS"
        candidate.dbCompiledExpansion=11
        candidate.dbIsCompiled=true
        candidate.dbCompiledCount=(candidate.dbCompiledCount or 0)+1
        candidate.nQuestieDataRevision=capturedRevision
        -- Only one generation pointer changes. No yield in this block.
        -- This is a PROTOTYPE API, not today's AceDB global field structure.
        self.published=candidate
        self.active=false
        return "SUCCESS"
    end
    function h:Stage1()
        -- Proposed explicit handshake: original Stage1 has NO such status check.
        local status=self:Compile()
        if status~="SUCCESS" then return status end
        self.initializations=self.initializations+1
        return "SUCCESS"
    end
    return h
end
local function start(h)
    return coroutine.create(function() return h:Stage1() end)
end
local function tick(thread)
    local ok,result=coroutine.resume(thread)
    assert(ok,"SHADOW_MODEL_INTERNAL_ERROR:"..tostring(result))
    return result
end
local function allKinds(h,version)
    for _,kind in ipairs(kinds) do
        if h.published[kind.."Bin"]~=version.."_BIN_"..kind and
            h.published[kind.."Bin"]~=version.."_BIN_"..kind.."_r7" then return false end
        if h.published[kind.."Ptrs"]~=version.."_PTR_"..kind and
            h.published[kind.."Ptrs"]~=version.."_PTR_"..kind.."_r7" then return false end
    end
    return true
end
local function drain(thread)
    local result
    repeat
        result=tick(thread)
    until coroutine.status(thread)=="dead"
    return result
end

local good=model()
local before=good.published
local run=start(good)
check(tick(run)=="staged:npc","H05_SUCCESS_FIRST_PRIVATE_STAGE")
check(good.published==before and allKinds(good,"OLD"),
      "H06_NO_PUBLISH_DURING_NPC_STAGE")
check(good:Compile()=="BUSY","H07_EXPLICIT_BUSY_DURING_ACTIVE_STAGE")
check(good.initializations==0,"H08_NO_DOWNSTREAM_INIT_DURING_COMPILE")
check(tick(run)=="staged:obj","H09_OBJECT_PRIVATE_STAGE")
check(tick(run)=="staged:quest","H10_QUEST_PRIVATE_STAGE")
check(tick(run)=="staged:item","H11_ITEM_PRIVATE_STAGE")
check(good.published==before and good.published.dbCompiledCount==4,
      "H12_ALL_FOUR_STAGED_BUT_OLD_PUBLISHED")
check(tick(run)=="SUCCESS" and coroutine.status(run)=="dead",
      "H13_SUCCESS_STATUS_ONLY_AFTER_COMMIT")
check(good.published~=before,"H14_SINGLE_GENERATION_POINTER_SWAPPED")
check(allKinds(good,"NEW"),"H15_ALL_EIGHT_FIELDS_SAME_GENERATION")
check(good.published.dbCompiledOnVersion=="9.5.1.1" and
      good.published.dbCompiledLang=="enUS" and
      good.published.dbCompiledExpansion==11 and
      good.published.dbIsCompiled==true,
      "H16_METADATA_COHERENT_WITH_COMMITTED_GENERATION")
check(good.published.dbCompiledCount==5 and
      good.published.nQuestieDataRevision==7,
      "H17_VERSION_AND_DATA_REVISION_COMMITTED_TOGETHER")
check(good.initializations==1,"H18_INIT_ONLY_AFTER_SUCCESS")
check(good.active==false,"H19_SUCCESS_RELEASES_LEASE")
local second=start(good)
check(tick(second)=="staged:npc" and
      good.published.dbCompiledCount==5,
      "H20_SECOND_GENERATION_REMAINS_PRIVATE")
check(drain(second)=="SUCCESS" and
      good.published.dbCompiledCount==6 and
      good.initializations==2,"H21_REUSABLE_LEASE_SECOND_SUCCESS")

local errorCase=model({failAt="obj"})
local oldError=errorCase.published
local errThread=start(errorCase)
check(tick(errThread)=="staged:npc","H22_ERROR_AFTER_ONE_STAGED_KIND")
check(errorCase.published==oldError,"H23_ERROR_FIXTURE_NO_EARLY_WRITE")
check(tick(errThread)=="ERROR","H24_WRITER_THROW_EXPLICIT_ERROR")
check(errorCase.published==oldError and allKinds(errorCase,"OLD"),
      "H25_WRITER_ERROR_NO_PARTIAL_PUBLICATION")
check(not errorCase.active,"H26_ERROR_RELEASES_LEASE")
check(errorCase.initializations==0,"H27_ERROR_BLOCKS_DOWNSTREAM_INIT")
errorCase.writer=function(self,kind,rev)
    self.writes=self.writes+1
    return "NEW_BIN_"..kind.."_r"..rev,"NEW_PTR_"..kind.."_r"..rev
end
check(drain(start(errorCase))=="SUCCESS","H28_RECOVER_AFTER_ERROR")

local invalid=model({invalidAt="item"})
local oldInvalid=invalid.published
check(drain(start(invalid))=="ERROR","H29_INVALID_LATE_WRITER_SHAPE_ERROR")
check(invalid.published==oldInvalid and invalid.initializations==0,
      "H30_INVALID_LATE_WRITER_NO_PUBLICATION")
local aba=model()
local abaOld=aba.published
local abaOwner=aba.source.owner
local abaRun=start(aba)
check(tick(abaRun)=="staged:npc","H31_ABA_AFTER_FIRST_YIELD")
aba.source.owner={};aba.source.epoch=2
aba.source.owner=abaOwner;aba.source.epoch=3
check(drain(abaRun)=="RETRY","H32_A_TO_B_TO_A_EPOCH_REJECTED")
check(aba.published==abaOld,"H33_ABA_STALE_CANDIDATE_NOT_PUBLISHED")
check(aba.initializations==0,"H34_ABA_NO_DOWNSTREAM_INIT")
check(not aba.active,"H35_ABA_RELEASES_LEASE")
check(drain(start(aba))=="SUCCESS","H36_ABA_NEW_GENERATION_RETRY_PASSES")

local ownerChanged=model()
local firstOwner=ownerChanged.source.owner
local ownerRun=start(ownerChanged)
tick(ownerRun)
ownerChanged.source.owner={}
check(drain(ownerRun)=="RETRY" and
      ownerChanged.published.dbCompiledCount==4,
      "H37_OWNER_IDENTITY_CHANGES_WITHOUT_EPOCH_RETRY")
local revisionChanged=model()
local revRun=start(revisionChanged)
tick(revRun)
revisionChanged.source.revision=8
check(drain(revRun)=="RETRY" and
      revisionChanged.published.nQuestieDataRevision==6,
      "H38_SOURCE_REVISION_DRIFT_RETRY")
local absent=model()
absent.source.available=false
check(drain(start(absent))=="RETRY" and absent.writes==0,
      "H39_MISSING_SOURCE_FAST_RETRY")
local invalidated=model()
local invalidatedRun=start(invalidated)
tick(invalidatedRun)
invalidated.source.available=false
check(drain(invalidatedRun)=="RETRY" and
      invalidated.published.dbCompiledCount==4,
      "H40_SOURCE_DISAPPEARED_MID_COMPILE_RETRY")
local busyStart=model()
busyStart.active=true
check(drain(start(busyStart))=="BUSY" and
      busyStart.initializations==0 and busyStart.writes==0,
      "H41_ALREADY_BUSY_NOT_TREATED_AS_SUCCESS")
local late=model({failAt="item"})
local oldLate=late.published
check(drain(start(late))=="ERROR","H42_LAST_KIND_FAILURE_RETURNS_ERROR")
check(late.published==oldLate and allKinds(late,"OLD"),
      "H43_LAST_KIND_FAILURE_PRESERVES_ALL_EIGHT_FIELDS")
check(late.published.nQuestieDataRevision==6 and
      late.published.dbCompiledCount==4,
      "H44_LAST_KIND_ERROR_PRESERVES_METADATA")
check(late.initializations==0 and late.active==false,
      "H45_LAST_KIND_ERROR_NO_INIT_AND_LEASE_RELEASE")

assert(checks==45,"ALPHA0_SHADOW_HANDSHAKE_CENSUS_CHANGED")
print("PUBLIC G08 PART43 SHADOW FAIL-CLOSED HANDSHAKE: 45/45 PASS")
print("PUBLIC G08 PROTOTYPE ONLY: SUCCESS/BUSY/RETRY/ERROR, staged four-kind fields and metadata, one in-memory generation swap, epoch ABA guard, failure without downstream initialization.")
print("PUBLIC G08 NOT ACCEPTED: shadow API is NOT original production Questie/AceDB, actual E01-E08 writers or QuestieStream, disk/relog or native 3.3.5a/IP, ZIP/install/merge/release.")
