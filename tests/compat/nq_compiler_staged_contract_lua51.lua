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
    [nk.questStarts]={301},[nk.spawns]={[141]={{-1,-1},{41.2,50.1}}}}}
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
  -- Preserve 'seen' so shared branches are rejected, not just cycles.
  return out
end
local function capture()
  local out={}
  for _,s in ipairs(specs)do
    -- Prevent 16-bit pointer count overflow before allocating a snapshot.
    local count=0
    for _ in pairs(db[s.data])do
      count=count+1
      assert(count<=65535,"source pointer-count overflow")
    end
    out[s.kind]=deepCopy(db[s.data],{})
  end
  return out
end
local function writeCategory(spec,source)
  local ids={}
  for id in pairs(source)do
    assert(type(id)=="number" and id==math.floor(id) and
      id>=1 and id<=16777215,"bad ID")
    ids[#ids+1]=id
  end
  assert(#ids<=65535,"too many pointer entries")
  table.sort(ids)
  local out=streamMod:GetStream("raw")
  -- The writer and pointer encoder do not yield: Lua 5.1 permits pcall here.
  -- Always return the source stream to its pool, even on a nested write error.
  local ok,payload=pcall(function()
    local ptrs={}
    for _,id in ipairs(ids)do
      local record=source[id]
      assert(type(record)=="table","bad source entry")
      assert(out._pointer>=1 and out._pointer<=16777215,
        "pointer address exceeds 24-bit encoding")
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
    assert(#bin<=16777215,"staged binary exceeds 24-bit pointer budget")
    local pointers=compiler:EncodePointerMap(out,ptrs)
    assert(type(bin)=="string" and type(pointers)=="string")
    return {bin=bin,ptrs=pointers,source=source,ids=ids,offsets=ptrs}
  end)
  out:finished()
  if not ok then error(payload,0)end
  return payload
end

-- Fixture-only oracle: compare every explicitly populated source field.
-- Spawn locations alone need the *real writer's* floor(x*40.90)/40.90 rule;
-- a loose numeric tolerance would mask integer/source drift.
local function normalizedSpawns(input)
  local out={}
  for zone,coords in pairs(input)do
    out[zone]={}
    for i,xy in ipairs(coords)do
      if xy[1]==-1 and xy[2]==-1 then out[zone][i]={-1,-1}
      else
        out[zone][i]={
          math.floor(xy[1]*40.90)/40.90,
          math.floor(xy[2]*40.90)/40.90
        }
      end
    end
  end
  return out
end
local function equalExact(actual,expected,path)
  if type(expected)~="table"then
    assert(actual==expected,"field drift at "..path)
    return
  end
  assert(type(actual)=="table","missing table at "..path)
  for k,value in pairs(expected)do
    equalExact(actual[k],value,path.."."..tostring(k))
  end
  for k in pairs(actual)do
    assert(expected[k]~=nil,"unexpected decoded member at "..path.."."..tostring(k))
  end
end
local function verify(spec,staged)
  -- Check raw pointer grammar BEFORE yielding inside GetDBHandle.
  -- In particular, malformed counts/lengths never acquire a stream.
  local ptrs=staged.ptrs
  local count=#staged.ids
  assert(count<=65535,"pointer count overflow")
  assert(#ptrs==2+6*count,"pointer map byte length drift")
  local b1,b2=string.byte(ptrs,1,2)
  assert(b1*256+b2==count,"pointer header count mismatch")
  local seen={}
  for i=1,count do
    local p=3+(i-1)*6
    local a,b,c,d,e,f=string.byte(ptrs,p,p+5)
    local id=a*65536+b*256+c
    local offset=d*65536+e*256+f
    assert(not seen[id],"duplicate pointer ID")
    seen[id]=true
    assert(staged.offsets[id]~=nil,"unplanned pointer ID")
    assert(staged.offsets[id]==offset,"unplanned pointer address")
    assert(offset>=1 and offset<=#staged.bin,"pointer outside staged binary")
  end
  -- Actual compiler.GetDBHandle yields and is NOT override masked.
  local handle=compiler:GetDBHandle(staged.bin,staged.ptrs,
    compiler:BuildSkipMap(db[spec.types],db[spec.order]),
    db[spec.keys],nil)
  -- Only the non-yielding field verification may be pcall-wrapped under
  -- Lua 5.1. Ensure reader streams are returned even on failed assertions.
  local verified,verifyError=pcall(function()
  -- Validate the entire decoded pointer map, not only known ID presence.
  assert(#staged.ids<=65535,"pointer count would overflow short")
  assert(#staged.ptrs==2+6*#staged.ids,"pointer map byte length drift")
  local pointerCount=0
  for pointerId,offset in pairs(handle.pointers)do
    pointerCount=pointerCount+1
    assert(staged.offsets[pointerId]~=nil,"unexpected decoded pointer ID")
    assert(offset==staged.offsets[pointerId],"decoded pointer offset drift")
    assert(offset>=1 and offset<=#staged.bin,"pointer offset outside bin")
  end
  assert(pointerCount==#staged.ids,"decoded pointer count drift")
  for _,id in ipairs(staged.ids)do
    assert(handle.pointers[id]~=nil,"missing staged pointer")
    assert(handle.QuerySingle(id,"name")==staged.source[id][db[spec.keys].name],
      "unmasked staged name drift")
    for _,field in ipairs(db[spec.order])do
      local expected=staged.source[id][db[spec.keys][field]]
      if expected~=nil then
        local ty=db[spec.types][field]
        if ty=="spawnlist"then expected=normalizedSpawns(expected) end
        equalExact(handle.QuerySingle(id,field),expected,
          spec.kind.."["..tostring(id).."]."..field)
      end
    end
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
  end)
  handle.stream:finished()
  assert(verified,verifyError)
end
-- Synthetic owner-controlled generation witness. Real production code still
-- needs complete registration of all late writers before this can be trusted.
local sourceGeneration=0
local function trackedQuestLevel(value)
  db.questData[301][db.questKeys.questLevel]=value
  sourceGeneration=sourceGeneration+1
end
local busy=false
local function transaction(opts)
  if busy then return "BUSY"end
  busy=true
  -- All remaining failures are coroutine errors; published old data untouched.
  local snap=capture()
  local capturedGeneration=sourceGeneration
  local staged={}
  for _,spec in ipairs(specs)do
    staged[spec.kind]=writeCategory(spec,snap[spec.kind])
    coroutine.yield("stage:"..spec.kind)
    if opts and opts.fail=="after_"..spec.kind then
      error("injected abort after "..spec.kind)
    end
  end
  -- Test-only tampering AFTER four local stages, BEFORE readback/publish.
  if opts and opts.corrupt=="quest_requiredLevel"then
    local item=staged.quest
    local offset=item.offsets[301]
    local byte=assert(string.byte(item.bin,offset))
    item.bin=item.bin:sub(1,offset-1)..string.char((byte+1)%256)
      ..item.bin:sub(offset+1)
  elseif opts and opts.corrupt=="item_objectDrops_witness"then
    staged.item.source[401][db.itemKeys.objectDrops]={999}
  elseif opts and opts.corrupt=="pointer_header_count"then
    local old=staged.quest.ptrs
    staged.quest.ptrs=old:sub(1,1)..string.char(0)..old:sub(3)
  elseif opts and opts.corrupt=="pointer_extra_bytes"then
    staged.quest.ptrs=staged.quest.ptrs..string.char(0)
  elseif opts and opts.corrupt=="pointer_offset"then
    local old=staged.quest.ptrs
    local last=string.byte(old,#old)
    staged.quest.ptrs=old:sub(1,#old-1)..string.char((last+1)%256)
  elseif opts and opts.corrupt=="truncate_pointer"then
    staged.quest.ptrs=staged.quest.ptrs:sub(1,1)
  elseif opts and opts.corrupt=="truncate_bin"then
    staged.quest.bin=""
  end
  for _,spec in ipairs(specs)do verify(spec,staged[spec.kind])end
  if opts and opts.fail=="after_verify"then error("injected verify abort")end
  assert(sourceGeneration==capturedGeneration,
    "synthetic source-generation witness changed during compilation")
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
local function reset()fixtures();publishOld();busy=false;sourceGeneration=0 end
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
    trackedQuestLevel(99)
    trackedQuestLevel(13)
  end
end)
check("transient_ABA_exercised",function()assert(transient)end)
check("transient_ABA_rejected_by_generation",function()
  assert(not okaba and resultaba:find("source%-generation witness changed"))
  assert(db.questData[301][db.questKeys.questLevel]==13)
end)
check("transient_ABA_preserves_old",function()assertOld(Questie.db.global)end)
reset()
local trackedOnce=false
local okmut,errmut=run(nil,function(mark)
  if mark=="stage:npc"and not trackedOnce then
    trackedOnce=true
    trackedQuestLevel(19)
  end
end)
check("persistent_writer_mutation_refused",function()
  assert(not okmut and trackedOnce and
    errmut:find("source%-generation witness changed"))
end)
check("persistent_writer_mutation_preserves_old",function()
  assertOld(Questie.db.global)
end)
reset()
busy=true
local busyok,busyres=run()
check("busy_status_explicit",function()assert(busyok and busyres=="BUSY")end)
check("busy_leaves_old_published_data",function()assertOld(Questie.db.global)end)
for _,corruption in ipairs({"pointer_offset","pointer_header_count","pointer_extra_bytes","truncate_pointer","truncate_bin","quest_requiredLevel","item_objectDrops_witness"})do
  reset()
  local okcorrupt,corruptReason=run({corrupt=corruption})
  local expectedDiagnostic={
    pointer_offset="unplanned pointer address",
    pointer_header_count="pointer header count mismatch",
    pointer_extra_bytes="pointer map byte length drift",
    truncate_pointer="pointer map byte length drift",
    truncate_bin="pointer outside staged binary",
    quest_requiredLevel="field drift at quest",
    item_objectDrops_witness="field drift at item"
  }
  check(corruption.."_refused",function()
    assert(not okcorrupt and type(corruptReason)=="string")
    assert(corruptReason:find(expectedDiagnostic[corruption],1,true),
      "unexpected corruption failure: "..corruptReason)
  end)
  check(corruption.."_preserves_old",function()assertOld(Questie.db.global)end)
end
reset()
local shared={{101}}
db.questData[301][db.questKeys.startedBy]=shared
db.questData[301][db.questKeys.finishedBy]=shared
local okshared=run()
check("shared_reference_refused",function()assert(not okshared)end)
check("shared_reference_preserves_old",function()assertOld(Questie.db.global)end)
reset()
setmetatable(db.questData[301],{__index=function()return nil end})
local okmeta=run()
check("metatable_refused",function()assert(not okmeta)end)
check("metatable_preserves_old",function()assertOld(Questie.db.global)end)
reset()
db.questData[301][db.questKeys.questLevel]="WRONG-TYPE"
local retryFailed=run()
db.questData[301][db.questKeys.questLevel]=13
local retryOk,retryResult=run()
check("failed_run_retry_succeeds",function()
  assert(not retryFailed and retryOk and retryResult=="SUCCESS")
end)
check("retry_metadata_once_only",function()
  assert(Questie.db.global.dbCompiledCount==12)
  assert(Questie.db.global.nQuestieDataRevision==23)
end)
reset()
local allYields=0
local precommitOk,precommitResult=run(nil,function()
  allYields=allYields+1
  assertOld(Questie.db.global)
end)
check("old_state_visible_at_every_yield",function()
  assert(precommitOk and precommitResult=="SUCCESS" and allYields>=4)
end)
-- Cover EVERY root compiler field using only fictional, codec-appropriate data.
-- This does not certify arbitrary production nested records or pointer corruption.
local function exampleForCodec(ty)
  if ty=="s8" then return 9
  elseif ty=="u8" then return 14
  elseif ty=="u16" then return 141
  elseif ty=="s16" then return 22
  elseif ty=="u24" then return 301
  elseif ty=="s24" then return 207
  elseif ty=="u32" then return 123456
  elseif ty=="u12pair" then return {5,6}
  elseif ty=="u24pair" then return {7,8}
  elseif ty=="s24pair" then return {9,10}
  elseif ty=="u8string" then return "Synthetic name"
  elseif ty=="u16string" then return "Synthetic long string"
  elseif ty=="u8u16array" then return {16}
  elseif ty=="u8s16pairs" then return {{17,18}}
  elseif ty=="u16u16array" then return {19}
  elseif ty=="u8s24pairs" then return {{20,21}}
  elseif ty=="u8u24array" then return {301}
  elseif ty=="u16u24array" then return {301}
  elseif ty=="u8u16stringarray" then return {"Synthetic objective text"}
  elseif ty=="faction" then return "AH"
  elseif ty=="spawnlist" then return {[141]={{-1,-1}}}
  elseif ty=="waypointlist" then return {[141]={{{-1,-1}}}}
  elseif ty=="trigger" then return {"Synthetic trigger",{[141]={{-1,-1}}}}
  elseif ty=="questgivers" then return {{101},{201},{401}}
  elseif ty=="objective" then return {{101,"Synthetic target"}}
  elseif ty=="spellobjective" then return {{501,"Synthetic spell",1}}
  elseif ty=="objectives" then
    return {
      {{101,"Synthetic creature"}},
      {{201,"Synthetic object"}},
      {{401,"Synthetic item"}},
      {5,6},
      {{{101},101,"Synthetic kill"}},
      {{501,"Synthetic spell",1}}
    }
  elseif ty=="reflist" then return {{"monster",101}}
  elseif ty=="extraobjectives" then
    return {{{[141]={{-1,-1}}},12,"Synthetic extra",2,{{"monster",101}}}}
  end
  error("unhandled pinned compiler type "..tostring(ty))
end
local function fillCompleteSchema()
  local roots,typesSeen=0,{}
  for _,spec in ipairs(specs)do
    local record=db[spec.data][spec.id]
    for _,field in ipairs(db[spec.order])do
      local ty=db[spec.types][field]
      assert(ty,"missing compiler type "..spec.kind.."."..field)
      assert(type(compiler.writers[ty])=="function","missing writer for "..ty)
      roots=roots+1
      typesSeen[ty]=true
      local index=db[spec.keys][field]
      assert(index,"missing source key "..spec.kind.."."..field)
      if record[index]==nil then record[index]=exampleForCodec(ty)end
      assert(record[index]~=nil,"schema fixture missing "..field)
    end
  end
  assert(roots==67,"pinned root schema drift, got "..roots)
  local distinct=0
  for _ in pairs(typesSeen)do distinct=distinct+1 end
  assert(distinct==20,"pinned referenced codec count drift, got "..distinct)
  return roots,distinct
end
reset()
local allRootFields,allRootCodecs=fillCompleteSchema()
local fullOk,fullResult=run()
check("all_67_schema_fields_source_backed",function()
  assert(fullOk and fullResult=="SUCCESS")
  assert(allRootFields==67 and allRootCodecs==20)
end)
check("all_67_schema_fields_publish_metadata",function()
  local g=Questie.db.global
  assert(g.dbCompiledCount==12 and g.nQuestieDataRevision==23)
  for _,kind in ipairs(specs)do
    assert(type(g[kind.kind.."Bin"])=="string")
    assert(type(g[kind.kind.."Ptrs"])=="string")
  end
end)
reset()
fillCompleteSchema()
db.questData[301][db.questKeys.questLevel]="BAD_TYPE"
local fullBad=run()
check("full_schema_invalid_type_refused",function()assert(not fullBad)end)
check("full_schema_bad_type_preserves_old",function()assertOld(Questie.db.global)end)
reset()
local multiCount=0
db.itemData[16777215]={[db.itemKeys.name]="Synthetic edge item",
  [db.itemKeys.startQuest]=301}
db.itemData[10000]={[db.itemKeys.name]="Synthetic sparse item"}
for _ in pairs(db.itemData)do multiCount=multiCount+1 end
local multiOk,multiResult=run()
check("sparse_u24_max_id_stage_succeeds",function()
  assert(multiOk and multiResult=="SUCCESS" and multiCount==3)
end)
check("sparse_u24_max_id_decoded",function()
  local g=Questie.db.global
  local co=coroutine.create(function()
    return compiler:GetDBHandle(g.itemBin,g.itemPtrs,
      compiler:BuildSkipMap(db.itemCompilerTypes,db.itemCompilerOrder),
      db.itemKeys,nil)
  end)
  local handle
  for _=1,32 do
    local ok,result=coroutine.resume(co)
    assert(ok,tostring(result))
    if coroutine.status(co)=="dead"then handle=result;break end
  end
  assert(handle,"unmasked sparse lookup did not finish")
  assert(handle.pointers[10000] and handle.pointers[16777215])
  assert(handle.QuerySingle(10000,"name")=="Synthetic sparse item")
  assert(handle.QuerySingle(16777215,"name")=="Synthetic edge item")
  handle.stream:finished()
end)
-- Malformed source IDs and impossible pointer counts must fail before publish.
for _,badId in ipairs({0,1.5,16777216})do
  reset()
  db.itemData[badId]={[db.itemKeys.name]="Synthetic invalid ID"}
  local accepted,idReason=run()
  check("invalid_source_id_"..tostring(badId).."_refused",function()
    assert(not accepted and type(idReason)=="string")
    assert(idReason:find("bad ID",1,true),
      "unexpected invalid-ID failure: "..idReason)
  end)
  check("invalid_source_id_"..tostring(badId).."_preserves_old",function()
    assertOld(Questie.db.global)
  end)
end
reset()
for id=100000,165535 do db.itemData[id]=false end
local overLimit,limitReason=run()
check("65536_plus_pointer_count_refused",function()
  assert(not overLimit and type(limitReason)=="string")
  assert(limitReason:find("source pointer-count overflow",1,true),
    "unexpected source-count failure: "..limitReason)
end)
check("65536_plus_pointer_count_preserves_old",function()
  assertOld(Questie.db.global)
end)
-- Cleanup oracle for a readback failure occurring AFTER handle acquisition.
reset()
local normalGetHandle=compiler.GetDBHandle
local observedCleanup=0
compiler.GetDBHandle=function(self,...)
  local handle=normalGetHandle(self,...)
  local originalFinish=handle.stream.finished
  handle.stream.finished=function(stream)
    observedCleanup=observedCleanup+1
    return originalFinish(stream)
  end
  return handle
end
local afterHandle,afterHandleReason=run({corrupt="quest_requiredLevel"})
compiler.GetDBHandle=normalGetHandle
check("failed_decoded_field_releases_reader_streams",function()
  assert(not afterHandle and observedCleanup>=3)
  assert(type(afterHandleReason)=="string" and
    afterHandleReason:find("field drift at quest",1,true),
    "unexpected readback failure: "..tostring(afterHandleReason))
end)
check("failed_decoded_field_preserves_old",function()
  assertOld(Questie.db.global)
end)
-- Check streams are returned after bad root or nested codec writes.
local originalGetStream=streamMod.GetStream
local function runWithWriterStreamCounting(mutate)
  reset()
  mutate()
  local returned=0
  streamMod.GetStream=function(self,...)
    local st=originalGetStream(self,...)
    local previous=st.finished
    st.finished=function(x)
      returned=returned+1
      return previous(x)
    end
    return st
  end
  local ok,reason=run()
  streamMod.GetStream=originalGetStream
  return ok,reason,returned
end
local rootAccepted,rootReason,rootReleased=runWithWriterStreamCounting(function()
  db.questData[301][db.questKeys.questLevel]="INVALID_ROOT"
end)
check("invalid_root_writer_releases_its_stream",function()
  assert(not rootAccepted and rootReleased>=3)
  assert(type(rootReason)=="string" and
    rootReason:find("preflight type mismatch",1,true))
end)
check("invalid_root_writer_preserves_published_data",function()
  assertOld(Questie.db.global)
end)
local nestedAccepted,nestedReason,nestedReleased=runWithWriterStreamCounting(function()
  db.questData[301][db.questKeys.startedBy]={{"BAD_NESTED_ID"}}
end)
check("nested_codec_failure_releases_writer_stream",function()
  assert(not nestedAccepted and nestedReleased>=3)
  assert(type(nestedReason)=="string" and
    not nestedReason:find("preflight type mismatch",1,true))
end)
check("nested_codec_failure_preserves_published_data",function()
  assertOld(Questie.db.global)
end)
assert(passed==67,"wrong test count: "..passed)
print("STAGED PROPOSAL RESULT: 67/67 PASS")
