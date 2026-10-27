-- PUBLIC-SAFE TEST-ONLY Gate08 shared QuestieStream pool witness.
-- Real Modules/QuestieStream.lua; NO production quarantine or Stage1 changes.
-- This test intentionally demonstrates a known failure. Passing != safety.
tremove=table.remove -- WoW global used by the pinned module
bit={
    band=function(a,b)
        local n,p=0,1
        for _=1,32 do
            if a%2==1 and b%2==1 then n=n+p end
            a,b,p=math.floor(a/2),math.floor(b/2),p*2
        end
        return n
    end,
    lshift=function(n,k) return (n*2^k)%4294967296 end,
    rshift=function(n,k) return math.floor((n%4294967296)/2^k) end,
}
local modules={}
QuestieLoader={
    CreateModule=function(_,name)
        modules[name]=modules[name] or {}
        return modules[name]
    end,
}
Questie={Error=function(_,message) error(message,0) end}
assert(loadfile("Modules/QuestieStream.lua"))()
local streamLib=assert(modules.QuestieStreamLib)
local tested=0
local function check(label,predicate)
    tested=tested+1
    assert(predicate,"FAIL GATE08 GLOBAL POOL "..tested.." "..label)
    print("PASS GATE08 GLOBAL POOL "..tested.." "..label)
end

-- A suspended/owner caller may observe an ambiguous failure after the
-- genuine finished() has already reset and returned its object to StreamPool.
-- The exception is synthetic; the shared pool and methods are REAL.
local writer=streamLib:GetStream("raw")
writer:WriteByte(17)
check("a live writer starts with distinct bytes",writer:Save()==string.char(17))
local trueFinish=writer.finished
writer.finished=function(self)
    trueFinish(self)
    error("SYNTHETIC_FAILURE_AFTER_REAL_POOL_RETURN",0)
end
local ok,reason=pcall(function() writer:finished() end)
check("the post-return exception is observable",not ok and
    tostring(reason):find("SYNTHETIC_FAILURE_AFTER_REAL_POOL_RETURN",1,true)~=nil)

-- The owner has not relinquished its old pointer because Finish threw,
-- but an unrelated consumer can acquire precisely the same pooled object.
local unrelated=streamLib:GetStream("raw")
check("unrelated consumer receives still-held writer object",unrelated==writer)
unrelated:WriteByte(23)
check("unrelated writes alter original owner-visible bytes",
    unrelated:Save()==string.char(23) and writer:Save()==string.char(23))

-- GetStream's same-mode fast path returns the pooled table without reinitialising
-- its method slots. Restore our synthetic method wrapper so the second witness
-- exercises the REAL finished() method (not the injected exception again).
unrelated.finished=trueFinish

-- A driver that interprets the exception as NOT yet returned and calls
-- finished() again duplicates the same reference in the global pool.
-- Two unrelated live callers then receive one mutable stream object.
unrelated:finished()
unrelated:finished()
local callerA=streamLib:GetStream("raw")
local callerB=streamLib:GetStream("raw")
check("ambiguous double-finish duplicates a live pooled reference",
    callerA==callerB and callerA==writer)
callerA:WriteByte(41)
check("two concurrent borrowed identities share the same storage",
    callerB:Save()==string.char(41) and callerA:Save()==string.char(41))

-- POSITIVE CONTROL: ordinary successful Finish must continue to benefit
-- from the current normal pool recycling path. A blanket "disable pooling"
-- hypothetical fix should fail this control, unlike targeted quarantine.
local healthy=streamLib:GetStream("raw_assert")
healthy:WriteByte(71)
assert(healthy:Save()==string.char(71))
healthy:finished()
local healthyNext=streamLib:GetStream("raw_assert")
check("normal unambiguous Finish reuses one reset stream",
    healthyNext==healthy and healthyNext._pointer==1
    and healthyNext:Save()=="")

-- INDEPENDENT KNOWN UNSAFE: the same-mode fast path does not repopulate
-- methods. A polluted method slot persists into an unrelated borrower.
-- This is synthetic instrumentation, NOT a real addon exploit claim.
local methodOwner=streamLib:GetStream("raw")
local cleanSave=methodOwner.Save
local function injectedSave() return "SYNTHETIC_POISONED_METHOD" end
methodOwner.Save=injectedSave
methodOwner:finished()
local methodBorrower=streamLib:GetStream("raw")
check("poisoned method slot leaks to next same-mode borrower",
    methodBorrower==methodOwner and methodBorrower.Save==injectedSave
    and methodBorrower.Save~=cleanSave
    and methodBorrower:Save()=="SYNTHETIC_POISONED_METHOD")

assert(tested==8)
print("GATE08 GLOBAL STREAM POOL WITNESS: 8/8 KNOWN UNSAFE / POSITIVE CONTROL")
print("DRAFT ONLY: global pool quarantine NOT fixed; no source epoch, atomic publish, SavedVariables recovery or native client QA")
