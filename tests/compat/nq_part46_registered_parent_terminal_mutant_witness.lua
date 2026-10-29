-- TEST-ONLY: mutation witnesses of the unchanged #369 invented registered-ledger.
-- Not actual addon Lua, no game client/frame/source implementation asserted.
local path="tests/compat/nq_part46_g08_registered_descendant_owner_model.lua"
local f=assert(io.open(path,"rb"),"REGISTERED_LEDGER_FIXTURE_NOT_FOUND")
local source=assert(f:read("*a"));f:close()
local function extract(a,b)
  local i=assert(source:find(a,1,true),"SOURCE_LEDGER_START_MISSING")
  local j=assert(source:find(b,i+#a, true),"SOURCE_LEDGER_END_MISSING")
  return source:sub(i,j-1)
end
local ledger=extract("local function registeredLedger(unsafe)",
  "\n-- Positive nested owner/child/grandchild path.")
local function replaceOne(s,a,b)
  local i,j=assert(s:find(a,1,true),"MUTATION_ANCHOR_MISSING")
  assert(not s:find(a,j+1,true),"MUTATION_ANCHOR_AMBIGUOUS")
  return s:sub(1,i-1)..b..s:sub(j+1)
end
local checkCount=0
local function check(ok,name) assert(ok,name);checkCount=checkCount+1 end
local function constructor(src)
  local chunk=src.."\nreturn registeredLedger"
  local fn
  if _VERSION=="Lua 5.1" then fn=assert(loadstring(chunk,"=exact_parent_registered_model"));setfenv(fn,_G)
  else fn=assert(load(chunk,"=exact_parent_registered_model","t",_G)) end
  return assert(fn())
end
local make=constructor(ledger)
check(ledger:find("not owner.issued[parentChild]",1,true)~=nil,
  "P01_ORIGINAL_MODEL_PARENT_MEMBERSHIP_PRESENT")
check(ledger:find("owner.issued[child]=nil",1,true)~=nil,
  "P02_ORIGINAL_MODEL_REMOVES_CHILDREN_AT_TERMINAL")
local valid=make()
local owner=valid:begin("TEST")
check(owner.state=="PENDING" and owner.outstanding==0,
  "P03_PARENT_NEW_PENDING")
local root=valid:child(owner)
local grand=valid:child(owner,root)
check(root and grand and root.dependents==1,
  "P04_REGISTERED_PARENT_DESCENDANT_CREATED")
check(valid:childDone(grand) and grand.done and root.dependents==0,
  "P05_REGISTERED_GRANDCHILD_FINISHED")
check(not owner.issued[grand],
  "P06_COMPLETED_GRANDCHILD_REMOVED_FROM_REGISTRY")
check(valid:child(owner,grand)==nil,
  "P07_NO_CHILD_OF_COMPLETED_REGISTERED_PARENT")
local forged={owner=owner,serial=owner.serial,done=false,
  cancelled=false,dependents=0}
check(valid:child(owner,forged)==nil,
  "P08_NO_CHILD_OF_UNREGISTERED_PARENT_TICKET")
check(owner.registered==1 and owner.outstanding==1
  and owner.issued[root] and not owner.issued[forged],
  "P09_INVALID_PARENTS_DO_NOT_MUTATE_REGISTRY")
local sibling=valid:child(owner)
check(sibling and owner.registered==2 and owner.outstanding==2,
  "P10_STILL_ACCEPTS_VALID_SIBLING")
local newOwner=valid:begin("NEXT")
check(owner.state=="ABORTED" and newOwner.state=="PENDING",
  "P11_NEW_EPOCH_ABORTS_OLD_OWNER")
check(root.cancelled and sibling.cancelled,
  "P12_ABORT_CASCADES_LIVE_CHILDREN")
check(next(owner.issued)==nil,
  "P13_ABORT_ACTUALLY_EMPTIES_REGISTRY")
check(owner.registered==0 and owner.outstanding==0,
  "P14_ABORT_CLEARS_COUNTERS")
check(not valid:publish(root) and not valid:childDone(sibling),
  "P15_ABORT_REJECTS_OLD_CHILD_WRITES_AND_COMPLETION")
check(valid.readySignals==0 and valid.counts.ABORTED==1,
  "P16_ABORT_NEVER_CLAIMS_READY")
check(valid:parentDone(newOwner) and newOwner.state=="COMPLETED",
  "P17_FRESH_ZERO_CHILD_COMPLETES")
check(next(newOwner.issued)==nil and valid.readySignals==1,
  "P18_SUCCESS_EMPTIES_REGISTRY_AND_READIES_ONCE")

local err=make()
local bad=err:begin("ERROR")
local c1=err:child(bad)
local c2=err:child(bad,c1)
check(c1 and c2 and bad.registered==2,
  "P19_ERROR_TEST_NESTED_ACTIVE_CHILDREN")
check(err:error(bad) and bad.state=="ERROR",
  "P20_ERROR_TERMINAL_REACHED")
check(next(bad.issued)==nil and bad.registered==0
  and bad.outstanding==0,"P21_ERROR_REGISTRY_EMPTY")
check(c1.cancelled and c2.cancelled and err.readySignals==0,
  "P22_ERROR_CANCELS_CHILDREN_NO_READY")
check(not err:publish(c1) and not err:childDone(c2),
  "P23_POST_ERROR_CHILD_REJECTED")

local parentGate=[[
    if parentChild and (not owner.issued[parentChild]
      or parentChild.done or parentChild.cancelled) then return nil end
]]
local weakenedParent=replaceOne(ledger,parentGate,
  "    -- NEGATIVE MUTANT: full parent-validity gate intentionally removed\n")
local badCtor=constructor(weakenedParent)
local weak=badCtor()
local w=weak:begin("PARENT_MUTANT")
local wr=weak:child(w)
local wg=weak:child(w,wr)
check(wr and wg and weak:childDone(wg),
  "P24_PARENT_MUTANT_TEST_PRECONDITION")
local accepted=weak:child(w,wg)
check(accepted~=nil and accepted.parent==wg,
  "P25_PARENT_VALIDITY_MUTANT_ACCEPTS_DONE_PARENT")
check(weak:child(w,{owner=w,serial=w.serial,done=false,
  cancelled=false,dependents=0})~=nil,
  "P26_PARENT_VALIDITY_MUTANT_ACCEPTS_UNREGISTERED_PARENT")

local cleanupAnchor="      owner.issued[child]=nil\n    end\n    owner.registered=0"
local weakenedTerminal=replaceOne(ledger,cleanupAnchor,
  "      -- NEGATIVE MUTANT: leave issued[child] retained\n    end\n    owner.registered=0")
local cleanupCtor=constructor(weakenedTerminal)
local broken=cleanupCtor()
local bo=broken:begin("CLEANUP_MUTANT")
local bc=broken:child(bo)
check(bc and bo.issued[bc],"P27_TERMINAL_MUTANT_CHILD_REGISTERED")
local second=broken:begin("NEW")
check(bo.state=="ABORTED" and second.state=="PENDING",
  "P28_TERMINAL_MUTANT_ABORTS")
check(next(bo.issued)~=nil,"P29_TERMINAL_MUTANT_RETAINS_STALE_TICKET")
check(bo.registered==0 and bo.outstanding==0,
  "P30_TERMINAL_MUTANT_COUNTERS_HIDE_RETAINED_TICKET")
local brokenError=cleanupCtor()
local be=brokenError:begin("E")
local ec=brokenError:child(be)
check(brokenError:error(be) and ec.cancelled,
  "P31_TERMINAL_MUTANT_ERROR_OCCURRED")
check(next(be.issued)~=nil and brokenError.readySignals==0,
  "P32_TERMINAL_MUTANT_ERROR_STILL_LEAKS_ISSUED")

-- Both witnesses address exact peer-surviving mutants. This does not make
-- the invented registeredLedger a production implementation.
assert(checkCount==32,"PART46_REGISTERED_PARENT_CENSUS:"..checkCount)
print("PUBLIC G08 PART46 REGISTERED PARENT TERMINAL MUTANTS: 32/32 PASS")
print("PUBLIC G08 PART46 NEGATIVE WITNESSES: deleting child-parent membership admits forged descendant; dropping terminal issued cleanup retains canceled tickets.")
print("PUBLIC G08 PART46 LIMITS: exact invented #369 registeredLedger source; no native WoW scheduler, original addon ownership guard, production or real character state.")
