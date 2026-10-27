-- PUBLIC-SAFE TEST-ONLY witness for the real CompileTableCoroutine lease path.
-- Drives pinned Database/compiler.lua and Modules/QuestieStream.lua.
-- NO production quarantine, compiler, stream, or Stage1 edits.
-- Passing a KNOWN UNSAFE check records the current failure. It is not a fix.
--
-- Source-owned Finish: the compiler calls the external lease owner.
--   BEFORE pool — Finish throws before the real stream:finished() insert.
--   AFTER pool  — the real finished() has already inserted, then Finish throws.
-- Compiler-owned: Finish inserts and returns, then NQAssertStageAttempt throws
--   because Finish re-entered Begin. The scratch pair is not published.
-- Driver reclaim runs only after the coroutine is DEAD, at most once, and
-- never calls finished() again once the owner has inserted. Production still
-- does not quarantine that object: a retained holder aliases the next raw lease.

-- Harness guards under test. Mutation checks flip exactly one to false.
local CLEANUP_ONLY_WHEN_DEAD = true
local CLEANUP_ONLY_ONCE = true
local REFUSE_AMBIGUOUS_RETRY = true
local RECORD_POOL_TOUCH = true

unpack = unpack or table.unpack
tremove = table.remove
local function band(a, b)
    local result, place = 0, 1
    for _ = 1, 32 do
        if a % 2 == 1 and b % 2 == 1 then result = result + place end
        a, b, place = math.floor(a / 2), math.floor(b / 2), place * 2
    end
    return result
end
bit = {
    band = band,
    lshift = function(n, s) return (n * 2 ^ s) % 4294967296 end,
    rshift = function(n, s) return math.floor((n % 4294967296) / 2 ^ s) end,
}
local modules = {}
QuestieLoader = {
    CreateModule = function(_, name)
        modules[name] = modules[name] or {}
        return modules[name]
    end,
    ImportModule = function(_, name)
        assert(modules[name], "missing Questie module " .. name)
        return modules[name]
    end,
}
for _, kind in ipairs({"QuestieDB", "QuestieLib", "l10n"}) do
    QuestieLoader:CreateModule(kind)
end
QuestieCompat = {Is335 = true, WOW_PROJECT_ID = 2}
Questie = {
    IsSoD = false, IsTBC = false, IsWotlk = true,
    db = {profile = {debugEnabled = false}, global = {}},
    Error = function() end,
    Debug = function() end,
}
assert(loadfile("Modules/QuestieStream.lua"))()
assert(loadfile("Database/npcDB.lua"))()
assert(loadfile("Database/compiler.lua"))()
local db = QuestieLoader:ImportModule("QuestieDB")
local compiler = QuestieLoader:ImportModule("DBCompiler")

local NPC_ID = 77101
local NPC_NAME = "Invented NPC"
db.npcData = {[NPC_ID] = {[db.npcKeys.name] = NPC_NAME}}

local saved = Questie.db.global
saved.npcBin = "OLD_BIN_npc"
saved.npcPtrs = "OLD_PTRS_npc"
saved.nQuestieDataRevision = 57
saved.dbCompiledCount = 9
saved.dbIsCompiled = true

local tested = 0
local function check(label, predicate)
    tested = tested + 1
    assert(predicate, "FAIL GATE08 COMPILER FINISH " .. tested .. " " .. label)
    print("PASS GATE08 COMPILER FINISH " .. tested .. " " .. label)
end

local function contains(text, needle)
    return tostring(text):find(needle, 1, true) ~= nil
end

local function compilerStream()
    for index = 1, 40 do
        local name, value = debug.getupvalue(compiler.CompileTableCoroutine, index)
        if name == "QuestieStream" then
            assert(type(value) == "table" and type(value.GetStream) == "function")
            return value
        end
        if name == nil then break end
    end
    error("pinned compiler writer stream unavailable")
end

local function upvalue(fn, wanted)
    for index = 1, 20 do
        local name, value = debug.getupvalue(fn, index)
        if name == wanted then return value end
        if name == nil then break end
    end
    error("missing upvalue " .. wanted)
end

local streamParent = compilerStream()
local pool = upvalue(streamParent.GetStream, "StreamPool")
-- Prove GetStream and the real finished() closure share one pool object.
local poolProbe = streamParent:GetStream("raw")
assert(upvalue(poolProbe.finished, "StreamPool") == pool,
    "finished() does not close over the observed StreamPool")
assert(poolProbe._mode == "raw")
-- The probe is intentionally not returned; it is not part of any case.

local function drain(target)
    -- Harness isolation between cases only. This is not production quarantine.
    for index = #target, 1, -1 do target[index] = nil end
end

local function occurrences(target, object)
    local count = 0
    for index = 1, #target do
        if target[index] == object then count = count + 1 end
    end
    return count
end

local function hasDuplicate(target)
    local seen = {}
    for index = 1, #target do
        if seen[target[index]] then return true end
        seen[target[index]] = true
    end
    return false
end

local function savedUntouched()
    return saved.npcBin == "OLD_BIN_npc"
        and saved.npcPtrs == "OLD_PTRS_npc"
        and saved.nQuestieDataRevision == 57
        and saved.dbCompiledCount == 9
        and saved.dbIsCompiled == true
end

-- Reclaim is the stand-in for the missing production driver. It may run while
-- a coroutine is still suspended; the guards must make that a no-op.
local function reclaim(co, lease)
    if not lease then return false end
    if CLEANUP_ONLY_WHEN_DEAD and coroutine.status(co) ~= "dead" then
        return false
    end
    if CLEANUP_ONLY_ONCE and lease.reclaimAttempts >= 1 then
        return false
    end
    lease.reclaimAttempts = lease.reclaimAttempts + 1
    if REFUSE_AMBIGUOUS_RETRY and (lease.done or lease.poolTouched) then
        return false
    end
    lease.stream:finished()
    lease.cleanupFinishCalls = lease.cleanupFinishCalls + 1
    return true
end

local function runCompile(opts)
    drain(pool)
    local stage = {
        npcBin = "PRIOR_BIN",
        npcPtrs = "PRIOR_PTRS",
    }
    local lease
    local owner = {}
    function owner:Acquire(parent, mode)
        assert(parent == streamParent, "compiler did not pass its stream owner")
        assert(mode == "raw", "non-debug CompileTableCoroutine must request raw")
        assert(lease == nil, "one compile acquired two writer leases")
        local stream = parent:GetStream(mode)
        lease = {
            stream = stream,
            mode = mode,
            rawWrite = stream.WriteByte,
            done = false,
            releasing = false,
            poolTouched = false,
            ownerFinishCalls = 0,
            finishedCalls = 0,
            cleanupFinishCalls = 0,
            reclaimAttempts = 0,
            suspendedReclaims = 0,
        }
        return lease
    end
    function owner:Finish(got)
        assert(got == lease, "compiler finished a different lease")
        lease.releasing = true
        lease.ownerFinishCalls = lease.ownerFinishCalls + 1
        if opts.throwBefore then error("SYNTHETIC_FINISH_BEFORE_POOL", 0) end
        got.stream:finished()
        lease.finishedCalls = lease.finishedCalls + 1
        if RECORD_POOL_TOUCH then lease.poolTouched = true end
        if opts.throwAfter then error("SYNTHETIC_FINISH_AFTER_POOL", 0) end
        if opts.reenterBegin then compiler:BeginNQStagedGeneration(stage) end
        lease.done = true
        lease.releasing = false
    end
    stage._nqWriterLeaseOwner = owner
    local co = coroutine.create(function()
        compiler:CompileNPCs(stage)
    end)
    local resumes, ok, err = 0, true, nil
    while coroutine.status(co) ~= "dead" and resumes < 8 do
        ok, err = coroutine.resume(co)
        resumes = resumes + 1
        if lease and coroutine.status(co) ~= "dead" then
            lease.suspendedReclaims = lease.suspendedReclaims + 1
            reclaim(co, lease)
        end
        if not ok then break end
    end
    return {
        ok = ok, err = err, stage = stage, lease = lease, resumes = resumes,
        co = co, dead = coroutine.status(co) == "dead",
    }
end

local function reclaimTwiceAfterDead(result)
    assert(result.dead, "cleanup invoked before DEAD")
    reclaim(result.co, result.lease)
    reclaim(result.co, result.lease)
end

local function singleReturn(lease)
    return lease.finishedCalls + lease.cleanupFinishCalls == 1
end

local function drive(fn)
    local thread = coroutine.create(fn)
    for _ = 1, 64 do
        local ok, value = coroutine.resume(thread)
        if not ok then error(tostring(value), 0) end
        if coroutine.status(thread) == "dead" then return value end
    end
    error("reader coroutine exceeded 64 resumes")
end

-- (a) Normal-use positive control. Run before any failing Finish.
local positive = runCompile({})
reclaimTwiceAfterDead(positive)
local positiveLease = positive.lease
check("positive control healthy raw compile leaves SavedVariables unchanged",
    positive.ok and positive.dead and positive.resumes == 2
    and positiveLease.mode == "raw"
    and type(positive.stage.npcBin) == "string" and #positive.stage.npcBin > 0
    and positive.stage.npcBin ~= "PRIOR_BIN"
    and type(positive.stage.npcPtrs) == "string" and #positive.stage.npcPtrs > 0
    and positive.stage.npcPtrs ~= "PRIOR_PTRS"
    and savedUntouched())
check("positive control Finish once and suspended reclaim does not pool",
    positiveLease.ownerFinishCalls == 1
    and positiveLease.finishedCalls == 1
    and positiveLease.done
    and positiveLease.suspendedReclaims == 1
    and positiveLease.cleanupFinishCalls == 0
    and positiveLease.reclaimAttempts == 1
    and singleReturn(positiveLease))
check("positive control returns that handle to the pool exactly once",
    #pool == 1 and occurrences(pool, positiveLease.stream) == 1
    and not hasDuplicate(pool))
local positiveReuse = streamParent:GetStream("raw")
check("positive control reuse yields the same reset raw stream",
    positiveReuse == positiveLease.stream
    and positiveReuse._mode == "raw"
    and positiveReuse._pointer == 1
    and positiveReuse:Save() == ""
    and positiveReuse.WriteByte == positiveLease.rawWrite
    and occurrences(pool, positiveLease.stream) == 0)
local positiveHandle = drive(function()
    return compiler:GetDBHandle(positive.stage.npcBin, positive.stage.npcPtrs,
        compiler:BuildSkipMap(db.npcCompilerTypes, db.npcCompilerOrder),
        db.npcKeys, nil)
end)
check("positive control readback returns the fictional NPC name",
    positiveHandle.QuerySingle(NPC_ID, "name") == NPC_NAME
    and savedUntouched())
positiveHandle.stream:finished()

-- (b) Source-owned throw BEFORE the real pool insert.
local before = runCompile({throwBefore = true})
check("throw before pool is distinct and publishes neither scratch field",
    not before.ok and before.dead and before.resumes == 2
    and contains(before.err, "SYNTHETIC_FINISH_BEFORE_POOL")
    and not contains(before.err, "SYNTHETIC_FINISH_AFTER_POOL")
    and before.stage.npcBin == "PRIOR_BIN"
    and before.stage.npcPtrs == "PRIOR_PTRS"
    and before.lease.ownerFinishCalls == 1
    and before.lease.finishedCalls == 0
    and not before.lease.poolTouched
    and not before.lease.done
    and before.lease.suspendedReclaims == 1
    and savedUntouched())
check("throw before pool is absent until DEAD cleanup",
    before.lease.cleanupFinishCalls == 0
    and occurrences(pool, before.lease.stream) == 0
    and #pool == 0)
reclaimTwiceAfterDead(before)
check("DEAD cleanup after before-pool throw finishes once and does not double-pool",
    before.lease.cleanupFinishCalls == 1
    and before.lease.reclaimAttempts == 1
    and before.lease.ownerFinishCalls == 1
    and singleReturn(before.lease)
    and #pool == 1 and occurrences(pool, before.lease.stream) == 1
    and not hasDuplicate(pool)
    and savedUntouched())

-- (b) Source-owned throw AFTER the real pool insert. Separate from BEFORE.
local after = runCompile({throwAfter = true})
check("throw after pool is distinct and publishes neither scratch field",
    not after.ok and after.dead and after.resumes == 2
    and contains(after.err, "SYNTHETIC_FINISH_AFTER_POOL")
    and not contains(after.err, "SYNTHETIC_FINISH_BEFORE_POOL")
    and after.stage.npcBin == "PRIOR_BIN"
    and after.stage.npcPtrs == "PRIOR_PTRS"
    and after.lease.ownerFinishCalls == 1
    and after.lease.finishedCalls == 1
    and after.lease.poolTouched
    and not after.lease.done
    and savedUntouched())
check("throw after pool is singly pooled before DEAD cleanup",
    #pool == 1 and occurrences(pool, after.lease.stream) == 1
    and not hasDuplicate(pool)
    and after.lease.cleanupFinishCalls == 0)
reclaimTwiceAfterDead(after)
check("DEAD cleanup after post-pool throw does not Finish again",
    after.lease.cleanupFinishCalls == 0
    and after.lease.ownerFinishCalls == 1
    and singleReturn(after.lease)
    and #pool == 1 and occurrences(pool, after.lease.stream) == 1
    and not hasDuplicate(pool))
local afterBorrower = streamParent:GetStream("raw")
check("KNOWN UNSAFE post-pool throw still leases the held stream",
    afterBorrower == after.lease.stream
    and afterBorrower._mode == "raw"
    and occurrences(pool, after.lease.stream) == 0)
after.lease.stream:WriteByte(23)
check("KNOWN UNSAFE post-pool holder and next borrower share storage",
    afterBorrower:Save() == string.char(23)
    and after.lease.stream:Save() == string.char(23))

-- Compiler-owned: Finish itself succeeded, then the compiler throws.
local compilerOwned = runCompile({reenterBegin = true})
check("compiler-owned post-Finish throw is distinct and does not publish",
    not compilerOwned.ok and compilerOwned.dead and compilerOwned.resumes == 2
    and contains(compilerOwned.err, "GATE08_STAGE_ATTEMPT_CHANGED")
    and not contains(compilerOwned.err, "SYNTHETIC_FINISH_BEFORE_POOL")
    and not contains(compilerOwned.err, "SYNTHETIC_FINISH_AFTER_POOL")
    and compilerOwned.lease.done
    and compilerOwned.lease.ownerFinishCalls == 1
    and compilerOwned.lease.finishedCalls == 1
    and compilerOwned.lease.poolTouched
    and compilerOwned.stage.npcBin == nil
    and compilerOwned.stage.npcPtrs == nil
    and savedUntouched())
reclaimTwiceAfterDead(compilerOwned)
check("compiler-owned failure stays singly pooled with no second Finish",
    compilerOwned.lease.cleanupFinishCalls == 0
    and compilerOwned.lease.reclaimAttempts == 1
    and singleReturn(compilerOwned.lease)
    and #pool == 1 and occurrences(pool, compilerOwned.lease.stream) == 1
    and not hasDuplicate(pool))
local compilerBorrower = streamParent:GetStream("raw")
check("KNOWN UNSAFE compiler-owned failure still leases the held stream",
    compilerBorrower == compilerOwned.lease.stream
    and compilerBorrower._pointer == 1
    and compilerBorrower:Save() == ""
    and occurrences(pool, compilerOwned.lease.stream) == 0)
compilerOwned.lease.stream:WriteByte(29)
check("KNOWN UNSAFE compiler-owned holder and next borrower share storage",
    compilerBorrower:Save() == string.char(29)
    and compilerOwned.lease.stream:Save() == string.char(29))

-- Throw before Finish is reached at all: invalid staged datatype.
-- Cleanup still has to be exactly one finished() after DEAD.
local originalNpc = db.npcData
db.npcData = {[NPC_ID] = {[db.npcKeys.name] = {99}}}
local datatype = runCompile({})
db.npcData = originalNpc
check("pre-Finish datatype error never calls Finish and keeps scratch unpublished",
    not datatype.ok and datatype.dead
    and contains(datatype.err, "GATE08_STAGE_INVALID_DATATYPE")
    and datatype.lease.ownerFinishCalls == 0
    and datatype.lease.finishedCalls == 0
    and not datatype.lease.poolTouched
    and not datatype.lease.done
    and datatype.stage.npcBin == "PRIOR_BIN"
    and datatype.stage.npcPtrs == "PRIOR_PTRS"
    and savedUntouched())
check("pre-Finish stream is absent from the pool while the coroutine was suspended",
    datatype.lease.suspendedReclaims == 1
    and datatype.lease.cleanupFinishCalls == 0
    and occurrences(pool, datatype.lease.stream) == 0
    and #pool == 0)
reclaimTwiceAfterDead(datatype)
check("DEAD cleanup after pre-Finish error finishes once and does not double-pool",
    datatype.lease.cleanupFinishCalls == 1
    and datatype.lease.reclaimAttempts == 1
    and datatype.lease.ownerFinishCalls == 0
    and singleReturn(datatype.lease)
    and #pool == 1 and occurrences(pool, datatype.lease.stream) == 1
    and not hasDuplicate(pool)
    and db.npcData[NPC_ID][db.npcKeys.name] == NPC_NAME
    and savedUntouched())

assert(tested == 20, "expected 20 compiler Finish checks, got " .. tested)
print("GATE08 COMPILER-OWNED AMBIGUOUS FINISH: 20/20 KNOWN UNSAFE / POSITIVE CONTROL")
print("DRAFT ONLY: compiler lease Finish quarantine is NOT proven; no production fix, source epoch, atomic publish, SavedVariables recovery or native client QA")
