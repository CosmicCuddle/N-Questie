-- PUBLIC TEST ONLY: complete original protected 335 QuestieStream module
-- and unchanged complete original compiler:GetDBHandle source together.
-- Pointers/byte rows, DecodePointerMap and tiny key layout are FICTIONAL.
local root=assert(os.getenv("NQ_G08_REAL_STREAM_HANDLE_ROOT"),"PINNED_SOURCE_ROOT_REQUIRED")
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"),"ORIGINAL_FILE_NOT_FOUND:"..path)
  local x=assert(f:read("*a"));f:close();return x
end
local streamSource=read("Modules/QuestieStream.lua")
local compilerSource=read("Database/compiler.lua")
local first="function QuestieDBCompiler:GetDBHandle(data, pointers, skipMap, keyToRootIndex, overrides)"
local at=assert(compilerSource:find(first,1,true),"ORIGINAL_GETDBHANDLE_NOT_FOUND")
assert(not compilerSource:find(first,at+#first,true),"DUPLICATE_GETDBHANDLE")
local actualGetDBHandle=compilerSource:sub(at) -- complete original through its final end
local n=0
local function check(cond,label)assert(cond,label);n=n+1 end
local function compile(source,env,name)
  local f
  if _VERSION=="Lua 5.1" then
    f=assert(loadstring(source,name));setfenv(f,env)
  else
    f=assert(load(source,name,"t",env))
  end
  return f()
end
check(streamSource:find("function QuestieStreamLib:GetStream(mode)",1,true)~=nil,
  "S01_REAL_ORIGINAL_STREAM_FACTORY")
check(streamSource:find("local stream = tremove(StreamPool)",1,true)~=nil,
  "S02_REAL_ORIGINAL_POOL_POP")
check(streamSource:find("tinsert(StreamPool, self)",1,true)~=nil,
  "S03_REAL_FINISHED_PUSH")
check(streamSource:find("function QuestieStreamLib:Load(bin)",1,true)~=nil,
  "S04_REAL_STREAM_LOAD")
check(actualGetDBHandle:find('local stream = QuestieStream:GetStream("raw")',1,true)~=nil,
  "S05_REAL_GETDBHANDLE_STREAM_REQUEST")
check(actualGetDBHandle:find("coroutine.yield()",1,true)~=nil,
  "S06_REAL_HANDLE_SOURCE_YIELD")
check(actualGetDBHandle:find("handle.QuerySingle = function(id, key)",1,true)~=nil,
  "S07_REAL_QUERY_CLOSURE")
check(actualGetDBHandle:find("handle.pointers = pointers",1,true)~=nil,
  "S08_REAL_HANDLE_POINTER_EXPORT")
local modules={}
local loader={}
function loader:CreateModule(name)
  assert(name=="QuestieStreamLib","UNEXPECTED_ORIGINAL_MODULE")
  local t={};modules[name]=t;return t
end
local errors={}
local questie={}
function questie:Error(...)errors[#errors+1]=table.concat({...}," ")end
local bitStub={
  band=function()return 0 end,
  lshift=function(a,shift)return a*2^shift end,
  rshift=function(a,shift)return math.floor(a/2^shift)end
}
local env={QuestieLoader=loader,Questie=questie,bit=bitStub,
  tremove=table.remove,unpack=unpack or table.unpack}
setmetatable(env,{__index=_G})
compile(streamSource,env,"@335/Modules/QuestieStream.lua")
local lib=assert(modules.QuestieStreamLib,"ORIGINAL_STREAM_MODULE_MISSING")
check(type(lib.GetStream)=="function","S09_COMPLETE_STREAM_MODULE_EXECUTED")
local compiler={decodes={}}
function compiler:DecodePointerMap(stream)
  local pointerBlob=stream._bin
  assert(type(pointerBlob)=="string" and pointerBlob:sub(1,4)=="PTR_",
    "FICTIONAL_POINTER_ENCODING_INVALID")
  self.decodes[#self.decodes+1]=pointerBlob
  return {[55]=1}
end
local sourceStream=lib:GetStream("raw")
local compilerEnv={QuestieDBCompiler=compiler,QuestieStream=sourceStream,
  Questie=questie,unpack=unpack or table.unpack,
  readers={u8=function(stream)return stream:ReadByte()end},
  skippers={}}
setmetatable(compilerEnv,{__index=_G})
compile(actualGetDBHandle,compilerEnv,"@335/Database/compiler.lua.GetDBHandle")
check(type(compiler.GetDBHandle)=="function","S10_COMPLETE_REAL_GETDBHANDLE_EXECUTED")
local skipMap={{value=0},1,0,{value="u8"},{"value"},{"value"},{value=1}}
local rootIndex={value=1}
local function beginHandle(label,byte)
  local co=coroutine.create(function()
    return compiler:GetDBHandle(string.char(byte),"PTR_"..label,skipMap,rootIndex,{})
  end)
  return co
end
local function step(co)
  local ok,result=coroutine.resume(co)
  assert(ok,"ORIGINAL_COROUTINE_ERROR:"..tostring(result))
  return result
end
local function finish(co)
  assert(coroutine.status(co)=="suspended","EXPECTED_SUSPENDED_SOURCE")
  step(co);step(co);step(co)
  assert(coroutine.status(co)=="dead","EXPECTED_COMPLETED_SOURCE")
end
local a=beginHandle("A",65)
check(coroutine.status(a)=="suspended","S11_A_COROUTINE_NOT_STARTED")
step(a)
check(coroutine.status(a)=="suspended","S12_REAL_GETDBHANDLE_FIRST_YIELD")
step(a)
check(coroutine.status(a)=="suspended","S13_REAL_GETDBHANDLE_SECOND_YIELD")
step(a)
check(coroutine.status(a)=="suspended" and compiler.decodes[1]=="PTR_A",
  "S14_REAL_GETDBHANDLE_THIRD_YIELD_AFTER_DECODING")
local handleA=step(a)
check(coroutine.status(a)=="dead" and type(handleA)=="table",
  "S15_REAL_GETDBHANDLE_RETURNED_A")
check(handleA.QuerySingle(55,"value")==65,"S16_REAL_A_READER_RAW_BYTE")
check(handleA.pointers[55]==1,"S17_REAL_A_POINTER_MAP")
check(handleA.QuerySingle(999,"value")==nil,"S18_UNKNOWN_ID_NIL")
local b=beginHandle("B",66)
step(b);step(b);step(b)
local handleB=step(b)
check(handleB.QuerySingle(55,"value")==66,"S19_REAL_B_RAW_BYTE")
check(handleB.stream~=handleA.stream,"S20_ACTIVE_STREAMS_DISTINCT_NO_FINISH")
check(handleA.QuerySingle(55,"value")==65,"S21_UNRELEASED_OLD_HANDLE_STAYS_OLD")
check(compiler.decodes[2]=="PTR_B","S22_REAL_POINTER_DECODE_ORDER")
-- Controlled artificial early release of a still-referenced handle.
handleA.stream:finished()
check(handleA.stream._pointer==1,"S23_REAL_FINISHED_RESETS_STREAM")
local c=beginHandle("C",67)
step(c);step(c);step(c)
local handleC=step(c)
check(handleC.stream==handleA.stream,"S24_ORIGINAL_POOL_REUSES_FINISHED_OBJECT")
check(handleC.QuerySingle(55,"value")==67,"S25_NEW_C_READER_CORRECT")
check(handleA.QuerySingle(55,"value")==67,
  "S26_OLD_CLOSURE_READS_C_AFTER_EARLY_RELEASE")
check(handleB.QuerySingle(55,"value")==66,"S27_SEPARATE_UNRELEASED_B_STAYS_STABLE")
check(handleA.pointers[55]==1 and handleC.pointers[55]==1,
  "S28_SAME_ID_POINTER_MAP_CANNOT_DETECT_DATA_REUSE")
-- Deliberate invalid duplicate finish: model a misuse forbidden by a future lease.
handleC.stream:finished()
handleA.stream:finished()
local d=beginHandle("D",68)
step(d);step(d);step(d)
local handleD=step(d)
check(handleD.QuerySingle(55,"value")==68,"S29_D_QUERY_FROM_DUPLICATED_POOL")
local e=beginHandle("E",69)
step(e);step(e);step(e)
local handleE=step(e)
check(handleD.stream==handleE.stream,"S30_DOUBLE_FINISHED_DUPLICATE_POOL_LEASE")
check(handleE.QuerySingle(55,"value")==69 and handleD.QuerySingle(55,"value")==69,
  "S31_DUPLICATE_POOL_ENTRIES_CROSS_MUTATE_BOTH_READERS")
check(#errors==0,"S32_REAL_SOURCE_PATH_NO_ERROR_WARNINGS")
check(#compiler.decodes==5,"S33_A_THROUGH_E_REAL_HANDLE_POINTER_DECODE_CALLS")
-- Model-only safe choice: do NOT return live A/B streams; stay pinned until
-- all bound readers and queued consumers release their source generation.
assert(n==33,"STREAM_HANDLE_ASSERTION_CENSUS_CHANGED:"..n)
print("PUBLIC G08 PART44 REAL STREAM AND HANDLE LIFETIME: 33/33 PASS")
print("PUBLIC G08 REAL SOURCE: entire unchanged original QuestieStream module and entire unchanged original compiler GetDBHandle body executed, including real three yields, raw-byte query closures and pool finished/reuse methods.")
print("PUBLIC G08 CONSTRUCTED LEASE FAULT: artificially finishing an accessible old reader stream permits genuine original pooled stream reuse; a retained QuerySingle closure then observes later invented binary payload, and double finish can duplicate a pool lease.")
print("PUBLIC G08 NOT NATIVE: fabricated pointer decoder, one-field skipmap and binary strings, no real producer, native client, WoW 3.3.5a/IP, SaveVariables, original full compiler, QuestieDB module, package/ZIP, install, merge or release.")
