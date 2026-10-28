-- Part41 G08: execute EXACT pinned public CompileTableCoroutine and Compile.
-- Fictional codec stream and tiny one-row inputs; NOT the real global pool.
-- All negative results are KNOWN UNSAFE observations, never acceptance gates.
local root=assert(os.getenv("NQ_G08_PINNED_SOURCE_ROOT"),
    "G08_PINNED_PROTECTED_SOURCE_REQUIRED")
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"),"G08_SOURCE_NOT_STAGED")
    local data=assert(f:read("*a"));f:close()
    return data
end
local compilerSource=read("Database/compiler.lua")
local stage1Source=read("Modules/QuestieInit.lua")
local function extract(source,startText,endText)
    local first=assert(source:find(startText,1,true),"G08_PINNED_FUNCTION_MISSING")
    assert(not source:find(startText,first+1,true),
        "G08_PINNED_FUNCTION_DUPLICATED")
    local last=assert(source:find(endText,first+#startText,true),
        "G08_FUNCTION_END_ANCHOR_MISSING")
    assert(last>first,"G08_FUNCTION_ORDER_INVALID")
    return source:sub(first,last-1)
end
local exactPerKind=extract(compilerSource,
    "function QuestieDBCompiler:CompileTableCoroutine(",
    "\nfunction QuestieDBCompiler:BuildSkipMap(")
local exactOuter=extract(compilerSource,
    "function QuestieDBCompiler:Compile()",
    "\nfunction QuestieDBCompiler:ValidateNPCs()")
local stage1Anchor="QuestieDBCompiler:Compile()\n        Questie.db.global.nQuestieDataRevision = nQuestieRevision\n        dbCompiled = true"
assert(stage1Source:find(stage1Anchor,1,true),
    "G08_STAGE1_UNCONDITIONAL_REVISION_ANCHOR_MISSING")
local function loadExact(src,name,env)
    local fn
    if _VERSION=="Lua 5.1" then
        fn=assert(loadstring(src,name));setfenv(fn,env)
    else
        fn=assert(load(src,name,"t",env))
    end
    fn()
end
local kinds={"npc","obj","quest","item"}
local function copyGlobal()
    local global={
        dbIsCompiled=false,dbCompiledCount=4,
        dbCompiledOnVersion="old-version",dbCompiledLang="old-locale",
        dbCompiledExpansion=3,nQuestieDataRevision=7,
    }
    for _,key in ipairs(kinds) do
        global[key.."Bin"]="OLD-BIN-"..key
        global[key.."Ptrs"]="OLD-PTR-"..key
    end
    return global
end
local function build(config)
    config=config or {}
    local global=copyGlobal()
    local state={streams={},errors={},global=global,activeKind=nil}
    local publicQuestie={
        IsSoD=false,db={profile={debugEnabled=false},global=global},
        Error=function(_,msg)state.errors[#state.errors+1]=tostring(msg)end
    }
    local compiler={
        supportedTypes={number={u8=true},string={},["table"]={}},
        writers={},
        startTime=0,
    }
    compiler.writers.u8=function(stream,value)
        if stream.kind==config.writerFailsKind then
            error("G08_INVENTED_CODEC_WRITER_ERROR")
        end
        stream._pointer=stream._pointer+1
        stream.buffer[#stream.buffer+1]=tostring(value)
    end
    function compiler:EncodePointerMap(stream,pointerMap)
        if stream.kind==config.pointerFailsKind then
            error("G08_INVENTED_POINTER_ENCODE_ERROR")
        end
        return "PTR-"..stream.kind.."-"..tostring(pointerMap[1])
    end
    local streamProvider={}
    function streamProvider:GetStream(mode)
        assert(mode=="raw","G08_UNKNOWN_STREAM_MODE")
        local stream={
            kind=assert(state.activeKind,"G08_STREAM_KIND_MISSING"),
            _pointer=1,buffer={},finishedCount=0
        }
        function stream:Save()
            return "BIN-"..self.kind.."-"..table.concat(self.buffer,",")
        end
        function stream:finished()
            self.finishedCount=self.finishedCount+1
        end
        state.streams[#state.streams+1]=stream
        return stream
    end
    local env=setmetatable({
        QuestieDBCompiler=compiler,
        QuestieStream=streamProvider,
        Questie=publicQuestie,
        QuestieLib={GetAddonVersionString=function()return "test-new-version"end},
        l10n=setmetatable({GetUILocale=function()return "test-new-locale"end},
            {__call=function(_,msg)return msg end}),
        WOW_PROJECT_ID=77,
        TICKS_PER_YIELD=1,TICKS_PER_YIELD_DEBUG=1,
        GetTime=function()return 123 end,
        print=function()end,
    },{__index=_G})
    loadExact(exactPerKind,"=pinned_335_compile_table_coroutine",env)
    loadExact(exactOuter,"=pinned_335_compile_driver",env)
    for _,kind in ipairs(kinds) do
        local method={
            npc="CompileNPCs",obj="CompileObjects",
            quest="CompileQuests",item="CompileItems",
        }
        compiler[method[kind]]=function(self)
            state.activeKind=kind
            local value=(kind==config.invalidTypeKind) and
                "INVENTED_WRONG_TYPE" or 9
            return self:CompileTableCoroutine({[1]={[1]=value}},
                {field="u8"},{"field"},{field=1},kind,"Synthetic",1)
        end
    end
    state.compiler=compiler
    return state
end
local function driver(state)
    return coroutine.create(function()
        return state.compiler:Compile()
    end)
end
local function drain(thread)
    for _=1,16 do
        local ok,err=coroutine.resume(thread)
        if not ok then return false,tostring(err) end
        if coroutine.status(thread)=="dead" then return true,err end
    end
    error("G08_COROUTINE_DID_NOT_TERMINATE_IN_BOUND")
end
local function changed(global,kind)
    return global[kind.."Bin"]=="BIN-"..kind.."-9" and
        global[kind.."Ptrs"]=="PTR-"..kind.."-1"
end
local function old(global,kind)
    return global[kind.."Bin"]=="OLD-BIN-"..kind and
        global[kind.."Ptrs"]=="OLD-PTR-"..kind
end
local function unfinished(state,kind)
    for _,stream in ipairs(state.streams) do
        if stream.kind==kind then
            return stream.finishedCount==0
        end
    end
    return false
end
local okState,okThread=build(),nil
okThread=driver(okState)
local errorState=build({invalidTypeKind="obj"})
local errorThread=driver(errorState)
local writerState=build({writerFailsKind="quest"})
local writerThread=driver(writerState)
local ptrState=build({pointerFailsKind="item"})
local ptrThread=driver(ptrState)
local controls={
    function()
        assert(#exactPerKind>2000 and #exactOuter>1000,
            "G08_EXACT_TWO_FUNCTIONS_NOT_LOADED")
        assert(stage1Source:find(stage1Anchor,1,true),
            "G08_STAGE1_REVISION_SEQUENCE_CHANGED")
    end,
    function()
        local ok=coroutine.resume(okThread)
        assert(ok and coroutine.status(okThread)=="suspended" and
            #okState.streams==1 and old(okState.global,"npc") and
            old(okState.global,"obj") and
            not okState.global.dbIsCompiled,
            "G08_FIRST_YIELD_MUST_NOT_PUBLISH")
    end,
    function()
        assert(drain(okThread),"G08_HEALTHY_COMPILER_MUST_FINISH")
        for _,kind in ipairs(kinds) do
            assert(changed(okState.global,kind),
                "G08_HEALTHY_ALL_FOUR_KINDS_MUST_PUBLISH")
        end
    end,
    function()
        assert(okState.global.dbIsCompiled==true and
            okState.global.dbCompiledCount==5 and
            okState.global.dbCompiledOnVersion=="test-new-version" and
            okState.global.dbCompiledLang=="test-new-locale" and
            okState.global.dbCompiledExpansion==77 and
            okState.global.nQuestieDataRevision==7 and
            #okState.streams==4,
            "G08_HEALTHY_METADATA_EXPECTED")
        for _,stream in ipairs(okState.streams) do
            assert(stream.finishedCount==1,
                "G08_HEALTHY_FICTIONAL_STREAM_FINISHED")
        end
    end,
    function()
        local ok=drain(errorThread)
        assert(ok and coroutine.status(errorThread)=="dead" and
            #errorState.errors==1 and unfinished(errorState,"obj"),
            "G08_KNOWN_UNSAFE_INVALID_TYPE_RETURNS_WITH_HELD_STREAM")
    end,
    function()
        assert(changed(errorState.global,"npc") and
            old(errorState.global,"obj") and
            changed(errorState.global,"quest") and
            changed(errorState.global,"item"),
            "G08_KNOWN_UNSAFE_CROSS_KIND_PARTIAL_PUBLISH")
    end,
    function()
        assert(errorState.global.dbIsCompiled==true and
            errorState.global.dbCompiledCount==5 and
            errorState.global.dbCompiledOnVersion=="test-new-version" and
            errorState.compiler._isCompiling==true,
            "G08_KNOWN_UNSAFE_ERROR_STILL_MARKED_COMPILED")
    end,
    function()
        local ok,err=drain(writerThread)
        assert(not ok and err:find("G08_INVENTED_CODEC_WRITER_ERROR",1,true)
            and coroutine.status(writerThread)=="dead" and
            unfinished(writerState,"quest"),
            "G08_KNOWN_UNSAFE_WRITER_ERROR_LEAVES_STREAM")
    end,
    function()
        assert(changed(writerState.global,"npc") and
            changed(writerState.global,"obj") and
            old(writerState.global,"quest") and
            old(writerState.global,"item") and
            not writerState.global.dbIsCompiled,
            "G08_KNOWN_UNSAFE_WRITER_ERROR_LEAVES_PARTIAL_DB")
    end,
    function()
        local prior=#writerState.streams
        assert(writerState.compiler:Compile()==nil and
            #writerState.streams==prior and
            writerState.compiler._isCompiling==true and
            writerState.global.dbCompiledCount==4,
            "G08_KNOWN_UNSAFE_RETRY_SUPPRESSED_BY_STICKY_FLAG")
    end,
    function()
        local ok,err=drain(ptrThread)
        assert(not ok and err:find("G08_INVENTED_POINTER_ENCODE_ERROR",1,true)
            and coroutine.status(ptrThread)=="dead" and
            ptrState.global.itemBin=="BIN-item-9" and
            ptrState.global.itemPtrs=="OLD-PTR-item" and
            unfinished(ptrState,"item"),
            "G08_KNOWN_UNSAFE_HALF_PAIR_ON_POINTER_EXCEPTION")
    end,
    function()
        assert(changed(ptrState.global,"npc") and
            changed(ptrState.global,"obj") and
            changed(ptrState.global,"quest") and
            not ptrState.global.dbIsCompiled and
            ptrState.global.dbCompiledCount==4 and
            ptrState.compiler._isCompiling==true and
            ptrState.global.nQuestieDataRevision==7,
            "G08_KNOWN_UNSAFE_EIGHT_FIELD_AND_METADATA_NONATOMIC")
    end,
}
assert(#controls==12,"G08_CONTROL_CENSUS_CHANGED")
local executed=0
for index,fn in ipairs(controls) do
    fn()
    executed=executed+1
    assert(executed==index,"G08_CONTROL_SEQUENCE_CHANGED")
end
assert(executed==12,"G08_CONTROL_INCOMPLETE")
print("PUBLIC G08 REAL PINNED COMPILER NEGATIVE CONTROLS: 12/12 PASS")
print("PUBLIC G08 KNOWN UNSAFE: invalid-kind return reports compiled despite mixed four-kind state; errors strand streams and partial pairs.")
print("PUBLIC G08 NOT ACCEPTED: full QuestieStream pool behaviour, all-writer epochs, atomic memory, disk crash/relog, client or release.")
