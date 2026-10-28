-- N-Questie Part42 G08: unmodified real per-kind compiler + real shared
-- QuestieStream, then actual pointer decoder and GetDBHandle. Fictional bytes only.
-- Expected-UNSAFE A->B->A and abort schedules are diagnostics, NOT a fix.
local root=assert(os.getenv("NQ_G08_REAL_COMPILER_POOL_ROOT"),
    "G08_REAL_COMPILER_POOL_PINNED_SOURCES_REQUIRED")
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"),
        "G08_REAL_COMPILER_POOL_SOURCE_MISSING")
    local data=assert(f:read("*a"));f:close()
    return data
end
local compilerSource=read("Database/compiler.lua")
local streamSource=read("Modules/QuestieStream.lua")
local function once(src,anchor,label)
    local i=assert(src:find(anchor,1,true),label.."_MISSING")
    assert(not src:find(anchor,i+#anchor,true),label.."_DUPLICATED")
    return i
end
local function extract(src,first,last,label)
    local a=once(src,first,label.."_BEGIN")
    local b=once(src,last,label.."_END")
    assert(b>a,label.."_REVERSED")
    return src:sub(a,b-1)
end
once(streamSource,"local StreamPool = {}","G08_REAL_GLOBAL_POOL")
once(streamSource,"function QuestieStreamLib:GetStream(mode)",
    "G08_REAL_SHARED_POOL_ACQUIRE")
once(streamSource,"local function _StreamFinished(self)",
    "G08_REAL_SHARED_POOL_RETURN")
local perKind=extract(compilerSource,
    "function QuestieDBCompiler:CompileTableCoroutine(",
    "\nfunction QuestieDBCompiler:BuildSkipMap(","G08_REAL_PER_KIND")
local encoder=extract(compilerSource,
    "function QuestieDBCompiler:EncodePointerMap(",
    "\nfunction QuestieDBCompiler:DecodePointerMap(","G08_REAL_ENCODER")
local decoder=extract(compilerSource,
    "function QuestieDBCompiler:DecodePointerMap(",
    "\nfunction QuestieDBCompiler:CompileTable(","G08_REAL_DECODER")
local handleStart=once(compilerSource,
    "function QuestieDBCompiler:GetDBHandle(","G08_REAL_READER")
local handleBody=compilerSource:sub(handleStart)
assert(perKind:find("coroutine.yield()",1,true),
    "G08_COMPILER_SUSPENSION_REMOVED")
assert(perKind:find('Questie.db.global[databaseKey.."Bin"] = stream:Save()',1,true)
    and perKind:find('Questie.db.global[databaseKey.."Ptrs"] = QuestieDBCompiler:EncodePointerMap(stream, pointerMap)',1,true),
    "G08_REAL_PER_KIND_NONATOMIC_WRITES_ANCHOR")
assert(handleBody:find('local stream = QuestieStream:GetStream("raw")\n    coroutine.yield()',1,true),
    "G08_READER_POOL_ACQUIRE_BEFORE_YIELD")
local function band(a,b)
    local out,place=0,1
    for _=1,32 do
        if a%2==1 and b%2==1 then out=out+place end
        a=math.floor(a/2);b=math.floor(b/2);place=place*2
    end
    return out
end
local function loadExact(src,name,env)
    local fn
    if _VERSION=="Lua 5.1" then
        fn=assert(loadstring(src,name));setfenv(fn,env)
    else
        fn=assert(load(src,name,"t",env))
    end
    fn()
end
local function boot(options)
    options=options or {}
    local module,errors=nil,{}
    local streamEnv=setmetatable({
        QuestieLoader={CreateModule=function(_,name)
            assert(name=="QuestieStreamLib",
                "G08_UNEXPECTED_STREAM_MODULE_NAME")
            module={}
            return module
        end},
        Questie={Error=function(_,msg)errors[#errors+1]=msg end},
        bit={
            band=band,
            lshift=function(a,b)return (a*(2^b))%(2^32) end,
            rshift=function(a,b)return math.floor(a/(2^b)) end,
        },
        tremove=table.remove,
        unpack=unpack or table.unpack,
    },{__index=_G})
    loadExact(streamSource,"=actual_335_entire_stream_module",streamEnv)
    assert(type(module)=="table" and type(module.GetStream)=="function",
        "G08_ACTUAL_POOL_MISSING")
    local global={npcBin="OLD-BIN",npcPtrs="OLD-PTR"}
    local state={global=global,module=module,errors=errors,
        lastWriterStream=nil,writerCount=0}
    local compiler={
        supportedTypes={number={u8=true},string={u8=false}},
        writers={},startTime=0,
    }
    compiler.writers.u8=function(stream,value)
        state.lastWriterStream=stream
        state.writerCount=state.writerCount+1
        if options.errorOnWrite==state.writerCount then
            error("G08_FICTIONAL_U8_WRITER_EXCEPTION")
        end
        stream:WriteByte(value) -- actual QuestieStream public writer
    end
    -- The captured static compiler import is itself a real GetStream("raw")
    -- object, just as at compiler.lua top-level in the protected source.
    local staticImport=module:GetStream("raw")
    local env=setmetatable({
        QuestieDBCompiler=compiler,QuestieStream=staticImport,
        Questie={db={profile={debugEnabled=false},global=global},
            IsSoD=false,
            Error=function(_,msg)errors[#errors+1]=tostring(msg)end},
        TICKS_PER_YIELD=48,TICKS_PER_YIELD_DEBUG=144,
        min=math.min,unpack=unpack or table.unpack,
        readers={u8=function(s)return s:ReadByte()end},
        skippers={},
    },{__index=_G})
    loadExact(encoder,"=actual_335_pointer_encoder",env)
    loadExact(decoder,"=actual_335_pointer_decoder",env)
    loadExact(perKind,"=actual_335_compile_table_coroutine",env)
    loadExact(handleBody,"=actual_335_getdbhandle",env)
    state.compiler=compiler
    state.staticImport=staticImport
    return state
end
local function rows()
    return {[1]={[1]=11},[2]={[1]=22}}
end
local TYPES={value="u8"}
local ORDER={"value"}
local LOOKUP={value=1}
local SKIP={{value=0},1,0,TYPES,ORDER,{"value"},{value=1}}
local function compileThread(state,source,perTick)
    return coroutine.create(function()
        return state.compiler:CompileTableCoroutine(
            source,TYPES,ORDER,LOOKUP,"npc","NPC",perTick)
    end)
end
local function step(co)
    local ok,value=coroutine.resume(co)
    assert(ok,"G08_REAL_COROUTINE_ERROR: "..tostring(value))
    return value
end
local function readHandle(state)
    local thread=coroutine.create(function()
        return state.compiler:GetDBHandle(state.global.npcBin,
            state.global.npcPtrs,SKIP,{},nil)
    end)
    for _=1,12 do
        local ok,value=coroutine.resume(thread)
        assert(ok,"G08_REAL_READER_DECODER_ERROR: "..tostring(value))
        if coroutine.status(thread)=="dead" then return value end
    end
    error("G08_REAL_READER_STUCK")
end
local passed=0
local function check(ok,name)
    assert(ok,name)
    passed=passed+1
end
-- Positive, healthy: actual publisher, actual pointer encoding, real pooled
-- stream recycling into actual GetDBHandle with the original byte values.
do
    local s=boot()
    check(#perKind>2000 and #encoder>200 and #decoder>200 and
        #handleBody>3000,"G08_C01_ACTUAL_SOURCE_BODIES")
    local t=compileThread(s,rows(),0)
    step(t)
    check(coroutine.status(t)=="suspended" and
        s.global.npcBin=="OLD-BIN" and s.global.npcPtrs=="OLD-PTR",
        "G08_C02_PREWRITE_YIELD_NO_PUBLISH")
    step(t)
    check(s.writerCount==1 and
        s.global.npcBin=="OLD-BIN" and s.global.npcPtrs=="OLD-PTR",
        "G08_C03_FIRST_ENTRY_WRITES_ONLY_PRIVATE_STREAM")
    step(t)
    check(s.writerCount==2 and s.global.npcBin=="OLD-BIN",
        "G08_C04_SECOND_ENTRY_STILL_NOT_PUBLISHED")
    step(t)
    check(coroutine.status(t)=="dead" and
        s.global.npcBin==string.char(11,22) and
        type(s.global.npcPtrs)=="string" and
        s.global.npcPtrs~="OLD-PTR",
        "G08_C05_REAL_SOURCE_PUBLISH_AND_PTRS")
    local h=readHandle(s)
    check(h.stream==s.lastWriterStream and h.pointers[1]==1 and
        h.pointers[2]==2,
        "G08_C06_REAL_POOLED_WRITER_TO_READER_RECYCLE")
    check(h.QuerySingle(1,"value")==11 and
        h.QuerySingle(2,"value")==22 and
        h.Query(1,{"value"})[1]==11,
        "G08_C07_REAL_ENCODER_DECODER_AND_READER_VALUES")
    local independent=s.module:GetStream("raw")
    check(independent~=h.stream and
        h.QueryValidator(2,{"value"})[1]==22,
        "G08_C08_HELD_READER_NOT_REISSUED")
end
-- Source A -> B -> A while writer is suspended. The original real compiler
-- consumes B for entry 1, then live source is restored A before publication.
-- A before/after equality check would miss this. Test driver is a synthetic
-- source writer; real E01-E08 coverage remains unproven.
do
    local s=boot()
    local data=rows()
    local before=data[1][1]
    local t=compileThread(s,data,0)
    step(t) -- compiler has indexed entries and yielded
    data[1][1]=33 -- invented writer A -> B
    step(t) -- actual compiler encodes B for first entry and yields
    check(s.writerCount==1 and
        s.global.npcBin=="OLD-BIN",
        "G08_C09_REAL_COMPILE_SUSPENSION_ACCEPTS_TEMP_B")
    data[1][1]=before -- invented writer B -> A
    step(t) -- second row
    step(t) -- publish
    check(coroutine.status(t)=="dead" and
        data[1][1]==before and data[2][1]==22,
        "G08_C10_ABA_SOURCE_RESTORED")
    check(s.global.npcBin==string.char(33,22) and
        data[1][1]==11,
        "G08_C11_KNOWN_UNSAFE_REAL_COMPILER_ABA_STALE_BIN")
    local h=readHandle(s)
    check(h.QuerySingle(1,"value")==33 and
        h.QuerySingle(2,"value")==22 and
        data[1][1]==11,
        "G08_C12_REAL_READER_SEES_TRANSIENT_B_AFTER_ABA")
end
-- Real compiler error handling with a fictional codec failure injection:
-- the public stream stays borrowed and publication is not completed.
do
    local s=boot({errorOnWrite=2})
    local t=compileThread(s,rows(),0)
    step(t)
    step(t)
    local ok,err=coroutine.resume(t)
    check(not ok and type(err)=="string" and
        err:find("G08_FICTIONAL_U8_WRITER_EXCEPTION",1,true) and
        coroutine.status(t)=="dead",
        "G08_C13_ACTUAL_COMPILER_PROPAGATES_CODEC_ERROR")
    check(s.global.npcBin=="OLD-BIN" and
        s.global.npcPtrs=="OLD-PTR" and
        s.lastWriterStream:Save()==string.char(11),
        "G08_C14_FAILED_COMPILE_HELD_UNPUBLISHED_BUFFER")
    local nextBorrow=s.module:GetStream("raw")
    check(nextBorrow~=s.lastWriterStream and
        s.writerCount==2 and #s.errors>=2,
        "G08_C15_ABORTED_COMPILE_HAS_NO_POOL_RETURN")
end
-- Invalid type logs error and returns, leaving a primed stream inaccessible
-- to new borrowers. Test uses only fictional invalid Lua data, not real rows.
do
    local s=boot()
    local alias=s.module:GetStream("raw")
    alias:finished()
    local bad={[1]={[1]="FICTIONAL_INVALID_U8"}}
    local t=compileThread(s,bad,0)
    step(t)
    step(t)
    check(coroutine.status(t)=="dead" and #s.errors==1 and
        s.global.npcBin=="OLD-BIN" and
        s.global.npcPtrs=="OLD-PTR",
        "G08_C16_REAL_INVALID_TYPE_EARLY_RETURN")
    local fresh=s.module:GetStream("raw")
    check(fresh~=alias and s.writerCount==0 and
        alias:Save()=="" and alias._mode=="raw",
        "G08_C17_KNOWN_UNSAFE_INVALID_TYPE_STREAM_NOT_FINISHED")
end
assert(passed==17,"G08_REAL_COMPILER_POOL_CONTROL_CENSUS_CHANGED")
print("PUBLIC G08 REAL COMPILER GLOBAL POOL ABA CONTROLS: 17/17 PASS")
print("PUBLIC G08 KNOWN UNSAFE: staged actual compiler reads transient B across source A-to-B-to-A, real decoder returns B after source restored; aborts retain borrowed streams.")
print("PUBLIC G08 NOT ACCEPTED: authenticated E01-E08 writer epochs, all-kind atomic publication, normal client source timing, durable disk/relog, or release.")
