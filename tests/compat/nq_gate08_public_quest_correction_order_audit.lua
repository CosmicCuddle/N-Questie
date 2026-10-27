-- N-Questie Part39 PUBLIC WotLK QUEST simple compound correction-order audit.
-- Aggregate-only read-only TEST fixture: never log quest IDs, source records,
-- owner-private relationships, strings, SQL, loot, class/IP mappings or tokens.
-- Source order checked against QuestieCorrections:Initialize/MinimalInit.
-- Out of scope: client, native compiler, 335 Compat.LoadCorrections, derived
-- requiredRaces, unknown late writers and complex questgiver/objective codecs.
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
QuestieCompat={Is335=true,WOW_PROJECT_ID=2,WOW_PROJECT_WRATH_CLASSIC=2,
    WOW_PROJECT_CLASSIC=1}
local db=QuestieLoader:CreateModule("QuestieDB")
local zone=QuestieLoader:CreateModule("ZoneDB")
local corrections=QuestieLoader:CreateModule("QuestieCorrections")
corrections.killCreditObjectiveFirst={}
QuestieLoader:CreateModule("QuestieQuest")
-- Questie quest fixes call l10n() for *excluded complex extraObjectives*.
-- Keep the caller's public text unchanged in this headless audit, without
-- importing client locale systems; no strings are inspected or printed.
local l10n=QuestieLoader:CreateModule("l10n")
setmetatable(l10n,{__call=function(_,publicText)
    assert(type(publicText)=="string","PUBLIC_QUEST_L10N_ARG_CHANGED")
    return publicText
end})
assert(loadfile("Database/questDB.lua"))()
assert(loadfile("Database/Zones/zoneTables.lua"))()
zone.zoneIDs=assert(zone.private.zoneIDs)
-- Do not copy or invent enum constants. Isolate the real declared tables
-- from the public QuestieDB.lua source without loading its runtime/client.
local function loadPublicEnums()
    local f=assert(io.open("Database/QuestieDB.lua","rb"))
    local source=assert(f:read("*a"));f:close()
    local race=assert(source:match("QuestieDB%.raceKeys%s*=%s*%b{}"),
        "PUBLIC_QUEST_RACE_ENUM_NOT_FOUND")
    local class=assert(source:match("QuestieDB%.classKeys%s*=%s*%b{}"),
        "PUBLIC_QUEST_CLASS_ENUM_NOT_FOUND")
    local text="local QuestieDB=...;local VANILLA=false\n"..race.."\n"..class
    local ctor=assert((loadstring or load)(text,"=public_quest_enums"))
    ctor(db)
    assert(db.raceKeys and db.classKeys and db.raceKeys.ALL_ALLIANCE==1101,
        "PUBLIC_QUEST_WRATH_ENUM_CHANGED")
end
loadPublicEnums()
assert(loadfile("Database/Constants.lua"))()
assert(db.sortKeys and db.questFlags and db.factionIDs,
    "PUBLIC_QUEST_SCHEMA_ENUM_MISSING")
-- QuestieProfessions.lua installs client hooks at top level; invoking it
-- in headless CI is invalid. Extract JUST the genuine public enum tables.
local function loadPublicProfessions()
    local f=assert(io.open("Modules/QuestieProfessions.lua","rb"))
    local source=assert(f:read("*a"));f:close()
    local keys=assert(source:match("QuestieProfessions%.professionKeys%s*=%s*%b{}"),
        "PUBLIC_QUEST_PROFESSION_ENUM_SOURCE_MISSING")
    local specialization=assert(source:match(
        "QuestieProfessions%.specializationKeys%s*=%s*%b{}"),
        "PUBLIC_QUEST_SPECIALIZATION_ENUM_SOURCE_MISSING")
    local sourceEnums="local QuestieProfessions=...\n"..keys.."\n"..specialization
    local ctor=assert((loadstring or load)(sourceEnums,
        "=public_quest_profession_enums"))
    local prof=QuestieLoader:CreateModule("QuestieProfessions")
    ctor(prof)
    assert(prof.professionKeys and prof.specializationKeys
        and prof.professionKeys.MINING==186,
        "PUBLIC_QUEST_PROFESSION_ENUM_MISSING")
end
loadPublicProfessions()
local sources={
    {"Database/Corrections/classicQuestFixes.lua","QuestieQuestFixes"},
    {"Database/Corrections/tbcQuestFixes.lua","QuestieTBCQuestFixes"},
    {"Database/Corrections/wotlkQuestFixes.lua","QuestieWotlkQuestFixes"},
}
assert(loadfile("Database/Corrections/Automatic/classicQuestReputationFixes.lua"))()
for _,pair in ipairs(sources) do
    assert(loadfile(pair[1]))()
end
assert(loadfile("Database/Wotlk/wotlkQuestDB.lua"))()
local encodedBase=assert(db.questData)
assert(type(encodedBase)=="string","PUBLIC_QUEST_BASE_FORMAT_CHANGED")
local function newBase()
    local decode=assert((loadstring or load)(encodedBase,"=public_quest_base"),
        "PUBLIC_QUEST_BASE_DECODE_FAILED")
    local ok,value=pcall(decode)
    assert(ok and type(value)=="table","PUBLIC_QUEST_BASE_EVAL_FAILED")
    return value
end
local specs={
    u8u24array={mode="array",lo=0,hi=16777215,max=255},
    u12pair={mode="pair",lo=0,hi=4095},
    s24pair={mode="pair",lo=-8388608,hi=8388607},
    u8s24pairs={mode="pairs",lo=-8388608,hi=8388607,max=255},
}
local function integral(v,lo,hi)
    return type(v)=="number" and v==v and v%1==0 and v>=lo and v<=hi
end
local function validPair(v,spec)
    if type(v)~="table" then return false end
    local n=0
    for k,value in pairs(v) do
        n=n+1
        if (k~=1 and k~=2) or not integral(value,spec.lo,spec.hi) then
            return false
        end
    end
    return n==2 and v[1]~=nil and v[2]~=nil
end
local function classify(value,kind)
    local spec=assert(specs[kind],"PUBLIC_QUEST_KIND_UNKNOWN")
    if type(value)~="table" then return "malformed" end
    if next(value)==nil then return "empty" end
    if spec.mode=="pair" then
        return validPair(value,spec) and "ordered" or "malformed"
    end
    local count,wrong,bad=0,false,false
    for k,v in pairs(value) do
        count=count+1
        if type(k)~="number" or k%1~=0 or k<1 or k>spec.max
            or count>spec.max then
            bad=true
        elseif k~=count then
            wrong=true
        end
        if spec.mode=="array" then
            if not integral(v,spec.lo,spec.hi) then bad=true end
        elseif not validPair(v,spec) then
            bad=true
        end
    end
    if count>spec.max then bad=true end
    for i=1,count do if value[i]==nil then bad=true;break end end
    if bad then return "malformed" end
    return wrong and "reordered" or "ordered"
end
local function effective(record,over,key)
    if over and over[key]~=nil then return over[key],true end
    return record and record[key],false
end
local function merge(base,patches)
    assert(type(patches)=="table","PUBLIC_QUEST_PATCH_INVALID")
    local writes=0
    for id,fields in pairs(patches) do
        assert(type(id)=="number" and type(fields)=="table",
            "PUBLIC_QUEST_PATCH_ROW_INVALID")
        if base[id]==nil then base[id]={} end
        for key,value in pairs(fields) do
            base[id][key]=value;writes=writes+1
        end
    end
    return writes
end
local function mergeOverrides(overrides,patch)
    assert(type(patch)=="table","PUBLIC_QUEST_FACTION_PATCH_INVALID")
    local writes=0
    for id,fields in pairs(patch) do
        assert(type(id)=="number" and type(fields)=="table",
            "PUBLIC_QUEST_FACTION_ROW_INVALID")
        if overrides[id]==nil then overrides[id]={} end
        for key,v in pairs(fields) do
            overrides[id][key]=v;writes=writes+1
        end
    end
    return writes
end
local function extraRows(base,overrides,visitor)
    local count=0
    for id,row in pairs(overrides) do
        if base[id]==nil then count=count+1;visitor(row) end
    end
    return count
end
-- Entirely invented controls. Pair-arities, empties and numeric hash ordering
-- must be sensitive on both 5.1 and 5.4 before surveying actual public tables.
local controls={
    {"u8u24array",{1,2,3},"ordered"},
    {"u8u24array",{[4]=4,[3]=3,[2]=2,[1]=1},"reordered"},
    {"u8u24array",{[1]=1,[3]=3},"malformed"},
    {"u8u24array",{},"empty"},
    {"u12pair",{12,200},"ordered"},
    {"u12pair",{4095,0},"ordered"},
    {"u12pair",{4096,0},"malformed"},
    {"s24pair",{-8388608,0},"ordered"},
    {"s24pair",{-8388609,0},"malformed"},
    {"s24pair",{8388607,0},"ordered"},
    {"s24pair",{8388608,0},"malformed"},
    {"u12pair",{[1]=0,[3]=2},"malformed"},
    {"s24pair",{1090,-500},"ordered"},
    {"s24pair",{1090,8388608},"malformed"},
    {"u8s24pairs",{{1,40},{2,-30}},"ordered"},
    {"u8s24pairs",{[4]={4,4},[3]={3,3},[2]={2,2},[1]={1,1}},"reordered"},
    {"u8s24pairs",{{1}},"malformed"},
}
for _,row in ipairs(controls) do
    assert(classify(row[2],row[1])==row[3],
        "PUBLIC_QUEST_COMPOUND_CONTROL_FAILED")
end
local fakeBase={[1]={12,15}}
local fakeOver={[1]={}}
local v,fromOver=effective(fakeBase,fakeOver,1)
assert(fromOver and v==fakeOver[1] and next(v)==nil,
    "PUBLIC_QUEST_OVERRIDE_CLEAR_CONTROL_FAILED")
v,fromOver=effective(fakeBase,{},1)
assert(not fromOver and v==fakeBase[1],
    "PUBLIC_QUEST_OVERRIDE_FALLBACK_CONTROL_FAILED")
local visits=0
local count=extraRows({[-800]={[1]={10}}},{
    [-800]={[1]={11}},[-801]={[1]={}},
},function(row)
    visits=visits+1
    local item,isOver=effective(nil,row,1)
    assert(isOver and type(item)=="table" and next(item)==nil,
        "PUBLIC_QUEST_OVERRIDE_ONLY_CLEAR_FAILED")
end)
assert(count==1 and visits==1,"PUBLIC_QUEST_OVERRIDE_ONLY_COUNT_FAILED")
print("PUBLIC QUEST COMPOUND CONTROLS: 20/20 PASS")
local keys=assert(db.questKeys)
local schema=assert(db.questCompilerTypes)
local explored={}

-- PUBLIC TEST-ONLY sorted source-value witness. Never print IDs, relationships
-- or values. Two bounded polynomial hashes are deterministic across Lua 5.1/5.4;
-- collision remains possible: NOT an authenticated source/ABA guard.
local function sortedKeys(t)
    local out={}
    for key in pairs(t) do out[#out+1]=key end
    table.sort(out)
    return out
end
local function valueDigest(base,overrides,fieldKinds,keys)
    local a,b=0,0
    local function feed(s)
        s=tostring(s)
        local block=tostring(#s)..":"..s..";"
        for i=1,#block do
            local v=string.byte(block,i)
            a=(a*131+v)%1000000007
            b=(b*137+v)%1000000009
        end
    end
    local ids={}
    for id in pairs(base) do ids[id]=true end
    for id in pairs(overrides) do ids[id]=true end
    local names=sortedKeys(fieldKinds)
    for _,id in ipairs(sortedKeys(ids)) do
        for _,name in ipairs(names) do
            local kind=fieldKinds[name]
            local v=effective(base[id],overrides[id],keys[name])
            if v~=nil then
                local status=classify(v,kind)
                assert(status=="ordered" or status=="empty",
                    "PUBLIC_VALUE_DIGEST_INVALID_COMPOUND")
                feed(string.format("%.0f",id))
                feed(name);feed(kind);feed(status)
                if status=="ordered" then
                    if kind=="u8u24array" then
                        feed(#v)
                        for i=1,#v do feed(string.format("%.0f",v[i])) end
                    elseif kind=="u8s24pairs" then
                        feed(#v)
                        for i=1,#v do
                            feed(string.format("%.0f",v[i][1]))
                            feed(string.format("%.0f",v[i][2]))
                        end
                    else
                        feed(2)
                        feed(string.format("%.0f",v[1]))
                        feed(string.format("%.0f",v[2]))
                    end
                end
            end
        end
    end
    return string.format("%09d-%09d",a,b)
end

for _,faction in ipairs({"Alliance","Horde"}) do
    UnitFactionGroup=function() return faction end
    db.questData=newBase()
    local beforeMissing=0
    for _ in pairs(db.questData) do beforeMissing=beforeMissing+1 end
    local classic=QuestieLoader:ImportModule("QuestieQuestFixes")
    local tbc=QuestieLoader:ImportModule("QuestieTBCQuestFixes")
    local wotlk=QuestieLoader:ImportModule("QuestieWotlkQuestFixes")
    classic:LoadMissingQuests()
    local writes=0
    local rep=QuestieLoader:ImportModule("QuestieClassicQuestReputationFixes")
    local reputationWrites=merge(db.questData,assert(rep:Load()))
    writes=writes+merge(db.questData,assert(classic:Load()))
    writes=writes+merge(db.questData,assert(tbc:Load()))
    writes=writes+merge(db.questData,assert(wotlk:Load()))
    local overrides={}
    local overrideWrites=mergeOverrides(overrides,assert(classic:LoadFactionFixes()))
    overrideWrites=overrideWrites+mergeOverrides(overrides,assert(tbc:LoadFactionFixes()))
    local stats={ordered=0,reordered=0,malformed=0,empty=0}
    local typeCounts={u8u24array=0,u12pair=0,s24pair=0,u8s24pairs=0}
    local rows,fields,overrideFields=0,0,0
    local function audit(record,over)
        for name,kind in pairs(schema) do
            if specs[kind] then
                explored[kind]=true
                local value,isOver=effective(record,over,keys[name])
                if isOver then overrideFields=overrideFields+1 end
                if value~=nil then
                    fields=fields+1
                    typeCounts[kind]=typeCounts[kind]+1
                    local state=classify(value,kind)
                    stats[state]=stats[state]+1
                end
            end
        end
    end
    for id,record in pairs(db.questData) do
        rows=rows+1
        audit(record,overrides[id])
    end
    local extra=extraRows(db.questData,overrides,function(over) audit(nil,over) end)
    rows=rows+extra
    assert(writes>0 and reputationWrites>0 and overrideWrites>0,
        "PUBLIC_QUEST_CORRECTION_LAYER_NOT_EXERCISED")
    assert(rows>=beforeMissing and fields>0 and
        fields==stats.ordered+stats.reordered+stats.malformed+stats.empty,
        "PUBLIC_QUEST_ACCOUNTING_FAILED")
    print(string.format("PUBLIC WOTLK QUEST CORRECTED faction=%s rows=%d simple_fields=%d ordered=%d reordered_dense=%d malformed=%d intentional_empty=%d manual_writes=%d reputation_writes=%d faction_writes=%d override_fields=%d override_only_rows=%d arrays=%d u12pairs=%d s24pairs=%d reward_pairs=%d",
        faction,rows,fields,stats.ordered,stats.reordered,stats.malformed,
        stats.empty,writes,reputationWrites,overrideWrites,overrideFields,extra,
        typeCounts.u8u24array,typeCounts.u12pair,typeCounts.s24pair,
        typeCounts.u8s24pairs))
    assert(stats.reordered==0 and stats.malformed==0,
        "PUBLIC_QUEST_COMPOUND_ORDER_BLOCKER")
    -- Freeze the observed PUBLIC correction snapshot; any count drift is a
    -- reviewable failure, not an automatic assertion of data corruption.
    local horde=(faction=="Horde")
    assert(rows==9158 and fields==(horde and 15267 or 15266)
        and stats.ordered==(horde and 13361 or 13360)
        and stats.empty==1906 and writes==7603
        and reputationWrites==4254 and overrideWrites==(horde and 24 or 23)
        and overrideFields==(horde and 1 or 0) and extra==0
        and typeCounts.u8u24array==(horde and 7359 or 7358)
        and typeCounts.u12pair==260 and typeCounts.s24pair==715
        and typeCounts.u8s24pairs==6933,
        "PUBLIC_QUEST_CORRECTION_LAYER_SNAPSHOT_CHANGED")
    local digestFields={}
    for name,kind in pairs(schema) do
        if specs[kind] then digestFields[name]=kind end
    end
    local digest=valueDigest(db.questData,overrides,digestFields,keys)
    local expectedDigest={Alliance="043054440-899980232",Horde="429450508-289752222"}
    assert(digest==expectedDigest[faction],
        "PUBLIC_QUEST_VALUE_DIGEST_SNAPSHOT_CHANGED")
    print("PUBLIC WOTLK QUEST VALUE DIGEST faction="..faction.." digest="..digest)
    db.questData=nil
    collectgarbage("collect")
end
for typ in pairs(specs) do
    assert(explored[typ],"PUBLIC_QUEST_SIMPLE_TYPE_NOT_AUDITED")
end
print("PUBLIC QUEST CORRECTION AUDIT COMPLETE (both factions)")
print("SCOPE LIMIT: WotLK public quest base and Classic reputation, Classic/TBC/WotLK quest corrections and two faction views, four simple compound families only.")
print("NOT ACCEPTED: full QuestieCorrections derived patches, complex questgiver/objectives/trigger/string, 335 Compat, native compiler/Stage1/client.")
