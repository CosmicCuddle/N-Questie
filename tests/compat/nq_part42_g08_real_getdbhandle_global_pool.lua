-- Part42 public-safe Gate08: actual pinned GetDBHandle reader + actual global QuestieStream.
-- Both are unmodified protected-335 source; all bytes, requests and schedules are invented.
-- Deliberate premature finished()/stale aliases are caller MISUSE witnesses, not client proof.
local root=assert(os.getenv("NQ_G08_HANDLE_SOURCE_ROOT"),"G08_HANDLE_PINNED_SOURCE_REQUIRED")
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"),"G08_HANDLE_SOURCE_NOT_STAGED")
    local data=assert(f:read("*a"));f:close()
    return data
end
local streamSource=read("Modules/QuestieStream.lua")
local compilerSource=read("Database/compiler.lua")
local function once(src,anchor,label)
    local i=assert(src:find(anchor,1,true),label.."_MISSING")
    assert(not src:find(anchor,i+#anchor,true),label.."_DUPLICATE")
    return i
end
once(streamSource,"local StreamPool = {}","G08_ACTUAL_GLOBAL_POOL")
once(streamSource,"local function _StreamFinished(self)","G08_ACTUAL_RETURN")
once(streamSource,"function QuestieStreamLib:GetStream(mode)","G08_ACTUAL_ACQUIRE")
local decoderStart=once(compilerSource,
    "function QuestieDBCompiler:DecodePointerMap(stream)","G08_ACTUAL_DECODE")
local decoderStop=once(compilerSource,
    "\nfunction QuestieDBCompiler:CompileTable(","G08_ACTUAL_DECODE_END")
assert(decoderStop>decoderStart,"G08_DECODE_ORDER")
local handleStart=once(compilerSource,
    "function QuestieDBCompiler:GetDBHandle(","G08_ACTUAL_HANDLE")
local decoderSource=compilerSource:sub(decoderStart,decoderStop-1)
local handleSource=compilerSource:sub(handleStart)
assert(handleSource:find('local stream = QuestieStream:GetStream("raw")\n    coroutine.yield()',1,true),
    "G08_HANDLE_OWNED_ACQUIRE_YIELD_MISSING")
assert(handleSource:find("handle.stream = stream",1,true) and
    handleSource:find("return handle\nend",1,true),
    "G08_HANDLE_RETURN_ANCHORS")
local function band(a,b)
    local place,out=1,0
    for _=1,32 do
        local aa,bb=a%2,b%2
        if aa==1 and bb==1 then out=out+place end
        a=math.floor(a/2);b=math.floor(b/2);place=place*2
    end
    return out
end
local function loadExact(src,name,env)
    local chunk
    if _VERSION=="Lua 5.1" then
        chunk=assert(loadstring(src,name))
        setfenv(chunk,env)
    else
        chunk=assert(load(src,name,"t",env))
    end
    chunk()
end
local function boot()
    local streamModule,errors=nil,{}
    local streamEnv=setmetatable({
        QuestieLoader={CreateModule=function(_,name)
            assert(name=="QuestieStreamLib","G08_UNEXPECTED_STREAM_MODULE")
            streamModule={}
            return streamModule
        end},
        Questie={Error=function(_,msg)errors[#errors+1]=msg end},
        bit={
            band=band,
            lshift=function(a,b) return (a*(2^b))%(2^32) end,
            rshift=function(a,b) return math.floor(a/(2^b)) end,
        },
        -- WoW tremove is absent from standalone PUC Lua.
        tremove=table.remove,
        unpack=unpack or table.unpack,
    },{__index=_G})
    loadExact(streamSource,"=pinned_335_entire_real_stream",streamEnv)
    assert(type(streamModule)=="table" and
        type(streamModule.GetStream)=="function","G08_REAL_STREAM_NOT_READY")
    local compiler={}
    local compilerEnv=setmetatable({
        QuestieDBCompiler=compiler,
        QuestieStream=streamModule,
        Questie={Error=function(_,msg)errors[#errors+1]=msg end},
        min=math.min,
        unpack=unpack or table.unpack,
        readers={u8=function(s) return s:ReadByte() end},
        skippers={},
    },{__index=_G})
    loadExact(decoderSource,"=pinned_335_real_decoder",compilerEnv)
    loadExact(handleSource,"=pinned_335_real_getdbhandle",compilerEnv)
    assert(type(compiler.GetDBHandle)=="function" and
        type(compiler.DecodePointerMap)=="function",
        "G08_REAL_HANDLE_METHODS_NOT_READY")
    return streamModule,compiler,errors
end

-- Fictional pointer map: one entry, ID=7, data pointer=1 (network-byte-order).
local PTR=string.char(0,1,0,0,7,0,0,1)
local DATA=string.char(65)
local SKIP={{value=0},1,0,{value="u8"},{}, {"value"}, {value=1}}
local function startReader(compiler,pointers)
    return coroutine.create(function()
        return compiler:GetDBHandle(DATA,pointers or PTR,SKIP,{},nil)
    end)
end
local function advance(thread)
    local ok,value=coroutine.resume(thread)
    assert(ok,"G08_READER_COROUTINE_ERROR: "..tostring(value))
    return value
end
local passed=0
local function check(condition,label)
    assert(condition,label)
    passed=passed+1
end

-- Healthy reader: exact GetDBHandle owns the stream over four real yields,
-- including the yield inside the real DecodePointerMap.
do
    local lib,compiler=boot()
    check(#streamSource>5000 and #decoderSource>100 and
        #handleSource>3000,"G08_W01_REAL_FUNCTION_BODIES")
    local primed=lib:GetStream("raw")
    primed:finished()
    local thread=startReader(compiler)
    advance(thread) -- actual GetDBHandle yield #1: borrowed, not yet loaded
    check(coroutine.status(thread)=="suspended" and
        primed._mode=="raw" and type(primed._bin)=="table",
        "G08_W02_ACQUIRED_BEFORE_FIRST_YIELD")
    local peer=lib:GetStream("raw")
    check(peer~=primed and peer:Save()=="" and
        coroutine.status(thread)=="suspended",
        "G08_W03_FIRST_YIELD_HAS_DISTINCT_BORROWER")
    advance(thread) -- actual GetDBHandle yield #2: pointer blob now loaded
    check(primed._bin==PTR and primed._pointer==1 and peer~=primed,
        "G08_W04_SECOND_YIELD_REAL_POINTER_LOAD")
    advance(thread) -- actual DecodePointerMap yields after decoding one entry
    check(primed._pointer==9 and primed._bin==PTR and
        coroutine.status(thread)=="suspended",
        "G08_W05_DECODER_REAL_INTERNAL_YIELD")
    advance(thread) -- actual GetDBHandle yield #3: decoded map
    check(primed._bin==PTR and coroutine.status(thread)=="suspended",
        "G08_W06_DECODE_COMPLETION_STILL_HELD")
    local handle=advance(thread)
    check(coroutine.status(thread)=="dead" and
        handle.stream==primed and handle.pointers[7]==1,
        "G08_W07_RETURNED_HANDLE_OWNS_REAL_STREAM")
    check(primed._bin==DATA and handle.QuerySingle(7,"value")==65 and
        handle.QuerySingle(8,"value")==nil,
        "G08_W08_REAL_QUERY_READS_FICTIONAL_BYTE")
    check(handle.Query(7,{"value"})[1]==65 and
        handle.QueryValidator(7,{"value"})[1]==65,
        "G08_W09_REAL_QUERY_AND_VALIDATOR")
    peer:WriteByte(66)
    check(peer:Save()=="B" and handle.QuerySingle(7,"value")==65,
        "G08_W10_DISTINCT_ACTIVE_READER_AND_PEER")
    local more=lib:GetStream("raw")
    check(more~=handle.stream and more~=peer,
        "G08_W11_UNFINISHED_HANDLE_STAYS_OUT_OF_GLOBAL_POOL")
end

-- KNOWN UNSAFE, intentionally invalid caller behaviour: return reader's
-- stream while the actual GetDBHandle coroutine is still suspended.
do
    local lib,compiler=boot()
    local primed=lib:GetStream("raw")
    primed:finished()
    local thread=startReader(compiler)
    advance(thread)
    primed:finished() -- externally violates reader ownership; NOT native flow
    local peer=lib:GetStream("raw")
    check(peer==primed and coroutine.status(thread)=="suspended",
        "G08_W12_KNOWN_UNSAFE_PREMATURE_RETURN_REBORROW")
    peer:WriteByte(88)
    local handle
    for _=1,4 do handle=advance(thread) end
    check(handle.stream==peer and handle.QuerySingle(7,"value")==65 and
        peer._bin==DATA and peer._pointer==2,
        "G08_W13_KNOWN_UNSAFE_REAL_READER_OVERWRITES_PEER_STREAM")
end

-- A real decode failure exits its coroutine without a caller-visible handle.
-- A primed external alias makes the otherwise invisible borrowed stream
-- observable in this fictional test. This is NOT crash/relog acceptance.
do
    local lib,compiler=boot()
    local primed=lib:GetStream("raw")
    primed:finished()
    local truncated=string.char(0,1,0,0,7)
    local thread=startReader(compiler,truncated)
    advance(thread) -- acquired
    advance(thread) -- loaded truncated pointer blob
    local ok,err=coroutine.resume(thread)
    check(not ok and type(err)=="string" and
        coroutine.status(thread)=="dead",
        "G08_W14_REAL_DECODE_ERROR_ABORTS_READER")
    local peer=lib:GetStream("raw")
    check(peer~=primed and primed._bin==truncated,
        "G08_W15_FAILED_HANDLE_DOES_NOT_RETURN_OWNED_POOL_STREAM")
    check(type(primed.finished)=="function" and
        peer._mode=="raw" and peer:Save()=="",
        "G08_W16_ABORTED_READER_HAS_NO_AUTOMATIC_HANDLE_RECOVERY")
end
assert(passed==16,"G08_HANDLE_CONTROL_COUNT_CHANGED")
print("PUBLIC G08 REAL GETDBHANDLE GLOBAL POOL CONTROLS: 16/16 PASS")
print("PUBLIC G08 KNOWN UNSAFE: deliberately premature reader stream return causes live handle to overwrite peer's pooled stream.")
print("PUBLIC G08 NOT ACCEPTED: normal client violation, all-writer epochs, atomic four-kind RAM publication, SavedVariables disk/relog, or release.")
