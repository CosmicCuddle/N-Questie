-- GATE08 TEST ONLY: unchanged first-party historic 335 validator METHOD bodies
-- executed under entirely invented quest/NPC/object/item data and reader stream handles.
-- NOT a client, actual QuestieStream pool experiment, in-game corruption or leak proof.
local root=assert(os.getenv("NQ_PART45_ORIGINAL_ROOT"),"AUTHENTIC_ROOT_REQUIRED")
local f=assert(io.open(root.."/Database/compiler.lua","rb"),"HISTORIC_COMPILER_BLOB_MISSING")
local original=assert(f:read("*a"));f:close()
local function extract(a,b)
  local i=assert(original:find(a,1,true),"ORIGINAL_START_MISSING:"..a)
  local j=assert(original:find(b,i+#a,true),"ORIGINAL_END_MISSING:"..b)
  return original:sub(i,j-1)
end
local npcSrc=extract("function QuestieDBCompiler:ValidateNPCs()",
  "\nfunction QuestieDBCompiler:ValidateObjects()")
local objSrc=extract("function QuestieDBCompiler:ValidateObjects()",
  "\nfunction QuestieDBCompiler:ValidateItems()")
local itemSrc=extract("function QuestieDBCompiler:ValidateItems()",
  "\nfunction QuestieDBCompiler:ValidateQuests()")
local questSrc=extract("function QuestieDBCompiler:ValidateQuests()",
  "\nfunction QuestieDBCompiler:GetDBHandle(")
local tests=0
local function check(ok,label)assert(ok,"ORIGINAL_G08_VALIDATOR:"..label);tests=tests+1 end
check(npcSrc:find("validator.stream:finished()",1,true)~=nil,"NPC_ORIGINAL_TERMINAL_FINISH")
check(objSrc:find("validator.stream:finished()",1,true)~=nil,"OBJECT_ORIGINAL_TERMINAL_FINISH")
check(itemSrc:find("obj.stream:finished()",1,true)~=nil and itemSrc:find("npc.stream:finished()",1,true)~=nil,
  "ITEM_ORIGINAL_THREE_READER_FINISH")
check(questSrc:find("b[i][4] = 0",1,true)~=nil,"QUEST_ORIGINAL_NESTED_WRITE")
local function equals(a,b)
  if type(a)~=type(b) then return false end
  if type(a)~="table" then return a==b end
  for k,v in pairs(a) do if not equals(v,b[k]) then return false end end
  for k,v in pairs(b) do if not equals(v,a[k]) then return false end end
  return true
end
local db={
  npcCompilerTypes={kind="npc"}, npcCompilerOrder={"name"},npcKeys={name=1},
  objectCompilerTypes={kind="object"},objectCompilerOrder={"name"},objectKeys={name=1},
  itemCompilerTypes={kind="item"},itemCompilerOrder={"name"},itemKeys={name=1},
  questCompilerTypes={kind="quest"},questCompilerOrder={"extraObjectives"},
  questKeys={extraObjectives=1}
}
local handles,warnings,errors,scenario
local compiler={}
function compiler:BuildSkipMap(types,order)
  assert(type(types.kind)=="string" and #order==1)
  return types.kind
end
function compiler:GetDBHandle(bin,ptrs,kind)
  assert(type(kind)=="string")
  local reader={kind=kind,stream={calls=0}}
  function reader.stream:finished()self.calls=self.calls+1 end
  reader.pointers=scenario.pointers[kind] or {}
  reader.QueryValidator=function(id,order)
    assert(type(order)=="table")
    return assert(scenario.compiled[kind][id],"UNEXPECTED_VALIDATION_ID_"..tostring(id))
  end
  reader.QuerySingle=function(id,key)
    local values=scenario.single[kind][id]
    return values and values[key]
  end
  handles[#handles+1]=reader
  return reader
end
local questie={DEBUG_INFO=1,IsSoD=false,IsWotlk=false,IsTBC=false,
  db={global={npcBin="NPCBIN",npcPtrs="NPCPTR",objBin="OBJBIN",objPtrs="OBJPTR",
  itemBin="ITEMBIN",itemPtrs="ITEMPTR",questBin="QBIN",questPtrs="QPTR"}}}
function questie:Warning(v)warnings[#warnings+1]=v end
function questie:Error(v)errors[#errors+1]=v end
function questie:Debug(...) end
local env={Questie=questie,QuestieDB=db,QuestieDBCompiler=compiler,
  TICKS_PER_YIELD_DEBUG=999,abs=math.abs,equals=equals,
  UnitLevel=function(u)assert(u=="player");return 60 end,
  DevTools_Dump=function()end}
setmetatable(env,{__index=_G})
local authentic=npcSrc.."\n"..objSrc.."\n"..itemSrc.."\n"..questSrc
local chunk
if _VERSION=="Lua 5.1" then
  chunk=assert(loadstring(authentic,"=ORIGINAL_335_DB_VALIDATOR_METHODS"))
  setfenv(chunk,env)
else
  chunk=assert(load(authentic,"=ORIGINAL_335_DB_VALIDATOR_METHODS","t",env))
end
chunk()
local function reset()
  handles,warnings,errors={},{},{}
  db.npcData={[101]={[1]="NPC"}}
  db.objectData={[801]={[1]="Object"}}
  db.itemData={[501]={[1]="Item"}}
  db.questData={[401]={[1]={{"Text",1,1}}}}
  scenario={
    compiled={
      npc={[101]={[1]="NPC"}},
      object={[801]={[1]="Object"}},
      item={[501]={[1]="Item"}},
      quest={[401]={[1]={{"Text",1,1,0}}}}
    },
    pointers={item={[501]=1}},
    single={
      npc={[101]={name="NPC"}},
      object={[801]={name="Object"}},
      item={[501]={name="Item",objectDrops={801},npcDrops={101}}}
    }
  }
end
local function released(expected)
  for _,h in ipairs(handles) do if h.stream.calls~=expected then return false end end
  return true
end
check(type(compiler.ValidateNPCs)=="function" and type(compiler.ValidateObjects)=="function"
  and type(compiler.ValidateItems)=="function" and type(compiler.ValidateQuests)=="function",
  "FOUR_AUTHENTIC_VALIDATOR_METHODS_COMPILED")
reset();compiler:ValidateNPCs()
check(#handles==1 and handles[1].kind=="npc","NPC_SUCCESS_SINGLE_HANDLE")
check(released(1) and #warnings==0,"NPC_SUCCESS_RELEASED")
reset();scenario.compiled.npc[101][1]="OTHER";compiler:ValidateNPCs()
check(#handles==1 and released(0),"NPC_MISMATCH_RETURNS_WITHOUT_FINISH")
check(#warnings==1 and warnings[1]:find("Nonmatching string",1,true)~=nil,"NPC_MISMATCH_WARNING")
reset();compiler:ValidateObjects()
check(#handles==1 and handles[1].kind=="object","OBJECT_SUCCESS_SINGLE_HANDLE")
check(released(1) and #warnings==0,"OBJECT_SUCCESS_RELEASED")
reset();scenario.compiled.object[801][1]="OTHER";compiler:ValidateObjects()
check(#handles==1 and released(0),"OBJECT_MISMATCH_RETURNS_WITHOUT_FINISH")
check(#warnings==1,"OBJECT_MISMATCH_WARNING")
reset();compiler:ValidateItems()
check(#handles==3 and handles[1].kind=="item" and handles[2].kind=="object"
  and handles[3].kind=="npc","ITEM_SUCCESS_THREE_HANDLES_ACQUIRED")
check(released(1) and #warnings==0 and #errors==0,"ITEM_SUCCESS_ALL_THREE_RELEASED")
reset();scenario.single.object[801].name=nil;compiler:ValidateItems()
check(#handles==3 and released(0),"MISSING_OBJECT_RETURNS_WITH_THREE_UNFINISHED")
check(#errors==1 and errors[1]:find("Missing object",1,true)~=nil,
  "MISSING_OBJECT_ERROR_SOURCE")
reset();scenario.single.npc[101].name=nil;compiler:ValidateItems()
check(#handles==3 and released(0),"MISSING_NPC_RETURNS_WITH_THREE_UNFINISHED")
check(#errors==1 and errors[1]:find("Missing npc",1,true)~=nil,
  "MISSING_NPC_ERROR_SOURCE")
reset();scenario.compiled.item[501][1]="DIFFERENT";compiler:ValidateItems()
check(#handles==3 and released(0),"ITEM_MISMATCH_RETURNS_WITH_THREE_UNFINISHED")
check(#warnings==1 and warnings[1]:find("Nonmatching string",1,true)~=nil,
  "ITEM_MISMATCH_WARNING")
reset()
check(db.questData[401][1][1][4]==nil,"QUEST_RAW_FOURTH_FIELD_UNSET")
compiler:ValidateQuests()
check(db.questData[401][1][1][4]==0,"QUEST_SUCCESS_INPLACE_NIL_TO_ZERO_WRITE")
check(#handles==1 and handles[1].kind=="quest" and released(1),
  "QUEST_SUCCESS_READER_RELEASED")
check(#warnings==0,"QUEST_SUCCESS_NO_MISMATCH")
reset()
scenario.compiled.quest[401][1][1][1]="WRONG_TEXT"
compiler:ValidateQuests()
check(db.questData[401][1][1][4]==0,
  "QUEST_FAILED_VALIDATION_STILL_WRITES_RAW_NESTED_FOURTH")
check(#handles==1 and released(0),"QUEST_TABLE_MISMATCH_READER_NOT_FINISHED")
check(#warnings==1 and warnings[1]:find("Nonmatching table",1,true)~=nil,
  "QUEST_TABLE_MISMATCH_WARNING")
reset()
scenario.compiled.quest[401][1][1][4]=3
compiler:ValidateQuests()
check(db.questData[401][1][1][4]==nil,
  "QUEST_NONZERO_COMPILED_FOURTH_DOES_NOT_NORMALIZE_RAW_NIL")
check(#handles==1 and released(0) and #warnings==1,
  "QUEST_NONZERO_COMPARISON_MISMATCH_UNFINISHED")
check(#errors==0,"NO_STUBBED_SERVER_ERRORS")
assert(tests==31,"ORIGINAL_G08_VALIDATOR_CENSUS:"..tests)
print("PUBLIC G08 PART49 ORIGINAL 335 VALIDATORS: 31/31 PASS")
print("PUBLIC G08 PART49 VALIDATORS: genuine 335 ValidateNPCs/ValidateObjects/ValidateItems/ValidateQuests source; fake reader handles and invented raw/compiled data.")
print("PUBLIC G08 PART49 NOT NATIVE: no actual QuestieStream, client, memory leak, server, SavedVariables or player impact.")
