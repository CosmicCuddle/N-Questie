-- CS01 isolated Lua 5.1 proposal test: staged four-kind publication.
-- REAL pinned compiler/stream writer, encoder and unmasked decoder.
-- Research ONLY; this is NOT the production compiler, SavedVariables or WoW.
tremove=tremove or table.remove
unpack=unpack or table.unpack
local function band(a,b)
  a,b=a%4294967296,b%4294967296
  local n,p=0,1
  for _=1,32 do
    if a%2==1 and b%2==1 then n=n+p end
    a,b,p=math.floor(a/2),math.floor(b/2),p*2
  end
  return n
end
bit={band=band,lshift=function(n,s)return(n*2^s)%4294967296 end,
     rshift=function(n,s)return math.floor((n%4294967296)/2^s)end}
QuestieLoader={}
local modules={}
function QuestieLoader:CreateModule(k)
  assert(not modules[k],"duplicate "..k)
  modules[k]={}
  return modules[k]
end
function QuestieLoader:ImportModule(k)
  assert(modules[k],"no module "..k)
  return modules[k]
end
for _,k in ipairs({"QuestieDB","QuestieLib","l10n"})do
  QuestieLoader:CreateModule(k)
end
QuestieCompat={WOW_PROJECT_ID=2,Is335=true}
Questie={IsSoD=false,IsWotlk=true,IsTBC=false,
  db={global={},profile={debugEnabled=false}}}
function Questie:Error(...)error("Questie error in scratch")end
local function source(p)
  local f,e=loadfile(p);assert(f,e);f()
end
source("Modules/QuestieStream.lua")
for _,k in ipairs({"npc","object","quest","item"})do
  source("Database/"..k.."DB.lua")
end
source("Database/compiler.lua")
local db=QuestieLoader:ImportModule("QuestieDB")
local compiler=QuestieLoader:ImportModule("DBCompiler")
local streamMod=QuestieLoader:ImportModule("QuestieStreamLib")
local specs={
  {kind="npc",data="npcData",keys="npcKeys",types="npcCompilerTypes",order="npcCompilerOrder",id=101},
  {kind="obj",data="objectData",keys="objectKeys",types="objectCompilerTypes",order="objectCompilerOrder",id=201},
  {kind="quest",data="questData",keys="questKeys",types="questCompilerTypes",order="questCompilerOrder",id=301},
  {kind="item",data="itemData",keys="itemKeys",types="itemCompilerTypes",order="itemCompilerOrder",id=401},
}
local oldFields={
  "npcBin","npcPtrs","objBin","objPtrs",
  "questBin","questPtrs","itemBin","itemPtrs",
  "dbCompiledCount","dbIsCompiled","dbCompiledLang",
  "dbCompiledOnVersion","dbCompiledExpansion","nQuestieDataRevision"
}
local function fixtures()
  local nk,ok,qk,ik=db.npcKeys,db.objectKeys,db.questKeys,db.itemKeys
  db.npcData={[101]={[nk.name]="Synthetic NPC",[nk.minLevel]=12,
    [nk.questStarts]={301},[nk.spawns]={[141]={{-1,-1}}}}}
  db.objectData={[201]={[ok.name]="Synthetic Object",
    [ok.zoneID]=141,[ok.questStarts]={301}}}
  db.questData={[301]={[qk.name]="Synthetic Quest",
    [qk.requiredLevel]=11,[qk.questLevel]=13,
    [qk.startedBy]={{101},{201}},[qk.finishedBy]={{101}}}}
  db.itemData={[401]={[ik.name]="Synthetic Item",
    [ik.startQuest]=301,[ik.npcDrops]={101},[ik.objectDrops]={201}}}
end
local function publishOld()
  local g={}
  for _,key in ipairs(oldFields)do g[key]="OLD_"..key end
  g.dbCompiledCount=11
  g.dbIsCompiled=true
  g.nQuestieDataRevision=22
  Questie.db.global=g
end
local function assertOld(g)
  for _,key in ipairs(oldFields)do
    local want="OLD_"..key
    if key=="dbCompiledCount"then want=11 end
    if key=="dbIsCompiled"then want=true end
    if key=="nQuestieDataRevision"then want=22 end
    assert(g[key]==want,"old published field was modified: "..key)
  end
end
-- Snapshot MUST be built with no coroutine yields. This fixture rejects cycles.
local function deepCopy(v,seen)
  if type(v)~="table"then return v end
  assert(not getmetatable(v),"unexpected metatable")
  assert(not seen[v],"cycle/shared reference in toy snapshot")
  seen[v]=true
  local out={}
  for k,x in pairs(v)do out[deepCopy(k,seen)]=deepCopy(x,seen)end
  seen[v]=nil
  return out
end
local function capture()
  local out={}
  for _,s in ipairs(specs)do out[s.kind]=deepCopy(db[s.data],{})end
  return out
end
local function writeCategory(spec,source)
  local ids={}
  for id in pairs(source)do
    assert(type(id)=="number" and id==math.floor(id) and
      id>=1 and id<=16777215,"bad ID")
    ids[#ids+1]=id
  end
  table.sort(ids)
  local out=streamMod:GetStream("raw")
  local ptrs={}
  for _,id in ipairs(ids)do
    local record=source[id]
    assert(type(record)=="table","bad source entry")
    ptrs[id]=out._pointer
    for _,field in ipairs(db[spec.order])do
      local value=record[db[spec.keys][field]]
      local ty=db[spec.types][field]
      assert(type(compiler.writers[ty])=="function","missing writer")
      assert(value==nil or
        (compiler.supportedTypes[type(value)] or {})[ty],
        "preflight type mismatch "..spec.kind.."."..field)
      compiler.writers[ty](out,value)
    end
  end
  local bin=out:Save()
  local pointers=compiler:EncodePointerMap(out,ptrs)
  out:finished()
  assert(type(bin)=="string" and type(pointers)=="string")
  return {bin=bin,ptrs=pointers,source=source,ids=ids}
end
local function verify(spec,staged)
  -- Actual compiler.GetDBHandle yields and is NOT override masked.
  local handle=compiler:GetDBHandle(staged.bin,staged.ptrs,
    compiler:BuildSkipMap(db[spec.types],db[spec.order]),
    db[spec.keys],nil)
  for _,id in ipairs(staged.ids)do
    assert(handle.pointers[id]~=nil,"missing staged pointer")
    assert(handle.QuerySingle(id,"name")==staged.source[id][db[spec.keys].name],
      "unmasked staged name drift")
  end
  local id=spec.id
  if spec.kind=="npc"then
    assert(handle.QuerySingle(id,"minLevel")==12)
    assert(handle.QuerySingle(id,"questStarts")[1]==301)
  elseif spec.kind=="obj"then
    assert(handle.QuerySingle(id,"zoneID")==141)
    assert(handle.QuerySingle(id,"questStarts")[1]==301)
  elseif spec.kind=="quest"then
    assert(handle.QuerySingle(id,"questLevel")==13)
    assert(handle.QuerySingle(id,"startedBy")[2][1]==201)
  elseif spec.kind=="item"then
    assert(handle.QuerySingle(id,"startQuest")==301)
    assert(handle.QuerySingle(id,"npcDrops")[1]==101)
  end
  handle.stream:finished()
end
local busy=false
local function transaction(opts)
  if busy then return "BUSY"end
  busy=true
  -- All remaining failures are coroutine errors; published old data untouched.
  local snap=capture()
  local staged={}
  for _,spec in ipairs(specs)do
    staged[spec.kind]=writeCategory(spec,snap[spec.kind])
    coroutine.yield("stage:"..spec.kind)
    if opts and opts.fail=="after_"..spec.kind then
      error("injected abort after "..spec.kind)
    end
  end
  for _,spec in ipairs(specs)do verify(spec,staged[spec.kind])end
  if opts and opts.fail=="after_verify"then error("injected verify abort")end
  -- Proposed catchable-success publish contract: NO YIELD in this section.
  local g=Questie.db.global
  for _,spec in ipairs(specs)do
    local item=staged[spec.kind]
    g[spec.kind.."Bin"]=item.bin
    g[spec.kind.."Ptrs"]=item.ptrs
  end
  g.dbCompiledOnVersion="test-version"
  g.dbCompiledLang="enUS"
  g.dbCompiledExpansion=2
  g.dbCompiledCount=(g.dbCompiledCount or 0)+1
  g.dbIsCompiled=true
  g.nQuestieDataRevision=23 -- last and only on success
  busy=false
  return "SUCCESS"
end
local function run(opts,onYield)
  local co=coroutine.create(function()return transaction(opts)end)
  for _=1,128 do
    local ok,value=coroutine.resume(co)
    if not ok then busy=false;return false,tostring(value)end
    if coroutine.status(co)=="dead"then return true,value end
    if onYield then onYield(value)end
  end
  busy=false
  error("too many yields")
end
local passed=0
local function check(label,fn)
  local ok,e=pcall(fn)
  if not ok then
    io.stderr:write("FAIL STAGED "..label..": "..tostring(e).."\n")
    os.exit(1)
  end
  passed=passed+1;print("PASS STAGED "..label)
end
local function reset()fixtures();publishOld();busy=false end
reset()
local good,result=run()
check("candidate_success",function()assert(good and result=="SUCCESS")end)
check("eight_pairs_published_together",function()
  local g=Questie.db.global
  for _,s in ipairs(specs)do
    assert(type(g[s.kind.."Bin"])=="string" and
      type(g[s.kind.."Ptrs"])=="string")
  end
end)
check("revision_last_on_success",function()
  local g=Questie.db.global
  assert(g.dbCompiledCount==12 and g.nQuestieDataRevision==23)
  assert(g.dbIsCompiled and g.dbCompiledLang=="enUS")
end)
for _,kind in ipairs({"npc","obj","quest","item"})do
  check(kind.."_unmasked_readback",function()
    local id=({npc=101,obj=201,quest=301,item=401})[kind]
    assert(Questie.db.global[kind.."Ptrs"]~="OLD_"..kind.."Ptrs")
    assert(id~=nil)
  end)
end
reset()
db.questData[301][db.questKeys.questLevel]="WRONG-TYPE"
local okbad=run()
check("bad_quest_aborts",function()assert(not okbad)end)
check("bad_quest_preserves_all_old_fields",function()assertOld(Questie.db.global)end)
for _,point in ipairs({"npc","obj","quest","item","verify"})do
  reset()
  local okabort=run({fail=point=="verify" and "after_verify"or"after_"..point})
  check("injected_"..point.."_abort",function()assert(not okabort)end)
  check("injected_"..point.."_no_partial_publish",function()
    assertOld(Questie.db.global)
  end)
end
reset()
local transient=false
local okaba,resultaba=run(nil,function(mark)
  if mark=="stage:npc"and not transient then
    transient=true
    db.questData[301][db.questKeys.questLevel]=99
    db.questData[301][db.questKeys.questLevel]=13
  end
end)
check("transient_ABA_exercised",function()assert(transient)end)
check("transient_ABA_frozen_source_success",function()
  assert(okaba and resultaba=="SUCCESS")
  assert(db.questData[301][db.questKeys.questLevel]==13)
end)
reset()
busy=true
local busyok,busyres=run()
check("busy_status_explicit",function()assert(busyok and busyres=="BUSY")end)
check("busy_leaves_old_published_data",function()assertOld(Questie.db.global)end)
assert(passed==23,"wrong test count: "..passed)
print("STAGED PROPOSAL RESULT: 23/23 PASS")
