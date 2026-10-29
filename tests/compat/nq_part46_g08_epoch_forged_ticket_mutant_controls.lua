-- TEST-ONLY counterfactual owner ledger adversarial mutation controls.
-- This tests an invented model from the repo test suite, NOT original addon code.
local f=assert(io.open("tests/compat/nq_part45_g08_original_orphan_child_epoch_contract.lua","rb"))
local original=assert(f:read("*a"));f:close()
local function extract(s,startText,endText)
  local a=assert(s:find(startText,1,true),"MODEL_BEGIN_NOT_FOUND")
  local b=assert(s:find(endText,a+#startText,true),"MODEL_END_NOT_FOUND")
  return s:sub(a,b-1)
end
local src=extract(original,"local function newLedger()","\nlocal v=newLedger()")
local old='if t~=self.current or t.state~="PENDING"\n      or child.serial~=self.serial or child.done then return false end'
local pub=extract(src,"  function v:publish(child)","\n  function v:parentDone(t)")
assert(pub:find(old,1,true),"ORIGINAL_MODEL_PUBLISH_PREDICATE_CHANGED")
local function makeLedger(code)
  local payload=code.."\nreturn newLedger"
  if _VERSION=="Lua 5.1" then
    local fn=assert(loadstring(payload,"=invented_G08_ledger"))
    return assert(fn())
  else return assert(load(payload,"=invented_G08_ledger","t",_G))() end
end
local default=makeLedger(src)
local function replaceOne(target,before,after)
  local a,b=target:find(before,1,true)
  assert(a and not target:find(before,b+1,true),"AMBIGUOUS_MUTATION")
  return target:sub(1,a-1)..after..target:sub(b+1)
end
local function buildMutant(predicate)
  local mutantPublish=replaceOne(pub,old,predicate)
  local a,b=src:find(pub,1,true)
  assert(a and not src:find(pub,b+1,true),"MUTATION_PUBLISH_UNIQUE")
  return makeLedger(src:sub(1,a-1)..mutantPublish..src:sub(b+1))
end
local stateOnly=buildMutant(
  'if t.state~="PENDING" or child.done then return false end')
local labelOnly=buildMutant(
  'if t.label~=self.current.label or t.state~="PENDING" or child.done then return false end')
local n=0
local function check(ok,label) assert(ok,label);n=n+1 end
check(original:find("local function newLedger()",1,true)~=nil,
  "E01_TEST_LEDGER_SOURCE_EXTRACTED")
check(src:find("child.serial~=self.serial",1,true)~=nil,
  "E02_ORIGINAL_MODEL_HAS_SERIAL_GUARD")
check(type(default)=="function" and type(stateOnly)=="function"
  and type(labelOnly)=="function","E03_THREE_MODEL_CONSTRUCTORS")

-- An ordinary A->B->A test is not an adversarial serial test because
-- begin(B) already ABORTS the original A. This is why weak guards survived.
local aba=default()
local oldA=aba:begin("A")
local oldChild=aba:child(oldA)
local middleB=aba:begin("B")
local currentA=aba:begin("A")
check(oldA.state=="ABORTED" and middleB.state=="ABORTED",
  "E04_ORDINARY_ABA_ALREADY_ABORTED")
check(currentA.label==oldA.label and currentA.serial~=oldA.serial,
  "E05_ABA_LABEL_SAME_SERIAL_NEW")
check(not aba:publish(oldChild),"E06_ORDINARY_STALE_REJECTED")
check(aba.visible==0,"E07_ORDINARY_NO_WRITES")

-- Forged/retained serials attack the CURRENT and still-PENDING owner.
local v=default()
local owner=v:begin("A")
local valid=v:child(owner)
check(owner.serial==1 and owner.state=="PENDING",
  "E08_CURRENT_OWNER_PENDING")
check(valid~=nil and v:publish(valid),"E09_VALID_CHILD_PUBLISHED")
local before=v.visible
local forgedPrior={owner=owner,serial=owner.serial-1,done=false}
local forgedFuture={owner=owner,serial=owner.serial+1,done=false}
check(not v:publish(forgedPrior),"E10_CURRENT_OWNER_OLD_SERIAL_REJECTED")
check(not v:publish(forgedFuture),"E11_CURRENT_OWNER_FUTURE_SERIAL_REJECTED")
check(v.visible==before,"E12_WRONG_SERIAL_NO_SIDE_EFFECT")
local impostor={label=owner.label,serial=owner.serial,state="PENDING",
  parentFinished=false,outstanding=0}
local fakeOwnerChild={owner=impostor,serial=owner.serial,done=false}
check(not v:publish(fakeOwnerChild),"E13_SAME_LABEL_FAKE_OWNER_REJECTED")
check(v.visible==before,"E14_OWNER_SPOOF_NO_SIDE_EFFECT")
check(not v:childDone(forgedPrior),"E15_WRONG_SERIAL_CANNOT_COMPLETE_CHILD")
check(not v:childDone(fakeOwnerChild),"E16_FAKE_OWNER_CANNOT_COMPLETE_CHILD")
check(valid.done==false and owner.outstanding==1,
  "E17_INVALID_CHILD_DONE_NO_MUTATION")
check(v:parentDone(owner) and owner.state=="PENDING",
  "E18_PARENT_WAITS_FOR_AUTHENTIC_CHILD")
check(not v:publish(forgedPrior),"E19_WRONG_SERIAL_REJECTED_AFTER_PARENT_DONE")
check(v:childDone(valid) and owner.state=="COMPLETED",
  "E20_VALID_CHILD_COMPLETES_OWNER")
check(not v:publish(valid) and v.visible==before,
  "E21_COMPLETED_CHILD_NO_MORE_WRITES")
check(v.counts.COMPLETED==1 and v.counts.ABORTED==0,
  "E22_EXACT_SUCCESS_CENSUS")

-- Explicit negative mutant controls: these two deliberately weakened
-- counterfactual guards MUST be observed ACCEPTING invalid children.
local ms=stateOnly()
local msOwner=ms:begin("A")
local msGood=ms:child(msOwner)
check(ms:publish(msGood),"E23_STATE_ONLY_MUTANT_NORMAL_CONTROL")
local msForged={owner=msOwner,serial=msOwner.serial-1,done=false}
check(ms:publish(msForged),"E24_STATE_ONLY_MUTANT_ACCEPTS_WRONG_EPOCH")
check(ms.visible==2,"E25_STATE_ONLY_WRONG_EPOCH_PUBLISHED")
local ml=labelOnly()
local mlOwner=ml:begin("A")
local mlGood=ml:child(mlOwner)
check(ml:publish(mlGood),"E26_LABEL_MUTANT_NORMAL_CONTROL")
local mlForged={owner=mlOwner,serial=mlOwner.serial+99,done=false}
check(ml:publish(mlForged),"E27_LABEL_MUTANT_ACCEPTS_WRONG_EPOCH")
local mlImpostor={label=mlOwner.label,serial=mlOwner.serial,state="PENDING",
  parentFinished=false,outstanding=0}
check(ml:publish({owner=mlImpostor,serial=mlOwner.serial,done=false}),
  "E28_LABEL_MUTANT_ACCEPTS_FORGED_OWNER")
check(ml.visible==3,"E29_LABEL_MUTANT_PUBLISHED_INVALID_CHILDREN")

-- Limit surfaced by the same model: an unregistered child with correct
-- current owner+serial can publish. This is not evidence about production.
local gap=default()
local gapOwner=gap:begin("A")
check(gapOwner.outstanding==0,"E30_ZERO_REGISTERED_CHILDREN")
check(gap:publish({owner=gapOwner,serial=gapOwner.serial,done=false}),
  "E31_ORIGINAL_MODEL_STILL_ACCEPTS_UNREGISTERED_LOOKALIKE")
check(gap.visible==1 and gapOwner.outstanding==0,
  "E32_UNREGISTERED_PUBLISH_NOT_TRACKED_FOR_COMPLETION")
assert(n==32,"PART46_EPOCH_ADVERSARIAL_CENSUS:"..n)
print("PUBLIC G08 PART46 EPOCH FORGED TICKET MODEL: 32/32 PASS")
print("PUBLIC G08 PART46 MUTANTS: state-only and label-only publish guards observed accepting invalid current-owner serials; original model rejects both.")
print("PUBLIC G08 PART46 LIMITS: invented owner ledger only; authentic original addon has no guard; even this model accepts unregistered same-serial ticket, no production safety claim.")
