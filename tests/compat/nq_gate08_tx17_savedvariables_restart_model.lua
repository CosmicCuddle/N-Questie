-- N-Questie Part40: FICTIONAL TEST-ONLY SavedVariables restart-selection model.
-- No addon data, real server mappings, client SavedVariables or production code.
-- This is a falsifiable TX17 design contract, NOT a disk/crash safety proof.
local fields={
    "npcBin","npcPtrs","objBin","objPtrs",
    "questBin","questPtrs","itemBin","itemPtrs"
}
local metadata={"generation","schema","revision","compiledCount","locale","sourceStamp"}
local function integer(n)
    return type(n)=="number" and n==n and n%1==0 and n>=0 and n<=100000000
end
local function canonical(slot)
    local pieces={}
    local function field(key,value)
        local s=tostring(value)
        pieces[#pieces+1]=tostring(#key)..":"..key..tostring(#s)..":"..s..";"
    end
    for _,key in ipairs(fields) do field(key,slot[key]) end
    for _,key in ipairs(metadata) do field(key,slot[key]) end
    return table.concat(pieces)
end
local function digest(slot)
    local a,b=0,0
    local data=canonical(slot)
    for i=1,#data do
        local n=string.byte(data,i)
        a=(a*131+n)%1000000007
        b=(b*137+n)%1000000009
    end
    return a,b
end
local function seal(slot)
    slot.checkA,slot.checkB=digest(slot)
    return slot
end
local function valid(slot)
    if type(slot)~="table" or slot.schema~=1
        or not integer(slot.generation) or not integer(slot.revision)
        or not integer(slot.compiledCount) or slot.compiledCount==0
        or type(slot.locale)~="string" or #slot.locale==0
        or type(slot.sourceStamp)~="string" or #slot.sourceStamp==0 then
        return false
    end
    for _,key in ipairs(fields) do
        if type(slot[key])~="string" or #slot[key]==0 then return false end
    end
    local a,b=digest(slot)
    return a==slot.checkA and b==slot.checkB
end
local function copy(slot)
    local out={}
    for _,key in ipairs(fields) do out[key]=slot[key] end
    for _,key in ipairs(metadata) do out[key]=slot[key] end
    out.checkA,out.checkB=slot.checkA,slot.checkB
    return out
end
local function same(x,y)
    for _,key in ipairs(fields) do if x[key]~=y[key] then return false end end
    for _,key in ipairs(metadata) do if x[key]~=y[key] then return false end end
    return true
end
-- The active-slot selector is a separate persisted commit intent. A complete
-- uncommitted slot MUST NOT be promoted simply because its generation is high.
-- An invalid marker or invalid active checksum ALWAYS requires external
-- recovery. Even a readable generation from an invalid slot is untrusted.
-- Automatically picking a "lower" alternate risks promoting never-committed
-- staged data after a torn write or generation-number forgery.
local function recover(disk)
    if type(disk)~="table" or (disk.active~=1 and disk.active~=2)
        or type(disk.slots)~="table" then
        return "REFUSE_MARKER"
    end
    local selected=disk.slots[disk.active]
    local alternate=disk.slots[3-disk.active]
    -- Two names for the same writable table are not two independently
    -- recoverable generations. Reject before considering checksums.
    if selected~=nil and rawequal(selected,alternate) then
        return "REFUSE_ALIASED_SLOTS"
    end
    local selectedOK,alternateOK=valid(selected),valid(alternate)
    if selectedOK then
        if alternateOK and selected.generation==alternate.generation
            and not same(selected,alternate) then
            return "REFUSE_EQUIVOCATION"
        end
        return "ACTIVE",copy(selected)
    end
    -- Do NOT infer the alternate was committed from an unauthenticated
    -- generation number in a damaged active slot; refuse automatic fallback.
    return "REFUSE_NO_CERTIFIED_GENERATION"
end
-- Entirely fictional records. These string tokens are not Questie data.
local function generation(n,tag)
    local x={generation=n,schema=1,revision=n,compiledCount=4,
        locale="synthetic-locale",sourceStamp="synthetic-source-"..tag}
    for _,name in ipairs(fields) do x[name]="synthetic:"..tag..":"..name end
    return seal(x)
end
local function disk(active,one,two)
    return {active=active,slots={[1]=one,[2]=two}}
end
local function corrupt(x,key,val)
    local out=copy(x)
    out[key]=val
    return out
end
local cases=0
local seenControls={}
local function expect(name,state,want,gen)
    assert(not seenControls[name],"PUBLIC_TX17_DUPLICATE_CONTROL")
    local status,value=recover(state)
    assert(status==want,"PUBLIC_TX17_CONTROL_"..name)
    if gen~=nil then
        assert(value and value.generation==gen
            and value.npcBin~=nil and value.itemPtrs~=nil,
            "PUBLIC_TX17_GENERATION_"..name)
    else
        assert(value==nil,"PUBLIC_TX17_UNEXPECTED_RESULT_"..name)
    end
    cases=cases+1
    seenControls[name]=true
end
local first=generation(1,"A")
local second=generation(2,"B")
expect("C01_FIRST_ACTIVE",disk(1,first,nil),"ACTIVE",1)
expect("C02_SECOND_ACTIVE",disk(2,first,second),"ACTIVE",2)
expect("C03_UNCOMMITTED_STAGING",disk(1,first,second),"ACTIVE",1)
for i,key in ipairs(fields) do
    expect("C04_TORN_FIELD_"..i,disk(2,first,corrupt(second,key,nil)),
        "REFUSE_NO_CERTIFIED_GENERATION")
    expect("C05_CHANGED_FIELD_"..i,
        disk(2,first,corrupt(second,key,"synthetic:wrong")),
        "REFUSE_NO_CERTIFIED_GENERATION")
end
for i,key in ipairs({"revision","compiledCount","locale","sourceStamp"}) do
    expect("C06_MIXED_META_"..i,
        disk(2,first,corrupt(second,key,"synthetic:wrong")),
        "REFUSE_NO_CERTIFIED_GENERATION")
end
expect("C07_BAD_MARKER",disk(3,first,second),"REFUSE_MARKER")
expect("C08_MISSING_MARKER",disk(nil,first,second),"REFUSE_MARKER")
expect("C09_MISSING_ACTIVE",disk(2,first,nil),"REFUSE_NO_CERTIFIED_GENERATION")
expect("C10_BAD_INACTIVE",disk(2,corrupt(first,"npcBin","bad"),second),
    "ACTIVE",2)
expect("C11_BOTH_INVALID",disk(2,corrupt(first,"npcBin","bad"),
    corrupt(second,"itemPtrs","bad")),"REFUSE_NO_CERTIFIED_GENERATION")
expect("C12_UNKNOWN_ACTIVE_GENERATION",disk(2,first,
    corrupt(second,"generation",nil)),"REFUSE_NO_CERTIFIED_GENERATION")
expect("C13_INVALID_ACTIVE_GENERATION",disk(2,first,
    corrupt(second,"generation",-1)),"REFUSE_NO_CERTIFIED_GENERATION")
expect("C14_INVALID_SCHEMA",disk(2,first,corrupt(second,"schema",2)),
    "REFUSE_NO_CERTIFIED_GENERATION")
expect("C15_CORRUPT_REVISION",disk(2,first,corrupt(second,"revision",-1)),
    "REFUSE_NO_CERTIFIED_GENERATION")
expect("C16_EMPTY_LOCALE",disk(2,first,corrupt(second,"locale","")),
    "REFUSE_NO_CERTIFIED_GENERATION")
expect("C17_SAME_GEN_DIFFERENT_SIGNED",disk(2,
    generation(2,"A"),generation(2,"B")),"REFUSE_EQUIVOCATION")
expect("C18_SAME_GEN_SAME_SIGNED",disk(2,copy(second),second),"ACTIVE",2)
expect("C19_VALID_ACTIVE_WITH_NEWER_UNCOMMITTED",
    disk(1,first,generation(3,"STAGED")),"ACTIVE",1)
local status,snapshot=recover(disk(2,first,second))
assert(status=="ACTIVE" and snapshot~=second,"PUBLIC_TX17_ALIAS_CONTROL")
snapshot.npcBin="mutated-outside"
assert(second.npcBin~="mutated-outside","PUBLIC_TX17_RETURN_ALIAS")
cases=cases+1
-- An attacker/unknown writer who changes values and recomputes these checks
-- defeats both simple hashes. Reproduce this limit *without* claiming safety.
local forged=seal(corrupt(second,"npcBin","synthetic:forged"))
expect("C20_KNOWN_UNSAFE_FORGED_CHECK",disk(2,first,forged),"ACTIVE",2)
-- A damaged active generation falsely claims to be newer than a complete
-- but never-committed alternate. Reading the number does NOT prove it.
expect("C21_FORGED_ACTIVE_EPOCH_CANNOT_PROMOTE_SPARE",
    disk(1,corrupt(first,"generation",3),second),
    "REFUSE_NO_CERTIFIED_GENERATION")
-- F1d: an invalid OLD active slot must not promote a newer
-- complete-but-uncommitted alternate; neither its checksum nor its
-- generation number authenticates a commit.
expect("C22_DAMAGED_OLD_ACTIVE_NEWER_UNCOMMITTED",
    disk(1,corrupt(first,"npcBin","synthetic:damaged"),second),
    "REFUSE_NO_CERTIFIED_GENERATION")
-- G3/G4: changed but still well-typed metadata must invalidate the seal.
expect("C23_VALID_INT_REVISION_DRIFT",
    disk(2,first,corrupt(second,"revision",7)),
    "REFUSE_NO_CERTIFIED_GENERATION")
expect("C24_VALID_INT_COUNT_DRIFT",
    disk(2,first,corrupt(second,"compiledCount",9)),
    "REFUSE_NO_CERTIFIED_GENERATION")
-- F7: an attacker may recompute BOTH checks after deleting a field.
-- The independent type/empty validation must still refuse.
expect("C25_RESEALED_MISSING_BIN_FIELD",
    disk(2,first,seal(corrupt(second,"npcBin",nil))),
    "REFUSE_NO_CERTIFIED_GENERATION")
-- Slot aliases cannot represent independent persisted generations.
expect("C26_IDENTICAL_TABLE_ALIAS",
    disk(2,second,second),"REFUSE_ALIASED_SLOTS")
-- Independent expected-name census: replacing an expect() with a bare
-- cases increment must fail even if its printed headline is also forged.
local requiredNames={
    "C01_FIRST_ACTIVE","C02_SECOND_ACTIVE","C03_UNCOMMITTED_STAGING",
    "C07_BAD_MARKER","C08_MISSING_MARKER","C09_MISSING_ACTIVE",
    "C10_BAD_INACTIVE","C11_BOTH_INVALID",
    "C12_UNKNOWN_ACTIVE_GENERATION","C13_INVALID_ACTIVE_GENERATION",
    "C14_INVALID_SCHEMA","C15_CORRUPT_REVISION","C16_EMPTY_LOCALE",
    "C17_SAME_GEN_DIFFERENT_SIGNED","C18_SAME_GEN_SAME_SIGNED",
    "C19_VALID_ACTIVE_WITH_NEWER_UNCOMMITTED",
    "C20_KNOWN_UNSAFE_FORGED_CHECK",
    "C21_FORGED_ACTIVE_EPOCH_CANNOT_PROMOTE_SPARE",
    "C22_DAMAGED_OLD_ACTIVE_NEWER_UNCOMMITTED",
    "C23_VALID_INT_REVISION_DRIFT","C24_VALID_INT_COUNT_DRIFT",
    "C25_RESEALED_MISSING_BIN_FIELD","C26_IDENTICAL_TABLE_ALIAS",
}
for i=1,8 do
    requiredNames[#requiredNames+1]="C04_TORN_FIELD_"..i
    requiredNames[#requiredNames+1]="C05_CHANGED_FIELD_"..i
end
for i=1,4 do requiredNames[#requiredNames+1]="C06_MIXED_META_"..i end
assert(#requiredNames==43 and cases==44,
    "PUBLIC_TX17_CASE_CENSUS_CHANGED")
for _,name in ipairs(requiredNames) do
    assert(seenControls[name],"PUBLIC_TX17_CONTROL_NOT_EXECUTED")
end
print("PUBLIC TX17 FICTIONAL RECOVERY CONTROLS: "..cases.." PASS")
print("PUBLIC TX17 KNOWN LIMIT: checksums are not writer authentication.")
print("PUBLIC TX17 NOT ACCEPTED: WoW client disk serialization, crash atomicity, SavedVariables provenance, full source epoch, real relog or production integration.")
