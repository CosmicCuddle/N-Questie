-- Gate08 Part36: actual pinned Questie four-kind compiler stage seam.
-- Fictional records only; no WoW client, private SQL, source ownership, or IP.
-- This verifies local staging, NOT an all-eight-field commit/stream recovery.
unpack = unpack or table.unpack
tremove = table.remove
local function band(a,b)
    local result,place=0,1
    for _=1,32 do
        if a%2==1 and b%2==1 then result=result+place end
        a,b,place=math.floor(a/2),math.floor(b/2),place*2
    end
    return result
end
bit={
    band=band,
    lshift=function(n,s) return (n*2^s)%4294967296 end,
    rshift=function(n,s) return math.floor((n%4294967296)/2^s) end,
}
local modules={}
QuestieLoader={
    CreateModule=function(_,name)
        modules[name]=modules[name] or {}
        return modules[name]
    end,
    ImportModule=function(_,name)
        assert(modules[name],"missing Questie module "..name)
        return modules[name]
    end,
}
for _,kind in ipairs({"QuestieDB","QuestieLib","l10n"}) do QuestieLoader:CreateModule(kind) end
QuestieCompat={Is335=true,WOW_PROJECT_ID=2}
Questie={
    IsSoD=false,IsTBC=false,IsWotlk=true,
    db={profile={debugEnabled=false},global={}},
    Error=function(_,...) error("synthetic Questie error: "..tostring((...)),0) end,
    Debug=function()end,
}
assert(loadfile("Modules/QuestieStream.lua"))()
for _,file in ipairs({"npcDB","objectDB","questDB","itemDB"}) do
    assert(loadfile("Database/"..file..".lua"))()
end
assert(loadfile("Database/compiler.lua"))()
local db=QuestieLoader:ImportModule("QuestieDB")
local compiler=QuestieLoader:ImportModule("DBCompiler")
db.npcData={[77101]={[db.npcKeys.name]="Invented NPC"}}
db.objectData={[77201]={[db.objectKeys.name]="Invented Object"}}
db.questData={[77301]={[db.questKeys.name]="Invented Quest"}}
db.itemData={[77401]={[db.itemKeys.name]="Invented Item"}}
local categories={
    {kind="npc",fn="CompileNPCs",id=77101,tableKeys="npcKeys",
        schema="npc",name="Invented NPC"},
    {kind="obj",fn="CompileObjects",id=77201,tableKeys="objectKeys",
        schema="object",name="Invented Object"},
    {kind="quest",fn="CompileQuests",id=77301,tableKeys="questKeys",
        schema="quest",name="Invented Quest"},
    {kind="item",fn="CompileItems",id=77401,tableKeys="itemKeys",
        schema="item",name="Invented Item"},
}
local saved=Questie.db.global
for _,entry in ipairs(categories) do
    saved[entry.kind.."Bin"]="OLD_BIN_"..entry.kind
    saved[entry.kind.."Ptrs"]="OLD_PTRS_"..entry.kind
end
saved.nQuestieDataRevision=57
saved.dbIsCompiled=true
saved.dbCompiledCount=9
local tests=0
local function check(label,ok)
    tests=tests+1
    assert(ok,"FAIL GATE08 STAGE "..tests.." "..label)
    print("PASS GATE08 STAGE "..tests.." "..label)
end
local function drive(fn)
    local thread=coroutine.create(fn)
    for _=1,256 do
        local ok,result=coroutine.resume(thread)
        assert(ok,tostring(result))
        if coroutine.status(thread)=="dead" then return result end
    end
    error("Gate08 synthetic compiler coroutine exceeded 256 resumes")
end
check("actual source compiler wrappers exposed",type(compiler.CompileNPCs)=="function"
    and type(compiler.CompileObjects)=="function"
    and type(compiler.CompileQuests)=="function"
    and type(compiler.CompileItems)=="function")
local stage={}
for _,entry in ipairs(categories) do
    local prefix=entry.kind
    drive(function() return compiler[entry.fn](compiler,stage) end)
    check(prefix.." staged real nonempty bytes and pointer map",
        type(stage[prefix.."Bin"])=="string" and #stage[prefix.."Bin"]>0
        and type(stage[prefix.."Ptrs"])=="string" and #stage[prefix.."Ptrs"]>0)
    check(prefix.." live pair and revision stayed untouched",
        saved[prefix.."Bin"]=="OLD_BIN_"..prefix
        and saved[prefix.."Ptrs"]=="OLD_PTRS_"..prefix
        and saved.nQuestieDataRevision==57 and saved.dbCompiledCount==9)
    local handle=drive(function()
        return compiler:GetDBHandle(stage[prefix.."Bin"],stage[prefix.."Ptrs"],
            compiler:BuildSkipMap(db[entry.schema.."CompilerTypes"],
                db[entry.schema.."CompilerOrder"]),db[entry.tableKeys],nil)
    end)
    check(prefix.." real reader returns original synthetic name",
        handle.QuerySingle(entry.id,"name")==entry.name)
    handle.stream:finished()
end
local keys=0
for _,entry in ipairs(categories) do
    if type(stage[entry.kind.."Bin"])=="string" then keys=keys+1 end
    if type(stage[entry.kind.."Ptrs"])=="string" then keys=keys+1 end
end
check("exact eight distinct fields staged without publication",keys==8)
drive(function()compiler:CompileNPCs()end)
check("legacy no-stage NPC compiler still writes SavedVariables",
    type(saved.npcBin)=="string" and saved.npcBin~="OLD_BIN_npc"
    and type(saved.npcPtrs)=="string" and saved.npcPtrs~="OLD_PTRS_npc")
local okBadStage=pcall(function()
    drive(function() compiler:CompileObjects("not a staging table") end)
end)
check("invalid stage object is rejected before publication",not okBadStage)
db.itemData={[77401]={[db.itemKeys.name]={99}}}
local failingStage={}
local okBadCodec=pcall(function()
    drive(function()compiler:CompileItems(failingStage)end)
end)
check("malformed final item stage fails closed",not okBadCodec
    and failingStage.itemBin==nil and failingStage.itemPtrs==nil)
check("failed later stage cannot change previous saved fields or metadata",
    saved.itemBin=="OLD_BIN_item" and saved.itemPtrs=="OLD_PTRS_item"
    and saved.objBin=="OLD_BIN_obj" and saved.questBin=="OLD_BIN_quest"
    and saved.nQuestieDataRevision==57 and saved.dbCompiledCount==9)
assert(tests==18,"expected 18 source-backed compiler stage tests, got "..tests)
print("GATE08 SOURCE STAGING RESULT: 18/18 PASS")
print("DRAFT ONLY: no writer epoch/ABA, lease recovery, atomic commit, disk recovery or client QA")
