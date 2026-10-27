-- Part39 public WotLK OBJECT correction order audit.
-- No private owner DB, IDs, object links or source values are printed.
-- READ ONLY: public base plus Classic/TBC/WotLK object Load() and faction
-- overrides. Excludes Compat custom writers, dynamic corrections and client.
local modules={}
QuestieLoader={
    CreateModule=function(_,name)
        modules[name]=modules[name] or {}
        return modules[name]
    end,
    ImportModule=function(_,name)
        assert(modules[name],"missing public module "..tostring(name))
        return modules[name]
    end,
}
Questie={IsWotlk=true,IsTBC=false,IsClassic=false,IsSoD=false}
QuestieCompat={Is335=true,WOW_PROJECT_ID=2}
local db=QuestieLoader:CreateModule("QuestieDB")
local zone=QuestieLoader:CreateModule("ZoneDB")
assert(loadfile("Database/objectDB.lua"))()
assert(loadfile("Database/Zones/zoneTables.lua"))()
zone.zoneIDs=assert(zone.private.zoneIDs)
local sources={
    {"Database/Corrections/classicObjectFixes.lua","QuestieObjectFixes"},
    {"Database/Corrections/tbcObjectFixes.lua","QuestieTBCObjectFixes"},
    {"Database/Corrections/wotlkObjectFixes.lua","QuestieWotlkObjectFixes"},
}
for _,source in ipairs(sources) do
    assert(loadfile(source[1]))()
end
assert(loadfile("Database/Wotlk/wotlkObjectDB.lua"))()
local source=assert(db.objectData)
assert(type(source)=="string","PUBLIC_OBJECT_SOURCE_FORMAT_CHANGED")
local function newBase()
    local decode=(loadstring or load)(source,"=nq_public_object_base")
    assert(decode,"PUBLIC_OBJECT_DECODE_FAILED")
    local ok,value=pcall(decode)
    assert(ok and type(value)=="table","PUBLIC_OBJECT_EVAL_FAILED")
    return value
end
local function integral(v,lo,hi)
    return type(v)=="number" and v==v and v%1==0 and v>=lo and v<=hi
end
-- Object questStarts and questEnds use u8u24array, max 255 elements.
local function classify(v)
    if type(v)~="table" then return "malformed" end
    if next(v)==nil then return "empty" end
    local count,wrong,bad=0,false,false
    for k,val in pairs(v) do
        count=count+1
        if type(k)~="number" or k%1~=0 or k<1 or k>255 or count>255 then
            bad=true
        elseif k~=count then
            wrong=true
        end
        if not integral(val,0,16777215) then bad=true end
    end
    if count==0 or count>255 then bad=true end
    for i=1,count do
        if v[i]==nil then bad=true;break end
    end
    if bad then return "malformed" end
    if wrong then return "reordered" end
    return "ordered"
end
local function effective(record,over,key)
    if over and over[key]~=nil then return over[key],true end
    return record and record[key],false
end
local function apply(base,updates)
    assert(type(updates)=="table","PUBLIC_OBJECT_PATCH_SOURCE_BAD")
    local writes=0
    for id,fields in pairs(updates) do
        assert(type(id)=="number" and type(fields)=="table","PUBLIC_OBJECT_PATCH_BAD")
        if not base[id] then base[id]={} end
        for key,v in pairs(fields) do
            base[id][key]=v
            writes=writes+1
        end
    end
    return writes
end
local function addOverride(overrides,updates)
    assert(type(updates)=="table","PUBLIC_OBJECT_FACTION_SOURCE_BAD")
    local writes=0
    for id,fields in pairs(updates) do
        assert(type(id)=="number" and type(fields)=="table","PUBLIC_OBJECT_FACTION_BAD")
        if not overrides[id] then overrides[id]={} end
        for k,v in pairs(fields) do
            overrides[id][k]=v
            writes=writes+1
        end
    end
    return writes
end
local function extras(base,overrides,visit)
    local n=0
    for id,row in pairs(overrides) do
        if base[id]==nil then
            n=n+1
            visit(row)
        end
    end
    return n
end
-- Fictional controls: no real object IDs, names or linked quest values.
local examples={
    {{9,10},"ordered"},
    {{[3]=30,[2]=20,[1]=10},"reordered"},
    {{[1]=10,[3]=30},"malformed"},
    {{[1]=-1},"malformed"},
    {{[1]=16777216},"malformed"},
    {{}, "empty"},
}
for _,control in ipairs(examples) do
    assert(classify(control[1])==control[2],"PUBLIC_OBJECT_CLASSIFIER_CONTROL_FAILED")
end
local fakeBase={[1]={9,10}}
local fakeOverride={[1]={}}
local chosen,hasOverride=effective(fakeBase,fakeOverride,1)
assert(hasOverride and chosen==fakeOverride[1] and next(chosen)==nil,
    "PUBLIC_OBJECT_EMPTY_OVERRIDE_CONTROL_FAILED")
local fallback,fallbackOver=effective(fakeBase,{},1)
assert(not fallbackOver and fallback==fakeBase[1],
    "PUBLIC_OBJECT_FALLBACK_CONTROL_FAILED")
local count=extras({[-700]={[1]={9,10}}},{
    [-700]={[1]={11,12}},
    [-701]={[1]={}},
},function(row)
    local selected,yes=effective(nil,row,1)
    assert(yes and type(selected)=="table" and next(selected)==nil,
        "PUBLIC_OBJECT_EXTRA_CLEAR_CONTROL_FAILED")
end)
assert(count==1,"PUBLIC_OBJECT_EXTRA_ROW_CONTROL_FAILED")
print("PUBLIC OBJECT CORRECTION CONTROLS: 10/10 PASS")
local keys=assert(db.objectKeys)
local cTypes=assert(db.objectCompilerTypes)
local audited={questStarts=false,questEnds=false}
for _,faction in ipairs({"Alliance","Horde"}) do
    UnitFactionGroup=function() return faction end
    local base=newBase()
    local patchWrites,overlayWrites=0,0
    for _,sourcePair in ipairs(sources) do
        patchWrites=patchWrites+apply(base,
            assert(QuestieLoader:ImportModule(sourcePair[2]):Load()))
    end
    local overrides={}
    for _,sourcePair in ipairs(sources) do
        overlayWrites=overlayWrites+addOverride(overrides,
            assert(QuestieLoader:ImportModule(sourcePair[2]):LoadFactionFixes()))
    end
    local stats={ordered=0,reordered=0,malformed=0,empty=0}
    local rows,fields,overridden,extraRows=0,0,0,0
    local function examine(row,over)
        for field,typ in pairs(cTypes) do
            if typ=="u8u24array" then
                assert(field=="questStarts" or field=="questEnds",
                    "PUBLIC_OBJECT_COMPILER_TYPE_DRIFT")
                audited[field]=true
                local value,fromOver=effective(row,over,keys[field])
                if fromOver then overridden=overridden+1 end
                if value~=nil then
                    fields=fields+1
                    local state=classify(value)
                    stats[state]=stats[state]+1
                end
            end
        end
    end
    for id,row in pairs(base) do
        rows=rows+1
        examine(row,overrides[id])
    end
    extraRows=extras(base,overrides,function(over)
        examine(nil,over)
    end)
    rows=rows+extraRows
    assert(patchWrites>0 and overlayWrites>0 and fields>0,
        "PUBLIC_OBJECT_LAYER_NOT_EXERCISED")
    assert(fields==stats.ordered+stats.reordered+stats.malformed+stats.empty,
        "PUBLIC_OBJECT_ACCOUNTING_FAILED")
    print(string.format("PUBLIC WOTLK OBJECT CORRECTED faction=%s rows=%d simple_fields=%d ordered=%d reordered_dense=%d malformed=%d intentional_empty=%d patch_writes=%d faction_writes=%d override_fields=%d override_only_rows=%d",
        faction,rows,fields,stats.ordered,stats.reordered,stats.malformed,
        stats.empty,patchWrites,overlayWrites,overridden,extraRows))
    -- Classifiers must refuse unexpected structures; a failure is evidence
    -- to investigate and DOES NOT permit a stage or production change.
    assert(stats.reordered==0 and stats.malformed==0,
        "PUBLIC_OBJECT_CORRECTION_ORDER_BLOCKER")
    collectgarbage("collect")
end
assert(audited.questStarts and audited.questEnds,
    "PUBLIC_OBJECT_FIELDS_NOT_AUDITED")
print("PUBLIC OBJECT CORRECTION AUDIT COMPLETE (both factions)")
print("SCOPE LIMIT: public WotLK objects and Classic/TBC/WotLK fixes/faction override projections only.")
print("NOT ACCEPTED: 4-kind effective source, Compat custom/late writers, pool quarantine, Stage1 or client.")
