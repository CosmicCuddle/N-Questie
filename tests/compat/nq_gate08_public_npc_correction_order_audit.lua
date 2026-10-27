-- Part39 PUBLIC READ-ONLY WotLK NPC correction-order compatibility survey.
-- Aggregates ONLY. Never print NPC IDs, quest IDs, locations or relationships.
-- QuestieCorrections load order: Classic Load, TBC Load, WotLK LoadAutomatics,
-- WotLK Load; both factions' read-time LoadFactionFixes projections.
-- Intentional scope limitation: only questStarts/questEnds u8u24array; no
-- complex spawn/waypoint, extra derived quest-faction patching, custom 335
-- Compat.LoadCorrections, late unknown writers or client integration.
local modules={}
QuestieLoader={
    CreateModule=function(_,name)
        modules[name]=modules[name] or {}
        return modules[name]
    end,
    ImportModule=function(_,name)
        assert(modules[name],"missing public fixture module "..tostring(name))
        return modules[name]
    end,
}
Questie={IsWotlk=true,IsTBC=false,IsClassic=false,IsSoD=false}
QuestieCompat={Is335=true,WOW_PROJECT_ID=2}
local db=QuestieLoader:CreateModule("QuestieDB")
local zone=QuestieLoader:CreateModule("ZoneDB")
QuestieLoader:CreateModule("l10n")
assert(loadfile("Database/npcDB.lua"))()
assert(loadfile("Database/Zones/zoneTables.lua"))()
zone.zoneIDs=assert(zone.private.zoneIDs)
-- These two placeholder tables allow public Load() to retain its waypoint
-- field keys. We do NOT interpret waypoint bytes/coordinates here; this is
-- a simple-quest-array projection, not exact full-source materialization.
db.waypointPresets={ORGRIMS_HAMMER={},THE_SKYBREAKER={}}
local sources={
    {"Database/Corrections/classicNPCFixes.lua","QuestieNPCFixes"},
    {"Database/Corrections/tbcNPCFixes.lua","QuestieTBCNpcFixes"},
    {"Database/Corrections/wotlkNPCFixes.lua","QuestieWotlkNpcFixes"},
}
for _,pair in ipairs(sources) do
    assert(loadfile(pair[1]))()
end
assert(loadfile("Database/Wotlk/wotlkNpcDB.lua"))()
local encodedBase=assert(db.npcData)
assert(type(encodedBase)=="string","PUBLIC_NPC_BASE_FORMAT_CHANGED")
local function newBase()
    local decode=(loadstring or load)(encodedBase,"=nq_public_npc_base")
    assert(decode,"PUBLIC_NPC_BASE_DECODE_FAILED")
    local ok,value=pcall(decode)
    assert(ok and type(value)=="table","PUBLIC_NPC_BASE_EVAL_FAILED")
    return value
end
local function classify(v)
    if type(v)~="table" then return "malformed" end
    if next(v)==nil then return "empty" end
    local n,wrong,bad=0,false,false
    for k,value in pairs(v) do
        n=n+1
        if type(k)~="number" or k%1~=0 or k<1 or k>255 or n>255 then
            bad=true
        elseif k~=n then
            wrong=true
        end
        if type(value)~="number" or value~=value or value%1~=0
            or value<0 or value>16777215 then
            bad=true
        end
    end
    if n>255 then bad=true end
    for i=1,n do if v[i]==nil then bad=true;break end end
    if bad then return "malformed" end
    return wrong and "reordered" or "ordered"
end
local function effective(row,over,key)
    if over and over[key]~=nil then return over[key],true end
    return row and row[key],false
end
local function apply(base,corrections)
    assert(type(corrections)=="table","PUBLIC_NPC_PATCH_SOURCE_INVALID")
    local writes=0
    for id,row in pairs(corrections) do
        assert(type(id)=="number" and type(row)=="table",
            "PUBLIC_NPC_PATCH_RECORD_INVALID")
        if not base[id] then base[id]={} end
        for key,value in pairs(row) do
            base[id][key]=value
            writes=writes+1
        end
    end
    return writes
end
local function mergeOverrides(target,update)
    assert(type(update)=="table","PUBLIC_NPC_FACTION_SOURCE_INVALID")
    local writes=0
    for id,row in pairs(update) do
        assert(type(id)=="number" and type(row)=="table",
            "PUBLIC_NPC_FACTION_RECORD_INVALID")
        if not target[id] then target[id]={} end
        for key,value in pairs(row) do
            target[id][key]=value
            writes=writes+1
        end
    end
    return writes
end
local function extraRows(base,overrides,visit)
    local n=0
    for id,row in pairs(overrides) do
        if base[id]==nil then n=n+1;visit(row) end
    end
    return n
end
-- Purely fictional positive and negative witnesses, never owner mappings.
local orderCases={
    {{3,4},"ordered"},
    {{[4]=4,[3]=3,[2]=2,[1]=1},"reordered"},
    {{[1]=3,[3]=4},"malformed"},
    {{[1]=-1},"malformed"},
    {{[1]=16777216},"malformed"},
    {{}, "empty"},
}
for _,pair in ipairs(orderCases) do
    assert(classify(pair[1])==pair[2],"PUBLIC_NPC_CLASSIFIER_CONTROL_FAILED")
end
local sampleBase={[1]={5,6}}
local sampleOver={[1]={}}
local picked,fromOver=effective(sampleBase,sampleOver,1)
assert(fromOver and picked==sampleOver[1] and next(picked)==nil,
    "PUBLIC_NPC_EMPTY_OVERRIDE_CONTROL_FAILED")
picked,fromOver=effective(sampleBase,{},1)
assert(not fromOver and picked==sampleBase[1],
    "PUBLIC_NPC_FALLBACK_CONTROL_FAILED")
local visits=0
local extra=extraRows({[-700]={[1]={5,6}}},{
    [-700]={[1]={1,2}},
    [-701]={[1]={}},
},function(fields)
    visits=visits+1
    local value,from=effective(nil,fields,1)
    assert(from and type(value)=="table" and next(value)==nil,
        "PUBLIC_NPC_EXTRA_CLEAR_CONTROL_FAILED")
end)
assert(extra==1 and visits==1,"PUBLIC_NPC_EXTRA_ROW_CONTROL_FAILED")
print("PUBLIC NPC CORRECTION CONTROLS: 10/10 PASS")
local compilerTypes=assert(db.npcCompilerTypes)
local keys=assert(db.npcKeys)
local seen={questStarts=false,questEnds=false}
for _,faction in ipairs({"Alliance","Horde"}) do
    UnitFactionGroup=function() return faction end
    local base=newBase()
    local writes,autoWrites,factionWrites=0,0,0
    for i=1,2 do
        local obj=QuestieLoader:ImportModule(sources[i][2])
        writes=writes+apply(base,assert(obj:Load()))
    end
    local wotlk=QuestieLoader:ImportModule(sources[3][2])
    autoWrites=apply(base,assert(wotlk:LoadAutomatics()))
    writes=writes+apply(base,assert(wotlk:Load()))
    local overrides={}
    for _,source in ipairs(sources) do
        local obj=QuestieLoader:ImportModule(source[2])
        factionWrites=factionWrites+mergeOverrides(overrides,
            assert(obj:LoadFactionFixes()))
    end
    local stats={ordered=0,reordered=0,malformed=0,empty=0}
    local rows,fields,overrideFields=0,0,0
    local function readRecord(record,over)
        for field,typ in pairs(compilerTypes) do
            if typ=="u8u24array" then
                assert(field=="questStarts" or field=="questEnds",
                    "PUBLIC_NPC_COMPILER_SCHEMA_DRIFT")
                seen[field]=true
                local value,fromOver=effective(record,over,keys[field])
                if fromOver then overrideFields=overrideFields+1 end
                if value~=nil then
                    fields=fields+1
                    local result=classify(value)
                    stats[result]=stats[result]+1
                end
            end
        end
    end
    for id,row in pairs(base) do
        rows=rows+1
        readRecord(row,overrides[id])
    end
    local nExtra=extraRows(base,overrides,function(over)
        readRecord(nil,over)
    end)
    rows=rows+nExtra
    assert(writes>0 and autoWrites>0 and factionWrites>0 and fields>0,
        "PUBLIC_NPC_CORRECTION_LAYERS_NOT_EXERCISED")
    assert(fields==stats.ordered+stats.reordered+stats.malformed+stats.empty,
        "PUBLIC_NPC_AUDIT_ACCOUNTING_FAILED")
    print(string.format("PUBLIC WOTLK NPC CORRECTED faction=%s rows=%d simple_fields=%d ordered=%d reordered_dense=%d malformed=%d intentional_empty=%d patch_writes=%d auto_writes=%d faction_writes=%d override_fields=%d override_only_rows=%d",
        faction,rows,fields,stats.ordered,stats.reordered,stats.malformed,
        stats.empty,writes,autoWrites,factionWrites,overrideFields,nExtra))
    assert(stats.reordered==0 and stats.malformed==0,
        "PUBLIC_NPC_CORRECTION_ORDER_BLOCKER")
    collectgarbage("collect")
end
assert(seen.questStarts and seen.questEnds,
    "PUBLIC_NPC_SIMPLE_FIELDS_NOT_AUDITED")
print("PUBLIC NPC CORRECTION AUDIT COMPLETE (both factions)")
print("SCOPE LIMIT: WotLK NPC public base plus Classic/TBC/WotLK manual and WotLK automatic NPC fixes; simple questStarts/questEnds only.")
print("NOT ACCEPTED: full effective four-kind sources, waypoint/spawnlist, derived faction updates, Compat/unknown writers, Stage1 or client.")
