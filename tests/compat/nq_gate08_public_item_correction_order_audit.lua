-- Part39 PUBLIC read-only ITEM effective-layer compound ordering probe.
-- Real WotLK item base + Classic/TBC/WotLK item Load() corrections,
-- automatic item quest starts and Classic/TBC/WotLK faction overlays.
-- Not a full QuestieCorrections:Initialize() or real client execution.
-- Never print item IDs, NPC/object/quest relationships or source values.
local modules = {}
QuestieLoader = {
    CreateModule = function(_, name)
        modules[name] = modules[name] or {}
        return modules[name]
    end,
    ImportModule = function(_, name)
        assert(modules[name], "missing public module " .. tostring(name))
        return modules[name]
    end,
}
Questie = {IsWotlk=true, IsTBC=false, IsClassic=false, IsSoD=false}
QuestieCompat = {Is335=true, WOW_PROJECT_ID=2}
local db = QuestieLoader:CreateModule("QuestieDB")
assert(loadfile("Database/itemDB.lua"))()
local sources = {
    {"Database/Corrections/classicItemFixes.lua", "QuestieItemFixes"},
    {"Database/Corrections/tbcItemFixes.lua", "QuestieTBCItemFixes"},
    {"Database/Corrections/wotlkItemFixes.lua", "QuestieWotlkItemFixes"},
}
for _, source in ipairs(sources) do
    assert(loadfile(source[1]))()
end
assert(loadfile("Database/Corrections/Automatic/itemStartFixes.lua"))()
local automatic = QuestieLoader:ImportModule("QuestieItemStartFixes")
local baseChunk = assert(loadfile("Database/Wotlk/wotlkItemDB.lua"))
baseChunk()
local baseSource = assert(db.itemData)
assert(type(baseSource) == "string", "PUBLIC_ITEM_BASE_FORMAT_CHANGED")
local function newBase()
    local decode = (loadstring or load)(baseSource, "=public_item_effective_base")
    assert(decode, "PUBLIC_ITEM_BASE_DECODE_FAILED")
    local ok, value = pcall(decode)
    assert(ok and type(value) == "table", "PUBLIC_ITEM_BASE_EVAL_FAILED")
    return value
end
local specs = {
    u12pair={"pair",0,4095},
    u24pair={"pair",0,16777215},
    s24pair={"pair",-8388608,8388607},
    u8u16array={"array",0,65535,255},
    u8s16pairs={"pairArray",-32767,32768,255},
    u16u16array={"array",0,65535,65535},
    u8s24pairs={"pairArray",-8388608,8388607,255},
    u8u24array={"array",0,16777215,255},
    u16u24array={"array",0,16777215,65535},
}
local function integral(value,lo,hi)
    return type(value)=="number" and value==value and value%1==0
        and value>=lo and value<=hi
end
local function validPair(value,lo,hi,top)
    if type(value)~="table" then return false end
    local n=0
    for k,v in pairs(value) do
        if (k~=1 and k~=2) or not integral(v,lo,hi) then return false end
        n=n+1
    end
    return n==2 and (not top or value[1]~=0 or value[2]~=0)
end
local function classify(value,spec)
    if type(value)~="table" then return "malformed" end
    if next(value)==nil then return "empty" end
    local mode,lo,hi,max=spec[1],spec[2],spec[3],spec[4]
    if mode=="pair" then
        return validPair(value,lo,hi,true) and "ordered" or "malformed"
    end
    local count,wrong,bad=0,false,false
    for k,v in pairs(value) do
        count=count+1
        if type(k)~="number" or k<1 or k%1~=0
            or k>max or count>max then
            bad=true
        elseif k~=count then
            wrong=true
        end
        if mode=="array" then
            if not integral(v,lo,hi) then bad=true end
        elseif not validPair(v,lo,hi,false) then
            bad=true
        end
    end
    if count==0 or count>max then bad=true end
    for i=1,count do
        if value[i]==nil then bad=true;break end
    end
    if bad then return "malformed" end
    return wrong and "reordered" or "ordered"
end
-- Mutation-sensitive fictional witnesses. Each VM must expose the same
-- expected outcomes or this audit refuses to run against the real corpus.
local controls = {
    {{10,20},specs.u8u24array,"ordered"},
    {{[3]=30,[2]=20,[1]=10},specs.u8u24array,"reordered"},
    {{[2]={3,4},[1]={1,2}},specs.u8s24pairs,"reordered"},
    {{[1]=10,[3]=30},specs.u8u24array,"malformed"},
    {{[1]=3,[3]=4},specs.u12pair,"malformed"},
    {{},specs.u8u24array,"empty"},
}
-- Use one resolver for the fictional guard cases AND the public survey,
-- so a base-first or empty-override regression cannot silently survive.
local function effectiveValue(record, override, key)
    if override and override[key] ~= nil then
        return override[key], true
    end
    return record and record[key], false
end
-- Do not count an override row again when it already exists in base.
-- Returning the visited count also gives us a synthetic branch witness.
local function visitExtraOverrideRows(base, overrides, visit)
    local n=0
    for id, fields in pairs(overrides) do
        if base[id] == nil then
            n=n+1
            visit(fields)
        end
    end
    return n
end
for _, t in ipairs(controls) do
    assert(classify(t[1],t[2])==t[3], "PUBLIC_ITEM_CLASSIFIER_CONTROL_FAILED")
end
local baseControl={[1]={10,20}}
local overrideControl={[1]={30,40}}
local clearControl={[1]={}}
local chosen,fromOverride=effectiveValue(baseControl,overrideControl,1)
assert(chosen==overrideControl[1] and fromOverride,
    "PUBLIC_ITEM_OVERRIDE_FIRST_CONTROL_FAILED")
chosen,fromOverride=effectiveValue(baseControl,clearControl,1)
assert(chosen==clearControl[1] and fromOverride and next(chosen)==nil,
    "PUBLIC_ITEM_INTENTIONAL_CLEAR_CONTROL_FAILED")
chosen,fromOverride=effectiveValue(baseControl,{},1)
assert(chosen==baseControl[1] and not fromOverride,
    "PUBLIC_ITEM_BASE_FALLBACK_CONTROL_FAILED")
chosen,fromOverride=effectiveValue(nil,{},1)
assert(chosen==nil and not fromOverride,
    "PUBLIC_ITEM_MISSING_ROW_CONTROL_FAILED")
local extraVisits,extraClears=0,0
local extraBase={[-701]={[1]={10,20}}}
local extraOverrides={
    [-701]={[1]={30,40}}, -- existing row must not be double-counted
    [-702]={[1]={}},     -- wholly fictional override-only clear
}
local extraCount=visitExtraOverrideRows(extraBase,extraOverrides,function(fields)
    extraVisits=extraVisits+1
    local val,yes=effectiveValue(nil,fields,1)
    if yes and type(val)=="table" and next(val)==nil then
        extraClears=extraClears+1
    end
end)
assert(extraCount==1 and extraVisits==1 and extraClears==1,
    "PUBLIC_ITEM_OVERRIDE_ONLY_CONTROL_FAILED")
print("PUBLIC ITEM EFFECTIVE CONTROLS: 11/11 PASS")
local function apply(main,changes,noOverwrite,noNew)
    assert(type(changes)=="table", "PUBLIC_ITEM_CORRECTION_SOURCE_INVALID")
    local n=0
    for id,fields in pairs(changes) do
        assert(type(id)=="number" and type(fields)=="table",
            "PUBLIC_ITEM_CORRECTION_RECORD_INVALID")
        if not main[id] and not noNew then main[id]={} end
        if main[id] then
            for key,value in pairs(fields) do
                if not noOverwrite or main[id][key]==nil then
                    main[id][key]=value
                    n=n+1
                end
            end
        end
    end
    return n
end
local function addOverrides(main,updates)
    assert(type(updates)=="table", "PUBLIC_ITEM_FACTION_SOURCE_INVALID")
    local n=0
    for id,fields in pairs(updates) do
        assert(type(id)=="number" and type(fields)=="table",
            "PUBLIC_ITEM_FACTION_RECORD_INVALID")
        if not main[id] then main[id]={} end
        for key,value in pairs(fields) do
            main[id][key]=value
            n=n+1
        end
    end
    return n
end
local compilerTypes=assert(db.itemCompilerTypes)
local keys=assert(db.itemKeys)
for _, faction in ipairs({"Alliance","Horde"}) do
    UnitFactionGroup=function() return faction end
    db.itemData=newBase()
    local patchWrites,factionWrites=0,0
    for _, source in ipairs(sources) do
        local module=QuestieLoader:ImportModule(source[2])
        patchWrites=patchWrites+apply(db.itemData,assert(module:Load()))
    end
    patchWrites=patchWrites+apply(db.itemData,
        assert(automatic:LoadAutomaticQuestStarts()),true,true)
    local overrides={}
    for _, source in ipairs(sources) do
        local module=QuestieLoader:ImportModule(source[2])
        factionWrites=factionWrites+addOverrides(overrides,
            assert(module:LoadFactionFixes()))
    end
    local stats={ordered=0,reordered=0,malformed=0,empty=0}
    local rows,fields,overrideFields=0,0,0
    -- This is a read-only projection of GetDBHandle's override-first field
    -- resolution; no correction tables are mutated by the classifier.
    for id,record in pairs(db.itemData) do
        rows=rows+1
        local over=overrides[id]
        for field,typ in pairs(compilerTypes) do
            local key=keys[field]
            local spec=specs[typ]
            if key and spec then
                local value, fromOverride=effectiveValue(record,over,key)
                if fromOverride then overrideFields=overrideFields+1 end
                if value~=nil then
                    fields=fields+1
                    local result=classify(value,spec)
                    stats[result]=stats[result]+1
                end
            end
        end
    end
    -- Faction-specific extra records must only be visited when base lacks
    -- them. Our synthetic test covers this branch even if public data has 0.
    local extraRows=visitExtraOverrideRows(db.itemData,overrides,function(over)
        for field,typ in pairs(compilerTypes) do
            local key=keys[field]
            local spec=specs[typ]
            if key and spec and over[key]~=nil then
                overrideFields=overrideFields+1
                fields=fields+1
                local classification=classify(over[key],spec)
                stats[classification]=stats[classification]+1
            end
        end
    end)
    rows=rows+extraRows
    assert(patchWrites>0 and factionWrites>0,
        "PUBLIC_ITEM_CORRECTION_LAYERS_NOT_EXERCISED")
    assert(fields>0 and fields==stats.ordered+stats.reordered
        +stats.malformed+stats.empty, "PUBLIC_ITEM_AUDIT_ACCOUNTING_FAILED")
    -- This is an exact-public-HEAD snapshot, not a permanent claim about
    -- future Questie data. Any count movement requires independent review.
    assert(stats.reordered==0 and stats.malformed==0,
        "PUBLIC_ITEM_CORRECTION_ORDER_BLOCKER")
    local expectedFactionWrites=(faction=="Alliance") and 12 or 11
    assert(rows==36767 and extraRows==0 and fields==28755
        and stats.ordered==28409 and stats.empty==346
        and patchWrites==1432 and factionWrites==expectedFactionWrites
        and overrideFields==11,
        "PUBLIC_ITEM_CORRECTION_LAYER_REGRESSION")
    print(string.format(
        "PUBLIC WOTLK ITEM CORRECTED faction=%s rows=%d simple_fields=%d ordered=%d reordered_dense=%d malformed=%d intentional_empty=%d patch_writes=%d faction_writes=%d override_fields=%d",
        faction,rows,fields,stats.ordered,stats.reordered,stats.malformed,
        stats.empty,patchWrites,factionWrites,overrideFields))
    db.itemData=nil
    collectgarbage("collect")
end
print("PUBLIC ITEM CORRECTION AUDIT COMPLETE (both factions)")
print("SCOPE LIMIT: public WotLK items with Classic/TBC/WotLK item fixes, automatic starts and faction views ONLY.")
print("NOT ACCEPTED: whole-four-kind effective Corrections, custom compat writers, source epoch, Stage1 and native client.")
