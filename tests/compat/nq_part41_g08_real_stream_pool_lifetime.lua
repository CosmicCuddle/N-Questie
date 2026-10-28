-- Part41 G08: full REAL pinned QuestieStream.lua executed, invented byte data.
-- Test deliberately unsafe borrowing patterns; not a production pool repair.
local root=assert(os.getenv("NQ_G08_STREAM_SOURCE_ROOT"),
    "G08_STREAM_PINNED_SOURCE_REQUIRED")
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"),"G08_STREAM_SOURCE_NOT_STAGED")
    local src=assert(f:read("*a"));f:close()
    return src
end
local streamSource=read("Modules/QuestieStream.lua")
local compilerSource=read("Database/compiler.lua")
local function occursOnce(src,pattern,label)
    local i=assert(src:find(pattern,1,true),label.."_MISSING")
    assert(not src:find(pattern,i+#pattern,true),label.."_DUPLICATED")
end
occursOnce(streamSource,"local StreamPool = {}",
    "G08_REAL_GLOBAL_POOL_ANCHOR")
occursOnce(streamSource,"function QuestieStreamLib:GetStream(mode)",
    "G08_REAL_GETSTREAM_ANCHOR")
occursOnce(streamSource,"local function _StreamFinished(self)",
    "G08_REAL_FINISHED_ANCHOR")
occursOnce(compilerSource,
    'local stream = QuestieStream:GetStream("raw")\n    coroutine.yield()',
    "G08_REAL_READER_ACQUIRE_BEFORE_YIELD")
local function band(a,b)
    local place,out=1,0
    for _=1,32 do
        local aa,bb=a%2,b%2
        if aa==1 and bb==1 then out=out+place end
        a=math.floor(a/2);b=math.floor(b/2);place=place*2
    end
    return out
end
local function boot()
    local module,errors=nil,{}
    local env=setmetatable({
        QuestieLoader={CreateModule=function(_,name)
            assert(name=="QuestieStreamLib",
                "G08_REAL_STREAM_MODULE_NAME_CHANGED")
            module={}
            return module
        end},
        Questie={Error=function(_,msg)errors[#errors+1]=msg end},
        bit={
            band=band,
            lshift=function(a,b)return (a*(2^b))%(2^32) end,
            rshift=function(a,b)return math.floor(a/(2^b)) end,
        },
        unpack=unpack or table.unpack
    },{__index=_G})
    local chunk
    if _VERSION=="Lua 5.1" then
        chunk=assert(loadstring(streamSource,
            "=pinned_335_entire_QuestieStream"))
        setfenv(chunk,env)
    else
        chunk=assert(load(streamSource,
            "=pinned_335_entire_QuestieStream","t",env))
    end
    chunk()
    assert(type(module)=="table" and
        type(module.GetStream)=="function" and
        type(module.Save)=="function" and
        type(module.Load)=="function" and
        type(module._writeByte)=="function",
        "G08_REAL_STREAM_MODULE_NOT_LOADED")
    return module,errors
end
local function payload(s,byte)
    s:WriteByte(byte)
    return s:Save()
end
local controls={
    function()
        local lib=boot()
        local s=lib:GetStream("raw")
        assert(s._mode=="raw" and s._pointer==1 and
            type(s._bin)=="table" and s:Save()=="" and
            type(s.finished)=="function",
            "G08_REAL_STREAM_NEW_LEASE")
    end,
    function()
        local lib=boot()
        local s=lib:GetStream("raw")
        assert(payload(s,65)=="A" and s._pointer==2,
            "G08_REAL_STREAM_RAW_BYTE_WRITE")
    end,
    function()
        local lib,errors=boot()
        local ok=pcall(function()lib:GetStream(nil)end)
        assert(not ok and #errors==1,
            "G08_REAL_STREAM_MODE_REJECTED")
    end,
    function()
        local lib=boot()
        local s=lib:GetStream("raw")
        payload(s,65)
        s:finished()
        assert(s._pointer==1 and s:Save()=="" and
            s._level==0,
            "G08_REAL_FINISHED_RESETS_STREAM")
    end,
    function()
        local lib=boot()
        local s=lib:GetStream("raw")
        payload(s,65)
        s:finished()
        local again=lib:GetStream("raw")
        assert(again==s and again:Save()=="" and
            payload(again,66)=="B",
            "G08_REAL_POOL_REUSE_AFTER_FINISHED")
    end,
    function()
        local lib=boot()
        local one=lib:GetStream("raw")
        local two=lib:GetStream("raw")
        assert(one~=two and payload(one,65)=="A" and
            payload(two,66)=="B",
            "G08_UNRETURNED_LEASES_NOT_IN_POOL")
    end,
    function()
        -- KNOWN UNSAFE: no invalidation of a stale caller reference.
        local lib=boot()
        local stale=lib:GetStream("raw")
        payload(stale,65)
        stale:finished()
        local borrower=lib:GetStream("raw")
        assert(borrower==stale and payload(borrower,66)=="B",
            "G08_STALE_REFERENCE_BASELINE")
        assert(payload(stale,67)=="BC" and
            borrower:Save()=="BC",
            "G08_KNOWN_UNSAFE_USE_AFTER_FINISHED")
    end,
    function()
        -- KNOWN UNSAFE: second finished() adds same object to pool twice.
        local lib=boot()
        local s=lib:GetStream("raw")
        s:finished()
        s:finished()
        local borrowerA=lib:GetStream("raw")
        local borrowerB=lib:GetStream("raw")
        assert(borrowerA==borrowerB and borrowerA==s,
            "G08_KNOWN_UNSAFE_DOUBLE_RETURN_ALIASES_TWO_LEASES")
    end,
    function()
        local lib=boot()
        local s=lib:GetStream("raw")
        s:finished();s:finished()
        local a=lib:GetStream("raw")
        local b=lib:GetStream("raw")
        payload(a,65)
        assert(payload(b,66)=="AB" and a:Save()=="AB",
            "G08_KNOWN_UNSAFE_DUPLICATED_ACTIVE_LEASE_WRITES")
    end,
    function()
        -- A suspended reader/writer must not be reissued if still owned.
        local lib=boot()
        local writer
        local thread=coroutine.create(function()
            writer=lib:GetStream("raw")
            payload(writer,65)
            coroutine.yield("owned")
            return payload(writer,67)
        end)
        local ok,y=coroutine.resume(thread)
        assert(ok and y=="owned" and
            coroutine.status(thread)=="suspended",
            "G08_SUSPENDED_LEASE_BASELINE")
        local other=lib:GetStream("raw")
        assert(other~=writer and payload(other,66)=="B",
            "G08_SUSPENDED_STREAM_NOT_RETURNED_IS_DISTINCT")
        local resumed,answer=coroutine.resume(thread)
        assert(resumed and answer=="AC" and writer:Save()=="AC",
            "G08_SUSPENDED_LEASE_STAYS_DISTINCT_WHEN_OWNED")
    end,
    function()
        -- KNOWN UNSAFE controlled misuse: externally finish a stream
        -- held by a still-suspended coroutine and it is recycled.
        local lib=boot()
        local owned,reader
        local thread=coroutine.create(function()
            owned=lib:GetStream("raw")
            payload(owned,65)
            coroutine.yield("pending")
            return payload(owned,67)
        end)
        local ok,y=coroutine.resume(thread)
        assert(ok and y=="pending" and
            coroutine.status(thread)=="suspended",
            "G08_SUSPENDED_PREMATURE_RETURN_BASELINE")
        owned:finished() -- caller protocol violation, not normal handling
        reader=lib:GetStream("raw")
        assert(reader==owned and payload(reader,66)=="B",
            "G08_KNOWN_UNSAFE_POOL_REISSUES_SUSPENDED_STREAM")
        local resumed,result=coroutine.resume(thread)
        assert(resumed and result=="BC" and reader:Save()=="BC",
            "G08_KNOWN_UNSAFE_SUSPENDED_STREAM_CONTAMINATION")
    end,
    function()
        -- The global pool is shared by independent callers of SAME module.
        local lib=boot()
        local function subsystemA()return lib:GetStream("raw")end
        local function subsystemB()return lib:GetStream("raw")end
        local s=subsystemA()
        payload(s,65)
        s:finished()
        local other=subsystemB()
        assert(other==s and payload(other,66)=="B",
            "G08_GLOBAL_POOL_CROSS_SUBSYSTEM_REUSE")
    end,
    function()
        local lib=boot()
        local s=lib:GetStream("raw")
        s:finished()
        local nextMode=lib:GetStream("raw_assert")
        assert(nextMode~=s and nextMode._mode=="raw_assert",
            "G08_CROSS_MODE_POOL_POP_CREATES_NEW_STREAM")
    end,
    function()
        local lib=boot()
        local s=lib:GetStream("raw")
        payload(s,65)
        s:finished()
        local renewed=lib:GetStream("raw")
        local binary=string.char(120,121,122)
        renewed:Load(binary)
        assert(renewed._pointer==1 and
            renewed:ReadByte()==120 and
            renewed:ReadByte()==121 and
            renewed._pointer==3,
            "G08_ACTUAL_STREAM_LOAD_RESET_BOUNDARY")
    end
}
assert(#controls==14,"G08_REAL_POOL_CONTROL_CENSUS_CHANGED")
local ran=0
for i,check in ipairs(controls) do
    check()
    ran=ran+1
    assert(ran==i,"G08_REAL_POOL_SEQUENCE_DRIFT")
end
assert(ran==14,"G08_REAL_POOL_CONTROL_TOTAL_DRIFT")
print("PUBLIC G08 EXACT REAL STREAM POOL CONTROLS: 14/14 PASS")
print("PUBLIC G08 KNOWN UNSAFE: stale aliases, double-finished duplicate leases, and prematurely returned suspended writers can contaminate pool borrowers.")
print("PUBLIC G08 NOT ACCEPTED: normal client can trigger misuse, ownership quarantine, full compiler, writer epochs, durable relog or release.")
