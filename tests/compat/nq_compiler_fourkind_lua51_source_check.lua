-- CS01 standalone actual-source four-kind binary compiler characterization.
-- NEVER run against a WoW profile or SavedVariables: fictional tables only.
tremove = tremove or table.remove
unpack = unpack or table.unpack
local function band(a,b)
  a,b=a%4294967296,b%4294967296
  local n,p=0,1
  for i=1,32 do
    if a%2==1 and b%2==1 then n=n+p end
    a,b,p=math.floor(a/2),math.floor(b/2),p*2
  end
  return n
end
bit={band=band,lshift=function(n,s) return (n*2^s)%4294967296 end,
     rshift=function(n,s) return math.floor((n%4294967296)/2^s) end}
QuestieLoader={}
local modules={}
function QuestieLoader:CreateModule(k)
  assert(not modules[k],"duplicate module "..k)
  modules[k]={};return modules[k]
end
function QuestieLoader:ImportModule(k)
  assert(modules[k],"missing module "..k);return modules[k]
end
for _,name in ipairs({"QuestieDB","QuestieLib","l10n"}) do
  QuestieLoader:CreateModule(name)
end
QuestieCompat={WOW_PROJECT_ID=2,Is335=true}
Questie={IsSoD=false,IsWotlk=true,IsTBC=false,
        db={global={},profile={debugEnabled=false}}}
local errors={}
function Questie:Error(...) errors[#errors+1]=table.concat({...}," ") end
GetTime=function() return 123.5 end
local lib=QuestieLoader:ImportModule("QuestieLib")
function lib:GetAddonVersionString()return "test-version" end
local localize=QuestieLoader:ImportModule("l10n")
function localize:GetUILocale() return "enUS" end
setmetatable(localize,{__call=function(_,message)return message end})
local function load(path)
  local fn,err=loadfile(path)
  assert(fn,"cannot load pinned source "..path..": "..tostring(err))
  fn()
end
load("Modules/QuestieStream.lua")
for _,kind in ipairs({"npc","object","quest","item"}) do
  load("Database/"..kind.."DB.lua")
end
load("Database/compiler.lua")
local db=QuestieLoader:ImportModule("QuestieDB")
local compiler=QuestieLoader:ImportModule("DBCompiler")
local kinds={
  {"npc","npcData","npcKeys","npcCompilerTypes","npcCompilerOrder",101},
  {"obj","objectData","objectKeys","objectCompilerTypes","objectCompilerOrder",201},
  {"quest","questData","questKeys","questCompilerTypes","questCompilerOrder",301},
  {"item","itemData","itemKeys","itemCompilerTypes","itemCompilerOrder",401},
}
-- Object category source is named objectData; all others use their prefix.
local function fixture()
  local nk,ok,qk,ik=db.npcKeys,db.objectKeys,db.questKeys,db.itemKeys
  db.npcData={[101]={[nk.name]="Synthetic NPC",
      [nk.minLevel]=12,[nk.questStarts]={301},
      [nk.spawns]={[141]={{-1,-1}}}}}
  db.objectData={[201]={[ok.name]="Synthetic Object",
      [ok.zoneID]=141,[ok.questStarts]={301}}}
  db.questData={[301]={[qk.name]="Synthetic Quest",
      [qk.requiredLevel]=11,[qk.questLevel]=13,
      [qk.startedBy]={{101},{201}},[qk.finishedBy]={{101}}}}
  db.itemData={[401]={[ik.name]="Synthetic Item",
      [ik.startQuest]=301,[ik.npcDrops]={101},[ik.objectDrops]={201}}}
end
local function drive(fn)
  local thread=coroutine.create(fn)
  for i=1,256 do
    local ok,returned=coroutine.resume(thread)
    assert(ok,returned)
    if coroutine.status(thread)=="dead" then return returned, i end
  end
  error("coroutine exceeded 256 resume steps")
end
local passes=0
local function check(label,fn)
  local ok,err=pcall(fn)
  if not ok then io.stderr:write("FAIL "..label..": "..tostring(err).."\n");os.exit(1) end
  passes=passes+1
  print("PASS FOURKIND "..label)
end
fixture()
drive(function()compiler:Compile()end)
check("all_four_published_binary_and_ptr_pairs",function()
  for _,kind in ipairs(kinds) do
    local k=kind[1]
    assert(type(Questie.db.global[k.."Bin"])=="string" and
      #Questie.db.global[k.."Bin"]>0,k.." binary absent")
    assert(type(Questie.db.global[k.."Ptrs"])=="string" and
      #Questie.db.global[k.."Ptrs"]>0,k.." pointer map absent")
  end
end)
check("compile_metadata_only_after_success",function()
  local g=Questie.db.global
  assert(g.dbIsCompiled==true and g.dbCompiledCount==1)
  assert(g.dbCompiledLang=="enUS" and g.dbCompiledOnVersion=="test-version")
  assert(g.dbCompiledExpansion==2)
end)
-- Characterization of original pinned compiler, not desired production behaviour.
check("successful_compile_lock_blocks_second_attempt",function()
  local g=Questie.db.global
  assert(compiler._isCompiling==true,"expected original persistent lock")
  -- Exact binary equality is a weak oracle for deterministic recompilation.
  -- Use a deliberate sentinel, then restore the genuine compiled bytes for
  -- subsequent real decoder tests. Busy must return BEFORE its first yield.
  local originalBin,beforeCount=g.npcBin,g.dbCompiledCount
  g.npcBin="LOCKED_SENTINEL"
  local result,steps=drive(function()return compiler:Compile()end)
  assert(steps==1,"locked compilation unexpectedly yielded")
  assert(result==nil and g.npcBin=="LOCKED_SENTINEL" and
    g.dbCompiledCount==beforeCount,"locked compilation changed saved outputs")
  g.npcBin=originalBin
end)
for _,kind in ipairs(kinds) do
  local k,data,keys,types,order,id=unpack(kind)
  check(k.."_actual_pointer_and_unmasked_reader",function()
    local g=Questie.db.global
    local handle=drive(function()
      return compiler:GetDBHandle(g[k.."Bin"],g[k.."Ptrs"],
        compiler:BuildSkipMap(db[types],db[order]),db[keys],nil)
    end)
    assert(type(handle)=="table" and handle.pointers[id]==1,
      k.." pointer invalid")
    assert(type(handle.QuerySingle)=="function")
    local name=handle.QuerySingle(id,"name")
    assert(type(name)=="string" and name:match("^Synthetic"),
      k.." decoded name mismatch")
    assert(handle.QuerySingle(id+12345,"name")==nil)
    if k=="npc" then
      assert(handle.QuerySingle(id,"minLevel")==12)
      assert(handle.QuerySingle(id,"questStarts")[1]==301)
    elseif k=="obj" then
      assert(handle.QuerySingle(id,"zoneID")==141)
      assert(handle.QuerySingle(id,"questStarts")[1]==301)
    elseif k=="quest" then
      assert(handle.QuerySingle(id,"questLevel")==13)
      assert(handle.QuerySingle(id,"startedBy")[1][1]==101)
      assert(handle.QuerySingle(id,"startedBy")[2][1]==201)
    elseif k=="item" then
      assert(handle.QuerySingle(id,"startQuest")==301)
      assert(handle.QuerySingle(id,"npcDrops")[1]==101)
    end
    handle.stream:finished()
  end)
end
-- Characterization ONLY: current pinned source publishes some pairs and then
-- advances metadata even after an invalid quest datatype normal return.
check("invalid_quest_characterizes_nonfatal_partial_publication",function()
  errors={}
  Questie.db.global={}
  for _,kind in ipairs(kinds) do
    local key=kind[1]
    Questie.db.global[key.."Bin"]="BEFORE_"..key
    Questie.db.global[key.."Ptrs"]="OLDPTR_"..key
  end
  fixture()
  db.questData[301][db.questKeys.questLevel]="BAD_TYPE"
  compiler._isCompiling=false -- reset isolated fixture's one-shot guard only
  drive(function()compiler:Compile()end)
  local g=Questie.db.global
  assert(#errors>0,"expected original nonfatal invalid-datatype signal")
  assert(g.questBin=="BEFORE_quest" and g.questPtrs=="OLDPTR_quest",
    "invalid quest table unexpectedly published")
  assert(g.npcBin~="BEFORE_npc" and g.itemBin~="BEFORE_item",
    "characterization missing partial cross-kind publication")
  assert(g.dbIsCompiled==true and g.dbCompiledCount==1,
    "characterization missing current false success metadata")
end)
-- Even after invalid quest data is repaired, the original compiler lock persists.
check("failed_compile_lock_blocks_valid_retry",function()
  local g=Questie.db.global
  assert(compiler._isCompiling==true,"expected original failed-run lock")
  db.questData[301][db.questKeys.questLevel]=13
  local oldBin,oldCount=g.questBin,g.dbCompiledCount
  local result,steps=drive(function()return compiler:Compile()end)
  assert(steps==1,"failed-run lock unexpectedly yielded on retry")
  assert(result==nil and g.questBin==oldBin and g.dbCompiledCount==oldCount,
    "original compiler unexpectedly retried repaired data")
end)
check("busy_guard_returns_without_compiling",function()
  local before=Questie.db.global.npcBin
  compiler._isCompiling=true
  local result,steps=drive(function()return compiler:Compile()end)
  assert(steps==1 and result==nil and Questie.db.global.npcBin==before)
end)
assert(passes==10,"expected exactly 10 checks, got "..passes)
print("FOURKIND SOURCE RESULT: 10/10 PASS")
