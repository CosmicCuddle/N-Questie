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
-- Invalid marker or unreadable active generation => require external recovery.
-- Only use the other complete slot if the damaged active slot still has a
-- readable *newer* generation and the other slot passes its independent check.
local function recover(disk)
    if type(disk)~="table" or (disk.active~=1 and disk.active~=2)
        or type(disk.slots)~="table" then
        return "REFUSE_MARKER"
    end
    local selected=disk.slots[disk.active]
    local alternate=disk.slots[3-disk.active]
    local selectedOK,alternateOK=valid(selected),valid(alternate)
    if selectedOK then
        if alternateOK and selected.generation==alternate.generation
            and not same(selected,alternate) then
            return "REFUSE_EQUIVOCATION"
        end
        return "ACTIVE",copy(selected)
    end
    if alternateOK and type(selected)=="table"
        and integer(selected.generation)
        and alternate.generation<selected.generation then
        return "FALLBACK",copy(alternate)
    end
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
local function expect(name,state,want,gen)
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
end
local first=generation(1,"A")
local second=generation(2,"B")
expect("C01_FIRST_ACTIVE",disk(1,first,nil),"ACTIVE",1)
expect("C02_SECOND_ACTIVE",disk(2,first,second),"ACTIVE",2)
expect("C03_UNCOMMITTED_STAGING",disk(1,first,second),"ACTIVE",1)
for i,key in ipairs(fields) do
    expect("C04_TORN_FIELD_"..i,disk(2,first,corrupt(second,key,nil)),
        "FALLBACK",1)
    expect("C05_CHANGED_FIELD_"..i,
        disk(2,first,corrupt(second,key,"synthetic:wrong")),
        "FALLBACK",1)
end
for i,key in ipairs({"revision","compiledCount","locale","sourceStamp"}) do
    expect("C06_MIXED_META_"..i,
        disk(2,first,corrupt(second,key,"synthetic:wrong")),
        "FALLBACK",1)
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
    "FALLBACK",1)
expect("C15_CORRUPT_REVISION",disk(2,first,corrupt(second,"revision",-1)),
    "FALLBACK",1)
expect("C16_EMPTY_LOCALE",disk(2,first,corrupt(second,"locale","")),
    "FALLBACK",1)
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
print("PUBLIC TX17 FICTIONAL RECOVERY CONTROLS: "..cases.." PASS")
print("PUBLIC TX17 KNOWN LIMIT: checksums are not writer authentication.")
print("PUBLIC TX17 NOT ACCEPTED: WoW client disk serialization, crash atomicity, SavedVariables provenance, full source epoch, real relog or production integration.")
