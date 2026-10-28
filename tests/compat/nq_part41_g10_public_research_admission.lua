-- Part41 G09/G10 PUBLIC-SAFE model: fictional records, NO owner data.
-- Uses pinned public 439-RAW programme text, not private per-quest findings.
-- Passing guards are proof of test semantics ONLY, not 439 decisions.
local path=assert(os.getenv("NQ_G10_PUBLIC_PROGRAMME"),
    "G10_PINNED_PUBLIC_PROGRAMME_REQUIRED")
local f=assert(io.open(path,"rb"),"G10_PUBLIC_DOC_NOT_STAGED")
local document=assert(f:read("*a"))
f:close()
local function exactlyOnce(s,reason)
    local p=assert(document:find(s,1,true),reason.."_MISSING")
    assert(not document:find(s,p+#s,true),reason.."_DUPLICATED")
end
local rawCategories={
    {key="linked",name="Source-linked first-pass candidates",count=12},
    {key="exploratory",name="Exploratory server-only records without both conventional relation types",count=418},
    {key="excluded",name="Owner-excluded quests 30000–30004",count=5},
    {key="placeholder",name="Identified placeholders/development records",count=3},
    {key="overlay",name="Existing N-Questie overlay quest 2001",count=1},
}
for _,bucket in ipairs(rawCategories) do
    exactlyOnce("| "..bucket.name.." | **"..bucket.count.."** |",
        "G10_PINNED_PUBLIC_BUCKET")
end
exactlyOnce("| **Total raw server-only research universe** | **439** |",
    "G10_PINNED_TOTAL")
exactlyOnce("**0/3 implemented**","G10_PILOT_IMPLEMENTATION")
-- The pilot text appears once in the source programme and is NOT a sixth
-- count bucket; never expand the 439 denominator by another 3.

local rows,seen={},{}
for _,bucket in ipairs(rawCategories) do
    for j=1,bucket.count do
        local key=bucket.key..":"..j -- anonymous invented index, NOT a quest ID
        assert(not seen[key],"G10_TEST_BUCKET_DUPLICATE")
        seen[key]=true
        local status="UNREVIEWED"
        if bucket.key=="excluded" then status="OWNER_DEFERRED" end
        if bucket.key=="placeholder" then status="NOT_PLAYABLE" end
        if bucket.key=="overlay" then status="ALREADY_COVERED" end
        rows[#rows+1]={key=key,bucket=bucket.key,status=status,
            eligible=nil,approved=nil}
    end
end
assert(#rows==439,"G10_RAW_RECORD_COUNT_MISMATCH")
local function counts()
    local c={linked=0,exploratory=0,excluded=0,placeholder=0,overlay=0}
    local keys={}
    for _,row in ipairs(rows) do
        assert(c[row.bucket]~=nil,"G10_BAD_BUCKET")
        assert(not keys[row.key],"G10_DUPLICATE_ANONYMOUS_RECORD")
        keys[row.key]=true
        c[row.bucket]=c[row.bucket]+1
    end
    return c
end
local proofKeys={
    "sourceSnapshotPinned","rawVsEffectiveVerified","missingFromEffective",
    "offeredToPlayer","starterAndFinisherVerified","itemRoleDistinguished",
    "privatePhaseEligible","historyAndConditionsReviewed",
    "independentSourceReview","ownerSourceApproval",
}
local function fullProof()
    local p={}
    for _,key in ipairs(proofKeys) do p[key]=true end
    return p
end
local function eligible(row)
    if row.bucket=="excluded" or row.bucket=="placeholder" or
        row.bucket=="overlay" then
        return false,"G10_BUCKET_NOT_ELIGIBLE_FOR_ADDITION"
    end
    local p=row.proof
    if type(p)~="table" then return false,"G10_PRIVATE_PROOF_UNKNOWN" end
    for _,key in ipairs(proofKeys) do
        if p[key]~=true then return false,"G10_PRIVATE_PROOF_INCOMPLETE" end
    end
    if p.unknownServerCondition or p.publicMapPinOnly or
        p.privateIPUnverified or p.sourceIsOnlyRaw then
        return false,"G10_INFERRED_AVAILABILITY_REFUSED"
    end
    return true,"G10_EVIDENCE_QUALIFIED_IN_FICTIONAL_MODEL"
end
local transitions={
    UNREVIEWED={EVIDENCE_IN_PROGRESS=true},
    EVIDENCE_IN_PROGRESS={
        PRESENT_BUT_FILTERED=true,ALREADY_COVERED=true,
        OWNER_DEFERRED=true,NOT_PLAYABLE=true,
        CONDITIONAL_OR_IP_UNKNOWN=true,SCHEMA_UNSUPPORTED=true,
        MISSING_AND_ELIGIBLE=true,
    },
    MISSING_AND_ELIGIBLE={APPROVED_TO_IMPLEMENT=true},
    APPROVED_TO_IMPLEMENT={IMPLEMENTED_IN_DRAFT=true},
    IMPLEMENTED_IN_DRAFT={QA_PASSED=true},
    QA_PASSED={ACCEPTED_IN_RELEASE=true},
}
local function advance(row,nextState)
    if row.bucket=="excluded" or row.bucket=="placeholder" or
        row.bucket=="overlay" then
        return false,"G10_TERMINAL_SOURCE_BUCKET"
    end
    if not (transitions[row.status] and
            transitions[row.status][nextState]) then
        return false,"G10_DISALLOWED_STATE_TRANSITION"
    end
    if nextState=="MISSING_AND_ELIGIBLE" then
        local ok,reason=eligible(row)
        if not ok then return false,reason end
    elseif nextState=="APPROVED_TO_IMPLEMENT" then
        local ok,reason=eligible(row)
        if not ok then return false,reason end
        if row.ownerPerQuestDecision~=true then
            return false,"G10_OWNER_PER_QUEST_DECISION_REQUIRED"
        end
    elseif nextState=="IMPLEMENTED_IN_DRAFT" then
        if row.independentImplementationReview~=true then
            return false,"G10_IMPLEMENTATION_REVIEW_REQUIRED"
        end
    elseif nextState=="QA_PASSED" then
        if row.nativeClientQA~=true or row.rollbackVerified~=true then
            return false,"G11_NATIVE_QA_AND_ROLLBACK_REQUIRED"
        end
    elseif nextState=="ACCEPTED_IN_RELEASE" then
        if row.separateReleaseAuthority~=true then
            return false,"G12_SEPARATE_RELEASE_AUTHORITY_REQUIRED"
        end
    end
    row.status=nextState
    return true,"G10_TRANSITION_ACCEPTED"
end
local function sample()
    return {bucket="exploratory",status="EVIDENCE_IN_PROGRESS",
        key="fictional:PRIVATE_NONE"}
end
local function refused(row,destination,expected)
    local before=row.status
    local ok,reason=advance(row,destination)
    assert(not ok and reason==expected and row.status==before,
        "G10_FAIL_CLOSED_TRANSITION_MISSING_"..expected)
end
local controls={
    function()
        local c=counts()
        assert(c.linked==12 and c.exploratory==418 and c.excluded==5
            and c.placeholder==3 and c.overlay==1,
            "G10_FIVE_PUBLIC_COUNTS_CHANGED")
    end,
    function()
        local c=counts()
        assert(c.linked+c.exploratory+c.excluded+c.placeholder+c.overlay==439,
            "G10_TOTAL_NOT_439")
    end,
    function()
        local approved=0
        for _,r in ipairs(rows) do if r.status=="APPROVED_TO_IMPLEMENT" then
            approved=approved+1 end end
        assert(approved==0,"G10_RAW_MUST_NOT_AUTO_APPROVE")
    end,
    function()
        local pilotAliases={"PILOT_A","PILOT_B","PILOT_C"}
        assert(#pilotAliases==3 and #rows==439,
            "G10_PILOT_NOT_A_NEW_BUCKET")
    end,
    function()
        refused({bucket="excluded",status="OWNER_DEFERRED"},
            "MISSING_AND_ELIGIBLE","G10_TERMINAL_SOURCE_BUCKET")
    end,
    function()
        refused({bucket="placeholder",status="NOT_PLAYABLE"},
            "MISSING_AND_ELIGIBLE","G10_TERMINAL_SOURCE_BUCKET")
    end,
    function()
        refused({bucket="overlay",status="ALREADY_COVERED"},
            "MISSING_AND_ELIGIBLE","G10_TERMINAL_SOURCE_BUCKET")
    end,
    function()
        refused(sample(),"APPROVED_TO_IMPLEMENT",
            "G10_DISALLOWED_STATE_TRANSITION")
    end,
    function()
        refused(sample(),"MISSING_AND_ELIGIBLE",
            "G10_PRIVATE_PROOF_UNKNOWN")
    end,
    function()
        local r=sample()
        r.proof=fullProof()
        r.proof.privatePhaseEligible=nil
        refused(r,"MISSING_AND_ELIGIBLE","G10_PRIVATE_PROOF_INCOMPLETE")
    end,
    function()
        local r=sample()
        r.proof=fullProof()
        r.proof.rawVsEffectiveVerified=nil
        refused(r,"MISSING_AND_ELIGIBLE","G10_PRIVATE_PROOF_INCOMPLETE")
    end,
    function()
        local r=sample()
        r.proof=fullProof()
        r.proof.itemRoleDistinguished=nil
        refused(r,"MISSING_AND_ELIGIBLE","G10_PRIVATE_PROOF_INCOMPLETE")
    end,
    function()
        local r=sample()
        r.proof=fullProof()
        r.proof.offeredToPlayer=nil
        refused(r,"MISSING_AND_ELIGIBLE","G10_PRIVATE_PROOF_INCOMPLETE")
    end,
    function()
        local r=sample()
        r.proof=fullProof()
        r.proof.publicMapPinOnly=true
        refused(r,"MISSING_AND_ELIGIBLE","G10_INFERRED_AVAILABILITY_REFUSED")
    end,
    function()
        local r=sample()
        r.proof=fullProof()
        r.proof.unknownServerCondition=true
        refused(r,"MISSING_AND_ELIGIBLE","G10_INFERRED_AVAILABILITY_REFUSED")
    end,
    function()
        local r=sample()
        r.proof=fullProof()
        assert(advance(r,"MISSING_AND_ELIGIBLE"),
            "G10_FICTIONAL_PROOF_POSITIVE_PATH")
        refused(r,"APPROVED_TO_IMPLEMENT",
            "G10_OWNER_PER_QUEST_DECISION_REQUIRED")
    end,
    function()
        local r=sample()
        r.proof=fullProof()
        assert(advance(r,"MISSING_AND_ELIGIBLE"))
        r.ownerPerQuestDecision=true
        assert(advance(r,"APPROVED_TO_IMPLEMENT"),
            "G10_FICTIONAL_OWNER_APPROVED_PATH")
        refused(r,"IMPLEMENTED_IN_DRAFT",
            "G10_IMPLEMENTATION_REVIEW_REQUIRED")
    end,
    function()
        local r=sample()
        r.proof=fullProof()
        assert(advance(r,"MISSING_AND_ELIGIBLE"))
        r.ownerPerQuestDecision=true
        assert(advance(r,"APPROVED_TO_IMPLEMENT"))
        r.independentImplementationReview=true
        assert(advance(r,"IMPLEMENTED_IN_DRAFT"))
        refused(r,"QA_PASSED","G11_NATIVE_QA_AND_ROLLBACK_REQUIRED")
    end,
    function()
        local r=sample()
        r.proof=fullProof()
        assert(advance(r,"MISSING_AND_ELIGIBLE"))
        r.ownerPerQuestDecision=true
        assert(advance(r,"APPROVED_TO_IMPLEMENT"))
        r.independentImplementationReview=true
        assert(advance(r,"IMPLEMENTED_IN_DRAFT"))
        r.nativeClientQA=true
        refused(r,"QA_PASSED","G11_NATIVE_QA_AND_ROLLBACK_REQUIRED")
    end,
    function()
        local r=sample()
        r.proof=fullProof()
        assert(advance(r,"MISSING_AND_ELIGIBLE"))
        r.ownerPerQuestDecision=true
        assert(advance(r,"APPROVED_TO_IMPLEMENT"))
        r.independentImplementationReview=true
        assert(advance(r,"IMPLEMENTED_IN_DRAFT"))
        r.nativeClientQA=true
        r.rollbackVerified=true
        assert(advance(r,"QA_PASSED"),"G11_FULL_FICTIONAL_QA_PATH")
        refused(r,"ACCEPTED_IN_RELEASE",
            "G12_SEPARATE_RELEASE_AUTHORITY_REQUIRED")
    end,
    function()
        local r=sample()
        r.proof=fullProof()
        assert(advance(r,"MISSING_AND_ELIGIBLE"))
        r.ownerPerQuestDecision=true
        assert(advance(r,"APPROVED_TO_IMPLEMENT"))
        r.independentImplementationReview=true
        assert(advance(r,"IMPLEMENTED_IN_DRAFT"))
        r.nativeClientQA=true
        r.rollbackVerified=true
        assert(advance(r,"QA_PASSED"))
        r.separateReleaseAuthority=true
        assert(advance(r,"ACCEPTED_IN_RELEASE"),
            "G12_FULL_FICTIONAL_RELEASE_PATH")
    end,
}
assert(#controls==21,"G10_CONTROL_CENSUS_CHANGED")
local n=0
for i,fn in ipairs(controls) do
    fn()
    n=n+1
    assert(n==i,"G10_CONTROL_EXECUTION_ORDER_CHANGED")
end
assert(n==21,"G10_CONTROL_EXECUTION_TOTAL_CHANGED")
print("PUBLIC G10 FICTIONAL RESEARCH CONTRACT: 21/21 PASS")
print("PUBLIC G10 RAW BUCKETS: 12 + 418 + 5 + 3 + 1 = 439; approved eligible count UNKNOWN; pilot 0/3 implemented.")
print("PUBLIC G10 NOT ACCEPTED: private evidence, per-quest dispositions, source eligibility, native QA or production/release permission.")
